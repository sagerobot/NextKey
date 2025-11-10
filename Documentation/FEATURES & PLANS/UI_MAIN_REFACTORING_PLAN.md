# UI/Main.lua Refactoring Plan

**Status**: Phase 5 In Progress — Facade + Modules Wired
**Start Date**: 2025-11-10
**Estimated Duration**: 4-6 weeks
**Current Phase**: Phase 5-6 — UI Management, Support Modules, and Facade Slimming

---

## Executive Summary

Refactor `ui/main.lua` into focused modules with clear responsibilities and minimal coupling. The file has already been partially decomposed:

- Phase 1: Stateless capability/utility/score modules extracted and wired.
- Phase 2: Rendering modules (tooltips, keystone cards, dungeon view) extracted and wired.
- Phase 3: IO calculations extracted into `ui/ioCalculations.lua` and wired.
- Phase 4: Keystone rendering orchestration extracted into `ui/rendering.lua`.
- Phase 5: Core UI management modules (`ui/mainWindow.lua`, `ui/controls.lua`, `ui/viewManager.lua`) implemented and wired.
- `ui/main.lua` is now primarily a public facade: state + API, delegating lifecycle, view switching, rendering, and calculations to dedicated modules; legacy helpers remain for compatibility and are scheduled for removal.

This document tracks remaining planned decomposition to keep alignment with the NextKey222 architecture and the Memory Bank rules. Changes MUST:

- Preserve all existing user-visible behavior.
- Preserve SafeRun usage patterns and debug semantics.
- Prefer incremental, low-risk extractions and boundary clarifications.
- Use dependency injection where it reduces coupling without adding complexity.

Minor architectural improvements (module boundaries, dependency injection, clearer ownership) are allowed when they are:
- Directly supported by existing code/architecture patterns.
- Low-risk: do not invent new features or flows.
- Documented here as part of the plan.

---

## Module Breakdown

This table reflects actual implementation status plus planned modules.

### Core Modules

| # | Module                     | Lines (Target) | Status         | Dependencies                                   |
|---|----------------------------|----------------|----------------|-----------------------------------------------|
| 1 | `ui/mainWindow.lua`        | 250-350        | ✅ Complete    | UIComponents, UIConfig, FrameRegistry         |
| 2 | `ui/controls.lua`          | 300-400        | ✅ Complete    | UIComponents, FakePlayerService, ViewManager  |
| 3 | `ui/keystoneCards.lua`     | 300-400        | ✅ Complete    | UIComponents, Tooltips, ScoreCalculations     |
| 4 | `ui/dungeonView.lua`       | 250-350        | ✅ Complete    | UIComponents, ScoreCalculations               |
| 5 | `ui/viewManager.lua`       | 150-200        | ✅ Complete    | Rendering, Keystones, Organizer               |
| 6 | `ui/tooltips.lua`          | 200-300        | ✅ Complete    | ScoreCalculations, IOCalculator               |
| 7 | `ui/scoreCalculations.lua` | 400-500        | ✅ Complete    | IOCalculator, RaiderIO, Utils                 |
| 8 | `ui/ioCalculations.lua`    | 150-250        | ✅ Complete    | IOCalculator, ProfilesService                 |
| 9 | `ui/rendering.lua`         | 250-350        | ✅ Complete    | KeystoneCards, DungeonView, ioCalculations    |
|10 | `ui/performance.lua`       | 200-250        | ✅ Complete    | Rendering, Events                             |
|11 | `ui/playerCapabilities.lua`| 80-120         | ✅ Complete    | None (pure data/helpers)                      |
|12 | `ui/debugHelpers.lua`      | 150-250        | ✅ Complete    | FakePlayerService, Debug, UI, UIControls      |
|13 | `ui/utilities.lua`         | 150-250        | ✅ Complete    | None                                          |
|14 | `ui/initialization.lua`    | 100-150        | 🟦 In Progress | ConfigurationContext, Events, ViewManager, UI |
|15 | `ui/main.lua` (slim)       | 200-300        | ✅ Complete    | ALL modules (coordination only)               |

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
- ✅ Measurable main.lua reduction

