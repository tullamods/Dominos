--[[
	Localization.lua
		Translations for Dominos

	English: Default language
--]]

local AddonName = ...
local L = LibStub('AceLocale-3.0'):NewLocale(AddonName, 'enUS', true)

L.ActionBarDisplayName = HUD_EDIT_MODE_ACTION_BAR_LABEL
-- fully saying "Dominos Action Bar %d Button %d" gets cut off in the default
-- bindings editor
L.ActionBarButtonDisplayName = AddonName .. " Bar %d Button %d"
L.AlertsBarDisplayName = "Alerts"
L.AvailableProfiles = 'Available Profiles'
L.BagBarDisplayName = HUD_EDIT_MODE_BAGS_LABEL
L.BarDisplayName = "%s Bar"
L.BindingEnterTip = 'Shift-Left Click to enter binding mode'
L.BindingExitTip = 'Shift-Left Click to exit binding mode'
L.CantDeleteCurrentProfile = 'Cannot delete the current profile'
L.ClassBarDisplayName = HUD_EDIT_MODE_STANCE_BAR_LABEL
L.ConfigDesc = 'Toggles configuration mode'
L.ConfigEnterTip = 'Left Click to enter configuration mode'
L.ConfigExitTip = 'Left Click to exit configuration mode'
L.ConfigMode = 'Configuration Mode'
L.ConfigModeExit = 'Exit Config Mode'
L.ConfigModeHelp = 'Drag any bar to move it. Right Click to configure. Middle Click or Shift-Right Click to toggle visibility.'
L.CopyDesc = 'Copies settings from <profile>'
L.DeleteDesc = 'Deletes <profile>'
L.EncounterBarDisplayName = HUD_EDIT_MODE_ENCOUNTER_BAR_LABEL
L.ExtraBarDescription = "Displays zone and encounter specific abilities"
L.ExtraBarDisplayName = HUD_EDIT_MODE_EXTRA_ABILITIES_LABEL
L.Hidden = "Hidden"
L.HideBar = 'Middle Click or Shift-Right Click to hide'
L.HideFramesDesc = 'Hides the given <frameList>'
L.InvalidProfile = 'Invalid profile "%s"'
L.KeyboardMovementTip = "Use movement keys to adjust position."
L.ListDesc = 'Lists all profiles'
L.MenuBarDisplayName = HUD_EDIT_MODE_MICRO_MENU_LABEL
L.MouseMovementTip = 'Drag with the Left Button to move.'
L.NewPlayer = 'Created new profile for %s'
L.PetBarDisplayName = HUD_EDIT_MODE_PET_ACTION_BAR_LABEL
L.PossessBarDisplayName = HUD_EDIT_MODE_POSSESS_ACTION_BAR_LABEL
L.PrintVersionDesc = 'Prints the current version'
L.ProfileCopied = 'Copied settings from "%s"'
L.ProfileCreated = 'Created new profile "%s"'
L.ProfileDeleted = 'Deleted profile "%s"'
L.ProfileLoaded = 'Set profile to "%s"'
L.ProfileReset = 'Reset profile "%s"'
L.QueueStatusBarDisplayName = "Queue Status"
L.ResetDesc = 'Returns to default settings'
L.RollBarDisplayName = "Rolls"
L.SaveDesc = 'Saves current settings and switches to <profile>'
L.SetAlpha = 'Mousewheel to set opacity (|cffffffff%d|r)'
L.SetAlphaDesc = 'Sets the opacity of <frameList>'
L.SetColsDesc = 'Sets the number of columns for <frameList>'
L.SetDesc = 'Switches settings to <profile>'
L.SetFadeDesc = 'Sets the faded opacity of <frameList>'
L.SetPadDesc = 'Sets the padding level for <frameList>'
L.SetScaleDesc = 'Sets the scale of <frameList>'
L.SetSpacingDesc = 'Sets the spacing level for <frameList>'
L.AlignmentGridSize = "Grid Density"
L.AlignmentGridSizeTooltip = "How many grid lines are drawn across the screen. Higher values make a finer grid for bars to snap to."
L.ShowAlignmentGrid = HUD_EDIT_MODE_SHOW_GRID
L.ShowBar = 'Middle Click or Shift-Right Click to show'
L.ShowConfig = 'Right Click to configure'
L.ShowFramesDesc = 'Shows the given <frameList>'
L.Shown = "Shown"
L.ShowOptionsDesc = 'Shows the options menu'
L.ShowOptionsTip = 'Right Click to show the options menu'
L.TalkingHeadBarDisplayName = HUD_EDIT_MODE_TALKING_HEAD_FRAME_LABEL
L.TipRollBar = 'Displays frames for rolling on items when in a group.'
L.TipVehicleBar = [[Displays controls to aim and exit a vehicle.\nAll other vehicle actions are displayed on the possess bar.]]
L.ToggleFramesDesc = 'Toggles the given <frameList>'
L.TotemBarDisplayName = HUD_EDIT_MODE_TOTEM_ACTION_BAR_LABEL

-- action slot regions
L.ActionPagesRegion = 'Action Pages'
L.ActionPageRegion = 'Action Page %d'
L.BonusBarRegion = 'Bonus Bar %d'
L.SkyridingRegion = _G.GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE
L.TotemsRegion = 'Totems'
L.TotemSetRegion = 'Totems %d'
L.GamepadPageRegion = 'Gamepad Page %d'
L.GamepadModifiersRegion = '%s + %s'
L.GamepadDpadRegion = 'D-Pad'
L.GamepadFaceRegion = 'Button'
-- "Gamepad Page 1 - LT + Button"
L.GamepadRegionName = '%s - %s'
L.GamepadStanceBarsRegion = 'Gamepad Stance Bars'
L.GamepadStanceBarRegion = 'Gamepad Stance Bar %d'
L.UnusedRegion = 'Unused'
L.SlotName = 'Slot %d'
L.RegionSlotName = '%s Slot %d'
L.Updated = 'Updated to v%s'
L.ActionBarsDesc = 'Sets the number of action bars and buttons per bar, like 8x12 (up to 168 buttons in all)'
L.NumBarsDesc = 'Sets the number of action bars'
L.NumButtonsDesc = 'Sets the number of buttons per action bar'
L.NumBarsLimited = 'Set to %d bars, the most that fit with %d buttons per bar'
L.NumButtonsLimited = 'Set to %d buttons per bar, the most that fit with %d bars'
L.SavedVariablesNotMigrated = "Failed to update your settings, disabling for this session. Please report this error at %s"
L.SavedVariablesTooNew = "Your settings are from a newer version, disabling for this session. Please update to the latest version."
L.VehicleBarDisplayName = HUD_EDIT_MODE_VEHICLE_LEAVE_BUTTON_LABEL
L.WrongBuildWarning = "You're running a %s version for %s on a %s server. Things may not work"
