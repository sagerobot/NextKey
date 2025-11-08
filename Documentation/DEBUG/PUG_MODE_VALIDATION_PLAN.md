# PUG Mode Validation Plan
**Date**: November 8, 2025  
**Status**: Active Debugging  
**Goal**: Systematic end-to-end validation of PUG Helper implementation

## Critical Issues Identified

### 1. **Primary Invite Lock Not Always Set** ⚠️
**Location**: [`core/pugHelper_applications.lua:260-272`](core/pugHelper_applications.lua:260)

**Issue**: When status changes to "invited", the primary invite lock is set. However, if an application transitions to "inviteaccepted" BEFORE being seen as "invited", the primary lock may never be set.

**Evidence**:
```lua
-- Line 260-272: Only sets primary on "invited" status
if newStatus == "invited" then
    if not self.primaryInvite and not self.activeInviteID then
        self:SetPrimaryInvite(appData)
        ...
    end
end

-- Line 275-288: "inviteaccepted" checks primary but doesn't set it
if newStatus == "inviteaccepted" then
    if (self.activeInviteID and appID == self.activeInviteID) or not self.activeInviteID then
        -- Uses primary but may not have set it!
    end
end
```

**Impact**: If LFG events arrive out of order or skip "invited" status, primary invite lock fails.

**Validation Steps**:
1. Monitor debug logs for sequence: `pending -> invited -> inviteaccepted`
2. Test rapid accept scenarios where status may skip
3. Check if `activeInviteID` is nil when `inviteaccepted` fires

**Fix Required**: Set primary invite on FIRST accepted-related status if not already set.

---

### 2. **Dungeon ID Detection Fallback Chain** ⚠️
**Location**: [`core/pugHelper_applications.lua:373-408`](core/pugHelper_applications.lua:373)

**Issue**: Two-step fallback (ActivityToDungeonMap → DungeonNameMatcher) may fail if:
- Activity ID is missing or incorrect
- Group name doesn't match known abbreviations
- Portal data not loaded

**Evidence**:
```lua
-- Line 373-378: Primary method uses activityID
local dungeonID = nil
if appData.activityID and NextKey222.ActivityToDungeonMap then
    dungeonID = NextKey222.ActivityToDungeonMap:GetMapIDFromActivityID(appData.activityID)
end

-- Line 380-384: Fallback uses group name parsing
if not dungeonID and appData.name and NextKey222.DungeonNameMatcher then
    dungeonID = NextKey222.DungeonNameMatcher:ParseGroupName(appData.name)
end
```

**DungeonNameMatcher Limitations**:
- Only handles Season 1 abbreviations (see [`core/dungeonNameMatcher.lua:12-23`](core/dungeonNameMatcher.lua:12))
- Missing Season 3 patterns like "priory", "floodgate", "eco-dome"
- No fuzzy matching for typos

**Validation Steps**:
1. Test with all Season 3 dungeon group names
2. Test with non-standard abbreviations ("PSF", "OPF", "ECO")
3. Monitor fallback rate: how often ActivityToDungeonMap succeeds vs DungeonNameMatcher

**Fix Required**: Update DungeonNameMatcher for Season 3 patterns.

---

### 3. **Search Result Cache Timing** ⚠️
**Location**: [`core/pugHelper_applications.lua:20-58`](core/pugHelper_applications.lua:20)

**Issue**: SearchResultCache populated on `LFG_LIST_SEARCH_RESULTS_UPDATED` but applications processed on `LFG_LIST_APPLICATION_STATUS_UPDATED`. Race condition possible.

**Evidence**:
```lua
-- Line 20-58: Cache built from search results
function PUGHelper:CacheSearchResults()
    wipe(SearchResultCache)
    local searchResults = C_LFGList.GetSearchResults()
    -- ...caches dungeon info by resultID...
end

-- Line 132-202: Applications use cached data
local cachedInfo = SearchResultCache[resultID]
if cachedInfo then
    dungeonName = cachedInfo.dungeonName  -- May not be in cache yet!
```

**Timing Issue**:
- User browses LFG → cache populated
- User applies → application tracked with cached data
- User closes LFG → cache still valid
- BUT: If user applies BEFORE browsing full list, cache may be incomplete

**Validation Steps**:
1. Apply to group immediately after opening LFG (minimal browsing)
2. Check if `cachedInfo` is nil in debug logs
3. Monitor "No cached data" fallback messages

**Fix Consideration**: Cache may need longer TTL or on-demand population.

---

### 4. **Group Detection False Positives** ⚠️
**Location**: [`core/pugHelper_detection.lua:34-46`](core/pugHelper_detection.lua:34)

**Issue**: Detection logic may misclassify groups:

