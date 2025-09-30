# NextKey AI Development Guide

This document provides essential context for AI agents working with the NextKey World of Warcraft addon codebase.

## Project Overview

NextKey is a Mythic+ keystone optimization addon that helps groups choose their next dungeon run by analyzing party members' keystones, scores, and loot preferences.

## Core Architecture

- Built on **Ace3 Framework** - uses multiple Ace3 libraries for core functionality:
  - `AceAddon-3.0` - Core addon structure
  - `AceComm-3.0` - Inter-player communication (prefix: `NKEY`)
  - `AceDB-3.0` - SavedVariables management (`NextKeyDB`)
  - `AceConfig-3.0/AceGUI-3.0` - Configuration UI

## Code Organization

The codebase uses `-- MARK:` comments for quick navigation in VS Code. Major sections should be marked following this pattern:

```lua
-- MARK: Initialization & Setup
-- Core addon initialization code...

-- MARK: Event Handlers
-- Event registration and handlers...

-- MARK: UI Components
-- UI frame creation and updates...

-- MARK: Data Management
-- Data processing and state management...

-- MARK: Communication
-- Inter-player message handling...
```

Common MARK categories:
- Initialization & Setup
- Event Handlers
- UI Components
- Data Management
- Communication
- Utility Functions
- Frame Management
- State Updates

Example organization from `KeyTracker.lua`:
```lua
-- MARK: My Keystone
-- Personal keystone tracking

-- MARK: Cooldown Update Function
-- Spell cooldown management

-- MARK: Request Functions
-- Party keystone data requests

-- MARK: Sync Keys
-- Cross-addon communication
```

## Critical Files & Components

- `Core.lua` - Main addon initialization and core logic
- `Events.lua` - WoW event handlers
- `Options.lua` - AceConfig tables for settings
- `MythicPlusOptions.lua` - M+ specific configuration
- `UI.lua` - Main interface components 
- `PortalDB.lua` - Dungeon teleport data
- `TeleportWindow.lua` - Travel assistance UI

## Key Data Structures

```lua
-- Communication payload structure
{
    keystone = { dungeonID, level, ownerName },
    scores = { [dungeonID] = bestScore },
    liveRun = { dungeonID, level, timedSuccess },
    lootTargets = { [itemID] = true }
}

-- SavedVariables (NextKeyDB)
{
    global = {
        leaderSettings = { autoSuggestEnabled, defaultSortMode }
    },
    char = {
        liveRuns = {},
        targetedItems = {},
        dungeonRunCounts = {}
    }
}
```

## Development Patterns

1. **Event Handling**: Register through `AceEvent-3.0`:
   ```lua
   NextKey:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnMythicPlusCompleted")
   ```

2. **Inter-player Communication**: Use `AceComm-3.0` for party data sync:
   ```lua
   NextKey:SendCommMessage("NKEY", serializedData, "PARTY")
   ```

3. **Settings**: Add new options in `Options.lua` using AceConfig structure

4. **SavedVariables**: Access through `NextKey.db.global` or `NextKey.db.char`

## Dependencies

- Hard dependency on **Raider.IO** addon for score data
- Test with both retail and PTR WoW clients (check Interface version in .toc)

## Common Workflows

1. **Adding New Features**:
   - Register event handlers in `Events.lua` (use MARK comments for organization)
   - Add configuration in `Options.lua`
   - Implement UI components in `UI.lua` (group related components under MARK sections)
   - Update communication payload if needed

2. **Testing**:
   - Use `/nk` or `/nextkey` commands
   - Test in 5-player party context
   - Verify cross-realm communication