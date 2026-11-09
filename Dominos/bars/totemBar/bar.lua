if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem bar
-- Implemented because MultiCastActionBarFrame loves to reposition itself in 
-- combat 
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local SpellButton = Addon.TotemSpellButton
local TotemPicker = Addon.TotemPicker

local TOTEM_ACTION_OFFSET = 132
local NUM_TOTEMS = NUM_MULTI_CAST_BUTTONS_PER_PAGE
local NUM_TOTEM_SETS = NUM_MULTI_CAST_PAGES

--------------------------------------------------------------------------------
-- Button setup
--------------------------------------------------------------------------------

-- shrink the actions
local function shrinkTotemButton(button)
    local size = SpellButton.SIZE
    local textures = {
        button.NormalTexture or _G[button:GetName() .. 'NormalTexture'],
        button.HighlightTexture,
        button.CheckedTexture,
        button.PushedTexture,
    }

    button:SetSize(size, size)

    for i = 1, 4 do
        if textures[i] then
            textures[i]:SetSize(size, size)
        end
    end

    -- other textures, depends on the game
    MultiCastButton_ApplyOverrides(button)
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

-- a saved set you don't know (profile from a higher level toon) falls back to
-- one you do, without overwriting it
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

-- the set's page, then the element's slot
function TotemBar:GetActionSlot(totemIndex, totemSet)
    local slot = SHAMAN_TOTEM_PRIORITIES[totemIndex]

    return TOTEM_ACTION_OFFSET + (totemSet - 1) * NUM_TOTEMS + slot
end

-- custom paging. totem buttons swap to action-totemsetN (action-base for set 1)
-- via ActionButton's _childupdate-state, summon does the same with spell-, so it
-- works in combat
local bar_OnStateTotemSet = [[
    control:ChildUpdate('state', 'totemset' .. newstate)
    self:CallMethod('OnTotemSetChanged', newstate)
]]

-- moves state-totemset to the next known set
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

-- summon pages its spell with the set, like the totem actions
local summonButton_OnChildUpdateState = [[
    local spell = self:GetAttribute('spell-' .. message) or self:GetAttribute('spell-base')

    if spell then
        self:SetAttribute('spell', spell)
    end
]]

-- right click on summon cycles sets, on up so it fires once. false skips the click
local summonButton_OnClick = [[
    if button == 'RightButton' then
        if not down then
            control:RunAttribute('CycleTotemSet')
        end

        return false
    end
]]

TotemBar:Extend('OnCreate', function(self)
    -- restricted code can't read globals
    self:Execute(('TotemSetCount = %d'):format(NUM_TOTEM_SETS))

    self:SetAttribute('_onstate-totemset', bar_OnStateTotemSet)
    self:SetAttribute('CycleTotemSet', bar_CycleTotemSet)
end)

-- can run in combat
function TotemBar:OnTotemSetChanged(totemSet)
    -- a GetTotemSet fallback isn't a choice, don't save it
    if totemSet ~= self:GetTotemSet() then
        self.sets.totemSet = totemSet
    end

    self:UpdateSpellButtons()
end

-- push the out of combat totem set to the secure side
function TotemBar:PushTotemSetState()
    local totemSet = self:GetTotemSet()

    -- setting it runs the state handler, even for a state we're already in
    if self:GetAttribute('state-totemset') ~= totemSet then
        self:SetAttribute('state-totemset', totemSet)
    end

    for totemSet, spellId in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
        self:SetAttribute('totemsetknown' .. totemSet, SpellButton.IsSpellKnown(spellId) or false)
    end
end

function TotemBar:SetupTotemButton(button, totemIndex)
    button:SetAttributeNoHandler('action-base', self:GetActionSlot(totemIndex, 1))

    for totemSet = 2, NUM_TOTEM_SETS do
        button:SetAttributeNoHandler('action-totemset' .. totemSet, self:GetActionSlot(totemIndex, totemSet))
    end

    button:SetAttribute('action', self:GetActionSlot(totemIndex, self:GetTotemSet()))

    -- the bar stands in for set 1 as far as blizzard's keybindings go
    button:SetAttributeNoHandler('commandName', 'MULTICASTACTIONBUTTON' .. totemIndex)
    button:UpdateOverrideBindings()
    button:UpdateHotkeys()
end