**Evidence**:
```lua
-- Line 36-40: LFG active entry = PUG
local lfgActive = C_LFGList.GetActiveEntryInfo()
if lfgActive then
    return "PUG"  -- But what if LEADER created LFG entry for guild run?
end

-- Line 43-46: PUGHelper tracking = PUG
if self.currentGroupInfo and self.currentGroupInfo.viaPUGHelper then
    return "PUG"  -- Permanent marker - never resets?
end
```

**False Positive Scenarios**:
- Guild leader creates LFG listing → detected as PUG
- Player joins guild run after PUG run → still marked as PUG

**Validation Steps**:
1. Test guild run with active LFG entry (leader posted group)
2. Verify `viaPUGHelper` flag is cleared between runs
3. Check state reset on `GROUP_LEFT`

**Fix Required**: Add heuristics (guild member count, explicit PUG markers).

---

### 5. **Teleport Window Auto-Open Race Condition** ⚠️
**Location**: [`core/pugHelper_applications.lua:412-421`](core/pugHelper_applications.lua:412)

**Issue**: 0.7 second delay may conflict with other UI operations or state changes.

**Evidence**:
```lua
-- Line 412-421: Delayed teleport window open
C_Timer.After(0.7, function()
    NextKey222.SafeRun(function()
        if not NextKey.teleportWindow or not NextKey.teleportWindow.frame or not NextKey.teleportWindow.frame:IsShown() then
            NextKey:ToggleTeleportWindow()  -- What if user manually opened it?
        end
    end, "PUGHelper:ShowTeleportOnMPlusAccepted")
end)
```

**Race Conditions**:
- User manually opens teleport window during 0.7s delay
- Multiple invites within 0.7s (secondary invites)
- User declines invite during delay → window opens anyway

**Validation Steps**:
1. Rapidly accept/decline multiple invites
2. Manually open teleport window immediately after accept
3. Monitor for double-open or premature open

**Fix Consideration**: Check state at execution time, not just frame visibility.

---

## Systematic Testing Protocol

### Phase 1: State Machine Validation
**Goal**: Verify state transitions work correctly under all scenarios

**Test Cases**:
1. **Happy Path**: `IDLE → TRACKING → INVITE_RECEIVED → IN_GROUP → RUN_COMPLETE → IDLE`
2. **Decline Path**: `TRACKING → INVITE_RECEIVED → TRACKING` (invite declined)
3. **Cancel Path**: `TRACKING → IDLE` (cancel applications)
4. **Multiple Invites**: Track 3 apps, get invited to 2, accept first
5. **Out-of-Order Events**: Verify primary lock handles event reordering

**Commands**:
```lua
-- Monitor state
/script print("PUG State:", NextKey222.PUGHelper:GetState())
/script print("Primary Invite:", tostring(NextKey222.PUGHelper.activeInviteID))

-- Test UI
/nkpugtest  -- Opens PUG Helper Test UI
```

**Expected Results**:
- All transitions log with context
- Invalid transitions rejected with error
- Primary invite lock set on first invite, never overwritten by secondary

---

### Phase 2: Dungeon Detection Validation
**Goal**: Verify dungeon ID resolution for all Season 3 dungeons

**Test Matrix**:
| Dungeon | Activity ID | Abbrev Tested | Expected Map ID |
|---------|-------------|---------------|-----------------|
| Priory of the Sacred Flame | 1281 | priory, PSF, sacred | 499 |
| The Dawnbreaker | 1285 | dawn, dawnbreaker, DB | 505 |
| Eco-Dome Al'dani | 1694 | eco, eco-dome, aldani | 542 |
| Tazavesh: Streets | 1016 | taza, streets, tazavesh | 391 |
| Ara-Kara | 1284 | ara, kara, ara-kara | 503 |
| Tazavesh: Gambit | 1017 | gambit, taza gambit | 392 |
| Operation: Floodgate | 1550 | flood, floodgate, OPF | 525 |
| Halls of Atonement | 699 | halls, HOA, atonement | 378 |

**Test Procedure**:
1. Use Test UI to simulate acceptance for each dungeon
2. Verify activityID → mapID resolution logs
3. Test fallback by corrupting activityID
4. Test group name variations

**Commands**:
```lua
-- Simulate specific dungeon
/nkpugtest  -- Use dropdown to select dungeon, click "Simulate: Get Accepted to Group"

-- Check mapping
/script print(NextKey222.ActivityToDungeonMap:GetMapIDFromActivityID(1281))  -- Should be 499
/script print(NextKey222.DungeonNameMatcher:ParseGroupName("Priory +10"))  -- Should be 499
```

---

### Phase 3: Primary Invite Lock Validation
**Goal**: Verify first-accepted-wins behavior

