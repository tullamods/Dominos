local _, Addon = ...
local ProgressBar = Addon.ProgressBar

-- saved vars from the last release
local OLD_NATIVE_TEXTURE = 'blizzard'
local OLD_DEFAULT_FONT = 'Friz Quadrata TT'
local OLD_DISPLAY_PARTS = { 'label', 'value', 'max', 'remaining', 'bonus', 'percent' }

-- nearest format to what the old display checks showed. nil when none of them were on
local function textFormatFromDisplay(display)
	if display.value then
		if display.percent then
			return 'valueMaxPercent'
		end
		if display.max and display.remaining then
			return 'valueMaxRemaining'
		end
		return display.max and 'valueMax' or 'value'
	elseif display.percent then
		return 'percent'
	elseif display.remaining then
		return 'remaining'
	end
end

-- label and bonus carry over as their own checks. new bars get all of this from the defaults
local function upgradeText(sets)
	if sets.textFormat then
		return
	end

	local display = sets.display or {}
	local textFormat = textFormatFromDisplay(display)

	sets.textFormat = textFormat or 'valueMax'
	sets.showText = textFormat ~= nil and (sets.alwaysShowText and true or 'mouseover')
	sets.showLabel = display.label or false
	sets.showBonus = display.bonus or false
	sets.abbreviateNumbers = sets.compressValues and true or false

	for _, part in ipairs(OLD_DISPLAY_PARTS) do
		display[part] = nil
	end
	-- the border is new and goes with the stock look, so a custom texture skips it
	display.border = sets.texture == nil or sets.texture == OLD_NATIVE_TEXTURE
	sets.display = display
	sets.alwaysShowText = nil
	sets.compressValues = nil
end

-- old saved vars to the current format
function ProgressBar:UpgradeSettings()
	local sets = self.sets

	upgradeText(sets)

	-- hide at max level grew into auto hide
	if sets.hideAtMaxLevel ~= nil then
		sets.autoHide = sets.hideAtMaxLevel
		sets.hideAtMaxLevel = nil
	end

	-- the old defaults were saved as if picked. they mean the stock look now
	if sets.texture == OLD_NATIVE_TEXTURE then
		sets.texture = nil
	end
	if sets.font == OLD_DEFAULT_FONT then
		sets.font = nil
	end

	-- these were never saved until set, getters used to carry the fallbacks
	local defaults = self:GetDefaults()
	sets.width = sets.width or defaults.width
	sets.height = sets.height or defaults.height
	if sets.showTooltip == nil then
		sets.showTooltip = defaults.showTooltip
	end
end
