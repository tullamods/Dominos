-------------------------------------------------------------------------------
-- Dominos Config Localization
-- English (Default)
-------------------------------------------------------------------------------

local L = LibStub("AceLocale-3.0"):NewLocale("Dominos-Config", "enUS", true)

-- general options
L.ActionBarBehavior = "Action Bar Behavior"
L.ActionBarNumber = _G.HUD_EDIT_MODE_ACTION_BAR_LABEL
L.ActionBarSize = "Action Bar Size"
L.ActionBarSizeCustom = "Custom (%dx%d)"
L.ActionBarSizeDesc = "Changes your action bar layout"
L.ActionBarSizeValue = "%dx%d"
L.ActionButtonLookAndFeel = "Action Button Look & Feel"
L.EnterBindingMode = "Bind Keys..."
L.EnterConfigMode = "Configure Bars..."
L.LinkedOpacity = "Docked bars inherit opacity"
L.ManageActions = "Manage Actions..."
L.OutOfCombat = "Out of Combat"
L.PossessBar = "Override Bar"
L.PossessBarDesc = "What action bar to display special actions on when possessing an enemy and in certain encounters"
L.RCUFocus = _G.FOCUS
L.RCUPlayer = "Self"
L.RCUToT = "Target of Target"
L.RightClickUnit = "Right Click Target"
L.ShowBindingText = "Show Binding Text"
L.ShowCountText = "Show Count Text"
L.ShowEmptyButtons = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_ALWAYS_SHOW_BUTTONS
L.ShowEquippedItemBorders = "Show Equipped Item Borders"
L.ShowMacroText = "Show Macro Text"
L.ShowMinimapButton = "Show Minimap Button"
L.ShowOverrideUI = "Use Blizzard Override Action Bar"
L.ShowOverrideUIDesc = "Display the Blizzard override UI when piloting a vehicle, and other situations"
L.ShowSpellAnimations = "Show Spell Animations"
L.ShowSpellGlows = "Show Spell Overlay Glows"
L.ShowTooltips = "Show Tooltips"
L.StickyBars = "Sticky Bars"
L.ThemeActionButtons = "Theme Action Buttons (Requires Reload)"
L.ThemeActionButtonsDesc = "Applies some custom style adjustments to action buttons when enabled, and leave them untouched when not"

-- action button coloring
L.Color = COLOR
L.Colors = _G.COLORS

-- profiles
L.CopyProfile = "Copy Profile..."
L.Profiles = "Profiles"
L.ResetProfile = "Reset Profile..."
L.Set = "Set"

-- bar menus
L.Advanced = _G.ADVANCED_LABEL
L.Appearance = _G.APPEARANCE_LABEL
L.Bar = "Bar %d"
L.Behavior = "Behavior"
L.ClickThrough = "Enable Click Through"
L.Content = "Content"
L.DrawOrder = "Draw Order"
L.Enable = ENABLE
L.FadedOpacity = "Faded Opacity"
L.FadedOpacityTooltip = "Opacity when the mouse isn't over the bar, as a percentage of its normal opacity. Show conditions with an opacity value take priority."
L.FadeInDelay = "Fade In Delay (s)"
L.FadeInTime = "Fade In Time (s)"
L.FadeOutDelay = "Fade Out Delay (s)"
L.FadeOutTime = "Fade Out Time (s)"
L.Font = "Font"
L.FrameLevel = "Frame Level"
L.FrameStrata = "Frame Strata"
L.FrameStrata_BACKGROUND = BACKGROUND
L.FrameStrata_HIGH = HIGH
L.FrameStrata_LOW = LOW
L.FrameStrata_MEDIUM = "Medium"
L.General = _G.GENERAL
L.Height = "Height"
L.Layout = "Layout"
L.LayoutDirection = _G.HUD_EDIT_MODE_SETTING_MICRO_MENU_ORDER or "Order"
L.LayoutLeftDown = "Top Right"
L.LayoutLeftUp = "Bottom Right"
L.LayoutRightDown = "Top Left"
L.LayoutRightUp = "Bottom Left"
L.MouseoverFading = "Mouseover Fading"
L.NumButtons = "# of Buttons"
L.NumColumns = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_NUM_COLUMNS
L.Opacity = _G.OPACITY
L.Padding = "Padding"
L.Preset = "Preset"
L.RowOffset = "Row Offset"
L.RowSpacing = "Row Spacing"
L.Scale = "Scale"
L.Spacing = "Spacing"
L.Style = "Style"
L.Texture = "Texture"
L.Visibility = "Visibility"
L.Width = "Width"

-- bar specific
L.BagBarShowBags = "Show Bag Slots"
L.BagBarShowKeyRing = "Show Keyring"
L.ExtraBarShowBlizzardTexture = "Show Blizzard Texture"
L.ShowInOverrideUI = "Show With Override UI"
L.ShowInPetBattleUI = "Show With Pet Battle UI"

-- show states
L.CustomConditions = "Macro Conditionals"
L.ShowAlways = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_ALWAYS
L.ShowCustom = _G.CUSTOM
L.ShowInCombat = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
L.ShowInCombatOrWithTarget = "In Combat or With Target"
L.ShowNever = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_HIDDEN
L.ShowNotMounted = "When Not Mounted"
L.ShowOutOfCombat = _G.HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_OUT_OF_COMBAT
L.ShowStates = "Show States"
L.ShowStatesDescription = "Enter a macro conditional that results in show, hide, or an opacity value from 0 to 100. For example: [combat]100;50"
L.ShowWithTarget = "With Target"

-- paging
L.BarInState = "%s in %s"
L.BarState = "%s: %s"
L.Modifiers = "Modifiers"
L.Paging = "Paging"
L.PagingClear = "Clear"
L.PagingUnavailable = "%s (unavailable)"
L.PagingUnset = "Unset"
L.QuickPaging = "Quick Paging"
L.Targeting = "Targeting"

-- action book
L.ActionBook = "Action Book"
L.ShowWithSpellbook = "Show with Spellbook"

-- paging states
L.State_DRAGONRIDING = _G.GENERIC_TRAIT_FRAME_DRAGONRIDING_TITLE
L.State_HARM = "Harm"
L.State_HELP = "Help"
L.State_NOTARGET = "No Target"
L.State_SHIELD = "Shield Equipped"

-- derived translations
L.State_ALTSHIFT = strjoin("-", ALT_KEY_TEXT, SHIFT_KEY_TEXT)
L.State_CTRLALT = strjoin("-", CTRL_KEY_TEXT, ALT_KEY_TEXT)
L.State_CTRLALTSHIFT = strjoin("-", CTRL_KEY_TEXT, ALT_KEY_TEXT, SHIFT_KEY_TEXT)
L.State_CTRLSHIFT = strjoin("-", CTRL_KEY_TEXT, SHIFT_KEY_TEXT)
L.State_META = IsMacClient() and 'CMD Key' or 'Meta Key'
