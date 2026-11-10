if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem spell buttons
-- summon (Call of ...) and recall. right click on summon cycles the totem set
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local TotemArt = Addon.TotemArt

local SpellButton = {
    SUMMON = 'Summon',
    RECALL = 'Recall',
    SIZE = 30,
}

--------------------------------------------------------------------------------
-- Button
--------------------------------------------------------------------------------

local SpellButtonMixin = {}

-- the spell attribute is owned by secure code, this just reflects it
function SpellButtonMixin:UpdateSpell()
    local spellId = self:GetAttribute('spell')

    self.spellId = spellId
    self.icon:SetTexture(C_Spell.GetSpellTexture(spellId))
    self:UpdateCooldown()

    -- the name quick binding shows. out of combat, like any insecure attribute write
    if not InCombatLockdown() then
        self:SetAttributeNoHandler('displayName', C_Spell.GetSpellName(spellId))
    end
end

function SpellButtonMixin:SetShowBindingText(show)
    self.HotKey:SetShown(show)
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

local function button_Create(kind, name)
    local button = CreateFrame('Button', name, nil, 'SecureActionButtonTemplate')
    Mixin(button, SpellButtonMixin)

    button.kind = kind
    button.cropIcon = true

    button:SetSize(SpellButton.SIZE, SpellButton.SIZE)

    button:RegisterForClicks('AnyUp', 'AnyDown')
    button:SetAttribute('type', 'spell')

    button.icon = button:CreateTexture(nil, 'ARTWORK')
    button.icon:SetAllPoints()

    TotemArt:AddRing(button)

    if kind == SpellButton.SUMMON then
        for totemSet, spellId in ipairs(TOTEM_MULTI_CAST_SUMMON_SPELLS) do
            button:SetAttributeNoHandler('spell-totemset' .. totemSet, spellId)
        end

        -- pages with the bar's totem set
        button:SetAttributeNoHandler('_childupdate-state', [[
            local spell = self:GetAttribute('spell-' .. message)
            if spell then
                self:SetAttribute('spell', spell)
            end
        ]])
    else
        button:SetAttributeNoHandler('spell', TOTEM_MULTI_CAST_RECALL_SPELLS[1])
    end

    button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.cooldown:SetAllPoints()

    button.HotKey = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmallGray')
    button.HotKey:SetPoint('TOPRIGHT', -2, -2)

    if C_Texture.GetAtlasInfo('UI-HUD-ActionBar-IconFrame-Down') then
        button:SetPushedAtlas('UI-HUD-ActionBar-IconFrame-Down')

        -- blizzard's small button size
        local pushed = button:GetPushedTexture()
        pushed:ClearAllPoints()
        pushed:SetPoint('CENTER')
        pushed:SetSize(35, 35)
    else
        button:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
    end

    button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')

    button:SetScript('OnEnter', button_OnEnter)
    button:SetScript('OnLeave', button_OnLeave)

    button:SetAttributeNoHandler('commandName', ('CLICK %s:LeftButton'):format(name))
    Addon.BindableButton:AddQuickBindingSupport(button)

    return button
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

function SpellButton:Acquire(kind)
    local name = ('%sTotem%sButton'):format(AddonName, kind)

    return _G[name] or button_Create(kind, name)
end

function SpellButton:IsButton(frame)
    return frame.kind ~= nil
end

function SpellButton:IsSpellKnown(spellId)
    return spellId ~= nil
        and C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, false)
end

-- export
Addon.TotemSpellButton = SpellButton
