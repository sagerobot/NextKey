# PUG Mode Critical Fixes - November 8, 2025

## Overview
**Priority**: P1 (Blockers)  
**Status**: Fixed, Awaiting Validation  
**Files Modified**: 2  
**Related**: [PUG_MODE_VALIDATION_PLAN.md](PUG_MODE_VALIDATION_PLAN.md)

---

## Fix 1: Primary Invite Lock - Missing "invited" Status Handler

### Issue
**Location**: [`core/pugHelper_applications.lua:259-288`](../../core/pugHelper_applications.lua:259)

**Problem**: The primary invite lock was only set when an application transitioned to "invited" status. However, LFG events can arrive out of order or skip states entirely. If an application went directly from "pending" to "inviteaccepted" without being seen as "invited", the primary lock would never be set, breaking the first-accepted-wins guarantee.

**Impact**: 
- Multiple invites could drive teleport targeting
- Race conditions when receiving multiple invites
- Inconsistent PUG Helper state

### Root Cause Analysis
```lua
-- BEFORE: Primary lock only set on "invited"
if newStatus == "invited" then
    if not self.primaryInvite and not self.activeInviteID then
        self:SetPrimaryInvite(appData)
        self:OnMPlusAccepted(appData)
    end
end

if newStatus == "inviteaccepted" then
    -- Assumed primary was already set!
    if (self.activeInviteID and appID == self.activeInviteID) or not self.activeInviteID then
        -- This could execute with no primary lock if "invited" was skipped
    end
end
```

**Event Sequence That Failed**:
1. Apply to multiple groups
2. Group A: `pending -> inviteaccepted` (skipped "invited")
3. Primary lock never set
4. Group B: `pending -> invited`
5. Group B becomes primary even though A was accepted first

### Fix Implementation
**File**: `core/pugHelper_applications.lua`  
**Lines**: 275-284

```lua
-- Transition to IN_GROUP when invite is accepted
if newStatus == "inviteaccepted" then
    Debug:Dev("pughelper", "Invite accepted - transitioning to IN_GROUP state")

    -- CRITICAL FIX: Set primary invite if not already set
    -- This handles cases where status skips "invited" and goes straight to "inviteaccepted"
    if not self.primaryInvite and not self.activeInviteID then
        self:SetPrimaryInvite(appData)
        Debug:Dev("pughelper", "Primary invite set on inviteaccepted (missed invited status): " .. (appData.name or "Unknown"))
        self:OnMPlusAccepted(appData)
    end

    -- Only treat as our tracked PUG if it matches the primary invite
    if (self.activeInviteID and appID == self.activeInviteID) or not self.activeInviteID then
        if self.MarkGroupAsPUG then
            self:MarkGroupAsPUG()
        end
        self:TransitionToState(PUGHelper.STATE.IN_GROUP, "invite_accepted")
        self:ClearPrimaryInvite("inviteaccepted")
    else
        Debug:Dev("pughelper", "Inviteaccepted for non-primary application - ignoring for PUGHelper state")
    end
end
```

### Validation Tests
**Test Case 1: Normal Flow**
```lua
-- Status: pending -> invited -> inviteaccepted
-- Expected: Primary set on "invited", teleport driven once
```

**Test Case 2: Skipped "invited"**
```lua
-- Status: pending -> inviteaccepted
-- Expected: Primary set on "inviteaccepted", teleport driven once
-- This is the FIXED case!
```

**Test Case 3: Concurrent Invites**
```lua
-- App A: pending -> inviteaccepted (timestamp: 1000)
-- App B: pending -> invited (timestamp: 1001)
-- Expected: A becomes primary (first), B ignored
```

**Debug Commands**:
```lua
-- Monitor primary lock
/script print("Primary ID:", NextKey222.PUGHelper.activeInviteID)
/script print("Primary Name:", NextKey222.PUGHelper.primaryInvite and NextKey222.PUGHelper.primaryInvite.name)

-- Simulate rapid accepts
/nkpugtest  -- Use Test UI to simulate multiple quick accepts
```

---

## Fix 2: DungeonNameMatcher - Missing Season 3 Abbreviations

### Issue
**Location**: [`core/dungeonNameMatcher.lua:12-23`](../../core/dungeonNameMatcher.lua:12)

