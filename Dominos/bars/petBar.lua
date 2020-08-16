-- A bar that contains pet actions

local _, Addon = ...

-- a table that stores all the pet buttons
local PetButtons = {}

for i = 1, NUM_PET_ACTION_SLOTS do
	local button = _G[('PetActionButton%d'):format(i)]

	Addon.BindableButton:Inject(button, 'BONUSACTIONBUTTON')

	PetButtons[i] = button
end


-- the pet bar class
local PetBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function PetBar:New()
	return PetBar.proto.New(self, 'pet')
end

if Addon:IsBuild("classic") then
	function PetBar:GetShowStates()
		return '[pet]show;hide'
	end
else
	function PetBar:GetShowStates()
		return '[@pet,exists,nopossessbar]show;hide'
	end
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

function PetBar:AcquireButton(index)
	return PetButtons[index]
end

function PetBar:OnAttachButton(button)
	Addon:GetModule('ButtonThemer'):Register(button, 'Pet Bar')
	Addon:GetModule('Tooltips'):Register(button)
end

function PetBar:OnDetachButton(button)
	Addon:GetModule('ButtonThemer'):Unregister(button, 'Pet Bar')
	Addon:GetModule('Tooltips'):Unregister(button)
end

-- keybound events
function PetBar:KEYBOUND_ENABLED()
	self:SetAttribute('state-visibility', 'display')
	self:ForButtons("Show")
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

-- the module
local PetBarModule = Addon:NewModule('PetBar')

function PetBarModule:Load()
	self.frame = PetBar:New()
end

function PetBarModule:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end