**Test Scenarios**:
1. **Single Invite**: Apply to 1 group → get invited → verify lock
2. **Concurrent Invites**: Apply to 3 groups → invited to 2 simultaneously → verify first locks, second ignored
3. **Sequential Invites**: Invited to A, decline, invited to B → verify B becomes new primary
4. **Race Condition**: Invited to A and B in same frame → verify deterministic locking

**Debug Checks**:
```lua
-- After each invite
/script print("Primary ID:", NextKey222.PUGHelper.activeInviteID)
/script print("Primary Data:", NextKey222.PUGHelper.primaryInvite and NextKey222.PUGHelper.primaryInvite.name)

-- After decline
/script print("Primary Cleared:", NextKey222.PUGHelper.activeInviteID == nil)
```

**Expected Behavior**:
- First invite sets lock
- Secondary invites ignored (logged but not processed)
- Decline clears lock
- Next invite after decline becomes new primary

---

### Phase 4: Teleport Integration Validation
**Goal**: Verify teleport window shows correct context

**Test Cases**:
1. **PUG Accept**: Accept invite → teleport window opens in PUG mode with correct dungeon
2. **PUG Complete**: Finish M+ → teleport window shows Leave Group option
3. **Guild Run**: Join guild group → teleport window NOT in PUG mode
4. **Manual Open**: User opens teleport before auto-open → no duplicate

**Verification**:
```lua
-- Check teleport context
/script local ctx = NextKey222.Addon.teleportWindow and NextKey222.Addon.teleportWindow.context
/script print("Mode:", ctx and ctx.mode, "Complete:", ctx and ctx.dungeonComplete)

-- Check target key
/script local key = NextKey222.Addon:GetTeleportTargetKey()
/script print("Target:", key and key.dungeonID, key and key.level)
```

---

### Phase 5: Performance & Throttling
**Goal**: Verify no FPS drops or log spam

**Test Scenarios**:
1. **Rapid LFG Updates**: Browse LFG with 20+ groups → verify throttling
2. **Rapid Application Status**: Apply to 5 groups, rapid status changes
3. **Group Roster Spam**: Large raid with frequent roster updates

**Metrics**:
- Frame rate stays above 60 FPS
- LFG update throttle activates (0.5s minimum)
- Debug logs limited (no more than 10/sec)

**Commands**:
```lua
-- Enable performance monitoring
/nkperf start

-- After test
/nkperf metrics
```

---

## Known Limitations (Accept as Design)

1. **ActivityID Dependency**: If Blizzard doesn't provide activityID, fallback to name matching required
2. **Group Name Variations**: Can't match every possible abbreviation/typo
3. **Event Timing**: WoW event order not guaranteed; state machine must handle reordering
4. **Cross-Realm**: Group detection may behave differently cross-realm

---

## Critical Bugs to Fix Before Production

### Priority 1 (Blockers):
- [ ] Primary invite lock: Handle missing "invited" status (fix in pugHelper_applications.lua)
- [ ] DungeonNameMatcher: Add Season 3 abbreviations (fix in dungeonNameMatcher.lua)

### Priority 2 (Important):
- [ ] Group detection: Add guild vs PUG heuristics (fix in pugHelper_detection.lua)
- [ ] Teleport auto-open: Add state validation before toggle (fix in pugHelper_applications.lua)

### Priority 3 (Nice to Have):
- [ ] Search result cache: Add on-demand population fallback
- [ ] Performance: Add adaptive throttling based on application count

---

## Debug Commands Reference

```lua
-- PUG Helper State
/script print("State:", NextKey222.PUGHelper:GetState())
/script print("Primary:", NextKey222.PUGHelper.activeInviteID)
/script print("Apps:", #NextKey222.PUGHelper:GetApplicationsAsArray())

-- Group Detection
/script print("Group Type:", NextKey222.PUGHelper:DetectGroupType())
/script local info = NextKey222.PUGHelper:GetGroupTypeInfo()
/script print(info.displayText, info.type)

-- Test UI
/nkpugtest  -- Full test interface
/script NextKey222.PUGHelperTestUI:SimulateGroupAccept()
/script NextKey222.PUGHelperTestUI:SimulateDungeonComplete()

-- Application Tracker (Debug UI)
/script NextKey222.PUGApplicationTracker:Show()

-- Teleport
/script NextKey222.Addon:ToggleTeleportWindow()
/script print("Context:", NextKey222.Addon.teleportWindow.context.mode)
```

---

## Next Steps

1. ✅ Create validation plan (this document)
2. ⏳ Fix Priority 1 bugs (primary invite lock + Season 3 abbreviations)
3. ⏳ Run Phase 1-3 tests (state machine + detection + primary lock)
4. ⏳ Fix Priority 2 bugs based on test results
5. ⏳ Run Phase 4-5 tests (teleport + performance)
6. ⏳ Update Memory Bank with findings
7. ⏳ Mark PUG Mode as validated or document remaining issues
