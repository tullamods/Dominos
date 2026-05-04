--------------------------------------------------------------------------------
-- Secure binding bridge for Blizzard override/pet-battle action routing.
--
-- Default action bars route ACTIONBUTTON1-6 through Blizzard's secure action
-- button functions when the Override UI or Pet Battle UI is active. Dominos
-- also has a configurable override bar, so the bridge must preserve both:
--   1. Blizzard's priority ACTIONBUTTON routing when the default UI owns it.
--   2. Dominos' configured override-bar buttons when Dominos owns it.
--------------------------------------------------------------------------------

local _, Addon = ...
if not OverrideActionBar then return end

local Binder = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")

local MAX_OVERRIDE_BINDINGS = NUM_OVERRIDE_BUTTONS or 6
local MAX_BINDING_SOURCES = 6
local SOURCE_ATTRIBUTE_TEMPLATE = "ACTIONBUTTON%d_SOURCE%d"
local ENABLED_ATTRIBUTE_TEMPLATE = "ACTIONBUTTON%d_ENABLED"
local BUTTON_REF_TEMPLATE = "overrideButton%d"

Binder:SetAttribute("maxOverrideBindings", MAX_OVERRIDE_BINDINGS)

local function GetBindingCompat()
    return Addon.BindingCompat
end

local function GetOverrideButton(index)
    if not Addon.GetOverrideBar then
        return nil
    end

    local bar = Addon:GetOverrideBar()
    if bar and bar.buttons then
        return bar.buttons[index]
    end
end

local function SetSourceAttribute(self, buttonIndex, sourceIndex, value)
    self:SetAttribute(SOURCE_ATTRIBUTE_TEMPLATE:format(buttonIndex, sourceIndex), value)
end

local function ClearOverrideButtonSources(self, buttonIndex)
    for sourceIndex = 1, MAX_BINDING_SOURCES do
        SetSourceAttribute(self, buttonIndex, sourceIndex, nil)
    end
end

