local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local ProgressBarModule = Dominos:NewModule("ProgressBars", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

function ProgressBarModule:Load()
	if not Dominos:IsBuild("retail") then
		self.bars = {
			Addon.ProgressBar:New("exp", {"xp", "reputation", "gold"})
		}
	elseif Addon.Config:OneBarMode() then
		self.bars = {
			Addon.ProgressBar:New("exp", {"xp", "reputation", "honor", "artifact", "azerite", "gold"})
		}
	else
		self.bars = {
			Addon.ProgressBar:New("exp", {"xp", "reputation", "honor", "gold"}),
			Addon.ProgressBar:New("artifact", {"azerite", "artifact"})
		}
	end
end

function ProgressBarModule:Unload()
	local bars = self.bars

	if type(bars) == "table" then
		for i, bar in pairs(bars) do
			bar:Free()
			bars[i] = nil
		end
	end
end

function ProgressBarModule:OnFirstLoad()
	-- remove UI components we're replacing
	if StatusTrackingBarManager then
		StatusTrackingBarManager:UnregisterAllEvents()
		StatusTrackingBarManager:Hide()
	end

	-- initialize configuration settings
	Addon.Config:Init()

	-- register events
	-- common events
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("UPDATE_EXHAUSTION")

	-- xp bar events
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")

	-- reputation events
	self:RegisterEvent("UPDATE_FACTION")

	if C_Reputation and C_Reputation.GetMajorFactionData then
		self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "UpdateAllBars")
		self:RegisterEvent("MAJOR_FACTION_UNLOCKED", "UpdateAllBars")
	end

	-- honor events
	if Addon.dataProviders and Addon.dataProviders['honor'] then
		self:RegisterEvent("HONOR_LEVEL_UPDATE")
		self:RegisterEvent("HONOR_XP_UPDATE")
	end

	-- artifact events
	if Addon.dataProviders and Addon.dataProviders['artifact'] then
		self:RegisterEvent("ARTIFACT_XP_UPDATE")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	end

	-- azerite events
	if Addon.dataProviders and Addon.dataProviders['azerite'] then
		self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
	end

	-- gold events
	if Addon.dataProviders and Addon.dataProviders['gold'] then
		self:RegisterEvent("PLAYER_MONEY")
	end

	-- addon and library callbacks
	Dominos.RegisterCallback(self, "OPTIONS_MENU_LOADING")
	LibStub("LibSharedMedia-3.0").RegisterCallback(self, 'LibSharedMedia_Registered')
end

-- events
function ProgressBarModule:OPTIONS_MENU_LOADING()
	self:AddOptionsPanel()
end

function ProgressBarModule:PLAYER_ENTERING_WORLD()
	self:UpdateAllBars()
	self:ForAllBars("UpdateDisplayConditions")
end

function ProgressBarModule:PLAYER_UPDATE_RESTING()
	self:UpdateAllBars()
end

function ProgressBarModule:UPDATE_EXHAUSTION()
	self:UpdateAllBars()
end

function ProgressBarModule:PLAYER_LEVEL_UP()
	self:ForAllBars("UpdateDisplayConditions")
end

function ProgressBarModule:PLAYER_XP_UPDATE()
	self:UpdateAllBars()
end

function ProgressBarModule:UPDATE_FACTION(event)
	self:UpdateAllBars()
end

function ProgressBarModule:ARTIFACT_XP_UPDATE()
	self:UpdateAllBars()
end

function ProgressBarModule:AZERITE_ITEM_EXPERIENCE_CHANGED()
	self:UpdateAllBars()
end

function ProgressBarModule:UNIT_INVENTORY_CHANGED(event, unit)
	if unit ~= "player" then
		return
	end

	self:UpdateAllBars()
end

function ProgressBarModule:HONOR_LEVEL_UPDATE()
	self:UpdateAllBars()
end

function ProgressBarModule:HONOR_XP_UPDATE()
	self:UpdateAllBars()
end

function ProgressBarModule:PLAYER_MONEY()
	self:UpdateAllBars()
end

function ProgressBarModule:LibSharedMedia_Registered()
	self:UpdateAllBars()
end

function ProgressBarModule:UpdateAllBars()
	local bars = self.bars
	if not bars then return end

	for _, bar in pairs(self.bars) do
		bar:UpdateMode()
		bar:Update()
	end
end

function ProgressBarModule:ForAllBars(method, ...)
	local bars = self.bars
	if bars then
		for _, bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

function ProgressBarModule:AddOptionsPanel()
	local colors = { }
	for i, key in pairs{ "xp", "xp_bonus", "honor", "artifact", "azerite", "gold", "gold_realm" } do
		colors[key] = {
			type = "color",
			name = L["Color_" .. key],
			order = i,
			hasAlpha = true,

			get = function()
				return Addon.Config:GetColor(key)
			end,

			set = function(_, ...)
				Addon.Config:SetColor(key, ...)

				for _, bar in pairs(self.bars) do
					bar:Update()
				end
			end
		}
	end

	Dominos.Options:AddOptionsPanelOptions("progress", {
		type = "group",
		name = L.Progress,
		args = {
			oneBarMode = {
				type = "toggle",
				name = L.OneBarMode,
				order = 1,
				width = "double",

				get = function()
					return Addon.Config:OneBarMode()
				end,

				set = function(_, enable)
					Addon.Config:SetOneBarMode(enable)
					self:Unload()
					self:Load()
				end
			},

			skipInactiveModes = {
				type = "toggle",
				name = L.SkipInactiveModes,
				order = 2,
				width = "double",

				get = function()
					return Addon.Config:SkipInactiveModes()
				end,

				set = function(_, enable)
					Addon.Config:SetSkipInactiveModes(enable)
				end
			},

			colors = {
				type = "group",
				name = Dominos.Options:GetLocale().Colors,
				order = 3,
				width = "full",

				inline = true,
				args = colors
			},

			goldGoal = {
				type = "range",
				name = L.GoldGoal,
				order = 4,
				width = "full",

				min = 0,
				max = 10000000,
				softMin = 0,
				softMax = 100000,
				step = 100,
				bigStep = 1000,

				get = function()
					return Addon.Config:GoldGoal()
				end,

				set = function(_, value)
					Addon.Config:SetGoldGoal(value)
					self:UpdateAllBars()
				end,
			},
		}
	})
end
