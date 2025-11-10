# UI/Main.lua Refactoring Plan

**Status**: Phase 3 (IO + Rendering) In Progress / Partially Implemented  
**Start Date**: 2025-11-10  
**Estimated Duration**: 4-6 weeks  
**Current Phase**: Phase 3-4 - Extract Calculation & Rendering Orchestration Modules

---

## Executive Summary

Refactor `ui/main.lua` into focused modules with clear responsibilities and minimal coupling. The file has already been partially decomposed:

- Phase 1: Stateless capability/utility/score modules extracted and wired.
- Phase 2: Rendering modules (tooltips, keystone cards, dungeon view) extracted and wired.
- Phase 3: IO calculations module introduced; keystone render orchestration begins migration.
- `ui/main.lua` is progressively becoming a coordinator: state + public API, delegating real work.

This document tracks remaining planned decomposition to keep alignment with the NextKey222 architecture.

**Key Metrics (current after latest changes):**
- Original: 1 file, ~3,960 lines
- Current:
  - `ui/main.lua`: slimmer (orchestrator + performance + state; keystone render logic mostly delegated)
  - Extracted:
    - `ui/playerCapabilities.lua`
    - `ui/utilities.lua`
    - `ui/scoreCalculations.lua`
    - `ui/tooltips.lua`
    - `ui/keystoneCards.lua`
    - `ui/dungeonView.lua`
    - `ui/ioCalculations.lua`
    - `ui/rendering.lua`
- Target: Slim `ui/main.lua` (~300-400 lines) acting as coordinator; supporting modules own implementation details.

---

## Module Breakdown

This table reflects actual implementation status plus planned modules.

### Core Modules

| #  | Module                     | Lines (Target) | Status         | Dependencies                                   |
|----|----------------------------|----------------|----------------|-----------------------------------------------|
| 1  | `ui/mainWindow.lua`        | 250-350        | ⬜ Planned      | UIComponents, UIConfig                        |
| 2  | `ui/controls.lua`          | 300-400        | ⬜ Planned      | UIComponents, FakePlayerService               |
| 3  | `ui/keystoneCards.lua`     | 300-400        | ✅ Complete     | UIComponents, Tooltips, ScoreCalculations     |
| 4  | `ui/dungeonView.lua`       | 250-350        | ✅ Complete     | UIComponents, ScoreCalculations               |
| 5  | `ui/viewManager.lua`       | 150-200        | ⬜ Planned      | Rendering, Keystones                          |
| 6  | `ui/tooltips.lua`          | 200-300        | ✅ Complete     | ScoreCalculations, IOCalculator               |
| 7  | `ui/scoreCalculations.lua` | 400-500        | ✅ Complete     | IOCalculator, RaiderIO, Utils                 |
| 8  | `ui/ioCalculations.lua`    | 150-250        | ✅ Complete     | IOCalculator, ProfilesService                 |
| 9  | `ui/rendering.lua`         | 250-350        | 🟦 In Progress  | KeystoneCards, ioCalculations, UIComponents   |
| 10 | `ui/performance.lua`       | 200-250        | ⬜ Planned      | Rendering, Events                             |
| 11 | `ui/playerCapabilities.lua`| 80-120         | ✅ Complete     | None (pure data/helpers)                      |
| 12 | `ui/debugHelpers.lua`      | 150-250        | ⬜ Planned      | FakePlayerService                             |
| 13 | `ui/utilities.lua`         | 150-250        | ✅ Complete     | None                                          |
| 14 | `ui/initialization.lua`    | 100-150        | ⬜ Planned      | ConfigurationContext, Events                  |
| 15 | `ui/main.lua` (slim)       | 200-300        | 🟦 In Progress  | ALL modules (coordination only)               |

**Status Key**: ⬜ Planned | 🟦 In Progress | ✅ Complete | ⚠️ Blocked

---

## Implementation Phases

### Phase 1: Extract Stateless Modules (Week 1)

Risk Level: Low  
Goal: Extract pure functions and constants with no state dependencies.

- [x] 1.1 `ui/playerCapabilities.lua`
- [x] 1.2 `ui/utilities.lua`
- [x] 1.3 `ui/scoreCalculations.lua`
- [x] 1.4 Update `ui/main.lua` and `NextKey.toc` to delegate.

