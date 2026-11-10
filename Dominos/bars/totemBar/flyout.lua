if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem flyout
-- hover arrow on each totem button that opens the slot's totem list, close
-- button at the far end. the arrow is the secure header for the list, close
-- button and entries
--------------------------------------------------------------------------------

local AddonName, Addon = ...

local TotemArt = Addon.TotemArt
local TotemFlyout = {}

local MAX_ENTRIES = 12
local ENTRY_SIZE = 24
local PADDING = 4
local SPACING = 2

-- seconds before the flyout hides after the mouse leaves it
local HIDE_DELAY = 0.25

-- close button plus blizzard's gap
local ENDCAP = 2 + TotemArt.ARROW_HEIGHT

-- point anchors to the button's relPoint, far is the list's other end, x y is
-- the way it grows
local DIRECTIONS = {
    UP = { point = 'BOTTOM', relPoint = 'TOP', far = 'TOP', x = 0, y = 1 },
    DOWN = { point = 'TOP', relPoint = 'BOTTOM', far = 'BOTTOM', x = 0, y = -1 },
    LEFT = { point = 'RIGHT', relPoint = 'LEFT', far = 'LEFT', x = -1, y = 0 },
    RIGHT = { point = 'LEFT', relPoint = 'RIGHT', far = 'RIGHT', x = 1, y = 0 },
}

--------------------------------------------------------------------------------
-- Secure snippets
-- run in the arrow's environment, see Create for the globals and SetDirection
-- for the flyout* attributes
--------------------------------------------------------------------------------

-- autohide has to be registered while the mouse is over it, and the hovered
-- button is included so crossing to the arrow or list doesn't count as leaving
local arrow_Show = [[
    arrow:Show()
    arrow:RegisterAutoHide(HideDelay)
    arrow:AddToAutoHide(hovered)
]]

-- an empty slot has nothing to cast, so clicking toggles the list
local totemButton_OnClick = [[
    if button == 'LeftButton' then
        if not HasAction(self:GetAttribute('action')) then
            if not down then
                arrow:RunAttribute('ToggleList')
            end

            return false
        end

        -- casting closes the list
        if list:IsShown() then
            list:Hide()
            arrow:RunAttribute('ShowArrow')
        end
    end
]]

local totemButton_OnEnter = [[
    if hovered ~= self then
        list:Hide()
    end

    hovered = self
    arrow:CallMethod('SetSlot', self:GetAttribute('totemSlot'))

    arrow:ClearAllPoints()
    arrow:SetPoint(arrow:GetAttribute('flyoutPoint'), self, arrow:GetAttribute('flyoutRelPoint'))

    -- the list takes the arrow's place while it's open
    if not list:IsShown() then
        arrow:RunAttribute('ShowArrow')
    end
]]

