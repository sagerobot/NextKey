# NextKey Current Context

## Current Status
**Date**: November 17, 2025
**Version**: 0.6.0
**Current Phase**: Phase 4 In Progress — Event-Driven Core Module Refactoring
**Authoritative Note**: This file is the canonical snapshot of the current system state for AI and future contributors.

## Recent Completions

### 0. Phase 5: UI Layer Refactor ✅ **COMPLETE** (November 18, 2025)

**Goal**: Final UI cleanup, standardization, and performance optimization.

**Task 5.1: Extract Remaining UI Logic from ui/main.lua** ✅
- Extracted metadata enrichment to `ui/metadata.lua` (224 lines)
- Extracted profile caching to `ui/profiles.lua` (129 lines)
- Reduced `ui/main.lua` by 16% (277 lines removed)
- **Critical Bug Fix**: Fixed AceEvent callback signature in `ui/main.lua` (role icons now update correctly on spec changes)

**Task 5.2: Standardize Component Creation via Factories** ✅
- Standardized native frame factories in `ui/components.lua`
- Renamed legacy factories to `CreateNative*` for clarity
- Updated `ui/keystoneCards.lua` and `ui/dungeonCards.lua` to use new factory names
- Improved code clarity regarding AceGUI vs Native frames

**Task 5.3: Implement Render Queuing for Performance** ✅
- Implemented non-blocking render queue in `ui/performance.lua`
- Added `EnqueueRenderItems` and `render_card` task type
- Updated `ui/rendering.lua` to support granular render tasks
- Updated `ui/main.lua` to delegate `PrepareRenderData` to `UIRendering`
- Preserved immediate render fallback for safety

**Status**: ✅ **COMPLETE** - UI layer is now modular, standardized, and performant.

### 1. Phase 4.3: Profiles Event-Driven Validation ✅ **COMPLETE** (November 17, 2025)

**Architecture Discovery: ProfilesService Already Implements Target Pattern**

- Created comprehensive analysis: [`Documentation/_Architectural_Audit/15_Profiles_Event_Analysis.md`](Documentation/_Architectural_Audit/15_Profiles_Event_Analysis.md:1) (732+ lines)
  - Complete architecture review of ProfilesService (1164 lines)
  - Cache implementation analysis (LRU + TTL pattern)
  - Event system documentation (9 listeners + event announcements)
  - UI refresh mechanism discovery (delayed timer callbacks)
  - Validation checklist and best practices guide

- **Key Finding**: ProfilesService **already implements** cache + event pattern perfectly!
  - LRU cache with 100-entry limit and 5-minute TTL
  - Event-driven invalidation (9 Blizzard events + 2 custom messages)
  - Event announcements via `NEXTKEY_PROFILE_UPDATED`
  - Pure service pattern (zero UI dependencies)
  - Performance monitoring and metrics tracking

- **Critical Discovery**: Self-contained UI refresh mechanism
  - Built-in delayed timer callbacks (500ms for spec changes)
  - Pull model with event-driven invalidation (optimal design)
  - No UI event listeners needed - cache invalidation ensures fresh data on next pull
  - User confirmed: "The UI actually does refresh when spec changes happen"

- **Event Flow** ([`core/profiles.lua:204-220`](core/profiles.lua:204)):
  1. Spec change event fires → ProfilesService invalidates cache
  2. 500ms delayed timer triggers (allows Blizzard API to update)
  3. `RefreshUIComponents()` announces `NEXTKEY_PROFILE_UPDATED`
  4. Next `GetProfile()` call rebuilds from adapters with fresh data

- **Architecture Pattern**: Pull Model + Event-Driven Invalidation
  - UI calls `GetProfile()` when rendering (pull model)
  - Service invalidates cache on events (event-driven)
  - Cache ensures performance (avoids repeated adapter calls)
  - Next pull gets fresh data automatically

**Status**: ✅ **PRODUCTION-READY** - Serves as reference implementation for NextKey's event-driven architecture

**No refactoring needed** - existing implementation is exemplary

### 1. Phase 4.2: Keystones Event-Driven Refactor ✅ **COMPLETE** (November 17, 2025)

**Event-Driven Architecture Implementation**

- Created comprehensive analysis: [`Documentation/_Architectural_Audit/14_Keystones_Event_Analysis.md`](Documentation/_Architectural_Audit/14_Keystones_Event_Analysis.md:1) (1104 lines)
  - Identified 7 state change categories
  - Defined 6 events with complete payload structures
  - Created step-by-step implementation plan
  - Testing checklist and success criteria

