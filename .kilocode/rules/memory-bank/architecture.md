# NextKey Architecture

## System Architecture

NextKey follows the **Details! Damage Meter architectural patterns** for enterprise-grade WoW addon development. This is a hierarchical, modular architecture with strict error handling and performance monitoring.

## Core Architecture Principles

1. **NextKey222 Namespace**: All modules organized under `NextKey222` hierarchy
2. **Module Registration**: Every component must register with `NextKey222.RegisterModule()`
3. **Error Resilience**: All critical operations use `NextKey222.SafeRun()` wrapper
4. **Performance Monitoring**: Critical paths profiled with `NextKey222.Performance`
5. **Centralized Debug**: Professional debug system via `NextKey222.Debug`

## File Structure & Load Order

### Critical Load Order (from [`NextKey.toc`](../../../NextKey.toc))
```
1. embeds.xml                     # Ace3 libraries (LibStub, AceAddon, etc.)
2. core/config.lua                # Configuration defaults (MUST load before boot)
3. core/debugService.lua          # Debug system (MUST load before boot)
4. core/debugUI.lua               # Debug UI (MUST load before boot)
5. boot.lua                       # Single consolidated initialization
6. core/slashCommands.lua         # Slash command handlers
7. ui/components.lua              # UI component system
8. data/portals.lua               # Season dungeon data
9. data/loot.lua                  # Season loot definitions
10. [Core Modules]                # Keystones, profiles, comms, etc.
11. [UI Modules]                  # Main UI, teleport, dungeon cards, PUG UI components
12. [Options]                     # AceConfig options panels
13. [Debug Modules]               # Test suites and validation tools
```

### Module Organization

```
NextKey/
  boot.lua                     # Consolidated initialization (single entry point)
  core/                        # Core business logic
    config.lua                 # Settings management (AceDB schema)
    debugService.lua           # Debug routing
    debugUI.lua                # Debug configuration UI
    keystones.lua              # Keystone detection/management
    comms.lua                  # Inter-player messaging
    profiles.lua               # Profile aggregation service
    ioCalculator.lua           # IO score calculations
    groupSuggestions.lua       # Intelligent grouping logic
    raiderio.lua               # RaiderIO integration
    season.lua                 # Season data handling
    dungeonCards.lua           # Shared card model + loot tracking persistence
    pugHelper.lua              # PUG system orchestrator
    adapters/                  # Data source adapters
      blizzard.lua             # Blizzard API adapter
      raiderio.lua             # RaiderIO adapter
      libopenraid.lua          # LibOpenRaid adapter
      debug.lua                # Fake player adapter
  ui/                          # User interface (Ace3 + component factory)
    components.lua             # Component factory
    main.lua                   # Main window & controls
    dungeonCards.lua           # Dungeon card presentation
    teleport.lua               # Travel assistance UI
    lootWindow.lua             # Loot tracking interface
    organizer/                 # M+ Group Organizer UI
      rosterBoard.lua          # Main orchestrator (1,340 lines) - Delegates to modules
      playerCard.lua           # Draggable player cards with keystone buttons
      surveyDialog.lua         # Poll/survey UI (3-phase progressive)
      modules/                 # Specialized module layer (Week 2 Simplification)
        benchManager.lua       # Bench operations (462 lines)
        slotManager.lua        # Slot creation/layout (411 lines)
        cardMovement.lua       # Drag/drop validation (422 lines)
        keystoneManager.lua    # Keystone designation system (215 lines)
  data/                        # Static seasonal data
    portals.lua                # Dungeon teleport data per season
    loot.lua                   # Seasonal loot definitions
  events/                      # Event handlers
    handlers.lua               # WoW event processing
    performanceHandlers.lua    # Throttled performance-sensitive events
  options/                     # Configuration UI
    main.lua                   # AceConfig options
  debug/                       # Debug utilities and regression suites
    init.lua                   # Debug initialization
    tools.lua                  # Debug helpers
    performanceTest.lua        # Performance regression suite
```

