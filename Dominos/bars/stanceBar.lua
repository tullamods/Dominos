--[[
	stanceBar - a bar for displaying class specific buttons for things like stances/forms/etc
--]]

-- don't bother loading the module if the player is currently playing something without a stance
if select(2, UnitClass('player')) == 'MAGE' or select(2, UnitClass('player')) == 'SHAMAN' or select(2, UnitClass('player')) == 'HUNTER' then
	return
end

--[[ Globals ]]--

local Addon = _G[...]
local KeyBound = LibStub('LibKeyBound-1.0')


--[[ Button ]]--

local StanceButton = Addon:CreateClass('CheckButton', Addon.BindableButton)

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
		local button = self:Bind(_G['StanceButton' .. id])

		if button then
			button:HookScript('OnEnter', self.OnEnter)
			button:Skin()
		end

		return button
	end

	--if we have button facade support, then skin the button that way
	--otherwise, apply the dominos style to the button to make it pretty
	function StanceButton:Skin()
		if Addon:Masque('Class Bar', self) then
			return
		end

		local r = self:GetWidth() / _G['ActionButton1']:GetWidth()

		local nt = self:GetNormalTexture()
		nt:ClearAllPoints()
		nt:SetPoint('TOPLEFT', -15 * r, 15 * r)
		nt:SetPoint('BOTTOMRIGHT', 15 * r, -15 * r)

		self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
	end

	function StanceButton:Restore(id)
		local b = unused[id]
		if b then
			unused[id] = nil
			b:Show()

			return b
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

	--keybound support
	function StanceButton:OnEnter()
		KeyBound:Set(self)
	end
end


--[[ Bar ]]--

local StanceBar = Addon:CreateClass('Frame', Addon.ButtonBar)

do
	function StanceBar:New()
		local bar = StanceBar.proto.New(self, 'class')

		bar:UpdateNumForms()

		return bar
	end

	function StanceBar:GetDefaults()
		return {
			point = 'CENTER',
			spacing = 2
		}
	end

	function StanceBar:Free()
		self.numForms = nil

		StanceBar.proto.Free(self)
	end


	--[[ button stuff]]--

	function StanceBar:AddButton(index)
		local button = StanceButton:New(index)

		button:SetParent(self.header)
		button:EnableMouse(not self:GetClickThrough())

		self.buttons[index] = button

		return button
	end

	function StanceBar:UpdateNumForms()
		if InCombatLockdown() then return end

		local oldNumForms = self.numForms or 0
		local newNumForms = GetNumShapeshiftForms() or 0

		if oldNumForms ~= newNumForms then
			self.numForms = newNumForms

			for i = newNumForms + 1, oldNumForms do
	            self:RemoveButton(i)
	        end

	        for i = oldNumForms + 1, newNumForms do
	            self:AddButton(i)
	        end

			self:Layout()
		end
	end
end


--[[ Module ]]--

do
	local StanceBarController = Addon:NewModule('StanceBar', 'AceEvent-3.0')

	function StanceBarController:Load()
		self.bar = StanceBar:New()

		self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS', 'UpdateNumForms')
		self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateNumForms')
		self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateNumForms')
	end

	function StanceBarController:Unload()
		self:UnregisterAllEvents()

		if self.bar then
			self.bar:Free()
		end
	end

	function StanceBarController:UpdateNumForms()
		self.bar:UpdateNumForms()
	end
end
