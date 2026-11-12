local _, Addon = ...
local TextTemplates = Addon.TextTemplates

--------------------------------------------------------------------------------
-- Compatibility
--------------------------------------------------------------------------------

local PARAGON_FACTION_COLOR_INDEX = #FACTION_BAR_COLORS

local IsFactionParagon = C_Reputation and (
	C_Reputation.IsFactionParagonForCurrentPlayer
	or C_Reputation.IsFactionParagon
)

if not IsFactionParagon then
	IsFactionParagon = function()
		return false
	end
end

local IsMajorFaction = C_Reputation and C_Reputation.IsMajorFaction
if not IsMajorFaction then
	IsMajorFaction = function()
		return false
	end
end

local GetWatchedFactionInfo = GetWatchedFactionInfo
if not GetWatchedFactionInfo then
	GetWatchedFactionInfo = function()
		local data = C_Reputation.GetWatchedFactionData()
		if not data or data.factionID == 0 then
			return
		end

		return data.name,
			data.reaction,
			data.currentReactionThreshold,
			data.nextReactionThreshold,
			data.currentStanding,
			data.factionID
	end
end

---@class ReputationProvider : DataProvider
local Reputation = {}

--------------------------------------------------------------------------------
-- Values
--------------------------------------------------------------------------------

-- the friendship info, if it is one. retail hands back a table for any faction
local function getFriendship(factionID)
	if factionID then
		local getRep = C_GossipInfo and C_GossipInfo.GetFriendshipReputation

		if type(getRep) == "function" then
			local info = getRep(factionID)

			if type(info) == "table" and (info.friendshipFactionID or 0) > 0 then
				return info
			end
		end
	end
end

-- the stock colors are plain tables, the bar wants color objects
local factionColors = {}

local function getFactionColor(index)
	local color = factionColors[index]

	if not color then
		local stockColor = FACTION_BAR_COLORS[index]
		color = CreateColor(stockColor.r, stockColor.g, stockColor.b)
		factionColors[index] = color
	end

	return color
end

local function getReactionLabel(reaction)
	return GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player"))
end

local function getStanding(reaction, factionID)
	if IsMajorFaction(factionID) then
		local info = C_MajorFactions.GetMajorFactionData(factionID)
		return info and RENOWN_LEVEL_LABEL:format(info.renownLevel) or ""
	end

	local friendship = getFriendship(factionID)
	if friendship then
		return friendship.reaction
	end

	return getReactionLabel(reaction)
end

local function isCapped(reaction, factionID)
	if IsMajorFaction(factionID) then
		return C_MajorFactions.HasMaximumRenown(factionID)
	end

	local friendship = getFriendship(factionID)
	if friendship then
		return not friendship.nextThreshold
	end

	return reaction == MAX_REPUTATION_REACTION
end

function Reputation:GetValues()
	local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
	if not name then
		return 0, 1
	end

	-- paragon first, same order as the color and tooltip. data can still be loading
	if IsFactionParagon(factionID) then
		local currentValue, threshold = C_Reputation.GetFactionParagonInfo(factionID)
		if not (currentValue and threshold and threshold > 0) then
			return 0, 1
		end
		return currentValue % threshold, threshold
	elseif IsMajorFaction(factionID) then
		local info = C_MajorFactions.GetMajorFactionData(factionID)
		if not info then
			return 0, 1
		end
		local capped = C_MajorFactions.HasMaximumRenown(factionID)
		return capped and info.renownLevelThreshold or (info.renownReputationEarned or 0), info.renownLevelThreshold
	end

	local friendship = getFriendship(factionID)
	if friendship then
		if friendship.nextThreshold then
			return friendship.standing - friendship.reactionThreshold, friendship.nextThreshold - friendship.reactionThreshold
		end
		return 1, 1
	elseif reaction == MAX_REPUTATION_REACTION then
		return 1, 1
	end

	return value - min, max - min
end

function Reputation:GetColor()
	local name, reaction, _, _, _, factionID = GetWatchedFactionInfo()

	if not name then
		return getFactionColor(1)
	elseif IsFactionParagon(factionID) then
		return getFactionColor(PARAGON_FACTION_COLOR_INDEX)
	elseif IsMajorFaction(factionID) then
		return BLUE_FONT_COLOR
	end

	return getFactionColor(reaction)
end

--------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------

-- no label without a watched faction, the main text says reputation already
function Reputation:GetLabel()
	return (GetWatchedFactionInfo())
