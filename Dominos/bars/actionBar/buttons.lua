local AddonName, Addon = ...
if not Addon:IsBuild("retail") then return end

local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate')

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

-- how many bars are available
local function IsSummonPetAction(action)
    return GetActionInfo(action) == "summonpet"
end

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

-- states
-- [button] = action
ActionButtons.buttons = {}

-- [action] = { [button] = true }
ActionButtons.actionButtons = setmetatable({}, {
    __index = function(t, k)
        local r = {}

        t[k] = r

        return r
    end
})

-- dirty secure attributes
ActionButtons.dirtyCvars = {}

-- we use a traditional event handler so that we can take
-- advantage of unit event registration
ActionButtons:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

ActionButtons:RegisterEvent("PLAYER_LOGIN")
ActionButtons:Execute([[ ActionButtons = table.new() ]])

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

function ActionButtons:PLAYER_LOGIN()
    -- initialize state
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttribute("lockActionBars", GetCVarBool("lockActionBars"))
    self:SetShowSpellGlows(Addon:ShowingSpellGlows())
    self:SetShowGrid(Addon:ShowGrid(), self.ShowGridReasons.SHOW_EMPTY_BUTTONS)

    -- game events
    self:TryRegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    self:TryRegisterEvent("ACTION_USABLE_CHANGED")
    self:TryRegisterEvent("ACTIONBAR_HIDEGRID")
    self:TryRegisterEvent("ACTIONBAR_SHOWGRID")
    self:TryRegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:TryRegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self:TryRegisterEvent("ACTIONBAR_UPDATE_STATE")
    self:TryRegisterEvent("ARCHAEOLOGY_CLOSED")
    self:TryRegisterEvent("COMPANION_UPDATE")
    self:TryRegisterEvent("CVAR_UPDATE")
    self:TryRegisterEvent("PET_BAR_UPDATE")
    self:TryRegisterEvent("PET_STABLE_SHOW")
    self:TryRegisterEvent("PET_STABLE_UPDATE")
    self:TryRegisterEvent("PLAYER_ENTER_COMBAT")
    self:TryRegisterEvent("PLAYER_ENTERING_WORLD")
    self:TryRegisterEvent("PLAYER_LEAVE_COMBAT")
    self:TryRegisterEvent("PLAYER_REGEN_ENABLED")
    self:TryRegisterEvent("SPELL_UPDATE_CHARGES")
    self:TryRegisterEvent("SPELL_UPDATE_ICON")
    self:TryRegisterEvent("START_AUTOREPEAT_SPELL")
    self:TryRegisterEvent("STOP_AUTOREPEAT_SPELL")
    self:TryRegisterEvent("TRADE_SKILL_CLOSE")
    self:TryRegisterEvent("TRADE_SKILL_SHOW")
    self:TryRegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self:TryRegisterEvent("UPDATE_SUMMONPETS_ACTION")

    -- unit events
    self:TryRegisterUnitEvent("LOSS_OF_CONTROL_ADDED", "player")
    self:TryRegisterUnitEvent("LOSS_OF_CONTROL_UPDATE", "player")
    self:TryRegisterUnitEvent("UNIT_AURA", "pet")
    self:TryRegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self:TryRegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self:TryRegisterUnitEvent("UNIT_FLAGS", "pet")

    -- addon callbacks
    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")
    Addon.RegisterCallback(self, "SHOW_SPELL_GLOWS_CHANGED")
    Addon.RegisterCallback(self, "LAYOUT_LOADED")

    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end

    -- showgrid hack
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

    ActionButton1:SetAttributeNoHandler("showgrid", 0)

    self:WrapScript(ActionButton1, "OnAttributeChanged", [[
        if name ~= "showgrid" then return end

        for reason = 2, 4, 2 do
            local show = value % (reason * 2) >= reason
            control:RunAttribute("SetShowGrid", show, reason)
        end
    ]])
