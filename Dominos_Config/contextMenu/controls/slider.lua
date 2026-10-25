-- a labeled slider with a number box. holding shift while changing the number
-- goes past the limits of controls that have softLimits.
--
-- sliderWithCheck is the same control with a check box in place of the label's
-- left edge. the check has its own get and set under def.check. while it is off
-- the slider is dimmed, and keeps its value for when it is turned back on

local _, Addon = ...

local function readLimits(control)
    local def, menu = control.def, control.menu

    return menu:Resolve(def.min) or 0, menu:Resolve(def.max) or 100
end

-- a slider can't be changed while its check is off, or when its limits leave
-- nothing to choose between
local function isEnabled(control)
    if control.CheckButton and not control.checked then
        return false
    end

    return not control.noRange
end

local function updateEnabled(control)
    local enabled = isEnabled(control)
    local alpha = enabled and 1 or 0.5

    control.Slider:SetEnabled(enabled)
    control.Slider:SetAlpha(alpha)
    control.ValueInput:SetEnabled(enabled)
    control.ValueInput:SetAlpha(alpha)

    if not enabled then
        control.ValueInput:ClearFocus()
    end
end

local function refreshChecked(control)
    local checked = not not control.menu:GetValue(control.def.check)

    if control.checked ~= checked then
        control.checked = checked
        control.CheckButton:SetChecked(checked)
        updateEnabled(control)
    end
end

local function refresh(control)
    if control.CheckButton then
        refreshChecked(control)
    end

    -- never rewrite the number while it is being typed
    if control.ValueInput:HasFocus() then
        return
    end

    local value = control.menu:GetValue(control.def) or 0
    local minValue, maxValue = readLimits(control)

    if control.synced and value == control.value and minValue == control.limitMin and maxValue == control.limitMax then
        return
    end

    control.synced = true
    control.value = value
    control.limitMin, control.limitMax = minValue, maxValue

    -- a soft limit can be passed with shift, so there is still a choice
    control.noRange = not control.def.softLimits and maxValue <= minValue
    updateEnabled(control)

    -- a value past a soft limit was put there on purpose, so show it
    if control.def.softLimits then
        minValue = math.min(minValue, value)
        maxValue = math.max(maxValue, value)
    end

    control.minValue, control.maxValue = minValue, maxValue

    local shown = Clamp(value, minValue, maxValue)

    control.Slider:SetMinMaxValues(minValue, maxValue)
    control.Slider:SetValue(shown)
    control.ValueInput:SetText(shown)
end

local function setValue(control, value)
    if control.value ~= value then
        control.value = value

        control.Slider:SetValue(value)

        -- typing a number one digit at a time passes through values that get
        -- limited, so leave the box alone until the user is done with it
        if not control.ValueInput:HasFocus() then
            control.ValueInput:SetText(value)
        end

        control.menu:SetValue(control.def, value)
    end
end

local function setMinMaxValues(control, minValue, maxValue)
    control.minValue, control.maxValue = minValue, maxValue

    control.Slider:SetMinMaxValues(minValue, maxValue)
    control.Slider:SetValue(Clamp(control.Slider:GetValue(), minValue, maxValue))
end

local function trySetValue(control, value)
    if not isEnabled(control) then
        return
    end

    if control.def.softLimits and IsShiftKeyDown() then
        if value < control.minValue then
            setMinMaxValues(control, value, control.maxValue)
        elseif value > control.maxValue then
            setMinMaxValues(control, control.minValue, value)
        end
    end

    setValue(control, Clamp(value, control.minValue, control.maxValue))
end

local function step(control, direction)
    if control.def then
        trySetValue(control, control.value + direction * (control.def.step or 1))
    end
end

local function onMouseWheel(region, direction)
    step(region.control, direction > 0 and 1 or -1)
end

local function onEnter(region)
    local control = region.control

    -- the bar may have changed since the menu last looked
    if control.def then
        refresh(control)
    end

    Addon:ShowControlTooltip(control)
end

local function onLeave(region)
    Addon:HideControlTooltip(region.control)
end

local function checkbox_OnClick(checkbox)
    local control = checkbox.control

    if control.def then
        local checked = not not checkbox:GetChecked()

        control.checked = checked
        updateEnabled(control)
        control.menu:SetValue(control.def.check, checked)
    end
end

local function hitbox_OnClick(hitbox)
    hitbox.control.CheckButton:Click()
end

-- the hitbox covers the check box, so highlight it by hand
local function hitbox_OnEnter(hitbox)
    hitbox.control.CheckButton:LockHighlight()
    onEnter(hitbox)
end

local function hitbox_OnLeave(hitbox)
    hitbox.control.CheckButton:UnlockHighlight()
    onLeave(hitbox)
end

local function slider_OnValueChanged(slider, value, isUserInput)
    local control = slider.control

    if isUserInput and control.def then
        setValue(control, value)
    end
end

local function input_OnEnter(input)
    input.HoverBG:Show()
    onEnter(input)
end

local function input_OnLeave(input)
    if not input:HasFocus() then
        input.HoverBG:Hide()
    end

    onLeave(input)
end

local function input_OnFocusGained(input)
    input:HighlightText(0, -1)
    input.HoverBG:Show()
end

local function input_OnFocusLost(input)
    input:HighlightText(0, 0)
    input:SetText(input.control.value or '')

    if not input:IsMouseOver() then
        input.HoverBG:Hide()
    end
end

local function input_OnTabPressed(input)
    local control = input.control

    if control.def then
        control.menu:FocusNextEditBox(control, IsShiftKeyDown())
    end
end

local function input_OnTextChanged(input, isUserInput)
    local control = input.control

    if isUserInput and control.def then
        local value = tonumber(input:GetText())

        if value ~= nil then
            trySetValue(control, value)
        end
    end
