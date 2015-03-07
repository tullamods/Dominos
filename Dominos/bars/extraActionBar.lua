if not _G['ExtraActionBarFrame'] then return end

--[[ Globals ]]--

local Addon = _G[...]
local KeyBound = LibStub('LibKeyBound-1.0')
local Tooltips = Addon:GetModule('Tooltips')
local Bindings = Addon.BindingsController


--[[ buttons ]]--

local ExtraActionButton = Addon:CreateClass('CheckButton', Addon.BindableButton)

do
	local unused = {}

	function ExtraActionButton:New(id)
		local button = self:Restore(id) or self:Create(id)

		Tooltips:Register(button)
		Bindings:Register(button)

		return button
	end

	function ExtraActionButton:Create(id)
		local button = self:Bind(_G[('ExtraActionButton%d'):format(id)])

		if button then
			button.buttonType = 'EXTRAACTIONBUTTON'
			button:HookScript('OnEnter', self.OnEnter)
			Addon:GetModule('ButtonThemer'):Register(button, 'Extra Bar')

			return button
		end
	end

	function ExtraActionButton:Restore(id)
		local b = unused and unused[id]

		if b then
			unused[id] = nil
			b:Show()

			return b
		end
	end

	--saving them thar memories
	function ExtraActionButton:Free()
		unused[self:GetID()] = self

		self:SetParent(nil)
		self:Hide()

		Tooltips:Unregister(self)
		Bindings:Unregister(self)
	end

	--keybound support
	function ExtraActionButton:OnEnter()
		KeyBound:Set(self)
	end
end


--[[ bar ]]--

local ExtraBar = Addon:CreateClass('Frame', Addon.ButtonBar)

do
	function ExtraBar:New()
		local bar = ExtraBar.proto.New(self, 'extra')

		bar:UpdateShowBlizzardTexture()

		return bar
	end

	function ExtraBar:GetDefaults()
		return {
			point = 'CENTER',
			x = -244,
			y = 0,
		}
	end

	function ExtraBar:GetShowStates()
		return '[extrabar]show;hide'
	end

	function ExtraBar:NumButtons()
		return 1
	end

	function ExtraBar:GetButton(index)
		local button = ExtraActionButton:New(index)

		button:SetAttribute('showgrid', 1)

		return button
	end

	function ExtraBar:ShowBlizzardTexture(show)
		self.sets.hideBlizzardTeture = not show

		self:UpdateShowBlizzardTexture()
	end

	function ExtraBar:ShowingBlizzardTexture()
		return not self.sets.hideBlizzardTeture
	end

	function ExtraBar:UpdateShowBlizzardTexture()
		local showTexture = self:ShowingBlizzardTexture()

		for i, button in pairs(self.buttons) do
			if showTexture then
				button.style:Show()
			else
				button.style:Hide()
			end
		end
	end

	function ExtraBar:CreateMenu()
		local bar = self
		local menu = Addon:NewMenu(bar.id)
		local panel = menu:AddLayoutPanel()

		local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
		local showTextureButton = panel:NewCheckButton(L.ExtraBarShowBlizzardTexture)

		showTextureButton:SetScript('OnShow', function(self)
			self:SetChecked(bar:ShowingBlizzardTexture())
		end)

		showTextureButton:SetScript('OnClick', function(self)
			bar:ShowBlizzardTexture(self:GetChecked())
		end)

		menu:AddAdvancedPanel()
		self.menu = menu
	end
end

--[[ module ]]--

local ExtraBarController = Addon:NewModule('ExtraBar')

function ExtraBarController:OnInitialize()
	_G['ExtraActionBarFrame'].ignoreFramePositionManager = true
end

function ExtraBarController:Load()
	self.frame = ExtraBar:New()
end

function ExtraBarController:Unload()
	self.frame:Free()
end