**Problem**: DungeonNameMatcher only contained abbreviation patterns for TWW Season 1 dungeons. Season 3 dungeons (Priory, Eco-Dome, Operation: Floodgate) had no matching patterns, causing fallback failures when ActivityToDungeonMap couldn't resolve the dungeon.

**Impact**:
- Teleport window showed generic "All Portals" instead of specific dungeon
- No targeted travel assistance for Season 3 content
- Poor user experience for PUG runs

### Root Cause Analysis
```lua
-- BEFORE: Only Season 1 patterns
local ABBREVIATION_PATTERNS = {
    ["ara"] = true, ["kara"] = true,
    ["city of threads"] = true, ["cot"] = true,
    ["stonevault"] = true, ["sv"] = true,
    ["dawnbreaker"] = true, ["db"] = true,  -- Only this one was Season 3!
    ["mists"] = true, ["nw"] = true,
    ["sob"] = true, ["gb"] = true,
}
```

**Group Names That Failed**:
- "Priory +10" → No match
- "PSF 10" → No match
- "Eco-Dome 12" → No match
- "Floodgate +11" → No match
- "OPF 10" → No match

### Fix Implementation
**File**: `core/dungeonNameMatcher.lua`  
**Lines**: 12-33

```lua
-- Common abbreviation patterns for TWW Season 3 dungeons
local ABBREVIATION_PATTERNS = {
    -- TWW Season 3 dungeons (PRIMARY)
    ["priory"] = true, ["psf"] = true, ["sacred flame"] = true, ["priory of the sacred flame"] = true,
    ["dawnbreaker"] = true, ["db"] = true, ["dawn"] = true, ["the dawnbreaker"] = true,
    ["eco"] = true, ["eco-dome"] = true, ["aldani"] = true, ["eco-dome aldani"] = true,
    ["taza"] = true, ["tazavesh"] = true, ["streets"] = true, ["tazavesh streets"] = true,
    ["ara"] = true, ["kara"] = true, ["ara-kara"] = true, ["city of echoes"] = true,
    ["gambit"] = true, ["tazavesh gambit"] = true, ["so'leah"] = true,
    ["flood"] = true, ["floodgate"] = true, ["opf"] = true, ["operation floodgate"] = true, ["operation: floodgate"] = true,
    ["halls"] = true, ["hoa"] = true, ["atonement"] = true, ["halls of atonement"] = true,
    
    -- Legacy Season 1 patterns (kept for potential future rotation)
    ["city of threads"] = true, ["cot"] = true, ["threads"] = true,
    ["stonevault"] = true, ["sv"] = true, ["vault"] = true,
    ["mists"] = true, ["tirna scithe"] = true, ["mists of tirna scithe"] = true,
    ["necrotic wake"] = true, ["nw"] = true, ["wake"] = true,
    ["siege of boralus"] = true, ["sob"] = true, ["boralus"] = true,
    ["grim batol"] = true, ["gb"] = true, ["batol"] = true,
}
```

### Validation Tests
**Test Matrix**:
| Group Name | Should Match | Expected Dungeon | Map ID |
|------------|--------------|------------------|--------|
| "Priory +10" | ✅ "priory" | Priory of the Sacred Flame | 499 |
| "PSF 12" | ✅ "psf" | Priory of the Sacred Flame | 499 |
| "Eco-Dome 10" | ✅ "eco-dome" | Eco-Dome Al'dani | 542 |
| "ECO 11" | ✅ "eco" | Eco-Dome Al'dani | 542 |
| "OPF +10" | ✅ "opf" | Operation: Floodgate | 525 |
| "Floodgate 12" | ✅ "floodgate" | Operation: Floodgate | 525 |
| "HOA +10" | ✅ "hoa" | Halls of Atonement | 378 |
| "Halls 10" | ✅ "halls" | Halls of Atonement | 378 |

**Debug Commands**:
```lua
-- Test abbreviation matching
/script print(NextKey222.DungeonNameMatcher:ParseGroupName("Priory +10"))  -- Should be 499
/script print(NextKey222.DungeonNameMatcher:ParseGroupName("PSF 12"))      -- Should be 499
/script print(NextKey222.DungeonNameMatcher:ParseGroupName("Eco-Dome 10")) -- Should be 542
/script print(NextKey222.DungeonNameMatcher:ParseGroupName("OPF +11"))     -- Should be 525

-- Test via PUG Helper Test UI
/nkpugtest
-- Select each dungeon, click "Simulate: Get Accepted to Group"
-- Verify teleport window shows correct specific dungeon
```

