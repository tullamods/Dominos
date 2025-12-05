local _, Addon = ...

local Experience = {}

function Experience:GetValues()
	local value = UnitXP("player")
	local max = UnitXPMax("player")
	local bonus = GetXPExhaustion() or 0
	return value, max, bonus
end

function Experience:GetLabel()
	return XP
end

function Experience:GetColor()
	return Addon.Config:GetColor("xp")
end

function Experience:GetBonusColor()
	return Addon.Config:GetColor("xp_bonus")
end

function Experience:IsActive()
	if UnitLevel("player") == (GetMaxLevelForPlayerExpansion or GetMaxPlayerLevel)() then
		return false
	end
	return not IsXPUserDisabled()
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders["xp"] = Experience
