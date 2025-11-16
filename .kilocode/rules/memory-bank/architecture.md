# NextKey Architecture

## System Architecture

NextKey follows the Details! Damage Meter architectural patterns for enterprise-grade WoW addon development. This is a hierarchical, modular architecture with strict error handling, centralized debugging, and performance monitoring.

All significant systems are organized under the `NextKey222` namespace, initialized and orchestrated via a single consolidated boot sequence.

## Core Architecture Principles

1. NextKey222 Namespace: All modules organized under `NextKey222`.
2. Module Registration: Every component registers with `NextKey222.RegisterModule()`.
3. Error Resilience: All critical operations use `NextKey222.SafeRun()` wrapper.
4. Performance Monitoring: Critical paths may use `NextKey222.Performance` profiling.
5. Centralized Debug: `NextKey222.Debug` is the only debug/log facility.
6. Separation of Concerns: UI modules handle display/input only. Business logic lives in core services. UI must never contain data processing or business rules.

## File Structure & Load Order

Critical load order (from [`NextKey.toc`](NextKey.toc:1)):

1. embeds.xml                      — Ace3 libraries (LibStub, AceAddon, etc.)
2. core/config.lua                 — Configuration defaults (MUST load before boot)
3. core/debugService.lua           — Debug system (MUST load before boot)
4. core/debugUI.lua                — Debug UI (MUST load before boot)
5. boot.lua                        — Consolidated initialization (single entry point)
6. core/slashCommands.lua          — Slash command handlers
7. ui/components.lua               — UI component system
8. data/portals.lua                — Season dungeon data
9. data/loot.lua                   — Season loot definitions
10. data/hearthstones.lua          — Hearthstone metadata
11. Dungeon name helpers:
    - core/dungeonNameService.lua
    - core/dungeonNameMatcher.lua
    - core/activityToDungeonMap.lua
12. Core Modules:
    - core/constants.lua
    - core/ids.lua
    - core/uiConfig.lua
    - core/configurationContext.lua
    - core/tooltip.lua
    - core/theme.lua
    - core/uiScale.lua
    - core/responsive.lua
    - core/performance.lua
    - ui/performanceOptimizer.lua
    - events/performanceHandlers.lua
    - core/validation.lua
    - core/fakePlayerService.lua
    - core/profiles.lua
    - core/playerIOData.lua
    - core/adapters/debug.lua
    - core/adapters/blizzard.lua
    - core/adapters/libopenraid.lua
    - core/adapters/raiderio.lua
    - core/utils.lua
    - core/season.lua
    - core/libopenraid.lua
    - core/ioCalculator.lua
    - core/groupSuggestions.lua
    - core/keystones.lua
    - core/raiderio.lua
    - core/scoring.lua
    - core/comms.lua
    - core/dungeonCards.lua
13. Organizer Modules:
    - core/characterStorage.lua
    - core/types/player.lua
    - core/organizer/autoDetection.lua
    - core/organizer/playerDataBuilder.lua
    - core/organizer/validation.lua
    - core/organizer/comms.lua
    - core/organizer/survey.lua
    - core/organizer/state.lua       — OrganizerState (single source of truth)
    - core/organizer/sorting.lua
    - core/organizer/animationQueue.lua
14. PUG Helper:
    - core/pugHelper.lua
    - core/pugHelper_state.lua
    - core/pugHelper_applications.lua
    - core/pugHelper_detection.lua
15. Events:
    - events/handlers.lua
