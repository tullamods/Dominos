-- How action bars use addresses, for tooltips and highlights

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

-- names of the paging states loaded for this character, by id
local function getStateNames()
    local names = {}

    for _, stateType in ipairs(ParentAddon.ActionBar.statePrecedence) do
        for _, state in ParentAddon.BarStates:GetAll(stateType) do
            names[state.id] = state.text or rawget(L, 'State_' .. state.id:upper()) or state.id
        end
    end

    return names
end

local function addLine(lines, address, line)
    local list = lines[address]

    if list then
        list[#list + 1] = line
    else
        lines[address] = { line }
    end
end

-- base[address] is the bar that shows it at rest. paging[address] lists
-- "Bar: State" for each loaded state that pages a bar there
function Addon:GetActionSlotUsage()
    local base, paging = {}, {}
    local stateNames = getStateNames()

    for id = 1, ParentAddon:NumBars() do
        local bar = ParentAddon.Frame:Get(id)

        if bar and bar.GetBaseOffset then
            local name = bar:GetDisplayName()
            local numButtons = bar:NumButtons()
            local offset = bar:GetBaseOffset()

            for i = 1, numButtons do
                base[offset + i] = name
            end

            for stateId, pageOffset in pairs(bar.paging) do
                local stateName = stateNames[stateId]

                if stateName then
                    local line = L.BarState:format(name, stateName)

                    for i = 1, numButtons do
                        addLine(paging, pageOffset + i, line)
                    end
                end
            end
        end
    end

    for _, lines in pairs(paging) do
        table.sort(lines)
    end

    return { base = base, paging = paging }
end

function Addon:AddActionSlotUsageToTooltip(tooltip, usage, address)
    local barName = usage.base[address]
    if barName then
        tooltip:AddLine(barName, 0.5, 0.75, 1)
    end

    local lines = usage.paging[address]
    if lines then
        for _, line in ipairs(lines) do
            tooltip:AddLine(line, 0.8, 0.8, 0.8)
        end
    end
end
