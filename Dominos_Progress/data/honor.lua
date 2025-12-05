if not IsWatchingHonorAsXP then return end

local _, Addon = ...
local Honor = {}

function Honor:GetValues()
    local value = UnitHonor('player') or 0
    local max = UnitHonorMax('player') or 1
    return value, max
end

function Honor:GetLabel()
    return HONOR
end

function Honor:GetColor()
    return Addon.Config:GetColor('honor')
end

function Honor:IsActive()
    return IsWatchingHonorAsXP() or C_PvP.IsActiveBattlefield() or IsInActiveWorldPVP()
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders['honor'] = Honor
