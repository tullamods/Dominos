--[[ a generic widget for holding stuff ]]--

local _, Addon = ...
local L = Addon:GetLocale()
local ParentAddon = Addon:GetParent()

local PanelMixin = {}

PanelMixin.spacing = 8
PanelMixin.topPadding = 8
PanelMixin.bottomPadding = 4
PanelMixin.leftPadding = 4
PanelMixin.rightPadding = 4

local function addControl(panel, widget)
	local index = #panel.widgets + 1

	widget.layoutIndex = index
	panel.widgets[index] = widget
	panel:MarkDirty()
end

function PanelMixin:SetOwner(owner)
	self.owner = owner
end

function PanelMixin:GetOwner()
	return self.owner
end

function PanelMixin:Render()
	-- self:SetSize(max(self.width, MIN_WIDTH), max(self.height, MIN_HEIGHT))
	Addon:Render(self)
end

function PanelMixin:OnRender()
	self:MarkDirty()
end

--[[ generic widgets ]]--

function PanelMixin:NewHeader(name)
	local frame = CreateFrame('Frame', nil, self, 'ResizeLayoutFrame')

	frame.expand = true

	-- space out sections, but not above the first control
	if #self.widgets > 0 then
		frame.topPadding = 8
	end

	local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	text:SetJustifyH('LEFT')
	text:SetPoint('TOPLEFT', 0, 1)
	text:SetText(name)
	text:SetHeight(text:GetStringHeight())

	local divider = frame:CreateTexture(nil, 'ARTWORK')
	divider:SetAtlas('Options_HorizontalDivider', true)
	divider:SetPoint('BOTTOMLEFT')
	divider:SetPoint('BOTTOMRIGHT')

	frame:SetFixedHeight(text:GetStringHeight() + divider:GetHeight() + 4)
	frame:MarkDirty()

	addControl(self, frame)

	return frame
end

-- returns a copy of options for a widget in this panel, so that callers' tables
-- are left alone
local function widgetOptions(panel, options, overrides)
	local copy = { parent = panel }

	for k, v in pairs(options) do
		copy[k] = v
	end

	if overrides then
		for k, v in pairs(overrides) do
			copy[k] = v
		end
	end

	return copy
end

function PanelMixin:NewCheckButton(options)
	local button = Addon:CreateCheckButton(widgetOptions(self, options))

	addControl(self, button)

	return button
end

function PanelMixin:NewSlider(options)
	local slider = Addon:CreateSlider(widgetOptions(self, options))

	addControl(self, slider)

	return slider
end

function PanelMixin:NewDropdown(options)
	local dropdown = Addon:CreateDropdown(widgetOptions(self, options))

	addControl(self, dropdown)

	return dropdown
end

-- media settings may be missing or refer to media that isn't registered (ex,
-- old lowercase defaults). LibSharedMedia falls back to its default in that
-- case, so show that as the selected value
local function getValidMedia(mediaType, get)
	local LSM = LibStub('LibSharedMedia-3.0')

	return function(...)
		local value = get(...)

		if value and LSM:IsValid(mediaType, value) then
			return value
		end

		return LSM:GetDefault(mediaType)
	end
end

function PanelMixin:NewFontPicker(options)
	local dropdown = Addon:CreateFontPicker(widgetOptions(self, options, {
		get = getValidMedia('font', options.get)
	}))

	addControl(self, dropdown)

	return dropdown
end

function PanelMixin:NewTextureSelector(options)
	local dropdown = Addon:CreateDropdown(widgetOptions(self, options, {
		items = function()
			return LibStub('LibSharedMedia-3.0'):List('statusbar')
		end,
		get = getValidMedia('statusbar', options.get)
	}))

	addControl(self, dropdown)

	return dropdown
end

function PanelMixin:NewTextInput(options)
	local textInput = Addon:CreateTextInput(widgetOptions(self, options))

	addControl(self, textInput)

	return textInput
end

--[[ table driven options ]]--

-- returns a function that calls prop with the panel's current owner. prop can
-- be a function(owner, ...) or the name of a method on the owner. anything
-- else is returned as is. option is the definition prop came from, for errors
local function bindOwner(panel, prop, option)
	if type(prop) == 'string' then
		return function(...)
			local owner = panel.owner
			local method = owner[prop]

			if type(method) ~= 'function' then
				error(('Option %q refers to %q, which %s does not have'):format(
					tostring(option.name), prop, tostring(owner.id or owner)), 2)
			end

			return method(owner, ...)
		end
	end

	if type(prop) == 'function' then
		return function(...)
			return prop(panel.owner, ...)
		end
	end

	return prop
