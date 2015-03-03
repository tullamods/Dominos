-- buttonBar.lua
-- a dominos frame that contains buttons

local ButtonBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ButtonBar = ButtonBar

function ButtonBar:New(...)
    local bar = ButtonBar.proto.New(self, ...)

    bar:ReloadButtons()

    return bar
end

function ButtonBar:Create(...)
    local bar = ButtonBar.proto.Create(self, ...)

    bar.buttons = {}

    return bar
end

function ButtonBar:Free()
    for i in pairs(self.buttons) do
        self:DetachButton(i)
    end

    return ButtonBar.proto.Free(self)
end

-- retrives the button that should be placed at index
function ButtonBar:GetButton(index) end

-- adds the specified button to the bar
function ButtonBar:AttachButton(index)
    local button = self:GetButton(index)

    if button then
        button:SetParent(self.header)
		button:EnableMouse(not self:GetClickThrough())
		button:Show()

        self.buttons[index] = button
    end
end

-- removes the specified button from the bar
function ButtonBar:DetachButton(index)
    local button = self.buttons[index]

    if button then
        if type(button.Free) == 'function' then
            button:Free()
        else
            button:SetParent(nil)
            button:Hide()
        end

        self.buttons[index] = nil
    end
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

function ButtonBar:NumButtons()
    return self.sets.numButtons or 0
end

function ButtonBar:SetColumns(columns)
    self.sets.columns = columns ~= self:NumButtons() and columns or nil
    self:Layout()
end

function ButtonBar:NumColumns()
    return self.sets.columns or self:NumButtons()
end

function ButtonBar:SetSpacing(spacing)
    self.sets.spacing = spacing
    self:Layout()
end

function ButtonBar:GetSpacing()
    return self.sets.spacing or 0
end

--[[ Layout ]]--

--the wackiness here is for backward compaitbility reasons, since I did not implement true defaults
function ButtonBar:SetLeftToRight(isLeftToRight)
    local isRightToLeft = not isLeftToRight

    self.sets.isRightToLeft = isRightToLeft and true or nil
    self:Layout()
end

function ButtonBar:GetLeftToRight()
    return not self.sets.isRightToLeft
end

function ButtonBar:SetTopToBottom(isTopToBottom)
    local isBottomToTop = not isTopToBottom

    self.sets.isBottomToTop = isBottomToTop and true or nil
    self:Layout()
end

function ButtonBar:GetTopToBottom()
    return not self.sets.isBottomToTop
end

function ButtonBar:Layout()
    if #self.buttons <= 0 then
        return ButtonBar.proto.Layout(self)
    end

    local cols = min(self:NumColumns(), #self.buttons)
    local rows = ceil(#self.buttons / cols)
    local pW, pH = self:GetPadding()
    local spacing = self:GetSpacing()
    local isLeftToRight = self:GetLeftToRight()
    local isTopToBottom = self:GetTopToBottom()

    local firstButton = self.buttons[1]
    local w = firstButton:GetWidth() + spacing
    local h = firstButton:GetHeight() + spacing

    for i, button in pairs(self.buttons) do
        local col
        local row
        if isLeftToRight then
            col = (i-1) % cols
        else
            col = (cols-1) - (i-1) % cols
        end

        if isTopToBottom then
            row = ceil(i / cols) - 1
        else
            row = rows - ceil(i / cols)
        end

        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH))
    end

    local width = w*cols - spacing + pW*2
    local height = h*ceil(#self.buttons/cols) - spacing + pH*2

    self:SetSize(width + pW, height + pH)
end

function ButtonBar:UpdateClickThrough()
    local isClickThroughEnabled = self:GetClickThrough()

    for _, button in pairs(self.buttons) do
        if isClickThroughEnabled then
            button:EnableMouse(false)
        else
            button:EnableMouse(true)
        end
    end
end
