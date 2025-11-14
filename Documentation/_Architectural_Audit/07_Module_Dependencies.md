# Module Dependencies Documentation

**Date**: November 14, 2025  
**Version**: 0.6.6  
**Status**: Phase 1 - Foundation Complete

This document explicitly maps dependencies for all major modules following the architectural refactor. Use this as a reference when making changes to ensure you don't break dependent modules.

---

## Dependency Documentation Template

```lua
-- MARK: Module Dependencies
-- Required: [List modules that MUST exist for this module to function]
-- Optional: [List modules with graceful fallbacks]
-- Announces: [List events/messages this module fires via SendMessage]
-- Listens: [List events/messages this module handles via RegisterMessage]
```

---

## Core Infrastructure Modules

### boot.lua

**Required Dependencies:**
- `NextKey222` namespace (created by embeds.xml)
- `core/config.lua` (AceDB configuration)
- `core/debugService.lua` (Debug system)
- `core/debugUI.lua` (Debug UI)

**Optional Dependencies:** None (all dependencies are required)

**Announces:**
- None (boot is initialization only)

**Listens:**
- `ADDON_LOADED` (WoW event)
- `PLAYER_LOGIN` (WoW event)

**Notes:** This is the primary hotspot - changes here affect the entire addon.

---

### core/config.lua

**Required Dependencies:**
- AceDB-3.0 (loaded via embeds.xml)

**Optional Dependencies:** None

**Announces:** None (configuration only)

**Listens:** None

**Notes:** Must load BEFORE boot.lua. Defines SavedVariables schema.

---

### core/debugService.lua

**Required Dependencies:**
- `NextKey222` namespace

**Optional Dependencies:** None

**Announces:**
- `DEBUG_MODE_CHANGED` (when debug level changes)

**Listens:** None

**Notes:** Must load BEFORE boot.lua. Used by all other modules.

---

## Domain-Specific Utility Modules (Phase 1 Refactor)

### core/utils/time.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:**
- `GetServerTime()` (WoW API - fallback to `time()` if unavailable)

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Independent utility module - no module dependencies.

---

### core/utils/player.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:**
- `UnitClass()`, `UnitFullName()`, `UnitName()` (WoW APIs with fallbacks)

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Independent utility module - no module dependencies.

---

### core/utils/communication.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:**
- `IsInGroup()`, `IsInRaid()` (WoW APIs with fallbacks)

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Independent utility module - no module dependencies.

---

### core/utils/dungeon.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)
- `NextKey_DungeonAliases` (global from data/portals.lua)
- `NextKey_DungeonNames` (global from data/portals.lua)

**Optional Dependencies:** None

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Depends on portal data being loaded first.

---

### core/utils/item.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:** None

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Independent utility module - no module dependencies.

---

### core/utils/scoring.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:**
- `C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor()` (WoW API)
- `NextKey222.RaiderIO.GetScoreColor()` (fallback for score coloring)

**Announces:** None (pure utility functions)

**Listens:** None

**Notes:** Uses RaiderIO as fallback if Blizzard API unavailable.

---

### core/utils.lua (Backward Compatibility Shim)

**Required Dependencies:**
- All `core/utils/*.lua` modules (forwards calls to specialized utils)

**Optional Dependencies:**
- All domain-specific utils have graceful fallbacks built into the shim

**Announces:** None

**Listens:** None

**Notes:** **TODO: Remove this shim after all modules updated to use specialized utils directly.**

---

## Constants Module

### core/constants.lua

**Required Dependencies:**
- `NextKey222.RegisterModule` (from boot.lua)

**Optional Dependencies:** None

**Announces:** None (configuration only)

**Listens:** None

**Notes:** Phase 1 enhanced with domain namespacing (UI, PERFORMANCE, KEYSTONES, ORGANIZER).

---

## Service Modules

### core/ioCalculator.lua

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`
- `C_MythicPlus` (WoW API)
- `C_ChallengeMode` (WoW API)

**Optional Dependencies:**
- `NextKey222.RaiderIO` (for score calculations)
- `NextKey222.Profiles` (for player data)

**Announces:**
- None (service module - direct API calls)

**Listens:**
- None (service module - called on-demand)

**Notes:** Pure service module - no events, only direct API calls.

---

### core/scoring.lua

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`

**Optional Dependencies:**
- `NextKey222.RaiderIO`
- `NextKey222.IOCalculator`

**Announces:** None (service module)

**Listens:** None (service module)

**Notes:** Pure service module - no events, only direct API calls.

---

