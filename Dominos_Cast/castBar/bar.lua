local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')

-- help and harm replace cast and channel with contextual coloring on
local DEFAULT_COLORS = {
    cast = CreateColorFromRGBAHexString('FFB300FF'),
    channel = CreateColorFromRGBAHexString('00FF00FF'),
    uninterruptible = CreateColorFromRGBAHexString('A1A1A1FF'),
    failed = CreateColorFromRGBAHexString('D94040FF'),
    help = CreateColorFromRGBAHexString('4FC778FF'),
    harm = CreateColorFromRGBAHexString('A15CF0FF'),
    tradeskill = CreateColorFromRGBAHexString('0080FFFF')
}

-- placeholder is the old samwise icon, now a wow logo
local PLACEHOLDER_ICON = 136235
local CRAFTING_ICON = 136243

local function getSpellReaction(spellID)
    if spellID then
        if C_Spell.IsSpellHelpful(spellID) then
            return 'help'
        end

        if C_Spell.IsSpellHarmful(spellID) then
            return 'harm'
        end
    end
end

-- channel GUIDs can be nil. not spell ID, that names the spell not the cast
local function getCastID(castGUID, castBarID)
    return castBarID or castGUID or 'nil'
end

local function getSeconds(startTimeMs, endTimeMs)
    return (endTimeMs - startTimeMs) / 1000
end

local function getCastIcon(spellID, textureID, isTradeskill)
    if isTradeskill and C_TradeSkillUI.GetRecipeInfo then
        local recipe = C_TradeSkillUI.GetRecipeInfo(spellID)
        if recipe and recipe.icon then
            return recipe.icon
        end
    end

    if canaccessvalue(textureID) and textureID == PLACEHOLDER_ICON then
        return CRAFTING_ICON
    end

    return textureID
end

local CastBar = Dominos:CreateClass('Frame', Dominos.Frame)
Mixin(CastBar, Addon.TimerBarSettingsMixin)

CastBar.DEFAULT_COLORS = DEFAULT_COLORS

function CastBar:New(id, units, ...)
    local bar = CastBar.proto.New(self, id, ...)

    bar.units = units
    bar:RegisterEvents()
    bar:SyncCast()

    return bar
end

function CastBar:GetDisplayName()
    return L.CastBarDisplayName
end

-- new bars only. changing one means a migrations.lua step that writes the old
-- value for existing bars. no font or latency padding follows the stock font
-- and the spell queue window
function CastBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 0,
        y = 30,
        padW = 1,
        padH = 1,
        width = 228,
        height = 20,
        displayLayer = 'HIGH',
        texture = 'Blizzard',
        showBorder = true,
        border = 'Blizzard Tooltip',
        borderSize = 16,
        showLabel = true,
        showTime = true,
        showIcon = false,
        showLatency = true,
        showSpark = true,
        useSpellReactionColors = true
    }
end

function CastBar:CanSetShowStates()
    return false
end

-- the cast bar always shows with the override and pet battle UIs
function CastBar:CanShowInOverrideUI()
    return false
end

function CastBar:CanShowInPetBattleUI()
    return false
end

function CastBar:ShowingInOverrideUI()
    return true
end

function CastBar:ShowingInPetBattleUI()
    return true
end

CastBar:Extend('OnCreate', function(self)
    self:SetScript('OnEvent', self.OnEvent)

    self.timer = Addon.CastTimer:Create(self)
    self.timers = { self.timer }

    -- reused by empowers and the demo
    self.duration = C_DurationUtil.CreateDuration()
    self.stageEnds = {}
end)

CastBar:Extend('OnRelease', function(self)
    self:UnregisterAllEvents()

    -- freed with its menu open, like on a profile change
    self.menuShown = nil
    self:CancelDemo()
end)

CastBar:Extend('OnLoadSettings', function(self)
    self:UpdateTimerBarStyle()
end)

function CastBar:ApplyTimerBarStyle(timer)
    Addon.TimerBarSettingsMixin.ApplyTimerBarStyle(self, timer)

    timer:SetIconShown(self:ShowingIcon())
    timer:SetSparkShown(self:ShowingSpark())
end

function CastBar:GetTimers()
    return self.timers
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

-- border then padding go around the timer, so neither changes its size
function CastBar:Layout()
    local padW, padH = self:GetPadding()
    local outset = self:GetBorderOutset()
    local insetW = padW + outset
    local insetH = padH + outset
    local timer = self.timer

    self:TrySetSize(self:GetDesiredWidth() + 2 * insetW, self:GetDesiredHeight() + 2 * insetH)

    timer:ClearAllPoints()
    timer:SetPoint('TOPLEFT', insetW, -insetH)
    timer:SetPoint('BOTTOMRIGHT', -insetW, insetH)
    timer:SetTimerSize(self:GetDesiredWidth(), self:GetDesiredHeight())

    -- drawn to the fill's width
    self:UpdateLatency()
