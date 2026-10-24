local _, Addon = ...

local function frame_OnEnter(self)
	local tooltip = self.options.tooltip
	if tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, tooltip)
		GameTooltip:Show()
	end
end

local function frame_OnLeave(self)
	local tooltip = self.options.tooltip
	if tooltip then
		GameTooltip:Hide()
	end
end

local function frame_OnShow(self)
	self.CheckButton:SetChecked(self.options.get())
	self.CheckButton:SetHitRectInsets(0, self.CheckButton:GetWidth() - self:GetWidth(), 0, 0)
end

local function frame_OnSizeChanged(self)
	self.CheckButton:SetHitRectInsets(0, self.CheckButton:GetWidth() - self:GetWidth(), 0, 0)
end

local function checkbox_OnChecked(self)
	self:GetParent().options.set(self:GetChecked())
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

	local row = self:CreateRow(options.parent)

	row.options = options
	row.Refresh = frame_OnShow
	row:HookScript('OnShow', frame_OnShow)
	row:HookScript('OnSizeChanged', frame_OnSizeChanged)

	local checkbox = CreateFrame('CheckButton', nil, row, 'MinimalCheckboxTemplate')
	checkbox:SetScript('OnClick', checkbox_OnChecked)
	checkbox:SetScript('OnEnter', checkbox_OnEnter)
	checkbox:SetScript('OnLeave', checkbox_OnLeave)
	row:AddChild(checkbox)

	row.CheckButton = checkbox

	local label = row:CreateFontString(nil, 'ARTWORK', options.small and 'GameFontHighlightSmall' or 'GameFontHighlight')
	label.expand = true
	label:SetHeight(checkbox:GetHeight())
	label:SetJustifyH('LEFT')
	label:SetJustifyV('MIDDLE')
	label:SetText(options.name or "PLACEHOLDER_TEXT")
	row.Label = label
	row:AddChild(label)

	row:SetFixedHeight(checkbox:GetHeight())
	row:MarkDirty()

	return row
end