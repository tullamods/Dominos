local AddonName, Addon = ...
local Dominos = _G.Dominos
local HonorBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

function HonorBar:Init()
	self:SetColor(1.0, 0.24, 0, 1)
	self:SetBonusColor(1.0, 0.71, 0, 1)
	self:Update()
end

function HonorBar:Update()
	local value = UnitHonor('player') or 0
	local max = UnitHonorMax('player') or 1
	local bonus = GetHonorExhaustion() or 0

	self:SetValues(value, max, bonus)
	self:UpdateText(_G.HONOR, value, max, bonus)
end

function HonorBar:IsModeActive()
	return IsWatchingHonorAsXP() or InActiveBattlefield()
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['honor'] = HonorBar
Addon.HonorBar = HonorBar