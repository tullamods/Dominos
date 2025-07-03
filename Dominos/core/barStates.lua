-- BarStates is a utility defining ids that map to certain macro conditions

local _, Addon = ...
local states = {}

local getSpellName
if type(GetSpellInfo) == "function" then
    getSpellName = function(spell) return (GetSpellInfo(spell)) end
else
    getSpellName = C_Spell.GetSpellName
end

local function getStateIterator(type, i)
    for j = i + 1, #states do
        local state = states[j]
        if state and ((not type) or state.type == type) then
            return j, state
        end
    end
end

local BarStates = {
    add = function(_, state, index)
        if index then
            return table.insert(states, index, state)
        end
        return table.insert(states, state)
    end,

    getAll = function(_, type)
        return getStateIterator, type, 0
    end,

    get = function(_, id)
        for _, v in pairs(states) do
            if v.id == id then
                return v
            end
        end
    end,

    map = function(_, f)
        local results = {}
        for _, v in ipairs(states) do
            if f(v) then
                table.insert(results, v)
            end
        end
        return results
    end
}

Addon.BarStates = BarStates

local function addState(stateType, stateID, stateValue, stateText)
    return BarStates:add {
        type = stateType,
        id = stateID,
        value = stateValue,
        text = stateText
    }
end

-- some class states are a bit dynamic
-- druid forms, for instance, can vary based on how many different abilities
-- are known
local function addFormState(stateType, stateID, ...)
    local argCount = select("#", ...)
    local lookupFormConditional, name

    if argCount > 1 then
        local spells = { ... }

        lookupFormConditional = function()
            for i = 1, GetNumShapeshiftForms() do
                local _, _, _, formSpellID = GetShapeshiftFormInfo(i)

                for _, spellID in ipairs(spells) do
                    if spellID == formSpellID then
                        return ('[form:%d]'):format(i)
                    end
                end
            end
        end

        for _, spellID in ipairs(spells) do
            name = getSpellName(spellID)
            if name then
                break
            end
        end
    elseif argCount > 0 then
        local spellID = ...

        lookupFormConditional = function()
            for i = 1, GetNumShapeshiftForms() do
                local _, _, _, formSpellID = GetShapeshiftFormInfo(i)

                if spellID == formSpellID then
                    return ('[form:%d]'):format(i)
                end
            end
        end

        name = getSpellName(spellID)
    else
        error("Usage: addFormState(stateType, stateID, spellID1, spellID2, ...)")
    end

    addState(stateType, stateID, lookupFormConditional, name)
end

local function getEquippedConditional(classId, subclassId)
    local name = C_Item.GetItemSubClassInfo(classId, subclassId)

    return ('[equipped:%s]'):format(name)
end

-- modifiers
addState('modifier', 'selfcast', '[mod:SELFCAST]', AUTO_SELF_CAST_KEY_TEXT)
addState('modifier', 'ctrlAltShift', '[mod:alt,mod:ctrl,mod:shift]')
addState('modifier', 'ctrlAlt', '[mod:alt,mod:ctrl]')
addState('modifier', 'altShift', '[mod:alt,mod:shift]')
addState('modifier', 'ctrlShift', '[mod:ctrl,mod:shift]')
addState('modifier', 'alt', '[mod:alt]', ALT_KEY)
addState('modifier', 'ctrl', '[mod:ctrl]', CTRL_KEY)
addState('modifier', 'shift', '[mod:shift]', SHIFT_KEY)
addState('modifier', 'meta', '[mod:meta]')

-- paging
for i = 2, NUM_ACTIONBAR_PAGES do
    addState('page', ('page%d'):format(i), ('[bar:%d]'):format(i), _G['BINDING_NAME_ACTIONPAGE' .. i])
end

-- dragonriding
if Addon:IsBuild("retail") then
    addState('class', 'dragonriding', '[bonusbar:5]', GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE)
end

-- class
local class = UnitClassBase('player')
local race = select(2, UnitRace('player'))

if class == 'DRUID' then
    addState('class', 'bear', '[bonusbar:3]', getSpellName(5487))
    addState('class', 'prowl', '[bonusbar:1,stealth]', getSpellName(5215))
    addState('class', 'cat', '[bonusbar:1]', getSpellName(768))

    if Addon:IsBuild('retail') then
        addState('class', 'moonkin', '[bonusbar:4]', getSpellName(24858))

        addFormState('class', 'tree', 114282)
        addFormState('class', 'travel', 783)
        addFormState('class', 'stag', 210053)
    else
        addFormState('class', 'moonkin', 24858)

        if Addon:IsBuild('cata', 'wrath', 'bcc') then
            addFormState('class', 'tree', 33891)
        end

        addFormState('class', 'travel', 783)
        addFormState('class', 'aquatic', 1066)

        -- flight form & swift flight form
        if Addon:IsBuild('mists', 'cata', 'wrath', 'bcc') then
            addFormState('class', 'flight', 33943, 40120)
        end
    end
