local _, Addon = ...

local PARAGON_FACTION_COLOR_INDEX = #FACTION_BAR_COLORS

local GetFriendshipReputation = GetFriendshipReputation
if not GetFriendshipReputation then
    GetFriendshipReputation = function()
        return
    end
end

local IsFactionParagon = C_Reputation and C_Reputation.IsFactionParagon
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

local function IsFriendshipFaction(factionID)
    if factionID then
        local getRep = C_GossipInfo and C_GossipInfo.GetFriendshipReputation

        if type(getRep) == "function" then
            local info = getRep(factionID)

            if type(info) == "table" then
                return info.friendshipFactionID > 0
            end
        end
    end

    return false
end

local Reputation = {}

function Reputation:GetValues()
    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
    if not name then
        return 0, 1
    end

    if IsFactionParagon(factionID) then
        local currentValue, threshold = C_Reputation.GetFactionParagonInfo(factionID)
        return currentValue % threshold, threshold
    elseif IsFriendshipFaction(factionID) then
        local info = C_GossipInfo.GetFriendshipReputation(factionID)
        if info.nextThreshold then
            return info.standing - info.reactionThreshold, info.nextThreshold - info.reactionThreshold
        else
            return 1, 1
        end
    elseif IsMajorFaction(factionID) then
        local info = C_MajorFactions.GetMajorFactionData(factionID)
        local capped = C_MajorFactions.HasMaximumRenown(factionID)
        return capped and info.renownLevelThreshold or (info.renownReputationEarned or 0), info.renownLevelThreshold
    else
        if reaction == MAX_REPUTATION_REACTION then
            return 1, 1
        end
        return value - min, max - min
    end
end

function Reputation:GetLabel()
    local name = GetWatchedFactionInfo()
    return name or REPUTATION
end

function Reputation:GetColor()
    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
    local color

    if not name then
        color = FACTION_BAR_COLORS[1]
    elseif IsFactionParagon(factionID) then
        color = FACTION_BAR_COLORS[PARAGON_FACTION_COLOR_INDEX]
    elseif IsFriendshipFaction(factionID) then
        color = FACTION_BAR_COLORS[reaction]
    elseif IsMajorFaction(factionID) then
        color = BLUE_FONT_COLOR
    else
        color = FACTION_BAR_COLORS[reaction]
    end

    return color.r, color.g, color.b
end

function Reputation:GetBonusText()
    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
    if not name then
        return nil
    end

    if IsFactionParagon(factionID) then
        return GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player"))
    elseif IsFriendshipFaction(factionID) then
        local info = C_GossipInfo.GetFriendshipReputation(factionID)
        return info.reaction
    elseif IsMajorFaction(factionID) then
        local info = C_MajorFactions.GetMajorFactionData(factionID)
        return RENOWN_LEVEL_LABEL:format(info.renownLevel)
    else
        return GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player"))
    end
end

function Reputation:IsCapped()
    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
    if not name then
        return false
    end

    if IsFriendshipFaction(factionID) then
        local info = C_GossipInfo.GetFriendshipReputation(factionID)
        return not info.nextThreshold
    elseif IsMajorFaction(factionID) then
        return C_MajorFactions.HasMaximumRenown(factionID)
    else
        return reaction == MAX_REPUTATION_REACTION
    end
end

function Reputation:IsActive()
    return GetWatchedFactionInfo() ~= nil
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders["reputation"] = Reputation