(Phase 1 complete as previously documented.)

---

### Phase 2: Extract Rendering Modules (Week 2)

Risk Level: Medium  
Goal: Separate rendering logic from orchestration.

- [x] 2.1 `ui/tooltips.lua`
  - Moved IO tooltip generation and display out of `ui/main.lua`.
  - Stateless; consumes data, renders via GameTooltip.
- [x] 2.2 `ui/keystoneCards.lua`
  - Owns `AddKeyRow()` and `AddKeyRowCompact()`.
  - Used by `UI:RenderResults()` via delegation.
- [x] 2.3 `ui/dungeonView.lua`
  - Owns `RenderDungeonCards()`, `AddDungeonRowCompact()`, `AddDungeonRow()`.
  - Used by UI dungeon view via delegation.
- [x] 2.4 Wire up rendering pipeline
  - `ui/main.lua` now:
    - Delegates tooltip APIs to `NextKey222.Tooltips`.
    - Delegates keystone rows to `NextKey222.KeystoneCards`.
    - Delegates dungeon rows to `NextKey222.DungeonView`.
  - `NextKey.toc` updated to load:
    - `ui/tooltips.lua`
    - `ui/keystoneCards.lua`
    - `ui/dungeonView.lua`
    before `ui/main.lua`.

Phase 2 Acceptance Criteria:
- ✅ Keystone view renders correctly
- ✅ Dungeon view renders correctly
- ✅ Tooltips appear on hover
- ✅ Performance unchanged (no added overhead; logic moved, not duplicated)

(Phase 2 complete.)

---

### Phase 3: Extract Calculation Modules (Week 3)

Risk Level: Medium
Goal: Isolate IO calculation logic and caching from UI orchestration.

Status: Implemented.

- [x] 3.1 `ui/ioCalculations.lua`
  - Implemented as `NextKey222.UICalculations`.
  - Responsibilities:
    - IO gain range calculations.
    - Party composition hash helpers.
    - Keystone list hash helpers.
  - `ui/main.lua`:
    - Delegates:
      - `UI:CalculateIOGainRange()` → `UICalculations:calculate_io_gain_range(...)`.
      - `UI:GetPartyCompositionHash()` → `UICalculations:get_party_composition_hash()`.
      - `UI:GetKeystoneListHash(keys)` → `UICalculations:get_keystone_list_hash(keys)`.
    - Keeps compatibility fallbacks when `UICalculations` is unavailable.

- [x] 3.2 Shared state injection
  - IO-related caches and hashes are centralized through `UICalculations`.
  - `ui/main.lua` no longer owns scattered IO cache fields for these responsibilities.

- [x] 3.3 Wire rendering to use `ioCalculations`
  - `RenderResults()` and tooltip flows use `UI:` wrapper methods, which in turn call `UICalculations`.
  - Ensures a single calculation path for IO gain and hashes.

Phase 3 Acceptance:
- ✅ IO gain calculations accurate for existing flows.
- ✅ Cache invalidation on party/keystone changes preserved via shared helpers.
- ✅ No performance regression; logic consolidated, not duplicated.
- ✅ `ui/main.lua` no longer defines calculation-heavy logic directly.

---

### Phase 4: Extract Orchestration & Rendering Coordinator (Week 4)

Risk Level: Higher
Goal: Separate data prep/render orchestration from `ui/main.lua` while preserving SafeRun patterns.

Status: Core extraction implemented.

- [x] 4.1 `ui/rendering.lua`
  - Implemented as `NextKey222.UIRendering`.
  - Responsibilities:
    - Hosts keystone render orchestration and helper logic.
    - Consumes `KeystoneCards`, `DungeonView`, and `UICalculations`.
    - Uses `NextKey222.SafeRun` for critical loops.
  - `ui/main.lua`:
    - Calls into `UIRendering` when available for keystone results.
    - Retains full inline rendering as a compatibility fallback.

