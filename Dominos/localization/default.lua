--[[
	Localization.lua
		Translations for Dominos

	English: Default language
--]]

local AddonName = ...
local L = LibStub('AceLocale-3.0'):NewLocale(AddonName, 'enUS', true)

-- bars
-- fully saying "Dominos Action Bar %d Button %d" gets cut off in the default
-- bindings editor
L.ActionBarButtonDisplayName = AddonName .. " Bar %d Button %d"
L.ActionBarDisplayName = HUD_EDIT_MODE_ACTION_BAR_LABEL
L.AlertsBarDisplayName = "Alerts"
L.BagBarDisplayName = HUD_EDIT_MODE_BAGS_LABEL
L.BarButton = '%s Button %d'
L.BarDisplayName = "%s Bar"
L.ClassBarDisplayName = HUD_EDIT_MODE_STANCE_BAR_LABEL
L.EncounterBarDisplayName = HUD_EDIT_MODE_ENCOUNTER_BAR_LABEL
L.ExtraBarDisplayName = HUD_EDIT_MODE_EXTRA_ABILITIES_LABEL
L.MenuBarDisplayName = HUD_EDIT_MODE_MICRO_MENU_LABEL
L.PetBarDisplayName = HUD_EDIT_MODE_PET_ACTION_BAR_LABEL
L.PossessBarDisplayName = HUD_EDIT_MODE_POSSESS_ACTION_BAR_LABEL
L.QueueStatusBarDisplayName = "Queue Status"
L.RollBarDisplayName = "Rolls"
L.TalkingHeadBarDisplayName = HUD_EDIT_MODE_TALKING_HEAD_FRAME_LABEL
L.TipRollBar = 'Displays frames for rolling on items when in a group.'
L.TotemBarDisplayName = HUD_EDIT_MODE_TOTEM_ACTION_BAR_LABEL

-- config and binding modes
L.AlignmentGridSize = "Grid Density"
L.AlignmentGridSizeTooltip = "How many grid lines are drawn across the screen. Higher values make a finer grid for bars to snap to."
L.BindingEnterTip = 'Shift-Left Click to enter binding mode'
L.BindingExitTip = 'Shift-Left Click to exit binding mode'
L.ConfigEnterTip = 'Left Click to enter configuration mode'
L.ConfigExitTip = 'Left Click to exit configuration mode'
L.ConfigMode = 'Configuration Mode'
L.ConfigModeHelp = 'Drag any bar to move it. Right Click to configure. Middle Click or Shift-Right Click to toggle visibility.'
L.Hidden = "Hidden"
L.HideBar = 'Middle Click or Shift-Right Click to hide'
L.KeyboardMovementTip = "Use movement keys to adjust position."
L.SetAlpha = 'Mousewheel to set opacity (|cffffffff%d|r)'
L.ShowAlignmentGrid = HUD_EDIT_MODE_SHOW_GRID
L.ShowBar = 'Middle Click or Shift-Right Click to show'
L.ShowConfig = 'Right Click to configure'
L.Shown = "Shown"
L.ShowOptionsTip = 'Right Click to show the options menu'

-- slash commands
L.ActionBarsDesc = 'Sets the number of action bars and buttons per bar, like 8x12 (up to 168 buttons in all)'
L.ActionsDesc = 'Opens the action book'
L.ConfigDesc = 'Toggles configuration mode'
L.CopyDesc = 'Copies settings from <profile>'
L.DeleteDesc = 'Deletes <profile>'
L.HideFramesDesc = 'Hides the given <frameList>'
L.ListDesc = 'Lists all profiles'
L.NumBarsLimited = 'Set to %d bars, the most that fit with %d buttons per bar'
L.PrintVersionDesc = 'Prints the current version'
L.ResetDesc = 'Returns to default settings'
L.SaveDesc = 'Saves current settings and switches to <profile>'
L.SetAlphaDesc = 'Sets the opacity of <frameList>'
L.SetColsDesc = 'Sets the number of columns for <frameList>'
L.SetDesc = 'Switches settings to <profile>'
L.SetFadeDesc = 'Sets the faded opacity of <frameList>'
L.SetPadDesc = 'Sets the padding level for <frameList>'
L.SetScaleDesc = 'Sets the scale of <frameList>'
L.SetSpacingDesc = 'Sets the spacing level for <frameList>'
L.ShowFramesDesc = 'Shows the given <frameList>'
L.ToggleFramesDesc = 'Toggles the given <frameList>'

-- profiles
L.AvailableProfiles = 'Available Profiles'
L.CantDeleteCurrentProfile = 'Cannot delete the current profile'
L.InvalidProfile = 'Invalid profile "%s"'
L.ProfileCopied = 'Copied settings from "%s"'
L.ProfileCreated = 'Created new profile "%s"'
L.ProfileDeleted = 'Deleted profile "%s"'
L.ProfileLoaded = 'Set profile to "%s"'
L.ProfileReset = 'Reset profile "%s"'

-- updates and warnings
L.ActionBarsMigrated = "Action bars now follow Blizzard's ordering. Check your bars and move any actions or keybinds that ended up in the wrong place."
L.SavedVariablesNotMigrated = "Failed to update your settings, disabling for this session. Please report this error at %s"
L.SavedVariablesTooNew = "Your settings are from a newer version, disabling for this session. Please update to the latest version."
L.Updated = 'Updated to v%s'

-- action slot regions
L.ActionPageRegion = 'Action Page %d'
L.ActionPagesRegion = 'Action Pages'
L.BonusBarRegion = 'Bonus Bar %d'
L.GamepadBarKeys = '%s - %s'
L.GamepadDpadRegion = 'D-Pad'
L.GamepadFaceRegion = 'Button'
L.GamepadModifiersRegion = '%s + %s'
L.GamepadPageRegion = 'Gamepad Page %d'
L.GamepadStanceBarRegion = 'Gamepad Stance Bar %d'
L.GamepadStanceBarsRegion = 'Gamepad Stance Bars'
L.RegionSlotName = '%s Slot %d'
L.SkyridingRegion = _G.GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE
L.SlotName = 'Slot %d'
L.TotemSetRegion = 'Totems %d'
L.TotemsRegion = 'Totems'
L.UnusedRegion = 'Unused'
