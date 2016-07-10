local AddonName, Addon = ...
local ArtifactBar = Dominos:CreateClass('Frame', Dominos.ProgressBar)

do
    local GetEquippedArtifactInfo = _G.C_ArtifactUI.GetEquippedArtifactInfo
    local GetCostForPointAtRank = _G.C_ArtifactUI.GetCostForPointAtRank

	ArtifactBar.type = 'artifact'

	function ArtifactBar:Init()
        if not HasArtifactEquipped() then
            self:SetToNextType()
        else
            self:SetColor(1.0, 0.24, 0, 1)
            self:SetRestColor(1.0, 0.47, 0.3, 1)
            self:Update()
        end
	end

    -- so the artifact power bar is a bit odd, as its a bar where you can choose to
    -- level up or not. Blizzard renders this as whatever your xp would look like if
    -- you leveled up as many times as you could. I'm going to render this as
    -- as a single bar, with any XP beyond the amount needed for the next point
    -- represented as rest
	function ArtifactBar:Update()
        if not HasArtifactEquipped() then
            self:SetValue(0, 0, 1):SetRestValue(0)
            self:SetText('')
            return
        end

        local itemID, altItemID, name, icon, totalXP, pointsSpent = GetEquippedArtifactInfo()
        local nextRankCost = GetCostForPointAtRank(pointsSpent)
        local value = min(totalXP, nextRankCost)
        local max = self:GetMaximumCost(itemID)
        local rest = totalXP - value


        self:SetValue(value, 0, max):SetRestValue(rest)
        self:SetText(ARTIFACT_POWER_BAR, totalXP, nextRankCost)
	end

    -- it might be be benefical to memoize this
    function ArtifactBar:GetMaximumCost(itemID)
        local rank = 0
        local sum = 0
        local cost = 0

        repeat
            cost = GetCostForPointAtRank(rank) or 0
            sum = sum + cost
        until cost == 0

        return sum
    end

	-- the one time i get to use my favorite feature of lua
	function ArtifactBar:SetToNextType()
		Addon.HonorBar:Bind(self)
		self:Init()
	end
end

Addon.ArtifactBar = ArtifactBar