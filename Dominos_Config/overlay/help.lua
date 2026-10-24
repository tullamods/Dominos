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
    self:SetSize(396, 120)
    self:SetPoint('TOP', 0, -24)
    self:SetScript('OnDragStart', self.OnDragStart)
    self:SetScript('OnDragStop', self.OnDragStop)

    self.minimumWidth = 360
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
    description:SetWidth(360)
    description.layoutIndex = 1
    description.expand = true

    self.Description = description

    local row = CreateFrame("Frame", nil, self)
    row:SetSize(360, 32)
    row.layoutIndex = 2

    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", 0, 0)
    checkbox:SetChecked(Dominos:GetAlignmentGridEnabled())

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(L.ShowAlignmentGrid)

    -- let clicks on the label reach the check box
    checkbox:SetHitRectInsets(0, -(label:GetStringWidth() + 4), 0, 0)

    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("RIGHT", row, "RIGHT", -36, 0)
    slider:SetSize(170, 32)

    local rightLabel = MinimalSliderWithSteppersMixin.Label.Right
    slider:Init(Dominos:GetAlignmentGridSize(), GRID_SIZE_MINIMUM, GRID_SIZE_MAXIMUM,
        (GRID_SIZE_MAXIMUM - GRID_SIZE_MINIMUM) / GRID_SIZE_STEP,
        { [rightLabel] = CreateMinimalSliderFormatter(rightLabel) })

    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        if self.Slider:IsEnabled() then
            self.Slider:SetValue(self.Slider:GetValue() + delta * self.Slider:GetValueStep())
        end
    end)

    checkbox:SetScript("OnClick", function(c)
        local enable = c:GetChecked() and true

        slider:SetEnabled(enable)
        Dominos:SetAlignmentGridEnabled(enable)
    end)

    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        Dominos:SetAlignmentGridSize(value)
    end, slider)

    slider:SetEnabled(checkbox:GetChecked())

    local function showTooltip(owner)
        GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT')
        GameTooltip_SetTitle(GameTooltip, L.AlignmentGridSize)
        GameTooltip_AddNormalLine(GameTooltip, L.AlignmentGridSizeTooltip)
        GameTooltip:Show()
    end

    local function hideTooltip(owner)
        if GameTooltip:IsOwned(owner) then
            GameTooltip:Hide()
        end
    end

    -- the slider's own buttons and thumb are children, so hook each
    for _, region in ipairs({ slider, slider.Slider, slider.Back, slider.Forward }) do
        region:HookScript('OnEnter', function() showTooltip(slider) end)
        region:HookScript('OnLeave', function() hideTooltip(slider) end)
    end
    
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
