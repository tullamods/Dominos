local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local ProgressBar = Dominos:CreateClass('Frame', Dominos.ButtonBar); Dominos.ProgressBar = ProgressBar

function ProgressBar:Create(...)
	local bar = ProgressBar.proto.Create(self, ...)

	bar:SetFrameStrata('BACKGROUND')

	bar.colors = {
		base = {0, 0, 0},
		rest = {0, 0, 0, 0},
		bg = {0, 0, 0, 1}
	}

	local textArea = CreateFrame('Frame', nil, bar.header)
	textArea:SetFrameLevel(20)
	textArea:SetAllPoints(bar)

	local text = textArea:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	text:SetPoint('CENTER')
	bar.text = text

	local bg = bar.header:CreateTexture(nil, 'BACKGROUND')
	bg:SetColorTexture(0, 0, 0, 1)
	bg:SetAllPoints(bar)
	bar.bg = bg

	return bar
end

function ProgressBar:GetDefaults()
	return {
		point = 'TOP',
		x = 0,
		y = 0,
		columns = 20,
		numButtons = 20,
		segmentWidth = 32,
		segmentHeight = 8,
		texture = 'blizzard'
	}
end


--[[ config ]]--

function ProgressBar:SetText(text, ...)
	if select('#', ...) > 0 then
		self.text:SetFormattedText(text, ...)
	else
		self.text:SetText(text, ...)
	end

	return self
end

function ProgressBar:GetText()
	return self.text:GetText()
end

function ProgressBar:SetValue(value, min, max)
	local changed = false

	local min = math.max(tonumber(min) or 0, 0)
	if self.min ~= min then
		self.min = min
		changed = true
	end

	local max = math.max(tonumber(max) or 0, 1)
	if self.max ~= max then
		self.max = max
		changed = true
	end

	local value = math.min(math.max(tonumber(value) or 0, min), max)
	if self.value ~= value then
		self.value = value
		changed = true
	end

	if changed then
	   self:UpdateValue()
	end

	return self
end

function ProgressBar:GetValue()
	return self.value or 0, self.min or 0, self.max or 1
end

function ProgressBar:SetRestValue(rest)
	local changed = false

	local rest = tonumber(rest) or 0
	if self.rest ~= rest then
		self.rest = rest
		changed = true
	end

	if changed then
	   self:UpdateRest()
	end

	return self
end

function ProgressBar:GetRestValue()
	return self.rest or 0
end

function ProgressBar:SetColor(r, g, b, a)
	local colors = self.colors.base

	colors[1] = tonumber(r) or 0
	colors[2] = tonumber(g) or 0
	colors[3] = tonumber(b) or 0
	colors[4] = tonumber(a) or 1

	local r, g, b, a = self:GetColor()
	for i, bar in pairs(self.buttons) do
		bar.bg:SetVertexColor(r / 2, g / 2, b / 2, a / 2)
		bar.value:SetStatusBarColor(r, g, b, a)
	end

	return self
end

function ProgressBar:GetColor()
	local r, g, b, a = unpack(self.colors.base)

	return r or 0, g or 0, b or 0, a or 1
end

function ProgressBar:SetRestColor(r, g, b, a)
	local colors = self.colors.rest

	colors[1] = tonumber(r) or 0
	colors[2] = tonumber(g) or 0
	colors[3] = tonumber(b) or 0
	colors[4] = tonumber(a) or 1

	local r, g, b, a = self:GetRestColor()
	for i, bar in pairs(self.buttons) do
		bar.rest:SetStatusBarColor(r, g, b, a)
	end

	return self
end

function ProgressBar:GetRestColor()
	local r, g, b, a = unpack(self.colors.rest)

	return r or 0, g or 0, b or 0, a or 1
end

function ProgressBar:SetBackgroundColor(r, g, b, a)
	local colors = self.colors.bg

	colors[1] = tonumber(r) or 0
	colors[2] = tonumber(g) or 0
	colors[3] = tonumber(b) or 0
	colors[4] = tonumber(a) or 1

	self.bg:SetVertexColor(self:GetBackgroundColor())

	return self
end

function ProgressBar:GetBackgroundColor()
	local r, g, b, a = unpack(self.colors.bg)

	return r or 0, g or 0, b or 0, a or 1
end


function ProgressBar:SetDesiredWidth(width)
	self.sets.width = width
	self:Layout()
end

function ProgressBar:GetDesiredWidth()
	return self.sets.width or 1024
end

function ProgressBar:SetDesiredHeight(height)
	self.sets.height = height
	self:Layout()
end

function ProgressBar:GetDesiredHeight()
	return self.sets.height or 18
end

function ProgressBar:NumColumns()
	return self:NumButtons()
end


-- segment stuff
function ProgressBar:SetSegmentCount(count)
	local count = tonumber(count) or 1

	if count ~= self:GetSegmentCount() then
		self:SetNumButtons(count)
		self:UpdateValue()
		self:UpdateRest()
	end
end

ProgressBar.GetSegmentCount = ProgressBar.NumButtons

function ProgressBar:SetSegmentTextureID(id)
	self.sets.texture = id
	self:UpdateSegmentTexture()
	return self
end

function ProgressBar:GetSegmentTextureID()
	return self.sets.texture
end

function ProgressBar:GetSegmentTexture()
	return LibStub('LibSharedMedia-3.0'):Fetch('statusbar', self:GetSegmentTextureID())
end

