-- a bar for displaying class specific buttons for things like stances/forms/etc
local _, Addon = ...

local HAS_STANCE_BAR = {
	WARRIOR = Addon:IsBuild('classic'),
	PALADIN = true,
	HUNTER = false,
	ROGUE = true,
	PRIEST = Addon:IsBuild('retail'),
	DEATHKNIGHT = false,
	SHAMAN = false,
	MAGE = false,
	WARLOCK = false,
	MONK = false,
	DRUID = true,
	DEMONHUNTER = false
}

-- don't bother loading the module if the player is currently playing something
-- without a stance
if not HAS_STANCE_BAR[UnitClassBase('player')] then
	return
end

-- buttons
local StanceButtons = {}

for id = 1, NUM_STANCE_SLOTS do
    local button = _G[('StanceButton%d'):format(id)]

    Addon.BindableButton:AddQuickBindingSupport(button, 'SHAPESHIFTBUTTON' .. id)

    StanceButtons[id] = button
end

-- bar
local StanceBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function StanceBar:New()
    return StanceBar.proto.New(self, 'class')
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
    Addon:GetModule('ButtonThemer'):Register(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Register(button)
end

function StanceBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, 'Class Bar')
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- module
local StanceBarModule = Addon:NewModule('StanceBar', 'AceEvent-3.0')

function StanceBarModule:Load()
    self.bar = StanceBar:New()

    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateNumForms')
    self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateNumForms')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateNumForms')
    self:RegisterEvent('UPDATE_BINDINGS')
end

function StanceBarModule:Unload()
    self:UnregisterAllEvents()

    if self.bar then
        self.bar:Free()
    end
end

function StanceBarModule:UpdateNumForms()
    if InCombatLockdown() then
        return
    end

    self.bar:UpdateNumButtons()
end

function StanceBarModule:UPDATE_BINDINGS()
    self.bar:ForButtons('UpdateHotkeys')
end
