if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem spell buttons
-- summon (Call of ...) and recall
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local TotemArt = Addon.TotemArt

local SpellButton = {
    SUMMON = 'Summon',
    RECALL = 'Recall',

    -- Forever has none, so its buttons use CLICK bindings
    HAS_MULTICAST_BINDINGS = not Addon:IsGameType('forever'),
}

-- secure buttons read a trailing digit on an attribute as a mouse button, so
-- these avoid numbers
local TOTEM_SET_STATES = {
    'totems-elements',
    'totems-ancestors',
    'totems-spirits',
}

---@param totemSet number
---@return string
function SpellButton.GetTotemSetState(totemSet)
    return TOTEM_SET_STATES[totemSet]
end

---@return string[]
function SpellButton.GetTotemSetStates()
    return TOTEM_SET_STATES
end

local function setOverrideBindings(button, ...)
    local name = button:GetName()

    for i = 1, select('#', ...) do
        SetOverrideBindingClick(button, false, select(i, ...), name, 'LeftButton')
    end
end

--------------------------------------------------------------------------------
-- Button
--------------------------------------------------------------------------------

local SpellButtonMixin = {}

-- summon only, out of combat. a paged summon follows the bar's totem set, the
-- bar wraps its wheel to cycle it. a fixed one casts its own set's spell
function SpellButtonMixin:SetPaged(paged)
    self.paged = paged

    if paged then
        for totemSet, spellId in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
            self:SetAttributeNoHandler('spell-' .. SpellButton.GetTotemSetState(totemSet), spellId)
        end

        self:SetSpell(TOTEM_MULTI_CAST_SUMMON_SPELLS[1])

        self:SetAttributeNoHandler('_childupdate-state', [[
            local spell = self:GetAttribute('spell-' .. message)
            if spell then
                self:SetAttribute('type', 'spell')
                self:SetAttribute('spell', spell)
            end
        ]])
    else
        self:SetSpell(TOTEM_MULTI_CAST_SUMMON_SPELLS[self.totemSet])
        self:SetAttributeNoHandler('_childupdate-state', nil)
    end

    self:EnableMouseWheel(paged)
end

-- out of combat
function SpellButtonMixin:SetSpell(spellId)
    self:SetAttributeNoHandler('type', 'spell')
    self:SetAttributeNoHandler('spell', spellId)
end

function SpellButtonMixin:IsPaged()
    return self.paged and true or false
end

function SpellButtonMixin:UpdateSpell()
    local spellId = self:GetAttribute('spell')

    self.spellId = spellId

    -- just the icon. the other returns would land in SetTexture's wrap modes
    local icon
    if spellId then
        icon = C_Spell.GetSpellTexture(spellId)
    end
    self.icon:SetTexture(icon)

    self:UpdateUsable()
    self:UpdateCooldown()

    -- for quick binding
    if spellId and not InCombatLockdown() then
        self:SetAttributeNoHandler('displayName', C_Spell.GetSpellName(spellId))
    end
end

function SpellButtonMixin:SetShowBindingText(show)
    self.HotKey:SetShown(show)
end

-- GameTooltip calls this as it updates, so cycling while hovering shows the new spell
function SpellButtonMixin:UpdateTooltip()
    if not self.spellId then
        GameTooltip:Hide()
        return
    end

    GameTooltip:SetSpellByID(self.spellId)

    if self:IsPaged() then
        GameTooltip_AddBlankLineToTooltip(GameTooltip)
        GameTooltip_AddInstructionLine(GameTooltip, L.TotemSetHint)
        GameTooltip:Show()
    end
end

function SpellButtonMixin:UpdateCooldown()
    local duration = self.spellId and C_Spell.GetSpellCooldownDuration(self.spellId)

    if duration then
        self.cooldown:SetCooldownFromDurationObject(duration)
    else
        self.cooldown:Clear()
    end
end

function SpellButtonMixin:UpdateUsable()
    if not self.spellId then
        return
    end

    if not SpellButton:IsSpellKnown(self.spellId) then
        self.icon:SetVertexColor(0.4, 0.4, 0.4)
        return
    end

    local isUsable, notEnoughMana = C_Spell.IsSpellUsable(self.spellId)

    if isUsable then
        self.icon:SetVertexColor(1, 1, 1)
    elseif notEnoughMana then
        self.icon:SetVertexColor(0.5, 0.5, 1)
    else
        self.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

-- CLICK bindings reach the button on their own, blizzard's need pointing at it
function SpellButtonMixin:UpdateOverrideBindings()
    if InCombatLockdown() then
        return
    end

    ClearOverrideBindings(self)

    local command = self:GetAttribute('commandName')

    if not command:find('^CLICK ') then
        setOverrideBindings(self, GetBindingKey(command))
    end
end

--------------------------------------------------------------------------------
-- Scripts
--------------------------------------------------------------------------------

local function button_OnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    self:UpdateTooltip()
end

local function button_OnLeave()
    GameTooltip:Hide()
end

-- CheckButtons stay checked after a click otherwise
local function button_PostClick(self)
    self:SetChecked(false)
end

local function getCommandName(kind, name, totemSet)
    if not SpellButton.HAS_MULTICAST_BINDINGS then
        return ('CLICK %s:LeftButton'):format(name)
    end

    if kind == SpellButton.SUMMON then
        return 'MULTICASTSUMMONBUTTON' .. totemSet
    end

    -- blizzard only has the one recall binding
    if totemSet == 1 then
        return 'MULTICASTRECALLBUTTON1'
    end

    return ('CLICK %s:LeftButton'):format(name)
end

-- built like blizzard's summon and recall buttons. the ring replaces the
-- template's normal texture
local function button_Create(kind, name, totemSet)
    local button = CreateFrame('CheckButton', name, nil, 'ActionButtonTemplate, SecureActionButtonTemplate')
    Mixin(button, SpellButtonMixin)

    button.isSpell = true
    button.totemSet = totemSet

    TotemArt:ShrinkButton(button)

    button.NormalTexture:SetAlpha(0)
    button.SlotBackground:Hide()

    -- only Forever's template has it
    if button.SlotArt then
        button.SlotArt:Hide()
    end

    TotemArt:AddSlotRing(button)
    button.HotKey:SetDrawLayer('OVERLAY', 7)

    button:RegisterForClicks('AnyUp', 'AnyDown')

    -- so the camera still zooms over it, SetPaged turns it on
    button:EnableMouseWheel(false)

    -- summon gets its spell from SetPaged
    if kind == SpellButton.RECALL then
        button:SetSpell(TOTEM_MULTI_CAST_RECALL_SPELLS[1])
    end

    button:SetScript('OnEnter', button_OnEnter)
    button:SetScript('OnLeave', button_OnLeave)
    button:SetScript('PostClick', button_PostClick)

    button:SetAttributeNoHandler('commandName', getCommandName(kind, name, totemSet))
    Addon.BindableButton:AddQuickBindingSupport(button)

    button:UpdateSpell()

    return button
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

-- a summon and a recall per totem set, the paged bar uses set 1's
function SpellButton:Acquire(kind, totemSet)
    local name = ('%sTotem%sButton%d'):format(AddonName, kind, totemSet)

    return _G[name] or button_Create(kind, name, totemSet)
end

function SpellButton:IsSpellKnown(spellId)
    return spellId and C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, false)
end

-- export
Addon.TotemSpellButton = SpellButton
