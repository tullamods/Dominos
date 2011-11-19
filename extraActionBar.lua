local ExtraActionBarFrame = _G['ExtraActionBarFrame']
if not ExtraActionBarFrame then return end

local ExtraBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ExtraBar  = ExtraBar

function ExtraBar:New()
	if UIPARENT_MANAGED_FRAME_POSITIONS['ExtraActionBarFrame'] then
		UIPARENT_MANAGED_FRAME_POSITIONS['ExtraActionBarFrame'] = nil
	end

	local f = self.super.New(self, 'extra')
	f:LoadButtons()
	f:Layout()
	f:SetScript('OnEvent', f.OnEvent)
	f:RegisterEvent('UPDATE_EXTRA_ACTIONBAR')
	f:UpdateButtonsShown()
		
	return f
end

function ExtraBar:OnEvent(self, event, ...)
	if event == 'UPDATE_EXTRA_ACTIONBAR' then
		self:UpdateButtonsShown()
	end
end

function ExtraBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function ExtraBar:NumButtons(f)
	return 1
end

function ExtraBar:AddButton(i)
	local b = self:GetExtraButton(i)
	if b then
		b:SetAttribute('showgrid', 1)
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function ExtraBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

function ExtraBar:GetExtraButton(index)
	return _G['ExtraActionButton' .. index]
end

function ExtraBar:UpdateButtonsShown()
	if HasExtraActionBar() then
		self.header:Show()
	else
		self.header:Hide()
	end
end