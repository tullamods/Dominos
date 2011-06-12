--[[
	bagBar.lua
		Defines the Dominos bagBar object
--]]

local LBF = LibStub('LibButtonFacade', true)
local bags = {}


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

function BagBar:Reload()
	if not self.bags then
		self.bags = {}
	else
		for i = 1, #self.bags do
			self.bags[i] = nil
		end
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
	
	
	menu:AddAdvancedPanel()
	self.menu = menu
end