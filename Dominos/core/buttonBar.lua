-- A frame that contains a grid of buttons

local _, Addon = ...
local ButtonBar = Addon:CreateClass('Frame', Addon.Frame)

ButtonBar:Extend(
    'OnCreate',
    function(self)
        self.buttons = {}
    end
)

ButtonBar:Extend(
    'OnAcquire',
    function(self)
        self:ReloadButtons()
    end
)

ButtonBar:Extend(
    'OnRelease',
    function(self)
        for i in pairs(self.buttons) do
            self:DetachButton(i)
        end
    end
)

function ButtonBar:CanClickThrough()
    return true
end

function ButtonBar:AcquireButton(index)
    error(("Bar %s has not implemented Acquire Button"):format(self.id), 2)
end

function ButtonBar:ReleaseButton(button)
    if type(button.Free) == 'function' then
        button:Free()
    else
        button:SetParent(nil)
        button:Hide()
    end
end

-- adds the specified button to the bar
function ButtonBar:AttachButton(index)
    local button = self:AcquireButton(index)

    if button then
        button:SetParent(self)
        button:EnableMouse(not self:GetClickThrough())

        self:OnAttachButton(button, index)
        self.buttons[index] = button
    end
end

-- removes the specified button from the bar
function ButtonBar:DetachButton(index)
    local button = self.buttons[index]

    if button then
        self:OnDetachButton(button, index)
        self:ReleaseButton(button)
        self.buttons[index] = nil
    end
end

function ButtonBar:OnAttachButton(button, index)
end

function ButtonBar:OnDetachButton(button, index)
end

function ButtonBar:ReloadButtons()
    local oldNumButtons = #self.buttons
    for i = 1, oldNumButtons do
        self:DetachButton(i)
    end

    local newNumButtons = self:NumButtons()
    for i = 1, newNumButtons do
        self:AttachButton(i)
    end

    self:Layout()
end

function ButtonBar:NumButtons()
    return self.sets.numButtons or 0
end

function ButtonBar:SetNumButtons(numButtons)
    self.sets.numButtons = numButtons or 0

    self:UpdateNumButtons()
end

function ButtonBar:UpdateNumButtons()
    local oldNumButtons = #self.buttons
    local newNumButtons = self:NumButtons()

    for i = newNumButtons + 1, oldNumButtons do
        self:DetachButton(i)
    end

    for i = oldNumButtons + 1, newNumButtons do
        self:AttachButton(i)
    end

    self:Layout()
end

-- the most buttons the bar can have. bars that can have more buttons than they
-- have now override this
function ButtonBar:MaxLength()
    return math.max(1, self:NumButtons())
end

-- the most columns the bar can show right now, which is one per button
function ButtonBar:MaxColumns()
    return math.max(1, self:NumButtons())
end

-- a stored column count can be more than the bar has buttons now, so show no
-- more than it can use, and keep the stored value for when the bar grows again
function ButtonBar:NumColumns()
    local numButtons = self:NumButtons()

    return math.min(self.sets.columns or numButtons, numButtons)
end

function ButtonBar:SetColumns(columns)
    self.sets.columns = columns ~= self:NumButtons() and columns or nil
    self:Layout()
end

function ButtonBar:GetSpacing()
    return self.sets.spacing or 0
end

function ButtonBar:SetSpacing(spacing)
    self.sets.spacing = spacing
    self:Layout()
end

function ButtonBar:GetRowOffset()
    return self.sets.rowOffset or 0
end

function ButtonBar:SetRowOffset(rowOffset)
    self.sets.rowOffset = rowOffset
    self:Layout()
end

-- how far rows can be offset or spaced, in a button's width and height
function ButtonBar:GetRowOffsetLimit()
    return Round(ActionButton1:GetWidth()) + self:GetSpacing()
end

function ButtonBar:GetRowSpacing()
    return self.sets.rowSpacing or 0
end

function ButtonBar:SetRowSpacing(rowSpacing)
    self.sets.rowSpacing = rowSpacing
    self:Layout()
end

function ButtonBar:GetRowSpacingLimit()
    return Round(ActionButton1:GetHeight()) + self:GetSpacing()
end

-- the wackiness here is for backward compatibility reasons, since I did not
-- implement true defaults
function ButtonBar:GetLeftToRight()
    return not self.sets.isRightToLeft