- Implemented event infrastructure in Keystones: [`core/keystones.lua`](core/keystones.lua:1)
  - Added `AnnounceEvent()` helper method with SafeRun wrapper
  - Updated 5 state mutation methods to fire events:
    - `ScanPlayerKeystone()` → `KEYSTONE_PLAYER_DETECTED`
    - Player removal → `KEYSTONE_PLAYER_REMOVED`
    - `CollectPartyKeys()` → `KEYSTONE_SCAN_COMPLETE`
    - `StoreGuildKeystone()` → `KEYSTONE_GUILD_RECEIVED`
    - `SetTeleportTargetKey()` → `KEYSTONE_TELEPORT_SELECTED` / `KEYSTONE_TELEPORT_CLEARED`
  - All events include complete payloads with context
  - Debug logging via `keystones` category

- Added KEYSTONE_EVENTS to constants: [`core/constants.lua`](core/constants.lua:1) (lines 64-80)
  - 6 event definitions for all keystone state changes
  - Includes player detection, scanning, guild reception, teleport selection

- Implemented UI event listeners:
  - [`ui/main.lua`](ui/main.lua:1) (lines 359-456):
    - `OnPlayerKeystoneDetected()` - triggers UI refresh
    - `OnKeystoneScanComplete()` - updates scan status and refreshes results
    - `OnTeleportSelected()` - logs selection
    - Recursion guards with `_handlingKeystoneEvent` flag
  - [`ui/teleport.lua`](ui/teleport.lua:1) (lines 897-961):
    - `OnTeleportSelectedEvent()` - refreshes teleport window
    - `OnTeleportClearedEvent()` - hides teleport window
  - Event registration in [`boot.lua`](boot.lua:1) PostInit phase

- Critical Bug Fixes:
  - Fixed nil-safety error when accessing `payload.sourceCounts`
  - Fixed C stack overflow (infinite event loop) with guard flag
  - Recursion prevention with `_handlingKeystoneEvent` guard

**Status**: ✅ Complete and validated in-game — All workflows working correctly

### 1. Phase 4.1: Communications Refactor — Week 1 ✅ **COMPLETE** (November 16, 2025)

**Analysis & PlayerDataService Extraction**

- Created comprehensive refactor analysis: [`Documentation/_Architectural_Audit/13_Communications_Refactor_Analysis.md`](Documentation/_Architectural_Audit/13_Communications_Refactor_Analysis.md:1) (878 lines)
  - Identified 5 major problems in Communications architecture
  - Documented all 12 opcodes and their handling
  - Defined 14 COMM_EVENTS for opcode → event mapping
  - Created 3-week extraction plan

- Extracted PlayerDataService: [`core/playerDataService.lua`](core/playerDataService.lua:1) (379 lines)
  - Moved 240+ lines of IO data management from Communications
  - Manages playerIOCache independently
  - Event-driven architecture:
    - Listens: `COMM_EVENTS.PLAYER_IO_RECEIVED`, `COMM_EVENTS.PLAYER_IO_REQUEST`
    - Announces: `PLAYER_IO_UPDATED`, `PLAYER_IO_CACHE_CLEANED`
  - Key methods:
    - `CreateIOPackage(playerName)` — builds IO data packet
    - `SharePlayerIOData()` — broadcasts via Communications
    - `OnIODataReceived(payload)` — processes received IO data
    - `EnsureCurrentPlayerIOData()` — lazy initialization

- Implemented event infrastructure in Communications:
  - Added `AnnounceEvent()` helper method
  - All 12 opcodes announce events via `GetEventNameForOpcode()`
  - Added `RegisterEventListeners()` for backward compatibility
  - Event flow: Network message → Parse → AnnounceEvent → Legacy handlers
  - Maintains dual-path system during migration

- Added COMM_EVENTS to constants: [`core/constants.lua`](core/constants.lua:1)
  - 14 event definitions for all communication types
  - Includes organizer events, IO events, keystone events, teleport events

- Added debug category: `player_data` (Data Processing group)
  - Available in `/nk config` → Debug System
  - Validated operational in-game

**Status**: ✅ Week 1 Complete — Event system operational, PlayerDataService extracted and validated

