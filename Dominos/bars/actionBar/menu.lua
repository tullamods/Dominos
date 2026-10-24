-- the context menu for an action bar in config mode
local _, Addon = ...

function Addon.ActionBar:OnCreateMenu(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local dropdownItems = {}
    local lastNumBars = -1

    local function getDropdownItems()
        local numBars = Addon:NumBars()

        if lastNumBars ~= numBars then
            dropdownItems = {
                {value = -1, text = L.PagingDefault}
            }

            for i = 1, numBars do
                dropdownItems[i + 1] = {
                    value = i,
                    text = L.ActionBarNumber:format(i)
                }
            end

            lastNumBars = numBars
        end

        return dropdownItems
    end

    local function addGeneralPanel()
        local panel = menu:NewPanel(L.General)

        panel:AddOptions {
            {
                type = 'slider',
                name = L.NumButtons,
                min = 1,
                max = 'MaxLength',
                get = 'NumButtons',
                set = 'SetNumButtons'
            }
        }

        panel:AddGeneralOptions()

        return panel
    end

    local function addAppearancePanel()
        local panel = menu:AddAppearancePanel()
        local options = {}

        for _, prop in ipairs(self.ButtonProps) do
            tinsert(options, {
                type = 'check',
                -- a hack to work around naming consistency on my part
                name = L[(prop == "Counts" and "ShowCountText") or ("Show" .. prop)],
                get = "Showing" .. prop,
                set = "SetShow" .. prop
            })
        end

        panel:AddOptions(options)

        return panel
    end

    local function addStateGroup(options, categoryName, stateType)
        if not Addon.BarStates:Exists(stateType) then
            return
        end

        tinsert(options, { type = 'header', name = categoryName })

        for _, state in Addon.BarStates:GetAll(stateType) do
            local id = state.id

            tinsert(options, {
                type = 'dropdown',
                name = state.text or L['State_' .. id:upper()],
                items = getDropdownItems,
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

    local function addPagingPanel()
        local panel = menu:NewPanel(L.Paging)

        local options = {}

        addStateGroup(options, UnitClass('player'), 'class')
        addStateGroup(options, (UnitRace('player')), 'race')
        addStateGroup(options, L.Modifiers, 'modifier')
        addStateGroup(options, L.QuickPaging, 'page')
        addStateGroup(options, L.Targeting, 'target')

        panel:AddOptions(options)

        return panel
    end

    -- add panels
    addGeneralPanel()
    addAppearancePanel()
    addPagingPanel()
    menu:AddVisibilityPanel()
    menu:AddAdvancedPanel()

    Addon.ActionBar.menu = menu
end
