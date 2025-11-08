# PUG Mode Fixes - November 8, 2025

## Issues Fixed

### 1. AceGUI nil error when applying to groups

**Error**: `attempt to index field 'obj' (a nil value)` in AceGUI-3.0 during layout operations

**Root Cause**: The PUG Application Tracker was not properly using SafeRun() when manipulating AceGUI widgets, particularly when:
- Adding children to scroll frames
- Releasing children from containers
- Setting frame heights

**Fix Applied**:
- Wrapped all `AddChild()` calls in SafeRun() to prevent nil reference errors
- Wrapped `ReleaseChildren()` calls in SafeRun()
- Added nil checks before accessing frame properties
- Fixed content container parenting to use proper AceGUI hierarchy

**Files Modified**:
- `ui/pugApplicationTracker.lua` (lines 306-327, 484-498, 513-525)

### 2. Auto-open teleport window after M+ completion

**Issues**:
- No configuration option to disable auto-open
- No check if window was already showing
- Timing could cause conflicts

**Fix Applied**:
- Added configuration option `teleport.autoShowAfterCompletion` (defaults to `true`)
- Added check to prevent opening if window already shown
- Increased delay from 1.0s to 1.5s for better stability
- Added debug logging for configuration state

**Files Modified**:
- `events/handlers.lua` (lines 612-630)
- `core/config.lua` (line 126)
- `options/main.lua` (lines 1321-1334)

## Configuration

New setting available in `/nk config` → Teleport Settings:
- **Auto-Show After M+ Completion**: Toggle automatic teleport window display after dungeon completion (default: ON)

## Testing Checklist

### AceGUI Fix Testing
- [ ] Apply to multiple PUG groups in rapid succession
- [ ] Verify no AceGUI errors in `/console scriptErrors 1`
- [ ] Confirm application tracker displays correctly
- [ ] Test with `/nk test` fake players + PUG applications

### Auto-Open Testing
- [ ] Complete an M+ dungeon and verify teleport window opens automatically
- [ ] Disable setting and verify window does NOT auto-open
- [ ] Verify window doesn't re-open if already showing
- [ ] Test in both PUG and premade group contexts
- [ ] Verify delay timing feels natural (1.5s after completion)

## Debug Commands

```lua
-- Test PUG tracker (force show)
/script NextKey222.PUGApplicationTracker:Show()

-- Toggle auto-show setting
/script NextKey222.Addon.db.global.teleport.autoShowAfterCompletion = false

-- Check current setting
/script print("Auto-show:", NextKey222.Addon.db.global.teleport.autoShowAfterCompletion)

-- Simulate M+ completion
/script NextKey222.Events:OnChallengeModeCompleted(503, 10)

-- Check for AceGUI errors
/console scriptErrors 1
```

## Technical Notes

### SafeRun Pattern
All AceGUI widget manipulation now follows this pattern:
```lua
NextKey222.SafeRun(function()
    if widget and widget.Method then
        widget:Method(args)
    end
end, "Description for debugging")
```

### Auto-Show Logic
```lua
-- Only auto-shows if:
-- 1. Setting is not explicitly false (defaults to true)
-- 2. Window is not already showing
-- 3. 1.5 seconds have passed since completion
```

## Backwards Compatibility

- Existing users will have auto-show ENABLED by default
- Users can disable via `/nk config` → Teleport Settings
- Setting persists across sessions in SavedVariables

## Related Documentation

- Memory Bank: [context.md](../.kilocode/rules/memory-bank/context.md)
- Architecture: [architecture.md](../.kilocode/rules/memory-bank/architecture.md)
- PUG Mode Guide: [README/PUG_MODE.md](../../README/PUG_MODE.md)