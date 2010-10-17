--[[
	bagBar.lua
		Defines the Dominos bagBar object
--]]

local NT_RATIO = 64/37
local _G = getfenv(0)
local LBF = LibStub('LibButtonFacade', true)

--load up the bag set...
local bags = {}
do
	local function ResizeItemButton(b, size)
		b:SetWidth(size)
		b:SetHeight(size)
		b:GetNormalTexture():SetWidth(size * NT_RATIO)
		b:GetNormalTexture():SetHeight(size * NT_RATIO)

		local count = _G[b:GetName() .. 'Count']
		count:SetFontObject('NumberFontNormalSmall')
		count:SetPoint('BOTTOMRIGHT', 0, 2)

		_G[b:GetName() .. 'Stock']:SetFontObject('NumberFontNormalSmall')
		_G[b:GetName() .. 'Stock']:SetVertexColor(1, 1, 0)
	end

	local function CreateKeyRing(name)
		local b = CreateFrame('CheckButton', name, UIParent, 'ItemButtonTemplate')
		b:RegisterForClicks('anyUp')
		b:Hide()

		b:SetScript('OnClick', function()
			if CursorHasItem() then
				PutKeyInKeyRing()
			else
				ToggleKeyRing()
			end
		end)

		b:SetScript('OnReceiveDrag', function()
			if CursorHasItem() then
				PutKeyInKeyRing()
			end
		end)

		b:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

			local color = HIGHLIGHT_FONT_COLOR
			GameTooltip:SetText(KEYRING, color.r, color.g, color.b)
			GameTooltip:AddLine()
		end)

		b:SetScript('OnLeave', function()
			GameTooltip:Hide()
		end)

		_G[b:GetName() .. 'IconTexture']:SetTexture('Interface\\ContainerFrame\\KeyRing-Bag-Icon')
		_G[b:GetName() .. 'IconTexture']:SetTexCoord(0, 0.9, 0.1, 1)

		ResizeItemButton(b, 30)
	end
	
	CreateKeyRing('DominosKeyringButton')
	ResizeItemButton(_G['MainMenuBarBackpackButton'], 30)
end


--[[ Bag Bar ]]--

local BagBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.BagBar  = BagBar


function BagBar:New()
	local f = self.super.New(self, 'bags')
	f:Reload()

	return f
end

function BagBar:SkinButton(b)
	if b.skinned then return end

	if LBF then
		LBF:Group('Dominos', 'Bag Bar'):AddButton(b, {Icon = _G[b:GetName() .. 'IconTexture']})
	end
	
	b.skinned = true
end

function BagBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		spacing = 2,
	}
end

function BagBar:SetSetOneBag(enable)
	self.sets.oneBag = enable or nil
	self:Reload()
end

function BagBar:SetShowKeyring(enable)
	if enable then
		self.sets.hideKeyring = nil
	else
		self.sets.hideKeyring = true
	end
	self:Reload()
end

function BagBar:Reload()
	if not self.bags then
		self.bags = {}
	else
		for i = 1, #self.bags do
			self.bags[i] = nil
		end
	end
	
	if not self.sets.hideKeyring then
		table.insert(self.bags, _G['DominosKeyringButton'])
	end

	if not self.sets.oneBag then
		table.insert(self.bags, _G['CharacterBag3Slot'])
		table.insert(self.bags, _G['CharacterBag2Slot'])
		table.insert(self.bags, _G['CharacterBag1Slot'])
		table.insert(self.bags, _G['CharacterBag0Slot'])
	end

	table.insert(self.bags, _G['MainMenuBarBackpackButton'])
	
	self:SetNumButtons(#self.bags)
end


--[[ Frame Overrides ]]--

function BagBar:AddButton(i) 
	local b = self.bags[i]
	b:SetParent(self.header)
	b:Show()
	self:SkinButton(b)

	self.buttons[i] = b
end

function BagBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()
		self.buttons[i] = nil
	end
end

function BagBar:UpdateButtonCount(numButtons)
	for i = 1, #self.buttons do
		self:RemoveButton(i)
	end

	for i = 1, numButtons do
		self:AddButton(i)
	end
end

function BagBar:NumButtons()
	return #self.bags
end

function BagBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)
	local panel = menu:AddLayoutPanel()
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
	
	--add onebag and showkeyring options
	local oneBag = panel:NewCheckButton(L.OneBag)
	oneBag:SetScript('OnShow', function() 
		oneBag:SetChecked(self.sets.oneBag) 
	end)
	oneBag:SetScript('OnClick', function() 
		self:SetSetOneBag(oneBag:GetChecked())
		_G[panel:GetName() .. L.Columns]:OnShow()
	end)
	
	local showKeyring = panel:NewCheckButton(L.ShowKeyring)
	showKeyring:SetScript('OnShow', function() 
		showKeyring:SetChecked(not self.sets.hideKeyring) 
	end)
	showKeyring:SetScript('OnClick', function() 
		self:SetShowKeyring(showKeyring:GetChecked())
		_G[panel:GetName() .. L.Columns]:OnShow()
	end)
	
	
	menu:AddAdvancedPanel()
	self.menu = menu
end