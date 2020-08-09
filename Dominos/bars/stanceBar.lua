-- stanceBar - a bar for displaying class specific buttons for things like stances/forms/etc

local _, Addon = ...
local playerClass = select(2, UnitClass('player'))

-- don't bother loading the module if the player is currently playing something without a stance
if not (
	playerClass == 'DRUID'
	or playerClass == 'ROGUE'
	or (not Addon:IsBuild("classic") and playerClass == 'PRIEST')
	or (Addon:IsBuild("classic") and (playerClass == 'WARRIOR' or playerClass == 'PALADIN'))
) then
	return
end

local BindableButton = Addon.BindableButton


--[[ Button ]]--

local StanceButton = Addon:CreateClass('CheckButton')

do
	local unused = {}

	StanceButton.buttonType = 'SHAPESHIFTBUTTON'

	function StanceButton:New(id)
		local button = self:Restore(id) or self:Create(id)

		Addon.BindingsController:Register(button)
		Addon:GetModule('Tooltips'):Register(button)

		return button
	end

	function StanceButton:Create(id)
		local buttonName = ('StanceButton%d'):format(id)
		local button = self:Bind(_G[buttonName])

		if button then
			BindableButton:Register(button)

			Addon:GetModule('ButtonThemer'):Register(button, 'Class Bar')
		end

		return button
	end

	function StanceButton:Restore(id)
		local button = unused[id]

		if button then
			unused[id] = nil
			button:Show()

			return button
		end
	end

	--saving them thar memories
	function StanceButton:Free()
		unused[self:GetID()] = self

		self:SetParent(nil)
		self:Hide()

		Addon.BindingsController:Unregister(self)
		Addon:GetModule('Tooltips'):Unregister(self)
	end
end


--[[ Bar ]]--

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

function StanceBar:GetButton(index)
	return StanceButton:New(index)
end


--[[ Module ]]--

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
	end
end

function StanceBarModule:UpdateNumForms()
	if InCombatLockdown() then return end

	self.bar:UpdateNumButtons()
end
