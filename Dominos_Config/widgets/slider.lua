local _, Addon = ...

local function noop() end

local function slider_OnMouseWheel(self, direction)
    if direction > 0 then
        self:GetParent():Increment()
    else
        self:GetParent():Decrement()
    end
end

local function slider_OnValueChanged(self, value, isUserInput)
    if isUserInput then
        self:GetParent():SetValue(value)
    end
end

local function slider_Create(parent)
    local slider = CreateFrame('Slider', nil, parent, 'MinimalSliderTemplate')

    slider:EnableMouseWheel(true)
    slider:SetObeyStepOnDrag(true)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    slider:SetValue(0)

    slider:SetScript('OnMouseWheel', slider_OnMouseWheel)
    slider:SetScript('OnValueChanged', slider_OnValueChanged)

    return slider
end

local function label_Create(parent, text, template)
	local label = parent:CreateFontString(nil, 'ARTWORK', template or 'GameFontHighlight')

	label:SetJustifyH('LEFT')
	label:SetJustifyV('BOTTOM')
	label:SetText(text or 'PLACEHOLDER_TEXT')
	label:SetHeight(label:GetStringHeight())

    return label
end

local function input_OnEnter(self)
    self.HoverBG:Show()
end

local function input_OnLeave(self)
    if not self:HasFocus() then
        self.HoverBG:Hide()
    end
end

local function input_OnTabPressed(self)
    -- TODO: focus next input on panel
end

local function input_OnEscapePressed(self)
    self:ClearFocus()
end

local function input_OnFocusGained(self)
    self:HighlightText(0, -1)
    self.HoverBG:Show()
end

local function input_OnFocusLost(self)
    self:HighlightText(0, 0)
    self:SetText(self:GetParent().value or "")

    if not self:IsMouseOver() then
        self.HoverBG:Hide()
    end
end

local function input_OnChange(self, text, isUserInput)
    if isUserInput then
        local value = tonumber(text, 10)
        if value ~= nil then
            self:GetParent():TrySetValue(value)
        end
    end
end

local function input_OnMouseWheel(self, direction)
    if direction > 0 then
        self:GetParent():Increment()
    else
        self:GetParent():Decrement()
    end
end

local function input_Create(parent)
    local input = CreateFrame('EditBox', nil, parent)

    input:SetAutoFocus(false)
    input:ClearFocus()
    input:SetFontObject('GameFontHighlight')
    input:SetJustifyH('RIGHT')
    input:SetJustifyV('MIDDLE')
    input:SetSize(36, 20)

    input:SetScript('OnEnter', input_OnEnter)
    input:SetScript('OnLeave', input_OnLeave)

    input:SetScript('OnEscapePressed', input_OnEscapePressed)
    input:SetScript('OnEscapePressed', input_OnEscapePressed)
    input:SetScript("OnTabPressed", input_OnTabPressed)
    input:SetScript("OnEditFocusGained", input_OnFocusGained)
    input:SetScript("OnEditFocusLost", input_OnFocusLost)
    input:SetScript("OnTextChanged", input_OnChange)
    input:SetScript('OnMouseWheel', input_OnMouseWheel)

    input.HoverBG = Addon:CreateHoverBackground(input)

    return input
end

local SliderMixin = {}

function SliderMixin:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self:GetProp('label'))
    GameTooltip_AddNormalLine(GameTooltip, self:GetProp('tooltip'))
    GameTooltip:Show()
end

function SliderMixin:OnShow()
    Addon:Render(self)
end

function SliderMixin:OnRender()
    self.value = self:GetProp('value') or 0
    self.minValue = self:GetProp('min') or 0
    self.maxValue = self:GetProp('max') or 100
    self.step = self:GetProp('step') or 1

    self.Label:SetText(self:GetProp('label') or 'PLACEHOLDER_TEXT')

    if self.MinLabel then
        self.MinLabel:SetText(self.minValue)
    end

    if self.MaxLabel then
        self.MaxLabel:SetText(self.maxValue)
    end

    local value = Clamp(self.value, self.minValue, self.maxValue)

    self.Slider:SetMinMaxValues(self.minValue, self.maxValue)
    self.Slider:SetValueStep(self.step)
    self.Slider:SetValue(value)
    self.ValueInput:SetText(value)
