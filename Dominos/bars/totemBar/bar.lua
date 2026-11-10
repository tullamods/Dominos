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

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

local function shrinkTotemButton(button)
    button:SetSize(SpellButton.SIZE, SpellButton.SIZE)

    -- blizzard's small sizes, pushed is drawn bigger than highlight. normal is
    -- hidden by addSlotArt
    button.PushedTexture:SetSize(35, 35)
    button.HighlightTexture:SetSize(31.6, 30.9)
    button.CheckedTexture:SetSize(31.6, 30.9)

    -- the rest, depends on the game
    MultiCastButton_ApplyOverrides(button)
end

-- the ring replaces the template's normal texture
local function addSlotArt(button, totemIndex)
    if button.hasSlotArt then
        return
    end

    button.hasSlotArt = true

    button.NormalTexture:SetAlpha(0)

    -- only the camelot template has it
    if button.SlotArt then
        button.SlotArt:Hide()
    end

    local slot = SHAMAN_TOTEM_PRIORITIES[totemIndex]

    -- reuse the template's background, classic's is offset and faded
    local background = button.SlotBackground

    background:ClearAllPoints()
    background:SetAllPoints()
    background:SetAlpha(1)
    background:Show()
    TotemArt:SetEmptySlot(background, slot)

    TotemArt:AddRing(button, slot)

    -- SetShowBindingText(false) reparents HotKey out of the template's text
    -- container, under the ring
    button.HotKey:SetDrawLayer('OVERLAY', 7)
end

--------------------------------------------------------------------------------
-- Bar setup
--------------------------------------------------------------------------------

local TotemBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function TotemBar:New()
    return TotemBar.proto.New(self, 'totem')
end

function TotemBar:GetDisplayName()
    return L.TotemBarDisplayName
end

function TotemBar:GetDefaults()
    return {
        point = 'CENTER',
        spacing = 2
    }
end

-- from buttonOrder so this and AcquireButton agree mid reload
function TotemBar:NumButtons()
    return self.buttonOrder and #self.buttonOrder or 0
end

--------------------------------------------------------------------------------
-- Totem sets
--------------------------------------------------------------------------------

function TotemBar:GetTotemSet()
    local totemSet = self.sets.totemSet or 1

    if SpellButton.IsSpellKnown(TOTEM_MULTI_CAST_SUMMON_SPELLS[totemSet]) then
        return totemSet
    end

    for i, spellId in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
        if SpellButton.IsSpellKnown(spellId) then
            return i
        end
    end

    return totemSet
end

function TotemBar:GetAction(totemIndex, totemSet)
    local totemSlot = SHAMAN_TOTEM_PRIORITIES[totemIndex]

    return TOTEM_ACTION_OFFSET + (totemSet - 1) * NUM_TOTEMS + totemSlot
end

-- totem buttons page via ActionButton's _childupdate-state (action-totemsetN),
-- summon via spell-totemsetN, so it works in combat
local bar_OnStateTotemSet = [[
    control:ChildUpdate('state', 'totemset' .. newstate)
    self:CallMethod('OnTotemSetChanged', newstate)
]]

local bar_CycleTotemSet = [[
    local current = self:GetAttribute('state-totemset') or 1

    for offset = 1, TotemSetCount - 1 do
        local totemSet = (current - 1 + offset) % TotemSetCount + 1

        if self:GetAttribute('totemsetknown' .. totemSet) then
            self:SetAttribute('state-totemset', totemSet)
            return
        end
    end
]]

-- on up so it fires once, false skips the click
local summonButton_OnClick = [[
    if button == 'RightButton' then
        if not down then
            control:RunAttribute('CycleTotemSet')
        end

        return false
    end
]]

TotemBar:Extend('OnCreate', function(self)
    self:Execute(('TotemSetCount = %d'):format(NUM_TOTEM_SETS))
    self:SetAttribute('_onstate-totemset', bar_OnStateTotemSet)
    self:SetAttribute('CycleTotemSet', bar_CycleTotemSet)
end)

-- persist the user's totem set selection, and update buttons
function TotemBar:OnTotemSetChanged(totemSet)
    if totemSet ~= self:GetTotemSet() then
        self.sets.totemSet = totemSet
    end

    self:UpdateSpellButtons()
end

-- setting the state runs the handler even for the state we're in, which syncs
-- newly attached buttons and updates the spell buttons
function TotemBar:PushTotemSetState()
    for index, spellId in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
        self:SetAttribute('totemsetknown' .. index, SpellButton.IsSpellKnown(spellId) or false)
    end

    self:SetAttribute('state-totemset', self:GetTotemSet())
end

-- camelot doesn't have them, and there's no lookup by name
local multicastBindings

local function hasMulticastBindings()
    if multicastBindings == nil then
        multicastBindings = false

        for i = 1, GetNumBindings() do
            if (GetBinding(i)) == 'MULTICASTACTIONBUTTON1' then
                multicastBindings = true
                break
            end
        end
    end

    return multicastBindings
end

function TotemBar:SetupTotemButton(button, totemIndex)
    for totemSet = 1, NUM_TOTEM_SETS do
        button:SetAttributeNoHandler('action-totemset' .. totemSet, self:GetAction(totemIndex, totemSet))
    end

    button:SetAttribute('action', self:GetAction(totemIndex, self:GetTotemSet()))

    -- blizzard's bindings are for set 1. without them the button keeps its
    -- CLICK binding
    if not Addon:IsGameType("forever") then
        button:SetAttributeNoHandler('commandName', 'MULTICASTACTIONBUTTON' .. totemIndex)
    end

    button:UpdateOverrideBindings()
    button:UpdateHotkeys()
