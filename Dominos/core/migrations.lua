-- Saved variable migrations. These run when this file loads
local AddonName, Addon = ...

local SCHEMA_VERSION = 3

-- iterates over every profile in the saved variables
local function profiles(sv)
    return pairs(type(sv.profiles) == 'table' and sv.profiles or {})
end

-- Migrations[version](sv) upgrades the saved variables to that version
local Migrations = {}

-- 2: bar 1 pages to the skyriding bar by default
Migrations[2] = function(sv)
    for _, profile in profiles(sv) do
        local mainBar = profile.frames and profile.frames[1]
        local pages = mainBar and mainBar.pages

        if type(pages) == 'table' then
            for _, classPages in pairs(pages) do
                if type(classPages) == 'table' and classPages.dragonriding == nil then
                    classPages.dragonriding = 10
                end
            end
        end
    end
end

-- 3: action bars use action slot addresses (core/addressMap.lua), and bar count
-- and length are saved separately. Paging becomes address offsets. With 12
-- buttons per bar (13 or 14 bars, nearly everyone), bars are renumbered so that
-- each keeps the slots it had. Otherwise, the player is told
do
    local PAGE_SIZE = 12

    -- the page order, as it was for version 3
    local PAGE_ORDER = { 1, 6, 5, 3, 4, 13, 14, 15, 2, 7, 8, 9, 10, 11, 12 }

    -- at 12 buttons per bar: the new number of each old bar, so that it keeps
    -- its slots
    local NEW_BAR_IDS = { 1, 9, 4, 5, 3, 2, 10, 11, 12, 13, 14, 6, 7, 8 }

    local addressPages = {}
    for addressPage, page in ipairs(PAGE_ORDER) do
        addressPages[page] = addressPage
    end

    local function getAddress(slot)
        if slot < 1 or slot > #PAGE_ORDER * PAGE_SIZE then
            return slot
        end

        local page = math.floor((slot - 1) / PAGE_SIZE) + 1
        return (addressPages[page] - 1) * PAGE_SIZE + (slot - 1) % PAGE_SIZE + 1
    end

    -- the old slot offset for a bar number: bars split the slots in order,
    -- skipping slots 133-144
    local function getOldOffset(barId, length)
        local offset = (barId - 1) * length
        if offset >= 132 then
            offset = offset + 12
        end
        return offset
    end

    -- old paging values were relative bar numbers: bar id + value, wrapped
    local function convertPaging(sets, barId, count, length)
        local pages = sets.pages
        sets.pages = nil

        if type(pages) ~= 'table' then
            return
        end

        local paging = {}

        for class, states in pairs(pages) do
            if type(states) == 'table' then
                local classPaging = {}

                for stateId, value in pairs(states) do
                    if type(value) == 'number' then
                        local page = (barId + value - 1) % count + 1
                        classPaging[stateId] = getAddress(getOldOffset(page, length) + 1) - 1
                    end
                end

                paging[class] = classPaging
            end
        end

        sets.paging = paging
    end

    local function renumberAnchor(anchor, newIds)
        if type(anchor) == 'table' then
            local group = anchor.relFrameGroup
            local id = tonumber(anchor.relFrame)

            if (group == nil or group == 'Dominos') and id and newIds[id] then
                anchor.relFrame = newIds[id]
            end
        elseif type(anchor) == 'string' then
            -- legacy "<id><point>", like "3TL"
            local id = tonumber(anchor:sub(1, -3))

            if id and newIds[id] then
                return newIds[id] .. anchor:sub(-2)
            end
        end

        return anchor
    end

    -- returns the new bar count: the highest new number
    local function renumber(profile, frames, count)
        local newIds = {}
        for oldId = 1, math.min(count, #NEW_BAR_IDS) do
            newIds[oldId] = NEW_BAR_IDS[oldId]
        end

        local used = {}
        local maxId = 0

        for _, newId in pairs(newIds) do
            used[newId] = true
            maxId = math.max(maxId, newId)
        end

        local renumbered = {}

        for id, sets in pairs(frames) do
            if type(id) ~= 'number' then
                renumbered[id] = sets
            elseif newIds[id] then
                renumbered[newIds[id]] = sets
            end
            -- settings for bars past the old count are dropped
        end

        -- hide numbers that no old bar moved to
        for id = 1, maxId do
            if not used[id] then
                renumbered[id] = { hidden = true }
            end
        end

        for _, sets in pairs(renumbered) do
            if type(sets) == 'table' then
                sets.anchor = renumberAnchor(sets.anchor, newIds)
            end
        end

        if type(profile.possessBar) == 'number' and newIds[profile.possessBar] then
            profile.possessBar = newIds[profile.possessBar]
        end

        profile.frames = renumbered
        return maxId
    end

    Migrations[3] = function(sv)
        for _, profile in profiles(sv) do
            -- showgrid was renamed showEmptyButtons. Was migrated on every load
            if profile.showgrid ~= nil then
                profile.showEmptyButtons = profile.showgrid
                profile.showgrid = nil
            end

            local ab = profile.ab or {}
            profile.ab = ab

            -- already done (going back to an older release can lower the
            -- saved version)
            if not ab.addresses then
                -- bars split 168 buttons evenly, 14 of them by default
                local count = ab.count or 14
                local length = math.floor(168 / count)
                local frames = type(profile.frames) == 'table' and profile.frames or {}

                for id, sets in pairs(frames) do
                    if type(id) == 'number' and type(sets) == 'table' then
                        convertPaging(sets, id, count, length)
                    end
                end

                if length == PAGE_SIZE then
                    count = renumber(profile, frames, count)
                else
                    ab.migrationNotice = true
                end

                -- saved explicitly, since the default changes
                ab.count = count
                ab.length = length
                ab.addresses = true
            end
        end
    end
end

-- migrates saved variables, if present, to the latest schema version
local function migrate(sv)
    local fromVersion = type(sv) == 'table'
        and type(sv.global) == 'table'
        and sv.global.configVersion

    if type(fromVersion) ~= 'number' or fromVersion >= SCHEMA_VERSION then
        return
    end

    sv = CopyTable(sv)

    for version = fromVersion + 1, SCHEMA_VERSION do
        local migration = Migrations[version]
        if migration then
            migration(sv)
        end
    end

    sv.global.configVersion = SCHEMA_VERSION
    return sv
end

-- for stamping new databases
Addon.DB_SCHEMA_VERSION = SCHEMA_VERSION

-- only update the user's saved variables if migration was a success
local svName = AddonName .. 'DB'
local success, result = pcall(migrate, _G[svName])

if success then
    if result then
        _G[svName] = result
    end

    Addon.savedVariablesMigrated = true
else
    geterrorhandler()(result)
end
