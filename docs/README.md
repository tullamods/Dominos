# Dominos Documentation

Comprehensive guides for using and configuring Dominos, the World of Warcraft action bar addon.

## Quick Start

New to Dominos? Start here:

1. **[Features](Features.md)** - Overview of everything Dominos can do
2. **[Bar Configuration](Bar-Configuration.md)** - Learn to position and layout your bars
3. **[FAQ and Troubleshooting](FAQ-and-Troubleshooting.md)** - Common questions and solutions

## Documentation Guides

### Core Guides

**[Features Overview](Features.md)**
- Complete feature list
- Bar types (action bars, pet bar, cast bar, etc.)
- Customization options
- Module descriptions (Cast, Progress, Roll)
- Integration with other addons

**[Bar Configuration](Bar-Configuration.md)**
- Accessing bar settings
- Layout options (columns, spacing, padding, orientation)
- Positioning and anchoring
- Scaling and layering
- Common configurations and examples

**[Paging and Bar States](Paging-and-Bar-States.md)**
- Understanding action bar paging
- State types (modifier, class, race, target)
- Configuring paging for forms/stances
- Class-specific setups
- Advanced paging techniques

**[Visibility and Fading](Visibility-and-Fading.md)**
- Show/hide options
- Opacity and fading controls
- Conditional visibility (show only in combat, with modifiers, etc.)
- Special UI states (vehicles, pet battles)
- Common visibility setups

**[Slash Commands](Slash-Commands.md)**
- Complete command reference
- Configuration commands
- Layout commands (columns, spacing, padding)
- Appearance commands (scale, opacity)
- Visibility commands
- Profile management
- Examples and use cases

**[FAQ and Troubleshooting](FAQ-and-Troubleshooting.md)**
- Frequently asked questions
- Common problems and solutions
- Keybinding issues
- Visual issues
- Paging problems
- Addon conflicts
- Performance and errors

## Quick Reference

### Essential Commands

```
/dominos              -- Open options menu
/dominos config       -- Toggle configuration mode (move bars)
/kb                   -- Quick keybinding mode

/dominos scale 1 0.9  -- Set bar 1 to 90% size
/dominos show 1       -- Show bar 1
/dominos hide bags    -- Hide bag bar
```

### Common Tasks

**Moving bars**: `/dominos config` → drag bars → exit config mode

**Binding keys**: `/kb` → hover over button → press key

**Combat-only bar**: Right-click bar → Show States → `[combat] show; hide`

**Fade to invisible**: Right-click bar → Faded Opacity → 0%

**Form/stance paging**: Right-click bar → Paging → enable forms/stances

### Getting Help

- **In-game**: Right-click bars in config mode for contextual menus
- **GitHub Issues**: [Report bugs or ask questions](https://github.com/tullamods/Dominos/issues)
- **Wiki**: [Online wiki](https://github.com/tullamods/Dominos/wiki)

## Guide Map

Here's how the guides relate to each other:

```
Start Here
    ↓
[Features] ←─────── Overview of capabilities
    ↓
    ├─→ [Bar Configuration] ── Basic positioning and layout
    │
    ├─→ [Visibility and Fading] ── Show/hide and opacity
    │
    ├─→ [Paging and Bar States] ── Advanced form/stance switching
    │
    ├─→ [Slash Commands] ──────── Command-line reference
    │
    └─→ [FAQ and Troubleshooting] ── Solutions to common issues
```

## Documentation Updates

This documentation is maintained alongside the Dominos addon. If you find errors, outdated information, or have suggestions for improvement:

1. [Open an issue](https://github.com/tullamods/Dominos/issues) on GitHub
2. Submit a pull request with corrections
3. Ask questions in the issues section

## Contributing to Docs

To improve these guides:

1. Fork the repository
2. Edit files in the `docs/` directory
3. Submit a pull request
4. Include description of what you've improved

**Style guidelines**:
- Use clear, simple language
- Include examples for complex topics
- Cross-reference related guides
- Test all commands/instructions before documenting
- Format code blocks with proper markdown

## About Dominos

Dominos is a lightweight, powerful action bar addon for World of Warcraft. It replaces the default action bars with highly customizable alternatives featuring:

- Up to 14 action bars (168 buttons)
- Extensive layout customization
- Advanced paging for forms/stances
- Conditional visibility
- Opacity fading
- Masque support
- Compatible with all WoW versions

**Development**: [GitHub Repository](https://github.com/tullamods/Dominos)

**Downloads**:
- [CurseForge](https://www.curseforge.com/wow/addons/dominos)
- [WoWInterface](https://www.wowinterface.com/downloads/info4782-Dominos.html)

## Version History

For changelog and version history, see [CHANGELOG.md](../CHANGELOG.md) in the main repository.
