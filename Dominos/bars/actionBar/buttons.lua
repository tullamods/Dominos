local ADDON_NAME, Addon = ...
local ActionButtons = Addon:NewModule('ActionButtons', 'AceEvent-3.0')

local ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND = 2048

-- configuration
function ActionButtons:OnInitialize()
    self.buttons = {}

    self.actionButtons = setmetatable({}, {
        __index = function(t, k)
            local v = {}

            t[k] = v

            return v
        end
    })

    self.slotRanges = {}
end

function ActionButtons:OnEnable()
    self:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
    self:RegisterEvent("ACTION_USABLE_CHANGED")
    self:RegisterEvent("ACTIONBAR_HIDEGRID")
    self:RegisterEvent("ACTIONBAR_SHOWGRID")
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("ARCHAEOLOGY_CLOSED", "ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("COMPANION_UPDATE")
    self:RegisterEvent("LOSS_OF_CONTROL_ADDED", "LOSS_OF_CONTROL_UPDATE")
    self:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
    self:RegisterEvent("PET_STABLE_SHOW", "PET_STABLE_UPDATE")
    self:RegisterEvent("PET_STABLE_UPDATE")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")
    self:RegisterEvent("SPELL_UPDATE_ICON")
    self:RegisterEvent("TRADE_SKILL_CLOSE", "ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("TRADE_SKILL_SHOW", "ACTIONBAR_UPDATE_STATE")
    self:RegisterEvent("UNIT_ENTERED_VEHICLE")
    self:RegisterEvent("UNIT_EXITED_VEHICLE", "UNIT_ENTERED_VEHICLE")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

    -- addon callbacks
    local keybound = LibStub("LibKeybound-3.0", true)
    if keybound then
        keybound.RegisterCallback(self, 'LIBKEYBOUND_ENABLED')
        keybound.RegisterCallback(self, 'LIBKEYBOUND_DISABLED')
    end

	-- self:RegisterEvent("PET_BAR_UPDATE")
	-- self:RegisterEvent("PLAYER_ENTER_COMBAT")
	-- self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:RegisterEvent("PLAYER_LEAVE_COMBAT")
	-- self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	-- self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	-- self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
	-- self:RegisterEvent("SPELL_UPDATE_CHARGES")
	-- self:RegisterEvent("START_AUTOREPEAT_SPELL")
	-- self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	-- self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	-- self:RegisterEvent("UNIT_SPELLCAST_SENT")
	-- self:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	-- self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	-- self:RegisterEvent("UPDATE_SUMMONPETS_ACTION")
	-- self:RegisterUnitEvent("UNIT_AURA", "pet")
	-- self:RegisterUnitEvent("UNIT_FLAGS", "pet")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_CLEAR", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_RETICLE_TARGET", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
	-- self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

function ActionButtons:ACTIONBAR_SLOT_CHANGED(_, slot)
    if slot then
        self:ForActions(slot, "OnSlotUpdated")
    else
        self:ForAll("OnSlotUpdated")
    end
end

function ActionButtons:ACTION_RANGE_CHECK_UPDATE(_, action, inRange, checksRange)
    self:ForActions(action, "SetInRange", checksRange, inRange)
end

function ActionButtons:ACTION_USABLE_CHANGED(_, changes)
    for _, change in ipairs(changes) do
        self:ForActions(change.slot, "SetIsUsuable", change.usable, change.noMana)
    end
end

function ActionButtons:COMPANION_UPDATE(_, kind)
    if kind == "MOUNT" then
        self:ForActions("UpdateActive")
    end
end

function ActionButtons:LIBKEYBOUND_ENABLED()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND, true)
end

function ActionButtons:LIBKEYBOUND_DISABLED()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND, false)
end

function ActionButtons:ACTIONBAR_SHOWGRID()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_EVENT, true)
end

function ActionButtons:ACTIONBAR_HIDEGRID()
    self:ForAll("SetShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_EVENT, false)
end

function ActionButtons:ACTIONBAR_UPDATE_COOLDOWN()
    self:ForAll("UpdateCooldown")
end

function ActionButtons:ACTIONBAR_UPDATE_STATE()
    self:ForAll("UpdateActive")
end

function ActionButtons:LOSS_OF_CONTROL_UPDATE(_, unit)
    if unit == "player" then
        self:ForAll("UpdateCooldown")
    end
end

function ActionButtons:SPELL_UPDATE_ICON()
    self:ForAll("UpdateIcon")
end

function ActionButtons:UPDATE_SHAPESHIFT_FORM()
    self:ForAll("UpdateIcon")
end

function ActionButtons:UNIT_ENTERED_VEHICLE(_, unit)
    if unit == "player" then
        self:ForAll("UpdateActive")
    end
end

function ActionButtons:PET_STABLE_UPDATE()
    self:ForAll("OnSlotUpdated")
end

function ActionButtons:SPELL_UPDATE_CHARGES()
    self:ForAll("UpdateCount")
end

function ActionButtons:OnActionButtonActionChanged(button, action, prevAction)
    if prevAction ~= nil then
        self.actionButtons[prevAction][button] = nil
    end

    self.actionButtons[action][button] = action
    self.buttons[button] = action

    C_ActionBar.EnableActionRangeCheck(action, true)
end

local ACTION_BUTTON_NAME_TEMPLATE = ADDON_NAME .. "ActionButton%d"

function ActionButtons:GetOrCreateActionButton(id, ...)
    return self:GetActionButton(id) or self:CreateActionButton(id, ...)
end

function ActionButtons:GetActionButton(id)
    return _G[ACTION_BUTTON_NAME_TEMPLATE:format(id)]
end

function ActionButtons:CreateActionButton(id, parent)
    local name = ACTION_BUTTON_NAME_TEMPLATE:format(id)
    local button = CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, SecureHandlerDragTemplate")

    Addon.ActionButton:Bind(button)
    button:OnCreate(id)

    return button
end

function ActionButtons:ForAll(method, ...)
    for button in pairs(self.buttons) do
        button[method](button, ...)
    end
end

function ActionButtons:ForActions(slot, method, ...)
    local actions = rawget(self.actionButtons, slot)

    if actions ~= nil then
        for button in pairs(actions) do
            button[method](button, ...)
        end
    end
end

-- exports
Addon.ActionButtons = ActionButtons