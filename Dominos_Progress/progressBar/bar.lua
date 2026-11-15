local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local LSM = LibStub('LibSharedMedia-3.0')

---@alias FontOutline '' | 'OUTLINE' | 'THICKOUTLINE'

local ProgressBar = Dominos:CreateClass('Frame', Dominos.Frame)

-- stock status bar art
local NATIVE_BORDER_ATLAS = 'UI-HUD-ExperienceBar-Frame'
local NATIVE_BACKGROUND_ATLAS = 'UI-HUD-ExperienceBar-Background'
local NATIVE_DIVIDER_ATLAS = 'ui-hud-experiencebar-divider'
local NATIVE_FONT = 'TextStatusBarText'

-- the stock look for modes without fill art
local PLAIN_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]

-- ONly Forever has the good border texture for now.
local HAS_BORDER_ART = Dominos:IsGameType('forever')

local BORDER_OUTSET = 2

local TEXT_OFFSET_Y = 1

local TRANSPARENT_COLOR = CreateColor(0, 0, 0, 0)

-- desaturated stock art is a mid grey, so its tint is brightened to make up for it
local DESATURATED_TINT_BOOST = 1.6

local function getStockFont()
	return _G[NATIVE_FONT]:GetFont()
end

-- capped by the brightest channel, so the hue stays the same
local function brightenTint(r, g, b, a)
	local boost = math.min(DESATURATED_TINT_BOOST, 1 / math.max(r, g, b, 0.001))
	return r * boost, g * boost, b * boost, a
end

local function snapToPixel(value, pixel)
	return Round(value / pixel) * pixel
end

-- segment i's left and right, from the padding. snapping the edges rather than
-- the widths keeps every gap the same number of pixels
local function getSegmentEdges(i, segW, divW, pixel)
	local gaps = (i - 1) * divW
	return snapToPixel((i - 1) * segW, pixel) + gaps, snapToPixel(i * segW, pixel) + gaps
end

local function atlasExists(atlas)
	return atlas and C_Texture.GetAtlasInfo(atlas)
end

-- the segment is the bonus bar, value bar on top
local function createSegment(parent)
	local segment = CreateFrame('StatusBar', nil, parent)
	segment:SetMinMaxValues(0, 100)
	segment:SetValue(0)
	segment:EnableMouse(false)

	local bg = segment:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(segment)
	segment.bg = bg

	local value = CreateFrame('StatusBar', nil, segment)
	value:SetMinMaxValues(0, 100)
	value:SetValue(0)
	value:EnableMouse(false)
	value:SetAllPoints(segment)
	segment.value = value

	return segment
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

function ProgressBar:GetDefaults()
	return {
		point = 'BOTTOM',
		width = 1024,
		height = 12,
		-- segment count
		numButtons = 20,
		padW = 2,
		padH = 2,
		-- just the border
		display = { border = true },
		displayLayer = 'BACKGROUND',
		textFormat = 'valueMaxPercent',
		showLabel = true,
		showBonus = true,
		showText = true,
		abbreviateNumbers = false,
		showTooltip = true,
		-- the opposite of auto switching modes
		lockMode = true
	}
end

