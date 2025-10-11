if not _G.C_AzeriteItem then return end

local Addon = select(2, ...)
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local AzeriteBar = Dominos:CreateClass("Frame", Addon.ProgressBar)
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-Progress")

function AzeriteBar:Init()
    self:SetColor(Addon.Config:GetColor("azerite"))
    self:Update()
end

function AzeriteBar:GetDefaults()
    local defaults = AzeriteBar.proto.GetDefaults(self)

    defaults.y = defaults.y - 16

    return defaults
end

function AzeriteBar:Update()
    if not self:IsModeActive() then
        self:SetValues()
        self:UpdateText(L.Azerite, 0, 0, 0)
        return
    end

    local item = C_AzeriteItem.FindActiveAzeriteItem()
    if not (item and item:IsEquipmentSlot()) then
        self:SetValues()
        self:UpdateText(L.Azerite, 0, 0, 0)
        return
    end

    local value, max = C_AzeriteItem.GetAzeriteItemXPInfo(item)
    local powerLevel = C_AzeriteItem.GetPowerLevel(item)

    self:SetValues(value, max)
    self:UpdateText(L.Azerite, value, max, powerLevel)
end

function AzeriteBar:IsModeActive()
    local item = C_AzeriteItem.FindActiveAzeriteItem()

    return item
        and not C_AzeriteItem.IsAzeriteItemAtMaxLevel()
        and C_AzeriteItem.IsAzeriteItemEnabled(item)
        and item:IsEquipmentSlot()
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes["azerite"] = AzeriteBar
Addon.AzeriteBar = AzeriteBar
