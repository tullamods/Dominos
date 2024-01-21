local _, Addon = ...
if not Addon:IsBuild("retail") then return end

local function GetActionButtonCommand(id)
    -- 0
    if id <= 0 then
        return
        -- 1
    elseif id <= 12 then
        return "ACTIONBUTTON" .. id
        -- 2
    elseif id <= 24 then
        return
        -- 3
    elseif id <= 36 then
        return "MULTIACTIONBAR3BUTTON" .. (id - 24)
        -- 4
    elseif id <= 48 then
        return "MULTIACTIONBAR4BUTTON" .. (id - 36)
        -- 5
    elseif id <= 60 then
        return "MULTIACTIONBAR2BUTTON" .. (id - 48)
        -- 6
    elseif id <= 72 then
        return "MULTIACTIONBAR1BUTTON" .. (id - 60)
        -- 7-11
    elseif id <= 132 then
        return
        -- 12
    elseif id <= 144 then
        return "MULTIACTIONBAR5BUTTON" .. (id - 132)
        -- 13
    elseif id <= 156 then
        return "MULTIACTIONBAR6BUTTON" .. (id - 144)
        -- 14
    elseif id <= 168 then
        return "MULTIACTIONBAR7BUTTON" .. (id - 156)
    end
end

local function SetOverrideClickBindings(owner, button, ...)
    ClearOverrideBindings(owner)

    for i = 1, select("#", ...) do
        SetOverrideBindingClick(owner, false, select(i, ...), owner:GetName(), button)
    end
end

local ATTACK_BUTTON_FLASH_TIME = ATTACK_BUTTON_FLASH_TIME * 1.5

local ActionButton = Addon:CreateClass("CheckButton")

--[[ Script Handlers ]]--

function ActionButton:OnCreate(id)
    self:Construct()

    -- unmix BaseActionButtonMixin to reduce conflicts with our stuff
    for k, v in pairs(BaseActionButtonMixin) do
        if type(v) == "function" then
            self[k] = nil
        end
    end

    -- initialize state
    self.id = id
    self.action = 0
    self.commandName = GetActionButtonCommand(id)

    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("id", id)
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("type", "action")
    self:SetAttributeNoHandler("typerelease", "actionrelease")
	self:SetAttributeNoHandler("useparent-checkselfcast", true)
	self:SetAttributeNoHandler("useparent-checkfocuscast", true)
	self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-unit", true)

    -- register for clicks
    self:RegisterForDrag("LeftButton", "RightButton")
    self:RegisterForClicks("AnyUp", "AnyDown")
    self:EnableMouseWheel()

    -- script handlers
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("PostClick", self.OnPostClick)

    self:SetAttributeNoHandler("_onattributechanged", [[
        if name == "action" then
            self:RunAttribute("UpdateShown")
            self:CallMethod("OnActionChanged", value)
        end
    ]])

    self:SetAttributeNoHandler("_ondragstart", [[
        local action = self:GetAttribute("action")

        if HasAction(action) then
            return "action", action
        end
    ]])

    self:SetAttributeNoHandler("_onreceivedrag", [[
        if kind then
            self:SetAttribute("dragging", kind)
            return "action", self:GetAttribute("action")
        else
            self:SetAttribute("dragging", nil)
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

            local show = (value > 0 or HasAction(self:GetAttribute("action")))
                and not self:GetAttribute("statehidden")

            if show then
                self:Show(true)
            else
                self:Hide(true)
            end
        end
    ]])

    self:SetAttributeNoHandler("UpdateShown", [[
        local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
            and not self:GetAttribute("statehidden")

        if show then
            self:Show(true)
        else
            self:Hide(true)
        end
    ]])

    -- ...and the rest
    Addon.BindableButton:AddQuickBindingSupport(self)
    Addon.SpellFlyout:Register(self)

    self:UpdateOverrideBindings()
    self:UpdateHotkeys()
end

