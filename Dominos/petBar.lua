--[[
	petBar.lua
		A Dominos pet bar
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

--libs and omgspeed
local _G = getfenv(0)
local format = string.format

local KeyBound = LibStub('LibKeyBound-1.0')
local unused


--[[ Pet Button ]]--

local PetButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)

function PetButton:New(id)
	local b = self:Restore(id) or self:Create(id)
	b:UpdateHotkey()

	return b
end

function PetButton:Create(id)
	local b = self:Bind(_G['PetActionButton' .. id])
	b.buttonType = 'BONUSACTIONBUTTON'
	b:SetScript('OnEnter', self.OnEnter)
	b:Skin()

	return b
end

--if we have button facade support, then skin the button that way
--otherwise, apply the dominos style to the button to make it pretty
function PetButton:Skin()
	local LBF = LibStub('LibButtonFacade', true)
	if LBF then
		LBF:Group('Dominos', 'Pet Bar'):AddButton(self)
	else
		_G[self:GetName() .. 'Icon']:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
	end
end

function PetButton:Restore(id)
	local b = unused and unused[id]
	if b then
		unused[id] = nil
		b:Show()

		return b
	end
end

--saving them thar memories
function PetButton:Free()
	if not unused then unused = {} end
	unused[self:GetID()] = self

	self:SetParent(nil)
	self:Hide()
end

--keybound support
function PetButton:OnEnter()
	if Dominos:ShowTooltips() then
		PetActionButton_OnEnter(self)
	end
	KeyBound:Set(self)
end

--override keybinding display
hooksecurefunc('PetActionButton_SetHotkeys', PetButton.UpdateHotkey)


--[[ Pet Bar ]]--

local PetBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.PetBar  = PetBar

function PetBar:New()
	local f = self.super.New(self, 'pet')
	f:LoadButtons()
	f:Layout()

	return f
end

function PetBar:GetShowStates()
	return '[target=pet,exists,nobonusbar:5]show;hide'
end

function PetBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = -32,
		spacing = 6
	}
end

--dominos frame method overrides
function PetBar:NumButtons()
	return NUM_PET_ACTION_SLOTS
end

function PetBar:AddButton(i)
	local b = PetButton:New(i)
	b:SetParent(self.header)
	self.buttons[i] = b
end

function PetBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end


--[[ keybound  support ]]--

function PetBar:KEYBOUND_ENABLED()
	self.header:SetAttribute('state-visibility', 'display')

	for _,button in pairs(self.buttons) do
		button:Show()
	end
end

function PetBar:KEYBOUND_DISABLED()
	self:UpdateShowStates()

	local petBarShown = PetHasActionBar()
	for _,button in pairs(self.buttons) do
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end