elseif class == 'DEATHKNIGHT' then
    if Addon:IsBuild('mists', 'cata', 'wrath') then
        addFormState('class', 'blood', 48266)
        addFormState('class', 'frost', 48263)
        addFormState('class', 'unholy', 48265)
    end
elseif class == 'EVOKER' then
    addState('class', 'soar', '[bonusbar:1]', getSpellName(369536))
elseif class == 'HUNTER' then
    if Addon:IsBuild('mists', 'cata') then
        addFormState('class', 'hawk', 13165)
        addFormState('class', 'cheetah', 5118)
        addFormState('class', 'pack', 13159)

        if not Addon:IsBuild('mists') then
            addFormState('class', 'wild', 20043)
        end
    end
elseif class == 'MONK' then
    if Addon:IsBuild('mists') then
        addFormState('class', 'ox', 115069)
        addFormState('class', 'tiger', 103985)
        addFormState('class', 'serpent', 115070)
    end
elseif class == 'PALADIN' then
    if Addon:IsBuild('retail') then
        addFormState('class', 'concentration', 317920)
        addFormState('class', 'crusader', 32223)
        addFormState('class', 'devotion', 465)
        addFormState('class', 'retribution', 183435)
        addState('class', 'shield', getEquippedConditional(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield))
    elseif Addon:IsBuild('mists') then
        addFormState('class', 'truth', 31801)
        addFormState('class', 'righteousness', 20154)
        addFormState('class', 'insight', 20165)
    elseif Addon:IsBuild('cata') then
        addFormState('class', 'concentration', 19746)
        addFormState('class', 'crusader', 32223)
        addFormState('class', 'devotion', 465)
        addFormState('class', 'resistance', 19891)
        addFormState('class', 'retribution', 7294)
    elseif Addon:IsBuild('wrath') then
        addFormState('class', 'concentration', 19746)
        addFormState('class', 'crusader', 32223)
        addFormState('class', 'devotion', 27149)
        addFormState('class', 'fire', 27153)
        addFormState('class', 'frost', 27152)
        addFormState('class', 'retribution', 27150)
        addFormState('class', 'shadow', 27151)
    elseif Addon:IsBuild('bcc') then
        addFormState('class', 'concentration', 19746)
        addFormState('class', 'crusader', 32223)
        addFormState('class', 'devotion', 10292)
        addFormState('class', 'fire', 19899)
        addFormState('class', 'frost', 19898)
        addFormState('class', 'retribution', 10301)
        addFormState('class', 'shadow', 19896)
    end
elseif class == 'PRIEST' then
    if Addon:IsBuild('retail') then
        addFormState('class', 'shadowform', 232698)
    else
        addState('class', 'shadowform', '[form:1]', getSpellName(15473))
    end
elseif class == 'ROGUE' then
    -- classic shadowdance
    if Addon:IsBuild('mists', 'cata', 'wrath') then
        addState('class', 'shadowdance', '[bonusbar:2]', getSpellName(51713))
        -- retail shadowdance
    elseif getSpellName(185313) then
        addState('class', 'shadowdance', '[bonusbar:1,form:2]', getSpellName(185313))
    end

    addState('class', 'stealth', '[bonusbar:1]', getSpellName(1784))
elseif class == 'WARLOCK' then
    if Addon:IsBuild('mists') then
        addFormState('class', 'metamorphosis', 103958)
    elseif not Addon:IsBuild('retail') then
        addState('class', 'metamorphosis', '[form:1]', getSpellName(47241))
    end
elseif class == 'WARRIOR' then
    if Addon:IsBuild('retail') then
        addFormState('class', 'battle', 386164)
        addFormState('class', 'defensive', 386208)
    else
        addFormState('class', 'battle', 2457)
        addFormState('class', 'defensive', 71)
        addFormState('class', 'berserker', 2458)
    end

    if Addon:IsBuild("retail", "mists", "cata") then
        addState('class', 'shield', getEquippedConditional(Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield))
    end
end

-- race
if race == 'NightElf' then
    local name = (getSpellName(58984) or getSpellName(20580))

    if name then
        addState('class', 'shadowmeld', '[stealth]', name)
    end
end

-- target reaction
addState('target', 'help', '[help]')
addState('target', 'harm', '[harm]')
addState('target', 'notarget', '[noexists]')
