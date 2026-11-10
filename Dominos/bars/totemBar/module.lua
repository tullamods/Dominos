if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

local _, Addon = ...
local TotemBarModule = Addon:NewModule('TotemBar', 'AceEvent-3.0')
local bar

function TotemBarModule:OnFirstLoad()
    local frame = MultiCastActionBarFrame
    local managed = frame.layoutParent and frame.layoutParent.showingFrames

    frame.ignoreFramePositionManager = true
    if managed then
        managed[frame] = nil
    end

    frame:SetParent(Addon.ShadowUIParent)
    frame:EnableMouse(false)

    -- its own events at least, shared button event frames still drive its buttons
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
    bar = Addon.TotemBar:New()

    self:RegisterEvent('SPELLS_CHANGED', 'Update')
    self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR', 'Update')
    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Update')
    self:RegisterEvent('SPELL_UPDATE_COOLDOWN', 'UpdateSpellCooldowns')
end

function TotemBarModule:Unload()
    self:UnregisterAllEvents()

    if bar then
        bar:Free()
        bar = nil
    end
end

function TotemBarModule:Update()
    if bar then
        bar:Update()
    end
end

function TotemBarModule:UpdateSpellCooldowns()
    if bar then
        bar:UpdateSpellCooldowns()
    end
end

