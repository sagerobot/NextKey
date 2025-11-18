# NextKey Current Status & Requirements

## Project Status
**Date**: November 17, 2025
**Version**: 0.6.0
**Phase**: Phase 4 In Progress — Event-Driven Core Module Refactoring

This file is the concise status mirror of the current codebase. For complete version history, see [`CHANGELOG.md`](../../../CHANGELOG.md).

## Completed

### 1. M+ Group Organizer UI
- `ui/organizer/rosterBoard.lua` and `ui/organizer/playerCard.lua` fully redesigned.
- Compact, single-line, draggable player cards for the bench.
- Visually distinct group slots with role-colored borders and class-colored cards.
- Card expansion on drop with detailed information.
- Role validation and "bounce-back" logic for invalid placements.
- Modern WoW API compatibility using texture-based UI (no deprecated SetBackdrop).
- Robust drag-and-drop handling using `OnMouseDown` / `OnMouseUp`.

### 2. OrganizerState Integration — Event-Driven Architecture ✅ **COMPLETE** (November 16, 2025)
- `core/organizer/state.lua` implemented as the SINGLE SOURCE OF TRUTH for organizer data:
  - Players, bench, opt-out, groups, keystones, active poll.
  - SafeRun-wrapped getters/setters and movement APIs.
  - Persistence of real players only; fake players filtered out.
  - **Event-Driven Pattern**:
    - All mutations announce events via `AnnounceEvent()` helper
    - 5 core events: PLAYER_ADDED, PLAYER_MOVED, PLAYER_UPDATED, POLL_RESPONSE_RECEIVED, STATE_CLEARED
    - Complete decoupling: State has zero UI knowledge
- Organizer UI (roster board, cards, etc.) listens for events and reacts:
  - Event listeners registered in `RosterBoard:Initialize()`
  - 5 event handler methods implemented
  - Visibility guards for performance optimization
  - Animation guards prevent event handling during sort animations
  - Cards are views only (read state, react to events)
- **Critical Bug Fixes**:
  - Fixed syntax error (extra `end` statements)
  - Fixed infinite event loop (C stack overflow)
  - Fixed cards missing text in slots (skipStateUpdate parameter)
  - Fixed animation crashes during sort (isAnimating guard flag)

### 3. Handshake & Unified Poll System
- Organizer discovery and polls standardized via:
  - `ORG_ADDON_PING` / `ORG_ADDON_PONG`
  - `ORG_POLL_REQUEST` / `ORG_POLL_RESPONSE`
- Routed centrally through `core/comms.lua` and `core/organizer/comms.lua`.
- Poll responses stored in OrganizerState to prevent data loss.

### 4. Teleport Selection Sync (Leader-Synced)
- Canonical API: `NextKey:SetTeleportTargetKey(keyInfo, opts)`:
  - All syncing flows call with `{ broadcast = true }` from leader to announce group key.
- `TELEPORT_SELECT`:
  - Implemented in `core/comms.lua`:
    - Validates payload.
    - Leader-only + group-context enforcement.
    - Routes to `SetTeleportTargetKey(..., { source = "remote_select", broadcast = false })` on receivers.
  - No echo, no rebroadcast loops.
- UI:
  - `ui/teleport.lua` auto-opens/updates teleport window on synced selection.

### 5. PUG Mode Architecture (Core Implementation)
- PUG Helper stack implemented and wired:
  - `core/pugHelper.lua`: Orchestrator.
  - `core/pugHelper_state.lua`: State machine + primary invite lock (first-accepted-wins).
  - `core/pugHelper_applications.lua`: Throttled LFG application tracking, search result caching, OnMPlusAccepted → teleport integration.
  - `core/pugHelper_detection.lua`: Group type detection (`PUG` / `GUILD` / `PREMADE` / `SOLO`).
- UI integrations:
  - `ui/pugInviteNotification.lua`: Enhanced invite notice.
  - `ui/pugTravelAssistant.lua`: Uses shared teleport window in PUG context.
  - `ui/pugApplicationTracker.lua`: Debug/visualization (SafeRun-wrapped).
