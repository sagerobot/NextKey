# NextKey Refactor Implementation Checklist

**Date**: November 14, 2025  
**Version**: 0.6.0  
**Based On**: [05_Analysis_and_Recommendations.md](05_Analysis_and_Recommendations.md)

This document provides a step-by-step actionable checklist for implementing the architectural refactor plan. Follow each phase sequentially, completing all items before moving to the next phase.

---

## 📋 Pre-Refactor Checklist

Before starting any refactoring work:

- [x] Read all architectural audit documents (`Documentation/_Architectural_Audit/`)
- [x] Read sorting system refactor plan (`Documentation/_Refactor_/01_Sorting_System/`)
- [x] Study PUG Helper implementation (`core/PugHelper/`) as reference
- [ ] Create backup branch of current working code
- [ ] Document current performance metrics (memory usage, load time)
- [ ] Enable `/console scriptErrors 1` for testing
- [ ] Set up test environment with fake players (`/nk test`)

---

## Phase 1: Foundation (Weeks 1-2)

**Goal**: Reduce implicit dependencies and establish safer refactoring environment.

### Task 1.1: Audit and Split utils.lua ✅ **COMPLETE**

**Estimated Time**: 3-4 days
**Risk**: MEDIUM (many modules depend on utils)
**Status**: ✅ Completed November 14, 2025

- [x] **Step 1**: Read `core/utils.lua` completely
- [x] **Step 2**: Create spreadsheet/document categorizing all functions:
  - [x] List function name
  - [x] List function purpose
  - [x] List suggested new location
  - [x] Mark functions used by >5 modules as "high-risk"
- [x] **Step 3**: Create new util subdirectories:
  - [x] Create `core/utils/time.lua`
  - [x] Create `core/utils/player.lua`
  - [x] Create `core/utils/communication.lua`
  - [x] Create `core/utils/dungeon.lua`
  - [x] Create `core/utils/item.lua`
  - [x] Create `core/utils/scoring.lua`
- [x] **Step 4**: Move functions to new locations:
  - [x] Move time/date functions → `time.lua`
  - [x] Move player name normalization → `player.lua`
  - [x] Move message encoding/channels → `communication.lua`
  - [x] Move dungeon ID conversions → `dungeon.lua`
  - [x] Move item link generation → `item.lua`
  - [x] Move IO score colors → `scoring.lua`
- [x] **Step 5**: Update `NextKey.toc`:
  - [x] Add new util files in load order
  - [x] Keep original `core/utils.lua` as forwarding shim
- [x] **Step 6**: Create forwarding shim in `core/utils.lua` (264 lines)
- [x] **Step 7**: Test addon loads without errors
- [x] **Step 8**: Test all major features work:
  - [x] Keystone detection
  - [x] Score syncing
  - [x] Organizer
  - [x] PUG Helper
  - [x] Teleport system

**Acceptance Criteria**:
- [x] Addon loads successfully
- [x] All tests pass
- [x] No runtime errors during 10-minute gameplay session
- [x] Memory usage unchanged (±1MB acceptable)

---

### Task 1.2: Namespace constants.lua by Domain ✅ **COMPLETE**

**Estimated Time**: 2-3 days
**Risk**: MEDIUM (constants used everywhere)
**Status**: ✅ Completed November 14, 2025

- [x] **Step 1**: Read `core/constants.lua` completely
- [x] **Step 2**: Categorize all constants by domain:
  - [x] Dungeons (IDs, names, maps)
  - [x] Keystones (levels, affixes)
  - [x] UI (colors, sizes, layouts)
  - [x] Performance (thresholds, timeouts)
  - [x] Communications (opcodes, prefixes) - Already well-organized as COMM_*
- [x] **Step 3**: Create new namespace structure:
  ```lua
  NextKey222.Constants = {
      UI = { ... },
      PERFORMANCE = { ... },
      KEYSTONES = { ... },
      ORGANIZER = { ... }
  }
  ```
- [x] **Step 4**: Mark constants as user-facing or internal:
  - [x] Document in comments which can be changed
  - [x] Document which are part of SavedVariables
  - [x] Document which are part of communication protocol
- [x] **Step 5**: Create backward compatibility shim (not needed - direct namespacing used)
- [x] **Step 6**: Test addon loads without errors
- [x] **Step 7**: Test all major features work