end

--------------------------------------------------------------------------------
-- Button list
-- buttonOrder: summon, the totems, recall. summon and recall only if known,
-- recall also if shown. items are SpellButton.SUMMON/RECALL or a totem index
--------------------------------------------------------------------------------

function TotemBar:ShowingRecall()
    return not self.sets.hideRecall
end

function TotemBar:SetShowRecall(show)
    self.sets.hideRecall = not show or nil
    self:Update()
end

-- returns true if the order changed
function TotemBar:UpdateButtonOrder()
    local hasSummon = SpellButton.IsSpellKnown(TOTEM_MULTI_CAST_SUMMON_SPELLS[self:GetTotemSet()])
    local hasRecall = self:ShowingRecall() and SpellButton.IsSpellKnown(TOTEM_MULTI_CAST_RECALL_SPELLS[1])

    if self.buttonOrder and hasSummon == self.hasSummon and hasRecall == self.hasRecall then
        return false
    end

    local buttonOrder = {}

    if hasSummon then
        buttonOrder[#buttonOrder + 1] = SpellButton.SUMMON
    end

    for totemIndex = 1, NUM_TOTEMS do
        buttonOrder[#buttonOrder + 1] = totemIndex
    end

    if hasRecall then
        buttonOrder[#buttonOrder + 1] = SpellButton.RECALL
    end

    self.buttonOrder, self.hasSummon, self.hasRecall = buttonOrder, hasSummon, hasRecall
    return true
end

-- pooled frames keep their fields, and a stale order would skip the reload
TotemBar:Extend('OnRelease', function(self)
    self.buttonOrder = nil
end)

-- the order is empty on acquire, so Update reloads
function TotemBar:ReloadButtons()
    self:Update()
end

-- protected buttons, so not in combat. PLAYER_REGEN_ENABLED runs it again
function TotemBar:Update()
    if InCombatLockdown() then
        return
    end

    if self:UpdateButtonOrder() then
        TotemBar.proto.ReloadButtons(self)
    end

    self:PushTotemSetState()
end

--------------------------------------------------------------------------------
-- Spell buttons
--------------------------------------------------------------------------------

function TotemBar:ForSpellButtons(method, ...)
    for _, button in pairs(self.buttons) do
        if SpellButton:IsButton(button) then
            button[method](button, ...)
        end
    end
end

function TotemBar:UpdateSpellButtons()
    self:ForSpellButtons('UpdateSpell')
end

function TotemBar:UpdateSpellCooldowns()
    self:ForSpellButtons('UpdateCooldown')
end

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

function TotemBar:AcquireButton(index)
    local item = self.buttonOrder[index]

    if item == SpellButton.SUMMON or item == SpellButton.RECALL then
        return SpellButton:Acquire(item)
    end

    local totemIndex = item
    local button = Addon.ActionButtons:GetOrCreateActionButton(0, self, ('%sTotemButton%d'):format(AddonName, totemIndex))

    button:SetAttributeNoHandler('index', index)

    button:SetAttributeNoHandler(
        'displayName',
        _G['BINDING_NAME_MULTICASTACTIONBUTTON' .. totemIndex] or ('%s %d'):format(self:GetDisplayName(), totemIndex)
    )

    shrinkTotemButton(button)
    addSlotArt(button, totemIndex)

    return button
end

-- like action bars, only happens out of combat
function TotemBar:ReleaseButton(button)
    if not SpellButton:IsButton(button) then
        button:SetAttribute('statehidden', true)
    end

    button:Hide()
end

function TotemBar:OnAttachButton(button, index)
    if SpellButton:IsButton(button) then
        self:AttachSpellButton(button)
    else
        self:AttachTotemButton(button, self.buttonOrder[index])
    end
end

function TotemBar:OnDetachButton(button)
    if SpellButton:IsButton(button) then
        self:DetachSpellButton(button)
    else
        self:DetachTotemButton(button)
    end
end

function TotemBar:AttachSpellButton(button)
    button:SetShowBindingText(self:ShowingBindingText())
    button:Show()

    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Register(button)

    if button.kind == SpellButton.SUMMON then
        self:WrapScript(button, 'OnClick', summonButton_OnClick)
    end
end

function TotemBar:DetachSpellButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Unregister(button)

    if button.kind == SpellButton.SUMMON then
        self:UnwrapScript(button, 'OnClick')
    end
end

function TotemBar:AttachTotemButton(button, totemIndex)
    self:SetupTotemButton(button, totemIndex)
    button:SetAttributeNoHandler('statehidden', nil)

    button:SetShowGridInsecure(true, Addon.ActionButtons.ShowGridReasons.SHOW_EMPTY_BUTTONS_PER_BAR)
    button:SetShowCooldowns(true)
    button:SetShowBindingText(self:ShowingBindingText())
    button:UpdateShown()

    button:SetAttributeNoHandler('totemSlot', SHAMAN_TOTEM_PRIORITIES[totemIndex])

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

TotemBar:Extend('OnCreate', function(self)
    self.flyout = TotemFlyout:Create(self)
end)

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
                name = 'ShowTotemRecall',
                get = 'ShowingRecall',
                set = 'SetShowRecall'
            }
        }
    }
}

-- export
Addon.TotemBar = TotemBar