---

## Testing Protocol

### Automated Test Commands
```lua
-- 1. Enable debug logging
/nk config
-- Navigate to: Debug System → Enable Debugging → Enable "pughelper" category

-- 2. Clear state
/script NextKey222.PUGHelper:ResetState()

-- 3. Verify modules loaded
/script print("ActivityMap:", NextKey222.ActivityToDungeonMap ~= nil)
/script print("NameMatcher:", NextKey222.DungeonNameMatcher ~= nil)
/script print("PUGHelper:", NextKey222.PUGHelper ~= nil)

-- 4. Test primary lock fix
/script NextKey222.PUGHelper:OnApplicationStatusChanged(999, "inviteaccepted", "pending")
/script print("Primary ID:", NextKey222.PUGHelper.activeInviteID)  -- Should be "999"

-- 5. Test dungeon matching
/script print("Priory:", NextKey222.DungeonNameMatcher:ParseGroupName("Priory +10"))
/script print("Eco:", NextKey222.DungeonNameMatcher:ParseGroupName("Eco-Dome 11"))
/script print("OPF:", NextKey222.DungeonNameMatcher:ParseGroupName("OPF 12"))
```

### Manual Testing Steps
1. **Primary Lock Validation**:
   - Open LFG, apply to 3+ M+ groups
   - Accept first invite
   - Verify only one teleport window opens
   - Verify secondary invites are logged but ignored

2. **Dungeon Detection Validation**:
   - Use `/nkpugtest` UI
   - Test each Season 3 dungeon
   - Verify teleport window shows correct specific portal
   - Test with various abbreviations (PSF, ECO, OPF, HOA)

3. **End-to-End PUG Flow**:
   - Apply to M+ via LFG
   - Get accepted
   - Verify teleport window opens in PUG mode
   - Complete dungeon
   - Verify teleport window shows Leave Group option

---

## Regression Risks

### Low Risk
- ✅ Primary lock logic is additive (only sets if not already set)
- ✅ DungeonNameMatcher patterns are additive (legacy patterns preserved)
- ✅ No changes to core state machine

### Medium Risk
- ⚠️ Primary lock on "inviteaccepted" may cause unexpected behavior if other code assumes "invited" always fires first
- **Mitigation**: Added detailed debug logging; monitor for double-OnMPlusAccepted calls

### Monitoring Required
```lua
-- Watch for these debug messages:
-- "Primary invite set on inviteaccepted (missed invited status)"  -- This is the FIX
-- "Secondary invited application ignored (primary locked)"         -- Should still work
-- "Primary invite cleared"                                         -- Should happen on decline/leave
```

---

## Success Criteria

### Fix 1: Primary Invite Lock
- [ ] No double teleport window opens
- [ ] Primary lock set on FIRST accepted invite (regardless of status sequence)
- [ ] Secondary invites always ignored
- [ ] Debug logs confirm "missed invited status" when applicable

### Fix 2: Dungeon Name Matching
- [ ] All Season 3 dungeons match by full name
- [ ] All Season 3 common abbreviations match (PSF, ECO, OPF, HOA, DB, ARA)
- [ ] Teleport window shows specific dungeon portal (not "All Portals")
- [ ] Fallback to generic portals still works for unrecognized dungeons

---

## Next Steps

1. ✅ Implement fixes (DONE)
2. ⏳ Deploy to test environment
3. ⏳ Run automated test suite
4. ⏳ Perform manual validation per [PUG_MODE_VALIDATION_PLAN.md](PUG_MODE_VALIDATION_PLAN.md)
5. ⏳ Monitor live usage for 48 hours
6. ⏳ Address Priority 2 fixes if validation passes
7. ⏳ Update Memory Bank with final status

---

## Related Documentation
- [PUG_MODE_FIXES_2025-11-08.md](../FIXES/PUG_MODE_FIXES_2025-11-08.md) - AceGUI + auto-open fixes
- [PUG_MODE_VALIDATION_PLAN.md](PUG_MODE_VALIDATION_PLAN.md) - Comprehensive testing protocol
- [architecture.md](../../.kilocode/rules/memory-bank/architecture.md) - PUG Helper architecture
