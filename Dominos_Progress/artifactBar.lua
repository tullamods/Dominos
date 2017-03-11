local AddonName, Addon = ...
local Dominos = _G.Dominos
local ArtifactBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

local GetEquippedArtifactInfo = _G.C_ArtifactUI.GetEquippedArtifactInfo
local GetCostForPointAtRank = _G.C_ArtifactUI.GetCostForPointAtRank

function ArtifactBar:Init()
    self:SetColor(Addon.Config:GetColor('artifact'))
    self:Update()
end

function ArtifactBar:GetDefaults()
    local defaults = ArtifactBar.proto.GetDefaults(self)

    defaults.y = defaults.y - 16

    return defaults
end

function ArtifactBar:Update()
    if not self:IsModeActive() then
        self:SetValues()
        self:SetText(_G.ARTIFACT_POWER)
        return
    end

    local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop, artifactTier = GetEquippedArtifactInfo()
    local pointsAvailable = 0
    local nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable, artifactTier) or 0

    while xp >= nextRankCost  do
        xp = xp - nextRankCost
        pointsAvailable = pointsAvailable + 1
        nextRankCost = GetCostForPointAtRank(pointsSpent + pointsAvailable, artifactTier) or 0
    end

    self:SetValues(xp, nextRankCost)
    self:UpdateText(_G.ARTIFACT_POWER, xp, nextRankCost, pointsAvailable)
end

function ArtifactBar:IsModeActive()
    return HasArtifactEquipped()
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['artifact'] = ArtifactBar
Addon.ArtifactBar = ArtifactBar