end

function ButtonBar:SetLeftToRight(isLeftToRight)
    local isRightToLeft = not isLeftToRight

    self.sets.isRightToLeft = isRightToLeft and true or nil
    self:Layout()
end

function ButtonBar:GetTopToBottom()
    return not self.sets.isBottomToTop
end

function ButtonBar:SetTopToBottom(isTopToBottom)
    local isBottomToTop = not isTopToBottom

    self.sets.isBottomToTop = isBottomToTop and true or nil
    self:Layout()
end

function ButtonBar:GetButtonInsets()
    if #self.buttons >= 1 then
        return self.buttons[1]:GetHitRectInsets()
    end

    return 0, 0, 0, 0
end

function ButtonBar:GetButtonSize()
    if #self.buttons >= 1 then
        local w, h = self.buttons[1]:GetSize()
        local l, r, t, b = self:GetButtonInsets()

        return w - (l + r), h - (t + b)
    end

    return 0, 0
end

-- A rough model of a bar for doing calculations
-- ^
-- | Padding
-- v
-- <--Padding--> [Button]<--Spacing-->[Button] <--Padding-->
-- ^
-- | Spacing
-- v
-- <--Padding--> [Button]<--Spacing-->[Button] <--Padding-->
-- ^
-- | Padding
-- v
function ButtonBar:Layout()
    local numButtons = math.min(self:NumButtons(), #self.buttons)
    if numButtons < 1 then
        ButtonBar.proto.Layout(self)
        return
    end

    local cols = Clamp(self:NumColumns(), 1, numButtons)
    local rows = math.ceil(numButtons / cols)

    local isLeftToRight = self:GetLeftToRight()
    local isTopToBottom = self:GetTopToBottom()

    -- grab base button sizes
    local l, r, t, b = self:GetButtonInsets()
    local bW, bH = self:GetButtonSize()
    local pW, pH = self:GetPadding()
    local spacing = self:GetSpacing()
    local rowOffset = self:GetRowOffset()
    local lineSpace = self:GetRowSpacing()

    local buttonWidth = bW + spacing
    local buttonHeight = bH + spacing

    local xOff = pW - l
    local yOff = pH - t

    for i = 1, numButtons do
        local button = self.buttons[i]

        local row = math.floor((i - 1) / cols)
        if not isTopToBottom then
            row = rows - (row + 1)
        end

        local col = (i - 1) % cols
        if not isLeftToRight then
            col = cols - (col + 1)
        end

        local x = xOff + buttonWidth * col
        if rowOffset >= 0 then
            x = x + (row * rowOffset)
        else
            x = x + ((1 + row) - rows) * rowOffset
        end

        local y = yOff + (buttonHeight + lineSpace) * row

        button:ClearAllPoints()
        button:SetParent(self)
        button:SetPoint('TOPLEFT', x, -y)
    end

    local barWidth = (buttonWidth * cols) + (pW * 2) - spacing + math.abs(rowOffset) * (rows - 1)
    local barHeight = (buttonHeight * rows) + (pH * 2) - spacing + lineSpace * (rows - 1)

    self:TrySetSize(barWidth, barHeight)
end

function ButtonBar:UpdateClickThrough()
    local enableMouse = not self:GetClickThrough()

    for _, button in pairs(self.buttons) do
        button:EnableMouse(enableMouse)
    end
end

function ButtonBar:ForButtons(methodOrFunc, ...)
    if type(methodOrFunc) == 'function' then
        for _, button in pairs(self.buttons) do
            methodOrFunc(button, ...)
        end
    elseif type(methodOrFunc) == 'string' then
        for _, button in pairs(self.buttons) do
            local func = button[methodOrFunc]

            if type(func) == 'function' then
                func(button, ...)
            end
        end
    end
end

ButtonBar.contextMenu = Addon.Frame.contextMenu:Extend {
    {
        insert = 'General',
        at = 'start',
        controls = {
            'ColumnsSlider',
            'SpacingSlider',
            'RowOffsetSlider',
            'RowSpacingSlider'
        }
    },
    {
        insert = 'Advanced',
        before = 'DrawOrderHeader',
        controls = {
            {
                type = 'header',
                name = 'Layout'
            },
            'LayoutDirectionDropdown'
        }
    }
}

-- exports
Addon.ButtonBar = ButtonBar