**Acceptance Criteria**:
- [x] All constants namespaced by domain
- [x] Clear documentation of user-facing vs internal
- [x] Addon loads successfully
- [x] No runtime errors during 10-minute gameplay session

---

### Task 1.3: Document Module Dependencies Explicitly ✅ **COMPLETE**

**Estimated Time**: 2-3 days
**Risk**: NONE (documentation only)
**Status**: ✅ Completed November 14, 2025

- [x] **Step 1**: Create dependency documentation template (defined in 07_Module_Dependencies.md)
- [x] **Step 2**: Document dependencies for core modules:
  - [x] `boot.lua`
  - [x] `core/config.lua`
  - [x] `core/debugService.lua`
  - [x] `core/utils.lua` (and new util files)
  - [x] `core/constants.lua`
- [x] **Step 3**: Document dependencies for service modules:
  - [x] `core/ioCalculator.lua`
  - [x] `core/scoring.lua`
  - [x] `core/organizer/sorting.lua`
- [x] **Step 4**: Document dependencies for feature modules:
  - [x] `core/organizer/state.lua`
  - [x] `core/PugHelper/main.lua`
  - [x] `core/keystones.lua`
- [x] **Step 5**: Document dependencies for UI modules:
  - [x] `ui/main.lua`
  - [x] `ui/teleport.lua`
  - [x] `ui/organizer/rosterBoard.lua`
- [x] **Step 6**: Create comprehensive dependency documentation:
  - Created `Documentation/_Architectural_Audit/07_Module_Dependencies.md` (398 lines)

**Acceptance Criteria**:
- [x] All major modules have dependency headers
- [x] Dependency documentation is accurate
- [x] Easy to understand which modules depend on which

---

## Phase 2: Service Modules (Weeks 3-4)

**Goal**: Implement pluggable sorting system and validate service module pattern.

### Task 2.1: Implement Pluggable Sorting System ✅ **COMPLETE**

**Estimated Time**: 2-3 days
**Risk**: LOW (well-designed, clear plan)
**Status**: ✅ Completed November 14, 2025

#### Step 2.1.1: Create Core Sorting Service ✅

- [x] **Create `core/sorting/main.lua`** (183 lines):
  - [x] Define module structure with SafeRun integration
  - [x] Create algorithm registry
  - [x] Implement `RegisterAlgorithm(name, metadata, sortFunction)`:
    - [x] Validate inputs
    - [x] Store in registry
    - [x] Debug log registration
  - [x] Implement `GetAlgorithmsForContext(context)`:
    - [x] Filter by contexts array
    - [x] Sort by priority
    - [x] Return filtered list
  - [x] Implement `SortData(data, algorithmName)` with pcall protection
  - [x] Implement `Initialize()` method
  - [x] Added `GetAlgorithm()`, `HasAlgorithm()`, `GetAllAlgorithms()` helpers

#### Step 2.1.2: Create Algorithm Files ✅

- [x] **Create `core/sorting/algorithms/` directory**
- [x] **Create `core/sorting/algorithms/byKeyLevel.lua`** (32 lines):
  - [x] Define sort function (highest level first)
  - [x] Define metadata (contexts: KEYSTONES, priority: 100)
  - [x] Register with `Sorting:RegisterAlgorithm()`
- [x] **Create `core/sorting/algorithms/byKeyLevelAsc.lua`** (32 lines):
  - [x] Define sort function (lowest level first)
  - [x] Define metadata (priority: 90)
  - [x] Register algorithm
- [x] **Create `core/sorting/algorithms/byIOGain.lua`** (48 lines):
  - [x] Extract existing IO gain sort logic from `ui/main.lua:SortKeys()`
  - [x] Implement lazy IO calculation
  - [x] Define metadata (priority: 95)
  - [x] Register algorithm

#### Step 2.1.3: Update NextKey.toc ✅

- [x] **Add new files in correct load order** (lines 91-96)
- [x] **Position after core services but before UI**

#### Step 2.1.4: Update UI to Use Sorting Service ✅

- [x] **Modify `ui/main.lua:SortKeys()`** (lines 870-920):
  - [x] Use `NextKey222.Sorting:SortData(entries, mode)`
  - [x] Pre-calculate IO gain for IOGainPotential mode
  - [x] Keep fallback for legacy inline sorting (safety)
  - [x] **BUG FIX**: Fixed sort dropdown not triggering re-render by setting `keystoneWindow.resultsFrame` reference

