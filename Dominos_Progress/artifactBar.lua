local AddonName, Addon = ...
local Dominos = _G.Dominos
local ArtifactBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

do
    local GetEquippedArtifactInfo = _G.C_ArtifactUI.GetEquippedArtifactInfo
    local GetCostForPointAtRank = _G.C_ArtifactUI.GetCostForPointAtRank

	function ArtifactBar:Init()
        self:SetColor(1.0, 0.24, 0, 1)
        self:Update()
	end

    function ArtifactBar:GetDefaults()
        local defaults = ArtifactBar.proto.GetDefaults(self)

        defaults.y = defaults.y - 16

        return defaults
    end

	function ArtifactBar:Update()
        if not HasArtifactEquipped() then
            self:SetValues()
            self:SetText('')
            return
        end

        local itemID, altItemID, name, icon, totalXP, pointsSpent = GetEquippedArtifactInfo()
        local pointsAvailable = 0
        local nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable) or 0

        while totalXP >= nextRankCost  do
            totalXP = totalXP - nextRankCost
            pointsAvailable = pointsAvailable + 1
            nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable) or 0
        end

        self:SetValues(totalXP, nextRankCost)
		if pointsAvailable > 0 then
			self:SetText('%s: %s / %s (+%s)', name, BreakUpLargeNumbers(totalXP), BreakUpLargeNumbers(nextRankCost), pointsAvailable)
		else
			self:SetText('%s: %s / %s', name, BreakUpLargeNumbers(totalXP), BreakUpLargeNumbers(nextRankCost))
		end
	end
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['artifact'] = ArtifactBar