local AddonName, Addon = ...
local ActionButtons = CreateFrame('Frame', nil, nil, 'SecureHandlerBaseTemplate')

-- constants
local ACTION_BUTTON_NAME_TEMPLATE = AddonName .. "ActionButton%d"

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- global showgrid event reasons
ActionButtons.ShowGridReasons = {
    -- GAME_EVENT = 1,
    -- SPELLBOOK_SHOWN = 2,
    KEYBOUND_EVENT = 16,
    SHOW_EMPTY_BUTTONS_PER_BAR = 32
}

-- states
-- [button] = id
ActionButtons.buttons = {}

-- dirty secure attributes
ActionButtons.dirtyAttributes = {}

--------------------------------------------------------------------------------
-- Event and Callback Handling
--------------------------------------------------------------------------------

function ActionButtons:Initialize()
    self:SetScript("OnEvent", function(f, event, ...) f[event](f, ...) end)

    -- load initial state
    self:SetAttribute("ActionButtonUseKeyDown", GetCVarBool("ActionButtonUseKeyDown"))

    -- watch game events
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- watch for keybound show/hide
    local keybound = LibStub("LibKeyBound-1.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
        self:SetShowGrid(keybound:IsShown(), self.ShowGridReasons.KEYBOUND_EVENT)
    end

    self.Initialize = nil
end

-- addon callbacks
function ActionButtons:CVAR_UPDATE(name)
    if name == "ActionButtonUseKeyDown" then
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

function ActionButtons:TrySetAttribute(key, value)
    if InCombatLockdown() then
        self.dirtyAttributes[key] = value
        return false
    end

    self:SetAttribute(key, value)
    return true
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

function ActionButtons:SetShowGrid(show, reason, force)
    self:ForAll("SetShowGridInsecure", show, reason, force)
end

--------------------------------------------------------------------------------
-- Action Button Constrution
--------------------------------------------------------------------------------

local ActionButton_ClickBefore = [[
    if button == "HOTKEY" then
        if down == control:GetAttribute("ActionButtonUseKeyDown") then
            return "LeftButton"
        end
        return false
    end

    if down then
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
        return "MultiBarRightButton" .. (id - 24), true
    -- 4
    elseif id <= 48 then
        return "MultiBarLeftButton" .. (id - 36), true
    -- 5
    elseif id <= 60 then
        return "MultiBarBottomRightButton" .. (id - 48), true
    -- 6
    elseif id <= 72 then
        return "MultiBarBottomLeftButton" .. (id - 60), true
    -- 7+
    elseif id <= 168 then
        return ACTION_BUTTON_NAME_TEMPLATE:format(id)
    end
end

function ActionButtons:GetOrCreateActionButton(id, parent)
    local name, noGrid = GetActionButtonName(id)
    local button = _G[name]
    local new = false

    -- a button we're creating
    if button == nil then
        button = CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate")
        Mixin(button, Addon.ActionButton)

        new = true
    -- a standard UI button we're reusing
    elseif self.buttons[button] == nil then
        Mixin(button, Addon.ActionButton)

        button:SetID(0)

        if noGrid then
            button.noGrid = true
        end

        new = true
    end

    if new then
        button:OnCreate(id)
        self:WrapScript(button, "OnClick", ActionButton_ClickBefore)
        self.buttons[button] = id
    end

    return button
end

--------------------------------------------------------------------------------
-- Collection Methods
--------------------------------------------------------------------------------

function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        button[method](button, ...)
    end
end

function ActionButtons:GetAll()
    return pairs(self.buttons)
end

-- startup and export
ActionButtons:Initialize()

Addon.ActionButtons = ActionButtons