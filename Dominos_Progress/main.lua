--[[
	the main controller of dominos progress
--]]

local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local ProgressBarModule = Dominos:NewModule('ProgressBars', 'AceEvent-3.0')

function ProgressBarModule:Load()
	self.bars = {
		xp = Addon.XPBar:New('exp')
	}

	-- common events
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('UPDATE_EXHAUSTION')
	self:RegisterEvent('PLAYER_UPDATE_RESTING')

	-- xp bar events
	self:RegisterEvent('PLAYER_XP_UPDATE')

	-- reputation events
	self:RegisterEvent('UPDATE_FACTION')

	-- honor events
	self:RegisterEvent("HONOR_XP_UPDATE");
	self:RegisterEvent("HONOR_LEVEL_UPDATE");

	-- artifact events
	self:RegisterEvent('ARTIFACT_XP_UPDATE')
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function ProgressBarModule:UpdateAllBars()
	for _, bar in pairs(self.bars) do
		bar:Update()
	end
end

function ProgressBarModule:UpdateAllBarsOfType(type)
	for _, bar in pairs(self.bars) do
		if bar.type == type then
			bar:Update()
		end
	end
end

function ProgressBarModule:Unload()
	for i, bar in pairs(self.bars) do
		bar:Free()
	end

	self.bars = {}
end

function ProgressBarModule:PLAYER_ENTERING_WORLD()
	self:UpdateAllBars()
end

function ProgressBarModule:UPDATE_EXHAUSTION()
	self:UpdateAllBars()
end

function ProgressBarModule:PLAYER_UPDATE_RESTING()
	self:UpdateAllBars()
end

function ProgressBarModule:PLAYER_XP_UPDATE()
	self:UpdateAllBarsOfType('xp')
end

function ProgressBarModule:UPDATE_FACTION(event, unit)
	if unit ~= 'player' then return end

	self:UpdateAllBarsOfType('rep')
end

function ProgressBarModule:ARTIFACT_XP_UPDATE()
	self:UpdateAllBarsOfType('artifact')
end

function ProgressBarModule:UNIT_INVENTORY_CHANGED(event, unit)
	if unit ~= 'player' then return end

	self:UpdateAllBarsOfType('artifact')
end

function ProgressBarModule:HONOR_XP_UPDATE()
	self:UpdateAllBarsOfType('honor')
end

function ProgressBarModule:HONOR_LEVEL_UPDATE()
	self:UpdateAllBarsOfType('honor')
end