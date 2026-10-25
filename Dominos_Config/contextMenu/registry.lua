-- the options shared by bars' context menus, by name. definitions are tables
-- of widget settings; get, set, available, min, max and items are a method name
-- on the bar or a function of the bar, and min, max and items can also be plain
-- values. softLimits is explained in controls/slider.lua

local _, Addon = ...
local L = Addon:GetLocale()

local MAX_BAR_HEIGHT_PIXELS = 64

-- combines the left to right and top to bottom settings into the direction
-- buttons fill the grid in
local LAYOUT_DIRECTION_ITEMS = {
    { value = "TOPLEFT", text = L.LayoutRightDown, leftToRight = true, topToBottom = true },
    { value = "TOPRIGHT", text = L.LayoutLeftDown, leftToRight = false, topToBottom = true },
    { value = "BOTTOMLEFT", text = L.LayoutRightUp, leftToRight = true, topToBottom = false },
    { value = "BOTTOMRIGHT", text = L.LayoutLeftUp, leftToRight = false, topToBottom = false }
}

-- common show state macro conditionals, so that people don't need to write
-- them by hand
local SHOW_PRESET_ITEMS = {
    { value = "ALWAYS", text = L.ShowAlways, conditions = "" },
    { value = "NEVER", text = L.ShowNever, conditions = "hide" },
    { value = "COMBAT", text = L.ShowInCombat, conditions = "[combat]show;hide" },
    { value = "NOCOMBAT", text = L.ShowOutOfCombat, conditions = "[nocombat]show;hide" },
    { value = "TARGET", text = L.ShowWithTarget, conditions = "[@target,exists]show;hide" },
    { value = "COMBAT_OR_TARGET", text = L.ShowInCombatOrWithTarget, conditions = "[combat][@target,exists]show;hide" },
    { value = "NOMOUNT", text = L.ShowNotMounted, conditions = "[nomounted]show;hide" }
}

local SHOW_PRESET_CUSTOM = { value = "CUSTOM", text = L.ShowCustom }

local function getShowPreset(bar)
    local conditions = bar:GetUserDisplayConditions() or ""

    for _, item in ipairs(SHOW_PRESET_ITEMS) do
        if item.conditions == conditions then
            return item
        end
    end

    return SHOW_PRESET_CUSTOM
end

-- layout settings have no effect on a bar that can only have one button
local function canHaveMultipleButtons(bar)
    return bar:MaxLength() > 1
end

-- width and height are shown as screen pixels but stored in ui units, so the
-- same stored size shows a different number when the bar's scale changes
local function toPixels(bar, uiUnits)
    return Round(uiUnits * bar:GetEffectiveScale() / PixelUtil.GetPixelToUIUnitFactor())
end

local function fromPixels(bar, pixels)
    return pixels * PixelUtil.GetPixelToUIUnitFactor() / bar:GetEffectiveScale()
end

local Controls = {}

-- the General panel
Controls.ColumnsSlider = {
    type = 'slider',
    name = L.NumColumns,
    available = canHaveMultipleButtons,
    min = 1,
    max = 'MaxColumns',
    get = 'NumColumns',
    set = 'SetColumns'
}

Controls.SpacingSlider = {
    type = 'slider',
    name = L.Spacing,
    available = canHaveMultipleButtons,
    min = -16,
    max = 32,
    softLimits = true,
    get = 'GetSpacing',
    set = 'SetSpacing'
}

Controls.RowOffsetSlider = {
    type = 'slider',
    name = L.RowOffset,
    available = canHaveMultipleButtons,
    min = function(bar) return -bar:GetRowOffsetLimit() end,
    max = 'GetRowOffsetLimit',
    softLimits = true,
    get = 'GetRowOffset',
    set = 'SetRowOffset'
}

Controls.RowSpacingSlider = {
    type = 'slider',
    name = L.RowSpacing,
    available = canHaveMultipleButtons,
    min = function(bar) return -bar:GetRowSpacingLimit() end,
    max = 'GetRowSpacingLimit',
    softLimits = true,
    get = 'GetRowSpacing',
    set = 'SetRowSpacing'
}

Controls.PaddingSlider = {
    type = 'slider',
    name = L.Padding,
    min = -16,
    max = 32,
    softLimits = true,
    get = 'GetPadding',
    set = 'SetPadding'
}

Controls.ScaleSlider = {
    type = 'slider',
    name = L.Scale,
    min = 50,
    max = 200,
    get = function(bar) return Round(bar:GetFrameScale() * 100) end,
    set = function(bar, value) bar:SetFrameScale(value / 100) end
}

Controls.OpacitySlider = {
    type = 'slider',
    name = L.Opacity,
    get = function(bar) return Round(bar:GetFrameAlpha() * 100) end,
    set = function(bar, value) bar:SetFrameAlpha(value / 100) end
}

Controls.WidthSlider = {
    type = 'slider',
    name = L.Width,
    min = 1,
    max = function() return (GetPhysicalScreenSize()) end,
    softLimits = true,
    get = function(bar) return toPixels(bar, bar:GetDesiredWidth()) end,
    set = function(bar, value) bar:SetDesiredWidth(fromPixels(bar, value)) end
}

Controls.HeightSlider = {
    type = 'slider',
    name = L.Height,
    min = 1,
    max = MAX_BAR_HEIGHT_PIXELS,
    softLimits = true,
    get = function(bar) return toPixels(bar, bar:GetDesiredHeight()) end,
    set = function(bar, value) bar:SetDesiredHeight(fromPixels(bar, value)) end
}