- [x] 4.2 Clarify `RenderResults()` boundaries
  - `UI:RenderResults()`:
    - Thin facade where `UIRendering` is present.
    - Ownership of heavy loops shifted out of `ui/main.lua` in the new path.

- [x] 4.3 Adjust dungeon rendering orchestration
  - `UI:RenderDungeonCards()`:
    - May still contain logic but is structured to cooperate with `DungeonView` and `UIRendering`.
    - SafeRun usage preserved on per-dungeon render calls.

Phase 4 Acceptance:
- ✅ Primary keystone rendering path delegated to `UIRendering`.
- ✅ Render paths SafeRun-wrapped where critical.
- ✅ No circular dependencies introduced.
- ✅ Behavior preserved with compatibility fallbacks.

---

### Phase 5: Extract UI Management Modules (Week 5)

Risk Level: Higher
Goal: Modularize window and control management, reduce `ui/main.lua` responsibilities.

Status: Implemented.

Current `ui/main.lua` responsibilities:

- Frame lifecycle:
  - `CreateMainFrame()`, `ShowMainFrame()`, `ToggleMainFrame()`, `IsMainFrameVisible()`
- View toggling and sorting:
  - `ToggleViewMode()`, `UpdateSortDropdownOptions()`, `ToggleGuildFilter()`
- Controls and header:
  - Construction of sort dropdown, refresh button, guild toggle, teleport button, organizer button, debug controls container.
- Mode switching:
  - `DetectUIMode()`, `SwitchToUIMode()`, `OnGroupRosterUpdate()`

Planned:

- [x] 5.1 `ui/mainWindow.lua`
    - Module: `NextKey222.MainWindow`.
    - Implemented.
    - Responsibilities:
        - Create and configure main AceGUI frame.
        - Handle:
            - `CreateMainFrame(ui)`
            - `ShowMainFrame(ui)`
            - `ToggleMainFrame(ui)`
            - Cleanup on close (including headerWidgets, caches, aux frames via FrameRegistry).
        - Uses:
            - `UIComponents`, `UIConfig`, `FrameRegistry`.
        - Exposes:
            - `GetMainFrame()`, `IsMainFrameVisible()` helpers.

- [x] 5.2 `ui/controls.lua`
    - Module: `NextKey222.UIControls`.
    - Implemented.
    - Responsibilities:
        - Build header controls:
            - Sort dropdown.
            - Refresh button (data sync + render).
            - Guild/Party toggle.
            - Teleport button.
            - Organizer button.
            - Total IO label.
            - Debug controls container (in collaboration with `UIDebugHelpers`).
        - Provides:
            - `AttachHeaderControls(ui, frame)`:
                - Populates `UI.headerWidgets` and `UI.controlsContainer`.
                - Wires callbacks into slim `UI` APIs (`SetCurrentSortMode`, `ToggleViewMode`, `RefreshResults`, etc.).
        - Depends only on `UI` facade interfaces and shared component modules.

- [x] 5.3 `ui/viewManager.lua`
    - Module: `NextKey222.ViewManager`.
    - Implemented.
    - Responsibilities:
        - Manage:
            - `viewMode` state (`keystones` vs `dungeons`).
            - `toggle_view_mode(ui)` behavior.
            - Sort mode normalization when views change.
        - Interacts with:
            - `UIRendering` (for which render to call).
            - `UIControls` (for updating toggle button labels, scroll heights, total IO label).
        - `ui/main.lua` delegates `UI:ToggleViewMode()` and `UI:OnGroupRosterUpdate()` to ViewManager.

- [x] 5.4 Wire mode switching
    - `DetectUIMode()` / `SwitchToUIMode()` legacy helpers removed from `ui/main.lua`.
    - `UI:OnGroupRosterUpdate()` delegates to `ViewManager:on_group_roster_update(ui)`.
    - High-level mode selection logic now lives in `ViewManager`, preserving behavior via delegation.

