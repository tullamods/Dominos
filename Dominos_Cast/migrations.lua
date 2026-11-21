-- old saved settings to the current format, once per version across every
-- profile. anything an old bar got from a fallback is written out, so
-- upgrading never changes how a bar looks
local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local LSM = LibStub('LibSharedMedia-3.0')

local DB_VERSION = 3

-- the old border was the dialog edge, with the fill this far inside it
local OLD_BORDER = 'Blizzard Dialog'
local OLD_BORDER_SIZE = 16
local OLD_BORDER_MARGIN = 5

local OLD_CAST_ID = 'cast'
local OLD_CAST_WIDTH = 240
local OLD_CAST_HEIGHT = 32
local OLD_CAST_FONT = 'Friz Quadrata TT'
-- what the old OnLoadSettings nil guard wrote
local OLD_CAST_DISPLAY = { icon = false, time = true, border = true, latency = true }

-- one bar per timer, before they became one bar
local OLD_MIRROR_IDS = { 'mirrorTimer1', 'mirrorTimer2', 'mirrorTimer3' }
local MIRROR_ID = 'mirror'
local OLD_MIRROR_WIDTH = 200
local OLD_MIRROR_HEIGHT = 20

-- stacked like the old bars, spaced like blizzard's
local MIRROR_ORIENTATION = 'VERTICAL'
local MIRROR_SPACING = 11

local function profiles()
    local sv = Dominos.db.sv

    return pairs(type(sv) == 'table' and type(sv.profiles) == 'table' and sv.profiles or {})
end

-- the border becomes a check and a media key, set either way so turning it on
-- brings back the old one. returns how far inside it the fill sat
local function upgradeBorder(sets, hasBorder)
    sets.showBorder = hasBorder and true or false
    sets.border = OLD_BORDER
    sets.borderSize = OLD_BORDER_SIZE

    if hasBorder then
        return OLD_BORDER_MARGIN
    end

    return 0
end

-- the old size took in the padding and the border's margin, the new one is
-- just the fill
local function upgradeSize(sets, oldWidth, oldHeight, margin)
    local padW = sets.padW or 0
    local padH = sets.padH or padW

    sets.width = (sets.w or oldWidth) - 2 * (padW + margin)
    sets.height = (sets.h or oldHeight) - 2 * (padH + margin)
    sets.w = nil
    sets.h = nil
end

--------------------------------------------------------------------------------
-- Cast bar
--------------------------------------------------------------------------------

-- showTime marks ones already done
local function upgradeCastBar(sets)
    if sets.showTime ~= nil then
        return
    end

    local display = sets.display or OLD_CAST_DISPLAY

    -- the cast bar always showed its label
    sets.showLabel = true
    sets.showIcon = display.icon and true or false
    sets.showTime = display.time and true or false
    sets.showLatency = display.latency and true or false
    sets.showSpark = display.spark and true or false
    sets.display = nil

    local margin = upgradeBorder(sets, display.border)
    upgradeSize(sets, OLD_CAST_WIDTH, OLD_CAST_HEIGHT, margin)

    -- 'blizzard' was never an lsm key, it fell back to Blizzard
    if sets.texture == nil or sets.texture == 'blizzard' then
        sets.texture = 'Blizzard'
    end

    if sets.font == nil then
        sets.font = OLD_CAST_FONT
    end

    -- nil read as off
    sets.useSpellReactionColors = sets.useSpellReactionColors and true or false
end

--------------------------------------------------------------------------------
-- Mirror timers
--------------------------------------------------------------------------------

-- legacy anchors are "<id><point>" strings, like "mirrorTimer1TL"
local function getAnchoredId(anchor)
    if type(anchor) == 'table' then
        if anchor.relFrameGroup == nil or anchor.relFrameGroup == 'Dominos' then
            return anchor.relFrame
        end
    elseif type(anchor) == 'string' then
        return anchor:sub(1, -3)
    end
end

local function isOldMirrorAnchor(anchor)
    local id = getAnchoredId(anchor)

    return id ~= nil and tContains(OLD_MIRROR_IDS, id)
end

-- the first old bar's look and position, as the new bar's
local function upgradeMirrorTimer(sets)
    local display = sets.display or {}

    -- the old label toggle never did anything
    sets.showLabel = true
    sets.showTime = display.time and true or false
    sets.display = nil

    local margin = upgradeBorder(sets, display.border)
    upgradeSize(sets, OLD_MIRROR_WIDTH, OLD_MIRROR_HEIGHT, margin)

    if sets.texture == nil then
        sets.texture = LSM:GetDefault(LSM.MediaType.STATUSBAR)
    end

    if sets.font == nil then
        sets.font = LSM:GetDefault(LSM.MediaType.FONT)
    end

    sets.orientation = MIRROR_ORIENTATION
    sets.spacing = MIRROR_SPACING

    -- would be anchored to itself now
    if isOldMirrorAnchor(sets.anchor) then
        sets.anchor = nil
    end

    return sets
end

-- anything anchored to an old bar follows the new one
local function upgradeMirrorTimers(frames)
    local oldSets = frames[OLD_MIRROR_IDS[1]]

    if type(oldSets) == 'table' and frames[MIRROR_ID] == nil then
        frames[MIRROR_ID] = upgradeMirrorTimer(CopyTable(oldSets))
    end

    for _, id in ipairs(OLD_MIRROR_IDS) do
        frames[id] = nil
    end

    for _, sets in pairs(frames) do
        local anchor = type(sets) == 'table' and sets.anchor

        if isOldMirrorAnchor(anchor) then
            if type(anchor) == 'table' then
                anchor.relFrame = MIRROR_ID
            else
                sets.anchor = MIRROR_ID .. anchor:sub(-2)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Upgrade
--------------------------------------------------------------------------------

-- version 2 bars had no check: None hid the border and Solid was the flat one
local function upgradeShowBorder(sets)
    if type(sets) ~= 'table' or sets.showBorder ~= nil then
        return
    end

    sets.showBorder = sets.border ~= 'None'

    if sets.border == 'None' or sets.border == 'Solid' then
        sets.border = nil
    end

    if sets.borderSize == nil then
        sets.borderSize = OLD_BORDER_SIZE
    end
end

local function upgrade(oldVersion)
    for _, profile in profiles() do
        local frames = profile.frames

        if type(frames) == 'table' then
            if oldVersion < 2 then
                if type(frames[OLD_CAST_ID]) == 'table' then
                    upgradeCastBar(frames[OLD_CAST_ID])
                end

                upgradeMirrorTimers(frames)
            end

            if oldVersion < 3 then
                upgradeShowBorder(frames[OLD_CAST_ID])
                upgradeShowBorder(frames[MIRROR_ID])
            end
        end
    end
end

-- both modules call this from OnFirstLoad, before any bar reads its settings
local upgraded = false

function Addon:UpgradeSettings()
    if upgraded then
        return
    end

    upgraded = true

    local db = Dominos.db:RegisterNamespace('CastBars')
    local dbVersion = db.global.version or 1

    if dbVersion ~= DB_VERSION then
        upgrade(dbVersion)
        db.global.version = DB_VERSION
    end
end
