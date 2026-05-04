-- Centralized binding identity helpers for Dominos action buttons.
--
-- Dominos buttons should expose Blizzard-native binding commands whenever a
-- stable Dominos button maps to a native Blizzard action button.  Dominos CLICK
-- bindings remain available as fallback compatibility bindings for buttons that
-- do not have a Blizzard-native binding command.
local AddonName, Addon = ...

local BindingCompat = {}
local CLICK_BINDING_TEMPLATE = "CLICK %s:HOTKEY"
local LEGACY_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

local NATIVE_BINDING_RANGES = {
    -- Main action bar.
    {first = 1, last = 12, prefix = "ACTIONBUTTON", offset = 0},

    -- Blizzard multi action bars.  The Dominos stable button ids intentionally
    -- match action slot layout, not paged runtime action attributes.
    {first = 25, last = 36, prefix = "MULTIACTIONBAR3BUTTON", offset = 24},
    {first = 37, last = 48, prefix = "MULTIACTIONBAR4BUTTON", offset = 36},
    {first = 49, last = 60, prefix = "MULTIACTIONBAR2BUTTON", offset = 48},
    {first = 61, last = 72, prefix = "MULTIACTIONBAR1BUTTON", offset = 60},

    -- Retail extra multi action bars.  These are capability-checked before use
    -- so TBC safely falls back to Dominos CLICK bindings.
    {first = 133, last = 144, prefix = "MULTIACTIONBAR5BUTTON", offset = 132, retailOnly = true},
    {first = 145, last = 156, prefix = "MULTIACTIONBAR6BUTTON", offset = 144, retailOnly = true},
    {first = 157, last = 168, prefix = "MULTIACTIONBAR7BUTTON", offset = 156, retailOnly = true},
}

local function IsNonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function GetBindingNameGlobal(command)
    if IsNonEmptyString(command) then
        return _G["BINDING_NAME_" .. command]
    end
end

local function IsNativeBindingCommandAvailable(command)
    -- Binding name globals are the safest capability probe here: they indicate
    -- that the client actually exposes the command through Blizzard's binding
    -- system.  GetBindingKey() alone cannot distinguish unbound commands from
    -- commands that do not exist on a flavor.
    return GetBindingNameGlobal(command) ~= nil
end

local function GetRangeInfo(buttonID)
    if type(buttonID) ~= "number" then
        return nil
    end

    for _, range in ipairs(NATIVE_BINDING_RANGES) do
        if buttonID >= range.first and buttonID <= range.last then
            return range
        end
    end
end