Acceptance:
- ✅ All tests pass
- ✅ No regressions
- ✅ Measurable `main.lua` reduction

(Phase 1 complete as previously documented.)

---

### Phase 2: Extract Rendering Modules (Week 2)

Risk Level: Medium  
Goal: Separate rendering logic from orchestration.

- [x] 2.1 `ui/tooltips.lua`
  - IO tooltip generation and display extracted.
- [x] 2.2 `ui/keystoneCards.lua`
  - Owns `AddKeyRow()` and `AddKeyRowCompact()`.
- [x] 2.3 `ui/dungeonView.lua`
  - Owns `RenderDungeonCards()`, `AddDungeonRowCompact()`, `AddDungeonRow()`.
- [x] 2.4 Wire up rendering pipeline
  - `ui/main.lua` delegates:
    - Tooltip APIs → `NextKey222.Tooltips`.
    - Keystone rows → `NextKey222.KeystoneCards`.
    - Dungeon rows → `NextKey222.DungeonView`.
  - `NextKey.toc` load order updated appropriately.

Phase 2 Acceptance:
- ✅ Keystone view renders correctly
- ✅ Dungeon view renders correctly
- ✅ Tooltips appear on hover
- ✅ Performance unchanged

(Phase 2 complete.)

---

### Phase 3: Extract Calculation Modules (Week 3)

Risk Level: Medium  
Goal: Isolate IO calculation logic and caching from UI orchestration.

Implemented:

- [x] 3.1 `ui/ioCalculations.lua`
  - Introduced `NextKey222.UICalculations` to centralize:
    - IO gain computation for keystones.
    - Party composition hash.
    - Keystone list hash.
    - IO gain cache management.
  - `NextKey.toc` updated to load `ui/ioCalculations.lua` before `ui/main.lua`.

- [x] 3.2 Shared state injection
  - `ui/main.lua` now:
    - Uses `UI:GetPartyCompositionHash()` and `UI:GetKeystoneListHash()` which delegate to `UICalculations` when available.
    - Calls `NextKey222.UICalculations:clear_io_gain_cache()` when party hash changes (plus legacy cache clear).
  - Ensures single, centralized cache and prevents split state.

- [x] 3.3 Public wrappers
  - `UI:CalculateIOGainRange(keystoneData)`:
    - Delegates to `NextKey222.UICalculations:calculate_io_gain_range(...)`.
    - Provides safe fallback if module missing.
  - Existing external callers continue using `UI:` methods; behavior preserved.

Phase 3 Acceptance:
- ✅ IO gain calculations accurate (validated in-game: sort behavior unchanged)
- ✅ Cache invalidation on party changes (validated: IO gains update correctly)
- ✅ No performance regression or new errors

---

### Phase 4: Extract Orchestration Modules (Week 4)

Risk Level: Higher  
Goal: Move rendering orchestration and frame pacing into dedicated modules while preserving SafeRun patterns and API stability.

Current Status: In progress, first concrete step implemented.

#### 4.1 `ui/rendering.lua` (NEW - Implemented)

- Implemented `NextKey222.UIRendering` with responsibility for keystone render orchestration:

  - `build_sorted_entries(keys, mode, ui)`:
    - Re-implements sort logic previously in `UI:SortKeys` for keystones.
    - Uses `UI:CalculateIOGainRange` for `IOGainPotential`.
  - `enrich_entry_metadata(ui, entry)`:
    - Mirrors `UI:EnrichEntryMetadata` logic:
      - Profiles, roles, heroism/bres, dungeon names, expected gain, current IO.
  - `render_keystones(ui, keys, mode)`:
    - Computes keystone hash via `UICalculations` (or `UI:GetKeystoneListHash` fallback).
    - Skips re-render if hash + sort mode unchanged.
    - Clears aux frames + children.
    - Handles "no keys" case with existing UX.
    - Builds entries, enriches them, and renders via `UI:AddKeyRow` / `UI:AddKeyRowCompact` using `NextKey222.SafeRun`.
    - Updates keystone control visibility.

- `UIRendering:Initialize()`:
  - Clears internal caches and logs via debug system.

- `NextKey.toc` updated to load `ui/rendering.lua` between `ui/ioCalculations.lua` and `ui/main.lua`.

