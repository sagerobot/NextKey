# Service Module Analysis: IOCalculator, Profiles, Scoring

**Date**: November 14, 2025  
**Version**: 0.6.0  
**Status**: Complete - Phase 2 Task 2.2

---

## Executive Summary

This document analyzes three core service modules in NextKey to validate their compliance with the pure service pattern. **All three modules are well-architected service modules** that follow best practices, though IOCalculator has some technical debt that should be addressed.

**Verdict**: ✅ **APPROVED** - All three modules qualify as pure service modules with minor improvements recommended.

---

## Module Analysis

### 1. IOCalculator (`core/ioCalculator.lua`)

**Lines of Code**: 1531  
**Complexity**: HIGH (multiple calculation algorithms, caching, adapter integration)  
**Service Pattern Compliance**: ✅ **EXCELLENT** (with minor improvements needed)

#### Current Architecture

**Module Registration**:
```lua
local IOCalculator = {}
NextKey222.IOCalculator = IOCalculator
NextKey222.RegisterModule("IOCalculator", IOCalculator)
```

**Core Responsibilities**:
1. Mythic+ score calculation using MythicPlanner.com algorithm
2. IO gain range calculations (min/max/expected)
3. Player score tracking and retrieval
4. Group recommendation generation
5. Optimizer helper functions (Gain, AggregateValues, WeightedScore)

**Data Sources** (read-only):
- ProfilesService (player profiles)
- Communications (shared IO data)
- RaiderIOAdapter (RaiderIO scores)
- BlizzardAdapter (current player scores)
- FakePlayerService (testing data)

**Public API** (synchronous service calls):
```lua
-- Core Calculations
IOCalculator:EstimateRunScore(level, timed, fractionalTime)
IOCalculator:CalculateDungeonScore(runTime, timeLimit, keyLevel)
IOCalculator:GetDungeonMetrics(keyLevel)

-- Player Score Analysis
IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
IOCalculator:GetPlayerTotalIO(playerName)
IOCalculator:HasPlayerAddonData(playerName)

-- IO Range Calculations
IOCalculator:CalculateIORange(keystoneData, playerProfile)
IOCalculator:CalculateGroupIORange(keystoneData, partyProfiles)

-- Optimizer Functions
IOCalculator:Gain(playerName, keystoneData)
IOCalculator:CalculateAggregateValues(playerNames, keystoneData)
IOCalculator:GetWeightedScore(playerName, roleWeights)
IOCalculator:GetUtilityScore(playerName, utilityWeights)
IOCalculator:GetCombinedScore(playerName, roleWeights, utilityWeights)
IOCalculator:GetPreferenceScore(playerName, dungeonID, preferenceWeights)

-- Group Recommendations
IOCalculator:GenerateGroupRecommendations(availableKeystones, partyProfiles, sortMode)
```

#### Service Pattern Validation

✅ **Pure Service**: No direct UI dependencies  
✅ **Synchronous APIs**: All methods return immediately  
✅ **One-Way Dependencies**: Depends on other services (Profiles, Adapters) but they don't depend on it  
✅ **SafeRun Wrapped**: Critical operations use NextKey222.SafeRun  
✅ **Error Handling**: Graceful degradation when adapters unavailable  
✅ **Caching**: Implements refresh-cycle memoization (5-second TTL)  

#### Performance Characteristics

**Caching Strategy**:
- Refresh cycle memoization (line 12-16)
- 5-second cache reset interval
- Per-player, per-dungeon score lookups cached

**Optimization Features**:
- Batch processing support (`GetPlayerDungeonScores`)
- Memoization to avoid redundant API calls
- Early-return for invalid inputs

#### Areas of Concern

⚠️ **Technical Debt** (lines 525-794):

1. **Massive GetPlayerDungeonScore Function** (269 lines):
   - Multiple fallback paths with duplicate logic
   - Memoization wrapper calls backup function (lines 787-793)
   - Difficult to maintain and test

2. **Duplicate Code**:
   - `GetPlayerDungeonScore` (lines 525-794)
   - `_GetPlayerDungeonScore_Original` (lines 797-1003)
   - **206 lines of duplicated logic** for memoization wrapper

3. **Complex Fallback Chain**:
   - ProfileService → RaiderIO fallback → CurrentPlayer UI → Communications → Legacy fake players → Stored scores
   - 6 different data source checks with overlapping logic

#### Recommended Improvements

**Priority 1: Refactor GetPlayerDungeonScore**

Extract data source checks into strategy pattern:

