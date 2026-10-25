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

function RollBarModule:Load()
	if GroupLootContainer then
		self.rollBar = RollBar:New()
	end
end

function RollBarModule:Unload()
	if self.rollBar then
		self.rollBar:Free()
		self.rollBar = nil
	end
end

function RollBarModule:OnFirstLoad()
	if GroupLootContainer then
		GroupLootContainer.ignoreFramePositionManager = true

		hooksecurefunc(AlertFrame, "UpdateAnchors", function()
			if self.rollBar then
				self.rollBar:RepositionChildFrame()
			end
		end)
	end
end
