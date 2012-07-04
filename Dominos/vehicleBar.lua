--[[
	vehicleBar.lua
		A Dominos vehicle bar
--]]

--[[ Vehicle Bar ]]--

local VehicleBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.VehicleBar  = VehicleBar

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')
local buttons = {OverrideActionBarLeaveFrameLeaveButton, OverrideActionBarPitchFramePitchUpButton, OverrideActionBarPitchFramePitchDownButton}

function VehicleBar:New()
	local f = self.super.New(self, 'vehicle', L.TipVehicleBar)
	f:SkinButtons()
	f:LoadButtons()
	f:Layout()
	f:SetScript('OnEvent', f.OnEvent)
	f:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR')
	f:RegisterEvent('UNIT_ENTERED_VEHICLE')

	return f
end


function VehicleBar:OnEvent(event, ...)
	if event == 'UPDATE_VEHICLE_ACTIONBAR' or event == 'UNIT_ENTERED_VEHICLE' then
		self:UpdateButtonVisibility()
	end
end

function VehicleBar:UpdateButtonVisibility()
	if IsVehicleAimAngleAdjustable() then
		_G['OverrideActionBarPitchFramePitchUpButton']:Show()
		_G['OverrideActionBarPitchFramePitchDownButton']:Show()
	else
		_G['OverrideActionBarPitchFramePitchUpButton']:Hide()
		_G['OverrideActionBarPitchFramePitchDownButton']:Hide()
	end

	if CanExitVehicle() then
		_G['OverrideActionBarLeaveFrameLeaveButton']:Show()
	else
		_G['OverrideActionBarLeaveFrameLeaveButton']:Hide()
	end
end

function VehicleBar:SkinButtons()
	self:ApplySkin('PitchFramePitchUpButton')
	self:ApplySkin('PitchFramePitchDownButton')
	self:ApplySkin('LeaveFrameLeaveButton')
end

function VehicleBar:ApplySkin(frameName)
	local skin = self:GetSkinData(frameName)
	local frame = _G['OverrideActionBar' .. frameName]
	frame:SetWidth(30)
	frame:SetHeight(30)

	if skin.normalTexture then
		frame:GetNormalTexture():SetTexture(skin.normalTexture);
		frame:GetNormalTexture():SetTexCoord(unpack(skin.normalTexCoord));
	end

	if skin.pushedTexture then
		frame:GetPushedTexture():SetTexture(skin.pushedTexture);
		frame:GetPushedTexture():SetTexCoord(unpack(skin.pushedTexCoord));
	end

	if skin.texture then
		frame:SetTexture(skin.texture);
		frame:SetTexCoord(unpack(skin.texCoord))
	end
end

function VehicleBar:GetSkinData(frameName)
	if frameName == 'PitchFramePitchUpButton' then
		return {	--Pitch up button
			height = 36,
			width = 38,
			point = "BOTTOMLEFT",
			xOfs = 146,
			yOfs = 41,
			normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-Pitch-Up]],
			normalTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
			pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-Pitch-Down]],
			pushedTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
			pitchHidden = 1,
		}
	elseif frameName == 'PitchFramePitchDownButton' then
		return {	--Pitch up button
			height = 36,
			width = 38,
			point = "BOTTOMLEFT",
			xOfs = 146,
			yOfs = 3,
			normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Up]],
			normalTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
			pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-PitchDown-Down]],
			pushedTexCoord = { 0.21875, 0.765625, 0.234375, 0.78125 },
			pitchHidden = 1,
		}
	elseif frameName == 'LeaveFrameLeaveButton' then
		return {	--Leave button
			height = 47,
			width = 50,
			point = "BOTTOMRIGHT",
			xOfs = -148,
			yOfs = 18,
			normalTexture = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]],
			normalTexCoord = { 0.140625, 0.859375, 0.140625, 0.859375 },
			pushedTexture = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]],
			pushedTexCoord = { 0.140625, 0.859375, 0.140625, 0.859375 },
		}
	end
end

function VehicleBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0
	}
end

function VehicleBar:NumButtons()
	return #buttons
end

function VehicleBar:AddButton(i)
	local b = buttons[i]
	b:SetParent(self.header)
	b:Show()

	self.buttons[i] = b
end

function VehicleBar:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	b:Hide()

	self.buttons[i] = nil
end

function VehicleBar:GetShowStates()
	return '[vehicleui]show;hide'
end