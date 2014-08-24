if not _G['ExtraActionBarFrame'] then
	return
end

--[[ Globals ]]--

local _G = _G
local Dominos = _G['Dominos']
local KeyBound = LibStub('LibKeyBound-1.0')
local Tooltips = Dominos:GetModule('Tooltips')
local Bindings = Dominos.BindingsController

--[[ buttons ]]--

local ExtraActionButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)

do
	local unused = {}

	function ExtraActionButton:New(id)
		local button = self:Restore(id) or self:Create(id)

		Tooltips:Register(button)
		Bindings:Register(button)

		return button
	end

	function ExtraActionButton:Create(id)
		local b = self:Bind(_G[('ExtraActionButton%d'):format(id)])

		if b then
			b.buttonType = 'EXTRAACTIONBUTTON'
			b:HookScript('OnEnter', self.OnEnter)
			b:Skin()

			return b
		end
	end

	--if we have button facade support, then skin the button that way
	--otherwise, apply the dominos style to the button to make it pretty
	function ExtraActionButton:Skin()
		if not Dominos:Masque('Extra Bar', self) then
			self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
			self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
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

		Tooltips:Unregister(button)
		Bindings:Unregister(self)
	end

	--keybound support
	function ExtraActionButton:OnEnter()
		KeyBound:Set(self)
	end
end


--[[ bar ]]--

local ExtraBar = Dominos:CreateClass('Frame', Dominos.Frame)

function ExtraBar:New()
	local f = Dominos.Frame.New(self, 'extra')
	
	f:LoadButtons()
	f:Layout()
	f:UpdateShowBlizzardTexture()

	return f
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

function ExtraBar:AddButton(i)
	local b = ExtraActionButton:New(i)

	if b then
		b:SetAttribute('showgrid', 1)
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function ExtraBar:RemoveButton(i)
	local b = self.buttons[i]

	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

function ExtraBar:ShowBlizzardTexture(enable)
	self.sets.hideBlizzardTeture = not enable

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
	local menu = Dominos:NewMenu(bar.id)
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

--[[ module ]]--

local ExtraBarController = Dominos:NewModule('ExtraBar')

function ExtraBarController:OnInitialize()
	_G['ExtraActionBarFrame'].ignoreFramePositionManager = true
end

function ExtraBarController:Load()
	self.frame = ExtraBar:New()
end

function ExtraBarController:Unload()
	self.frame:Free()
end