end

--------------------------------------------------------------------------------
-- Game Events
--------------------------------------------------------------------------------

function CastBar:OnEvent(event, ...)
    local func = self[event]

    if func then
        func(self, event, ...)
    end
end

function CastBar:RegisterEvents()
    local function registerUnitEvents(...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_DELAYED', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_FAILED_QUIET', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_FAILED', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_INTERRUPTED', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_INTERRUPTIBLE', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_NOT_INTERRUPTIBLE', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_START', ...)
        self:RegisterUnitEvent('UNIT_SPELLCAST_STOP', ...)

        if Dominos:IsGameType('standard') then
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_START', ...)
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_STOP', ...)
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_UPDATE', ...)
        end
    end

    registerUnitEvents(unpack(self.units))
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function CastBar:IsCurrentCast(castGUID, castBarID)
    return getCastID(castGUID, castBarID) == self.castID
end

function CastBar:BeginCast(unit, castGUID, castBarID)
    self.castID = getCastID(castGUID, castBarID)
    self.unit = unit
end

-- picks up a cast that started before the bar existed, or before a loading
-- screen, like after a reload
function CastBar:SyncCast()
    for _, unit in ipairs(self.units) do
        local name, _, _, _, _, _, castGUID, _, _, castBarID = UnitCastingInfo(unit)
        if name then
            self:BeginCast(unit, castGUID, castBarID)
            self:UpdateCasting()
            return
        end

        local channelName, _, _, _, _, _, _, _, isEmpowered, _, channelBarID = UnitChannelInfo(unit)
        if channelName then
            self:BeginCast(unit, nil, channelBarID)

            if isEmpowered then
                self:UpdateEmpowering()
            else
                self:UpdateChanneling()
            end

            return
        end
    end
end

function CastBar:PLAYER_ENTERING_WORLD()
    self:SyncCast()
end

function CastBar:UNIT_SPELLCAST_START(event, unit, castGUID, spellID, castBarID)
    self:BeginCast(unit, castGUID, castBarID)
    self:UpdateCasting()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, castGUID, spellID, castBarID)
    self:BeginCast(unit, castGUID, castBarID)
    self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_EMPOWER_START(event, unit, castGUID, spellID, castBarID)
    self:BeginCast(unit, castGUID, castBarID)
    self:UpdateEmpowering()
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit, castGUID, spellID, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:UpdateCasting()
    end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, castGUID, spellID, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:UpdateChanneling()
    end
end

