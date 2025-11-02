# Tooltip Bug Report - M+ Group Organizer

## The Bug

**Problem**: Role icon tooltips are NOT displaying spec-level details (e.g., "Havoc: Want to Play"). Instead, they show only the role name (e.g., "DAMAGER") with no additional information.

**Expected Behavior**: 
- Before poll: Show current spec as green "Want to Play" (e.g., "Havoc: Want to Play")
- After poll: Show spec-level preferences from poll responses
- Never show generic fallback text like "Want to Play" without spec name

**Actual Behavior**:
- Before poll: Shows only role name (e.g., "DAMAGER"), no spec details
- After poll: Works correctly for real player, fails for fake players
- `playerData.specDetails` is empty/undefined for all players before poll

---

## Root Cause Analysis

The bug exists in the **data generation pipeline**, NOT the tooltip rendering code.

### Data Flow
```
rosterBoard.lua:GetBenchPlayers()
  → Calls GenerateDefaultSpecPreferences(playerName)
  → Should return (success, specPreferences, specDetails)
  → Sets playerData.specPreferences and playerData.specDetails

playerCard.lua:CreateCompactContent()/CreateExpandedContent()
  → Reads playerData.specDetails
  → Renders tooltip with spec-level breakdown
```

### The Critical Bug
**File**: `ui/organizer/rosterBoard.lua` (lines 413, 475)

**What was wrong**: Not capturing the `success` flag from `SafeRun()` wrapper:
```lua
-- WRONG (before fix)
local specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(fakeData.name)
```

Since `GenerateDefaultSpecPreferences` is wrapped in `SafeRun()`, it returns:
```lua
return (success, result1, result2, ...)
```

This meant:
- `specPrefs` was capturing the **success boolean** (true/false)
- `specDetails` was capturing the **actual specPrefs table**
- The **real specDetails** was never captured

**Result**: `playerData.specDetails` was always `nil`, causing tooltips to show only role names.

---

## Attempted Fixes

### Fix #1: SafeRun Return Value Capture (LATEST)
**File**: `ui/organizer/rosterBoard.lua` (lines 413-427, 475-489)

**Change**:
```lua
-- CORRECT (after fix)
local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(fakeData.name)

if success and specPrefs then
    playerData.specPreferences = specPrefs
    playerData.specDetails = specDetails
else
    Debug:Error("Failed to generate default spec preferences")
end
```

**Status**: Applied to both fake players (line 413) and real players (line 475)

### Fix #2: Remove Fallback Tooltips (LATEST)
**File**: `ui/organizer/playerCard.lua` (lines 248-294, 504-550)

**Change**: Removed the `else` clause that showed generic "Want to Play"/"Will Fill" text without spec names.

**Before**:
```lua
if playerData.specDetails and playerData.specDetails[normalizedRole] then
    -- Show spec details
else
    -- FALLBACK: "Want to Play" or "Will Fill"
    GameTooltip:AddLine("Want to Play", 0.2, 0.9, 0.2)
end
```

**After**:
```lua
if playerData.specDetails and playerData.specDetails[normalizedRole] then
    -- Show spec details
end
-- NO FALLBACK - If specDetails doesn't exist, just show the role name
```

### Previous Fix Attempts (Historical)
1. **Case sensitivity normalization** - Fixed role key lookups to use uppercase (`TANK`, `HEALER`, `DAMAGER`)
2. **Enhanced debug logging** - Added comprehensive logging to `playerDataBuilder.lua`
3. **Fake player spec data** - Ensured fake players have full `specializations` array
4. **Poll response handling** - Fixed `surveyDialog.lua` and `pollSimulator.lua` case sensitivity

---

## Current Status

**Last Fix Applied**: SafeRun return value capture + fallback removal

**Still Not Working**: Tooltips still showing only role names (no spec details)

**Likely Issue**: Either:
1. `GenerateDefaultSpecPreferences()` is failing silently (returning `success=false`)
2. `GenerateDefaultSpecPreferences()` is returning empty `specDetails` even when successful
3. WoW API calls inside `GenerateDefaultSpecPreferences()` are failing for fake players
4. Data is being lost/overwritten somewhere between generation and tooltip rendering

---

## Next Steps for Investigation

1. **Enable debug logging** in-game: `/nk config` → Debug System → Enable "organizer_ui" category at DEV level
2. **Test tooltip hover** and check debug output for:
   - "Generated default spec preferences" messages
   - "specDetails keys:" output (should NOT be empty)
   - Any error messages from `GenerateDefaultSpecPreferences`
3. **Check if `GenerateDefaultSpecPreferences()` is even being called** - add print statements if needed
4. **Verify WoW API availability** - `GetSpecializationInfoForClassID()` may not work for fake players

---

## Files Modified

1. `ui/organizer/rosterBoard.lua` - Lines 413-427, 475-489 (SafeRun fix)
2. `ui/organizer/playerCard.lua` - Lines 248-294, 504-550 (fallback removal)
3. `core/organizer/playerDataBuilder.lua` - Enhanced debug logging
4. `ui/organizer/surveyDialog.lua` - Case normalization
5. `debug/pollSimulator.lua` - Case normalization

---

## Key Code References

- **Tooltip rendering**: `ui/organizer/playerCard.lua:248` (compact), `ui/organizer/playerCard.lua:504` (expanded)
- **Data generation**: `ui/organizer/rosterBoard.lua:413` (fake players), `ui/organizer/rosterBoard.lua:475` (real players)
- **Spec preference generator**: `core/organizer/playerDataBuilder.lua:28` (`GenerateDefaultSpecPreferences()`)
- **Poll response handler**: `ui/organizer/surveyDialog.lua:772` (works correctly after poll)