16. Debug:
    - debug/init.lua
    - debug/tools.lua
    - debug/*tests.lua (various targeted tools/tests)
17. UI:
    - ui/main.lua
    - ui/teleport.lua
    - ui/dungeonCards.lua
    - ui/lootWindow.lua
    - ui/hearthstoneSelector.lua
18. Organizer UI:
    - ui/organizer/dragManager.lua
    - ui/organizer/playerCard.lua
    - ui/organizer/modules/benchManager.lua
    - ui/organizer/modules/slotManager.lua
    - ui/organizer/modules/cardMovement.lua
    - ui/organizer/modules/keystoneManager.lua
    - ui/organizer/rosterBoard.lua
    - ui/organizer/surveyDialog.lua
19. PUG Helper UI:
    - ui/pugInviteNotification.lua
    - ui/pugTravelAssistant.lua
    - ui/pugApplicationTracker.lua
20. Options:
    - options/main.lua

This load order ensures config, debug, and boot systems are ready before higher-level modules.

## Module Organization

Top-level structure:

- boot.lua — Consolidated initialization (single entry point)
- core/ — Core business logic and services
- ui/ — UI systems and components
- data/ — Static seasonal data
- events/ — Event handlers
- options/ — Configuration UI
- debug/ — Debug utilities and visual test tools

Key module groups:

- Core systems:
  - `core/config.lua` — AceDB defaults and schema (`NextKey222.Defaults`).
  - `core/debugService.lua` / `core/debugUI.lua` — Debug system and UI.
  - `core/performance.lua` — Performance helpers.
  - `core/utils.lua` — Legacy common helpers (being phased out).
  - `core/utils/*.lua` — Domain-specific utilities (time, player, communication, dungeon, item, scoring).
  - `core/constants.lua` — Namespaced constants by domain.
  - `core/ids.lua`, `core/uiConfig.lua` — Shared IDs and UI config.

- Data adapters:
  - `core/adapters/blizzard.lua`
  - `core/adapters/raiderio.lua`
  - `core/adapters/libopenraid.lua`
  - `core/adapters/debug.lua` — Fake players.

- Profiles & scoring (Pure Service Modules):
  - `core/profiles.lua` — ProfilesService with event-based UI refresh pattern
  - `core/playerIOData.lua`
  - `core/ioCalculator.lua` — IOCalculator with optimized memoization (single internal implementation)
  - `core/scoring.lua` — Scoring service (thin wrappers)

- Sorting system (Pluggable Architecture):
  - `core/sorting/main.lua` — Registry-based sorting system
  - `core/sorting/algorithms/bySmartSort.lua` — Default Borda count algorithm
  - `core/sorting/algorithms/byMaxGroupIO.lua` — Maximize group IO
  - `core/sorting/algorithms/byPlayerCoverage.lua` — Maximize benefiting players
  - `core/sorting/algorithms/byKeyLevel.lua` — Sort by key level
  - `core/sorting/algorithms/byItemNeed.lua` — Loot priority

- Keystone & dungeon model:
  - `core/keystones.lua`
  - `core/dungeonCards.lua`
  - `data/portals.lua`
  - `data/loot.lua`
  - `data/hearthstones.lua`
  - `core/dungeonNameService.lua`
  - `core/dungeonNameMatcher.lua`
  - `core/activityToDungeonMap.lua`

- Communications:
  - `core/comms.lua` — Central AceComm router, IO sharing, TELEPORT_SELECT, organizer routing.
  - `core/libopenraid.lua` — LibOpenRaid integration.

- Organizer:
  - `core/organizer/state.lua` — OrganizerState (authoritative state).
  - `core/organizer/comms.lua` — OrganizerComms on top of Communications.
  - `core/organizer/playerDataBuilder.lua`
  - `core/organizer/validation.lua`
  - `core/organizer/survey.lua` — Participant survey / poll handling.
  - `core/organizer/autoDetection.lua`
  - `core/organizer/sorting.lua`
  - `core/organizer/animationQueue.lua`
  - UI: `ui/organizer/*.lua` modules (dragManager, playerCard, benchManager, slotManager, cardMovement, keystoneManager, rosterBoard, surveyDialog).

- PUG Helper:
  - `core/pugHelper.lua` — PUG Helper orchestrator.
  - `core/pugHelper_state.lua` — PUG state machine + primary invite lock.
  - `core/pugHelper_applications.lua` — LFG applications tracking, throttling, first-accepted-wins.
  - `core/pugHelper_detection.lua` — Group type detection (PUG/GUILD/PREMADE/SOLO).
  - UI helpers:
    - `ui/pugInviteNotification.lua`
    - `ui/pugTravelAssistant.lua`
    - `ui/pugApplicationTracker.lua` (debug/visual).

- Teleport & shared UI:
  - `ui/teleport.lua` — Unified teleport window (normal + PUG modes).
  - `ui/components.lua` — Component factory.
  - `ui/main.lua`, `ui/dungeonCards.lua`, `ui/lootWindow.lua`, `ui/hearthstoneSelector.lua`.

## Key Components

### 1. Boot System ([`boot.lua`](boot.lua:1))

Single-file initialization:

- Initializes `NextKey222` namespace and `_G.NextKey`.
- Sets up early `NextKey222.RegisterModule` and `NextKey222.SafeRun`.
- Creates phased startup system:

  Phases:
  - PreInit — Basic setup.
  - Init — DB, adapters, core systems.
  - PostInit — UI, comms, organizer, PUG helper.
  - Enable — Event registration.
  - Finalize — Character data capture and final readiness.

- Calls into modules via registered phase handlers; all critical init wrapped in SafeRun.
- Integrates with AceAddon-3.0 lifecycle (`NextKey:OnInitialize()`).

### 2. Debug System ([`core/debugService.lua`](core/debugService.lua:1), [`core/debugUI.lua`](core/debugUI.lua:1))

- Levels: NONE, ERROR, USER, DEV, TRACE.
- Category-based logging; UI-configurable.
- Mandatory:
  - No `print()` — always use `NextKey222.Debug`.
- Used across all systems (boot, comms, organizer, PUG, teleport).

### 3. Communications Core ([`core/comms.lua`](core/comms.lua:413))

Responsibilities:

- Registers AceComm prefix (`COMM_PREFIX`).
- Serializes/deserializes messages via AceSerializer.
- Throttling & batching for group-size-scaled load.
- IO sharing:
  - `PLAYER_IO_UPDATE`, `REQUEST_PLAYER_IO`.
  - `playerIOCache` with validation and cleanup.
- Handles:
  - `SYNC`, preferences, legacy dungeon scores.
  - Guild keystone share (`KEYSTONE_REQUEST` / `KEYSTONE_SHARE`).
- TELEPORT_SELECT:
  - Special opcode:
    - Ignores own messages.
    - Validates `key` (dungeonID, level).
    - Calls `NextKey:SetTeleportTargetKey(k, { source = "remote_select", broadcast = false, receivedFrom = sender })`.
    - Ensures teleport window visible/updated as needed.
- Organizer integration:
  - Routes organizer opcodes (ORG_*), poll requests/responses, organizer data exchange.
  - Delegates poll handling to survey and organizer UI modules.

### 4. OrganizerState & Organizer Stack

#### OrganizerState ([`core/organizer/state.lua`](core/organizer/state.lua:1))

Single source of truth for organizer with **event-driven architecture**:

- Tracks:
  - `players`, `bench`, `optOut`, `groups`, `keystones`, `activePoll`.
- APIs:
  - Get/Set/Update/Remove players.
  - Location moves: bench, opt-out, specific slots.
  - Keystone designation per group.
  - Poll lifecycle & responses, persisted state.
- **Event Announcements** (November 16, 2025):
  - All state mutations fire events via `AnnounceEvent()` helper
  - 5 core events: `ORGANIZER_PLAYER_ADDED`, `ORGANIZER_PLAYER_MOVED`, `ORGANIZER_PLAYER_UPDATED`, `ORGANIZER_POLL_RESPONSE_RECEIVED`, `ORGANIZER_STATE_CLEARED`
  - Complete payloads include all necessary context (no additional queries needed)
  - Events use AceEvent-3.0 `SendMessage()` for pub/sub pattern
- Persistence:
  - Saves only real players to SavedVariables.
  - Restores state on load, rehydrating bench/groups/keystones/opt-out.
- **Architecture Pattern**:
  - State has zero UI knowledge (pure event announcements)
  - UI modules listen and react to events
  - Direct calls still supported for backward compatibility
  - All organizer UI (roster board, cards, etc.) are views only

#### Organizer Communications ([`core/organizer/comms.lua`](core/organizer/comms.lua:1))

- Defines organizer opcodes (ORG_ADDON_PING/PONG, ORG_POLL_REQUEST/RESPONSE, ORG_ROSTER_FULL/DELTA, etc.).
- Uses main Communications module for actual send/receive.
- Provides helpers like `SendPollRequest`, `SendPollResponse`, `QueueRosterUpdate`.

#### Survey & UI

- `core/organizer/survey.lua` + `ui/organizer/surveyDialog.lua`:
  - Poll creation, polling UI, participant responses.
- `ui/organizer/rosterBoard.lua` & modules:
  - **Event-Driven UI** (November 16, 2025):
    - Registers 5 event listeners in `Initialize()`
    - Event handlers: `OnPlayerAdded`, `OnPlayerMoved`, `OnPlayerUpdated`, `OnPollResponseReceived`, `OnStateCleared`
    - Visibility guards prevent updates when UI hidden (performance optimization)
    - Animation guards prevent event handling during sort animations
  - RosterBoard uses OrganizerState for deterministic layouts (read-only queries).
  - `benchManager`, `slotManager`, `cardMovement`, `keystoneManager`:
    - Encapsulate layout and drag/drop/keystone designation.
    - `slotManager.place_card_in_slot()` has `skipStateUpdate` parameter to prevent circular event loops
  - Animation & UX handled via `animationQueue.lua`.

### 5. Teleport System ([`ui/teleport.lua`](ui/teleport.lua:1), `core/keystones.lua`, `core/comms.lua`)

Core rules:

- Single entry: `NextKey:SetTeleportTargetKey(keyInfo, opts)` (implemented on the Addon).
- Leader-only broadcast:
  - When `opts.broadcast = true` and caller is leader/in group:
    - Communications sends `TELEPORT_SELECT` with minimal key.
- Receiver:
  - `Communications:ProcessMessage()`:
    - On TELEPORT_SELECT:
      - Applies via SetTeleportTargetKey (no re-broadcast).
      - Ensures teleport window shown/updated.

UI behavior:

- `ui/teleport.lua`:
  - Builds unified teleport window:
    - Keystone destination card(s).
    - Configurable hearthstone card.
    - In PUG mode with `dungeonComplete = true`, adds Leave Group card.
  - Supports:
    - Normal mode (leader-selected keystone).
    - PUG mode (PUG Helper context + optional Leave Group).
  - Uses UIConfig and UIComponents for consistent look and secure buttons.

### 6. PUG Helper Stack

PUG mode is an integrated system that drives decisions and travel without separate bespoke teleports.

- `core/pugHelper.lua`:
  - Wires events to state/applications/detection helpers.
  - Provides PUG-specific entry points.

- `core/pugHelper_state.lua`:
  - State machine:
    - `IDLE` → `TRACKING` → `INVITE_RECEIVED` → `IN_GROUP` → `RUN_COMPLETE` → `IDLE`.
  - Primary invite lock:
    - `primaryInvite` + `activeInviteID` enforce first-accepted-wins.
  - Reset/cleanup helpers.

- `core/pugHelper_applications.lua`:
  - Throttled handling of `C_LFGList` updates.
  - Caches search result info, parses key levels, tracks status history.
  - On accepted invite:
    - Uses primaryInvite lock.
    - Calls `OnMPlusAccepted(appData)` to:
      - Map activity/group names to dungeon IDs.
      - Set PUG-mode teleport target via `SetTeleportTargetKey` (broadcast = false).
      - Open teleport window in PUG mode (unified UI).

- `core/pugHelper_detection.lua`:
  - Determines group type: `PUG`, `GUILD`, `PREMADE`, `SOLO`.
  - Uses:
    - LFG active entry.
    - PUGHelper markers.
    - Guild membership proportion.

- UI integrations:
  - `ui/pugInviteNotification.lua` — Enhanced invite notice.
  - `ui/pugTravelAssistant.lua` — Uses shared teleport window for PUG travel.
  - `ui/pugApplicationTracker.lua` — Debug/visual tool; SafeRun-wrapped to avoid AceGUI errors.

### 7. Loot Targeting System ([`ui/lootWindow.lua`](ui/lootWindow.lua:1), [`data/loot.lua`](data/loot.lua:1))

- Season-aware definitions based on `data/loot.lua`.
- Tracks targeted items, run counts, persistence via AceDB.
- Integrated with dungeon cards and main UI (loot-focused workflows).

## Critical Implementation Patterns

### Module Registration

All modules must:

- Attach to `NextKey222` namespace.
- Register via `NextKey222.RegisterModule("Name", ModuleTable)`.
- Provide `Initialize()` when they have startup behavior.

### Error Handling

- Wrap critical code in `NextKey222.SafeRun(function() ... end, "Context")`.
- No unguarded calls in comms, file I/O-like logic, or UI construction.

### Debug Usage

- Always use:
  - `Debug:Error(...)`
  - `Debug:User(category, ...)` or `Debug:User(...)`
  - `Debug:Dev(category, ...)`
  - `Debug:Trace(category, ...)`
- Never use `print()`.

### Performance Profiling

- Use `NextKey222.Performance:StartProfile(name)` / `StopProfile(name)` for expensive paths when enabled.

## Data Persistence

SavedVariables structure (from [`NextKey.toc`](NextKey.toc:7)):

- `NextKeyDB.global`:
  - leaderSettings, ui, communications, debug, performance, etc.
- `NextKeyDB.char`:
  - liveRuns, preferences, targetedItems, dungeonRunCounts, mythicPlus seasons.
  - Organizer-specific:
    - `organizerState` (filtered real players, groups, keystones, opt-out, poll metadata).

## Integration Points

- Blizzard APIs:
  - `C_MythicPlus`, `C_ChallengeMode`, `C_PlayerInfo`, `C_Container`, `C_GuildInfo`, `C_LFGList`, etc.
- RaiderIO:
  - Used via adapter for scores and dungeon data.
- LibOpenRaid:
  - Guild/party keystone sharing (where available).

## Performance Characteristics

Targets:

- Initialization: < 2 seconds.
- UI interactions: < 100ms.
- Memory baseline: < 10MB.
- Heavy usage peak: < 50MB.
- No meaningful FPS impact.

Strategies:

- On-demand UI creation.
- Caching with TTL and event-based invalidation.
- Message throttling and batching.
- Table reuse where appropriate.

## Critical Paths

1. Keystone Detection:
   - Scan + APIs → Profiles → IOCalculator → UI rendering.

2. IO / Comms:
   - Request/Share IO → Validate → Cache → UI updates.

3. Teleport Sync:
   - Leader SetTeleportTargetKey(broadcast=true) → TELEPORT_SELECT → receivers SetTeleportTargetKey(remote_select) → teleport window update.

4. Organizer:
   - Poll → OrganizerComms → OrganizerState → RosterBoard (views) → persisted state.

5. PUG Helper:
   - LFG apps → trackedApplications → primary invite lock → PUG detection → PUG context → Teleport window.

## Naming Conventions

- Functions: snake_case
- Variables: snake_case
- Modules: PascalCase (e.g., OrganizerState, PUGHelper)
- Constants: UPPER_SNAKE_CASE
- Private functions: `_prefix`
- Event handlers: `OnEventName`

## Code Organization (MARK Comments)

Use:

- `-- MARK: Module Definition`
- `-- MARK: Public Interface`
- `-- MARK: Private Implementation`
- `-- MARK: Event Handlers`

for navigation and consistency.

## Design Rationale

- Single boot.lua:
  - Linear, predictable initialization.
  - Matches industry-standard WoW addon architecture.
- OrganizerState:
  - Central, durable truth for organizer; eliminates UI-driven data sources.
- Teleport Single-Source API:
  - Prevents divergence between local selection and sync.
  - TELEPORT_SELECT has one meaning and path.
- PUG Helper Composition:
  - Clear separation of state/applications/detection/UI.
  - Uses shared teleport UI to avoid fragmentation.

## Modularity Standards

NextKey follows strict modularity principles to ensure code is maintainable and extensible:

1. **Code Isolation**: All modules use local scope and NextKey222 namespace
2. **Event-Driven Communication**: Modules announce state changes, don't call each other directly
3. **UI/Logic Separation**: Business logic in core/, UI code in ui/
4. **Code Health**: Remove dead code, simplify complex logic, document both what AND why

For detailed refactoring guidance, see:
- `Documentation/_Architectural_Audit/04_Modularity_Checklist.md` - Reusable checklist for file/feature refactoring
- `Documentation/_Architectural_Audit/06_Implementation_Checklist.md` - Step-by-step refactor execution plan