-- clear, then every totem for the slot
local arrow_ToggleList = [[
    -- the arrow is hidden while the list is open, so this is a button click
    if list:IsShown() then
        list:Hide()
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
            local offset = ListPadding + (i - 1) * EntryStep

            entry:SetAttribute('action', action)
            entry:SetAttribute('spell', i == 1 and 0 or spells[i - 1])
            entry:ClearAllPoints()
            entry:SetPoint(point, list, point, x * offset, y * offset)
            entry:Show()
        else
            entry:Hide()
        end
    end

    local length = numEntries * EntryStep - ListSpacing + ListPadding + ListEndcap

    if x == 0 then
        list:SetWidth(ListThickness)
        list:SetHeight(length)
    else
        list:SetWidth(length)
        list:SetHeight(ListThickness)
    end

    -- on the button's edge, where the arrow was
    list:ClearAllPoints()
    list:SetPoint(point, hovered, self:GetAttribute('flyoutRelPoint'))

    list:Show()
    list:RegisterAutoHide(HideDelay)
    list:AddToAutoHide(hovered)
    arrow:Hide()

    self:CallMethod('UpdateListArt', slot)
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

-- for what the snippet just laid out, textures are fine in combat
function FlyoutMixin:UpdateListArt(slot)
    local direction = self:GetAttribute('flyoutDirection')

    TotemArt:SetFlyout(self.list.cap, self.list.body, slot, direction)
    TotemArt:SetClose(self.close, slot, direction)

    for _, entry in ipairs(self.entries) do
        if entry:IsShown() then
            local spellId = entry:GetAttribute('spell')

            if spellId and spellId > 0 then
                entry.icon:SetTexture(C_Spell.GetSpellTexture(spellId))
                entry.icon:SetTexCoord(0, 1, 0, 1)
            else
                TotemArt:SetEmptySlot(entry.icon, slot)
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
    local list, close = self.list, self.close
    local thickness, capLength = TotemArt.FLYOUT_THICKNESS, TotemArt.FLYOUT_CAP_LENGTH

    self:SetAttribute('flyoutDirection', direction)
    self:SetAttribute('flyoutPoint', d.point)
    self:SetAttribute('flyoutRelPoint', d.relPoint)
    self:SetAttribute('flyoutX', d.x)
    self:SetAttribute('flyoutY', d.y)

    list:Hide()
    self:Hide()
    self:SetSize(TotemArt:GetArrowSize(direction))

    close:ClearAllPoints()
    close:SetPoint(d.far, list, d.far)
    close:SetSize(TotemArt:GetArrowSize(direction))

    -- the cap sits inside the far edge
    list.cap:ClearAllPoints()
    list.cap:SetPoint(d.far, list, d.far, -d.x * TotemArt.FLYOUT_CAP_INSET, -d.y * TotemArt.FLYOUT_CAP_INSET)

    list.body:ClearAllPoints()
    list.body:SetPoint(d.far, list.cap, d.point)
    list.body:SetPoint(d.point, list, d.point)

    if TotemArt:IsSideways(direction) then
        list.cap:SetSize(capLength, thickness)
        list.body:SetHeight(thickness)
    else
        list.cap:SetSize(thickness, capLength)
        list.body:SetWidth(thickness)
    end

    TotemArt:SetArrow(self, self.slot, direction)
end

-- from the hover snippet, textures are fine in combat
function FlyoutMixin:SetSlot(slot)
    self.slot = slot
    TotemArt:SetArrow(self, slot, self:GetAttribute('flyoutDirection'))
end

-- Tooltips first so ours is outermost, its wrap can cancel OnEnter. unwrap pops
-- the outermost, so UnhookButton is the reverse
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

-- the post body only runs if the pre body returns a message
local function wrapCloseOnClick(frame, arrow)
    arrow:WrapScript(frame, 'OnClick', [[ return nil, 'close' ]], [[ list:Hide() ]])
end

local function createEntry(list, arrow, index)
    local entry = CreateFrame('Button', ('%sTotemFlyoutEntry%d'):format(AddonName, index), list, 'SecureActionButtonTemplate')
    entry:SetSize(ENTRY_SIZE, ENTRY_SIZE)
    entry:RegisterForClicks('LeftButtonUp')
    entry:SetAttribute('type', 'multispell')

    -- ActionButtonUseKeyDown makes secure buttons skip up clicks
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

local function createClose(list, arrow)
    local close = CreateFrame('Button', AddonName .. 'TotemFlyoutClose', list, 'SecureActionButtonTemplate')
    close:RegisterForClicks('LeftButtonUp')
    close:SetAttribute('useOnKeyDown', false)
    close:SetNormalTexture(TotemArt.TEXTURE_FILE)
    close:SetHighlightTexture(TotemArt.TEXTURE_FILE, 'ADD')

    wrapCloseOnClick(close, arrow)

    return close
end

function TotemFlyout:Create(bar)
    local arrow = CreateFrame('Button', AddonName .. 'TotemFlyout', bar, 'SecureHandlerClickTemplate')
    arrow:SetFrameStrata('HIGH')
    arrow:SetNormalTexture(TotemArt.TEXTURE_FILE)
    arrow:SetHighlightTexture(TotemArt.TEXTURE_FILE, 'ADD')
    arrow:Hide()

    Mixin(arrow, FlyoutMixin)
    arrow.entries = {}

    -- not the arrow's child, the arrow hides while the list is open
    local list = CreateFrame('Frame', AddonName .. 'TotemFlyoutList', bar, 'SecureHandlerBaseTemplate')
    list:SetFrameStrata('DIALOG')
    list:SetSize(TotemArt.FLYOUT_THICKNESS, TotemArt.FLYOUT_THICKNESS)
    list:EnableMouse(true)
    list:Hide()

    list.cap = list:CreateTexture(nil, 'BACKGROUND')
    list.body = list:CreateTexture(nil, 'BACKGROUND')

    arrow.list = list
    arrow.close = createClose(list, arrow)

    arrow:SetFrameRef('list', list)

    -- restricted code can't read globals
    arrow:Execute(([[
        arrow = self
        list = self:GetFrameRef('list')
        entries = table.new()
        hovered = nil

        HideDelay = %g
        EntryStep = %d
        ListPadding = %d
        ListSpacing = %d
        ListThickness = %d
        ListEndcap = %d
    ]]):format(HIDE_DELAY, ENTRY_SIZE + SPACING, PADDING, SPACING, TotemArt.FLYOUT_THICKNESS, ENDCAP))

    for i = 1, MAX_ENTRIES do
        arrow.entries[i] = createEntry(list, arrow, i)
    end

    arrow:SetAttribute('ShowArrow', arrow_Show)
    arrow:SetAttribute('ToggleList', arrow_ToggleList)
    arrow:SetAttribute('_onclick', [[ self:RunAttribute('ToggleList') ]])

    arrow:SetDirection('UP')

    return arrow
end

-- export
Addon.TotemFlyout = TotemFlyout