function CastBar:UNIT_SPELLCAST_EMPOWER_UPDATE(event, unit, castGUID, spellID, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:UpdateEmpowering()
    end
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellID, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:Finish()
    end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, castGUID, spellID, interruptedBy, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:Finish()
    end
end

function CastBar:UNIT_SPELLCAST_EMPOWER_STOP(event, unit, castGUID, spellID, complete, interruptedBy, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:Finish()
    end
end

function CastBar:UNIT_SPELLCAST_FAILED(event, unit, castGUID, spellID, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:Fail(FAILED)
    end
end

CastBar.UNIT_SPELLCAST_FAILED_QUIET = CastBar.UNIT_SPELLCAST_FAILED

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, castGUID, spellID, interruptedBy, castBarID)
    if self:IsCurrentCast(castGUID, castBarID) then
        self:Fail(INTERRUPTED)
    end
end

function CastBar:UNIT_SPELLCAST_INTERRUPTIBLE(event, unit)
    if unit == self.unit and self:IsCasting() then
        self.uninterruptible = nil
        self:UpdateColors()
    end
end

function CastBar:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(event, unit)
    if unit == self.unit and self:IsCasting() then
        self.uninterruptible = true
        self:UpdateColors()
    end
end

--------------------------------------------------------------------------------
-- Casts
--------------------------------------------------------------------------------

function CastBar:IsCasting()
    local state = self.state

    return state == 'casting' or state == 'channeling' or state == 'empowering'
end

function CastBar:SetCast(state, spellID, notInterruptible, isTradeskill, total)
    self.state = state
    self.reaction = getSpellReaction(spellID)
    self.uninterruptible = notInterruptible or nil
    self.tradeskill = isTradeskill or nil
    self.castTotal = total
end

function CastBar:UpdateCasting()
    local name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, _, notInterruptible, spellID = UnitCastingInfo(self.unit)
    if not name then
        return
    end

    self:SetCast('casting', spellID, notInterruptible, isTradeskill, getSeconds(startTimeMs, endTimeMs))

    local icon = getCastIcon(spellID, textureID, isTradeskill)

    self.timer:StartCast(displayName, icon, UnitCastingDuration(self.unit), Enum.StatusBarTimerDirection.ElapsedTime)
    self:UpdateColors()
    self:UpdateLatency()
end

-- channels drain instead of fill
function CastBar:UpdateChanneling()
    local name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, notInterruptible, spellID = UnitChannelInfo(self.unit)
    if not name then
        return
    end

    self:SetCast('channeling', spellID, notInterruptible, isTradeskill, getSeconds(startTimeMs, endTimeMs))

    local icon = getCastIcon(spellID, textureID, isTradeskill)

    self.timer:StartCast(displayName, icon, UnitChannelDuration(self.unit), Enum.StatusBarTimerDirection.RemainingTime)
    self:UpdateColors()
    self:UpdateLatency()
end

-- no duration api covers the hold at max
function CastBar:UpdateEmpowering()
    local unit = self.unit
    local name, displayName, textureID, startTimeMs, endTimeMs, _, notInterruptible, spellID, _, numStages = UnitChannelInfo(unit)
    if not name then
        return
    end

    local total = getSeconds(startTimeMs, endTimeMs)
    local stageEnds

    if numStages > 0 then
        total = total + GetUnitEmpowerHoldAtMaxTime(unit) / 1000

        -- reused, empowers update a lot while held
        stageEnds = self.stageEnds
        wipe(stageEnds)

        local stageEnd = 0

        for stage = 1, numStages do
            stageEnd = stageEnd + GetUnitEmpowerStageDuration(unit, stage - 1) / 1000
            stageEnds[stage] = stageEnd
        end
    end

    self:SetCast('empowering', spellID, notInterruptible, nil, total)

    local duration = self.duration
    duration:SetTimeFromStart(startTimeMs / 1000, total)

    self.timer:StartCast(displayName, textureID, duration, Enum.StatusBarTimerDirection.ElapsedTime)

    if stageEnds then
        self.timer:StartEmpower(stageEnds, total)
    end

    self:UpdateColors()
    self:UpdateLatency()
end

-- a stop follows a fail, which shouldn't cut its hold short
function CastBar:Finish()
    if not (self:IsCasting() or self.state == 'demo') then
        return
    end

    self.state = 'stopped'
    self.timer:FinishCast()
end

function CastBar:Fail(reason)
    self.state = 'failed'
    self:UpdateColors()
    self.timer:FailCast(reason)
end

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

function CastBar:GetColorID()
    if self.state == 'failed' then
        return 'failed'
    end

    -- crafts win over all but failing, like blizzard's
    if self.tradeskill then
        return 'tradeskill'
    end

    if self.uninterruptible then
        return 'uninterruptible'
    end

    if self:UseSpellReactionColors() and self.reaction then
        return self.reaction
    end

    if self.state == 'channeling' then
        return 'channel'
    end

    return 'cast'
end

function CastBar:UpdateColors()
    local color = self:GetColor(self:GetColorID())

    self.timer:SetFillColor(color)
    self.timer:SetLatencyColor(color)
end

function CastBar:SetUseSpellReactionColors(enable)
    self.sets.useSpellReactionColors = enable and true or false
    self:UpdateColors()
end

function CastBar:UseSpellReactionColors()
    return self.sets.useSpellReactionColors
end

--------------------------------------------------------------------------------
-- Display toggles
--------------------------------------------------------------------------------

function CastBar:SetShowIcon(enable)
    self.sets.showIcon = enable and true or false
    self:UpdateTimerBarStyle()
end

function CastBar:ShowingIcon()
    return self.sets.showIcon
end

function CastBar:SetShowSpark(enable)
    self.sets.showSpark = enable and true or false
    self:UpdateTimerBarStyle()
end

function CastBar:ShowingSpark()
    return self.sets.showSpark
end

--------------------------------------------------------------------------------
-- Latency
--------------------------------------------------------------------------------

function CastBar:SetShowLatency(enable)
    self.sets.showLatency = enable and true or false
    self:UpdateLatency()
end

function CastBar:ShowingLatency()
    return self.sets.showLatency
end

-- channels and empowers don't show it
function CastBar:ShouldShowLatency()
    if not self:ShowingLatency() then
        return false
    end

    local state = self.state
    return state == 'casting' or state == 'demo'
end

function CastBar:UpdateLatency()
    if not self:ShouldShowLatency() then
        self.timer:SetLatency(nil)
        return
    end

    local _, _, latencyHome, latencyWorld = GetNetStats()
    local latency = math.max(latencyHome, latencyWorld, self:GetLatencyPadding()) / 1000

    self.timer:SetLatency(latency, self.castTotal)
end

-- nil follows the spell queue window
function CastBar:SetLatencyPadding(value)
    self.sets.latencyPadding = value
    self:UpdateLatency()
end

function CastBar:GetLatencyPadding()
    return self.sets.latencyPadding or tonumber(GetCVar('SpellQueueWindow')) or 0
end

-- exports
Addon.CastBar = CastBar
