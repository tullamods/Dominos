-- Binding code that's shared between the various flavors of action buttons
local AddonName, Addon = ...
local KeyBound = LibStub('LibKeyBound-1.0')
local COMMAND_TEMPLATE = 'CLICK %s:HOTKEY'

-- binding method definitions
-- returns the binding action associated with the button

-- we use a virtual button (arbitrarily named HOTKEY)
-- to enable cast on key press support
local function getButtonBindingAction(button)
    return button.commandName
        or COMMAND_TEMPLATE:format(button:GetName())
end

local function getButtonBindingActionName(button)
    local displayName = button.displayName
    if displayName then
        return displayName
    end

    local bindingName = _G["BINDING_NAME_" .. getButtonBindingAction(button)]
    if bindingName then
        return bindingName
    end

    return button:GetName()
end

local function getButtonBindings(button)
    return GetBindingKey(getButtonBindingAction(button))
end

-- returns what hotkey to display for the button
local function getButtonHotkey(button)
    local key = (getButtonBindings(button))

    if key then
        return KeyBound:ToShortKey(key)
    end

    return ''
end

-- returns a space separated list of all bindings for the given button
local function getButtonBindingsList(button)
    return strjoin(' ', getButtonBindings(button))
end

-- set bindings
local function setButtonBinding(button, key)
    return SetBinding(key, getButtonBindingAction(button))
end

-- clears all bindings from the button
local function clearButtonBindings(button)
    local key = (getButtonBindings(button))

    while key do
        SetBinding(key, nil)
        key = (getButtonBindings(button))
    end
end

-- used to implement keybinding support without applying all of the LibKeyBound
-- interface methods via a mixin
local BindableButtonProxy = Addon:CreateHiddenFrame('Frame', AddonName .. 'BindableButtonProxy')

-- call a thing if the thing exists
local function whenExists(obj, func, ...)
    if obj then
        return func(obj, ...)
    end
end

function BindableButtonProxy:GetHotkey()
    return whenExists(self:GetParent(), getButtonHotkey)
end

function BindableButtonProxy:SetKey(key)
    return whenExists(self:GetParent(), setButtonBinding, key)
end

function BindableButtonProxy:GetBindings()
    return whenExists(self:GetParent(), getButtonBindingsList)
end

function BindableButtonProxy:ClearBindings()
    return whenExists(self:GetParent(), clearButtonBindings)
end

function BindableButtonProxy:GetActionName()
    return whenExists(self:GetParent(), getButtonBindingActionName) or UNKNOWN
end

BindableButtonProxy:SetScript('OnLeave', function(self)
    self:ClearAllPoints()
    self:SetParent(nil)
end)

-- methods to inject onto a bar to add in common binding functionality
-- previously, this was a mixin
local BindableButton = {}

-- adds quickbinding support to buttons
function BindableButton:AddQuickBindingSupport(button, bindingAction)
    button:HookScript('OnEnter', BindableButton.OnEnter)

    if bindingAction then
        button:SetAttribute('bindingAction', bindingAction)
    end

    if button.UpdateHotkeys then
        hooksecurefunc(button, 'UpdateHotkeys', BindableButton.UpdateHotkeys)
    else
        button.UpdateHotkeys = BindableButton.UpdateHotkeys
    end

    if not button.GetHotkey then
        button.GetHotkey = BindableButton.GetHotkey
    end
end

function BindableButton:UpdateHotkeys()
    self.HotKey:SetText(self:GetHotkey() or '')
    self.HotKey:SetShown(Addon:ShowBindingText())
end

function BindableButton:GetHotkey()
    local key = (getButtonBindings(self))

    if key then
        return KeyBound:ToShortKey(key) or ''
    end

    return ''
end

function BindableButton:OnEnter()
    if not KeyBound:IsShown() then
        return
    end

    BindableButtonProxy:ClearAllPoints()
    BindableButtonProxy:SetParent(self)
    BindableButtonProxy:SetAllPoints()

    KeyBound:Set(BindableButtonProxy)
end

-- exports
Addon.BindableButton = BindableButton