end

function SliderMixin:GetProp(key, ...)
    local value = self.props[key]
    if type(value) == "function" then
        return value(self, ...)
    end

    return value
end

function SliderMixin:Refresh()
    Addon:Render(self)
end

function SliderMixin:Increment()
    self:TrySetValue(self.value + self.step)
end

function SliderMixin:Decrement()
    self:TrySetValue(self.value - self.step)
end

function SliderMixin:Focus()
    self.ValueInput:Focus()
end

function SliderMixin:GetValue()
    return self.value
end

function SliderMixin:SetValue(value, force)
    if (self.value ~= value) or force then
        self.value = value

        self.Slider:SetValue(value)
        self.ValueInput:SetText(value)
        self.onChange(value)
    end
end

function SliderMixin:TrySetValue(value)
    if self:ShouldBreakLimits() then
        if value < self.minValue then
            self:SetMinMaxValues(value, self.maxValue)
        elseif value > self.maxValue then
            self:SetMinMaxValues(self.minValue, value)
        end
    end

    self:SetValue(Clamp(value, self.minValue, self.maxValue))
end

function SliderMixin:SetMinMaxValues(minValue, maxValue)
    if minValue ~= nil then
        self.minValue = minValue
    end

    if maxValue ~= nil then
        self.maxValue = maxValue
    end

    if self.MinLabel then
        self.MinLabel:SetText(self.minValue)
    end

    if self.MaxLabel then
        self.MaxLabel:SetText(self.maxValue)
    end

    self.Slider:SetMinMaxValues(self.minValue, self.maxValue)
    self.Slider:SetValue(Clamp(self.Slider:GetValue(), self.minValue, self.maxValue))
end

function SliderMixin:ShouldBreakLimits()
    return self:GetProp('softLimits') and IsShiftKeyDown()
end

function SliderMixin:SetEnabled(enable)
    if enable then
        self.Slider:Enable()
        self.ValueInput:Enable()
    else
        self.Slider:Disable()
        self.ValueInput:Disable()
    end
end


function Addon:CreateSlider(options)
    local frame = CreateFrame('Frame', nil, options.parent, 'ResizeLayoutFrame')

    Mixin(frame, SliderMixin)

    frame.expand = true

    frame.props = {
        min = options.min or 0,
        max = options.max or 100,
        value = options.get,
        step = options.step or 1,
        softLimits = options.softLimits or false,
        label = options.label or options.name or "MISSING_LABEL",
        tooltip = options.tooltip
    }

    local setter = options.set
    if type(setter) == "function" then
        frame.onChange = function(value) setter(value) end
    else
        frame.onChange = noop
    end

    frame.Label = label_Create(frame)
    frame.Label:SetPoint('TOPLEFT', 2, -4)

    frame.ValueInput = input_Create(frame)
    frame.ValueInput:SetPoint('TOPRIGHT', -4, 0)

    frame.Slider = slider_Create(frame)
    frame.Slider:SetPoint('BOTTOMLEFT')
    frame.Slider:SetPoint('BOTTOMRIGHT')

    if options.tooltip then
        local function showTooltip()
            frame:ShowTooltip()
        end

        frame:SetMouseMotionEnabled(true)

        for _, region in ipairs{ frame, frame.Slider, frame.ValueInput } do
            region:HookScript('OnEnter', showTooltip)
            region:HookScript('OnLeave', GameTooltip_Hide)
        end
    end

    frame:SetScript('OnShow', frame.OnShow)
    frame:MarkDirty()

    return frame
end