function ProgressBar:UpdateSegmentTexture()
	local texture = self:GetSegmentTexture()

	for i, segment in pairs(self.buttons) do
		segment.bg:SetTexture(texture)
		segment.value:SetStatusBarTexture(texture)
		segment.rest:SetStatusBarTexture(texture)
	end
end

--[[ actions ]]--

function ProgressBar:GetSegmentSize()
	local width = self:GetDesiredWidth()
	local height = self:GetDesiredHeight()
	local numButtons = self:NumButtons()
	local columns = self:NumColumns()
	local rows = math.ceil(numButtons / columns)
	local spacing = self:GetSpacing()

	-- subtract spacing between segments
	width = width - (spacing * (columns - 1))

	-- divide by the number of columns
	width = (width / columns)

	-- subtract the spacing between segments
	height = height - (spacing * (rows - 1))

	-- divide height by the number of rows
	height = (height / rows)

	return width, height
end

function ProgressBar:Layout()
	local width, height = self:GetSegmentSize()

	for i, segment in pairs(self.buttons) do
		segment:SetSize(width, height)
	end

	Dominos.ButtonBar.Layout(self)
end

function ProgressBar:UpdateValue()
	local value, min, max = self:GetValue()
	value = math.min(value, max)

	local segmentValue = max / self:GetSegmentCount()
	local lastFilledIndex = floor(value / segmentValue)
	local remainder = floor(100 * (value % segmentValue) / (segmentValue * 1.0) + 0.5)

	for i, segment in pairs(self.buttons) do
		if i <= lastFilledIndex then
			segment.value:SetValue(100)
		elseif i == lastFilledIndex + 1 then
			segment.value:SetValue(remainder)
		else
			segment.value:SetValue(0)
		end
	end
end

function ProgressBar:UpdateRest()
	local value, min, max = self:GetValue()
	local rest = math.min(value + self:GetRestValue(), max)

	local segmentValue = max / self:GetSegmentCount()
	local lastFilledIndex = floor(rest / segmentValue)
	local remainder = floor(100 * (rest % segmentValue) / (segmentValue * 1.0) + 0.5)

	for i, segment in pairs(self.buttons) do
		if i <= lastFilledIndex then
			segment.rest:SetValue(100)
		elseif i == lastFilledIndex + 1 then
			segment.rest:SetValue(remainder)
		else
			segment.rest:SetValue(0)
		end
	end
end


--[[ overrides ]]--

do
	local segmentPool = CreateFramePool('Frame')

	function ProgressBar:GetButton(index)
		local segment = segmentPool:Acquire()

		if not segment.value then
			local bg = segment:CreateTexture(nil, 'ARTWORK')
			bg:SetAllPoints(segment)
			segment.bg = bg

			local rest = CreateFrame('StatusBar', nil, segment)
			rest:SetMinMaxValues(0, 100)
			rest:SetValue(0)
			rest:EnableMouse(false)
			rest:SetAllPoints(segment)

			segment.rest = rest

			local value = CreateFrame('StatusBar', nil, rest)
			value:SetMinMaxValues(0, 100)
			value:SetValue(0)
			value:EnableMouse(false)
			value:SetAllPoints(rest)

			segment.value = value
		end

		segment:SetSize(self:GetSegmentSize())

		local r, g, b, a = self:GetColor()
		segment.bg:SetTexture(self:GetSegmentTexture())
		segment.bg:SetVertexColor(r / 3, g / 3, b / 3, a)

		segment.value:SetStatusBarTexture(self:GetSegmentTexture())
		segment.value:SetStatusBarColor(self:GetColor())

		segment.rest:SetStatusBarTexture(self:GetSegmentTexture())
		segment.rest:SetStatusBarColor(self:GetRestColor())

		return segment
	end
end


--[[ menu ]]--

do
	function ProgressBar:CreateMenu()
		local menu = Dominos:NewMenu(self.id)

		-- things we need to configure:

		self:AddLayoutPanel(menu)
		self:AddTexturePanel(menu)
		self:AddFontPanel(menu)

		menu:AddAdvancedPanel()

		ProgressBar.menu = menu
	end

	function ProgressBar:AddLayoutPanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		local panel = menu:NewPanel(l.Layout)

		panel.segmentedCheckbox = panel:NewCheckButton{
			name = 'Segmented',

			get = function()
				return panel.owner:GetSegmentCount() > 1
			end,

			set = function(_, enable)
				local segmentCount = enable and 20 or 1
				panel.owner:SetSegmentCount(segmentCount)
			end
		}

		panel.widthSlider = panel:NewSlider{
			name = 'Width',

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetWidth() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredWidth()
			end,

			set = function(_, value)
				panel.owner:SetDesiredWidth(value)
			end,
		}

		panel.heightSlider = panel:NewSlider{
			name = 'Height',

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetHeight() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredHeight()
			end,

			set = function(_, value)
				panel.owner:SetDesiredHeight(value)
			end,
		}

		panel.spacingSlider = panel:NewSpacingSlider()
		panel.paddingSlider = panel:NewPaddingSlider()
		panel.scaleSlider = panel:NewScaleSlider()
		panel.opacitySlider = panel:NewOpacitySlider()
		panel.fadeSlider = panel:NewFadeSlider()
	end

	function ProgressBar:AddFontPanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		local panel = menu:NewPanel('Font')
	end

	function ProgressBar:AddTexturePanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		local panel = menu:NewPanel('Texture')

		panel.textureSelector = Dominos.Options.TextureSelector:New{
			parent = panel,

			get = function()
				return panel.owner:GetSegmentTextureID()
			end,

			set = function(_, value)
				panel.owner:SetSegmentTextureID(value)
			end,
		}
	end
end