local _, Addon = ...

local BORDER_INSET = 6
local BORDER_RIGHT_INSET = 8
local DEFAULT_NUM_LINES = 4
local SCROLL_BAR_GAP = 4

local function label_Create(parent, text)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")

    label:SetJustifyV("BOTTOM")
    label:SetJustifyH("LEFT")
    label:SetText(text or "PLACEHOLDER_TEXT")
    label:SetHeight(label:GetStringHeight())

    return label
end

local TextInputMixin = {}

TextInputMixin.expand = true
TextInputMixin.spacing = 8
TextInputMixin.topPadding = 8
TextInputMixin.bottomPadding = 8
TextInputMixin.leftPadding = 8
TextInputMixin.rightPadding = 8

function TextInputMixin:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, self.options.label or self.options.name)
    GameTooltip_AddNormalLine(GameTooltip, self.options.tooltip)
    GameTooltip:Show()
end

function TextInputMixin:OnShow()
    self.value = tostring(self.options.get() or "")
    self.EditBoxFrame:SetText(self.value)
end

TextInputMixin.Refresh = TextInputMixin.OnShow

function TextInputMixin:IsValid(value)
    local validate = self.options.validate

    return not validate or validate(value)
end

function TextInputMixin:SetValue(value)
    if self.value ~= value then
        self.value = value
        self.options.set(value)
    end
end

local function editBox_GetHeightForLines(editBox, numLines)
    local _, fontHeight = editBox:GetFont()
    local lineHeight = fontHeight + editBox:GetSpacing()

    return math.ceil(numLines * lineHeight)
end

function Addon:CreateTextInput(options)
    assert(options.set, 'Options property set is required')
    assert(options.get, 'Options property get is required')

    local frame = Mixin(CreateFrame('Frame', nil, options.parent, 'VerticalLayoutFrame'), TextInputMixin)

    frame.options = options

    frame.Label = label_Create(frame, options.label or options.name)
    frame.Label.layoutIndex = 1
    frame.Label.expand = true

    frame.EditBoxFrame = CreateFrame("Frame", nil, frame, "ScrollingEditBoxTemplate")
    frame.EditBoxFrame:SetHeight(editBox_GetHeightForLines(
        frame.EditBoxFrame:GetEditBox(),
        options.numLines or DEFAULT_NUM_LINES
    ))
    frame.EditBoxFrame.layoutIndex = 2
    frame.EditBoxFrame.expand = true

    -- only apply the text once the user is done editing, so that partially
    -- typed values aren't saved. text that fails validation is reverted
    local editBox = frame.EditBoxFrame:GetEditBox()
    editBox:HookScript('OnEditFocusLost', function()
        local text = editBox:GetInputText()

        if frame:IsValid(text) then
            frame:SetValue(text)
        else
            frame.EditBoxFrame:SetText(frame.value)
        end
    end)

    frame.ScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    frame.ScrollBar:SetPoint("TOPLEFT", frame.EditBoxFrame, "TOPRIGHT", SCROLL_BAR_GAP, 0)
    frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.EditBoxFrame, "BOTTOMRIGHT", SCROLL_BAR_GAP, 0)

    local rightInset = SCROLL_BAR_GAP + frame.ScrollBar:GetWidth() + BORDER_RIGHT_INSET

    frame.Border = CreateFrame('Frame', nil, frame, 'TooltipBackdropTemplate')
    frame.Border:SetPoint('TOPLEFT', frame.EditBoxFrame, -BORDER_INSET, BORDER_INSET)
    frame.Border:SetPoint('BOTTOMRIGHT', frame.EditBoxFrame, "BOTTOMRIGHT", rightInset, -BORDER_INSET)

    ScrollUtil.RegisterScrollBoxWithScrollBar(frame.EditBoxFrame:GetScrollBox(), frame.ScrollBar)

    frame:HookScript('OnSizeChanged', function(_, width)
        frame.EditBoxFrame:SetWidth(width - (rightInset + 12))
    end)

    if options.tooltip then
        local function showTooltip()
            frame:ShowTooltip()
        end

        frame:SetScript('OnEnter', showTooltip)
        frame:SetScript('OnLeave', GameTooltip_Hide)

        editBox:HookScript('OnEnter', showTooltip)
        editBox:HookScript('OnLeave', GameTooltip_Hide)
    end

    frame:HookScript('OnShow', frame.OnShow)
    frame:MarkDirty()

    return frame
end
