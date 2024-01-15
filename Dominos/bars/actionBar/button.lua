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
    -- 7-12
    elseif id <= 120 then
        return
    -- 13
    elseif id <= 132 then
        return "MULTIACTIONBAR5BUTTON" .. (id - 120)
    -- 14
    elseif id <= 144 then
        return "MULTIACTIONBAR6BUTTON" .. (id - 132)
    -- 15
    elseif id <= 156 then
        return "MULTIACTIONBAR7BUTTON" .. (id - 144)
    end
end

local function SetOverrideClickBindings(owner, button, ...)
    ClearOverrideBindings(owner)

    for i = 1, select("#", ...) do
        SetOverrideBindingClick(owner, false, select(i, ...), owner:GetName(), button)
    end
end

local function Cooldown_OnDone(self)
    if self.requireCooldownUpdate and self:GetParent():IsVisible() then
        self:GetParent():UpdateCooldown()
    end
end

local ATTACK_BUTTON_FLASH_TIME = ATTACK_BUTTON_FLASH_TIME * 1.5

local ActionButton = Addon:CreateClass("CheckButton")

--[[ Script Handlers ]]--

function ActionButton:OnCreate(id)
    self:Construct()

    -- initialize state
    self.id = id
    self.action = 0
    self.showgrid = 0
    self.commandName = GetActionButtonCommand(id)

    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("id", id)
    self:SetAttributeNoHandler("type", "action")
    self:SetAttributeNoHandler("typerelease", "actionrelease")
    self:SetAttributeNoHandler("useparent-checkbuttoncast", true)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-locked", true)
    self:SetAttributeNoHandler("useparent-unit", true)

    -- register for clicks
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterForClicks("AnyUp", "LeftButtonDown", "RightButtonDown")
    self:EnableMouseWheel()

    -- script handlers
    self:SetScript("OnAttributeChanged", self.OnAttributeChanged)
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    self:SetScript("PostClick", self.OnPostClick)

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

    -- ...and the rest
    Addon.BindableButton:AddQuickBindingSupport(self)
    Addon.SpellFlyout:Register(self)

    self:UpdateOverrideBindings()
    self:UpdateHotkeys()
end

function ActionButton:OnAttributeChanged(key, value)
    if key ~= "action" then return end

    local oldAction = self.action
    if value ~= oldAction then
        self.action = value

        Addon.ActionButtons:OnActionChanged(self, value, oldAction)

        self:Update()
    end
end

