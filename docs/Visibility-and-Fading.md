# Visibility and Fading

This guide covers how to control when bars appear, how they fade in and out, and how to create a clean, minimal interface that only shows what you need when you need it.

## Table of Contents

- [Visibility Options](#visibility-options)
- [Opacity and Fading](#opacity-and-fading)
- [Conditional Visibility](#conditional-visibility)
- [Special UI States](#special-ui-states)
- [Common Setups](#common-setups)
- [Advanced Techniques](#advanced-techniques)

## Visibility Options

### Show/Hide Toggle

The simplest visibility option: is the bar shown or hidden?

**How to configure:**
- Right-click bar in configuration mode → Check/uncheck "Show" (usually at the top)
- Command: `/dominos show <bar>` or `/dominos hide <bar>`
- Toggle: `/dominos toggle <bar>`

**Examples:**
```
/dominos hide bags         -- Hide the bag bar
/dominos show pet          -- Show the pet bar
/dominos toggle menu       -- Toggle menu bar on/off
```

**Use cases:**
- Temporarily hide bars you don't need for current content
- Disable bars entirely (like extra action bars 10-14)
- Quick toggle for screenshots

### Click Through

Make a bar non-interactive while keeping it visible.

**What it does:**
- Bar is visible on screen
- Mouse clicks pass through to targets/terrain below
- Cannot click buttons or interact with bar
- Useful for reference bars or cooldown tracking

**How to configure:**
- Right-click bar → Advanced → Check "Click Through"

**Use cases:**
- Show cooldowns but prevent accidental clicks
- Display information bars (like extra action bar) without interference
- Create non-interactive cooldown tracker displays

## Opacity and Fading

Opacity controls how transparent a bar appears. Fading creates smooth transitions between opacity levels.

### Base Opacity

**What it is**: How visible the bar is when "active" (moused over or not faded)

**Range**: 0% to 100%
- 0% = Completely invisible
- 50% = Half transparent
- 100% = Fully opaque

**How to configure:**
- Right-click bar → Opacity slider
- Command: `/dominos setalpha <bar> <opacity>`
  - Example: `/dominos setalpha 1 0.8` (80% opacity)

**Use cases:**
- Reduce visual clutter (80-90% opacity)
- Create subtle background bars (40-60%)
- Keep bars visible but de-emphasized (70%)

### Faded Opacity

**What it is**: How visible the bar is when "faded" (mouse not over it, after fade out delay)

**Range**: 0% to 100%

**How to configure:**
- Right-click bar → Faded Opacity slider
- Command: `/dominos fade <bar> <opacity>`
  - Example: `/dominos fade 1 0` (fade to invisible)

**Common patterns:**
- **Fade to invisible**: Base 100%, Faded 0%
- **Subtle fade**: Base 100%, Faded 50%
- **Minimal fade**: Base 90%, Faded 70%
- **No fade**: Base 100%, Faded 100%

### Fade In Settings

Controls how the bar appears when you mouse over it or it becomes active.

**Fade In Delay**: How long to wait before starting the fade in
- Range: 0 to 10 seconds
- Default: 0 seconds (immediate)
- Use case: Delay prevents accidental triggers when mousing across screen

**Fade In Duration**: How long the fade in animation takes
- Range: 0.1 to 10 seconds
- Default: ~0.3 seconds
- Shorter = snappy response
- Longer = smooth, gradual appearance

**How to configure:**
- Right-click bar → Fade In section
- Adjust Delay and Duration sliders

### Fade Out Settings

Controls how the bar disappears when you move your mouse away.

**Fade Out Delay**: How long to wait before starting the fade out
- Range: 0 to 10 seconds
- Default: ~0.5 seconds
- Common values:
  - 0.5s = Quick fade for active bars
  - 2s = Moderate delay for reference
  - 5s+ = Long visibility after interaction

**Fade Out Duration**: How long the fade out animation takes
- Range: 0.1 to 10 seconds
- Default: ~0.3 seconds
- Usually matches fade in duration

**How to configure:**
- Right-click bar → Fade Out section
- Adjust Delay and Duration sliders

### Linked Opacity

**What it does**: Anchored bars share the parent bar's opacity state

**How it works:**
- Bar A is anchored to Bar B
- When you mouse over Bar B, both bars fade in
- When you move away, both fade out together
- Treats anchored bars as a single unit

**How to enable:**
- `/dominos` main menu → Check "Linked Opacity"
- Global setting that affects all anchored bars

**Use cases:**
- Create bar groups that fade together
- Main bar + modifier bars
- Stacked bars that should appear as one unit

**Example:**
```
Bar 1: Main action bar (100% base, 0% faded)
Bar 2: Anchored above Bar 1 (100% base, 0% faded)
Bar 3: Anchored above Bar 2 (100% base, 0% faded)

With Linked Opacity enabled:
- Mouse over any bar → all three fade in
- Mouse away from all bars → all three fade out together
```

## Conditional Visibility

Control when bars appear using WoW macro conditionals.

### Show States

**What it is**: A text field where you specify conditions for showing the bar

**Format**: Standard WoW macro conditional syntax
- Same conditionals used in `/cast` macros
- Multiple conditions can be combined

**Access**: Right-click bar → Show States field (usually near visibility options)

### Common Conditional Expressions

**Combat-based:**
```
[combat]          -- Show only in combat
[nocombat]        -- Show only out of combat
```

**Modifier-based:**
```
[mod:shift]       -- Show only when holding Shift
[mod:ctrl]        -- Show only when holding Ctrl
[mod:alt]         -- Show only when holding Alt
[nomod]           -- Show only when no modifiers held
```

**Target-based:**
```
[help]            -- Show when targeting friendly unit
[harm]            -- Show when targeting enemy
[exists]          -- Show when any target exists
[noexists]        -- Show when no target exists
```

**Stance/Form-based:**
```
[stance:1]        -- Show in stance/form 1
[stance:2]        -- Show in stance/form 2
[form:1]          -- Same as stance (alternate syntax)
[noform]          -- Show when not in any form
```

**Stealth-based:**
```
[stealth]         -- Show when stealthed
[nostealth]       -- Show when not stealthed
```

**Other useful conditionals:**
```
[mounted]         -- Show when mounted
[nomounted]       -- Show when not mounted
[swimming]        -- Show when swimming
[flyable]         -- Show in flyable areas
[indoors]         -- Show indoors
[outdoors]        -- Show outdoors
```

### Combining Conditions

Use multiple conditions for complex visibility:

**AND logic (comma-separated):**
```
[combat,harm]     -- Show in combat AND targeting enemy
[nomod,nocombat]  -- Show when no modifier AND not in combat
```

**OR logic (separate brackets):**
```
[combat][harm]    -- Show in combat OR targeting enemy
[mod:shift][stealth] -- Show when Shift held OR stealthed
```

**With explicit show/hide:**
```
show              -- Show unconditionally (default if condition met)
hide              -- Hide unconditionally
```

### Examples

**Combat-only bar:**
```
Show States: [combat] show; hide
```
Bar appears only in combat, hidden out of combat.

**Out-of-combat utilities:**
```
Show States: [nocombat] show; hide
```
Show mounts, food, etc. only out of combat.

**Shift-reveal bar:**
```
Show States: [mod:shift] show; hide
```
Completely hidden until Shift is held.

**Stealth abilities:**
```
Show States: [stealth] show; hide
```
Show only when stealthed (Rogue/Druid stealth bar).

**Friendly/hostile switching:**
```
Bar 1 Show States: [harm] show; hide     -- DPS bar for enemies
Bar 2 Show States: [help] show; hide     -- Heal bar for friends
```

**Moonkin/Caster separation:**
```
Show States: [form:4] show; hide         -- Moonkin only (form 4)
```
```
Show States: [noform] show; hide         -- Caster only (no form)
```

**Complex example (Druid):**
```
Show States: [noform,nocombat] show; [form:1,combat] show; hide
```
Show when: (in caster form AND out of combat) OR (in Bear form AND in combat)

## Special UI States

### Override UI

**What it is**: The vehicle/possess interface

**When it appears:**
- Entering vehicles (tanks, siege engines, etc.)
- Possessing NPCs
- Mind Control
- Any time the default UI is "overridden"

**Configuration option**: "Override UI"
- Show: Bar visible during override UI
- Hide: Bar hidden during override UI

**Common settings:**
- Action bars: Usually shown (need abilities in vehicles)
- Pet bar: Usually shown (pet bar often becomes vehicle bar)
- Utility bars (bags, menu): Usually hidden (not needed in vehicles)

**How to configure:**
- Right-click bar → "Override UI" dropdown → Show/Hide

### Pet Battle UI

**What it is**: The interface during pet battles

**Configuration option**: "Pet Battle UI"
- Show: Bar visible during pet battles
- Hide: Bar hidden during pet battles

**Common settings:**
- Most bars: Hidden (pet battle has its own UI)
- Utility bars (bags, menu): Can show if desired
- Exit button bars: Often shown to keep pet battle exit accessible

**How to configure:**
- Right-click bar → "Pet Battle UI" dropdown → Show/Hide

## Common Setups

### Minimal Interface (Fade to Transparent)

**Goal**: Bars invisible until needed, appear on mouse-over

**Configuration per bar:**
- Base Opacity: 100%
- Faded Opacity: 0%
- Fade Out Delay: 0.5-1 seconds
- Fade Out Duration: 0.3 seconds
- Fade In Delay: 0 seconds
- Fade In Duration: 0.3 seconds
- Enable Linked Opacity (if using anchored bars)

**Result**: Clean screen until you mouse over, then bars appear smoothly.

**Recommended for:**
- Action bars you rarely look at (know your rotation by muscle memory)
- Secondary bars (utilities, cooldowns)
- Pet bar (you don't need to see it constantly)

### Semi-Transparent Always Visible

**Goal**: Bars always visible but not distracting

**Configuration per bar:**
- Base Opacity: 80-90%
- Faded Opacity: 80-90% (same as base)
- No fading (or very subtle)

**Result**: Constant visibility without full opacity distraction.

**Recommended for:**
- Main action bar (need to see cooldowns)
- Class/stance bar (important to see current form)
- Cast bar (need timing feedback)

### Combat-Based Visibility

**Goal**: Bars appear in combat, hidden out of combat

**Configuration:**
- Show States: `[combat] show; hide`
- Can combine with opacity fading for extra smoothness

**Result**: Ultra-clean out of combat, functional in combat.

**Recommended for:**
- Secondary DPS bars
- Cooldown tracking bars
- Pet bar (if you only use pet in combat)

**Enhancement**: Combine with high fade out delay (5-10s) so bars stay visible briefly after leaving combat.

### Modifier-Reveal Bars

**Goal**: Completely hidden bars that appear on key press

**Configuration:**
- Show States: `[mod:shift] show; hide` (or your chosen modifier)
- Base Opacity: 100%
- Faded Opacity: Can be anything (bar is hidden, not faded)

**Result**: Screen space saved, instant access when needed.

**Recommended for:**
- Consumables bar (food, potions)
- Mount bar
- Toy/utility bar
- Profession bars

**Alternative**: Use paging instead (covered in [Paging and Bar States](Paging-and-Bar-States.md))

### Layered Fading (Stacked Bars)

**Goal**: Multiple bars with different fade levels

**Example setup:**
```
Bar 1 (primary): Base 100%, Faded 80%
Bar 2 (secondary): Base 100%, Faded 50%
Bar 3 (tertiary): Base 100%, Faded 20%
```

**With Linked Opacity disabled**: Each bar fades independently based on mouse position.

**Result**: Visual hierarchy - important bars more visible, less important bars more faded.

### Always-Visible Utilities

**Goal**: Keep certain bars always fully visible

**Configuration:**
- Base Opacity: 100%
- Faded Opacity: 100%
- No fading needed

**Recommended for:**
- Menu bar (always need access to UI)
- Bag bar (frequently accessed)
- Stance/class bar (need to see current form)
- Any bar with important information display

## Advanced Techniques

### Conditional Opacity via Weakauras

**Limitation**: Dominos opacity settings are static (don't change based on conditions)

**Workaround**: Use WeakAuras to dynamically hide/show Dominos bars
- WeakAuras can track complex conditions
- Use WeakAuras to run `/dominos show <bar>` or `/dominos hide <bar>`

**Example**: Hide DPS bars when in healer spec
1. Create WeakAura that detects spec change
2. On spec change to healer: run `/dominos hide 1-3`
3. On spec change to DPS: run `/dominos show 1-3`

### Profile-Based Visibility

**Use case**: Different bar visibility for different characters/specs

**How:**
1. Create separate profiles for different situations
2. Configure visibility differently per profile
3. Switch profiles as needed (`/dominos set <profile>`)

**Example profiles:**
- **Raid Profile**: Combat bars always visible, utilities hidden
- **Solo Profile**: More bars visible for flexibility
- **Screenshot Profile**: All bars hidden

### Zone-Based Visibility with Macros

**Goal**: Show/hide bars based on zone

**Method**: Create macro buttons that adjust visibility

**Example macro for PvP zone:**
```
/dominos show 1-3    -- Show PvP action bars
/dominos hide 4-6    -- Hide PvE bars
```

**Example macro for raiding:**
```
/dominos show 1-5    -- Show main rotation bars
/dominos hide 6-8    -- Hide solo utility bars
```

Place these macros on a hidden utility bar, bind to keys, and press when entering zones.

### Padding for Fade Area

**Technique**: Increase bar padding to create larger mouse-over area

**Why**: With high padding and low faded opacity, you can mouse near the bar to reveal it

**Configuration:**
- Padding: 10-20 pixels
- Faded Opacity: 0% or very low
- Base Opacity: 100%

**Result**: Bar has invisible "aura" around it that triggers fade-in.

**Use case**: Bars at screen edges - mouse to edge to reveal without mousing directly over buttons.

### Staggered Fade Delays

**Technique**: Different fade delays for different bars

**Why**: Create sequential fading effect

**Example:**
```
Bar 1: Fade Out Delay 1 second
Bar 2: Fade Out Delay 2 seconds
Bar 3: Fade Out Delay 3 seconds
```

**Result**: After mousing away, bars fade one at a time instead of all at once.

**Effect**: More dynamic, attention-grabbing animation (may be too much for some users).

### Hide Empty Buttons for Cleaner Fading

**Combine**: Empty button hiding + fading

**Configuration:**
1. Right-click bar → Uncheck "Empty Buttons"
2. Set up fading as desired

**Result**: Bars shrink to only show assigned abilities, then fade when not in use.

**Great for:**
- Cooldown bars (few buttons, lots of empty space)
- Situational bars (only some slots filled)
- Pet bar (pets with fewer than 10 abilities)

## Troubleshooting

### Bar Won't Fade

**Possible causes:**
- Base Opacity and Faded Opacity are the same (no difference to fade between)
- Fade duration set to 0 (instant change, not smooth fade)
- Mouse is still over the bar or linked bar

**Solution:**
- Ensure Base and Faded opacity are different
- Set fade duration to at least 0.3 seconds
- Move mouse completely away from bar

### Bar Fades at Wrong Time

**Causes:**
- Fade delay too short or too long
- Linked opacity enabled and mousing over anchored bars

**Solution:**
- Adjust fade out delay (longer delay = bar stays visible longer)
- Disable linked opacity if you don't want bars to fade together

### Bar Is Invisible

**Possible causes:**
- Both Base and Faded opacity set to 0%
- Show States hiding the bar
- Bar is hidden (Show option unchecked)
- Bar is behind other UI elements (Display Layer too low)

**Solution:**
- Check opacity settings - set Base to 100%
- Clear Show States field or check conditions
- `/dominos show <bar>` to unhide
- Increase Display Layer to HIGH

### Show States Not Working

**Causes:**
- Syntax error in conditional
- Condition never met (e.g., `[stance:5]` when you only have 3 stances)
- Conflicting conditions

**Solution:**
- Double-check syntax against macro conditional documentation
- Test condition in a regular macro first (`/cast [harm] Fireball`)
- Try simple conditions first, add complexity gradually
- Clear field entirely to reset (`show` = always visible)

### Bars Fade Together When They Shouldn't

**Cause:**
- Linked Opacity is enabled
- Bars are anchored to each other

**Solution:**
- Disable Linked Opacity in `/dominos` main settings
- Or break the anchor between bars if they shouldn't be linked

### Click Through Not Working

**Cause:**
- Bar has visible padding or background that still catches clicks
- Some addons override click behavior

**Solution:**
- Reduce padding to 0
- Check for conflicting addons
- Ensure Click Through is actually checked in bar settings

### Fade Timing Feels Wrong

**Too fast/instant:**
- Increase fade duration (try 0.5-1.0 seconds)

**Too slow/sluggish:**
- Decrease fade duration (try 0.1-0.3 seconds)
- Reduce fade delay

**Triggers too easily:**
- Increase fade in delay (0.1-0.3s prevents accidental triggers)

**Stays visible too long:**
- Reduce fade out delay

## Quick Reference

### Typical Opacity Settings

**Always visible, no fading:**
- Base: 100%, Faded: 100%

**Fade to invisible:**
- Base: 100%, Faded: 0%

**Subtle fade:**
- Base: 100%, Faded: 60-80%

**Always semi-transparent:**
- Base: 80-90%, Faded: 80-90%

### Typical Fade Timing

**Snappy/responsive:**
- Fade In: Delay 0s, Duration 0.2s
- Fade Out: Delay 0.5s, Duration 0.2s

**Smooth/gradual:**
- Fade In: Delay 0.1s, Duration 0.5s
- Fade Out: Delay 1s, Duration 0.5s

**Lazy/delayed:**
- Fade In: Delay 0.2s, Duration 0.3s
- Fade Out: Delay 3-5s, Duration 1s

### Common Show States

```
[combat] show; hide              -- Combat only
[nocombat] show; hide            -- Out of combat only
[mod:shift] show; hide           -- Shift to reveal
[harm] show; hide                -- Hostile target only
[help] show; hide                -- Friendly target only
[stealth] show; hide             -- Stealth only
[combat][harm] show; hide        -- Combat OR hostile target
[nocombat,nomod] show; hide      -- Out of combat AND no modifiers
```

---

For information on bar paging, see [Paging and Bar States](Paging-and-Bar-States.md).

For layout and positioning help, see [Bar Configuration](Bar-Configuration.md).
