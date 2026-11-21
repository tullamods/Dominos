local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')

local MirrorTimerModule = Dominos:NewModule('MirrorTimer', 'AceEvent-3.0')

local bar

function MirrorTimerModule:Load()
    bar = Addon.MirrorTimerBar:New()

    self:RegisterEvent('MIRROR_TIMER_PAUSE')
    self:RegisterEvent('MIRROR_TIMER_START')
    self:RegisterEvent('MIRROR_TIMER_STOP')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateTimers')
    self:UpdateTimers()
end

function MirrorTimerModule:Unload()
    self:UnregisterAllEvents()

    if bar then
        bar:Free()
        bar = nil
    end
end

function MirrorTimerModule:OnFirstLoad()
    Addon:UpgradeSettings()

    local container = MirrorTimerContainer
    if container then
        container:UnregisterAllEvents()

        for _, timer in pairs(container.mirrorTimers) do
            timer:UnregisterAllEvents()
            timer:Hide()
        end
    else
        UIParent:UnregisterEvent('MIRROR_TIMER_START')

        for i = 1, Addon.MirrorTimerBar.NUM_TIMERS do
            local timer = _G['MirrorTimer' .. i]
            if timer then
                timer:UnregisterAllEvents()
                timer:Hide()
            end
        end
    end

    LibStub('LibSharedMedia-3.0').RegisterCallback(self, 'LibSharedMedia_Registered')
end

function MirrorTimerModule:LibSharedMedia_Registered(event, mediaType, key)
    if bar then
        bar:OnMediaRegistered(mediaType, key)
    end
end

function MirrorTimerModule:UpdateTimers()
    bar:UpdateTimers()
end

---@param event string
---@param timerName string
---@param value number
---@param maxValue number
---@param scale number
---@param paused number
---@param timerLabel string
function MirrorTimerModule:MIRROR_TIMER_START(event, timerName, value, maxValue, scale, paused, timerLabel)
    bar:StartTimer(timerName, value, maxValue, scale, paused, timerLabel)
end

---@param timerName string
---@param paused number
function MirrorTimerModule:MIRROR_TIMER_PAUSE(event, timerName, paused)
    bar:PauseTimer(timerName, paused)
end

---@param timerName string
function MirrorTimerModule:MIRROR_TIMER_STOP(event, timerName)
    bar:StopTimer(timerName)
end
