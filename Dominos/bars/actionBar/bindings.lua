if not OverrideActionBar then return end

--------------------------------------------------------------------------------
-- Sets priority bindings to the Pet Battle and Override UI when either frame
-- is visible
--
-- TODO:
-- Load the override bindings from whatever bar we've configured as the Dominos
-- override bar. Ensure that the bindings displayed for those frames are sourced
-- from those
--------------------------------------------------------------------------------

local Binder = CreateFrame("Frame", nil, OverrideActionBar, "SecureHandlerStateTemplate, SecureHandlerShowHideTemplate")

Binder:SetAttributeNoHandler("_onshow", [[
    self:SetAttribute("state-overrideui", 1)
]])

Binder:SetAttributeNoHandler("_onhide", [[
    self:SetAttribute("state-overrideui", 0)
]])

Binder:SetAttributeNoHandler("_onstate-overrideui", [[
    local bindState = self:GetAttribute("state-bind") or 0

    if newstate == 1 or self:GetAttribute("state-petabattleui") == 1 then
        if bindState == 0 then
            self:SetAttribute("state-bind", 1)
        end
    else
        if bindState == 1 then
            self:SetAttribute("state-bind", 0)
        end
    end
]])

Binder:SetAttributeNoHandler("_onstate-petabattleui", [[
    local bindState = self:GetAttribute("state-bind") or 0

    if newstate == 1 or self:GetAttribute("state-overrideui") == 1 then
        if bindState == 0 then
            self:SetAttribute("state-bind", 1)
        end
    else
        if bindState == 1 then
            self:SetAttribute("state-bind", 0)
        end
    end
]])

Binder:SetAttributeNoHandler("_onstate-bind", [[
    self:ClearBindings()

    if newstate == 1 then
        for i = 1, 6 do
            local command = "ACTIONBUTTON" .. i
            local keyCommand = self:GetAttribute(command) or command

            self:RunAttribute("SetBindings", command, GetBindingKey(keyCommand))
        end
    end
]])

Binder:SetAttributeNoHandler("SetBindings", [[
    local command = ...

    for i = 2, select("#", ...) do
        self:SetBinding(true, select(i, ...), command)
    end
]])

Binder:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event)
    self:SetScript("OnEvent", nil)

    -- initialize secure state
    self:SetAttribute("state-overrideui", self:IsVisible() and 1 or 0)
    RegisterStateDriver(self, "petabattleui", "[petbattle]1;0")
end)

Binder:RegisterEvent("PLAYER_LOGIN")
