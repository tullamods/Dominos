--------------------------------------------------------------------------------
-- Action Bar
-- A pool of action bars
--------------------------------------------------------------------------------
local AddonName, Addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local ActionBar = Addon:CreateClass('Frame', Addon.ButtonBar)

ActionBar.ButtonProps = {
    'EmptyButtons',
    'BindingText',
    'Counts',
    'EquippedItemBorders',
    'MacroText',
}

ActionBar.class = UnitClassBase('player')

-- the order in which bar state groups are evaluated
ActionBar.statePrecedence = {
    'modifier',
    'page',
    'class',
    'race',
    'target'
}

-- paging: sets.paging[class][stateId] = address offset. class tables are made
-- on first use, so only for classes actually played
ActionBar.defaultPaging = {
    __index = function(t, class)
        t[class] = {}
        return t[class]
    end
}

-- bar 1's defaults, as Blizzard action pages
local function getMainBarPages(class)
    local pages = { page2 = 2, page3 = 3, page4 = 4, page5 = 5, page6 = 6 }

    if class == 'DRUID' then
        pages.cat = 7
        pages.tree = 8
        pages.bear = 9
        pages.moonkin = 10
    elseif class == 'EVOKER' then
        pages.soar = 8
    elseif class == 'ROGUE' then
        pages.stealth = 7
        pages.shadowdance = 7
    elseif class == 'WARRIOR' then
        if Addon:IsGameType('forever', 'vanilla', 'tbc', 'wrath', 'cata') then
            pages.battle = 7
            pages.defensive = 8
            pages.berserker = 9
        elseif Addon:IsGameType('mists') then
            pages.defensive = 8
            pages.berserker = 9
        end
    elseif class == 'PRIEST' and not Addon:IsGameType('standard') then
        pages.shadowform = 7
    end

    if Addon:IsGameType('standard') then
        pages.dragonriding = 11
    end

    return pages
end

ActionBar.mainBarPaging = {
    __index = function(t, class)
        local paging = {}

        for stateId, page in pairs(getMainBarPages(class)) do
            paging[stateId] = Addon.AddressMap:GetAddress((page - 1) * NUM_ACTIONBAR_BUTTONS + 1) - 1
        end

        t[class] = paging
        return paging
    end
}

ActionBar:Extend('OnLoadSettings', function(self)
    local sets = self.sets

    -- placeholder bars from migrations only have hidden set
    sets.paging = sets.paging or {}
    sets.numButtons = sets.numButtons or self:MaxLength()

    setmetatable(sets.paging, self.id == 1 and self.mainBarPaging or self.defaultPaging)
    self.paging = sets.paging[self.class]
end)

ActionBar:Extend('OnAcquire', function(self)
    self:SetAttribute("checkselfcast", true)
    self:SetAttribute("checkfocuscast", true)
    self:SetAttribute("checkmouseovercast", true)

    self:LoadStateController()
    self:UpdateStateDriver()
    self:SetUnit(self:GetUnit())
    self:SetRightClickUnit(self:GetRightClickUnit())
    self:SetShowEmptyButtons(self:ShowingEmptyButtons())
    self:UpdateTransparent(true)
    self:UpdateFlyoutDirection()
end)

ActionBar:Extend('OnRelease', function(self)
    UnregisterStateDriver(self, 'page')
end)

-- TODO: change the position code to be based more on the number of action bars
function ActionBar:GetDefaults()
    return {
        point = 'BOTTOM',
        x = 0,
        y = 14 + (ActionButton1:GetHeight() + 4) * (self.id - 1),
        paging = {},
        spacing = 2,
        padW = 2,
        padH = 2,
        numButtons = self:MaxLength(),
        showEmptyButtons = false,
        unit = "none",
        rightClickUnit = "none",
        displayLayer = 'LOW'
    }
end

function ActionBar:GetDisplayName()
    return L.ActionBarDisplayName:format(self.id)
end

-- returns the maximum possible size for a given bar
function ActionBar:MaxLength()
    return Addon:GetActionBarLength()
end

-- named after their default address's slot, so Blizzard keybinds follow them.
-- ids skip page 12 (totems), which bars never rest on
function ActionBar:AcquireButton(index)
    local slot = Addon.AddressMap:GetSlot(self:GetBaseOffset() + index)
    local id = slot <= 132 and slot or slot - 12

    local button = Addon.ActionButtons:GetOrCreateActionButton(id, self)

    button:SetAttributeNoHandler('index', index)
    button:SetAttributeNoHandler("displayName", L.ActionBarButtonDisplayName:format(self.id, index))

    return button