end

-- the standing is the bonus, after the numbers. a capped faction only shows that
function Reputation:FormatProgress(textFormat, value, max, formatNumber)
	local name, reaction, _, _, _, factionID = GetWatchedFactionInfo()
	if not name then
		return REPUTATION
	elseif isCapped(reaction, factionID) then
		return getStanding(reaction, factionID)
	end

	return Addon.DataProvider.FormatProgress(self, textFormat, value, max, formatNumber)
end

function Reputation:HasBonus()
	local name, reaction, _, _, _, factionID = GetWatchedFactionInfo()
	return name ~= nil and not isCapped(reaction, factionID)
end

function Reputation:FormatBonus()
	local _, reaction, _, _, _, factionID = GetWatchedFactionInfo()
	return TextTemplates.suffix:format(getStanding(reaction, factionID))
end

function Reputation:IsActive()
	return GetWatchedFactionInfo() ~= nil
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

-- retail only
local ReputationUtil = ReputationUtil
local RenownRewardUtil = RenownRewardUtil

local function addAccountWideLine(tooltip, factionID)
	if ReputationUtil then
		ReputationUtil.TryAppendAccountReputationLineToTooltip(tooltip, factionID)
	end
end

-- ReputationEntryMixin:ShowFriendshipReputationTooltip, minus the click hint
local function addFriendshipLines(tooltip, factionID, info)
	local ranks = C_GossipInfo.GetFriendshipReputationRanks and C_GossipInfo.GetFriendshipReputationRanks(info.friendshipFactionID)

	if ranks and ranks.maxLevel > 0 then
		GameTooltip_SetTitle(tooltip, TextTemplates.detail:format(info.name, TextTemplates.progress:format(ranks.currentLevel, ranks.maxLevel)))
	else
		GameTooltip_SetTitle(tooltip, info.name)
	end
	addAccountWideLine(tooltip, factionID)

	GameTooltip_AddBlankLineToTooltip(tooltip)
	tooltip:AddLine(info.text, nil, nil, nil, true)

	if info.nextThreshold then
		local progress = TextTemplates.progress:format(info.standing - info.reactionThreshold, info.nextThreshold - info.reactionThreshold)
		GameTooltip_AddHighlightLine(tooltip, TextTemplates.detail:format(info.reaction, progress))
	else
		GameTooltip_AddHighlightLine(tooltip, info.reaction)
	end
end

-- the stock tooltip is just the name, so add the standing like friendships do
local function addStandingLines(tooltip, name, reaction, factionID, value, max)
	GameTooltip_SetTitle(tooltip, name)
	addAccountWideLine(tooltip, factionID)

	local standing = getStanding(reaction, factionID)
	if isCapped(reaction, factionID) then
		GameTooltip_AddHighlightLine(tooltip, standing)
	else
		GameTooltip_AddHighlightLine(tooltip, TextTemplates.detail:format(standing, TextTemplates.progress:format(value, max)))
	end
end

-- the stock bar polls while paragon rewards load. retry, one at a time, until they're in
local pendingRefresh
local function retryRefresh()
	local refresh = pendingRefresh
	pendingRefresh = nil
	refresh()
end

-- same order as ReputationEntryMixin:ShowTooltipForReputationType
function Reputation:SetupTooltip(tooltip, refreshTooltip)
	local name, reaction, _, _, _, factionID = GetWatchedFactionInfo()
	if not name then
		GameTooltip_SetTitle(tooltip, REPUTATION)
		return
	end

	if IsFactionParagon(factionID) and ReputationUtil then
		ReputationUtil.AddParagonRewardsToTooltip(tooltip, factionID)

		if tooltip.waitingForData and not pendingRefresh then
			pendingRefresh = refreshTooltip
			C_Timer.After(TOOLTIP_UPDATE_TIME or 0.2, retryRefresh)
		end

		-- adds nothing when only the old paragon check passed
		if tooltip:NumLines() > 0 then
			return
		end
	end

	local friendship = getFriendship(factionID)

	if friendship then
		addFriendshipLines(tooltip, factionID, friendship)
	elseif IsMajorFaction(factionID) and RenownRewardUtil then
		RenownRewardUtil.AddMajorFactionToTooltip(tooltip, factionID, refreshTooltip)
	else
		addStandingLines(tooltip, name, reaction, factionID, self:GetValues())
	end
end

Addon.dataProviders["reputation"] = Reputation
