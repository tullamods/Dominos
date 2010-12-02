--[[
	petBar.lua
		A Dominos pet bar
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
	b:UnregisterEvent('UPDATE_BINDINGS')
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
		button:RegisterEvent('UPDATE_BINDINGS')
		button:Show()
	end
end

function PetBar:KEYBOUND_DISABLED()
	self:UpdateShowStates()

	local petBarShown = PetHasActionBar()
	for _,button in pairs(self.buttons) do
		button:UnregisterEvent('UPDATE_BINDINGS')
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end