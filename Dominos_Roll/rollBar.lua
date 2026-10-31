if not GroupLootContainer then return end

--------------------------------------------------------------------------------
-- Roll
-- A bar for moving the Group Loot frames
--------------------------------------------------------------------------------

local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')

--------------------------------------------------------------------------------
-- bar
--------------------------------------------------------------------------------

local RollBar = Dominos:CreateClass('Frame', Dominos.Frame)

function RollBar:New()
	local bar = RollBar.proto.New(self, 'roll')

	bar:Layout()

	return bar
end

function RollBar:GetDisplayName()
	return L.RollBarDisplayName
end

function RollBar:GetDescription()
	return L.TipRollBar
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
	self:RepositionChildFrame()

	local pW, pH = self:GetPadding()
	self:SetSize(317 + pW, 119 + pH)
end

function RollBar:RepositionChildFrame()
	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint('BOTTOM', self)
end

--------------------------------------------------------------------------------
-- module
--------------------------------------------------------------------------------

local RollBarModule = Dominos:NewModule('Roll')
local bar

function RollBarModule:Load()
	bar = RollBar:New()
	Dominos:SetAlertAnchorRedirect(GroupLootContainer, true)
end

function RollBarModule:Unload()
	Dominos:SetAlertAnchorRedirect(GroupLootContainer, false)

	if bar then
		bar:Free()
		bar = nil
	end
end

function RollBarModule:OnFirstLoad()
	GroupLootContainer.ignoreFramePositionManager = true
end
