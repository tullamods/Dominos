-- a check box with a label. the whole row is clickable

local _, Addon = ...

local function row_OnEnter(row)
    -- the bar may have changed since the menu last looked
    if row.def then
        Addon:RefreshControl(row)
    end

    Addon:ShowControlTooltip(row)
end

local function checkbox_OnClick(checkbox)
    local row = checkbox:GetParent()

    if row.def then
        local checked = not not checkbox:GetChecked()

        row.checked = checked
        row.menu:SetValue(row.def, checked)
    end
end

local function hitbox_OnClick(hitbox)
    hitbox:GetParent().CheckButton:Click()
end

-- the hitbox covers the check box, so highlight it by hand
local function hitbox_OnEnter(hitbox)
    local row = hitbox:GetParent()

    row.CheckButton:LockHighlight()
    row_OnEnter(row)
end

local function hitbox_OnLeave(hitbox)
    local row = hitbox:GetParent()

    row.CheckButton:UnlockHighlight()
    Addon:HideControlTooltip(row)
end

local function create(parent)
    local row = CreateFrame('Frame', nil, parent, 'HorizontalLayoutFrame')
    row.expand = true
    row.spacing = 3

    local checkbox = CreateFrame('CheckButton', nil, row, 'MinimalCheckboxTemplate')
    checkbox:SetScript('OnClick', checkbox_OnClick)
    checkbox.layoutIndex = 1
    row.CheckButton = checkbox

    local label = row:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    label.expand = true
    label:SetHeight(checkbox:GetHeight())
    label:SetJustifyH('LEFT')
    label:SetJustifyV('MIDDLE')
    label.layoutIndex = 2
    row.Label = label

    -- an invisible button over the whole row, so the label is clickable too
    local hitbox = CreateFrame('Button', nil, row)
    hitbox:SetAllPoints(row)
    hitbox:SetFrameLevel(checkbox:GetFrameLevel() + 1)
    hitbox:SetScript('OnClick', hitbox_OnClick)
    hitbox:SetScript('OnEnter', hitbox_OnEnter)
    hitbox:SetScript('OnLeave', hitbox_OnLeave)
    hitbox.ignoreInLayout = true
    row.Hitbox = hitbox

    row:SetFixedHeight(checkbox:GetHeight())
    row:MarkDirty()

    return row
end

local function refresh(row)
    local checked = not not row.menu:GetValue(row.def)

    if row.checked ~= checked then
        row.checked = checked
        row.CheckButton:SetChecked(checked)
    end
end

local function bind(row)
    row.Label:SetText(row.menu:Localize(row.def.name, row.def.locale))
    row.checked = nil

    refresh(row)
end

local function release(row)
    row.CheckButton:UnlockHighlight()
    Addon:HideControlTooltip(row)
    row.checked = nil
end

Addon:RegisterControlType('check', {
    Create = create,
    Bind = bind,
    Refresh = refresh,
    Release = release
})
