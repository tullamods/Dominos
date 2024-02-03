local AddonName, Addon = ...
if not Addon:IsBuild("retail") then return end

local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerAttributeTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- global showgrid event reasons
ActionButtons.ShowGridReasons = {
    -- CVAR = 1,
    GAME_EVENT = 2,
    SPELLBOOK_SHOWN = 4,

    KEYBOUND_EVENT = 16,
    SHOW_EMPTY_BUTTONS = 32,
    SHOW_EMPTY_BUTTONS_PER_BAR = 64
}

-- states
-- [button] = action
ActionButtons.buttons = {}

ActionButtons:Execute([[
    ActionButtons = table.new()
    DirtyButtons = table.new()
]])

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

ActionButtons:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function ActionButtons:PLAYER_LOGIN()
    -- initialize state
    self:SetAttributeNoHandler("showgrid", 0)

    -- game events
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

    -- addon callbacks
    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")
    Addon.RegisterCallback(self, "SHOW_SPELL_ANIMATIONS_CHANGED")
    Addon.RegisterCallback(self, "SHOW_SPELL_GLOWS_CHANGED")
    Addon.RegisterCallback(self, "LAYOUT_LOADED")

    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end

    -- secure methods
    self:SetAttributeNoHandler("SetShowGrid", [[
        local show, reason, force = ...
        local value = self:GetAttribute("showgrid")
        local prevValue = value

        if show then
            if value % (reason * 2) < reason then
                value = value + reason
            end
        elseif value % (reason * 2) >= reason then
            value = value - reason
        end

        if (prevValue ~= value) or force then
            self:SetAttribute("showgrid", value)

            for button in pairs(ActionButtons) do
                button:RunAttribute("SetShowGrid", show, reason)
            end
        end
    ]])

    self:SetAttributeNoHandler("ForActionSlot", [[
        local id, method = ...
        for button, action in pairs(ActionButtons) do
            if action == id then
                button:RunAttribute(method)
            end
        end
    ]])

    -- commit hack:
    -- we can leverage and attribute or secure state driver driver in order to
    -- cause something to happen on the next frame or so. We do this by marking
    -- buttons as dirty when something changes that we want to handle later, and
    -- then setting the commit attribute to 0. After STATE_DRIVER_UPDATE_THROTTLE
    -- duration (200ms), the value of commit will reset to our constant value of
    -- 1 and we'll apply the visibility change
    RegisterAttributeDriver(self, "commit", 1)

    self:SetAttributeNoHandler("_onattributechanged", [[
        if name == "commit" and value == 1 then
            for button in pairs(DirtyButtons) do
                button:RunAttribute("UpdateShown")
                DirtyButtons[button] = nil
            end
        end
    ]])

    -- showgrid hack:
    -- monitor ActionButton1's attribute changes to its showgrid attribute.
    -- When it changes, update the controller's show grid attribute for any of
    -- of the reasons only triggered by game events (like ACTIONBAR_SHOWGRID).
    -- Propagate those changes to all the buttons managed by the controller.
    -- This allows us to properly show and hide action buttons in combat
    -- when the player is attempting to drag and drop abilities
    ActionButton1:SetAttribute("showgrid", 0)

    self:WrapScript(ActionButton1, "OnAttributeChanged", [[
        if name ~= "showgrid" then return end

        for reason = 2, 4, 2 do
            local show = value % (reason * 2) >= reason
            control:RunAttribute("SetShowGrid", show, reason)
        end
    ]])
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:SetShowGrid(true, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(false, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_SLOT_CHANGED(slot)
    if slot == 0 or slot == nil then
        self:ForAll("UpdateIcon")
    else
        self:ForActionSlot(slot, "UpdateIcon")
    end
end

function ActionButtons:PLAYER_ENTERING_WORLD()
    self:ForAll("UpdateShown")
end

-- addon callbacks
function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(true, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(false, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:SHOW_EMPTY_BUTTONS_CHANGED(_, show)
    self:SetShowGrid(show, self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
end

function ActionButtons:SHOW_SPELL_ANIMATIONS_CHANGED(_, show)
    self:SetShowSpellAnimations(show)
end

function ActionButtons:SHOW_SPELL_GLOWS_CHANGED(_, show)
    self:SetShowSpellGlows(show)
end

function ActionButtons:LAYOUT_LOADED()
    self:SetShowSpellGlows(Addon:ShowingSpellGlows())
    self:SetShowSpellAnimations(Addon:ShowingSpellAnimations())
    self:SetShowGrid(Addon:ShowGrid(), self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
end

function ActionButtons:OnActionChanged(buttonName, action)
    local button = _G[buttonName]
    if button ~= nil then
        self.buttons[button] = action
    end
end

--------------------------------------------------------------------------------
-- Action Button Constrution
--------------------------------------------------------------------------------

-- keep track of the current action associated with a button
-- mark the button as dirty when the action changes, so that we can make sure
-- it is properly shown later
local ActionButton_AttributeChanged = [[
    if name ~= "action" then return end

    local prevValue = ActionButtons[self]
    if prevValue ~= value then
        ActionButtons[self] = value

        DirtyButtons[self] = value
        control:SetAttribute("commit", 0)

        control:CallMethod("OnActionChanged", self:GetName(), value, prevValue)
    end
]]

-- translate HOTKEY clicks into LeftButton
local ActionButton_Click = [[
    if button == "HOTKEY" then
        return "LeftButton"
    end
]]

-- after clicking a button, or after dragging something onto a button, update
-- the visibility of any button with the same action. This is to handle placing
-- new actions on a button
local ActionButton_PostClick = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

-- if we're dragging something onto a button, make sure to update the visibil;it
local ActionButton_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local ActionButton_ReceiveDragAfter = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

-- when showing or hiding a button, reapply the visibility of the button to
-- work around delayed updates and help mitigate flashing
local ActionButton_OnShowHide = [[
    self:RunAttribute("UpdateShown")
]]

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = _G[name]

    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

        -- add custom methods
        for k, v in pairs(Addon.ActionButton) do
            if rawget(button, k) ~= nil then
                error(("%s[%q] has alrady been set"):format(button:GetName(), k), 2)
            end

            button[k] = v
        end

        -- initialize the button
        button:OnCreate(id)

        -- add secure handlers
        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChanged)
        self:WrapScript(button.bind, "OnClick", ActionButton_Click)
        self:WrapScript(button, "PostClick", ActionButton_PostClick)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)
        self:WrapScript(button, "OnShow", ActionButton_OnShowHide)
        self:WrapScript(button, "OnHide", ActionButton_OnShowHide)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local button = self:GetFrameRef("add")
            ActionButtons[button] = button:GetAttribute("action") or 0
        ]])
    end

    return button
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

function ActionButtons:SetShowGrid(show, reason)
    self:ForAll("SetShowGridInsecure", show, reason)
end

function ActionButtons:SetShowSpellGlows(enable)
    local f = ActionBarActionEventsFrame

    if enable then
        if not f:IsEventRegistered("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
            f:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
            f:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
        end
    else
        if f:IsEventRegistered("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
            f:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
            f:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
        end
    end
end

function ActionButtons:SetShowSpellAnimations(enable)
    local f = ActionBarActionEventsFrame

    if enable then
        if not f:IsEventRegistered("UNIT_SPELLCAST_SENT") then
            f:RegisterEvent("UNIT_SPELLCAST_SENT")
            f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
            f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        end
    else
        if f:IsEventRegistered("UNIT_SPELLCAST_SENT") then
            f:UnregisterEvent("UNIT_SPELLCAST_SENT")
            f:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
            f:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
            f:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_START")
            f:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
            f:UnregisterEvent("UNIT_SPELLCAST_FAILED")
            f:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
            f:UnregisterEvent("UNIT_SPELLCAST_RETICLE_CLEAR")
            f:UnregisterEvent("UNIT_SPELLCAST_RETICLE_TARGET")
            f:UnregisterEvent("UNIT_SPELLCAST_START")
            f:UnregisterEvent("UNIT_SPELLCAST_STOP")
            f:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        end
    end
end

--------------------------------------------------------------------------------
-- Collection Methods
--------------------------------------------------------------------------------

function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        button[method](button, ...)
    end
end

function ActionButtons:ForActionSlot(slot, method, ...)
    for button, action in pairs(self.buttons) do
        if action == slot then
            button[method](button, ...)
        end
    end
end

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- startup and export
ActionButtons:RegisterEvent("PLAYER_LOGIN")

Addon.ActionButtons = ActionButtons