### core/organizer/sorting.lua

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`

**Optional Dependencies:** None

**Announces:** None (service module)

**Listens:** None (service module)

**Notes:** Pure service module following the service pattern. Provides `CalculateSequentialAssignment()` API.

---

## Feature Modules

### core/organizer/state.lua (OrganizerState)

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`
- `NextKey222.Addon.db` (AceDB for persistence)

**Optional Dependencies:** None

**Announces:**
- `ORGANIZER_PLAYER_ADDED`
- `ORGANIZER_PLAYER_MOVED`
- `ORGANIZER_PLAYER_REMOVED`
- `ORGANIZER_KEYSTONE_DESIGNATED`
- `ORGANIZER_POLL_STARTED`
- `ORGANIZER_POLL_RESPONSE`
- `ORGANIZER_STATE_CHANGED`

**Listens:** None (state module - modified via API calls)

**Notes:** Single source of truth for organizer data. Announces state changes via events.

---

### core/PugHelper/main.lua

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`
- `NextKey222.Addon.db` (for configuration)

**Optional Dependencies:**
- `NextKey222.SetTeleportTargetKey` (for teleport integration)
- `NextKey222.SetTeleportWindowContext` (for PUG mode teleport)

**Announces:**
- `PUG_RUN_COMPLETED` (after M+ completion in PUG group)

**Listens:**
- `LFG_SEARCH_RESULTS_UPDATED`
- `LFG_APPLICATION_STATUS_CHANGED`
- `GROUP_INVITE_CONFIRMATION`

**Notes:** Event-driven architecture. Excellent reference implementation for modular design.

---

## UI Modules

### ui/main.lua

**Required Dependencies:**
- `NextKey222.MainWindow`
- `NextKey222.UIControls`
- `NextKey222.ViewManager`
- `NextKey222.UIRendering`
- `NextKey222.UICalculations`
- `NextKey222.UIPerformance`

**Optional Dependencies:**
- `NextKey222.DungeonWindow`
- `NextKey222.UIComponents`

**Announces:**
- None (facade delegates to specialized modules)

**Listens:**
- `GROUP_ROSTER_UPDATE` (via OnGroupRosterUpdate)
- `PLAYER_SPECIALIZATION_CHANGED` (via OnSpecChanged)

**Notes:** Facade pattern - delegates to specialized UI modules.

---

## Communications Module

### core/comms.lua

**Required Dependencies:**
- `NextKey222.Debug`
- `NextKey222.SafeRun`
- `NextKey222.Constants.COMM_PREFIX`
- `AceComm-3.0`
- `AceSerializer-3.0`

**Optional Dependencies:**
- `NextKey222.OrganizerState` (for organizer message routing)
- `NextKey222.Profiles` (for IO data caching)

**Announces:**
- Forwards organizer messages to `OrganizerState`
- Forwards IO data updates

**Listens:**
- `TELEPORT_SELECT` (leader keystone selection sync)
- `PLAYER_IO_UPDATE` (IO data sharing)
- `ORG_*` (organizer opcodes)

**Notes:** Central message router. Should be pure router (no business logic).

---

## Dependency Chain Summary

### Critical Path (Load Order):
1. `embeds.xml` (Ace3 libraries)
2. `core/config.lua` (configuration schema)
3. `core/debugService.lua` (debug system)
4. `core/debugUI.lua` (debug UI)
5. `boot.lua` (addon initialization)
6. Domain-specific utils (`core/utils/*.lua`)
7. `core/utils.lua` (backward compatibility shim)
8. `core/constants.lua` (enhanced constants)
9. Service modules (IOCalculator, Scoring, etc.)
10. Feature modules (Organizer, PUG Helper)
11. UI modules (main, teleport, etc.)

### High-Risk Dependencies (Changes Affect Many Modules):
- `boot.lua` - Everything depends on this
- `core/debugService.lua` - Used by all modules
- `core/utils/*.lua` - Used throughout codebase (via shim)
- `NextKey222.SafeRun` - Used for error handling everywhere

---

## Migration Guidelines

When refactoring a module to use domain-specific utils:

**Before:**
```lua
local shortName = NextKey222.Utils.getShortName(playerName)
```

**After:**
```lua
local shortName = NextKey222.PlayerUtils.getShortName(playerName)
```

**Compatibility Note:** Both forms work during migration period due to backward compatibility shim in `core/utils.lua`.

---

## Next Steps

After Phase 1 (Foundation) completion:
- Phase 2: Implement Pluggable Sorting System
- Phase 3: Refactor Organizer to full event-driven architecture
- Phase 4: Refactor Communications to pure message router
- Phase 5: Final UI layer cleanup