function ActionButton:OnActionChanged(action)
    if action ~= self.action then
        self.action = action
        self:Update()
    end
end

function ActionButton:OnEnter()
    self:UpdateAutocast()

    if HasAction(self.action) then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        self:UpdateTooltip()
    end
end

function ActionButton:OnLeave()
    GameTooltip:Hide()
end

function ActionButton:OnPostClick(_, down)
    self:UpdateShown()
    self:UpdateActive()
    self:UpdateFlyout(down)
end

--[[ Methods ]]--

-- setup all of the necessary frames and textures
function ActionButton:Construct()
    -- textures - artwork
    self.Flash.Animation = self.Flash:CreateAnimationGroup()
    self.Flash.Animation:SetLooping("BOUNCE")

    self.Flash.Animation.Alpha = self.Flash.Animation:CreateAnimation("ALPHA")
    self.Flash.Animation.Alpha:SetDuration(ATTACK_BUTTON_FLASH_TIME)
    self.Flash.Animation.Alpha:SetFromAlpha(0)
    self.Flash.Animation.Alpha:SetToAlpha(1)

    self.Border:SetVertexColor(0, 1, 0, 0.5)
end

function ActionButton:Update()
    self:UpdateActive()
    self:UpdateAutocast()
    self:UpdateBorder()
    self:UpdateCooldown()
    self:UpdateCount()
    self:UpdateFlashing()
    self:UpdateFlyout()
    self:UpdateIcon()
    self:UpdateProfessionQuality()
    self:UpdateShown()
    self:UpdateUsable()

    if Addon:ShowingSpellGlows() then
        self:UpdateOverlayGlow()
    end
end

function ActionButton:UpdateActive()
    local action = self.action
    local active = IsCurrentAction(action) or IsAutoRepeatAction(action)
    local autocastable = C_ActionBar.IsAutoCastPetAction(action)
    local autocasting = C_ActionBar.IsEnabledAutoCastPetAction(action)

    self:SetChecked(active and not autocastable)
    self.AutoCastable:SetShown(autocastable)
    self.AutoCastShine:SetShown(autocasting)

    if autocasting then
        AutoCastShine_AutoCastStart(self.AutoCastShine)
    else
        AutoCastShine_AutoCastStop(self.AutoCastShine)
    end
end

function ActionButton:UpdateAutocast()
    if InCombatLockdown() then return end

    local action = self.action
    if C_ActionBar.IsAutoCastPetAction(action) then
        local _, id = GetActionInfo(action)
        self:SetAttribute("type2", "macro")
        self:SetAttribute("macrotext", "/petautocasttoggle " .. id)
    elseif self:GetAttribute("type2") then
        self:SetAttribute("type2", nil)
        self:SetAttribute("macro", nil)
    end
end

function ActionButton:UpdateBorder()
    self.Border:SetShown((not self.hideBorders) and IsEquippedAction(self.action))
end

function ActionButton:UpdateCount()
    local action = self.action
    local count = GetActionCount(action) or 0

    if not HasAction(action) then
        self.Count:SetText("")
        self.Name:SetText("")
    elseif IsConsumableAction(action) or IsStackableAction(action) or (not IsItemAction(action) and count > 0) then
        if count > 999 then
            self.Count:SetFormattedText("%.1f%k", count / 1000)
            self.Name:SetText("")
        elseif count > 0 then
            self.Count:SetText(count)
            self.Name:SetText("")
        else
            self.Count:SetText("")
            self.Name:SetText(GetActionText(action) or "")
        end
    else
        local charges, maxCharges = GetActionCharges(action)
        if maxCharges and maxCharges > 1 then
            self.Count:SetText(charges)
            self.Name:SetText("")
        else
            self.Count:SetText("")
            self.Name:SetText(GetActionText(action) or "")
        end
    end
end

