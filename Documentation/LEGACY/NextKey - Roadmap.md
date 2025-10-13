# NextKey – Roadmap

This roadmap translates the high‑level design into a practical, incremental delivery plan. It sequences work into small, verifiable milestones with clear deliverables and acceptance criteria.

References:
- Design: Documentation/NextKey - Addon Design Document.md
- Ace3 primer: Documentation/Getting Started.md

## Guiding Principles
- Ship in thin vertical slices that are testable in-game.
- Favor Ace3 conventions for structure, config, and events.
- Keep data and UI loosely coupled; centralize logic.
- Prefer simple defaults; add options after core flows work.

## Milestones

### M0.1 — Bootstrap & Load
Goal: Load the addon cleanly with a visible confirmation.

Deliverables
- Non-empty `NextKey.toc` loading embedded Ace3 libs and our files.
- Minimal `Core.lua` AceAddon with `/nk` slash command that prints “NextKey loaded”.
- Existing `PortalDB.lua` loads without errors.

Implementation Notes
- Use embeds listed under `Libs/` already in the repo (no network needed).
- Keep file list minimal: `embeds.xml` (optional), `PortalDB.lua`, `Core.lua`.

Acceptance Criteria
- Addon enabled in AddOns list; no Lua errors on login.
- `/nk` prints a message.

### M0.2 — SavedVariables + Options Shell
Goal: Persist config and expose a basic options panel.

Deliverables
- SavedVariables: `NextKeyDB` with sane defaults (see design doc 2.2).
- `Options.lua` registering AceConfig options and `/nk config` to open it.

Acceptance Criteria
- Toggling a setting in options persists across reloads.

### M0.3 — UI Frame Skeleton
Goal: Show a movable AceGUI frame with placeholder controls.

Deliverables
- `UI.lua` with a basic AceGUI Frame: title bar, close button.
- Buttons for sort modes (disabled/placeholder) and a ScrollFrame area for results.
- `/nk` toggles the frame.

Acceptance Criteria
- Frame appears, moves, closes; no errors.

### M0.4 — Data Model & Available Keys Stub
Goal: Establish internal models and display stubbed keys.

Deliverables
- Module/namespace for “keys” data (in `Core.lua` or `data.lua`).
- Function to produce a small static list of test keys using IDs present in `PortalDB.lua`.
- UI renders that list in the ScrollFrame with simple labels.

Acceptance Criteria
- A few test entries render reliably; no performance issues.

### M0.5 — Ranking Engine (Foundations)
Goal: Implement ranking metrics and sort modes with test inputs.

Deliverables
- Functions for metrics: `totalGain`, `playerCount`, `itemNeed`, `keyLevel` (stub non-available inputs with zeros or defaults).
- Sort modes: MaxGroupIO, MaxPlayerCoverage, HighestKeyLevel, MaxItemNeed, SmartSort (Borda).
- Wire buttons to re-sort the current list.

Acceptance Criteria
- Switching sort modes reorders the list deterministically.

### M0.6 — AceComm Sync (Skeleton)
Goal: Introduce `NKEY` prefix, versioned payload, and manual sync.

Deliverables
- AceComm register/send/receive handlers with simple, versioned payload.
- Manual “Sync” button in UI to request party data.
- Safe guards for non-raid/non-party contexts.

Acceptance Criteria
- In a party with two clients, pressing Sync logs a receipt on both.

### M0.7 — Raider.IO Score Read (Dependency Gate)
Goal: Read player best-run scores from Raider.IO SV if present; fail gracefully otherwise.

Deliverables
- Reader module that extracts per-dungeon score table; caches in `NextKeyDB.char`.
- Feature flags: disable score weighting when RIO data is missing.

Acceptance Criteria
- With RIO SV present, we can log non-empty per-dungeon scores.

### M0.8 — Loot Targeting (Basics)
Goal: Track preferred items and show item-need metric.

Deliverables
- `Databases/LootDB.lua` scaffold for current season (can start partial and expand).
- Options UI to browse dungeons and toggle target items (defer to checkboxes or multi-select list).
- Incorporate `itemNeed` into ranking.

Acceptance Criteria
- Selecting an item updates ranks (visible effect on equal keys).

### M0.9 — Travel Assistant & Visuals
Goal: Provide teleport/hearth convenience and use map art IDs.

Deliverables
- Use `NextKey_PortalDB` and `NextKey_MapArtDB` for action button and banner art per key.
- “Teleport/Hearthstone” button reflects availability (spell known/in-CD ignored for now).

Acceptance Criteria
- Clicking action prints intent/log; correct art shows per selected key.

### M1.0 — Party Leader Auto-Suggest
Goal: Leader auto-suggest after runs and roster sync.

Deliverables
- Leader-only toggle in options and logic on `CHALLENGE_MODE_COMPLETED` + `BAG_UPDATE`.
- Broadcast the top-ranked key and show a compact pop-up on clients with “Announce” and “Teleport/Hearthstone”.

Acceptance Criteria
- Completing a run produces an auto-suggest flow without errors.

### Polish & Release
Goal: Smooth edges and prepare for distribution.

Deliverables
- Tooltips with metric breakdowns, slash help, keybinding, CHANGELOG.
- Packaging pass on `.toc` metadata and versioning.

Acceptance Criteria
- No errors on a normal play session; basic flows feel responsive.

## File Plan (incremental)
- Core: `Core.lua` (addon bootstrap, events, data model)
- UI: `UI.lua` (AceGUI frame, rendering, interactions)
- Options: `Options.lua` (AceConfig tables, getters/setters)
- Databases: `PortalDB.lua` (exists), `Databases/LootDB.lua` (new)
- Packaging: `NextKey.toc`, `embeds.xml` (optional), `CHANGELOG.md`

## Risks & Dependencies
- Raider.IO SV format changes or missing data: feature‑flag scoring gracefully.
- Patch/season rotations: keep `LootDB.lua` and dungeon IDs updated per season.
- Party sync variability: defensively code AceComm handlers and schema‑version payloads.

## Immediate Next Actions
1) M0.1: Populate `NextKey.toc` and bootstrap `Core.lua` with an AceAddon and `/nk`.
2) Add `SavedVariables: NextKeyDB` to `.toc`, create defaults, and stub `Options.lua`.
3) Build the `UI.lua` frame shell with buttons and an empty ScrollFrame.

When ready, we can start implementing M0.1 in code using the structure from the design doc.

