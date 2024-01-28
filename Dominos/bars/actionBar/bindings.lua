local _, Addon = ...
if not Addon:IsBuild("retail") then return end
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

local Binder = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")

Binder:WrapScript(OverrideActionBarButton1, "OnShow", [[
    control:SetAttribute("overrideui", 1)
]])

Binder:WrapScript(OverrideActionBarButton1, "OnHide", [[
    control:SetAttribute("overrideui", 0)
]])

Binder:SetAttributeNoHandler("_onattributechanged", [[
    if name == "bind" then return end

    local bind = (
        (self:GetAttribute("overrideui") == 1 and self:GetAttribute("useoverrideui") == 1)
        or self:GetAttribute("petbattleui") == 1
    )

    if self:GetAttribute("bind") ~= bind then
        self:SetAttribute("bind", bind)
        self:ClearBindings()

        if bind then
            for i = 1, 6 do
                local command = "ACTIONBUTTON" .. i
                local keyCommand = self:GetAttribute(command) or command
                self:RunAttribute("SetBindings", command, GetBindingKey(keyCommand))
            end
        end
    end
]])

Binder:SetAttributeNoHandler("SetBindings", [[
    local command = ...
    for i = 2, select("#", ...) do
        self:SetBinding(true, select(i, ...), command)
    end
]])

-- initialize state
Binder:SetScript("OnEvent", function(self, event)
    self:SetScript("OnEvent", nil)
    self:UnregisterEvent(event)

    self:SetAttribute("overrideui", OverrideActionBarButton1:IsShown() and 1 or 0)
    self:SetAttribute("useoverrideui", Addon:UsingOverrideUI() and 1 or 0)
    RegisterAttributeDriver(self, "petabattleui", "[petbattle]1;0")
end)

Binder:RegisterEvent("PLAYER_LOGIN")

function Binder:USE_OVERRRIDE_UI_CHANGED(_, enabled)
    self:SetAttribute("useoverrideui", enabled and 1 or 0)
end

function Binder:LAYOUT_LOADED()
    self:SetAttribute("useoverrideui", Addon:UsingOverrideUI() and 1 or 0)
end

Addon.RegisterCallback(Binder, "USE_OVERRRIDE_UI_CHANGED")
Addon.RegisterCallback(Binder, "LAYOUT_LOADED")
