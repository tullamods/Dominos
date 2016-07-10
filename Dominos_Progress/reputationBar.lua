local AddonName, Addon = ...
local ReputationBar = Dominos:CreateClass('Frame', Dominos.ProgressBar)

do
    local FRIEND_ID_FACTION_COLOR_INDEX = 5

    ReputationBar.type = 'rep'

    function ReputationBar:Init()
        if not GetWatchedFactionInfo() then
            self:SetToNextType()
        else
            self:SetRestValue(0)
            self:Update()
        end
    end

    function ReputationBar:Update()
        local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
        if not name then
            local color = FACTION_BAR_COLORS[0]

            self:SetColor(color.r, color.g, color.b)
            self:SetValue(0, 0, 1)
            self:SetText('')

            return
        end

        local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
        if friendID then
            if nextFriendThreshold then
                min, max, value = friendThreshold, nextFriendThreshold, friendRep
            else
                -- max rank, make it look like a full bar
                min, max, value = 0, 1, 1;
            end

            reaction = FRIEND_ID_FACTION_COLOR_INDEX
        else
            friendTextLevel = _G['FACTION_STANDING_LABEL' .. reaction]
        end

        max = max - min
        value = value - min

        local color = FACTION_BAR_COLORS[reaction]

        self:SetColor(color.r, color.g, color.b)
        self:SetValue(value, 0, max)
        self:SetText('%s: %s / %s (%s)', name, BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), friendTextLevel)
    end

    -- the one time i get to use my favorite feature of lua
    function ReputationBar:SetToNextType()
        Addon.ArtifactBar:Bind(self)
        self:Init()
    end
end

Addon.ReputationBar = ReputationBar