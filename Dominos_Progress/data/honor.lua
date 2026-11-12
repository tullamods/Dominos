if not IsWatchingHonorAsXP then return end

local _, Addon = ...
---@class HonorProvider : DataProvider
local Honor = {
	colorKeys = { 'honor' }
}

function Honor:GetValues()
	local value = UnitHonor('player') or 0
	local max = UnitHonorMax('player') or 1
	return value, max
end

function Honor:GetLabel()
	return HONOR
end

-- the stock bar has no tooltip, only HONOR_BAR text, so add the level the pvp ui shows
function Honor:SetupTooltip(tooltip)
	GameTooltip_SetTitle(tooltip, HONOR)

	if HONOR_LEVEL_LABEL and UnitHonorLevel then
		GameTooltip_AddNormalLine(tooltip, HONOR_LEVEL_LABEL:format(UnitHonorLevel('player')))
	end

	self:AddTooltipProgress(tooltip, self:GetValues())
end

function Honor:GetColor()
	return Addon.Config:GetColor('honor')
end

function Honor:GetNativeTextures()
	return 'UI-HUD-ExperienceBar-Fill-Honor'
end

function Honor:IsActive()
	return IsWatchingHonorAsXP() or C_PvP.IsActiveBattlefield() or IsInActiveWorldPVP()
end

Addon.dataProviders['honor'] = Honor
