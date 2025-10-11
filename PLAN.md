# NextKey Cleanup & Consolidation Plan

This document is our     - `debug.lua` (consume fake players' `best` directly)orking checkli## Phase 5 – Remove stale/backup files from shipping

- [x] Identify: `*.bak`, `*.old`, `startup.lua.bak`, `preboot.lua.bak`, `events/handlers.lua.old`, `boot.lua.bak`
- [x] Remove from `NextKey.toc` and optionally delete from the addon folder after review
  - Acceptance: TOC doesn't reference any backup/old files; addon still loads cleanly clean up redundant/old code, harden architecture, and finish the small QoL fixes we discussed. We’ll do this in small, safe phases. Each item has an acceptance criteria and checkboxes.

## Phase 0 – Ground truth and quick wins

- [x] Align Interface/Version in `NextKey.toc` with client (Interface 110200, Version 0.2.0.x)
  - Acceptance: Addon loads without out-of-date prompt; version shows in AddOns list
- [x] Options live-refresh after debug actions
  - Change: Call `AceConfigRegistry:NotifyChange("NextKey")` in debug/preset generation paths and on option setters
  - Acceptance: After generating presets, the Options panel reflects changes without reopening
- [x] Debug category coverage
  - Change: Ensure categories exist for: `comms`, `events`, `startup`, `season`, `libopenraid`, `ioc`, `ui`, `options`
  - Acceptance: Toggling categories produces logs from respective modules; no unknown-category prints
- [x] Fix debug key schema
  - Change: Ensure fake players store `player.key = { dungeonID, level }` in addition to `player.keystone` so `core/keystones.lua` picks them up
  - Acceptance: After pressing a preset, logs show "Debug player key added" and fake keys appear in GetAvailableKeys results

## Phase 1 – Single source of truth for defaults

- [x] Make `core/config.lua` the canonical defaults holder
- [x] Remove duplicate defaults from `core/constants.lua` and any leftovers in `boot.lua`
- [x] Ensure AceDB init reads from `NextKey222.Defaults` exported by `core/config.lua`
- [x] Verify options and modules read settings only through `config.lua` APIs
  - Acceptance: One Defaults table in repo; new profiles start with the expected values; no references to removed duplicates

## Phase 2 – Communications unification

- [x] Use a single `COMM_PREFIX` in `core/constants.lua`
- [x] Update all comms code to reference that constant; remove `core/comms_old.lua`
- [x] Audit opcodes and message schemas; document in constants with brief comments
- [x] Update `NextKey.toc` to stop loading old comms module
  - Acceptance: Only one comms module present and loaded; messages send/receive across clients; no prefix mismatches

## Phase 3 – Scoring model consolidation ✅

- [x] Compare `core/ioCalculator.lua` and `core/scoring.lua`
- [x] Choose one primary path or extract a shared score function to avoid drift
- [x] Add two tiny tests (happy path + edge)
  - Acceptance: One authoritative scoring path; tests pass; dependent UI displays consistent scores
  - Implementation: IOCalculator is now the single source of truth for all scoring; scoring.lua delegates to IOCalculator; added test_score_consolidation.lua and test_io_range.lua; removed duplicate EstimateRunScore from seasons.lua

## Phase 3A – Profiles pipeline unification and ID mapping ✅

- [x] Establish a canonical ID mapper module
  - Change: Add `core/ids.lua` that defines canonical dungeon IDs (prefer the map IDs in `data/portals.lua`) and exposes helpers such as `ToDungeonID(sourceId)`, `ChallengeMapToDungeonID`, and `GetActiveSeasonDungeonIDs`
  - Acceptance: All modules asking for IDs import from `core/ids.lua`; no UI-local mapping helpers remain
- [x] Introduce a centralized profiles service
  - Change: Add `core/profiles.lua` providing a single contract for building player profiles from heterogeneous sources
  - Contract:
    - Input: `unitOrName` (player-Name-Realm or UnitID), optional source hints
    - Output: `PlayerProfile = { name, class, io, dataSource, dungeonScores = { [dungeonID] = { bestScore:number, level?:number } } }`
    - Methods: `GetPartyProfiles(mode)`, `GetGuildProfiles()`, `BuildProfileForPlayer(nameRealm)`, basic caching and invalidation
  - Acceptance: UI and IO calculator receive identical shapes for real and fake players; no special-casing based on origin
- [x] Implement source adapters behind the service
  - Change: Create adapters under `core/adapters/`:
    - `blizzard.lua` (challenge mode APIs)
    - `libopenraid.lua` (wrap existing functions as an adapter)
    - `raiderio.lua` (optional)
    - `debug.lua` (consume fake players’ `bests` directly)
  - Acceptance: Adapters normalize data into the `PlayerProfile` contract and are orchestrated by `core/profiles.lua`
- [x] Move UI profile building onto the service
  - Change: Replace `ui/main.lua` profile-assembly functions (e.g., `GetPlayerProfileForIOCalculation`, `ConvertFakePlayerDataToProfile`) with calls to `Profiles:GetPartyProfiles()`; remove UI-local mapping/estimation helpers
  - Acceptance: The tooltip/player breakdown is identical or improved; fake players display non-zero per-dungeon "Current IO" via the same path as real players
- [x] Caching and invalidation
  - Change: Cache `PlayerProfile` per player (keyed by name-realm and season) with event-driven invalidation on keystone updates, LibOpenRaid messages, `CHALLENGE_MODE_COMPLETED`, and on-demand for debug presets
  - Acceptance: No noticeable UI regressions; recomputation happens within 1 frame of relevant events
- [x] Rollout and safety
  - Change: Add a feature flag `features.profilesService` (enabled by default in debug) to allow fallback to the old path if needed for release builds
  - Change: Log a one-line metrics summary when the service is used (count, sources, cache hits) behind the `debug` category
  - Acceptance: Feature can be toggled without errors; no performance regressions; old code path can be removed after a soak period

## Phase 4 – Season data and debug generators

- [ ] Keep `debug/init.lua` using `Season:GetActiveSeasonDungeonIDs()` only
- [ ] Ensure `EnsureDungeonIDs()` fallback covers no-API cases
- [ ] Add minimal seeds to guarantee at least 8-10 fake players per preset
  - Acceptance: Presets always populate players and scores; no nil errors if season API is unavailable

## Phase 5 – Remove stale/backup files from shipping

- [ ] Identify: `*.bak`, `*.old`, `startup.lua.bak`, `preboot.lua.bak`, `events/handlers.lua.old`, `boot.lua.bak`
- [ ] Remove from `NextKey.toc` and optionally delete from the addon folder after review
  - Acceptance: TOC doesn’t reference any backup/old files; addon still loads cleanly

## Phase 6 – Debug UX and polish

- [x] Replace emoji labels in option buttons with plain text
- [x] Randomize fake player classes and ensure IO is shown
  - Acceptance: Preset players show varied class icons and a score next to their names
- [x] Show party members with no keystone in the list
  - Acceptance: Entries labeled “No Keystone” render for real and fake players missing a key
- [ ] Add a “Reroll Last Preset” action
- [ ] Add a concise “Debug Summary” (players, dungeons covered, avg score)
  - Acceptance: Options debug tab is clean and immediately useful

## Phase 7 – Documentation and audit report

- [ ] Write `AUDIT.md` with findings, file-by-file notes, and prioritized action list
- [ ] Include suggested deletions and rationale
  - Acceptance: Clear roadmap from current to clean architecture; no ambiguity on next steps

---

## Implementation notes

- Keep all shared constants in `core/constants.lua`; no defaults there once Phase 1 completes
- All settings access should go through `core/config.lua`
- Debug print categories centralized in `boot.lua` or a tiny `debug/categories.lua`
- After Phase 2, grep for the old comms prefix to ensure no stragglers
- All ID normalization and season dungeon IDs should route through `core/ids.lua`
- UI and calculators should obtain player data via `core/profiles.lua` and not build profiles locally

## Quick status (as of 2025-10-04)

- Options panel: fixed and rendering
- Preset generation: fixed, now uses Season API with fallback; labels cleaned
- Boot cleanup: removed duplicate Constants/Utils blocks; removed fragile RaiderIO debug block
- TOC: Interface set to 110200; version 0.2.0.1
- Guild view: filters to online guild members; includes player's own key; no "Unknown-<realm>" ghost
- Fake players: per-dungeon IO fixed; proposal added for unified profiles pipeline (Phase 3A)

## Checklists to drive PRs/commits

- [ ] Phase 0 (live-refresh, categories)
- [ ] Phase 1 (defaults consolidation)
- [ ] Phase 2 (comms unification)
- [ ] Phase 3 (scoring consolidation + tests)
- [ ] Phase 4 (season/debug hardening)
- [ ] Phase 5 (remove stale files)
- [ ] Phase 6 (debug UX)
- [ ] Phase 7 (audit doc)
