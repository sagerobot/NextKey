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
9. [Core Modules]                 # Keystones, profiles, comms, etc.
10. [UI Modules]                  # Main UI, teleport, dungeon cards
11. [Options]                     # AceConfig options panels
```

### Module Organization

```
NextKey/
├── boot.lua                    # Consolidated initialization (SINGLE FILE)
├── core/                       # Core business logic
│   ├── config.lua             # Settings management
│   ├── constants.lua          # Shared constants
│   ├── debugService.lua       # Professional debug system
│   ├── debugUI.lua            # Debug UI controls
│   ├── keystones.lua          # Keystone detection/management
│   ├── comms.lua              # Inter-player messaging
│   ├── profiles.lua           # Centralized profile service
│   ├── ioCalculator.lua       # IO score calculations
│   ├── groupSuggestions.lua   # Intelligent grouping
│   ├── raiderio.lua           # RaiderIO integration
│   ├── utils.lua              # Utility functions
│   ├── season.lua             # Season data handling
│   └── adapters/              # Data source adapters
│       ├── blizzard.lua       # Blizzard API adapter
│       ├── raiderio.lua       # RaiderIO adapter
│       ├── libopenraid.lua    # LibOpenRaid adapter
│       └── debug.lua          # Fake player adapter
├── ui/                        # User interface
│   ├── main.lua              # Main window & controls
│   ├── dungeonCards.lua      # Card-based dungeon display
│   ├── teleport.lua          # Travel assistance UI
│   └── lootWindow.lua        # Loot tracking interface
├── data/                      # Static data
│   └── portals.lua           # Dungeon teleport data per season
├── events/                    # Event handlers
│   └── handlers.lua          # WoW event processing
├── options/                   # Configuration UI
│   └── main.lua              # AceConfig options
└── debug/                     # Testing & debugging
    ├── init.lua              # Debug initialization
    ├── tools.lua             # Debug utilities
    └── testSuite.lua         # Test framework
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
- Performance monitoring with microsecond precision
- Advanced filtering with patterns and time ranges
- Compile-time stripping when `DEV_MODE = false`

**Critical Rule**: **NEVER use `print()` - ALWAYS use `Debug:Error/User/Dev/Trace()`**

### 3. Module Registry System

**All modules MUST register**:
```lua
local MyModule = {}
NextKey222.MyModule = MyModule
NextKey222.RegisterModule("MyModule", MyModule)

function MyModule:Initialize()
    -- Module initialization logic
    return true
end
```

**Key Modules**:
- `Keystones`: Keystone detection and management
- `Communications`: Inter-player messaging (AceComm-3.0)
- `ProfilesService`: Centralized player data
- `IOCalculator`: Score calculations (MythicPlanner.com algorithm)
- `GroupSuggestions`: Intelligent group formation
- `UI`: Main user interface
- `FakePlayerService`: Testing data generation

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
              │ Group Suggestions│
              │ (Intelligence)   │
              └──────────────────┘
```

### 5. Communication System ([`core/comms.lua`](../../../core/comms.lua))

**Protocol**: AceComm-3.0 with custom opcodes
- **Prefix**: `NKEY1` (versioned)
- **Channels**: PARTY, RAID, GUILD, WHISPER
- **Throttling**: 2 seconds between messages per player
- **Serialization**: AceSerializer-3.0

**Message Types**:
- `SYNC`: Request/send party member data sync
- `PLAYER_IO_UPDATE`: Standardized IO data sharing
- `REQUEST_PLAYER_IO`: Request IO data from party
- `PREFERENCE`: Dungeon preference updates
- `KEYSTONE_REQUEST/SHARE`: Guild keystone coordination

**Data Sharing**:
- Keystones via LibOpenRaid (primary)
- IO scores via custom communication
- Preferences via AceComm-3.0
- Cross-realm support built-in

### 6. Profile System ([`core/profiles.lua`](../../../core/profiles.lua))

**Centralized profile building** with adapter pattern:
- **Data Sources**: Blizzard API → LibOpenRaid → RaiderIO → Fake Players
- **Caching**: 5-minute TTL with event-driven invalidation
- **Profile Contract**: Standardized `PlayerProfile` format
- **Event Invalidation**: Auto-refresh on spec changes, roster updates

**Profile Structure**:
```lua
PlayerProfile = {
    name = "PlayerName-Realm",
    class = "WARRIOR",
    specID = 71,
    specName = "Arms",
    role = "DAMAGER",
    io = 2500,
    dungeonScores = { [dungeonID] = { bestScore, bestLevel, ... } },
    capabilities = { heroism = false, battleRes = false },
    addonStatus = { nextkey = false, raiderio = true },
    dataSource = "combined"
}
```

### 7. IO Calculator ([`core/ioCalculator.lua`](../../../core/ioCalculator.lua))

**MythicPlanner.com algorithm implementation**:
- Formula: `Rating = BaseLevel + (PT * 37.5) - (overtime_penalty)`
- PT = `Min[(TLimit - TRun) / TLimit, 0.40]`
- Overtime penalty: -15 points if over time
- Range calculations: min/max/expected gains

**Key Functions**:
- `CalculateDungeonScore()`: Score for specific run
- `CalculateIORange()`: Min/max/expected gains
- `CalculateGroupIORange()`: Total party gains
- `GetRequiredKeyLevel()`: Target score requirements

### 8. UI System ([`ui/main.lua`](../../../ui/main.lua))

**Dual-view interface**:
1. **Keystone View**: Ranked list of party keystones with IO gains
2. **Dungeon View**: Personal scores and preferences per dungeon

**Features**:
- AceGUI-3.0 widget system
- Dynamic compact mode (>5 players)
- Real-time IO gain tooltips
- Guild/Party filter toggle
- Debug controls (when enabled)

## Critical Implementation Patterns

### 1. Module Registration (MANDATORY)
```lua
local _, NextKey222 = ...

