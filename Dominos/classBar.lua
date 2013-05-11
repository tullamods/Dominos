--[[
	classBar.lua
		Defines a Dominos class bar, which contains things like forms for druids, stances for warriors, auras for paladins, etc
--]]

local ClassBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ClassBar  = ClassBar


function ClassBar:New()
	local f = self.super.New(self, 'class')
	f:SetScript('OnEvent', f.UpdateForms)
	f:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
	f:UpdateForms()

	return f
end

function ClassBar:GetDefaults()
	return {
		point = 'CENTER',
		spacing = 2
	}
end

function ClassBar:Free()
	self:UnregisterAllEvents()
	self.super.Free(self)
end


--[[ button stuff]]--

function ClassBar:LoadButtons()
	self:UpdateForms()
	self:UpdateClickThrough()
end

function ClassBar:AddButton(i)
	local b = Dominos.ClassButton:New(i)
	b:SetParent(self.header)
	self.buttons[i] = b

	return b
end

function ClassBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end

function ClassBar:UpdateForms()
	for i = 1, GetNumShapeshiftForms() do
		local b = self.buttons[i] or self:AddButton(i)
		b:UpdateSpell()
		b:Show()
	end
	self:SetNumButtons(GetNumShapeshiftForms() or 0)
end

function ClassBar:UPDATE_BINDINGS()
	for _,b in pairs(self.buttons) do
		b:UpdateHotkey(b.buttonType)
	end
end