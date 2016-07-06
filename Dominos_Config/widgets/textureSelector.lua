--[[
	textureSelector.lua
		Displays a list of textures registered with LibSharedMedia for the user to pick from
--]]

local AddonName, Addon = ...
local PADDING = 2
local FONT_HEIGHT = 24
local BUTTON_HEIGHT = 24
local SCROLL_STEP = BUTTON_HEIGHT + PADDING

-- wrapper around LSM
local Textures = {}
do
	local libSharedMedia = LibStub('LibSharedMedia-3.0')
	local key = libSharedMedia.MediaType.STATUSBAR
	
	function Textures:Get(id)
		if id and libSharedMedia:IsValid(key, id) then
			return libSharedMedia:Fetch(key, id)
		end
		
		return libSharedMedia:GetDefault(key)        
	end
	
	function Textures:GetAll()
		return ipairs(libSharedMedia:List(key))
	end
end

--[[
	The Texture Button
--]]

local TextureButton = Addon:CreateClass('CheckButton')
do
	function TextureButton:New(parent)
		local b = self:Bind(CreateFrame('CheckButton', nil, parent))
		b:SetHeight(BUTTON_HEIGHT)
		b:SetScript('OnClick', b.OnClick)
		b:SetScript('OnEnter', b.OnEnter)
		b:SetScript('OnLeave', b.OnLeave)
		b:SetScript('OnAttributeChanged', b.OnAttributeChanged)

		local bg = b:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(b)
		b.bg = bg
		
		b:OnLeave()

		local text = b:CreateFontString(nil, 'ARTWORK')
		text:SetPoint('CENTER')	

		b:SetFontString(text)
		b:SetNormalFontObject('GameFontNormalSmall')
		b:SetHighlightFontObject('GameFontHighlightSmall')

		local ct = b:CreateTexture(nil, 'OVERLAY')
		ct:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
		ct:SetPoint('LEFT')
		ct:SetSize(24, 24)
		b:SetCheckedTexture(ct)

		return b
	end
	
	function TextureButton:OnEnter()
		self.bg:SetVertexColor(1, 1, 1, 1)
	end

	function TextureButton:OnLeave()
		self.bg:SetVertexColor(0.7, 0.7, 0.7, 0.7)
	end
	
	function TextureButton:OnAttributeChanged(attribute, value)
		if attribute == 'texture' then
			self:UpdateTexture()
		end        
	end
	
	function TextureButton:UpdateTexture()
		local textureId = self:GetAttribute('texture')
		
		self.bg:SetTexture(Textures:Get(textureId))
		self:SetText(textureId)        
	end
end

--[[
	The Font Selector
--]]

