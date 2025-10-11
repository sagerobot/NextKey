# Fake Player System Analysis & Improvement Plan

**Date**: October 11, 2025  
**Status**: Current State Analysis + Proposed Improvements

---

## Executive Summary

The fake player system is **mostly modular** but has several areas where fake/real player detection logic is scattered across multiple layers. The system works but violates the "display and logic shouldn't care if it's a fake or real player" principle in several places.

### Current Health Score: **6.5/10**

**Strengths:**
- ✅ ProfilesService provides good abstraction with DebugAdapter
- ✅ Fake players generate realistic data (IO scores, keystones, class distribution)
- ✅ IOCalculator handles both fake and real players uniformly
- ✅ Data structure is comprehensive with addon status, preferences, etc.

**Critical Issues:**
- ❌ Direct `dbg.players` access scattered throughout codebase (20+ locations)
- ❌ UI layer has explicit `GetFakePlayerData()` checks
- ❌ Keystones module doesn't integrate with ProfilesService
- ❌ Mixed data shapes: `key` vs `keystone` vs `dungeonID/level` tuples
- ❌ Manual cache invalidation for fake players
- ❌ Inconsistent player name resolution (FakePlayer1 vs FakePlayer1-Realm)

---

## Current Architecture Map

### Data Flow for Fake Players

```
┌─────────────────────────────────────────────────────────────┐
│ User Action (Generate Preset / Add Fake Player)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ debug/init.lua                                              │
│ - GenerateRealisticFakePlayer()                            │
│ - SetFakePlayerBest()                                      │
│ - RecalculateFakePlayerScore()                            │
│ - Stores in: NextKey.db.global.debug.players[index]       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ core/adapters/debug.lua (DebugAdapter)                     │
│ - GetProfile() - Converts dbg.players to PlayerProfile     │
│ - IsDebugPlayer()                                          │
│ ⚠️  ISSUE: Accessed by ProfilesService but not integrated  │
│    with Keystones module                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────────┐  ┌────────────────────────────┐
│ ProfilesService      │  │ UI Layer (main.lua)        │
│ - GetDebugProfile()  │  │ - GetFakePlayerData()      │
│ - Returns standard   │  │ ⚠️  ISSUE: Direct check    │
│   PlayerProfile      │  │    breaks abstraction      │
└──────────────────────┘  └────────────────────────────┘
          │                         │
          └────────────┬────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Display Layer                                               │
│ - Dungeon cards, party list, tooltips                      │
│ ✅ Should not distinguish fake vs real                     │
└─────────────────────────────────────────────────────────────┘
```

### Problem: Parallel Data Paths

```
CURRENT STATE (Broken Abstraction):

Real Players:
  WoW API → ProfilesService → UI ✅

Fake Players:  
  debug.players → DebugAdapter → ProfilesService → UI ✅ (good)
  debug.players → UI.GetFakePlayerData() ❌ (breaks abstraction)
  debug.players → Keystones.GetAvailableKeys() ❌ (direct access)
  debug.players → Options panels ❌ (direct access)
```

---

## Issue Breakdown

### 🔴 **Critical Issue #1: Direct `dbg.players` Access**

**Location**: 20+ references across:
- `options/main.lua` (8 locations)
- `debug/init.lua` (12 locations)
- `ui/main.lua` (indirect via GetFakePlayerData)

**Problem**: Code directly accesses `NextKey.db.global.debug.players[index]` instead of going through a service layer.

**Impact**:
- Cannot easily change fake player storage format
- Testing logic leaks into production code
- Difficult to add features like "import test data from file"

**Example Violation**:
```lua
-- In options/main.lua
local dbg = self:EnsureDebug()
for idx, player in ipairs(dbg.players or {}) do
    -- Direct manipulation of internal structure
    local player = dbg.players[idx]
    player.name = "NewName"
end
```

---

### 🔴 **Critical Issue #2: UI Layer Has Fake Player Detection**

**Location**: `ui/main.lua:275-288`

**Problem**:
```lua
function UI:GetFakePlayerData(playerName)
    -- Check if this is a fake player by getting their debug profile
    local debugProfile = NextKey222.ProfilesService:GetDebugProfile(playerName)
    if debugProfile and debugProfile.addonStatus then
        return debugProfile
    end
    return nil
end
```

This function exists solely to distinguish fake from real players, then is called in:
- Line 722: Check addon status for fake players
- Line 748: Get best runs for fake players

**Impact**: UI logic explicitly checks "are you fake?" before rendering, violating the abstraction principle.

---

### 🟡 **Major Issue #3: Keystones Module Bypasses ProfilesService**

**Location**: `core/keystones.lua`

**Problem**: The keystones module doesn't use ProfilesService to get player data. It directly:
1. Calls Blizzard APIs
2. Calls RaiderIO directly
3. Has no integration with fake players except through a manual `CollectPartyKeys()` hack

