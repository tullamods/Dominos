-- A labeled button showing where a bar pages to for a state. Clicking it opens
-- the page picker (slots/pagePicker.lua).
--
-- def.get returns an offset, or nil. def.set takes an offset, or nil

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

-- "Unset", "Bonus Bar 1", or "Bonus Bar 1 (unavailable)"
local function describe(offset)
    if offset == nil then
        return L.PagingUnset
    end

    local AddressMap = ParentAddon.AddressMap
    local name = AddressMap:GetName(offset + 1)

    if AddressMap:GetSlot(offset + 1) == 0 then
        return L.PagingUnavailable:format(name)
    end

    return name
end

local function button_OnClick(button)
    local row = button:GetParent()

    if row.def then
        Addon:TogglePagePicker(row)
    end
end

-- the full text, when it doesn't fit
local function button_OnEnter(button)
    if button.Text:IsTruncated() then
        GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
        GameTooltip:SetText(button.Text:GetText(), 1, 1, 1)
        GameTooltip:Show()
    end
end

local function button_OnLeave(button)
    if GameTooltip:IsOwned(button) then
        GameTooltip:Hide()
    end
end

-- laid out like a dropdown: the label on the left, the button on the right
local function create(parent)
    local row = CreateFrame('Frame', nil, parent, 'ResizeLayoutFrame')
    row.leftPadding = 2
    row.rightPadding = 2
    row.topPadding = 2
    row.bottomPadding = 2
    row.expand = true

    local button = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
    button:SetSize(120, 22)
    button:SetPoint('RIGHT')
    button:SetScript('OnClick', button_OnClick)
    button:SetScript('OnEnter', button_OnEnter)
    button:SetScript('OnLeave', button_OnLeave)
    row.Button = button

    -- truncated to fit
    local text = button:GetFontString()
    text:ClearAllPoints()
    text:SetPoint('LEFT', 8, 0)
    text:SetPoint('RIGHT', -8, 0)
    text:SetWordWrap(false)
    button.Text = text

    local label = row:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label:SetPoint('LEFT')
    label:SetPoint('RIGHT', button, 'LEFT', -5, 0)
    label:SetJustifyH('LEFT')
    label:SetJustifyV('MIDDLE')
    label:SetWordWrap(false)
    row.Label = label

    row:SetFixedHeight(button:GetHeight())
    row:MarkDirty()

    return row
end

local function refresh(row)
    local text = describe(row.menu:GetValue(row.def))

    if row.text ~= text then
        row.text = text
        row.Button:SetText(text)
    end
end

local function bind(row)
    row.Label:SetText(row.menu:Localize(row.def.name, row.def.locale))
    row.text = nil

    refresh(row)
end

local function release(row)
    Addon:HidePagePicker(row)
    Addon:HideControlTooltip(row)
    row.text = nil
end

Addon:RegisterControlType('pagePicker', {
    Create = create,
    Bind = bind,
    Refresh = refresh,
    Release = release
})
