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

-- 3: bar count and length are saved separately. Until now, bars split 168
-- buttons evenly, with 14 bars by default
Migrations[3] = function(sv)
    for _, profile in profiles(sv) do
        local ab = profile.ab or {}
        local count = ab.count or 14

        ab.count = count
        ab.length = ab.length or math.floor(168 / count)
        profile.ab = ab
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