end

local function createSlider(control)
    local slider = CreateFrame('Slider', nil, control, 'MinimalSliderTemplate')

    slider:EnableMouseWheel(true)
    slider:SetObeyStepOnDrag(true)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    slider:SetValue(0)

    slider:SetScript('OnMouseWheel', onMouseWheel)
    slider:SetScript('OnValueChanged', slider_OnValueChanged)
    slider:SetScript('OnEnter', onEnter)
    slider:SetScript('OnLeave', onLeave)

    slider.control = control

    return slider
end

local function createInput(control)
    local input = CreateFrame('EditBox', nil, control)

    input:SetAutoFocus(false)
    input:ClearFocus()
    input:SetFontObject('GameFontHighlight')
    input:SetJustifyH('RIGHT')
    input:SetJustifyV('MIDDLE')
    input:SetSize(36, 20)

    input:SetScript('OnEnter', input_OnEnter)
    input:SetScript('OnLeave', input_OnLeave)
    input:SetScript('OnEscapePressed', input.ClearFocus)
    input:SetScript('OnTabPressed', input_OnTabPressed)
    input:SetScript('OnEditFocusGained', input_OnFocusGained)
    input:SetScript('OnEditFocusLost', input_OnFocusLost)
    input:SetScript('OnTextChanged', input_OnTextChanged)
    input:EnableMouseWheel(true)
    input:SetScript('OnMouseWheel', onMouseWheel)

    local hoverBG = input:CreateTexture(nil, 'BACKGROUND')
    hoverBG:Hide()
    hoverBG:SetColorTexture(1, 1, 1, 0.1)
    hoverBG:SetAllPoints()
    hoverBG.ignoreInLayout = true
    input.HoverBG = hoverBG
    input.control = control

    return input
end

-- the label, number box and, for controls with a check, the check box and the
-- hitbox over it
local function createHeader(control, withCheck)
    local label = control:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label:SetJustifyH('LEFT')
    control.Label = label

    if not withCheck then
        label:SetJustifyV('BOTTOM')
        -- the height comes from one line of text, so measure it before there is any
        label:SetText('X')
        label:SetHeight(label:GetStringHeight())
        label:SetPoint('TOPLEFT', 2, -4)

        control.ValueInput = createInput(control)
        control.ValueInput:SetPoint('TOPRIGHT', -4, 0)
        return
    end

    local checkbox = CreateFrame('CheckButton', nil, control, 'MinimalCheckboxTemplate')
    checkbox:SetPoint('TOPLEFT')
    checkbox:SetScript('OnClick', checkbox_OnClick)
    checkbox.control = control
    control.CheckButton = checkbox

    label:SetJustifyV('MIDDLE')
    label:SetHeight(checkbox:GetHeight())
    label:SetPoint('LEFT', checkbox, 'RIGHT', 3, 0)

    control.ValueInput = createInput(control)
    -- centered on the check box, which is taller than the number
    control.ValueInput:SetPoint('RIGHT', control, 'TOPRIGHT', -4, -checkbox:GetHeight() / 2)

    -- the label ends where the number starts
    label:SetPoint('RIGHT', control.ValueInput, 'LEFT', -4, 0)

    -- an invisible button over the check box and label, so the label is
    -- clickable too
    local hitbox = CreateFrame('Button', nil, control)
    hitbox:SetPoint('TOPLEFT', checkbox)
    hitbox:SetPoint('BOTTOM', checkbox)
    hitbox:SetPoint('RIGHT', control.ValueInput, 'LEFT')
    hitbox:SetFrameLevel(checkbox:GetFrameLevel() + 1)
    hitbox:SetScript('OnClick', hitbox_OnClick)
    hitbox:SetScript('OnEnter', hitbox_OnEnter)
    hitbox:SetScript('OnLeave', hitbox_OnLeave)
    hitbox.control = control
    control.Hitbox = hitbox
end

local function create(parent, withCheck)
    local control = CreateFrame('Frame', nil, parent, 'ResizeLayoutFrame')

    control.expand = true
    control.control = control

    createHeader(control, withCheck)

    control.Slider = createSlider(control)
    control.Slider:SetPoint('BOTTOMLEFT')
    control.Slider:SetPoint('BOTTOMRIGHT')

    if control.SetMouseMotionEnabled then
        control:SetMouseMotionEnabled(true)
    end

    control:SetScript('OnEnter', onEnter)
    control:SetScript('OnLeave', onLeave)
    control:MarkDirty()

    return control
end

local function bind(control)
    local def = control.def

    control.Label:SetText(control.menu:Localize(def.name, def.locale))
    control.Slider:SetValueStep(def.step or 1)
    control.synced = false
    control.checked = nil

    refresh(control)
end

local function release(control)
    control.ValueInput:ClearFocus()
    control.ValueInput.HoverBG:Hide()
    Addon:HideControlTooltip(control)

    if control.CheckButton then
        control.CheckButton:UnlockHighlight()
    end

    control.synced = false
    control.checked = nil
    control.noRange = nil
    control.value = nil
end

local function getEditBox(control)
    -- a disabled number can't take focus
    if not isEnabled(control) then
        return nil
    end

    return control.ValueInput
end

Addon:RegisterControlType('slider', {
    Create = function(parent) return create(parent, false) end,
    Bind = bind,
    Refresh = refresh,
    Release = release,
    GetEditBox = getEditBox
})

Addon:RegisterControlType('sliderWithCheck', {
    Create = function(parent) return create(parent, true) end,
    Bind = bind,
    Refresh = refresh,
    Release = release,
    GetEditBox = getEditBox
})
