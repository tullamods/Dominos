# Dominos Features

Dominos is a comprehensive action bar replacement addon that provides extensive customization options for your World of Warcraft interface. This guide covers all available features.

## Table of Contents

- [Bar Types](#bar-types)
- [Customization Options](#customization-options)
- [Advanced Features](#advanced-features)
- [Integration](#integration)

## Bar Types

Dominos provides many different types of bars, each serving a specific purpose.

### Action Bars

**Action Bars 1-14** are the core of Dominos, providing up to 168 customizable action buttons (14 bars × 12 buttons).

- Fully independent positioning and configuration
- Support for advanced paging (automatic bar switching based on conditions)
- Per-bar customization of layout, visibility, and appearance
- Configure the number of active bars with `/dominos numbars <count>`

**Key Features:**
- Keybinding support via LibKeyBound
- Individual Masque theming per bar
- Custom left/right-click unit targeting
- Flyout menu direction control
- Empty button visibility toggle

### Pet Bar

Displays your pet's action buttons with automatic visibility management.

- Shows/hides automatically when you have a pet
- Supports standard pet commands (Attack, Follow, Stay, etc.)
- Full positioning and styling customization
- Compatible with pet-related addons

### Stance/Class Bar

Shows class-specific abilities including stances, forms, and auras.

**Supported by Class:**
- **Druid**: Shapeshift forms (Bear, Cat, Moonkin, Travel, Aquatic, Flight, etc.)
- **Warrior**: Stances (Battle, Defensive, Berserker)
- **Paladin**: Auras (Devotion, Retribution, Concentration, Crusader)
- **Rogue**: Stealth and Shadow Dance
- **Priest**: Shadowform
- **Death Knight**: Presences (Blood, Frost, Unholy) in Wrath
- **Warlock**: Metamorphosis in Wrath/Cata
- **Hunter**: Aspects (Hawk, Viper, Monkey, etc.) in Wrath
- **Evoker**: Soar in Retail

### Bag Bar

Provides access to your bags and backpack.

- Individual bag slot visibility (show/hide specific bags)
- Keyring support (Classic/TBC)
- Reagent bag support (Retail)
- Customizable layout and ordering

### Menu Bar

The micro menu containing Character, Spellbook, Talents, and other game menus.

- Enable/disable individual buttons
- Automatic layout adjustment in vehicles and pet battles
- Customizable spacing and arrangement
- Compatible with various WoW versions

### Specialized Bars

**Extra Ability Bar**: Zone-specific abilities and extra action buttons
- Optional Blizzard texture display
- Auto-visibility based on available abilities

**Possess Bar**: Vehicle and taxi exit button
- Appears when controlling vehicles or using flight paths

**Encounter Bar**: Boss encounter alternate power display
- Shows boss-specific resources and mechanics

**Queue Status Bar** (Retail only): LFG/PVP queue indicator

**Totem Bar** (Wrath/Cata): Shaman totem management interface

**Talking Head Bar**: NPC dialogue and quest interactions
- Option to mute quest dialogue audio

## Dominos Modules

### Dominos_Cast

**Cast Bar**: Player and vehicle casting visualization

- Customizable colors for different spell types:
  - Default casting
  - Failed casts
  - Harmful spells (enemy targets)
  - Helpful spells (friendly targets)
  - Uninterruptible casts
- Optional spell icon display
- Cast time and remaining time display
- Latency indicator (helps with spell queueing)
- Visual spark effect
- Border customization
- LibSharedMedia support for fonts and textures

**Mirror Timers**: Breath, fatigue, and feign death bars
- Up to 3 separate movable timer displays
- Individual positioning for each timer type

### Dominos_Progress

Multiple progress tracking bars that can cycle between different modes:

**Available Modes:**
- **XP Bar**: Experience tracking with rested XP visualization
- **Reputation Bar**: Faction reputation progress
  - Major faction support in Retail
- **Honor Bar**: PVP honor accumulation
- **Artifact Bar**: Artifact power (Legion)
- **Azerite Bar**: Azerite power (Battle for Azeroth)
- **Gold Bar**: Gold accumulation tracking with customizable goals

**Features:**
- Click to cycle between available modes
- One-bar or two-bar display mode
- Skip inactive modes option
- Custom colors per mode
- Hide at max level option
- Configurable gold tracking goal

### Dominos_Roll

**Roll Bar**: Repositionable loot roll interface
- Move the loot roll frame anywhere on screen

**Alerts Bar**: Achievement and alert positioning
- Control placement of achievement popups and alerts

## Customization Options

### Layout & Positioning

**Per-Bar Layout:**
- **Columns**: Set buttons per row (creates grid layouts)
- **Spacing**: Gap between buttons (supports negative values for overlap)
- **Row Offset**: Horizontal offset between rows (creates diagonal/staggered layouts)
- **Row Spacing**: Additional vertical gap between rows
- **Padding**: Inner frame padding around buttons
- **Orientation**: Four directional options
  - Left to Right / Right to Left
  - Top to Bottom / Bottom to Top

**Positioning:**
- **Free Drag**: Click and drag to any screen location
- **Anchoring**: Attach bars to other Dominos bars (or compatible addon frames)
- **Sticky Frames**: Automatic snapping within 8 pixels of:
  - Other bars
  - Screen edges
  - Alignment grid lines
- **Alignment Grid**: Optional visual grid overlay for precise positioning
  - Configurable grid size in settings

**Scaling & Layering:**
- **Scale**: 50-200% size adjustment per bar
- **Display Layer (Strata)**: BACKGROUND, LOW, MEDIUM, HIGH
  - Controls rendering order relative to other UI elements
- **Display Level**: Fine-tune z-order within a layer (1-200)
  - Higher numbers appear on top

### Appearance

**Opacity & Fading:**
- **Base Opacity**: 0-100% when bar is active/moused over
- **Faded Opacity**: Separate opacity when mouse leaves bar
- **Fade In**: Configurable delay (0-10s) and duration (0.1-10s)
- **Fade Out**: Configurable delay (0-10s) and duration (0.1-10s)
- **Linked Opacity**: Anchored bars can inherit parent opacity state

**Button Display Options** (per bar):
- **Binding Text**: Show/hide keybind text on buttons
- **Macro Text**: Show/hide macro names
- **Counts**: Show/hide item/charge counts
- **Empty Buttons**: Show/hide unassigned button slots
- **Equipped Item Borders**: Highlight currently equipped items

**Global Settings:**
- **Button Theme**: Built-in Dominos button skin (when Masque isn't active)
- **Show Tooltips**: Enable action button tooltips
- **Show Tooltips in Combat**: Separate in-combat tooltip setting
- **Show Spell Glows**: Proc and cooldown glow effects
- **Show Spell Animations**: Button press animations

### Visibility

Control when bars appear using flexible condition system:

**Basic Visibility:**
- **Show/Hide**: Simple on/off toggle per bar

**Conditional Visibility:**
Use WoW macro conditionals to show bars only when needed:
- `[combat]` / `[nocombat]` - Combat state
- `[mod:shift]`, `[mod:ctrl]`, `[mod:alt]` - Modifier keys
- `[help]`, `[harm]`, `[exists]` - Target type
- `[stance:1]`, `[form:2]` - Stance/form
- Any valid macro conditional expression

**Special UI States:**
- **Override UI**: Show/hide during vehicle/possess states
- **Pet Battle UI**: Show/hide during pet battles
- **Click Through**: Make bar non-interactive (clicks pass through)

## Advanced Features

### Action Bar Paging

Action bars can automatically switch pages based on various conditions. See the [Paging and Bar States](Paging-and-Bar-States.md) guide for detailed information.

**Modifier Paging**: Hold keys to temporarily switch bars
- Self-cast, Shift, Ctrl, Alt, Meta
- Combinations (Ctrl+Alt, Ctrl+Shift, Alt+Shift)

**Quick Paging**: Manual page selection (pages 2-6)

**Class-Specific Paging**: Automatic switching based on:
- Stances/forms (Warrior stances, Druid forms)
- Abilities (Rogue stealth, Priest Shadowform)
- Equipment (Shield equipped for Paladins/Warriors)

**Targeting Paging**: Switch bars based on target type
- Friendly target (Help)
- Hostile target (Harm)
- No target

### Profiles

Manage multiple configurations for different characters or situations:

- **Create New Profiles**: Save custom configurations
- **Copy Profiles**: Duplicate settings between profiles
- **Reset Profile**: Restore defaults
- **Delete Profiles**: Remove unused profiles
- **Per-Character or Shared**: Flexible profile assignment
- **Dual Spec Support**: Automatic profile switching (via LibDualSpec)
- **Default Profiles**: Class-based starting configurations

### Configuration Modes

**Configuration Mode**: Unlock bars for repositioning
- **Access**: Minimap button (left-click) or `/dominos config`
- **Features**:
  - Visible bar outlines
  - Drag handles for movement
  - Right-click for bar-specific options
  - Sticky frame snapping
  - Alignment grid (if enabled)

**Binding Mode**: Quick keybinding interface
- **Access**: `/kb` or Shift+click minimap button
- **Usage**: Hover over buttons and press desired key
- **Features**:
  - Visual feedback for bound keys
  - Quick unbinding
  - Character or account-wide bindings

### Slash Commands

Dominos provides extensive slash commands for advanced users and macro integration. See the [Slash Commands](Slash-Commands.md) guide for the complete reference.

**Common Examples:**
```
/dominos scale 1-5 0.9          -- Scale bars 1-5 to 90%
/dominos setalpha pet 0.8       -- Set pet bar opacity to 80%
/dominos hide bags              -- Hide bag bar
/dominos setcols 1 6            -- Set bar 1 to 6 columns (2 rows)
/dominos numbars 10             -- Use 10 action bars total
```

## Integration

### Compatible Addons

**Masque/ButtonFacade**
- Full button styling support
- Individual Masque settings per bar
- Hundreds of community-created skins available

**LibSharedMedia**
- Font selection for cast bar and other text
- Texture selection for bars and backgrounds

**Action Button Enhancers** (all compatible):
- **OmniCC**: Cooldown text and timers
- **tullaRange**: Out-of-range coloring
- **AdiButtonAuras**: Buff/debuff overlays and tracking

**LibKeyBound**
- Built-in integration for quick keybinding
- Standard keybinding interface

**FlyPaper**
- Cross-addon bar anchoring
- Attach Dominos bars to other compatible addons

### WoW Version Support

Dominos supports all major World of Warcraft versions:
- Retail (The War Within and future expansions)
- Cataclysm Classic
- Wrath of the Lich King Classic
- The Burning Crusade Classic
- Classic Era (Vanilla)
- Special events (Mists of Pandaria Remix, etc.)

Features automatically enable/disable based on game version to ensure compatibility.

## Getting Help

- **In-Game**: Right-click bars in configuration mode for contextual help
- **Slash Commands**: Type `/dominos` to see available commands
- **Tooltips**: Hover over options in the settings panel for explanations
- **GitHub**: [Report issues](https://github.com/tullamods/Dominos/issues) or browse existing solutions
- **Wiki**: Additional guides and examples in the [Dominos Wiki](https://github.com/tullamods/Dominos/wiki)
