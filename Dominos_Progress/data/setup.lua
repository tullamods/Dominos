local _, Addon = ...

---@alias TextFormat 'value'|'valueRemaining'|'valuePercent'|'valueRemainingPercent'|'valueMax'|'valueMaxRemaining'|'valueMaxPercent'|'valueMaxRemainingPercent'|'percent'|'remaining'|'remainingPercent'

---@type TextFormat[]
local TEXT_FORMATS = {
	'value',
	'valueRemaining',
	'valuePercent',
	'valueRemainingPercent',
	'valueMax',
	'valueMaxRemaining',
	'valueMaxPercent',
	'valueMaxRemainingPercent',
	'percent',
	'remaining',
	'remainingPercent',
}

local TEXT_FORMAT_PARTS = {
	value = { value = true },
	valueRemaining = { value = true, remaining = true },
	valuePercent = { value = true, percent = true },
	valueRemainingPercent = { value = true, remaining = true, percent = true },
	valueMax = { value = true, max = true },
	valueMaxRemaining = { value = true, max = true, remaining = true },
	valueMaxPercent = { value = true, max = true, percent = true },
	valueMaxRemainingPercent = { value = true, max = true, remaining = true, percent = true },
	percent = { percent = true },
	remaining = { remaining = true },
	remainingPercent = { remaining = true, percent = true },
}

---@alias NumberFormatter fun(number: number): string

---@class TextOptions
---@field formatNumber NumberFormatter
---@field showLabel boolean
---@field showBonus boolean

-- every provider falls back to this. GetValues, GetColor and IsActive are
-- required, the rest is optional. bonus is a number to fill for xp and gold, but
-- reputation only uses it as text (the standing)
---@class DataProvider
---@field GetValues fun(self: DataProvider): number, number, number?  value, max, bonus
---@field GetColor fun(self: DataProvider): ColorMixin
---@field IsActive fun(self: DataProvider): boolean
---@field GetLabel? fun(self: DataProvider): string?
---@field GetBonusColor? fun(self: DataProvider): ColorMixin
---@field GetNativeTextures? fun(self: DataProvider): string, string?  value and bonus atlas
---@field colorKeys? ColorKey[]
---@field tintsStockArt? boolean desaturate the stock art and tint it with GetColor
local DataProvider = {}
local inheritDataProvider = { __index = DataProvider }

-- a custom color means desaturated, tinted art. providers with GetNativeTextures list
-- the colors the stock art would use in colorKeys
---@return boolean
function DataProvider:IsRecolored()
	for _, key in ipairs(self.colorKeys or {}) do
		if Addon.Config:HasCustomColor(key) then
			return true
		end
	end
	return false
end

-- false when the mode has nothing to show yet (gold without a goal), so
-- cycling skips it even when inactive modes are allowed
---@return boolean
function DataProvider:IsAvailable()
	return true
end

--------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------

-- how the bar's text is put together. each %s is a formatted number or another
-- of these
local TextTemplates = {
	label = '%s: %s',
	progress = '%s / %s',
	detail = '%s (%s)',
	separator = ', ',
	remaining = '-%s',
	bonus = '(+%s)',
	suffix = '(%s)'
}

-- a nil part is just left out
---@param text string?
---@param part string?
---@return string?
local function join(text, part)
	if not part then
		return text
	end
	return text and (text .. ' ' .. part) or part
end

-- label, main text and bonus. override the Format* methods to change the
-- wording, or this to do it all yourself
---@param textFormat TextFormat
---@param options TextOptions the bar reuses it, don't keep it
---@param value number
---@param max number
---@param bonus number
---@return string?
function DataProvider:GetText(textFormat, options, value, max, bonus)
	local formatNumber = options.formatNumber
	local text = self:FormatProgress(textFormat, value, max, formatNumber)

	if options.showBonus and self:HasBonus(bonus) then
		text = join(text, self:FormatBonus(bonus, formatNumber))
	end

	local label = options.showLabel and self.GetLabel and self:GetLabel()
	if label and text then
		return TextTemplates.label:format(label, text)
	end
	return text
