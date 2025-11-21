# Dominos Changelog

## 11.2.8

* (Classic) Fixed the missing Monk class bar

## 11.2.7

* (Retail, Midnight) Reuse the existing pet bar action buttons and logic. This should make the bar usable in Midnight
* (Classic) Use a custom impelemntation for the class bar. This shold resolve issues with positioning of the bar when playing certain classes
* (Midnight) Partially reimplemented the logic for hiding action button cooldowns on transparent bars.

## 11.2.6

* (Midnight) Enabled the cast bar after resolving some secret value comparison errors

## 11.2.5

* Fixed an issue that would prevent bindings from working when in Edit House mode

## 11.2.4

* Updated TOC files for game versions 5.5.3 and 1.15.8
* Dropped the specific TOC file for Vanilla as 1.15.8 supports conditional directives
* The artifactBar and azeriteBar lua files should now not load at all on Classic

## 11.2.3

* Updated TOC files for 12.0.0 (Midnight) and 11.2.7
* Fixed an error caused byt the progress bar trying to call a missing API when attempting to show azerite information.
* (Midnight) Disabled the cast bar and pet bar
* (Midnight) Disabled the ability to open flyouts via keypress

## 11.2.2

* Changed the default paging settings for Warriors in Mists to use Action Bar 1 for battle stance, instead of Action Bar 7
* Fixed an issue with the progress bars that could cause an Addon Action Blocked message to occur when leveling up in combat
* Reintroduced a workaround for a Blizzard error that could occur when hiding the achievement button in classic version
* Updated TOCs for 11.2.5 and 5.5.1

## 11.2.1

* Fixed the addon compartment menu icon not showing the options menu when clicked

## 11.2.0

* Excluded the new combat assistant highlights from spell animation filtering

## 11.1.9

* Fixed menu bar errors
* Corrected pkgmeta file so that you'll actually see the right changelog and not just my commit messages

## 11.1.8

* Added support for 11.2.0
* Updated TOCs to use conditional file loading directives
* Rewrote the bar states configuration formats to handle multiple game versions a bit better
* Updated the menu bar button ordering to hopefully prevent issues when switching to vehicle/pet battle UIs

## 11.1.7

* Added support for Monk stances in MoP Classic

## 11.1.6

* Fixed multiple paging issues with Mists of Pandaria Classic

## 11.1.5

* Updated TOCs for 11.1.7 and 5.5.0 (Mists of Pandaria Classic)
* Refreshed libraries to fix a lua error in MoP Classic

## 11.1.4

* Updated TOCs for 11.1.5

## 11.1.3

* Updated TOCs for 1.15.7

## 11.1.2

* Context menu dropdowns now use the standard dropdown menu templates

## 11.1.1

* Fixed renown level text showing %d

## 11.1.0

* Adjusted KeyRingButton test to hopefully avoid some errors

## 11.0.9

* Updated TOCs for 11.1.0, 4.4.2 and 1.15.6
* (Classic) Added experimental support for the extra ability bar

## 11.0.8

* Updated TOCs for 1.15.5

## 11.0.7

* (Classic) Fixed tooltip issues when enabling all Blizzard action bars

## 11.0.6

* Updated TOCs for 11.0.7 and 11.0.5

## 11.0.5

* (Vanilla) Fixed tooltip issues when enabling all Blizzard action bars

## 11.0.4

* Added a new slider for row spacing (contributed by [Xiaoyang-Huang](https://github.com/Xiaoyang-Huang))
* Added a Hide at Max Level option to the display menu of progress bars

## 11.0.3

* Added support for classic versions 4.4.1 and 1.15.4

## 11.0.2

* Updated Override UI detection

## 11.0.1

* Fixed an issue that would let spell overlay glows still display, even if disabled

## 11.0.0

* (Classic) Ensured the Encounter Bar always is given a size to prevent issues with repositioning frames
* Dropped WoW 10.x from TOC files
