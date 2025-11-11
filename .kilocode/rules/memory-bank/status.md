# NextKey Current Status & Requirements

## Project Status
**Date**: November 9, 2025
**Version**: 0.5.32
**Phase**: Active Development — Memory Optimization, Debug System Enhancements, M+ Group Organizer

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

### 2. OrganizerState Integration
- `core/organizer/state.lua` implemented as the SINGLE SOURCE OF TRUTH for organizer data:
  - Players, bench, opt-out, groups, keystones, active poll.
  - SafeRun-wrapped getters/setters and movement APIs.
  - Persistence of real players only; fake players filtered out.
- Organizer UI (roster board, cards, etc.) now reads from OrganizerState (cards are views only).

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

1. OrganizerState & Organizer
   - Live group validation:
     - End-to-end: handshake → poll → OrganizerState → UI.
     - Persistence, reload, and fake-player filtering.

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

5. UI/Main.lua Refactor
   - Status: ✅ **Complete** (Phases 1-7)
     - `ui/main.lua` now functions as a slim facade (~1940 lines, includes inline dungeon rendering and compatibility wrappers):
       - Registers `NextKey222.UI` and exposes a stable public API.
       - Delegates window lifecycle to [`ui/mainWindow.lua`](../../../ui/mainWindow.lua).
       - Delegates header/controls to [`ui/controls.lua`](../../../ui/controls.lua).
       - Delegates view toggling and UI mode detection to [`ui/viewManager.lua`](../../../ui/viewManager.lua).
       - Delegates keystone rendering orchestration to [`ui/rendering.lua`](../../../ui/rendering.lua).
       - Delegates IO gain/hashing helpers to [`ui/ioCalculations.lua`](../../../ui/ioCalculations.lua).
       - Delegates frame pacing to [`ui/performance.lua`](../../../ui/performance.lua) via `QueueFramePacedRender`.
       - Integrates debug helpers via [`ui/debugHelpers.lua`](../../../ui/debugHelpers.lua).
       - Slash commands centralized in [`core/slashCommands.lua`](../../../core/slashCommands.lua).
     - Architectural goals achieved:
       - ✅ Clear separation of concerns with facade pattern.
       - ✅ All lifecycle, view management, rendering orchestration, performance, and calculations delegated to specialized modules.
       - ✅ Full backward compatibility (all public APIs preserved).
       - ✅ SafeRun usage patterns preserved throughout.
     - Remaining inline code (optional future extraction):
       - Dungeon view rendering (`RenderDungeonCards`, `AddDungeonRowCompact`).
       - Fake player handlers (`HandleAddDebugFakePlayer`, etc.) - could call into UIDebugHelpers.
       - Entry metadata enrichment (`EnrichEntryMetadata`).
       - Backward-compatible wrappers and fallback paths.
   - Full in-game verification complete:
     - ✅ `/nk` open/close, view toggle, guild/party toggle.
     - ✅ Teleport + organizer buttons.
     - ✅ Debug/fake player tools and frame pacing behavior.
     - ✅ All sort modes functional.
     - ✅ No regressions in UX or performance.

## Upcoming Priorities

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
