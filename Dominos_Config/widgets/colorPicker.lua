local _, Addon = ...

local ColorPickerMixin = {}

function ColorPickerMixin:OnClick()
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()
	else
		self.r, self.g, self.b, self.opacity = self:GetSavedValue()
		self.opacity = 1 - (self.opacity or 1) --correction, since the color menu is crazy

		OpenColorPicker(self)
		ColorPickerFrame:SetFrameStrata('TOOLTIP')
		ColorPickerFrame:Raise()
	end
end

function ColorPickerMixin:OnShow()
	local r, g, b = self:GetSavedValue()
	self:GetNormalTexture():SetVertexColor(r, g, b)
end

function ColorPickerMixin:OnEnter()
	local color = _G['NORMAL_FONT_COLOR']
	self.bg:SetVertexColor(color.r, color.g, color.b)
end

function ColorPickerMixin:OnLeave()
	local color = _G['HIGHLIGHT_FONT_COLOR']
	self.bg:SetVertexColor(color.r, color.g, color.b)
end

function ColorPickerMixin:SetColor(r, g, b, a)
	self:GetNormalTexture():SetVertexColor(r, g, b)
	self:SetSavedValue(r, g, b, a)
end

function ColorPickerMixin:SetSavedValue(r, g, b, a)
	assert(false, 'Hey, you forgot to implement SetSavedValue for ' .. self:GetName())
end

function ColorPickerMixin:GetSavedValue(r, g, b, a)
	assert(false, 'Hey, you forgot to implement GetSavedValue for ' .. self:GetName())
end

function ColorPickerMixin:UpdateColor()
	self:SetColor(self:GetSavedValue())
end

do
	local nextName = Addon:CreateNameGenerator('ColorPicker')

	function Addon:CreateColorPicker(options)
		local picker = CreateFrame('Button', nextName(), options.parent)

		Mixin(picker, ColorPickerMixin)

		picker.hasOpacity = options.hasOpacity
		picker:SetSize(16, 16)

		if options.set then
			picker.SetSavedValue = function(_, ...) options.set(...) end
		end

		if options.get then
			picker.GetSavedValue = function() return options.get() end
		end

		if options.hasOpacity then
			picker.swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = 1 - OpacitySliderFrame:GetValue()
				picker:SetColor(r, g, b, a)
			end

			picker.opacityFunc = picker.swatchFunc

			picker.cancelFunc = function()
				local prev = ColorPickerFrame.previousValues

				picker:SetColor(prev.r, prev.g, prev.b, 1 - prev.opacity)
			end
		else
			picker.swatchFunc = function()
				picker:SetColor(ColorPickerFrame:GetColorRGB())
			end

			picker.cancelFunc = function()
				picker:SetColor(ColorPicker_GetPreviousValues())
			end
		end

		local nt = picker:CreateTexture(nil, 'OVERLAY')
		nt:SetColorTexture(1, 1, 1, 1)
		nt:SetAllPoints(picker)
		picker:SetNormalTexture(nt)

		local bg = picker:CreateTexture(nil, 'BACKGROUND')
		bg:SetColorTexture(1, 1, 1)
		bg:SetPoint('TOPLEFT', nt, -1, 1)
		bg:SetPoint('BOTTOMRIGHT', nt, 1, -1)
		picker.bg = bg

		local text = picker:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint('LEFT', picker, 'RIGHT', 4, 0)
		text:SetText(options.name)
		picker.text = text

		picker:SetScript('OnClick', picker.OnClick)
		picker:SetScript('OnEnter', picker.OnEnter)
		picker:SetScript('OnLeave', picker.OnLeave)
		picker:SetScript('OnShow', picker.OnShow)

		return picker
	end
end
