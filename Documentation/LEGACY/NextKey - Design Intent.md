# NextKey - Design Intent & User Experience

> **📋 For Technical Implementation**: See `AI_DEVELOPMENT_GUIDE.md` for all architectural standards, coding patterns, and technical requirements.

This document focuses on the **user experience design** and **feature intent** behind NextKey.

## Problem Statement

In World of Warcraft's Mythic+ dungeon system, groups often waste time deciding which keystone to run next. This decision involves multiple factors:
- Each player has their own keystone
- Players need different dungeons for score improvements
- Players target specific items from specific dungeons
- Some players haven't completed certain dungeons at all
- Key levels vary and affect completion probability
- Some Players Dont have a keystone yet, but will be given one after their first dungeon completion.

Players currently solve this through manual discussion, checking multiple sources of information, and often miss optimal choices.

## Desired Outcome

NextKey should make the "what key should we run next?" decision automatic and optimal. When a group finishes a dungeon, they should immediately know:
1. Which available key gives the most benefit to the group
2. Why that key is beneficial
3. How to get to that dungeon quickly

## Core User Experience

### Operating Modes

1. **Premade Group Mode** (Default)
   - Full addon functionality assuming other players have the addon
   - Automatic key sharing and score syncing
   - Complex sorting and suggestions based on group data
   - Full travel assistance features

2. **PUG Mode**
   - Automatically activates when joining group finder groups
   - Can be manually toggled with `/nk pug`
   - Simplified interface focused on travel assistance
   - Detects dungeon from group finder context
   - No key sharing or complex sorting needed

### Key Moments

1. **Group Formation**
   Premade Groups:
   - As players join the group, their keystones are automatically shared
   - Their dungeon scores and loot needs are silently synced
   - Group leader sees a ranked list of available keys for manual selection
   - Group leader sets auto mode to auto select the best key

   PUG Groups:
   - Automatically detects dungeon from group finder
   - Shows immediate travel options for target dungeon
   - Simple UI focused on getting to the right place

2. **After Completing a Run**
   Premade Groups:
   - New keystones are automatically detected
   - Scores are immediately updated (not waiting for RaiderIO refresh)
   - A suggestion popup shows the best next key to run with auto-selected optimal choice

   PUG Groups:
   - Simplified travel window appears
   - Hearthstone and teleport options clearly displayed
   - No key suggestions or complex sorting

3. **Getting to the Dungeon**
   - One-click travel options (teleports, optional hearthstone button, optional beg for summon button)
   - Clear indication of when the user has the assigned key for the next dungeon in the teleport window
   - Easy key announcements to group to enable basic integration with non-addon users

### Information Display
- **Dungeon Cards**
  - Visual card-based interface for each available key
  - Card includes dungeon artwork and color-coded difficulty indicators
  - Interactive preference toggles for quick sorting adjustments
  - Individual sections for scores, loot, and group benefits
  - Smart hover tooltips with detailed breakdowns
  - Color-coded borders indicating completion status and timing potential

- Each card shows:
  - Dungeon name and key level
  - How many players would improve their score displayed as a + icon with the number of players next to it, tooltip shows which players and a +xx showing how much score they could get if the key was 3 chested, the available score from the key eg "Hunter-Hyjal (+115)"
  - Which players need items from it, displayed as a chest icon with a number beside it
  - Key owner name and server in class color
  - Personal preference indicators for quick filtering
  - Visual progress indicators for "bad luck protection" on desired loot

## Key Features

### 1. Contextual Mode Switching
- **Automatic PUG Detection**: Identifies group finder groups and switches modes
- **Manual Toggle**: `/nk pug` command for manual mode switching
- **Smart Defaults**: Remembers preferred mode per group type
- **Seamless Transition**: Smooth UI changes between modes

### 2. Smart Key Ranking
Multiple sorting algorithms that can be switched between:
- **Group Score Impact**: How many players would improve their rating
- **Score Impact**: IO gained total, could be all from 1 player. Ideal setting for a group with players boosting fresh alts or low scored players. 
- **Loot Value**: Based on player-marked desired items
- **Smart Sort**: Smart Sort (The All-Arounder): Uses a Borda Count points-based system. Run all four other sorts in the background. For each sorted list, award points based on rank (e.g., for 5 keys, 1st place gets 5 points, 2nd gets 4, etc.). The rank for each category must be stored in the key's data table for tooltip use. Sum the points for each key across all four lists The final ranking is ordered by the total accumulated points (descending).
- **Preference Based**: Sorts based on individual and group dungeon preferences, synced across the party
- **Manual**: Ignore the sorting and enable buttons for the group leader only that allow them to manually select a dungeon, that dungeon will be sent to the travel assistant for the group

### 2.1 Preference System
- **Individual Preferences**: Players can mark dungeons they prefer or want to avoid
- **Group Sync**: Preferences are automatically shared with party members
- **Visual Indicators**: Clear icons showing group member preferences on dungeon cards
- **Smart Weighting**: Preferences factor into scoring algorithms
- **Persistence**: Preferences saved per-character and per-season
- **Quick Toggle**: One-click preference changes from dungeon cards


### 2. Real-Time Score Tracking
- Maintains accurate scores even before RaiderIO updates
- Shows potential score improvements per dungeon

### 3. Loot Targeting
- Players mark items they want from a set of target items from specific dungeons
- Shows drop chances and attempt counts
- Celebrates when targeted items drop and puts into party chat how many runs of that dungeon it took to drop and a % drop chance
- Helps track "bad luck protection" progress

### 4. Travel Assistance
- Shows available teleport to the selected dungeon
- Shows to the person who has the selected key that their key has been selected by the sorting algorithm or group leader
- Pops up automatically when a mythic plus dungeon is completed
- If the group leader is in manual mode, shows a "Waiting for Group Leader to pick a key" message to let people know to wait, and if you are the group leader both the travel assistant and the main window showing the keys pops up when a dungeon is completed, this behavior can be toggled in options to not automatically pop up
- Optional button to beg for a summon in chat, has a default message but can be configured in options

## Success Criteria

The addon succeeds when:
1. Groups spend less than 30 seconds deciding next key
2. Players improve their scores more efficiently
3. Players get their targeted items faster
4. Travel to dungeons is streamlined
5. The addon's suggestions feel "obviously correct" to users

## Integration Points

### Required Data Sources
- RaiderIO for base scoring data
- Game API for keystone detection
- Game API for loot detection
- Game API for travel spell availability

### Expected User Actions
- Mark desired loot items in advance
- Respond to suggestion popups
- Keep RaiderIO addon updated

## Design Principles

1. **Minimal Setup**
   - Auto-detection wherever possible
   - Reasonable defaults
   - Optional fine-tuning

2. **Silent Efficiency**
   - Background data sync
   - Proactive calculations
   - Only show relevant info

3. **Clear Benefits**
   - Always explain why a key is ranked highly
   - Show potential gains for each option
   - Highlight time-saving opportunities

4. **Group Focused**
   - Consider all players' needs
   - Show impact on whole group
   - Facilitate group coordination

## Performance Expectations

- Initial sync under 2 seconds
- Suggestions appear within 1 second of run completion
- UI updates feel instant
- Minimal memory footprint
- No combat performance impact