# Dominos Changelog

## 10.2.31

* (Cata) Fix encounter bar positioning

## 10.2.30

* Add preliminary support for War Within

## 10.2.29

* Updated TOCs for 10.2.7
* The TOC files now use the new comma separated values format.

## 10.2.28

* (Cata) Update Paladin aura paging options

## 10.2.27

* Add support for Cataclysm Classic

## 10.2.26

* Fix issues causing action bars 11-14 to not be bindable in classic versions
* Ensure that GM Ticket Status button is anchored upon loading the UI

## 10.2.25

* Updated TOCs for 1.14.2
* Action Button hotkeys are now reparented when hidden, instead of via an
  opacity change. This should be more compatible with other addons.
* The GM Ticket Status button should now be anchored to the menu bar

## 10.2.24

* (Retail) Restored the menu, bags and queue status bars

## 10.2.23

* Updated TOC file versions for 10.2.6
* (Retail) Temporarily disabled Dominos from handling the menu, bags and queue
  status bars to work around issues introduced by the new patch. These can still
  be modified using standard Edit Mode.

## 10.2.22

* (Classic) Fix latency tooltip

## 10.2.21

* Fix hotkey display issues
* Fixed some inconsistencies when toggling the new per bar options
* Renamed the `showgrid` profile value to `showEmptyButtons` to maintain consistency with per bar settings

## 10.2.20

* Added per bar toggles for bindings, macros, counts, and equipped item border visibility
* Added the ability to configure the number of segments on progress bars

## 10.2.19

* (Classic) Update Shadowform and Metamorphosis conditionals to not check for a result from
* (Classic) Add some workarounds to prevent cooldown flashes from showing up on the stance and pet bars when they're transparent but not hidden.

## 10.2.18

* Action Buttons that have been hidden by shrinking the size of the bar are now
  simply hidden, instead of being completely detached from the bar. This should
  allow them to still remain usable in macros or by pressing any associated
  hotkeys.
* Added a new Row Offset layout setting. This will indent each row of buttons
  by the specified value.

## 10.2.17

* Update TOC file versions for 1.15.1

## 10.2.16

* (Retail) Fix an issue causing slots to appear empty when switching specs

## 10.2.15

* (Retail) Enabled reuse of Blizzard Action Bars 2-8
* (Wrath, Classic) Added action bars 11-14
* Immaterial code optimizations and cleanup

## 10.2.14b

* Make workaround a bit more consistent

## 10.2.14

* Add a workaround for missing icons when switching forms/etc
* Fix typo in pet battle detection

## 10.2.13

* (Retail) Reimplement cast on key press support

## 10.2.12b

* Fix error on load in Classic

## 10.2.12

* (Retail) Revert back most of the post 10.2.1 changes
* (Retail) Added an option to toggle spell animations

## 10.2.11

* (Retail) Fix issues causing keybindings to not properly from and to the Override UI
* Revert Override UI detection implementation to the 10.2.1 version

## 10.2.10

* (Retail) `/click` macros should work a bit better when CastOnKeyDown is enabled
* Cleanup code a bit

## 10.2.9

* (Retail) Fix Override Bar micro menu button positioning
* (Retail) Improved support for addons like HideActionbarAnimations by deferring some function bindings until later
* (Retail) Fixed an issue with displaying counts of at least 1000 on actions
* Updated LibUIDropDownMenu to resolve the NewFeature error

## 10.2.8

* Updated LibUIDropDownMenu to prevent an error with opening right click menus that contain well, dropdowns.

## 10.2.7

* Add profession quality indicators
* Icon coloring is now configurable. Defaults have been reverted to those of the
  base UI
* Hid extraneous options from Classic builds

## 10.2.6

* Resolve issues with focus, self, and mouseover cast not working
* Revert overlay glow behavior
* Update bar visibility when entering/leaving areas

## 10.2.5

### THIS IS A MAJOR BREAKING UPDATE

Action Buttons in retail are no longer derived from ActionBarButtonTemplate. The behavior
in classic should be about the same as it was before.

Benefits:

* You'll (hopefully) no longer see cases where action buttons would randomly stop working when switching zones.
* Generally action button behavior should be more consistent across all action buttons

Drawbacks:

* Press and hold casting is no longer supported. (This is an API limitation of using completely custom action buttons)
* Addons that modify the stock action won't just work with Dominos anymore. They'll need to code in their own support
  (sorry).

Other Changes:

* (Retail) Out of range coloring is now builtin
* (Retail) Spell activation glows can now be disabled. They're also a bit less dramatic.

## 10.2.1

* Handle hiding the stock mirror timers in 10.2
* Update TOCs for 1.15.0
* Better updates to action flyouts when hunter pets change
* Throttle menu bar updates

## 10.2.0

* Update TOCs for 10.2.0
* Prevent Dominos Progress from registering for events before its settings have
  been loaded

## 10.1.5

* Update TOCs for 3.4.3
* Resolve some possible null reference errors with unloading modules

## 10.1.4

* Update TOCs for 1.14.4 and 10.1.7
* (Classic) Fix the positioning close button positioning on right click menus
* (Retail) Fix the micro menu positioning when in a pet battle

## 10.1.3

* Add the Evoker class bar
* Made some internal improvements to handling one time events for module loading

## 10.1.2

* Add support for 10.1.5

## 10.1.1

* Add support for 3.4.3

