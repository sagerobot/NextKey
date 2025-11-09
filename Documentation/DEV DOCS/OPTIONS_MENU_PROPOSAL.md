# NextKey Options Menu Proposal

Source files:
- [`options/main.lua`](options/main.lua)
- [`core/config.lua`](core/config.lua)
- [`core/debugUI.lua`](core/debugUI.lua)
- [`core/organizer/state.lua`](core/organizer/state.lua)
- [`core/pugHelper.lua`](core/pugHelper.lua)
- [`ui/teleport.lua`](ui/teleport.lua)

This proposal is designed to:
- Only expose settings that are real, wired, and needed.
- Keep the surface area understandable for normal users.
- Push noisy/testing knobs into Debug System / Developer Tools.
- Make the Debug top-level section useful (no empty click).

---

## Top-Level Sections

1. General
2. Teleport Window
3. PUG Helper
4. Organizer & Roles
5. Appearance
6. Interface
7. Performance
8. Debug System
9. Developer Tools

Below is the intended purpose and content for each.

---

## 1. General

Audience: All users (party leaders especially).

Backed by:
- [`core/config.lua`](core/config.lua)
- Group suggestion logic in [`core/groupSuggestions.lua`](core/groupSuggestions.lua:1)

Settings:
- Auto Suggest
  - Uses `db.global.leaderSettings.autoSuggestEnabled`.
- Default Sort Mode
  - Uses `db.global.leaderSettings.defaultSortMode`.
  - Only expose real modes that exist in sorting implementation.
- Group Composition Preferences (minimal)
  - Prefer Heroism Support
  - Prefer Battle Res Support
  - Both map to `db.global.groupPreferences`.

Remove/avoid:
- Any unimplemented strategy toggles or optimizer modes.
- Speculative knobs not consumed by code.

---

## 2. Teleport Window

Audience: All users.

Backed by:
- Teleport system in [`ui/teleport.lua`](ui/teleport.lua:1)
- Teleport defaults in [`core/config.lua`](core/config.lua:121)

Settings:
- Compact Mode
  - `db.global.teleport.compactMode`.
- Show Hearthstone
  - `db.global.teleport.showHearthstone`.
- Select Hearthstone
  - Opens Hearthstone selector UI if implemented.
- Auto-Show After M+ Completion
  - `db.global.teleport.autoShowAfterCompletion`.

Clarify:
- Only show controls that directly affect the unified teleport window behavior.

---

## 3. PUG Helper

Audience: Users who PUG.

Backed by:
- [`core/pugHelper.lua`](core/pugHelper.lua:1)
- [`core/pugHelper_state.lua`](core/pugHelper_state.lua:1)
- [`core/pugHelper_applications.lua`](core/pugHelper_applications.lua:1)
- [`core/pugHelper_detection.lua`](core/pugHelper_detection.lua:1)
- UI helpers in `ui/pugInviteNotification.lua`, `ui/pugTravelAssistant.lua`, `ui/pugApplicationTracker.lua`

Settings:
- Enable PUG Helper
- Invite Notifications on/off
- Auto-Accept Invites (advanced but user-facing; must be safe)
- Travel Assistant
- Post-Run Getaway UI
- Application Tracker + Auto-Show

Hide or move:
- Synthetic test buttons (simulate runs, etc.) → Developer Tools.
- Experimental flags that are not stable.

---

## 4. Organizer & Roles

Audience: Organizer users and players who multi-role.

Backed by:
- Organizer stack in `core/organizer/*`
- Character roles in `NextKey222.CharacterStorage`

Settings:
- Character role configuration per character:
  - Tank / Healer / DPS multi-select per char, wired to CharacterStorage.
- High-level description of how Organizer uses roles.

Ensure:
- Only show when CharacterStorage / Organizer modules are available.
- No dummy or placeholder options.

---

## 5. Appearance

Audience: All users who care about look and feel.

Backed by:
- Theme system in [`core/theme.lua`](core/theme.lua:1)
- Defaults in [`core/config.lua`](core/config.lua:129)

Settings:
- Theme Selection (only from actual implemented themes).
- Theme description (read-only, from theme data).

Avoid:
- Duplicating scale/responsiveness here (keep in Interface).
- Exposing any theme keys that are not implemented.

---

## 6. Interface

Audience: Intermediate users.

Backed by:
- Tooltip helpers in [`core/tooltip.lua`](core/tooltip.lua:1)
- Responsive/layout logic in [`core/responsive.lua`](core/responsive.lua:1)
- UI scale in [`core/uiScale.lua`](core/uiScale.lua:1)

