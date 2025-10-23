# NextKey Current Status & Requirements

## Project Status
**Date**: October 20, 2025  
**Version**: 0.2.1  
**Phase**: Post-UI Refactor Bugfixing - Loot System Implementation

## Phase 3: Loot Targeting System
**State**: Implementation complete, validation in progress.

### Delivered
- `data/loot.lua` provides a full Season 3 dataset with featured and dropdown item groupings per dungeon.
- `ui/lootWindow.lua` uses native frames plus the component factory for featured rows, dropdown toggles, and manual item input.
- `core/dungeonCards.lua` now handles loot tracking persistence, run counters, and helper lookups used by both the UI and tests.
- `debug/loot_tracking_test.lua` exposes `TestLootTrackingFixes()` to exercise persistence, run counters, and +7 level filtering.

### Outstanding Validation
1. Exercise loot window rendering to ensure texture preloading and layout hold under real data.
2. Verify custom item workflow (add/remove) and confirm data survives `/reload`.
3. Audit Season 3 item IDs/names against authoritative sources; adjust dataset if mismatches appear.
4. Restore tooltip Hero-track item level display in regular and compact views.

## Phase 4: PUG Mode (Queued)
- Core performance optimizations are in place (`events/performanceHandlers.lua`, `core/pugHelper_applications.lua`, `ui/pugApplicationTracker.lua`, `debug/pugPerformanceTest.lua`), but feature work remains blocked until loot validation finishes.
- Highest-priority fixes once unblocked: invite notifications, application tracker accuracy, getaway UI composition, and overall workflow polish.

## Implementation Priorities
1. Finish Phase 3 validation checklist and document any data corrections.
2. Ship tooltip Hero-track fix as part of the loot window polish.
3. Resume PUG mode repairs (Phase 4) with invite/application flows first, then getaway UI and options cleanup.

## Technical Notes
- Performance tooling is available through `/nk pug performance test`, `/nkperf metrics`, and `TestLootTrackingFixes()`; use these to guard against regressions.
- Keep `data/loot.lua` season key (`activeSeasonKey`) accurate when transitioning content.
- Maintain component factory usage in all new UI work to stay aligned with the refactored architecture.
