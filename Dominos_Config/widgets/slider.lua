local AddonName, Addon = ...
local Slider = Addon:CreateClass('Slider')

do
	local nextName = Addon:CreateNameGenerator('Slider')

	local getOrCall = function(self, v, ...)
		if type(v) == 'function' then
			return v(self, ...)
		end
		return v
	end

	local function editBox_OnEditFocusLost(self)
		self:GetParent():UpdateText()
	end

	local function editBox_OnTextChanged(self)
		local value = tonumber(self:GetText())

		if value and value ~= self:GetParent():GetValue() then
			local min, max = self:GetParent():GetMinMaxValues()

			self:GetParent():SetValue(math.max(math.min(value, max), min))
		end
	end

	local function editBox_OnEscapePressed(self)
		self:ClearFocus()
	end

	-- a hacky way to go to the next edit box
	-- with the assumption we only care about edit boxes that are
	-- valText properties of other elements
	local function editBox_FocusNext(self, ...)
		local editBoxes = {}

		local index = nil
		for i = 1, select('#', ...) do
			local vt = select(i, ...).valText
			if vt and vt:GetObjectType() == 'EditBox' then
				table.insert(editBoxes, vt)

				if vt == self then
					index = i
				end
			end
		end

		editBoxes[index % #editBoxes + 1]:SetFocus()
	end

	local function editBox_OnTabPressed(self)
		editBox_FocusNext(self, self:GetParent():GetParent():GetChildren())


		local value = self:GetNumber()
		local min, max = self:GetParent():GetMinMaxValues()
		local current = self:GetParent():GetValue()

		if value and value ~= current and value >= min and value <= max then
			self:GetParent():SetValue(math.max(math.min(value, max), min))
		end
	end

	function Slider:New(options)
		local f = self:Bind(CreateFrame('Slider', nextName(), options.parent, 'OptionsSliderTemplate'))

		f.text = _G[f:GetName() .. 'Text']
		f.text:SetFontObject('GameFontNormalLeft')
		f.text:ClearAllPoints()
		f.text:SetPoint('BOTTOMLEFT', f, 'TOPLEFT')
		f.text:SetText(options.name or '')

		f.High:Hide()
		f.Low:Hide()
		f:EnableMouseWheel(true)

		f.min = options.min or 0
		f.max = options.max or 100
		f.step = options.step or 1
		f.GetSavedValue = options.get
		f.SetSavedValue = options.set

		--todo: add edit option
		local editBox = CreateFrame('EditBox', nil, f)
		editBox:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT')
		editBox:SetNumeric(false)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject('GameFontHighlightRight')
		editBox:SetHeight(f.text:GetHeight())
		editBox:SetWidth(f.text:GetHeight() * 3)
		editBox:HighlightText(0, 0)
		editBox:SetScript('OnTextChanged', editBox_OnTextChanged)
		editBox:SetScript('OnEditFocusLost', editBox_OnEditFocusLost)
		editBox:SetScript('OnEscapePressed', editBox_OnEscapePressed)
		editBox:SetScript('OnTabPressed', editBox_OnTabPressed)

		local bg = editBox:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(bg:GetParent())
		bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
		editBox.bg = bg
		f.valText = editBox

		-- register Events
		f:SetScript('OnShow', f.OnShow)
		f:SetScript('OnValueChanged', f.OnValueChanged)
		f:SetScript('OnMouseWheel', f.OnMouseWheel)
		f:SetWidth(284)

		return f
	end

	--[[ Frame Events ]]--

	-- the render call here is a delay hack since it seemed to fix

	function Slider:OnShow()
		Addon:Render(self)
	end

	function Slider:OnRender()
		self:UpdateRange()
		self:UpdateValue()
	end

	function Slider:OnValueChanged(value)
		local min = self:GetMinMaxValues()
		local step = self:GetValueStep()
		local value = min + ceil((value - min) / step) * step

		self:SetSavedValue(value)
		self:UpdateText(value)
	end

	function Slider:OnMouseWheel(direction)
		local step = self:GetValueStep() * direction
		local value = self:GetValue()
		local minVal, maxVal = self:GetMinMaxValues()

		if step > 0 then
			self:SetValue(min(value+step, maxVal))
		else
			self:SetValue(max(value+step, minVal))
		end
	end

	--[[ Update Methods ]]--

	function Slider:GetEffectiveSize()
		local width, height = self:GetSize()

		height = height + self.text:GetHeight()

		return width, height
	end

	function Slider:SetSavedValue(value)
		assert(false, 'Hey, you forgot to set SetSavedValue for ' .. self:GetName())
	end

	function Slider:GetSavedValue()
		assert(false, 'Hey, you forgot to set GetSavedValue for ' .. self:GetName())
	end

	function Slider:UpdateRange()
		local min = getOrCall(self, self.min)
		local max = getOrCall(self, self.max)

		local oldMin, oldMax = self:GetMinMaxValues()
		if oldMin ~= min or oldMax ~= max then
			self:SetEnabled(max > min)
			self:SetMinMaxValues(min, max)
		end

		local step = getOrCall(self, self.step)
		if step ~= self:GetValueStep() then
			self:SetValueStep(step)
		end
	end

	function Slider:UpdateValue()
		local min, max = self:GetMinMaxValues()
		self:SetEnabled(max > min)
		self:SetValue(self:GetSavedValue())
	end

	function Slider:UpdateText(value)
		self.valText:SetText(value or self:GetSavedValue())
	end

	function Slider:SetEnabled(enable)
		if enable then
			return BlizzardOptionsPanel_Slider_Enable(self)
		end
		return BlizzardOptionsPanel_Slider_Disable(self)
	end
end

Addon.Slider = Slider