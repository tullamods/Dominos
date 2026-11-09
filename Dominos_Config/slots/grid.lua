-- A scrollable grid of action slots, laid out from the address map's regions,
-- in address order. It only shows slots: whoever uses it decides what hovering,
-- clicking and dragging a cell does, and how cells are colored.
--
-- Hooks, set on the grid:
--   grid.OnCellEnter(grid, cell)            the mouse entered a cell
--   grid.OnCellLeave(grid, cell)            the mouse left a cell
--   grid.OnCellClick(grid, cell, button)    a cell was clicked
--   grid.OnCellTooltip(grid, cell, tooltip) add lines to a cell's tooltip
--   grid.OnCellDragStart(grid, cell)        a cell started being dragged
--   grid.OnCellReceiveDrag(grid, cell)      something was dropped on a cell
--   grid.GetCellColor(grid, cell)           a cell's overlay color, or nil
--
-- cell.slot is the cell's action slot, cell.address its address. tooltips
-- already have the address's name as their title

local _, Addon = ...
local ParentAddon = Addon:GetParent()

local DEFAULT_CELL_SIZE = 24
local CELL_SPACING = 2
local HEADER_HEIGHT = 16
local LABEL_HEIGHT = 14
local ROW_SPACING = 6
local SECTION_SPACING = 12

-- extra space after each group of a row that has them
local GROUP_SPACING = 8

local HasAction = C_ActionBar and C_ActionBar.HasAction or HasAction
local GetActionTexture = C_ActionBar and C_ActionBar.GetActionTexture or GetActionTexture

--------------------------------------------------------------------------------
-- Elements
--------------------------------------------------------------------------------

-- the flat list the scroll box lays out:
--   { text, font, height }  a header or row label, a full line
--   { address, slot }       a cell
--   { cells }               a group of cells, wrapped as a whole

