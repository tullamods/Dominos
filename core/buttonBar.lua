-- buttonBar.lua
-- a dominos frame that contains buttons

local ButtonBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ButtonBar = ButtonBar

function ButtonBar:Create(id)
    local bar = ButtonBar.proto.Create(self, id)

    bar.buttons = {}

    return bar
end

function ButtonBar:Free()
    for i in pairs(self.buttons) do
        self:RemoveButton(i)
    end

    return ButtonBar.proto.Free(self)
end

--this function is used in a lot of places, but never called in Frame
function ButtonBar:AddButton(index) end

function ButtonBar:RemoveButton(index)
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

function ButtonBar:SetNumButtons(numButtons)
    local numButtons = numButtons or 0

    if numButtons ~= self:NumButtons() then
        self.sets.numButtons = numButtons

        for i = numButtons + 1, #self.buttons do
            self:RemoveButton(i)
        end

        for i = #self.buttons + 1, numButtons do
            self:AddButton(i)
        end

        self:Layout()
    end
end

function ButtonBar:NumButtons()
    return self.sets.numButtons or 0
end

--this function is used in a lot of places, but never called in Frame
function ButtonBar:LoadButtons()
    for i = 1, self:NumButtons() do
        self:AddButton(i)
    end

    self:UpdateClickThrough()
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
