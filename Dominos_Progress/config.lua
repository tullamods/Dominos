local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local ConfigVersion = 3

-- the options panel lists them in this order
local COLOR_KEYS = { 'xp', 'xp_bonus', 'honor', 'artifact', 'azerite', 'gold', 'gold_realm' }

local DEFAULT_COLORS = {
	xp = '94008CFF',
	xp_bonus = '0063E0FF',
	honor = 'FF3D00FF',
	artifact = 'FFBF73CF',
	azerite = '99CCE6FF',
	gold = 'FFD700FF',
	gold_realm = 'FFF1BAFF'
}

---@alias ColorKey 'xp'|'xp_bonus'|'honor'|'artifact'|'azerite'|'gold'|'gold_realm'

---@class ProgressConfig
---@field db table
local Config = {
	COLOR_KEYS = COLOR_KEYS
}

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

function Config:Init()
	local db = Dominos.db:RegisterNamespace("ProgressBars", self:GetDefaults())
	local dbVersion = db.global.version or 1

	if dbVersion ~= ConfigVersion then
		self:Upgrade(db, dbVersion)

		db.global.version = ConfigVersion
	end

	self.db = db
end

--------------------------------------------------------------------------------
-- Upgrades
--------------------------------------------------------------------------------

function Config:Upgrade(db, oldVersion)
	if oldVersion < 3 then
		self:UpgradeColors(db)
	end
end

-- colors used to be saved as {r, g, b, a}
function Config:UpgradeColors(db)
	local profiles = db and db.sv and db.sv.profiles
	if type(profiles) ~= "table" then
		return
	end

	for _, profile in pairs(profiles) do
		for key, color in pairs(profile.colors or {}) do
			if type(color) == "table" then
				profile.colors[key] = Dominos:GetHexFromColor(color[1], color[2], color[3], color[4])
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

function Config:GetDefaults()
	return {
		profile = {
			one_bar = true,
			skip_inactive_modes = false,
			gold_goal = 0,
			colors = DEFAULT_COLORS
		},

		char = {
			bars = {
				["**"] = {
				}
			}
		}
	}
end

--------------------------------------------------------------------------------
-- Bar modes
--------------------------------------------------------------------------------

---@param barId string
---@param mode string
function Config:SetBarMode(barId, mode)
	local barSettings = self.db.char.bars[barId]

	if type(barSettings) == "table" then
		barSettings.mode = mode
	else
		self.db.char.bars[barId] = {
			["mode"] = mode
		}
	end
end

---@param barId string
---@return string?
function Config:GetBarMode(barId)
	return self.db.char.bars[barId].mode
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

function Config:SetOneBarMode(enable)
	self.db.profile.one_bar = enable and true
end

function Config:OneBarMode()
	return self.db.profile.one_bar
end

function Config:SetSkipInactiveModes(skip)
	self.db.profile.skip_inactive_modes = skip and true
end

function Config:SkipInactiveModes()
	return self.db.profile.skip_inactive_modes
end

--------------------------------------------------------------------------------
-- Gold goal
--------------------------------------------------------------------------------

---@return number gold 0 for no goal
function Config:GoldGoal()
	return self.db.profile.gold_goal
end

function Config:SetGoldGoal(value)
	self.db.profile.gold_goal = value or 0
end

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

---@param key ColorKey
---@param r number
---@param g number
---@param b number
---@param a number?
function Config:SetColor(key, r, g, b, a)
	self.db.profile.colors[key] = Dominos:GetHexFromColor(r, g, b, a)
end

-- the stock art is already colored, so a changed color has to leave it
-- back to the defaults, which brings the stock art back
function Config:ResetColors()
	for _, key in ipairs(COLOR_KEYS) do
		self.db.profile.colors[key] = nil
	end
end

---@param key ColorKey
---@return boolean
function Config:HasCustomColor(key)
	return self.db.profile.colors[key] ~= DEFAULT_COLORS[key]
end

---@param key ColorKey
---@return ColorMixin
function Config:GetColor(key)
	return Dominos:GetColorFromHex(self.db.profile.colors[key]) or Dominos:GetColorFromHex(DEFAULT_COLORS[key])
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

Addon.Config = Config