**Next Steps (Week 2)**:
- Extract keystone sharing logic → KeystoneService
- Remove direct UI calls from Communications
- Complete end-to-end communication path testing

### 1. Phase 2 Architectural Refactoring ✅ **COMPLETE & VALIDATED** (November 14-15, 2025)

#### Phase 2.1: Pluggable Sorting System ✅ **VALIDATED IN-GAME**
- Implemented registry-based sorting system in [`core/sorting/main.lua`](core/sorting/main.lua:1)
- Created 7 modular sorting algorithms:
  - `core/sorting/algorithms/bySmartSort.lua` - Borda count algorithm (priority 100, default)
  - `core/sorting/algorithms/byMaxGroupIO.lua` - Maximize total group IO gain (priority 90)
  - `core/sorting/algorithms/byPlayerCoverage.lua` - Maximize benefiting players (priority 85)
  - `core/sorting/algorithms/byItemNeed.lua` - Prioritize loot targeting (priority 80)
  - `core/sorting/algorithms/byKeyLevel.lua` - Sort by highest key level (priority 75)
  - `core/sorting/algorithms/byKeyLevelAsc.lua` - Sort by lowest key level (priority 70)
  - `core/sorting/algorithms/byIOGain.lua` - IO gain potential (priority 65)
- UI Integration:
  - Updated [`ui/main.lua`](ui/main.lua:917) `UpdateSortDropdownOptions()` to dynamically populate from registry
  - Dropdown now uses `Sorting:GetAlgorithmsForContext("KEYSTONES")` for automatic population
  - Context-aware filtering (KEYSTONES, DUNGEONS, ORGANIZER)
  - Priority-based ordering in dropdown
- Benefits:
  - Clean algorithm registration via `RegisterAlgorithm(name, metadata, sortFn)`
  - Easy to add new sorting modes without modifying core code
  - Metadata-driven UI integration (displayName, description, priority)
  - Follows PUG Helper compositional architecture pattern
  - All 7 algorithms properly registered and validated in-game
- Files Modified:
  - [`NextKey.toc`](NextKey.toc:92) - Added 4 new algorithm files to load order
  - [`ui/main.lua`](ui/main.lua:917) - Dynamic dropdown population
  - [`options/main.lua`](options/main.lua:303) - Fixed Boosting Team generator to properly set addonStatus
- **Status**: ✅ Complete and validated - all algorithms working correctly in-game

#### Phase 2.2-2.3: Service Module Validation
- Validated IOCalculator, ProfilesService, and Scoring as pure service modules
- Confirmed compliance with service pattern:
  - ✅ No UI dependencies (synchronous APIs only)
  - ✅ One-way dependencies (UI → Services)
  - ✅ SafeRun wrapped critical operations
  - ✅ Graceful error handling
- Created comprehensive analysis: [`Documentation/_Architectural_Audit/08_Service_Module_Analysis.md`](Documentation/_Architectural_Audit/08_Service_Module_Analysis.md:1)

#### Phase 2.4: Service Module Improvements
**IOCalculator - Removed Duplicate Memoization Logic (206 lines removed)**
- Before: Duplicate score lookup logic in `GetPlayerDungeonScore()` and `_GetPlayerDungeonScore_Original()`
- After: Clean memoization wrapper + single internal implementation
- Impact:
  - Single source of truth for score lookup
  - Easier maintenance and testing
  - 206 lines of duplicate code eliminated

**ProfilesService - Event-Based UI Refresh Pattern**
- Before: Direct UI calls in `RefreshUIComponents()` created soft UI dependency
- After: Event announcement via `NEXTKEY_PROFILE_UPDATED` message
- Impact:
  - Pure service pattern maintained (zero UI knowledge)
  - UI modules listen and refresh themselves
  - Better testability and flexibility
  - Follows established NextKey event patterns

#### Phase 1 Completions (November 13-14, 2025)
- Split `core/utils.lua` into domain-specific modules:
  - `core/utils/time.lua`, `core/utils/player.lua`, `core/utils/communication.lua`
  - `core/utils/dungeon.lua`, `core/utils/item.lua`, `core/utils/scoring.lua`
- Namespaced `core/constants.lua` by domain
- Documented module dependencies in [`Documentation/_Architectural_Audit/07_Module_Dependencies.md`](Documentation/_Architectural_Audit/07_Module_Dependencies.md:1)

