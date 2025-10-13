# NextKey Current Context

## Current State

**Status**: PUG Mode implementation completed but with initialization issues  
**Focus**: Post-implementation debugging required for startup errors  
**Phase**: Feature-complete but needs fixes before production-ready

## Recent Major Changes

### PUG Mode Implementation (Completed with Issues)
- **Complete PUG Helper System**: Implemented automatic LFG workflow assistance
  - Core state machine with 5 states (IDLE → TRACKING → INVITE_RECEIVED → IN_GROUP → RUN_COMPLETE)
  - Application tracking with invite matching
  - Event-driven architecture following NextKey patterns

- **UI Components Created**:
  - Contextual Invite Notification (`ui/pugInviteNotification.lua`)
  - Travel Assistant with teleport/hearthstone/summon options (`ui/pugTravelAssistant.lua`)
  - Post-Run Getaway UI for quick exit options (`ui/pugGetawayUI.lua`)

- **Integration Points**:
  - Event handlers updated in `events/handlers.lua`
  - Configuration added to `options/main.lua`
  - Slash commands extended in `core/slashCommands.lua`
  - Boot system updated in `boot.lua`
  - Load order updated in `NextKey.toc`

- **Testing & Debug System**:
  - Comprehensive `/nk pug` command suite
  - Workflow simulation commands
  - Debug category integration
  - Status monitoring capabilities

### Documentation Consolidation (Completed)
- **PUG Mode Documentation**: Complete technical and user documentation (`Documentation/PUG_MODE.md`)
- **Updated Index**: Added PUG Mode to main documentation index (`Documentation/README.md`)
- **Testing Commands**: Updated testing documentation with PUG Helper commands

## Current Work Status

### Completed Features
- ✅ Core keystone detection and management
- ✅ RaiderIO + LibOpenRaid + Blizzard API integration
- ✅ Multi-factor ranking algorithms (Smart Sort, Max Group IO, etc.)
- ✅ Professional debug system with UI controls
- ✅ Fake player service for testing
- ✅ Centralized profiles service
- ✅ IO Calculator with MythicPlanner.com algorithm
- ✅ Communication system for party data sharing
- ✅ Dungeon and keystone views with preferences
- ✅ Teleport integration
- ✅ Group suggestion system (Best Key, Best Groups modes)
- ✅ **PUG Mode with automatic LFG workflow assistance (implemented but has issues)**

### Active Development Areas
- **PUG Mode Initialization Issues**: Critical startup errors need resolution
  - `NextKey222DB` nil value error in pugHelper.lua:144
  - `SetBackdrop` method errors in all UI components
  - All PUG Helper modules failing to initialize properly

### Known Issues
- **PUG Helper Initialization**: `NextKey222DB` global not available during module initialization
- **UI Backdrop Issues**: `SetBackdrop` method not available during UI creation
- **Module Loading Order**: PUG Helper modules loading before required dependencies are ready
- **Boot Sequence**: PUG modules initializing in PostInit phase but dependencies not ready

## Next Steps

### Immediate Priorities (CRITICAL)
1. Fix `NextKey222DB` nil value error in PUG Helper initialization
2. Resolve `SetBackdrop` method issues in UI components
3. Adjust module loading order to ensure dependencies are ready
4. Test PUG Mode initialization after fixes
5. Validate all PUG Helper functionality works correctly

### Future Enhancements (Backlog)
- Advanced loot tracking system
- Guild-wide keystone coordination
- Historical data analytics
- Mobile companion app integration
- Import/export configurations
- Enhanced PUG Mode features based on user feedback

## Development Notes

### Important Constraints
- Must maintain <100ms UI response time
- Must not impact gameplay performance
- Must support cross-realm groups
- Must work with partial addon coverage (some party members without NextKey)

### Testing Focus
- Fix initialization errors before testing
- Use `/nk pug test` to test PUG Helper application tracking
- Use `/nk pug simulate` to test workflow steps
- Use `/nk pug status` to monitor PUG Helper state
- Test with `Debug:Dev()` system using pughelper category
- Validate PUG Mode functionality with end-to-end testing

### Season Transitions
When new season arrives:
1. Update [`data/portals.lua`](../../../data/portals.lua) with new dungeon data
2. Update ID mappings in [`core/utils.lua`](../../../core/utils.lua)
3. Test all dungeon detection and scoring
4. Update documentation with new dungeon names
5. Test PUG Mode teleport functionality with new dungeons

## Critical Reminders

### Debug System (MANDATORY)
- **NEVER** use `print()` - always use `Debug:Error/User/Dev/Trace()`
- **ALWAYS** include categories for `Dev()` and `Trace()` calls
- **ALL** debug configuration through UI: `/nk config` → Debug System
- Set `DEV_MODE = false` in [`core/debugService.lua`](../../../core/debugService.lua:102) before release

### Architecture Standards
- All modules must use `NextKey222.RegisterModule()`
- Critical operations must use `NextKey222.SafeRun()` wrapper
- Performance-critical paths must use `NextKey222.Performance` profiling
- Follow Details! Damage Meter architectural patterns

### Communication Protocol
- Use `NextKey222.Constants.COMM_PREFIX` for all messages
- Throttle at 2 seconds between messages per player
- Validate all incoming data before processing
- Support graceful degradation when comms fail

