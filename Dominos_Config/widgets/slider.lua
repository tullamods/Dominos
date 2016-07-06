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
		f.FormatValue = options.format
		
		--todo: add edit option
		local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
		text:SetJustifyH('RIGHT')
		text:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT')
		f.valText = text			
		
		-- register Events
		f:SetScript('OnShow', f.OnShow)
		f:SetScript('OnValueChanged', f.OnValueChanged)
		f:SetScript('OnMouseWheel', f.OnMouseWheel)

		return f
	end

	--[[ Frame Events ]]--

	function Slider:OnShow()
		self:UpdateRange()
		self:UpdateValue()
	end

	function Slider:OnValueChanged(value)
		local min = self:GetMinMaxValues()
		local step = self:GetValueStep()
		local value = min + ceil((value - min) / step) * step

		self:SetSavedValue(value)
		self:UpdateText(self:GetSavedValue())
	end

	function Slider:OnMouseWheel(direction)
		local step = self:GetValueStep() *  direction
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
		self:UpdateText(self:GetSavedValue())
	end
	
	function Slider:FormatValue(value)
		return value
	end

	function Slider:UpdateText(value)
		if type(self.FormatValue) == 'string' then
			self.valText:SetFormattedText(self.FormatValue, value)
		else
			self.valText:SetText(self:FormatValue(value))
		end
	end
	
	function Slider:SetEnabled(enable)
		if enable then
			return BlizzardOptionsPanel_Slider_Enable(self)
		end		
		return BlizzardOptionsPanel_Slider_Disable(self)
	end
end

Addon.Slider = Slider