### 1. OrganizerState — Single Source of Truth ✅
- Implemented [`OrganizerState`](core/organizer/state.lua:1) as the central state module for the M+ Group Organizer.
- Responsibilities:
  - Stores players, bench, opt-out, groups, designated keystones, and active poll state.
  - Provides safe, debugged APIs for:
    - Adding/updating/removing players
    - Moving players between bench/opt-out/group slots
    - Managing designated keystones
    - Managing poll lifecycle and responses
  - Persists only real players (filters fake/simulated) via SavedVariables.
- Impact:
  - Organizer UI (roster board, cards, etc.) now treats cards as views keyed by playerID.
  - Eliminates prior data loss and inconsistent state across rebuilds and interactions.

### 2. Handshake Protocol & Unified Poll System ✅
- Organizer/participant discovery and poll flows standardized through Communications:
  - `ORG_ADDON_PING` / `ORG_ADDON_PONG` for addon presence discovery.
  - `ORG_POLL_REQUEST` / `ORG_POLL_RESPONSE` for structured poll exchange.
  - Routed via [`Communications:ProcessMessage()`](core/comms.lua:413).
- Poll responses are:
  - Stored in OrganizerState (no more silent loss).
  - Used to populate spec preferences, roles, and metadata for organizer UI.
- Result:
  - Deterministic, debuggable handshake/poll pipeline suitable for real groups and simulations.

### 3. Teleport Selection Sync (Leader-Synced) ✅ **VALIDATED PRODUCTION-READY** (November 15, 2025)

**Status**: ✅ Completed architectural validation - NO REFACTORING REQUIRED

**Validation Report**: [`Documentation/_Architectural_Audit/09_Teleport_System_Validation.md`](Documentation/_Architectural_Audit/09_Teleport_System_Validation.md:1) (425 lines)

The teleport system demonstrates exemplary event-driven architecture and serves as a reference implementation for NextKey modules.

Key Architecture Validations:
1. **Single-Source API** ✅
   - Canonical entry point: [`NextKey:SetTeleportTargetKey(keyInfo, opts)`](core/keystones.lua:1114)
   - All flows call this method - prevents divergence
   - Pure coordinator pattern with no business logic

2. **Leader-Only Broadcast** ✅
   - Dual enforcement via `IsLeaderOrSolo()` checks
   - Implemented in [`Communications:BroadcastTeleportSelection()`](core/comms.lua:39)
   - Multiple validation guards prevent invalid broadcasts
   - Minimal payload (only essential key data)

3. **TELEPORT_SELECT Reception** ✅
   - Centralized handler in [`Communications:ProcessMessage()`](core/comms.lua:428)
   - Echo prevention (double-checked, ignores own messages)
   - Payload validation before applying changes
   - Uses single-source API with `broadcast = false` to prevent loops
   - Auto-opens teleport window on receivers

4. **Teleport UI Integration** ✅
   - Unified window: [`ui/teleport.lua:801`](ui/teleport.lua:801)
   - Supports normal mode, PUG mode, and Leave Group
   - Context-aware via `SetTeleportWindowContext({ mode = "PUG", ... })`
   - Pure view layer that reacts to state changes
   - Auto-refresh on target key changes

Compliance Verified:
- ✅ Event-driven pattern compliance
- ✅ No broadcast loops (explicit `broadcast = false` on remote selections)
- ✅ Clean separation of concerns
- ✅ PUG mode integration via context system

Result:
- **Production-ready** with excellent architectural compliance
- Serves as reference implementation for other NextKey systems
- Zero architectural changes needed

### 4. Organizer Communications & Data Flows ✅
- Organizer-specific comms standardized via:
  - [`core/organizer/comms.lua`](core/organizer/comms.lua:1) (OrganizerComms)
  - Core comms router in [`core/comms.lua`](core/comms.lua:413)
- Responsibilities:
  - Organizer discovery (PING/PONG)
  - Poll requests/responses
  - Roster state snapshots and deltas
  - Keystone designation updates
  - Optimizer status messages (planned/partial)
- All organizer messages:
  - Use shared `COMM_PREFIX`.
  - Are validated and routed centrally.
  - Respect throttling and batching rules.

### 5. PUG Mode Architecture & Hardening (Implementation Complete, Validation Active) ✅/🧪

PUG Mode is now a composed, stateful system:

Components:
- Orchestrator:
  - [`core/pugHelper.lua`](core/pugHelper.lua:1) — main entry, wires event handlers and helpers.