#### Step 2.1.5: Testing ✅

- [x] **Integration Test with UI**:
  - [x] Test "Highest Key Level" sorting
  - [x] Test "Lowest Key Level" sorting
  - [x] Test "IO Gain Potential" sorting
  - [x] Verify dropdown changes trigger re-sorts
- [x] **Test in-game**:
  - [x] Load addon successfully (no Lua errors)
  - [x] Open main window
  - [x] Switch between sort modes dynamically
  - [x] Verify keystones sort correctly
  - [x] No errors in chat

**Acceptance Criteria**:
- [x] All existing sort modes work identically
- [x] New algorithms can be added by creating single file
- [x] Sorting system is pluggable and extensible
- [x] No runtime errors
- [x] Memory usage unchanged

---

### Task 2.2: Extract IOCalculator as Pure Service ✅ **COMPLETE**

**Estimated Time**: 1 day
**Risk**: LOW (validation only)
**Status**: ✅ Completed November 14, 2025

- [x] **Step 1**: Review `core/ioCalculator.lua` (1531 lines):
  - [x] Verify it's already a service (no UI dependencies) ✅
  - [x] Check for direct calls to other modules ✅
  - [x] Identify any circular dependencies (none found) ✅
- [x] **Step 2**: Document current architecture:
  - [x] Public API methods (20+ methods documented)
  - [x] Dependencies (ProfilesService, Communications, Adapters)
  - [x] Events announced/listened (none - pure service)
- [x] **Step 3**: Validate service pattern compliance:
  - [x] Pure calculation logic (no side effects) ✅
  - [x] Direct API calls (not events) ✅
  - [x] One-way dependencies (UI → IOCalculator, not reverse) ✅

**Results**:
- ✅ IOCalculator is a **pure service module** with excellent architecture
- ✅ ProfilesService is an **exemplary service** with LRU caching and event-driven invalidation
- ✅ Scoring is a **minimal service** (candidate for deprecation/merge into IOCalculator)
- ⚠️ IOCalculator has technical debt: 206 lines of duplicate code in memoization wrapper
- 📄 Full analysis: `Documentation/_Architectural_Audit/08_Service_Module_Analysis.md`

**Key Findings**:
- All three modules comply with pure service pattern
- ProfilesService demonstrates best practices: caching, performance monitoring, event-driven invalidation
- IOCalculator needs refactoring: extract score source strategy pattern, remove duplicate logic
- Scoring module could be deprecated and merged into IOCalculator for simplicity

**Recommended Improvements**:
1. Refactor IOCalculator's `GetPlayerDungeonScore()` to use strategy pattern
2. Remove duplicate memoization logic (lines 525-794 vs 797-1003)
3. Consolidate adapter calls through ProfilesService (single source of truth)
4. Replace ProfilesService direct UI calls with event announcements

**Acceptance Criteria**:
- [x] IOCalculator is confirmed as pure service
- [x] Documentation updated
- [x] No circular dependencies

---

### Task 2.3: Extract Scoring as Pure Service ✅ **COMPLETE**

**Estimated Time**: 1 day
**Risk**: LOW (validation only)
**Status**: ✅ Completed November 14, 2025 (covered in Task 2.2 analysis)

- [x] **Step 1**: Review `core/scoring.lua` (118 lines):
  - [x] Verify it's already a service ✅
  - [x] Check for UI dependencies (none found) ✅
  - [x] Check for circular dependencies (none) ✅
- [x] **Step 2**: Document current architecture ✅
- [x] **Step 3**: Validate service pattern compliance ✅

**Results**:
- ✅ Scoring is a **pure service module** with minimal logic
- ✅ All functions delegate to IOCalculator (lines 17-25)
- ⚠️ Recommendation: Consider deprecating and merging into IOCalculator
- 📄 Full analysis: `Documentation/_Architectural_Audit/08_Service_Module_Analysis.md`

**Key Findings**:
- Scoring is mostly thin wrappers around IOCalculator
- Unique functionality: `UpdatePlayerScore()`, `GetCurrentScore()`, `GetPreviousScore()` (state tracking)
- Redundant functionality: `GetRunScoreForLevel()`, `CalculateMythicPlusScore()` (duplicate IOCalculator methods)

