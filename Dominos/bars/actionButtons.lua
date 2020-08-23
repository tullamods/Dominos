--------------------------------------------------------------------------------
-- ActionButtons - A pregenerated list of all action buttons
--------------------------------------------------------------------------------

local AddonName, Addon = ...

local NUM_ACTION_BUTTONS = 120

local function CreateActionButton(id)
    local name = ('%sActionButton%d'):format(AddonName, id)

    local button = CreateFrame('CheckButton', name, nil, 'ActionBarButtonTemplate')

    Addon.BindableButton:AddCastOnKeyPressSupport(button)

    return button
end

local function AcquireActionButton(id)
    if id <= 12 then
        return _G[('ActionButton%d'):format(id)]
    elseif id <= 24 then
        return CreateActionButton(id - 12)
    elseif id <= 36 then
        return _G[('MultiBarRightButton%d'):format(id - 24)]
    elseif id <= 48 then
        return _G[('MultiBarLeftButton%d'):format(id - 36)]
    elseif id <= 60 then
        return _G[('MultiBarBottomRightButton%d'):format(id - 48)]
    elseif id <= 72 then
        return _G[('MultiBarBottomLeftButton%d'):format(id - 60)]
    else
        return CreateActionButton(id - 60)
    end
end

local function getBindingAction(button)
    local id = button:GetID()

    if id > 0 then
        return (button.buttonType or 'ACTIONBUTTON') .. id
    end
end

local ActionButtons = {}

-- do one time setup on all action buttons
for id = 1, NUM_ACTION_BUTTONS do
    local button = AcquireActionButton(id)

    -- apply our extra action button methods
    Mixin(button, Addon.ActionButtonMixin)

    -- apply hooks for quick binding
    Addon.BindableButton:AddQuickBindingSupport(button, getBindingAction(button))

    -- set a handler for updating the action from a parent frame
    button:SetAttribute(
        '_childupdate-offset',
        [[
            local offset = message or 0
            local id = self:GetAttribute('index') + offset

            if self:GetAttribute('action') ~= id then
                self:SetAttribute('action', id)
                self:CallMethod('UpdateState')
            end
        ]]
    )

    button:SetID(0)

    -- clear current position to avoid forbidden frame issues
    button:ClearAllPoints()

    -- reset the showgrid setting to default
    button:SetAttribute('showgrid', 0)

    -- enable mousewheel clicks
    button:EnableMouseWheel(true)

    ActionButtons[id] = button
end

-- exports
Addon.ActionButtons = ActionButtons
