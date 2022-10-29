--------------------------------------------------------------------------------
-- ActionButtons - A pool of action buttons
--------------------------------------------------------------------------------
local AddonName, Addon = ...

local function createActionButton(id)
    local name = ('%sActionButton%d'):format(AddonName, id)

    local button = CreateFrame('CheckButton', name, nil, 'ActionBarButtonTemplate')

    button.id = id

    return button
end

-- handle notifications from our parent bar about whate the action button
-- ID offset should be
local actionButton_OnUpdateOffset = [[
    local offset = message or 0
    local id = self:GetAttribute('index') + offset

    if self:GetAttribute('action') ~= id then
        self:SetAttribute('action', id)
        self:RunAttribute("UpdateShown")
        self:CallMethod('UpdateState')
    end
]]

local actionButton_OnUpdateShowGrid = [[
    local new = message or 0
    local old = self:GetAttribute("showgrid") or 0

    if old ~= new then
        self:SetAttribute("showgrid", new)
        self:RunAttribute("UpdateShown")
    end
]]

local actionButton_UpdateShown = [[
    local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
                 and not self:GetAttribute("statehidden")

    if show then
        self:Show(true)
    else
        self:Hide(true)
    end
]]

-- action button creation is deferred so that we can avoid creating buttons for
-- bars set to show less than the maximum
local ActionButtons = setmetatable({}, {
    -- index creates & initializes buttons as we need them
    __index = function(self, id)
        -- validate the ID of the button we're getting is within an
        -- our expected range
        id = tonumber(id) or 0
        if id < 1 then
            error(('Usage: %s.ActionButtons[>0]'):format(AddonName), 2)
        end

        local button = createActionButton(id)

        -- apply our extra action button methods
        Mixin(button, Addon.ActionButtonMixin)

        -- apply hooks for quick binding
        -- this must be done before we reset the button ID, as we use it
        -- to figure out the binding action for the button
        Addon.BindableButton:AddQuickBindingSupport(button)

        -- set a handler for updating the action from a parent frame
        button:SetAttribute('_childupdate-offset', actionButton_OnUpdateOffset)

        -- set a handler for updating showgrid status
        button:SetAttribute('_childupdate-showgrid', actionButton_OnUpdateShowGrid)

        button:SetAttribute("UpdateShown", actionButton_UpdateShown)

        -- reset the ID to zero, as that prevents the default paging code
        -- from being used
        button:SetID(0)

        -- clear current position to avoid forbidden frame issues
        button:ClearAllPoints()

        -- reset the showgrid setting to default
        button:SetAttribute('showgrid', 0)

        button:Hide()

        -- enable mousewheel clicks
        button:EnableMouseWheel(true)

        rawset(self, id, button)
        return button
    end,

    -- newindex is set to block writes to prevent errors
    __newindex = function()
        error(('%s.ActionButtons does not support writes'):format(AddonName), 2)
    end
})

-- exports
Addon.ActionButtons = ActionButtons
