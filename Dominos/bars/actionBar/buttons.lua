local AddonName, Addon = ...
local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerAttributeTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

local function noop()
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- global showgrid event reasons
ActionButtons.ShowGridReasons = {
    -- CVAR = 1,
    GAME_EVENT = 2,
    SPELLBOOK_SHOWN = 4,

    KEYBOUND_EVENT = 16,
    SHOW_EMPTY_BUTTONS_PER_BAR = 32
}

-- states
-- [button] = action
ActionButtons.buttons = {}
ActionButtons.blizzardActionButtonBridge = {}
ActionButtons.blizzardActionButtonBridgeHooked = {}
ActionButtons.pendingExternalOverrideUpdates = {}

ActionButtons:Execute([[
    ActionButtons = table.new()
    DirtyButtons = table.new()
]])

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

function ActionButtons:Initialize()
    -- register game events
    self:SetScript("OnEvent", function(f, event, ...) f[event](f, ...); end)
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("PET_BAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("SPELLS_CHANGED")

    -- addon callbacks
    Addon.RegisterCallback(self, "LAYOUT_LOADED")
    Addon.RegisterCallback(self, "SHOW_SPELL_ANIMATIONS_CHANGED")
    Addon.RegisterCallback(self, "SHOW_SPELL_GLOWS_CHANGED")

    -- library callbacks
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end

    -- secure methods
    self:SetAttributeNoHandler("SetShowGrid", [[
        local show, reason, force = ...
        local value = self:GetAttribute("showgrid") or 0
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
    -- when the player is attempting to drag and drop abilities.
    --
    -- Midnight hardens native action button attributes and cooldown values.
    -- Dominos detaches hidden stock buttons from Blizzard's shared dispatchers
    -- there, so avoid wrapping ActionButton1 and rely on the explicit
    -- ACTIONBAR_SHOWGRID/ACTIONBAR_HIDEGRID events registered above.
    if not Addon:IsAfterMidnight() then
        self:WrapScript(ActionButton1, "OnAttributeChanged", [[
            if name ~= "showgrid" then return end

            for reason = 2, 4, 2 do
                local show = value % (reason * 2) >= reason
                control:RunAttribute("SetShowGrid", show, reason)
            end
        ]])
    end

    -- overlay glow hiding
    if ActionButtonSpellAlertManager then
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(manager, button)
            if not self.buttons[button] or Addon:ShowingSpellGlows() then return end

            local hasAlert, alertType = manager:HasAlert(button)
            if hasAlert and alertType ~= manager.SpellAlertType.AssistedCombatRotation then
                manager:HideAlert(button)
            end
        end)
    elseif type(ActionButton_ShowOverlayGlow) == "function" then
        hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
            if not self.buttons[button] or Addon:ShowingSpellGlows() then return end

            local alert = button.SpellActivationAlert

            if alert:IsShown() then
                if alert.ProcStartAnim:IsPlaying() then
                    alert.ProcStartAnim:Stop()
                end

                alert:Hide()
            end
        end)
    end

    self.Initialize = nil
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:SetShowGrid(true, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:SetShowGrid(false, self.ShowGridReasons.GAME_EVENT)
end

function ActionButtons:PET_BAR_HIDEGRID()
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

-- reset grid state at login. This covers waiting for the game to apply the
-- always show buttons state to the main bar
function ActionButtons:PLAYER_LOGIN()
    if not Addon:IsAfterMidnight() then
        ActionButton1:SetAttribute("showgrid", 0)
    end

    self:LAYOUT_LOADED()
end

function ActionButtons:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    for sourceButton, targetButton in pairs(self.blizzardActionButtonBridge) do
        self:MirrorBlizzardActionButtonOverride(sourceButton, targetButton)
    end

    for button in pairs(self.pendingExternalOverrideUpdates) do
        if button.UpdateShown then
            button:UpdateShown()
        end

        if button.UpdateOverrideBindings then
            button:UpdateOverrideBindings()
        end

        self.pendingExternalOverrideUpdates[button] = nil
    end

    self:ForAll("UpdateShown")
    self:ForAll("UpdateOverrideBindings")
end

function ActionButtons:OnExternalOverrideChanged(buttonName)
    local button = _G[buttonName]
    if not button or not self.buttons[button] then
        return
    end

    if InCombatLockdown() then
        self:QueueExternalOverrideUpdate(button)
        return
    end

    button:UpdateShown()
    button:UpdateOverrideBindings()
end

-- force a visibility updates when spells changed (typically called when
-- switching talents)
function ActionButtons:SPELLS_CHANGED()
    self:ForAll("UpdateShown")
end

-- addon callbacks
function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(true, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(false, self.ShowGridReasons.KEYBOUND_EVENT)
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
    if name == "action" then
        local prevValue = ActionButtons[self]
        if prevValue ~= value then
            ActionButtons[self] = value

            DirtyButtons[self] = value
            control:SetAttribute("commit", 0)

            control:CallMethod("OnActionChanged", self:GetName(), value, prevValue)
        end
    elseif name == "type"
        or name == "type1"
        or name == "*type1"
        or name == "typerelease"
        or name == "clickbutton"
        or name == "clickbutton1"
        or name == "*clickbutton1"
        or name == "gse-button"
        or name == "gse-eff-action"
    then
        DirtyButtons[self] = true
        control:SetAttribute("commit", 0)
        control:CallMethod("OnExternalOverrideChanged", self:GetName(), name)
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


local MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTES = {
    "gse-button",
    "gse-eff-action",
    "type",
    "type1",
    "type2",
    "*type1",
    "*type2",
    "typerelease",
    "clickbutton",
    "clickbutton1",
    "clickbutton2",
    "*clickbutton1",
    "*clickbutton2",
    "macro",
    "macro1",
    "macro2",
    "*macro1",
    "*macro2",
    "macrotext",
    "macrotext1",
    "macrotext2",
    "*macrotext1",
    "*macrotext2",
    "spell",
    "spell1",
    "spell2",
    "*spell1",
    "*spell2",
    "item",
    "item1",
    "item2",
    "*item1",
    "*item2",
    "unit",
    "unit1",
    "unit2",
    "*unit1",
    "*unit2",
}

local MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTE_SET = {}
for _, attributeName in ipairs(MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTES) do
    MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTE_SET[attributeName] = true
end

local function IsMirroredExternalOverrideAttribute(attributeName)
    return MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTE_SET[attributeName] == true
end

local function IsExternalActionOverrideType(actionType)
    return actionType ~= nil and actionType ~= "action" and actionType ~= "actionrelease"
end

local function HasExternalActionOverrideAttributes(button)
    if not button or not button.GetAttribute then
        return nil
    end

    return button:GetAttribute("gse-button")
        or button:GetAttribute("clickbutton")
        or IsExternalActionOverrideType(button:GetAttribute("type"))
        or IsExternalActionOverrideType(button:GetAttribute("type1"))
        or IsExternalActionOverrideType(button:GetAttribute("*type1"))
end

local ACTION_BUTTON_CAST_TYPE_CAST = 1
local ACTION_BUTTON_CAST_TYPE_CHANNEL = 2
local ACTION_BUTTON_CAST_TYPE_EMPOWERED = 3

local function ClearCooldown(cooldown)
    if cooldown and cooldown.Clear then
        cooldown:Clear()
    end
end

local function ClearActionButtonCooldownsSafe(button)
    ClearCooldown(button and button.cooldown)
    ClearCooldown(button and button.chargeCooldown)
    ClearCooldown(button and button.lossOfControlCooldown)
end

local function SetCooldownFromDurationObject(cooldown, duration)
    if not cooldown then
        return
    end

    if duration and cooldown.SetCooldownFromDurationObject then
        cooldown:SetCooldownFromDurationObject(duration, true)
    else
        cooldown:Clear()
    end
end

local function GetActionCooldownDuration(action, ignoreGCD)
    if C_ActionBar and C_ActionBar.GetActionCooldownDuration then
        return C_ActionBar.GetActionCooldownDuration(action, ignoreGCD and true or false)
    end
end

local function GetActionChargeDuration(action)
    if C_ActionBar and C_ActionBar.GetActionChargeDuration then
        return C_ActionBar.GetActionChargeDuration(action)
    end
end

local function GetActionLossOfControlCooldownDuration(action)
    if C_ActionBar and C_ActionBar.GetActionLossOfControlCooldownDuration then
        return C_ActionBar.GetActionLossOfControlCooldownDuration(action)
    end
end

local function HasActionSafe(action)
    if action and C_ActionBar and C_ActionBar.HasAction then
        return C_ActionBar.HasAction(action)
    end

    return action and HasAction(action)
end

local function GetActionTextureForUpdate(action)
    if C_ActionBar and C_ActionBar.GetActionTexture then
        return C_ActionBar.GetActionTexture(action)
    end

    return GetActionTexture(action)
end

local function DominosActionButton_UpdateCount(button)
    local updateCount = button and button.dominosNativeUpdateCount
    if type(updateCount) ~= "function" then
        return
    end

    local ok = pcall(updateCount, button)
    if not ok and button.Count then
        button.Count:SetText("")
    end
end

local function DominosActionButton_UpdateCooldown(button)
    local action = button and (button.action or button:GetAttribute("action"))
    if not action or not HasActionSafe(action) then
        ClearActionButtonCooldownsSafe(button)
        return
    end

    -- Midnight cooldown APIs can return secret start/duration values.  The safe
    -- public replacement path is to pass Blizzard's duration object directly to
    -- the cooldown frame instead of reading start/duration and calling SetCooldown.
    SetCooldownFromDurationObject(button.cooldown, GetActionCooldownDuration(action, false))
    SetCooldownFromDurationObject(button.chargeCooldown, GetActionChargeDuration(action))

    if button.enableLOCCooldown then
        SetCooldownFromDurationObject(button.lossOfControlCooldown, GetActionLossOfControlCooldownDuration(action))
    else
        ClearCooldown(button.lossOfControlCooldown)
    end
end

local function InstallMidnightPressAndHoldUpdater(button)
    if not button or button.dominosMidnightPressAndHoldUpdaterInstalled then
        return
    end

    if type(button.SetAttributeNoHandler) ~= "function" then
        return
    end

    button:SetAttributeNoHandler("UpdatePressAndHoldAction", [[
        local pressAndHoldAction = false
        local action

        if self.CalculateAction then
            action = self:CalculateAction()
        end

        if not action then
            action = self:GetAttribute("action")
        end

        if action and action ~= 0 then
            local actionType, id = GetActionInfo(action)
            if actionType == "spell" and id then
                pressAndHoldAction = IsPressHoldReleaseSpell(id)
            end
        end

        if self:GetAttribute("pressAndHoldAction") ~= pressAndHoldAction then
            self:SetAttribute("pressAndHoldAction", pressAndHoldAction)
        end
    ]])

    button.dominosMidnightPressAndHoldUpdaterInstalled = true
end

local function DominosActionButton_UpdatePressAndHoldAction(button)
    if button and button.RunAttribute and button:GetAttribute("UpdatePressAndHoldAction") then
        button:RunAttribute("UpdatePressAndHoldAction")
    end
end

local function DominosActionButton_Update(button)
    local action = button.action or button:GetAttribute("action")
    local icon = button.icon
    local texture = GetActionTextureForUpdate(action)

    if icon then
        icon:SetDesaturated(false)
    end

    if HasActionSafe(action) then
        if not button.eventsRegistered and ActionBarActionEventsFrame then
            ActionBarActionEventsFrame:RegisterFrame(button)
            button.eventsRegistered = true
        end

        if button.UpdateState then button:UpdateState() end
        if button.UpdateUsable then button:UpdateUsable() end
        if button.UpdateProfessionQuality then button:UpdateProfessionQuality() end
        if button.UpdateTypeOverlay then button:UpdateTypeOverlay() end
        DominosActionButton_UpdateCooldown(button)
        if button.UpdateFlash then button:UpdateFlash() end
        if button.UpdateHighlightMark then button:UpdateHighlightMark() end
        if button.UpdateSpellHighlightMark then button:UpdateSpellHighlightMark() end
    else
        if button.eventsRegistered and ActionBarActionEventsFrame then
            ActionBarActionEventsFrame:UnregisterFrame(button)
            button.eventsRegistered = nil
        end

        ClearActionButtonCooldownsSafe(button)
        if button.ClearFlash then button:ClearFlash() end
        button:SetChecked(false)
        if button.ClearProfessionQuality then button:ClearProfessionQuality() end
        if button.ClearTypeOverlay then button:ClearTypeOverlay() end

        if button.LevelLinkLockIcon then
            button.LevelLinkLockIcon:SetShown(false)
        end
    end

    DominosActionButton_UpdatePressAndHoldAction(button)

    local border = button.Border
    if border then
        if action and C_ActionBar and C_ActionBar.IsEquippedAction and C_ActionBar.IsEquippedAction(action) then
            border:SetVertexColor(0, 1.0, 0, 0.5)
            border:Show()
        else
            border:Hide()
        end
    end

    local actionName = button.Name
    if actionName then
        if action and C_ActionBar and C_ActionBar.UsesActionText and C_ActionBar.UsesActionText(action) then
            actionName:SetText(C_ActionBar.GetActionText(action))
        else
            actionName:SetText("")
        end
    end

    if texture and icon then
        icon:SetTexture(texture)
        icon:Show()
        if button.UpdateCount then button:UpdateCount() end
    else
        if button.Count then button.Count:SetText("") end
        if icon then icon:Hide() end
        ClearActionButtonCooldownsSafe(button)

        local hotkey = button.HotKey
        if hotkey then
            if hotkey:GetText() == RANGE_INDICATOR then
                hotkey:Hide()
            elseif ACTIONBAR_HOTKEY_FONT_COLOR then
                hotkey:SetVertexColor(ACTIONBAR_HOTKEY_FONT_COLOR:GetRGB())
            end
        end
    end

    if button.UpdateFlyout then button:UpdateFlyout() end
    if button.UpdateSpellAlert then button:UpdateSpellAlert() end

    if GameTooltip:GetOwner() == button and button.SetTooltip then
        button:SetTooltip()
    end

    button.feedback_action = action
end

local function DominosActionButton_OnEvent(button, event, ...)
    local arg1 = ...

    if ((event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "LEARNED_SPELL_IN_SKILL_LINE") then
        if GameTooltip:GetOwner() == button and button.SetTooltip then
            button:SetTooltip()
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        if arg1 == 0 or arg1 == tonumber(button.action) then
            ClearNewActionHighlight(button.action, true)
            button:UpdateAction(true)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        button:Update()
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        local texture = GetActionTextureForUpdate(button.action)
        if texture then
            button.icon:SetTexture(texture)
        end
    elseif event == "UPDATE_BINDINGS" or event == "GAME_PAD_ACTIVE_CHANGED" then
        button:UpdateHotkeys(button.buttonType)
    elseif event == "UNIT_FLAGS" or event == "UNIT_AURA" or event == "PET_BAR_UPDATE" then
        button.flashDirty = true
        button.stateDirty = true
        button:CheckNeedsUpdate()
    elseif event == "ACTIONBAR_UPDATE_STATE"
        or ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and arg1 == "player")
        or (event == "COMPANION_UPDATE" and arg1 == "MOUNT")
    then
        button:UpdateState()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        button:UpdateUsable()
    elseif event == "LOSS_OF_CONTROL_UPDATE" then
        DominosActionButton_UpdateCooldown(button)
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "LOSS_OF_CONTROL_ADDED" then
        DominosActionButton_UpdateCooldown(button)
        if GameTooltip:GetOwner() == button and button.SetTooltip then
            button:SetTooltip()
        end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" or event == "ARCHAEOLOGY_CLOSED" then
        button:UpdateState()
    elseif event == "PLAYER_ENTER_COMBAT" then
        if C_ActionBar and C_ActionBar.IsAttackAction and C_ActionBar.IsAttackAction(button.action) then
            button:StartFlash()
        end
    elseif event == "PLAYER_LEAVE_COMBAT" then
        if C_ActionBar and C_ActionBar.IsAttackAction and C_ActionBar.IsAttackAction(button.action) then
            button:StopFlash()
        end
    elseif event == "START_AUTOREPEAT_SPELL" then
        if C_ActionBar and C_ActionBar.IsAutoRepeatAction and C_ActionBar.IsAutoRepeatAction(button.action) then
            button:StartFlash()
        end
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        if button:IsFlashing() and not (C_ActionBar and C_ActionBar.IsAttackAction and C_ActionBar.IsAttackAction(button.action)) then
            button:StopFlash()
        end
    elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
        button:Update()
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local actionType, id, subType = GetActionInfo(button.action)
        if actionType == "spell" and id == arg1 then
            ActionButtonSpellAlertManager:ShowAlert(button)
        elseif actionType == "macro" and subType == "spell" and id == arg1 then
            ActionButtonSpellAlertManager:ShowAlert(button)
        elseif actionType == "flyout" and FlyoutHasSpell(id, arg1) then
            ActionButtonSpellAlertManager:ShowAlert(button)
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local actionType, id, subType = GetActionInfo(button.action)
        if actionType == "spell" and id == arg1 then
            ActionButtonSpellAlertManager:HideAlert(button)
        elseif actionType == "macro" and subType == "spell" and id == arg1 then
            ActionButtonSpellAlertManager:HideAlert(button)
        elseif actionType == "flyout" and FlyoutHasSpell(id, arg1) then
            ActionButtonSpellAlertManager:HideAlert(button)
        end
    elseif event == "SPELL_UPDATE_CHARGES" then
        button:UpdateCount()
    elseif event == "UPDATE_SUMMONPETS_ACTION" then
        local actionType = GetActionInfo(button.action)
        if actionType == "summonpet" then
            local texture = GetActionTextureForUpdate(button.action)
            if texture then
                button.icon:SetTexture(texture)
            end
        end
    elseif event == "SPELL_UPDATE_ICON" then
        button:Update()
    elseif event == "ACTION_RANGE_CHECK_UPDATE" then
        local inRange, checksRange = select(2, ...)
        ActionButton_UpdateRangeIndicator(button, checksRange, inRange)
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        button:PlaySpellInterruptedAnim()
    elseif event == "UNIT_SPELLCAST_START" then
        button:PlaySpellCastAnim(ACTION_BUTTON_CAST_TYPE_CAST)
    elseif event == "UNIT_SPELLCAST_STOP" then
        button:StopSpellCastAnim(true, ACTION_BUTTON_CAST_TYPE_CAST)
        button:StopTargettingReticleAnim()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        button:StopSpellCastAnim(false, ACTION_BUTTON_CAST_TYPE_CAST)
        button:StopTargettingReticleAnim()
    elseif event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_FAILED" then
        button:StopTargettingReticleAnim()
    elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
        button:PlaySpellCastAnim(ACTION_BUTTON_CAST_TYPE_EMPOWERED)
    elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        local _, _, _, castComplete = ...
        local interrupted = not castComplete
        if interrupted then
            button:PlaySpellInterruptedAnim()
        else
            button:StopSpellCastAnim(interrupted, ACTION_BUTTON_CAST_TYPE_EMPOWERED)
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        button:PlaySpellCastAnim(ACTION_BUTTON_CAST_TYPE_CHANNEL)
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        button:StopSpellCastAnim(false, ACTION_BUTTON_CAST_TYPE_CHANNEL)
    elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
        button:PlayTargettingReticleAnim()
    elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
        button:StopTargettingReticleAnim()
    elseif event == "AssistedCombatManager.OnSetActionSpell" then
        button:UpdateAssistedCombatRotationFrame()
    end
end

local function ApplyMidnightActionButtonSafety(button)
    -- Midnight restricts passing action cooldown start/duration secrets through
    -- tainted Lua. Dominos buttons are addon-owned ActionButtonTemplate frames, so
    -- using Blizzard's shared OnEvent/Update path now pushes protected cooldown and
    -- press-and-hold mutations through a tainted stack. Keep the Blizzard frame
    -- contract, but replace only the unsafe dispatch methods with duration-object
    -- based equivalents.
    if not Addon:IsAfterMidnight() then
        return
    end

    InstallMidnightPressAndHoldUpdater(button)

    if button.dominosMidnightActionButtonSafetyApplied then
        return
    end

    button.dominosNativeOnEvent = button.OnEvent
    button.dominosNativeUpdate = button.Update
    button.dominosNativeUpdatePressAndHoldAction = button.UpdatePressAndHoldAction
    button.dominosNativeUpdateCount = button.UpdateCount

    button.OnEvent = DominosActionButton_OnEvent
    button.Update = DominosActionButton_Update
    button.UpdateCount = DominosActionButton_UpdateCount
    button.UpdatePressAndHoldAction = DominosActionButton_UpdatePressAndHoldAction
    button.dominosMidnightActionButtonSafetyApplied = true
end

local function SetAttributeIfChanged(button, attributeName, value)
    if button:GetAttribute(attributeName) ~= value then
        button:SetAttribute(attributeName, value)
    end
end

local function GetButtonIcon(button)
    if not button then
        return nil
    end

    return button.icon or button.Icon or (button.GetName and _G[button:GetName() .. "Icon"])
end

local function CopyButtonIcon(sourceButton, targetButton)
    local sourceIcon = GetButtonIcon(sourceButton)
    local targetIcon = GetButtonIcon(targetButton)
    if not sourceIcon or not targetIcon or not sourceIcon.GetTexture then
        return
    end

    local texture = sourceIcon:GetTexture()
    if texture then
        targetIcon:SetTexture(texture)
        targetIcon:Show()
    end
end

local function ScheduleButtonIconCopy(sourceButton, targetButton)
    CopyButtonIcon(sourceButton, targetButton)

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if targetButton and targetButton.GetAttribute and targetButton:GetAttribute("gse-button") then
                CopyButtonIcon(sourceButton, targetButton)
            end
        end)
    end
end

local function RestoreNativeActionAttributes(button)
    SetAttributeIfChanged(button, "type", "action")
    SetAttributeIfChanged(button, "typerelease", "actionrelease")

    for _, attributeName in ipairs(MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTES) do
        if attributeName ~= "type" and attributeName ~= "typerelease" then
            SetAttributeIfChanged(button, attributeName, nil)
        end
    end
end

function ActionButtons:QueueExternalOverrideUpdate(button)
    if not button then
        return
    end

    self.pendingExternalOverrideUpdates[button] = true
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function ActionButtons:MirrorBlizzardActionButtonOverride(sourceButton, targetButton)
    if not sourceButton or not targetButton or sourceButton == targetButton then
        return
    end

    if InCombatLockdown() then
        self:QueueExternalOverrideUpdate(targetButton)
        return
    end

    if HasExternalActionOverrideAttributes(sourceButton) then
        targetButton.dominosExternalOverrideBridgeSource = sourceButton

        for _, attributeName in ipairs(MIRRORED_EXTERNAL_OVERRIDE_ATTRIBUTES) do
            SetAttributeIfChanged(targetButton, attributeName, sourceButton:GetAttribute(attributeName))
        end

        if sourceButton:GetAttribute("clickbutton") and not targetButton:GetAttribute("type") then
            SetAttributeIfChanged(targetButton, "type", "click")
        end

        ScheduleButtonIconCopy(sourceButton, targetButton)
    elseif targetButton.dominosExternalOverrideBridgeSource == sourceButton then
        targetButton.dominosExternalOverrideBridgeSource = nil
        RestoreNativeActionAttributes(targetButton)
    end

    if targetButton.UpdateShown then
        targetButton:UpdateShown()
    end

    if targetButton.UpdateOverrideBindings then
        targetButton:UpdateOverrideBindings()
    end
end

local function BlizzardActionButton_OnAttributeChanged(sourceButton, attributeName)
    if not IsMirroredExternalOverrideAttribute(attributeName) then
        return
    end

    local targetButton = ActionButtons.blizzardActionButtonBridge[sourceButton]
    if targetButton then
        ActionButtons:MirrorBlizzardActionButtonOverride(sourceButton, targetButton)
    end
end

local function SuppressHiddenBlizzardActionButtonSource(sourceButton)
    if not Addon:IsAfterMidnight() or not sourceButton or sourceButton.dominosBlizzardBridgeSourceSuppressed then
        return
    end

    -- These source buttons are kept only as Blizzard-compatible external contract
    -- anchors. They must not continue running Blizzard's native action update path
    -- while Dominos owns the visible action button, because that path can call
    -- protected SetAttribute/SetCooldown with Midnight secret values from a
    -- Dominos-tainted stack.
    sourceButton.dominosNativeOnEvent = sourceButton.OnEvent
    sourceButton.dominosNativeOnUpdate = sourceButton.OnUpdate
    sourceButton.dominosNativeUpdate = sourceButton.Update
    sourceButton.dominosNativeUpdateAction = sourceButton.UpdateAction
    sourceButton.dominosNativeUpdatePressAndHoldAction = sourceButton.UpdatePressAndHoldAction
    sourceButton.dominosNativeCheckNeedsUpdate = sourceButton.CheckNeedsUpdate
    sourceButton.dominosNativeActionButtonOnClick = sourceButton.ActionBarActionButtonDerivedMixin_OnClick

    sourceButton.OnEvent = noop
    sourceButton.OnUpdate = noop
    sourceButton.Update = noop
    sourceButton.UpdateAction = noop
    sourceButton.UpdatePressAndHoldAction = noop
    sourceButton.CheckNeedsUpdate = noop
    sourceButton.ActionBarActionButtonDerivedMixin_OnClick = noop
    sourceButton.eventsRegistered = nil
    sourceButton.needsUpdate = nil
    sourceButton.dominosBlizzardBridgeSourceSuppressed = true
end

local function GetBlizzardActionButtonName(id)
    if id >= 1 and id <= 12 then
        return ("ActionButton%d"):format(id)
    elseif id >= 25 and id <= 36 then
        return ("MultiBarRightButton%d"):format(id - 24)
    elseif id >= 37 and id <= 48 then
        return ("MultiBarLeftButton%d"):format(id - 36)
    elseif id >= 49 and id <= 60 then
        return ("MultiBarBottomRightButton%d"):format(id - 48)
    elseif id >= 61 and id <= 72 then
        return ("MultiBarBottomLeftButton%d"):format(id - 60)
    elseif id >= 133 and id <= 144 then
        return ("MultiBar5Button%d"):format(id - 132)
    elseif id >= 145 and id <= 156 then
        return ("MultiBar6Button%d"):format(id - 144)
    elseif id >= 157 and id <= 168 then
        return ("MultiBar7Button%d"):format(id - 156)
    end
end

function ActionButtons:ApplyMidnightActionButtonSafety(button)
    ApplyMidnightActionButtonSafety(button)
end

function ActionButtons:RegisterBlizzardActionButtonBridge(button, id)
    local sourceName = GetBlizzardActionButtonName(id)
    if not sourceName then
        return
    end

    local sourceButton = _G[sourceName]
    if not sourceButton or sourceButton == button then
        return
    end

    SuppressHiddenBlizzardActionButtonSource(sourceButton)

    self.blizzardActionButtonBridge[sourceButton] = button
    button.dominosBlizzardActionButtonBridgeSource = sourceButton
    button.blizzardActionButtonName = sourceButton:GetName()

    if not self.blizzardActionButtonBridgeHooked[sourceButton] then
        sourceButton:HookScript("OnAttributeChanged", BlizzardActionButton_OnAttributeChanged)
        self.blizzardActionButtonBridgeHooked[sourceButton] = true
    end

    self:MirrorBlizzardActionButtonOverride(sourceButton, button)
end

local function GetActionButtonName(id)
    if id <= 0 then
        return
    -- 1, 2
    elseif id <= 24 then
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    -- 3
    elseif id <= 36 then
        return ("MultiBarRightActionButton%d"):format(id - 24)
    -- 4
    elseif id <= 48 then
        return ("MultiBarLeftActionButton%d"):format(id - 36)
    -- 5
    elseif id <= 60 then
        return ("MultiBarBottomRightActionButton%d"):format(id - 48)
    -- 6
    elseif id <= 72 then
        return ("MultiBarBottomLeftActionButton%d"):format(id - 60)
    -- 7-11
    elseif id <= 132 then
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    -- 12
    elseif id <= 144 then
        return ("MultiBar5ActionButton%d"):format(id - 132)
    -- 13
    elseif id <= 156 then
        return ("MultiBar6ActionButton%d"):format(id - 144)
    -- 14
    elseif id <= 168 then
        return ("MultiBar7ActionButton%d"):format(id - 156)
    end
end

local function SafeMixin(button, trait)
    for k, v in pairs(trait) do
        if rawget(button, k) ~= nil then
            error(("%s[%q] has alrady been set"):format(button:GetName(), k), 2)
        end

        button[k] = v
    end
end

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = GetActionButtonName(id)
    if name == nil then
        error(("Invalid Action ID %q"):format(id))
    end

    local button = _G[name]
    local created = false

    -- button not found, create a new one
    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")

        -- add custom methods
        SafeMixin(button, Addon.ActionButton)

        -- initialize the button
        button:OnCreate(id)
        created = true
    -- button found, but not yet registered, reuse
    elseif self.buttons[button] == nil then
        -- add custom methods
        SafeMixin(button, Addon.ActionButton)

        -- reset the id of a button to zero to avoid triggering the paging
        -- logic of the standard UI
        button:SetParent(parent)
        button:SetID(0)

        -- drop the reference to the bar's original parent, which would otherwise
        -- call thing we do not want
        button.Bar = nil

        -- initialize the button
        button:OnCreate(id)
        created = true
    end

    if created then
        ApplyMidnightActionButtonSafety(button)
        self:AddOverrideActionProxy(button)

        -- add secure handlers
        self:WrapScript(button, "OnAttributeChanged", ActionButton_AttributeChanged)
        self:WrapScript(button, "PostClick", ActionButton_PostClick)
        self:WrapScript(button, "OnReceiveDrag", ActionButton_ReceiveDragBefore, ActionButton_ReceiveDragAfter)
        self:WrapScript(button, "OnShow", ActionButton_OnShowHide)
        self:WrapScript(button, "OnHide", ActionButton_OnShowHide)

        self:AddCastOnKeyPressSupport(button)

        -- register the button with the controller
        self:SetFrameRef("add", button)

        self:Execute([[
            local b = self:GetFrameRef("add")
            ActionButtons[b] = b:GetAttribute("action") or 0
        ]])

        self.buttons[button] = 0
    end

    self:RegisterBlizzardActionButtonBridge(button, id)

    return button
end

local function GetOverrideActionProxyName(button)
    local name = button and button:GetName()
    if name then
        return name .. "OverrideActionProxy"
    end
end

function ActionButtons:AddOverrideActionProxy(button)
    if button.dominosOverrideActionProxy then
        return button.dominosOverrideActionProxy
    end

    local proxyName = GetOverrideActionProxyName(button)
    if not proxyName then
        return nil
    end

    -- This transparent child is only shown while Dominos' configured
    -- override/vehicle/possess bar is active.  It executes the current action
    -- slot through Blizzard's native SecureActionButtonTemplate while the
    -- visible Dominos button keeps any GSE/clickbutton attributes untouched.
    local proxy = CreateFrame("Button", proxyName, button, "SecureActionButtonTemplate")
    proxy:SetAllPoints(button)
    proxy:SetFrameLevel(button:GetFrameLevel() + 10)
    proxy:EnableMouse(true)
    proxy:RegisterForClicks("AnyUp", "LeftButtonDown", "RightButtonDown")

    proxy:SetAttributeNoHandler("type", "action")
    proxy:SetAttributeNoHandler("typerelease", "actionrelease")
    proxy:SetAttributeNoHandler("useparent-action", true)
    proxy:SetAttributeNoHandler("useparent-checkfocuscast", true)
    proxy:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    proxy:SetAttributeNoHandler("useparent-checkselfcast", true)
    proxy:SetAttributeNoHandler("useparent-flyoutDirection", true)
    proxy:SetAttributeNoHandler("useparent-pressAndHoldAction", true)
    proxy:SetAttributeNoHandler("useparent-unit", true)
    proxy:Hide()

    SecureHandlerSetFrameRef(button, "dominos-override-action-proxy", proxy)
    button.dominosOverrideActionProxy = proxy

    if Addon.SpellFlyout then
        Addon.SpellFlyout:Register(proxy)
    end

    return proxy
end

-- update the pushed state of our parent button when pressing and releasing
-- the button's hotkey. The hidden secure proxy owns override bindings for normal
-- slot execution. When an external addon replaces the visible button contract
-- with a clickbutton/macro/spell override, bindings are retargeted to the visible
-- button so the external secure override receives the same click as the mouse.
local function bindButton_PreClick(self, _, down)
    local owner = self:GetParent()
    if not owner then
        return
    end

    if down then
        if owner:GetButtonState() == "NORMAL" then
            owner:SetButtonState("PUSHED")
        end
    elseif owner:GetButtonState() == "PUSHED" then
        owner:SetButtonState("NORMAL")
    end
end

local function bindButton_SetOverrideBindings(self, useVisibleButton, ...)
    ClearOverrideBindings(self)

    local owner = self:GetParent()
    local targetName = useVisibleButton and owner and owner:GetName() or self:GetName()
    local targetButton = useVisibleButton and "LeftButton" or "HOTKEY"
    if not targetName then
        return
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if key then
            SetOverrideBindingClick(self, false, key, targetName, targetButton)
        end
    end
end

-- Cast-on-keypress support is implemented by using a second hidden button that
-- mirrors the secure action attributes of its parent. Native Blizzard binding
-- keys are captured with override bindings and redirected here for normal action
-- slots so addon-created Dominos buttons are not executed through Blizzard's
-- restricted ACTIONBUTTON binding snippets.
function ActionButtons:AddCastOnKeyPressSupport(button)
    local bind = CreateFrame("Button", "$parentHotkey", button, "SecureActionButtonTemplate")

    bind:SetAttributeNoHandler("type", "action")
    bind:SetAttributeNoHandler("typerelease", "actionrelease")
    bind:SetAttributeNoHandler("useparent-action", true)
    bind:SetAttributeNoHandler("useparent-checkfocuscast", true)
    bind:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    bind:SetAttributeNoHandler("useparent-checkselfcast", true)
    bind:SetAttributeNoHandler("useparent-flyoutDirection", true)
    bind:SetAttributeNoHandler("useparent-pressAndHoldAction", true)
    bind:SetAttributeNoHandler("useparent-unit", true)
    SecureHandlerSetFrameRef(bind, "owner", button)

    bind:EnableMouseWheel()
    bind:RegisterForClicks("AnyUp", "AnyDown")
    bind:SetScript("PreClick", bindButton_PreClick)
    bind.SetOverrideBindings = bindButton_SetOverrideBindings

    if Addon.SpellFlyout then
        Addon.SpellFlyout:Register(bind)
    end

    -- Translate HOTKEY button clicks into LeftButton. This matches the old
    -- Dominos fallback path while preserving flyout safety on Midnight builds.
    if Addon:IsAfterMidnight() then
        self:WrapScript(bind, "OnClick", [[
            if button == "HOTKEY" then
                if GetActionInfo(self:GetEffectiveAttribute("action")) == "flyout" then
                    return false
                end

                return "LeftButton"
            end
        ]])
    else
        self:WrapScript(bind, "OnClick", [[
            if button == "HOTKEY" then
                return "LeftButton"
            end
        ]])
    end

    button.bind = bind
    button:UpdateOverrideBindings()
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

function ActionButtons:SetShowGrid(show, reason, force)
    self:ForAll("SetShowGridInsecure", show, reason, force)
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
ActionButtons:Initialize()

Addon.ActionButtons = ActionButtons