end

---@param textFormat TextFormat
---@param value number
---@param max number
---@param formatNumber NumberFormatter
---@return string?
function DataProvider:FormatProgress(textFormat, value, max, formatNumber)
	local parts = TEXT_FORMAT_PARTS[textFormat] or TEXT_FORMAT_PARTS.valueMax
	local text

	if parts.value then
		text = self:FormatValue(value, formatNumber)

		if parts.max and max > 0 then
			text = TextTemplates.progress:format(text, self:FormatValue(max, formatNumber))
		end
	end

	-- 1 / 5 (-4, 20.0%)
	local detail

	-- nothing left once it's full
	if parts.remaining and value < max then
		local remaining = self:FormatRemaining(max - value, formatNumber)

		if text then
			detail = remaining
		else
			text = remaining
		end
	end

	local percent = parts.percent and self:FormatPercent(value, max)

	if percent then
		if not text then
			text = percent
		elseif detail then
			detail = detail .. TextTemplates.separator .. percent
		else
			detail = percent
		end
	end

	if detail then
		return TextTemplates.detail:format(text, detail)
	end
	return text
end

---@param value number
---@param formatNumber NumberFormatter
---@return string
function DataProvider:FormatValue(value, formatNumber)
	return formatNumber(value)
end

---@param remaining number
---@param formatNumber NumberFormatter
---@return string
function DataProvider:FormatRemaining(remaining, formatNumber)
	return TextTemplates.remaining:format(self:FormatValue(math.max(remaining, 0), formatNumber))
end

-- nothing to measure against at a max of 0. floored, so it never says 100 before it's full
---@param value number
---@param max number
---@return string?
function DataProvider:FormatPercent(value, max)
	if max > 0 then
		return ('%.1f%%'):format(math.floor(value / max * 1000) / 10)
	end
end

--------------------------------------------------------------------------------
-- Bonus
--------------------------------------------------------------------------------

---@param bonus number
---@return boolean
function DataProvider:HasBonus(bonus)
	return bonus > 0
end

---@param bonus number
---@param formatNumber NumberFormatter
---@return string
function DataProvider:FormatBonus(bonus, formatNumber)
	return TextTemplates.bonus:format(self:FormatValue(bonus, formatNumber))
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

-- override it to mirror a stock tooltip
---@param tooltip GameTooltip already owned, anchored and cleared
---@param refreshTooltip fun() redoes it if the bar still owns it, for load callbacks
---@param formatNumber NumberFormatter
---@return boolean? waitingForData the bar polls it till it's false
function DataProvider:SetupTooltip(tooltip, refreshTooltip, formatNumber)
	local value, max = self:GetValues()

	if self.GetLabel then
		GameTooltip_SetTitle(tooltip, self:GetLabel())
	end
	self:AddTooltipProgress(tooltip, tonumber(value) or 0, tonumber(max) or 0, formatNumber)
end

---@param tooltip GameTooltip
---@param value number
---@param max number
---@param formatNumber NumberFormatter?
function DataProvider:AddTooltipProgress(tooltip, value, max, formatNumber)
	formatNumber = formatNumber or BreakUpLargeNumbers

	local progress = TextTemplates.progress:format(formatNumber(value), formatNumber(max))
	local percent = self:FormatPercent(value, max)
	GameTooltip_AddHighlightLine(tooltip, percent and TextTemplates.detail:format(progress, percent) or progress)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

-- for the providers that put their own text together
Addon.TextTemplates = TextTemplates

Addon.textFormats = TEXT_FORMATS

-- so providers can call the base methods
Addon.DataProvider = DataProvider

-- keyed by mode. each provider file adds its own entry
Addon.dataProviders = setmetatable({}, {
	__newindex = function(providers, mode, provider)
		for _, method in ipairs({ 'GetValues', 'GetColor', 'IsActive' }) do
			assert(provider[method], ('provider %q needs a %s method'):format(mode, method))
		end

		rawset(providers, mode, setmetatable(provider, inheritDataProvider))
	end
})