**Code**:
```lua
-- keystones.lua creates entries manually
local entry = {
    dungeonID = dungeonID,
    level = level,
    ownerName = ownerName,
    -- ... manually queries RaiderIO, LibOpenRaid
}
```

**Impact**: Fake players must be manually injected into keystone collection rather than being discovered naturally like real players.

---

### 🟡 **Major Issue #4: Inconsistent Data Shapes**

**Location**: Throughout codebase

**Problem**: Fake players store keystone data in multiple formats:
```lua
-- Format 1: Legacy keystone object
dbg.players[i].keystone = {
    dungeonID = 375,
    level = 15,
    ownerName = "FakePlayer1"
}

-- Format 2: Simplified key tuple
dbg.players[i].key = {
    dungeonID = 375,
    level = 15
}

-- Format 3: Per-dungeon bests
dbg.players[i].best = {
    [375] = {
        level = 15,
        chests = 2,
        score = 150
    }
}
```

Real players use completely different structures from WoW APIs.

**Impact**: Conversion logic scattered everywhere, hard to maintain.

---

### 🟡 **Major Issue #5: Player Name Inconsistency**

**Location**: `debug/init.lua`, throughout

**Problem**: Fake players have inconsistent naming:
- Created as: `"FakePlayer1"` (no realm)
- Sometimes used as: `"FakePlayer1-Realm"`
- Real players always: `"PlayerName-RealmName"`

**Code**:
```lua
-- debug/init.lua creates without realm
dbg.players[index] = {
    name = "FakePlayer" .. index,  -- ❌ No realm
    -- ...
}

-- But keystones reference with realm
ownerName = "FakePlayer" .. math.random(1, 4)  -- ❌ Inconsistent
```

**Impact**: Name matching logic fails, causing fake players to not appear in party lists or get filtered incorrectly.

---

### 🟢 **Minor Issue #6: Manual Cache Invalidation**

**Location**: `debug/init.lua:142`

**Problem**:
```lua
-- After generating fake player
if NextKey222.ProfilesService then
    NextKey222.ProfilesService:InvalidateCache(playerName)
end
```

This is manual and error-prone. Should be event-driven.

**Impact**: Risk of stale cache if developer forgets to invalidate.

---

### 🟢 **Minor Issue #7: Mixed Storage of IO Packages**

**Location**: `debug/init.lua:170-177`

**Problem**: Fake players create IO packages and store them in `Communications.playerIOCache`, but this is a global cache shared with real player data.

```lua
-- Store the standardized IO package in communications cache
if NextKey222.Communications then
    NextKey222.Communications.playerIOCache[playerName] = ioPackage
end
```

**Impact**: Pollutes the communications cache with test data, making it harder to debug real communication issues.

---

## Proposed Improvements

### 🎯 **Goal**: True Modularity
> "Display and logic shouldn't care if it's a fake or real player"

### Phase 1: Centralized Fake Player Service ⭐ **HIGH PRIORITY**

**Create**: `core/fakePlayerService.lua`

**Purpose**: Single source of truth for all fake player operations.

**API**:
```lua
FakePlayerService = {
    -- Player Management
    CreatePlayer(config) -> playerID
    RemovePlayer(playerID)
    ClearAllPlayers()
    GetPlayer(playerNameOrID) -> player
    GetAllPlayers() -> players[]
    
    -- Data Access (returns standard PlayerProfile)
    GetProfile(playerName) -> PlayerProfile
    GetKeystone(playerName) -> KeystoneEntry
    
    -- Presets
    GeneratePreset(presetType, count)
    
    -- Configuration
    SetAddonStatus(playerID, status)
    SetDungeonBest(playerID, dungeonID, level, timed)
    SetKeystone(playerID, dungeonID, level)
    
    -- Integration
    IsEnabled() -> boolean
    GetPlayerNames() -> names[]  -- For party list injection
}
```

**Benefits**:
- ✅ Single import point: `local FPS = NextKey222.FakePlayerService`
- ✅ Easy to disable entirely for production builds
- ✅ Can swap storage backend without changing callers
- ✅ Encapsulates all fake player logic

---

### Phase 2: Remove UI Fake Player Detection ⭐ **HIGH PRIORITY**

**Changes**:
1. Delete `UI:GetFakePlayerData()` entirely
2. All player data comes through `ProfilesService:BuildProfileForPlayer()`
3. ProfilesService automatically checks DebugAdapter if player not found in real sources

**Before**:
```lua
-- ui/main.lua (BAD)
local fakePlayerData = self:GetFakePlayerData(playerName)
if fakePlayerData and fakePlayerData.addonStatus then
    hasNextKey = fakePlayerData.addonStatus.nextkey
end
```

