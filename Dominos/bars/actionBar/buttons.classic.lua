local AddonName, Addon = ...
if Addon:IsBuild("retail") then return end

local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

-- global showgrid event reasons
ActionButtons.ShowGridReasons = {
    -- GAME_EVENT = 1,
    -- SPELLBOOK_SHOWN = 2,
    KEYBOUND_EVENT = 16,
    SHOW_EMPTY_BUTTONS = 32,
    SHOW_EMPTY_BUTTONS_PER_BAR = 64
}

-- states
-- [button] = id
ActionButtons.buttons = {}

-- [reason] = show
ActionButtons.showGridStates = {}

-- dirty secure attributes
ActionButtons.dirtyAttributes = {}

-- we use a traditional event handler so that we can take
-- advantage of unit event registration
ActionButtons:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if type(handler) == "function" then
        handler(self, ...)
    else
        error(("%s is missing a handler for %q"):format("ActionButtons", event))
    end
end)

ActionButtons:RegisterEvent("PLAYER_LOGIN")

-- events
function ActionButtons:PLAYER_LOGIN()
    self:Initialize()

    self:RegisterEvent("CVAR_UPDATE")

    -- addon callbacks
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
    end

    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")
end

-- addon callbacks
function ActionButtons:CVAR_UPDATE(name)
    if name == "lockActionBars" or name == "ActionButtonUseKeyDown" then
        self:TrySetAttribute(name, GetCVarBool(name))
    end
end

function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(SHOW_GRID_REASONS.KEYBOUND_EVENT, true)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(SHOW_GRID_REASONS.KEYBOUND_EVENT, false)
end

function ActionButtons:SHOW_EMPTY_BUTTONS_CHANGED(_, show)
    self:SetShowGrid(SHOW_GRID_REASONS.ADDON_SHOW_EMPTY_BUTTONS, show)
end

-- api
local ActionButton_ClickBefore = [[
    if button == "HOTKEY" then
        if down == control:GetAttribute("ActionButtonUseKeyDown") then
            return "LeftButton"
        end
        return false
    elseif down then
        return false
    end
]]

local function GetActionButtonName(id)
    -- 0
    if id <= 0 then
        return
    -- 1
    elseif id <= 12 then
        return "ActionButton" .. id
    -- 2
    elseif id <= 24 then
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    -- 3
    elseif id <= 36 then
        return "VerticalMultiBar3Button" .. (id - 24)
    -- 4
    elseif id <= 48 then
        return "VerticalMultiBar4Button" .. (id - 36)
    -- 5
    elseif id <= 60 then
        return "HorizontalMultiBar2Button" .. (id - 48)
    -- 6
    elseif id <= 72 then
        return "HorizontalMultiBar1Button" .. (id - 60)
    -- 7+
    else
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    end
end

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name = GetActionButtonName(id)
    local button = _G[name]

    -- a button we're creating
    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "SecureHandlerDragTemplate, ActionBarButtonTemplate")

        Mixin(button, Addon.ActionButton)
        button:OnCreate(id)
        self:WrapScript(button, "OnClick", ActionButton_ClickBefore)
        self:LoadShowGrid(button)

        self.buttons[button] = id
    -- a standard UI button we're reusing
    elseif self.buttons[button] == nil then
        Mixin(button, Addon.ActionButton)

        button:SetID(0)

        if not button.commandName then
            button.commandName = button:GetName():upper()
        end

        button:OnCreate(id)

        self:WrapScript(button, "OnClick", ActionButton_ClickBefore)
        self:LoadShowGrid(button)

        self.buttons[button] = id
    end

    return button
end

function ActionButtons:Initialize()
    -- load show grid states
    self.showGridStates[SHOW_GRID_REASONS.ADDON_SHOW_EMPTY_BUTTONS] = Addon:ShowGrid()

    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        self.showGridStates[SHOW_GRID_REASONS.KEYBOUND_EVENT] = keybound:IsShown()
    end

    self:SetAttribute("lockActionBars", GetCVarBool("lockActionBars"))
    self:SetAttribute("ActionButtonUseKeyDown", GetCVarBool("ActionButtonUseKeyDown"))
end

function ActionButtons:LoadShowGrid(button)
    local states = self.showGridStates

    for _, reason in pairs(SHOW_GRID_REASONS) do
        button:SetShowGrid(reason, states[reason] and true)
    end
end

function ActionButtons:SetShowGrid(reason, show)
    self.showGridStates[reason] = show and true or nil
    self:ForAll("SetShowGrid", reason, show)
end

function ActionButtons:TrySetAttribute(key, value)
    if InCombatLockdown() then
        self.dirtyAttributes[key] = value
        return false
    end

    self:SetAttribute(key, value)
    return true
end

-- collection metamethods
function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        local callback = button[method]
        if type(callback) == "function" then
            callback(button, ...)
        else
            error(("ActionButton %d does not have a method named %q"):format(button.id, method))
        end
    end
end

-- exports
Addon.ActionButtons = ActionButtons