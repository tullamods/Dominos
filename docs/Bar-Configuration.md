# Bar Configuration Guide

This guide covers how to configure and customize individual bars in Dominos, from basic positioning to advanced layout options.

## Table of Contents

- [Accessing Bar Settings](#accessing-bar-settings)
- [Layout Options](#layout-options)
- [Positioning and Anchoring](#positioning-and-anchoring)
- [Scaling and Layering](#scaling-and-layering)
- [Common Configurations](#common-configurations)

## Accessing Bar Settings

There are three ways to access bar-specific settings:

1. **Configuration Mode (Right-Click)**
   - Enter configuration mode: `/dominos config` or left-click the minimap button
   - Right-click any bar to open its context menu
   - All bar-specific options are available here

2. **Configuration Mode (Alt+Left-Click)**
   - Same as right-click but works with alt+left-click
   - Useful if you've rebound right-click

3. **Main Options Menu**
   - Open with `/dominos` or right-click the minimap button
   - Some global settings affect all bars

## Layout Options

Layout options control how buttons are arranged within a bar.

### Columns

**What it does**: Sets the number of buttons per row

**Examples:**
- `1 column` = Vertical bar (12 rows × 1 column)
- `12 columns` = Horizontal bar (1 row × 12 columns)
- `6 columns` = Grid layout (2 rows × 6 columns)
- `4 columns` = Grid layout (3 rows × 4 columns)

**How to set:**
- GUI: Right-click bar → Layout → Columns slider
- Command: `/dominos setcols <bar> <columns>`
  - Example: `/dominos setcols 1 6` (set bar 1 to 6 columns)

### Spacing

**What it does**: Controls the gap between buttons

**Range**: -20 to 20 pixels
- Positive values = gaps between buttons
- Negative values = overlapping buttons
- `0` = buttons touching with no gap

**Examples:**
- `2` = Small gap (default Blizzard spacing)
- `4` = Medium gap
- `-2` = Slight overlap (popular for compact layouts)

**How to set:**
- GUI: Right-click bar → Layout → Spacing slider
- Command: `/dominos space <bar> <spacing>`
  - Example: `/dominos space 1 -2` (overlap buttons on bar 1)

### Row Spacing

**What it does**: Additional vertical gap between rows (separate from button spacing)

**Use case**: Create more vertical space between rows without affecting horizontal spacing

**Example:**
- Spacing = 2, Row Spacing = 8
- Creates 2px gaps between buttons horizontally
- Creates 8px gap between rows vertically

**How to set:**
- GUI: Right-click bar → Layout → Row Spacing slider

### Row Offset

**What it does**: Horizontal offset between rows

**Use case**: Create diagonal or staggered button layouts

**Examples:**
- `0` = Normal grid (rows aligned)
- `20` = Each row shifted 20px right
- `-20` = Each row shifted 20px left (staircase effect)

**How to set:**
- GUI: Right-click bar → Layout → Row Offset slider

### Padding

**What it does**: Inner spacing around the bar frame

**Range**: 0-20 pixels

**Effect**: Creates a border area inside the bar frame
- Useful for visual separation
- Helps with mouse-over detection for fading
- Creates space for bar backgrounds

**How to set:**
- GUI: Right-click bar → Layout → Padding slider
- Command: `/dominos pad <bar> <padding>`
  - Example: `/dominos pad 1 5` (5px padding on bar 1)

### Orientation

**What it does**: Controls the direction buttons are added to the bar

**Options:**
1. **Left to Right** (default for horizontal)
   - Button 1 on left, button 12 on right

2. **Right to Left**
   - Button 1 on right, button 12 on left
   - Useful for right-side screen alignment

3. **Top to Bottom** (default for vertical)
   - Button 1 on top, button 12 on bottom

4. **Bottom to Top**
   - Button 1 on bottom, button 12 on top
   - Good for bars at bottom of screen

**How to set:**
- GUI: Right-click bar → Layout → Orientation dropdown

## Positioning and Anchoring

### Free Positioning

**How to move bars:**
1. Enter configuration mode (`/dominos config`)
2. Click and drag any bar to desired location
3. Exit configuration mode when done

**Tips:**
- Hold Shift while dragging to disable sticky frames temporarily
- Use the alignment grid (enable in settings) for precise placement
- Bars snap to edges and other bars within 8 pixels by default

### Anchoring to Other Bars

**What it does**: Attach one bar to another so they move together

**How to anchor:**
1. Enable sticky frames (on by default)
2. In configuration mode, drag a bar near another bar
3. When bars are within 8 pixels, they snap together
4. Release to create the anchor relationship

**Anchor behavior:**
- Anchored bars move together when parent moves
- Anchored bars can share opacity states (if Linked Opacity is enabled)
- Multiple bars can anchor to the same parent
- Can anchor to bars from other compatible addons (via LibFlyPaper)

**Breaking anchors:**
- Drag the anchored bar away from its parent
- Or disable sticky frames and reposition

### Alignment Grid

**What it does**: Visual grid overlay for precise alignment

**How to enable:**
1. `/dominos` to open main settings
2. Check "Alignment Grid" option
3. Grid appears in configuration mode

**Configuring:**
- Grid size can be adjusted in settings
- Bars snap to grid intersections
- Disable in settings if not needed

### Sticky Frames

**What it does**: Automatic snapping to other UI elements

**Snaps to:**
- Other Dominos bars
- Screen edges
- Alignment grid lines (if enabled)
- Compatible addon frames (via LibFlyPaper)

**Snap distance**: 8 pixels (automatic)

**Disabling:**
- Globally: Uncheck "Sticky Frames" in `/dominos` settings
- Temporarily: Hold Shift while dragging

## Scaling and Layering

### Scale

**What it does**: Changes the size of the bar and its buttons

**Range**: 50% to 200%
- `1.0` (100%) = Default Blizzard size
- `0.8` (80%) = Smaller, compact bars
- `1.2` (120%) = Larger, more visible bars

**How to set:**
- GUI: Right-click bar → Scale slider
- Command: `/dominos scale <bar> <scale>`
  - Example: `/dominos scale 1-3 0.9` (scale bars 1-3 to 90%)

**Tips:**
- Scale affects the bar's screen position (bars grow from their anchor point)
- Pet and bag bars often look good at 80-90%
- Main action bars typically stay at 90-100%

### Display Layer (Strata)

**What it does**: Controls rendering order relative to other UI elements

**Options** (back to front):
1. **BACKGROUND** - Behind most UI elements
2. **LOW** - Behind medium elements
3. **MEDIUM** - Default layer for most frames
4. **HIGH** - In front of most UI elements

**Use cases:**
- Set to HIGH to ensure bars appear over other addons
- Set to LOW to allow other elements to overlap
- Most bars work fine on MEDIUM (default)

**How to set:**
- GUI: Right-click bar → Display Layer dropdown

### Display Level

**What it does**: Fine-tunes z-order within the same layer

**Range**: 1 to 200
- Higher numbers appear on top
- Only affects frames in the same strata

**Use cases:**
- Resolve overlap issues between Dominos bars
- Control which bar appears on top when they overlap
- Usually not needed unless you have overlapping bars

**How to set:**
- GUI: Right-click bar → Display Level slider

## Common Configurations

Here are some popular bar configurations to get you started.

### Compact Main Action Bars

Create a tight 3×4 grid of main abilities:

```
/dominos setcols 1 4
/dominos space 1 2
/dominos scale 1 0.95
```

Result: 3 rows of 4 buttons each, slightly scaled down, 2px spacing

### Vertical Side Bars

Create vertical bars on the side of the screen:

```
/dominos setcols 2 1
/dominos setcols 3 1
/dominos scale 2-3 0.85
```

Position bars 2 and 3 on the left or right edge. Result: Single-column vertical bars.

### Compact Pet Bar

Smaller, horizontal pet bar:

```
/dominos setcols pet 10
/dominos scale pet 0.8
/dominos space pet 1
```

Result: 10-button horizontal pet bar at 80% size

### Staggered Diagonal Layout

Create a diagonal staircase effect:

```
/dominos setcols 1 6
/dominos rowoffset 1 30
/dominos space 1 2
```

Result: 2 rows of 6 buttons, second row offset 30px to the right

### Minimal Bag Bar

Hide individual bags, show only backpack:

1. Right-click bag bar in config mode
2. Uncheck bags 1-4 (leave bag 0 - backpack)
3. Scale down: `/dominos scale bags 0.8`

### Center Bottom Action Bars

Classic MMO setup with centered bars at bottom:

1. Create bars 1-3 with 12 columns each
2. Stack them vertically at bottom-center of screen
3. Use spacing of 2-4 pixels
4. Scale to 0.9-1.0 depending on preference

```
/dominos setcols 1-3 12
/dominos space 1-3 3
/dominos scale 1-3 0.95
```

Then position in config mode at bottom-center, stacked vertically.

### Raid Frames Corner Bars

Small utility bars that don't interfere with raid frames:

```
/dominos setcols 4-5 2
/dominos scale 4-5 0.75
/dominos space 4-5 2
```

Position in corners. Result: 6 rows × 2 columns, 75% size - good for cooldowns and utilities.

## Advanced Layout Tips

### Using Negative Spacing

Negative spacing creates overlapping buttons:
- Good for reducing screen space
- Keep it subtle (-1 to -3) for best results
- Test with your button skin/theme

### Combining Row Offset and Row Spacing

Create unique layouts by adjusting both:
- Row offset: horizontal shift between rows
- Row spacing: vertical gap between rows
- Experiment with values to create custom shapes

### Multi-Bar Anchoring

Build complex layouts by anchoring multiple bars:
1. Position your main bar (e.g., bar 1 at bottom-center)
2. Anchor bar 2 above bar 1
3. Anchor bar 3 above bar 2
4. Now moving bar 1 moves all three together

### Orientation for Screen Edges

Match orientation to screen position:
- Left edge: Right to Left orientation (buttons flow inward)
- Right edge: Left to Right orientation (buttons flow inward)
- Top edge: Bottom to Top orientation
- Bottom edge: Top to Bottom orientation

### Padding for Visibility

Add padding when using:
- Faded opacity (creates hover area larger than buttons)
- Bar backgrounds (creates visual border)
- Tight button spacing (prevents accidental clicks)

## Slash Command Quick Reference

```
/dominos setcols <bar> <columns>    -- Set columns
/dominos space <bar> <spacing>      -- Set button spacing
/dominos pad <bar> <padding>        -- Set bar padding
/dominos scale <bar> <scale>        -- Set scale (0.5-2.0)
/dominos show <bar>                 -- Show bar
/dominos hide <bar>                 -- Hide bar

Bar identifiers:
- Numbers: 1, 2, 3, ... 14
- Names: pet, bags, menu, class, extra, possess
- Ranges: 1-5 (bars 1 through 5)
- All: all (affects all bars)
```

For more commands, see the [Slash Commands](Slash-Commands.md) guide.

## Troubleshooting

**Bar won't move**
- Make sure you're in configuration mode (`/dominos config`)
- Check that the bar isn't locked (shouldn't be possible in config mode)

**Buttons overlapping too much**
- Increase spacing: `/dominos space <bar> 2`
- Reduce columns if using grid layout

**Bar appears behind other UI elements**
- Increase display layer: Set to HIGH in bar's right-click menu
- Or increase display level value

**Can't see the bar**
- Check if bar is hidden: `/dominos show <bar>`
- Check opacity settings (might be at 0%)
- Check visibility conditions (might be set to hide in current state)

**Anchor won't stick**
- Enable sticky frames in `/dominos` main settings
- Get bars within 8 pixels of each other
- Try disabling alignment grid if it's interfering

---

For visibility and fading options, see the [Visibility and Fading](Visibility-and-Fading.md) guide.

For action bar paging and states, see the [Paging and Bar States](Paging-and-Bar-States.md) guide.
