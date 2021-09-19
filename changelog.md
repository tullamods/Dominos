# Dominos Changelog

## 9.1.2

* Implement spec profile support in Retail (Thanks wkrueger)
* Add Swift Flight Form support (thanks ap0yuv)
* Fix transparency of normal texture for action buttons

## 9.1.1

* Fix micro menu bar in BCC
* Also, it should go without saying, but the [toxic workplace at Blizzard](https://en.wikipedia.org/wiki/California_Department_of_Fair_Employment_and_Housing_v._Activision_Blizzard)
  is REAL bad and I don't support that. Solidarity with the workers at Blizzard.

## 9.1.0

* TOC update for WoW 9.1.0

## 9.0.29

* Banished the MainMenuBarMaxLevelBar

## 9.0.28

* Added support for Burning Crusade Classic

## 9.0.27

* Fix progress bar text showing up under the actual progress bar

## 9.0.26

* You can now make adjustments to strata and level of bars (thanks Goranaws)
* Fixed issues with the talking head bar not working if the Blizzard Talking Head UI was already loaded
* All bars should now have the advanced options panel for display states

## 9.0.25

* Update TOCs for 9.0.5
* Force the talking head UI to reposition upon load

## 9.0.24

* Adjusted the alignment grid thickness to prevent issues with displaying at various scaled resolutions

## 9.0.23

* The alignment grid is now drawn from the center, and uses a square grid instead of rectangles (thanks Swanarog)
* Fix issues with calculating which way flyout button should open
* Fix issues with saving bar positions when not anchoring to an edge, grid point, or other bar
* Prevent the Talking Head and Group Loot frames from moving to unexpected places (Needs more testing)

## 9.0.22

* Fixed an issue where flyout locations (ex Warlock minion/Hunter pet) would be used for fading detection, even if the flyout was closed
* Fixed an issue where moving a pet ability could trigger an error in classic
* Forced the cast bar to be enabled when in a vehicle/override UI state
* Added a fading panel to the cast bar

## 9.0.21

* Work around an issue with the stock UI expecting the possess bar to be positioned on the screen somewhere

## 9.0.20

### New Features

* Added a dedicated possess bar for the leaving various ability states (Eye of Killrog, Karazhan Chess)
* Required display logic has been separated from show states. You can now configure showstates for more bars (including the pet bar)
* Included the advanced panel on most of the bars it was missing from.

### Configuration Mode Enhancements

* Configuration mode will hide when entering combat, and resume when exiting combat
* Added the ability to adjust the grid scale in config mode (thanks Swanarog)
* Added the ability to stick to grid points (if shown)
* Added the ability to stick to additional points on screen edges/center points
* Added the ability to stick to additional points on other bars
* Added the ability to microadjust bar positions via pressing a movement key when hovering over a bar. Previously this was limited to just keyboard movement.
* Added a bit more live feedback when adjusting bar opacity/visibility in configuration mode via the mouse
* Added proper display names for the various bars in configuration mode. Bar IDs are now available in the tooltip
* Gave bars different layers in configuration mode. The talking head frame, for example, will display under action bars.

### Fixes

* Updated WoW Classic TOCs for 1.13.6
* Added as "is the azerite item in the bank?" check to the Azerite mode of progress bars
* Bar positions should be a bit more consistent when scaling
* Fixed some issue with binding display names
* Increased the specificity of the Shadowstate conditional to hopefully prevent conflicts with Shadowlands abilities

## 9.0.19

* Fixed a potential error when attemping to view azerite item xp info for an item in the bank

## 9.0.18

* Added an alignment grid when configuring bars

## 9.0.17

* Updated TOCs for 9.0.2

## 9.0.16

* Fixed a typo that caused the vehicle bar fail to load

## 9.0.15

* Fixed a typo that prevented binding Dominos action buttons via the standard keybinding UI
* Cleared a showstate from the vehicle bar, if one exists. This should hopefully fix issues with the exit vehicle button not showing up
* Sticky bars should be a bit better about picking the nearest point

## 9.0.14

* Add a mute option to the talking head bar's context menu

## 9.0.13

* Added gold tracking as an option for the progess bar (thanks WanderingFox)
* The possess bar should now be properly hidden
* Fixed some issues when smoothly transitioning between different bar opacities with fade in/out delays
* Prevent the talking head bar from resizing in combat

## 9.0.12

* Added a workaround for Titan Panel messing with the extra ability container

## 9.0.11

* Update Chinese localization (thanks Kuletco)
* Fixed an issue causing the columns silder to not adjust properly when resizing an action bar
* Fixed an issue with action buttons not initializing properly when increasing the size of an action bar after shrinking it
* The extra ability bar now has a static size. This should hopefully allow it to show up in cases where it wasn't before
* Disabled the hotkey text resizing bits for pet and stance buttons if Masque is enabled for those bars

## 9.0.10

* Yep, one more buttonThemer fix for the stance/pet bar

## 9.0.9

* Fix an issue with button theming that caused the bag bar to disappear

## 9.0.8

* Fix an issue causing paging settings to not be applied to new characters (thanks Kuletco)
* The extra action bar can now be skinned by Masque (thanks Kuletco)

## 9.0.7

* Disable mouse interaction on ExtraActionBarFrame to prevent issues with interacting with actions on the extra bar

## 9.0.6

* Fix hide extra ability bar artwork option not applying if after reloading your UI with the bar active
* Only reposition the ExtraAbilityContainer when initializing the extra bar

## 9.0.5

* Added Dominos_Roll back to retail build

## 9.0.4

* Add support for paging based upon cmd/meta keys
* Fix an issue preventing the click through setting from applying after reloading your UI

## 9.0.3

* Updated the IsActiveBattlefield check used by the honor bar

## 9.0.2

* Fixed an issue with override bar detection

## 9.0.1

* Fixed an issue causing the bindings migration code to not save. Bindings should be visible again

## 9.0.0

### Enhancements

* Added support for WoW 9.0.1 (Shadowlands Prepatch)
* Added support for the new Blizzard Quick Keybinding mode
* Added standard Blizzard binidngs for all action buttons created by Dominos
* Added support for Paladin auras on the class bar in 9.0
* Added paging support for Paladin auras (they're \[form\] macro conditions)
* Added a Shield Equipped paging option for Paladins and Warriors
* Action Bars now have individual groups in Masque
* The zone and extra action bars have been merged into the extra bar

### Fixes

* Removed the unnecessary extrabar show state from the extra ability bar
* Resized pet and stance button hotkey text to fit better within the buttons
* Fixed an issue with hiding actions currently assigned to an action bar
* Rewrote the keybindings handler. Cast on key down should work better on the DominosActionButtonXX buttons.

### Other

* Rewrote the action button portion of Dominos to be more compatibile with 9.0. Among other things, empty slots should now show up when expected.
* Moved the overlay interface code to Dominos_Config, trimmming the main file size a slight bit
* By default, Dominos no longer shows the Artifact/Azerite bar. You can change this the main options menu
* Dominos_Roll isn't provided in the main build for now.
