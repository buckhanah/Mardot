# Mardot

A Turtle WoW addon that displays DoT (Damage over Time) and debuff durations as icons on enemy nameplates.

![Version](https://img.shields.io/badge/version-2.1-blue)
![WoW](https://img.shields.io/badge/WoW-1.12.1-orange)
![Turtle WoW](https://img.shields.io/badge/Turtle%20WoW-Compatible-green)

## Features

- 📊 **Icon-based display** - Shows debuff icons with countdown timers on nameplates
- ⚡ **Dynamic haste tracking** - Automatically adjusts for spell haste from gear and buffs
- 🌀 **Dark Harvest support** - Tracks channeling effects that accelerate DoT tick rates
- 🎯 **Priority-based ordering** - Smart display order (Curses → Corruption → Other DoTs)
- ⚙️ **Full configuration UI** - Adjust icon size, max icons, and toggle individual debuffs
- 💾 **Persistent settings** - All configurations save between sessions

## Supported Classes

### Warlock
- All Curses (Agony, Shadows, Recklessness, Doom, Weakness, Tongues)
- Corruption
- Immolate
- Siphon Life

### Warrior
- Rend (21s duration, bleeds every 3s)
- Hamstring (15s snare)
 
### Paladin
- Judgements duration (10s)

## Installation

### Manual Installation
1. Download the latest release or clone this repository
2. Extract the `Mardot` folder to your WoW installation directory:
```
   <WoW Directory>/Interface/AddOns/Mardot/
```
3. Restart WoW or type `/console reloadui` in-game

### Folder Structure
Your AddOns folder should look like:
```
Interface/
└── AddOns/
    └── Mardot/
        ├── Mardot.toc
        └── Mardot.lua
```

## Usage

### Commands
- `/mardot config` or `/md config` - Open configuration UI
- `/mardot toggle` or `/md toggle` - Enable/disable addon
- `/mardot haste` or `/md haste` - Show current spell haste percentage
- `/mardot debug` or `/md debug` - Show active DoTs being tracked

### Configuration
Type `/mardot config` to open the settings panel where you can:
- Adjust icon size (16-48 pixels)
- Set maximum number of icons displayed (3-10)
- Enable/disable individual debuffs
- All settings save automatically

## Display Priority

Icons are displayed in strategic order, NOT by time remaining:

**Warlock Priority:**
1. Curse of Agony
2. Curse of Shadows
3. Curse of Recklessness
4. Curse of Doom
5. Other Curses
6. Corruption
7. Other DoTs (Immolate, Siphon Life, etc.)

This ensures important debuffs like curses are always visible first!

## Dark Harvest Support

The addon intelligently tracks Dark Harvest channeling:
- Detects when you start channeling Dark Harvest
- Accelerates DoT durations as the channel ticks
- Adjusts timers dynamically based on actual tick consumption
- Shows acceleration count in debug mode

## Screenshots

*Coming soon - add your own screenshots here!*

## Known Issues

- Nameplate detection may vary depending on other nameplate addons
- Combat log parsing depends on game language (currently optimized for English)

## Contributing

Feel free to open issues or submit pull requests for:
- Additional debuffs/spells
- Bug fixes
- Feature requests
- Localization support

## License

This addon is provided as-is for the Turtle WoW community.

## Credits

Created by IT Solutions for the Turtle WoW community.

Special thanks to the Turtle WoW development team for their custom content that inspired features like Dark Harvest tracking.

## Changelog

### Version 2.1
- Initial public release
- Icon-based nameplate display
- Full configuration UI
- Dynamic haste tracking
- Dark Harvest support
- Priority-based ordering system



<img width="462" height="42" alt="image" src="https://github.com/user-attachments/assets/2079e905-9057-48cc-b837-da75b2592771" />

<img width="228" height="44" alt="image" src="https://github.com/user-attachments/assets/4410a927-038b-4a42-b44d-d07658f86473" />
