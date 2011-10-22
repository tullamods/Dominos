local ExtraActionBar = _G['ExtraActionBarFrame']
if not ExtraActionBar then return end

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
	ExtraActionBar:SetParent(self.header)
	ExtraActionBar:ClearAllPoints()
	ExtraActionBar:SetPoint('CENTER')
	
	self:SetSize(ExtraActionBar:GetSize())
	
	self.drag:SetFrameStrata('HIGH')
	self.drag:SetFrameLevel(ExtraActionBar:GetFrameLevel() + 5)
end