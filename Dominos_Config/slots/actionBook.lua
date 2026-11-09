-- The action book: every action slot, by action bar page. Drag spells, items
-- and macros onto slots, drag actions between slots, or click a slot to pick
-- up its action. Out of combat only.
--
-- Opened by hand (/dom actions), or beside the spellbook: Addon:ShowActionBook(anchor)

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

-- about action button size, so slots are easy to drop on
local CELL_SIZE = 36
local PADDING = 12
local SCROLLBAR_WIDTH = 16
local TITLE_HEIGHT = 20
local FOOTER_HEIGHT = 40
local DEFAULT_COLUMNS = 12
local MIN_COLUMNS = 6
local HEIGHT = 600
local MIN_HEIGHT = 300

local HasAction = C_ActionBar and C_ActionBar.HasAction or HasAction

local Book

--------------------------------------------------------------------------------
-- Grid hooks
--------------------------------------------------------------------------------

-- the book closes in combat, so none of these need to check
local function grid_OnCellDragStart(_, cell)
    PickupAction(cell.slot)
end

local function grid_OnCellReceiveDrag(_, cell)
    PlaceAction(cell.slot)
end

-- places what's on the cursor, else picks up the slot's action
local function grid_OnCellClick(_, cell)
    if GetCursorInfo() then
        PlaceAction(cell.slot)
    else
        PickupAction(cell.slot)
    end
end

-- the slot's action, then its name. usage is read on hover, so paging changes
-- need no refresh
local function grid_OnCellTooltip(_, cell, tooltip)
    if HasAction(cell.slot) then
        tooltip:SetAction(cell.slot)
        tooltip:AddLine(ParentAddon.AddressMap:GetAddressName(cell.address), 1, 1, 1)
    end

    Addon:AddActionSlotUsageToTooltip(tooltip, Addon:GetActionSlotUsage(), cell.address)
end

--------------------------------------------------------------------------------
-- Dialog
--------------------------------------------------------------------------------

-- beside the spellbook, at its height
local function anchorTo(frame, anchor)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', anchor, 'TOPRIGHT', 2, 0)
    frame:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMRIGHT', 2, 0)
end

local function createBook()
    local frame = CreateFrame('Frame', 'DominosActionBook', UIParent, 'DefaultPanelFlatTemplate')
    frame:SetFrameStrata('FULLSCREEN_DIALOG')
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', function(self)
        if not self.anchor then
            self:StartMoving()
        end
    end)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:SetPoint('CENTER')
    frame:SetTitle(L.ActionBook)
    frame:Hide()

    frame.CloseButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButtonDefaultAnchors')

    local grid = Addon:CreateActionSlotGrid(frame, CELL_SIZE)
    grid:SetPoint('TOPLEFT', PADDING, -(TITLE_HEIGHT + PADDING))
    grid:SetPoint('BOTTOMRIGHT', -(PADDING + SCROLLBAR_WIDTH), FOOTER_HEIGHT)
    grid.OnCellDragStart = grid_OnCellDragStart
    grid.OnCellReceiveDrag = grid_OnCellReceiveDrag
    grid.OnCellClick = grid_OnCellClick
    grid.OnCellTooltip = grid_OnCellTooltip
    frame.Grid = grid

    local spellbook = CreateFrame('CheckButton', nil, frame, 'UICheckButtonTemplate')
    spellbook:SetSize(24, 24)
    spellbook:SetPoint('BOTTOMLEFT', PADDING - 4, 8)
    spellbook:SetScript('OnClick', function(checkbox)
        ParentAddon:SetShowActionBookWithSpellbook(checkbox:GetChecked())
    end)

    local spellbookLabel = spellbook:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    spellbookLabel:SetPoint('LEFT', spellbook, 'RIGHT', 2, 0)
    spellbookLabel:SetText(L.ShowWithSpellbook)

    -- clicks on the label reach the check box
    spellbook:SetHitRectInsets(0, -(spellbookLabel:GetStringWidth() + 2), 0, 0)
    frame.SpellbookCheck = spellbook

    local chromeWidth = PADDING * 2 + SCROLLBAR_WIDTH
    frame:SetSize(grid:GetColumnsWidth(DEFAULT_COLUMNS) + chromeWidth, HEIGHT)
    frame:SetResizable(true)

    local resize = CreateFrame('Button', nil, frame, 'PanelResizeButtonTemplate')
    resize:SetPoint('BOTTOMRIGHT', -4, 4)
    resize:Init(frame, grid:GetColumnsWidth(MIN_COLUMNS) + chromeWidth, MIN_HEIGHT)

    -- beside the spellbook, only the width changes
    frame.onResizeStartCallback = function(button)
        if frame.anchor then
            local height = frame:GetHeight()
            button.minHeight, button.maxHeight = height, height
        else
            button.minHeight, button.maxHeight = MIN_HEIGHT, nil
        end

        return true
    end

    -- sizing drops the anchors
    resize.resizeStoppedCallback = function()
        if frame.anchor then
            anchorTo(frame, frame.anchor)
        end
    end

    frame:SetScript('OnShow', function(self)
        self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
        self.SpellbookCheck:SetChecked(ParentAddon:ShowingActionBookWithSpellbook())
        self.Grid:Refresh()
    end)

    frame:SetScript('OnHide', function(self)
        self:UnregisterAllEvents()
    end)

    frame:SetScript('OnEvent', function(self, event)
        if event == 'PLAYER_REGEN_DISABLED' then
            self:Hide()
        else
            self.Grid:UpdateIcons()
        end
    end)

    -- the grid's rows follow bar length
    local function refresh()
        if frame:IsShown() then
            frame.Grid:Refresh()
        end
    end

    ParentAddon.RegisterCallback(frame, 'ACTIONBARS_UPDATED', refresh)
    ParentAddon.RegisterCallback(frame, 'LAYOUT_LOADED', refresh)

    tinsert(UISpecialFrames, frame:GetName())

    return frame
end

-- opens it, beside anchor if given. if it was opened by hand, the spellbook
-- leaves it alone
function Addon:ShowActionBook(anchor)
    if InCombatLockdown() then
        return
    end

    Book = Book or createBook()

    if anchor and Book:IsShown() and not Book.anchor then
        return
    end

    if anchor then
        anchorTo(Book, anchor)
    elseif Book.anchor then
        Book:ClearAllPoints()
        Book:SetPoint('CENTER')
        Book:SetHeight(HEIGHT)
    end

    Book.anchor = anchor
    Book:Show()
end

-- closes it, if it's beside anchor
function Addon:HideActionBook(anchor)
    if Book and Book.anchor and Book.anchor == anchor then
        Book:Hide()
    end
end

function Addon:ToggleActionBook()
    if Book and Book:IsShown() then
        Book:Hide()
    else
        self:ShowActionBook()
    end
end
