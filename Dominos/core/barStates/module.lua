-- BarStates is a utility defining ids that map to certain macro conditions
local _, Addon = ...

local statesByType = {
    modifier = {},
    page = {},
    class = {},
    race = {},
    target = {}
}

local BarStates = {}

local function getFormConditional(state)
    local spells = state.spells
    for i = 1, GetNumShapeshiftForms() do
        local _, _, _, spellID = GetShapeshiftFormInfo(i)
        for j = 1, #spells do
            if spells[j] == spellID then
                return ('[form:%d]'):format(i)
            end
        end
    end
end

function BarStates:Load(config)
    local function addState(state)
        local states = statesByType[state.type]
        states[#states + 1] = state
    end

    local function getLabelText(label)
        if type(label) == 'number' then
            return C_Spell.GetSpellName(label)
        end
        return label
    end

    local function addFormState(stateType, id, spellIDs)
        local spells = type(spellIDs) == 'table' and spellIDs or {spellIDs}

        addState{
            id = id,
            type = stateType,
            value = getFormConditional,
            spells = spells,
            text = C_Spell.GetSpellName(spells[1])
        }
    end

    local function addEquippedState(stateType, id, itemClass, label)
        local classID, subclassID = unpack(itemClass)
        local conditional = ('[worn:%s]'):format(C_Item.GetItemSubClassInfo(classID, subclassID))

        addState{
            id = id,
            type = stateType,
            value = conditional,
            text = getLabelText(label)
        }
    end

    local function addStates(stateType, values)
        for _, state in ipairs(values) do
            local id = state[1] or state.id

            if state.form then
                addFormState(stateType, id, state.form)
            elseif state.equipped then
                addEquippedState(stateType, id, state.equipped, state.label)
            else
                addState{
                    id = id,
                    type = stateType,
                    value = state.macro,
                    text = getLabelText(state.label)
                }
            end
        end
    end

    for _, type in ipairs{'modifier', 'page', 'target'} do
        if config[type] then
            addStates(type, config[type])
        end
    end

    if config.class then
        if config.class.ALL then
            addStates('class', config.class.ALL)
        end

        local classStates = config.class[UnitClassBase('player')]
        if classStates then
            addStates('class', classStates)
        end
    end

    if config.race then
        local raceStates = config.race[select(2, UnitRace('player'))]
        if raceStates then
            addStates('race', raceStates)
        end
    end
end

function BarStates:LoadClass(config)
    self:Load{ class = config }
end

function BarStates:Clear(type)
    statesByType[type] = {}
end

function BarStates:ClearAll()
    for stateType in pairs(statesByType) do
        statesByType[stateType] = {}
    end
end

function BarStates:GetAll(type)
    return ipairs(statesByType[type])
end

function BarStates:Exists(type)
    return #statesByType[type] > 0
end

Addon.BarStates = BarStates