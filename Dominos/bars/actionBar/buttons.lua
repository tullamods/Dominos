local ADDON_NAME, Addon = ...
local ActionButtons = CreateFrame("Frame")

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = ADDON_NAME .. "ActionButton%d"
local ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND = 2048

local function IsSummonPetAction(action)
    return GetActionInfo(action) == "summonpet"
end

local function IsSpellID(action, spellID)
    local actionType, id, subType = GetActionInfo(action)
    if actionType == "spell" then
        return id == spellID
    end

    if actionType == "macro" then
        return subType == "spell" and id == spellID
    end

    if actionType == "flyout" then
        return FlyoutHasSpell(id, spellID)
    end

    return false
end

-- configuration
ActionButtons.buttons = {}

ActionButtons.actionButtons = setmetatable({}, {
    __index = function(t, k)
        local v = {}

        t[k] = v

        return v
    end
})

-- we use a traditional event handler so that we can take
-- advantage of unit event registration
ActionButtons:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if type(handler) == "function" then
        handler(self, ...)
    else
        error(("%s is missing a handler for %q"):format("ActionButtons", event))
    end
end)

ActionButtons:RegisterEvent("PLAYER_LOGIN")

-- events
function ActionButtons:PLAYER_LOGIN()
    self:Hide()

    -- game events
    self:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    self:RegisterEvent("ACTION_USABLE_CHANGED")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("ARCHAEOLOGY_CLOSED")
    self:RegisterEvent("COMPANION_UPDATE")
    self:RegisterEvent("PET_BAR_UPDATE")
    self:RegisterEvent("PET_STABLE_SHOW")
    self:RegisterEvent("PET_STABLE_UPDATE")
    self:RegisterEvent("PLAYER_ENTER_COMBAT")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVE_COMBAT")
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")
    self:RegisterEvent("SPELL_UPDATE_ICON")
    self:RegisterEvent("START_AUTOREPEAT_SPELL")
    self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    self:RegisterEvent("TRADE_SKILL_CLOSE")
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    self:RegisterEvent("UPDATE_SUMMONPETS_ACTION")

    -- unit events
    self:RegisterUnitEvent("LOSS_OF_CONTROL_ADDED", "player")
    self:RegisterUnitEvent("LOSS_OF_CONTROL_UPDATE", "player")
    self:RegisterUnitEvent("UNIT_AURA", "pet")
    self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    self:RegisterUnitEvent("UNIT_FLAGS", "pet")

    -- addon callbacks
    local keybound = LibStub("LibKeybound-3.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
    end
end

function ActionButtons:ACTION_RANGE_CHECK_UPDATE(slot, isInRange, checksRange)
    self:ForActionSlot(slot, "SetInRange", isInRange, checksRange)
end

function ActionButtons:ACTION_USABLE_CHANGED(changes)
    for _, change in ipairs(changes) do
        self:ForActionSlot(change.slot, "SetIsUsable", change.usuable, change.noMana)
    end
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

function ActionButtons:PLAYER_MOUNT_DISPLAY_CHANGED()
    self:ForAllWhere(HasAction, "UpdateUsable")
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

-- callbacks
function ActionButtons:LIBKEYBOUND_ENABLED()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND, true)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND, false)
end

function ActionButtons:OnActionButtonActionChanged(button, action, prevAction)
    if prevAction ~= nil then
        self.actionButtons[prevAction][button] = nil
    end

    self.actionButtons[action][button] = action
    self.buttons[button] = action

    C_ActionBar.EnableActionRangeCheck(action, true)
end

-- api
function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)

    local button = _G[name]
    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, SecureHandlerDragTemplate")

        Addon.ActionButton:Bind(button)

        button:OnCreate(id)
    end

    return button
end

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
        if next(buttons) ~= nil and IsSpellID(action, spellID) then
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

-- exports
Addon.ActionButtons = ActionButtons