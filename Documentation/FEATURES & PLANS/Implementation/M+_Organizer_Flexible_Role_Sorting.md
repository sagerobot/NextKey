# M+ Organizer: Flexible Role Assignment Enhancement

## Overview

This document describes the enhancement to the round-robin sorting algorithm to support flexible role assignments. The goal is to intelligently place players who indicate "Want to Play DPS" but "Will Fill Tank/Healer" into tank/healer slots when no dedicated tank/healer players are available.

## Current Implementation Analysis

### Current Sorting Algorithm ([`core/organizer/sorting.lua`](../../../core/organizer/sorting.lua))

**Current Behavior:**
1. Players are separated by their **primary role** (first role in `playerData.roles[]`)
2. Round-robin distribution in 3 phases:
   - Phase 1: Tanks (1 per group)
   - Phase 2: Healers (1 per group)
   - Phase 3: DPS (3 per group)

**Limitation:**
- A player with `roles = ["DAMAGER", "TANK"]` and `specPreferences = {DAMAGER = "play", TANK = "fill"}` is categorized as pure DPS
- They will NEVER be considered for tank slots, even if no dedicated tanks exist

### Poll System Data Structure

Players submit preferences via 3-state system:
- **"play"** (Want to Play) - Priority 10
- **"fill"** (Will Fill) - Priority 5
- **"none"** (Not Playing) - Priority 0

Data stored in `playerData.specPreferences`:
```lua
playerData.specPreferences = {
    Tank = "fill",      -- Will fill tank if needed
    Healer = "none",    -- Not playing healer
    DPS = "play"        -- Want to play DPS
}

playerData.specDetails = {
    Tank = {
        { specName = "Protection Warrior", preference = "fill" }
    },
    DPS = {
        { specName = "Fury", preference = "play" },
        { specName = "Arms", preference = "none" }
    }
}
```

## Design: Flexible Role Assignment Algorithm

### Core Principles

1. **Priority-Based Assignment**: Assign players based on weighted preference scores
2. **Role Scarcity First**: Tanks/Healers assigned before DPS (current behavior maintained)
3. **Flexibility Consideration**: Players with "fill" preferences considered for understaffed roles
4. **Player Happiness Optimization**: Maximize "play" preferences, use "fill" as fallback

### Weighted Scoring System

**Role Preference Weights:**
```lua
local PREFERENCE_WEIGHTS = {
    play = 10,  -- Player WANTS this role
    fill = 5,   -- Player WILL fill this role if needed
    none = 0    -- Player will NOT play this role
}
```

**Assignment Priority Formula:**
```
PlayerScore(role) = PreferenceWeight(role) + RoleScarcityBonus(role)

Where:
- PreferenceWeight: 10 (play), 5 (fill), 0 (none)
- RoleScarcityBonus: +20 for tank, +15 for healer, +0 for DPS
```

### Enhanced Algorithm Flow

```
Phase 1: Tank Assignment (Enhanced)
├─ Collect all players with Tank preference (play OR fill)
├─ Sort by: play > fill > none
├─ Assign 1 tank per group (round-robin)
└─ Remaining tank-capable players move to flex pool

Phase 2: Healer Assignment (Enhanced)
├─ Collect all players with Healer preference (play OR fill)
├─ Exclude already-assigned tanks
├─ Sort by: play > fill > none
├─ Assign 1 healer per group (round-robin)
└─ Remaining healer-capable players move to flex pool

Phase 3: DPS Assignment (Enhanced)
├─ Collect all unassigned players
├─ Prioritize players with DPS "play" preference
├─ Assign 3 DPS per group (round-robin)
└─ Use flex pool players if needed

Flex Pool:
- Tank-capable players who weren't assigned to tank slot
- Healer-capable players who weren't assigned to healer slot
- Used to fill DPS slots with their "play" roles
```

### Example Scenario

**Input:**
```
Group 1 needs: 1 Tank, 1 Healer, 3 DPS

Available Players:
1. Alice    - Tank: play,  DPS: none
2. Bob      - Healer: play, DPS: none
3. Charlie  - DPS: play, Tank: fill
4. Diana    - DPS: play, Healer: none
5. Eve      - DPS: play, Tank: none
```

