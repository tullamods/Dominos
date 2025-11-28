# Paging and Bar States

Action bar paging is one of Dominos' most powerful features, allowing your bars to automatically change what abilities they display based on your character's state. This guide explains how paging works and how to configure it.

## Table of Contents

- [What is Bar Paging?](#what-is-bar-paging)
- [Understanding Bar States](#understanding-bar-states)
- [Types of Bar States](#types-of-bar-states)
- [Configuring Paging](#configuring-paging)
- [Common Paging Setups](#common-paging-setups)
- [Advanced Paging](#advanced-paging)

## What is Bar Paging?

**Bar paging** is the ability to automatically swap which set of 12 abilities appears on a bar based on conditions like:
- Your current stance or form (Warrior stances, Druid forms)
- What modifier keys you're holding (Shift, Ctrl, Alt)
- Your current target type (friendly, hostile, no target)
- What you have equipped (shield)
- Your current class abilities (Stealth, Shadowform)

### Why Use Paging?

**Access more abilities**: Instead of having 12 buttons per bar, paging lets you access 24, 36, or more abilities on the same screen space.

**Contextual abilities**: Automatically show the right abilities for your current situation:
- Druid in Bear form sees tanking abilities
- Druid in Cat form sees DPS abilities
- Warrior in Defensive Stance sees defensive cooldowns
- Holding Shift shows consumables or alternate rotations

### How It Works

World of Warcraft has multiple "action bar pages" (numbered 1-6 by default). Paging tells the game which page to display based on conditions.

**Example**: Without paging, your bar always shows Page 1.
With paging configured:
- Default state: Show Page 1 (normal abilities)
- Bear Form: Show Page 2 (tanking abilities)
- Cat Form: Show Page 3 (DPS abilities)

## Understanding Bar States

**Bar states** are the conditions that trigger paging. Dominos organizes states into several categories.

### State Priority

States are evaluated in this order (first match wins):

1. **Modifier** - Keyboard modifiers (Ctrl, Alt, Shift, etc.)
2. **Page** - Manual quick paging (action bar 2-6)
3. **Class** - Class-specific states (forms, stances, abilities)
4. **Race** - Race-specific states (Shadowmeld for Night Elves)
5. **Target** - Target-based states (friendly, hostile, none)

**Important**: Higher priority states override lower ones. For example, if you configure both "Cat Form → Page 3" and "Shift → Page 2", holding Shift while in Cat Form will show Page 2 (modifier has higher priority).

### Page vs State

**Confusion point**: The terms "page" and "state" are related but different:

- **Page**: Which set of 12 abilities to display (Page 1, Page 2, etc.)
- **State**: The condition that determines which page to show (Cat Form, Shift, etc.)

You configure states to map to pages.

## Types of Bar States

### Modifier States

Modifier states trigger when you hold specific keyboard keys.

**Available Modifiers:**
- **Self-cast modifier** - Your configured self-cast key
- **Shift**
- **Ctrl** (Control)
- **Alt**
- **Meta** (Windows key on PC, Command on Mac)

**Modifier Combinations:**
- Ctrl+Alt
- Ctrl+Shift
- Alt+Shift

**How to configure:**
1. Right-click bar in configuration mode
2. Go to "Paging" section
3. Enable desired modifier(s)
4. Set which page to show when held

**Example Use Cases:**
- Shift: Show consumables (food, potions, flasks)
- Ctrl: Show alternate rotation or cooldowns
- Alt: Show utility abilities (mounts, toys)
- Ctrl+Shift: Show profession abilities

### Quick Paging (Manual Pages)

Quick paging lets you manually switch between pages, similar to the default Blizzard action bar paging.

**Available Pages**: 2, 3, 4, 5, 6
- Corresponds to Action Bar 2, 3, 4, 5, 6 in the default UI

**How to configure:**
Enable the pages you want available in the Paging section of bar settings.

**How to use:**
- By default, no keybinds are set
- Bind keys in Key Bindings → Dominos → "Quick Page #"
- Pressing the bound key switches the bar to that page
- Pressing again switches back to default state

**Example**:
- Bind Shift+1 to "Quick Page 2"
- Press Shift+1 to show Action Bar 2's abilities
- Press Shift+1 again to return to normal

### Class-Specific States

These states automatically trigger based on class mechanics like forms, stances, and auras.

#### Druid Forms

- **Bear Form** - Guardian tanking
- **Cat Form** - Feral DPS
- **Prowl** - Stealth while in Cat Form
- **Moonkin Form** - Balance DPS
- **Travel Form** - Ground travel
- **Stag Form** - Mount speed ground travel
- **Aquatic Form** - Swimming
- **Flight Form** - Flying (includes Swift Flight)
- **Tree of Life** - Restoration healing (if talented)
- **Dragonriding** - Retail dragonriding

**Common Druid Setup:**
- Default (Caster): Page 1
- Bear Form: Page 2
- Cat Form: Page 3
- Moonkin Form: Page 4

#### Warrior Stances

- **Battle Stance** - DPS stance (Classic/TBC/Wrath)
- **Defensive Stance** - Tanking stance
- **Berserker Stance** - Rage generation
- **Shield Equipped** - When wearing a shield

**Common Warrior Setup (Classic/Wrath):**
- Battle Stance: Page 1
- Defensive Stance: Page 2
- Berserker Stance: Page 3

**Retail Note**: Retail Warriors don't have stances, but can use Shield Equipped state.

#### Paladin States

- **Auras** (Classic/TBC/Wrath):
  - Devotion Aura
  - Retribution Aura
  - Concentration Aura
  - Crusader Aura
- **Shield Equipped** - When wearing a shield

#### Rogue States

- **Stealth** - In stealth mode
- **Shadow Dance** - Shadow Dance ability active

**Common Rogue Setup:**
- Default: Page 1 (normal rotation)
- Stealth: Page 2 (opener abilities)

#### Priest States

- **Shadowform** - Shadow Priest form active

#### Death Knight Presences (Wrath/Cata)

- **Blood Presence** - Tanking presence
- **Frost Presence** - Tank/PvP presence
- **Unholy Presence** - DPS presence

**Retail Note**: Presences removed in later expansions.

#### Hunter Aspects (Wrath/Cata)

- **Aspect of the Hawk/Dragonhawk** - DPS aspect
- **Aspect of the Viper** - Mana regen
- **Aspect of the Monkey** - Melee defense

**Retail Note**: Aspects removed in later expansions.

#### Warlock States (Wrath/Cata)

- **Metamorphosis** - Demon form

#### Evoker States (Retail)

- **Soar** - Flying ability

### Race-Specific States

- **Shadowmeld (Night Elf)** - Currently shadowmelded

**Use case**: Show different abilities while stealthed via Shadowmeld.

### Target-Based States

Change your bar based on your current target:

- **Help** - Friendly target selected
- **Harm** - Hostile target selected
- **No Target** - No target selected

**Example Use Cases:**
- **Harm**: Show DPS rotation
- **Help**: Show healing/support abilities
- **No Target**: Show buffs/preparation abilities

**Priority Note**: Target states have the lowest priority, so they're overridden by stances, forms, and modifiers.

## Configuring Paging

### Basic Configuration

1. **Enter Configuration Mode**
   - `/dominos config` or left-click minimap button

2. **Open Bar Settings**
   - Right-click the action bar you want to configure

3. **Navigate to Paging Section**
   - Find the "Paging" section in the context menu

4. **Enable States**
   - Check the boxes for states you want to use
   - Each state lets you select which page to show
   - Page numbers correspond to action bar pages (1-6)

5. **Set Page Numbers**
   - For each enabled state, choose which page to display
   - Pages correspond to the 12-button action bars in your keybindings

6. **Test It**
   - Exit configuration mode
   - Try triggering the states (change forms, hold modifiers, etc.)
   - Verify the correct abilities appear

### Understanding Page Numbers

**Page 1**: Default action bar (visible in keybindings as "Action Bar 1")
**Page 2**: Action Bar 2 buttons
**Page 3**: Action Bar 3 buttons
**Page 4**: Action Bar 4 buttons
**Page 5**: Action Bar 5 buttons
**Page 6**: Action Bar 6 buttons

When you set "Cat Form: Page 3", you're telling the bar to show the buttons from Action Bar 3 when you're in Cat Form.

### Setting Up Keybindings

**Important**: Don't bind the same keys to multiple action bars!

**Wrong approach:**
- Bind 1, 2, 3, 4 to Action Bar 1
- Bind 1, 2, 3, 4 to Action Bar 2
- This creates conflicts

**Correct approach:**
- Bind 1, 2, 3, 4 to Action Bar 1 (Page 1)
- Bind F1, F2, F3, F4 to Action Bar 2 (Page 2)
- Configure paging so Bar 1 shows Page 2 in Cat Form
- Now pressing 1, 2, 3, 4 activates buttons from Page 2 when in Cat Form

**OR use the same keys** (common for forms/stances):
- Bind 1, 2, 3, 4 to Action Bar 1
- Place Cat abilities on Action Bar 3, slot by slot matching Bar 1
- Configure Bar 1 to show Page 3 in Cat Form
- Now 1, 2, 3, 4 work in both forms, showing different abilities

## Common Paging Setups

### Druid Multi-Form Setup

**Goal**: One bar that shows appropriate abilities for each form

**Configuration:**
1. Bar 1 (Main bar):
   - Default/Caster: Page 1
   - Bear Form: Page 2
   - Cat Form: Page 3
   - Moonkin Form: Page 4

2. Keybindings:
   - Action Bar 1: 1, 2, 3, 4, 5, 6, etc.
   - Don't bind Action Bars 2-4 (or use different keys)

3. Place abilities:
   - Page 1 (Action Bar 1): Resto/Balance caster spells
   - Page 2 (Action Bar 2): Bear tanking abilities
   - Page 3 (Action Bar 3): Cat DPS abilities
   - Page 4 (Action Bar 4): Moonkin Balance abilities

**Result**: Pressing 1-9 always activates the right ability for your current form.

### Warrior Stance Setup (Classic/Wrath)

**Goal**: Main bar changes with stance

**Configuration:**
1. Bar 1:
   - Battle Stance: Page 1
   - Defensive Stance: Page 2
   - Berserker Stance: Page 3

2. Keybindings:
   - Action Bar 1: 1-9
   - Leave Action Bars 2-3 unbound

3. Place abilities:
   - Page 1: Battle abilities (Mortal Strike, Overpower)
   - Page 2: Defensive abilities (Shield Block, Shield Slam)
   - Page 3: Berserker abilities (Whirlwind, Execute)

### Rogue Stealth Setup

**Goal**: Show openers in stealth, normal rotation outside

**Configuration:**
1. Bar 1:
   - Default: Page 1
   - Stealth: Page 2

2. Place abilities:
   - Page 1: Normal rotation (Sinister Strike, Eviscerate)
   - Page 2: Openers (Ambush, Cheap Shot, Garrote)

**Result**: Bar automatically switches when entering stealth.

### Modifier-Based Consumables

**Goal**: Hold Shift to see consumables/utility

**Configuration:**
1. Bar 1:
   - Default: Page 1 (normal abilities)
   - Shift: Page 2 (consumables)

2. Place abilities:
   - Page 1: Main rotation
   - Page 2: Potions, food, flasks, toys, mounts

**Result**: Hold Shift to access consumables without changing your main bar.

### Healer Target-Based Setup

**Goal**: Show heals on friendly targets, DPS on enemies

**Configuration:**
1. Bar 1:
   - Harm (hostile): Page 1 (DPS abilities)
   - Help (friendly): Page 2 (healing abilities)

2. Place abilities:
   - Page 1: Damage spells
   - Page 2: Healing spells

**Limitation**: Target-based paging has low priority, so modifiers/forms will override it.

### Combined Modifier + Class State

**Goal**: Multiple paging layers

**Example Druid Setup:**
1. Bar 1:
   - Shift: Page 5 (consumables - works in all forms)
   - Bear Form: Page 2 (tanking)
   - Cat Form: Page 3 (DPS)
   - Moonkin: Page 4 (Balance)
   - Default: Page 1 (caster)

**How it works:**
- In Cat Form: Shows Page 3 (Cat abilities)
- In Cat Form + holding Shift: Shows Page 5 (consumables)
- In Caster form + holding Shift: Shows Page 5 (consumables)

Modifiers always take priority over forms.

## Advanced Paging

### Custom State Conditions

**Advanced users** can manually edit state conditions using macro conditionals.

**Access**: Right-click bar → Paging → at the bottom is a text field for custom conditions

**Format**: `[condition] page; [condition] page; default_page`

**Example custom condition:**
```
[mod:shift,mod:ctrl] 5; [mod:shift] 2; [stance:1] 3; [stance:2] 4; 1
```

This reads as:
- If Shift+Ctrl held: Show page 5
- If Shift held: Show page 2
- If in stance 1: Show page 3
- If in stance 2: Show page 4
- Otherwise: Show page 1

**Macro Conditionals**: See [WoW Macro Conditionals](https://warcraft.wiki.gg/wiki/Macro_conditionals) for all available conditions.

### Override Bar

**What it is**: Special bar that appears when you enter vehicles, possess NPCs, or use mind control.

**Configuration:**
- Right-click bar → "Override Bar" dropdown
- Choose which action bar to use as the override bar
- Default is usually Action Bar 1

**Use case**: Set a specific bar (like Action Bar 14) as override bar to keep it separate from your normal rotation.

### State Precedence Customization

**What it is**: Advanced Lua configuration to change state evaluation order.

**Default order**:
1. Modifier
2. Page
3. Class
4. Race
5. Target

**When to change**: Rarely needed, but you could make target states higher priority than class states if desired.

**How**: Requires editing Lua files - beyond scope of normal configuration.

### Per-Spec Paging (Retail)

**Goal**: Different paging rules for different specs

**How**:
- Use Dominos profiles feature
- Create separate profiles for each spec
- Configure different paging per profile
- Use automatic profile switching (LibDualSpec)

**Example**:
- Balance Druid profile: Moonkin Form → Page 1 (don't need separate page)
- Feral Druid profile: Bear Form → Page 2, Cat Form → Page 3

## Tips and Best Practices

### Start Simple

Don't try to configure all states at once:
1. Start with just one or two forms/stances
2. Test thoroughly
3. Add more states as needed
4. Many players only use 2-3 pages total

### Label Your Pages

Keep notes on which page is for what:
- Page 1: Caster/default
- Page 2: Bear Form
- Page 3: Cat Form
- etc.

This helps when placing abilities and troubleshooting.

### Use Consistent Keybinds

If possible, use the same keybinds across pages:
- 1-9 on Action Bar 1 (Page 1)
- Don't bind Action Bars 2-6
- Use paging to swap what 1-9 do

This creates muscle memory - "1 is always my main attack" even if that ability changes by form.

### Test Before Combat

Enter configuration mode and test all your states:
- Change forms
- Hold modifiers
- Change targets
- Verify correct abilities show

Don't discover paging issues in a raid!

### Backup Your Profile

Before making major paging changes:
1. `/dominos save backup`
2. Make changes
3. If something breaks: `/dominos set backup`

### Consider Bar Count

Paging uses multiple action bars' worth of buttons:
- 1 page = 12 buttons (1 action bar)
- 2 pages = 24 buttons (2 action bars)
- 4 pages = 48 buttons (4 action bars)

Make sure you have enough action bars enabled:
- `/dominos numbars <count>`
- Default is 10, maximum is 14

## Troubleshooting

**Bar doesn't change when expected**
- Check state priority - modifiers override forms
- Verify the state is enabled in paging configuration
- Check you're testing the correct bar (multiple bars can page independently)

**Wrong page showing**
- Review all enabled states - an unexpected one might be active
- Check custom state conditions for typos
- Disable all states and re-enable one at a time

**Keybinds not working after paging**
- Verify you've bound the correct action bar in WoW keybindings
- Check you haven't bound the same key to multiple action bars
- Remember: Page 2 = Action Bar 2, Page 3 = Action Bar 3, etc.

**Abilities disappearing**
- You're paging to an empty page
- Place abilities on the appropriate action bar (Page 2 = Action Bar 2)
- Check which page the state is configured to show

**Modifier paging conflicts**
- Can't use the same modifier for different bars
- If Shift is configured on Bar 1, it affects all bars unless they have different Shift settings
- Use different modifiers for different bars

**Form/stance not detected**
- Ensure you're on the correct WoW version (some forms are expansion-specific)
- Verify the form is available to your spec
- Check if the form requires a talent

---

For more information on bar visibility conditions, see [Visibility and Fading](Visibility-and-Fading.md).

For keybinding help, see the [FAQ and Troubleshooting](FAQ-and-Troubleshooting.md) guide.
