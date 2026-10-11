local _, Addon = ...

local PanelSelectorMixin = {}

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

	button:SetFixedSize(80, 24)
	button:SetNormalFontObject('GameFontNormalSmall')
	button:SetHighlightFontObject('GameFontHighlightSmall')
	button:SetHighlightTexture(Addon:CreateHoverBackground(button))
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
			if button.id == id then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
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

	self:MarkDirty()
end

function Addon:CreatePanelSelector(parent)
    local frame = self:CreateScrollableContainer(parent)

	Mixin(frame, PanelSelectorMixin)

	frame.buttons = {}

    frame.Content = CreateFrame('Frame', nil, frame, 'VerticalLayoutFrame')
	frame.Content.expand = true
	frame.Content.spacing = 4
	frame.Content.topPadding = 4
	frame.Content.bottomPadding = 4
	frame.Content.leftPadding = 4
	frame.Content.rightPadding = 6
	frame:SetContent(frame.Content)

	frame.Divider = frame:CreateTexture(nil, 'ARTWORK')
	frame.Divider:SetColorTexture(1, 1, 1, 0.3)
	frame.Divider:SetPoint('TOPLEFT', frame, 'TOPRIGHT', -2, 0)
	frame.Divider:SetPoint('BOTTOMRIGHT', 0, 0)
	frame.Divider.ignoreInLayout = true

	frame:MarkDirty()

	return frame
end
