--------------------------------------------------------------------------------
-- ActionButtonMixin
-- Additional methods we define on action buttons
--------------------------------------------------------------------------------

local _, Addon = ...
if Addon:IsBuild("retail") then return end

local ActionButton = { }

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

function ActionButton:OnCreate(id)
    -- initialize state
    if self.commandName == nil then
        self:SetAttributeNoHandler("commandName", GetActionButtonCommand(id))
    end

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

    -- hide by default
    self:Hide()
end

function ActionButton:SetShowGrid(show, reason, force)
    if InCombatLockdown() then return end

    if reason == nil then
        error("Usage: ActionButton:SetShowGrid(show, reason, [, force?])", 2)
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

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    local show = (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")

    self:SetShown(show)
end

-- configuration commands
function ActionButton:SetFlyoutDirection(direction)
    if InCombatLockdown() then return end

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
