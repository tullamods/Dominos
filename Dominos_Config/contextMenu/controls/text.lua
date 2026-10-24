-- a labeled box for several lines of text. the text is only applied once the
-- user is done editing, so that partly typed values aren't saved

local _, Addon = ...

local BORDER_INSET = 6
local BORDER_RIGHT_INSET = 8
local DEFAULT_NUM_LINES = 4
local SCROLL_BAR_GAP = 4

local function getHeightForLines(editBox, numLines)
    local _, fontHeight = editBox:GetFont()
    local lineHeight = fontHeight + editBox:GetSpacing()

    return math.ceil(numLines * lineHeight)
end

local function refresh(control)
    local editBox = control.EditBoxFrame:GetEditBox()

    -- never rewrite text that is being typed
    if editBox:HasFocus() then
        return
    end

    local text = tostring(control.menu:GetValue(control.def) or '')

    if not control.synced or control.value ~= text then
        control.synced = true
        control.value = text
        control.EditBoxFrame:SetText(text)
    end
end

local function isValid(control, text)
    local validate = control.def.validate

    return not validate or validate(text)
end

local function editBox_OnEditFocusLost(control, editBox)
    if not control.def then
        return
    end

    local text = editBox:GetInputText()

    if not isValid(control, text) then
        control.EditBoxFrame:SetText(control.value)
    elseif control.value ~= text then
        control.value = text
        control.menu:SetValue(control.def, text)
    end
end

local function create(parent)
    local control = CreateFrame('Frame', nil, parent, 'VerticalLayoutFrame')

    control.expand = true
    control.spacing = 8
    control.topPadding = 8
    control.bottomPadding = 8
    control.leftPadding = 8
    control.rightPadding = 8

    local label = control:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label:SetJustifyV('BOTTOM')
    label:SetJustifyH('LEFT')
    label:SetText('X')
    label:SetHeight(label:GetStringHeight())
    label.layoutIndex = 1
    label.expand = true
    control.Label = label

    control.EditBoxFrame = CreateFrame('Frame', nil, control, 'ScrollingEditBoxTemplate')
    control.EditBoxFrame.layoutIndex = 2
    control.EditBoxFrame.expand = true

    local editBox = control.EditBoxFrame:GetEditBox()
    editBox:HookScript('OnEditFocusLost', function()
        editBox_OnEditFocusLost(control, editBox)
    end)

    editBox:HookScript('OnTabPressed', function()
        if control.def then
            control.menu:FocusNextEditBox(control, IsShiftKeyDown())
        end
    end)

    control.ScrollBar = CreateFrame('EventFrame', nil, control, 'MinimalScrollBar')
    control.ScrollBar:SetPoint('TOPLEFT', control.EditBoxFrame, 'TOPRIGHT', SCROLL_BAR_GAP, 0)
    control.ScrollBar:SetPoint('BOTTOMLEFT', control.EditBoxFrame, 'BOTTOMRIGHT', SCROLL_BAR_GAP, 0)

    local rightInset = SCROLL_BAR_GAP + control.ScrollBar:GetWidth() + BORDER_RIGHT_INSET

    control.Border = CreateFrame('Frame', nil, control, 'TooltipBackdropTemplate')
    control.Border:SetPoint('TOPLEFT', control.EditBoxFrame, -BORDER_INSET, BORDER_INSET)
    control.Border:SetPoint('BOTTOMRIGHT', control.EditBoxFrame, 'BOTTOMRIGHT', rightInset, -BORDER_INSET)

    ScrollUtil.RegisterScrollBoxWithScrollBar(control.EditBoxFrame:GetScrollBox(), control.ScrollBar)

    control:HookScript('OnSizeChanged', function(_, width)
        control.EditBoxFrame:SetWidth(width - (rightInset + 12))
    end)

    local function onEnter()
        if control.def then
            refresh(control)
        end

        Addon:ShowControlTooltip(control)
    end

    local function onLeave()
        Addon:HideControlTooltip(control)
    end

    control:SetScript('OnEnter', onEnter)
    control:SetScript('OnLeave', onLeave)
    editBox:HookScript('OnEnter', onEnter)
    editBox:HookScript('OnLeave', onLeave)

    control:MarkDirty()

    return control
end

local function bind(control)
    local def = control.def
    local editBox = control.EditBoxFrame:GetEditBox()

    control.Label:SetText(control.menu:Localize(def.label or def.name, def.locale))
    control.EditBoxFrame:SetHeight(getHeightForLines(editBox, def.numLines or DEFAULT_NUM_LINES))
    control.synced = false

    refresh(control)

    -- the box keeps its scroll position from the last bar it showed
    local scrollBox = control.EditBoxFrame:GetScrollBox()
    if scrollBox.ScrollToBegin then
        scrollBox:ScrollToBegin()
    end

    control:MarkDirty()
end

local function release(control)
    -- losing focus applies the text to the bar it was typed for
    control.EditBoxFrame:GetEditBox():ClearFocus()
    Addon:HideControlTooltip(control)

    control.synced = false
    control.value = nil
end

Addon:RegisterControlType('text', {
    Create = create,
    Bind = bind,
    Refresh = refresh,
    Release = release,
    GetEditBox = function(control) return control.EditBoxFrame:GetEditBox() end
})