local function SetOverrideButtonSources(self, buttonIndex, button)
    ClearOverrideButtonSources(self, buttonIndex)

    if not button then
        self:SetAttribute(ENABLED_ATTRIBUTE_TEMPLATE:format(buttonIndex), nil)
        return
    end

    local bindingCompat = GetBindingCompat()
    if bindingCompat and bindingCompat.GetActionButtonCommands then
        local commands = bindingCompat.GetActionButtonCommands(button:GetAttribute("bindingID"), button)
        for sourceIndex = 1, math.min(#commands, MAX_BINDING_SOURCES) do
            SetSourceAttribute(self, buttonIndex, sourceIndex, commands[sourceIndex])
        end
    else
        SetSourceAttribute(self, buttonIndex, 1, button:GetAttribute("commandName"))
    end

    self:SetFrameRef(BUTTON_REF_TEMPLATE:format(buttonIndex), button)
    self:SetAttribute(ENABLED_ATTRIBUTE_TEMPLATE:format(buttonIndex), 1)
end

local function MarkBindingsDirty(self)
    if InCombatLockdown() then
        self.needsBindingRefresh = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    self:SetAttribute("bindingUpdate", (self:GetAttribute("bindingUpdate") or 0) + 1)
end

local function SetUseOverrideUI(self, enabled)
    if InCombatLockdown() then
        self.pendingUseOverrideUI = enabled and true or false
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    self:SetAttribute("useoverrideui", enabled and 1 or 0)
end

function Binder:UpdateOverrideBindingSources()
    if InCombatLockdown() then
        self.needsOverrideBindingSourceUpdate = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    for buttonIndex = 1, MAX_OVERRIDE_BINDINGS do
        SetOverrideButtonSources(self, buttonIndex, GetOverrideButton(buttonIndex))
    end

    MarkBindingsDirty(self)
end

function Binder:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    if self.pendingUseOverrideUI ~= nil then
        self:SetAttribute("useoverrideui", self.pendingUseOverrideUI and 1 or 0)
        self.pendingUseOverrideUI = nil
    end

    if self.needsOverrideBindingSourceUpdate then
        self.needsOverrideBindingSourceUpdate = nil
        self:UpdateOverrideBindingSources()
    elseif self.needsBindingRefresh then
        self.needsBindingRefresh = nil
        MarkBindingsDirty(self)
    end
end

function Binder:UPDATE_BINDINGS()
    MarkBindingsDirty(self)
end

Binder:WrapScript(OverrideActionBarButton1, "OnShow", [[
    control:SetAttribute("overrideui", 1)
]])

Binder:WrapScript(OverrideActionBarButton1, "OnHide", [[
    control:SetAttribute("overrideui", 0)
]])

Binder:SetAttributeNoHandler("SetCommandBindings", [[
    local targetCommand = ...

    for sourceIndex = 2, select("#", ...) do
        local sourceCommand = select(sourceIndex, ...)
        if sourceCommand then
            for keyIndex = 1, select("#", GetBindingKey(sourceCommand)) do
                local key = select(keyIndex, GetBindingKey(sourceCommand))
                if key then
                    self:SetBinding(true, key, targetCommand)
                end
            end
        end
    end
]])

Binder:SetAttributeNoHandler("SetClickBindings", [[
    local targetButton = ...

    for sourceIndex = 2, select("#", ...) do
        local sourceCommand = select(sourceIndex, ...)
        if sourceCommand then
            for keyIndex = 1, select("#", GetBindingKey(sourceCommand)) do
                local key = select(keyIndex, GetBindingKey(sourceCommand))
                if key then
                    self:SetBindingClick(true, key, targetButton, "LeftButton")
                end
            end
        end
    end
]])

Binder:SetAttributeNoHandler("UpdateBindings", [[
    local overrideUIValue = self:GetAttribute("overrideui")
    local useOverrideUIValue = self:GetAttribute("useoverrideui")
    local petBattleValue = self:GetAttribute("petbattleui")
    local statePetBattleValue = self:GetAttribute("state-petbattleui")
    local overridePage = tonumber(self:GetAttribute("state-overridepage")) or 0
    local maxOverrideBindings = tonumber(self:GetAttribute("maxOverrideBindings")) or 6

    local overrideUIActive = overrideUIValue == 1 or overrideUIValue == "1" or overrideUIValue == true
    local useOverrideUI = useOverrideUIValue == 1 or useOverrideUIValue == "1" or useOverrideUIValue == true
    local petBattleActive = petBattleValue == 1 or petBattleValue == "1" or petBattleValue == true
        or statePetBattleValue == 1 or statePetBattleValue == "1" or statePetBattleValue == true
    local dominosOverrideActive = overridePage > 0 and not useOverrideUI and not petBattleActive

    self:ClearBindings()

    if (overrideUIActive and useOverrideUI) or petBattleActive then
        for buttonIndex = 1, maxOverrideBindings do
            local targetCommand = "ACTIONBUTTON" .. buttonIndex
            self:RunAttribute(
                "SetCommandBindings",
                targetCommand,
                targetCommand,
                self:GetAttribute(targetCommand .. "_SOURCE1"),
                self:GetAttribute(targetCommand .. "_SOURCE2"),
                self:GetAttribute(targetCommand .. "_SOURCE3"),
                self:GetAttribute(targetCommand .. "_SOURCE4"),
                self:GetAttribute(targetCommand .. "_SOURCE5"),
                self:GetAttribute(targetCommand .. "_SOURCE6")
            )
        end
    elseif dominosOverrideActive then
        for buttonIndex = 1, maxOverrideBindings do
            if self:GetAttribute("ACTIONBUTTON" .. buttonIndex .. "_ENABLED") == 1 then
                local targetCommand = "ACTIONBUTTON" .. buttonIndex
                local targetButton = self:GetFrameRef("overrideButton" .. buttonIndex)
                if targetButton then
                    self:RunAttribute(
                        "SetClickBindings",
                        targetButton,
                        targetCommand,
                        self:GetAttribute(targetCommand .. "_SOURCE1"),
                        self:GetAttribute(targetCommand .. "_SOURCE2"),
                        self:GetAttribute(targetCommand .. "_SOURCE3"),
                        self:GetAttribute(targetCommand .. "_SOURCE4"),
                        self:GetAttribute(targetCommand .. "_SOURCE5"),
                        self:GetAttribute(targetCommand .. "_SOURCE6")
                    )
                end
            end
        end
    end
]])

Binder:SetAttributeNoHandler("_onattributechanged", [[
    self:RunAttribute("UpdateBindings")
]])

Binder:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)

        self:SetAttribute("overrideui", OverrideActionBarButton1:IsVisible() and 1 or 0)
        SetUseOverrideUI(self, Addon:UsingOverrideUI())
        RegisterAttributeDriver(self, "petbattleui", "[petbattle]1;0")

        if Addon.OverrideController then
            Addon.OverrideController:Add(self)
        end

        self:RegisterEvent("UPDATE_BINDINGS")
        self:UpdateOverrideBindingSources()
        return
    end

    if self[event] then
        self[event](self)
    end
end)

Binder:RegisterEvent("PLAYER_LOGIN")

function Binder:USE_OVERRRIDE_UI_CHANGED(_, enabled)
    SetUseOverrideUI(self, enabled)
end

function Binder:LAYOUT_LOADED()
    SetUseOverrideUI(self, Addon:UsingOverrideUI())
    self:UpdateOverrideBindingSources()
end

function Binder:OVERRIDE_BAR_UPDATED()
    self:UpdateOverrideBindingSources()
end

Addon.RegisterCallback(Binder, "USE_OVERRRIDE_UI_CHANGED")
Addon.RegisterCallback(Binder, "LAYOUT_LOADED")
Addon.RegisterCallback(Binder, "OVERRIDE_BAR_UPDATED")
