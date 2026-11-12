if not (C_ArtifactUI and select(4, GetBuildInfo()) < 80000) then return end

local _, Addon = ...

local IsEquippedArtifactDisabled
if C_ArtifactUI.IsEquippedArtifactDisabled ~= nil then
	IsEquippedArtifactDisabled = C_ArtifactUI.IsEquippedArtifactDisabled
else
	IsEquippedArtifactDisabled = function()
		return false
	end
end

---@class ArtifactProvider : DataProvider
local ArtifactPower = {
	colorKeys = { 'artifact' }
}

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

-- ArtifactTickMixin:OnEnter, for the whole bar instead of just the tick
function ArtifactPower:SetupTooltip(tooltip)
	if not (self:IsActive() and ARTIFACT_POWER_TOOLTIP_TITLE and ArtifactBarGetNumArtifactTraitsPurchasableFromXP) then
		Addon.DataProvider.SetupTooltip(self, tooltip)
		return
	end

	local _, _, _, _, artifactTotalXP, artifactPointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
	local numPointsAvailable, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(artifactPointsSpent, artifactTotalXP, artifactTier)

	tooltip:SetText(
		ARTIFACT_POWER_TOOLTIP_TITLE:format(BreakUpLargeNumbers(artifactTotalXP, true), BreakUpLargeNumbers(xp, true), BreakUpLargeNumbers(xpForNextPoint, true)),
		HIGHLIGHT_FONT_COLOR:GetRGB()
	)

	if ARTIFACT_POWER_TOOLTIP_BODY then
		tooltip:AddLine(ARTIFACT_POWER_TOOLTIP_BODY:format(numPointsAvailable), nil, nil, nil, true)
	end
end

function ArtifactPower:GetColor()
	return Addon.Config:GetColor('artifact')
end

function ArtifactPower:GetNativeTextures()
	return 'UI-HUD-ExperienceBar-Fill-ArtifactPower'
end

function ArtifactPower:IsActive()
	return HasArtifactEquipped() and not (C_ArtifactUI.IsEquippedArtifactMaxed() or IsEquippedArtifactDisabled())
end

Addon.dataProviders['artifact'] = ArtifactPower
