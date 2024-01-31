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

local ActionButton = {}

--[[ Script Handlers ]]--

local function bind_PreClick(self, _, down)
    local owner = self:GetParent()

    if down then
        if owner:GetButtonState() == "NORMAL" then
            owner:SetButtonState("PUSHED")
        end
    else
        if owner:GetButtonState() == "PUSHED" then
            owner:SetButtonState("NORMAL")
        end
    end
end

function ActionButton:OnCreate(id)
    -- initialize secure state
    self:SetAttributeNoHandler("action", 0)
    self:SetAttributeNoHandler("id", id)
    self:SetAttributeNoHandler("showgrid", 0)
    self:SetAttributeNoHandler("commandName", GetActionButtonCommand(id))
    self:SetAttributeNoHandler("useparent-checkselfcast", true)
    self:SetAttributeNoHandler("useparent-checkfocuscast", true)
    self:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    self:SetAttributeNoHandler("useparent-unit", true)

    -- register for clicks
    self:EnableMouseWheel()
    self:RegisterForClicks("AnyUp", "AnyDown")

    -- cast on keypress support
    local bind = CreateFrame("Button", "$parentHotkey", self, "SecureActionButtonTemplate")
    bind:SetAttributeNoHandler("type", "action")
    bind:SetAttributeNoHandler("typerelease", "actionrelease")
    bind:SetAttributeNoHandler("useparent-action", true)
    bind:SetAttributeNoHandler("useparent-checkselfcast", true)
    bind:SetAttributeNoHandler("useparent-checkfocuscast", true)
    bind:SetAttributeNoHandler("useparent-checkmouseovercast", true)
    bind:SetAttributeNoHandler("useparent-unit", true)
    bind:SetAttributeNoHandler("useparent-flyoutDirection", true)
    bind:SetAttributeNoHandler("useparent-pressAndHoldAction", true)
    bind:RegisterForClicks("AnyUp", "AnyDown")
    bind:SetScript("PreClick", bind_PreClick)

    SecureHandlerSetFrameRef(bind, "owner", self)
    Addon.SpellFlyout:Register(bind)
    self.bind = bind

    -- script handlers
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

function ActionButton:UpdateOverrideBindings()
    if InCombatLockdown() then return end

    local command = self:GetAttribute("commandName") or ("CLICK %s:HOTKEY"):format(self:GetName())
    if command then
        SetOverrideClickBindings(self.bind, "HOTKEY", GetBindingKey(command))
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

function ActionButton:SetFlyoutDirectionInsecure(direction, force)
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
    if show then
        self.Border:SetParent(self)
    else
        self.Border:SetParent(Addon.ShadowUIParent)
    end
end

function ActionButton:SetShowMacroText(show)
    self.Name:SetShown(show and true)
end

function ActionButton:SetShowGridInsecure(show, reason, force)
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

        self:SetShown(
            (value > 0 or HasAction(self:GetAttribute("action")))
            and not self:GetAttribute("statehidden")
        )
    end
end

function ActionButton:UpdateShown()
    if InCombatLockdown() then return end

    self:SetShown(
        (self:GetAttribute("showgrid") > 0 or HasAction(self:GetAttribute("action")))
        and not self:GetAttribute("statehidden")
    )
end

-- exports
Addon.ActionButton = ActionButton
