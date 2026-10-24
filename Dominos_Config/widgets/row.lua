local _, Addon = ...

local function row_AddChild(self, element)
    local layoutIndex = 1 + (self.lastLayoutIndex or 0)

    element.layoutIndex = layoutIndex
    element:SetParent(self)

    self.lastLayoutIndex = layoutIndex
    self:MarkDirty()
end

function Addon:CreateRow(parent)
    local row = CreateFrame('Frame', nil, parent, 'HorizontalLayoutFrame')

    row.expand = true
    row.spacing = 3
    row.AddChild = row_AddChild

    return row
end
