if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem flyout
-- an arrow over the hovered totem button opens a flyout of the slot's totems.
-- the arrow is the secure header for the flyout, its entries and close button
--------------------------------------------------------------------------------

local _, Addon = ...

local TotemArt = Addon.TotemArt
local TotemFlyout = {}

local MAX_ENTRIES = 12
local ENTRY_SIZE = 24
local PADDING = 4
local SPACING = 2

-- seconds
local HIDE_DELAY = 0.25

-- close button plus blizzard's gap
local ENDCAP_SIZE = 2 + TotemArt.ARROW_HEIGHT

-- point anchors to the button's relPoint, far is the flyout's far end, x y is
-- the way it grows
local DIRECTIONS = {
    UP = { point = 'BOTTOM', relPoint = 'TOP', far = 'TOP', x = 0, y = 1 },
    DOWN = { point = 'TOP', relPoint = 'BOTTOM', far = 'BOTTOM', x = 0, y = -1 },
    LEFT = { point = 'RIGHT', relPoint = 'LEFT', far = 'LEFT', x = -1, y = 0 },
    RIGHT = { point = 'LEFT', relPoint = 'RIGHT', far = 'RIGHT', x = 1, y = 0 },
}

--------------------------------------------------------------------------------
-- Secure Handlers
--------------------------------------------------------------------------------

local arrow_Show = [[
    arrow:Show()
    arrow:RegisterAutoHide(HideDelay)
    arrow:AddToAutoHide(hovered)
]]

-- clicking an empty slot toggles the flyout
local totemButton_OnClick = [[
    if button == 'LeftButton' then
        if not HasAction(self:GetAttribute('action')) then
            if not down then
                arrow:RunAttribute('ToggleFlyout')
            end

            return false
        end

        -- casting closes the flyout
        if flyout:IsShown() then
            flyout:Hide()
            arrow:RunAttribute('ShowArrow')
        end
    end
]]

local totemButton_OnEnter = [[
    if hovered ~= self then
        flyout:Hide()
    end

    hovered = self
    arrow:CallMethod('SetHoveredSlot', self:GetAttribute('totemSlot'))

    arrow:ClearAllPoints()
    arrow:SetPoint(arrow:GetAttribute('flyoutPoint'), self, arrow:GetAttribute('flyoutRelPoint'))

    -- the flyout replaces the arrow while open
    if not flyout:IsShown() then
        arrow:RunAttribute('ShowArrow')
    end
]]

