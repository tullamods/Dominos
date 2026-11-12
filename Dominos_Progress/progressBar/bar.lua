local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local LSM = LibStub('LibSharedMedia-3.0')

---@alias FontOutline '' | 'OUTLINE' | 'THICKOUTLINE'

---@class ProgressBar : Frame
---@field sets table saved settings
---@field modes string[] what this bar can show, the first is the fallback
---@field mode string? the one showing
---@field autoMode string? the last one auto switch picked
---@field provider DataProvider? for the mode showing
---@field lastShowText true|'mouseover'|nil what showText was before it was turned off
---@field displayConditions string? what the last UpdateDisplayConditions applied
---@field shownMax number? the max the fill last showed, so a new one snaps
---@field tipValue number? what the open tooltip was built from
---@field tipMax number?
---@field tipBonus number?
---@field tinted boolean? false while the stock art is on
---@field valueColor ColorMixin?
---@field bonusColor ColorMixin?
---@field borderCapWidth number? nil without the border art
---@field textOptions TextOptions
---@field refreshTooltip fun()
---@field valueBar StatusBar
---@field bonusBar StatusBar under the value bar, so bonus shows past it
---@field background Texture
---@field overlay Button clicks, dividers, border and text live on it
---@field dividers table texture pool
---@field border Texture
---@field text FontString
local ProgressBar = Dominos:CreateClass('Frame', Dominos.Frame)

-- stock status bar art
local NATIVE_BORDER_ATLAS = 'UI-HUD-ExperienceBar-Frame'
local NATIVE_BACKGROUND_ATLAS = 'UI-HUD-ExperienceBar-Background'
local NATIVE_DIVIDER_ATLAS = 'ui-hud-experiencebar-divider'
local NATIVE_FONT = 'TextStatusBarText'
-- the stock look for modes without fill art, and clients without the atlases
local PLAIN_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]

-- the stock container is 6 bigger than its bar, so 3 per side
local BORDER_OUTSET = 3

-- same as the stock divider
local DIVIDER_WIDTH = 3

-- painted gaps between segments, when not using the stock divider
local GAP_ALPHA = 0.5

local NO_BONUS_COLOR = CreateColor(0, 0, 0, 0)

local SMOOTH_FILL = Enum.StatusBarInterpolation.ExponentialEaseOut
local INSTANT_FILL = Enum.StatusBarInterpolation.Immediate

local DEFAULT_DISPLAY = { border = true }

local function atlasExists(atlas)
	return atlas ~= nil and C_Texture.GetAtlasInfo(atlas) ~= nil
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