local TextureSelector = Addon:CreateClass('Frame')
do
	function TextureSelector:New(options)
		local f = self:Bind(CreateFrame('Frame', nil, options.parent))

		local scrollBar = f:CreateScrollBar()
		scrollBar:SetPoint('TOPRIGHT', -4, -4)
		scrollBar:SetPoint('BOTTOMRIGHT', -4, 4)
		scrollBar:SetWidth(16)
		f.scrollBar = scrollBar

		local scrollFrame = f:CreateScrollFrame()			
		scrollFrame:SetPoint('TOPLEFT', 4, -4)
		scrollFrame:SetPoint('BOTTOMRIGHT', scrollBar, 'BOTTOMLEFT')		
		f.scrollFrame = scrollFrame
				
		local scrollChild = f:CreateScrollChild()		
		f.scrollChild = scrollChild
		scrollFrame:SetScrollChild(scrollChild)
		
		f:SetScript('OnShow', f.OnShow)
		
		if options.set then
			self.SetSavedValue = set
		end
		
		if options.get then
			self.GetSavedValue = get
		end
		
		return f
	end

	do
		local function scrollFrame_OnSizeChanged(self)
			local scrollChild = self:GetParent().scrollChild
			scrollChild:SetWidth(self:GetWidth())
		
			local scrollBar  = self:GetParent().scrollBar
			local scrollMax = max(scrollChild:GetHeight() - self:GetHeight(), 0)
			scrollBar:SetMinMaxValues(0, scrollMax)
			scrollBar:SetValue(0)
		end
		
		local function scrollFrame_OnMouseWheel(self, delta)
			local scrollBar = self:GetParent().scrollBar
			local min, max = scrollBar:GetMinMaxValues()
			local current = scrollBar:GetValue()

			if IsShiftKeyDown() and (delta > 0) then
			   scrollBar:SetValue(min)
			elseif IsShiftKeyDown() and (delta < 0) then
			   scrollBar:SetValue(max)
			elseif (delta < 0) and (current < max) then
			   scrollBar:SetValue(current + SCROLL_STEP)
			elseif (delta > 0) and (current > 1) then
			   scrollBar:SetValue(current - SCROLL_STEP)
			end
		end

		function TextureSelector:CreateScrollFrame()
			local scrollFrame = CreateFrame('ScrollFrame', nil, self)
			scrollFrame:EnableMouseWheel(true)			
			scrollFrame:SetScript('OnSizeChanged', scrollFrame_OnSizeChanged)
			scrollFrame:SetScript('OnMouseWheel', scrollFrame_OnMouseWheel)

			return scrollFrame
		end
	end

	do
		local function scrollBar_OnValueChanged(self, value)
			self:GetParent().scrollFrame:SetVerticalScroll(value)
		end

		function TextureSelector:CreateScrollBar()
			local scrollBar = CreateFrame('Slider', nil, self)
			scrollBar:SetOrientation('VERTICAL')
			scrollBar:SetScript('OnValueChanged', scrollBar_OnValueChanged)

			local bg = scrollBar:CreateTexture(nil, 'BACKGROUND')
			bg:SetAllPoints(true)
			bg:SetColorTexture(0, 0, 0, 0.5)

			local thumb = scrollBar:CreateTexture(nil, 'OVERLAY')
			thumb:SetTexture([[Interface\Buttons\UI-ScrollBar-Knob]])
			thumb:SetSize(25, 25)
			scrollBar:SetThumbTexture(thumb)

			return scrollBar
		end
	end

	function TextureSelector:CreateScrollChild()
		local scrollChild = CreateFrame('Frame')
		
		local f_OnClick = function(f) 
			self:Select(f:GetAttribute('texture')) 
		end
		
		local buttons = {}

		for i, id in Textures:GetAll() do
			local f = TextureButton:New(scrollChild, i % 4 == 0 or (i + 1) % 4 == 0)
			f:SetAttribute('texture', id)
			f:SetScript('OnClick', f_OnClick)

			if i == 1 then
				f:SetPoint('TOPLEFT')
				f:SetPoint('TOPRIGHT', scrollChild, 'TOP', -PADDING/2, 0)
			elseif i == 2 then
				f:SetPoint('TOPLEFT', scrollChild, 'TOP', PADDING/2, 0)
				f:SetPoint('TOPRIGHT')
			else
				f:SetPoint('TOPLEFT', buttons[i-2], 'BOTTOMLEFT', 0, -PADDING)
				f:SetPoint('TOPRIGHT', buttons[i-2], 'BOTTOMRIGHT', 0, -PADDING)
			end

			tinsert(buttons, f)
		end

		scrollChild:SetWidth(self.scrollFrame:GetWidth())
		scrollChild:SetHeight(ceil(#buttons / 2) * (BUTTON_HEIGHT + PADDING) - PADDING)

		self.buttons = buttons
		return scrollChild
	end


	function TextureSelector:OnShow()
		self:UpdateSelected()
	end

	function TextureSelector:Select(value)
		self:SetSavedValue(value)
		self:UpdateSelected()
	end

	function TextureSelector:SetSavedValue(value)
		assert(false, 'Hey, you forgot to set SetSavedValue for ' .. self:GetName())
	end

	function TextureSelector:GetSavedValue()
		assert(false, 'Hey, you forgot to set GetSavedValue for ' .. self:GetName())
	end

	function TextureSelector:UpdateSelected()
		local selectedValue = self:GetSavedValue()
		for i, button in pairs(self.buttons) do
			button:SetChecked(button:GetAttribute('texture') == selectedValue)
		end
	end
end

Addon.TextureSelector = TextureSelector