-- Define module
local MyModule = {}
NextKey222.MyModule = MyModule

-- MANDATORY registration
NextKey222.RegisterModule("MyModule", MyModule)

-- REQUIRED initialization
function MyModule:Initialize()
    -- Setup logic
    return true
end
```

### 2. Error Handling (MANDATORY)
```lua
-- All critical operations MUST use SafeRun
function MyModule:CriticalOperation()
    return NextKey222.SafeRun(function()
        -- Validate inputs
        if not validInput then
            error("Invalid input")
        end
        
        -- Critical logic
        return result
    end, "MyModule:CriticalOperation")
end
```

### 3. Debug Usage (MANDATORY)
```lua
-- ✅ CORRECT
Debug:Error("Critical error")                    -- Always shown
Debug:User("User message")                      -- Release + Debug
Debug:Dev("category", "Development message")    -- Debug only
Debug:Trace("category", "Verbose trace")        -- Debug only

-- ❌ FORBIDDEN
print("Debug message")  -- NEVER use this
```

### 4. Performance Profiling
```lua
-- Profile expensive operations
NextKey222.Performance:StartProfile("MyModule:ExpensiveOp")
-- ... expensive code ...
NextKey222.Performance:StopProfile("MyModule:ExpensiveOp")
```

## Data Persistence

### SavedVariables Structure ([`NextKeyDB`](../../../NextKey.toc:7))
```lua
NextKeyDB = {
    global = {
        leaderSettings = { autoSuggestEnabled, defaultSortMode, ... },
        ui = { cardViewEnabled, framePosition, scale, ... },
        communications = { throttleInterval, maxRetries, ... },
        debug = { enabled, categories = {...}, level, ... },
        performance = { enabled, profileFunctions }
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
- **Ace3 Framework**: Core addon functionality
  - AceAddon-3.0: Addon structure
  - AceComm-3.0: Communication
  - AceDB-3.0: Database management
  - AceConfig-3.0: Options UI
  - AceGUI-3.0: UI widgets
  - AceSerializer-3.0: Data serialization

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
- Profile access: `RaiderIO.GetProfile(name, realm)`
- Score coloring: `RaiderIO.GetScoreColor(score)`
- Dungeon data: `mythicKeystoneProfile.fortifiedDungeonScores`

### LibOpenRaid Integration
- Keystone sharing: `LibOpenRaid.GetAllKeystonesInfo()`
- Player data: `LibOpenRaid.GetPlayerInformation()`
- Guild coordination: `LibOpenRaid.RequestKeystoneDataFromGuild()`

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
```
User has keystone → Bag scan/Blizzard API → LibOpenRaid check → 
RaiderIO fallback → Store in cache → Notify UI → Render display
```

### 2. Score Calculation Path
```
Request scores → ProfilesService → Adapters (priority order) → 
IOCalculator → Cache result → Display in UI/tooltips
```

### 3. Communication Path
```
Event trigger → Serialize data → AceComm send → Party receives → 
Deserialize → Validate → Store in cache → Update UI
```

### 4. UI Render Path
```
User opens /nk → Collect keystones → Get party profiles → 
Calculate IO ranges → Sort by mode → Render cards → Display
```

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
**Primary**: [`data/portals.lua`](../../../data/portals.lua)

### Season Structure
```lua
["TWW_S3"] = {
    name = "The War Within Season 3",
    dungeons = {
        [503] = { name, alias, spellID, mapArtID },
        -- 8 dungeons per season
    }
}
```

### Season Updates (Critical Process)
1. Add new season block to `portals.lua`
2. Update `activeSeasonKey` variable
3. Update ID mappings in [`core/utils.lua`](../../../core/utils.lua)
4. Test dungeon detection thoroughly
5. Update documentation

## Testing Infrastructure

### Fake Player System ([`core/fakePlayerService.lua`](../../../core/fakePlayerService.lua))
- Realistic IO distributions (8 skill tiers)
- Complete dungeon score generation
- Spec/role/capability simulation
- Preset configurations (mixed_skill, expert, etc.)

### Test Commands
```lua
/nk test                        -- Generate 4 random fake players
/nk test preset mixed_skill     -- Generate preset team
/nk test clear                  -- Remove all fake players
/script NextKeyRunTests()       -- Run test suite
```

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
-- MARK: Performance Optimizations
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

## Common Workflows

### Adding New Feature
1. Create module file in appropriate directory
2. Register with `NextKey222.RegisterModule()`
3. Implement `Initialize()` function
4. Use `SafeRun()` for critical operations
5. Add appropriate debug categories
6. Update documentation

### Debugging Issues
1. Enable debug: `/nk config` → Debug System
2. Enable relevant categories
3. Reproduce issue
4. Check debug output
5. Use performance monitoring if needed

### Season Transition
1. Update [`data/portals.lua`](../../../data/portals.lua) with new dungeons
2. Update ID mappings in [`core/utils.lua`](../../../core/utils.lua)
3. Test keystone detection
4. Verify IO calculations
5. Update user documentation