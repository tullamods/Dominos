local AddonName, Addon = ...
local Dominos = _G.Dominos
local HonorBar = Dominos:CreateClass('Frame', Addon.ProgressBar)

function HonorBar:Init()
	self:SetColor(1.0, 0.24, 0, 1)
	self:SetBonusColor(1.0, 0.71, 0, 1)
	self:Update()
end

function HonorBar:Update()
	local value = UnitHonor('player')
	local max = UnitHonorMax('player')
	local bonus = GetHonorExhaustion()

	self:SetValues(value, max, bonus)

	if bonus and bonus > 0 then
		self:SetText('%s: %s / %s (+%s)', HONOR, BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), BreakUpLargeNumbers(bonus))
	else
		self:SetText('%s: %s / %s', HONOR, BreakUpLargeNumbers(value), BreakUpLargeNumbers(max))
	end
end

-- register this as a possible progress bar mode
Addon.progressBarModes = Addon.progressBarModes or {}
Addon.progressBarModes['honor'] = HonorBar