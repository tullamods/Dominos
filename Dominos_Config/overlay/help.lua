--------------------------------------------------------------------------------
-- Overlay UI Help Dialog
-- Shows information about how to configure bars in configuration mode
--------------------------------------------------------------------------------

local _, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Addon:GetParent():GetName())

local GRID_SIZE_MINIMUM = 1
local GRID_SIZE_MAXIMUM = 128
local GRID_SIZE_STEP = 1

local HelpDialog = CreateFrame('Frame', nil, nil, 'VerticalLayoutFrame'); HelpDialog:Hide()

function HelpDialog:OnLoad(owner)
    self:SetParent(owner)
    self:EnableMouse(true)
    self:RegisterForDrag('LeftButton')
    self:SetClampedToScreen(true)
    self:SetFrameStrata('FULLSCREEN_DIALOG')
    self:SetMovable(true)
    self:SetSize(360, 120)
    self:SetPoint('TOP', 0, -24)
    self:SetScript('OnDragStart', self.OnDragStart)
    self:SetScript('OnDragStop', self.OnDragStop)

    self.minimumWidth = 320
    self.minimumHeight = 120
    self.topPadding = 36
    self.bottomPadding = 18
    self.leftPadding = 18
    self.rightPadding = 18
    self.spacing = 10

    self.Border = CreateFrame('Frame', nil, self, 'DialogBorderTemplate')
    self.Border.ignoreInLayout = true

    self.Header = CreateFrame('Frame', nil, self, 'DialogHeaderTemplate')
    self.Header.Text:SetText(L.ConfigMode)
    self.Header.ignoreInLayout = true

    local close = CreateFrame('Button', nil, self, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT', 3, 4)
    close.ignoreInLayout = true
    self.onCloseCallback = function() Addon:GetParent():SetLock(true); end

    local description = self:CreateFontString(nil, 'ARTWORK')
    description:SetFontObject('GameFontHighlight')
    description:SetJustifyV('TOP')
    description:SetJustifyH('LEFT')
    description:SetText(L.ConfigModeHelp)
    description:SetWidth(320)
    description.layoutIndex = 1
    description.expand = true

    self.Description = description

    local showGrid = Addon:CreateCheckButton {
        label = L.ShowAlignmentGrid,
        parent = self,
        get = function() return Dominos:GetAlignmentGridEnabled(); end,
        set = function(_, enable) print("showGrid", enable); Dominos:SetAlignmentGridEnabled(enable); end,
    }

    showGrid.layoutIndex = 2
    showGrid.expand = true

    local gridDensity = Addon:CreateSlider {
        label = L.GridDensity,
        parent = self,
        min = GRID_SIZE_MINIMUM,
        max = GRID_SIZE_MAXIMUM,
        step = GRID_SIZE_STEP,
        get = function() return Dominos:GetAlignmentGridSize(); end,
        set = function(value) Dominos:SetAlignmentGridSize(value); end,
    }

    gridDensity.layoutIndex = 3
    gridDensity.expand = true

    self:Show()
end

function HelpDialog:OnDragStart()
    self:StartMoving()
end

function HelpDialog:OnDragStop()
    self:StopMovingOrSizing()
end

--------------------------------------------------------------------------------
-- exports
--------------------------------------------------------------------------------

Addon.HelpDialog = HelpDialog
