local _, Addon = ...
local ProgressBar = Addon.ProgressBar

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

-- old saved vars to the current format
function ProgressBar:UpgradeSettings()
	local sets = self.sets

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

	if self.texture == nil then
		self.texture = 'blizzard'
	end

	if self.font == nil then
		self.font = 'Friz Quadrata TT'
	end

	-- these were never saved until set, getters used to carry the fallbacks
	local defaults = self:GetDefaults()
	sets.width = sets.width or defaults.width
	sets.height = sets.height or defaults.height
	if sets.showTooltip == nil then
		sets.showTooltip = defaults.showTooltip
	end
end