```lua
-- NEW: core/ioCalculator/scoreSources.lua
local ScoreSources = {
    priority = {
        "ProfileService",
        "Communications", 
        "RaiderIO",
        "FakePlayer",
        "StoredScore"
    }
}

function ScoreSources:GetScore(playerName, dungeonID)
    for _, sourceName in ipairs(self.priority) do
        local source = self.sources[sourceName]
        if source and source:CanHandle(playerName) then
            local score = source:GetScore(playerName, dungeonID)
            if score and score > 0 then
                return score, sourceName
            end
        end
    end
    return 0, "no_data"
end
```

**Priority 2: Remove Duplicate Memoization Logic**

The memoization wrapper should wrap the ENTIRE function, not call a backup:

```lua
-- BEFORE (problematic):
function IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
    -- ... 200 lines of logic ...
    
    -- Then calls backup with same logic
    local originalResult = self:_GetPlayerDungeonScore_Original(playerName, dungeonID)
    self.scoreLookupCache[cacheKey] = originalResult
    return self.scoreLookupCache[cacheKey]
end

-- AFTER (clean):
local function _GetPlayerDungeonScore_Internal(self, playerName, dungeonID)
    -- All the actual lookup logic here (single source of truth)
end

function IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
    -- Memoization check
    local cacheKey = string.format("%s:%d:%d", playerName, dungeonID, self.refreshCycleID)
    if self.scoreLookupCache[cacheKey] then
        return self.scoreLookupCache[cacheKey]
    end
    
    -- Call internal function
    local result = _GetPlayerDungeonScore_Internal(self, playerName, dungeonID)
    
    -- Cache and return
    self.scoreLookupCache[cacheKey] = result
    return result
end
```

**Priority 3: Consolidate Adapter Calls**

Use ProfilesService as SINGLE source, improve ProfilesService data merging:

```lua
-- IOCalculator should trust ProfilesService to handle all data sources
function IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
    -- ProfilesService already merges all adapters
    local profile = NextKey222.ProfilesService:GetProfile(playerName)
    if profile and profile.dungeonScores and profile.dungeonScores[dungeonID] then
        return profile.dungeonScores[dungeonID].bestScore or 0
    end
    return 0
end
```

#### Module Dependencies

**Required**:
- `NextKey222.Debug` - Debug logging
- `NextKey222.SafeRun` - Error handling
- `NextKey222.RegisterModule` - Module registration

**Optional** (graceful degradation):
- `NextKey222.ProfilesService` - Player profiles (primary source)
- `NextKey222.Communications` - Shared IO data
- `NextKey222.RaiderIOAdapter` - RaiderIO scores
- `NextKey222.FakePlayerService` - Testing data
- `NextKey222.UI` - Current player score fallback
- `NextKey222.IDMapper` - Dungeon ID conversions

