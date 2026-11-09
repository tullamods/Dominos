-- the context menu for an action bar in config mode
local _, Addon = ...

-- which parts of a button to show
local function getAppearanceControls(bar)
    local controls = {}

    for _, prop in ipairs(bar.ButtonProps) do
        tinsert(controls, {
            type = 'check',
            -- a hack to work around naming consistency on my part
            name = (prop == 'Counts' and 'ShowCountText') or ('Show' .. prop),
            get = 'Showing' .. prop,
            set = 'SetShow' .. prop
        })
    end

    return controls
end

local function addStateGroup(controls, categoryName, stateType)
    if not Addon.BarStates:Exists(stateType) then
        return
    end

    tinsert(controls, {
        type = 'header',
        name = categoryName
    })

    for _, state in Addon.BarStates:GetAll(stateType) do
        local id = state.id

        tinsert(controls, {
            type = 'pagePicker',
            name = state.text or ('State_' .. id:upper()),
            get = function(bar)
                return bar:GetPageOffset(id)
            end,
            set = function(bar, value)
                bar:SetPageOffset(id, value)
            end
        })
    end
end

local function getPagingControls()
    local controls = {}

    addStateGroup(controls, UnitClass('player'), 'class')
    addStateGroup(controls, (UnitRace('player')), 'race')
    addStateGroup(controls, 'Modifiers', 'modifier')
    addStateGroup(controls, 'QuickPaging', 'page')
    addStateGroup(controls, 'Targeting', 'target')

    return controls
end

Addon.ActionBar.contextMenu = Addon.ButtonBar.contextMenu:Extend {
    {
        insert = 'General',
        before = 'ColumnsSlider',
        controls = {
            {
                type = 'slider',
                name = 'NumButtons',
                min = 1,
                max = 'MaxLength',
                get = 'NumButtons',
                set = 'SetNumButtons'
            }
        }
    },
    {
        addPanel = 'Appearance',
        after = 'General',
        controls = getAppearanceControls
    },
    {
        addPanel = 'Paging',
        after = 'Appearance',
        controls = getPagingControls
    }
}
