local _, Addon = ...

---@class XPProvider : DataProvider
local Experience = {
	colorKeys = { "xp", "xp_bonus" }
}

function Experience:GetValues()
	local value = UnitXP("player")
	local max = UnitXPMax("player")
	local bonus = GetXPExhaustion() or 0
	return value, max, bonus
end

function Experience:GetLabel()
	return XP
end

-- trial accounts bank xp past their level cap
local function addBankedXP(tooltip)
	if not (GameLimitedMode_IsBankedXPActive and UnitTrialBankedLevels and GameLimitedMode_IsBankedXPActive()) then
		return
	end

	local bankedLevels = UnitTrialBankedLevels('player')
	local bankedXP = UnitTrialXP('player')

	if (bankedLevels > 0 or bankedXP > 0) and XP_TEXT_BANKED_XP_HEADER then
		GameTooltip_AddBlankLineToTooltip(tooltip)
		GameTooltip_AddNormalLine(tooltip, XP_TEXT_BANKED_XP_HEADER)
	end

	if bankedLevels > 0 and TRIAL_CAP_BANKED_LEVELS_TOOLTIP then
		GameTooltip_AddHighlightLine(tooltip, TRIAL_CAP_BANKED_LEVELS_TOOLTIP:format(bankedLevels))
	elseif bankedXP > 0 and TRIAL_CAP_BANKED_XP_TOOLTIP then
		GameTooltip_AddHighlightLine(tooltip, TRIAL_CAP_BANKED_XP_TOOLTIP)
	end
end

-- the stock exhaustion tick tooltip, for the whole bar
function Experience:SetupTooltip(tooltip)
	local value, max = UnitXP('player'), UnitXPMax('player')

	if XP_TEXT and max > 0 then
		GameTooltip_SetTitle(tooltip, XP_TEXT:format(BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), math.ceil(value / max * 100)))
	else
		self:AddTooltipProgress(tooltip, value, max)
	end

	local restStateID, restStateName, restMultiplier = GetRestState()
	if restStateID and EXHAUST_TOOLTIP1 then
		GameTooltip_AddHighlightLine(tooltip, EXHAUST_TOOLTIP1:format(restStateName, restMultiplier * 100))
	end

	if EXHAUST_TOOLTIP2 and not IsResting() and (restStateID == 4 or restStateID == 5) then
		GameTooltip_AddHighlightLine(tooltip, EXHAUST_TOOLTIP2)
	end

	addBankedXP(tooltip)
end

function Experience:GetColor()
	return Addon.Config:GetColor("xp")
end

function Experience:GetBonusColor()
	return Addon.Config:GetColor("xp_bonus")
end

-- stock art for the value and rested bonus bars
function Experience:GetNativeTextures()
	return "UI-HUD-ExperienceBar-Fill-Experience", "UI-HUD-ExperienceBar-Fill-Rested"
end

function Experience:IsActive()
	-- the stock check knows about trial caps too
	if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then
		return false
	end
	if UnitLevel("player") >= Addon.GetMaxPlayerLevel() then
		return false
	end
	return not IsXPUserDisabled()
end

Addon.dataProviders["xp"] = Experience
