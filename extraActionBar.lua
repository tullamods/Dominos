local ExtraActionBarFrame = _G['ExtraActionBarFrame']
if not ExtraActionBarFrame then return end

local ExtraBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ExtraBar  = ExtraBar

function ExtraBar:New()
	local f = self.super.New(self, 'extra')
	
	f:LoadButtons()
	f:Layout()

	return f
end

function ExtraBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function ExtraBar:GetShowStates()
	return '[extrabar]show;hide'
end

function ExtraBar:NumButtons(f)
	return 1
end

--KeyBound Support!
local KeyBound = LibStub('LibKeyBound-1.0')
function ExtraBar:RetroFit_BindableButton(button)
	for i, data in pairs(Dominos.BindableButton) do
		if (type(data) ~= "userdata") then
			button[i] = data
		end
	end
	button:UnregisterEvent("UPDATE_EXTRA_ACTIONBAR");
	button:HookScript("OnEnter", function(self)	KeyBound:Set(self) end)
end

function ExtraBar:AddButton(i)
	local b = self:GetExtraButton(i)
	if b then
		b:SetAttribute('showgrid', 1)
		b:SetParent(self.header)
		b:Show()
		self:RetroFit_BindableButton(b)
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