function ActionButton:OnEnter()
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
    if self.Icon then return end

    self:SetSize(ActionButton1:GetSize())

    -- textures - background
    self.Icon = self:CreateTexture(nil, "BACKGROUND")
    self.Icon:SetAllPoints()

    self.IconMask = self:CreateMaskTexture(nil, "BACKGROUND")
    self.IconMask:SetTexture(4626072, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    self.IconMask:SetPoint("CENTER", self.Icon)
    self.Icon:AddMaskTexture(self.IconMask)

    self.SlotBackground = self:CreateTexture(nil, "BACKGROUND")
    self.SlotBackground:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
    self.SlotBackground:SetAllPoints()

    -- self.SlotArt = self:CreateTexture(nil, "BACKGROUND")
    -- self.SlotArt:SetAtlas("ui-hud-actionbar-iconframe-slot")
    -- self.SlotArt:SetAllPoints()

    -- textures - artwork
    self.Flash = self:CreateTexture(nil, "ARTWORK", nil, 1)
    self.Flash:SetAtlas("UI-HUD-ActionBar-IconFrame-Flash", true)
    self.Flash:SetPoint("TOPLEFT")
    self.Flash:Hide()

    self.Flash.Animation = self.Flash:CreateAnimationGroup()
    self.Flash.Animation:SetLooping("BOUNCE")

    self.Flash.Animation.Alpha = self.Flash.Animation:CreateAnimation("ALPHA")
    self.Flash.Animation.Alpha:SetDuration(ATTACK_BUTTON_FLASH_TIME)
    self.Flash.Animation.Alpha:SetFromAlpha(0)
    self.Flash.Animation.Alpha:SetToAlpha(1)

    self.FlyoutBorderShadow = self:CreateTexture(nil, "ARTWORK", nil, 1)
    self.FlyoutBorderShadow:SetSize(52, 52)
    self.FlyoutBorderShadow:SetPoint("CENTER", self.Icon, "CENTER", 0.2, 0.5)
    self.FlyoutBorderShadow:SetAtlas("UI-HUD-ActionBar-IconFrame-FlyoutBorderShadow")
    self.FlyoutBorderShadow:Hide()

    -- textures - overlway
    self.Border = self:CreateTexture(nil, "OVERLAY")
    self.Border:SetAtlas("UI-HUD-ActionBar-IconFrame-Border", true)
    self.Border:SetPoint("TOPLEFT")
    self.Border:SetVertexColor(0, 1, 0, 0.5)
    self.Border:Hide()

    self.AutoCastable = self:CreateTexture(nil, "OVERLAY", nil, 1)
    self.AutoCastable:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
    self.AutoCastable:SetSize(80, 80)
    self.AutoCastable:SetPoint("CENTER", 1, -1)
    self.AutoCastable:Hide()

    self.NormalTexture = self:CreateTexture(nil, "OVERLAY")
    self.NormalTexture:SetAtlas("UI-HUD-ActionBar-IconFrame")
    self.NormalTexture:SetAllPoints()
    self:SetNormalTexture(self.NormalTexture)

    self.CheckedTexture = self:CreateTexture()
    self.CheckedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    self.CheckedTexture:SetAllPoints()
    self:SetCheckedTexture(self.CheckedTexture)

    self.PushedTexture = self:CreateTexture(nil, "OVERLAY")
    self.PushedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
    self.PushedTexture:SetPoint("TOPLEFT", self.NormalTexture, -1, 1)
    self.PushedTexture:SetPoint("BOTTOMRIGHT", self.NormalTexture, 1, -1)
    self:SetPushedTexture(self.PushedTexture)

    self.HighlightTexture = self:CreateTexture()
    self.HighlightTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    self.HighlightTexture:SetPoint("TOPLEFT", self.NormalTexture, -2, 2)
    self.HighlightTexture:SetPoint("BOTTOMRIGHT", self.NormalTexture, 2, -2)
    self:SetHighlightTexture(self.HighlightTexture)

    -- text
    self.HotKey = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.HotKey:SetPoint("TOPRIGHT", -3.5, -3)

    self.Count = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.Count:SetPoint("BOTTOMRIGHT", -3, 3.5)

    self.Name = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    self.Name:SetPoint("BOTTOMLEFT", 5, 5)

    -- frames
    self.Cooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    self.Cooldown:SetDrawBling(true)
    self.Cooldown:SetDrawEdge(false)
    self.Cooldown:SetPoint("TOPLEFT", self.Icon, 3, -3)
    self.Cooldown:SetPoint("BOTTOMRIGHT", self.Icon, -3, 3)
    self.Cooldown:SetScript("OnCooldownDone", Cooldown_OnDone)

    self.ChargeCooldown = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    self.ChargeCooldown:SetHideCountdownNumbers(true)
    self.ChargeCooldown:SetDrawSwipe(false)
    self.ChargeCooldown:SetPoint("TOPLEFT", self.Icon, 3, -3)
    self.ChargeCooldown:SetPoint("BOTTOMRIGHT", self.Icon, -3, 3)

    self.FlyoutArrowContainer = CreateFrame("Frame", nil, self)
    self.FlyoutArrowContainer:SetAllPoints()
    self.FlyoutArrowContainer:Hide()

    local flyoutArrowNormal = self.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
    flyoutArrowNormal:Hide()
    flyoutArrowNormal:SetAtlas("UI-HUD-ActionBar-Flyout")
    flyoutArrowNormal:SetSize(18, 7)
    flyoutArrowNormal:SetPoint("TOP")
    self.FlyoutArrowContainer.FlyoutArrowNormal = flyoutArrowNormal

    local flyoutArrowPushed = self.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
    flyoutArrowPushed:Hide()
    flyoutArrowPushed:SetAtlas("UI-HUD-ActionBar-Flyout-Down")
    flyoutArrowPushed:SetSize(18, 8)
    flyoutArrowPushed:SetPoint("TOP")
    self.FlyoutArrowContainer.FlyoutArrowPushed = flyoutArrowNormal

    local flyoutArrowHighlight = self.FlyoutArrowContainer:CreateTexture(nil, "ARTWORK", nil, 2)
    flyoutArrowHighlight:Hide()
    flyoutArrowHighlight:SetAtlas("UI-HUD-ActionBar-Flyout-Mouseover")
    flyoutArrowHighlight:SetSize(18, 7)
    flyoutArrowHighlight:SetPoint("TOP")
    self.FlyoutArrowContainer.FlyoutArrowHighlight = flyoutArrowHighlight

    self.AutoCastShine = CreateFrame("Frame", "$parentShine", self, "AutoCastShineTemplate")
    self.AutoCastShine:SetSize(40, 40)
    self.AutoCastShine:SetPoint("CENTER")

    -- these aliases are added for compatibility with other addons
    self.icon = self.Icon
    self.cooldown = self.Cooldown
    self.chargeCooldown = self.ChargeCooldown
end

function ActionButton:Update()
    self:UpdateActive()
    self:UpdateBorder()
    self:UpdateCooldown()
    self:UpdateCount()
    self:UpdateFlashing()
    self:UpdateFlyout()
    self:UpdateIcon()
    self:UpdateShown()
    self:UpdateUsable()
end

function ActionButton:UpdateActive()
    local action = self.action

    local active = HasAction(action) and (
        IsCurrentAction(action)
        or IsAutoRepeatAction(action)
        and not C_ActionBar.IsAutoCastPetAction(action)
    )

    self:SetChecked(active)
end

function ActionButton:UpdateBorder()
    self.Border:SetShown((not self.hideBorders) and IsEquippedAction(self.action))
end

function ActionButton:UpdateCount()
    local action = self.action

    if IsConsumableAction(action) or IsStackableAction(action) then
        local count = GetActionCount(action) or 0
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

    if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
        if not self.Flash:IsShown() then
            self.Flash:Show()
            self.Flash.Animation:Play()
        end
    elseif self.Flash:IsShown() then
        self.Flash.Animation:Stop()
        self.Flash:Hide()
    end
end

function ActionButton:UpdateIcon()
    local icon = GetActionTexture(self.action)
    if icon then
        self.Icon:SetTexture(icon)
        self.Icon:Show()
    else
        self.Icon:Hide()
    end
end

function ActionButton:UpdateOverrideBindings()
    local command = self.commandName
    if command then
        SetOverrideClickBindings(self, "HOTKEY", GetBindingKey(command))
    end
end

function ActionButton:UpdateShown()
    if self.showgrid > 0 or HasAction(self.action) then
        self:SetAlpha(1)
    else
        self:SetAlpha(0)
    end
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

    local icon = self.Icon

    if oom then
        icon:SetDesaturated(true)
        icon:SetVertexColor(0.4, 0.4, 1.0)
    elseif oor then
        icon:SetDesaturated(true)
        icon:SetVertexColor(1, 0.4, 0.4)
    elseif usable then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1, 1, 1)
    else
        icon:SetDesaturated(true)
        icon:SetVertexColor(0.4, 0.4, 0.4)
    end

    if oor then
        self.HotKey:SetVertexColor(1, 0, 0)
    else
        self.HotKey:SetVertexColor(1, 1, 1)
    end