- Updated `ui/main.lua`:

  - `UI:RenderResults()` now:

    - Coordinator only:
      - Acquires `keys` and `mode`.
      - If `NextKey222.UIRendering.render_keystones` exists:
        - Delegates to `UIRendering:render_keystones(self, keys, mode)`.
        - Synchronizes configuration context via `self.configContext:SynchronizeWithUI(self)` if present.
        - Returns.
      - Fallback path:
        - Retains a trimmed, functionally equivalent implementation (for safety if `UIRendering` is absent / load issues).
        - Uses `SortKeys`, `EnrichEntryMetadata`, and SafeRun to render cards.
        - Maintains existing visibility and config sync behavior.

Result:
- Keystone render orchestration is effectively relocated to `ui/rendering.lua`.
- `UI:RenderResults` is now aligned with the “slim coordinator” goal.
- In-game validation confirmed no regressions.

Planned (next steps):

- [ ] 4.2 `ui/performance.lua`
  - Extract frame pacing system from `ui/main.lua`:
    - `QueueFramePacedRender`
    - `StartFramePacing`
    - `ProcessFramePacing`
    - `ExecuteWorkItem`
    - `ExecuteRenderItem`
    - `PrepareRenderData`
    - `StopFramePacing`
  - Implement `NextKey222.UIPerformance`:
    - Owns frame pacing state.
    - Provides `QueueFramePacedRender(ui)` and helpers.
    - Uses `NextKey222.SafeRun` for expensive operations.
  - `UI` methods become wrappers delegating into `UIPerformance`.

- [ ] 4.3 Wire event handlers
  - Ensure any frame pacing triggers (e.g. large group refresh) call into `UIPerformance` instead of inline logic.

---

### Phase 5: Extract UI Management Modules (Week 5)

Risk Level: Higher  
Goal: Modularize window and control management; reduce `ui/main.lua` to orchestration + facade.

Planned:

- [ ] 5.1 `ui/viewManager.lua`
  - Own:
    - `viewMode` state (`keystones` vs `dungeons`)
    - `DetectUIMode()`, `SwitchToUIMode()`, `OnGroupRosterUpdate()`
    - Integration with Organizer/RosterBoard.

- [ ] 5.2 `ui/controls.lua`
  - Own:
    - Header/controls construction:
      - Sort dropdown
      - Refresh Data button
      - Guild/Party toggle
      - Teleport button
      - Organizer button
      - Debug controls container wiring (delegating to `debugHelpers`).
    - View toggle button configuration.
  - Provide functions that `ui/mainWindow.lua` / `UI` call to build controls.

- [ ] 5.3 `ui/mainWindow.lua`
  - Own:
    - `CreateMainFrame()`
    - `ShowMainFrame()`
    - `ToggleMainFrame()`
  - State:
    - `mainFrame`, `resultsFrame`, `controlsContainer`, `viewToggleBtn`, etc.
  - Use `UIComponents` and `UIConfig`; no heavy logic.

- [ ] 5.4 Resolve circular dependencies
  - Use injected callbacks / small facades:
    - e.g. `UI:SetRenderCallbacks`, `UI:SetViewManager`, etc.

---

### Phase 6: Extract Support Modules (Week 6)

Risk Level: Low  
Goal: Extract remaining support behaviors.

Planned:

- [ ] 6.1 `ui/debugHelpers.lua`
  - Fake player management:
    - `HandleAddDebugFakePlayer()`
    - `HandleDeleteFakePlayer()`
    - `HandleDeleteAllFakePlayers()`

- [ ] 6.2 `ui/initialization.lua`
  - UI initialization and event wiring:
    - `UI:Initialize()`
    - `OnSpecChanged()` integration
    - Group roster handling for UI mode (with `viewManager`).

- [ ] 6.3 Move slash commands
  - Relocate UI-related slash commands out of `ui/main.lua` into initialization/debug modules.

---

### Phase 7: Finalize Coordinator

Risk Level: Medium  
Goal: Slim `ui/main.lua` to a pure coordinator.

Planned:

