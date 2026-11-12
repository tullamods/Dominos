if not C_AzeriteItem then return end

local _, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

---@class AzeriteProvider : DataProvider
local AzeritePower = {
	colorKeys = { 'azerite' }
}

-- the heart, only while it's worn
local function getEquippedItem()
	local item = C_AzeriteItem.FindActiveAzeriteItem()
	if item and item:IsEquipmentSlot() then
		return item
	end
end

local function isActiveItem(item)
	return item ~= nil
		and not C_AzeriteItem.IsAzeriteItemAtMaxLevel()
		and C_AzeriteItem.IsAzeriteItemEnabled(item)
end

function AzeritePower:GetValues()
	local item = getEquippedItem()
	if not isActiveItem(item) then
		return 0, 1
	end

	local value, max = C_AzeriteItem.GetAzeriteItemXPInfo(item)
	return value, max
end

function AzeritePower:GetLabel()
	return L.Azerite
end

-- AzeriteBarMixin:GetLevel
local function getPowerLevel(item)
	if C_AzeriteItem.IsUnlimitedLevelingUnlocked and C_AzeriteItem.IsUnlimitedLevelingUnlocked() then
		return C_AzeriteItem.GetUnlimitedPowerLevel(item)
	end
	return C_AzeriteItem.GetPowerLevel(item)
end

-- AzeriteBarMixin:OnEnter and SetupPointsTooltip
function AzeritePower:SetupTooltip(tooltip, refreshTooltip)
	local item = C_AzeriteItem.FindActiveAzeriteItem()

	if not (item and item:IsEquipmentSlot()) then
		if item and HEART_OF_AZEROTH_MISSING_ERROR then
			tooltip:SetText(HEART_OF_AZEROTH_MISSING_ERROR, HIGHLIGHT_FONT_COLOR:GetRGB())
		else
			Addon.DataProvider.SetupTooltip(self, tooltip)
		end
		return
	end

	if not AZERITE_POWER_TOOLTIP_TITLE then
		Addon.DataProvider.SetupTooltip(self, tooltip)
		return
	end

	local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(item)
	tooltip:SetText(AZERITE_POWER_TOOLTIP_TITLE:format(getPowerLevel(item), totalLevelXP - xp), HIGHLIGHT_FONT_COLOR:GetRGB())

	if not AZERITE_POWER_TOOLTIP_BODY then
		return
	end

	-- the name can still be loading. come back once it's in
	local heart = Item:CreateFromItemLocation(item)
	if heart:IsItemDataCached() then
		tooltip:AddLine(AZERITE_POWER_TOOLTIP_BODY:format(heart:GetItemName()))
	else
		heart:ContinueOnItemLoad(refreshTooltip)
	end
end

function AzeritePower:GetColor()
	return Addon.Config:GetColor("azerite")
end

function AzeritePower:GetNativeTextures()
	return 'UI-HUD-ExperienceBar-Fill-ArtifactPower'
end

function AzeritePower:IsActive()
	return isActiveItem(getEquippedItem())
end

Addon.dataProviders["azerite"] = AzeritePower
