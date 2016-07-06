local AddonName, Addon = ...
local TextInput = Addon:CreateClass('EditBox')

local nextName = Addon:CreateNameGenerator('EditBox')

function TextInput:New(options)
	local frame = self:Bind(CreateFrame('EditBox', nextName(), options.parent, 'InputBoxTemplate'))
	
	frame.SetSavedValue = options.set
	frame.GetSavedValue = options.get
	frame:SetAutoFocus(false)
	
	frame:SetScript('OnShow', frame.OnShow)
	frame:SetScript('OnEnterPressed', frame.OnEnterPressed)
	frame:SetScript('OnEditFocusGained', frame.OnEditFocusGained)
	frame:SetScript('OnEditFocusLost', frame.OnEditFocusLost)
	
	return frame
end

function TextInput:OnShow()
	self:SetText(self:GetSavedValue() or '')
end

function TextInput:OnEnterPressed()
	self:SelectValue()
end

function TextInput:OnEditFocusGained()
	self:HighlightText()
end

function TextInput:OnEditFocusLost()
	self:HighlightText(0, 0)
	self:SelectValue()
end

function TextInput:SelectValue()
	self:SetSavedValue(self:GetText() or nil)
end

function TextInput:GetSavedValue() end

function TextInput:SetSavedValue(value) end

Addon.TextInput = TextInput