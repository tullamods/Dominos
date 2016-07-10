local AddonName, Addon = ...
local Dominos = _G.Dominos
local ExperienceBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

function ExperienceBar:Init()
	self:SetColor(0.58, 0.0, 0.55, 1)
	-- self:SetBonusColor(0.25, 0, 0.22, 1)
	self:SetBonusColor(0.47, 0, 1, 0.8)
	self:Update()
end

function ExperienceBar:Update()
	local value = UnitXP('player')
	local max = UnitXPMax('player')
	local rest = GetXPExhaustion()

	self:SetValues(value, max, rest)

	if rest and rest > 0 then
		self:SetText('%s: %s / %s (+%s)', XP, BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), BreakUpLargeNumbers(rest))
	else
		self:SetText('%s: %s / %s', XP, BreakUpLargeNumbers(value), BreakUpLargeNumbers(max))
	end
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['xp'] = ExperienceBar