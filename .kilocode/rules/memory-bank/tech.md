# NextKey Technical Stack

## Core Technologies

### Primary Language
- **Lua 5.1**: WoW addon scripting language
- **Version**: Lua 5.1 (WoW embedded version)
- **Features**: Standard Lua with WoW-specific APIs and restrictions

### Framework & Libraries

#### Ace3 Framework (Core Dependencies)
- **AceAddon-3.0**: Addon structure and lifecycle management
- **AceComm-3.0**: Inter-addon communication with throttling
- **AceDB-3.0**: SavedVariables database management with profiles
- **AceConfig-3.0**: Options panel configuration system
- **AceGUI-3.0**: UI widget framework for frames/controls
- **AceSerializer-3.0**: Data serialization for network transmission
- **AceEvent-3.0**: Event handling and registration
- **AceConsole-3.0**: Slash command registration

#### External Libraries
- **LibStub**: Library dependency management (embedded)
- **LibOpenRaid**: Real-time keystone and player data sharing (optional)
- **CallbackHandler-1.0**: Event callback management

### WoW API Integration
- **C_MythicPlus**: Keystone detection and score tracking
- **C_ChallengeMode**: Dungeon information and completion data
- **C_PlayerInfo**: Player rating summaries and profiles
- **C_Container**: Bag scanning for keystone detection
- **C_GuildInfo**: Guild roster and member information
- **C_Spell**: Spell information for teleport functionality

## Development Environment

### Required Tools
- **World of Warcraft**: Retail client (11.0.2+)
- **Text Editor**: VS Code recommended with Lua language support
- **WoW AddOns Folder**: `_retail_/Interface/AddOns/`
- **Script Errors**: Enable with `/console scriptErrors 1`

### Recommended VS Code Extensions
- Lua Language Server
- WoW API IntelliSense (if available)
- GitLens for version control
- Bracket Pair Colorizer

### Development Workflow
1. Edit files in AddOns directory
2. `/reload` in-game to test changes
3. Use `/nk config` → Debug System for troubleshooting
4. Run `/script NextKeyRunTests()` for validation
5. Test with fake players: `/nk test`

## Project Structure Standards

### File Organization
- **Core logic**: `core/` directory
- **UI components**: `ui/` directory
- **Configuration**: `options/` directory
- **Static data**: `data/` directory
- **Event handling**: `events/` directory
- **Testing**: `debug/` directory

### Load Order Management
Critical files loaded via [`NextKey.toc`](../../../NextKey.toc):
1. Libraries first (embeds.xml)
2. Configuration (config.lua)
3. Debug system (debugService.lua, debugUI.lua)
4. Boot system (boot.lua)
5. Core modules
6. UI components
7. Options panels

## Technical Constraints

### WoW API Limitations
- **No File I/O**: Cannot read/write files directly
- **Sandboxed Lua**: Restricted standard library access
- **No Multithreading**: Single-threaded execution
- **No Network Access**: Communication only via WoW channels
- **Memory Limits**: Must be memory-efficient
- **Performance**: No blocking operations during combat

### Addon Restrictions
- **Load Time**: Must initialize quickly (<2 seconds)
- **Memory**: Keep baseline under 10MB
- **Frame Rate**: Zero impact during gameplay
- **Communication**: Channel bandwidth limits
- **SavedVariables**: Size constraints for persistence

### Cross-Realm Challenges
- Player names include realm suffix (Name-Realm)
- Different realm formats and naming
- Communication across realms via party/raid channels
- LibOpenRaid dependency for cross-realm keystone sharing

## Data Sources & Dependencies

### Primary Data Sources
1. **RaiderIO Addon** (Hard Dependency)
   - Player M+ scores and ratings
   - Dungeon-specific performance data
   - Run counts and completion statistics
   - **Must be installed** for core functionality

2. **Blizzard APIs** (Always Available)
   - Current season scores via `C_MythicPlus`
   - Keystone detection via `C_MythicPlus.GetOwnedKeystoneLevel()`
   - Dungeon information via `C_ChallengeMode`

3. **LibOpenRaid** (Optional Enhancement)
   - Real-time keystone sharing across party/guild
   - Player information from compatible addons
   - Fallback when RaiderIO unavailable

4. **Fake Player Service** (Development Only)
   - Testing data generation
   - Realistic IO score distributions
   - Development workflow support

### Data Flow Priority
```
Blizzard API (Base) → LibOpenRaid (Real-time) → RaiderIO (Comprehensive) → Fake Players (Testing)
```

## Communication Protocol

### AceComm-3.0 Implementation
- **Prefix**: `NKEY1` (versioned for compatibility)
- **Channels**: PARTY, RAID, GUILD, WHISPER
- **Serialization**: AceSerializer-3.0 for complex data
- **Throttling**: 2-second minimum between messages per player
- **Validation**: All incoming messages validated before processing

### Message Structure
```lua
{
    opcode = "SYNC|PLAYER_IO_UPDATE|REQUEST_PLAYER_IO|...",
    version = "0.2.0.1",
    timestamp = GetTime(),
    sender = "PlayerName-Realm",
    data = { ... }
}
```

## Performance Optimization Techniques

### Caching Strategies
- **Profile Cache**: 5-minute TTL with event invalidation
- **Score Cache**: Per-player dungeon scores
- **UI Cache**: Rendered components and calculations
- **Message Cache**: Prevent duplicate processing

