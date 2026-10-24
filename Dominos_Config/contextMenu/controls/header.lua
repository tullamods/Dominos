-- a title with a divider line under it, to start a section

local _, Addon = ...

local function create(parent)
    local header = CreateFrame('Frame', nil, parent, 'ResizeLayoutFrame')

    header.expand = true

    local text = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    text:SetJustifyH('LEFT')
    text:SetPoint('TOPLEFT', 0, 1)
    -- the height comes from one line of text, so measure it before there is any
    text:SetText('X')
    text:SetHeight(text:GetStringHeight())
    header.Text = text

    local divider = header:CreateTexture(nil, 'ARTWORK')
    divider:SetAtlas('Options_HorizontalDivider', true)
    divider:SetPoint('BOTTOMLEFT')
    divider:SetPoint('BOTTOMRIGHT')

    header:SetFixedHeight(text:GetStringHeight() + divider:GetHeight() + 4)
    header:MarkDirty()

    return header
end

local function bind(header)
    header.Text:SetText(header.menu:Localize(header.def.name, header.def.locale))
end

local function refresh() end

local function release(header)
    -- the menu pads all but the first section
    header.topPadding = nil
end

Addon:RegisterControlType('header', {
    Create = create,
    Bind = bind,
    Refresh = refresh,
    Release = release
})
