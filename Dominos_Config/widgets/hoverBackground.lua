local _, Addon = ...

function Addon:CreateHoverBackground(frame)
	local bg = frame:CreateTexture(nil, 'BACKGROUND')

	bg:Hide()
	bg:SetColorTexture(1, 1, 1, 0.1)
	bg:SetAllPoints()
	bg.ignoreInLayout = true

    return bg
end

function Addon:CreateHeader(text, parent)
	local frame = CreateFrame('Frame', nil, parent, 'ResizeLayoutTemplate')

	local label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	label:SetPoint('LEFT')
	label:SetJustifyV('MIDDLE')
	label:SetText(text or "PLACEHOLDER_TEXT")
	frame.Label = label

	frame:SetFixedHeight(label:GetStringHeight() + 4)
	frame:MarkDirty()

	return frame
end

function Addon:ApplyDebugBackground(frame)
	local bg = frame:CreateTexture(nil, 'BACKGROUND')

	bg:SetColorTexture(random(), random(), random(), 0.3)
	bg:SetAllPoints()
	bg.ignoreInLayout = true
end