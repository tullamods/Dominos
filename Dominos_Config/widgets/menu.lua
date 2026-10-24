--------------------------------------------------------------------------------
--- A Dominos context menu
--------------------------------------------------------------------------------

local _, Addon = ...
local L = Addon:GetLocale()
local CONTENT_WIDTH, CONTENT_HEIGHT = 280, 420

local MenuMixin = {}

MenuMixin.minimumWidth = 320
MenuMixin.topPadding = 30
MenuMixin.bottomPadding = 12
MenuMixin.leftPadding = 12
MenuMixin.rightPadding = 12
MenuMixin.spacing = 0

function MenuMixin:Initialize()
	self.panels = {}

	self:EnableKeyboard(false)
	self:EnableMouse(true)
	self:SetClampedToScreen(true)
    self:SetFrameStrata('DIALOG')
	self:SetMovable(true)
	self:SetToplevel(true)

	self.TitleBar = CreateFrame('Frame', nil, self, 'DialogHeaderTemplate, TitleDragAreaTemplate')
	self.TitleBar.ignoreInLayout = true

    self.Border = CreateFrame('Frame', nil, self, 'DialogBorderTranslucentTemplate')
	self.Border:SetFrameLevel(self.TitleBar:GetFrameLevel() + 1)
    self.Border.ignoreInLayout = true

    self.CloseButton = CreateFrame('Button', nil, self, 'UIPanelCloseButton')

	local closeOffset = Addon:IsGameType("vanilla") and 8 or 2
	self.CloseButton:SetPoint('TOPRIGHT', closeOffset, closeOffset)

	self.CloseButton:SetFrameLevel(self.TitleBar:GetFrameLevel() + 10)
	self.CloseButton.ignoreInLayout = true

	local selector = Addon:CreatePanelSelector(self)
	selector.OnSelect = function(_, id) self:OnShowPanel(id) end
	selector:SetFixedHeight(CONTENT_HEIGHT)
	selector.layoutIndex = 1
	self.Selector = selector

    local settings = Addon:CreateScrollableContainer(self)
    settings:SetFixedSize(CONTENT_WIDTH, CONTENT_HEIGHT)
	settings.layoutIndex = 2
	self.Settings = settings

	self:MarkDirty()
end

local function isDescendantOf(region, ancestor)
	while region do
		if region == ancestor then
			return true
		end

		region = region:GetParent()
	end

	return false
end

-- text inputs apply their value when they lose focus, to whichever frame the
-- panels are pointed at. so apply anything being typed before that changes
function MenuMixin:CommitEdits()
	local focus = GetCurrentKeyBoardFocus()

	if focus and isDescendantOf(focus, self) then
		focus:ClearFocus()
	end
end

-- tells the panel what frame we're pointed to
function MenuMixin:SetOwner(owner)
	self:CommitEdits()

	if self.panels then
		for _, panel in pairs(self.panels) do
			panel:SetOwner(owner)
		end
	end

	self.TitleBar:Setup(owner:GetDisplayName())
	self:Anchor(owner)
end

function MenuMixin:Anchor(frame)
	local ratio = UIParent:GetScale() / frame:GetEffectiveScale()
	local x = frame:GetLeft() / ratio
	local y = frame:GetTop() / ratio

	self:ClearAllPoints()
	self:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', x, y)
end

function MenuMixin:NewPanel(id)
	self.Selector:AddPanel(id)

	local panel = Addon:CreatePanel(self.Settings)

	panel.fixedWidth = self.Settings.fixedWidth

	self.panels[id] = panel

	return panel
end

function MenuMixin:ShowPanel(id)
	if self.Selector then
		return self.Selector:Select(id)
	end
end

function MenuMixin:OnShowPanel(id)
	for i, panel in pairs(self.panels) do
		if i == id then
			panel:Show()
			self.Settings:SetContent(panel)
		else
			panel:Hide()
		end
	end
end

--- @param flags { basic: boolean? }? basic is for frames that aren't a grid of buttons
function MenuMixin:AddGeneralPanel(flags)
	local panel = self:NewPanel(L.General)

	panel:AddGeneralOptions(flags)

	return panel
end

function MenuMixin:AddAppearancePanel()
	return self:NewPanel(L.Appearance)
end

function MenuMixin:AddVisibilityPanel()
	local panel = self:NewPanel(L.Visibility)

	panel:AddVisibilityOptions()

	return panel
end

--- @param flags { basic: boolean?, alwaysShowInSpecialUI: boolean? }?
function MenuMixin:AddAdvancedPanel(flags)
	local panel = self:NewPanel(L.Advanced)

	panel:AddAdvancedOptions(flags)

	return panel
end

local Menu = {}

--- @params parent Region?
function Menu:New(parent)
    local frame = CreateFrame('Frame', nil, parent or UIParent, 'HorizontalLayoutFrame')
	
	Mixin(frame, MenuMixin)

	frame:Initialize()

	return frame
end

Addon.Menu = Menu