function ActionButton:UpdateFlashing()
    local action = self.action
    local flash = self.Flash

    if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
        if not flash:IsShown() then
            flash:Show()
            flash.Animation:Play()
        end
    elseif flash:IsShown() then
        flash.Animation:Stop()
        flash:Hide()
    end
end

function ActionButton:UpdateIcon()
    local icon = GetActionTexture(self.action)
    if icon then
        self.icon:SetTexture(icon)
        self.icon:Show()
    else
        self.icon:Hide()
    end
end

function ActionButton:UpdateOverrideBindings()
    local command = self.commandName
    if command then
        SetOverrideClickBindings(self, "HOTKEY", GetBindingKey(command))
    end
end

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    local show = (
        (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")
    )

    self:SetShown(show)
end

function ActionButton:UpdateTooltip()
    GameTooltip:SetAction(self.action)
end

function ActionButton:UpdateUsable(usable, oom, oor)
    if usable == nil then
        usable, oom = IsUsableAction(self.action)
    end

    if oor == nil then
        oor = IsActionInRange(self.action) == false
    end

    local state
    if usable then
        if oor then
            state = "oor"
        else
            state = "normal"
        end
    elseif oom then
        state = "oom"
    else
        state = "unusuable"
    end

    local icon = self.icon
    local iconColors = Addon.db.profile.actionColors
    local c = iconColors[state]
    if c.enabled then
        icon:SetVertexColor(c.r, c.g, c.b, c.a)
        icon:SetDesaturated(c.desaturate)
    else
        icon:SetVertexColor(1, 1, 1)
        icon:SetDesaturated(false)
    end

    local hotkey = self.HotKey
    local hotkeyColors = Addon.db.profile.hotkeyColors

    if oor and hotkeyColors.oor.enabled then
        c = hotkeyColors.oor
        hotkey:SetTextColor(c.r, c.g, c.b, c.a)

        if (hotkey:GetText() or '') == '' then
            hotkey:SetText(RANGE_INDICATOR)
        end
    else
        hotkey:SetTextColor(1, 1, 1, 1)

        if hotkey:GetText() == RANGE_INDICATOR then
            hotkey:SetText(self:GetHotkey())
        end
    end
end

function ActionButton:SetFlyoutDirection(direction, force)
    if InCombatLockdown() then return end

    if (self.flyoutDirection ~= direction) or force then
        self.flyoutDirection = direction
        self:SetAttribute("flyoutDirection", direction)
        self:UpdateFlyout()
    end
end

function ActionButton:SetShowCountText(show)
    self.Count:SetShown(show and true)
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButton:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)
            self:UpdateCooldown()
        end
    else
        self.cooldown:SetParent(Addon.ShadowUIParent)
    end
end

function ActionButton:SetShowEquippedItemBorders(show)
    self.hideBorders = (not show) or nil

    self:UpdateBorder()
end

function ActionButton:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

function ActionButton:SetShowGrid(show, reason, force)
    if InCombatLockdown() then return end

    if reason == nil then
        error("Usage: ActionButton:SetShowGrid(show, reason, force?)", 2)
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

function ActionButton:GetShowGrid()
    return self:GetAttribute("showgrid") > 0
end


-- standard method references
ActionButton.ClearProfessionQuality = ActionBarActionButtonMixin.ClearProfessionQuality
ActionButton.GetHotkey = Addon.BindableButton.GetHotkey
ActionButton.HideOverlayGlow = ActionButton_HideOverlayGlow
ActionButton.ShowOverlayGlow = ActionButton_ShowOverlayGlow
ActionButton.UpdateCooldown = ActionButton_UpdateCooldown
ActionButton.UpdateFlyout = ActionBarActionButtonMixin.UpdateFlyout
ActionButton.UpdateOverlayGlow = ActionBarActionButtonMixin.UpdateOverlayGlow
ActionButton.UpdateProfessionQuality = ActionBarActionButtonMixin.UpdateProfessionQuality

-- exports
Addon.ActionButton = ActionButton

