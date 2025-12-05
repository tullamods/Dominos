local _, Addon = ...

local COPPER_PER_GOLD = 10000

local Gold = {}

function Gold:GetValues()
    local gold = GetMoney()
    local max = Addon.Config:GoldGoal()
    local realm

    if DataStore then
        realm = 0
        for _, c in pairs(DataStore:GetCharacters()) do
            realm = realm + DataStore:GetMoney(c)
        end
        realm = realm - gold
    else
        realm = 0
    end

    if max == 0 then
        max = (gold + realm) / COPPER_PER_GOLD
    end

    -- Return values in gold (convert from copper)
    return gold / COPPER_PER_GOLD, max, realm / COPPER_PER_GOLD
end

function Gold:GetLabel()
    return MONEY
end

function Gold:GetColor()
    return Addon.Config:GetColor("gold")
end

function Gold:GetBonusColor()
    return Addon.Config:GetColor("gold_realm")
end

function Gold:IsActive()
    local goal = Addon.Config:GoldGoal()
    return goal and goal > 0
end

-- register this as a possible progress bar mode
Addon.dataProviders = Addon.dataProviders or {}
Addon.dataProviders["gold"] = Gold
