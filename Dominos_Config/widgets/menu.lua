local _, Addon = ...
local L = Addon:GetLocale()

local TITLE_DIVIDER_HEIGHT = 2
local TITLE_PADDING = 8
local BORDER_PADDING = 10
local CONTENT_WIDTH, CONTENT_HEIGHT = 300, 420

local function createMenuButton(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(64, 64)
	button:SetHitRectInsets(20, 20, 20, 20)

	button.Icon = button:CreateTexture(nil, 'BACKGROUND')
	button.Icon:SetTexture('Interface/AddOns/Dominos/Dominos')
	button.Icon:SetSize(23, 23)
	button.Icon:SetPoint('CENTER')

	button.Ring = button:CreateTexture(nil, 'BORDER')
	button.Ring:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
	button.Ring:SetSize(64, 64)
	button.Ring:SetPoint('CENTER', 12, -13)

	local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
	highlight:SetBlendMode('ADD')
	highlight:SetSize(46, 46)
	highlight:SetPoint('CENTER', -1, 1)
	button:SetHighlightTexture(highlight)

	return button
end

local function createCloseButton(parent)
	return CreateFrame('Button', nil, parent, 'UIPanelCloseButton')
end

local function createTitleBar(parent)
	local frame = CreateFrame('Frame', nil, parent, 'TitleDragAreaTemplate, ResizeLayoutFrame')
	frame.ignoreInLayout = true

	local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
	text:SetText("MENU_TITLE")
	text:SetJustifyH('CENTER')
	text:SetJustifyV('MIDDLE')
	text:SetPoint('TOPLEFT')
	text:SetPoint('TOPRIGHT')
	text:SetHeight(text:GetStringHeight() + TITLE_PADDING)
	frame.Text = text

	local divider = frame:CreateTexture(nil, 'ARTWORK')
	divider:SetColorTexture(1, 1, 1, 0.2)
	divider:SetPoint('TOPLEFT', text, 'BOTTOMLEFT')
	divider:SetPoint('TOPRIGHT', text, 'BOTTOMRIGHT')
	divider:SetHeight(TITLE_DIVIDER_HEIGHT)
	frame.Divider = divider

	local bg =  frame:CreateTexture(nil, 'BACKGROUND')
	bg:SetColorTexture(1, 1, 1, 0.2)
	bg:SetAllPoints()
	bg.ignoreInLayout = true

	-- frame:SetFixedHeight(text:GetStringHeight() + TITLE_PADDING) + TITLE_DIVIDER_HEIGHT)

	return frame
end

local MenuMixin = {}

MenuMixin.widthPadding = 20
MenuMixin.heightPadding = 47

function MenuMixin:Initialize()
	self.panels = {}
	self:EnableKeyboard(false)
	self:EnableMouse(true)
	self:SetClampedToScreen(true)
    self:SetFrameStrata('DIALOG')
	self:SetMovable(true)
	self:SetToplevel(true)

	self.TitleBar = createTitleBar(self)
	self.TitleBar:SetPoint('TOPLEFT', BORDER_PADDING, -BORDER_PADDING)
	self.TitleBar:SetPoint('TOPRIGHT', -BORDER_PADDING, -BORDER_PADDING)

    self.Border = CreateFrame('Frame', nil, self, 'DialogBorderTranslucentTemplate')
	self.Border:SetFrameLevel(self.TitleBar:GetFrameLevel() + 1)
    self.Border.ignoreInLayout = true

	self.MenuButton = createMenuButton(self)
	self.MenuButton:SetPoint('TOPLEFT', -20, 20)
	self.MenuButton:SetFrameLevel(self.TitleBar:GetFrameLevel() + 10)
	self.MenuButton.ignoreInLayout = true

    self.CloseButton = createCloseButton(self)
    self.CloseButton:SetPoint('TOPRIGHT')
	self.CloseButton:SetFrameLevel(self.TitleBar:GetFrameLevel() + 10)
	self.CloseButton.ignoreInLayout = true

	local selector = Addon:CreatePanelSelector(self)
	selector:SetPoint('TOPLEFT', self.TitleBar, 'BOTTOMLEFT')
	selector.OnSelect = function(_, id) self:OnShowPanel(id) end
	selector:SetFixedHeight(CONTENT_HEIGHT)
	self.Selector = selector

	local settings = Addon:CreateScrollableContainer(self)
	settings:SetPoint('TOPLEFT', self.Selector, 'TOPRIGHT')
	settings:SetFixedSize(CONTENT_WIDTH, CONTENT_HEIGHT)
	self.Settings = settings

	self:MarkDirty()
end

-- tells the panel what frame we're pointed to
function MenuMixin:SetOwner(owner)
	if self.panels then
		for _, panel in pairs(self.panels) do
			panel:SetOwner(owner)
		end
	end

	self.TitleBar.Text:SetText(owner:GetDisplayName())
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

	Addon:ApplyDebugBackground(panel)

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

function MenuMixin:AddLayoutPanel()
	local panel = self:NewPanel(L.Layout)

	panel:AddLayoutOptions()

	return panel
end

function MenuMixin:AddBasicLayoutPanel()
	local panel = self:NewPanel(L.Layout)

	panel:AddBasicLayoutOptions()

	return panel
end

function MenuMixin:AddAdvancedPanel(basic)
	local panel = self:NewPanel(L.Advanced)

	panel:AddAdvancedOptions(basic)

	return panel
end

function MenuMixin:AddFadingPanel()
	local panel = self:NewPanel(L.Fading)

	panel:AddFadingOptions()

	return panel
end

local Menu = {}

--- @params parent Region?
function Menu:New(parent)
	local frame = CreateFrame('Frame', nil, parent or UIParent, 'ResizeLayoutFrame')

	Mixin(frame, MenuMixin)

	frame:Initialize()

	return frame
end

Addon.Menu = Menu