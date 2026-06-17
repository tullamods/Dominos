local _, Addon = ...
local ActionButton = {}

local function GetBindingCompat()
    return Addon.BindingCompat
end

local function GetActionTextureSafe(action)
    if C_ActionBar and C_ActionBar.GetActionTexture then
        return C_ActionBar.GetActionTexture(action)
    end

    return GetActionTexture(action)
end

local function GetActionButtonCommand(button)
    local bindingCompat = GetBindingCompat()
    if bindingCompat then
        local command = bindingCompat.NormalizeCommandName(button:GetAttribute("commandName"))
        if command then
            return command
        end

        return bindingCompat.GetActionButtonCommand(button:GetAttribute("bindingID"), button)
    end

    local name = button:GetName()
    if name then
        return ("CLICK %s:HOTKEY"):format(name)
    end
end

local function ApplyActionButtonContract(button, id)
    local bindingCompat = GetBindingCompat()
    if bindingCompat and bindingCompat.ApplyActionButtonContract then
        bindingCompat.ApplyActionButtonContract(button, id)
        return
    end

    local name = button:GetName()
    local command = name and ("CLICK %s:HOTKEY"):format(name) or nil
    button.commandName = command
    button.bindingAction = command
    button.bindingID = id
    button.dominosButtonID = id

    button:SetAttributeNoHandler("commandName", command)
    button:SetAttributeNoHandler("bindingID", id)
    button:SetAttributeNoHandler("dominosButtonID", id)
end

local function SetRegionParent(region, parent)
    if region and region:GetParent() ~= parent then
        region:SetParent(parent)
    end
end

local function IsSecureTruthy(value)
    return value == true or value == 1 or value == "1"
end

local function IsOverrideActionBarActive(button)
    return button and IsSecureTruthy(button:GetAttribute("dominos-override-action-active"))
end

local function IsExternalActionOverrideType(actionType)
    return actionType ~= nil and actionType ~= "action" and actionType ~= "actionrelease"
end

local function HasExternalActionOverride(button)
    if not button then
        return nil
    end

    -- While the configured Dominos override/vehicle/possess bar is active,
    -- external clickbutton/GSE attributes on the normal button must not make
    -- the swapped action look occupied.  Actual clicks are handled by a
    -- separate override-only secure proxy, so the normal button can keep its
    -- external attributes untouched for instant restoration afterward.
    if IsOverrideActionBarActive(button) then
        return nil
    end

    if button:GetAttribute("gse-button") then
        return true
    end

    if button:GetAttribute("clickbutton") then
        return true
    end

    if IsExternalActionOverrideType(button:GetAttribute("type")) then
        return true
    end

    if IsExternalActionOverrideType(button:GetAttribute("type1")) then
        return true
    end

    if IsExternalActionOverrideType(button:GetAttribute("*type1")) then
        return true
    end

    if type(SecureButton_GetModifiedAttribute) == "function" then
        return IsExternalActionOverrideType(SecureButton_GetModifiedAttribute(button, "type", "LeftButton"))
    end
end

function ActionButton:OnCreate(id)
    -- Preserve a Blizzard-compatible public identity before the button is used
    -- by binding, tooltip, hotkey, or external hook code.  This identity is the
    -- stable Dominos/native button id, not the current paged action slot.
    ApplyActionButtonContract(self, id)

    -- initialize secure state.  Match Blizzard's ActionBarActionButtonMixin
    -- public secure-action contract while keeping Dominos execution slot-driven
    -- through the explicit secure "action" attribute.
    self:SetAttributeNoHandler("type", "action")
    self:SetAttributeNoHandler("typerelease", "actionrelease")
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("statehidden", nil)
    self:SetAttributeNoHandler("dominos-override-action-active", nil)
    self:SetAttributeNoHandler("checkfocuscast", true)
    self:SetAttributeNoHandler("checkmouseovercast", true)
    self:SetAttributeNoHandler("checkselfcast", true)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-checkselfcast", true)
    self:SetAttributeNoHandler("useparent-unit", true)

    -- Midnight press-and-hold handling is installed by ActionButtons so the same
    -- hardened path can be reused by native extra-action buttons.

    -- register for clicks exactly like Blizzard action buttons: mouse-up for
    -- normal actions, plus down-click support for ActionButtonUseKeyDown paths.
    self:EnableMouseWheel()
    self:RegisterForDrag("LeftButton", "RightButton")
    self:RegisterForClicks("AnyUp", "LeftButtonDown", "RightButtonDown")

    -- secure handlers
    self:SetAttributeNoHandler('_childupdate-offset', [[
        local encodedOffset = tonumber(message) or 0
        local active

        if encodedOffset >= 100000 then
            encodedOffset = encodedOffset - 100000
            active = 1
        end

        local id = self:GetAttribute('index') + encodedOffset

        if self:GetAttribute('action') ~= id then
            self:SetAttribute('action', id)
        end

        if self:GetAttribute("dominos-override-action-active") ~= active then
            self:SetAttribute("dominos-override-action-active", active)
        end

        local proxy = self:GetFrameRef("dominos-override-action-proxy")
        if proxy then
            if active then
                proxy:Show(true)
            else
                proxy:Hide(true)
            end
        end
    ]])

    self:SetAttributeNoHandler('_childupdate-overrideactive', [[
        local active
        if message == true or message == 1 or message == "1" then
            active = 1
        end

        if self:GetAttribute("dominos-override-action-active") ~= active then
            self:SetAttribute("dominos-override-action-active", active)
        end

        local proxy = self:GetFrameRef("dominos-override-action-proxy")
        if proxy then
            if active then
                proxy:Show(true)
            else
                proxy:Hide(true)
            end
        end

        self:RunAttribute("UpdateShown")
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

            local buttonType = self:GetAttribute("type")
            local type1 = self:GetAttribute("type1") or self:GetAttribute("*type1")
            local hasExternalActionOverride = self:GetAttribute("gse-button")
                or self:GetAttribute("clickbutton")
                or (buttonType and buttonType ~= "action" and buttonType ~= "actionrelease")
                or (type1 and type1 ~= "action" and type1 ~= "actionrelease")

            if self:GetAttribute("dominos-override-action-active") then
                hasExternalActionOverride = nil
            end

            local show = (value > 0
                    or HasAction(self:GetAttribute("action"))
                    or hasExternalActionOverride)
                and not self:GetAttribute("statehidden")

            if show then
                self:Show(true)
            else
                self:Hide(true)
            end
        end
    ]])

    self:SetAttributeNoHandler("UpdateShown", [[
        local buttonType = self:GetAttribute("type")
        local type1 = self:GetAttribute("type1") or self:GetAttribute("*type1")
        local hasExternalActionOverride = self:GetAttribute("gse-button")
            or self:GetAttribute("clickbutton")
            or (buttonType and buttonType ~= "action" and buttonType ~= "actionrelease")
            or (type1 and type1 ~= "action" and type1 ~= "actionrelease")

        if self:GetAttribute("dominos-override-action-active") then
            hasExternalActionOverride = nil
        end

        local show = (self:GetAttribute("showgrid") > 0
                or HasAction(self:GetAttribute("action"))
                or hasExternalActionOverride)
            and not self:GetAttribute("statehidden")

        if show then
            self:Show(true)
        else
            self:Hide(true)
        end
    ]])

    -- ...and the rest
    Addon.BindableButton:AddQuickBindingSupport(self)

    if Addon.SpellFlyout then
        Addon.SpellFlyout:Register(self)
    end
