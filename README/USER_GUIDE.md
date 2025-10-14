# NextKey User Guide

## Overview

NextKey is a World of Warcraft addon that helps Mythic+ groups intelligently select the best keystone to run next. It analyzes your party's keystones, player scores, and loot preferences to provide ranked recommendations.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Usage](#basic-usage)
3. [Understanding the Interface](#understanding-the-interface)
4. [Sorting Options](#sorting-options)
5. [Loot Targeting](#loot-targeting)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Installation

1. Download NextKey from your preferred addon manager
2. Extract to your World of Warcraft `_retail_/Interface/AddOns` folder
3. Restart World of Warcraft or reload your UI (`/reload`)
4. Ensure RaiderIO addon is installed (required dependency)

### First Time Setup

1. Type `/nk` or `/nextkey` to open the main window
2. Type `/nk config` to open the options panel
3. Configure your preferences in the options panel
4. The addon will automatically detect your keystone and scores

### Required Addons

- **RaiderIO**: Required for player score data
- **NextKey**: The main addon (this one)

---

## Basic Usage

### Opening NextKey

```
/nk          - Opens the main ranking window
/nk config   - Opens the options panel
/nk show     - Shows the main window if hidden
```

### Understanding the Main Window

The main window shows all available keystones from your party, ranked by your selected sorting method:

```

```

### Key Elements

- **Dungeon Cards**: Visual representation of each available keystone
- **IO Gain**: Total potential IO gain for the party
- **Player Coverage**: Number of players who can gain IO
- **Action Buttons**: Suggest, Teleport, and Announce options

---

## Understanding the Interface

### Dungeon Cards

Each card shows important information about a keystone:

- **Dungeon Name and Level**: Which dungeon and key level
- **Owner**: Who has the keystone
- **IO Gain**: How much total IO the party can gain
- **Player Coverage**: How many players benefit from this key
- **Class Icons**: Classes of players who can gain IO

### Tooltips

Hover over any dungeon card to see detailed information:
- **IO Breakdown**: How much each player can gain
- **Player Scores**: Current scores for this dungeon
- **Loot Information**: Targeted items and drop chances
- **Preferences**: Who likes/dislikes this dungeon

### Action Buttons

- **Refresh**: Updates all data from party members
- **Dice Roll**: Randomly selects a key (for fun)
- **Suggest**: Recommends the best key (party leaders only)
- **Teleport**: Provides travel assistance
- **Announce**: Shares recommendation in party chat

---

## Sorting Options

### Smart Sort (Recommended)
Uses a sophisticated algorithm that considers:
- IO gain potential
- Player coverage
- Key level
- Loot preferences
- Dungeon preferences

### Max Group IO
Prioritizes keystones that offer the most total IO gain for the entire party.

### Max Player Coverage
Shows keys where the most party members can gain IO, even if individual gains are smaller.

### Highest Key Level
Sorts by the highest available key level, helping groups push higher content.

### Max Item Need
Prioritizes dungeons that contain items party members are targeting.

---

## Loot Targeting

### Setting Loot Targets

1. Open options: `/nk config`
2. Navigate to "Loot Targets"
3. Expand dungeons to see available items
4. Check items you want to target
5. Set priority (1-3) for each item

### How It Works

- **Drop Chance Calculation**: Shows probability of targeted items dropping
- **Run Tracking**: Counts how many times you've run for each item
- **Success Announcements**: Celebrates when targeted items are obtained
- **Priority System**: Higher priority items influence sorting more

### Loot Notifications

When a targeted item drops:
- **Chat Announcement**: Automatic celebration message
- **Run Counter**: Updates your attempt count
- **Success Tracking**: Records successful acquisitions

---

## Advanced Features

### Auto-Suggest (Party Leaders)

Party leaders can enable automatic suggestions:
1. Open `/nk config`
2. Go to "General Settings"
3. Enable "Auto-Suggest"
4. Choose your preferred sort mode

The addon will automatically suggest the best key after completing a Mythic+ run.

### Travel Assistance

NextKey helps you get to dungeons:
- **Teleport Spells**: Suggests available teleportation spells
- **Flight Paths**: Shows nearest flight master
- **Hearthstone**: Recommends using hearthstone if close
- **Portal Information**: Provides portal locations when available

### Party Communication

The addon automatically shares data with party members:
- **Keystone Detection**: Automatically detects when someone gets a new key
- **Score Updates**: Shares score changes after runs
- **Real-time Sync**: Keeps everyone's data current

### Custom Preferences

You can set personal dungeon preferences:
1. Right-click any dungeon card
2. Select "Like" or "Dislike"
3. Optionally add a reason
4. These preferences influence sorting

---

## Troubleshooting

### Common Issues

**NextKey isn't showing my keystone:**
- Check that your keystone is in your bags
- Try `/nk refresh` to update data
- Ensure RaiderIO is installed and updated
- Reload your UI with `/reload`

**Scores aren't showing:**
- RaiderIO addon must be installed
- Update RaiderIO to the latest version
- Check that you've run at least one Mythic+ this season
- Try visiting RaiderIO website to update your data

**Party members aren't showing up:**
- Ensure all party members have NextKey installed
- Check that you're in a party (not raid group)
- Try `/nk refresh` to sync data
- Make sure everyone has the latest addon version

**UI elements are missing or misplaced:**
- Reload your UI with `/reload`
- Reset UI position in options: `/nk config → UI Preferences`
- Check if other addons are conflicting
- Disable other addons temporarily to test

### Debug Mode

If you're having persistent issues, enable debug mode:
1. Type `/nk config`
2. Go to "Debug System" tab
3. Enable debug mode
4. Enable relevant categories
5. Reproduce the issue
6. Share the debug output when reporting bugs

### Getting Help

For additional help:
1. Check the debug system as described above
2. Visit the addon's project page
3. Report issues with detailed information
4. Include screenshots when relevant

### Performance Tips

If you experience performance issues:
- Disable debug mode when not needed
- Reduce the number of displayed columns
- Close the addon when not in use
- Update all addons to latest versions

---

## Keyboard Shortcuts

```
/nk              - Toggle main window
/nk config       - Open options panel
/nk refresh      - Refresh all data
/nk debug        - Toggle debug mode
/nk test         - Generate test players (development)
```

---

## Tips and Best Practices

### For Party Leaders
- Use Smart Sort for balanced recommendations
- Check player coverage before deciding
- Consider group preferences when choosing
- Use the Suggest feature to help with decisions

### For All Players
- Set your loot targets to influence recommendations
- Mark dungeons you like or dislike
- Keep your addons updated for best results
- Share feedback with your group leader

### For Score Pushing
- Use Max Group IO sorting
- Focus on dungeons where you can gain the most
- Track your progress over time
- Consider key level vs. IO gain tradeoffs

### For Loot Farming
- Set specific loot targets
- Use Max Item Need sorting
- Track your run counts
- Celebrate successes with your group

---

## FAQ

**Q: Does NextKey work with cross-realm groups?**
A: Yes, NextKey works with players from different realms.

**Q: Do all party members need NextKey installed?**
A: No, but you'll get better data if everyone has it installed.

**Q: Can I use NextKey in PUG groups?**
A: Yes, NextKey works in any group type.

**Q: How often does data update?**
A: Data updates automatically when keys change or runs complete.

**Q: Does NextKey affect my game performance?**
A: NextKey is optimized to have minimal performance impact.

---

**Last Updated**: October 13, 2025  
**Version**: User Guide v1.0