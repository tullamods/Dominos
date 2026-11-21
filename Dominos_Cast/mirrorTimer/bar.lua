-- a game timer takes the first free timer and keeps it until it stops
local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')

local NUM_TIMERS = MIRRORTIMER_NUMTIMERS or #MirrorTimerContainer.mirrorTimers

local DEFAULT_COLORS = {
    EXHAUSTION = CreateColorFromRGBAHexString('FFE600FF'),
    BREATH = CreateColorFromRGBAHexString('0080FFFF'),
    DEATH = CreateColorFromRGBAHexString('FFB300FF'),
    FEIGNDEATH = CreateColorFromRGBAHexString('00FF00FF'),
    UNKNOWN = CreateColor(1, 1, 1, 1)
}

-- shown while the menu is open, so there's something to style
local PREVIEW_TIMERS = {
    { 'BREATH', BREATH_LABEL or 'Breath' },
    { 'EXHAUSTION', EXHAUSTION_LABEL or 'Fatigue' },
    { 'FEIGNDEATH', 'Feign Death' }
}

local MirrorTimerBar = Dominos:CreateClass('Frame', Dominos.Frame)
Mixin(MirrorTimerBar, Addon.TimerBarSettingsMixin)

MirrorTimerBar.DEFAULT_COLORS = DEFAULT_COLORS

MirrorTimerBar.NUM_TIMERS = NUM_TIMERS

function MirrorTimerBar:New()
    return MirrorTimerBar.proto.New(self, 'mirror')
end

function MirrorTimerBar:GetDisplayName()
    return L.MirrorTimersDisplayName
end

-- new bars only. changing one means a migrations.lua step that writes the old
-- value for existing bars
function MirrorTimerBar:GetDefaults()
    return {
        point = 'TOP',
        x = 0,
        y = -96,
        padW = 1,
        padH = 1,
        orientation = 'VERTICAL',
        spacing = 11,
        width = 194,
        height = 14,
        displayLayer = 'HIGH',
        texture = 'Blizzard',
        showBorder = true,
        border = 'Blizzard Tooltip',
        borderSize = 16,
        showLabel = true,
        showTime = false
    }
end

function MirrorTimerBar:CanSetShowStates()
    return false
end

MirrorTimerBar:Extend('OnCreate', function(self)
    local timers = {}

    for i = 1, NUM_TIMERS do
        timers[i] = Addon.MirrorTimer:Create(self)
    end

    self.timers = timers
end)

MirrorTimerBar:Extend('OnLoadSettings', function(self)
    self:UpdateTimerBarStyle()
end)

function MirrorTimerBar:GetTimers()
    return self.timers
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

local function getStackLength(count, timerLength, spacing)
    return math.max(count * (timerLength + spacing) - spacing, 0)
end

