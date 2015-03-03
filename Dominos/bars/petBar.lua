-- A bar that contains pet actions


--[[ Globals ]]--

local Addon = _G[...]
local KeyBound = LibStub('LibKeyBound-1.0')

local format = string.format
local unused = {}


--[[ Pet Button ]]--

local PetButton = Addon:CreateClass('CheckButton', Addon.BindableButton)

function PetButton:New(id)
	local b = self:Restore(id) or self:Create(id)

	Addon.BindingsController:Register(b)
	Addon:GetModule('Tooltips'):Register(b)

	return b
end

function PetButton:Create(id)
	local b = self:Bind(_G['PetActionButton' .. id])
	b.buttonType = 'BONUSACTIONBUTTON'

	b:HookScript('OnEnter', self.OnEnter)
	b:Skin()

	return b
end

--if we have button facade support, then skin the button that way
--otherwise, apply the dominos style to the button to make it pretty
function PetButton:Skin()
	if not Addon:Masque('Pet Bar', self) then
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
	unused[self:GetID()] = self

	Addon.BindingsController:Unregister(self)
	Addon:GetModule('Tooltips'):Unregister(self)

	self:SetParent(nil)
	self:Hide()
end

--keybound support
function PetButton:OnEnter()
	KeyBound:Set(self)
end

--override keybinding display
hooksecurefunc('PetActionButton_SetHotkeys', PetButton.UpdateHotkey)


--[[ Pet Bar ]]--

local PetBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PetBar:New()
	return PetBar.proto.New(self, 'pet')
end

function PetBar:GetShowStates()
	return '[@pet,exists,nopossessbar]show;hide'
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

function PetBar:GetButton(index)
	return PetButton:New(index)
end

--[[ keybound support ]]--

function PetBar:KEYBOUND_ENABLED()
	self.header:SetAttribute('state-visibility', 'display')

	for _, button in pairs(self.buttons) do
		button:Show()
	end
end

function PetBar:KEYBOUND_DISABLED()
	self:UpdateShowStates()

	local petBarShown = PetHasActionBar()

	for _, button in pairs(self.buttons) do
		if petBarShown and GetPetActionInfo(button:GetID()) then
			button:Show()
		else
			button:Hide()
		end
	end
end

--[[ controller good times ]]--

local PetBarController = Addon:NewModule('PetBar')

function PetBarController:Load()
	self.frame = PetBar:New()
end

function PetBarController:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end
