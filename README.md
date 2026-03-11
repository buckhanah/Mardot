# Mardot

A Turtle WoW addon that displays DoT (Damage over Time) and debuff durations with dynamic haste tracking in a movable window.

**Version:** 3.1 | **Turtle WoW Compatible** | **SuperWoW Supported**

## Features

- 📊 **Movable window display** - Clean, draggable frame showing DoTs on current target
- ⚡ **SuperWoW integration** - Uses UNIT_CASTEVENT for instant, accurate tracking when available
- 🌀 **Dark Harvest support** - Real-time DoT acceleration tracking with visual indicator (green border)
- 🎯 **Priority-based ordering** - Smart display order (Curses → Corruption → Other DoTs)
- 🛡️ **Paladin Seal tracker** - Shows active seal below character in 3D world
- 💾 **Persistent settings** - Position and preferences save between sessions

## Supported Classes

### Warlock
- **All Curses** (Agony, Shadows, Recklessness, Doom, Weakness, Tongues, Elements)
- **Corruption**
- **Immolate**
- **Siphon Life**

**Dark Harvest**: When channeling, DoT icons turn green and timers accelerate 30% faster in real-time!

### Paladin
- **Judgement durations** (Light, Wisdom, Justice, Crusader) - 10s on target
- **Active Seal display** - Shows current seal icon below character (Righteousness, Crusader, Command, Light, Wisdom, Justice)

## Installation

### Manual Installation
1. Download the latest release or clone this repository
2. Extract the `Mardot` folder to your WoW installation directory:
```
   <WoW Directory>/Interface/AddOns/Mardot/
```
3. Restart WoW or type `/console reloadui` in-game

### Folder Structure
```
Interface/
└── AddOns/
    └── Mardot/
        ├── Mardot.toc
        └── Mardot.lua
```

## Usage

### Commands
- `/mardot` or `/md` - Show command list
- `/mardot toggle` - Enable/disable addon
- `/mardot lock` - Lock/unlock DoT window position
- `/mardot show` - Force show DoT window
- `/mardot reset` - Reset window position to center
- `/mardot size <16-64>` - Set icon size (requires reload)
- `/mardot reload` - Reload window with new settings
- `/mardot debug` - Show active DoTs and addon info
- `/mardot test <spell>` - Add test DoT for testing

### Display Priority

Icons display in strategic order (NOT by time remaining):

**Warlock Priority:**
1. Curse of Agony
2. Curse of Shadows
3. Curse of Recklessness
4. Curse of Doom
5. Other Curses
6. Corruption
7. Immolate, Siphon Life

**Example:** If you have CoA (20s), Corruption (5s), Immolate (12s) active, they display as:
```
[CoA] [Corr] [Immo]
 20s    5s     12s
```

## Dark Harvest Mechanics

**What it does:**
- While channeling Dark Harvest, all DoTs on the target tick 30% faster
- DoT durations are consumed 30% faster during the channel
- Visual indicator: Icon borders turn **bright green** while Dark Harvest is active

**How it works:**
```
Time consumed = normal_elapsed + (Dark_Harvest_duration × 0.3)
```

**Example:**
- Cast Corruption (18s) at T=0
- Channel Dark Harvest for 8 seconds starting at T=5
- At T=13: Corruption has ~2.6s remaining (18s - 13s - 2.4s acceleration)

## Paladin Features

### Judgement Tracking
Shows judgement debuff durations (10s) on enemy targets in the main DoT window.

### Seal Display
- Displays your active seal as an icon below your character in the 3D world
- Position: Center screen, Y=-150 (below character feet)
- Updates instantly when switching seals
- Color-coded borders for each seal type

## SuperWoW Support

Mardot automatically detects SuperWoW and uses `UNIT_CASTEVENT` for:
- Instant spell tracking (no scanning delay)
- Accurate cast detection with spell IDs
- Latency compensation based on your ping

**Without SuperWoW:** Falls back to `UnitDebuff()` scanning (still works!)

## Configuration

Settings are saved per character in `MardotDB`:
- Window position
- Icon size (default: 32px)
- Lock state
- Enabled debuffs

Adjust icon size:
```
/mardot size 40
/mardot reload
```

## Color Coding

**Timer Colors:**
- Green: >5 seconds remaining
- Yellow: 3-5 seconds remaining
- Red: <3 seconds remaining

**Border Colors:**
- Default: Spell-specific color
- Bright Green: Dark Harvest active on this DoT

## Known Issues

- Spell IDs may need verification for Turtle WoW custom content
- Seal position may need adjustment based on UI scale/resolution

## Contributing

Contributions welcome! Please open issues for:
- Missing spells/debuffs
- Incorrect spell IDs for Turtle WoW
- Bug reports
- Feature requests

## Credits

Created by IT Solutions for the Turtle WoW community.

Inspired by Cursive addon's event handling patterns.

## Changelog

### Version 3.1 (Current)
- Added SuperWoW UNIT_CASTEVENT support
- Added real-time Dark Harvest acceleration tracking
- Added Paladin Seal display below character
- Removed Warrior support (focused scope)
- Window-based display (moved away from nameplates)
- Improved stability and performance

### Version 2.1
- Priority-based icon ordering
- Configuration commands
- Dark Harvest detection

### Version 1.0
- Initial release
- Basic DoT tracking