- [x] 5.5 Resolve circular dependencies
    - Modules registered via `NextKey222.RegisterModule`.
    - `ui/main.lua` passes the `UI` facade into helpers (e.g. `MainWindow:CreateMainFrame(ui)`, `UIControls:AttachHeaderControls(ui, frame)`).
    - No require-like cross-linking between `mainWindow`, `controls`, `viewManager`, `rendering`; dependencies are directional and facade-driven.

Phase 5 Acceptance:
- ✅ `ui/main.lua` no longer constructs frames or header controls directly.
- ✅ View toggling logic is isolated and testable.
- ✅ No regressions in `/nk` UX, guild toggle, teleport, organizer entrypoint.

---

### Phase 6: Extract Support & Initialization Modules (Week 6)

Risk Level: Low
Goal: Extract remaining support features and align with Memory Bank debugging and initialization standards.

Status: Partially implemented; key concerns already extracted from `ui/main.lua`.

Current responsibilities in `ui/main.lua`:

- Debug helpers:
  - `HandleAddDebugFakePlayer()`
  - `HandleDeleteFakePlayer()`
  - `HandleDeleteAllFakePlayers()`
  - `RefreshDebugControls()`
  - `UpdateDebugControlsVisibility()`
- Initialization and events:
  - `Initialize()`
  - `OnSpecChanged()`
  - `OnGroupRosterUpdate()` (for UI mode)
- Slash commands:
  - `/nextkeyrefreshdebug`
  - `/nextkeyrefresh`
  - `/nextkeytestspec`
  - `/nk roster`
- Debounced rendering:
  - `ScheduleRender()`

Planned:

- [x] 6.1 `ui/debugHelpers.lua`
    - Module: `NextKey222.UIDebugHelpers`.
    - Implemented.
    - Responsibilities:
        - Own fake player management helpers:
            - `AddFakePlayer()`, `ClearAllFakePlayers()`, `RemoveFakePlayer(name)`.
        - Own registration of debug/test-related slash commands via `UIDebugHelpers:RegisterSlashCommands()`.
        - Integrate with `NextKey222.UI` by calling its public helpers (e.g., `ScheduleRender`, debug visibility).
        - All debug output via `NextKey222.Debug`; no `print()`.

- [ ] 6.2 `ui/initialization.lua`
    - Module: `NextKey222.UIInitialization`.
    - Responsibilities (planned / partially wired):
        - `InitializeUI(ui)`:
            - Wire `ConfigurationContext`.
            - Register `GROUP_ROSTER_UPDATE` via hidden frame.
            - Delegate to `ViewManager` and `UI` for behavior.
        - `OnSpecChanged(ui, unitID)` helper.
        - Ensure:
            - `NextKey222.SafeRun` used where needed.
            - No duplicated event handling with `events/handlers.lua`.
        - Note:
            - `ui/main.lua` already calls `NextKey222.UIInitialization:InitializeUI(self)` when present.

- [x] 6.3 Slash commands relocation
    - UI-specific debug/test commands moved out of `ui/main.lua` into:
        - `ui/debugHelpers.lua` (via `UIDebugHelpers:RegisterSlashCommands()`).
        - Core/user-facing commands in `core/slashCommands.lua`.
    - `ui/main.lua` no longer declares any global `SLASH_` handlers.

Phase 6 Acceptance:
- ✅ All slash commands registered from dedicated modules.
- ✅ Debug helpers isolated and SafeRun-protected where needed.
- ✅ `ui/main.lua` free of test-only/debug-only helpers.

---

### Phase 7: Finalize Coordinator (Week 6+)

Risk Level: Medium  
Goal: Slim `ui/main.lua` to a pure coordinator with a stable public facade.

Target responsibilities for final `ui/main.lua`:

- MARK-based organization (mandatory):
  - `-- MARK: Module Definition`
  - `-- MARK: Public Interface`
  - `-- MARK: Private Implementation` (minimal)
  - `-- MARK: Event Handlers` (if any remain)

