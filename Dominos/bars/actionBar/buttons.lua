local ADDON_NAME, Addon = ...

local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerAttributeTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = ADDON_NAME .. "ActionButton%d"

-- global showgrid event reasons
local SHOW_GRID_REASONS = {
    -- CVAR = 1,
    GAME_EVENT = 2,
    SPELLBOOK_SHOWN = 4,
    KEYBOUND_EVENT = 8,
    ADDON_SHOW_EMPTY_BUTTONS = 16
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
ActionButtons.buttons = {
    -- [button] = action
}

ActionButtons.actionButtons = setmetatable({
    -- [action] = { [button] = true }
}, {
    __index = function(t, k)
        local r = {}

        t[k] = r

        return r
    end
})

ActionButtons.showGridStates = {
    -- [reason] = show
}

-- ActionButtons.blizzardButtons = {}
-- if Addon:IsBuild("retail") then
--     local function addBar(bar, page)
--         if not (bar and bar.actionButtons) then return end

--         page = page or bar:GetAttribute("actionpage")

--         -- when assigning buttons, we skip bar 12 (totems)
--         -- so shift pages above 12 down one
--         if page > 12 then
--             page = page - 1
--         end

--         local offset = (page - 1) * NUM_ACTIONBAR_BUTTONS

--         for i, button in pairs(bar.actionButtons) do
--             ActionButtons.blizzardButtons[i + offset] = button
--         end
--     end

--     addBar(MainMenuBar, 1) -- 1
--     addBar(MultiBarRight) -- 3
--     addBar(MultiBarLeft) -- 4
--     addBar(MultiBarBottomRight) -- 5
--     addBar(MultiBarBottomLeft) -- 6
--     addBar(MultiBar5) -- 13
--     addBar(MultiBar6) -- 14
--     addBar(MultiBar7) -- 15
-- else
--     local function addButton(button, page)
--         page = page or button:GetParent():GetAttribute("actionpage")

--         local index = button:GetID() + (page - 1) * NUM_ACTIONBAR_BUTTONS

--         ActionButtons.blizzardButtons[index] = button
--     end

--     for i = 1, NUM_ACTIONBAR_BUTTONS do
--         addButton(_G['ActionButton' .. i], 1) -- 1
--         addButton(_G['MultiBarRightButton' .. i]) -- 3
--         addButton(_G['MultiBarLeftButton' .. i]) -- 4
--         addButton(_G['MultiBarBottomRightButton' .. i]) -- 5
--         addButton(_G['MultiBarBottomLeftButton' .. i]) -- 6
--     end
-- end

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
    self:Initialize()

    -- game events
    self:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    self:RegisterEvent("ACTION_USABLE_CHANGED")
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("ARCHAEOLOGY_CLOSED")
    self:RegisterEvent("COMPANION_UPDATE")
    self:RegisterEvent("CVAR_UPDATE")
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
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
    end

    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")
end

function ActionButtons:ACTION_RANGE_CHECK_UPDATE(slot, isInRange, checksRange)
    self:ForActionSlot(slot, "SetInRange", isInRange, checksRange)
end

function ActionButtons:ACTION_USABLE_CHANGED(changes)
    for _, change in pairs(changes) do
        self:ForActionSlot(change.slot, "SetIsUsable", change.usuable, change.noMana)
    end
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:SetShowGrid(SHOW_GRID_REASONS.GAME_EVENT, true)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(SHOW_GRID_REASONS.GAME_EVENT, false)
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

function ActionButtons:CVAR_UPDATE(event, key)
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

-- addon callbacks
function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(SHOW_GRID_REASONS.KEYBOUND_EVENT, true)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(SHOW_GRID_REASONS.KEYBOUND_EVENT, false)
end

function ActionButtons:SHOW_EMPTY_BUTTONS_CHANGED(_, show)
    self:SetShowGrid(SHOW_GRID_REASONS.ADDON_SHOW_EMPTY_BUTTONS, show)
end

function ActionButtons:OnActionChanged(button, action, prevAction)
    if prevAction ~= nil then
        self.actionButtons[prevAction][button] = nil
    end

    self.actionButtons[action][button] = action
    self.buttons[button] = action

    C_ActionBar.EnableActionRangeCheck(action, true)
end

-- api
local ActionButton_ClickBefore = [[
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

local ActionButton_ReceiveDragBefore = [[
    if kind then
        return "message", kind
    end
]]

local ActionButton_ReceiveDragAfter = [[
    self:CallMethod("UpdateShown")
]]

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = _G[name]

    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, SecureHandlerDragTemplate")

        Addon.ActionButton:Bind(button)

        button:OnCreate(id)

        self:WrapScript(button, "OnClick", ActionButton_ClickBefore, ActionButton_ClickAfter)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)

        -- initialize showgrid values
        self:LoadShowGrid(button)

        -- local blizzardButton = self.blizzardButtons[id]
        -- if blizzardButton then
        --     local commandName = blizzardButton.commandName

        --     if not commandName then
        --         if blizzardButton.buttonType then
        --             commandName = blizzardButton.buttonType .. blizzardButton:GetID()
        --         else
        --             commandName = blizzardButton:GetName():upper()
        --         end
        --     end

        --     if commandName then
        --         button.commandName = commandName
        --         button:SetOverrideBindings(GetBindingKey(commandName))
        --     end
        -- end
    end

    return button
end

function ActionButtons:Initialize()
    self.showGridStates[SHOW_GRID_REASONS.ADDON_SHOW_EMPTY_BUTTONS] = Addon:ShowGrid()

    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        self.showGridStates[SHOW_GRID_REASONS.KEYBOUND_EVENT] = keybound:IsShown()
    end
end

function ActionButtons:LoadShowGrid(button)
    local states = self.showGridStates

    for _, reason in pairs(SHOW_GRID_REASONS) do
        button:SetShowGrid(reason, states[reason] and true)
    end
end

function ActionButtons:SetShowGrid(reason, show)
    self.showGridStates[reason] = show and true or nil
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

-- exports
Addon.ActionButtons = ActionButtons