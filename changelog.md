# Dominos Changelog

8.2.30

* Updated TOCs for 8.2.5

8.2.29

* Now using the Dominos icon in both retail and classic
* Added the ability to disable Dominos modules on a per profile basis via Dominos.db.profile.modules.ModuleName = false
* Misc internal changes

8.2.28

* Fix an error when channeling spells

8.2.27

* Yet more progress bar bugfixes
* Fix an issue that would cause empty slots to not reappear after switching profiles

8.2.26

* Added a new option Show Count Text - toggles showing item/reagent counts on action buttons
* Updated the artifact bar display to prioritize the azerite bar

8.2.25

* Added a workaround for cases where the progress bar mode update updated failed
* Added druid travel form paging options
* Set statehidden = true on all Blizzard action buttons by default
* Classic - Added counts to action buttons for abilities that consume reagents

8.2.24

* Add a new progress bar mode setting: Skip Inactive modes. Enabling this skip any inactive progress bar mode when you
click a progress bar to switch the next mode

8.2.23

* Revert one bar mode being the default setting for the progress bar.

8.2.22

* Fix an issue preventing the main options panel for the progress bar from loading

8.2.21

* Fix an issue causing druid form states to not work properly if the player has a bar set for Moonkin form without having the form

8.2.20

* Skipped version 8.2.19
* Added a Theme Action Buttons toggle to the main interface window to enable/disable the Dominos look for action buttons
* Added support for the next version of Masque

8.2.18

* Fix a db migration error for completely new profiles

8.2.17

* Add migration bits for the config change introduced in 8.2.16

8.2.16

* Fixed cases where the progress bar would appear blank

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

8.2.2

* Use Dominos:IsBuild("classic") for tests. * Add stance bar for paladins

8.2.1

* Allow exit vehicle button to load

8.2.0

* Initial release for classic
