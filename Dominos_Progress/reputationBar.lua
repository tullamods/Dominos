local AddonName, Addon = ...
local Dominos = _G.Dominos
local ReputationBar = Dominos:CreateClass('Frame', Addon.ProgressBar)
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Progress')
local FRIEND_FACTION_COLOR_INDEX = 5
local PARAGON_FACTION_COLOR_INDEX = #FACTION_BAR_COLORS

function ReputationBar:Init()
    self:Update()
end

function ReputationBar:Update()
    local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
    if not name then
        local color = FACTION_BAR_COLORS[1]
        self:SetColor(color.r, color.g, color.b)
        self:SetValues()
        self:SetText(_G.REPUTATION)
        return
    end

    local description
    if C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold = C_Reputation.GetFactionParagonInfo(factionID)
        min, max, value = 0, threshold, currentValue
        reaction = PARAGON_FACTION_COLOR_INDEX
        description = L.Paragon
    else
        local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
        if friendID then
            if nextFriendThreshold then
                min, max, value = friendThreshold, nextFriendThreshold, friendRep
            else
                -- max rank, make it look like a full bar
                min, max, value = 0, 1, 1;
            end

            reaction = FRIEND_FACTION_COLOR_INDEX
            description = friendTextLevel
        else
            description = _G['FACTION_STANDING_LABEL' .. reaction]
        end
    end

    max = max - min
    value = (value - min) % max

    local color = FACTION_BAR_COLORS[reaction]
    self:SetColor(color.r, color.g, color.b)
    self:SetValues(value, max)
    self:UpdateText(name, value, max, description)
end

function ReputationBar:IsModeActive()
    return GetWatchedFactionInfo() ~= nil
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['reputation'] = ReputationBar
Addon.ReputationBar = ReputationBar
