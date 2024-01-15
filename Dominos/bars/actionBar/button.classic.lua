--------------------------------------------------------------------------------
-- ActionButtonMixin
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------

local _, Addon = ...
if Addon:IsBuild("retail") then return end

local ActionButton = { }

function ActionButton:OnCreate(id)
    -- initialize state
    self.id = id
    self.action = 0

    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("id", id)
    self:SetAttributeNoHandler("type", "action")
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("useparent-checkbuttoncast", true)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)

    -- register for clicks
	self:RegisterForDrag("LeftButton", "RightButton")
	self:RegisterForClicks("AnyUp", "AnyDown")
    self:EnableMouseWheel()

    -- bindings setup
    Addon.BindableButton:AddQuickBindingSupport(self)
    self:UpdateHotkeys()

    -- hide b default
    self:SetAttributeNoHandler("showgrid", 0)
    self:Hide()
end

function ActionButton:SetShowGrid(reason, show, force)
    if reason == nil then
        error("Usage: ActionButton:SetShowGrid(reason, show [, force?])", 2)
    end

    if InCombatLockdown() then return end

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

function ActionButton:UpdateShown()
    if InCombatLockdown() then
        return
    end

    local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")

    self:SetShown(show)
end

-- configuration commands
function ActionButton:SetFlyoutDirection(direction)
    if InCombatLockdown() then
        return
    end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

function ActionButton:SetShowCountText(show)
    if show then
        self.Count:Show()
    else
        self.Count:Hide()
    end
end

function ActionButton:SetShowMacroText(show)
    if show then
        self.Name:Show()
    else
        self.Name:Hide()
    end
end

function ActionButton:SetShowEquippedItemBorders(show)
    if show then
        self.Border:SetParent(self)
    else
        self.Border:SetParent(Addon.ShadowUIParent)
    end
end

-- we hide cooldowns when action buttons are transparent
-- so that the sparks don't appear
function ActionButton:SetShowCooldowns(show)
    if show then
        if self.cooldown:GetParent() ~= self then
            self.cooldown:SetParent(self)
            ActionButton_UpdateCooldown(self)
        end
    else
        self.cooldown:SetParent(Addon.ShadowUIParent)
    end
end

ActionButton.Update = ActionButton_Update
ActionButton.UpdateFlyout = ActionButton_UpdateFlyout
ActionButton.UpdateState = ActionButton_UpdateState
hooksecurefunc("ActionButton_UpdateHotkeys", Addon.BindableButton.UpdateHotkeys)

Addon.ActionButton = ActionButton
