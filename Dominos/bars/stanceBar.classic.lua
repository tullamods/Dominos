if not StanceBarFrame then return end

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
    PRIEST = Addon:IsBuild('wrath'),
    ROGUE = true,
    SHAMAN = false,
    WARLOCK = Addon:IsBuild('wrath'),
    WARRIOR = true
})[UnitClassBase('player')] then
    return
end

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local StanceButtons = setmetatable({}, {
    __index = function(self, id)
        local button =  _G['StanceButton' .. id]

        if button then
            button.commandName = ("SHAPESHIFTBUTTON%d"):format(id)
            Addon.BindableButton:AddQuickBindingSupport(button)

            self[id] = button
        end

        return button
    end
})

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
    return StanceButtons[index]
end

function StanceBar:OnAttachButton(button)
    button:UpdateHotkeys()
    button:Show()

    Addon:GetModule('ButtonThemer'):Register(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Register(button)
end

function StanceBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Unregister(button)
end

StanceBar:Extend('OnAcquire', function(self) self:UpdateTransparent(true) end)

function StanceBar:OnSetAlpha()
    self:UpdateTransparent()
end

function StanceBar:UpdateTransparent(force)
    local transparent = self:GetAlpha() == 0
    if (self.transparent ~= transparent) or force then
        self.transparent = transparent

        if transparent then
            for _, button in pairs(self.buttons) do
                if button.cooldown:GetParent() ~= Addon.ShadowUIParent then
                    button.cooldown:SetParent(Addon.ShadowUIParent)
                end
            end
        else
            for _, button in pairs(self.buttons) do
                if button.cooldown:GetParent() ~= button then
                    button.cooldown:SetParent(button)
                end
            end
        end
    end
end

-- export
Addon.StanceBar = StanceBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local StanceBarModule = Addon:NewModule('StanceBar', 'AceEvent-3.0')

function StanceBarModule:Load()
    self.bar = StanceBar:New()

    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateNumForms')
    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateNumForms')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateNumForms')
end

function StanceBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
        self.bar = nil
    end
end

function StanceBarModule:UpdateNumForms()
    if InCombatLockdown() then
        return
    end

    self.bar:UpdateNumButtons()
end
