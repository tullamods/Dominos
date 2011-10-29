local ExtraActionBarFrame = _G['ExtraActionBarFrame']
if not ExtraActionBarFrame then return end

local ExtraBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ExtraBar  = ExtraBar

function ExtraBar:New()
	if UIPARENT_MANAGED_FRAME_POSITIONS['ExtraActionBarFrame'] then
		UIPARENT_MANAGED_FRAME_POSITIONS['ExtraActionBarFrame'] = nil
	end

	local f = self.super.New(self, 'extra')
	f:SetFrameStrata('HIGH')
	f:Layout()
	return f
end

function ExtraBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
		numButtons = 1,
	}
end

function ExtraBar:Layout()
	self:SetSize(64, 64)

	-- ExtraActionBarFrame:SetScript('OnLoad', nil)
	-- ExtraActionBarFrame:Show()
	ExtraActionButton1:SetAttribute('showgrid', 1)
	
	ExtraActionBarFrame:SetParent(self.header)
	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetPoint('CENTER')
	
	self.drag:SetFrameStrata('HIGH')
	self.drag:SetFrameLevel(ExtraActionBarFrame:GetFrameLevel() + 5)
end