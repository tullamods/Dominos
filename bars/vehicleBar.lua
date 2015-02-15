local VehicleBar = Dominos:CreateClass('Frame', Dominos.ButtonBar)

function VehicleBar:New()
	local f = self.super.New(self, 'vehicle')

	f:LoadButtons()
	f:Layout()

	return f
end

function VehicleBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function VehicleBar:GetShowStates()
	return '[@vehicle,exists]show;hide'
end

function VehicleBar:NumButtons(f)
	return 1
end

function VehicleBar:AddButton(i)
	local b = self:GetLeaveButton()
	b:UnregisterAllEvents()
	if b then
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function VehicleBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

function VehicleBar:GetLeaveButton()
	return _G['MainMenuBarVehicleLeaveButton']
end

--[[ Controller ]]--

local VehicleBarController = Dominos:NewModule('VehicleBar')

function VehicleBarController:Load()
	self.frame = VehicleBar:New()
end

function VehicleBarController:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end
