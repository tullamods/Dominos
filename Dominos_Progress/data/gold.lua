local _, Addon = ...
local TextTemplates = Addon.TextTemplates

local COPPER_PER_GOLD = 10000

---@class GoldProvider : DataProvider
local Gold = {}

function Gold:GetValues()
	local gold = GetMoney()
	local realm = 0

	if DataStore then
		for _, c in pairs(DataStore:GetCharacters()) do
			realm = realm + DataStore:GetMoney(c)
		end
		-- stale data can leave this character out of the totals
		realm = math.max(realm - gold, 0)
	end

	-- the bar is only available with a goal. values are in gold, not copper
	return gold / COPPER_PER_GOLD, Addon.Config:GoldGoal(), realm / COPPER_PER_GOLD
end

function Gold:GetLabel()
	return MONEY
end

-- whole gold only. abbreviating counts digits, silver and copper included
function Gold:FormatValue(gold, formatNumber)
	return formatNumber(math.floor(gold)) .. GOLD_AMOUNT_SYMBOL
end

-- round up, so it never says none is left before the goal is reached
function Gold:FormatRemaining(remaining, formatNumber)
	return TextTemplates.remaining:format(self:FormatValue(math.ceil(math.max(remaining, 0)), formatNumber))
end

local function formatCoins(copper)
	return GetMoneyString(Round(copper), true)
end

function Gold:SetupTooltip(tooltip)
	local money = GetMoney()
	local _, goal, realm = self:GetValues()
	local goalCopper = goal * COPPER_PER_GOLD

	local progress = TextTemplates.progress:format(formatCoins(money), formatCoins(goalCopper))
	local percent = self:FormatPercent(money, goalCopper)
	GameTooltip_SetTitle(tooltip, percent and TextTemplates.detail:format(progress, percent) or progress)

	if goalCopper > money then
		GameTooltip_AddHighlightLine(tooltip, TextTemplates.remaining:format(formatCoins(goalCopper - money)))
	end

	if realm > 0 then
		GameTooltip_AddNormalLine(tooltip, TextTemplates.bonus:format(formatCoins(realm * COPPER_PER_GOLD)))
	end
end

function Gold:GetColor()
	return Addon.Config:GetColor("gold")
end

function Gold:GetBonusColor()
	return Addon.Config:GetColor("gold_realm")
end

function Gold:IsAvailable()
	return (Addon.Config:GoldGoal() or 0) > 0
end

Gold.IsActive = Gold.IsAvailable

Addon.dataProviders["gold"] = Gold