-- only new bars get these. a setting added later needs a fill-in in migrations.lua
function ProgressBar:GetDefaults()
	return {
		point = 'BOTTOM',
		width = 1024,
		height = 12,
		numButtons = 20,
		padW = 2,
		padH = 2,
		display = CopyTable(DEFAULT_DISPLAY),
		displayLayer = 'BACKGROUND',
		textFormat = 'valueMaxPercent',
		showLabel = true,
		showBonus = true,
		showText = true,
		abbreviateNumbers = false,
		showTooltip = true,
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

	bar.modes = loadedModes
	bar.mode = nil
	bar.provider = nil
	bar.autoMode = nil
	bar.lastShowText = nil
	bar.displayConditions = nil
	bar.tipValue, bar.tipMax, bar.tipBonus = nil, nil, nil
	bar:Refresh()

	return bar
end

function ProgressBar:OnCreate()
	ProgressBar.proto.OnCreate(self)

	self.textOptions = {}

	-- made once, so providers can hand it to late loading data
	self.refreshTooltip = function()
		self:RefreshTooltip()
	end

	-- bonus sits under value, so rested xp shows past the current xp
	local bonusBar = CreateFrame('StatusBar', nil, self)
	bonusBar:SetFillStyle(Enum.StatusBarFillStyle.StandardNoRangeFill)
	self.bonusBar = bonusBar

	local valueBar = CreateFrame('StatusBar', nil, self)
	valueBar:SetFillStyle(Enum.StatusBarFillStyle.StandardNoRangeFill)
	valueBar:SetAllPoints(bonusBar)
	self.valueBar = valueBar

	local background = self:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints(bonusBar)
	self.background = background

	-- clicks, dividers, border and text all live on one frame over the fill
	local overlay = CreateFrame('Button', nil, self)
	overlay:SetAllPoints(self)
	overlay:RegisterForClicks('AnyUp')
	overlay:SetScript('OnClick', function()
		self:NextMode()
	end)
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
	self.overlay = overlay

	self.dividers = CreateTexturePool(overlay, 'ARTWORK')

	local border = overlay:CreateTexture(nil, 'OVERLAY')
	local borderInfo = C_Texture.GetAtlasInfo(NATIVE_BORDER_ATLAS)
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

	local text = overlay:CreateFontString(nil, 'OVERLAY', NATIVE_FONT)
	text:SetDrawLayer('OVERLAY', 1)
	text:SetPoint('CENTER', 0, 1)
	self.text = text
end

-- runs before New hands over the modes, so nothing here can touch the provider
function ProgressBar:OnLoadSettings()
	self:UpgradeSettings()

	self:Layout()
	self:UpdateFont()
	self:UpdateClickThrough()
	self:UpdateTextShown()
end

-- the border depends on whether the bar spans the screen
function ProgressBar:OnSetScale()
	self:UpdateBorder()
end

-- keep the fill and overlay above the bar, wherever its level is set
function ProgressBar:UpdateDisplayLevel()
	ProgressBar.proto.UpdateDisplayLevel(self)

	local level = self:GetFrameLevel()
	self.bonusBar:SetFrameLevel(level + 1)
	self.valueBar:SetFrameLevel(level + 2)
	self.overlay:SetFrameLevel(level + 3)
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
		self:UpdateDividers()
	elseif mediaType == LSM.MediaType.FONT and key == self.sets.font then
		self:UpdateFont()
	end
end

--------------------------------------------------------------------------------
-- Modes
--------------------------------------------------------------------------------

-- what game events call: let auto switch pick, restyle if the mode changed, update
function ProgressBar:Refresh()
	-- modes go active and inactive, and hiding has to follow
	if self:UsesAutoHide() and self:GetDisplayConditions() ~= self.displayConditions then
		self:UpdateDisplayConditions()
	end

	-- auto switch only acts when its own pick changes, so manual clicks stick
	if not self:IsModeLocked() then
		local autoMode = self:GetAutoMode()

		if autoMode ~= self.autoMode then
			self.autoMode = autoMode
			Addon.Config:SetBarMode(self.id, autoMode)
		end
	end

	self:ApplyMode()
end

function ProgressBar:ApplyMode()
	local mode = self:GetMode()

	if mode ~= self.mode then
		self.mode = mode
		self.provider = Addon.dataProviders[mode]
		self.shownMax = nil
		self.tipValue = nil
		self:UpdateTextures()
	end

	self:Update()
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
	self.autoMode = nil
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

function ProgressBar:Update()
	-- settings can change before the first refresh picks a mode
	if not self.provider then
		return
	end

	local value, max, bonus = self.provider:GetValues()
	value, max, bonus = tonumber(value) or 0, tonumber(max) or 0, tonumber(bonus) or 0

	self:UpdateFill(value, max, bonus)
	self:UpdateColors()
	self:UpdateText(value, max, bonus)

	-- a tooltip that's open only needs redoing when its numbers moved
	if value ~= self.tipValue or max ~= self.tipMax or bonus ~= self.tipBonus then
		self.tipValue, self.tipMax, self.tipBonus = value, max, bonus
		self:RefreshTooltip()
	end
end

---@param value number
---@param max number
---@param bonus number
function ProgressBar:UpdateFill(value, max, bonus)
	-- a new max (level up, new mode) snaps, so the bar doesn't drain backwards
	local interpolation = (self:UsesSmoothFill() and max == self.shownMax) and SMOOTH_FILL or INSTANT_FILL
	self.shownMax = max

	self.valueBar:SetMinMaxValues(0, max)
	self.valueBar:SetValue(value, interpolation)

	self.bonusBar:SetMinMaxValues(0, max)
	self.bonusBar:SetValue(bonus > 0 and math.min(value + bonus, max) or 0, interpolation)
end

function ProgressBar:SetSmoothFill(enable)
	self.sets.smoothFill = enable and true or false
end

function ProgressBar:UsesSmoothFill()
	return self.sets.smoothFill
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
	local padW, padH = self:GetPadding()
	local width = self:GetDesiredWidth()

	self:TrySetSize(width + 2 * padW, self:GetDesiredHeight() + 2 * padH)

	self.bonusBar:ClearAllPoints()
	self.bonusBar:SetPoint('TOPLEFT', padW, -padH)
	self.bonusBar:SetPoint('BOTTOMRIGHT', -padW, padH)

	-- long text is cut off instead of spilling out of short bars
	self.text:SetWidth(width)
	self.text:SetWordWrap(false)

	self:UpdateDividers()
	self:UpdateBorder()
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

-- segments are only dividers painted over the one fill
function ProgressBar:UpdateDividers()
	self.dividers:ReleaseAll()

	local count = self:GetSegmentCount()
	local segmentWidth = self:GetDesiredWidth() / count
	local useAtlas = not self:HasTexture() and atlasExists(NATIVE_DIVIDER_ATLAS)

	for i = 1, count - 1 do
		local divider = self.dividers:Acquire()

		if useAtlas then
			divider:SetAtlas(NATIVE_DIVIDER_ATLAS)
		else
			divider:SetColorTexture(0, 0, 0, GAP_ALPHA)
		end

		divider:SetWidth(DIVIDER_WIDTH)
		divider:SetPoint('TOP', self.bonusBar, 'TOPLEFT', i * segmentWidth, 0)
		divider:SetPoint('BOTTOM', self.bonusBar, 'BOTTOMLEFT', i * segmentWidth, 0)
		divider:Show()
	end
end

-- numButtons is the old ButtonBar key, kept so settings carry over
function ProgressBar:SetSegmentCount(count)
	self.sets.numButtons = count
	self:UpdateDividers()
end

function ProgressBar:GetSegmentCount()
	return math.max(1, self.sets.numButtons)
end

function ProgressBar:HasBorderArt()
	return self.borderCapWidth ~= nil
end

function ProgressBar:UpdateBorder()
	local border = self.border
	local capWidth = self.borderCapWidth
	if not (capWidth and self:ShowingBorder()) then
		border:Hide()
		return
	end

	-- a bar as wide as the screen pushes the caps offscreen, so only the edges show
	local edge = BORDER_OUTSET
	if self:GetWidth() * self:GetEffectiveScale() >= UIParent:GetWidth() * UIParent:GetEffectiveScale() then
		edge = self:GetPadding() + capWidth + BORDER_OUTSET
	end

	border:ClearAllPoints()
	border:SetPoint('TOPLEFT', self.bonusBar, -edge, BORDER_OUTSET)
	border:SetPoint('BOTTOMRIGHT', self.bonusBar, edge, -BORDER_OUTSET)
	border:Show()
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

	if self:HasTexture() or not provider.GetNativeTextures or provider:IsRecolored() then
		return
	end

	local valueAtlas, bonusAtlas = provider:GetNativeTextures()
	bonusAtlas = bonusAtlas or valueAtlas

	if atlasExists(valueAtlas) and atlasExists(bonusAtlas) and atlasExists(NATIVE_BACKGROUND_ATLAS) then
		return valueAtlas, bonusAtlas
	end
end

-- mode and texture changes only. per event coloring is UpdateColors
function ProgressBar:UpdateTextures()
	if not self.provider then
		return
	end

	local valueAtlas, bonusAtlas = self:GetNativeAtlases()

	self.valueColor = nil
	self.bonusColor = nil

	-- the stock art is already colored
	self.tinted = not valueAtlas

	if valueAtlas then
		self.valueBar:SetStatusBarTexture(valueAtlas)
		self.valueBar:SetStatusBarColor(1, 1, 1, 1)
		self.bonusBar:SetStatusBarTexture(bonusAtlas)
		self.bonusBar:SetStatusBarColor(1, 1, 1, 1)
		self.background:SetAtlas(NATIVE_BACKGROUND_ATLAS)
		self.background:SetVertexColor(1, 1, 1, 1)
		return
	end

	local texture = self:HasTexture() and LSM:Fetch('statusbar', self:GetTextureID()) or PLAIN_TEXTURE

	self.valueBar:SetStatusBarTexture(texture)
	self.bonusBar:SetStatusBarTexture(texture)
	self.background:SetTexture(texture)
	-- the atlas leaves its own coords behind
	self.background:SetTexCoord(0, 1, 0, 1)
	self:UpdateColors()
end

-- providers hand out colors on every update, but they almost never change
function ProgressBar:UpdateColors()
	if not self.tinted then
		return
	end

	local provider = self.provider

	local valueColor = provider:GetColor()
	if valueColor ~= self.valueColor then
		self.valueColor = valueColor

		local r, g, b, a = valueColor:GetRGBA()
		self.valueBar:SetStatusBarColor(r, g, b, a)
		self.background:SetVertexColor(r / 2, g / 2, b / 2, a / 2)
	end

	-- no bonus color, no visible bonus
	local bonusColor = provider.GetBonusColor and provider:GetBonusColor() or NO_BONUS_COLOR
	if bonusColor ~= self.bonusColor then
		self.bonusColor = bonusColor
		self.bonusBar:SetStatusBarColor(bonusColor:GetRGBA())
	end
end

-- no texture is the stock art
---@param textureID string|false|nil false or nil for the stock art
function ProgressBar:SetTextureID(textureID)
	self.sets.texture = textureID or nil
	self:UpdateTextures()
	self:UpdateDividers()
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
	bar:Update()
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

	self.text:SetText(text)
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
	self:Update()
end

function ProgressBar:GetTextFormat()
	return self.sets.textFormat
end

function ProgressBar:SetShowLabel(enable)
	self.sets.showLabel = enable and true or false
	self:Update()
end

function ProgressBar:ShowingLabel()
	return self.sets.showLabel
end

function ProgressBar:SetShowBonus(enable)
	self.sets.showBonus = enable and true or false
	self:Update()
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
	self:Update()
end

function ProgressBar:AbbreviatesNumbers()
	return self.sets.abbreviateNumbers
end

--------------------------------------------------------------------------------
-- Font
--------------------------------------------------------------------------------

-- no font means the stock one. size and outline apply to it too
function ProgressBar:UpdateFont()
	local stockPath = _G[NATIVE_FONT]:GetFont()
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
	return self.sets.fontSize or Round((select(2, _G[NATIVE_FONT]:GetFont())))
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
	local flags = select(3, _G[NATIVE_FONT]:GetFont()) or ''

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