---@param id string
---@param modes string[]
---@return ProgressBar? bar nil if none of the modes have a provider on this client
function ProgressBar:New(id, modes)
	local loadedModes = {}
	for _, mode in ipairs(modes) do
		if Addon.dataProviders[mode] then
			loadedModes[#loadedModes + 1] = mode
		end
	end

	if #loadedModes == 0 then
		return
	end

	local bar = ProgressBar.proto.New(self, id)

	-- pooled frames keep their fields
	bar.modes = loadedModes
	bar.appliedMode = nil
	bar.provider = nil
	bar.lastAutoMode = nil
	bar.lastShowText = nil
	bar.displayConditions = nil
	bar.shownText = nil

	bar:Refresh()

	return bar
end

function ProgressBar:OnCreate()
	ProgressBar.proto.OnCreate(self)

	self.textOptions = {}
	self.segments = {}
	self.dividers = {}
	self.refreshTooltip = function() self:RefreshTooltip(); end

	local bg = self:CreateTexture(nil, 'BACKGROUND')
	bg:SetColorTexture(0, 0, 0, 1)
	bg:SetAllPoints(self)
	self.bg = bg

	-- clicks, dividers, border and text all live on one frame over the fill
	local overlay = CreateFrame('Button', nil, self)
	overlay:SetAllPoints(self)
	overlay:RegisterForClicks('AnyUp')

	overlay:SetScript('OnClick', function() self:NextMode(); end)

	overlay:SetScript('OnEnter', function()
		self:UpdateTextShown(true)
		if self:ShowingTooltip() then
			self:ShowTooltip()
		end
	end)

	overlay:SetScript('OnLeave', function()
		self:UpdateTextShown(false)
		self:HideTooltip()
	end)

	overlay:SetFrameLevel(7)
	self.overlay = overlay

	local text = overlay:CreateFontString(nil, 'OVERLAY', NATIVE_FONT)
	text:SetDrawLayer('OVERLAY', 1)
	text:SetJustifyH('CENTER')
	text:SetJustifyV('MIDDLE')
	text:SetWordWrap(false)
	text:SetPoint('CENTER', 0, TEXT_OFFSET_Y)
	self.text = text

	local border = overlay:CreateTexture(nil, 'OVERLAY')
	local borderInfo = HAS_BORDER_ART and C_Texture.GetAtlasInfo(NATIVE_BORDER_ATLAS)

	if borderInfo then
		-- caps as wide as the art is tall, and a middle row left for the sides
		local capWidth = borderInfo.height
		local capHeight = math.floor((borderInfo.height - 1) / 2)

		border:SetAtlas(NATIVE_BORDER_ATLAS)
		border:SetTextureSliceMargins(capWidth, capHeight, capWidth, capHeight)
		border:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
		self.borderCapWidth = capWidth
	end

	self.border = border
end

-- runs before New hands over the modes, so nothing here can touch the provider
function ProgressBar:OnLoadSettings()
	self:Layout()
	self:UpdateFont()
	self:UpdateClickThrough()
	self:UpdateTextShown()
end

-- segments snap to pixels, and the border depends on whether the bar spans the screen
function ProgressBar:OnSetScale()
	self:Layout()
end

function ProgressBar:CanClickThrough()
	return true
end

function ProgressBar:UpdateClickThrough()
	local overlay = self.overlay
	local clickThrough = self:GetClickThrough()

	overlay:EnableMouse(not clickThrough)

	-- motion alone, so the text can still show on mouseover
	if clickThrough and self:ShowingTextOnMouseover() then
		overlay:SetMouseMotionEnabled(true)
	end
end

---@param mediaType string
---@param key string
function ProgressBar:OnMediaRegistered(mediaType, key)
	if mediaType == LSM.MediaType.STATUSBAR and key == self.sets.texture then
		self:UpdateTextures()
	elseif mediaType == LSM.MediaType.FONT and key == self.sets.font then
		self:UpdateFont()
	end
end

--------------------------------------------------------------------------------
-- Modes
--------------------------------------------------------------------------------

function ProgressBar:Refresh()
	-- modes go active and inactive, and hiding has to follow
	if self:UsesAutoHide() and self:GetDisplayConditions() ~= self.displayConditions then
		self:UpdateDisplayConditions()
	end

	-- auto switch only acts when its own pick changes, so manual clicks stick
	if not self:IsModeLocked() then
		local autoMode = self:GetAutoMode()

		if autoMode ~= self.lastAutoMode then
			self.lastAutoMode = autoMode
			Addon.Config:SetBarMode(self.id, autoMode)
		end
	end

	self:ApplyMode()
end

function ProgressBar:ApplyMode()
	local mode = self:GetMode()

	if mode ~= self.appliedMode then
		self.appliedMode = mode
		self.provider = Addon.dataProviders[mode]
		self:InvalidateShownValues()
		self:UpdateTextures()
	end

	self:UpdateDisplay()
end

---@param mode string
function ProgressBar:SetMode(mode)
	Addon.Config:SetBarMode(self.id, mode)
	self:ApplyMode()
end

-- the saved mode, if it's one this bar can show
function ProgressBar:GetMode()
	local saved = Addon.Config:GetBarMode(self.id)

	if tIndexOf(self.modes, saved) and Addon.dataProviders[saved]:IsAvailable() then
		return saved
	end

	return self.modes[1]
end

-- the last active mode in the list wins, the first is the fallback
function ProgressBar:GetAutoMode()
	local modes = self.modes

	for i = #modes, 2, -1 do
		if Addon.dataProviders[modes[i]]:IsActive() then
			return modes[i]
		end
	end

	return modes[1]
end

function ProgressBar:HasActiveMode()
	-- the core asks for display conditions before New hands over the modes
	if not self.modes then
		return false
	end

	for _, mode in ipairs(self.modes) do
		if Addon.dataProviders[mode]:IsActive() then
			return true
		end
	end

	return false
end

function ProgressBar:NextMode()
	local modes = self.modes
	local current = tIndexOf(modes, self:GetMode())
	local skipInactive = Addon.Config:SkipInactiveModes()

	for offset = 1, #modes - 1 do
		local mode = modes[Wrap(current + offset, #modes)]
		local provider = Addon.dataProviders[mode]

		if provider:IsAvailable() and (not skipInactive or provider:IsActive()) then
			self:SetMode(mode)
			return
		end
	end
end

function ProgressBar:IsModeLocked()
	return self.sets.lockMode or not self:HasMultipleModes()
end

function ProgressBar:HasMultipleModes()
	return #self.modes > 1
end

function ProgressBar:SetAutoSwitchModes(enable)
	self.sets.lockMode = not enable
	self.lastAutoMode = nil
	self:Refresh()
end

function ProgressBar:SwitchesModesAutomatically()
	return not self:IsModeLocked()
end

--------------------------------------------------------------------------------
-- Display conditions
--------------------------------------------------------------------------------

-- a bar with any active mode stays, so there's always something to click to.
-- xp is inactive at max level, which is what hides a bar that only has xp
function ProgressBar:GetDisplayConditions()
	if self:UsesAutoHide() and not self:HasActiveMode() then
		return 'hide'
	end
end

-- remembers what was applied, so Refresh only acts when it changes
function ProgressBar:UpdateDisplayConditions()
	ProgressBar.proto.UpdateDisplayConditions(self)
	self.displayConditions = self:GetDisplayConditions()
end

function ProgressBar:SetAutoHide(hide)
	self.sets.autoHide = hide and true or false
	self:UpdateDisplayConditions()
end

function ProgressBar:UsesAutoHide()
	return self.sets.autoHide or false
end

--------------------------------------------------------------------------------
-- Values
--------------------------------------------------------------------------------

function ProgressBar:UpdateDisplay()
	local value, max, bonus = self.provider:GetValues()
	value = tonumber(value) or 0
	max = tonumber(max) or 0
	bonus = tonumber(bonus) or 0

	self:UpdateText(value, max, bonus)

	-- reputation's stock art follows the standing
	if self.nativeAtlas and self.provider:GetNativeTextures() ~= self.nativeAtlas then
		self:UpdateTextures()
	else
		self:UpdateColors()
	end

	if value ~= self.shownValue or max ~= self.shownMax or bonus ~= self.shownBonus then
		self.shownValue = value
		self.shownMax = max
		self.shownBonus = bonus
		self:UpdateFill(value, max, bonus)
		self:RefreshTooltip()
	end
end

---@param value number
---@param max number
---@param bonus number
function ProgressBar:UpdateFill(value, max, bonus)
	value = math.min(value, max)
	bonus = bonus > 0 and math.min(value + bonus, max) or bonus

	-- in percent of a segment
	local segments = self.segments
	local count = self:GetSegmentCount()
	local scale = max > 0 and (100 * count / max) or 0

	for i = 1, count do
		local start = (i - 1) * 100

		segments[i].value:SetValue(Round(Clamp(value * scale - start, 0, 100)))
		segments[i]:SetValue(Round(Clamp(bonus * scale - start, 0, 100)))
	end
end

function ProgressBar:InvalidateShownValues()
	self.shownValue = nil
	self.shownMax = nil
	self.shownBonus = nil
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

-- bars sit at screen edges, so open toward the middle
function ProgressBar:GetTooltipAnchor()
	local _, y = self:GetCenter()

	if y and y * self:GetEffectiveScale() > UIParent:GetHeight() * UIParent:GetEffectiveScale() / 2 then
		return 'ANCHOR_BOTTOM'
	end

	return 'ANCHOR_TOP'
end

function ProgressBar:ShowTooltip()
	GameTooltip:SetOwner(self.overlay, self:GetTooltipAnchor())
	self.provider:SetupTooltip(GameTooltip, self.refreshTooltip)
	GameTooltip:Show()
end

-- like the stock UpdatePointsTooltip, only redo a tooltip we already own.
-- hidden first, as ClearLines leaves progress bars and reward frames behind
function ProgressBar:RefreshTooltip()
	if GameTooltip:IsOwned(self.overlay) then
		GameTooltip:Hide()
		self:ShowTooltip()
	end
end

function ProgressBar:HideTooltip()
	if GameTooltip:IsOwned(self.overlay) then
		GameTooltip:Hide()
	end
end

function ProgressBar:SetShowTooltip(enable)
	self.sets.showTooltip = enable and true or false
	if not enable then
		self:HideTooltip()
	end
end

function ProgressBar:ShowingTooltip()
	return self.sets.showTooltip
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

function ProgressBar:Layout()
	local width, height = self:GetDesiredWidth(), self:GetDesiredHeight()
	local padW, padH = self:GetPadding()
	local segCount = self:GetSegmentCount()
	local segW, divW, pixel = self:GetSegmentMetrics()

	for i = 1, segCount do
		local segment = self.segments[i]
		if not segment then
			segment = createSegment(self)
			self.segments[i] = segment
		end

		local left, right = getSegmentEdges(i, segW, divW, pixel)
		segment:SetSize(right - left, height)
		segment:SetPoint('LEFT', left + padW, 0)
		segment:Show()
	end

	for i = segCount + 1, #self.segments do
		self.segments[i]:Hide()
	end

	self.text:SetWidth(width)

	self:UpdateBorder()

	self:TrySetSize(width + padW * 2, height + padH * 2)
end

function ProgressBar:SetDesiredWidth(width)
	self.sets.width = width
	self:Layout()
end

function ProgressBar:GetDesiredWidth()
	return self.sets.width
end

function ProgressBar:SetDesiredHeight(height)
	self.sets.height = height
	self:Layout()
end

function ProgressBar:GetDesiredHeight()
	return self.sets.height
end

function ProgressBar:SetSegmentCount(count)
	self.sets.numButtons = count

	self:Layout()
	self:UpdateTextures()
	self:InvalidateShownValues()
	self:UpdateDisplay()
end

function ProgressBar:GetSegmentCount()
	return math.max(1, self.sets.numButtons)
end

-- the room each segment gets, the gap between them in whole pixels (at least
-- one, if there's any), and the size of a pixel
---@return number segW
---@return number divW
---@return number pixel
function ProgressBar:GetSegmentMetrics()
	local pixel = PixelUtil.GetPixelToUIUnitFactor() / self:GetEffectiveScale()
	local count = self:GetSegmentCount()

	local divW = self:GetDividerWidth()
	if divW > 0 then
		divW = math.max(snapToPixel(divW, pixel), pixel)
	end

	local segW = (self:GetDesiredWidth() - (count - 1) * divW) / count
	return segW, divW, pixel
end

-- saved as spacing
function ProgressBar:SetDividerWidth(width)
	self.sets.spacing = tonumber(width) or 0
	self:Layout()
end

function ProgressBar:GetDividerWidth()
	return math.max(self.sets.spacing or 0, 0)
end

function ProgressBar:HasBorderArt()
	return self.borderCapWidth ~= nil
end

-- Layout calls this, so the dividers follow size changes too
function ProgressBar:UpdateBorder()
	local border = self.border
	local capWidth = self.borderCapWidth
	local showBorder = capWidth ~= nil and self:ShowingBorder()

	self:UpdateDividers(showBorder)

	if not showBorder then
		border:Hide()
		return
	end

	-- a bar as wide as the screen pushes the caps offscreen, so only the edges show
	local edge = BORDER_OUTSET
	if self:GetWidth() * self:GetEffectiveScale() >= UIParent:GetWidth() * UIParent:GetEffectiveScale() then
		edge = capWidth + BORDER_OUTSET
	end

	border:ClearAllPoints()
	border:SetPoint('TOPLEFT', -edge, BORDER_OUTSET)
	border:SetPoint('BOTTOMRIGHT', edge, -BORDER_OUTSET)
	border:Show()
end

-- the stock dividers go with the border. otherwise the gaps between segments
-- are left empty, and there's nothing to make
---@param showBorder boolean
function ProgressBar:UpdateDividers(showBorder)
	local dividers = self.dividers
	local divCount = 0

	if showBorder and atlasExists(NATIVE_DIVIDER_ATLAS) then
		local height = self:GetDesiredHeight()
		local padW = self:GetPadding()
		local segW, divW, pixel = self:GetSegmentMetrics()

		divCount = self:GetSegmentCount() - 1

		for i = 1, divCount do
			local divider = dividers[i]
			if not divider then
				divider = self:CreateTexture(nil, 'ARTWORK')
				divider:SetAtlas(NATIVE_DIVIDER_ATLAS)
				dividers[i] = divider
			end

			-- in the gap after segment i
			local _, right = getSegmentEdges(i, segW, divW, pixel)
			divider:SetSize(divW, height)
			divider:SetPoint('LEFT', right + padW, 0)
			divider:Show()
		end
	end

	for i = divCount + 1, #dividers do
		dividers[i]:Hide()
	end
end

-- display only holds the border now
function ProgressBar:SetShowBorder(enable)
	self.sets.display.border = enable and true or false
	self:UpdateBorder()
end

function ProgressBar:ShowingBorder()
	return self.sets.display.border
end

--------------------------------------------------------------------------------
-- Textures and colors
--------------------------------------------------------------------------------

-- the stock art for the current mode, unless overridden or missing on this client
---@return string? valueAtlas nil when not using the stock art
---@return string? bonusAtlas
function ProgressBar:GetNativeAtlases()
	local provider = self.provider

	if self:HasTexture() or not provider.GetNativeTextures then
		return
	end

	local valueAtlas, bonusAtlas = provider:GetNativeTextures()
	bonusAtlas = bonusAtlas or valueAtlas

	if atlasExists(valueAtlas) and atlasExists(bonusAtlas) and atlasExists(NATIVE_BACKGROUND_ATLAS) then
		return valueAtlas, bonusAtlas
	end
end

-- mode, texture and color setting changes. per event coloring is UpdateColors
function ProgressBar:UpdateTextures()
	local valueAtlas, bonusAtlas = self:GetNativeAtlases()
	self.nativeAtlas = valueAtlas

	-- stock art in other colors is desaturated, then tinted like the plain bar
	local provider = self.provider
	self.tintsFill = not valueAtlas or provider:IsRecolored()
	self:InvalidateShownColors()

	if valueAtlas then
		local desaturate = self.tintsFill

		for _, segment in ipairs(self.segments) do
			segment.value:SetStatusBarTexture(valueAtlas)
			segment.value:GetStatusBarTexture():SetDesaturated(desaturate)
			segment.value:SetStatusBarColor(1, 1, 1, 1)

			segment:SetStatusBarTexture(bonusAtlas)
			segment:GetStatusBarTexture():SetDesaturated(desaturate)
			segment:SetStatusBarColor(1, 1, 1, 1)

			segment.bg:SetAtlas(NATIVE_BACKGROUND_ATLAS)
			segment.bg:SetVertexColor(1, 1, 1, 1)
		end
	else
		local texture = self:HasTexture() and LSM:Fetch('statusbar', self:GetTextureID()) or PLAIN_TEXTURE

		for _, segment in ipairs(self.segments) do
			segment.value:SetStatusBarTexture(texture)
			segment.value:GetStatusBarTexture():SetDesaturated(false)

			segment:SetStatusBarTexture(texture)
			segment:GetStatusBarTexture():SetDesaturated(false)

			segment.bg:SetTexture(texture)
		end
	end

	self:UpdateColors()

	-- a new fill texture isn't cropped until the value is set again
	if self.shownValue then
		self:UpdateFill(self.shownValue, self.shownMax, self.shownBonus)
	end
end

-- providers return shared color objects, so compare by reference
function ProgressBar:UpdateColors()
	if not self.tintsFill then
		return
	end

	local provider = self.provider

	local valueColor = provider:GetColor()
	local bonusColor = provider.GetBonusColor and provider:GetBonusColor() or TRANSPARENT_COLOR

	if valueColor == self.shownColor and bonusColor == self.shownBonusColor then
		return
	end

	self.shownColor = valueColor
	self.shownBonusColor = bonusColor

	local r, g, b, a = valueColor:GetRGBA()
	local br, bg, bb, ba = bonusColor:GetRGBA()

	-- the stock background stays as is
	local tintsBackground = not self.nativeAtlas

	local vr, vg, vb, va = r, g, b, a
	if self.nativeAtlas then
		vr, vg, vb, va = brightenTint(r, g, b, a)
		br, bg, bb, ba = brightenTint(br, bg, bb, ba)
	end

	for _, segment in ipairs(self.segments) do
		segment.value:SetStatusBarColor(vr, vg, vb, va)
		segment:SetStatusBarColor(br, bg, bb, ba)

		if tintsBackground then
			segment.bg:SetVertexColor(r / 2, g / 2, b / 2, a / 2)
		end
	end
end

function ProgressBar:InvalidateShownColors()
	self.shownColor = nil
	self.shownBonusColor = nil
end

-- no texture is the stock art
---@param textureID string|false|nil false or nil for the stock art
function ProgressBar:SetTextureID(textureID)
	self.sets.texture = textureID or nil
	self:UpdateTextures()
end

function ProgressBar:GetTextureID()
	return self.sets.texture
end

-- a saved texture that isn't registered (yet) draws the stock art, like the menu shows
function ProgressBar:HasTexture()
	return self.sets.texture ~= nil and LSM:IsValid('statusbar', self.sets.texture)
end

--------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------

local function refreshText(bar)
	bar:UpdateClickThrough()
	bar:UpdateTextShown()
	bar:UpdateDisplay()
end

---@param value number
---@param max number
---@param bonus number
function ProgressBar:UpdateText(value, max, bonus)
	local text

	if self:ShowingText() then
		local options = self.textOptions
		options.formatNumber = self:AbbreviatesNumbers() and AbbreviateNumbers or BreakUpLargeNumbers
		options.showLabel = self:ShowingLabel()
		options.showBonus = self:ShowingBonus()
		text = self.provider:GetText(self:GetTextFormat(), options, value, max, bonus)
	end

	if text ~= self.shownText then
		self.shownText = text
		self.text:SetText(text)
	end
end

---@param hovered boolean? asks the overlay when nil
function ProgressBar:UpdateTextShown(hovered)
	if hovered == nil then
		hovered = self.overlay:IsMouseOver()
	end

	self.text:SetShown(self:ShowingText() and (hovered or not self:ShowingTextOnMouseover()))
end

---@param textFormat TextFormat
function ProgressBar:SetTextFormat(textFormat)
	self.sets.textFormat = textFormat
	self:UpdateDisplay()
end

function ProgressBar:GetTextFormat()
	return self.sets.textFormat
end

function ProgressBar:SetShowLabel(enable)
	self.sets.showLabel = enable and true or false
	self:UpdateDisplay()
end

function ProgressBar:ShowingLabel()
	return self.sets.showLabel
end

function ProgressBar:SetShowBonus(enable)
	self.sets.showBonus = enable and true or false
	self:UpdateDisplay()
end

function ProgressBar:ShowingBonus()
	return self.sets.showBonus
end

-- saved as one value: true, false or 'mouseover'. no text is built while it's
-- off, so turning it on rebuilds. the condition it had is kept for this session,
-- so checking it again puts that back
function ProgressBar:SetShowText(enable)
	if enable then
		self.sets.showText = self.lastShowText or true
	else
		if self:ShowingText() then
			self.lastShowText = self.sets.showText
		end
		self.sets.showText = false
	end

	refreshText(self)
end

function ProgressBar:ShowingText()
	return self.sets.showText ~= false
end

function ProgressBar:ShowingTextOnMouseover()
	return self.sets.showText == 'mouseover'
end

-- the condition 'always' or 'mouseover', for when it's shown
---@param visibility 'always'|'mouseover'
function ProgressBar:SetTextVisibility(visibility)
	local showText = visibility == 'mouseover' and 'mouseover' or true

	if self:ShowingText() then
		self.sets.showText = showText
		refreshText(self)
	else
		self.lastShowText = showText
	end
end

-- shows the remembered condition while the text is off
---@return 'always'|'mouseover'
function ProgressBar:GetTextVisibility()
	local showText = self.sets.showText

	if showText == false then
		showText = self.lastShowText
	end

	return showText == 'mouseover' and 'mouseover' or 'always'
end

function ProgressBar:SetAbbreviateNumbers(enable)
	self.sets.abbreviateNumbers = enable and true or false
	self:UpdateDisplay()
end

function ProgressBar:AbbreviatesNumbers()
	return self.sets.abbreviateNumbers
end

--------------------------------------------------------------------------------
-- Font
--------------------------------------------------------------------------------

-- no font means the stock one. size and outline apply to it too
function ProgressBar:UpdateFont()
	local stockPath = getStockFont()
	local fontID = self:GetFontID()
	local fontPath = fontID and LSM:Fetch('font', fontID) or stockPath
	local size, outline = self:GetFontSize(), self:GetFontOutline()

	-- shared media can list fonts this client doesn't have (classic), and
	-- SetFont errors on those
	local ok, loaded = pcall(self.text.SetFont, self.text, fontPath, size, outline)

	if not ok or loaded == false then
		self.text:SetFont(stockPath, size, outline)
	end
end

---@param fontID string|false|nil false or nil for the stock font
function ProgressBar:SetFontID(fontID)
	self.sets.font = fontID or nil
	self:UpdateFont()
end

-- same as the texture, a font that isn't registered (yet) is the stock one
function ProgressBar:GetFontID()
	local fontID = self.sets.font

	if fontID and LSM:IsValid('font', fontID) then
		return fontID
	end
end

function ProgressBar:SetFontSize(size)
	self.sets.fontSize = size
	self:UpdateFont()
end

function ProgressBar:GetFontSize()
	if self.sets.fontSize then
		return self.sets.fontSize
	end

	local _, size = getStockFont()
	return Round(size)
end

---@param outline FontOutline
function ProgressBar:SetFontOutline(outline)
	self.sets.fontOutline = outline
	self:UpdateFont()
end

---@return FontOutline
function ProgressBar:GetFontOutline()
	local outline = self.sets.fontOutline
	if outline then
		return outline
	end

	-- the stock font's flags can hold more than the outline
	local _, _, flags = getStockFont()
	flags = flags or ''

	if flags:find('THICKOUTLINE', 1, true) then
		return 'THICKOUTLINE'
	elseif flags:find('OUTLINE', 1, true) then
		return 'OUTLINE'
	end

	return ''
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

Addon.ProgressBar = ProgressBar