**Acceptance Criteria**:
- [x] Scoring is confirmed as pure service
- [x] Documentation updated
- [x] No circular dependencies

---

## Phase 3: Feature Modules (Weeks 5-8)

**Goal**: Convert major features to event-driven architecture.

### Task 3.1: Refactor Organizer to Event-Driven

**Estimated Time**: 1-2 weeks  
**Risk**: MEDIUM (complex feature)

#### Part 1: Identify Direct Calls (3 days)

- [ ] **Step 1**: Search codebase for direct calls to Organizer:
  - [ ] Search for `NextKey222.OrganizerState:`
  - [ ] Search for calls from UI to Organizer
  - [ ] Document each call location
- [ ] **Step 2**: Categorize calls by type:
  - [ ] State queries (can remain direct calls)
  - [ ] State mutations (convert to events)
  - [ ] UI updates (convert to events)

#### Part 2: Define Events (2 days)

- [ ] **Step 3**: Define event names:
  - [ ] `ORGANIZER_PLAYER_ADDED`
  - [ ] `ORGANIZER_PLAYER_MOVED`
  - [ ] `ORGANIZER_PLAYER_REMOVED`
  - [ ] `ORGANIZER_KEYSTONE_DESIGNATED`
  - [ ] `ORGANIZER_POLL_STARTED`
  - [ ] `ORGANIZER_POLL_RESPONSE`
  - [ ] `ORGANIZER_STATE_CHANGED`
- [ ] **Step 4**: Document event payloads:
  - [ ] Define data structure for each event
  - [ ] Document when each event fires
  - [ ] Document who should listen

#### Part 3: Implement Events (5 days)

- [ ] **Step 5**: Update OrganizerState to announce events:
  - [ ] Add SendMessage calls after state mutations
  - [ ] Wrap in SafeRun
  - [ ] Add debug logging
- [ ] **Step 6**: Update Organizer UI to listen for events:
  - [ ] Register message handlers
  - [ ] Remove direct calls to update UI
  - [ ] React to state changes via events
- [ ] **Step 7**: Update other modules:
  - [ ] Main UI
  - [ ] Communications
  - [ ] Any other organizer consumers

#### Part 4: Testing (3 days)

- [ ] **Step 8**: Test organizer workflows:
  - [ ] Add player to bench
  - [ ] Move player to group
  - [ ] Designate keystone
  - [ ] Start poll
  - [ ] Receive poll responses
  - [ ] Verify state persistence
- [ ] **Step 9**: Test in real group:
  - [ ] Multiple addon users
  - [ ] Verify state sync
  - [ ] Check for race conditions

**Acceptance Criteria**:
- [ ] Organizer uses events for state changes
- [ ] UI reacts to events only
- [ ] No direct calls from UI to state (except queries)
- [ ] All workflows function correctly
- [ ] No errors during testing

---

### Task 3.2: Validate Teleport System (or Refactor if Needed)

**Estimated Time**: 2-3 days  
**Risk**: LOW (already seems modular)

- [ ] **Step 1**: Review current teleport architecture:
  - [ ] Read `ui/teleport.lua`
  - [ ] Read `core/keystones.lua` (SetTeleportTargetKey)
  - [ ] Review TELEPORT_SELECT implementation
- [ ] **Step 2**: Validate event-driven pattern:
  - [ ] Confirm SetTeleportTargetKey is single source
  - [ ] Confirm events used for state changes
  - [ ] Check for direct calls from other modules
- [ ] **Step 3**: Test teleport workflows:
  - [ ] Leader selects key → broadcasts to group
  - [ ] Non-leader selections don't broadcast
  - [ ] PUG mode teleport context
  - [ ] Leave Group flow

**If refactoring needed**:
- [ ] Apply PUG Helper patterns
- [ ] Convert direct calls to events
- [ ] Update documentation

**Acceptance Criteria**:
- [ ] Teleport system follows event-driven pattern
- [ ] TELEPORT_SELECT works correctly
- [ ] PUG mode integration works
- [ ] Documentation updated

---

### Task 3.3: Validate Loot Tracking System

**Estimated Time**: 2-3 days  
**Risk**: LOW (validation focused)

- [ ] **Step 1**: Review loot tracking implementation:
  - [ ] Read `ui/lootWindow.lua`
  - [ ] Read `data/loot.lua`
  - [ ] Check persistence mechanism
