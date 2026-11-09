-- The action bars module: hides Blizzard's bars, keeps a pool of Dominos
-- action bars sized to the profile, answers what's at an address, and names
-- their key bindings

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local ActionBarsModule = Addon:NewModule('ActionBars', 'AceEvent-3.0')

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

local function hideBlizzardActionBars()
    -- the main bar keeps its events and buttons
    local bars = {
        'MainActionBar',
        'MultiBarBottomLeft',
        'MultiBarBottomRight',
        'MultiBarLeft',
        'MultiBarRight',
        'MultiBar5',
        'MultiBar6',
        'MultiBar7',
    }

    -- classic
    if MainMenuBar then
        tinsert(bars, 'MainMenuBar')
        tinsert(bars, 'MainMenuBarArtFrame')
    end

    for _, name in ipairs(bars) do
        local bar = _G[name]
        local isMainBar = name == 'MainActionBar'

        if bar then
            if not isMainBar then
                bar:UnregisterAllEvents()
            end

            (bar.HideBase or bar.Hide)(bar)
            bar:SetParent(Addon.ShadowUIParent)

            if type(bar.actionButtons) == 'table' then
                for _, button in pairs(bar.actionButtons) do
                    button:UnregisterAllEvents()
                    button:SetAttributeNoHandler('statehidden', true)
                    button:Hide()
                end

                if not isMainBar then
                    wipe(bar.actionButtons)
                end
            end
        else
            Addon:Printf('Could not find frame %q', name)
        end
    end
end

-- while the override or pet battle UI is shown, gives its buttons priority
-- bindings: the keys bound to Blizzard's action buttons 1-6
--
-- TODO: take the bindings from the Dominos override bar instead, and show those
-- on the override and pet battle UI
local function setUpOverrideBindings()
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

    -- initial state. Settings are applied on LAYOUT_LOADED
    Binder:SetAttribute("overrideui", OverrideActionBarButton1:IsVisible() and 1 or 0)
    RegisterAttributeDriver(Binder, "petbattleui", "[petbattle]1;0")

    function Binder:USE_OVERRRIDE_UI_CHANGED(_, enabled)
        self:SetAttribute("useoverrideui", enabled and 1 or 0)
    end

    function Binder:LAYOUT_LOADED()
        self:SetAttribute("useoverrideui", Addon:UsingOverrideUI() and 1 or 0)
    end

    Addon.RegisterCallback(Binder, "USE_OVERRRIDE_UI_CHANGED")
    Addon.RegisterCallback(Binder, "LAYOUT_LOADED")
end

-- the buttons in Bindings.xml. their slots are their ids
local BOUND_BUTTON_IDS = { { 13, 24 }, { 73, 132 } }

-- names those buttons in the key bindings UI, by where they are now
local function updateBindingNames()
    for _, ids in ipairs(BOUND_BUTTON_IDS) do
        for id = ids[1], ids[2] do
            local name = Addon:GetButtonName(Addon.AddressMap:GetAddress(id))

            _G[('BINDING_NAME_CLICK %sActionButton%d:HOTKEY'):format(AddonName, id)] = name
        end
    end
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

-- once per profile, for bars the migration couldn't renumber
local function showMigrationNotice()
    local ab = Addon.db.profile.ab

    if ab.migrationNotice then
        Addon:Print(L.ActionBarsMigrated)
        ab.migrationNotice = nil
    end
end

function ActionBarsModule:OnFirstLoad()
    hideBlizzardActionBars()

    Addon.ActionButtons:Initialize()

    if Addon:IsGameType('standard', 'forever') then
        setUpOverrideBindings()
    end
end

function ActionBarsModule:Load()
    self:SetBarCount(Addon:NumBars())
    updateBindingNames()
    showMigrationNotice()

    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    Addon.RegisterCallback(self, "ACTIONBAR_COUNT_UPDATED")
end

function ActionBarsModule:Unload()
    self:UnregisterAllEvents()
    self:ForActive('Free')
    self.active = nil
    self.length = nil
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function ActionBarsModule:ACTIONBAR_COUNT_UPDATED(_, count)
    self:SetBarCount(count)
    updateBindingNames()

    -- bars were added, removed or recreated
    Addon.callbacks:Fire('ACTIONBARS_UPDATED')
end

-- form macro conditions depend on form order. in combat, bars wait
function ActionBarsModule:UPDATE_SHAPESHIFT_FORMS()
    self:ForActive('UpdateStateDriver')
end

-- rebuild bars that changed in combat
function ActionBarsModule:PLAYER_REGEN_ENABLED()
    if self.active then
        for _, bar in pairs(self.active) do
            if bar.stateDriverPending then
                bar:UpdateStateDriver()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Bars
--------------------------------------------------------------------------------

-- only adds or removes bars, unless the length changed, which changes every
-- bar's buttons
function ActionBarsModule:SetBarCount(count)
    local length = Addon:GetActionBarLength()

    if length ~= self.length then
        self:ForActive('Free')
        self.active = nil
        self.length = length
    end

    local active = self.active or {}

    for i = #active, count + 1, -1 do
        active[i]:Free()
        active[i] = nil
    end

    for i = #active + 1, count do
        active[i] = Addon.ActionBar:New(i)
    end

    self.active = active
end

function ActionBarsModule:ForActive(method, ...)
    if self.active then
        for _, bar in pairs(self.active) do
            bar:CallMethod(method, ...)
        end
    end
end

--------------------------------------------------------------------------------
-- Address Lookups
--------------------------------------------------------------------------------

-- the bar whose base covers an address, and the button's place in it
function Addon:GetBarAt(address)
    for _, bar in ipairs(ActionBarsModule.active or {}) do
        local index = address - bar:GetBaseOffset()

        if index >= 1 and index <= bar:MaxLength() then
            return bar, index
        end
    end
end

-- { bar, state } for each loaded state that pages a bar here, or nil
function Addon:GetPagingBars(address)
    local paging

    for _, bar in ipairs(ActionBarsModule.active or {}) do
        for _, stateType in ipairs(self.ActionBar.statePrecedence) do
            for _, state in self.BarStates:GetAll(stateType) do
                local offset = bar.paging[state.id]

                if offset and address > offset and address <= offset + bar:NumButtons() then
                    paging = paging or {}
                    tinsert(paging, { bar = bar, state = state })
                end
            end
        end
    end

    return paging
end

-- "Action Bar 9 Button 1", or "Bonus Bar 1 Slot 1" when no bar is there
function Addon:GetButtonName(address)
    local bar, index = self:GetBarAt(address)

    if bar then
        return L.BarButton:format(bar:GetDisplayName(), index)
    end

    return self.AddressMap:GetAddressName(address)
end