**After**:
```lua
-- ui/main.lua (GOOD)
local profile = NextKey222.ProfilesService:BuildProfileForPlayer(playerName)
if profile and profile.addonStatus then
    hasNextKey = profile.addonStatus.nextkey
end
```

**Benefits**:
- ✅ UI code identical for fake and real players
- ✅ Easier to test UI with fake data
- ✅ Cleaner separation of concerns

---

### Phase 3: Integrate Keystones with ProfilesService ⭐ **HIGH PRIORITY**

**Changes**:
1. `Keystones.createKeyEntry()` should call `ProfilesService:BuildProfileForPlayer()`
2. Remove manual RaiderIO/LibOpenRaid calls from keystones module
3. Keystones module becomes a "keystone-specific view" of player profiles

**Before**:
```lua
-- keystones.lua (BAD)
local entry = {
    dungeonID = dungeonID,
    ownerName = ownerName,
    -- Manually query RaiderIO
    rioScore = NextKey222.RaiderIO:GetProfile(ownerName)
}
```

**After**:
```lua
-- keystones.lua (GOOD)
local profile = NextKey222.ProfilesService:BuildProfileForPlayer(ownerName)
local entry = {
    dungeonID = dungeonID,
    ownerName = ownerName,
    rioScore = profile.io,
    class = profile.class,
    dungeonBest = profile.dungeonScores[dungeonID]
}
```

**Benefits**:
- ✅ Fake player keystones automatically available
- ✅ Consistent data source for all keystone metadata
- ✅ Easier to add new data sources (just update adapters)

---

### Phase 4: Standardize Player Names 🟡 **MEDIUM PRIORITY**

**Changes**:
1. All fake players created with realm suffix: `"FakePlayer1-TestRealm"`
2. Add utility function: `FakePlayerService:NormalizeName(name)` that ensures realm is present
3. Update all fake player generation to use consistent naming

**Benefits**:
- ✅ Fake players behave identically to real players in name matching
- ✅ No special cases in party member detection
- ✅ Guild view filtering works correctly

---

### Phase 5: Event-Driven Cache Invalidation 🟡 **MEDIUM PRIORITY**

**Changes**:
1. FakePlayerService fires custom events when data changes:
   - `NEXTKEY_FAKE_PLAYER_ADDED`
   - `NEXTKEY_FAKE_PLAYER_REMOVED`
   - `NEXTKEY_FAKE_PLAYER_UPDATED`
2. ProfilesService listens for these events and auto-invalidates

**Benefits**:
- ✅ No manual cache management needed
- ✅ Impossible to forget to invalidate
- ✅ Follows WoW addon best practices

---

### Phase 6: Separate Test Data Storage 🟢 **LOW PRIORITY**

**Changes**:
1. Move fake player data from `NextKey.db.global.debug.players` to dedicated storage
2. Option: `NextKey.testData.players` (not in SavedVariables)
3. OR: In-memory only with preset loader from JSON files

**Benefits**:
- ✅ SavedVariables smaller and cleaner
- ✅ Can ship preset test scenarios
- ✅ Easier to reset to clean state

---

## Implementation Priority

### Sprint 1 (Essential Foundation) - **Estimated: 4-6 hours**
1. ✅ Create `core/fakePlayerService.lua` with basic API
2. ✅ Migrate fake player creation logic to service
3. ✅ Update DebugAdapter to use FakePlayerService
4. ✅ Add comprehensive debug logging

### Sprint 2 (Remove UI Dependencies) - **Estimated: 2-3 hours**
1. ✅ Remove `UI:GetFakePlayerData()`
2. ✅ Update all UI code to use ProfilesService exclusively
3. ✅ Test that fake players render identically to real players

### Sprint 3 (Keystones Integration) - **Estimated: 3-4 hours**
1. ✅ Update `Keystones.createKeyEntry()` to use ProfilesService
2. ✅ Remove direct RaiderIO/LibOpenRaid calls
3. ✅ Test fake player keystones appear in available keys list

### Sprint 4 (Polish & Consistency) - **Estimated: 2-3 hours**
1. ✅ Standardize all fake player names with realms
2. ✅ Add event-driven cache invalidation
3. ✅ Add validation tests for fake/real player parity

---

## Testing Strategy