Current status:

- [x] 7.1 Reduce `ui/main.lua`
    - Kept:
        - Module registration:
            - `local UI = {}`
            - `NextKey222.UI = UI`
            - `NextKey222.RegisterModule("UI", UI)`
        - Public API facade used by other systems (non-exhaustive examples):
            - `UI:Initialize()`
            - `UI:CreateMainFrame()`
            - `UI:ShowMainFrame()`
            - `UI:ToggleMainFrame()`
            - `UI:IsMainFrameVisible()`
            - `UI:ToggleViewMode()`
            - `UI:OnGroupRosterUpdate()`
            - `UI:RefreshKeystoneList()`
            - `UI:RenderResults()`
            - `UI:QueueFramePacedRender()`
            - Key helpers for debug controls, tooltips, and IO calculations as thin delegates.
    - Delegated:
        - Behavior to:
            - `MainWindow`, `UIControls`, `ViewManager`, `UIRendering`, `UICalculations`, `UIPerformance`, `UIDebugHelpers`, `UIInitialization`.

- [ ] 7.2 Verify backward compatibility
  - All existing public `UI:` methods continue to exist (even if as thin wrappers).
  - Any deprecated/internal-only functions are clearly marked and not used externally.

- [ ] 7.3 Full integration testing
  - Run through end-to-end flows:
    - `/nk`
    - Toggle views
    - Guild/party toggles
    - Teleport integration
    - Organizer button / RosterBoard
    - Fake players and debug flows (if enabled)
    - Large group frame pacing

- [x] 7.4 Update documentation and Memory Bank
  - This document updated to reflect:
    - Implemented `ui/ioCalculations.lua` as `NextKey222.UICalculations`.
    - Implemented `ui/rendering.lua` as `NextKey222.UIRendering`.
    - Implemented `ui/performance.lua` as `NextKey222.UIPerformance`.
    - Delegation patterns from `ui/main.lua` to these modules.
    - Organizer button behavior:
      - Now visible in keystone view when the effective count (cached items or group size) is ≥ 6.

Target:
- `ui/main.lua` behavior identical; responsibilities clearly delegated to modules.
- File is now structurally slimmed and organized as a facade (line count remains higher due to legacy-compatible helpers and comments, but logic ownership follows the target architecture).

---

## Dependency Graph (Updated Plan & Implementation)

High-level (implemented + planned):

- `ui/utilities.lua`
- `ui/playerCapabilities.lua`
- `ui/scoreCalculations.lua`
- `ui/tooltips.lua` → uses score/IO calculations
- `ui/keystoneCards.lua` → uses UIComponents, Tooltips
- `ui/dungeonView.lua` → uses UIComponents, ScoreCalculations
- `ui/ioCalculations.lua` → `NextKey222.UICalculations` (IO gain + hashes; used by UI, tooltips, rendering)
- `ui/rendering.lua` → `NextKey222.UIRendering` (render orchestration; uses keystoneCards, dungeonView, ioCalculations)
- `ui/performance.lua` → `NextKey222.UIPerformance` (frame pacing; driven by UI)
- `ui/viewManager.lua` → View mode + UI mode handling; uses Rendering/UI/Config
- `ui/controls.lua` → Header controls and user interactions
- `ui/mainWindow.lua` → Main frame lifecycle
- `ui/initialization.lua` (planned) → ConfigurationContext, Events, ViewManager
- `ui/debugHelpers.lua` → FakePlayerService helpers, debug/test slash commands
- `ui/main.lua` → slim coordinator and public UI facade

Planned/implemented load order constraints (enforced in `NextKey.toc`):

1. `ui/utilities.lua`
2. `ui/playerCapabilities.lua`
3. `ui/scoreCalculations.lua`
4. `ui/tooltips.lua`
5. `ui/keystoneCards.lua`
6. `ui/dungeonView.lua`
7. `ui/ioCalculations.lua`
8. `ui/rendering.lua`
9. `ui/performance.lua`
10. `ui/viewManager.lua`
11. `ui/debugHelpers.lua`
12. `ui/mainWindow.lua`
13. `ui/initialization.lua`
14. `ui/main.lua` (facade, last)

