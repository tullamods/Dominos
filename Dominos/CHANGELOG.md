# Dominos Changelog

### Midnight extra action button taint isolation

- Applied Dominos' Midnight action-button safety wrapper to the native `ExtraActionButton1` so Blizzard shared action events cannot call protected `SetAttribute()` / cooldown paths through a Dominos-tainted stack.
- Reused the secure press-and-hold updater for both Dominos action buttons and the native extra-action button, preserving slot-driven Blizzard execution.

### Midnight extra action bar event relay

- Restored Blizzard extra-action button visibility on Midnight builds after Dominos disables the native `ActionBarController` event pump.
- Added a narrow Dominos relay for `UPDATE_EXTRA_ACTIONBAR` / `PLAYER_ENTERING_WORLD` that calls Blizzard's native `ExtraActionBar_Update()` instead of replacing extra-action execution.
- Hardened `bars/extraAbilityBar.lua` against missing Retail/Classic extra-bar helpers and preserved secure `ExtraActionButton1` click behavior.

### Midnight native override action-bar taint isolation

- Forced Dominos-owned override-bar handling on Midnight builds instead of using Blizzard's native `OverrideActionBar` button frame.
- Detached native `OverrideActionBarButton*` frames from Blizzard shared action button dispatchers so hidden native override buttons cannot call protected `SetCooldown` / `SetAttribute` paths with secret values from a Dominos-tainted stack.
- Stopped wrapping native `OverrideActionBarButton1` show/hide scripts on Midnight; override routing now uses Dominos secure override-page state instead.

### Midnight native action-bar controller taint isolation

- Stopped hiding or reparenting protected Blizzard action-bar frames on Midnight builds; Dominos now visually suppresses them with alpha/mouse suppression instead.
- Disabled Blizzard's native ActionBarController event pump on Midnight so hidden `MainActionBar` is not shown, hidden, or repaged by Blizzard after Dominos has taken ownership of the visible action bars.
- Preserved the Classic/TBC/Mists hiding path unchanged.

### Midnight native button taint isolation

- Detached hidden Blizzard stock action buttons from Blizzard shared action button dispatcher frames on Midnight builds.
- Avoided Dominos touching `ActionButton1` showgrid attributes on Midnight; Dominos now relies on explicit showgrid events there.
- Prevented hidden native `MultiBar*Button*` frames from reaching Blizzard `UpdatePressAndHoldAction()` / `ActionButton_UpdateCooldown()` after Dominos has hidden the stock bars.


## Unreleased - Phase 2: Blizzard-compatible action button frame contract rebase

* (Midnight) Replaced the Dominos-owned action button cooldown/update dispatch with a Blizzard-compatible duration-object path. This avoids passing secret cooldown `start`/`duration` values through tainted Lua and prevents protected `pressAndHoldAction` attribute writes from Blizzard's shared `ActionButton_Update` path.
* Rebased the Phase 2 action-button frame contract work onto the updated `Dominos-master` base without downgrading the newer 11.3.0-beta1 TOC metadata or Mists loading directives.
* Added `core/bindingCompat.lua` as the centralized binding identity layer for native Blizzard binding commands, Dominos fallback CLICK bindings, and stable action-button binding IDs.
* Updated action-button setup to expose stable binding fields and attributes such as `commandName`, `bindingAction`, `bindingID`, `dominosButtonID`, `nativeCommandName`, and `fallbackCommandName` without deriving stable identity from paged action slots.
* Updated hotkey and quick-binding lookup paths to consume the shared BindingCompat contract while preserving existing Dominos fallback bindings for saved user configurations.
* Hardened action button override-binding refresh paths to tolerate missing or nil binding keys and avoid unsafe binding mutation.
* Refactored override binding handling for Blizzard default override states, vehicle/possess-style action states, pet battle states, native `ACTIONBUTTON1`-`ACTIONBUTTON6` keys, and Dominos fallback CLICK bindings.
* Improved support for external secure action-button overrides by detecting `type`, `clickbutton`, and `gse-button` style override attributes on action buttons.
* Preserved the safe restricted-environment correction: Dominos does not alias `ActionButton1`-`ActionButton12` to Dominos-created frames and does not write Dominos buttons into Blizzard restricted `MainActionBar.actionButtons` tables.
* Added a safe bridge for external addons that attach overrides to Blizzard `ActionButton1`-`ActionButton12`, mirroring supported external override attributes onto the matching visible Dominos action buttons without corrupting Blizzard restricted action-bar controller state.
* Preserved slot-driven secure action behavior; Dominos remains a Blizzard-compatible action-slot orchestrator and does not implement custom spell, item, macro, or GSE casting logic.
* Kept Phase 2 changes Lua 5.1 compatible and guarded against combat-taint-prone protected attribute updates where possible.

## 11.3.0-beta1

* Note: This version won't work on 5.5.3 (hence the beta designation)
* Update TOCs for the 12.0.7 and 5.5.4 PTRs

## 11.2.21

* Update TOCs for 12.0.5

## 11.2.20

* (Retail) Fixed an issue causing the cast bar to not disappear when canceling a channeled spell.

## 11.2.19

* (Retail) Fixed the reputation bar for major factions (Thanks [fediazgon](https://github.com/fediazgon))

## 11.2.18

* (Retail) Fix more secret errors with the cast bar by using castBarID when available.

## 11.2.17

* Keyboard nudging now checks your Strafe Left/Right keybindings in addition to Turn Left/Right. (Handles the Modern/Legacy control options in 12.x)
* (TBC) Added latency information to the minimap icon, like in Vanilla (Thanks [PortalPi ](https://github.com/PortalPi))

## 11.2.16

* (Retail) Better handle secret icons on the cast bar.

## 11.2.15

* (TBC) Fixed the talent button not appearing on the menu bar

## 11.2.14

* (Retail) Fixed an menu bar error when entering/exiting pet battles

## 11.2.13

* Fixed an issue with unregistering the Blizzard stance bar that was causing errors

## 11.2.12

* Added support for Burning Crusade Classic Anniversary Edition
* Added in missing menu bar button names

## 11.2.11

* Refactored the progress bar to use a data provider interface instead of metatable manipulation (which broke with the last Midnight fix)

## 11.2.10

* Added a workaround Dominos frame class inheritance to fix the Invalid 'self' frame handle errors in the latest Midnight build (Thanks, [Tyler Fleckenstein](https://github.com/tpfleck))

## 11.2.9

* (Midnight) Added a workaround for GetUnitEmpowerHoldAtMaxTime returning
  secret values to prevent error messages when casting empowered spells.
  Hopefully Blizzard will drop this restriction.

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
