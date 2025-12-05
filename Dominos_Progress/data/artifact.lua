if not (C_ArtifactUI and select(4, GetBuildInfo()) < 80000) then return end

local Addon = select(2, ...)

local IsEquippedArtifactDisabled
if C_ArtifactUI.IsEquippedArtifactDisabled ~= nil then
    IsEquippedArtifactDisabled = C_ArtifactUI.IsEquippedArtifactDisabled
else
    IsEquippedArtifactDisabled = function() return false end
end

local ArtifactPower = {}

function ArtifactPower:GetValues()
    if not self:IsActive() then
        return 0, 1
    end

    local _, _, _, _, artifactTotalXP, artifactPointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
    local _, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(artifactPointsSpent, artifactTotalXP, artifactTier)

    return xp, xpForNextPoint
end

function ArtifactPower:GetLabel()
    return ARTIFACT_POWER
end

function ArtifactPower:GetColor()
    return Addon.Config:GetColor('artifact')
end

function ArtifactPower:IsActive()
    return HasArtifactEquipped() and not (C_ArtifactUI.IsEquippedArtifactMaxed() or IsEquippedArtifactDisabled())
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders['artifact'] = ArtifactPower
