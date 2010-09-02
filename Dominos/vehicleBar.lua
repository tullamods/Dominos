--[[
	vehicleBar.lua
		A Dominos vehicle bar
--]]

--[[
	Copyright (c) 2008-2009 Jason Greer
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

		* Redistributions of source code must retain the above copyright notice,
		  this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the
		  documentation and/or other materials provided with the distribution.
		* Neither the name of the author nor the names of its contributors may
		  be used to endorse or promote products derived from this software
		  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
	LIABLE FORANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
--]]


--[[ Vehicle Bar ]]--

local VehicleBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.VehicleBar  = VehicleBar

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')
local buttons = {VehicleMenuBarLeaveButton, VehicleMenuBarPitchUpButton, VehicleMenuBarPitchDownButton}

function VehicleBar:New()
	local f = self.super.New(self, 'vehicle', L.TipVehicleBar)
	f:SkinButtons()
	f:LoadButtons()
	f:Layout()
	f:SetScript('OnEvent', f.OnEvent)
	f:RegisterEvent('UNIT_ENTERED_VEHICLE')
	f:RegisterEvent('UNIT_ENTERING_VEHICLE')

	return f
end


function VehicleBar:OnEvent(event, arg1)
	if event == 'UNIT_ENTERED_VEHICLE' then
		if arg1 == 'player' then
			self:UpdateButtonVisibility()
		end
	end
end

function VehicleBar:UpdateButtonVisibility()
	if IsVehicleAimAngleAdjustable() then
		_G['VehicleMenuBarPitchUpButton']:Show()
		_G['VehicleMenuBarPitchDownButton']:Show()
	else
		_G['VehicleMenuBarPitchUpButton']:Hide()
		_G['VehicleMenuBarPitchDownButton']:Hide()
	end

	if CanExitVehicle() then
		_G['VehicleMenuBarLeaveButton']:Show()
	else
		_G['VehicleMenuBarLeaveButton']:Hide()
	end
end

function VehicleBar:SkinButtons()
	self:ApplySkin('PitchUpButton')
	self:ApplySkin('PitchDownButton')
	self:ApplySkin('LeaveButton')
end

function VehicleBar:ApplySkin(frameName)
	local skin = self:GetSkinData(frameName)
	local frame = _G['VehicleMenuBar' .. frameName]
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
	if frameName == 'PitchUpButton' then
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
	elseif frameName == 'PitchDownButton' then
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
	elseif frameName == 'LeaveButton' then
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
		y = 0,
		numButtons = #buttons
	}
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
	return '[target=vehicle,exists]show;hide'
end