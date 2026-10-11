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

	local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	text:SetJustifyH('LEFT')
	text:SetPoint('TOPLEFT', 0, 1)
	text:SetText(name)
	text:SetHeight(text:GetStringHeight())

	frame:MarkDirty()

	addControl(self, frame)

	return frame
end

function PanelMixin:NewCheckButton(options)
	options.parent = self

	local button = Addon:CreateCheckButton(options)

	addControl(self, button)

	return button
end

function PanelMixin:NewSlider(options)
	options.parent = self

	local slider = Addon:CreateSlider(options)

	addControl(self, slider)

	return slider
end

function PanelMixin:NewLayerSlider(options)
	options.parent = self

	local slider = Addon:CreateSlider(options)

	addControl(self, slider)

	return slider
end

function PanelMixin:NewDropdown(options)
	options.parent = self

	local dropdown = Addon:CreateDropdown(options)

	addControl(self, dropdown)

	return dropdown
end

function PanelMixin:NewFontPicker(options)
	options.parent = self

	local dropdown = Addon:CreateFontPicker(options)

	addControl(self, dropdown)

	return dropdown
end

function PanelMixin:NewTextureSelector(options)
	options.parent = self

	local dropdown = Addon.Dropdown:New(options)

	addControl(self, dropdown)

	return dropdown
end

function PanelMixin:NewTextInput(options)
	options.parent = self

	local textInput = Addon:CreateTextInput(options)

	local prev = self.lastWidget
	if prev then
		textInput:SetPoint('TOPLEFT', self.lastWidget, 'BOTTOMLEFT', 0, -6)
	else
		textInput:SetPoint('TOPLEFT', 0, -6)
	end

	if options.width then
		textInput:SetWidth(options.width)
	else
		textInput:SetPoint('RIGHT')
	end

	textInput:SetHeight(options.height)

	addControl(self, textInput)

	return textInput
end

--[[ specialized widgets ]]--

function PanelMixin:NewScaleSlider()
	return self:NewSlider{
		name = L.Scale,
		min = 50,
		max = 200,

		get = function()
			return Round(self.owner:GetFrameScale() * 100)
		end,

		set = function(value)
			self.owner:SetFrameScale(value / 100)
		end
	}
end

function PanelMixin:NewOpacitySlider()
	return self:NewSlider{
		name = L.Opacity,

		get = function()
			return Round(self.owner:GetFrameAlpha() * 100)
		end,

		set = function(value)
			self.owner:SetFrameAlpha(value / 100)
		end
	}
end

function PanelMixin:NewFadeSlider()
	return self:NewSlider{
		name = L.FadedOpacity,

		get = function()
			return Round(self.owner:GetFadeMultiplier() * 100)
		end,

		set = function(value)
			self.owner:SetFadeMultiplier(value / 100)
		end
	}
end

function PanelMixin:NewPaddingSlider()
	return self:NewSlider{
		name = L.Padding,
		min = -16,
		max = 32,
		softLimits = true,

		get = function()
			return self.owner:GetPadding()
		end,

		set = function(value)
			self.owner:SetPadding(value)
		end
	}
end

function PanelMixin:NewSpacingSlider()
	return self:NewSlider{
		name = L.Spacing,
		min = -16,
		max = 32,
		softLimits = true,

		get = function()
			return self.owner:GetSpacing()
		end,

		set = function(value)
			self.owner:SetSpacing(value)
		end
	}
end

function PanelMixin:NewColumnsSlider()
	return self:NewSlider{
		name = L.Columns,

		min = 1,

		max = function()
			return self.owner:NumButtons()
		end,

		get = function()
			return self.owner:NumColumns()
		end,

		set = function(value)
			self.owner:SetColumns(value)
		end
	}
end

function PanelMixin:NewRowOffsetSlider()
	return self:NewSlider{
		name = L.RowOffset,

		min = function()
			return -(Round(ActionButton1:GetWidth()) + self.owner:GetSpacing())
		end,

		max = function()
			return Round(ActionButton1:GetWidth()) + self.owner:GetSpacing()
		end,

		softLimits = true,

		get = function()
			return self.owner:GetRowOffset()
		end,

		set = function(value)
			self.owner:SetRowOffset(value)
		end
	}
end

function PanelMixin:NewRowSpacingSlider()
	return self:NewSlider{
		name = L.RowSpacing,

		min = function()
			return -(Round(ActionButton1:GetHeight()) + self.owner:GetSpacing())
		end,

		max = function()
			return Round(ActionButton1:GetHeight()) + self.owner:GetSpacing()
		end,

		softLimits = true,

		get = function()
			return self.owner:GetRowSpacing()
		end,

		set = function(value)
			self.owner:SetRowSpacing(value)
		end
	}
end

local DISPLAY_LAYER_OPTIONS = {
	{ value = "BACKGROUND", text = L["FrameStrata_BACKGROUND"] },
	{ value = "LOW", text = L["FrameStrata_LOW"] },
	{ value = "MEDIUM", text = L["FrameStrata_MEDIUM"] },
	{ value = "HIGH", text = L["FrameStrata_HIGH"] }
}