-- no totem, then every totem for the slot
local arrow_ToggleFlyout = [[
    if flyout:IsShown() then
        flyout:Hide()
        self:RunAttribute('ShowArrow')
        return
    end

    if not hovered then return end

    local slot = hovered:GetAttribute('totemSlot')
    local spells = newtable(GetMultiCastTotemSpells(slot))
    if #spells == 0 then return end

    local point = self:GetAttribute('flyoutPoint')
    local x = self:GetAttribute('flyoutX')
    local y = self:GetAttribute('flyoutY')

    local action = hovered:GetAttribute('action')
    local numEntries = math.min(#spells + 1, #entries)

    -- grows away from the arrow, first entry closest
    for i = 1, #entries do
        local entry = entries[i]

        if i <= numEntries then
            local offset = FlyoutPadding + (i - 1) * EntryStep

            entry:SetAttribute('action', action)
            entry:SetAttribute('spell', i == 1 and 0 or spells[i - 1])
            entry:ClearAllPoints()
            entry:SetPoint(point, flyout, point, x * offset, y * offset)
            entry:Show()
        else
            entry:Hide()
        end
    end

    local length = numEntries * EntryStep - FlyoutSpacing + FlyoutPadding + FlyoutEndcap

    if x == 0 then
        flyout:SetWidth(FlyoutThickness)
        flyout:SetHeight(length)
    else
        flyout:SetWidth(length)
        flyout:SetHeight(FlyoutThickness)
    end

    flyout:ClearAllPoints()
    flyout:SetPoint(point, hovered, self:GetAttribute('flyoutRelPoint'))

    flyout:Show()
    flyout:RegisterAutoHide(HideDelay)
    flyout:AddToAutoHide(hovered)
    arrow:Hide()

    self:CallMethod('UpdateFlyoutArt', slot)
]]

--------------------------------------------------------------------------------
-- Frames
--------------------------------------------------------------------------------

local function entry_OnEnter(self)
    local spellId = self:GetAttribute('spell')

    if spellId and spellId > 0 then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetSpellByID(spellId)
    elseif spellId == 0 then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetText(MULTI_CAST_TOOLTIP_NO_TOTEM)
    end
end

local function entry_OnLeave()
    GameTooltip:Hide()
end

local FlyoutMixin = {}

-- textures are fine in combat
function FlyoutMixin:UpdateFlyoutArt(slot)
    local direction = self:GetAttribute('flyoutDirection')

    TotemArt:SetFlyoutArt(self.flyout.cap, self.flyout.body, slot, direction)
    TotemArt:SetCloseArt(self.close, slot, direction)

    for _, entry in ipairs(self.entries) do
        if entry:IsShown() then
            local spellId = entry:GetAttribute('spell')

            if spellId and spellId > 0 then
                local icon = C_Spell.GetSpellTexture(spellId)
                entry.icon:SetTexture(icon)
                entry.icon:SetTexCoord(0, 1, 0, 1)
            else
                TotemArt:SetEmptySlotArt(entry.icon, slot)
            end
        end
    end
end

-- protected frames, so not in combat
function FlyoutMixin:SetDirection(direction)
    if InCombatLockdown() or self:GetAttribute('flyoutDirection') == direction then
        return
    end

    local d = DIRECTIONS[direction]
    local flyout = self.flyout
    local close = self.close
    local thickness = TotemArt.FLYOUT_THICKNESS
    local capLength = TotemArt.FLYOUT_CAP_LENGTH

    self:SetAttribute('flyoutDirection', direction)
    self:SetAttribute('flyoutPoint', d.point)
    self:SetAttribute('flyoutRelPoint', d.relPoint)
    self:SetAttribute('flyoutX', d.x)
    self:SetAttribute('flyoutY', d.y)

    flyout:Hide()
    self:Hide()
    self:SetSize(TotemArt:GetArrowSize(direction))

    close:ClearAllPoints()
    close:SetPoint(d.far, flyout, d.far)
    close:SetSize(TotemArt:GetArrowSize(direction))

    flyout.cap:ClearAllPoints()
    flyout.cap:SetPoint(d.far, flyout, d.far, -d.x * TotemArt.FLYOUT_CAP_INSET, -d.y * TotemArt.FLYOUT_CAP_INSET)

    flyout.body:ClearAllPoints()
    flyout.body:SetPoint(d.far, flyout.cap, d.point)
    flyout.body:SetPoint(d.point, flyout, d.point)

    if TotemArt:IsSideways(direction) then
        flyout.cap:SetSize(capLength, thickness)
        flyout.body:SetHeight(thickness)
    else
        flyout.cap:SetSize(thickness, capLength)
        flyout.body:SetWidth(thickness)
    end

    TotemArt:SetArrowArt(self, self.hoveredSlot, direction)
end

function FlyoutMixin:SetHoveredSlot(slot)
    self.hoveredSlot = slot
    TotemArt:SetArrowArt(self, slot, self:GetAttribute('flyoutDirection'))
end

-- after Tooltips, so ours is the outer wrap. its wrap can cancel OnEnter
function FlyoutMixin:HookButton(button)
    Addon:GetModule('Tooltips'):Register(button)

    -- wrapping turns mouse on, put it back for click through
    local mouseEnabled = button:IsMouseEnabled()

    self:WrapScript(button, 'OnEnter', totemButton_OnEnter)
    self:WrapScript(button, 'OnClick', totemButton_OnClick)

    button:EnableMouse(mouseEnabled)
end

function FlyoutMixin:UnhookButton(button)
    local mouseEnabled = button:IsMouseEnabled()

    self:UnwrapScript(button, 'OnEnter')
    self:UnwrapScript(button, 'OnClick')

    button:EnableMouse(mouseEnabled)

    Addon:GetModule('Tooltips'):Unregister(button)
end

-- the post body only runs when the pre body returns a message
local function wrapCloseOnClick(frame, arrow)
    arrow:WrapScript(frame, 'OnClick', [[ return nil, 'close' ]], [[ flyout:Hide() ]])
end

local function createEntry(flyout, arrow)
    local entry = CreateFrame('Button', nil, flyout, 'SecureActionButtonTemplate')
    entry:SetSize(ENTRY_SIZE, ENTRY_SIZE)
    entry:RegisterForClicks('LeftButtonUp')
    entry:SetAttribute('type', 'multispell')

    -- ActionButtonUseKeyDown would skip up clicks
    entry:SetAttribute('useOnKeyDown', false)
    entry:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
    entry:SetScript('OnEnter', entry_OnEnter)
    entry:SetScript('OnLeave', entry_OnLeave)
    entry:Hide()

    Addon:GetModule('Tooltips'):Register(entry)

    entry.icon = entry:CreateTexture(nil, 'BACKGROUND')
    entry.icon:SetAllPoints()

    arrow:SetFrameRef('entry', entry)
    arrow:Execute([[ entries[#entries + 1] = self:GetFrameRef('entry') ]])

    wrapCloseOnClick(entry, arrow)

    return entry
end

local function createClose(flyout, arrow)
    local close = CreateFrame('Button', nil, flyout, 'SecureActionButtonTemplate')
    close:RegisterForClicks('LeftButtonUp')
    close:SetAttribute('useOnKeyDown', false)
    close:SetNormalTexture(TotemArt.TEXTURE_FILE)
    close:SetHighlightTexture(TotemArt.TEXTURE_FILE, 'ADD')

    wrapCloseOnClick(close, arrow)

    return close
end

function TotemFlyout:Create(bar)
    local arrow = CreateFrame('Button', nil, bar, 'SecureHandlerClickTemplate')
    arrow:SetFrameStrata('HIGH')
    arrow:SetNormalTexture(TotemArt.TEXTURE_FILE)
    arrow:SetHighlightTexture(TotemArt.TEXTURE_FILE, 'ADD')
    arrow:Hide()

    Mixin(arrow, FlyoutMixin)
    arrow.entries = {}

    -- not the arrow's child, the arrow hides while the flyout is open
    local flyout = CreateFrame('Frame', nil, bar, 'SecureHandlerBaseTemplate')
    flyout:SetFrameStrata('DIALOG')
    flyout:SetSize(TotemArt.FLYOUT_THICKNESS, TotemArt.FLYOUT_THICKNESS)
    flyout:EnableMouse(true)
    flyout:Hide()

    flyout.cap = flyout:CreateTexture(nil, 'BACKGROUND')
    flyout.body = flyout:CreateTexture(nil, 'BACKGROUND')

    arrow.flyout = flyout
    arrow.close = createClose(flyout, arrow)

    arrow:SetFrameRef('flyout', flyout)

    arrow:Execute(([[
        arrow = self
        flyout = self:GetFrameRef('flyout')
        entries = table.new()
        hovered = nil

        HideDelay = %g
        EntryStep = %d
        FlyoutPadding = %d
        FlyoutSpacing = %d
        FlyoutThickness = %d
        FlyoutEndcap = %d
    ]]):format(HIDE_DELAY, ENTRY_SIZE + SPACING, PADDING, SPACING, TotemArt.FLYOUT_THICKNESS, ENDCAP_SIZE))

    for i = 1, MAX_ENTRIES do
        arrow.entries[i] = createEntry(flyout, arrow)
    end

    arrow:SetAttribute('ShowArrow', arrow_Show)
    arrow:SetAttribute('ToggleFlyout', arrow_ToggleFlyout)
    arrow:SetAttribute('_onclick', [[ self:RunAttribute('ToggleFlyout') ]])

    arrow:SetDirection('UP')

    return arrow
end

-- export
Addon.TotemFlyout = TotemFlyout
