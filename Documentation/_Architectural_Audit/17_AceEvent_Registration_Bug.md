# AceEvent Registration Bug - UI Main Profile Updates

**Date**: November 18, 2025
**Status**: **CRITICAL - REQUIRES MANUAL INVESTIGATION** 🚨
**Severity**: HIGH - Role icons do not update on spec changes in main UI
**Impact**: User experience degradation (role icons show stale data until window reopened)

## Bug Summary

The UI Main module's event listener for `NEXTKEY_PROFILE_UPDATED` appears to register successfully, but the callback **NEVER fires** when ProfilesService sends the event. Multiple diagnostic attempts have failed to identify the root cause.

## Root Cause Analysis - Multiple Failed Fixes

### ❌ FIXES ATTEMPTED (ALL FAILED)

1. **SafeRun Wrapper** - Wrapped event registration in `NextKey222.SafeRun()`
   - **Result**: No improvement - callback still doesn't fire

2. **Named Function Callback** - Changed from anonymous to named function
   - **Result**: No improvement - callback still doesn't fire

3. **Direct Registration in Initialize** - Moved registration directly into `UI:Initialize()`
   - **Result**: No improvement - callback still doesn't fire

4. **Organizer Pattern Match** - Copied EXACT registration pattern from working RosterBoard
   - **Result**: No improvement - callback still doesn't fire

5. **Module Structure Match** - Converted UI module to match RosterBoard table structure
   - **Result**: No improvement - callback still doesn't fire

6. **Local Debug Reference** - Added local Debug variable like RosterBoard
   - **Result**: No improvement - callback still doesn't fire

7. **Test Messages** - Added diagnostic test messages to verify AceEvent connectivity
   - **Result**: Test callbacks never fired either, suggesting broader AceEvent issue

8. **Explicit UI Reference** - Used stored UI instance reference to avoid self issues
   - **Result**: No improvement - callback still doesn't fire

9. **Restored Original Structure** - Reverted to original UI module table definition
   - **Result**: TBD - awaiting user testing

## Critical Evidence

### ✅ Registration APPEARS Successful
```
[NextKey DEV] [ui] Successfully registered NEXTKEY_PROFILE_UPDATED listener
```

### ❌ Callback NEVER Fires
**Expected but NEVER seen:**
```
[NextKey DEV] [ui] PROFILE UPDATE CALLBACK FIRED!
```

### ✅ Event IS Being Sent
```
[NextKey DEV] [profiles] Announced NEXTKEY_PROFILE_UPDATED event for PLAYER_SPECIALIZATION_CHANGED
```

## The Mystery

**Registration works** → We see success messages  
**Event sending works** → ProfilesService sends the event  
**Callback definition exists** → Code is present in UI:Initialize()  
**But callback NEVER fires** → Zero execution when event sent

This suggests a **fundamental disconnect** between registration and callback execution.

## Working vs Broken Comparison

### ✅ WORKING: RosterBoard Pattern
```lua
function RosterBoard:Initialize()
    return NextKey222.SafeRun(function()
        -- Registration happens here with full context
        NextKey222.Addon:RegisterMessage("NEXTKEY_PROFILE_UPDATED", function(event, payload)
            self:OnProfileUpdated(payload)  -- ✅ WORKS
        end)
    end, "RosterBoard:Initialize")
end
```

### ❓ CURRENT: UI Pattern (ui/main.lua:388-430)
```lua
function UI:Initialize()
    return NextKey222.SafeRun(function()
        -- Exact same pattern as RosterBoard
        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            NextKey222.Addon:RegisterMessage("NEXTKEY_PROFILE_UPDATED", function(event, payload)
                Debug:Dev("ui", "PROFILE UPDATE CALLBACK FIRED!")
                self:OnProfileUpdated(payload)  -- ❌ NEVER FIRES
            end)
        end
    end, "UI:Initialize")
end
```

## Manual Investigation Required

### 🔍 Critical Questions

1. **Is the UI module actually loading?**
   ```lua
   -- Check if UI module exists
   /script print("UI module exists:", NextKey222.UI ~= nil)
   /script print("UI Initialize exists:", NextKey222.UI.Initialize ~= nil)
   ```

2. **Are ANY AceEvent messages working from UI module?**
   ```lua
   -- Test immediate message send during initialization
   /script NextKey222.Addon:RegisterMessage("IMMEDIATE_TEST", function(event, payload) 
       print("IMMEDIATE CALLBACK:", event, payload) 
   end)
   /script NextKey222.Addon:SendMessage("IMMEDIATE_TEST", "immediate_test")
   ```

3. **Is there a Lua error during callback execution?**
   ```lua
   -- Check for script errors during spec change
   /console scriptErrors 1
   /spec ChangeYourSpec
   -- Look for any red error popups
   ```

4. **Does the Organizer still work for comparison?**
   ```lua
   -- Open organizer window and test spec change there
   /nk organizer
   /spec ChangeYourSpec
   -- Verify organizer role icon updates correctly
   ```

5. **Is there a difference in AceEvent internals?**
   ```lua
   -- Compare Addon object between UI and Organizer contexts
   /script print("Addon type:", type(NextKey222.Addon))
   /script print("Addon.RegisterMessage:", NextKey222.Addon.RegisterMessage)
   /script print("Addon.SendMessage:", NextKey222.Addon.SendMessage)
   ```

### 🔧 Manual Diagnostic Steps

1. **Test Registration Function Directly**
   ```lua
   -- Manually call the registration function
   /script NextKey222.UI:RegisterProfileEventListeners()
   ```

2. **Test Event Sending Directly**
   ```lua
   -- Manually trigger the profile update event
   /script NextKey222.Addon:SendMessage("NEXTKEY_PROFILE_UPDATED", {triggerEvent="MANUAL_TEST", playerName="Test-Player"})
   ```

3. **Test Simple Callback Pattern**
   ```lua
   -- Try simplest possible registration
   /script NextKey222.Addon:RegisterMessage("SIMPLE_TEST", function() print("SIMPLE WORKS") end)
   /script NextKey222.Addon:SendMessage("SIMPLE_TEST")
   ```

## Current State

**Latest Attempt**: Restored original UI module structure with SafeRun wrapper in Initialize function (attempt #9)

**Next Action**: User must test this version and report results

**If This Fails**: The issue may be beyond code fixes and require deeper investigation of:
- AceEvent library initialization timing
- Module loading dependencies
- Lua environment state during registration

## Workaround

**Current user impact**: Role icons show stale data until window is closed and reopened.

**Manual workaround**:
1. Change spec
2. Close NextKey window
3. Reopen NextKey window (`/nk`)
4. Role icon now shows correct role

**Why it works**: Window recreation triggers fresh profile lookup via `GetPlayerProfileCached()`, which bypasses the broken event system.

## Files Involved

- **`ui/main.lua`** (lines 388-430) - Registration code (attempt #9: restored original structure)
- **`ui/organizer/rosterBoard.lua`** (lines 47-100) - WORKING reference implementation
- **`core/profiles.lua`** (lines 315-339) - Event sender
- **`boot.lua`** (lines 404-409) - Initialization sequence

---

**Investigation Status**: 🚨 **CRITICAL - MANUAL INVESTIGATION REQUIRED**
**Pattern**: All code-level fixes failed, suggesting deeper architectural issue
**Next Step**: User manual testing + AceEvent system diagnostics