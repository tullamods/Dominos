local addonName, Addon = ...
local parentAddon = _G[Addon.parent]
local AuraModule, AuraFrame = parentAddon:NewModule('Buff'), parentAddon:CreateClass('Frame', parentAddon.Frame)

function AuraModule:Load()
	self.frame = AuraFrame:New("buff")
end

function AuraModule:Unload()
	self.frame:Free()
end

function AuraFrame:New(name)
	local f = AuraFrame.proto.New(self, name)
	f:SetFrameStrata('LOW')
	Addon:New(f, "Buffs")

	return f
end

function AuraFrame:HideBlizz()
	local hideBlizz = self.sets.hideBlizz
	if hideBlizz then
		BuffFrame:Hide()
	else
		BuffFrame:Show()
	end
end

function AuraFrame:GetDefaults()
	return {
		scale = 1,
		point = 'CENTER',
		y = -150,
		x = 0,
		spacing = 0,
		columns = 10,
		rows = 2,
		isRightToLeft = false,
		isBottomToTop = false,
		method = 1, --time, index or name
		direction = true,
		padding = 0,
		hideBlizz = true,
		textOffset = 0,
		anchorText = "Bottom",
		textX = 0,
		textY = 0,
	}
end

function AuraFrame:GetFilter()
	return "HELPFUL"
end
