local AddonName, Addon = ...
local ScrollablePanel = Addon:CreateClass('Frame')

ScrollablePanel.scrollBarSize = 8

function ScrollablePanel:New(parent)
	local panel = self:Bind(CreateFrame('Frame', nil, parent))
	panel:SetScript('OnSizeChanged', self.OnSizeChanged)

	local container = Addon.Panel:New()
	container:SetScript('OnSizeChanged', function() Addon:Render(panel) end)
	panel.container = container

	local viewport = CreateFrame('ScrollFrame', nil, panel)
	viewport:SetScrollChild(panel.container)
	viewport:SetPoint('TOPLEFT')
	viewport:SetSize(panel:GetSize())
	viewport:EnableMouseWheel(true)
	viewport:SetScript('OnMouseWheel', function(self, delta)
		local scrollBar = panel.vScrollBar
		if scrollBar:IsShown() then
			scrollBar:GetScript('OnMouseWheel')(scrollBar, delta)
		end
	end)
	panel.viewport = viewport

	panel.vScrollBar = panel:CreateVerticalScrollBar()
	panel.hScrollBar = panel:CreateHorizontalScrollBar()

	return panel
end

function ScrollablePanel:OnSizeChanged()
	Addon:Render(self)
end

function ScrollablePanel:OnRender()
	-- update the size of the scroll frame
	local viewportWidth, viewportHeight = self:GetSize()

	-- the total width of the thing we care about
	local containerWidth, containerHeight = self.container:GetSize()

	local showHScrollBar = false
	if viewportWidth < containerWidth then
		viewportHeight = viewportHeight - self.scrollBarSize
		showHScrollBar = true
	end

	local showVScrollBar = false
	if viewportHeight < containerHeight then
		viewportWidth = viewportWidth - self.scrollBarSize
		showVScrollBar = true
	end

	-- update scroll frame size
	self.viewport:SetSize(viewportWidth, viewportHeight)

	-- update scroll bar visibility and bounds
	if showHScrollBar then
		self.hScrollBar:SetSize(viewportWidth, self.scrollBarSize)
		self.hScrollBar:SetMinMaxValues(0, containerWidth - viewportWidth)
		self.hScrollBar:SetValue(self.viewport:GetHorizontalScroll())
		self.hScrollBar:Show()
	else
		self.hScrollBar:Hide()
	end

	if showVScrollBar then
		self.vScrollBar:SetSize(self.scrollBarSize, viewportHeight)
		self.vScrollBar:SetMinMaxValues(0, containerHeight - viewportHeight)
		self.vScrollBar:SetValue(self.viewport:GetVerticalScroll())
		self.vScrollBar:Show()
	else
		self.vScrollBar:Hide()
	end
end

function ScrollablePanel:SetContainerSize(width, height)
	self.container:SetSize(width, height)
end

do
	local function scrollBar_OnMouseWheel(self, delta)
		local min, max = self:GetMinMaxValues()
		local value = self:GetValue()
		local step = max/5

		if IsShiftKeyDown() and (delta > 0) then
			self:SetValue(min)
		elseif IsShiftKeyDown() and (delta < 0) then
			self:SetValue(max)
		elseif (delta < 0) and (value < max) then
			self:SetValue(math.min(value + step, max))
		elseif (delta > 0) and (value > min) then
			self:SetValue(math.max(value - step, min))
		end
	end

	function ScrollablePanel:CreateScrollBar(orientation)
		local scrollBar = CreateFrame('Slider', nil, self)
		scrollBar:EnableMouseWheel(true)

		local bg = scrollBar:CreateTexture(nil, 'BACKGROUND')
		bg:SetColorTexture(0, 0, 0, 0.5)
		bg:SetAllPoints(scrollBar)

		local tt = scrollBar:CreateTexture(nil, 'OVERLAY')
		tt:SetColorTexture(0.3, 0.3, 0.3, 0.8)
		tt:SetSize(self.scrollBarSize, self.scrollBarSize)
		scrollBar:SetThumbTexture(tt)

		scrollBar:EnableMouseWheel(true)
		scrollBar:SetScript('OnMouseWheel', scrollBar_OnMouseWheel)
		scrollBar:SetOrientation(orientation)
		scrollBar:Hide()

		return scrollBar
	end
end

do
	local function vScrollBar_OnValueChanged(self, value)
		self:GetParent().viewport:SetVerticalScroll(value)
	end

	local function vScrollBar_OnSizeChanged(self)
		local height = self:GetHeight()
		local viewportHeight = self:GetParent().viewport:GetHeight()
		local containerHeight = self:GetParent().container:GetHeight()

		if containerHeight > 0 then
			self:GetThumbTexture():SetHeight(height * (viewportHeight / containerHeight))
		else
			self:GetThumbTexture():SetHeight(height)
		end
	end

	function ScrollablePanel:CreateVerticalScrollBar()
		local vScrollBar = self:CreateScrollBar('VERTICAL')

		vScrollBar:SetPoint('TOPRIGHT')
		vScrollBar:SetScript('OnValueChanged', vScrollBar_OnValueChanged)
		vScrollBar:SetScript('OnSizeChanged', vScrollBar_OnSizeChanged)

		return vScrollBar
	end
end

do
	local function hScrollBar_OnValueChanged(self, value)
		self:GetParent().viewport:SetHorizontalScroll(value)
	end

	local function hScrollBar_OnSizeChanged(self)
		local width = self:GetWidth()
		local viewportWidth = self:GetParent().viewport:GetWidth()
		local containerWidth = self:GetParent().container:GetWidth()

		if containerWidth > 0 then
			self:GetThumbTexture():SetWidth(width * (viewportWidth / containerWidth))
		else
			self:GetThumbTexture():SetWidth(width)
		end
	end

	function ScrollablePanel:CreateHorizontalScrollBar()
		local hScrollBar = self:CreateScrollBar('HORIZONTAL')

		hScrollBar:SetPoint('BOTTOMLEFT')
		hScrollBar:SetScript('OnValueChanged', hScrollBar_OnValueChanged)
		hScrollBar:SetScript('OnSizeChanged', hScrollBar_OnSizeChanged)

		return hScrollBar
	end
end

--[[ exports ]]--

Addon.ScrollablePanel = ScrollablePanel