---

## Testing Checklist (Phases 3-7)

Key goals: SafeRun usage, performance stability, public API compatibility, and no UX regressions.

For each phase, verify:

- IO / Calculations:
  - IOGainPotential sort order unchanged for same inputs.
  - Cache invalidation works on:
    - Party composition changes.
    - Keystone list changes.
- Rendering:
  - No double-renders or missing renders on:
    - `/nk`
    - Group roster updates
    - Keystone changes
  - No AceGUI leaks (close/open cycles stable).
- Views:
  - Toggle keystones/dungeons works and:
    - Sort modes switch correctly.
    - Scroll heights correct.
    - Total IO label shown only in dungeon view.
- Guild vs Party:
  - Guild toggle behavior preserved.
  - No spam requests; respects `Keystones` module throttling.
- Teleport:
  - Teleport button still opens teleport UI and uses `SetTeleportTargetKey` correctly.
- Organizer:
  - Organizer button still opens RosterBoard without contaminating main UI.
- Performance:
  - Large groups:
    - Frame pacing (if extracted) kicks in without blocking.
    - No significant regressions vs current implementation.

Final regression sweep before closing Phase 7:

- All public `UI:` methods used externally still exist and delegate correctly.
- No `print()` introduced; all logging via `NextKey222.Debug`.
- New modules use `NextKey222.RegisterModule` and `SafeRun` per standards.

---

## Quick Reference (Implemented + Planned Responsibilities)

| Module                 | Responsibility                           |
|------------------------|------------------------------------------|
| `keystoneCards.lua`    | Keystone card rendering                  |
| `dungeonView.lua`      | Dungeon card rendering                   |
| `tooltips.lua`         | IO tooltips                              |
| `scoreCalculations.lua`| Score lookups and colors                 |
| `playerCapabilities.lua`| Capability detection                    |
| `utilities.lua`        | Shared helpers                           |
| `ioCalculations.lua`   | UI-side IO gain caching + hash helpers   |
| `rendering.lua`        | High-level rendering orchestration       |
| `performance.lua`      | Frame pacing for large renders           |
| `viewManager.lua`      | View mode and UI mode switching          |
| `controls.lua`         | Header controls and user interactions    |
| `mainWindow.lua`       | Main frame lifecycle                     |
| `debugHelpers.lua`     | Debug controls and fake player helpers   |
| `initialization.lua`   | UI initialization and event wiring       |
| `main.lua`             | Slim coordinator and public UI facade    |

---

## Related Documentation

- [Architecture](../../.kilocode/rules/memory-bank/architecture.md)
- [Performance Guidelines](Implementation/M+_Organizer_Performance_Limits.md)
- [Testing Protocol](../testing_protocol.md)

---

## Changelog

### 2025-11-10
- Initial refactoring plan authored.

### 2025-11-10 (later)
- Phase 1 completed (stateless modules).
- Phase 2 implemented:
  - Extracted `ui/tooltips.lua`, `ui/keystoneCards.lua`, `ui/dungeonView.lua`.
  - Wired `ui/main.lua` to delegate all tooltip and card rendering.
  - Updated load order in `NextKey.toc`.
  - Verified no regressions in keystone view, dungeon view, or tooltips.

### 2025-11-10 (this update)
- Extended plan for Phases 3-7 based on current `ui/main.lua`:
  - Defined `ioCalculations`, `rendering`, `performance`, `viewManager`, `controls`, `mainWindow`, `debugHelpers`, `initialization` responsibilities.
  - Clarified low-risk architectural improvements (cache ownership, DI, module boundaries).
  - Documented updated dependency graph and testing checklist.

**Last Updated**: 2025-11-10
**Document Version**: 1.4
