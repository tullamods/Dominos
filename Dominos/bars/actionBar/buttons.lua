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

local function HasSpellID(action, spellID)
    local actionType, id, subType = GetActionInfo(action)
    if actionType == "spell" then
        return id == spellID
    end

    if actionType == "macro" then
        return subType == "spell" and id == spellID
    end

    if actionType == "flyout" and id then
        return FlyoutHasSpell(id, spellID)
    end

    return false
end

local function SafeMixin(button, trait)
    for k, v in pairs(trait) do
        if rawget(button, k) ~= nil then
            error(("%s[%q] has alrady been set"):format(button:GetName(), k), 2)
        end

        button[k] = v
    end
end

-- states
-- [button] = action
ActionButtons.buttons = {}

-- we use a traditional event handler so that we can take
-- advantage of unit event registration
ActionButtons:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

ActionButtons:RegisterEvent("PLAYER_LOGIN")
ActionButtons:Execute([[ ActionButtons = table.new(); DirtyButtons = table.new() ]])

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

function ActionButtons:PLAYER_LOGIN()
    -- initialize state
    self:SetAttributeNoHandler("showgrid", 0)

    -- game events
    self:TryRegisterEvent("ACTIONBAR_HIDEGRID")
    self:TryRegisterEvent("ACTIONBAR_SHOWGRID")
    self:TryRegisterEvent("ACTIONBAR_SLOT_CHANGED")

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

    self:SetAttributeNoHandler("_onattributechanged", [[
        if name == "commit" and value == 1 then
            for button in pairs(DirtyButtons) do
                button:RunAttribute("UpdateShown")
                DirtyButtons[button] = nil
            end
        end
    ]])

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

    -- show grid hack: monitor ActionButton1's attribute for this
    -- notify us when either of the game event reasons change
    ActionButton1:SetAttribute("showgrid", 0)

    self:WrapScript(ActionButton1, "OnAttributeChanged", [[
        if name ~= "showgrid" then return end

        for reason = 2, 4, 2 do
            local show = value % (reason * 2) >= reason
            control:RunAttribute("SetShowGrid", show, reason)
        end
    ]])

    RegisterAttributeDriver(self, "commit", 1)
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

function ActionButtons:PLAYER_REGEN_ENABLED()
    for k in pairs(self.dirtyCvars) do
        self:SetAttribute(k, GetCVarBool(k))
        self.dirtyCvars[k] = nil
    end
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
-- ActionButton Handlers
--------------------------------------------------------------------------------

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

local ActionButton_Click = [[
    if button == "HOTKEY" then
        return "LeftButton"
    end
]]

-- post click:
-- update the visibility of any button with the same action as this one
-- this is to handle cases where a person has picked up a spell, released the
-- mouse button, and then clicked on the button to place an action
local ActionButton_PostClick = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

local ActionButton_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local ActionButton_ReceiveDragAfter = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

local ActionButton_OnShow = [[
    self:RunAttribute("UpdateShown")
]]

local ActionButton_OnHide = [[
    self:RunAttribute("UpdateShown")
]]

--------------------------------------------------------------------------------
-- Methods
--------------------------------------------------------------------------------

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = _G[name]

    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

        SafeMixin(button, Addon.ActionButton)

        button:OnCreate(id)

        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChanged)
        self:WrapScript(button.bind, "OnClick", ActionButton_Click)
        self:WrapScript(button, "PostClick", ActionButton_PostClick)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)
        self:WrapScript(button, "OnShow", ActionButton_OnShow)
        self:WrapScript(button, "OnHide", ActionButton_OnHide)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local button = self:GetFrameRef("add")
            ActionButtons[button] = button:GetAttribute("action") or 0
        ]])
    end

    return button
end

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

function ActionButtons:TryRegisterEvent(event)
    if type(self[event]) ~= "function" then
        error(("Cannot register event %q - Handler is missing"):format(event), 2)
    end

    self:RegisterEvent(event)
end

function ActionButtons:TryRegisterUnitEvent(event, ...)
    if type(self[event]) ~= "function" then
        error(("Cannot register unit event %q - Handler is missing"):format(event), 2)
    end

    self:RegisterUnitEvent(event, ...)
end

-- collection metamethods
function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        button[method](button, ...)
    end
end

function ActionButtons:ForAllWhere(predicate, method, ...)
    for button, action in pairs(self.buttons) do
        if predicate(action) then
            button[method](button, ...)
        end
    end
end

function ActionButtons:ForActionSlot(slot, method, ...)
    for button, action in pairs(self.buttons) do
        if action == slot then
            button[method](button, ...)
        end
    end
end

function ActionButtons:ForSpellID(spellID, method, ...)
    local hasSpellID = HasSpellID
    for button, action in pairs(self.buttons) do
        if  hasSpellID(action, spellID) then
            button[method](button, ...)
        end
    end
end

function ActionButtons:ForVisible(method, ...)
    for button in pairs(self.buttons) do
        if button:IsVisible() then
            button[method](button, ...)
        end
    end
end

function ActionButtons:ForVisibleWhere(predicate, method, ...)
    for button, action in pairs(self.buttons) do
        if button:IsVisible() and predicate(action) then
            button[method](button, ...)
        end
    end
end

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- exports
Addon.ActionButtons = ActionButtons
