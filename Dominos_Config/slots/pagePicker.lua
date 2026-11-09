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

local HEIGHT = 480
local MIN_HEIGHT = 200

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

local function clearHover()
    Picker.hoverAddress = nil
    Picker.hoverStatus = nil
end

local function setOffset(offset)
    Picker.row.menu:SetValue(Picker.row.def, offset)
    Addon:RefreshControl(Picker.row)
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

    if ParentAddon:GetBarAt(address) then
        return COLORS.bar
    end
end

local function grid_OnCellEnter(grid, cell)
    Picker.hoverAddress = cell.address
    Picker.hoverStatus = getStartStatus(cell.address)
    grid:UpdateColors()
end

local function grid_OnCellLeave(grid)
    clearHover()
    grid:UpdateColors()
end

local function grid_OnCellClick(_, cell)
    if getStartStatus(cell.address) ~= 'invalid' then
        setOffset(cell.address - 1)
    end
end

--------------------------------------------------------------------------------
-- Dialog
--------------------------------------------------------------------------------

local function createPicker()
    local frame = Addon:CreateActionSlotDialog('DominosPagePicker', nil, HEIGHT, MIN_HEIGHT)

    -- parented to a context menu, which lays out its children
    frame.ignoreInLayout = true

    local grid = frame.Grid
    grid.OnCellEnter = grid_OnCellEnter
    grid.OnCellLeave = grid_OnCellLeave
    grid.OnCellClick = grid_OnCellClick
    grid.GetCellColor = grid_GetCellColor

    local clear = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    clear:SetSize(120, 22)
    clear:SetPoint('BOTTOMLEFT', 12, 10)
    clear:SetText(L.PagingClear)
    clear:SetScript('OnClick', function()
        setOffset(nil)
    end)
    frame.ClearButton = clear

    frame:HookScript('OnHide', function(self)
        self.row = nil
        clearHover()
    end)

    return frame
end

-- opens the picker for a page picker control of a context menu
function Addon:ShowPagePicker(row)
    if InCombatLockdown() then
        return
    end

    Picker = Picker or createPicker()
    Picker.row = row
    clearHover()

    -- "Action Bar 1: Cat Form"
    Picker:SetTitle(L.BarState:format(row.menu.owner:GetDisplayName(), row.Label:GetText()))

    -- parented to the menu, so it closes with it
    Picker:SetParent(row.menu)
    Picker:SetFrameStrata('DIALOG')
    Picker:ClearAllPoints()
    Picker:SetPoint('TOPLEFT', row.menu, 'TOPRIGHT', 8, 0)
    Picker:Show()

    -- cells pick up their colors and icons as they're set up
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