end

function ActionButton:SetFlyoutDirection(direction, force)
    if InCombatLockdown() then
        return
    end

    if (self.flyoutDirection ~= direction) or force then
        self.flyoutDirection = direction
        self:SetAttribute("flyoutDirection", direction)
        self:UpdateFlyout()
    end
end

function ActionButton:SetShowCountText(show)
    self.Count:SetShown(show and true)
end

function ActionButton:SetShowEquippedItemBorders(show)
    self.hideBorders = (not show) or nil

    self:UpdateBorder()
end

function ActionButton:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

function ActionButton:SetShowGrid(reason, show, force)
    local showgrid
    if show then
        showgrid = bit.bor(self.showgrid, reason)
    else
        showgrid = bit.band(self.showgrid, bit.bnot(reason))
    end

    if (self.showgrid ~= showgrid) or force then
        self.showgrid = showgrid
        self:UpdateShown()
    end
end

-- standard method references
ActionButton.UpdateCooldown = ActionButton_UpdateCooldown
ActionButton.UpdateFlyout = ActionBarActionButtonMixin.UpdateFlyout
ActionButton.ShowOverlayGlow = ActionButton_ShowOverlayGlow
ActionButton.HideOverlayGlow = ActionButton_HideOverlayGlow
ActionButton.UpdateOverlayGlow = ActionBarActionButtonMixin.UpdateOverlayGlow

-- exports
Addon.ActionButton = ActionButton