end

function ActionButton:UpdateIcon()
    local icon = GetActionTextureSafe(self.action)
    if icon then
        self.icon:SetTexture(icon)
        self.icon:Show()
    elseif not HasExternalActionOverride(self) then
        self.icon:Hide()
    end
end

function ActionButton:UpdateOverrideBindings()
    if InCombatLockdown() then return end
    if not self.bind then return end

    if C_HouseEditor and C_HouseEditor.IsHouseEditorActive() then
        ClearOverrideBindings(self.bind)
        return
    end

    local bindingCompat = GetBindingCompat()
    if bindingCompat and bindingCompat.GetActionButtonBindingKeys then
        local keys = bindingCompat.GetActionButtonBindingKeys(self:GetAttribute("bindingID"), self)
        self.bind:SetOverrideBindings(HasExternalActionOverride(self), unpack(keys))
        return
    end

    local command = GetActionButtonCommand(self)
    local keys = command and { GetBindingKey(command) } or {}
    self.bind:SetOverrideBindings(HasExternalActionOverride(self), unpack(keys))
end

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    self:SetShown(
        (self:GetAttribute("showgrid") > 0
            or HasAction(self:GetAttribute("action"))
            or HasExternalActionOverride(self))
        and not self:GetAttribute("statehidden")
    )
end

--------------------------------------------------------------------------------
-- configuration
--------------------------------------------------------------------------------

function ActionButton:SetFlyoutDirectionInsecure(direction)
    if InCombatLockdown() then return end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

-- the stock UI shows and hides hotkeys based on if there's a binding or not
-- so we simply make our hotkeys transparent when we don't want them shown
function ActionButton:SetShowBindingText(show)
    local parent = (show and self) or Addon.ShadowUIParent
    SetRegionParent(self.HotKey, parent)
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButton:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)

            if not Addon:IsAfterMidnight() then
                ActionButton_UpdateCooldown(self)
            end
        end
    else
        self.cooldown:SetParent(Addon.ShadowUIParent)
    end
end

function ActionButton:SetShowCounts(show)
    self.Count:SetShown(show)
end

function ActionButton:SetShowEquippedItemBorders(show)
    local parent = (show and self) or Addon.ShadowUIParent
    SetRegionParent(self.Border, parent)
end

function ActionButton:SetShowEmptyButtons(show, force)
    self:SetShowGridInsecure(show, Addon.ActionButtons.ShowGridReasons.SHOW_EMPTY_BUTTONS_PER_BAR, force)
end

function ActionButton:SetShowGridInsecure(show, reason, force)
    if InCombatLockdown() then return end

    if type(reason) ~= "number" then
        error("Usage: ActionButton:SetShowGridInsecure(show, reason, force?)", 2)
    end

    local value = self:GetAttribute("showgrid") or 0
    local prevValue = value

    if show then
        value = bit.bor(value, reason)
    else
        value = bit.band(value, bit.bnot(reason))
    end

    if (value ~= prevValue) or force then
        self:SetAttribute("showgrid", value)
        self:UpdateShown()
    end
end

function ActionButton:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

-- exports
Addon.ActionButton = ActionButton