end

function ActionButtons:ACTION_RANGE_CHECK_UPDATE(slot, isInRange, checksRange)
    local buttons = self.actionButtons[slot]

    if buttons then
        local usable, oom = IsUsableAction(slot)
        local oor = checksRange and not isInRange

        for button in pairs(buttons) do
            button:UpdateUsable(usable, oom, oor)
        end
    end
end

function ActionButtons:ACTION_USABLE_CHANGED(changes)
    for _, change in pairs(changes) do
        local buttons = self.actionButtons[change.slot]

        if buttons ~= nil then
            local oor = IsActionInRange(change.slot) == false

            for button in pairs(buttons) do
                button:UpdateUsable(change.usable, change.noMana, oor)
            end
        end
    end
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:SetShowGrid(true, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(false, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_UPDATE_STATE()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:ACTIONBAR_SLOT_CHANGED(slot)
    if slot == 0 or slot == nil then
        self:ForAll("Update")
    else
        self:ForActionSlot(slot, "Update")
    end
end

function ActionButtons:ACTIONBAR_UPDATE_COOLDOWN()
    self:ForAllWhere(HasAction, "UpdateCooldown")
end

function ActionButtons:ARCHAEOLOGY_CLOSED()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:CVAR_UPDATE(name, ...)
    if name == "lockActionBars" then
        self:TrySetCVarAttribute(name, GetCVarBool(name))
    end
end

function ActionButtons:COMPANION_UPDATE(companionType)
    if companionType == "MOUNT" then
        self:ForAllWhere(HasAction, "UpdateActive")
    end
end

function ActionButtons:PET_BAR_UPDATE()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:PET_STABLE_SHOW()
    self:ForAll("Update")
end

function ActionButtons:PET_STABLE_UPDATE()
    self:ForAll("Update")
end

function ActionButtons:PLAYER_ENTER_COMBAT()
    self:ForAllWhere(IsAttackAction, "UpdateFlashing")
end

function ActionButtons:PLAYER_LEAVE_COMBAT()
    self:ForAllWhere(IsAttackAction, "UpdateFlashing")
end

function ActionButtons:PLAYER_ENTERING_WORLD()
    self:ForAll("Update")
end

function ActionButtons:PLAYER_REGEN_ENABLED()
    for k in pairs(self.dirtyCvars) do
        self:SetAttribute(k, GetCVarBool(k))
        self.dirtyCvars[k] = nil
    end
end

function ActionButtons:SPELL_UPDATE_CHARGES()
    self:ForAllWhere(HasAction, "UpdateCount")
end

function ActionButtons:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID)
    self:ForSpellID(spellID, "ShowOverlayGlow")
end

function ActionButtons:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
    self:ForSpellID(spellID, "HideOverlayGlow")
end

function ActionButtons:SPELL_UPDATE_ICON()
    self:ForAllWhere(HasAction, "UpdateIcon")
end

function ActionButtons:START_AUTOREPEAT_SPELL()
    self:ForAllWhere(IsAutoRepeatAction, "UpdateFlashing")
end

function ActionButtons:STOP_AUTOREPEAT_SPELL()
    self:ForAllWhere(IsAutoRepeatAction, "UpdateFlashing")
end

function ActionButtons:TRADE_SKILL_CLOSE()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:TRADE_SKILL_SHOW()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:UPDATE_SHAPESHIFT_FORM()
    self:ForAllWhere(HasAction, "UpdateIcon")
end

function ActionButtons:UPDATE_SUMMONPETS_ACTION()
    self:ForAllWhere(IsSummonPetAction, "UpdateIcon")
end

-- unit events
function ActionButtons:LOSS_OF_CONTROL_ADDED()
    self:ForAllWhere(HasAction, "UpdateCooldown")
end

function ActionButtons:LOSS_OF_CONTROL_UPDATE()
    self:ForAllWhere(HasAction, "UpdateCooldown")
end

function ActionButtons:UNIT_AURA()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:UNIT_ENTERED_VEHICLE()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:UNIT_EXITED_VEHICLE()
    self:ForAllWhere(HasAction, "UpdateActive")
end

function ActionButtons:UNIT_FLAGS()
    self:ForAllWhere(HasAction, "UpdateActive")
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

function ActionButtons:SHOW_SPELL_GLOWS_CHANGED(_, show)
    self:SetShowSpellGlows(show)
end

function ActionButtons:LAYOUT_LOADED()
    self:SetShowSpellGlows(Addon:ShowingSpellGlows())
    self:SetShowGrid(Addon:ShowGrid(), self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
end

function ActionButtons:OnActionChanged(buttonName, action, prevAction)
    local button = _G[buttonName]
    if button == nil then
        return
    end

    if prevAction ~= nil then
        self.actionButtons[prevAction][button] = nil
    end

    self.actionButtons[action][button] = action
    self.buttons[button] = action

    C_ActionBar.EnableActionRangeCheck(action, true)
end

--------------------------------------------------------------------------------
-- ActionButton Handlers
--------------------------------------------------------------------------------

local ActionButton_AttributeChanged = [[
    if name ~= "action" then return end

    local prevValue = ActionButtons[self]
    if prevValue ~= value then
        ActionButtons[self] = value
        control:CallMethod("OnActionChanged", self:GetName(), value, prevValue)
    end
]]

-- pre click:
-- update press and hold action state
local ActionButton_PreClick = [[
    local actionType, id = GetActionInfo(self:GetAttribute("action"))

    if actionType == "spell" then
        local ph = IsPressHoldReleaseSpell(id)
        if self:GetAttribute("pressAndHoldAction") ~= ph then
            self:SetAttribute("pressAndHoldAction", ph)
        end
    end
]]

-- on click:
-- remap hotkey presses to LeftButton and let both down and up clicks through
-- prevent activating actions on mouse button clicks. This is to avoid conflicts
-- with drag and drop behaviors
--
-- When filtering out mouse button down presses, we need to also temporarily
-- turn off the cast on key down behavior. We restore it after the mouse button
-- was released
--
-- /click macros complicate this a bit. The simplest version, /click Button only
-- triggers the default click (left button up). So to handle these, we keep
-- track of the button that was originally clicked. The original button will
-- disable the cast on key press setting for any mouse button down call.
-- Any buttons clicked during the click of that button will adjust the setting
-- on an up click
local ActionButton_Click = [[
    local callerName = control:GetAttribute("caller")
    local buttonName = self:GetName()
    local isCaller

    if callerName == nil then
        control:SetAttribute("caller", buttonName)
        isCaller = true
    else
        isCaller = callerName == buttonName
    end

    if button == "HOTKEY" then
        return "LeftButton"
    end

    if down then
        if isCaller then
            control:CallMethod("SaveActionButtonUseKeyDown", buttonName)
        end
        return false
    end

    if not isCaller then
        control:CallMethod("SaveActionButtonUseKeyDown", buttonName)
    end
    return nil, true
]]

local ActionButton_ClickAfter = [[
    local buttonName = self:GetName()

    if control:GetFrameRef("caller") == buttonName then
        control:SetFrameRef("caller", nil)
    end

    control:CallMethod("RestoreActionButtonUseKeyDown", buttonName)
]]

-- post click:
-- update the visibility of any button with the same action as this one
-- this is to handle cases where a person has picked up a spell, released the
-- mouse button, and then clicked on the button to place an action
local ActionButton_PostClick = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

-- drag & drop
local ActionButton_DragStart = [[
    if not (IsModifiedClick("PICKUPACTION") or not control:GetAttribute("lockActionBars")) then
        return false
    end
]]

local ActionButton_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local ActionButton_ReceiveDragAfter = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

--------------------------------------------------------------------------------
-- Methods
--------------------------------------------------------------------------------

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = _G[name]

    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, SecureHandlerAttributeTemplate, SecureHandlerDragTemplate, ActionButtonTemplate")

        Addon.ActionButton:Bind(button)

        button:OnCreate(id)

        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChanged)

        self:WrapScript(button, "PreClick", ActionButton_PreClick)
        self:WrapScript(button, "OnClick", ActionButton_Click, ActionButton_ClickAfter)
        self:WrapScript(button, "PostClick", ActionButton_PostClick)

        self:WrapScript(button, "OnDragStart", ActionButton_DragStart)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)

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
    self:ForAll("SetShowGrid", show, reason)
