# Dominos Changelog

## 10.0.0-beta2

* Re-enable action button reuse in classic versions
* Re-enable cast on keypress in classic versions
* Potentially add support for dragonriding
* Reduce some potential source of taint

## 10.0.0-beta1

* Added a placeholder for Dominos Encounter/Extras to automatically disable it

### Known Issues

* Action bars do not support spell flyout actions on 10.x realms (Blizzard bug).
  You will receive an error if you try to use one.
* Not all action bars support cast on key press on 10.x realms (Blizzard bug)
* Not all action bars support hold to cast on 10.x realms (Blizzard bug)

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
