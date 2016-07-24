--[[
	rollBar
		A dominos frame for rolling on items when in a party
--]]

--[[ Roll Bar Object ]]--

local RollBar = Dominos:CreateClass('Frame', Dominos.Frame)

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')

function RollBar:New()
	local bar = RollBar.proto.New(self, 'roll', L.TipRollBar)

	bar:Layout()

	return bar
end

function RollBar:GetDefaults()
	return {
		point = 'LEFT',
		columns = 1,
		spacing = 2,
		showInPetBattleUI = true,
		showInOverrideUI = true,
	}
end

function RollBar:Layout()
	local container = _G.AlertFrame
	container:ClearAllPoints()
	container:SetPoint('BOTTOM', self.header)

	local pW, pH = self:GetPadding()
	self:SetSize(317 + pW, 119 + pH)
end

function RollBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

	local panel = menu:NewPanel(L.Layout)

	panel.opacitySlider = panel:NewOpacitySlider()
	panel.fadeSlider = panel:NewFadeSlider()
	panel.scaleSlider = panel:NewScaleSlider()
	panel.paddingSlider = panel:NewPaddingSlider()

	self.menu = menu
end


--[[ Module Stuff ]]--

local RollBarController = Dominos:NewModule('RollBar')

function RollBarController:Load()
	self.frame = RollBar:New()
	self:Debug()
end

function RollBarController:Unload()
	self.frame:Free()
end

function RollBarController:Debug()
	local t = _G.GroupLootContainer:CreateTexture(nil, 'BACKGROUND')
	t:SetAllPoints(t:GetParent())
	t:SetColorTexture(0, 1, 0, 0.5)
end