### Unit Tests (Pseudo-code)
```lua
function TestFakeRealPlayerParity()
    -- Generate 2 fake players
    FakePlayerService:GeneratePreset("mixed_skill", 2)
    
    -- Get profiles through service
    local fakeProfile = ProfilesService:BuildProfileForPlayer("FakePlayer1-TestRealm")
    local realProfile = ProfilesService:BuildProfileForPlayer(UnitName("player"))
    
    -- Assert same structure
    assert(fakeProfile.dataSource ~= nil)
    assert(fakeProfile.dungeonScores ~= nil)
    assert(fakeProfile.io ~= nil)
    
    -- Assert no "isFake" fields
    assert(fakeProfile.isFake == nil)
    assert(fakeProfile.isDebug == nil)
end

function TestUIRenderingParity()
    -- Generate fake player with known data
    local fakeID = FakePlayerService:CreatePlayer({
        class = "WARRIOR",
        io = 2500,
        keystoneLevel = 15
    })
    
    -- Render in UI
    UI:CreateMainFrame()
    
    -- Check that fake player appears in party list
    local entries = UI:GetPartyListEntries()
    assert(#entries > 0)
    
    -- Verify no special rendering for fake players
    for _, entry in ipairs(entries) do
        assert(entry.isFakePlayer == nil)  -- Should not exist
    end
end
```

### Integration Tests
1. **Party List Test**: Generate 4 fake players, verify all appear in party list with correct data
2. **Keystone Selection Test**: Generate fake keystones, verify they rank correctly
3. **IO Calculator Test**: Generate fake dungeon scores, verify IO calculations match real player calculations
4. **Communication Test**: Verify fake players don't pollute real communication channels

---

## Migration Path

### Week 1: Foundation
- Create FakePlayerService
- No breaking changes, new service exists alongside old code

### Week 2: Internal Migration
- Update ProfilesService, DebugAdapter to use FakePlayerService
- Options panels continue using old code (direct access)
- Full backward compatibility maintained

### Week 3: UI Migration
- Remove GetFakePlayerData from UI
- Update all UI rendering to use ProfilesService
- Add feature flag to rollback if needed

### Week 4: Keystones Migration
- Update Keystones module
- Remove direct data source access
- Extensive testing of keystone detection

### Week 5: Cleanup
- Remove old direct access patterns
- Add deprecation warnings for old APIs
- Update documentation

---

## Success Criteria

### Definition of Done
✅ **No code outside of FakePlayerService directly accesses `dbg.players`**  
✅ **UI code has zero fake player detection logic**  
✅ **Keystones module uses ProfilesService for all player data**  
✅ **Fake players appear in party list, keystone list, and tooltips identically to real players**  
✅ **All fake player names include realm suffix**  
✅ **ProfilesService automatically handles fake players without explicit checks**  
✅ **Test suite passes with 100% fake/real parity**

### Verification Tests
```lua
-- Test 1: No direct debug.players access
assert(grep_search("dbg.players") == 0, "Found direct debug.players access")

-- Test 2: UI has no fake player checks
assert(grep_search("GetFakePlayerData", "ui/") == 0, "UI still checks for fake players")

-- Test 3: Fake players work end-to-end
GeneratePreset("expert", 4)
local keys = GetAvailableKeys()
assert(#keys == 4, "Fake player keystones not appearing")
```

---

## Risk Assessment

### Low Risk ✅
- Creating FakePlayerService (additive change)
- Adding event-driven invalidation (enhancement)
- Standardizing names (cosmetic)

### Medium Risk ⚠️
- Removing UI fake player detection (behavior change, but well-tested)
- Migrating keystones to ProfilesService (major refactor, but controlled scope)

### High Risk 🔴
- None if we follow phased approach with feature flags

### Mitigation Strategies
1. **Feature Flags**: All changes behind `features.fakePlayerServiceV2`
2. **Parallel Running**: Old and new code run simultaneously during migration
3. **Extensive Logging**: Debug category `fakeplayerservice` logs all operations
4. **Rollback Plan**: Keep old code paths for 2-3 releases after migration

---

## Questions for Discussion

1. **Storage Strategy**: Keep fake players in SavedVariables or move to in-memory/JSON presets?
2. **Production Builds**: Should FakePlayerService be compiled out of production builds?
3. **Performance**: Is caching strategy sufficient for 20+ fake players?
4. **Testing**: Should we build automated tests into the addon or use external test harness?
5. **Preset Library**: Should we ship with 10+ preset scenarios for common testing needs?

---

## Appendix: Code Smell Inventory

### Direct `dbg.players` References
```bash
# Command to find violations
grep -r "dbg.players" --include="*.lua"

# Results: 20 matches
options/main.lua: 8 instances
debug/init.lua: 12 instances
```

### Fake Player Detection in UI
```bash
# Command to find violations  
grep -r "GetFakePlayerData\|IsFakePlayer\|isDebug\|isFake" ui/

# Results: 4 instances
ui/main.lua:275 (function definition)
ui/main.lua:722 (addon status check)
ui/main.lua:748 (dungeon best check)
```

### Direct RaiderIO/LibOpenRaid Access Outside Adapters
```bash
# Should only exist in adapters/
grep -r "RaiderIO\|LibOpenRaid" --include="*.lua" --exclude-dir="adapters"

# Results: 15+ instances in keystones.lua, ui/main.lua
```

---

**End of Analysis**