end

-- the widget to create for each option type. every widget calls set with the
-- new value
local OPTION_WIDGETS = {
	slider = 'NewSlider',
	check = 'NewCheckButton',
	dropdown = 'NewDropdown',
	font = 'NewFontPicker',
	texture = 'NewTextureSelector',
	text = 'NewTextInput',
}

function PanelMixin:AddOption(def)
	if def.type == 'header' then
		return self:NewHeader(def.name)
	end

	local create = OPTION_WIDGETS[def.type]
	assert(create, ('Unknown option type %q'):format(tostring(def.type)))

	local label = tostring(def.name)
	assert(def.get, ('Option %q is missing get'):format(label))
	assert(def.set, ('Option %q is missing set'):format(label))

	local options = {}
	for k, v in pairs(def) do
		options[k] = v
	end

	options.min = bindOwner(self, def.min, def)
	options.max = bindOwner(self, def.max, def)
	options.items = bindOwner(self, def.items, def)

	options.get = bindOwner(self, def.get, def)

	-- after any change, refresh the rest of the panel, as other options may
	-- depend on this one (ex, columns is limited by size)
	local set = bindOwner(self, def.set, def)
	local widget
	options.set = function(value)
		set(value)
		self:QueueRefresh(widget)
	end

	widget = self[create](self, options)

	return widget
end

function PanelMixin:AddOptions(defs)
	for _, def in ipairs(defs) do
		self:AddOption(def)
	end
end

-- refresh every widget, other than the ones that just changed, on the next
-- frame. this batches up rapid changes (ex, dragging a slider)
function PanelMixin:QueueRefresh(source)
	self.refreshSources = self.refreshSources or {}
	self.refreshSources[source] = true

	if self.refreshQueued then
		return
	end

	self.refreshQueued = true

	C_Timer.After(0, function()
		local sources = self.refreshSources

		self.refreshQueued = nil
		self.refreshSources = nil

		for _, widget in ipairs(self.widgets) do
			if not sources[widget] and widget.Refresh then
				widget:Refresh()
			end
		end
	end)
end

--[[ shared option definitions ]]--

-- combines the left to right and top to bottom settings into the direction
-- buttons fill the grid in
local LAYOUT_DIRECTION_ITEMS = {
	{ value = "TOPLEFT", text = L.LayoutRightDown, leftToRight = true, topToBottom = true },
	{ value = "TOPRIGHT", text = L.LayoutLeftDown, leftToRight = false, topToBottom = true },
	{ value = "BOTTOMLEFT", text = L.LayoutRightUp, leftToRight = true, topToBottom = false },
	{ value = "BOTTOMRIGHT", text = L.LayoutLeftUp, leftToRight = false, topToBottom = false }
}

-- common show state macro conditionals, so that people don't need to write
-- them by hand
local SHOW_PRESET_ITEMS = {
	{ value = "ALWAYS", text = L.ShowAlways, conditions = "" },
	{ value = "NEVER", text = L.ShowNever, conditions = "hide" },
	{ value = "COMBAT", text = L.ShowInCombat, conditions = "[combat]show;hide" },
	{ value = "NOCOMBAT", text = L.ShowOutOfCombat, conditions = "[combat]hide;show" },
	{ value = "TARGET", text = L.ShowWithTarget, conditions = "[@target,exists]show;hide" },
	{ value = "COMBAT_OR_TARGET", text = L.ShowInCombatOrWithTarget, conditions = "[combat][@target,exists]show;hide" },
	{ value = "NOMOUNT", text = L.ShowNotMounted, conditions = "[mounted]hide;show" }
}

local SHOW_PRESET_CUSTOM = { value = "CUSTOM", text = L.ShowCustom }

local function getShowPreset(bar)
	local conditions = bar:GetUserDisplayConditions() or ""

	for _, item in ipairs(SHOW_PRESET_ITEMS) do
		if item.conditions == conditions then
			return item
		end
	end

	return SHOW_PRESET_CUSTOM
end

local OPTIONS = {}

-- general
OPTIONS.columns = {
	type = 'slider',
	name = L.NumColumns,
	min = 1,
	max = 'NumButtons',
	get = 'NumColumns',
	set = 'SetColumns'
}

OPTIONS.spacing = {
	type = 'slider',
	name = L.Spacing,
	min = -16,
	max = 32,
	softLimits = true,
	get = 'GetSpacing',
	set = 'SetSpacing'
}