local function cellsOf(address, size)
    local AddressMap = ParentAddon.AddressMap
    local cells = {}

    for i = address, address + size - 1 do
        cells[#cells + 1] = { address = i, slot = AddressMap:GetSlot(i) }
    end

    return cells
end

local function buildElements()
    local regions = ParentAddon.AddressMap:GetRegions()
    local rowLength = ParentAddon:GetActionBarLength()
    local elements = {}

    local function add(element)
        elements[#elements + 1] = element
    end

    local function addHeader(text)
        local spacing = #elements > 0 and SECTION_SPACING or 0

        add { text = text, font = 'GameFontNormal', height = HEADER_HEIGHT + spacing }
    end

    local function addLabel(text)
        add { text = text, font = 'GameFontHighlightSmall', height = LABEL_HEIGHT + ROW_SPACING }
    end

    local function addCells(address, size)
        for _, cell in ipairs(cellsOf(address, size)) do
            add(cell)
        end
    end

    -- a row is its label, then its cells, or its children's cells as groups
    local function addRow(region)
        addLabel(region.label)

        if region.children then
            for _, child in ipairs(region.children) do
                add { cells = cellsOf(child.address, child.size) }
            end
        else
            addCells(region.address, region.size)
        end
    end

    -- each top level region is a section, and its children are rows. a
    -- section that's a region of its own (a gamepad page) shows its loose
    -- addresses (the no modifier D-pad) first, unlabeled
    for _, region in ipairs(regions) do
        if region.available and not region.parent then
            addHeader(region.name)

            if region.children then
                for _, child in ipairs(region.children) do
                    if child.available then
                        if region.section or child.children then
                            addRow(child)
                        else
                            add { cells = cellsOf(child.address, child.size) }
                        end
                    end
                end
            else
                -- Unused, in rows the length of the player's bars
                for address = region.address, region.address + region.size - 1, rowLength do
                    addLabel(ParentAddon.AddressMap:GetName(address))
                    addCells(address, math.min(rowLength, region.address + region.size - address))
                end
            end
        end
    end

    return elements
end

--------------------------------------------------------------------------------
-- Cells
--------------------------------------------------------------------------------

local function cell_OnEnter(cell)
    local grid = cell.grid

    GameTooltip:SetOwner(cell, 'ANCHOR_RIGHT')
    GameTooltip:SetText(ParentAddon.AddressMap:GetAddressName(cell.address))

    if grid.OnCellTooltip then
        grid:OnCellTooltip(cell, GameTooltip)
    end

    GameTooltip:Show()

    if grid.OnCellEnter then
        grid:OnCellEnter(cell)
    end
end

local function cell_OnLeave(cell)
    local grid = cell.grid

    GameTooltip:Hide()

    if grid.OnCellLeave then
        grid:OnCellLeave(cell)
    end
end

local function cell_OnDragStart(cell)
    local grid = cell.grid

    if grid.OnCellDragStart then
        grid:OnCellDragStart(cell)
    end
end

local function cell_OnReceiveDrag(cell)
    local grid = cell.grid

    if grid.OnCellReceiveDrag then
        grid:OnCellReceiveDrag(cell)
    end
end

local function cell_OnClick(cell, button)
    local grid = cell.grid

    if grid.OnCellClick then
        grid:OnCellClick(cell, button)
    end
end

-- sets up a pooled button as a cell, once
local function setUpCell(grid, cell)
    if cell.grid then
        return
    end

    cell.grid = grid
    cell:SetSize(grid.cellSize, grid.cellSize)
    cell:RegisterForClicks('AnyUp')
    cell:RegisterForDrag('LeftButton')
    cell:SetScript('OnDragStart', cell_OnDragStart)
    cell:SetScript('OnReceiveDrag', cell_OnReceiveDrag)
    cell:SetScript('OnEnter', cell_OnEnter)
    cell:SetScript('OnLeave', cell_OnLeave)
    cell:SetScript('OnClick', cell_OnClick)

    local background = cell:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)

    local icon = cell:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('TOPLEFT', 1, -1)
    icon:SetPoint('BOTTOMRIGHT', -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.Icon = icon

    local overlay = cell:CreateTexture(nil, 'OVERLAY')
    overlay:SetAllPoints()
    overlay:Hide()
    cell.Overlay = overlay

    cell:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
end

local function updateIcon(cell)
    local texture = HasAction(cell.slot) and GetActionTexture(cell.slot)

    cell.Icon:SetTexture(texture or nil)
    cell.Icon:SetShown(texture and true or false)
end

local function updateColor(cell)
    local grid = cell.grid
    local color = grid.GetCellColor and grid:GetCellColor(cell)

    if color then
        cell.Overlay:SetColorTexture(unpack(color))
        cell.Overlay:Show()
    else
        cell.Overlay:Hide()
    end
end

local function initCell(grid, cell, data)
    setUpCell(grid, cell)

    cell.address = data.address
    cell.slot = data.slot

    updateIcon(cell)
    updateColor(cell)
end

--------------------------------------------------------------------------------
-- Text and groups
--------------------------------------------------------------------------------

-- pooled frames are either text or a group of cells, so they can be both
local function initFrame(grid, frame, data)
    local text = frame.Text
    if data.text and not text then
        text = frame:CreateFontString(nil, 'ARTWORK')
        text:SetPoint('BOTTOMLEFT')
        text:SetPoint('BOTTOMRIGHT')
        text:SetJustifyH('LEFT')
        text:SetWordWrap(false)
        frame.Text = text
    end

    if text then
        text:SetShown(data.text ~= nil)

        if data.text then
            text:SetFontObject(data.font)
            text:SetText(data.text)
        end
    end

    local cells = frame.cells or {}
    frame.cells = cells

    local count = data.cells and #data.cells or 0

    for i = 1, count do
        local cell = cells[i]

        if not cell then
            cell = CreateFrame('Button', nil, frame)
            cell:SetPoint('TOPLEFT', (i - 1) * (grid.cellSize + CELL_SPACING), 0)
            cells[i] = cell
        end

        initCell(grid, cell, data.cells[i])
        cell:Show()
    end

    for i = count + 1, #cells do
        cells[i]:Hide()
    end
end

local function getElementSize(grid, data)
    if data.text then
        return ScrollBoxConstants.FillExtent, data.height
    end

    if data.cells then
        return grid:GetColumnsWidth(#data.cells) + GROUP_SPACING, grid.cellSize
    end

    return grid.cellSize, grid.cellSize
end

--------------------------------------------------------------------------------
-- Grid
--------------------------------------------------------------------------------

local GridMixin = {}

-- rebuilds from the regions, for the current bar length
function GridMixin:Refresh()
    self:SetDataProvider(CreateDataProvider(buildElements()), ScrollBoxConstants.RetainScrollPosition)
end

-- centers the cell, or group, holding an address
function GridMixin:ScrollToAddress(address)
    self:ScrollToElementDataByPredicate(function(data)
        if data.address then
            return data.address == address
        end

        local cells = data.cells
        return cells and cells[1].address <= address and address <= cells[#cells].address
    end, ScrollBoxConstants.AlignCenter, 0, ScrollBoxConstants.NoScrollInterpolation)
end

-- the width of a number of slot columns
function GridMixin:GetColumnsWidth(columns)
    return columns * (self.cellSize + CELL_SPACING) - CELL_SPACING
end

-- calls func(cell) for every cell shown
function GridMixin:ForEachCell(func)
    self:ForEachFrame(function(frame, data)
        if data.slot then
            func(frame)
        elseif data.cells then
            for i = 1, #data.cells do
                func(frame.cells[i])
            end
        end
    end)
end

-- re-reads GetCellColor
function GridMixin:UpdateColors()
    self:ForEachCell(updateColor)
end

-- shows each cell's current action
function GridMixin:UpdateIcons()
    self:ForEachCell(updateIcon)
end

-- cellSize is optional, and defaults to a compact size. the scroll bar sits
-- just right of the grid, and hides when there's nothing to scroll
function Addon:CreateActionSlotGrid(parent, cellSize)
    local grid = CreateFrame('Frame', nil, parent, 'WowScrollBoxList')
    Mixin(grid, GridMixin)
    grid.cellSize = cellSize or DEFAULT_CELL_SIZE

    local scrollBar = CreateFrame('EventFrame', nil, parent, 'MinimalScrollBar')
    scrollBar:SetPoint('TOPLEFT', grid, 'TOPRIGHT', 6, 0)
    scrollBar:SetPoint('BOTTOMLEFT', grid, 'BOTTOMRIGHT', 6, 0)
    grid.ScrollBar = scrollBar

    local view = CreateScrollBoxListSequenceView(0, 0, 0, 0, CELL_SPACING, CELL_SPACING)

    view:SetElementFactory(function(factory, data)
        if data.slot then
            factory('Button', function(cell, cellData)
                initCell(grid, cell, cellData)
            end)
        else
            factory('Frame', function(frame, frameData)
                initFrame(grid, frame, frameData)
            end)
        end
    end)

    view:SetElementSizeCalculator(function(_, data)
        return getElementSize(grid, data)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(grid, scrollBar, view)
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(grid, scrollBar)

    return grid
end
