local Addon = _G[...]

--[[ The Bar ]]--

local VehicleBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function VehicleBar:New()
	local frame = VehicleBar.proto.New(self, 'vehicle')

	frame.header:SetAttribute('_onstate-taxi', [[
		self:RunAttribute('updateVehicleButton')
	]])

	frame.header:SetAttribute('_onstate-canexitvehicle', [[
		self:RunAttribute('updateVehicleButton')
	]])

	frame.header:SetAttribute('updateVehicleButton', [[
		local isVisible = self:GetAttribute('state-taxi') == 1
		 				  or self:GetAttribute('state-canexitvehicle') == 1

		self:SetAttribute('state-display', isVisible and 'show' or 'hide')
	]])

	RegisterStateDriver(frame.header, 'canexitvehicle', '[canexitvehicle]1;0')

	frame:UpdateOnTaxi()
	frame:LoadButtons()
	frame:Layout()

	return frame
end

function VehicleBar:UpdateOnTaxi()
	self.header:SetAttribute('state-taxi', UnitOnTaxi('player') and 1 or 0)
end

function VehicleBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function VehicleBar:GetShowStates()
	return nil
end

function VehicleBar:NumButtons()
	return 1
end

function VehicleBar:AddButton(index)
	local button = self:GetLeaveButton()
	button:UnregisterAllEvents()

	if button then
		button:SetParent(self.header)
		button:Show()

		self.buttons[index] = button
	end
end

function VehicleBar:GetLeaveButton()
	return _G['MainMenuBarVehicleLeaveButton']
end


--[[ Controller ]]--

local VehicleBarController = Addon:NewModule('VehicleBar', 'AceEvent-3.0')

function VehicleBarController:Load()
	self.frame = VehicleBar:New()

	self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'UpdateOnTaxi')
	self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR', 'UpdateOnTaxi')
	self:RegisterEvent('UNIT_ENTERED_VEHICLE', 'UpdateOnTaxi')
	self:RegisterEvent('UNIT_EXITED_VEHICLE', 'UpdateOnTaxi')
	self:RegisterEvent('VEHICLE_UPDATE', 'UpdateOnTaxi')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateOnTaxi')
end

function VehicleBarController:Unload()
	self:UnregisterAllEvents()

	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

function VehicleBarController:UpdateOnTaxi()
	if InCombatLockdown() then return end

	self.frame:UpdateOnTaxi()
end