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
                {value = -1, text = _G.DISABLE}
            }

            for i = 1, numBars do
                dropdownItems[i + 1] = {
                    value = i,
                    text = ('Action Bar %d'):format(i)
                }
            end

            lastNumBars = numBars
        end

        return dropdownItems
    end

    local function addStateGroup(panel, categoryName, stateType)
        local states = Addon.BarStates:map(function(s) return s.type == stateType end)
        if #states == 0 then
            return
        end

        panel:NewHeader(categoryName)

        for _, state in ipairs(states) do
            local id = state.id
            local name = state.text
            if type(name) == 'function' then
                name = name()
            elseif not name then
                name = L['State_' .. id:upper()]
            end

            panel:NewDropdown {
                name = name,
                items = getDropdownItems,
                get = function()
                    local owner = panel.owner
                    if owner then
                        local offset = owner:GetOffset(state.id) or -1
                        if offset > -1 then
                            return (owner.id + offset - 1) % Addon:NumBars() + 1
                        end
                        return offset
                    end
                end,
                set = function(_, value)
                    local offset

                    if value == -1 then
                        offset = nil
                    elseif value < panel.owner.id then
                        offset = (Addon:NumBars() - panel.owner.id) + value
                    else
                        offset = value - panel.owner.id
                    end

                    panel.owner:SetOffset(state.id, offset)
                end
            }
        end
    end

    local function addLayoutPanel()
        local panel = menu:NewPanel(L.Layout)

        panel.sizeSlizer = panel:NewSlider {
            name = L.Size,
            min = 1,
            max = function()
                return panel.owner:MaxLength()
            end,
            get = function()
                return panel.owner:NumButtons()
            end,
            set = function(_, value)
                panel.owner:SetNumButtons(value)

                panel.colsSlider:UpdateRange()
                panel.colsSlider:UpdateValue()
            end
        }

        panel:AddLayoutOptions()

        return panel
    end

    local function addButtonPanel()
        local panel = menu:NewPanel(L.Buttons)

        for _, prop in ipairs(self.ButtonProps) do
            panel:NewCheckButton {
                -- a hack to work around naming consistency on my part
                name = L[(prop == "Counts" and "ShowCountText") or ("Show" .. prop)],
                get = function()
                    return panel.owner["Showing" .. prop](panel.owner)
                end,
                set = function(_, enable)
                    panel.owner["SetShow" .. prop](panel.owner, enable)
                end
            }
        end
    end

    local function addPagingPanel()
        local panel = menu:NewPanel(L.Paging)

        addStateGroup(panel, UnitClass('player'), 'class')
        addStateGroup(panel, L.QuickPaging, 'page')
        addStateGroup(panel, L.Modifiers, 'modifier')
        addStateGroup(panel, L.Targeting, 'target')

        return panel
    end

    -- add panels
    addLayoutPanel()
    addButtonPanel()
    addPagingPanel()
    menu:AddFadingPanel()
    menu:AddAdvancedPanel()

    Addon.ActionBar.menu = menu
end