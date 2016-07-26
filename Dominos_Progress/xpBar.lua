local AddonName, Addon = ...
local Dominos = _G.Dominos
local ExperienceBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

function ExperienceBar:Init()
	self:SetColor(0.58, 0, 0.55, 1)
	self:SetBonusColor(0, 0.39, 0.88)
	self:Update()
end

function ExperienceBar:Update()
	local value = UnitXP('player')
	local max = UnitXPMax('player')
	local rest = GetXPExhaustion() or 0

	self:SetValues(value, max, rest)
	self:UpdateText(_G.XP, value, max, rest)
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['xp'] = ExperienceBar
Addon.ExperienceBar = ExperienceBar