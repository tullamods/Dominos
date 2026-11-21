-- a labeled color swatch that opens blizzard's color picker. get and set take
-- RRGGBBAA hex. right or shift click sets nil, so the bar goes back to its own
-- color. def.hasAlpha false hides the opacity slider
--
-- colorWithCheck puts a check box (def.check get/set) before the swatch, like
-- sliderWithCheck. the swatch is dimmed while it's off, and keeps its color.
-- clicking its label flips the check, the swatch has its own clicks

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

-- from the edge of the check box art to the inside of its box
local SWATCH_INSET = 5

-- for a value that isn't a color. blizzard's WHITE_FONT_COLOR has no alpha
local FALLBACK_COLOR = CreateColor(1, 1, 1, 1)

-- the picker is shared, so only one control has it at a time
local pickerControl
local pickerHasAlpha

local function isEnabled(control)
    return control.CheckButton == nil or control.checked
end

local function updateEnabled(control)
    local enabled = isEnabled(control)

    control.Swatch:SetEnabled(enabled)
    control.Swatch:SetAlpha(enabled and 1 or 0.5)
end

local function getColor(control)
    return ParentAddon:GetColorFromHex(control.menu:GetValue(control.def)) or FALLBACK_COLOR
end

local function refresh(control)
    if control.CheckButton then
        Addon:RefreshControlCheck(control)
    end

    local value = control.menu:GetValue(control.def)

    if control.synced and control.value == value then
        return
    end

    control.synced = true
    control.value = value
    -- colors made without an alpha have none
    local r, g, b, a = getColor(control):GetRGBA()
    control.Swatch.Color:SetColorTexture(r, g, b, a or 1)
end

--------------------------------------------------------------------------------
-- Color picker
--------------------------------------------------------------------------------

local function setPickedColor(r, g, b, a)
    local control = pickerControl

    -- the control may have been given up while the picker was open
    if control and control.def then
        control.menu:SetValue(control.def, ParentAddon:GetHexFromColor(r, g, b, a))
    end
end

local function picker_OnColorChanged()
    local r, g, b = ColorPickerFrame:GetColorRGB()
    local a = 1

    if pickerHasAlpha then
        a = ColorPickerFrame:GetColorAlpha()
    end

    setPickedColor(r, g, b, a)
end

local function picker_OnCancel(previous)
    setPickedColor(previous.r, previous.g, previous.b, previous.a or 1)
end

-- opacity is alpha on both mainline and classic, not 1 - alpha
local function openPicker(control)
    local r, g, b, a = getColor(control):GetRGBA()

    -- setting up fires swatchFunc before the opacity is set, with whatever
    -- alpha the picker last had, so only listen once it's showing
    pickerControl = nil
    pickerHasAlpha = control.def.hasAlpha ~= false

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r,
        g = g,
        b = b,
        opacity = a or 1,
        hasOpacity = pickerHasAlpha,
        swatchFunc = picker_OnColorChanged,
        opacityFunc = picker_OnColorChanged,
        cancelFunc = picker_OnCancel
    })

    pickerControl = control
end

local function closePicker(control)
    if pickerControl == control then
        pickerControl = nil

        if ColorPickerFrame:IsShown() then
            ColorPickerFrame:Hide()
        end
    end
end

-- someone else may open the picker after us
ColorPickerFrame:HookScript('OnHide', function()
    pickerControl = nil
end)

--------------------------------------------------------------------------------
-- Widget
--------------------------------------------------------------------------------

local function control_OnEnter(control)
    -- the bar may have changed since the menu last looked
    if control.def then
        refresh(control)
        Addon:ShowControlTooltip(control, L.ColorResetTip)
    end
end

local function control_OnLeave(control)
    Addon:HideControlTooltip(control)
end

local function swatch_OnClick(swatch, button)
    local control = swatch.control

    if not control.def then
        return
    end

    -- shift click stands in for right click, like on the drag frames
    if button == 'RightButton' or IsModifierKeyDown() then
        closePicker(control)
        control.menu:SetValue(control.def, nil)
    else
        openPicker(control)
    end
end

local function swatch_OnEnter(swatch)
    control_OnEnter(swatch.control)
end

local function swatch_OnLeave(swatch)
    control_OnLeave(swatch.control)
end

