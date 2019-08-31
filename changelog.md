8.2.15
* Automated release

8.2.14
* Hide the bag buttons a bit better in one bag mode
* Add latency to the minimap button tooltip when running on classic realms

8.2.13
* Made progress bar modes a per character setting
* Update libraries

8.2.12
* Fix latency frame still appearing in classic

8.2.11
* Fixed menu bar ordering issues
* You can now type in values beyond the normal limits for the spacing and padding sliders. You can also increment beyond limits via holding a modifier key and using the mouse wheel on a slider
* The progress bar will only now switch between active modes on click

8.2.10
* Added a workaround to handle adding appropriate spacing to container frames/quest log when both right bars are checked and not set to be stacked vertically in Blizzard's option menu.

8.2.9
* Rewrote the code for hiding the various bits of Blizzard's UI to handle both the changes in 8.2 around restricted frames and the differences between classic and retail.

8.2.8
* Apply a quick fix for the save bindings error
* Fix an error upon load for the multiactionbars

8.2.7
* WoW 8.2 Release
* Fix some druid forms and shadow form for classic

8.2.6
* Fix shadowdance check

8.2.5
* Fix a typo in the addon TOC * Hide addon options that are not relevant to classic

8.2.4
* Fix a redbox error on exiting combat

8.2.3
* Fix multiactionbar fixer error on classic

8.2.2-classic:
* Use Dominos:IsBuild("classic") for tests. * Add stance bar for paladins

8.2.1-classic:
* Allow exit vehicle button to load

8.2.0-classic:
* Initial release

8.1.3:
* Added a (hopefully) better fix for the multibar related issues

8.1.2:
* Update TOC version
* Added a workaround for some multibar related taint issues

8.1.1:
* Adds support for WoW 8.1
* Fixes issues with the profiles selector
* Now uses LibFlyPaper instead of FlyPaper

8.0.7:
* XP is now disabled when at max level
* Minor fixes

8.0.6:
* Reintroduce fix for Achievement frame errors.

8.0.5:
* Azerite bar fixes

8.0.4:
* Fix issues causing the cast bar to not work properly.

8.0.3:
* Work around an issue causing menus to sometimes not render properly.

8.0.2:
* Right click menus have been re-skinned a bit to look more Blizzard-like once again
* Fixed some issues causing the right click menus to not always render as expected (ScrollingFrames are weird)
* Fixed an issue causing action buttons to sometimes get stuck in a pushed state when using Masque
* Fixed an issue with bag bar borders when using Masque

8.0.1:
* Added support for the Azerite bar

8.0.0:
* Initial changes for compatibility with WoW 8.0

7.3.2
* Improve reputation display for factions at exalted levels.
* Make LibSharedMedia a core dependency to reduce redundancy

7.3.1
* Handle potential infinite loop on Artifact Bar

7.3.0
* Updated for WoW 7.3
* Fix paragon reputation display.

7.2.4
* Hopefully fix the null index issue.

7.2.3
* Added a basic paragon reputation display
* Added an option to show/hide equipped item borders
* Fixed an issue causing a duplicate cast bar to show up during certain quests/encounters
* Fixed an issue causing Masque skins to not display properly when switching profiles

7.2.2
* Corrected an issue that would cause the options menu to not always open to the general panel

7.2.1
* Updated TOC files for 7.2
* Updated artifact XP calculations to include the new tier parameter.

7.2.0
* Remove references to the HelpMenuMicroButton, as it no longer exists

7.1.4
* Fix for the roll/alert bar's righclick menu

7.1.3
* The roll bar module should now move the roll bar frames again.
* Added a second bar that should only move the alerts frame.

7.1.2
* Reverted to the old artifact bar color
* Added new progress bar color options to the main options menu (/dominos)
* Added an option to merge the xp and artifact bars together

7.1.1
* Updated for compatibility with WoW 7.1
* Adjusted the color of the artifact bar (thanks GrantSheehan)

7.0.21
* Add vehicle support to the castbar

7.0.20
* Add a missing default to use the Blizzard override bar

7.0.19
* Handle loading cast bar textures a bit better
* Implemented safe loading of Dominos modules to prevent your entire UI from going away when an old module fails to load
* Better handle switching artifact weapons for progress bar updates

