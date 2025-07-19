--------------------------------------------------------------------------------
-- Action Bar
-- A pool of action bars
--------------------------------------------------------------------------------
local AddonName, Addon = ...

local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local ACTION_BUTTON_COUNT = Addon.ACTION_BUTTON_COUNT

local ActionBar = Addon:CreateClass('Frame', Addon.ButtonBar)

ActionBar.ButtonProps = {
    'BindingText',
    'Counts',
    'EmptyButtons',
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

-- Metatable magic. Basically this says, "create a new table for this index"
-- I do this so that I only create page tables for classes the user is actually
-- playing
ActionBar.defaultOffsets = {
    __index = function(t, i)
        t[i] = {}
        return t[i]
    end
}

-- Metatable magic.  Basically this says, 'create a new table for this index,
-- with these defaults. I do this so that I only create page tables for classes
-- the user is actually playing
ActionBar.mainbarOffsets = {
    __index = function(t, i)
        local pages = {
            page2 = 1,
            page3 = 2,
            page4 = 3,
            page5 = 4,
            page6 = 5
        }

        if i == 'DRUID' then
            pages.cat = 6
            pages.bear = 8
            pages.moonkin = 9
            pages.tree = 7
        elseif i == 'EVOKER' then
            pages.soar = 7
        elseif i == 'ROGUE' then
            pages.stealth = 6
            pages.shadowdance = 6
        elseif i == 'WARRIOR' and not Addon:IsBuild('retail') then
            pages.battle = 6
            pages.defensive = 7
            pages.berserker = 8
        elseif i == 'PRIEST' and not Addon:IsBuild('retail') then
            pages.shadowform = 6
        end

        if Addon:IsBuild("retail") then
            pages.dragonriding = 10
        end

        t[i] = pages
        return pages
    end
}

ActionBar:Extend('OnLoadSettings', function(self)
    if self.id == 1 then
        setmetatable(self.sets.pages, self.mainbarOffsets)
    else
        setmetatable(self.sets.pages, self.defaultOffsets)
    end

    self.pages = self.sets.pages[self.class]
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

-- TODO: change the position code to be based more on the number of action bars
function ActionBar:GetDefaults()
    return {
        point = 'BOTTOM',
        x = 0,
        y = 14 + (ActionButton1:GetHeight() + 4) * (self.id - 1),
        pages = {},
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
    return floor(ACTION_BUTTON_COUNT / Addon:NumBars())
end

function ActionBar:AcquireButton(index)
    local id = index + (self.id - 1) * self:MaxLength()

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
    button:SetAttribute("action", button:GetAttribute("index") + (self:GetAttribute("actionOffset") or 0))
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
function ActionBar:SetOffset(stateId, page)
    self.pages[stateId] = page
    self:UpdateStateDriver()
end

function ActionBar:GetOffset(stateId)
    return self.pages[stateId]
end


local function getMacroCondition(state)
    local condition = state.value
    if type(condition) == "function" then
        return condition(state)
    end
    return condition
end

function ActionBar:UpdateStateDriver()
    local conditions = {}
    local numBars = Addon:NumBars()

    for _, stateType in ipairs(self.statePrecedence) do
        for _, state in Addon.BarStates:GetAll(stateType) do
            local offset = self.pages[state.id]
            if offset then
                local condition = getMacroCondition(state)
                if condition then
                    conditions[#conditions + 1] = condition .. Wrap(self.id + offset, numBars)
                end
            end
        end
    end

    if #conditions > 0 then
        conditions[#conditions + 1] = self.id
        RegisterStateDriver(self, 'page', table.concat(conditions, ';'))
    else
        UnregisterStateDriver(self, 'page')
        self:SetAttribute('state-page', self.id)
    end
end

function ActionBar:LoadStateController()
    self:SetAttribute('barLength', self:MaxLength())
    self:SetAttribute('overrideBarLength', NUM_ACTIONBAR_BUTTONS)

    self:SetAttribute('_onstate-overridebar', [[ self:RunAttribute('UpdateOffset') ]])
    self:SetAttribute('_onstate-overridepage', [[ self:RunAttribute('UpdateOffset') ]])
    self:SetAttribute('_onstate-page', [[ self:RunAttribute('UpdateOffset') ]])

    self:SetAttribute('UpdateOffset', [[
        local offset = 0

        local overridePage = self:GetAttribute('state-overridepage') or 0
        if overridePage > 0 and self:GetAttribute('state-overridebar') then
            offset = (overridePage - 1) * self:GetAttribute('overrideBarLength')
        else
            local page = self:GetAttribute('state-page') or 1

            offset = (page - 1) * self:GetAttribute('barLength')

            -- skip action bar 12 slots (not really usable)
            if offset >= 132 then
                offset = offset + 12
            end
        end

        self:SetAttribute('actionOffset', offset)
        control:ChildUpdate('offset', offset)
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

function ActionBar:GetCalculatedFlyoutDirection()
    local width, height = self:GetSize()
    local _, relPoint = self:GetRelativePosition()

    if width < height then
        if relPoint:match('RIGHT') then
            return 'LEFT'
        end

        return 'RIGHT'
    end

    if relPoint and relPoint:match('TOP') then
        return 'DOWN'
    end
    return 'UP'
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