Settings:
- Tooltip:
  - Smart Tooltip Positioning, Delay, Scale (only if used by tooltip code).
- UI Scale:
  - Auto vs Manual scale, Scale slider or presets.
- Layout Mode:
  - Auto / Compact / Standard / Expanded
  - Only if mapped to real `Responsive` behavior.

Simplify:
- Keep concise; anything experimental or not clearly wired goes into Debug/Dev only.

---

## 7. Performance

Audience: Power users, but still user-facing.

Backed by:
- Performance helpers in [`core/performance.lua`](core/performance.lua:1)
- Defaults in [`core/config.lua`](core/config.lua:168)

Settings:
- Enable Performance Monitoring (if it toggles real behavior).
- Possibly:
  - Basic throttling slider if actually consumed (e.g. UI or comms throttle).

Do NOT expose:
- Raw internal tuning values that are not stable.
- Profiling-only flags that belong strictly to dev workflows.

If most of current Performance options are not meaningfully implemented, reduce this section to:
- A single toggle: "Enable performance telemetry (for troubleshooting)" or hide entirely.

---

## 8. Debug System

Audience: Advanced users and support/debugging.

Backed by:
- Debug system in [`core/debugService.lua`](core/debugService.lua:1)
- Debug UI factory in [`core/debugUI.lua`](core/debugUI.lua:1)

Goal:
- Clicking "Debug System" at top-level should show content immediately (no empty wrapper).

Content:
- Log level / mode selection (Error, User, Dev, Trace) if implemented.
- Category toggles (from real category map).
- Short description of how to use debug for bug reports.
- Optional: "Copy debug snapshot" style tools if available.

Rules:
- No print() usage; all debug wired through NextKey222.Debug.
- This is where we centralize real debug configuration.
- Keep it useful for gather-logs-not-for-play.

---

## 9. Developer Tools

Audience: Author, QA, advanced testers only.

Backed by:
- FakePlayerService, test utilities, internal helpers:
  - [`core/fakePlayerService.lua`](core/fakePlayerService.lua:1)
  - `debug/*tests.lua`
  - Legacy debug options code currently embedded in `options/main.lua`.

Content:
- Fake player generation presets.
- Custom fake player builder.
- Clear fake players.
- Test hooks (e.g. PUG Helper test, teleport test), only when available.
- Any mythic-plus data override tools.

Constraints:
- Hidden behind a clear warning:
  - "Developer / testing tools; not required for normal use."
- Potentially gated by:
  - A "Show developer tools" toggle in Debug System, or
  - DEV_MODE / debug feature flag.

---

## Real vs Non-Real / Actions To Take

High-level classification based on [`options/main.lua`](options/main.lua:779) and defaults:

1. Keep as real, user-facing:
   - General: autoSuggest, sortMode, groupPreferences.
   - Teleport window: compactMode, showHearthstone, selected hearthstone, autoShowAfterCompletion.
   - PUG Helper: enable, notifications, travel assistant, getaway UI, tracker options.
   - Organizer & Roles: character roles (via CharacterStorage).
   - Appearance: theme selector (for actual themes).
   - Interface: tooltip + scaling + responsive where backed by modules.

2. Move to Debug System:
   - Debug categories, levels, any internal logging toggles.
   - Dynamic configuration / debug-mode integration switches that are not core UX.

3. Move to Developer Tools:
   - Fake player presets and editors.
   - Mythic+ manual data entry editors.
   - "Test Application Tracking" and similar test-only executes.
   - Any options that call debug/test functions under `debug/`.

4. Drop or hide:
   - Duplicate M+ data options from `options/mythic_plus.lua` that conflict with the unified plan.
   - Options that reference functions which no longer exist or are not wired.
   - Overly granular performance/caching/animation flags that do not map cleanly to code paths.

---

## Implementation Notes

Key changes to apply in [`options/main.lua`](options/main.lua:779):

- Ensure only one canonical `SetupOptions()` builds and registers the NextKey options tree.
- Build top-level groups exactly as described above.
- Inline Debug System options so that the `debugSystem` group has visible args at the top level (no empty group requiring a second click).
- Extract debug/fake-player/test buttons into a `developerTools` group under the same options table.
- Remove or conditionally compile any dead or legacy blocks.
- Wire logging to `NextKey222.Debug` instead of `print`.

Once this structure is approved:
- Code mode can implement the refactor with:
  - A single, clean builder in `SetupOptions()`.
  - Centralized use of `NextKey222.DebugUI:CreateDebugOptions()` for Debug System.
  - A dedicated `CreateDeveloperToolsOptions()` that is only shown when DEV/testing is desired.