function PanelMixin:NewDisplayLayerSlider()
	return self:NewDropdown{
		name = L.FrameStrata,
		items = DISPLAY_LAYER_OPTIONS,
		get = function()
			if self.owner then
				return self.owner:GetDisplayLayer()
			end
		end,
		set = function(value) self.owner:SetDisplayLayer(value) end
	}
end

function PanelMixin:NewDisplayLevelSlider()
	return self:NewSlider{
		name = L.FrameLevel,
		min = 1,
		max = 200,
		get = function() return self.owner:GetDisplayLevel() or 1 end,
		set = function(value) self.owner:SetDisplayLevel(value) end
	}
end

function PanelMixin:NewLeftToRightCheckbox()
	return self:NewCheckButton{
		name = L.LeftToRight,
		get = function() return self.owner:GetLeftToRight() end,
		set = function(_, enable) self.owner:SetLeftToRight(enable) end
	}
end

function PanelMixin:NewTopToBottomCheckbox()
	return self:NewCheckButton{
		name = L.TopToBottom,
		get = function() return self.owner:GetTopToBottom() end,
		set = function(_, enable) self.owner:SetTopToBottom(enable) end
	}
end

function PanelMixin:NewClickThroughCheckbox()
	return self:NewCheckButton{
		name = L.ClickThrough,
		get = function() return self.owner:GetClickThrough() end,
		set = function(_, enable) self.owner:SetClickThrough(enable) end
	}
end

function PanelMixin:NewShowInOverrideUICheckbox()
	return self:NewCheckButton{
		name = L.ShowInOverrideUI,
		get = function() return self.owner:ShowingInOverrideUI() end,
		set = function(_, enable) self.owner:ShowInOverrideUI(enable) end
	}
end

function PanelMixin:NewShowInPetBattleUICheckbox()
	return self:NewCheckButton{
		name = L.ShowInPetBattleUI,
		get = function() return self.owner:ShowingInPetBattleUI() end,
		set = function(_, enable) self.owner:ShowInPetBattleUI(enable) end
	}
end

function PanelMixin:NewFadeDelaySlider(smoothType)
    return self:NewSlider{
		name = L.Delay,

		min = 0,

		max = 10,

		step = 0.1,

		format = "%.1f",

        get = smoothType == "IN"
			and function() return self.owner:GetFadeInDelay() end
			or function() return self.owner:GetFadeOutDelay() end,

        set = smoothType == "IN"
			and function(_, value) self.owner:SetFadeInDelay(value) end
            or function(_, value) self.owner:SetFadeOutDelay(value) end,
    }
end

function PanelMixin:NewFadeDurationSlider(smoothType)
    return self:NewSlider{
        name = L.Duration,

		min = 0.1,

		max = 10,

		step = 0.1,

		format = "%.1f",

        get = smoothType == "IN"
			and function() return self.owner:GetFadeInDuration() end
			or function() return self.owner:GetFadeOutDuration() end,

        set = smoothType == "IN"
			and function(_, value) self.owner:SetFadeInDuration(value) end
			or function(_, value) self.owner:SetFadeOutDuration(value) end,
    }
end

function PanelMixin:AddLayoutOptions()
	self.colsSlider = self:NewColumnsSlider()
	self.spacingSlider = self:NewSpacingSlider()
	self.rowOffsetSlider = self:NewRowOffsetSlider()
	self.rowSpacingSlider = self:NewRowSpacingSlider()
	self:AddBasicLayoutOptions()
end

function PanelMixin:AddBasicLayoutOptions()
	self.paddingSlider = self:NewPaddingSlider()
	self.scaleSlider = self:NewScaleSlider()
	self.displayLayerSlider = self:NewDisplayLayerSlider()
	self.displayLevelSlider = self:NewDisplayLevelSlider()
end

function PanelMixin:AddAdvancedOptions(displayConditionsOnly)
	if not displayConditionsOnly then
		self:NewLeftToRightCheckbox()
		self:NewTopToBottomCheckbox()
		self:NewClickThroughCheckbox()
	end

	if ParentAddon:IsGameType("standard", "mists") then
		self:NewShowInOverrideUICheckbox()
		self:NewShowInPetBattleUICheckbox()
	end

	self.showStatesEditBox = self:NewTextInput{
		name = L.ShowStates,
		multiline = true,
		width = 268,
		height = 64,
		get = function() return self.owner:GetUserDisplayConditions() end,
		set = function(value) self.owner:SetUserDisplayConditions(value) end
	}
end

function PanelMixin:AddFadingOptions()
	self:NewHeader(L.FadeIn)
	self:NewOpacitySlider()
	self:NewFadeDelaySlider("IN")
	self:NewFadeDurationSlider("IN")

    self:NewHeader(L.FadeOut)
    self:NewFadeSlider()
	self:NewFadeDelaySlider("OUT")
	self:NewFadeDurationSlider("OUT")
end

function Addon:CreatePanel(parent)
	local panel = CreateFrame('Frame', nil, parent, 'VerticalLayoutFrame')

	Mixin(panel, PanelMixin)

	panel.spacing = 8
	panel.widgets = {}

	return panel
end

Addon.Panel = PanelMixin
