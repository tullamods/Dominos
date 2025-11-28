# Slash Commands

Dominos provides extensive slash commands for configuration, automation, and macro integration. This reference covers all available commands with examples.

## Table of Contents

- [Basic Syntax](#basic-syntax)
- [Configuration Commands](#configuration-commands)
- [Layout Commands](#layout-commands)
- [Appearance Commands](#appearance-commands)
- [Visibility Commands](#visibility-commands)
- [Profile Commands](#profile-commands)
- [Bar Identifiers](#bar-identifiers)
- [Examples and Use Cases](#examples-and-use-cases)

## Basic Syntax

### Command Prefix

All Dominos commands use one of these prefixes:
- `/dominos` (full command)
- `/dom` (short alias)

Both work identically. Examples use `/dominos` for clarity.

### Value Ranges

When commands accept numeric values, they often support:
- **Single value**: `/dominos scale 1 0.9` (set bar 1 to 90%)
- **Range**: `/dominos scale 1-5 0.9` (set bars 1 through 5 to 90%)
- **All**: `/dominos scale all 0.9` (set all bars to 90%)

## Configuration Commands

### General Settings

**Open Options Menu**
```
/dominos
/dom
```
Opens the main Dominos configuration panel.

**Toggle Configuration Mode**
```
/dominos config
/dominos lock
```
Enters/exits configuration mode for repositioning bars.
- In config mode: bars are draggable, show outlines
- Out of config mode: bars are locked in place

**Toggle Binding Mode**
```
/dominos bind
/kb
```
Enters/exits LibKeyBound quick binding mode.
- Hover over buttons and press keys to bind
- Works the same as the standard `/kb` command

### Action Bar Count

**Set Number of Action Bars**
```
/dominos numbars <count>
```
Sets how many action bars are available (1-14).

**Examples:**
```
/dominos numbars 10    -- Use 10 action bars (default)
/dominos numbars 14    -- Use all 14 action bars (168 buttons)
/dominos numbars 5     -- Use only 5 action bars (60 buttons)
```

**Set Number of Buttons Per Bar**
```
/dominos numbuttons <count>
```
Sets how many buttons appear on each action bar (1-12).

**Examples:**
```
/dominos numbuttons 12    -- All bars have 12 buttons (default)
/dominos numbuttons 10    -- All bars have 10 buttons
```

**Note**: This is a global setting affecting all action bars.

## Layout Commands

**Available via slash commands**: Columns, Spacing, Padding

**GUI-only (no slash commands)**: Row Offset, Row Spacing, Orientation

### Columns

**Set Button Columns**
```
/dominos setcols <bars> <columns>
```
Sets the number of buttons per row, creating grid layouts.

**Examples:**
```
/dominos setcols 1 12        -- Bar 1: 1 row of 12 buttons (horizontal)
/dominos setcols 1 1         -- Bar 1: 12 rows of 1 button (vertical)
/dominos setcols 1 6         -- Bar 1: 2 rows of 6 buttons (grid)
/dominos setcols 1-3 4       -- Bars 1-3: 3 rows of 4 buttons each
/dominos setcols all 12      -- All bars: horizontal layout
```

### Spacing

**Set Button Spacing**
```
/dominos space <bars> <spacing>
```
Sets the gap between buttons (-20 to 20 pixels).

**Examples:**
```
/dominos space 1 2           -- Bar 1: 2px gap between buttons
/dominos space 1 0           -- Bar 1: buttons touching, no gap
/dominos space 1 -2          -- Bar 1: buttons overlap by 2px
/dominos space 1-5 3         -- Bars 1-5: 3px spacing
/dominos space all 4         -- All bars: 4px spacing
```

### Padding

**Set Bar Padding**
```
/dominos pad <bars> <padding>
```
Sets inner padding around the bar frame (0-20 pixels).

**Examples:**
```
/dominos pad 1 5             -- Bar 1: 5px padding
/dominos pad 1 0             -- Bar 1: no padding
/dominos pad pet 8           -- Pet bar: 8px padding
/dominos pad 1-3 6           -- Bars 1-3: 6px padding
```

## Appearance Commands

### Scale

**Set Bar Scale**
```
/dominos scale <bars> <scale>
```
Sets the size of the bar (0.5 to 2.0, where 1.0 = 100%).

**Examples:**
```
/dominos scale 1 0.9         -- Bar 1: 90% size
/dominos scale 1 1.2         -- Bar 1: 120% size
/dominos scale 1-5 0.85      -- Bars 1-5: 85% size
/dominos scale pet 0.8       -- Pet bar: 80% size
/dominos scale bags 0.75     -- Bag bar: 75% size
/dominos scale all 1.0       -- All bars: default size
```

### Opacity

**Set Base Opacity**
```
/dominos setalpha <bars> <opacity>
```
Sets the bar's base opacity (0 to 1, where 1 = 100%).

**Examples:**
```
/dominos setalpha 1 0.8      -- Bar 1: 80% opacity
/dominos setalpha 1 1.0      -- Bar 1: fully opaque
/dominos setalpha 1 0.5      -- Bar 1: 50% transparent
/dominos setalpha 1-5 0.9    -- Bars 1-5: 90% opacity
/dominos setalpha all 1      -- All bars: fully opaque
```

**Set Faded Opacity**
```
/dominos fade <bars> <opacity>
```
Sets the bar's faded opacity when mouse is not over it (0 to 1).

**Examples:**
```
/dominos fade 1 0            -- Bar 1: fades to invisible
/dominos fade 1 0.6          -- Bar 1: fades to 60%
/dominos fade 1 1.0          -- Bar 1: no fading (always 100%)
/dominos fade 2-4 0.5        -- Bars 2-4: fade to 50%
```

## Visibility Commands

### Show/Hide

**Show Bar**
```
/dominos show <bars>
```
Makes the specified bar(s) visible.

**Examples:**
```
/dominos show 1              -- Show bar 1
/dominos show pet            -- Show pet bar
/dominos show 1-5            -- Show bars 1 through 5
/dominos show all            -- Show all bars
```

**Hide Bar**
```
/dominos hide <bars>
```
Makes the specified bar(s) hidden.

**Examples:**
```
/dominos hide 1              -- Hide bar 1
/dominos hide bags           -- Hide bag bar
/dominos hide 6-10           -- Hide bars 6 through 10
/dominos hide all            -- Hide all bars (not recommended!)
```

**Toggle Bar Visibility**
```
/dominos toggle <bars>
```
Toggles bar(s) between shown and hidden.

**Examples:**
```
/dominos toggle 1            -- Toggle bar 1
/dominos toggle bags         -- Toggle bag bar
/dominos toggle 1-3          -- Toggle bars 1-3
```

## Profile Commands

Profiles let you save and switch between different configurations.

**Save Current Profile**
```
/dominos save <name>
```
Saves current settings as a named profile.

**Examples:**
```
/dominos save raid           -- Save as "raid" profile
/dominos save pvp            -- Save as "pvp" profile
/dominos save backup         -- Save as "backup" profile
```

**Load Profile**
```
/dominos set <name>
```
Switches to the specified profile.

**Examples:**
```
/dominos set raid            -- Load raid profile
/dominos set pvp             -- Load pvp profile
/dominos set Default         -- Load default profile
```

**Copy Profile**
```
/dominos copy <name>
```
Copies another profile's settings to your current profile.

**Examples:**
```
/dominos copy Default        -- Copy Default profile to current
/dominos copy MyOtherChar    -- Copy another character's profile
```

**Delete Profile**
```
/dominos delete <name>
```
Removes the specified profile.

**Examples:**
```
/dominos delete oldprofile   -- Delete "oldprofile"
/dominos delete backup       -- Delete backup profile
```

**Note**: Cannot delete the currently active profile.

**List All Profiles**
```
/dominos list
```
Shows all available profiles.

**Reset Current Profile**
```
/dominos reset
```
Resets current profile to default settings.

**Warning**: This deletes all your current configuration for this profile!

## Bar Identifiers

Commands accept various ways to specify which bars to affect.

### Numeric Identifiers

**Action Bars**: `1`, `2`, `3`, ... `14`
```
/dominos scale 1 0.9         -- Bar 1
/dominos scale 5 0.8         -- Bar 5
/dominos scale 14 1.0        -- Bar 14
```

### Named Identifiers

**Special Bars**:
- `pet` - Pet action bar
- `stance` or `class` - Stance/class bar
- `bags` - Bag bar
- `menu` - Menu bar (micro menu)
- `extra` - Extra ability bar
- `possess` - Possess/vehicle bar
- `encounter` - Encounter bar
- `queue` - Queue status bar (Retail)
- `totem` - Totem bar (Wrath/Cata)
- `talk` - Talking head bar
- `cast` - Cast bar (if Dominos_Cast installed)
- `exp` or `xp` - Experience bar (if Dominos_Progress installed)
- `rep` - Reputation bar (if Dominos_Progress installed)
- `roll` - Roll bar (if Dominos_Roll installed)
- `alerts` - Alerts bar (if Dominos_Roll installed)

**Examples:**
```
/dominos scale pet 0.8       -- Pet bar to 80%
/dominos hide bags           -- Hide bag bar
/dominos show menu           -- Show menu bar
/dominos setalpha cast 0.9   -- Cast bar to 90% opacity
```

### Ranges

**Syntax**: `<start>-<end>`

**Examples:**
```
/dominos scale 1-5 0.9       -- Bars 1 through 5
/dominos hide 6-10           -- Bars 6 through 10
/dominos setalpha 1-14 1     -- All action bars (1 to 14)
```

### All Bars

**Syntax**: `all`

**Examples:**
```
/dominos scale all 1.0       -- All bars to 100% scale
/dominos setalpha all 0.9    -- All bars to 90% opacity
/dominos show all            -- Show all bars
```

**Note**: `all` affects all bars including special bars (pet, bags, etc.).

## Examples and Use Cases

### Quick Bar Setups

**Compact Action Bars**
```
/dominos setcols 1-5 6       -- 5 bars with 6 columns (2 rows each)
/dominos scale 1-5 0.9       -- Slightly smaller
/dominos space 1-5 2         -- 2px spacing
```

**Vertical Side Bars**
```
/dominos setcols 2-3 1       -- Bars 2-3 as single column
/dominos scale 2-3 0.85      -- Smaller for side of screen
```

**Minimal Pet Bar**
```
/dominos setcols pet 10      -- 10 columns
/dominos scale pet 0.8       -- 80% size
/dominos fade pet 0          -- Fade to invisible when not moused over
```

### Profile Management

**Save Before Experimenting**
```
/dominos save backup         -- Save current setup
-- Make changes --
/dominos set backup          -- Restore if you don't like changes
```

**Create Spec-Specific Profiles**
```
-- In DPS spec --
/dominos save MyChar-DPS

-- In Tank spec --
/dominos save MyChar-Tank

-- Switch back to DPS --
/dominos set MyChar-DPS
```

**Content-Specific Profiles**
```
/dominos save Solo           -- Solo questing setup
/dominos save Raid           -- Raid UI setup
/dominos save PvP            -- PvP setup

-- Before entering raid --
/dominos set Raid
```

### Macro Integration

**Profile Switcher Macro**
```
#showtooltip
/dominos set Raid
/say Switching to raid UI
```
Place on a button for quick profile switching.

**Visibility Toggle Macro**
```
#showtooltip
/dominos toggle 6-10
```
Toggle extra bars on/off for cleaner screenshots.

**Combat-Based Bar Hiding (Manual)**
```
-- Pre-combat macro (hide utility bars) --
/dominos hide 8-10

-- Post-combat macro (show utilities) --
/dominos show 8-10
```

**Bar Size Adjuster**
```
/dominos scale 1-5 0.85      -- Combat size (smaller, less clutter)
-- OR --
/dominos scale 1-5 1.0       -- Default size (easier to see)
```

### Batch Configuration

**Reset Everything to Default Layout**
```
/dominos setcols all 12      -- All bars horizontal
/dominos space all 2         -- Standard spacing
/dominos scale all 1.0       -- Normal size
/dominos setalpha all 1      -- Fully opaque
/dominos fade all 1          -- No fading
/dominos show all            -- All visible
```

**Create Fade-to-Invisible Setup**
```
/dominos setalpha 1-10 1.0   -- Full opacity when visible
/dominos fade 1-10 0         -- Invisible when faded
```
Then configure fade delays in the GUI.

**Hide All Non-Essential Bars**
```
/dominos hide 6-14           -- Hide extra action bars
/dominos hide bags           -- Hide bags
/dominos hide menu           -- Hide menu
```
Useful for minimalist setups or specific content.

### Troubleshooting Commands

**Fix Invisible Bar**
```
/dominos show <bar>          -- Make sure it's not hidden
/dominos setalpha <bar> 1    -- Reset to full opacity
/dominos fade <bar> 1        -- Disable fading
/dominos scale <bar> 1       -- Reset to normal size
```

**Reset Single Bar**
```
-- No single command, but sequence: --
/dominos show 1
/dominos setcols 1 12
/dominos scale 1 1.0
/dominos setalpha 1 1.0
/dominos fade 1 1.0
/dominos space 1 2
/dominos pad 1 0
```

**Restore All Bars to Visible**
```
/dominos show all            -- Show everything
```

### Advanced Usage

**Conditional Macro with Multiple Commands**
```
#showtooltip
/dominos set Raid
/dominos scale 1-3 0.9
/dominos hide 8-10
/dominos show cast
/print Raid UI loaded
```
Loads raid profile and makes additional adjustments.

**Size Adjustment Based on Resolution**
```
-- For 1920x1080 --
/dominos scale all 0.9

-- For 2560x1440 --
/dominos scale all 0.8

-- For 4K --
/dominos scale all 0.7
```

**Create Standardized Bar Layouts**
```
-- Bottom center bars (1-3) --
/dominos setcols 1-3 12
/dominos scale 1-3 0.95
/dominos space 1-3 3

-- Side bars (4-5) --
/dominos setcols 4-5 2
/dominos scale 4-5 0.85
/dominos space 4-5 2

-- Pet and bags --
/dominos scale pet 0.8
/dominos scale bags 0.75
```

## Tips and Best Practices

### Command Efficiency

**Use ranges** instead of multiple commands:
```
-- Instead of: --
/dominos scale 1 0.9
/dominos scale 2 0.9
/dominos scale 3 0.9

-- Use: --
/dominos scale 1-3 0.9
```

**Chain commands in macros** for complex setup:
```
/dominos setcols 1 6; /dominos scale 1 0.9; /dominos space 1 2
```
Note: WoW macros have character limits, so very long chains may not fit.

### Profile Workflow

1. **Start with backup**: `/dominos save backup`
2. **Experiment**: Try different settings
3. **Save if you like it**: `/dominos save newsetup`
4. **Restore if you don't**: `/dominos set backup`

### Naming Conventions

**Use clear profile names:**
- Good: `MyChar-Raid-DPS`, `PvP-Healer`, `Solo-Questing`
- Bad: `profile1`, `test`, `asdf`

**Include character/spec** if you have many:
- `Warrior-Prot-Raid`
- `Warrior-Arms-PvP`
- `Warrior-Fury-Solo`

### Testing Commands

**Test one bar first** before applying to all:
```
/dominos scale 1 0.8         -- Test on bar 1
-- If you like it: --
/dominos scale all 0.8       -- Apply to all
```

### Documentation

**Keep a text file** with your preferred settings:
```
-- My Dominos Setup --
/dominos numbars 10
/dominos setcols 1 6
/dominos scale 1-5 0.9
/dominos space 1-5 2
-- etc --
```
You can paste these if you ever need to recreate your setup.

## Command Quick Reference

| Command | Syntax | Example |
|---------|--------|---------|
| Open menu | `/dominos` | `/dominos` |
| Config mode | `/dominos config` | `/dominos config` |
| Binding mode | `/dominos bind` | `/dominos bind` |
| Columns | `/dominos setcols <bars> <num>` | `/dominos setcols 1 6` |
| Spacing | `/dominos space <bars> <pixels>` | `/dominos space 1-5 2` |
| Padding | `/dominos pad <bars> <pixels>` | `/dominos pad 1 5` |
| Scale | `/dominos scale <bars> <scale>` | `/dominos scale 1 0.9` |
| Opacity | `/dominos setalpha <bars> <alpha>` | `/dominos setalpha 1 0.8` |
| Faded opacity | `/dominos fade <bars> <alpha>` | `/dominos fade 1 0` |
| Show | `/dominos show <bars>` | `/dominos show 1-5` |
| Hide | `/dominos hide <bars>` | `/dominos hide bags` |
| Toggle | `/dominos toggle <bars>` | `/dominos toggle pet` |
| Action bars | `/dominos numbars <count>` | `/dominos numbars 10` |
| Buttons/bar | `/dominos numbuttons <count>` | `/dominos numbuttons 12` |
| Save profile | `/dominos save <name>` | `/dominos save raid` |
| Load profile | `/dominos set <name>` | `/dominos set pvp` |
| Copy profile | `/dominos copy <name>` | `/dominos copy Default` |
| Delete profile | `/dominos delete <name>` | `/dominos delete old` |
| List profiles | `/dominos list` | `/dominos list` |
| Reset profile | `/dominos reset` | `/dominos reset` |

---

For information on configuring bars via the GUI, see [Bar Configuration](Bar-Configuration.md).

For profile strategies, see [FAQ and Troubleshooting](FAQ-and-Troubleshooting.md).
