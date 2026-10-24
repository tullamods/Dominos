local _, Addon = ...

local PanelSelectorMixin = {}

local BUTTON_MIN_WIDTH = 64
local BUTTON_HEIGHT = 24
local BUTTON_TEXT_PADDING = 12

-- extends the sidebar art up through the menu's top padding to the dialog border
local TOP_INSET = 18

local function selectButton_OnClick(self)
	self.owner:Select(self.id)
end

local function selectButton_OnEnter(self)
	if self:GetWidth() < self:GetFontString():GetStringWidth() then
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetText(self:GetText())
		GameTooltip:Show()
	end
end

local function selectButton_OnLeave(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

local function createSelectButton(id, parent, owner)
	local button = CreateFrame('Button', nil, parent, 'ResizeLayoutFrame')

	button:SetFixedSize(BUTTON_MIN_WIDTH, BUTTON_HEIGHT)
	button:SetNormalFontObject('GameFontNormalSmall')
	button:SetHighlightFontObject('GameFontHighlightSmall')
	button:SetHighlightAtlas('Options_List_Hover')

	button.Selected = button:CreateTexture(nil, 'BACKGROUND')
	button.Selected:SetAtlas('Options_List_Active')
	button.Selected:SetAllPoints()
	button.Selected:Hide()
	button:SetText(id)
	button:GetFontString():SetAllPoints()

	button:SetScript('OnClick', selectButton_OnClick)
	button:SetScript('OnEnter', selectButton_OnEnter)
	button:SetScript('OnLeave', selectButton_OnLeave)

	button.id = id
	button.owner = owner or parent

	return button
end

function PanelSelectorMixin:OnRender()
	self:MarkDirty()
end

function PanelSelectorMixin:Select(id)
	local oldID = self.currentPanelID

	if oldID ~= id then
		for _, button in pairs(self.buttons) do
			local selected = button.id == id

			button.Selected:SetShown(selected)
			button:SetNormalFontObject(selected and 'GameFontHighlightSmall' or 'GameFontNormalSmall')
		end

		self.currentPanelID = id
		self:OnSelect(id)
	end
end

function PanelSelectorMixin:OnSelect(id) end

function PanelSelectorMixin:AddPanel(id)
	local index = #self.buttons + 1

	local button = createSelectButton(id, self:GetContent(), self)

	button.layoutIndex = index

	self.buttons[index] = button

	-- size every button to fit the longest label
	local width = math.ceil(button:GetFontString():GetStringWidth()) + BUTTON_TEXT_PADDING

	if width > (self.buttonWidth or BUTTON_MIN_WIDTH) then
		self.buttonWidth = width

		for _, b in ipairs(self.buttons) do
			b:SetFixedSize(width, BUTTON_HEIGHT)
			b:MarkDirty()
		end
	else
		button:SetFixedSize(self.buttonWidth or BUTTON_MIN_WIDTH, BUTTON_HEIGHT)
	end

	self:MarkDirty()
end

function Addon:CreatePanelSelector(parent)
    local frame = self:CreateScrollableContainer(parent)

	Mixin(frame, PanelSelectorMixin)

	frame.buttons = {}

    frame.Content = CreateFrame('Frame', nil, frame, 'VerticalLayoutFrame')
	frame.Content.expand = true
	frame.Content.spacing = 4
	frame.Content.topPadding = 8
	frame.Content.bottomPadding = 4
	frame.Content.leftPadding = 4
	frame.Content.rightPadding = 6
	frame:SetContent(frame.Content)

	frame.Background = frame:CreateTexture(nil, 'BACKGROUND')
	frame.Background:SetColorTexture(1, 1, 1, 1)
	frame.Background:SetGradient('HORIZONTAL', CreateColor(1, 1, 1, 0.02), CreateColor(1, 1, 1, 0.1))
	frame.Background:SetPoint('TOPLEFT', 0, TOP_INSET)
	frame.Background:SetPoint('BOTTOMRIGHT')
	frame.Background.ignoreInLayout = true

	frame:MarkDirty()

	return frame
end
