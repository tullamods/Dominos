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
local HEIGHT = 600
local MIN_HEIGHT = 300

local Book

--------------------------------------------------------------------------------
-- Grid hooks
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Dialog
--------------------------------------------------------------------------------

-- beside the spellbook, at its height
local function dock(frame)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', frame.anchor, 'TOPRIGHT', 2, 0)
    frame:SetPoint('BOTTOMLEFT', frame.anchor, 'BOTTOMRIGHT', 2, 0)
    frame.docked = true
end

local function createBook()
    local frame = Addon:CreateActionSlotDialog('DominosActionBook', CELL_SIZE, HEIGHT, MIN_HEIGHT)
    frame:SetFrameStrata('FULLSCREEN_DIALOG')
    frame:SetPoint('CENTER')
    frame:SetTitle(L.ActionBook)

    -- dragging undocks it. it still closes with the spellbook
    frame:SetScript('OnDragStart', function(self)
        self.docked = nil
        self:SetHeight(self:GetHeight())
        self:StartMoving()
    end)

    local grid = frame.Grid
    grid.OnCellDragStart = grid_OnCellDragStart
    grid.OnCellReceiveDrag = grid_OnCellReceiveDrag
    grid.OnCellClick = grid_OnCellClick
    grid.showActions = true

    local spellbook = CreateFrame('CheckButton', nil, frame, 'UICheckButtonTemplate')
    spellbook:SetSize(24, 24)
    spellbook:SetPoint('BOTTOMLEFT', 8, 8)
    spellbook:SetScript('OnClick', function(checkbox)
        ParentAddon:SetShowActionBookWithSpellbook(checkbox:GetChecked())
    end)

    local spellbookLabel = spellbook:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
    spellbookLabel:SetPoint('LEFT', spellbook, 'RIGHT', 2, 0)
    spellbookLabel:SetText(L.ShowWithSpellbook)

    -- clicks on the label reach the check box
    spellbook:SetHitRectInsets(0, -(spellbookLabel:GetStringWidth() + 2), 0, 0)
    frame.SpellbookCheck = spellbook

    -- beside the spellbook, only the width changes
    frame.onResizeStartCallback = function(button)
        if frame.docked then
            local height = frame:GetHeight()
            button.minHeight, button.maxHeight = height, height
        else
            button.minHeight, button.maxHeight = MIN_HEIGHT, nil
        end

        return true
    end

    -- sizing drops the anchors
    frame.ResizeButton.resizeStoppedCallback = function()
        if frame.docked then
            dock(frame)
        end
    end

    frame:HookScript('OnShow', function(self)
        self.SpellbookCheck:SetChecked(ParentAddon:ShowingActionBookWithSpellbook())
        self.Grid:Refresh()
    end)

    -- the grid's rows follow bar length
    local function refresh()
        if frame:IsShown() then
            frame.Grid:Refresh()
        end
    end

    ParentAddon.RegisterCallback(frame, 'ACTIONBARS_UPDATED', refresh)
    ParentAddon.RegisterCallback(frame, 'LAYOUT_LOADED', refresh)

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

    Book.anchor = anchor

    if anchor then
        dock(Book)
    elseif Book.docked then
        Book.docked = nil
        Book:ClearAllPoints()
        Book:SetPoint('CENTER')
        Book:SetHeight(HEIGHT)
    end

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
