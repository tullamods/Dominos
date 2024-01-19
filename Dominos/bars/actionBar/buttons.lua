local AddonName, Addon = ...
if not Addon:IsBuild("retail") then return end

local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

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
ActionButtons.buttons = { }

-- [action] = { [button] = true }
ActionButtons.actionButtons = setmetatable({}, {
    __index = function(t, k)
        local r = {}

        t[k] = r

        return r
    end
})

-- dirty secure attributes
ActionButtons.dirtyAttributes = {}

-- we use a traditional event handler so that we can take
-- advantage of unit event registration
ActionButtons:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

ActionButtons:RegisterEvent("PLAYER_LOGIN")
ActionButtons:Execute([[ ActionButtons = table.new() ]])

-- events
function ActionButtons:PLAYER_LOGIN()
    self:Initialize()

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
    self:TryRegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self:TryRegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
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
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
    end

    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")

    -- showgrid hack
    self:SetAttributeNoHandler("showgrid", 0)
    -- self:SetAttributeNoHandler("sgc", 1)
    -- RegisterAttributeDriver(self, "sgc", 1)

    -- self:SetAttributeNoHandler("_onattributechanged", [[
    --     if name == "sgc" and value == 1 then
    --         for button in pairs(ActionButtons) do
    --             button:RunAttribute("UpdateShown")
    --         end
    --     end
    -- ]])

    self:SetAttributeNoHandler("SetShowGrid", [[
        local reason, show = ...
        local value = self:GetAttribute("showgrid")
        local prevValue = value

        if show then
            if value % (reason * 2) < reason then
                value = value + reason
            end
        elseif value % (reason * 2) >= reason then
            value = value - reason
        end

        if prevValue ~= value then
            self:SetAttribute("showgrid", value)

            for button in pairs(ActionButtons) do
                button:RunAttribute("SetShowGrid", reason, show)
            end

            -- self:SetAttribute("sgc", 0)
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
            control:RunAttribute("SetShowGrid", reason, value % (reason * 2) >= reason)
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
    self:SetShowGrid(self.ShowGridReasons.GAME_EVENT, true)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(self.ShowGridReasons.GAME_EVENT, false)
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
        self:TrySetAttribute(name, GetCVarBool(name))
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
    for k, v in pairs(self.dirtyAttributes) do
        self:SetAttribute(k, v)
        self.dirtyAttributes[k] = nil
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
    self:SetShowGrid(self.ShowGridReasons.KEYBOUND_EVENT, true)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(self.ShowGridReasons.KEYBOUND_EVENT, false)
end

function ActionButtons:SHOW_EMPTY_BUTTONS_CHANGED(_, show)
    self:SetShowGrid(self.ShowGridReasons.SHOW_EMPTY_BUTTONS, show)
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

-- api
local ActionButton_AttributeChangedBefore = [[
    if name == "action" then
        local prevValue = ActionButtons[self]
        if prevValue ~= value then
            ActionButtons[self] = value
            control:CallMethod("OnActionChanged", self:GetName(), value, prevValue)
        end
    end
]]

local ActionButton_ClickBefore = [[
    local actionType, id = GetActionInfo(self:GetAttribute("action"))
    if actionType == "spell" then
        self:SetAttribute("pressAndHoldAction", IsPressHoldReleaseSpell(id))
    end

    if button == "HOTKEY" then
        return "LeftButton"
    end

    if down then
        control:CallMethod("SaveActionButtonUseKeyDown")
        return false
    end

    return nil, "RESTORE"
]]

local ActionButton_ClickAfter = [[
    if message == "RESTORE" then
        control:CallMethod("RestoreActionButtonUseKeyDown")
    end
]]

local ActionButton_DragStartBefore = [[
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

local ActionButton_PostClickBefore = [[
    control:RunAttribute("ForActionSlot", self:GetAttribute("action"), "UpdateShown")
]]

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = _G[name]

    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "SecureHandlerAttributeTemplate, SecureActionButtonTemplate, SecureHandlerDragTemplate, ActionButtonTemplate")

        Addon.ActionButton:Bind(button)

        button:OnCreate(id)

        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChangedBefore)
        self:WrapScript(button, "OnClick", ActionButton_ClickBefore, ActionButton_ClickAfter)
        self:WrapScript(button, "OnDragStart", ActionButton_DragStartBefore)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)
        self:WrapScript(button, "PostClick", ActionButton_PostClickBefore)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local button = self:GetFrameRef("add")
            ActionButtons[button] = button:GetAttribute("action") or 0
        ]])
    end

    return button
end

function ActionButtons:Initialize()
    self:SetAttribute("lockActionBars", GetCVarBool("lockActionBars"))
end

function ActionButtons:SetShowGrid(reason, show)
    self:ForAll("SetShowGrid", reason, show)
end

function ActionButtons:SaveActionButtonUseKeyDown()
    if GetCVarBool("ActionButtonUseKeyDown") then
        SetCVar("ActionButtonUseKeyDown", 0)
        self.restoreKeyDown = true
    end
end

function ActionButtons:RestoreActionButtonUseKeyDown()
    if self.restoreKeyDown then
        SetCVar("ActionButtonUseKeyDown", 1)
        self.restoreKeyDown = nil
    end
end

function ActionButtons:TrySetAttribute(key, value)
    if InCombatLockdown() then
        self.dirtyAttributes[key] = value
        return false
    end

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

function ActionButtons:ForAllWhere(condition, method, ...)
    for action, buttons in pairs(self.actionButtons) do
        if next(buttons) ~= nil and condition(action) then
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

function ActionButtons:GetAll()
    return pairs(self.actionButtons)
end

-- exports
Addon.ActionButtons = ActionButtons