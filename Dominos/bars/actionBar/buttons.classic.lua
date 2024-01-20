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
    self:SetAttribute("lockActionBars", GetCVarBool("lockActionBars"))
    self:SetAttribute("ActionButtonUseKeyDown", GetCVarBool("ActionButtonUseKeyDown"))
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- watch the global showgrid setting
    self:SetShowGrid(Addon:ShowGrid(), self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
    Addon.RegisterCallback(self, "SHOW_EMPTY_BUTTONS_CHANGED")
    Addon.RegisterCallback(self, "LAYOUT_LOADED")

    -- watch for keybound show/hide
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end
end

-- addon callbacks
function ActionButtons:CVAR_UPDATE(name)
    if name == "lockActionBars" or name == "ActionButtonUseKeyDown" or name == "alwaysShowActionBars" then
        self:TrySetAttribute(name, GetCVarBool(name))
    end
end

function ActionButtons:PLAYER_REGEN_ENABLED()
    for k, v in pairs(self.dirtyAttributes) do
        self:SetAttribute(k, v)
        self.dirtyAttributes[k] = nil
    end
end

function ActionButtons:LIBKEYBOUND_ENABLED()
    self:SetShowGrid(true, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:SetShowGrid(false, self.ShowGridReasons.KEYBOUND_EVENT)
end

function ActionButtons:SHOW_EMPTY_BUTTONS_CHANGED(_, show)
    self:SetShowGrid(show, self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
end

function ActionButtons:LAYOUT_LOADED()
    self:SetShowGrid(Addon:ShowGrid(), self.ShowGridReasons.SHOW_EMPTY_BUTTONS)
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
        return "MultiBarRightButton" .. (id - 24)
    -- 4
    elseif id <= 48 then
        return "MultiBarLeftButton" .. (id - 36)
    -- 5
    elseif id <= 60 then
        return "MultiBarBottomRightButton" .. (id - 48)
    -- 6
    elseif id <= 72 then
        return "MultiBarBottomLeftButton" .. (id - 60)
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

        self.buttons[button] = id
    -- a standard UI button we're reusing
    elseif self.buttons[button] == nil then
        Mixin(button, Addon.ActionButton)

        button:SetID(0)
        button.noGrid = true
        button:OnCreate(id)
        self:WrapScript(button, "OnClick", ActionButton_ClickBefore)

        self.buttons[button] = id
    end

    return button
end

function ActionButtons:SetShowGrid(show, reason)
    self:ForAll("SetShowGrid", show, reason)
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

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- exports
Addon.ActionButtons = ActionButtons