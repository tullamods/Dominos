if not _G.PossessBarFrame then return end

--------------------------------------------------------------------------------
-- Possess bar
-- Lets you move around the bar for displaying possess abilities
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local function getPossessButton(id)
    return _G[('PossessButton%d'):format(id)]
end

for id = 1, _G.NUM_POSSESS_SLOTS do
    local button = getPossessButton(id)

    -- add quick binding support
    Addon.BindableButton:AddQuickBindingSupport(button)
end

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local PossessBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PossessBar:New()
    return PossessBar.proto.New(self, 'possess')
end

function PossessBar:GetDisplayName()
    return L.PossessBarDisplayName
end

function PossessBar:GetDisplayConditions()
    return '[possessbar]show;hide'
end

function PossessBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2
    }
end

function PossessBar:NumButtons()
    return _G.NUM_POSSESS_SLOTS
end

function PossessBar:AcquireButton(index)
    return getPossessButton(index)
end

function PossessBar:OnAttachButton(button)
    button:UpdateHotkeys()

    Addon:GetModule('ButtonThemer'):Register(button, L.PossessBarDisplayName)
    Addon:GetModule('Tooltips'):Register(button)
end

function PossessBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, L.PossessBarDisplayName)
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- export
Addon.PossessBar = PossessBar

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

local PossessBarModule = Addon:NewModule('PossessBar', 'AceEvent-3.0')

function PossessBarModule:Load()
    self.bar = PossessBar:New()
    self:RegisterEvent('UPDATE_BINDINGS')
end

function PossessBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
    end
end

function PossessBarModule:UPDATE_BINDINGS()
    self.bar:ForButtons('UpdateHotkeys')
end
