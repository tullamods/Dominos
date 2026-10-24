local _, Addon = ...

function Addon:CreateHoverBackground(frame)
	local bg = frame:CreateTexture(nil, 'BACKGROUND')

	bg:Hide()
	bg:SetColorTexture(1, 1, 1, 0.1)
	bg:SetAllPoints()
	bg.ignoreInLayout = true

    return bg
end
