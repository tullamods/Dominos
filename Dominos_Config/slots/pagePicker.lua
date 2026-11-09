-- A dialog for picking where a bar pages to for a state. Hovering a cell
-- highlights the addresses the bar would show from there, clicking saves it.
--
-- It edits one control of a context menu at a time: Addon:ShowPagePicker(row)

local _, Addon = ...
local ParentAddon = Addon:GetParent()
local L = Addon:GetLocale()

local COLORS = {
    -- hovered runs, by start status
    valid = { 1, 0.82, 0, 0.5 },
    partial = { 1, 0.5, 0, 0.5 },
    invalid = { 1, 0.1, 0.1, 0.5 },
    selected = { 0.1, 1, 0.1, 0.4 },
    bar = { 0.3, 0.6, 1, 0.25 }
}

local PADDING = 12
local SCROLLBAR_WIDTH = 16
local TITLE_HEIGHT = 20
local HEIGHT = 480
local MIN_HEIGHT = 200
local DEFAULT_COLUMNS = 12
local MIN_COLUMNS = 6

local Picker

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local function getBar()
    return Picker.row.menu.owner
end

local function getOffset()
    return Picker.row.menu:GetValue(Picker.row.def)
end

local function inRun(address, first, length)
    return first and address >= first and address < first + length
end

-- whether the bar can start at an address: 'valid', 'invalid', or 'partial'
-- when the run crosses addresses that can't hold actions
local function getStartStatus(address)
    local AddressMap = ParentAddon.AddressMap
    local last = address + getBar():NumButtons() - 1

    if AddressMap:GetSlot(address) == 0 or last > AddressMap:GetNumAddresses() then
        return 'invalid'
    end

    for i = address + 1, last do
        if AddressMap:GetSlot(i) == 0 then
            return 'partial'
        end
    end

    return 'valid'
end

local function setOffset(offset)
    Picker.row.menu:SetValue(Picker.row.def, offset)
    Addon:RefreshControl(Picker.row)
    Picker.usage = Addon:GetActionSlotUsage()
    Picker.Grid:UpdateColors()
end

--------------------------------------------------------------------------------
-- Grid hooks
--------------------------------------------------------------------------------

local function grid_GetCellColor(_, cell)
    if not Picker.row then
        return
    end

    local address = cell.address
    local length = getBar():NumButtons()
    local hover = Picker.hoverAddress

    if inRun(address, hover, length) then
        return COLORS[Picker.hoverStatus]
    end

    local offset = getOffset()
    if inRun(address, offset and offset + 1, length) then
        return COLORS.selected
    end

    if Picker.usage.base[address] then
        return COLORS.bar
    end
end

local function grid_OnCellEnter(grid, cell)
    Picker.hoverAddress = cell.address
    Picker.hoverStatus = getStartStatus(cell.address)
    grid:UpdateColors()
end

local function grid_OnCellLeave(grid)
    Picker.hoverAddress = nil
    Picker.hoverStatus = nil
    grid:UpdateColors()
end

local function grid_OnCellClick(_, cell)
    if getStartStatus(cell.address) ~= 'invalid' then
        setOffset(cell.address - 1)
    end
end

local function grid_OnCellTooltip(_, cell, tooltip)
    Addon:AddActionSlotUsageToTooltip(tooltip, Picker.usage, cell.address)
end

--------------------------------------------------------------------------------
-- Dialog
--------------------------------------------------------------------------------

local function createPicker()
    local frame = CreateFrame('Frame', 'DominosPagePicker', UIParent, 'DefaultPanelFlatTemplate')
    frame:SetFrameStrata('DIALOG')
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:Hide()

    -- parented to a context menu, which lays out its children
    frame.ignoreInLayout = true

    frame.CloseButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButtonDefaultAnchors')

    local grid = Addon:CreateActionSlotGrid(frame)
    grid:SetPoint('TOPLEFT', PADDING, -(TITLE_HEIGHT + PADDING))
    grid:SetPoint('BOTTOMRIGHT', -(PADDING + SCROLLBAR_WIDTH), 40)
    grid.OnCellEnter = grid_OnCellEnter
    grid.OnCellLeave = grid_OnCellLeave
    grid.OnCellClick = grid_OnCellClick
    grid.OnCellTooltip = grid_OnCellTooltip
    grid.GetCellColor = grid_GetCellColor
    frame.Grid = grid

    -- resizable from the bottom right corner
    local chromeWidth = PADDING * 2 + SCROLLBAR_WIDTH
    frame:SetSize(grid:GetColumnsWidth(DEFAULT_COLUMNS) + chromeWidth, HEIGHT)
    frame:SetResizable(true)

    local resize = CreateFrame('Button', nil, frame, 'PanelResizeButtonTemplate')
    resize:SetPoint('BOTTOMRIGHT', -4, 4)
    resize:Init(frame, grid:GetColumnsWidth(MIN_COLUMNS) + chromeWidth, MIN_HEIGHT)
    frame.ResizeButton = resize

    local clear = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    clear:SetSize(120, 22)
    clear:SetPoint('BOTTOMLEFT', PADDING, 10)
    clear:SetText(L.PagingClear)
    clear:SetScript('OnClick', function()
        setOffset(nil)
    end)
    frame.ClearButton = clear

    frame:SetScript('OnShow', function(self)
        self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
    end)

    frame:SetScript('OnHide', function(self)
        self:UnregisterAllEvents()
        self.row = nil
        self.hoverAddress = nil
        self.hoverStatus = nil
    end)

    -- paging can't change in combat
    frame:SetScript('OnEvent', function(self, event)
        if event == 'PLAYER_REGEN_DISABLED' then
            self:Hide()
        else
            self.Grid:UpdateIcons()
        end
    end)

    tinsert(UISpecialFrames, frame:GetName())

    return frame
end

-- opens the picker for a page picker control of a context menu
function Addon:ShowPagePicker(row)
    if InCombatLockdown() then
        return
    end

    Picker = Picker or createPicker()
    Picker.row = row
    Picker.hoverAddress = nil
    Picker.hoverStatus = nil
    Picker.usage = Addon:GetActionSlotUsage()

    -- "Action Bar 1: Cat Form"
    Picker:SetTitle(L.BarState:format(row.menu.owner:GetDisplayName(), row.Label:GetText()))

    -- parented to the menu, so it closes with it
    Picker:SetParent(row.menu)
    Picker:SetFrameStrata('DIALOG')
    Picker:ClearAllPoints()
    Picker:SetPoint('TOPLEFT', row.menu, 'TOPRIGHT', 8, 0)
    Picker:Show()

    -- colors and icons are applied as cells are initialized
    Picker.Grid:Refresh()

    -- the selection, else where the bar rests
    local offset = getOffset() or getBar():GetBaseOffset()
    Picker.Grid:ScrollToAddress(offset + 1)
end

-- closes the picker, if it's editing this control
function Addon:HidePagePicker(row)
    if Picker and Picker.row == row then
        Picker:Hide()
    end
end

function Addon:TogglePagePicker(row)
    if Picker and Picker.row == row and Picker:IsShown() then
        Picker:Hide()
    else
        self:ShowPagePicker(row)
    end
end