end

function ActionButtons:SetShowSpellGlows(enable)
    if enable then
        if not self:IsEventRegistered("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
            self:TryRegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
            self:TryRegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        end
    else
        if self:IsEventRegistered("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
            self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
            self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
            self:ForAll("HideOverlayGlow")
        end
    end
end

function ActionButtons:SaveActionButtonUseKeyDown(owner)
    if self.restoreKeyDown == nil and GetCVarBool("ActionButtonUseKeyDown") then
        SetCVar("ActionButtonUseKeyDown", 0)
        self.restoreKeyDown = owner
    end
end

function ActionButtons:RestoreActionButtonUseKeyDown(owner)
    if self.restoreKeyDown == owner then
        SetCVar("ActionButtonUseKeyDown", 1)
        self.restoreKeyDown = nil
    end
end

function ActionButtons:TrySetCVarAttribute(key, value)
    if InCombatLockdown() then
        self.dirtyCvars[key] = true
        return false
    end

    self.dirtyCvars[key] = nil
    self:SetAttribute(key, value)
    return true
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
        local callback = button[method]
        if type(callback) == "function" then
            callback(button, ...)
        else
            error(("ActionButton %d does not have a method named %q"):format(button.id, method))
        end
    end
end

function ActionButtons:ForAllWhere(predicate, method, ...)
    for action, buttons in pairs(self.actionButtons) do
        if next(buttons) ~= nil and predicate(action) then
            for button in pairs(buttons) do
                local callback = button[method]
                if type(callback) == "function" then
                    callback(button, ...)
                else
                    error(("ActionButton %d does not have a method named %q"):format(button.id, method))
                end
            end
        end
    end
end

function ActionButtons:ForActionSlot(slot, method, ...)
    local actions = rawget(self.actionButtons, slot)

    if actions ~= nil then
        for button in pairs(actions) do
            local callback = button[method]
            if type(callback) == "function" then
                callback(button, ...)
            else
                error(("ActionButton %d does not have a method named %q"):format(button.id, method))
            end
        end
    end
end

function ActionButtons:ForSpellID(spellID, method, ...)
    for action, buttons in pairs(self.actionButtons) do
        if next(buttons) ~= nil and HasSpellID(action, spellID) then
            for button in pairs(buttons) do
                local callback = button[method]
                if type(callback) == "function" then
                    callback(button, ...)
                else
                    error(("ActionButton %d does not have a method named %q"):format(button.id, method))
                end
            end
        end
    end
end

function ActionButtons:ForVisible(method, ...)
    for button in pairs(self.buttons) do
        if button:IsVisible() then
            local callback = button[method]
            if type(callback) == "function" then
                callback(button, ...)
            else
                error(("ActionButton %d does not have a method named %q"):format(button.id, method))
            end
        end
    end
end

function ActionButtons:ForVisibleWhere(predicate, method, ...)
    for button, action in pairs(self.buttons) do
        if button:IsVisible() and predicate(action) then
            local callback = button[method]
            if type(callback) == "function" then
                callback(button, ...)
            else
                error(("ActionButton %d does not have a method named %q"):format(button.id, method))
            end
        end
    end
end

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- exports
Addon.ActionButtons = ActionButtons
