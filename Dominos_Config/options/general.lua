-- general options for Dominos

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

-- bar lengths to pick from: ones that line up with Blizzard's 12 button pages
local ACTION_BAR_LENGTHS = { 1, 2, 3, 4, 6, 12, 24 }

local function getMaxNumBars()
    return floor(ParentAddon.ACTION_BUTTON_COUNT / ParentAddon:GetActionBarLength())
end

-- AceConfig needs a number for a slider's max, so it's updated on changes
local numBarsOption = {
    type = "range",
    name = L.NumActionBars,
    min = 1,
    max = getMaxNumBars(),
    step = 1,
    get = function()
        return ParentAddon:NumBars()
    end,
    set = function(_, value)
        ParentAddon:SetNumBars(value)
    end
}

local actionBarLengthOption = {
    type = "select",
    name = L.ActionBarLength,
    desc = L.ActionBarLengthDesc,
    values = function()
        local values = {}

        for _, length in ipairs(ACTION_BAR_LENGTHS) do
            values[length] = L.ActionBarLengthValue:format(length, floor(ParentAddon.ACTION_BUTTON_COUNT / length))
        end

        -- one set elsewhere, like with a slash command
        local length = ParentAddon:GetActionBarLength()
        if not values[length] then
            values[length] = L.ActionBarLengthCustom:format(length)
        end

        return values
    end,
    sorting = function()
        local sorting = CopyTable(ACTION_BAR_LENGTHS)
        local length = ParentAddon:GetActionBarLength()

        if not tContains(sorting, length) then
            tinsert(sorting, length)
            table.sort(sorting)
        end

        return sorting
    end,
    get = function()
        return ParentAddon:GetActionBarLength()
    end,
    set = function(_, value)
        -- a longer length lowers the count, if needed
        ParentAddon:SetActionBarSize(ParentAddon:NumBars(), value)
    end
}

-- covers every change: these options, slash commands, and profile changes
local function onActionBarSizeChanged()
    numBarsOption.max = getMaxNumBars()
    LibStub('AceConfigRegistry-3.0'):NotifyChange(ParentAddon:GetName())
end

ParentAddon.RegisterCallback(numBarsOption, 'ACTIONBAR_COUNT_UPDATED', onActionBarSizeChanged)
ParentAddon.RegisterCallback(numBarsOption, 'LAYOUT_LOADED', onActionBarSizeChanged)

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
            type = "execute",
            name = L.ManageActions,
            func = function()
                Addon:ToggleActionBook()
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

        numBarsOption,
        actionBarLengthOption,

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
            hidden = ParentAddon:IsGameType("vanilla"),
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

                if ParentAddon:IsGameType("tbc", "vanilla") then
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
            hidden = not ParentAddon:IsGameType("standard", "forever"),
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
            hidden = not ParentAddon:IsGameType("standard", "forever"),
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
