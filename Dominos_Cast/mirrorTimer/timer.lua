-- breath, fatigue, feign death and the like
local _, Addon = ...

local MirrorTimer = {}

---@param container table the mirror timer bar it belongs to
function MirrorTimer:Create(container)
    local timer = Mixin(CreateFrame('Frame', nil, container), Addon.TimerMixin, MirrorTimer)

    timer.container = container
    timer:CreateParts()

    timer.onTimerUpdate = function()
        timer:UpdateValue()
    end

    return timer
end

---@param timerName string
---@param value number
---@param maxValue number
---@param scale number
---@param paused number
---@param timerLabel string
function MirrorTimer:Setup(timerName, value, maxValue, scale, paused, timerLabel)
    self.timerName = timerName
    self.maxValue = maxValue / 1000
    -- draining shows what's left, refilling how long until full
    self.countdown = scale < 0

    self.label:SetText(timerLabel)
    self.fill:SetMinMaxValues(0, self.maxValue)
    self:SetFillColor(self.container:GetTimerColor(timerName))
    self:SetValue(value / 1000)
    self:SetPaused(paused)

    self:FadeIn()
end

function MirrorTimer:Clear()
    self.fill:SetScript('OnUpdate', nil)
    self.timerName = nil

    self:FadeOut(self.FINISH_FADE_DELAY)
end

function MirrorTimer:SetPaused(paused)
    if paused > 0 then
        self.fill:SetScript('OnUpdate', nil)
    else
        self.fill:SetScript('OnUpdate', self.onTimerUpdate)
    end
end

function MirrorTimer:IsInUse()
    return self.timerName ~= nil
end

-- the game doesn't say when a timer changes pace, so poll it
function MirrorTimer:UpdateValue()
    local progress = self.timerName and GetMirrorTimerProgress(self.timerName)

    self:SetValue((progress or 0) / 1000)
end

function MirrorTimer:SetValue(value)
    self.fill:SetValue(value)
    self:UpdateTimeText()
end

-- runs every frame, so skip the text when it's hidden
function MirrorTimer:UpdateTimeText()
    if not (self.timerName and self.time:IsShown()) then
        return
    end

    local value = self.fill:GetValue()

    if self.countdown then
        self.time:SetFormattedText('%.1f', value)
    else
        self.time:SetFormattedText('%.1f', math.max(self.maxValue - value, 0))
    end
end

-- paused timers (previews included) don't tick, so fill in the text now
function MirrorTimer:SetTextShown(showLabel, showTime)
    Addon.TimerMixin.SetTextShown(self, showLabel, showTime)
    self:UpdateTimeText()
end

-- so the stack can close the gap
function MirrorTimer:OnFadedOut()
    self.container:UpdateTimerOrder()
end

-- exports
Addon.MirrorTimer = MirrorTimer