- [ ] 7.1 Reduce `ui/main.lua`
  - Keep:
    - Module definition and registration.
    - Public API facade:
      - e.g. `UI:ToggleMainFrame`, `UI:RefreshResults`, `UI:RenderResults` as thin delegates.
  - Delegate all behaviors to:
    - `UIRendering`, `UICalculations`, `UIPerformance`,
    - `MainWindow`, `Controls`, `ViewManager`,
    - `DebugHelpers`, `Initialization`.

- [ ] 7.2 Backward compatibility
  - Preserve existing `UI:` public methods and semantics.

- [ ] 7.3 Full integration testing
- [ ] 7.4 Update documentation and Memory Bank

Target:
- `ui/main.lua` under ~300-400 lines, no direct layout/loop logic.

---

## Dependency Graph (Updated Snapshot)

High-level (implemented + planned):

- `utilities.lua`
- `playerCapabilities.lua`
- `scoreCalculations.lua`
- `ioCalculations.lua`
- `tooltips.lua` → uses score/IO calculations
- `keystoneCards.lua` → uses UIComponents, tooltips
- `dungeonView.lua` → uses UIComponents, ScoreCalculations
- `rendering.lua` → uses KeystoneCards, ioCalculations, UIComponents, SafeRun
- `performance.lua` (planned) → uses rendering, Events
- `viewManager.lua` (planned) → uses rendering, Keystones, Organizer
- `controls.lua` (planned) → uses UIComponents, viewManager
- `mainWindow.lua` (planned) → uses controls, viewManager
- `initialization.lua` (planned) → uses ConfigurationContext, Events
- `debugHelpers.lua` (planned) → uses FakePlayerService, UI
- `main.lua` → coordinates and exposes UI API

---

## Testing Checklist (Post-Rendering Extraction)

Validated:

- Keystone cards:
  - Render correctly via `UI:RenderResults()` → `UIRendering:render_keystones()`.
- Sort modes:
  - Highest/Lowest key level and IO Gain Potential behave as before.
- Party changes:
  - Adding/removing members updates IO gains correctly.
- Dungeon view:
  - Still rendered via existing `RenderDungeonCards` path.
- Performance:
  - No regressions; skip-when-unchanged and centralized cache intact.
- Public API:
  - `UI:RenderResults()` remains stable entry point.

---

## Session Notes

### Session 3: 2025-11-10 (Phase 2 - Rendering Modules)
- Completed tooltips, keystone cards, dungeon view.
- Wired `ui/main.lua` to delegate.

### Session 4: 2025-11-10 (Phase 3-4 - IO + Keystone Rendering Extraction)
- Implemented `ui/ioCalculations.lua` (`NextKey222.UICalculations`) and wired wrappers in `ui/main.lua`.
- Validated IO Gain Potential behavior under party changes.
- Implemented `ui/rendering.lua` (`NextKey222.UIRendering`) to own keystone render orchestration.
- Updated `UI:RenderResults()` to delegate to `UIRendering` with a robust fallback.
- Updated `NextKey.toc` to ensure correct load order.
- In-game validation:
  - No errors, all sort modes work, IO gains update correctly.
  - View toggling, open/close cycles remain stable.

---

## Quick Reference (Updated)

| Module                 | Responsibility                         | Key Functions / Notes                                          |
|------------------------|-----------------------------------------|----------------------------------------------------------------|
| `keystoneCards.lua`    | Keystone card rendering                 | `AddKeyRow()`, `AddKeyRowCompact()`                            |
| `dungeonView.lua`      | Dungeon card rendering                  | `RenderDungeonCards()`, `AddDungeonRow*()`                     |
| `tooltips.lua`         | IO tooltips                             | `ShowIOGainTooltip*()`, `BuildIOTooltip*()`                    |
| `scoreCalculations.lua`| Score lookups and colors                | Score helpers and color functions                              |
| `playerCapabilities.lua`| Capability detection                   | Heroism/BRes helpers                                           |
| `utilities.lua`        | Shared helpers                          | Frame tracking, darken content, compact mode, table count      |
| `ioCalculations.lua`   | UI IO calculations + hashes + caches    | `calculate_io_gain_range`, `get_party_composition_hash`, etc.  |
| `rendering.lua`        | Keystone render orchestration           | `render_keystones`, `build_sorted_entries`, `enrich_entry_metadata` |
| `main.lua`             | Orchestrator (in progress)              | Delegates to modules; owns state and public UI facade          |

---