## 10.1.0

* Add support for 10.1.0

## 10.0.22

* Fixed a few more issues with mouseover fading and hovering over the spell flyout

## 10.0.21

* Fixed an error caused by hovering over a faded bar
* Resolved a flyout activation issue when cast on key press is enabled

## 10.0.20

* Updated TOCs for 10.0.7
* Reverted to 10.0.15 implementations of pet and stance bars due to API changes
* Improved handling of flyout clicks

## 10.0.19

* Updated TOCs for 10.0.5

## 10.0.18

* (Classic) Correct spell ID used for shadowform detection

## 10.0.17

* Updated TOCs for 3.4.1
* Made Shadowform (Retail) and Metamorphosis (Classic) state calculations to be dynamic

## 10.0.16

* Simplified the implementation of the stance and pet bars. These once again reuse the stock buttons.
* Updated reputation calculations for major, friendly and paragon factions
* Prevented the pet bar from showing up when channeling Eye of Kilrog with an active summon
* Flyouts now better handle learning new abilities/switching specs
* Flyouts can now be toggled by clicking any mouse button, instead of only the left button.
* Added additional forbidden frame checks to the mouseover detection code

## 10.0.15

* Added major faction support to reputation bar (thanks, [Daenarys](https://github.com/Daenarys))
* (Classic) Added Death Knight presence paging (thanks [Road-block](https://github.com/Road-block))
* Increased dragon riding paging priority to resolve conflicts with warrior stances
* Improved menu bar handling in override/pet battle conditions
* Fixed a forbidden frame error impacting fading in combat
* Added a workaround for invalid micro menu hit rect offsets on 3.4.1

## 10.0.14

* Fix an issue with profile version updates upon the load of a new profile
* Improved flyout mouseover detection

## 10.0.13

* Implemented a flyout workaround for portals and pet abilities, etc.
* Dragonriding is now a normal paging condition. You can modify via an action bar's right click menu.
* Removed the deprecated Dominos_Encounter folder

## 10.0.12

* Fix dragonriding bar calculation

## 10.0.11

* Fix an issue causing the zhTW localization to not load for the cast bar
* Added some workarounds to better control the position of the extra action bar

## 10.0.10

* Add zhTW updates from @class2u

## 10.0.9

* Update TOCs for 10.0.2
* Add reagent bag slot

## 10.0.8

* Added the ability to show empty buttons per action bar
* Fixed a bug preventing the show empty buttons option from working
* Fixed an off by one error causing action slots to incorrectly map to the totem bar
* Fixed some weird dragging behavior with action buttons
* Fixed an issue causing keybindings for Blizzard bars 6, 7, and 8 to not map properly to Dominos bars 12, 13, and 14

## 10.0.7

* Update action button visibility when known spells changed

## 10.0.6

* Fix showing empty buttons not working in combat

## 10.0.5

* The exit vehicle button should work under more scenarios now
* Adjusted the strata of the queue status bar
* Add Evoker stance support (untested)
* Empowered spells should now show up on Dominos cast. Level display is not yet implemented

## 10.0.4

* The Dominos Masque skin is now packaged as a separate addon (thanks [StormFX](https://github.com/StormFX))
* Adjusted bindings header definitions in retail to avoid tainting issues

## 10.0.3

* Fix possess bar errors in classic

## 10.0.2

* Fix missing Bindings.xml errors
* Fix some errors with hiding frames

## 10.0.1

* Use LibUIDropdown to reduce potential sources of taint from configuration mode
* (Clssic) Reimplement :HOTKEY bindings to ensure that cast on keypress works
  properly with modifier keys
* Update zhCN localization (thanks Kuletco)

## 10.0.0

* Improved show empty buttons detection for battlepet, mount, and petaction cursor types

### Known Issues

* Action bars do not support spell flyout actions on 10.x realms (Blizzard bug).
  You will receive an error if you try to use one.
* Not all action bars support cast on key press on 10.x realms (Blizzard bug)
* Not all action bars support hold to cast on 10.x realms (Blizzard bug)

## 10.0.0-beta4

* Fix error when leaving combat

## 10.0.0-beta3

* Fix bindings not showing up for action buttons in classic
* Fix invalid event registration preventing the possess bar from loading in vanilla
* Work around dragging mounts not triggering showing empty buttons by showing empty buttons when the collections journal
  is shown

## 10.0.0-beta2

* Re-enable action button reuse in classic versions
* Re-enable cast on keypress in classic versions
* Potentially add support for dragonriding
* Reduce some potential source of taint

## 10.0.0-beta1

* Added a placeholder for Dominos Encounter/Extras to automatically disable it

## 10.0.0-alpha4

* Added a new possess bar implementation that handles both possess and vehicle
  exit actions

## 10.0.0-alpha3

* Added a new pet bar implementation
* Added a queue status bar
* Added support for Warrior stances
* Reorganized menu buttons (thanks Daenarys)
* Turned the extra bar back on (it *probably* works without any additional adjustments needed)

## 10.0.0-alpha2

* Action button proxying implemented. Action Bars 1, 3, 4, 5, 6, 13, and 14 now
  support cast on key press and hold to cast
* Fixed shield conditionals for Paladins/Warriors

## 10.0.0-alpha1

* Dragonflight Support
* Added support for 14 action bars
* Merged Dominos_Encounter/Extras into the main addon