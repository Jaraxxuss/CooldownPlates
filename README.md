# CooldownPlates

![CooldownPlates Banner](https://img.shields.io/badge/CooldownPlates-Enemy%20Cooldown%20Tracking-6f42c1?style=for-the-badge)
[![Vanilla](https://img.shields.io/badge/WoW-1.12-yellow.svg?style=flat-square)](https://github.com/yourusername/CooldownPlates/)
![GitHub](https://img.shields.io/badge/Requires-SuperWoW-red)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

CooldownPlates is a lightweight addon for World of Warcraft 1.12 that displays enemy ability cooldowns directly above their nameplates.

![CooldownPlates](https://github.com/user-attachments/assets/f4164c6c-d0bf-488e-8071-ff7e2f75a90f)

# ⚠️ **IMPORTANT: SUPERWOW IS REQUIRED!** ⚠️  
**This addon WILL NOT WORK without [SuperWoW](https://github.com/balakethelock/SuperWoW/releases)!**  

## Features

![CP](https://github.com/user-attachments/assets/3bc84857-a7b2-45c9-975c-ae9cfbe9eeda)

- **Nameplate Integration**: Displays cooldown icons directly above enemy nameplates
- **Visual Clarity**: Clean, customizable interface with cooldown swipe animations
- **Resource Efficient**: Uses object pooling to minimize memory usage and frame creation
- **Timer Display**: Optional cooldown text showing exact time remaining
- **Extensive Spell Database**: Tracks major cooldowns for all classes
- **Special Cooldown Detection**: Handles reset mechanics like Preparation, Cold Snap, and Readiness

## Configuration

CooldownPlates can be customized using the following slash commands:

```
/cooldownplates - Show help message
/cooldownplates timer - Toggle timer display on/off
/cooldownplates icons [1-7] - Set maximum number of icons
/cooldownplates spacing [20-60] - Set spacing between icons
/cooldownplates size [20-50] - Set icon size
/cooldownplates offset [20-70] - Set vertical offset above nameplates
/cooldownplates debug - Toggle debug mode
/cooldownplates reset - Reset to default settings
```

## Customizing Tracked Spells

CooldownPlates comes pre-configured with cooldowns for major abilities across all classes, but you can easily modify the spell database to suit your preferences.

### Adding New Spells

To add a new spell to be tracked, locate the `trackedSpells` table in `CooldownPlates.lua` and add a new entry:

```lua
["Spell Name"] = {cooldownInSeconds, "optional_icon_name"},
```

Example:
```lua
["Arcane Power"] = {180, nil}, -- Uses default spell icon
["Barkskin"] = {60, "Spell_Nature_StoneCloak"}, -- Uses custom icon
```

### Removing Spells

To remove tracking for a spell, simply delete or comment out its entry in the `trackedSpells` table.

### Reset Mechanics

For abilities that reset cooldowns (Preparation, Cold Snap, Readiness), edit the respective tables:
- `preparationResets` - For Rogue abilities reset by Preparation
- `coldSnapResets` - For Mage abilities reset by Cold Snap
- `readinessResets` - For Hunter abilities reset by Readiness

## Performance Considerations

CooldownPlates is designed with performance in mind:

- Uses the Compost-2.0 library for object pooling to reduce garbage collection
- Caches icon position calculations to avoid redundant math operations
- Only updates cooldown displays when necessary
- Efficiently manages frame creation and reuse
- Optimized nameplate detection with minimal performance impact

## Compatibility

Compatible with ShaguTweaks.
Currently not working with: pfUI, ShaguPlates.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<div align="center">
  <sub>Built with ❤️ for the Vanilla WoW community</sub>
</div>