7.0.18
* Add a bit of a glow effect to the cast bar
* Reposition the cast bar latency indicator to a static area
* Readjust defaults for the cast bar
* Add an option to display a border on the cas bar
* Fix an error when gaining honor xp

7.0.17
* Add a latency indicator to the cast bar
* Fix an issue that could cause the cast bar show up as interrupted when attempting and failing to cast another spell

7.0.16
* Add options for showing the icon and time on the cast bar

7.0.15
* First pass at a custom castbar

7.0.14
* Add back support for shadow dance (yay!)
* Minor bugfixes

7.0.13
* Fixed a null value error in Dominos_Progress
* Showstate opacity now always takes precedence over mouseover opacity

7.0.12
* Dominos_Progress: Change label of Lock Display Mode to Auto Switch Modes, and set it so that you can click to switch modes either way.
* Dominos_Progress: Add percentage and remaining as display options among others.
* Dominos_Roll: Readd ignoreFramePositionManager call in hopes that it'll fix the "roll frames like to move on their own issue"

7.0.11b
* Removed debug code from the roll bar

7.0.11
* Enabled Dominos_Roll by default again for wider testing.
* Changed the rest color on the XP bar blue again to make it easier to distinguish.
* Changed scale slider maximum range to 200%
* Updated zhTW localization (thanks class2u)
* Fixed an issue causing showstates to not properly turn off when clearing the edit box.
* Remove unnecessary GetChange call that was causing errors.
* Fix the textbox entry on sliders not liking negative numbers

7.0.10
* Disabled Dominos_Roll by default.
* Adjusted Dominos_Roll to move the alerts frame, which is what now manages the positioning of the roll frames, among other stuff. NEEDS TESTING.
* Fixed a localization bug with Dominos_Progress that was preventing all sections from showing up for French users
* Fixed a bug causing the artifact/xp bars to be clicked on even when hidden during pet battles/the override UI shown

