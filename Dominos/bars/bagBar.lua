--[[
	bagBar -  A bar for holding container buttons
--]]

local AddonName = ...
local Addon = _G[AddonName]
local skinnedButtons = {}


--[[ Bag Bar - A button frame for  ]]--

local BagBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function BagBar:New()
	local bar = BagBar.proto.New(self, 'bags')

	bar:Reload()

	return bar
end

function BagBar:SkinButton(button)
	if skinnedButtons[button] then return end

	Addon:Masque(
		'Bag Bar',
		button,
		{ Icon = _G[button:GetName() .. 'IconTexture'] }
	)

	skinnedButtons[button] = true
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
		table.wipe(self.bags)
	end

	if not self.sets.oneBag then
		for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
			local buttonName = ('CharacterBag%dSlot'):format(slot)
			table.insert(self.bags, _G[buttonName])
		end
	end

	table.insert(self.bags, _G['MainMenuBarBackpackButton'])

	if #self.bags ~= #self.buttons then
		for i = 1, #self.bags + 1, #self.buttons do
			self:RemoveButton(i)
		end

		for i = 1, #self.buttons + 1, #self.bags do
			self:AddButton(i)
		end

		self:Layout()
	end
end


--[[ Frame Overrides ]]--

function BagBar:AddButton(index)
	local button = self.bags[index]

	if button then
		button:SetParent(self.header)
		button:EnableMouse(not self:GetClickThrough())
		button:Show()

		self:SkinButton(button)

		self.buttons[index] = button
	end
end

function BagBar:NumButtons()
	return #self.bags
end

function BagBar:CreateMenu()
	local menu = Addon:NewMenu(self.id)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

	local panel = menu:AddLayoutPanel()

	-- add option to show only one bag
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

--[[ Bag Bar Controller ]]

local BagBarController = Addon:NewModule('BagBar')

function BagBarController:Load()
	self.frame = BagBar:New()
end

function BagBarController:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end