### Event-Driven Updates
- **Spec Changes**: `PLAYER_SPECIALIZATION_CHANGED`, `UNIT_SPECIALIZATION`
- **Roster Updates**: `GROUP_ROSTER_UPDATE`
- **Keystone Updates**: `CHALLENGE_MODE_KEYSTONE_SLOTTED`
- **Run Completion**: `CHALLENGE_MODE_COMPLETED`

### Lazy Evaluation
- UI created only when opened
- Profiles built on-demand
- Scores fetched when needed
- Tooltips generated dynamically

## Debugging Infrastructure

### Professional Debug System
- **Levels**: NONE (0), ERROR (1), USER (2), DEV (3), TRACE (4)
- **Categories**: 23 categories in 5 logical groups
- **UI Controls**: `/nk config` → Debug System
- **Performance**: Zero overhead when `DEV_MODE = false`
- **Compile-time Stripping**: Dev/Trace calls removed in release

### Debug Categories
```lua
-- Core Systems: startup, events, performance, database, config, options
-- Communications: communications, comms, libopenraid, raiderio, blizzard
-- Features & UI: ui, components, tooltip, teleport, lootwindow, profiles
-- Data Processing: keystones, season, IOCalculator, ioc, fakeplayerservice
-- Testing: test, debug
```

### Performance Monitoring
```lua
-- Built-in profiling system
NextKey222.Performance:StartProfile("operation_name")
-- ... code ...
NextKey222.Performance:StopProfile("operation_name")
```

## Build & Release Process

### Pre-Release Checklist
1. Set `DEV_MODE = false` in [`core/debugService.lua`](../../../core/debugService.lua:102)
2. Remove all `print()` statements (search entire project)
3. Test with debug level NONE (0) - should be silent
4. Verify memory usage under 10MB baseline
5. Test cross-realm functionality
6. Run full test suite: `/script NextKeyRunTests()`

### Version Numbering
- **Format**: `major.minor.patch.build`
- **Current**: 0.2.0.1
- **Location**: [`boot.lua`](../../../boot.lua:56-60) and [`NextKey.toc`](../../../NextKey.toc:5)

### Release Artifacts
- NextKey addon folder (complete directory)
- Documentation (user-facing only)
- README with installation instructions
- Changelog with version updates

## Integration Testing

### Testing Scenarios
1. **Solo Mode**: Addon functions without party
2. **Party Mode**: 5-player group functionality
3. **Cross-Realm**: Mixed realm party members
4. **Partial Coverage**: Some members without NextKey
5. **Guild Mode**: Guild-wide keystone coordination
6. **PUG Mode**: Group Finder integration

### Test Commands
```lua
/nk                          -- Open main window
/nk config                   -- Open options panel
/nk test                     -- Generate 4 fake players
/nk test preset mixed_skill  -- Generate preset team
/nk test clear               -- Remove fake players
/script NextKeyRunTests()    -- Run test suite
/console scriptErrors 1      -- Enable error display
```

## Known Technical Limitations

### Blizzard API Restrictions
- Keystone detection only for current player's owned keystone
- Party member keystones require LibOpenRaid or manual communication
- Score data may lag behind actual runs
- Cross-realm score queries not always available

### Addon Ecosystem Challenges
- RaiderIO data updates require external addon updates
- LibOpenRaid requires compatible addons from party members
- Some players may not have any compatible addons
- Version mismatches between party members

### Performance Constraints
- Large party sizes (>10 players) slow calculations
- Guild scans can be expensive (hundreds of members)
- UI rendering scales poorly beyond 20 items
- Communication overhead with many messages

## Development Best Practices

### Code Quality Standards
- All modules use `NextKey222.RegisterModule()`
- All critical operations use `NextKey222.SafeRun()`
- All debug uses `Debug:Error/User/Dev/Trace()`
- All expensive operations profiled with `Performance`
- MARK comments for VS Code navigation

### Error Handling Requirements
- Validate all function inputs
- Provide meaningful error messages
- Graceful degradation for missing data
- No silent failures
- Log all errors appropriately

### Performance Guidelines
- Cache frequently accessed data
- Throttle communication messages
- Batch UI updates
- Avoid string concatenation in loops
- Use table pools for frequent allocations

## Documentation Standards

### Required Documentation
- **DEVELOPMENT.md**: Technical implementation guide (PRIMARY)
- **DEBUG_SYSTEM.md**: Debug system usage (MANDATORY)
- **DESIGN.md**: Feature specifications and UX
- **USER_GUIDE.md**: End-user instructions
- **README.md**: Documentation index and navigation

### Code Documentation
- MARK comments for navigation
- Inline comments for complex logic
- Function headers with parameter descriptions
- Type annotations where helpful

## Version Control

### Repository Structure
- **Root**: Addon files only
- **Documentation/**: All documentation files
- **.kilocode/**: Kilo Code configuration
- **Libs/**: Embedded libraries (committed)

### Branching Strategy
- Main/master branch for stable releases
- Feature branches for development
- Hotfix branches for critical fixes

## Deployment

### Installation
1. Download addon package
2. Extract to `_retail_/Interface/AddOns/NextKey`
3. Ensure RaiderIO is installed
4. Restart WoW or `/reload`
5. Configure with `/nk config`

### Updates
- In-place updates supported
- SavedVariables preserved across updates
- Configuration migrates automatically (AceDB)
- No manual data migration needed