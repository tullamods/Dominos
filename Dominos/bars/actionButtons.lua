--------------------------------------------------------------------------------
-- ActionButtons - A pregenerated list of all action buttons
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local ActionButtons = {}

local function CreateActionButton(id)
    local button = CreateFrame('CheckButton', ('%sActionButton%d'):format(AddonName, id), nil, 'ActionBarButtonTemplate')

    Addon.CastOnKeyPressHandler:Register(button)

    return button
end

local function GetMainActionBarButton(id)
    local button = _G[('ActionButton%d'):format(id)]

    -- store the button type, since the main bar doesn't define one
    button:SetAttribute('buttonType', 'ACTIONBUTTON')

    return button
end

local function AcquireActionButton(id)
    if id <= 12 then
        return GetMainActionBarButton(id)
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

-- do one time setup on all action buttons
for id = 1, 120 do
    local button = AcquireActionButton(id)

    -- apply our extra action button methods
    Mixin(button, Addon.ActionButtonMixin)

    -- set the base action ID fo the button for use later
    button:SetAttribute('action--base', id)

    -- set a handler for updating the action from a parent frame
    button:SetAttribute('_childupdate-action', [[
        local state = message
        local overridePage = self:GetParent():GetAttribute('state-overridepage')
        local newActionID

        if state == 'override' then
            newActionID = (self:GetAttribute('button--index') or 1) + (overridePage - 1) * 12
        else
            newActionID = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')
        end

        if newActionID ~= self:GetAttribute('action') then
            self:SetAttribute('action', newActionID)
            self:CallMethod('UpdateState')
        end
    ]])

    -- keep track of our old button id, if we have one
    button:SetAttribute("bindingid", button:GetID())

    -- this is used to preserve the button's old id
    -- we cannot simply keep a button's id at > 0 or blizzard code will take
    -- control of paging
    -- but we need the button's id for the old bindings system
    button:SetID(0)

    -- clear current position to avoid forbidden frame issues
    button:ClearAllPoints()

    -- reset the showgrid setting to default
    button:SetAttribute('showgrid', 0)

    -- enable mousewheel clicks
    button:EnableMouseWheel(true)

    -- apply hooks for button binding
    Addon.BindableButton:Inject(button)

    ActionButtons[id] = button
end

Addon.ActionButtons = ActionButtons