function TotemBar:SetupSummonButton(button)
    button:SetAttributeNoHandler('spell-base', TOTEM_MULTI_CAST_SUMMON_SPELLS[1])

    for totemSet = 2, NUM_TOTEM_SETS do
        button:SetAttributeNoHandler('spell-totemset' .. totemSet, TOTEM_MULTI_CAST_SUMMON_SPELLS[totemSet])
    end

    button:SetAttributeNoHandler('_childupdate-state', summonButton_OnChildUpdateState)
end

--------------------------------------------------------------------------------
-- Button list
-- buttonOrder: summon and recall (if known, recall also if shown) around the
-- totems. entries are SpellButton.SUMMON/RECALL or a totem index
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

-- when the bar is acquired, the order is empty so this reloads
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
    else
        self:UpdateSpellButtons()
    end

    self:PushTotemSetState()
end

--------------------------------------------------------------------------------
-- Spell buttons
--------------------------------------------------------------------------------

function TotemBar:ForSpellButtons(method, ...)
    for _, button in pairs(self.buttons) do
        if SpellButton.IsButton(button) then
            button[method](button, ...)
        end
    end
end

function TotemBar:UpdateSpellButtons()
    self:ForSpellButtons('UpdateSpell', self:GetTotemSet())
end

function TotemBar:UpdateSpellCooldowns()
    self:ForSpellButtons('UpdateCooldown')
end

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

function TotemBar:AcquireButton(index)
    local entry = self.buttonOrder[index]

    if entry == SpellButton.SUMMON or entry == SpellButton.RECALL then
        return SpellButton:Acquire(entry)
    end

    local totemIndex = entry
    local button = Addon.ActionButtons:GetOrCreateActionButton(0, self, ('%sTotemButton%d'):format(AddonName, totemIndex))

    button:SetAttributeNoHandler('index', index)
    button:SetAttributeNoHandler('displayName', _G['BINDING_NAME_MULTICASTACTIONBUTTON' .. totemIndex])
    shrinkTotemButton(button)

    return button
end

-- like action bars, only happens out of combat
function TotemBar:ReleaseButton(button)
    if not SpellButton.IsButton(button) then
        button:SetAttribute('statehidden', true)
    end

    button:Hide()
end

function TotemBar:OnAttachButton(button, index)
    if SpellButton.IsButton(button) then
        self:AttachSpellButton(button)
    else
        self:AttachTotemButton(button, self.buttonOrder[index])
    end
end

function TotemBar:OnDetachButton(button)
    if SpellButton.IsButton(button) then
        self:DetachSpellButton(button)
    else
        self:DetachTotemButton(button)
    end
end

function TotemBar:AttachSpellButton(button)
    button:UpdateSpell(self:GetTotemSet())
    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    Addon:GetModule('Tooltips'):Register(button)

    if button.kind == SpellButton.SUMMON then
        self:SetupSummonButton(button)
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

    -- show empty slots too
    button:SetShowGridInsecure(true, Addon.ActionButtons.ShowGridReasons.SHOW_EMPTY_BUTTONS_PER_BAR)
    button:SetShowCooldowns(true)
    button:UpdateShown()

    button:SetAttributeNoHandler('totemSlot', SHAMAN_TOTEM_PRIORITIES[totemIndex])

    Addon:GetModule('ButtonThemer'):Register(button, self:GetDisplayName())
    self.arrow:HookButton(button)
end

function TotemBar:DetachTotemButton(button)
    self.arrow:UnhookButton(button)
    Addon:GetModule('ButtonThemer'):Unregister(button, self:GetDisplayName())
end

--------------------------------------------------------------------------------
-- Picker
--------------------------------------------------------------------------------

TotemBar:Extend('OnCreate', function(self)
    self.arrow = TotemPicker:Create(self)
end)

function TotemBar:UpdateFlyoutDirection()
    self.arrow:SetFlyoutDirection(self:GetCalculatedFlyoutDirection())
end

TotemBar:Extend('Layout', TotemBar.UpdateFlyoutDirection)
TotemBar:Extend('Stick', TotemBar.UpdateFlyoutDirection)

--------------------------------------------------------------------------------
-- Menu
--------------------------------------------------------------------------------

TotemBar.contextMenu = Addon.ButtonBar.contextMenu:Extend {
    {
        insert = 'General',
        at = 'start',
        controls = {
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