**Announces**: None (pure service, doesn't announce state changes)  
**Listens**: None (synchronous service, doesn't react to events)

---

### 2. ProfilesService (`core/profiles.lua`)

**Lines of Code**: 1189  
**Complexity**: HIGH (multi-source data merging, caching, event-driven invalidation)  
**Service Pattern Compliance**: ✅ **EXCELLENT**

#### Current Architecture

**Module Registration**:
```lua
local ProfilesService = {}
NextKey222.ProfilesService = ProfilesService
NextKey222.RegisterModule("ProfilesService", ProfilesService)
```

**Core Responsibilities**:
1. Unified player profile building from multiple data sources
2. LRU cache with automatic eviction (max 100 profiles)
3. Event-driven cache invalidation
4. Organizer-specific profile enrichment
5. Dungeon preference management

**Data Sources** (read-only):
- DebugAdapter (fake players)
- LibOpenRaidAdapter (keystone inventory)
- RaiderIOAdapter (comprehensive IO scores)
- BlizzardAdapter (local client data, real-time spec detection)

**Public API** (synchronous service calls):
```lua
-- Profile Retrieval
ProfilesService:GetProfile(playerName)
ProfilesService:GetOrganizerProfile(playerName)
ProfilesService:GetPartyProfiles(mode, customMembers)
ProfilesService:GetOrganizerProfilesBatch(playerNames)

-- Profile Components
ProfilesService:GetAvailableRoles(playerName)
ProfilesService:GetUtilities(playerName)
ProfilesService:GetPreferences(playerName)
ProfilesService:GetAlts(playerName)
ProfilesService:GetPlayerKeystone(playerName)

-- Cache Management
ProfilesService:InvalidateCache(playerName)
ProfilesService:GetCacheStats()

-- Preferences
ProfilesService:GetDungeonPreference(dungeonID)
ProfilesService:ToggleDungeonPreference(dungeonID, isLike)
```

#### Service Pattern Validation

✅ **Pure Service**: No direct UI dependencies (calls UI refresh methods, but doesn't depend on UI structure)  
✅ **Synchronous APIs**: All profile retrieval is immediate  
✅ **One-Way Dependencies**: Adapters feed into ProfilesService, but don't depend on it  
✅ **SafeRun Wrapped**: All event handlers wrapped (lines 240-242)  
✅ **Error Handling**: Graceful fallbacks when adapters unavailable  
✅ **LRU Caching**: Memory leak fix with max 100 profiles, automatic eviction (lines 461-474)  
✅ **Event-Driven Invalidation**: 9 registered events for smart cache invalidation

#### Performance Characteristics

**Caching Strategy**:
- LRU cache with max 100 entries (lines 82-86)
- 5-minute TTL per cache entry (line 84)
- Event-driven selective invalidation (not full cache clear)
- Performance metrics tracking (lines 88-95, 680-703)

**Cache Hit Rate Tracking**:
```lua
cacheStats = { 
    hits = 0, 
    misses = 0, 
    builds = 0, 
    invalidations = 0, 
    evictions = 0 
}
```

**Event-Driven Invalidation** (lines 147-303):
- `CHALLENGE_MODE_KEYSTONE_SLOTTED` → Selective invalidation
- `CHALLENGE_MODE_COMPLETED` → Selective invalidation
- `GROUP_ROSTER_UPDATE` → Only when roster size changes
- `PLAYER_SPECIALIZATION_CHANGED` → Current player only
- `UNIT_SPECIALIZATION` → Specific unit only
- Custom messages: `NEXTKEY_FAKE_PLAYER_UPDATED`, `NEXTKEY_FAKE_PLAYER_REMOVED`

#### Profile Data Merging Strategy

**Intelligent Precedence Rules** (lines 505-599):

1. **IO Score Merging** (line 515-522):
   - Only merge if source io > 0 (prevents LibOpenRaid 0s from overwriting RaiderIO)
   - Track which source provided the IO (`ioDataSource`)

2. **Spec Data Merging** (lines 531-552):
   - Blizzard adapter data ALWAYS overrides (real-time spec detection)
   - Ensures spec changes detected immediately

3. **Dungeon Score Merging** (lines 564-598):
   - RaiderIO data ALWAYS overwrites (even if 0) - authoritative source
   - Non-RaiderIO sources skip zero scores (prevents overwriting real data)

**Critical Fix Applied** (line 575-582):
```lua
-- RaiderIO data ALWAYS overwrites (even if 0)
local isRaiderIOData = source.dataSource == "raiderio"

-- For non-RaiderIO sources, skip zero scores
if sourceScore > 0 or isRaiderIOData then
    if sourceScore > existingScore or isRaiderIOData then
        target.dungeonScores[dungeonID] = scoreData
    end
end
```

#### UI Refresh Integration

**RefreshUIComponents Method** (lines 305-350):
- Called after spec changes to update UI
- Clears render tracking to force re-render
- Updates both Main UI and RosterBoard
- Uses 500ms delay for spec changes (allows Blizzard API to update)

⚠️ **Potential Concern**: This creates a soft dependency on UI modules

**Recommended Pattern**:
```lua
-- CURRENT (soft dependency):
function ProfilesService:RefreshUIComponents(event)
    if NextKey222.UI and NextKey222.UI.RefreshResults then
        NextKey222.UI:RefreshResults()
    end
end

-- BETTER (event-driven):
function ProfilesService:RefreshUIComponents(event)
    -- Announce profile update via event
    NextKey:SendMessage("PROFILE_UPDATED", event)
    -- UI modules listen and refresh themselves
end
```

#### Module Dependencies

**Required**:
- `NextKey222.Debug` - Debug logging
- `NextKey222.RegisterModule` - Module registration
- `NextKey222.Addon` - Event registration

**Optional** (graceful degradation):
- `NextKey222.DebugAdapter` - Fake player profiles
- `NextKey222.LibOpenRaidAdapter` - Keystone inventory data
- `NextKey222.RaiderIOAdapter` - Comprehensive IO scores
- `NextKey222.BlizzardAdapter` - Local client data
- `NextKey222.CharacterStorage` - Multi-role/utilities/alts data
- `NextKey222.IDMapper` - Dungeon ID conversions

**Announces**: None directly (should use events for UI refresh - see recommendation)  
**Listens**: 9 WoW events + 2 custom messages for cache invalidation

---

### 3. Scoring (`core/scoring.lua`)

**Lines of Code**: 118  
**Complexity**: LOW (mostly wrappers to IOCalculator)  
**Service Pattern Compliance**: ✅ **EXCELLENT**

#### Current Architecture

**Module Registration**: Attached to `NextKey.Addon` (not separate module)

**Core Responsibilities**:
1. Legacy wrapper functions for score calculations
2. RaiderIO integration helpers
3. Season score tracking

**Public API** (all delegate to IOCalculator):
```lua
-- Score Estimation
NextKey:GetRunScoreForLevel(level, timed)
NextKey:CalculateMythicPlusScore(level, chests)

-- Season Tracking
NextKey:GetSeasonBestLevel(dungeonID)
NextKey:GetCurrentScore()
NextKey:GetPreviousScore()
NextKey:UpdatePlayerScore()

-- RaiderIO Integration
NextKey:GetRaiderIOTotalScore()
```

#### Service Pattern Validation

✅ **Pure Service**: No UI dependencies  
✅ **Synchronous APIs**: All methods return immediately  
✅ **Delegates to IOCalculator**: Properly uses IOCalculator for calculations (line 18-24)  
✅ **Minimal Logic**: Only contains necessary wrapper/tracking code  

#### Current Status

**All score calculations delegated to IOCalculator** (lines 17-25):
```lua
function NextKey:GetRunScoreForLevel(level, timed)
    if not level or level < 2 then return 0 end
    -- Use IOCalculator directly for score estimation
    if NextKey222.IOCalculator then
        local fractionalTime = timed and 0.9 or nil
        return NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    end
    return 0
end
```

#### Recommended Future

**Consider Deprecation**:
- Most functions are thin wrappers around IOCalculator
- Adds indirection without significant value
- Could be merged into IOCalculator or removed entirely

**Keep These Functions** (unique functionality):
- `UpdatePlayerScore()` - Actively updates scores from API
- `GetCurrentScore()` / `GetPreviousScore()` - State tracking

**Deprecate These Functions** (direct IOCalculator equivalents):
- `GetRunScoreForLevel()` → `IOCalculator:EstimateRunScore()`
- `CalculateMythicPlusScore()` → `IOCalculator:EstimateRunScore()`

#### Module Dependencies

**Required**:
- None (standalone)

**Optional**:
- `NextKey222.IOCalculator` - Score calculations (fallback to 0 if unavailable)
- `RaiderIO` addon - Enhanced score data

**Announces**: None  
**Listens**: None

---

## Architectural Compliance Summary

### Service Pattern Checklist

| Criterion | IOCalculator | ProfilesService | Scoring |
|-----------|-------------|-----------------|---------|
| No UI dependencies | ✅ Yes | ⚠️ Soft (calls refresh) | ✅ Yes |
| Synchronous APIs | ✅ Yes | ✅ Yes | ✅ Yes |
| One-way dependencies | ✅ Yes | ✅ Yes | ✅ Yes |
| SafeRun wrapped | ✅ Yes | ✅ Yes | N/A (minimal) |
| Error handling | ✅ Graceful | ✅ Graceful | ✅ Graceful |
| Caching strategy | ✅ Memoization | ✅ LRU + Events | N/A |
| Performance monitoring | ❌ No | ✅ Yes | N/A |
| RegisterModule | ✅ Yes | ✅ Yes | ❌ No |

### Overall Assessment

**IOCalculator**: ✅ **SERVICE** (with refactoring recommended)  
**ProfilesService**: ✅ **SERVICE** (exemplary implementation)  
**Scoring**: ✅ **SERVICE** (consider deprecation/merge)

---

## Recommendations

### Immediate Actions (Phase 2)

1. ✅ **Document module dependencies** (completed in this analysis)
2. **IOCalculator Refactoring** (Priority: HIGH):
   - Extract score source strategy pattern
   - Remove duplicate memoization logic
   - Consolidate adapter calls through ProfilesService

3. **ProfilesService Event Pattern** (Priority: MEDIUM):
   - Replace direct UI calls with event announcements
   - Let UI modules listen for `PROFILE_UPDATED` events

### Future Considerations (Phase 3+)

1. **Scoring Module Deprecation**:
   - Move unique functions into IOCalculator
   - Update all callers to use IOCalculator directly
   - Remove thin wrapper functions

2. **Performance Monitoring**:
   - Add performance tracking to IOCalculator (similar to ProfilesService)
   - Track slowest calculations, average times

3. **Testing Infrastructure**:
   - Create unit tests for calculation accuracy
   - Test profile merging logic with mock adapters
   - Validate caching behavior under load

---

## Conclusion

**All three modules are well-architected service modules** that follow the pure service pattern correctly. ProfilesService is an exemplary implementation with excellent caching, event-driven invalidation, and performance monitoring. IOCalculator has some technical debt (duplicate logic) but is fundamentally sound. Scoring is minimal and could be deprecated/merged into IOCalculator for simplicity.

**Confidence Level**: **HIGH** - These modules are production-ready and demonstrate mature service architecture.

**Next Steps**:
1. Proceed with IOCalculator refactoring (Phase 2 Task 2.3)
2. Continue with remaining service modules
3. Document event-driven patterns for UI refresh