**Current Algorithm Result (WRONG):**
```
Group 1:
- Tank: Alice (Tank: play)
- Healer: Bob (Healer: play)
- DPS: Charlie, Diana, Eve
```

**Enhanced Algorithm Result (CORRECT):**
```
Group 1:
- Tank: Alice (Tank: play)
- Healer: Bob (Healer: play)
- DPS: Charlie (DPS: play), Diana (DPS: play), Eve (DPS: play)
```

**Understaffed Scenario (CRITICAL FIX):**
```
Available Players:
1. Charlie  - DPS: play, Tank: fill
2. Diana    - DPS: play, Healer: none
3. Eve      - DPS: play, Tank: none
4. Frank    - DPS: play, Healer: fill
5. George   - DPS: play, Tank: none

Current Algorithm: FAILS (no tanks assigned)
Group 1:
- Tank: [EMPTY]
- Healer: [EMPTY]
- DPS: Charlie, Diana, Eve

Enhanced Algorithm: SUCCESS
Group 1:
- Tank: Charlie (Tank: fill) ← Uses flexibility
- Healer: Frank (Healer: fill) ← Uses flexibility
- DPS: Diana, Eve, George
```

## Implementation Plan

### 1. Update Player Data Collection

**File:** [`core/organizer/sorting.lua`](../../../core/organizer/sorting.lua)

**New Function:** `CollectPlayersByRolePreference()`
```lua
-- Collect players who can play a specific role (play OR fill)
function OrganizerSorting:CollectPlayersByRolePreference(players, role)
    local result = {}
    
    for _, player in ipairs(players) do
        local preference = player.specPreferences and player.specPreferences[role]
        
        if preference == "play" or preference == "fill" then
            table.insert(result, {
                player = player,
                preference = preference,
                priority = (preference == "play") and 10 or 5
            })
        end
    end
    
    -- Sort by priority (play > fill)
    table.sort(result, function(a, b)
        return a.priority > b.priority
    end)
    
    return result
end
```

### 2. Enhanced Sorting Algorithm

**File:** [`core/organizer/sorting.lua`](../../../core/organizer/sorting.lua)

**Replace:** `CalculateSequentialAssignment()` function

**New Implementation:**
```lua
function OrganizerSorting:CalculateSequentialAssignment(benchPlayers, numGroups)
    local assignmentPlan = {}
    local assignedPlayers = {}  -- Track who's been assigned
    
    -- Phase 1: Tank Assignment (with flexibility)
    local tankCandidates = self:CollectPlayersByRolePreference(benchPlayers, "Tank")
    local tankIndex = 1
    
    for groupIndex = 1, numGroups do
        if tankIndex <= #tankCandidates then
            local candidate = tankCandidates[tankIndex]
            
            table.insert(assignmentPlan, {
                player = candidate.player,
                groupIndex = groupIndex,
                slotIndex = 1,
                role = "TANK",
                assignedFromPreference = candidate.preference  -- Track if "fill" or "play"
            })
            
            assignedPlayers[candidate.player.id] = true
            tankIndex = tankIndex + 1
        end
    end
    
    -- Phase 2: Healer Assignment (with flexibility, excluding assigned tanks)
    local healerCandidates = self:CollectPlayersByRolePreference(benchPlayers, "Healer")
    local healerIndex = 1
    
    for groupIndex = 1, numGroups do
        -- Skip already assigned players
        while healerIndex <= #healerCandidates and 
              assignedPlayers[healerCandidates[healerIndex].player.id] do
            healerIndex = healerIndex + 1
        end
        
        if healerIndex <= #healerCandidates then
            local candidate = healerCandidates[healerIndex]
            
            table.insert(assignmentPlan, {
                player = candidate.player,
                groupIndex = groupIndex,
                slotIndex = 2,
                role = "HEALER",
                assignedFromPreference = candidate.preference
            })
            
            assignedPlayers[candidate.player.id] = true
            healerIndex = healerIndex + 1
        end
    end
    
    -- Phase 3: DPS Assignment (all unassigned players)
    local dpsPlayers = {}
    for _, player in ipairs(benchPlayers) do
        if not assignedPlayers[player.id] then
            table.insert(dpsPlayers, player)
        end
    end
    
    local dpsIndex = 1
    for dpsSlotNumber = 1, 3 do
        for groupIndex = 1, numGroups do
            if dpsIndex <= #dpsPlayers then
                table.insert(assignmentPlan, {
                    player = dpsPlayers[dpsIndex],
                    groupIndex = groupIndex,
                    slotIndex = 2 + dpsSlotNumber,
                    role = "DAMAGER",
                    assignedFromPreference = "play"  -- Default
                })
                dpsIndex = dpsIndex + 1
            end
        end
    end
    
    return assignmentPlan
end
```

