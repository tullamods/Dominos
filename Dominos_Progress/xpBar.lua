local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local ExperienceBar = Dominos:CreateClass("Frame", Addon.ProgressBar)

function ExperienceBar:Init()
	self:Update()
	self:SetColor(Addon.Config:GetColor("xp"))
	self:SetBonusColor(Addon.Config:GetColor("xp_bonus"))
end

function ExperienceBar:Update()
	local value = UnitXP("player")
	local max = UnitXPMax("player")
	local rest = GetXPExhaustion() or 0

	self:SetValues(value, max, rest)
	self:UpdateText(XP, value, max, rest)
end

function ExperienceBar:IsModeActive()
	if UnitLevel("player") == (GetMaxLevelForPlayerExpansion or GetMaxPlayerLevel)() then
		return false
	end

	return not IsXPUserDisabled()
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes["xp"] = ExperienceBar
Addon.ExperienceBar = ExperienceBar
