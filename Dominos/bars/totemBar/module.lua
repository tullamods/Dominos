if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

local _, Addon = ...
local TotemBarModule = Addon:NewModule('TotemBar', 'AceEvent-3.0')
local bars = {}

function TotemBarModule:OnFirstLoad()
    local frame = MultiCastActionBarFrame
    local managed = frame.layoutParent and frame.layoutParent.showingFrames

    frame.ignoreFramePositionManager = true
    if managed then
        managed[frame] = nil
    end

    frame:SetParent(Addon.ShadowUIParent)
    frame:EnableMouse(false)

    -- shared button event frames still drive its buttons
    frame:UnregisterAllEvents()

    for i = 1, NUM_MULTI_CAST_PAGES * NUM_MULTI_CAST_BUTTONS_PER_PAGE do
        _G['MultiCastActionButton' .. i]:UnregisterAllEvents()
    end

    for i = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE do
        _G['MultiCastSlotButton' .. i]:UnregisterAllEvents()
    end

    MultiCastSummonSpellButton:UnregisterAllEvents()
    MultiCastRecallSpellButton:UnregisterAllEvents()
end

function TotemBarModule:Load()
    self:LoadBars()

    self:RegisterEvent('SPELLS_CHANGED', 'Update')
    self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR', 'Update')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    self:RegisterEvent('SPELL_UPDATE_COOLDOWN')
    self:RegisterEvent('SPELL_UPDATE_USABLE')
    Addon.RegisterCallback(self, 'SPLIT_TOTEM_BARS_CHANGED')
end

function TotemBarModule:Unload()
    self:UnregisterAllEvents()
    Addon.UnregisterCallback(self, 'SPLIT_TOTEM_BARS_CHANGED')

    self:FreeBars()
    self.reloadBarsAfterCombat = nil
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function TotemBarModule:SPLIT_TOTEM_BARS_CHANGED()
    if InCombatLockdown() then
        self.reloadBarsAfterCombat = true
        return
    end

    self:ReloadBars()
end

function TotemBarModule:PLAYER_REGEN_ENABLED()
    if self.reloadBarsAfterCombat then
        self.reloadBarsAfterCombat = nil
        self:ReloadBars()
    else
        self:Update()
    end
end

function TotemBarModule:SPELL_UPDATE_COOLDOWN()
    self:ForSpellButtons('UpdateCooldown')
end

function TotemBarModule:SPELL_UPDATE_USABLE()
    self:ForSpellButtons('UpdateUsable')
end

--------------------------------------------------------------------------------
-- Bars
--------------------------------------------------------------------------------

function TotemBarModule:LoadBars()
    if not Addon:SplittingTotemBars() then
        bars[1] = Addon.TotemBar:New()
        return
    end

    for totemSet = 1, NUM_MULTI_CAST_PAGES do
        bars[totemSet] = Addon.TotemBar:New(totemSet)
    end
end

function TotemBarModule:FreeBars()
    for i = #bars, 1, -1 do
        bars[i]:Free()
        bars[i] = nil
    end
end

function TotemBarModule:ReloadBars()
    self:FreeBars()
    self:LoadBars()

    -- config mode's drag frames need new owners
    Addon.callbacks:Fire('ACTIONBARS_UPDATED')
end

function TotemBarModule:ForBars(method, ...)
    for _, bar in ipairs(bars) do
        bar[method](bar, ...)
    end
end

function TotemBarModule:ForSpellButtons(method)
    self:ForBars('ForSpellButtons', method)
end

function TotemBarModule:Update()
    self:ForBars('Update')
end
