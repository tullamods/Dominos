local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local ProgressBarModule = Dominos:NewModule("ProgressBars", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

function ProgressBarModule:Load()
	if not Dominos:IsGameType("standard") then
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

	Addon.Config:Init()

	-- register events. anything that changes what a bar shows just refreshes it
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEVEL_UP")

	self:RegisterEvent("PLAYER_UPDATE_RESTING", "RefreshAllBars")
	self:RegisterEvent("UPDATE_EXHAUSTION", "RefreshAllBars")
	self:RegisterEvent("PLAYER_XP_UPDATE", "RefreshAllBars")
	self:RegisterEvent("UPDATE_FACTION", "RefreshAllBars")

	if C_Reputation and C_Reputation.GetMajorFactionData then
		self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "RefreshAllBars")
		self:RegisterEvent("MAJOR_FACTION_UNLOCKED", "RefreshAllBars")
	end

	if Addon.dataProviders['honor'] then
		self:RegisterEvent("HONOR_LEVEL_UPDATE", "RefreshAllBars")
		self:RegisterEvent("HONOR_XP_UPDATE", "RefreshAllBars")
	end

	if Addon.dataProviders['artifact'] then
		self:RegisterEvent("ARTIFACT_XP_UPDATE", "RefreshAllBars")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	end

	if Addon.dataProviders['azerite'] then
		self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "RefreshAllBars")
	end

	if Addon.dataProviders['gold'] then
		self:RegisterEvent("PLAYER_MONEY", "RefreshAllBars")
	end

	Dominos.RegisterCallback(self, "OPTIONS_MENU_LOADING")
	LibStub("LibSharedMedia-3.0").RegisterCallback(self, 'LibSharedMedia_Registered')
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function ProgressBarModule:OPTIONS_MENU_LOADING()
	self:AddOptionsPanel()
end

function ProgressBarModule:PLAYER_ENTERING_WORLD()
	self:RefreshAllBars()
	self:ForAllBars("UpdateDisplayConditions")
end

-- UnitLevel lags behind this event, so bars get the new level from it
function ProgressBarModule:PLAYER_LEVEL_UP(event, level)
	self:ForAllBars("SetPlayerLevel", level)
end

function ProgressBarModule:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		self:RefreshAllBars()
	end
end

-- only bars using the media that just showed up need to restyle
function ProgressBarModule:LibSharedMedia_Registered(event, mediaType, key)
	self:ForAllBars("OnMediaRegistered", mediaType, key)
end

--------------------------------------------------------------------------------
-- Bars
--------------------------------------------------------------------------------

function ProgressBarModule:RefreshAllBars()
	self:ForAllBars("Refresh")
end

function ProgressBarModule:ForAllBars(method, ...)
	local bars = self.bars
	if bars then
		for _, bar in pairs(bars) do
			bar[method](bar, ...)
		end
	end
end

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

function ProgressBarModule:AddOptionsPanel()
	local colors = { }
	for i, key in ipairs(Addon.Config.COLOR_KEYS) do
		colors[key] = {
			type = "color",
			name = L["Color_" .. key],
			order = i,
			hasAlpha = true,

			get = function()
				return Addon.Config:GetColor(key):GetRGBA()
			end,

			set = function(_, ...)
				Addon.Config:SetColor(key, ...)

				for _, bar in pairs(self.bars) do
					bar:UpdateTextures()
				end
			end
		}
	end

	colors.reset = {
		type = "execute",
		name = L.ResetColors,
		order = #Addon.Config.COLOR_KEYS + 1,
		confirm = true,

		func = function()
			Addon.Config:ResetColors()

			for _, bar in pairs(self.bars) do
				bar:UpdateTextures()
			end

			LibStub("AceConfigRegistry-3.0"):NotifyChange(Dominos:GetName())
		end
	}

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
					self:RefreshAllBars()
				end,
			},
		}
	})
end
