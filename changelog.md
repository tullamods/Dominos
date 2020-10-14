# Dominos Changelog

## 9.0.2

* Fixed an issue with override bar detection

## 9.0.1

* Fixed an issue causing the bindings migration code to not save. Bindings should be visible again

## 9.0.0

### Enhancments

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