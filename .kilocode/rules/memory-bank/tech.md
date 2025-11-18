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
  - **CRITICAL**: `RegisterMessage(messageName, callback)` passes only ONE parameter to callback
  - Callback signature: `function(_, payload)` NOT `function(event, payload)`
  - The first parameter IS the payload (message name already known from registration)
  - Incorrect signature will result in `nil` payload and silent event handler failures
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

### Development Workflow
1. Edit files in AddOns directory
2. `/reload` in-game to test changes
3. Use `/nk config` → Debug System for troubleshooting
4. Test with fake players: `/nk test`
5. Run targeted tests as needed

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

5. **Seasonal Loot Dataset** (`data/loot.lua`)
   - Featured and dropdown loot for the active season
   - Slot metadata for tooltip and filtering logic

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
    version = "0.2.1",
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

### Performance Tooling
- `ui/performanceOptimizer.lua` centralizes UI throttling helpers
- `events/performanceHandlers.lua` for roster/LFG batching
- `debug/performanceMonitor.lua` + `debug/performanceTest.lua` for runtime metrics
- Test commands: `/nk pug performance test`, `/nkperf metrics`, `/nkperf test`

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

## Testing Infrastructure

### Simplified Testing Protocol
NextKey uses a simplified, practical testing approach focused on core functionality and reliability.

**Testing Hierarchy**:
1. **In-Game Testing**: Use the addon as a normal user would
2. **Basic Debug Output**: Use debug system for troubleshooting only
3. **Error Reporting**: Focus on catching and reporting errors effectively
4. **Manual Verification**: Check that features work as expected

### Common Test Commands
```lua
/nk test                        -- Generate 4 random fake players
/nk test preset mixed_skill     -- Generate preset team
/nk test clear                  -- Remove all fake players
/script NextKeyRunTests()       -- Run test suite
```

## Build & Release Process

### Pre-Release Checklist
1. Set `DEV_MODE = false` in [`core/debugService.lua`](../../../core/debugService.lua)
2. Remove all `print()` statements (search entire project)
3. Test with debug level NONE (0) - should be silent
4. Verify memory usage under 10MB baseline
5. Test cross-realm functionality
6. Run full test suite

### Version Numbering
- **Format**: `major.minor.patch`
- **Current**: 0.2.1
- **Location**: [`boot.lua`](../../../boot.lua) and [`NextKey.toc`](../../../NextKey.toc)

### Release Artifacts
- NextKey addon folder (complete directory)
- Documentation (user-facing only)
- README with installation instructions
- Changelog with version updates

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
- Use component factories for all UI creation

### AceEvent-3.0 Event Handling (CRITICAL)

**How AceEvent SendMessage Works:**

When you call:
```lua
NextKey222.Addon:SendMessage("EVENT_NAME", payload)
```

AceEvent-3.0 uses CallbackHandler-1.0, which calls:
```lua
Dispatch(events[eventname], eventname, ...)  -- CallbackHandler line 54
```

This means registered callbacks receive:
1. **First parameter**: The message name (e.g., "EVENT_NAME")
2. **Remaining parameters**: All additional arguments from SendMessage

**CORRECT callback signature:**
```lua
NextKey222.Addon:RegisterMessage("EVENT_NAME", function(messageName, payload)
    -- First parameter: message name ("EVENT_NAME")
    -- Second parameter: payload (from SendMessage second argument)
    self:HandleEvent(payload)
end)
```

**ALSO CORRECT (if you don't need the message name):**
```lua
NextKey222.Addon:RegisterMessage("EVENT_NAME", function(_, payload)
    -- First parameter: message name (ignored with _)
    -- Second parameter: payload
    self:HandleEvent(payload)
end)
```

**WRONG (will receive nil payload):**
```lua
NextKey222.Addon:RegisterMessage("EVENT_NAME", function(event)
    -- Only receives message name, payload is lost!
    self:HandleEvent()  -- No payload!
end)
```

**Reference implementations:**
- Fixed: `ui/main.lua:462` (corrected November 18, 2025)
- Library source: `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua:54` (Dispatch function)

**Key rule**: AceEvent's `SendMessage(name, data)` results in callbacks receiving `(name, data)` as separate parameters via CallbackHandler's Dispatch mechanism.

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
- Component pooling for frequent creation

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
