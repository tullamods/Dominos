-- menu pieces timer bar containers share
local _, Addon = ...

local TimerBarMenu = {}

-- which texts show, as one choice. saved as the label and time checks
local TEXT_ITEMS = {
    { value = 'LABEL_AND_TIME', text = 'Text_LABEL_AND_TIME', label = true, time = true },
    { value = 'LABEL', text = 'Text_LABEL', label = true, time = false },
    { value = 'TIME', text = 'Text_TIME', label = false, time = true },
    { value = 'NONE', text = 'Text_NONE', label = false, time = false }
}

local function getShownText(bar)
    local showLabel = bar:ShowingLabel() and true or false
    local showTime = bar:ShowingTime() and true or false

    for _, item in ipairs(TEXT_ITEMS) do
        if item.label == showLabel and item.time == showTime then
            return item.value
        end
    end
end

local function setShownText(bar, value)
    for _, item in ipairs(TEXT_ITEMS) do
        if item.value == value then
            bar:SetShowLabel(item.label)
            bar:SetShowTime(item.time)
            return
        end
    end
end

local BAR_CONTROLS = {
    {
        type = 'header',
        name = 'Header_Bar'
    },
    {
        type = 'texture',
        name = 'Texture',
        get = 'GetTextureID',
        set = 'SetTextureID'
    }
}

local TEXT_CONTROLS = {
    {
        type = 'header',
        name = 'Header_Text'
    },
    {
        type = 'dropdown',
        name = 'TextFormat',
        items = TEXT_ITEMS,
        get = getShownText,
        set = setShownText
    },
    'FontDropdown',
    'FontOutlineDropdown',
    'FontSizeSlider'
}

-- the check shows the border and the list picks its style, whose default entry
-- is the flat one. the rest only matters while it shows. right clicking the
-- color goes back to the border's own
local BORDER_CONTROLS = {
    {
        type = 'header',
        name = 'Border'
    },
    {
        type = 'borderWithCheck',
        name = 'Style',
        default = 'Border_FLAT',
        get = 'GetBorderID',
        set = 'SetBorderID',
        check = {
            get = 'ShowingBorder',
            set = 'SetShowBorder'
        }
    },
    {
        type = 'color',
        name = 'Color',
        enabled = 'ShowingBorder',
        get = 'GetBorderColor',
        set = 'SetBorderColor'
    },
    {
        type = 'slider',
        name = 'BorderSize',
        min = 1,
        max = 32,
        softLimits = true,
        enabled = 'ShowingBorder',
        get = 'GetBorderSize',
        set = 'SetBorderSize'
    }
}

TimerBarMenu.SizeControls = {
    insert = 'General',
    at = 'start',
    controls = {
        'WidthSlider',
        'HeightSlider'
    }
}

-- inside out: the bar, the text on it, then the border around it. a group
-- leads with what defines it, then rows that start with a check, then drop
-- downs, then sliders. the bar's own controls go after the texture
---@param barControls table[]?
function TimerBarMenu:AppearancePanel(barControls)
    local controls = {}

    for _, group in ipairs { BAR_CONTROLS, barControls or {}, TEXT_CONTROLS, BORDER_CONTROLS } do
        for _, control in ipairs(group) do
            table.insert(controls, control)
        end
    end

    return {
        addPanel = 'Appearance',
        after = 'General',
        locale = 'Dominos-CastBar',
        controls = controls
    }
end

-- one of the bar's colors. right click goes back to the default. enabled, if
-- given, dims it while it doesn't apply
function TimerBarMenu:ColorControl(key, enabled)
    return {
        type = 'color',
        name = 'Color_' .. key,
        enabled = enabled,
        get = function(bar)
            return bar:GetColorHex(key)
        end,
        set = function(bar, hex)
            bar:SetColor(key, hex)
        end
    }
end

---@param controls table[]
function TimerBarMenu:ColorsPanel(controls)
    return {
        addPanel = 'Colors',
        after = 'Appearance',
        locale = 'Dominos-CastBar',
        controls = controls
    }
end

-- exports
Addon.TimerBarMenu = TimerBarMenu
