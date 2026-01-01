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
            hidden = ParentAddon:IsBuild("vanilla"),
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

                if ParentAddon:IsBuild("tbc", "vanilla") then
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
                return ParentAddon:ShowingEmptyButtons()
            end,
            set = function(_, enable)
                ParentAddon:SetShowEmptyButtons(enable)
            end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowBindingText,
            get = function()
                return ParentAddon:ShowingBindingText()
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
                return ParentAddon:ShowingMacroText()
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
                return ParentAddon:ShowingCounts()
            end,
            set = function(_, enable) ParentAddon:SetShowCounts(enable) end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowEquippedItemBorders,
            get = function()
                return ParentAddon:ShowingEquippedItemBorders()
            end,
            set = function(_, enable) ParentAddon:SetShowEquippedItemBorders(enable) end,
            width = 1.5,
        },

        {
            type = "toggle",
            name = L.ShowSpellAnimations,
            hidden = not ParentAddon:IsBuild("retail"),
            get = function()
                return ParentAddon:ShowingSpellAnimations()
            end,
            set = function(_, enable)
                ParentAddon:SetShowSpellAnimations(enable)
            end,
            width  = 1.5,
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
                return ParentAddon:ThemingButtons()
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
                if ParentAddon:ShowingTooltips() then
                    if ParentAddon:ShowingTooltipsInCombat() then
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
    }
})
