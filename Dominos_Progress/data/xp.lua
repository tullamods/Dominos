local _, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

-- needs the 9.0 quest log api, classic still uses GetQuestLogTitle
local CAN_ESTIMATE_QUEST_XP = C_QuestLog.GetInfo
	and C_QuestLog.IsComplete
	and true

local getMaxPlayerLevel = GetMaxLevelForPlayerExpansion or GetMaxPlayerLevel

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

local function getCompletedQuestXP()
	local xp = 0
	local count = 0
	local waitingForData = false

	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)

		-- IsComplete, not ReadyForTurnIn, matches the quest log
		if info and not (info.isHeader or info.isHidden or info.isTask) and C_QuestLog.IsComplete(info.questID) then
			local questID = info.questID
			local questXP = GetQuestLogRewardXP(questID) or 0

			if questXP > 0 then
				xp = xp + questXP
				count = count + 1
			end

			-- counted as 0 until it's in
			if not HaveQuestRewardData(questID) then
				C_TaskQuest.RequestPreloadRewardData(questID)
				waitingForData = true
			end
		end
	end

	return xp, count, waitingForData
end

---@return boolean waitingForData
function Experience:AddCompletedQuestLines(tooltip, formatNumber, remaining)
	local questXP, count, waitingForData = getCompletedQuestXP()

	if count > 0 then
		local afterQuests = remaining - questXP

		GameTooltip_AddColoredDoubleLine(tooltip, L.XPCompletedQuests:format(count), Addon.TextTemplates.remaining:format(formatNumber(questXP)), NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR)

		if afterQuests > 0 then
			GameTooltip_AddColoredDoubleLine(tooltip, L.XPAfterTurnIns, formatNumber(afterQuests), NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
		else
			GameTooltip_AddColoredDoubleLine(tooltip, L.XPAfterTurnIns, L.XPLevelUp:format(formatNumber(-afterQuests)), NORMAL_FONT_COLOR, GREEN_FONT_COLOR)
		end
	end

	return waitingForData
end

function Experience:AddRestLines(tooltip, formatNumber, rested)
	local resting = IsResting()
	if not (rested > 0 or resting) then
		return
	end

	GameTooltip_AddBlankLineToTooltip(tooltip)
	GameTooltip_AddColoredDoubleLine(tooltip, resting and L.XPResting or L.XPRested, formatNumber(rested), NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
end

function Experience:SetupTooltip(tooltip, refreshTooltip, formatNumber)
	local value, max, rested = self:GetValues()

	if max <= 0 then
		GameTooltip_SetTitle(tooltip, XP)
		return
	end

	local remaining = max - value

	if XP_TEXT then
		GameTooltip_SetTitle(tooltip, XP_TEXT:format(formatNumber(value), formatNumber(max), math.ceil(value / max * 100)))
	else
		GameTooltip_SetTitle(tooltip, Addon.TextTemplates.label:format(XP, Addon.TextTemplates.progress:format(formatNumber(value), formatNumber(max))))
	end

	GameTooltip_AddColoredDoubleLine(tooltip, L.XPRemaining, formatNumber(remaining), NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR)

	local waitingForData = CAN_ESTIMATE_QUEST_XP and self:AddCompletedQuestLines(tooltip, formatNumber, remaining)

	self:AddRestLines(tooltip, formatNumber, rested)

	addBankedXP(tooltip)

	return waitingForData
end

function Experience:GetColor()
	return Addon.Config:GetColor("xp")
end

function Experience:GetBonusColor()
	return Addon.Config:GetColor("xp_bonus")
end

function Experience:GetNativeTextures()
	return "UI-HUD-ExperienceBar-Fill-Experience", "UI-HUD-ExperienceBar-Fill-Rested"
end

function Experience:IsActive()
	-- the stock check knows about trial caps too
	if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then
		return false
	end
	if UnitLevel("player") >= getMaxPlayerLevel() then
		return false
	end
	return not IsXPUserDisabled()
end

Addon.dataProviders["xp"] = Experience