end

function ActionBar:ReleaseButton(button)
    button:SetAttribute('statehidden', true)
    button:Hide()
end

function ActionBar:OnAttachButton(button)
    self:UpdateButtonActions(button)
    button:SetAttribute('action', button:GetAttribute('action-' .. self:GetState()) or button:GetAttribute('action-base'))
    button:SetFlyoutDirectionInsecure(self:GetFlyoutDirection())

    for _, prop in pairs(self.ButtonProps) do
        button['SetShow' .. prop](button, self['Showing' .. prop](self))
    end

    button:SetShowCooldowns(self:GetAlpha() > 0)
    button:SetAttributeNoHandler("statehidden", (button:GetAttribute("index") > self:NumButtons()) or nil)
    button:UpdateShown()

    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Register(button)
end

function ActionBar:OnDetachButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Unregister(button)
end

-- sizing
function ActionBar:ReloadButtons()
    local oldNumButtons = #self.buttons
    for i = 1, oldNumButtons do
        self:DetachButton(i)
    end

    local newNumButtons = self:MaxLength()
    for i = 1, newNumButtons do
        self:AttachButton(i)
    end

    self:Layout()
end

function ActionBar:UpdateNumButtons()
    local numVisible = self:NumButtons()

    for i, button in pairs(self.buttons) do
        if i > numVisible then
            if not button:GetAttribute("statehidden") then
                button:SetAttribute("statehidden", true)
                button:Hide()
            end
        elseif button:GetAttribute("statehidden") then
            button:SetAttribute("statehidden", nil)
            button:UpdateShown()
        end
    end

    self:Layout()
end

-- paging
function ActionBar:SetPageOffset(stateId, offset)
    self.paging[stateId] = offset
    self:ApplyPaging()
end

function ActionBar:GetPageOffset(stateId)
    return self.paging[stateId]
end

function ActionBar:GetBaseOffset()
    return (self.id - 1) * self:MaxLength()
end

local function getMacroCondition(state)
    local condition = state.value
    if type(condition) == "function" then
        return condition(state)
    end
    return condition
end

-- the state the bar's buttons should show, as secure code picks it
function ActionBar:GetState()
    local overridePage = self:GetAttribute('state-overridepage') or 0

    if self:GetAttribute('state-overridebar') and overridePage > 0 then
        return 'override'
    end

    return self:GetAttribute('state-page') or 'base'
end

-- every action a button can show: base, each paged state, and override
function ActionBar:UpdateButtonActions(button)
    local index = button:GetAttribute('index')
    local AddressMap = Addon.AddressMap

    button:SetAttributeNoHandler('action-base', AddressMap:GetSlot(self:GetBaseOffset() + index))

    for stateId, offset in pairs(self.paging) do
        button:SetAttributeNoHandler('action-' .. stateId, AddressMap:GetSlot(offset + index))
    end

    -- normally written by secure code when the override page changes
    local overridePage = self:GetAttribute('state-overridepage') or 0
    if overridePage > 0 then
        local id = index <= NUM_ACTIONBAR_BUTTONS and index + (overridePage - 1) * NUM_ACTIONBAR_BUTTONS or 0
        button:SetAttributeNoHandler('action-override', id)
    end
end

-- returns the macro conditional for the state-page driver, or nil if no paged
-- state applies
function ActionBar:GetStateDriverConditional()
    local parts = {}

    for _, stateType in ipairs(self.statePrecedence) do
        for _, state in Addon.BarStates:GetAll(stateType) do
            local condition = self.paging[state.id] and getMacroCondition(state)

            if condition then
                tinsert(parts, condition)
                tinsert(parts, state.id)
                tinsert(parts, ';')
            end
        end
    end

    if #parts > 0 then
        tinsert(parts, 'base')
        return table.concat(parts)
    end
end

-- builds the paging driver. its conditions follow things like the form list, so
-- this is all that changes when those do. buttons' actions are ApplyPaging's.
-- secure, so waits for combat to end
function ActionBar:UpdateStateDriver()
    if InCombatLockdown() then
        self.stateDriverPending = true
        return
    end

    self.stateDriverPending = nil

    local conditional = self:GetStateDriverConditional()

    if conditional then
        RegisterStateDriver(self, 'page', conditional)
    else
        UnregisterStateDriver(self, 'page')

        -- fires _onstate-page, which applies it
        self:SetAttribute('state-page', 'base')
    end
end

