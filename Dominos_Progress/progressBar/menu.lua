local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local ProgressBar = Addon.ProgressBar

--------------------------------------------------------------------------------
-- Context menu
--------------------------------------------------------------------------------

local function choices(prefix, ...)
	local items = {}
	for i = 1, select('#', ...) do
		local value = select(i, ...)
		items[i] = { value = value, text = prefix .. value }
	end
	return items
end

ProgressBar.contextMenu = Dominos.Frame.contextMenu:Extend {
	{
		insert = 'General',
		at = 'start',
		controls = {
			{
				type = 'dropdownWithCheck',
				name = 'ShowText',
				locale = 'Dominos-Progress',
				items = choices('TextVisibility_', 'always', 'mouseover'),
				get = 'GetTextVisibility',
				set = 'SetTextVisibility',
				check = { get = 'ShowingText', set = 'SetShowText' }
			},
			{
				type = 'dropdown',
				name = 'TextFormat',
				locale = 'Dominos-Progress',
				items = choices('TextFormat_', unpack(Addon.textFormats)),
				get = 'GetTextFormat',
				set = 'SetTextFormat'
			},
			'WidthSlider',
			'HeightSlider',
			{
				type = 'slider',
				name = 'SegmentCount',
				locale = 'Dominos-Progress',
				min = 1,
				max = 100,
				get = 'GetSegmentCount',
				set = 'SetSegmentCount'
            },
			{
				type = 'slider',
				name = 'Spacing',
				min = 1,
				max = 32,
				get = 'GetDividerWidth',
				set = 'SetDividerWidth'
			}
		}
	},
	{
		insert = 'Advanced',
		after = 'BehaviorHeader',
		controls = {
			{
				type = 'check',
				name = 'AutoSwitchModes',
				locale = 'Dominos-Progress',
				available = 'HasMultipleModes',
				get = 'SwitchesModesAutomatically',
				set = 'SetAutoSwitchModes'
			},
			{
				type = 'check',
				name = 'AutoHide',
				tooltip = 'AutoHideTip',
				locale = 'Dominos-Progress',
				get = 'UsesAutoHide',
				set = 'SetAutoHide'
			}
		}
	},
	{
		addPanel = 'Appearance',
		after = 'General',
		locale = 'Dominos-Progress',
		controls = {
			{ type = 'header', name = 'Style' },
			{
				type = 'check',
				name = 'Display_border',
				available = 'HasBorderArt',
				get = 'ShowingBorder',
				set = 'SetShowBorder'
			},
			-- the default entry is the stock look
			{
				type = 'texture',
				name = 'Texture',
				default = DEFAULT,
				get = 'GetTextureID',
				set = 'SetTextureID'
			},
			'FontDropdown',
			'FontOutlineDropdown',
			'FontSizeSlider',
			{ type = 'header', name = 'Content' },
			{
				type = 'check',
				name = 'AbbreviateNumbers',
				get = 'AbbreviatesNumbers',
				set = 'SetAbbreviateNumbers'
			},
			{
				type = 'check',
				name = 'ShowLabel',
				get = 'ShowingLabel',
				set = 'SetShowLabel'
			},
			{
				type = 'check',
				name = 'ShowBonus',
				get = 'ShowingBonus',
				set = 'SetShowBonus'
			},
			{
				type = 'check',
				name = 'ShowTooltip',
				get = 'ShowingTooltip',
				set = 'SetShowTooltip'
			},
		}
	}
}