7.0.9
* Adjusted the defaults for Dominos_Progress so that you can click the xp bar to switch modes by default
* Adjusted the defaults for Dominos_Progresss so that the artifact bar isn't on top of the XP bar
* Fixed an issue causing the reputation bar to not update.
* Fixed a bug causing menus to not reset properly after being closed.
* Fixed a bug causing modifier mousewheel cycling of overlay frames to not work (I bet I'm the only one who uses that :P)
* Fixed some ugliness when placing one configuration menu on top of another
* Fixed a null value comparison when reloading your UI while in a vehicle
* Show states now update as you type
* Clicking anywhere inside of the showstate editbox will now properly set focus on the editbox

7.0.8
* Added back a basic show states editor
* Minor bugfixes

7.0.7
* Updated for compatibility WoW 7.0 (Legion)
* Replaced Dominos_XP with Dominos_Progress, adding in a new bar for tracking
* Recoded/reorganized most of the UI menus. Sliders have text inputs now!
* Caveats: I've not implemented the showstate textbox (still need to do a bit more testing), and this version does not work on realms that aren't running the latest patch.

6.2.9
* Fixed a null value comparison during override bar detection
* Updated Korean localization (Thanks WetU)

6.2.8
* Prevent the micro menu bar from disappearing if you opened the map fullscreen while in combat.

6.2.7b
* Fixed a typo I somehow missed.

6.2.7
* Workaround to try to ensure the encounter bar works in combat.
* Fix out of date roll and xp bars.

6.2.6
* Added a fix for cooldown pulses showing up on bars that are completely transparent.

6.2.5
* Add flyout support to Dominos_ActionSets

6.2.4
* Yet another encounter bar bugfix (stupid typos)

6.2.3
* Encounter bar bugfix
* Fix missing print version command

6.2.2
* Encounter bar workaround.

6.2.1
* Added Dominos_ActionSets. This is a module attaches action button placements to your Dominos profile. So when you switch profiles, your action buttons can also switch. Dominos_ActionSets is disabled by default, so you need to enable from the addons menu.

6.2.0
* Fixed an issue where Dominos would apply a default skin to buttons regardless of if Masque was running
* Refactored the layout code for menu buttons.

6.1.9
* Fix padding issues with frame layouts.

6.1.8
* Moved Masque support into its own module.
* Fixed a bug causing flyout buttons to not properly update direction

6.1.7
* Fixed a typo menuBar.lua

6.1.6
* Resolved errors when opening the menus of the encounter and roll bars.

6.1.5
* The main bag button should be positioned properly again
* Resolved an issue causing the vehicle exit button to not work after being used once
* And yes, more bugfixes

6.1.4
* Resolved vehicle button display issues (hopefully!)

6.1.3
* Added ability to cycle through overlapped in config mode frames via modifier key + mousewheel (thanks Gorwanaws)
* Bugfixes

6.1.2
* Added support for cancelling flights.
* Lots of code reorganization (make sure you delete everything and restart WoW after installing)

6.1.1
* Added missing dungeon finder button.

6.1.0
* Updated for WoW 6.1
* Dominos will now properly skin buttons when Masque is disabled for a particular group (on /reloadui)

6.0.13
* Bugfix for an error that would occur when an actionbar had less buttons than normal.

6.0.12
* Updated Italian localization (thanks to Kuzunkhaa)

6.0.11
* Added Italian localization (thanks to Kuzunkhaa)

6.0.10
* Reorganized folder layout. Make sure that you delete all Dominos folders before installing the addon, and restart the game.
* Adjusted the configuration mode look and feel.
* Added the ability to nudge bars: In configuration mode, hover over a bars and press an arrow key

6.0.9
* Updated Shadow Dance paging state
* Fixed UNKNOWN_STATE display for some stance bars.

6.0.8
* Added new option, /dom configstatus : Shows if Dominos_Config is enabled or not.

6.0.7
* Added support for Stance of the Spirited Crane and Gladiator Stance

6.0.6b
* Implemented a workaround to hide cooldown spirals on transparent action bars.

6.0.5
* Removed Berserker stance settings, since it no longer exists.
* Reimplemented defaults for stance paging for Warriors

6.0.4
* Updated Ace libraries

6.0.3
* Resolved an issue causing the XP bar to not automatically hide when in pet battles/vehicles
* Fixed some issues causing the menu bar to not show up properly during pet battles/vehicles.
* Updated the TOC for 6.0.0

5.4.12
* Fixed an issue when tracking a reputation of a friendly faction, and already at max level (hopefully)

5.4.11
* Resolved an issue causing the Dominos override/vehicle bar to not display any icons for certain encounters (ex, Noodle Time, Naz'Jar Battlemaiden). Thanks to mlangen & Wetxius for insight and testing.

5.4.10
* Paging bugfix

5.4.9
* Added a fix for the faction reputation error.
* Setting opacity with the mousewheel now properly uses a bar's base opacity (thanks ckaotik).
* Implemented hopeful fixes to resolve override bar issues.

5.4.8
* Fixed combat lockdown errors introduced by 5.4.7.

5.4.7
* Reworked code used to hide Blizzard frames and reuse the MultiActionBarButtons, hopefully finally preventing the addon blocked errors.

5.4.6
* Fixed a regression that was causing the help button to not display again.

5.4.5
* "Resolved" addon blocked error in a way that hopefully allows you to switch talents

5.4.4
* Resolved taint errors related to the Blizzard store button.

5.4.3
* Added back the help button.

5.4.2
* Fixed a regression in keybinding code
* Fixed slider display issues

5.4.1
* Added a new option to disable Blizzard artwork on the extra action button (available from its right click menu).
* Fixed issues preventing the options menu from displaying properly/
* Fixed issues with friendship reputation display

5.4.0
* Updated for WoW 5.4.0
* Adjusted override bar controller to use the new [shapeshift] macro conditional. This should hopefully resolve issues with fights that use the temp shapeshift bar.
* Adjusted reputation bar to handle friendship reputation (thanks to b-morgan)
* Code cleanup

5.3.1
* Simplified surrogate binding code and limited it to only custom buttons (ex, DominosActionButtonXX)
* Lowered surrogate button binding priority.

5.3.0
* Updated the TOC for 5.3.0. You can still use Dominos 5.3.0 with WoW 5.2, but you'll need to check the Enable Out of Date AddOns checkbox in the addons menu on the character select screen.
* The Encounter Bar (PlayerPowerBarAlt) should now show up when using the Blizzard Override/Vehicle UI.
* The class/stance bar has been rewritten. It now reuses the standard stance buttons and bindings and should no longer produce an error if you happen to level up and gain a new stance/form while in combat.
* The extra bar has been rewritten to now display and use the standard bindings for the bar.
* Added shadow meld paging support for Night Elf characters.
* Adjusted hide blizzard code to hopefully reduce tainting issues.
* Implemented full "Cast on Key Down" support.

5.2.0:
* TOC bump for WoW 5.2.0
* Added Dominos_Encounter: A new module for moving around the PlayerPowerBarAlt that shows up in some encounters. Thanks to Goranaws for the original version.
* Adjusted layout code to hopefully prevent issues when changing screen resolution (ported from LibWindow)

5.1.1
* Rewrote override page calculations to take advantage of some new functions available to me in the restricted environment

5.1.0
* TOC bump for WoW 5.1.0

5.0.29
* Fixed flyout button positions (thanks StephenClouse)
* Added a hack to fix errors when hiding the achievement micro button
* Simplified menu bar positioning code when the override ui

5.0.28
* Fixed an error when attempting to disable a menu button that no longer exists

5.0.27
* Resolved issues with the display of the menu bar when the world map is shown and hidden.

5.0.26
* This version should fix the various ADDON_ACTION_BLOCKED calls from MainMenuBarMicroButtons.lua

5.0.25
* Replaced custom minimap button code with LibDBIcon-1.0

5.0.24
* Resolved issues with empty action buttons sometimes being shown.

5.0.23
* Fixed some tainting issues
* Fixed an issue causing Dominos to think that the vehicle bar was shown upon loading
* Added a bit more debug information to the /dom statedump command.

5.0.22
* Fixed some typos
* Added new slash command /dom statedump: Please tell me what you get from this when reporting vehicle state bugs

5.0.21
* Fixed an error that was caused by attempting to read main action bar page information in combat.

5.0.20
* Fixed an error when switching profiles
* Added a new hack: If you enter a vehicle or something where you should get a new action bar, but are not, tap any modifier key. Your bar should hopefully switch :)

5.0.19
* Fixed a bug where your bar would get stuck on vehicle/override actions after exiting a vehicle

5.0.18
* Fixed show states being broken.

5.0.17
* Reworked how the override bar works a bit again. Should hopefully handle the state of a vehicle without a vehicle ui.

5.0.16
* Resolved issues with the possess bar not showing actions

5.0.15
* Resolved issue with buttons not working after the override ui is hidden.

5.0.14
* Added new global option: Use Blizzard Override UI. When enabled, shows the Blizzard Override UI interface.
* Added new advanced bar options: Show with Override UI, Show with Pet Battle UI. These control what bars will show up when the override ui/pet battle ui are shown.

5.0.13
* Fixed a bug that was causing the pet action bar background to show up
* Fixed a bug that caused errors when switching profiles

5.0.12
* Fixed missing pet bar bug
* Simplified menu bar layout code for override bars

5.0.11
* Reworked override ui code to better handle cases where action bars should change, but the UI does not.
* Renamed Possess Bar option to Override Bar.

5.0.10
* Reworked the roll bar.

5.0.9b
* Accidentally reverted the paging conditional for Shadow Dance; this has now been resolved.

5.0.9
* Fixed up Tree of Life bar switching.
* Added the roll bar back (I have not tested it, though)
* Renamed the Shadow Dance slider to Shadow Dance/Vanish to reflect that it controls paging for both abilities.
* Minor UI cleanup.

5.0.8
* Added a dedicated bar for the vehicle exit button
* Fixed a bug causing the click through option to not work on the menu bar

5.0.7
* So it turns out that Show Lua Errors is disabled by default on the beta :P
* Entering/exiting a vehicle should now work properly in combat
* Shadow dance does exists, its vanish that I can't detect separately anymore :P
* Warlock metamorphosis should work properly again.

5.0.6
* Fixed an error when entering a vehicle

5.0.5
* Adjusted states for warrior stances so that they work again

5.0.4
* Fixed a bug that would occur when switching profiles

5.0.3
* Re-enabled the advanced layout options for the menu bar (including disabling buttons)
* Adjusted vehicle bar button placements based upon vehicle bar size

5.0.2
* Made Dominos hide itself when the pet battle interface is shown.
* Made Dominos hide itself when the vehicle interface is shown. Dropped the Dominos vehicle bar. NEEDS TESTING WITH A VARIETY OF VEHICLES.
* Updated the possess bar to use the new [possessbar] macro conditional.
* Updated the extra action bar to use the new [extractionbar] macro conditional.

5.0.1
* Fixed divide by zero issue on the XP bar.
* Re-registered the event UPDATE_EXTRA_ACTIONBAR on the Blizzard actionbar controller so that the extra action bar will show up again.

5.0.0
* Made the addon not explode when loading it in the beta (Thanks, Laotseu, hasteur, Simon)
* Added initial support for Monk stances.
* Dropped Dominos_Totems
* Dropped Dominos_Roll

4.3.4
* Fixed an issue with the extra action bar frame interfering with clicking objects near the bottom center of the screen.

4.3.3
* Trying another method of showing the extra action bar

4.3.2
* Reverted to the old extra action bar behavior (that hopefully works :P)

4.3.1
* Adjusted the extra action bar to work more like a normal bar. Using RothUI's events for showing/hiding it.

4.3.0
* Adjusted action bar code to work with 4.3 action button event registration changes.

4.2.6:
* Forced ExtraActionButton1 to be shown. Hoping that'll make it stay shown.

4.2.5:
* Fixed upgrade issues /w Bear form, I hope :P

4.2.4:
* Goranaws: Added option to disable various menu buttons (Thanks Gorwanews)
* Goranaws: Added support for Masque, dropped legacy ButtonFacade support.
* Tuller: Added support for the 4.3 extra action bar (NEEDS TESTING!)
* Tuller: Fixed a bug causing bear form to not have a default bar set
* Tuller: Added some upgrade code to supply a default bear form bar if one was missing.

4.2.3:
* FIxed some issues with paging offsets (hopefully :P)

4.2.2:
* Fixed an issue making click-through settings not work upon next login

4.2.1:
* Profile switching bugfixes related to the menu bar code changes.

4.2.0:
* Updated for WoW 4.2
* Added new option: Show Tooltips in Combat
* Added new advanced option: Enable Click Through
* Goranaws: Made it possible to hide buttons on the menu bar

4.1.apple1:
* Switched how I store state information internally to not be directly based off of macro states, so that I can account for things like users with/without Tree Form.
* Fixed a bug on Shamans when switching profiles (https://github.com/Tuller/Dominos/issues/53)

1.25.0
* Updated TOC for 4.1
* Removed Quick Move key option, since Blizzard added it to the Action Bars portion of their interface options menu.

1.24.1
* Taint fix

1.24.0
* Added some code to make flyouts work nicer in 4.0.6
* Updated Spanish localization (thanks xibeca)

1.23.9
* Made it possible to drag actions off/to the totem bar once again.

1.23.8
* Bugfix

1.23.7b
* Added back missing submodule

1.23.7
* Rewrote the hide blizzard function to work a bit more like the Bartender one. You can now once again control bag/quest log placement by checking the extra blizzard action bars.

1.23.6
* Added Spanish localization (thanks xibeca)
* Made the totem bars act a bit more like the standard Blizzard one: Right click a totem or call spell to bring up a list of totems/calls to select from. Left click to switch. You can also mouse-wheel a call button to switch pages.

1.22.0
* Fixed issues caused by my fix for Tree of Life :P

1.21.0
* Fixed issues with Tree of Life for Druids

1.20.4
* Added back % display for XP by default
* Fixed a bug causing empty buttons to not show up when binding keys

1.20.3
* Fixed a bug that was causing Rogues to lose their shadow dance bar setting when upgrading versions
* Made the xp/rep bar text a bit more customizable, if you're lua handy

1.20.2
* Added some tweaks to binding updates to reduce CPU usage. This may or may not break stuff :)

1.20.0
* Fixed Rogue Shadowdance detection. Added detection for Vanish.

1.19.9
* Tweaked FlyPaper to be able to be standalone
* Forced updating of state sliders

1.19.8
* Made linked fading disabled by default (again)
* Fixed auto fading with flyout buttons
* Updated libraries

1.19.7b
* Removed some debug code

1.19.7
* Brought the animation system for fading back, hopefully without the missing hotkeys this time :P

1.19.6
* Turns out, the animation system does wacky things to hotkeys :P

1.19.5
* Auto fading fixes/performance improvements

1.19.4
* Stopped reusing buttons for bar #2: Should hopefully fix the missing buttons issue :)
* Switched to using the animation system for auto fading stuff.

1.19.3
* Updated for WoW v4.0.1

1.18.6
* Fixed an error on load

1.18.5
* Updated localization

1.18.4
* Fixed some issues causing Dominos to not work with the Chinese client.

1.18.3
* Fixed some 3.3.5 related issues

1.18.2
* Fizzwidget FactionFriend compatibility update

1.18.1
* Fixed an error when attempting to keybind to the pet bar
* Fixed an error causing fade settings to not reset properly when switching profiles

1.18.0
* Added a new option, “Docked bars inherit opacity.” When enabled, when a bar is stuck to another bar, that bar begins to mimic the parent’s opacity level. If the parent bar happens to be a mouseover bar, then the mouseover range is extended to include the new bar

1.17.0
* Added the ability to specify an opacity, instead of simply just telling a bar to show or hide, to the showstate dialog. For example, setting a bar's showstate to [combat]100;show will force a bar to have 100% opacity (regardless of if the bar has mouseover fading enabled) in combat, and otherwise just show the bar with its normal opacity setting.

1.16.3
* Fixed a bug causing the experience bar texture to tile instead of stretch.

1.16.2
* Totem bar bugfix #2

1.16.1
* Totem bar bugfix

1.16.0
* The totem bar should now work on characters even if he or she has yet to learn a call spell.

1.15.3b
* Added missing libraries (again).

1.15.3
* Updated Chinese localization

1.15.2b
* Added missing libraries

1.15.2
* Fixed an error when switching profiles on Shaman characters

1.15.1
* Updated TOC for 3.3

1.15.0
* Increased the padding on the casting bar
* Added two new options to the totem bars: Show Recall and Show Totems.

1.14.2
* Added 3.3/3.2 compatibility
* Added a percentage display to the experience bar
* Added tooltip descriptions to selected bars
* Added button facade support to the bag frame

1.12.1
* Updated LibKeyBound, giving Dominos support for up to 31 mouse buttons.
* Modified the menu bar creation code to fix some issues with patch 3.3

1.12.0
* Added industrials patch for modifier combos for paging
* Adjusted the defaults for the new layout ordering options to prevent issues.

1.11.1
* Version upgrade bugfix

1.11.0
*Implemented advanced layout ordering options, per gpsguru's patch

1.10.5
* Removed the range indicator display

1.10.4
* Taint fixes
* Added FactionFriend support to the experience bar

1.10.3
* Made the totem bar not disable itself when logging on a non Shaman character.

1.10.2
* 3.2 retail release

1.10.1
* Fixed a bug with talent swapping

1.10.0
* Updated for 3.2
* Added a new addon, Dominos_Totems – Provides three totem bars for shamans.

1.9.4
* Added russian localization
* Fixed the [none] targeting option.

1.9.3
* Merged into trunk
* Updated licensing information.

1.9.2
* Added a shadowdance bar for rogues. (3.1 only)

1.9.1
* Added some code to hopefully make the VehicleSeatIndicator stay completely on screen.

1.9.0
* Updated for 3.1 compatibility
* This should fix auto fading not working, along with the tainting issue with the quest log tracker item buttons

1.8.3
* Fixed the bug causing your bars to not load properly when in a form/stance/whatever.
* Updated translations

1.8.2
* Added a theoretical (ie, probably will not work) fix for the possess/vehicle bar issues people are having
* Modified the vehicle control bar to not always show the leave button
* Added Korean translation
* Added a fix for the missing profiles button under certain locales
* Made the buff and debuff highlighting code a bit more efficient

1.8.1
* Updated French translation
* Refactored code a bit

1.8.0
* Rewrote the bindings system to play more nicely with the stock blizzard bindings.
* Updated french translation.
* Adjusted some paging defaults for new users to sync up with the stock interface a bit better

1.7.2
* Removed pet option for the possess bar since it no longer works.

1.7.1
* I hear priests have class bar for shadow form now.

1.7.0
* Fixed a bug causing an action button's action to not update properly after being added back to a shrunken bar
* Fixed a bug causing phantom buttons to appear from bars derived from the multi action buttons
* Fixed a bug causing pages to be missing when extra action bars were selected on the blizzard side of interface options
* Fixed a bug causing duplicate vehicle bars when switching profiles
* Added tooltips to the databroker plugin. It now works exactly like the minimap button
* Added a help dialog when in configuration mode, along with a button to exit config mode
* Modified the behavior of clicking the config mode button in the options menu to close the options menu
* Added an option to lock action buttons to the dominos side of interface option. Note: this option WILL cause tainting issues when first set, which will clear up on next login/you reloading your interface
* Gave a few bars a minimum size to prevent those bars from becoming unclickable

1.6.3
* Fixed a bug with buff/debuff highlighting, and my inability to count parameters :)