-- after the paging settings change: every button's actions, then the driver
function ActionBar:ApplyPaging()
    if InCombatLockdown() then
        self.stateDriverPending = true
        return
    end

    for _, button in pairs(self.buttons) do
        self:UpdateButtonActions(button)
    end

    self:UpdateStateDriver()

    -- the state may not change, but the actions did
    self:Execute([[ self:RunAttribute('UpdateState') ]])
end

function ActionBar:LoadStateController()
    -- restricted code can't read globals
    self:Execute(('PageLength = %d'):format(NUM_ACTIONBAR_BUTTONS))

    self:SetAttribute('_onstate-page', [[ self:RunAttribute('UpdateState') ]])
    self:SetAttribute('_onstate-overridebar', [[ self:RunAttribute('UpdateState') ]])

    -- buttons write their override action before the bar switches to it
    self:SetAttribute('_onstate-overridepage', [[
        local page = self:GetAttribute('state-overridepage') or 0
        if page > 0 then
            control:ChildUpdate('overrideoffset', (page - 1) * PageLength)
        end

        self:RunAttribute('UpdateState')
    ]])

    -- override, then paging, then base
    self:SetAttribute('UpdateState', [[
        local state = self:GetAttribute('state-page') or 'base'

        if self:GetAttribute('state-overridebar') and (self:GetAttribute('state-overridepage') or 0) > 0 then
            state = 'override'
        end

        control:ChildUpdate('state', state)
    ]])

    self:UpdateOverrideBar()
end

function ActionBar:UpdateOverrideBar()
    self:SetAttribute('state-overridebar', self:IsOverrideBar())
end

function ActionBar:IsOverrideBar()
    -- TODO: make overrideBar a property of the bar itself instead of a global
    -- setting
    return Addon.db.profile.possessBar == self.id
end

-- unit
function ActionBar:SetUnit(unit)
    unit = unit or 'none'

    if unit == 'none' then
        self:SetAttribute('*unit*', nil)
    else
        self:SetAttribute('*unit*', unit)
    end

    self.sets.unit = unit
end

function ActionBar:GetUnit()
    return self.sets.unit or 'none'
end

-- right click unit
function ActionBar:SetRightClickUnit(unit)
    unit = unit or 'none'

    if unit == 'none' then
        self:SetAttribute('*unit2', nil)
    else
        self:SetAttribute('*unit2', unit)
    end

    self.sets.rightClickUnit = unit
end

function ActionBar:GetRightClickUnit()
    local unit = self.sets.rightClickUnit

    if unit ~= "none" then
        return unit
    end

    return Addon:GetRightClickUnit() or "none"
end

-- opacity
function ActionBar:OnSetAlpha(_alpha)
    self:UpdateTransparent()
end

function ActionBar:UpdateTransparent(force)
    local isTransparent = self:GetAlpha() == 0

    if (self.transparent ~= isTransparent) or force then
        self.transparent = isTransparent
        self:ForButtons('SetShowCooldowns', not isTransparent)
    end
end

-- flyout direction calculations
function ActionBar:SetFlyoutDirection(direction)
    local oldDirection = self.sets.flyoutDirection or 'auto'
    local newDirection = direction or 'auto'

    if oldDirection ~= newDirection then
        self.sets.flyoutDirection = newDirection
        self:UpdateFlyoutDirection()
    end
end

function ActionBar:GetFlyoutDirection()
    local direction = self.sets.flyoutDirection or 'auto'

    if direction == 'auto' then
        return self:GetCalculatedFlyoutDirection()
    end

    return direction
end

function ActionBar:UpdateFlyoutDirection()
    self:ForButtons('SetFlyoutDirectionInsecure', self:GetFlyoutDirection())
end

ActionBar:Extend("Layout", ActionBar.UpdateFlyoutDirection)
ActionBar:Extend("Stick", ActionBar.UpdateFlyoutDirection)

-- button property visibility toggles
for _, prop in pairs(ActionBar.ButtonProps) do
    local setterName = 'SetShow' .. prop
    local getterName = 'Showing' .. prop
    local settingKey = 'show' .. prop

    ActionBar[setterName] = function(self, show, ...)
        show = show and true

        if show == Addon.db.profile[settingKey] then
            self.sets[settingKey] = nil
        else
            self.sets[settingKey] = show
        end

        self:ForButtons(setterName, show, ...)
    end

    ActionBar[getterName] = function(self)
        local result = self.sets[settingKey]
        if result == nil then
            result = Addon.db.profile[settingKey]
        end
        return result
    end
end

-- exports
Addon.ActionBar = ActionBar
