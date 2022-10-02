--------------------------------------------------------------------------------
-- Stance bar
-- Lets you move around the bar for displaying forms/stances/etc
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- test to see if the player has a stance bar
-- not the best looking, but I also don't need to keep it after I do the check
if not ({
    DEATHKNIGHT = Addon:IsBuild('wrath'),
    DEMONHUNTER = false,
    DRUID = true,
    HUNTER = false,
    MAGE = false,
    MONK = false,
    PALADIN = true,
    PRIEST = Addon:IsBuild('retail', 'wrath'),
    ROGUE = true,
    SHAMAN = false,
    WARLOCK = Addon:IsBuild('wrath'),
    WARRIOR = not Addon:IsBuild('retail')
})[UnitClassBase('player')] then
    return
end

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local function getOrCreateStanceButton(id)
    local name = ('%sStanceButton%d'):format(AddonName, id)

    local button = _G[name]
    if button then
        return button
    end

    button = CreateFrame('CheckButton', name, nil, 'StanceButtonTemplate')
    button.commandName = ('SHAPESHIFTBUTTON%d'):format(id)
    button:SetID(id)
    button:Hide()
    button:EnableMouseWheel(true)
    button.cooldown:SetDrawEdge(false)
    button:SetScript("OnUpdate", nil)

    Mixin(button, Addon.BindableButton)

    return button
end

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local StanceBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function StanceBar:New()
    return StanceBar.proto.New(self, 'class')
end

function StanceBar:GetDisplayName()
    return L.ClassBarDisplayName
end

function StanceBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2
    }
end

function StanceBar:NumButtons()
    return GetNumShapeshiftForms() or 0
end

function StanceBar:AcquireButton(index)
    return getOrCreateStanceButton(index)
end

function StanceBar:OnAttachButton(button)
    Addon:GetModule('ButtonThemer'):Register(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Register(button)
end

function StanceBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- export
Addon.StanceBar = StanceBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local StanceBarModule = Addon:NewModule('StanceBar', 'AceEvent-3.0')

function StanceBarModule:Load()
    self.bar = StanceBar:New()

    -- self:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", 'UpdateNumForms')
    self:RegisterEvent("PLAYER_REGEN_ENABLED", 'UpdateNumForms')
    self:RegisterEvent("UPDATE_BINDINGS")
    -- self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", 'UpdateStanceButtons')
    -- self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", 'UpdateStanceButtons')
    -- self:RegisterEvent("UPDATE_POSSESS_BAR", 'UpdateStanceButtons')
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", 'UpdateStanceButtons')
    -- self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", 'UpdateStanceButtons')
    self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", 'UpdateStanceButtons')
    -- self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", 'UpdateStanceButtons')
    self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", 'UpdateStanceButtons')
end

function StanceBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
    end
end

function StanceBarModule:UpdateNumForms()
    if not InCombatLockdown() then
        self.bar:UpdateNumButtons()
    end

    self:UpdateStanceButtons()
end

function StanceBarModule:UPDATE_BINDINGS()
    self.bar:ForButtons('UpdateHotkeys')
end

StanceBarModule.UpdateStanceButtons = Addon:Defer(function(self)
    local bar = self.bar
    if not bar then
        return
    end

	for i, button in pairs(bar.buttons) do
        local texture, isActive, isCastable = GetShapeshiftFormInfo(i)

        button:SetAlpha(texture and 1 or 0)

        local icon = button.icon

        icon:SetTexture(texture)

        if isCastable then
            icon:SetVertexColor(1.0, 1.0, 1.0)
        else
            icon:SetVertexColor(0.4, 0.4, 0.4)
        end

        local start, duration, enable = GetShapeshiftFormCooldown(i)
        if enable and enable ~= 0 and start > 0 and duration > 0 then
            button.cooldown:SetCooldown(start, duration)
        else
            button.cooldown:Clear()
        end

        button:SetChecked(isActive and true)
    end
end, 0.01, StanceBarModule)
