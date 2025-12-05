if not C_AzeriteItem then return end

local Addon = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

local AzeritePower = {}

function AzeritePower:GetValues()
    if not self:IsActive() then
        return 0, 1
    end

    local item = C_AzeriteItem.FindActiveAzeriteItem()
    if not (item and item:IsEquipmentSlot()) then
        return 0, 1
    end

    local value, max = C_AzeriteItem.GetAzeriteItemXPInfo(item)
    return value, max
end

function AzeritePower:GetLabel()
    return L.Azerite
end

function AzeritePower:GetColor()
    return Addon.Config:GetColor("azerite")
end

function AzeritePower:GetBonus()
    if not self:IsActive() then
        return 0
    end

    local item = C_AzeriteItem.FindActiveAzeriteItem()
    if not (item and item:IsEquipmentSlot()) then
        return 0
    end

    return C_AzeriteItem.GetPowerLevel(item)
end

function AzeritePower:IsActive()
    local item = C_AzeriteItem.FindActiveAzeriteItem()

    return item
        and not C_AzeriteItem.IsAzeriteItemAtMaxLevel()
        and C_AzeriteItem.IsAzeriteItemEnabled(item)
        and item:IsEquipmentSlot()
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders["azerite"] = AzeritePower
