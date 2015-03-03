--[[
	bagBar -  A bar for holding container buttons
--]]

local AddonName = ...
local Addon = _G[AddonName]

-- register buttons for use later
local bagButtons = {}

do
	local function addButton(buttonName)
		local button = _G[buttonName]

		Addon:Masque(
			'Bag Bar',
			button,
			{ Icon = _G[button:GetName() .. 'IconTexture'] }
		)

		table.insert(bagButtons, button)
	end

	addButton('MainMenuBarBackpackButton')

	for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
		addButton(('CharacterBag%dSlot'):format(slot))
	end
end


--[[ Bag Bar ]]--

local BagBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function BagBar:New()
	local bar = BagBar.proto.New(self, 'bags')

	bar:UpdateNumButtons()

	return bar
end

function BagBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		spacing = 2,
	}
end

function BagBar:SetSetOneBag(enable)
	self.sets.oneBag = enable or nil

	self:UpdateNumButtons()
end


--[[ Frame Overrides ]]--

function BagBar:GetButton(index)
	return bagButtons[index]
end

function BagBar:NumButtons()
	if self.sets.oneBag then
		return 1
	end

	return #bagButtons
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
