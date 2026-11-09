if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem picker
-- A hover arrow on each totem button that opens a list of the totems for its slot
--------------------------------------------------------------------------------

local _, Addon = ...

local TotemPicker = {}

local MAX_ENTRIES = 12
local ENTRY_SIZE = 30
local PADDING = 4
local SPACING = 2
local CLEAR_ICON = 'Interface\\Buttons\\UI-GroupLoot-Pass-Up'

--------------------------------------------------------------------------------
-- Secure snippets
-- They run in the arrow's environment: `arrow`, `list`, `entries`, `hovered` and
-- the sizes (set up in TotemPicker:Create)
--------------------------------------------------------------------------------

-- hide unless the mouse is on the hovered button or the arrow (list is its child)
-- hide the list too, hiding the arrow leaves its shown flag set
local hoverGroup_OnLeave = [[
    if hovered and hovered:IsUnderMouse() then return end
    if arrow:IsUnderMouse(true) then return end

    list:Hide()
    arrow:Hide()
]]

local totemButton_OnEnter = [[
    if hovered ~= self then
        list:Hide()
    end

    hovered = self

    local direction = arrow:GetAttribute('flyoutDirection') or 'UP'

    arrow:ClearAllPoints()
    if direction == 'UP' then
        arrow:SetPoint('BOTTOM', self, 'TOP')
    elseif direction == 'DOWN' then
        arrow:SetPoint('TOP', self, 'BOTTOM')
    elseif direction == 'LEFT' then
        arrow:SetPoint('RIGHT', self, 'LEFT')
    else
        arrow:SetPoint('LEFT', self, 'RIGHT')
    end

    arrow:Show()
]]