-- the Visibility panel
Controls.ShowPresetDropdown = {
    type = 'dropdown',
    name = L.Preset,
    -- custom is only listed while the bar's conditions match no preset, to
    -- describe what is in the custom conditions box. it can't be picked
    items = function(bar)
        if getShowPreset(bar) == SHOW_PRESET_CUSTOM then
            local items = { unpack(SHOW_PRESET_ITEMS) }
            tinsert(items, SHOW_PRESET_CUSTOM)
            return items
        end

        return SHOW_PRESET_ITEMS
    end,
    get = function(bar)
        return getShowPreset(bar).value
    end,
    set = function(bar, value)
        for _, item in ipairs(SHOW_PRESET_ITEMS) do
            if item.value == value then
                bar:SetUserDisplayConditions(item.conditions)
                return
            end
        end
    end
}

Controls.ShowStatesText = {
    type = 'text',
    name = L.CustomConditions,
    tooltip = L.ShowStatesDescription,
    numLines = 3,
    -- a malformed conditional parses to nil. appending a catch-all clause (;_)
    -- means a well formed one always returns something, even if nothing matches
    validate = function(text)
        return text == '' or SecureCmdOptionParse(text .. ';_') ~= nil
    end,
    get = 'GetUserDisplayConditions',
    set = 'SetUserDisplayConditions'
}

Controls.FadedOpacitySlider = {
    type = 'slider',
    name = L.FadedOpacity,
    tooltip = L.FadedOpacityTooltip,
    get = function(bar) return Round(bar:GetFadeMultiplier() * 100) end,
    set = function(bar, value) bar:SetFadeMultiplier(value / 100) end
}

-- fade times are stored in seconds but shown in milliseconds
Controls.FadeInDelaySlider = {
    type = 'slider',
    name = L.FadeInDelay,
    min = 0,
    max = 2000,
    softLimits = true,
    step = 50,
    get = function(bar) return Round(bar:GetFadeInDelay() * 1000) end,
    set = function(bar, value) bar:SetFadeInDelay(value / 1000) end
}

Controls.FadeInTimeSlider = {
    type = 'slider',
    name = L.FadeInTime,
    min = 100,
    max = 2000,
    softLimits = true,
    step = 50,
    get = function(bar) return Round(bar:GetFadeInDuration() * 1000) end,
    set = function(bar, value) bar:SetFadeInDuration(value / 1000) end
}

Controls.FadeOutDelaySlider = {
    type = 'slider',
    name = L.FadeOutDelay,
    min = 0,
    max = 2000,
    softLimits = true,
    step = 50,
    get = function(bar) return Round(bar:GetFadeOutDelay() * 1000) end,
    set = function(bar, value) bar:SetFadeOutDelay(value / 1000) end
}

Controls.FadeOutTimeSlider = {
    type = 'slider',
    name = L.FadeOutTime,
    min = 100,
    max = 2000,
    softLimits = true,
    step = 50,
    get = function(bar) return Round(bar:GetFadeOutDuration() * 1000) end,
    set = function(bar, value) bar:SetFadeOutDuration(value / 1000) end
}

-- the Advanced panel
Controls.LayoutDirectionDropdown = {
    type = 'dropdown',
    name = L.LayoutDirection,
    available = canHaveMultipleButtons,
    items = LAYOUT_DIRECTION_ITEMS,
    get = function(bar)
        local leftToRight = bar:GetLeftToRight()
        local topToBottom = bar:GetTopToBottom()

        for _, item in ipairs(LAYOUT_DIRECTION_ITEMS) do
            if item.leftToRight == leftToRight and item.topToBottom == topToBottom then
                return item.value
            end
        end
    end,
    set = function(bar, value)
        for _, item in ipairs(LAYOUT_DIRECTION_ITEMS) do
            if item.value == value then
                bar:SetLeftToRight(item.leftToRight)
                bar:SetTopToBottom(item.topToBottom)
                return
            end
        end
    end
}

Controls.ClickThroughCheck = {
    type = 'check',
    name = L.ClickThrough,
    available = 'CanClickThrough',
    get = 'GetClickThrough',
    set = 'SetClickThrough'
}

Controls.ShowInOverrideUICheck = {
    type = 'check',
    name = L.ShowInOverrideUI,
    available = 'CanShowInOverrideUI',
    get = 'ShowingInOverrideUI',
    set = 'ShowInOverrideUI'
}

Controls.ShowInPetBattleUICheck = {
    type = 'check',
    name = L.ShowInPetBattleUI,
    available = 'CanShowInPetBattleUI',
    get = 'ShowingInPetBattleUI',
    set = 'ShowInPetBattleUI'
}

-- a header in the Advanced panel that other menus insert controls before
Controls.DrawOrderHeader = {
    type = 'header',
    name = 'DrawOrder'
}

Controls.FrameStrataDropdown = {
    type = 'dropdown',
    name = L.FrameStrata,
    items = {
        { value = "BACKGROUND", text = L["FrameStrata_BACKGROUND"] },
        { value = "LOW", text = L["FrameStrata_LOW"] },
        { value = "MEDIUM", text = L["FrameStrata_MEDIUM"] },
        { value = "HIGH", text = L["FrameStrata_HIGH"] }
    },
    get = 'GetDisplayLayer',
    set = 'SetDisplayLayer'
}

Controls.FrameLevelSlider = {
    type = 'slider',
    name = L.FrameLevel,
    min = 1,
    max = 200,
    get = 'GetDisplayLevel',
    set = 'SetDisplayLevel'
}

Addon.Controls = Controls
