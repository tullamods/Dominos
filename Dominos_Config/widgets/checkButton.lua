local _, Addon = ...

local function frame_OnEnter(self)
	self.HoverBackground:Show()

	local tooltip = self.options.tooltip
	if tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, self.tooltipText)
		GameTooltip:Show()
	end
end

local function frame_OnLeave(self)
	self.HoverBackground:Hide()

	local tooltip = self.options.tooltip
	if tooltip then
		GameTooltip:Hide()
	end
end

local function frame_OnShow(self)
	self.CheckButton:SetChecked(self.options:get())
	self.CheckButton:SetHitRectInsets(0, self.CheckButton:GetWidth() - self:GetWidth(), 0, 0)
end

local function frame_OnSizeChanged(self)
	self.CheckButton:SetHitRectInsets(0, self.CheckButton:GetWidth() - self:GetWidth(), 0, 0)
end

local function checkbox_OnChecked(self)
	self:GetParent().options:set(self:GetChecked())
end

local function checkbox_OnEnter(self)
	frame_OnEnter(self:GetParent())
end

local function checkbox_OnLeave(self)
	frame_OnLeave(self:GetParent())
end

function Addon:CreateCheckButton(options)
	assert(options.set, 'Options property set is required')
	assert(options.get, 'Options property get is required')

	local frame = CreateFrame('Frame', nil, options.parent, 'HorizontalLayoutFrame')

	frame.expand = true
	frame.spacing = 4
	frame.options = options

	frame.HoverBackground = self:CreateHoverBackground(frame)

	local hoverBG = frame:CreateTexture(nil, 'BACKGROUND')

	hoverBG:Hide()
	hoverBG:SetColorTexture(1, 1, 1, 0.1)
	hoverBG:SetAllPoints()
	hoverBG.ignoreInLayout = true

	frame.HoverBackground = hoverBG
	frame:HookScript('OnShow', frame_OnShow)
	frame:HookScript('OnSizeChanged', frame_OnSizeChanged)

	local checkbox = CreateFrame('CheckButton', nil, frame)
	checkbox.layoutIndex = 1
	checkbox:SetSize(30, 29)
	checkbox:SetNormalAtlas('checkbox-minimal')
	checkbox:SetPushedAtlas('checkbox-minimal')
	checkbox:SetCheckedTexture('checkmark-minimal')
	checkbox:SetDisabledAtlas('checkmark-minimal-disabled')
	checkbox:SetScript('OnClick', checkbox_OnChecked)
	checkbox:SetScript('OnEnter', checkbox_OnEnter)
	checkbox:SetScript('OnLeave', checkbox_OnLeave)
	frame.CheckButton = checkbox

	local label = frame:CreateFontString(nil, 'ARTWORK', options.small and 'GameFontHighlightSmall' or 'GameFontHighlight')
	label.layoutIndex = 2
	label.expand = true

	label:SetHeight(checkbox:GetHeight())
	label:SetJustifyH('LEFT')
	label:SetJustifyV('MIDDLE')
	label:SetText(options.label or options.name or "PLACEHOLDER_TEXT")

	frame.Label = label

	frame:SetFixedHeight(checkbox:GetHeight())
	frame:MarkDirty()

	return frame
end