local function createSwatch(control)
    -- the check box's art, so the two read as the same kind of control
    local swatch = CreateFrame('Button', nil, control)
    swatch:SetSize(30, 29)
    swatch:SetNormalAtlas('checkbox-minimal')
    swatch:SetPushedAtlas('checkbox-minimal')
    swatch:SetHighlightAtlas('checkbox-minimal', 'ADD')
    swatch:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    swatch:SetScript('OnClick', swatch_OnClick)
    swatch:SetScript('OnEnter', swatch_OnEnter)
    swatch:SetScript('OnLeave', swatch_OnLeave)
    swatch.control = control

    local color = swatch:CreateTexture(nil, 'ARTWORK', nil, 2)
    color:SetPoint('TOPLEFT', SWATCH_INSET, -SWATCH_INSET)
    color:SetPoint('BOTTOMRIGHT', -SWATCH_INSET, SWATCH_INSET)
    swatch.Color = color

    -- shows through see through colors, like the picker's own swatch. classic's
    -- picker doesn't use the atlas, so it may not have it
    local checkers = swatch:CreateTexture(nil, 'ARTWORK', nil, 1)
    checkers:SetAllPoints(color)

    if not checkers:SetAtlas('colorpicker-checkerboard') then
        checkers:SetColorTexture(1, 1, 1, 1)
    end

    -- rounds the corners to fit the box, like action button icons. left square
    -- where the atlas is missing
    local mask = swatch:CreateMaskTexture()
    mask:SetAllPoints(color)

    if mask:SetAtlas('UI-Frame-IconMask') then
        color:AddMaskTexture(mask)
        checkers:AddMaskTexture(mask)
    end

    return swatch
end

-- the row is clickable like a check row, so hovering it lights the swatch
local function hitbox_OnClick(hitbox, button)
    swatch_OnClick(hitbox.control.Swatch, button)
end

local function hitbox_OnEnter(hitbox)
    local control = hitbox.control

    control.Swatch:LockHighlight()
    control_OnEnter(control)
end

local function hitbox_OnLeave(hitbox)
    local control = hitbox.control

    control.Swatch:UnlockHighlight()
    control_OnLeave(control)
end

-- laid out like a check row: swatch then label, or check, swatch, then label
local function create(parent, withCheck)
    local control = CreateFrame('Frame', nil, parent, 'ResizeLayoutFrame')
    control.expand = true

    local label = control:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label:SetJustifyH('LEFT')
    label:SetJustifyV('MIDDLE')
    control.Label = label

    local swatch = createSwatch(control)
    control.Swatch = swatch

    if withCheck then
        local checkbox = Addon:AddControlCheck(control, label, updateEnabled)
        checkbox:SetPoint('LEFT')

        swatch:SetPoint('LEFT', checkbox, 'RIGHT', 3, 0)
        -- over the check's hitbox, which runs to the end of the label
        swatch:SetFrameLevel(control.Hitbox:GetFrameLevel() + 1)
    else
        swatch:SetPoint('LEFT')

        local hitbox = CreateFrame('Button', nil, control)
        hitbox:SetAllPoints(control)
        hitbox:SetFrameLevel(swatch:GetFrameLevel() + 1)
        hitbox:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        hitbox:SetScript('OnClick', hitbox_OnClick)
        hitbox:SetScript('OnEnter', hitbox_OnEnter)
        hitbox:SetScript('OnLeave', hitbox_OnLeave)
        hitbox.control = control
        control.Hitbox = hitbox
    end

    label:ClearAllPoints()
    label:SetPoint('LEFT', swatch, 'RIGHT', 3, 0)
    label:SetPoint('RIGHT')
    label:SetHeight(swatch:GetHeight())

    control:SetFixedHeight(swatch:GetHeight())
    control:SetMouseMotionEnabled(true)
    control:SetScript('OnEnter', control_OnEnter)
    control:SetScript('OnLeave', control_OnLeave)
    control:MarkDirty()

    return control
end

local function bind(control)
    local def = control.def

    control.Label:SetText(control.menu:Localize(def.name, def.locale))
    control.synced = false
    control.checked = nil

    refresh(control)

    -- a check calls this itself when it flips
    if not control.CheckButton then
        updateEnabled(control)
    end
end

local function release(control)
    closePicker(control)
    Addon:HideControlTooltip(control)
    control.Swatch:UnlockHighlight()

    if control.CheckButton then
        control.CheckButton:UnlockHighlight()
    end

    control.synced = false
    control.checked = nil
    control.value = nil
end

local function createPlain(parent)
    return create(parent, false)
end

local function createWithCheck(parent)
    return create(parent, true)
end

Addon:RegisterControlType('color', {
    Create = createPlain,
    Bind = bind,
    Refresh = refresh,
    Release = release
})

Addon:RegisterControlType('colorWithCheck', {
    Create = createWithCheck,
    Bind = bind,
    Refresh = refresh,
    Release = release
})