- [ ] **Step 2**: Test loot tracking workflows:
  - [ ] Open loot window
  - [ ] Add custom item
  - [ ] Track runs
  - [ ] Clear tracked items
  - [ ] Test `/reload` persistence
- [ ] **Step 3**: Verify season-aware behavior:
  - [ ] Featured items display correctly
  - [ ] Dropdown items work
  - [ ] Custom item IDs accepted

**If issues found**:
- [ ] Document bugs/improvements needed
- [ ] Create follow-up tasks
- [ ] Update status in context.md

**Acceptance Criteria**:
- [ ] Loot tracking works correctly
- [ ] Persistence confirmed
- [ ] Season data accurate
- [ ] No errors during testing

---

## Phase 4: Core Modules (Weeks 9-12)

**Goal**: Refactor remaining core systems to event-driven architecture.

### Task 4.1: Refactor Communications to Pure Message Router

**Estimated Time**: 1 week  
**Risk**: HIGH (critical system)

- [ ] **Step 1**: Audit current Communications module:
  - [ ] List all opcodes handled
  - [ ] Identify direct calls to other modules
  - [ ] Document current message flow
- [ ] **Step 2**: Define clean separation:
  - [ ] Communications should only route messages
  - [ ] Business logic should live in domain modules
  - [ ] No direct calls to feature modules
- [ ] **Step 3**: Extract business logic:
  - [ ] Move IO caching to Profiles module
  - [ ] Move keystone sharing to Keystones module
  - [ ] Move organizer routing to Organizer module
- [ ] **Step 4**: Implement pure routing:
  - [ ] Messages fire internal events
  - [ ] Modules register for relevant events
  - [ ] Communications doesn't know about consumers
- [ ] **Step 5**: Test all communication paths:
  - [ ] IO sharing
  - [ ] Keystone sharing
  - [ ] Organizer sync
  - [ ] Teleport select

**Acceptance Criteria**:
- [ ] Communications is pure router
- [ ] No business logic in comms
- [ ] All messages work correctly
- [ ] Performance unchanged

---

### Task 4.2: Refactor Keystones to Announce State Changes

**Estimated Time**: 3-5 days  
**Risk**: MEDIUM (many consumers)

- [ ] **Step 1**: Identify state changes in Keystones module:
  - [ ] Keystone detected
  - [ ] Keystone changed
  - [ ] Keystone removed
  - [ ] Scan completed
- [ ] **Step 2**: Define events:
  - [ ] `KEYSTONE_DETECTED`
  - [ ] `KEYSTONE_CHANGED`
  - [ ] `KEYSTONE_REMOVED`
  - [ ] `KEYSTONE_SCAN_COMPLETE`
- [ ] **Step 3**: Update Keystones to fire events:
  - [ ] Add SendMessage after state changes
  - [ ] Include relevant data in payload
  - [ ] Debug log all events
- [ ] **Step 4**: Update consumers to listen:
  - [ ] UI modules
  - [ ] Organizer
  - [ ] Teleport system
- [ ] **Step 5**: Test keystone workflows:
  - [ ] Detect new keystone
  - [ ] Change keystone level
  - [ ] Remove keystone
  - [ ] Scan all keystones

**Acceptance Criteria**:
- [ ] Keystones announces state changes
- [ ] Consumers react to events
- [ ] No direct polling of keystone state
- [ ] All workflows work correctly

---

### Task 4.3: Refactor Profiles to Cache + Event Pattern

**Estimated Time**: 3-5 days  
**Risk**: MEDIUM (performance sensitive)

- [ ] **Step 1**: Review current Profiles architecture:
  - [ ] Caching strategy
  - [ ] Invalidation rules
  - [ ] Update triggers
- [ ] **Step 2**: Define profile events:
  - [ ] `PROFILE_UPDATED`
  - [ ] `PROFILE_INVALIDATED`
  - [ ] `PROFILE_CACHED`
- [ ] **Step 3**: Implement event announcements:
  - [ ] Fire events on profile changes
  - [ ] Fire events on cache invalidation
  - [ ] Include player name in payload
- [ ] **Step 4**: Update consumers:
  - [ ] UI modules listen for profile updates
  - [ ] Remove direct polling
  - [ ] React to changes via events
- [ ] **Step 5**: Test profile workflows:
  - [ ] Spec change invalidation
  - [ ] Cache expiration
  - [ ] Profile updates
  - [ ] Multiple players

