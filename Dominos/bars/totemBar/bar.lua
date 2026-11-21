if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem Bar
--
-- This is mostly a 1:1 reimplementation of Blizzard's totem bar. Reusing
-- Blizzard's is a bit problematic, as it tends to try and reparent itself in
-- combat (and is secure, so we can't really move it back). It also is fairly
-- intertwined, so I couldn't simply move the buttons from it onto my own bar
-- without issue.
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local SpellButton = Addon.TotemSpellButton
local TotemArt = Addon.TotemArt
local TotemFlyout = Addon.TotemFlyout

-- same page math as blizzard's CalculateAction
local TOTEM_ACTION_OFFSET = (C_ActionBar.GetMultiCastBarIndex() - 1) * NUM_ACTIONBAR_BUTTONS
local NUM_TOTEMS = NUM_MULTI_CAST_BUTTONS_PER_PAGE
local NUM_TOTEM_SETS = NUM_MULTI_CAST_PAGES

-- button order kind, next to SpellButton.SUMMON and RECALL
local TOTEM = 'Totem'

local BAR_IDS = { 'totem', 'totem2', 'totem3' }
local DEFAULT_BAR_OFFSET = 40

--------------------------------------------------------------------------------
-- Totem button setup
--------------------------------------------------------------------------------

-- also blizzard's MULTICASTACTIONBUTTON number
local function getTotemButtonNumber(buttonInfo)
    return (buttonInfo.totemSet - 1) * NUM_TOTEMS + buttonInfo.totemIndex
end

-- the ring replaces the template's normal texture
local function addTotemSlotArt(button, totemIndex)
    if button.hasTotemSlotArt then
        return
    end

    button.hasTotemSlotArt = true

    button.NormalTexture:SetAlpha(0)

    -- only Forever's template has it
    if button.SlotArt then
        button.SlotArt:Hide()
    end

    local slot = SHAMAN_TOTEM_PRIORITIES[totemIndex]

    local background = button.SlotBackground
    background:ClearAllPoints()
    background:SetAllPoints()
    background:SetAlpha(1)
    background:Show()
    TotemArt:SetEmptySlotArt(background, slot)

    TotemArt:AddSlotRing(button, slot)

    -- SetShowBindingText(false) reparents HotKey under the ring
    button.HotKey:SetDrawLayer('OVERLAY', 7)
end

--------------------------------------------------------------------------------
-- Bar
--------------------------------------------------------------------------------

local TotemBar = Addon:CreateClass('Frame', Addon.ButtonBar)

-- no fixedTotemSet is the paged bar
function TotemBar:New(fixedTotemSet)
    local bar = TotemBar.proto.New(self, BAR_IDS[fixedTotemSet or 1])

    bar.fixedTotemSet = fixedTotemSet
    bar:Update()

    return bar
end

function TotemBar:IsPaged()
    return self.fixedTotemSet == nil
end

function TotemBar:GetDisplayName()
    if self:IsPaged() then
        return L.TotemBarDisplayName
    end

    return C_Spell.GetSpellName(TOTEM_MULTI_CAST_SUMMON_SPELLS[self.fixedTotemSet])
        or L.TotemSetRegion:format(self.fixedTotemSet)
end

-- runs before New sets fixedTotemSet, so this goes by id
function TotemBar:GetDefaults()
    local barIndex = tIndexOf(BAR_IDS, self.id)

    return {
        point = 'CENTER',
        y = (1 - barIndex) * DEFAULT_BAR_OFFSET,
        spacing = 2
    }
end

function TotemBar:NumButtons()
    return self.buttonOrder and #self.buttonOrder or 0
end

--------------------------------------------------------------------------------
-- Totem sets
--------------------------------------------------------------------------------

-- the set the bar is showing
function TotemBar:GetTotemSet()
    if self.fixedTotemSet then
        return self.fixedTotemSet
    end

    return Clamp(self.sets.totemSet or 1, 1, NUM_TOTEM_SETS)
end

function TotemBar:GetTotemAction(totemIndex, totemSet)
    local totemSlot = SHAMAN_TOTEM_PRIORITIES[totemIndex]

    return TOTEM_ACTION_OFFSET + (totemSet - 1) * NUM_TOTEMS + totemSlot
end

local bar_SetTotemSet = [[
    local totemSet = ...

    self:SetAttribute('totemset', totemSet)
    self:ChildUpdate('state', TotemSetStates[totemSet])
    self:CallMethod('OnTotemSetChanged', totemSet)
]]

local bar_CycleTotemSet = [[
    local step = ... or 1
    local current = self:GetAttribute('totemset') or 1

    self:RunAttribute('SetTotemSet', (current - 1 + step) % TotemSetCount + 1)
]]

local summonButton_OnMouseWheel = [[
    control:RunAttribute('CycleTotemSet', offset)
]]

local summonButton_OnClick = [[
    if button == 'RightButton' then
        if not down then
            control:RunAttribute('CycleTotemSet', 1)
        end

        return false
    end
]]

TotemBar:Extend('OnCreate', function(self)
    self:Execute(('TotemSetCount = %d'):format(NUM_TOTEM_SETS))
    self:Execute(('TotemSetStates = newtable(%q, %q, %q)'):format(unpack(SpellButton.GetTotemSetStates())))
    self:SetAttribute('SetTotemSet', bar_SetTotemSet)
    self:SetAttribute('CycleTotemSet', bar_CycleTotemSet)

    self.flyout = TotemFlyout:Create(self)
end)

function TotemBar:OnTotemSetChanged(totemSet)
    self.sets.totemSet = totemSet
    self:ForSpellButtons('UpdateSpell')
end

--------------------------------------------------------------------------------
-- Button list
-- buttonOrder is a list of buttonInfo:
-- { kind = SUMMON | RECALL | TOTEM, totemSet = n, totemIndex = n }
-- the set names the button. the paged bar uses set 1's
--------------------------------------------------------------------------------

function TotemBar:ShowingTotems()
    return not self.sets.hideTotems
end

function TotemBar:SetShowTotems(show)
    self.sets.hideTotems = not show or nil
    self:Update()
end

function TotemBar:ShowingRecall()
    return not self.sets.hideRecall
end

function TotemBar:SetShowRecall(show)
    self.sets.hideRecall = not show or nil
    self:Update()
end

-- returns true if the order changed
function TotemBar:UpdateButtonOrder()
    local showTotems = self:ShowingTotems()
    local showRecall = self:ShowingRecall()

    if self.buttonOrder
        and showTotems == self.showTotems
        and showRecall == self.showRecall
    then
        return false
    end

    local totemSet = self.fixedTotemSet or 1
    local buttonOrder = {}

    buttonOrder[#buttonOrder + 1] = { kind = SpellButton.SUMMON, totemSet = totemSet }

    if showTotems then
        for totemIndex = 1, NUM_TOTEMS do
            buttonOrder[#buttonOrder + 1] = { kind = TOTEM, totemSet = totemSet, totemIndex = totemIndex }
        end
    end

    if showRecall then
        buttonOrder[#buttonOrder + 1] = { kind = SpellButton.RECALL, totemSet = totemSet }
    end

    self.buttonOrder = buttonOrder
    self.showTotems = showTotems
    self.showRecall = showRecall

    return true
end

TotemBar:Extend('OnRelease', function(self)
    self.buttonOrder = nil
end)

-- protected buttons, so not in combat. PLAYER_REGEN_ENABLED runs it again
function TotemBar:Update()
    if InCombatLockdown() then
        return
    end

    if self:UpdateButtonOrder() then
        self:ReloadButtons()
    end

    -- the paged bar reapplies its set, which also syncs newly attached buttons
    if self:IsPaged() then
        self:Execute(('self:RunAttribute("SetTotemSet", %d)'):format(self:GetTotemSet()))
    else
        self:ForSpellButtons('UpdateSpell')
    end
end

function TotemBar:ForSpellButtons(method)
    for _, button in pairs(self.buttons) do
        if button.isSpell then
            button[method](button)
        end
    end
end

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

function TotemBar:AcquireButton(index)
    local buttonInfo = self.buttonOrder[index]

    if buttonInfo.kind ~= TOTEM then
        return SpellButton:Acquire(buttonInfo.kind, buttonInfo.totemSet)
    end

    local totemIndex = buttonInfo.totemIndex
    local button = Addon.ActionButtons:GetOrCreateActionButton(0, self, ('%sTotemButton%d'):format(AddonName, getTotemButtonNumber(buttonInfo)))

    button:SetAttributeNoHandler('index', index)

    local displayName = _G['BINDING_NAME_MULTICASTACTIONBUTTON' .. totemIndex] or ('%s %d'):format(L.TotemBarDisplayName, totemIndex)

    if not self:IsPaged() then
        local summonSpellName = C_Spell.GetSpellName(TOTEM_MULTI_CAST_SUMMON_SPELLS[buttonInfo.totemSet])

        if summonSpellName then
            displayName = ('%s: %s'):format(summonSpellName, displayName)
        end
    end

    button:SetAttributeNoHandler('displayName', displayName)

    TotemArt:ShrinkButton(button)
    addTotemSlotArt(button, totemIndex)

    return button
end

function TotemBar:ReleaseButton(button)
    if not button.isSpell then
        button:SetAttribute('statehidden', true)
        ClearOverrideBindings(button.bind)
    end

    button:Hide()
end

function TotemBar:OnAttachButton(button, index)
    local buttonInfo = self.buttonOrder[index]

    if button.isSpell then
        self:AttachSpellButton(button, buttonInfo)
    else
        self:AttachTotemButton(button, buttonInfo)
    end
end

function TotemBar:OnDetachButton(button)
    if button.isSpell then
        self:DetachSpellButton(button)
    else
        self:DetachTotemButton(button)
    end
end

function TotemBar:AttachSpellButton(button, buttonInfo)
    button:SetShowBindingText(self:ShowingBindingText())
    button:Show()

    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Register(button)

    if buttonInfo.kind == SpellButton.SUMMON then
        button:SetPaged(self:IsPaged())

        if button:IsPaged() then
            -- wrapping turns mouse on, put it back for click through
            local mouseEnabled = button:IsMouseEnabled()

            self:WrapScript(button, 'OnMouseWheel', summonButton_OnMouseWheel)
            self:WrapScript(button, 'OnClick', summonButton_OnClick)

            button:EnableMouse(mouseEnabled)
        end
    end

    button:UpdateOverrideBindings()
end

function TotemBar:DetachSpellButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Unregister(button)

    if button:IsPaged() then
        local mouseEnabled = button:IsMouseEnabled()

        self:UnwrapScript(button, 'OnClick')
        self:UnwrapScript(button, 'OnMouseWheel')

        button:EnableMouse(mouseEnabled)
        button:EnableMouseWheel(false)
    end

    ClearOverrideBindings(button)
end

function TotemBar:SetTotemButtonAction(button, totemIndex)
    local action = self:GetTotemAction(totemIndex, self:GetTotemSet())

    for totemSet = 1, NUM_TOTEM_SETS do
        local stateAction

        if self:IsPaged() then
            stateAction = self:GetTotemAction(totemIndex, totemSet)
        end

        button:SetAttributeNoHandler('action-' .. SpellButton.GetTotemSetState(totemSet), stateAction)
    end

    -- fixed buttons fall back to this if anything pushes a state at them
    if self:IsPaged() then
        button:SetAttributeNoHandler('action-base', nil)
    else
        button:SetAttributeNoHandler('action-base', action)
    end

    button:SetAttribute('action', action)
end

function TotemBar:AttachTotemButton(button, buttonInfo)
    self:SetTotemButtonAction(button, buttonInfo.totemIndex)
    button:SetAttributeNoHandler('totemSlot', SHAMAN_TOTEM_PRIORITIES[buttonInfo.totemIndex])
    button:SetAttributeNoHandler('statehidden', nil)

    if SpellButton.HAS_MULTICAST_BINDINGS then
        button:SetAttributeNoHandler('commandName', 'MULTICASTACTIONBUTTON' .. getTotemButtonNumber(buttonInfo))
    end

    button:UpdateOverrideBindings()
    button:UpdateHotkeys()

    button:SetShowGridInsecure(true, Addon.ActionButtons.ShowGridReasons.SHOW_EMPTY_BUTTONS_PER_BAR)
    button:SetShowCooldowns(true)
    button:SetShowBindingText(self:ShowingBindingText())
    button:UpdateShown()

    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    self.flyout:HookButton(button)
end

function TotemBar:DetachTotemButton(button)
    self.flyout:UnhookButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, self:GetDisplayName())
end

--------------------------------------------------------------------------------
-- Flyout
--------------------------------------------------------------------------------

function TotemBar:UpdateFlyoutDirection()
    self.flyout:SetDirection(self:GetCalculatedFlyoutDirection())
end

TotemBar:Extend('Layout', TotemBar.UpdateFlyoutDirection)
TotemBar:Extend('Stick', TotemBar.UpdateFlyoutDirection)

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

TotemBar:DefineButtonProp('BindingText')

TotemBar.contextMenu = Addon.ButtonBar.contextMenu:Extend {
    {
        insert = 'General',
        at = 'start',
        controls = {
            {
                type = 'check',
                name = 'ShowBindingText',
                get = 'ShowingBindingText',
                set = 'SetShowBindingText'
            },
            {
                type = 'check',
                name = 'ShowTotems',
                get = 'ShowingTotems',
                set = 'SetShowTotems'
            },
            {
                type = 'check',
                name = 'ShowTotemRecall',
                get = 'ShowingRecall',
                set = 'SetShowRecall'
            }
        }
    }
}

-- export
Addon.TotemBar = TotemBar