OPTIONS.scale = {
	type = 'slider',
	name = L.Scale,
	min = 50,
	max = 200,
	get = function(bar) return Round(bar:GetFrameScale() * 100) end,
	set = function(bar, value) bar:SetFrameScale(value / 100) end
}

OPTIONS.opacity = {
	type = 'slider',
	name = L.Opacity,
	get = function(bar) return Round(bar:GetFrameAlpha() * 100) end,
	set = function(bar, value) bar:SetFrameAlpha(value / 100) end
}

-- layout
OPTIONS.layoutDirection = {
	type = 'dropdown',
	name = L.LayoutDirection,
	items = LAYOUT_DIRECTION_ITEMS,
	get = function(bar)
		local leftToRight = bar:GetLeftToRight()
		local topToBottom = bar:GetTopToBottom()

		for _, item in ipairs(LAYOUT_DIRECTION_ITEMS) do
			if item.leftToRight == leftToRight and item.topToBottom == topToBottom then
				return item.value
			end
		end
	end,
	set = function(bar, value)
		for _, item in ipairs(LAYOUT_DIRECTION_ITEMS) do
			if item.value == value then
				bar:SetLeftToRight(item.leftToRight)
				bar:SetTopToBottom(item.topToBottom)
				return
			end
		end
	end
}

OPTIONS.rowOffset = {
	type = 'slider',
	name = L.RowOffset,
	min = function(bar) return -bar:GetRowOffsetLimit() end,
	max = 'GetRowOffsetLimit',
	softLimits = true,
	get = 'GetRowOffset',
	set = 'SetRowOffset'
}

OPTIONS.rowSpacing = {
	type = 'slider',
	name = L.RowSpacing,
	min = function(bar) return -bar:GetRowSpacingLimit() end,
	max = 'GetRowSpacingLimit',
	softLimits = true,
	get = 'GetRowSpacing',
	set = 'SetRowSpacing'
}

OPTIONS.padding = {
	type = 'slider',
	name = L.Padding,
	min = -16,
	max = 32,
	softLimits = true,
	get = 'GetPadding',
	set = 'SetPadding'
}

OPTIONS.frameStrata = {
	type = 'dropdown',
	name = L.FrameStrata,
	items = {
		{ value = "BACKGROUND", text = L["FrameStrata_BACKGROUND"] },
		{ value = "LOW", text = L["FrameStrata_LOW"] },
		{ value = "MEDIUM", text = L["FrameStrata_MEDIUM"] },
		{ value = "HIGH", text = L["FrameStrata_HIGH"] }
	},
	get = 'GetDisplayLayer',
	set = 'SetDisplayLayer'
}

OPTIONS.frameLevel = {
	type = 'slider',
	name = L.FrameLevel,
	min = 1,
	max = 200,
	get = function(bar) return bar:GetDisplayLevel() or 1 end,
	set = 'SetDisplayLevel'
}

-- visibility
OPTIONS.showPreset = {
	type = 'dropdown',
	name = L.Preset,
	-- custom isn't something to pick; it's listed only to describe conditions
	-- typed into the custom conditions box
	items = function(bar)
		if getShowPreset(bar) == SHOW_PRESET_CUSTOM then
			local items = { unpack(SHOW_PRESET_ITEMS) }
			tinsert(items, SHOW_PRESET_CUSTOM)
			return items
		end

		return SHOW_PRESET_ITEMS
	end,
	get = function(bar)
		return getShowPreset(bar).value
	end,
	set = function(bar, value)
		for _, item in ipairs(SHOW_PRESET_ITEMS) do
			if item.value == value then
				bar:SetUserDisplayConditions(item.conditions)
				return
			end
		end
	end
}

OPTIONS.showStates = {
	type = 'text',
	name = L.CustomConditions,
	tooltip = L.ShowStatesDescription,
	numLines = 3,
	-- a malformed conditional parses to nil. appending a catch-all clause means
	-- a well formed one always returns something, even if nothing matches
	validate = function(text)
		return text == '' or SecureCmdOptionParse(text .. ';_') ~= nil
	end,
	get = 'GetUserDisplayConditions',
	set = 'SetUserDisplayConditions'
}

OPTIONS.fadedOpacity = {
	type = 'slider',
	name = L.FadedOpacity,
	tooltip = L.FadedOpacityTooltip,
	get = function(bar) return Round(bar:GetFadeMultiplier() * 100) end,
	set = function(bar, value) bar:SetFadeMultiplier(value / 100) end
}

