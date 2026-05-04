-- Binding code that's shared between the various flavors of action buttons
local AddonName, Addon = ...
local KeyBound = LibStub('LibKeyBound-1.0')
local COMMAND_TEMPLATE = 'CLICK %s:HOTKEY'

local function getBindingCompat()
    return Addon.BindingCompat
end

-- binding method definitions
-- returns the binding action associated with the button

-- we use a virtual button (arbitrarily named HOTKEY)
-- to enable cast on key press support
local function getButtonBindingAction(button)
    local bindingCompat = getBindingCompat()
    if bindingCompat then
        return bindingCompat.NormalizeCommandName(button:GetAttribute("commandName"))
            or bindingCompat.GetActionButtonCommand(button:GetAttribute("bindingID"), button)
            or bindingCompat.GetFallbackClickBinding(button, button:GetAttribute("bindingID"))
    end

    return button:GetAttribute("commandName")
        or COMMAND_TEMPLATE:format(button:GetName())
end

local function getButtonBindingActionName(button)
    return button:GetAttribute("displayName")
        or _G["BINDING_NAME_" .. getButtonBindingAction(button)]
        or button:GetName()
end

local function getButtonBindings(button)
    local bindingID = button:GetAttribute("bindingID")
    local bindingCompat = getBindingCompat()

    if bindingID and bindingCompat and bindingCompat.GetActionButtonBindingKeys then
        return unpack(bindingCompat.GetActionButtonBindingKeys(bindingID, button))
    end

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
    local key = getButtonBindings(button)
    if key then
        return strjoin(' ', getButtonBindings(button))
    end

    return ''
end

-- set bindings
local function setButtonBinding(button, key)
    return SetBinding(key, getButtonBindingAction(button))
end

-- clears all bindings from the button
local function clearButtonBindingCommand(command)
    local key = GetBindingKey(command)

    while key do
        SetBinding(key, nil)
        key = GetBindingKey(command)
    end
end

local function clearButtonBindings(button)
    local bindingID = button:GetAttribute("bindingID")
    local bindingCompat = getBindingCompat()

    if bindingID and bindingCompat and bindingCompat.GetActionButtonCommands then
        local commands = bindingCompat.GetActionButtonCommands(bindingID, button)
        for _, command in ipairs(commands) do
            clearButtonBindingCommand(command)
        end
        return
    end

    clearButtonBindingCommand(getButtonBindingAction(button))
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
function BindableButton:AddQuickBindingSupport(button)
    button:HookScript('OnEnter', BindableButton.OnEnter)

    if button.UpdateHotkeys then
        hooksecurefunc(button, 'UpdateHotkeys', BindableButton.UpdateHotkeys)
    else
        button.UpdateHotkeys = BindableButton.UpdateHotkeys
    end

    button:UpdateHotkeys()
end

function BindableButton:UpdateHotkeys()
    local bindingAction = getButtonBindingAction(self)

    -- Blizzard's ActionBarActionButtonMixin may rebuild bindingAction from
    -- GetID(), which Dominos intentionally keeps decoupled from secure paging.
    -- Restore the stable binding contract after the native hotkey update path
    -- runs so external binding-highlighting hooks see the same command Dominos
    -- displays and binds.
    self.commandName = bindingAction
    self.bindingAction = bindingAction

    local key = (self.GetHotkey or getButtonHotkey)(self) or ''
    local hotkey = self.HotKey

    hotkey:SetText(key)
    hotkey:SetShown(key ~= '')
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