## Key Components

### 1. Boot System ([`boot.lua`](../../../boot.lua))

**Single-file initialization** following industry standards:
- Initializes `NextKey222` namespace
- Sets up module registry
- Provides `SafeRun()` error wrapper
- Implements phased startup system
- Registers with AceAddon-3.0

**Initialization Phases**:
1. **PreInit**: Basic setup, constants, namespaces
2. **Init**: Core systems, database (AceDB)
3. **PostInit**: Module initialization
4. **Enable**: Event registration, UI creation
5. **Finalize**: Final setup, announce ready

### 2. Debug System ([`core/debugService.lua`](../../../core/debugService.lua))

**Professional 5-level debug system**:
- **Level 0 (NONE)**: Production/silent
- **Level 1 (ERROR)**: Critical errors only (always shown)
- **Level 2 (USER)**: User-facing messages
- **Level 3 (DEV)**: Development logging
- **Level 4 (TRACE)**: Ultra-verbose tracing

**Key Features**:
- 23 organized categories in 5 logical groups
- UI-based configuration (`/nk config` → Debug System)
- Compile-time stripping when `DEV_MODE = false`

**Critical Rule**: **NEVER use `print()` - ALWAYS use `Debug:Error/User/Dev/Trace()`**

### 3. Module Registry System

**All modules MUST register** using this pattern - see individual module files for implementation.

**Key Modules**:
- `Keystones`: Keystone detection and management
- `Communications`: Inter-player messaging (AceComm-3.0)
- `ProfilesService`: Centralized player data
- `IOCalculator`: Score calculations (MythicPlanner.com algorithm)
- `GroupSuggestions`: Intelligent group formation
- `UI`: Main user interface
- `FakePlayerService`: Testing data generation
- `RosterBoard`: M+ Group Organizer main UI (orchestrator)
- `BenchManager`: Bench operations module
- `SlotManager`: Slot creation and layout module
- `CardMovement`: Drag-and-drop validation module
- `KeystoneManager`: Keystone designation system module

### 4. Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Data Sources                             │
├─────────────────────────────────────────────────────────────┤
│  Blizzard API  │  RaiderIO  │  LibOpenRaid  │  Fake Players │
└────────┬────────────┬────────────┬─────────────┬────────────┘
         │            │            │             │
         ▼            ▼            ▼             ▼
    ┌────────────────────────────────────────────────┐
    │           Adapter Layer                        │
    │  BlizzardAdapter  RaiderIOAdapter              │
    │  LibOpenRaidAdapter  DebugAdapter              │
    └────────────────┬───────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │  ProfilesService     │  ← Centralized profile building
          │  (Unified Profiles)  │
          └──────────┬───────────┘
                     │
         ┌───────────┴──────────────────────┐
         ▼                                   ▼
    ┌─────────────┐                  ┌─────────────┐
    │ IOCalculator│                  │  UI System  │
    │ (Scoring)   │                  │  (Display)  │
    └──────┬──────┘                  └──────┬──────┘
           │                                │
           └────────────┬───────────────────┘
                        ▼
              ┌──────────────────┐
              │ Group Suggestions│ / M+ Group Organizer
              │ (Intelligence)   │
              └──────────────────┘
