local _, Addon = ...
if not Addon:IsBuild("retail") then return end

local ActionButton = {}

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
    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("commandName", GetActionButtonCommand(id) or ("CLICK %s:HOTKEY"):format(self:GetName()))
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-checkselfcast", true)

    -- register for clicks on all buttons, and enable mousewheel bindings
    self:EnableMouseWheel()
    self:RegisterForClicks("AnyUp", "AnyDown")

    -- secure handlers
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

    self:UpdateHotkeys()
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
    if InCombatLockdown() then return end

    self.bind:SetOverrideBindings(GetBindingKey(self:GetAttribute("commandName")))
end

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    self:SetShown(
        (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")
    )
end

--------------------------------------------------------------------------------
-- configuration
--------------------------------------------------------------------------------

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

function ActionButton:SetShowCountText(show)
    self.Count:SetShown(show)
end

function ActionButton:SetFlyoutDirectionInsecure(direction)
    if InCombatLockdown() then return end

    self:SetAttribute("flyoutDirection", direction)
    self:UpdateFlyout()
end

function ActionButton:SetShowEquippedItemBorders(show)
    local parent = (show and self) or Addon.ShadowUIParent

    if self.Border:GetParent() ~= parent then
        self.Border:SetParent(parent)
    end
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
