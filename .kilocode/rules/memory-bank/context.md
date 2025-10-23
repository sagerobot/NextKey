# NextKey Current Context

## Current Work Status
**Date**: October 20, 2025  
**Version**: 0.2.1  
**Project Status**: Post-UI Refactor Bugfixing Phase - Loot System Implementation

## Focus: Loot Targeting System Validation
- The `GetCard(dungeonID)` name assertion is resolved across all call sites, unblocking the loot window.
- `data/loot.lua` now ships a full Season 3 dataset with featured/dropdown items, slot metadata, and helper lookups.
- Run counter persistence (`TrackItem`/`IncrementRunCounter`) and cross-session loading are in place; the `loot_tracking_test.lua` script exercises these flows.
- Outstanding issue: tooltip Hero-track item level display still needs a fix after the refactor.

### Validation Checklist (Active)
1. Open loot window from a dungeon card and verify featured and dropdown items render with correct icons (texture preloading).
2. Add/remove custom items via ID input and confirm persistence survives `/reload`.
3. Confirm run counters increment only for +7 and higher completions.
4. Audit Season 3 item IDs and names against Wowhead/Blizzard data; adjust `data/loot.lua` if discrepancies spotted.
5. Restore tooltip Hero-track item level information in both regular and compact views.

## Next Steps
1. Complete the above loot window validation to declare Phase 3 "feature complete."
2. Document any data corrections made to `data/loot.lua` and update automated tests (`TestLootTrackingFixes()`).
3. Once loot workflow is stable, resume Phase 4 PUG mode repairs (invite notifications, application tracker, getaway UI).