- Teleport integration:
  - PUG flows use `SetTeleportTargetKey(..., { broadcast = false })` + `SetTeleportWindowContext({ mode = "PUG", ... })`.
  - No separate teleport UI; unified teleport window handles PUG mode and Leave Group behavior.

## In Progress / Validation

1. OrganizerState & Organizer (Optional Real-World Validation)
   - Code-level validation: ✅ COMPLETE
   - Event-driven architecture: ✅ COMPLETE
   - Recommended real-world validation:
     - End-to-end: handshake → poll → OrganizerState → events → UI
     - Persistence, reload, and fake-player filtering
     - Monitor with debug category `organizer_events`

2. Teleport Sync (TELEPORT_SELECT)
   - 5-man:
     - Leader selection syncs correctly to all addon clients.
     - Non-leader actions do not spam TELEPORT_SELECT.
   - Raid:
     - Validate raid-leader semantics and performance.
   - Confirm no regressions with auto-open behavior and user settings.

3. PUG Mode Hardening
   - Validate full flow:
     - LFG applications tracked and throttled.
     - First-accepted-wins invite handling via primary invite lock.
     - Correct PUG vs GUILD vs PREMADE vs SOLO classification.
     - Teleport window:
       - Opens in PUG mode with appropriate context.
       - Shows Leave Group option after PUG dungeon completion.
   - Ensure no AceGUI errors (per `PUG_MODE_FIXES_2025-11-08.md`) and SafeRun guards are effective.

4. Loot Targeting System
   - Loot Targeting implementation exists (0.2.1).
   - Re-validation required under the current architecture:
     - Data correctness, persistence, integration with dungeon cards and decision logic.

5. UI/Main.lua Refactor ✅ **COMPLETE**
   - **Status**: Fully implemented and verified (2025-11-09)
   - **Documentation**: See [`UI_MAIN_REFACTORING_PLAN.md`](../../../Documentation/FEATURES & PLANS/UI_MAIN_REFACTORING_PLAN.md) (archived)
   - **Achievement**: Transformed monolithic 3000+ line file into modular architecture
   
   **Final Architecture** (~1531 lines):
   - `ui/main.lua` functions as slim facade exposing stable public APIs
   - Delegates window lifecycle to `ui/mainWindow.lua`
   - Delegates header/controls to `ui/controls.lua`
   - Delegates view management to `ui/viewManager.lua`
   - Delegates rendering orchestration to `ui/rendering.lua`
   - Delegates IO calculations to `ui/ioCalculations.lua`
   - Delegates frame pacing to `ui/performance.lua`
   - Integrates debug helpers via `ui/debugHelpers.lua`
   - Slash commands centralized in `core/slashCommands.lua`
   
   **Architectural Goals Achieved**:
   - ✅ Clear separation of concerns with facade pattern
   - ✅ All critical responsibilities delegated to specialized modules (13 modules created)
   - ✅ Full backward compatibility (zero breaking changes)
   - ✅ SafeRun usage patterns preserved throughout
   - ✅ 49% code reduction through modularization
   
   **Verification**:
   - ✅ All in-game workflows tested and functional
   - ✅ Zero performance or UX regressions
   - ✅ Module load order validated in `NextKey.toc`

### 6. Independent Two-Window Architecture ✅ **COMPLETE**
   - **Status**: Fully implemented and verified (2025-11-10)
   - **Achievement**: Revolutionary two-window system allowing complete independence
   
   **Architecture**:
   - Keystone Selection Window: Party keystones with IO gain calculations
   - Dungeon Overview Window: Personal dungeon performance tracking
   - Each window has its own dedicated toggle button
   - Windows operate completely independently
   
   **Benefits**:
   - Greater flexibility for both group coordination and personal tracking workflows
   - Users can view party keys and personal performance simultaneously
   - Clean separation of concerns between group and personal data
   
   **Verification**:
   - ✅ Both windows function independently
   - ✅ Toggle buttons work correctly
   - ✅ No UI conflicts between windows

### 7. Phase 4.1: Communications Refactor — Week 1 ✅ **COMPLETE** (November 16, 2025)

- PlayerDataService extracted (379 lines)
- Event infrastructure implemented in Communications
- COMM_EVENTS constants added (14 events)
- Debug category `player_data` added and validated
- Analysis document created (878 lines)
- Status: ✅ Event system operational, validated in-game

