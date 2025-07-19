# Bar States

This is a configuration format for defining different conditions where we want
to allow players to show different abilities on their action bars.We can't
always directly rely on a [macro conditional](https://warcraft.wiki.gg/wiki/Macro_conditionals)
as there ares ome quirks:

- `[form]` conditionals use indexes that change based on what spells a player
  has learned, an in what order
- `[worn]` conditionals use locale specific values

## File Organization

State definitions are split across multiple files:

- `Common.lua` - States shared across all game versions
- `[Game].lua` - Game specific states. There should be one file for each game
  flavor [as documented on the wiki](https://warcraft.wiki.gg/wiki/TOC_format).

## Table Structure

Bar states are organized into a configuration table with five main state types:

```lua
{
  -- Keyboard modifier ([mod:ctrl], etc)
  modifier = { state1, state2, state3... },

  -- Action bar quick paging ([bar:x])
  page = { ... },

  class = {
    -- States available to load for all classes
    ALL = { ... },

    -- class-specific states (ex DRUID, WARRIOR)
    WARRIOR = { ... }
  },

  -- race-specific abilities (really only used for Shadowmeld)
  race = {
    NightElf = { ... },
  },

  -- Target-based conditions (ex [help], [harm])
  target = { ... }
}
```

## State Definitions

Each state is specified using a table format with specific keys

- **stateId**: State identifier (first array element or `id` field)
- **macro**: WoW macro conditional expression
- **form**: Spell ID(s) for dynamic shapeshift form detection.
- **equipped**: `{classID, subclassID}` for detecting if an item is equipped. This is mainly to handle
  localization issues related to macros like `[worn:Shield]`
- **label**: Display text or spell ID (falls back to a `L.State_STATEID` lookup if omitted)

### Examples

```lua
-- Direct macro conditional
{ 'prowl', macro = '[bonusbar:1,stealth]', label = 'Prowl' },

-- Explicit state ID field
{ id = 'prowl', macro = '[bonusbar:1,stealth]', label = 'Prowl' },

-- You can specify a spell ID as a label instead. This helps with retrieving
-- a localized value
{ 'prowl', macro = '[bonusbar:1,stealth]', label = 5215 },

-- Form detection (for shapeshifting classes). Dominos will translate this into
-- the appropriate [form:index] when shapeshift forms change
{ 'moonkin', form = 24858 },

-- Use an array for classes that have form upgrades (ex Flight + Swift Flight)
-- The first item in the index will be used for the state's label
{ 'flight', form = {33943, 40120} },

-- Equipped item detection. This will be translated into the locale equivalent
-- of [worn:Shield]
{ 'shield', equipped = {Enum.ItemClass.Armor, Enum.ItemArmorSubclass.Shield} },
```

## Evaluation Order

States are evaluated in the following type order. Within each type, states
are evaluated in array index order.

1. **modifier** - Keyboard modifiers (ctrl, alt, shift, meta)
2. **page** - Action bar pages
3. **class** - Class-specific states. ALL is evaluated before a specific class
4. **race** - Race-specific states
5. **target** - Target conditions

This can be overriden on a per actionBar basis by setting updating the
ActionBar.statePrecedence array.
