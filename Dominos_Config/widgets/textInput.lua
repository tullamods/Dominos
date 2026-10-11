local _, Addon = ...

local function noop() end

local function label_Create(parent, text, template)
	local label = parent:CreateFontString(nil, 'ARTWORK', template or 'GameFontHighlight')

	label:SetJustifyV('BOTTOM')
	label:SetJustifyH('LEFT')
	label:SetText(text or 'PLACEHOLDER_TEXT')
	label:SetHeight(label:GetStringHeight())

    return label
end

local InputMixin = {}

function InputMixin:OnEnter()
    -- self.HoverBG:Show()
end

function InputMixin:OnLeave()
    -- if not self:HasFocus() then
    --     self.HoverBG:Hide()
    -- end
end

function InputMixin:OnTabPressed()
    -- TODO: focus next input on panel
end

function InputMixin:OnEscapePressed()
    self:ClearFocus()
end

function InputMixin:OnFocusGained()
end

function InputMixin:OnFocusLost()
    self:HighlightText(0, 0)
    self:SetText(self:GetParent().value or "")

    -- if not self:IsMouseOver() then
    --     self.HoverBG:Hide()
    -- end
end

function InputMixin:OnChange(text, isUserInput)
    if isUserInput then
        self.owner:SetValue(text)
    end

    self.owner:MarkDirty()
end

local function input_Create(parent, owner, numLines)
    local input = CreateFrame('EditBox', nil, parent)

	Mixin(input, InputMixin)

	input.owner = owner or parent
    input:SetAutoFocus(false)
    input:ClearFocus()
    input:SetFontObject('GameFontHighlight')
    input:SetJustifyV('TOP')
    input:SetJustifyH('LEFT')

    if numLines and numLines > 1 then
        input:SetMultiLine(true)
        input:SetResizeBounds(0, numLines * 1.5 * 24, nil, numLines * 1.5 * 24)
    end

    input:SetScript('OnEnter', input.OnEnter)
    input:SetScript('OnLeave', input.OnLeave)

    input:SetScript('OnEscapePressed', input.OnEscapePressed)
    input:SetScript('OnEscapePressed', input.OnEscapePressed)
    input:SetScript("OnTabPressed", input.OnTabPressed)
    input:SetScript("OnEditFocusGained", input.OnFocusGained)
    input:SetScript("OnEditFocusLost", input.OnFocusLost)
    input:SetScript("OnTextChanged", input.OnChange)

    return input
end

local TextBoxMixin = {}

function TextBoxMixin:OnShow()
    Addon:Render(self)
end

function TextBoxMixin:OnSizeChanged(width)
    self.Input:SetWidth(width)
end

function TextBoxMixin:OnRender()
    self.value = self:GetProp('value') or ''

    self.Label:SetText(self:GetProp('label') or 'PLACEHOLDER_TEXT')
	self.Input:SetText(self.value)
end

function TextBoxMixin:GetProp(key, ...)
    local value = self.props[key]
    if type(value) == "function" then
        return value(self, ...)
    end

    return value
end

function TextBoxMixin:SetValue(value, force)
    value = tostring(value) or ""

    if (self.value ~= value) or force then
        self.value = value

        self.Input:SetText(value)
        self.onChange(value)
    end
end

TextBoxMixin.expand = true
TextBoxMixin.spacing = 4

function Addon:CreateTextInput(options)
	local frame = Mixin(CreateFrame('Frame', nil, options.parent, 'VerticalLayoutFrame'), TextBoxMixin)

	frame.props = {
		value = options.get,
		label = options.label or options.name or "MISSING_LABEL"
	}

    local setter = options.set
    if type(setter) == "function" then
        frame.onChange = function(value) setter(value) end
    else
        frame.onChange = noop()
    end

	frame.Label = label_Create(frame)
    frame.Label.layoutIndex = 1
    frame.Label.expand = true

	frame.Input = input_Create(frame, nil, 4)
    frame.Input.expand = true

    frame.Container = Addon:CreateScrollableContainer(frame)
    frame.Container.layoutIndex = 2
    frame.Container.expand = true
    frame.Container:SetContent(frame.Input)
    frame.Container:SetHeight(4 * 1.5 * 20)

    frame:SetScript('OnShow', frame.OnShow)
    frame:SetScript('OnSizeChanged', frame.OnSizeChanged)
    frame:MarkDirty()

	return frame
end

