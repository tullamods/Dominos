--------------------------------------------------------------------------------
-- Pet Bar
-- A movable action bar for pets
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

--------------------------------------------------------------------------------
-- Pet Button Setup
--------------------------------------------------------------------------------

local PetButtons = setmetatable({}, {
    __index = function(self, index)
        local button =  (PetActionBar and PetActionBar.actionButtons[index])
            or _G['PetActionButton' .. index]

        if button then
            button:SetAttribute("commandName", "BONUSACTIONBUTTON" .. index)
            Addon.BindableButton:AddQuickBindingSupport(button)

            self[index] = button
        end

        return button
    end
})

--------------------------------------------------------------------------------
-- The Pet Bar
--------------------------------------------------------------------------------

local PetBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PetBar:New()
    return PetBar.proto.New(self, 'pet')
end

function PetBar:GetDisplayName()
    return L.PetBarDisplayName
end

function PetBar:IsOverrideBar()
    -- TODO: make overrideBar a property of the bar itself instead of a global
    -- setting
    return Addon.db.profile.possessBar == self.id
end

function PetBar:UpdateOverrideBar()
    self:UpdateDisplayConditions()
end

if Addon:IsBuild('vanilla', 'tbc') then
    function PetBar:GetDisplayConditions()
        if self:IsOverrideBar() then
            return '[@pet,exists][bonusbar:5]show;hide'
        end
        return '[@pet,exists,nobonusbar:5]show;hide'
    end
else
    function PetBar:GetDisplayConditions()
        return '[@pet,exists,nopossessbar]show;hide'
    end
end

function PetBar:GetDefaults()
    return {
        point = 'CENTER',
        x = 0,
        y = -32,
        spacing = 6
    }
end

function PetBar:NumButtons()
    return NUM_PET_ACTION_SLOTS
end

function PetBar:AcquireButton(index)
    return PetButtons[index]
end

function PetBar:OnAttachButton(button, index)
    button.HotKey:SetAlpha(self:ShowingBindingText() and 1 or 0)
    button:SetShown(PetHasActionBar() and GetPetActionInfo(index))

    Addon:GetModule('ButtonThemer'):Register(button, 'Pet Bar')
    Addon:GetModule('Tooltips'):Register(button)
end

function PetBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, 'Pet Bar')
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- keybound events
function PetBar:KEYBOUND_ENABLED()
    self:ForButtons("Show")
end

function PetBar:KEYBOUND_DISABLED()
    local hasPetBar = PetHasActionBar()

    for _, button in pairs(self.buttons) do
        local show = hasPetBar and GetPetActionInfo(button.index or button:GetID())
        button:SetShown(show)
    end
end

PetBar:Extend('OnAcquire', function(self)
    self:UpdateTransparent(true)
end)

function PetBar:OnSetAlpha()
    self:UpdateTransparent()
end

function PetBar:UpdateTransparent(force)
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

-- binding text
function PetBar:SetShowBindingText(show)
    show = show and true

    if show == Addon.db.profile.showBindingText then
        self.sets.showBindingText = nil
    else
        self.sets.showBindingText = show
    end

    for _, button in pairs(self.buttons) do
        button.HotKey:SetAlpha(show and 1 or 0)
    end
end

function PetBar:ShowingBindingText()
    local result = self.sets.showBindingText

    if result == nil then
        result = Addon.db.profile.showBindingText
    end

    return result
end

function PetBar:OnCreateMenu(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local layoutPanel = menu:NewPanel(L.Layout)

    layoutPanel:NewCheckButton {
        name = L.ShowBindingText,
        get = function()
            return layoutPanel.owner:ShowingBindingText()
        end,
        set = function(_, enable)
            layoutPanel.owner:SetShowBindingText(enable)
        end
    }

    layoutPanel:AddLayoutOptions()

    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

--------------------------------------------------------------------------------
-- the module
--------------------------------------------------------------------------------

local PetBarModule = Addon:NewModule('PetBar')

function PetBarModule:Load()
    self.bar = PetBar:New()
end

function PetBarModule:Unload()
    if self.bar then
        self.bar:Free()
        self.bar = nil
    end
end

function PetBarModule:OnFirstLoad()
    (PetActionBar or PetActionBarFrame):SetParent(Addon.ShadowUIParent)
end