if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem spell buttons
-- Summon ("Call of ...") and recall. Plain secure spell buttons, and right
-- clicking summon cycles the totem set (bar.lua wraps the right click)
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

local SpellButton = {
    SUMMON = 'Summon',
    RECALL = 'Recall',

    -- same as blizzard's totem bar
    SIZE = 30,
}

function SpellButton.IsButton(frame)
    return frame.kind ~= nil
end

function SpellButton.IsSpellKnown(spellId)
    return spellId ~= nil
        and C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, false)
end

--------------------------------------------------------------------------------
-- Button mixin
--------------------------------------------------------------------------------

local SpellButtonMixin = {}

function SpellButtonMixin:UpdateSpell(totemSet)
    local spellId
    if self.kind == SpellButton.SUMMON then
        spellId = TOTEM_MULTI_CAST_SUMMON_SPELLS[totemSet]
    else
        spellId = TOTEM_MULTI_CAST_RECALL_SPELLS[1]
    end

    local known = SpellButton.IsSpellKnown(spellId)

    self.spellId = spellId
    self.icon:SetTexture(known and C_Spell.GetSpellTexture(spellId) or nil)
    self:UpdateCooldown()

    -- protected, so not in combat
    if not InCombatLockdown() then
        self:SetAttribute('spell', spellId)
        self:SetShown(known)

        -- the name quick binding shows
        self:SetAttributeNoHandler('displayName', known and C_Spell.GetSpellName(spellId) or nil)
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

--------------------------------------------------------------------------------
-- Scripts
--------------------------------------------------------------------------------

local function button_OnEnter(self)
    if self.spellId then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetSpellByID(self.spellId)

        if self.kind == SpellButton.SUMMON then
            GameTooltip:AddLine(L.TotemSetHint, 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end
    end
end

local function button_OnLeave()
    GameTooltip:Hide()
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

local function create(kind, name)
    local button = CreateFrame('Button', name, nil, 'SecureActionButtonTemplate')
    Mixin(button, SpellButtonMixin)

    button.kind = kind

    button:SetSize(SpellButton.SIZE, SpellButton.SIZE)

    -- down too, for cast on key down
    button:RegisterForClicks('AnyUp', 'AnyDown')
    button:SetAttribute('type', 'spell')

    button.icon = button:CreateTexture(nil, 'ARTWORK')
    button.icon:SetAllPoints()

    button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.cooldown:SetAllPoints()

    button.HotKey = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmallGray')
    button.HotKey:SetPoint('TOPRIGHT', -2, -2)

    button:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
    button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')

    button:SetScript('OnEnter', button_OnEnter)
    button:SetScript('OnLeave', button_OnLeave)

    -- the game clicks the button when the key is pressed, no override bindings needed
    button:SetAttributeNoHandler('commandName', ('CLICK %s:LeftButton'):format(name))
    Addon.BindableButton:AddQuickBindingSupport(button)

    return button
end

function SpellButton:Acquire(kind)
    local name = ('%sTotem%sButton'):format(AddonName, kind)

    return _G[name] or create(kind, name)
end

-- export
Addon.TotemSpellButton = SpellButton
