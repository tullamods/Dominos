--------------------------------------------------------------------------------
-- ActionButtonMixin
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------

local _, Addon = ...

local ActionButtonMap = { }

local function getActionPageOffset(bar)
    local page = bar:GetAttribute("actionpage")

    return (page - 1) * NUM_ACTIONBAR_BUTTONS
end

local function addBar(bar, offset)
    if not (bar and bar.actionButtons) then return end

    offset = offset or getActionPageOffset(bar)

    for i, button in pairs(bar.actionButtons) do
        -- reset id, so that the actionpage attribute is not taken into account
        -- see SecureActionButtonMixin:CalculateAction(button)
        button:SetID(0)

        ActionButtonMap[i + offset] = button
    end
end

addBar(MainMenuBar, 0)
addBar(MultiBarBottomLeft)
addBar(MultiBarBottomRight)
addBar(MultiBarLeft)
addBar(MultiBarRight)
addBar(MultiBar5)
addBar(MultiBar6)
addBar(MultiBar7)

Addon.ActionButtonMap = ActionButtonMap