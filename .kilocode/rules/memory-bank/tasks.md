# NextKey Memory Bank Tasks

Authoritative recurring workflows for future development. Follow these steps whenever making related changes to keep code and Memory Bank aligned.

## 1. Season Data Update

**Purpose:** Add support for a new Mythic+ season (dungeons, portals, loot).

**Files to modify:**
- `data/portals.lua`
- `data/loot.lua`
- `data/hearthstones.lua` (if relevant)
- `core/season.lua` / `core/seasons.lua` / `core/seasons_utils.lua` (if present)
- `core/utils.lua` (ID helpers, lookups)
- Any UI references: `ui/dungeonCards.lua`, `ui/teleport.lua`

**Steps:**
1. Add new season block to `data/portals.lua` with mapIDs and teleport spellIDs.
2. Add corresponding season block to `data/loot.lua` for dungeon loot definitions.
3. Update the active season key / selector in season-related modules.
4. Align any dungeon name/ID helpers (`core/dungeonNameService.lua`, `core/dungeonNameMatcher.lua`, `core/activityToDungeonMap.lua`).
5. In-game test:
   - Verify portals resolve correctly.
   - Verify dungeon names and loot appear correctly.
6. Update Memory Bank (`context.md` and `status.md`) to document new season.

**Important notes:**
- Keep season keys consistent across all season-related files.
- Avoid hardcoding logic outside season helpers.

## 2. OrganizerState or Organizer Protocol Changes

**Purpose:** Safely evolve organizer data model or comms.

**Files to modify:**
- `core/organizer/state.lua`
- `core/organizer/comms.lua`
- `core/organizer/survey.lua`
- `ui/organizer/*.lua` (rosterBoard, playerCard, modules)
- `core/comms.lua` (if organizer opcodes/protocol change)

**Steps:**
1. Update `OrganizerState` schema and APIs (add fields, methods, or behaviors).
2. Ensure all reads/writes in organizer UI and comms modules use the updated APIs.
3. Maintain SavedVariables compatibility or add migration where necessary.
4. Verify:
   - Poll → OrganizerState → UI flow.
   - Drag/drop, bench/opt-out, keystone designation behavior.
5. Update `architecture.md` (OrganizerState & organizer stack) and `status.md` if semantics changed.

**Important notes:**
- OrganizerState is the single source of truth; UI must remain view-only.
- All critical mutations must be `NextKey222.SafeRun`-wrapped with debug logs.

## 3. Teleport Sync / TELEPORT_SELECT Changes

**Purpose:** Adjust how teleport selection syncs across group.

**Files to modify:**
- `core/keystones.lua` (SetTeleportTargetKey / GetTeleportTargetKey)
- `core/comms.lua` (TELEPORT_SELECT handling)
- `ui/teleport.lua`
- `events/handlers.lua` (auto-open behavior / completion hooks)

**Steps:**
1. Apply all logic changes through `NextKey:SetTeleportTargetKey(keyInfo, opts)` (single-source).
2. Ensure leader-only broadcast semantics are preserved:
   - `opts.broadcast = true` only when allowed (leader/valid group).
3. Keep TELEPORT_SELECT receive path:
   - Validate payload.
   - Ignore own messages.
   - Call `SetTeleportTargetKey(..., { broadcast = false, source = "remote_select" })`.
4. In-game test:
   - 5-man & raid: leader selection sync, non-leader selection does not spam.
   - Teleport window auto-open behavior matches requirements.
5. Update `architecture.md`, `context.md`, `status.md` if behavior/semantics change.

**Important notes:**
- Never introduce alternative direct teleport sync paths; TELEPORT_SELECT + SetTeleportTargetKey is canonical.

## 4. PUG Mode Hardening / PUG Helper Changes

**Purpose:** Extend or adjust PUG Helper behavior while preserving stability.

**Files to modify:**
- `core/pugHelper.lua`
- `core/pugHelper_state.lua`
- `core/pugHelper_applications.lua`
- `core/pugHelper_detection.lua`
- `ui/pugInviteNotification.lua`
- `ui/pugTravelAssistant.lua`
- `ui/pugApplicationTracker.lua`
- `ui/teleport.lua` (PUG mode context / Leave Group)

**Steps:**
1. Keep state machine authoritative:
   - Use `PUGHelper.STATE`, `ValidateStateTransition`, `TransitionToState`.
2. Maintain primary invite lock:
   - Only first accepted invite becomes primary; others are secondary.
3. Ensure LFG processing is throttled and uses SafeRun for UI interactions.
4. Drive all travel via:
   - `SetTeleportTargetKey` with `{ broadcast = false }`
   - `SetTeleportWindowContext({ mode = "PUG", ... })`
   - Shared `ui/teleport.lua` window (no separate teleport UI).
5. Validate end-to-end with `/console scriptErrors 1`:
   - No AceGUI nil errors.
   - Correct PUG vs GUILD vs PREMADE vs SOLO detection.
   - Teleport window PUG mode and Leave Group behavior.

**Important notes:**
- Do not add new print-based debug; use `NextKey222.Debug`.
- Any behavioral changes must be reflected in `context.md` and `status.md`.

## 5. Memory Bank Synchronization

**Purpose:** Keep documentation aligned with code after significant changes.

**Files to modify:**
- `.kilocode/rules/memory-bank/brief.md`
- `.kilocode/rules/memory-bank/product.md`
- `.kilocode/rules/memory-bank/context.md`
- `.kilocode/rules/memory-bank/architecture.md`
- `.kilocode/rules/memory-bank/tech.md`
- `.kilocode/rules/memory-bank/status.md`
- `.kilocode/rules/memory-bank/tasks.md` (this file)

**Steps:**
1. After completing a major feature or protocol change:
   - Update `context.md` with current status snapshot.
   - Update `status.md` to mirror implementation state and priorities.
   - Update `architecture.md` if module roles/paths changed.
   - Adjust `tech.md` when stack/protocol constraints change.
   - Optionally refine `brief.md` / `product.md` to reflect new capabilities.
2. Ensure no contradictions between Memory Bank, `NextKey.toc`, and code.
3. Treat Memory Bank as canonical for future AI and contributors.

**Important notes:**
- Use concise, factual language.
- Prefer updating Memory Bank immediately after code changes rather than deferring.