1.6.2
* Fixed a bug with buff/debuff highlighting

1.6.1
* Fixed a profile loading bug

1.6.0
* Added a minimap button + toggle
* Added a sticky bars toggle

1.5.3
* Fixed a bug causing the quest log button to have a weird display when the menu bar was set to be vertical
* Changed the behavior of the talent button: It will now always be displayed, and will now blink on login if you have free talent points to spend.

1.5.2
* Fixed some bugs when a warlock lacked any buttons for the class bar
* Added a very basic vehicle bar UI. Its hacky, and needs a good bit of testing.

1.5.1
* Removed the Lock Action Button Positions option. The one on the action bars portion of the blizzard side of interface options should be used in its place.
* Fixed the red box error when Dominos couldn't find a version of DataBroker

1.5.0
* Fixed some keybinding display bugs on the action and pet bars
* Added a onebag and keyring display options to the bag bar
* Added a databroker launcher. Left click to open up the options menu, right click to toggle locking bars, and alt right click to toggle binding mode
* Added a /dom numbuttons <count> command: Resets your actionbar layout, creating as many bars as possible with <count> buttons.

1.4.11
* Added a stance slider for Metamorphosis

1.4.10
* Fixed options menu code for the new Wrath build. This will probably not work on the PTR.

1.4.9
* Fixed a bug causing the token tab to not display
* Switched Ace3 libs back to the trunk version