-- clear option, then every totem the hovered button's slot can hold
local arrow_OnClick = [[
    if list:IsShown() then
        list:Hide()
        return
    end

    if not hovered then return end

    local direction = self:GetAttribute('flyoutDirection') or 'UP'
    local slot = hovered:GetAttribute('totemSlot')
    local action = hovered:GetAttribute('action')
    local numEntries = math.min(select('#', GetMultiCastTotemSpells(slot)) + 1, #entries)

    -- grows away from the arrow, first entry closest
    local point, relPoint, x, y
    if direction == 'UP' then
        point, relPoint, x, y = 'BOTTOM', 'TOP', 0, 1
    elseif direction == 'DOWN' then
        point, relPoint, x, y = 'TOP', 'BOTTOM', 0, -1
    elseif direction == 'LEFT' then
        point, relPoint, x, y = 'RIGHT', 'LEFT', -1, 0
    else
        point, relPoint, x, y = 'LEFT', 'RIGHT', 1, 0
    end

    for i = 1, #entries do
        local entry = entries[i]

        if i <= numEntries then
            local offset = ListPadding + (i - 1) * EntryStep

            entry:SetAttribute('action', action)
            entry:SetAttribute('spell', i == 1 and 0 or (select(i - 1, GetMultiCastTotemSpells(slot))))
            entry:ClearAllPoints()
            entry:SetPoint(point, list, point, x * offset, y * offset)
            entry:Show()
        else
            entry:Hide()
        end
    end

    local length = numEntries * EntryStep - ListSpacing + ListPadding * 2
    local thickness = EntrySize + ListPadding * 2

    if x == 0 then
        list:SetWidth(thickness)
        list:SetHeight(length)
    else
        list:SetWidth(length)
        list:SetHeight(thickness)
    end

    list:ClearAllPoints()
    list:SetPoint(point, arrow, relPoint)
    list:Show()

    self:CallMethod('UpdateEntryIcons')
]]

--------------------------------------------------------------------------------
-- Arrow art
--------------------------------------------------------------------------------

local ARROW_LEFT, ARROW_RIGHT, ARROW_TOP, ARROW_BOTTOM = 99 / 128, 127 / 128, 84 / 256, 102 / 256

local ARROW_CORNER_COORDS = {
    ul = { ARROW_LEFT, ARROW_TOP },
    ll = { ARROW_LEFT, ARROW_BOTTOM },
    ur = { ARROW_RIGHT, ARROW_TOP },
    lr = { ARROW_RIGHT, ARROW_BOTTOM },
}

-- texture corner that goes in each arrow corner (ul, ll, ur, lr) to point the
-- way the list opens
local ARROW_CORNERS = {
    UP = { 'ul', 'll', 'ur', 'lr' },
    DOWN = { 'lr', 'ur', 'll', 'ul' },
    LEFT = { 'ur', 'ul', 'lr', 'll' },
    RIGHT = { 'll', 'lr', 'ul', 'ur' },
}

local function setArrowDirection(arrow, direction)
    local ul, ll, ur, lr = unpack(ARROW_CORNERS[direction])
    local coords = ARROW_CORNER_COORDS

    arrow:GetNormalTexture():SetTexCoord(
        coords[ul][1], coords[ul][2],
        coords[ll][1], coords[ll][2],
        coords[ur][1], coords[ur][2],
        coords[lr][1], coords[lr][2]
    )

    if direction == 'LEFT' or direction == 'RIGHT' then
        arrow:SetSize(18, 28)
    else
        arrow:SetSize(28, 18)
    end
end

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

local ArrowMixin = {}

function ArrowMixin:UpdateEntryIcons()
    for _, entry in ipairs(self.entries) do
        if entry:IsShown() then
            local spellId = entry:GetAttribute('spell')

            entry.icon:SetTexture(spellId and spellId > 0 and C_Spell.GetSpellTexture(spellId) or CLEAR_ICON)
        end
    end
end

-- out of combat, the arrow is protected
function ArrowMixin:SetFlyoutDirection(direction)
    if InCombatLockdown() or self:GetAttribute('flyoutDirection') == direction then
        return
    end

    self:SetAttribute('flyoutDirection', direction)
    self.list:Hide()
    self:Hide()
    setArrowDirection(self, direction)
end

-- Tooltips goes first so our wrap is outermost, its wrap can cancel OnEnter and
-- the arrow would never show. unwrapping pops the outermost, so it's the reverse
function ArrowMixin:HookButton(button)
    Addon:GetModule('Tooltips'):Register(button)

    -- wrapping turns mouse on, put it back for click through
    local mouseEnabled = button:IsMouseEnabled()

    self:WrapScript(button, 'OnEnter', totemButton_OnEnter)
    self:WrapScript(button, 'OnLeave', hoverGroup_OnLeave)

    button:EnableMouse(mouseEnabled)
end

function ArrowMixin:UnhookButton(button)
    local mouseEnabled = button:IsMouseEnabled()

    self:UnwrapScript(button, 'OnEnter')
    self:UnwrapScript(button, 'OnLeave')

    button:EnableMouse(mouseEnabled)

    Addon:GetModule('Tooltips'):Unregister(button)
end

-- a wrapped OnLeave only runs if OnEnter is wrapped too
local function wrapHover(frame, arrow)
    arrow:WrapScript(frame, 'OnEnter', [[ return ]])
    arrow:WrapScript(frame, 'OnLeave', hoverGroup_OnLeave)
end

local function createEntry(list, arrow)
    local entry = CreateFrame('Button', nil, list, 'SecureActionButtonTemplate')
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

    entry.icon = entry:CreateTexture(nil, 'ARTWORK')
    entry.icon:SetAllPoints()

    arrow:SetFrameRef('entry', entry)
    arrow:Execute([[ entries[#entries + 1] = self:GetFrameRef('entry') ]])

    -- close on pick. post body only runs if the pre body returns a message
    arrow:WrapScript(entry, 'OnClick', [[ return nil, 'close' ]], [[ list:Hide() ]])
    wrapHover(entry, arrow)

    return entry
end

function TotemPicker:Create(bar)
    local arrow = CreateFrame('Button', nil, bar, 'SecureHandlerClickTemplate')
    arrow:SetFrameStrata('HIGH')
    arrow:SetNormalTexture('Interface\\Buttons\\UI-TotemBar')
    arrow:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
    arrow:Hide()
    setArrowDirection(arrow, 'UP')

    Mixin(arrow, ArrowMixin)
    arrow.entries = {}

    local list = CreateFrame('Frame', nil, arrow, 'SecureHandlerBaseTemplate')
    list:SetFrameStrata('DIALOG')
    list:SetSize(ENTRY_SIZE, ENTRY_SIZE)
    list:SetPoint('BOTTOM', arrow, 'TOP')
    list:EnableMouse(true)
    list:Hide()

    local bg = list:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)

    arrow.list = list

    arrow:SetFrameRef('list', list)
    -- restricted code can't read globals
    arrow:Execute(([[
        arrow = self
        list = self:GetFrameRef('list')
        entries = table.new()
        hovered = nil

        EntrySize = %d
        EntryStep = %d
        ListPadding = %d
        ListSpacing = %d
    ]]):format(ENTRY_SIZE, ENTRY_SIZE + SPACING, PADDING, SPACING))

    for i = 1, MAX_ENTRIES do
        arrow.entries[i] = createEntry(list, arrow)
    end

    arrow:SetAttribute('_onclick', arrow_OnClick)

    wrapHover(arrow, arrow)
    wrapHover(list, arrow)

    return arrow
end

-- export
Addon.TotemPicker = TotemPicker