OPTIONS.fadeInDelay = {
	type = 'slider',
	name = L.FadeInDelay,
	min = 0,
	max = 10,
	step = 0.1,
	get = 'GetFadeInDelay',
	set = 'SetFadeInDelay'
}

OPTIONS.fadeInTime = {
	type = 'slider',
	name = L.FadeInTime,
	min = 0.1,
	max = 10,
	step = 0.1,
	get = 'GetFadeInDuration',
	set = 'SetFadeInDuration'
}

OPTIONS.fadeOutDelay = {
	type = 'slider',
	name = L.FadeOutDelay,
	min = 0,
	max = 10,
	step = 0.1,
	get = 'GetFadeOutDelay',
	set = 'SetFadeOutDelay'
}

OPTIONS.fadeOutTime = {
	type = 'slider',
	name = L.FadeOutTime,
	min = 0.1,
	max = 10,
	step = 0.1,
	get = 'GetFadeOutDuration',
	set = 'SetFadeOutDuration'
}

OPTIONS.clickThrough = {
	type = 'check',
	name = L.ClickThrough,
	get = 'GetClickThrough',
	set = 'SetClickThrough'
}

OPTIONS.showInOverrideUI = {
	type = 'check',
	name = L.ShowInOverrideUI,
	get = 'ShowingInOverrideUI',
	set = 'ShowInOverrideUI'
}

OPTIONS.showInPetBattleUI = {
	type = 'check',
	name = L.ShowInPetBattleUI,
	get = 'ShowingInPetBattleUI',
	set = 'ShowInPetBattleUI'
}

Addon.OptionDefs = OPTIONS

--[[ shared option groups ]]--

-- the options people change most often. basic frames (ones that aren't a grid
-- of buttons) only get padding, scale and opacity
--- @param flags { basic: boolean? }?
function PanelMixin:AddGeneralOptions(flags)
	if not (flags and flags.basic) then
		self:AddOptions{ OPTIONS.columns, OPTIONS.spacing, OPTIONS.padding, OPTIONS.scale, OPTIONS.opacity }
	else
		self:AddOptions{ OPTIONS.padding, OPTIONS.scale, OPTIONS.opacity }
	end
end

-- fine tuning of the frame's layout
function PanelMixin:AddLayoutOptions()
	self:AddOptions{ OPTIONS.layoutDirection, OPTIONS.rowOffset, OPTIONS.rowSpacing }
end

function PanelMixin:AddVisibilityOptions()
	self:AddOptions{
		{ type = 'header', name = L.MouseoverFading },
		OPTIONS.fadedOpacity,
		OPTIONS.fadeInDelay,
		OPTIONS.fadeInTime,
		OPTIONS.fadeOutDelay,
		OPTIONS.fadeOutTime,

		{ type = 'header', name = L.ShowStates },
		OPTIONS.showPreset,
		OPTIONS.showStates
	}
end

-- options most people won't need to touch. basic frames (ones that aren't a
-- grid of buttons) have no click through or layout settings. frames that always
-- show with the override and pet battle UIs can skip those settings
--- @param flags { basic: boolean?, alwaysShowInSpecialUI: boolean? }?
function PanelMixin:AddAdvancedOptions(flags)
	flags = flags or {}

	local basic = flags.basic
	local alwaysShowInSpecialUI = flags.alwaysShowInSpecialUI
	local behavior = {}

	if not basic then
		tinsert(behavior, OPTIONS.clickThrough)
	end

	if not alwaysShowInSpecialUI and ParentAddon:IsGameType("standard", "mists", "forever") then
		tinsert(behavior, OPTIONS.showInOverrideUI)

		if not ParentAddon:IsGameType("forever") then
			tinsert(behavior, OPTIONS.showInPetBattleUI)
		end
	end

	if #behavior > 0 then
		self:NewHeader(L.Behavior)
		self:AddOptions(behavior)
	end

	-- basic frames aren't a grid of buttons, so have no layout options here
	if not basic then
		self:NewHeader(L.Layout)
		self:AddLayoutOptions()
	end

	self:NewHeader(L.DrawOrder)
	self:AddOptions{ OPTIONS.frameStrata, OPTIONS.frameLevel }
end

function Addon:CreatePanel(parent)
	local panel = CreateFrame('Frame', nil, parent, 'VerticalLayoutFrame')

	Mixin(panel, PanelMixin)

	panel.spacing = 8
	panel.widgets = {}

	return panel
end

Addon.Panel = PanelMixin