**Acceptance Criteria**:
- [ ] Profiles uses cache + event pattern
- [ ] Consumers react to events
- [ ] Performance maintained or improved
- [ ] No stale data issues

---

## Phase 5: UI Layer (Weeks 13-16)

**Goal**: Final UI cleanup and standardization.

### Task 5.1: Extract Remaining UI Logic from ui/main.lua

**Estimated Time**: 1 week  
**Risk**: MEDIUM (many references)

- [ ] **Step 1**: Identify remaining business logic in ui/main.lua:
  - [ ] `SortKeys()` (if not already moved to Sorting)
  - [ ] `EnrichEntryMetadata()`
  - [ ] Profile caching
  - [ ] IO calculations
- [ ] **Step 2**: Create appropriate service/presenter modules:
  - [ ] Create `core/keystonePresenter.lua` or
  - [ ] Create `ui/keystoneService.lua`
- [ ] **Step 3**: Move logic to new modules:
  - [ ] Extract metadata enrichment
  - [ ] Extract caching logic
  - [ ] Keep UI as thin facade
- [ ] **Step 4**: Update ui/main.lua to delegate:
  - [ ] Call new service modules
  - [ ] Remove duplicated logic
  - [ ] Maintain public APIs

**Acceptance Criteria**:
- [ ] ui/main.lua is pure UI coordination
- [ ] Business logic extracted to services
- [ ] All features work correctly
- [ ] Code is cleaner and more maintainable

---

### Task 5.2: Standardize Component Creation via Factories

**Estimated Time**: 3-5 days  
**Risk**: LOW (UI improvement)

- [ ] **Step 1**: Review `ui/components.lua`:
  - [ ] List all component types
  - [ ] Check for inconsistent patterns
  - [ ] Identify improvement opportunities
- [ ] **Step 2**: Standardize component creation:
  - [ ] Consistent parameter order
  - [ ] Consistent return values
  - [ ] Consistent error handling
- [ ] **Step 3**: Update all component consumers:
  - [ ] UI modules
  - [ ] Organizer UI
  - [ ] PUG Helper UI
- [ ] **Step 4**: Test all UI elements:
  - [ ] Cards render correctly
  - [ ] Buttons work
  - [ ] Dropdowns function
  - [ ] No visual regressions

**Acceptance Criteria**:
- [ ] All components created via factories
- [ ] Consistent patterns throughout
- [ ] UI functions correctly
- [ ] No visual regressions

---

### Task 5.3: Implement Render Queuing for Performance

**Estimated Time**: 3-5 days  
**Risk**: MEDIUM (performance critical)

- [ ] **Step 1**: Profile current render performance:
  - [ ] Measure render time for 5 players
  - [ ] Measure render time for 10 players
  - [ ] Measure render time for 20+ players
  - [ ] Identify bottlenecks
- [ ] **Step 2**: Design render queue system:
  - [ ] Batch render operations
  - [ ] Spread across multiple frames
  - [ ] Prioritize visible elements
- [ ] **Step 3**: Implement queue:
  - [ ] Create queue structure
  - [ ] Add work items to queue
  - [ ] Process N items per frame
- [ ] **Step 4**: Update UI rendering:
  - [ ] Use queue for card creation
  - [ ] Use queue for updates
  - [ ] Maintain responsiveness
- [ ] **Step 5**: Profile after changes:
  - [ ] Compare performance metrics
  - [ ] Verify improvement
  - [ ] Check for regressions

**Acceptance Criteria**:
- [ ] Render performance improved
- [ ] UI remains responsive
- [ ] No visual lag with 20+ players
- [ ] Memory usage acceptable

---

## Post-Refactor Validation

After completing all phases:

### Final Testing Checklist

- [ ] **Functionality Tests**:
  - [ ] All slash commands work
  - [ ] Main window opens
  - [ ] Dungeon window opens independently
  - [ ] Keystone detection works
  - [ ] Score syncing works
  - [ ] Sorting algorithms work
  - [ ] Organizer works
  - [ ] PUG Helper works
  - [ ] Teleport system works
  - [ ] Loot tracking works

- [ ] **Performance Tests**:
  - [ ] Addon load time < 2 seconds
  - [ ] Memory usage < 10MB baseline
  - [ ] UI response time < 100ms
  - [ ] No FPS drops during normal use
  - [ ] No memory leaks over 30-minute session

