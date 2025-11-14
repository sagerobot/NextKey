# Sorting System Testing Guide

## Phase 2.1 Completion: Pluggable Sorting System

### Overview
The sorting system has been successfully implemented with a registry-based architecture. All 7 sorting algorithms are now registered and should be available in the UI dropdown.

### What Was Implemented

#### Core Infrastructure
- **Registry System** ([`core/sorting/main.lua`](../../../core/sorting/main.lua:1))
  - `RegisterAlgorithm(name, metadata, sortFunction)` - Algorithm registration
  - `GetAlgorithmsForContext(context)` - Context-based filtering
  - `SortData(data, algorithmName)` - Sorting execution with error handling

#### Sorting Algorithms (7 total)

**Keystone Context Algorithms:**

1. **Smart Sort** ([`core/sorting/algorithms/bySmartSort.lua`](../../../core/sorting/algorithms/bySmartSort.lua:1))
   - **Priority**: 100 (highest - default)
   - **Method**: Borda count weighted ranking
   - **Weights**: IO gain (40%), player coverage (30%), key level (20%), loot (10%)
   - **Use Case**: Balanced decision-making for groups

2. **Max Group IO** ([`core/sorting/algorithms/byMaxGroupIO.lua`](../../../core/sorting/algorithms/byMaxGroupIO.lua:1))
   - **Priority**: 90
   - **Method**: Total expected IO gain across all players
   - **Use Case**: Score pushing groups maximizing total IO

3. **Player Coverage** ([`core/sorting/algorithms/byPlayerCoverage.lua`](../../../core/sorting/algorithms/byPlayerCoverage.lua:1))
   - **Priority**: 85
   - **Method**: Count of players with expected gain > 0
   - **Use Case**: Fairness-focused groups ensuring most players benefit

4. **Highest Key Level** ([`core/sorting/algorithms/byKeyLevel.lua`](../../../core/sorting/algorithms/byKeyLevel.lua:1))
   - **Priority**: 75
   - **Method**: Descending by key level
   - **Use Case**: Pushing high keys, challenge seekers

5. **Lowest Key Level** ([`core/sorting/algorithms/byKeyLevelAsc.lua`](../../../core/sorting/algorithms/byKeyLevelAsc.lua:1))
   - **Priority**: 70
   - **Method**: Ascending by key level
   - **Use Case**: Warming up, easier completions

6. **Item Need** ([`core/sorting/algorithms/byItemNeed.lua`](../../../core/sorting/algorithms/byItemNeed.lua:1))
   - **Priority**: 80
   - **Method**: Tracked loot item count (base 1000 + 100 per item)
   - **Use Case**: Loot-focused farming

7. **IO Gain Potential** ([`core/sorting/algorithms/byIOGain.lua`](../../../core/sorting/algorithms/byIOGain.lua:1))
   - **Priority**: 65
   - **Method**: Expected IO gain (similar to Max Group IO but simpler)
   - **Use Case**: Quick IO optimization

### UI Integration

The sort dropdown now dynamically populates from the Sorting registry:

**Before** ([`ui/main.lua`](../../../ui/main.lua:917) - hardcoded):
```lua
self.sortDropdown:SetList({ 
    HighestKeyLevel = "Highest Key Level", 
    LowestKeyLevel = "Lowest Key Level",
    IOGainPotential = "IO Gain Potential"
})
```

**After** (dynamic from registry):
```lua
local algorithms = NextKey222.Sorting:GetAlgorithmsForContext("KEYSTONES")
local dropdownList = {}
for _, algo in ipairs(algorithms) do
    dropdownList[algo.name] = algo.displayName
end
self.sortDropdown:SetList(dropdownList)
```

### Testing Instructions

#### 1. Launch the Game
```bash
# Start World of Warcraft and log in
/reload
```

#### 2. Open NextKey Keystone Window
```
/nk
```

#### 3. Verify Dropdown Population

**Expected Behavior:**
- Sort dropdown should show 7 algorithms in priority order:
  1. Smart Sort (Borda Count)
  2. Max Group IO
  3. Player Coverage
  4. Item Need Priority
  5. Highest Key Level
  6. Lowest Key Level
  7. IO Gain Potential

**What to Check:**
- [ ] All 7 algorithms appear in dropdown
- [ ] Display names are readable and clear
- [ ] Default selection is "Smart Sort"
- [ ] Dropdown order matches priority ranking

#### 4. Test Each Algorithm

**Setup:**
Generate test data with fake players:
```
/nk test preset mixed_skill
```

This creates a diverse party with varying IO levels.

**For Each Algorithm:**

1. **Select algorithm from dropdown**
2. **Observe keystone order**
3. **Verify sorting logic**

**Expected Results:**

| Algorithm | Expected Order | Validation |
|-----------|---------------|------------|
| Smart Sort | Balanced mix of IO/coverage/level/loot | Check keystones have good IO + multiple beneficiaries |
| Max Group IO | Highest total IO first | Sum expected IO for top keystones |
| Player Coverage | Most players benefit first | Count players with >0 gain in tooltip |
| Item Need | Tracked loot dungeons first | Check if you have loot tracked for those dungeons |
| Highest Key Level | Descending by level | 15 > 14 > 13... |
| Lowest Key Level | Ascending by level | 10 < 11 < 12... |
| IO Gain Potential | High expected gain first | Check expected IO in tooltip |