-- sized for every timer so the bar doesn't jump while placing it. spacing is
-- between borders, padding outside them
function MirrorTimerBar:Layout()
    local width = self:GetDesiredWidth()
    local height = self:GetDesiredHeight()
    local padW, padH = self:GetPadding()
    local outset = self:GetBorderOutset()
    local spacing = self:GetSpacing()
    local vertical = self:GetOrientation() == 'VERTICAL'
    local timerLength = (vertical and height or width) + 2 * outset

    local fullLength = getStackLength(#self.timers, timerLength, spacing)

    if vertical then
        self:TrySetSize(width + 2 * (padW + outset), fullLength + 2 * padH)
    else
        self:TrySetSize(fullLength + 2 * padW, height + 2 * (padH + outset))
    end

    local showing = {}
    for _, timer in ipairs(self.timers) do
        timer:SetSize(width, height)

        if timer:IsOnScreen() then
            showing[#showing + 1] = timer
        else
            timer:ClearAllPoints()
            timer:SetPoint('CENTER')
        end
    end

    -- from the first timer's center, relative to the bar's
    local start = (getStackLength(#showing, timerLength, spacing) - timerLength) / 2

    for i, timer in ipairs(showing) do
        local offset = start - (i - 1) * (timerLength + spacing)

        timer:ClearAllPoints()

        if vertical then
            timer:SetPoint('CENTER', 0, offset)
        else
            timer:SetPoint('CENTER', -offset, 0)
        end
    end
end

function MirrorTimerBar:UpdateTimerOrder()
    self:Layout()
end

---@param orientation 'VERTICAL'|'HORIZONTAL'
function MirrorTimerBar:SetOrientation(orientation)
    self.sets.orientation = orientation
    self:Layout()
end

function MirrorTimerBar:GetOrientation()
    return self.sets.orientation
end

function MirrorTimerBar:SetSpacing(spacing)
    self.sets.spacing = spacing
    self:Layout()
end

function MirrorTimerBar:GetSpacing()
    return self.sets.spacing
end

--------------------------------------------------------------------------------
-- Timers
--------------------------------------------------------------------------------

function MirrorTimerBar:GetTimer(timerName)
    for _, timer in ipairs(self.timers) do
        if timer.timerName == timerName then
            return timer
        end
    end
end

-- real timers win over previews
function MirrorTimerBar:GetFreeTimer()
    for _, timer in ipairs(self.timers) do
        if not timer:IsInUse() then
            return timer
        end
    end

    for _, timer in ipairs(self.timers) do
        if timer.preview then
            return timer
        end
    end
end

-- a game timer keeps its slot, like blizzard's
function MirrorTimerBar:StartTimer(timerName, value, maxValue, scale, paused, timerLabel)
    local timer = self:GetTimer(timerName) or self:GetFreeTimer()

    if timer then
        timer.preview = nil
        timer:Setup(timerName, value, maxValue, scale, paused, timerLabel)
        self:UpdateTimerOrder()
    end
end

function MirrorTimerBar:StopTimer(timerName)
    local timer = self:GetTimer(timerName)

    if timer then
        timer:Clear()
    end
end

function MirrorTimerBar:PauseTimer(timerName, paused)
    local timer = self:GetTimer(timerName)

    if timer then
        timer:SetPaused(paused)
    end
end

function MirrorTimerBar:UpdateTimers()
    local active = {}

    for i = 1, NUM_TIMERS do
        local timerName, value, maxValue, scale, paused, timerLabel = GetMirrorTimerInfo(i)

        -- it may return nothing
        if timerName and timerName ~= 'UNKNOWN' then
            active[timerName] = true
            self:StartTimer(timerName, value, maxValue, scale, paused, timerLabel)
        end
    end

    for _, timer in ipairs(self.timers) do
        if timer:IsInUse() and not (active[timer.timerName] or timer.preview) then
            timer:Clear()
        end
    end
end

---@return ColorMixin
function MirrorTimerBar:GetTimerColor(timerName)
    return self:GetColor(DEFAULT_COLORS[timerName] and timerName or 'UNKNOWN')
end

function MirrorTimerBar:UpdateColors()
    for _, timer in ipairs(self.timers) do
        if timer:IsInUse() then
            timer:SetFillColor(self:GetTimerColor(timer.timerName))
        end
    end
end

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

-- timers are found by name, so previews can't repeat
function MirrorTimerBar:GetUnusedPreviewTimer()
    for _, preview in ipairs(PREVIEW_TIMERS) do
        if not self:GetTimer(preview[1]) then
            return unpack(preview)
        end
    end
end

function MirrorTimerBar:OnMenuShown()
    for _, timer in ipairs(self.timers) do
        if not timer:IsInUse() then
            local timerName, timerLabel = self:GetUnusedPreviewTimer()

            if timerName then
                timer:Setup(timerName, random(20, 60) * 1000, 60000, -1, 1, timerLabel)
                timer.preview = true
            end
        end
    end

    self:UpdateTimerOrder()
end

function MirrorTimerBar:OnMenuHidden()
    for _, timer in ipairs(self.timers) do
        if timer.preview then
            timer.preview = nil
            timer:Clear()
        end
    end

    self:UpdateTimers()
end

-- exports
Addon.MirrorTimerBar = MirrorTimerBar