1.4.8
* Fixed a bug where aura events were not being detected on the class bar

1.4.7
* Fixed some redbox errors on the casting bar

1.4.6
* Fixed state code to work with the latest Wrath build (really this time)

1.4.5
* Fixed state code to work with the latest Wrath build.
* Profiles now default to one per class, instead of a single global profile.
* Formatted number values on the experience bar using commas (ex, 1,000,000)

1.4.4
* Added french translation (thanks Kubik)

1.4.3
* Fixed a bug causing the possess bar to not work

1.4.2
* Fixed a redbox error caused by me forgetting to update the profiles panel

1.4.1
* Turns out the casting bar did not work in 1.4.0, so I fixed that.

1.4.0
* Made compatible with Wrath

1.3.3
* Adjusted the possess bar to have a priority greater than everything except for modifier paging.

1.3.2
* Fixed an error in the right click menu of the experience bar.

1.3.1
* Fixed a bug where the experience bar would not register events if not watching a faction and not set to always watch experience
* Added in Chinese localization (thanks xuxianhe) to Dominos_XP. All localization files were moved to a localization directory. This change will require a restart of wow.

1.3.0
* Updated LibKeyBound.
* Added in an experience/reputation bar, Dominos_XP. Its basically the same as the Bongos one, except it cannot be made vertical, but has shared media support.

1.2.9
* Updated LibKeybound. This may require you to restart wow.
* Added Chinese localization (thanks xuxianhe)

1.2.8
* Unregistered a few more Blizzard things

1.2.7
* Fixed a hotkey display bug.

1.2.6
* Should fix some addon action blocked issues with the casting bar
* Fixed a bug where showstate settings were not being loaded on login

1.2.5
* Removed some debug prints.

1.2.4
* Fixed a bug where Tuller was sleepy and forgot to update the possess bar code with the right click selfcast fixes.

1.2.3
* Fixed a bug caused by me failing to correct some code after implementing the right click selfcast change :P

1.2.2
* Fixed an issue with right click self cast when not paged on a bar with paging enabled.

1.2.1
* Fixed an issue with ButtonFacade skins not saving properly

1.2.0
* Renamed any buttons that were still named Mangos
* Added an option to hide button tooltips

1.1.1
* Fixed a bug with the roll frame layout code
* Fixed a bug causing right clicking a frame in config mode to run the sticky logic
* The interface options menu will now hide when entering binding mode.
* Made the buff highlighting code more generic. It'll work on any standard action button that is loaded after it.