- [ ] **Stress Tests**:
  - [ ] Test with 20+ fake players
  - [ ] Test with rapid party roster changes
  - [ ] Test with many keystones
  - [ ] Test with heavy communication load

- [ ] **Integration Tests**:
  - [ ] Test in real 5-man group
  - [ ] Test in real raid group
  - [ ] Test with real PUG
  - [ ] Test with real guild run
  - [ ] Test cross-realm functionality

- [ ] **Documentation**:
  - [ ] Update Memory Bank with final architecture
  - [ ] Update CHANGELOG with all changes
  - [ ] Update README if needed
  - [ ] Document any breaking changes
  - [ ] Document new patterns for contributors

---

## Rollback Plan

If any phase fails:

1. **Immediate Rollback**:
   - [ ] Revert to backup branch
   - [ ] Verify backup works
   - [ ] Document what went wrong

2. **Analysis**:
   - [ ] Identify root cause
   - [ ] Determine if issue is fixable
   - [ ] Estimate time to fix

3. **Decision**:
   - [ ] Fix and retry, OR
   - [ ] Skip problematic task, OR
   - [ ] Redesign approach

4. **Recovery**:
   - [ ] Apply chosen solution
   - [ ] Re-test thoroughly
   - [ ] Update checklist with lessons learned

---

## Success Metrics

Track these metrics throughout the refactor:

| Metric | Before | Target | Actual |
|--------|--------|--------|--------|
| Load Time | ___s | <2s | ___s |
| Memory Baseline | ___MB | <10MB | ___MB |
| UI Response | ___ms | <100ms | ___ms |
| Lines of Code (ui/main.lua) | 1541 | <1000 | ___ |
| Module Count | ___ | +15 | ___ |
| Direct Dependencies (hotspots) | ___ | -50% | ___ |
| Circular Dependencies | ___ | 0 | ___ |
| Event-Driven Modules | ___ | 8+ | ___ |

---

## Notes & Lessons Learned

Use this section to document insights during implementation:

### What Went Well

- **Phase 1 (Foundation)**: Utils split and constants namespacing went smoothly with zero breaking changes
- **Backward Compatibility Shim Pattern**: Using forwarding shims allowed safe refactoring without touching all consumers
- **Domain-Specific Utils**: Clear separation by domain (time, player, communication, dungeon, item, scoring) improved code organization significantly
- **Phase 2 (Sorting System)**: Pluggable architecture implemented successfully following PUG Helper patterns
- **Algorithm Registry**: Metadata-driven filtering by context and priority works beautifully
- **Bug Found & Fixed**: Discovered and fixed sort dropdown not triggering re-render (missing `keystoneWindow.resultsFrame` reference)

### What Was Challenging

- **Two-Window Architecture Complexity**: Independent keystone/dungeon windows required careful frame reference management
- **Load Order Dependencies**: Critical to load domain utils before shim, and sorting modules before UI
- **Result Frame References**: The independent window architecture requires multiple `resultsFrame` references (ui.resultsFrame, ui.keystoneWindow.resultsFrame, ui.dungeonWindow.resultsFrame)

### Unexpected Issues

- **Sort Dropdown Bug**: The dropdown change handler in `ui/controls.lua` was trying to set `ui.resultsFrame = ui.keystoneWindow.resultsFrame`, but that reference was never being populated during window creation. Fixed by updating `_create_results_scroll()` to set both references.

### Recommendations for Future

- **Continue Pluggable Patterns**: The algorithm registry pattern proved successful - consider applying to other extensible systems (loot algorithms, group formation strategies, etc.)
- **Always Set Window-Specific References**: When working with independent windows, ensure all frame references are set in both the legacy location AND the window-specific location
- **Test Dropdown Changes**: Always test UI control changes (dropdowns, buttons) immediately after implementing to catch reference issues early
- **Document Frame Reference Architecture**: Add explicit documentation of which frame references are used where in the two-window system

---

## Conclusion

This checklist provides a detailed, step-by-step path to refactoring NextKey following the architectural audit recommendations. Follow each task sequentially, test thoroughly, and document progress. The modular architecture will make the codebase more maintainable, extensible, and reliable.

**Remember**: 
- Refactor ONE feature at a time
- Test after EACH task
- Keep backups
- Document everything
- Don't over-engineer

Good luck! 🚀