#### 5. Test Sort Persistence

1. Select a non-default algorithm (e.g., "Max Group IO")
2. Close NextKey window: `/nk`
3. Reopen NextKey window: `/nk`
4. **Verify**: Sort mode should be "Max Group IO" (persisted)

#### 6. Test Context Switching

**Keystone Window:**
```
/nk
```
- Should show all 7 keystone algorithms

**Dungeon Window:**
```
# Click "Open Dungeon View" button
```
- Should show dungeon-specific algorithms (Alphabetical, Highest IO, Lowest IO)
- Keystone algorithms should NOT appear

**Return to Keystones:**
```
# Click "Back to Keystones" button
```
- Should restore keystone algorithms
- Previous sort mode should be remembered

#### 7. Error Handling Tests

**Missing IO Calculator:**
1. Test with fake players (no real IO data)
2. **Expected**: Algorithms should handle missing data gracefully
3. **Verify**: No Lua errors, sensible fallback behavior

**Invalid Sort Mode:**
1. Use developer console to set invalid sort:
```
/run NextKey.db.char.sortMode = "InvalidAlgorithm"
/reload
/nk
```
2. **Expected**: Should fall back to first available algorithm (Smart Sort)
3. **Verify**: Dropdown shows valid selection, no errors

#### 8. Performance Tests

**Large Party Test:**
```
/nk test
/nk test
/nk test
# Repeat to generate many fake players
```

**Measure:**
- Sort switching should be instant (<100ms)
- No frame drops or stuttering
- UI remains responsive

**Expected:**
- Dropdown population: <50ms
- Sort execution: <100ms for 20+ keystones
- No memory leaks (check with `/dump collectgarbage("count")`)

### Success Criteria

✅ **Phase 2.1 Complete When:**

1. All 7 algorithms appear in keystone dropdown
2. Each algorithm sorts keystones correctly
3. Sort mode persists across sessions
4. Context switching works (keystone ↔ dungeon)
5. No Lua errors during normal operation
6. Performance remains smooth (<100ms)
7. Fallback behavior handles missing data

### Troubleshooting

#### Dropdown Shows Old Algorithms Only

**Symptom:** Only 3 algorithms (HighestKeyLevel, LowestKeyLevel, IOGainPotential)

**Cause:** Algorithm files not loaded or registration failed

**Fix:**
1. Check [`NextKey.toc`](../../../NextKey.toc:92) includes new algorithm files
2. Verify file paths are correct
3. `/reload` to reload addon
4. Check for Lua errors in chat

#### Sort Mode Doesn't Change Results

**Symptom:** Switching algorithms doesn't reorder keystones

**Cause:** Sort execution or UI refresh issue

**Fix:**
1. Check if `NextKey222.Sorting:SortData()` is being called
2. Verify `UI:RenderResults()` refreshes after sort change
3. Enable debug mode: `/nk config` → Debug System → Enable DEV level
4. Check logs for sorting category messages

#### Lua Errors on Sort

**Symptom:** "attempt to compare nil with number" or similar errors

**Cause:** Algorithm comparator function assumes data exists

**Fix:**
1. Check algorithm uses safe comparisons: `(a.value or 0) > (b.value or 0)`
2. Verify entry enrichment in `UI:EnrichEntryMetadata()`
3. Report specific error to maintainer

### Next Steps After Testing

**If Testing Successful:**
1. Mark Phase 2.5 complete in todo list
2. Update Memory Bank context.md with completion status
3. Proceed to Phase 3.1: Refactor Organizer to Event-Driven

**If Issues Found:**
1. Document specific failures
2. Check algorithm implementation against specification
3. Review debug logs for root cause
4. Fix issues before marking complete

### Developer Notes

**Adding New Algorithms:**

1. Create new file in `core/sorting/algorithms/`
2. Register with metadata:
```lua
NextKey222.Sorting:RegisterAlgorithm("MyAlgorithm", {
    displayName = "My Custom Sort",
    contexts = { "KEYSTONES" },
    description = "Sorts by custom criteria",
    priority = 50, -- Adjust priority as needed
}, function(a, b)
    -- Comparator logic
    return (a.customValue or 0) > (b.customValue or 0)
end)
```
3. Add to [`NextKey.toc`](../../../NextKey.toc:1) load order
4. Test with `/reload`

**Removing Algorithms:**

1. Comment out registration call in algorithm file
2. `/reload` to apply changes
3. Algorithm will disappear from dropdown automatically

---

## Completion Status

- [x] Phase 2.1: Registry-based sorting system implemented
- [x] All 7 algorithms created and registered
- [x] UI integration updated for dynamic dropdown
- [x] NextKey.toc updated with new files
- [ ] **Phase 2.5: In-game testing (USER ACTION REQUIRED)**

**Date Completed:** 2025-11-14  
**Implemented By:** Kilo Code (AI Assistant)  
**Ready for Testing:** Yes