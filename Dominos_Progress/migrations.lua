local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local Config = Addon.Config

local function profiles(sv)
	return pairs(type(sv) == "table" and type(sv.profiles) == "table" and sv.profiles or {})
end

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

-- colors used to be saved as {r, g, b, a}
local function upgradeColors(db)
	local oldDefaultColors = {
		xp = { 0.58, 0, 0.55, 1 },
		xp_bonus = { 0, 0.39, 0.88 },
		honor = { 1.0, 0.24, 0, 1 },
		artifact = { 1, 0.75, 0.45, 0.81 },
		azerite = { 0.601, 0.8, 0.901, 1 },
		gold = { 1, .8431, 0, 1 },
		gold_realm = { 1, .9451, .7294, 1 }
	}

	for _, profile in profiles(db.sv) do
		-- not saved until a color is changed
		local colors = profile.colors
		if type(colors) == "table" then
			for key, color in pairs(colors) do
				local default = oldDefaultColors[key]

				if type(color) == "table" and default then
					-- AceDB strips parts matching the default
					local c = {}
					for i = 1, 4 do
						c[i] = color[i] or default[i]
					end

					colors[key] = Dominos:GetHexFromColor(c[1], c[2], c[3], c[4])
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Bars
--------------------------------------------------------------------------------

-- the format matching the old display checks. nil when none of them were on
local function textFormatFromDisplay(display)
	if display.value then
		local textFormat = display.max and 'valueMax' or 'value'

		if display.remaining then
			textFormat = textFormat .. 'Remaining'
		end

		if display.percent then
			textFormat = textFormat .. 'Percent'
		end

		return textFormat
	elseif display.remaining then
		return display.percent and 'remainingPercent' or 'remaining'
	elseif display.percent then
		return 'percent'
	end
end

-- old saved vars to the current format. textFormat marks ones already done
---@param sets table
local function upgradeBarSettings(sets)
	-- before the check, upgraded bars can have it
	sets.smoothFill = nil

	if sets.textFormat ~= nil then
		return
	end

	local display = sets.display or {}
	local textFormat = textFormatFromDisplay(display)

	sets.textFormat = textFormat or 'valueMax'
	sets.showText = textFormat ~= nil and (sets.alwaysShowText and true or 'mouseover')
	sets.showLabel = display.label or false
	sets.showBonus = display.bonus or false
	sets.abbreviateNumbers = sets.compressValues and true or false

	for _, part in ipairs{ 'label', 'value', 'max', 'remaining', 'bonus', 'percent' } do
		display[part] = nil
	end

	display.border = false

	sets.display = display
	sets.alwaysShowText = nil
	sets.compressValues = nil

	-- hide at max level grew into auto hide
	if sets.hideAtMaxLevel ~= nil then
		sets.autoHide = sets.hideAtMaxLevel
		sets.hideAtMaxLevel = nil
	end

	-- the old default
	if sets.texture == nil or sets.texture == 'blizzard' then
		sets.texture = 'Blizzard'
	end

	if sets.font == nil then
		sets.font = 'Friz Quadrata TT'
	end

	-- these were never saved until set, getters used to carry the fallbacks
	local defaults = Addon.ProgressBar:GetDefaults()
	sets.width = sets.width or defaults.width
	sets.height = sets.height or defaults.height
	if sets.showTooltip == nil then
		sets.showTooltip = defaults.showTooltip
	end
end

-- bar settings live in the core db
local function upgradeBars()
	for _, profile in profiles(Dominos.db.sv) do
		local frames = profile.frames

		if type(frames) == "table" then
			for _, barId in ipairs{ "exp", "artifact" } do
				if type(frames[barId]) == "table" then
					upgradeBarSettings(frames[barId])
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Upgrade
--------------------------------------------------------------------------------

function Config:Upgrade(db, oldVersion)
	if oldVersion < 3 then
		upgradeColors(db)
	end

	if oldVersion < 4 then
		upgradeBars()
	end
end
