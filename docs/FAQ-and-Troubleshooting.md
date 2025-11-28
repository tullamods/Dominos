# FAQ and Troubleshooting

Common questions, problems, and solutions for Dominos users.

## Table of Contents

- [Frequently Asked Questions](#frequently-asked-questions)
- [Common Problems](#common-problems)
- [Keybinding Issues](#keybinding-issues)
- [Visual Issues](#visual-issues)
- [Paging and State Issues](#paging-and-state-issues)
- [Addon Conflicts](#addon-conflicts)
- [Performance and Errors](#performance-and-errors)

## Frequently Asked Questions

### General Questions

**Q: What is Dominos?**

A: Dominos is an action bar addon that replaces the default Blizzard action bars with highly customizable alternatives. It provides extensive options for positioning, scaling, fading, paging, and more.

**Q: Do I need Dominos if I already have Bartender/ElvUI?**

A: No. Dominos, Bartender, and ElvUI all provide action bar replacements. You should only use one at a time to avoid conflicts. Disable the action bar component of other addons if using Dominos.

**Q: Is Dominos compatible with Classic/TBC/Wrath/Cataclysm?**

A: Yes! Dominos supports all major WoW versions:
- Retail (The War Within and future expansions)
- Cataclysm Classic
- Wrath of the Lich King Classic
- The Burning Crusade Classic
- Classic Era (Vanilla)

The addon automatically enables/disables features based on game version.

**Q: How do I move bars?**

A: Enter configuration mode:
- Left-click the minimap button, OR
- Type `/dominos config`, OR
- Open settings (`/dominos`) and click "Configure Bars"

Then click and drag bars to reposition them.

**Q: How do I bind keys to abilities?**

A: Two methods:

1. **Standard WoW Keybindings**:
   - ESC → Keybindings → Dominos section
   - Find "Action Bar 1", "Action Bar 2", etc.
   - Bind keys to each button slot

2. **Quick Binding Mode** (faster):
   - Type `/kb` or Shift+click the Dominos minimap button
   - Hover over any button and press the key you want to bind
   - Exit binding mode when done

**Q: How many action bars can I have?**

A: Up to 14 action bars, each with 12 buttons = 168 total button slots.

Set the count with `/dominos numbars <count>` (default is 10).

**Q: Can I use Dominos with Masque/ButtonFacade?**

A: Yes! Dominos has full Masque support. Install Masque and a skin addon, then configure per-bar skins in each bar's right-click menu.

**Q: What's the difference between pages and bars?**

A: **Bars** are the visible frames on screen (Bar 1, Bar 2, etc.). **Pages** are sets of 12 abilities that can be displayed on a bar. Paging lets one bar show different pages based on conditions (forms, stances, modifiers).

Example: Bar 1 can show "Page 1" normally and "Page 2" when you're in Cat Form.

**Q: Where are my settings saved?**

A: Settings are saved in your WoW `WTF` folder:
- Account-wide: `WTF/Account/<account>/SavedVariables/Dominos.lua`
- Per-character: `WTF/Account/<account>/<server>/<character>/SavedVariables/Dominos.lua`

Profiles are in the account-wide file.

**Q: How do I backup my configuration?**

A: Two methods:

1. **In-game profile**: `/dominos save backup`
2. **File backup**: Copy `WTF/Account/<account>/SavedVariables/Dominos.lua`

**Q: Can I share my configuration with another character?**

A: Yes, use profiles:
1. On character A: `/dominos save SharedConfig`
2. Log in to character B: `/dominos set SharedConfig`

Or use a shared profile that both characters use.

**Q: Does Dominos work with other action button addons?**

A: Generally yes, if they modify button appearance but don't replace the action bar system:
- **Compatible**: OmniCC, tullaRange, AdiButtonAuras (enhance buttons)
- **Conflicts**: Bartender, ElvUI action bars, LUI (replace action bars)

### Feature Questions

**Q: Can I make bars appear only in combat?**

A: Yes, use conditional visibility:
1. Right-click bar in config mode
2. Find "Show States" field
3. Enter: `[combat] show; hide`

See [Visibility and Fading](Visibility-and-Fading.md) for more.

**Q: Can I make bars fade when not in use?**

A: Yes, use opacity fading:
1. Right-click bar in config mode
2. Set "Faded Opacity" to 0% (or low value)
3. Adjust fade timing as desired

See [Visibility and Fading](Visibility-and-Fading.md) for details.

**Q: Can my bars change with stances/forms automatically?**

A: Yes, use action bar paging:
1. Right-click bar in config mode
2. Go to "Paging" section
3. Enable states for your forms/stances
4. Set which page to show for each state

See [Paging and Bar States](Paging-and-Bar-States.md) for full guide.

**Q: Can I have a bar that appears when I hold Shift?**

A: Yes, two approaches:

**Approach 1 - Visibility** (bar hidden until Shift held):
1. Right-click bar → Show States: `[mod:shift] show; hide`

**Approach 2 - Paging** (bar changes to different abilities):
1. Right-click bar → Paging → Enable "Shift"
2. Set which page to show when Shift held
3. Put different abilities on that page

**Q: How do I hide the minimap button?**

A: `/dominos` → Uncheck "Minimap Button"

You can still access settings with `/dominos` command.

**Q: Can I stack bars vertically/horizontally?**

A: Yes, use anchoring:
1. Enter config mode
2. Ensure "Sticky Frames" is enabled (in `/dominos` settings)
3. Drag one bar near another (within 8 pixels)
4. Release - they snap together
5. Moving parent bar now moves both

**Q: Can I make bars different sizes?**

A: Yes, each bar has independent scaling:
- GUI: Right-click bar → Scale slider
- Command: `/dominos scale <bar> <value>`

Example: `/dominos scale pet 0.8` (80% size pet bar)

**Q: Can I see tooltips in combat?**

A: Yes/no, configurable:
1. `/dominos` → Global settings
2. "Show Tooltips in Combat" checkbox

**Q: What's the difference between "Empty Buttons" local and global setting?**

A:
- **Global setting** (in `/dominos`): Default for all bars
- **Per-bar setting** (right-click bar): Overrides global for that specific bar

Per-bar settings take priority.

## Common Problems

### "I can't see my bars!"

**Possible causes and solutions:**

1. **Bar is hidden**
   - Solution: `/dominos show <bar>` (e.g., `/dominos show 1`)
   - Or: `/dominos show all`

2. **Bar has 0% opacity**
   - Solution: `/dominos setalpha <bar> 1`
   - Check both base opacity and faded opacity

3. **Bar is off-screen**
   - Solution: Enter config mode (`/dominos config`)
   - Look around screen edges, especially after resolution changes
   - Or: Delete profile and recreate

4. **Bar is behind other UI elements**
   - Solution: Right-click bar → Display Layer → Set to HIGH
   - Or increase Display Level

5. **Conditional visibility is hiding it**
   - Solution: Right-click bar → Clear "Show States" field
   - Or check that you meet the condition (e.g., `[combat]` requires being in combat)

6. **Bar is click-through and has no background**
   - Solution: Disable click-through in bar settings
   - Or increase opacity

### "I can't move my bars!"

**Causes:**

1. **Not in configuration mode**
   - Solution: `/dominos config` to enter config mode

2. **Grabbing the wrong spot**
   - Solution: Click directly on buttons or bar frame (not empty space around it)

3. **Bar is anchored and you're trying to move the parent**
   - Solution: Break anchor first, or move the child bar

4. **UI scale issue**
   - Solution: Try adjusting UI scale in WoW settings, then retry

### "My keybinds don't work!"

See [Keybinding Issues](#keybinding-issues) section below.

### "Bars are in weird positions after changing resolution"

**Cause**: Resolution change alters screen dimensions, bars positioned at old coordinates may be off-screen.

**Solutions:**

1. **Find bars in config mode**:
   - `/dominos config`
   - Check screen edges carefully
   - Drag back to center

2. **Reset bar positions**:
   - Create new profile: `/dominos save newprofile`
   - Reconfigure from scratch

3. **Use anchoring to prevent issues**:
   - Anchor bars to each other, not absolute screen positions
   - Anchored bars maintain relative positions across resolutions

### "Paging doesn't work"

See [Paging and State Issues](#paging-and-state-issues) section below.

### "Buttons overlap or have gaps"

**Cause**: Spacing setting is incorrect.

**Solutions:**

- Reduce overlap: `/dominos space <bar> 2` (2px gaps)
- Eliminate gaps: `/dominos space <bar> 0` (touching)
- Intentional overlap: `/dominos space <bar> -2` (negative spacing)

### "Bar is too big/small"

**Cause**: Scale setting.

**Solution:**

- GUI: Right-click bar → Scale slider
- Command: `/dominos scale <bar> <value>`
  - `1.0` = 100% (default)
  - `0.8` = 80% (smaller)
  - `1.2` = 120% (larger)

### "Fading doesn't work"

**Possible causes:**

1. **Base and Faded opacity are the same**
   - Solution: Set different values (e.g., Base 100%, Faded 0%)

2. **Fade duration is 0**
   - Solution: Set fade duration to at least 0.3 seconds

3. **Mouse is still over the bar**
   - Solution: Move mouse completely away

4. **Linked opacity and mousing over anchored bar**
   - Solution: Disable linked opacity or break anchor

### "Cast bar doesn't show"

**Causes:**

1. **Dominos_Cast not installed**
   - Solution: Ensure Dominos_Cast folder is in your AddOns directory
   - Or download complete Dominos package

2. **Cast bar is hidden**
   - Solution: `/dominos show cast`

3. **Cast bar has conditional visibility**
   - Solution: Check Show States settings

### "Progress bars (XP/Rep) don't show"

**Causes:**

1. **Dominos_Progress not installed**
   - Solution: Install Dominos_Progress module

2. **Bar is set to wrong mode**
   - Solution: Click the bar to cycle through modes (XP, Rep, Honor, etc.)
   - Make sure you're on a mode that has data (e.g., if max level, XP mode is empty)

3. **Bar is hidden**
   - Solution: `/dominos show exp` or `/dominos show rep`

4. **"Hide at Max Level" is enabled**
   - Solution: Right-click bar → Uncheck "Hide at Max Level"

## Keybinding Issues

### "My keybinds stopped working"

**Common causes:**

1. **Bound to wrong action bar**
   - Check: ESC → Keybindings → Dominos
   - Solution: Verify you've bound the correct action bar
   - Remember: Page 2 = Action Bar 2, Page 3 = Action Bar 3, etc.

2. **Conflicting keybinds**
   - Check: Look for red text in keybinding menu (indicates conflicts)
   - Solution: Remove duplicate bindings

3. **Addon conflict**
   - Cause: Another addon is overriding keybinds
   - Solution: Disable other action bar addons

4. **WoW's Edit House mode** (Retail)
   - Cause: Housing mode disables combat keybinds
   - Solution: Exit Edit House mode

5. **Pet battle UI**
   - Cause: In pet battle, normal keybinds don't work
   - Solution: Expected behavior, exit pet battle

### "I can't bind Mouse Button 4/5"

**Cause**: WoW limitation with some mice.

**Solution**:
- Use mouse software to map MB4/5 to keyboard keys
- Or bind different keys in WoW

### "Keybinds work on one character but not another"

**Cause**: Keybinds are character-specific (or account-wide setting differs).

**Solutions:**

1. **Copy bindings**:
   - At character select: Click "Copy Character Settings"
   - Choose character with working bindings
   - Check "Keybindings"

2. **Re-bind on new character**:
   - Enter binding mode (`/kb`)
   - Bind keys again

3. **Check for character-specific conflicts**

### "Quick binding mode won't activate"

**Causes:**

1. **LibKeyBound not loaded**
   - Solution: Ensure it's in Dominos folder, restart WoW

2. **Another addon using `/kb`**
   - Solution: Use `/dominos bind` instead

3. **In pet battle or vehicle**
   - Solution: Exit special UI first

### "After using paging, my keybinds don't work"

**Cause**: Keybinds are set for Action Bar 1, but paging is showing Action Bar 2 (which has no bindings).

**Solution**:
- **Option 1**: Bind Action Bar 1 only, leave other bars unbound. Paging will make the keys trigger whichever page is showing.
- **Option 2**: Bind each action bar to different keys (e.g., Bar 1 = 1-9, Bar 2 = F1-F9)

See [Paging and Bar States](Paging-and-Bar-States.md) for detailed explanation.

## Visual Issues

### "Buttons look weird/wrong"

**Possible causes:**

1. **Masque skin issue**
   - Solution: Change Masque skin or disable Masque for that bar
   - Right-click bar → Masque section

2. **Missing textures**
   - Solution: Repair WoW installation
   - Or reinstall Dominos

3. **Addon conflict**
   - Solution: Disable other button-modifying addons one at a time

### "Spell glows don't show"

**Cause**: Spell animations disabled.

**Solution**:
- `/dominos` → Check "Show Spell Glows"

### "Cooldown numbers don't show"

**Cause**: That's OmniCC's job, not Dominos.

**Solution**:
- Install OmniCC addon for cooldown numbers
- Or use another cooldown timer addon

### "Macro/keybind text is too small/large"

**Cause**: Bar scaling affects all text.

**Solution**:
- Adjust bar scale: `/dominos scale <bar> <value>`
- Or hide the text: Right-click bar → Uncheck "Binding Text" or "Macro Text"

### "Can't see what's on cooldown when bar is transparent"

**Cause**: Faded opacity too low.

**Solution**:
- Increase faded opacity: `/dominos fade <bar> 0.5` (50% instead of 0%)
- Or keep bar visible in combat: Show States `[combat] show; hide`

### "Action button tooltips show in wrong place"

**Cause**: WoW tooltip positioning, not Dominos.

**Solution**:
- Use a tooltip addon like TipTac to control tooltip position
- Or reposition bars so tooltips don't overlap important areas

### "Bag bar shows bags I don't have"

**Cause**: Empty bag slots are shown.

**Solution**:
- Right-click bag bar in config mode
- Uncheck individual bag slots you want hidden

## Paging and State Issues

### "Bar doesn't change when I shapeshift/change stance"

**Possible causes:**

1. **Paging not configured**
   - Solution: Right-click bar → Paging section → Enable the form/stance state

2. **State not available in current expansion**
   - Example: Warrior stances don't exist in Retail
   - Solution: Verify the state exists in your game version

3. **Paging set to wrong page**
   - Solution: Verify you've set the correct page number
   - Remember to put abilities on that page (Action Bar 2 = Page 2)

4. **Higher priority state overriding**
   - Example: Holding Shift (modifier) overrides Cat Form (class state)
   - Solution: Expected behavior, see state priority in [Paging and Bar States](Paging-and-Bar-States.md)

### "Modifier paging doesn't work"

**Possible causes:**

1. **Modifier paging not enabled**
   - Solution: Right-click bar → Paging → Enable modifier (Shift, Ctrl, Alt)

2. **WoW keybinds using the same modifier**
   - Example: Shift+1 bound to something in WoW keybinds
   - Solution: WoW keybinds take priority, use different modifier or unbind the conflict

3. **Modifier state set to same page as default**
   - Example: Default page 1, Shift page 1 → no visible change
   - Solution: Set Shift to a different page

### "Abilities disappear when paging"

**Cause**: The page you're paging to is empty.

**Solution**:
- Place abilities on the correct action bar
- Page 2 = Action Bar 2, Page 3 = Action Bar 3, etc.
- Check in WoW keybindings interface or use Blizzard action bars temporarily to populate

### "Wrong abilities show when paging"

**Cause**: Paging to incorrect page number.

**Solution**:
- Verify which page has which abilities
- Right-click bar → Paging → Double-check page numbers
- Use `/dominos config` and test each state

### "Target-based paging doesn't work"

**Possible causes:**

1. **Not enabled**
   - Solution: Right-click bar → Paging → Enable target states

2. **Overridden by higher priority state**
   - Example: Cat Form overrides target-based paging
   - Solution: Expected behavior, target states have lowest priority

3. **Targeting wrong unit type**
   - Example: Configured for `[harm]` but targeting friendly
   - Solution: Verify condition matches your target

## Addon Conflicts

### "Dominos buttons don't work with [addon]"

**Generally compatible addons**:
- OmniCC (cooldown timers)
- tullaRange (range coloring)
- AdiButtonAuras (buff tracking)
- Masque (button skins)
- WeakAuras (doesn't conflict)

**Generally incompatible addons**:
- Bartender (both replace action bars)
- ElvUI action bars (disable ElvUI's bars if using Dominos)
- LUI action bars
- Any other action bar replacement

**Solution for conflicts**:
- Disable one of the conflicting addons
- Or disable specific features (e.g., turn off ElvUI action bars, keep rest of ElvUI)

### "ElvUI and Dominos conflict"

**Solution**:
1. Open ElvUI settings
2. ActionBars section
3. Disable ElvUI action bars
4. Keep other ElvUI features

Both addons can coexist if ElvUI's action bars are disabled.

### "Masque skins don't apply"

**Possible causes:**

1. **Masque not installed**
   - Solution: Install Masque addon

2. **No Masque skin selected**
   - Solution: Right-click bar → Masque section → Choose a skin

3. **Skin addon not installed**
   - Solution: Install a Masque skin addon (e.g., Masque: Dream, Masque: Apathy)

4. **Using Dominos button theme**
   - Solution: Masque overrides Dominos theme, ensure Masque is properly configured

### "OmniCC doesn't show on Dominos buttons"

**Cause**: OmniCC not configured to work on action buttons.

**Solution**:
- Check OmniCC settings
- Ensure "Action Buttons" are enabled in OmniCC
- Verify OmniCC is loaded and updated

## Performance and Errors

### "Lua error mentioning Dominos"

**Solutions**:

1. **Update Dominos**
   - Download latest version from CurseForge/WoWInterface
   - Ensure version matches your WoW version (Retail/Classic/etc.)

2. **Disable other addons**
   - Temporarily disable all addons except Dominos
   - Re-enable one at a time to find conflict

3. **Delete saved variables**
   - Warning: Resets all Dominos settings!
   - Delete `WTF/Account/<account>/SavedVariables/Dominos.lua`
   - Restart WoW

4. **Report the error**
   - Copy full error text
   - Report at https://github.com/tullamods/Dominos/issues

### "Dominos causes lag/low FPS"

**Unlikely**: Dominos is very efficient, but possible causes:

1. **Too many bars enabled**
   - Solution: Disable unused bars (`/dominos numbars 6` instead of 14)

2. **Complex fading on many bars**
   - Solution: Reduce number of fading bars

3. **Conflict with another addon**
   - Solution: Disable other addons to test

4. **Corrupted saved variables**
   - Solution: Reset Dominos (delete SavedVariables file)

**More likely**: Another addon is causing the lag, not Dominos.

### "Dominos doesn't load"

**Possible causes:**

1. **Wrong WoW version**
   - Solution: Download correct Dominos version for your game version

2. **Not enabled in addon list**
   - Solution: Character select → AddOns button → Check Dominos and all Dominos_* modules

3. **Corrupted addon files**
   - Solution: Completely delete Dominos folders, reinstall

4. **Outdated**
   - Solution: Update to latest version

### "Interface action blocked error"

**Cause**: Trying to use restricted functions (usually with macros/addons).

**Common scenario**: Automated slash commands in macros during combat.

**Solution**:
- Don't use Dominos slash commands during combat via macros
- Use pre-combat setup macros
- Some actions are restricted by Blizzard during combat

### "After patch, Dominos doesn't work"

**Causes:**

1. **Addon out of date**
   - Solution: Update Dominos to latest version
   - Check if update available for new patch

2. **Blizzard API changes**
   - Solution: Wait for Dominos update
   - Check Dominos GitHub for status

3. **Out of date addon blocking**
   - Solution: Character select → AddOns → Check "Load out of date AddOns"
   - Warning: May cause errors, but often works fine

## Getting More Help

If your issue isn't covered here:

1. **Check the other guides**:
   - [Features](Features.md) - Full feature list
   - [Bar Configuration](Bar-Configuration.md) - Layout and positioning
   - [Paging and Bar States](Paging-and-Bar-States.md) - Form/stance switching
   - [Visibility and Fading](Visibility-and-Fading.md) - Show/hide options
   - [Slash Commands](Slash-Commands.md) - Command reference

2. **Search existing issues**:
   - https://github.com/tullamods/Dominos/issues
   - Your problem may already be reported/solved

3. **Ask for help**:
   - **GitHub Issues**: Report bugs or ask questions
   - **WoW Forums**: Community help
   - **Discord servers**: Addon community servers often have Dominos users

4. **Include details when asking**:
   - WoW version (Retail/Classic/Wrath/etc.)
   - Dominos version
   - What you were trying to do
   - What actually happened
   - Any error messages (full text)
   - List of other installed addons

## Quick Troubleshooting Checklist

When something doesn't work, try these steps in order:

1. ☐ Enter config mode (`/dominos config`) to verify bar exists and is positioned correctly
2. ☐ Check visibility: `/dominos show <bar>`
3. ☐ Check opacity: `/dominos setalpha <bar> 1`
4. ☐ Check scale: `/dominos scale <bar> 1`
5. ☐ Verify Dominos is updated to latest version for your WoW version
6. ☐ Disable other action bar addons
7. ☐ Test with all other addons disabled
8. ☐ Check for Lua errors (install BugSack addon to catch errors)
9. ☐ Create new profile to test: `/dominos save testprofile`
10. ☐ As last resort: Delete saved variables and reconfigure

If none of these help, report the issue with full details!
