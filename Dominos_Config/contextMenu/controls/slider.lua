-- a labeled slider with a number box. holding shift while changing the number
-- goes past the limits of controls that have softLimits

local _, Addon = ...

local function readLimits(control)
    local def, menu = control.def, control.menu

    return menu:Resolve(def.min) or 0, menu:Resolve(def.max) or 100
end

local function refresh(control)
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
    input:SetScript('OnMouseWheel', onMouseWheel)

    input.HoverBG = Addon:CreateHoverBackground(input)
    input.control = control

    return input
end

local function create(parent)
    local control = CreateFrame('Frame', nil, parent, 'ResizeLayoutFrame')

    control.expand = true
    control.control = control

    control.Label = control:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    control.Label:SetJustifyH('LEFT')
    control.Label:SetJustifyV('BOTTOM')
    -- the height comes from one line of text, so measure it before there is any
    control.Label:SetText('X')
    control.Label:SetHeight(control.Label:GetStringHeight())
    control.Label:SetPoint('TOPLEFT', 2, -4)

    control.ValueInput = createInput(control)
    control.ValueInput:SetPoint('TOPRIGHT', -4, 0)

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

    refresh(control)
end

local function release(control)
    control.ValueInput:ClearFocus()
    control.ValueInput.HoverBG:Hide()
    Addon:HideControlTooltip(control)

    control.synced = false
    control.value = nil
end

Addon:RegisterControlType('slider', {
    Create = create,
    Bind = bind,
    Refresh = refresh,
    Release = release,
    GetEditBox = function(control) return control.ValueInput end
})