### 3. Visual Feedback Enhancement

**Problem:** Players assigned via "fill" preference should have visual indication

**Solution:** Enhance player card rendering to show "fill" assignments

**File:** [`ui/organizer/playerCard.lua`](../../../ui/organizer/playerCard.lua)

**Enhancement:** Add visual indicator for "fill" assignments
```lua
-- In CreateExpandedContent() or CreateCompactContent()
if card.assignedFromPreference == "fill" then
    -- Add subtle visual indicator (e.g., yellow border glow)
    local fillIndicator = CreateTrackedTexture(card, nil, "OVERLAY")
    fillIndicator:SetSize(8, 8)
    fillIndicator:SetPoint("TOPRIGHT", card, "TOPRIGHT", -2, -2)
    fillIndicator:SetColorTexture(0.9, 0.8, 0.2, 0.8)  -- Yellow dot
end
```

### 4. Data Validation

**File:** [`core/organizer/validation.lua`](../../../core/organizer/validation.lua)

**New Function:** `ValidatePlayerHasRoleCapability()`
```lua
function OrganizerValidation:ValidatePlayerHasRoleCapability(player, targetRole)
    -- Check if player has specPreferences for the target role
    if player.specPreferences then
        local preference = player.specPreferences[targetRole]
        return preference == "play" or preference == "fill"
    end
    
    -- Fallback: check playerData.roles array
    if player.roles then
        for _, role in ipairs(player.roles) do
            if role:upper() == targetRole:upper() then
                return true
            end
        end
    end
    
    return false
end
```

## Edge Cases & Validation

### Edge Case 1: Not Enough Flexible Players

**Scenario:**
- 5 groups need tanks
- Only 3 players have Tank preference (2 play, 1 fill)

**Expected Behavior:**
- Assign 2 "play" tanks first (groups 1-2)
- Assign 1 "fill" tank next (group 3)
- Groups 4-5 have no tank assigned (UI shows empty slot)

**Validation:**
- System should not crash
- Empty slots clearly marked in UI
- Organizer warned via debug message

### Edge Case 2: Player Changes Preference After Assignment

**Scenario:**
- Charlie assigned to tank slot via "fill" preference
- Charlie changes preference to Tank: "none"

**Expected Behavior:**
- Card remains in tank slot (manual mode - organizer decides)
- Visual indicator updates to show "invalid assignment" (red border?)
- Organizer can manually move Charlie if desired

**Validation:**
- Preferences are snapshot at poll submission time
- Changes don't retroactively affect assignments

### Edge Case 3: Multiple "Fill" Candidates for Same Slot

**Scenario:**
- 3 players: all DPS "play", Tank "fill"
- 1 tank slot available

**Expected Behavior:**
- First player in round-robin order gets tank slot
- Other 2 players assigned to DPS slots

**Priority Tie-Breaker:**
1. Preference level (play > fill)
2. Round-robin order (fair distribution)
3. IO score (optional - for future enhancement)

### Edge Case 4: Healer/Tank Multi-Spec Players

**Scenario:**
- Paladin with 3 specs: Holy (play), Protection (fill), Retribution (none)

**Expected Behavior:**
```
specPreferences = {
    Healer = "play",   -- Holy
    Tank = "fill",     -- Protection
    DPS = "none"       -- Retribution
}
```

- If healer slots full → check tank slots
- If tank slots full → player NOT assigned (no DPS preference)

