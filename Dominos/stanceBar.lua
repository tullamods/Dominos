--[[
	StanceBar.lua: A dominos stance bar
--]]

if select(2, UnitClass('player')) == 'MAGE' or select(2, UnitClass('player')) == 'SHAMAN' then
	return
end

--[[ Globals ]]--

local _G = _G
local Dominos = _G['Dominos']
local KeyBound = LibStub('LibKeyBound-1.0')


--[[ Button ]]--

local StanceButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)

do
	local unused = {}

	StanceButton.buttonType = 'SHAPESHIFTBUTTON'

	function StanceButton:New(id)
		local button = self:Restore(id) or self:Create(id)

		button:Update()
		button:UpdateHotkey()

		return button
	end

	function StanceButton:Create(id)
		local button = self:Bind(_G['StanceButton' .. id])

		if button then
			button:SetScript('OnEnter', self.OnEnter)
			button:Skin()
		end

		return button		
	end

	--if we have button facade support, then skin the button that way
	--otherwise, apply the dominos style to the button to make it pretty
	function StanceButton:Skin()
		if Dominos:Masque('Class Bar', self) then
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
	end

	--keybound support
	function StanceButton:OnEnter()
		if Dominos:ShowTooltips() then
			-- this should be the sameish as what is normally called by a stance button
			if GetCVarBool("UberTooltips") then
				GameTooltip_SetDefaultAnchor(GameTooltip, self)
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			end

			GameTooltip:SetShapeshift(self:GetID())
		end

		KeyBound:Set(self)
	end

	StanceButton.UpdateTooltip = StanceButton.OnEnter

	function StanceButton:Update()
		self:UpdateState()
		self:UpdateCooldown()
	end

	function StanceButton:UpdateState()
		local texture, name, isActive, isCastable = GetShapeshiftFormInfo(self:GetID())
		local icon = self.icon

		--update icon
		icon:SetTexture(texture)

		if isCastable then
			icon:SetVertexColor(1, 1, 1)
		else
			icon:SetVertexColor(0.4, 0.4, 0.4)
		end

		--update checked
		self:SetChecked(isActive)
	end

	function StanceButton:UpdateCooldown()
		CooldownFrame_SetTimer(self.cooldown, GetShapeshiftFormCooldown(self:GetID()))
	end
end


--[[ Bar ]]--

local StanceBar = Dominos:CreateClass('Frame', Dominos.Frame)

do
	function StanceBar:New()
		local f = Dominos.Frame.New(self, 'class')

		f:SetScript('OnEvent', f.OnEvent)
		
		f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
		f:RegisterEvent('PLAYER_REGEN_ENABLED')
		f:RegisterEvent('UPDATE_SHAPESHIFT_COOLDOWN')

		f:UpdateForms()

		return f
	end

	function StanceBar:GetDefaults()
		return {
			point = 'CENTER',
			spacing = 2
		}
	end

	function StanceBar:Free()
		self:UnregisterAllEvents()

		Dominos.Frame.Free(self)
	end


	--[[ Events/Messages ]]--

	function StanceBar:OnEvent(event, ...)
		local f = self[event]

		if f and type(f) == 'function' then
			f(self, event, ...)
		end
	end

	function StanceBar:UPDATE_SHAPESHIFT_FORMS()
		self:UpdateForms()
	end

	function StanceBar:UPDATE_SHAPESHIFT_COOLDOWN()
		self:UpdateCooldowns()
	end

	function StanceBar:PLAYER_REGEN_ENABLED()
		if self.needsUpdateNumForms then
			self.needsUpdateNumForms = nil

			self:UpdateNumForms()
		end
	end

	function StanceBar:UPDATE_BINDINGS()
		for _, b in pairs(self.buttons) do
			b:UpdateHotkey(b.buttonType)
		end
	end	


	--[[ button stuff]]--

	function StanceBar:LoadButtons()
		self:UpdateForms()
		self:UpdateClickThrough()
	end

	function StanceBar:AddButton(i)
		local b = StanceButton:New(i)

		b:SetParent(self.header)
		self.buttons[i] = b

		return b
	end

	function StanceBar:RemoveButton(i)
		local b = self.buttons[i]
		
		self.buttons[i] = nil

		b:Free()
	end

	function StanceBar:UpdateForms()
		for i, button in pairs(self.buttons) do
			button:Update()
		end

		self:UpdateNumForms()
	end

	function StanceBar:UpdateNumForms()
		if InCombatLockdown() then
			self.needsUpdateNumForms = true
			return
		end

		local numButtons = self:NumButtons() or 0
		local numForms = GetNumShapeshiftForms() or 0

		if numButtons ~= numForms then
			self:SetNumButtons(numForms)
		end
	end

	function StanceBar:UpdateCooldowns()
		for i, button in pairs(self.buttons) do
			button:UpdateCooldown()
		end
	end
end


--[[ Module ]]--

do
	local StanceBarController = Dominos:NewModule('StanceBarController')

	function StanceBarController:Load()
		self.bar = StanceBar:New()
	end

	function StanceBarController:Unload()
		if self.bar then
			self.bar:Free()
		end
	end
end