### 8. Phase 4.2: Keystones Event-Driven Refactor ✅ **COMPLETE** (November 17, 2025)

- `core/keystones.lua` refactored to event-driven architecture:
  - Added `AnnounceEvent()` helper method
  - 5 state mutation methods fire events
  - Complete event payloads with context
  - Debug logging via `keystones` category
- KEYSTONE_EVENTS added to constants (6 events):
  - `KEYSTONE_PLAYER_DETECTED` - Player keystone detected/changed
  - `KEYSTONE_PLAYER_REMOVED` - Player keystone removed
  - `KEYSTONE_SCAN_COMPLETE` - Party scan completed
  - `KEYSTONE_GUILD_RECEIVED` - Guild keystone received
  - `KEYSTONE_TELEPORT_SELECTED` - Teleport target selected
  - `KEYSTONE_TELEPORT_CLEARED` - Teleport target cleared
- UI event listeners implemented:
  - `ui/main.lua`: 3 event handlers with recursion guards
  - `ui/teleport.lua`: 2 event handlers for teleport UI
  - Event registration in boot PostInit phase
- Critical bug fixes:
  - Nil-safety for `payload.sourceCounts`
  - C stack overflow prevention with `_handlingKeystoneEvent` guard
- Analysis document: `Documentation/_Architectural_Audit/14_Keystones_Event_Analysis.md` (1104 lines)
- Status: ✅ Production-ready, validated in-game

### 9. Phase 5: UI Layer Refactor ✅ **COMPLETE** (November 18, 2025)

- **Task 5.1: Extract Remaining UI Logic from ui/main.lua** ✅
  - Extracted metadata enrichment to `ui/metadata.lua` (224 lines)
  - Extracted profile caching to `ui/profiles.lua` (129 lines)
  - Reduced `ui/main.lua` by 16% (277 lines removed)
  - **Critical Bug Fix**: Fixed AceEvent callback signature in `ui/main.lua`

- **Task 5.2: Standardize Component Creation via Factories** ✅
  - Standardized native frame factories in `ui/components.lua`
  - Renamed legacy factories to `CreateNative*` for clarity
  - Updated `ui/keystoneCards.lua` and `ui/dungeonCards.lua` to use new factory names

- **Task 5.3: Implement Render Queuing for Performance** ✅
  - Implemented non-blocking render queue in `ui/performance.lua`
  - Added `EnqueueRenderItems` and `render_card` task type
  - Updated `ui/rendering.lua` to support granular render tasks
  - Updated `ui/main.lua` to delegate `PrepareRenderData` to `UIRendering`

## Upcoming Priorities

**Post-Refactor Validation** (Next Task)

1. **Functionality Tests**: Verify all features work as expected.
2. **Performance Tests**: Check load time and memory usage.
3. **Stress Tests**: Test with many keystones/players.
4. **Integration Tests**: Test in real groups.
5. **Documentation Update**: Finalize all documentation.

**Phase 4.1: Communications Refactor (Weeks 2-3)** (Ongoing)

Week 2 Tasks:
1. Extract keystone sharing logic → KeystoneService (may leverage Keystones events)
2. Remove direct UI calls from Communications
3. Complete organizer routing verification
4. End-to-end communication path testing

Week 3 Tasks:
1. Remove legacy playerIOCache from Communications
2. Deprecate direct call methods
3. Reduce Communications from 1357 → <500 lines
4. Final validation and documentation

**Other Priorities**

1. Complete PUG Mode validation and mark hardened path as stable.
2. Reconfirm Loot Targeting System behavior and update docs if needed.
3. Integrate future optimizers:
   - Optimizer-selected key must call:
     - `NextKey:SetTeleportTargetKey(bestKey, { broadcast = true })` for group sync.
4. Keep Memory Bank synchronized with any architectural or protocol changes:
   - OrganizerState schema
   - TELEPORT_SELECT semantics
   - PUG Helper stack behavior
   - Season data update process

## Version History

For a complete, detailed changelog of all releases and changes, see the main [`CHANGELOG.md`](../../../CHANGELOG.md) file in the project root.
