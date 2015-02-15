-- buttonBar.lua
-- a dominos frame that contains buttons

local ButtonBar = Dominos:CreateClass('CheckButton', Dominos.Frame)
Dominos.ButtonBar = ButtonBar

function ButtonBar:Create()
    local bar = ButtonBar.super.Create(self)

    bar.buttons = {}

    return bar
end

function ButtonBar:Free()
    for i in pairs(self.buttons) do
        self:RemoveButton(i)
    end

    return ButtonBar.super.Free(self)
end

--this function is used in a lot of places, but never called in Frame
function ButtonBar:AddButton(index) end

function ButtonBar:RemoveButton(index)
    local button = self.buttons and self.buttons[index]

    if button then

        if type(button.Free) == 'function' then
            button:Free()
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
function Frame:LoadButtons()
    if not self.AddButton then return end

    for i = 1, self:NumButtons() do
        self:AddButton(i)
    end

    self:UpdateClickThrough()
end

function Frame:SetColumns(columns)
    self.sets.columns = columns ~= self:NumButtons() and columns or nil
    self:Layout()
end

function Frame:NumColumns()
    return self.sets.columns or self:NumButtons()
end

function Frame:SetSpacing(spacing)
    self.sets.spacing = spacing
    self:Layout()
end

function Frame:GetSpacing()
    return self.sets.spacing or 0
end

--[[ Layout ]]--

--the wackiness here is for backward compaitbility reasons, since I did not implement true defaults
function Frame:SetLeftToRight(isLeftToRight)
    local isRightToLeft = not isLeftToRight

    self.sets.isRightToLeft = isRightToLeft and true or nil
    self:Layout()
end

function Frame:GetLeftToRight()
    return not self.sets.isRightToLeft
end

function Frame:SetTopToBottom(isTopToBottom)
    local isBottomToTop = not isTopToBottom

    self.sets.isBottomToTop = isBottomToTop and true or nil
    self:Layout()
end

function Frame:GetTopToBottom()
    return not self.sets.isBottomToTop
end

function Frame:Layout()
    if #self.buttons <= 0 then
        self.super.Layout(self)
        return
    end

    local cols = min(self:NumColumns(), #self.buttons)
    local rows = ceil(#self.buttons / cols)
    local pW, pH = self:GetPadding()
    local spacing = self:GetSpacing()
    local isLeftToRight = self:GetLeftToRight()
    local isTopToBottom = self:GetTopToBottom()

    local b = self.buttons[1]
    local w = b:GetWidth() + spacing
    local h = b:GetHeight() + spacing

    for i,b in pairs(self.buttons) do
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

        b:ClearAllPoints()
        b:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH))
    end

    local width = w*cols - spacing + pW*2
    local height = h*ceil(#self.buttons/cols) - spacing + pH*2

    self:SetSize(width + paddingW, height + paddingH)
end

function ButtonBar:UpdateClickThrough()
    local buttons = self.buttons
    if not buttons then return end

    local clickThrough = self:GetClickThrough()
    for i, button in pairs(self.buttons) do
        if clickThrough then
            button:EnableMouse(false)
        else
            button:EnableMouse(true)
        end
    end
end