```

### 5. Communication System ([`core/comms.lua`](../../../core/comms.lua))

**Protocol**: AceComm-3.0 with custom opcodes
- **Prefix**: `NKEY1` (versioned)
- **Channels**: PARTY, RAID, GUILD, WHISPER
- **Throttling**: 2 seconds between messages per player
- **Serialization**: AceSerializer-3.0

**Message Types**: `SYNC`, `PLAYER_IO_UPDATE`, `REQUEST_PLAYER_IO`, `PREFERENCE`, `KEYSTONE_REQUEST/SHARE`

**Data Sharing**: Keystones via LibOpenRaid (primary), IO scores via custom communication, preferences via AceComm-3.0

### 6. Profile System ([`core/profiles.lua`](../../../core/profiles.lua))

**Centralized profile building** with adapter pattern:
- **Data Sources**: Blizzard API → LibOpenRaid → RaiderIO → Fake Players
- **Caching**: 5-minute TTL with event-driven invalidation
- **Profile Contract**: Standardized `PlayerProfile` format
- **Event Invalidation**: Auto-refresh on spec changes, roster updates

### 7. IO Calculator ([`core/ioCalculator.lua`](../../../core/ioCalculator.lua))

**MythicPlanner.com algorithm implementation**:
- Formula: `Rating = BaseLevel + (PT * 37.5) - (overtime_penalty)`
- PT = `Min[(TLimit - TRun) / TLimit, 0.40]`
- Overtime penalty: -15 points if over time

### 8. UI System ([`ui/main.lua`](../../../ui/main.lua))

**Dual-view interface**:
1. **Keystone View**: Ranked list of party keystones with IO gains
2. **Dungeon View**: Personal scores and preferences per dungeon

**Features**: Pure AceGUI-3.0 widget system, dynamic compact mode, real-time IO gain tooltips

### 9. UI Components Factory System ([`ui/components.lua`](../../../ui/components.lua))

**Factory pattern for consistent UI creation**:
- `Components:CreateBackdrop()`, `CreateButton()`, `CreateFrame()`, `CreateLabel()`, `CreateIcon()`
- Type constants for all component types
- 4 color schemes (DARK, STANDARD, LIGHT, TRANSPARENT)
- Component pooling for performance optimization

### 10. Loot Targeting System ([`ui/lootWindow.lua`](../../../ui/lootWindow.lua) + [`data/loot.lua`](../../../data/loot.lua))

**Season-aware loot tracking**:
- Featured items (always visible, protected)
- Dropdown items (quick toggles)
- Manual input (custom item IDs)
- Run counter tracking (+7 and higher completions)
- Persistence via `db.char.lootTracking`

## Critical Implementation Patterns

### 1. Module Registration (MANDATORY)
All modules must register with `NextKey222.RegisterModule()` and implement `Initialize()` function.

### 2. Error Handling (MANDATORY)
All critical operations MUST use `NextKey222.SafeRun()` wrapper.

### 3. Debug Usage (MANDATORY)
Always use `Debug:Error/User/Dev/Trace()` - NEVER `print()`.

### 4. Performance Profiling
Use `NextKey222.Performance:StartProfile()` / `StopProfile()` for expensive operations.

## Data Persistence

### SavedVariables Structure ([`NextKeyDB`](../../../NextKey.toc:7))
```lua
NextKeyDB = {
    global = {
        leaderSettings = { ... },
        ui = { ... },
        communications = { ... },
        debug = { ... },
        performance = { ... }
    },
    char = {
        liveRuns = {},           # Run history
        preferences = {},        # Dungeon preferences
        targetedItems = {},      # Loot targets
        dungeonRunCounts = {},   # Loot tracking
        mythicPlus = { activeSeason, seasons = {...} }
    }
}
```

## External Dependencies

### Hard Dependencies
- **RaiderIO**: Primary score data source (addon must be installed)
- **Ace3 Framework**: Core addon functionality (AceAddon, AceComm, AceDB, AceConfig, AceGUI, AceSerializer)

### Optional Dependencies
- **LibOpenRaid**: Alternative/supplemental score source
- **LibStub**: Library loading system (embedded)

## Integration Points

### WoW API Integration
- **C_MythicPlus**: Keystone detection, score tracking
- **C_ChallengeMode**: Dungeon information, completion data
- **C_PlayerInfo**: Player rating summaries
- **C_Container**: Bag scanning for keystones
- **C_GuildInfo**: Guild roster access

### RaiderIO Integration
Profile access, score coloring, dungeon data retrieval.

### LibOpenRaid Integration
Keystone sharing, player information, guild coordination.

## Performance Characteristics

### Target Metrics
- **Initialization**: <2 seconds addon load time
- **UI Response**: <100ms for all interactions
- **Communication Sync**: <1 second for full party
- **Memory Baseline**: <10MB at startup
- **Memory Peak**: <50MB during heavy usage
- **Combat Impact**: Zero frame rate effect

### Optimization Strategies
- **Profile caching**: 5-minute TTL with event invalidation
- **Message throttling**: 2-second minimum between messages
- **Lazy loading**: UI created on-demand
- **Batch updates**: Group UI changes together
- **Table pools**: Reuse tables where possible

## Critical Paths

### 1. Keystone Detection Path
User has keystone → Bag scan/Blizzard API → LibOpenRaid check → RaiderIO fallback → Store in cache → Notify UI → Render display

### 2. Score Calculation Path
Request scores → ProfilesService → Adapters (priority order) → IOCalculator → Cache result → Display in UI/tooltips

### 3. Communication Path
Event trigger → Serialize data → AceComm send → Party receives → Deserialize → Validate → Store in cache → Update UI

### 4. UI Render Path
User opens /nk → Collect keystones → Get party profiles → Calculate IO ranges → Sort by mode → Render cards → Display

## Error Handling Strategy

### Error Recovery Layers
1. **Function Level**: `NextKey222.SafeRun()` wraps critical operations
2. **Module Level**: Each module's `Initialize()` handles startup errors
3. **Event Level**: Event handlers isolated with pcall
4. **Communication Level**: Message validation prevents corrupt data
5. **UI Level**: Graceful degradation when data unavailable

### Fallback Mechanisms
- **Score Data**: RaiderIO → LibOpenRaid → Blizzard API → Default 0
- **Keystones**: Blizzard API → LibOpenRaid → Bag scan → Manual entry
- **Profiles**: ProfilesService → Individual adapters → Minimal profile
- **Communication**: AceComm → Manual sync → Solo mode

## Season Management

### Season Data Location
- [`data/portals.lua`](../../../data/portals.lua) — travel/teleport metadata
- [`data/loot.lua`](../../../data/loot.lua) — featured/dropdown loot definitions (season keyed)

### Season Updates (Critical Process)
1. Add new season blocks to `portals.lua` **and** `loot.lua`
2. Update `activeSeasonKey` in both files
3. Update ID mappings in [`core/utils.lua`](../../../core/utils.lua)
4. Test dungeon detection and loot lookup thoroughly

## Naming Conventions (STRICTLY ENFORCED)

- **Functions**: `snake_case` - `process_keystone_data()`, `update_player_score()`
- **Variables**: `snake_case` - `player_data`, `keystone_list`
- **Modules**: `PascalCase` - `Keystones`, `IOCalculator`
- **Constants**: `UPPER_SNAKE_CASE` - `COMM_PREFIX`, `MAX_KEY_LEVEL`
- **Private functions**: Underscore prefix - `_validate_input()`
- **Event handlers**: Start with "On" - `OnKeystoneUpdate()`

## Code Organization (MARK Comments)

All files use `-- MARK:` comments for VS Code navigation:
```lua
-- MARK: Module Definition
-- MARK: Public Interface  
-- MARK: Private Implementation
-- MARK: Event Handlers
```

## Key Design Decisions

### Why Single boot.lua?
- **Industry Standard**: All major WoW addons use single init file
- **Simplified Architecture**: Easier to understand and maintain
- **Better Performance**: Fewer file loads
- **Clear Dependencies**: Linear initialization flow

### Why ProfilesService?
- **Single Source of Truth**: All profile data flows through one service
- **Consistent Caching**: Unified cache management
- **Adapter Pattern**: Easy to add new data sources
- **Performance**: Reduces redundant API calls

### Why Debug System?
- **Professional Quality**: Enterprise-grade debugging
- **Performance**: Zero overhead when disabled
- **User Experience**: Clean output without debug spam
- **Maintainability**: Categorized, filterable logging
