-- the options shared by bars' context menus, by name. definitions are tables
-- of widget settings; get, set, min, max and items are a method name on the
-- bar or a function of the bar

local _, Addon = ...
local L = Addon:GetLocale()

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
	{ value = "NOCOMBAT", text = L.ShowOutOfCombat, conditions = "[nocombat]show;hide" },
	{ value = "TARGET", text = L.ShowWithTarget, conditions = "[@target,exists]show;hide" },
	{ value = "COMBAT_OR_TARGET", text = L.ShowInCombatOrWithTarget, conditions = "[combat][@target,exists]show;hide" },
	{ value = "NOMOUNT", text = L.ShowNotMounted, conditions = "[nomounted]show;hide" }
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

local Controls = {}

-- general
Controls.ColumnsSlider = {
	type = 'slider',
	name = L.NumColumns,
	min = 1,
	max = 'NumButtons',
	get = 'NumColumns',
	set = 'SetColumns'
}

Controls.SpacingSlider = {
	type = 'slider',
	name = L.Spacing,
	min = -16,
	max = 32,
	softLimits = true,
	get = 'GetSpacing',
	set = 'SetSpacing'
}

Controls.ScaleSlider = {
	type = 'slider',
	name = L.Scale,
	min = 50,
	max = 200,
	get = function(bar) return Round(bar:GetFrameScale() * 100) end,
	set = function(bar, value) bar:SetFrameScale(value / 100) end
}

Controls.OpacitySlider = {
	type = 'slider',
	name = L.Opacity,
	get = function(bar) return Round(bar:GetFrameAlpha() * 100) end,
	set = function(bar, value) bar:SetFrameAlpha(value / 100) end
}

-- layout
Controls.LayoutDirectionDropdown = {
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

Controls.RowOffsetSlider = {
	type = 'slider',
	name = L.RowOffset,
	min = function(bar) return -bar:GetRowOffsetLimit() end,
	max = 'GetRowOffsetLimit',
	softLimits = true,
	get = 'GetRowOffset',
	set = 'SetRowOffset'
}

Controls.RowSpacingSlider = {
	type = 'slider',
	name = L.RowSpacing,
	min = function(bar) return -bar:GetRowSpacingLimit() end,
	max = 'GetRowSpacingLimit',
	softLimits = true,
	get = 'GetRowSpacing',
	set = 'SetRowSpacing'
}

Controls.PaddingSlider = {
	type = 'slider',
	name = L.Padding,
	min = -16,
	max = 32,
	softLimits = true,
	get = 'GetPadding',
	set = 'SetPadding'
}

Controls.FrameStrataDropdown = {
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

Controls.FrameLevelSlider = {
	type = 'slider',
	name = L.FrameLevel,
	min = 1,
	max = 200,
	get = function(bar) return bar:GetDisplayLevel() or 1 end,
	set = 'SetDisplayLevel'
}

-- size, for frames that set their own (not a grid of buttons)
Controls.WidthSlider = {
	type = 'slider',
	name = L.Width,
	min = 1,
	max = function(bar) return math.ceil(UIParent:GetWidth() / bar:GetScale()) end,
	get = 'GetDesiredWidth',
	set = 'SetDesiredWidth'
}

Controls.HeightSlider = {
	type = 'slider',
	name = L.Height,
	min = 1,
	max = function(bar) return math.ceil(UIParent:GetHeight() / bar:GetScale()) end,
	get = 'GetDesiredHeight',
	set = 'SetDesiredHeight'
}

-- visibility
Controls.ShowPresetDropdown = {
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

Controls.ShowStatesText = {
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

Controls.FadedOpacitySlider = {
	type = 'slider',
	name = L.FadedOpacity,
	tooltip = L.FadedOpacityTooltip,
	get = function(bar) return Round(bar:GetFadeMultiplier() * 100) end,
	set = function(bar, value) bar:SetFadeMultiplier(value / 100) end
}

Controls.FadeInDelaySlider = {
	type = 'slider',
	name = L.FadeInDelay,
	min = 0,
	max = 10,
	step = 0.1,
	get = 'GetFadeInDelay',
	set = 'SetFadeInDelay'
}

Controls.FadeInTimeSlider = {
	type = 'slider',
	name = L.FadeInTime,
	min = 0.1,
	max = 10,
	step = 0.1,
	get = 'GetFadeInDuration',
	set = 'SetFadeInDuration'
}

Controls.FadeOutDelaySlider = {
	type = 'slider',
	name = L.FadeOutDelay,
	min = 0,
	max = 10,
	step = 0.1,
	get = 'GetFadeOutDelay',
	set = 'SetFadeOutDelay'
}

Controls.FadeOutTimeSlider = {
	type = 'slider',
	name = L.FadeOutTime,
	min = 0.1,
	max = 10,
	step = 0.1,
	get = 'GetFadeOutDuration',
	set = 'SetFadeOutDuration'
}

Controls.ClickThroughCheck = {
	type = 'check',
	name = L.ClickThrough,
	available = 'CanClickThrough',
	get = 'GetClickThrough',
	set = 'SetClickThrough'
}

Controls.ShowInOverrideUICheck = {
	type = 'check',
	name = L.ShowInOverrideUI,
	available = 'CanShowInOverrideUI',
	get = 'ShowingInOverrideUI',
	set = 'ShowInOverrideUI'
}

Controls.ShowInPetBattleUICheck = {
	type = 'check',
	name = L.ShowInPetBattleUI,
	available = 'CanShowInPetBattleUI',
	get = 'ShowingInPetBattleUI',
	set = 'ShowInPetBattleUI'
}

Addon.Controls = Controls