local function AddUniqueValue(values, seen, value)
    if IsNonEmptyString(value) and not seen[value] then
        values[#values + 1] = value
        seen[value] = true
    end
end

local function AddBindingKeysForCommand(keys, seen, command)
    if not IsNonEmptyString(command) then
        return
    end

    local firstKey, secondKey = GetBindingKey(command)
    AddUniqueValue(keys, seen, firstKey)
    AddUniqueValue(keys, seen, secondKey)
end

local function GetButtonName(button)
    if type(button) == "string" then
        return button
    end

    if type(button) == "table" and button.GetName then
        return button:GetName()
    end
end

function BindingCompat.NormalizeCommandName(command)
    if IsNonEmptyString(command) then
        return command
    end
end

function BindingCompat.GetLegacyActionButtonName(buttonID)
    if type(buttonID) == "number" and buttonID > 0 then
        return LEGACY_BUTTON_NAME_TEMPLATE:format(buttonID)
    end
end

function BindingCompat.GetBlizzardActionButtonAliasName(buttonID)
    if type(buttonID) == "number" and buttonID >= 1 and buttonID <= 12 then
        return ("ActionButton%d"):format(buttonID)
    end
end

function BindingCompat.CreateLegacyActionButtonAlias(button, buttonID)
    local legacyName = BindingCompat.GetLegacyActionButtonName(buttonID)
    if not legacyName or not button then
        return
    end

    -- Keep the historical DominosActionButtonN global as an alias only when it
    -- already resolves to this frame or has not been created yet.  Do not alias
    -- Blizzard-owned ActionButtonN globals to Dominos-created frames; those are
    -- used by restricted Blizzard binding scripts and controller tables.
    if _G[legacyName] == nil or _G[legacyName] == button then
        _G[legacyName] = button
    end
end

function BindingCompat.GetClickBindingForButtonName(buttonName)
    if IsNonEmptyString(buttonName) then
        return CLICK_BINDING_TEMPLATE:format(buttonName)
    end
end

function BindingCompat.GetActualClickBinding(button)
    local name = GetButtonName(button)
    return BindingCompat.GetClickBindingForButtonName(name)
end

function BindingCompat.GetBlizzardAliasClickBinding(buttonID)
    return BindingCompat.GetClickBindingForButtonName(BindingCompat.GetBlizzardActionButtonAliasName(buttonID))
end

function BindingCompat.GetFallbackClickBinding(button, buttonID)
    local legacyName = BindingCompat.GetLegacyActionButtonName(buttonID)
    if legacyName then
        return CLICK_BINDING_TEMPLATE:format(legacyName)
    end

    return BindingCompat.GetActualClickBinding(button)
end

function BindingCompat.GetNativeActionButtonCommand(buttonID)
    local range = GetRangeInfo(buttonID)
    if not range then
        return nil
    end

    local command = range.prefix .. (buttonID - range.offset)
    if not range.retailOnly then
        return command
    end

    -- Retail-only bars must be capability checked because this file also loads
    -- on TBC.  Prefer the capability probe, with Addon:IsBuild as a fallback in
    -- case a client delays binding-name globals.
    if IsNativeBindingCommandAvailable(command) then
        return command
    end

    if Addon.IsBuild and Addon:IsBuild("retail") then
        return command
    end
end

function BindingCompat.GetActionButtonCommand(buttonID, button)
    return BindingCompat.GetNativeActionButtonCommand(buttonID)
        or BindingCompat.GetFallbackClickBinding(button, buttonID)
end


function BindingCompat.GetActionButtonCommands(buttonID, button)
    local commands = {}
    local seen = {}

    AddUniqueValue(commands, seen, BindingCompat.GetNativeActionButtonCommand(buttonID))
    AddUniqueValue(commands, seen, BindingCompat.GetFallbackClickBinding(button, buttonID))
    AddUniqueValue(commands, seen, BindingCompat.GetActualClickBinding(button))

    return commands
end

function BindingCompat.GetActionButtonBindingKeys(buttonID, button)
    local keys = {}
    local seen = {}
    local commands = BindingCompat.GetActionButtonCommands(buttonID, button)

    for _, command in ipairs(commands) do
        AddBindingKeysForCommand(keys, seen, command)
    end

    return keys
end

function BindingCompat.GetFallbackActionButtonBindingKeys(buttonID, button)
    local keys = {}
    local seen = {}

    -- Fallback-only binding collection. The full binding collection above is used
    -- for Dominos-owned override bindings so native keys can be captured without
    -- executing Blizzard's restricted ACTIONBUTTON snippets against addon frames.
    AddBindingKeysForCommand(keys, seen, BindingCompat.GetFallbackClickBinding(button, buttonID))
    AddBindingKeysForCommand(keys, seen, BindingCompat.GetActualClickBinding(button))

    return keys
end

function BindingCompat.UsesNativeBindingRouting(buttonID)
    return BindingCompat.GetNativeActionButtonCommand(buttonID) ~= nil
end

function BindingCompat.GetOverrideActionButtonCommand(index)
    if type(index) == "number" and index > 0 then
        return "ACTIONBUTTON" .. index
    end
end

function BindingCompat.GetActionButtonIndex(buttonID)
    local range = GetRangeInfo(buttonID)
    if range then
        return buttonID - range.offset
    end

    if type(buttonID) == "number" and buttonID > 0 then
        return ((buttonID - 1) % NUM_ACTIONBAR_BUTTONS) + 1
    end
end

function BindingCompat.GetActionButtonType(buttonID)
    local command = BindingCompat.GetNativeActionButtonCommand(buttonID)
    if not command then
        return nil
    end

    return command:match("^(.-)%d+$")
end

function BindingCompat.ApplyActionButtonContract(button, buttonID)
    if not button then
        return
    end

    local command = BindingCompat.GetActionButtonCommand(buttonID, button)
    local nativeCommand = BindingCompat.GetNativeActionButtonCommand(buttonID)
    local fallbackCommand = BindingCompat.GetFallbackClickBinding(button, buttonID)
    local actualClickCommand = BindingCompat.GetActualClickBinding(button)
    local blizzardAliasName = BindingCompat.GetBlizzardActionButtonAliasName(buttonID)
    local blizzardAliasClickCommand = BindingCompat.GetBlizzardAliasClickBinding(buttonID)
    local buttonType = BindingCompat.GetActionButtonType(buttonID)
    local buttonIndex = BindingCompat.GetActionButtonIndex(buttonID)

    -- Mirror Blizzard's public action-button fields where practical.  These are
    -- intentionally stable button identity values, not the current paged action
    -- slot held in the secure "action" attribute.
    button.commandName = command
    button.bindingAction = command
    button.bindingID = buttonID
    button.dominosButtonID = buttonID
    button.dominosNativeCommandName = nativeCommand
    button.dominosFallbackCommandName = fallbackCommand
    button.dominosActualClickCommandName = actualClickCommand
    button.dominosBlizzardAliasName = blizzardAliasName
    button.dominosBlizzardAliasClickCommandName = blizzardAliasClickCommand

    if buttonType then
        button.buttonType = buttonType
    end

    if buttonIndex then
        button.buttonIndex = buttonIndex
    end

    button:SetAttributeNoHandler("commandName", command)
    button:SetAttributeNoHandler("bindingID", buttonID)
    button:SetAttributeNoHandler("nativeCommandName", nativeCommand)
    button:SetAttributeNoHandler("fallbackCommandName", fallbackCommand)
    button:SetAttributeNoHandler("actualClickCommandName", actualClickCommand)
    button:SetAttributeNoHandler("blizzardAliasName", blizzardAliasName)
    button:SetAttributeNoHandler("blizzardAliasClickCommandName", blizzardAliasClickCommand)
    button:SetAttributeNoHandler("dominosButtonID", buttonID)

    BindingCompat.CreateLegacyActionButtonAlias(button, buttonID)
end

Addon.BindingCompat = BindingCompat