- State Machine:
  - [`core/pugHelper_state.lua`](core/pugHelper_state.lua:1)
    - Defines states: `IDLE`, `TRACKING`, `INVITE_RECEIVED`, `IN_GROUP`, `RUN_COMPLETE`.
    - Enforces valid transitions with detailed debug.
    - Manages primary invite lock (first-accepted-wins) via `primaryInvite` + `activeInviteID`.
- LFG Applications:
  - [`core/pugHelper_applications.lua`](core/pugHelper_applications.lua:1)
    - Throttled processing of `C_LFGList` events.
    - Caches search results and maps them to applications.
    - Tracks status history, drives:
      - First-accepted-wins logic
      - Teleport targeting via `OnMPlusAccepted`.
- Group Detection:
  - [`core/pugHelper_detection.lua`](core/pugHelper_detection.lua:1)
    - Detects `PUG`, `GUILD`, `PREMADE`, `SOLO` using:
      - Active LFG entry
      - PUGHelper markers
      - Guild composition.
- UI Helpers:
  - [`ui/pugInviteNotification.lua`](ui/pugInviteNotification.lua:1)
  - [`ui/pugTravelAssistant.lua`](ui/pugTravelAssistant.lua:1)
  - [`ui/pugApplicationTracker.lua`](ui/pugApplicationTracker.lua:1) (debug/visualization)
- Teleport Integration:
  - PUG flows do NOT invent separate teleport UIs:
    - They use `NextKey:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })` and
      `NextKey:SetTeleportWindowContext({ mode = "PUG", ... })` to drive the shared teleport window.
    - After M+ completion in a PUG:
      - Teleport window can auto-open in PUG mode with a Leave Group card.

Status:
- Architecture and implementation are in place.
- Hardening/validation is ongoing using real and simulated PUG runs.

## Architectural Impact

- Single sources of truth:
  - Organizer: OrganizerState for all organizer data.
  - Teleport: SetTeleportTargetKey for all key/teleport selections and TELEPORT_SELECT integration.
  - PUG: PUGHelper stack for PUG detection, LFG tracking, and PUG-mode teleport behavior.
- Communications:
  - All major flows route through [`core/comms.lua`](core/comms.lua:413) with strict validation, throttling, and debug.
- UI Integration:
  - Teleport window (`ui/teleport.lua`) is the unified travel surface:
    - Normal mode: leader-selected keystone teleports.
    - PUG mode: targeted travel and optional Leave Group step.

## Next Steps (Authoritative)

### Post-Refactor Validation (Current Focus)

**Phase 5 Complete**: UI Layer refactoring is finished.
- `ui/main.lua` is now a thin facade (<1500 lines)
- Component creation is standardized
- Render queuing is implemented for performance

**Next Steps**:
1. **Functionality Tests**: Verify all features work as expected.
2. **Performance Tests**: Check load time and memory usage.
3. **Stress Tests**: Test with many keystones/players.
4. **Integration Tests**: Test in real groups.
5. **Documentation Update**: Finalize all documentation.

**Phase 4 Status**: ✅ **COMPLETE** (November 16-17, 2025)
**Phase 5 Status**: ✅ **COMPLETE** (November 18, 2025)

### Phase 3 Priorities (Completed)

1. **OrganizerState & Organizer Validation** (Recommended)
   - Real-world validation in live groups:
     - Poll → OrganizerState → UI pipeline in real groups
     - Persistence and reload behavior for organizer data
     - Monitor performance with debug category `organizer_events`

2. **PUG Mode End-to-End Validation** (Ongoing)
   - LFG applications detected and tracked (throttled)
   - First-accepted-wins invite handling stable
   - PUG group correctly classified
   - Teleport window opens in PUG mode with appropriate context
   - Leave Group flow on dungeon completion behaves correctly

### Completed Phase 3 Tasks

