-- general options for Dominos

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

local function dict(entries)
    for i = #entries, 1, -1 do
        local e = entries[i]

        entries[e.name] = e
        entries[e.name].order = i
        entries[i] = nil
    end

    return entries
end

Addon:AddOptionsPanelOptions("general", {
    type = "group",
    name = L.General,
    args = dict {
        {
            type = "execute",
            name = L.EnterConfigMode,
            func = function()
                ParentAddon:ToggleLockedFrames()
            end,
        },

        {
            type = "execute",
            name = L.EnterBindingMode,
            func = function()
                ParentAddon:ToggleBindingMode()
            end,
        },

        {
            type = "toggle",
            name = L.ShowMinimapButton,

            get = function()
                return ParentAddon:ShowingMinimap()
            end,

            set = function(_, enable)
                ParentAddon:SetShowMinimap(enable)
            end,

            width = "full",
        },

        {
            type = "toggle",
            name = L.ShowMinimapButton,

            get = function()
                return ParentAddon:ShowingMinimap()
            end,

            set = function(_, enable)
                ParentAddon:SetShowMinimap(enable)
            end,
            width = "full",
        },

        {
            type = "toggle",
            name = L.StickyBars,

            get = function()
                return ParentAddon:Sticky()
            end,

            set = function(_, enable)
                ParentAddon:SetSticky(enable)
            end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.LinkedOpacity,
            get = function()
                return ParentAddon:IsLinkedOpacityEnabled()
            end,
            set = function(_, enable)
                ParentAddon:SetLinkedOpacity(enable)
            end,
            width = 1.5,
        },

        { type = "header", name = L.ActionBarBehavior },

        {
            type = "select",
            name = L.RightClickUnit,
            values = {
                player = L.RCUPlayer,
                focus = L.RCUFocus,
                targettarget = L.RCUToT,
                none = DEFAULT
            },
            get = function()
                return ParentAddon:GetRightClickUnit() or "none"
            end,
            set = function(_, value)
                ParentAddon:SetRightClickUnit(value)
            end
        },

        {
            type = "toggle",
            name = L.ShowOverrideUI,
            desc = L.ShowOverrideUIDesc,
            disabled = InCombatLockdown(),
            hidden = ParentAddon:IsBuild("classic"),
            get = function()
                return ParentAddon:UsingOverrideUI()
            end,
            set = function(_, enable)
                ParentAddon:SetUseOverrideUI(enable)
            end,
            width = 1.5,
        },

        {
            type = "select",
            name = L.PossessBar,
            desc = L.PossessBarDesc,
            values = function()
                local items = {}

                for i = 1, ParentAddon:NumBars() do
                    tinsert(items, L.ActionBarNumber:format(i))
                end

                if ParentAddon:IsBuild("bcc", "classic") then
                    items.pet = ParentAddon.Frame:Get("pet"):GetDisplayName()
                end

                return items
            end,
            get = function()
                local bar = ParentAddon:GetOverrideBar()

                if bar then
                    return bar.id
                end

                return 1
            end,
            set = function(_, value)
                ParentAddon:SetOverrideBar(value)
            end
        },

        { type = "header", name = L.ActionButtonLookAndFeel },

        {
            type = "toggle",
            name = L.ShowEmptyButtons,
            get = function()
                return ParentAddon:ShowGrid()
            end,
            set = function(_, enable)
                ParentAddon:SetShowGrid(enable)
            end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowBindingText,
            get = function()
                return ParentAddon:ShowBindingText()
            end,
            set = function(_, enable)
                ParentAddon:SetShowBindingText(enable)
            end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowMacroText,
            get = function()
                return ParentAddon:ShowMacroText()
            end,
            set = function(_, enable)
                ParentAddon:SetShowMacroText(enable)
            end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowCountText,
            get = function()
                return ParentAddon:ShowCounts()
            end,
            set = function(_, enable) ParentAddon:SetShowCounts(enable) end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowEquippedItemBorders,
            get = function()
                return ParentAddon:ShowEquippedItemBorders()
            end,
            set = function(_, enable) ParentAddon:SetShowEquippedItemBorders(enable) end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowSpellGlows,
            hidden = not ParentAddon:IsBuild("retail"),
            get = function()
                return ParentAddon:ShowingSpellGlows()
            end,
            set = function(_, enable)
                ParentAddon:SetShowSpellGlows(enable)
            end,
            width  = 1.5,
        },

        {
            type = "toggle",
            name = L.ThemeActionButtons,
            get = function()
                return ParentAddon:ThemeButtons()
            end,
            set = function(_, enable)
                ParentAddon:SetThemeButtons(enable)
            end,
            desc = L.ThemeActionButtonsDesc,
            width = 2,
        },

        {
            type = "select",
            name = L.ShowTooltips,
            width = 1.5,
            values = {
                always = ALWAYS,
                never = NEVER,
                ooc = L.OutOfCombat
            },
            get = function()
                if ParentAddon:ShowTooltips() then
                    if ParentAddon:ShowCombatTooltips() then
                        return "always"
                    end

                    return "ooc"
                end

                return "never"
            end,
            set = function(_, value)
                if value == "always" then
                    ParentAddon:SetShowTooltips(true)
                    ParentAddon:SetShowCombatTooltips(true)
                elseif value == "ooc" then
                    ParentAddon:SetShowTooltips(true)
                    ParentAddon:SetShowCombatTooltips(false)
                elseif value == "never" then
                    ParentAddon:SetShowTooltips(false)
                    ParentAddon:SetShowCombatTooltips(false)
                else
                    error(("%s - Unknown tooltip option %q"):format(ParentAddon:GetName(), value))
                end
            end
        },

        {
            type = "group",
            name = L.ActionButtonColoring,
            inline = true,
            hidden = not ParentAddon:IsBuild("retail"),
            args = (function()
                local results = {}

                for i, state in ipairs { "oor", "oom", "unusable" } do
                    results[state] = {
                        type = "group",
                        name = L["ActionStates_" .. state],
                        inline = true,
                        order = i,
                        width = 0.5,
                        args = {
                            enable = {
                                type = "toggle",
                                name = L.Enable,
                                get = function()
                                    return ParentAddon.db.profile.actionColors[state].enabled
                                end,
                                set = function(_, enable)
                                    ParentAddon.db.profile.actionColors[state].enabled = enable
                                    ParentAddon.ActionButtons:ForVisible("UpdateUsable")
                                end,
                                order = 0,
                            },

                            color = {
                                type = "color",
                                name = L.Color,
                                hasAlpha = true,
                                get = function()
                                    local c = ParentAddon.db.profile.actionColors[state]
                                    return c.r, c.g, c.b, c.a
                                end,
                                set = function(_, r, g, b, a)
                                    local c = ParentAddon.db.profile.actionColors[state]

                                    c.r = r
                                    c.g = g
                                    c.b = b
                                    c.a = a

                                    ParentAddon.ActionButtons:ForVisible("UpdateUsable")
                                end,
                                order = 1,
                            },

                            desaturate = {
                                type = "toggle",
                                name = L.Desaturate,
                                get = function()
                                    return ParentAddon.db.profile.actionColors[state].desaturate
                                end,
                                set = function(_, enable)
                                    ParentAddon.db.profile.actionColors[state].desaturate = enable
                                    ParentAddon.ActionButtons:ForVisible("UpdateUsable")
                                end,
                                order = 2,
                            },
                        }
                    }
                end

                return results
            end)()
        }
    }
})
