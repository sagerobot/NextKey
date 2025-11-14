# NextKey Current Context

## Current Status
**Date**: November 14, 2025
**Version**: 0.6.0
**Current Phase**: Architectural Refactoring — Phase 2 Complete (Sorting System & Service Module Hardening)
**Authoritative Note**: This file is the canonical snapshot of the current system state for AI and future contributors.

## Recent Completions

### 0. Phase 2 Architectural Refactoring ✅ **COMPLETE** (November 14, 2025)

#### Phase 2.1: Pluggable Sorting System ✅ **COMPLETE**
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
  - All 7 algorithms properly registered and ready for testing
- Files Modified:
  - [`NextKey.toc`](NextKey.toc:92) - Added 4 new algorithm files to load order
  - [`ui/main.lua`](ui/main.lua:917) - Dynamic dropdown population
- **Status**: Implementation complete, ready for in-game testing (Phase 2.5)

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

### 3. Teleport Selection Sync (Leader-Synced) ✅

Goal: When the leader selects a key (manually or via future optimizer), all addon users see the same teleport target and, if appropriate, the teleport window opens.

Key rules:
1. Single-source API:
   - Canonical entry point: [`NextKey:SetTeleportTargetKey(keyInfo, opts)`](core/keystones.lua:1078)
   - All flows that should sync must call:
     - `SetTeleportTargetKey(keyInfo, { broadcast = true })` from the leader.

2. TELEPORT_SELECT broadcast:
   - Implemented via Communications on top of the existing AceComm channel:
     - Payload: `opcode = "TELEPORT_SELECT"`, with minimal `key` data (dungeonID, level, etc.).
     - Sent only when:
       - Caller is leader or solo-intent per project rules.
       - Group context is valid (party/raid).
   - Thin helper; authoritative logic remains inside `SetTeleportTargetKey`.

3. TELEPORT_SELECT receive path:
   - Handled in [`Communications:ProcessMessage()`](core/comms.lua:413):
     - Ignores messages from local player (no echo).
     - Validates key payload.
     - Calls:
       - `NextKey:SetTeleportTargetKey(k, { source = "remote_select", broadcast = false, receivedFrom = sender })`
         - Ensures single-source API is used on all clients.
         - Prevents re-broadcast loops.
     - UI behavior:
       - If teleport window is not open and ToggleTeleportWindow exists:
         - Opens the teleport window to show the synchronized key.
       - If already open:
         - Teleport UI refresh logic reflects the new target.

Result:
- TELEPORT_SELECT is now:
  - Leader-only group announcement.
  - Single, well-defined meaning: “This is the key we are running now.”
  - Integrated with teleport window auto-open so all addon users see the chosen key.

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

1. OrganizerState & Organizer Validation
   - Validate:
     - Poll → OrganizerState → UI pipeline in real groups.
     - Persistence and reload behavior for organizer data.

2. Teleport Sync Validation
   - 5-man:
     - Leader selects key via main UI → all addon users receive TELEPORT_SELECT → teleport window shows correct key.
     - Non-leader selections do not broadcast.
   - Raid:
     - Raid leader behavior mirrors 5-man semantics.

3. PUG Mode End-to-End Validation
   - LFG applications detected and tracked (throttled).
   - First-accepted-wins invite handling stable.
   - PUG group correctly classified.
   - Teleport window opens in PUG mode with appropriate key/portal or generic PUG context.
   - Leave Group flow on dungeon completion behaves correctly.

4. Loot Targeting System Reconfirmation
   - Re-verify loot system correctness and UX within the current architecture.
   - Ensure future updates are recorded in the Memory Bank and CHANGELOG.