## Testing Requirements

### Unit Tests

1. **Test: Basic Flexible Assignment**
   - Input: 1 group, 5 players (0 tanks, 1 DPS with Tank:fill)
   - Expected: DPS player assigned to tank slot

2. **Test: Priority Ordering (play > fill)**
   - Input: 2 tank slots, 1 Tank:play, 1 Tank:fill
   - Expected: "play" assigned first, "fill" assigned second

3. **Test: No Double Assignment**
   - Input: Player with Tank:play AND Healer:fill
   - Expected: Assigned to tank slot ONLY (not both)

4. **Test: Understaffed Groups**
   - Input: 3 groups, 1 tank, 1 healer
   - Expected: Group 1 has both, Groups 2-3 have empty slots

### Integration Tests

1. **Poll → Sort → Assign Flow**
   - Simulate poll submission with flexible roles
   - Run sorting algorithm
   - Verify assignments match expected distribution

2. **Visual Validation**
   - Check "fill" indicator shows correctly
   - Verify tooltip shows correct preference
   - Confirm role icons display properly

## Performance Considerations

**Complexity Analysis:**
- Current: O(n) - single pass through players
- Enhanced: O(n log n) - sorting by preference for each role
- Impact: Negligible for typical group sizes (5-50 players)

**Memory Impact:**
- Additional arrays for tank/healer candidates
- Assigned player tracking set
- Estimated: <5KB for 50 players

## Migration Strategy

### Phase 1: Add Flexible Collection (Non-Breaking)
- Implement `CollectPlayersByRolePreference()`
- Add debug logging
- Test with existing data (should work with current behavior)

### Phase 2: Update Assignment Logic
- Replace hard-coded role separation
- Use flexible collection for tank/healer phases
- Maintain DPS assignment as-is

### Phase 3: Add Visual Indicators
- Implement "fill" assignment markers
- Update tooltips to show assignment source
- Add validation warnings for invalid assignments

### Phase 4: Testing & Validation
- Run with fake player data (various preference combinations)
- Test with live polls in development environment
- Validate edge cases (understaffed groups, etc.)

## Configuration Options (Future Enhancement)

**Potential Settings:**
```lua
db.profile.organizer.sorting = {
    enableFlexibleAssignment = true,    -- Feature toggle
    preferPlayOverFill = true,          -- Always prioritize "play" preferences
    fillIndicatorEnabled = true,        -- Show visual indicator for "fill" assignments
    warnOnUnderstaffed = true          -- Show warning when groups lack tanks/healers
}
```

## Success Metrics

1. **Functional:** Players with "fill" preferences correctly assigned to understaffed roles
2. **User Experience:** Visual feedback clearly shows "play" vs "fill" assignments
3. **Performance:** No degradation in sort speed (<100ms for 50 players)
4. **Reliability:** Zero crashes or invalid assignments in testing

## Related Files

- **Core Logic:** [`core/organizer/sorting.lua`](../../../core/organizer/sorting.lua)
- **Poll System:** [`core/organizer/survey.lua`](../../../core/organizer/survey.lua)
- **UI Cards:** [`ui/organizer/playerCard.lua`](../../../ui/organizer/playerCard.lua)
- **Validation:** [`core/organizer/validation.lua`](../../../core/organizer/validation.lua)
- **Character Storage:** [`core/characterStorage.lua`](../../../core/characterStorage.lua)

## Implementation Checklist

- [ ] Implement `CollectPlayersByRolePreference()` function
- [ ] Update `CalculateSequentialAssignment()` to use flexible collection
- [ ] Add `assignedFromPreference` field to assignment objects
- [ ] Implement "fill" visual indicator in player cards
- [ ] Add tooltip enhancement to show assignment source
- [ ] Create validation function for role capability
- [ ] Add debug logging for flexible assignments
- [ ] Write unit tests for edge cases
- [ ] Test with poll simulator
- [ ] Update documentation with final implementation details

---

**Status:** Design Complete - Ready for Implementation
**Priority:** High - Core feature for flexible group formation
**Estimated Effort:** 4-6 hours implementation + 2-3 hours testing