- ✅ **Task 3.1: Refactor Organizer to Event-Driven** (November 16, 2025)
  - **Status**: COMPLETE - Event-driven architecture fully implemented
  - **Analysis Documents Created**:
    - [`Documentation/_Architectural_Audit/11_OrganizerState_Call_Analysis.md`](Documentation/_Architectural_Audit/11_OrganizerState_Call_Analysis.md:1) (348 lines)
    - [`Documentation/_Architectural_Audit/12_OrganizerState_Event_Definitions.md`](Documentation/_Architectural_Audit/12_OrganizerState_Event_Definitions.md:1) (690 lines)
  - **Implementation Results**:
    - OrganizerState announces 5 core events on all state mutations
    - RosterBoard listens and reacts to all events
    - Event-driven updates work alongside backward-compatible direct calls
    - Complete decoupling: State has zero UI knowledge
  - **Files Modified**:
    - [`core/organizer/state.lua`](core/organizer/state.lua:1) - Added `AnnounceEvent()` helper and event firing
    - [`ui/organizer/rosterBoard.lua`](ui/organizer/rosterBoard.lua:1) - Added event listeners and handlers
    - [`ui/organizer/modules/slotManager.lua`](ui/organizer/modules/slotManager.lua:1) - Added skipStateUpdate parameter
  - **Critical Bug Fixes**:
    - Fixed syntax error (extra `end` statements in SyncUIToState)
    - Fixed infinite event loop (C stack overflow from circular OnPlayerMoved → PlaceCardInSlot → MoveToSlot)
    - Fixed cards missing text in slots (added skipStateUpdate parameter)
    - Fixed animation crashes during sort (added isAnimating guard flag)
  - **Events Implemented**:
    - `ORGANIZER_PLAYER_ADDED` - Player added to organizer
    - `ORGANIZER_PLAYER_MOVED` - Player moved between locations
    - `ORGANIZER_PLAYER_UPDATED` - Player data updated
    - `ORGANIZER_POLL_RESPONSE_RECEIVED` - Poll response received
    - `ORGANIZER_STATE_CLEARED` - Entire state cleared
  - **Real-world Validation**: Recommended but optional (system is code-validated)

- ✅ **Task 3.2: Validate Teleport System** (November 15, 2025)
  - Comprehensive validation complete
  - Architecture confirmed as production-ready
  - Full report: `Documentation/_Architectural_Audit/09_Teleport_System_Validation.md`

- ✅ **Task 3.3: Validate Loot Tracking System** (November 15, 2025)
  - Comprehensive architectural validation completed
  - System is **PRODUCTION-READY** with minor recommendations
  - Full report: [`Documentation/_Architectural_Audit/10_Loot_Tracking_Validation.md`](Documentation/_Architectural_Audit/10_Loot_Tracking_Validation.md:1) (843 lines)
  - Key Findings:
    - ✅ Architecture follows NextKey patterns with clean 3-layer design
    - ✅ Persistence mechanism is robust and complete
    - ✅ Season-aware data structure properly implemented
    - ✅ Integration with dungeon cards and sorting system works correctly
    - ⚠️ Minor code cleanup recommended (duplicate toggle button)
  - Recommended Actions:
    - Complete in-game testing checklist (Section 8 of report)
    - Add season update task to memory-bank/tasks.md
    - Consider future enhancements (loot priority levels, migration helper)

- ✅ **Task 3.4: Fix Loot Window Display Issues** (November 16, 2025)
  - Fixed two critical bugs in loot window system:
    1. **UI Cleanup Bug** ([`ui/lootWindow.lua`](ui/lootWindow.lua:517))
       - Old item buttons were not properly cleared when switching dungeons
       - Added proper cleanup in `LootWindow:Update()` to destroy old frames
       - Prevents stale data from appearing across dungeon switches
    2. **Dungeon ID Mismatch Bug** ([`data/loot.lua`](data/loot.lua:1))
       - Loot data used incorrect dungeon IDs that didn't match portal data
       - Corrected all dungeon IDs to match official Blizzard Challenge Mode IDs:
         - Priory of the Sacred Flame: 523 → 499
         - The Dawnbreaker: 524 → 505
         - Eco-Dome Al'dani: 526 → 542
         - Tazavesh: Streets of Wonder: 401 → 391
         - Tazavesh: So'leah's Gambit: 402 → 392
       - Ara-Kara (503), Halls of Atonement (378), and Floodgate (525) already had correct IDs
  - Result: All 8 dungeons now correctly display their loot items without stale data
  - Status: **PRODUCTION-READY** - all dungeons validated working correctly

### Optional Enhancements (Low Priority)

- Phase 3: Options Menu Restructure
  - Current: Fake Player Tools successfully moved to top-level scrollable section
  - Consideration: Full options menu UI/UX overhaul for better organization
  - Priority: Low (current structure is functional and working)
