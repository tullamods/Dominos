-- the context menu for an action bar in config mode
local _, Addon = ...

-- the paging dropdowns offer every bar, so the list is made again only when the
-- number of bars changes
local pagingItems = {}
local pagingItemsNumBars = -1

local function getPagingItems()
    local numBars = Addon:NumBars()

    if pagingItemsNumBars ~= numBars then
        local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

        pagingItems = {
            {
                value = -1,
                text = L.PagingDefault
            }
        }

        for i = 1, numBars do
            pagingItems[i + 1] = {
                value = i,
                text = L.ActionBarNumber:format(i)
            }
        end

        pagingItemsNumBars = numBars
    end

    return pagingItems
end

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
            type = 'dropdown',
            name = state.text or ('State_' .. id:upper()),
            items = getPagingItems,
            get = function(bar)
                local offset = bar:GetOffset(id) or -1

                if offset > -1 then
                    return (bar.id + offset - 1) % Addon:NumBars() + 1
                end

                return offset
            end,
            set = function(bar, value)
                local offset

                if value == -1 then
                    offset = nil
                elseif value < bar.id then
                    offset = (Addon:NumBars() - bar.id) + value
                else
                    offset = value - bar.id
                end

                bar:SetOffset(id, offset)
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
