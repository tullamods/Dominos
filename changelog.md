# Dominos Changelog

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