### PUG Mode Specific
- PUG Helper operates automatically - no manual mode switching required
- State machine manages transitions between LFG workflow phases
- All UI components auto-dismiss with appropriate timeouts
- Configuration options available in `/nk config` → PUG Helper
- Testing commands available via `/nk pug` command suite
- **INITIALIZATION ISSUES**: All PUG modules currently failing to initialize

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
````
User has keystone → Bag scan/Blizzard API → LibOpenRaid check → 
RaiderIO fallback → Store in cache → Notify UI → Render display
```

### 2. Score Calculation Path
````
Request scores → ProfilesService → Adapters (priority order) → 
IOCalculator → Cache result → Display in UI/tooltips
```

### 3. Communication Path
````
Event trigger → Serialize data → AceComm send → Party receives → 
Deserialize → Validate → Store in cache → Update UI
```

### 4. UI Render Path
````
User opens /nk → Collect keystones → Get party profiles → 
Calculate IO ranges → Sort by mode → Render cards → Display
```

### 5. PUG Mode Path (IMPLEMENTED BUT BROKEN)
````
LFG Application → Track application → Receive invite → Show notification → 
Join group → Show travel assistant → Complete dungeon → Show getaway UI
```

## Error Handling Strategy

### Error Recovery Layers
1. **Function Level**: `NextKey222.SafeRun()` wraps critical operations
2. **Module Level**: Each module's `Initialize()` handles startup errors
3. **Event Level**: Event handlers isolated with pcall
4. **Communication Level**: Message validation prevents corrupt data
5. **UI Level**: Graceful degradation when data unavailable
6. **PUG Mode Level**: State reset on errors, timeout handling for all operations

### Fallback Mechanisms
- **Score Data**: RaiderIO → LibOpenRaid → Blizzard API → Default 0
- **Keystones**: Blizzard API → LibOpenRaid → Bag scan → Manual entry
- **Profiles**: ProfilesService → Individual adapters → Minimal profile
- **Communication**: AceComm → Manual sync → Solo mode
- **PUG Mode**: Graceful degradation to manual LFG workflow if automation fails

### Known Initialization Errors
```
[NextKey ERROR] SafeRun failed: Initialize PUG Helper - Interface/AddOns/NextKey/core/pugHelper.lua:144: attempt to index global 'NextKey222DB' (a nil value)
[NextKey ERROR] SafeRun failed: Initialize PUG Invite Notification - ...nterface/AddOns/NextKey/ui/pugInviteNotification.lua:101: attempt to call method 'SetBackdrop' (a nil value)
[NextKey ERROR] SafeRun failed: Initialize PUG Travel Assistant - Interface/AddOns/NextKey/ui/pugTravelAssistant.lua:167: attempt to call method 'SetBackdrop' (a nil value)
[NextKey ERROR] SafeRun failed: Initialize PUG Getaway UI - Interface/AddOns/NextKey/ui/pugGetawayUI.lua:94: attempt to call method 'SetBackdrop' (a nil value)
```

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
5. Update PUG Mode teleport spell data
6. Update documentation with new dungeon names

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

-- PUG Mode Testing (BROKEN)
/nk pug test                    -- Test PUG Helper application tracking
/nk pug simulate invite         -- Simulate receiving group invite
/nk pug simulate join           -- Simulate joining group
/nk pug simulate complete       -- Simulate dungeon completion
/nk pug status                  -- Show PUG Helper status
```

## Naming Conventions (STRICTLY ENFORCED)

- **Functions**: `snake_case` - `process_keystone_data()`, `update_player_score()`
- **Variables**: `snake_case` - `player_data`, `keystone_list`
- **Modules**: `PascalCase` - `Keystones`, `IOCalculator`, `PUGHelper`
- **Constants**: `UPPER_SNAKE_CASE` - `COMM_PREFIX`, `MAX_KEY_LEVEL`
- **Private functions**: Underscore prefix - `_validate_input()`
- **Event handlers**: Start with "On" - `OnKeystoneUpdate()`
- **PUG Mode functions**: PUG prefix for clarity - `PUGHelper:OnApplicationListUpdated()`

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

### Why PUG Mode as Automatic Feature?
- **User Experience**: No manual mode switching required
- **Context Awareness**: Activates only when using LFG tool
- **Seamless Integration**: Works alongside existing NextKey functionality
- **Reduced Complexity**: Simpler user experience with automatic operation

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
6. Test PUG Mode functionality with new content

### Testing PUG Mode
1. Enable PUG Helper: `/nk pug enable`
2. Test application tracking: `/nk pug test`
3. Simulate workflow: `/nk pug simulate invite/join/complete`
4. Check status: `/nk pug status`
5. Enable debug: `/nk debug category pughelper`
6. Monitor debug output during testing

### Fixing PUG Mode Initialization Issues (CURRENT PRIORITY)
1. **NextKey222DB Error**: Move database access to later in initialization or add dependency check
2. **SetBackdrop Error**: Delay UI creation until after dependencies are loaded
3. **Module Loading Order**: Consider moving PUG modules to later phase or adding dependency checks
4. **Error Handling**: Add better error handling for missing dependencies during initialization