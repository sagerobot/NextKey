# Memory Leak Fix - Implementation Plan
**Date**: November 9, 2025  
**Issue**: Memory creep in `/nk` and `/nk organizer` windows  
**Root Cause**: Forced garbage collection disrupting Lua's natural GC rhythm  
**Status**: Ready for Implementation

## Executive Summary

The memory leak investigation ([`memory_leak_investigation.md`](memory_leak_investigation.md)) correctly identified that **forced garbage collection** in the performance optimization modules is causing memory to accumulate rather than be freed. The solution is to **remove these problematic modules** and trust WoW's built-in memory management and your existing excellent UI cleanup code.

## Problem Analysis

### Files Causing Issues

1. **`ui/performanceOptimizer.lua`** (322 lines) - **PRIMARY CULPRIT**
   - Line 314-316: Forces full GC every 60 seconds
   - Line 210-213: OnUpdate script runs every frame (memory churn)
   - Hooks global WoW functions (GameTooltip, CreateFrame)
   - Duplicates existing ProfilesService caching
   - "Optimizations" that actually degrade performance

2. **`events/performanceHandlers.lua`** (203 lines) - **SECONDARY ISSUE**
   - Line 162-177: Also forces GC (throttled to 5 seconds)
   - Line 17-94: Group roster throttling (actually useful!)
   - Unnecessary event handler replacement

3. **`core/performance.lua`** (embedded in `boot.lua` lines 115-162) - **KEEP THIS**
   - Simple, lightweight profiler
   - No forced GC, no hooks
   - Optional and harmless

## Why This is Happening

From the investigation document:

> Lua's garbage collector is a finely-tuned, generational incremental collector. By calling `collectgarbage("collect")`, we are forcing a full, blocking garbage collection cycle. Frequent, forced GCs can paradoxically lead to **increased memory usage** because they interrupt the collector's natural rhythm.

Your addon already has:
✅ Excellent UI cleanup (`OnClose`, `CleanupNativeFrames`)  
✅ Debounced rendering with `C_Timer`  
✅ Centralized state management  
✅ Professional architecture

The performance modules are **fighting against** these good patterns, not enhancing them.

## Recommended Solution

### Delete Both Performance Optimization Modules

**Why this is the right approach:**
- Fixes the memory leak immediately
- Removes ~500 lines of complex, fragile code
- Eliminates risky global function hooking
- Trusts WoW's highly-optimized built-in systems
- Aligns with your addon philosophy: simple, performant, user-focused

**What you lose:**
- Nothing! The "optimizations" were making things worse

**What you gain:**
- Fixed memory leak
- Simpler, more maintainable codebase
- Better performance (no every-frame monitoring)
- Safer code (no global hooks)

## Implementation Steps

### Step 1: Delete `ui/performanceOptimizer.lua`
```
Action: Delete file
Reason: Primary source of memory leak
Impact: Removes forced GC and OnUpdate frame monitoring
```

### Step 2: Delete `events/performanceHandlers.lua`
```
Action: Delete file
Reason: Contains forced GC and unnecessary complexity
Impact: Removes secondary GC issue
Note: Roster throttling can be re-added later if truly needed (it's not)
```

### Step 3: Update `NextKey.toc`
Remove lines 51-52:
```diff
- ui\performanceOptimizer.lua
- events\performanceHandlers.lua
```

### Step 4: Update `boot.lua`
Remove lines 381-391 (Performance Optimization initialization):
```diff
-     -- Phase 7: Initialize Performance Optimization System (must be before UI)
-     if NextKey222.Performance then
-         if NextKey222.Performance.Initialize then
-             NextKey222.Debug:Dev("startup", "Initializing Performance Optimization System")
-             NextKey.SafeRun(function() NextKey222.Performance:Initialize() end, "Initialize Performance Optimization System")
-         else
-             NextKey222.Debug:Error("Performance Optimization System missing Initialize function")
-         end
-     else
-         NextKey222.Debug:Dev("startup", "Performance Optimization System not available - Phase 7 features disabled")
-     end
```

Note: Keep `NextKey222.Performance` in boot.lua (lines 115-162) - it's just a simple profiler.

### Step 5: Testing
After changes:
1. `/reload` in-game
2. Open `/nk` window
3. Leave it open for 5+ minutes
4. Monitor memory with `/nk debug memory` or similar
5. Close window
6. Verify memory decreases within 30-60 seconds

Expected result: Memory stays stable or decreases naturally, no more creep.

## Alternative Approaches Considered

### Option A: Fix instead of delete
- Remove forced GC only
- Convert OnUpdate to timer-based
- Keep other optimizations

**Rejected because:**
- Still leaves complex hooking code
- Optimizations don't actually help
- More code to maintain

### Option B: Keep roster throttling
- Extract just the roster throttling to `events/rosterThrottling.lua`
- Delete everything else

**Rejected because:**
- Roster updates are already event-driven and efficient
- Throttling adds complexity without measurable benefit
- Can be re-added later if profiling shows it's needed

### Option C: Disable GC only
- Comment out GC calls but keep modules

**Rejected because:**
- Leaves dead code in the codebase
- OnUpdate monitoring still causes memory churn
- Half-measures don't align with "simple and performant" philosophy

## Why Complete Removal is Best

Your addon already follows industry best practices:
- Details! Damage Meter architecture patterns
- Proper frame lifecycle management
- SafeRun error handling
- Centralized debug system

The performance modules were added with good intentions but are actively harmful. Removing them:
1. Fixes the reported memory leak
2. Improves actual performance (no every-frame code)
3. Reduces complexity and maintenance burden
4. Eliminates fragile global function hooks
5. Trusts WoW's proven, battle-tested systems

## Success Criteria

After implementation:
- ✅ No memory creep when windows left open
- ✅ Memory decreases after window closure
- ✅ No FPS impact (should be same or better)
- ✅ All features work normally
- ✅ Cleaner, simpler codebase

## Rollback Plan

If issues arise (unlikely):
1. Restore deleted files from git history
2. Restore TOC entries
3. Restore boot.lua initialization
4. Investigate specific symptoms

## Documentation Updates

After implementation, update:
- CHANGELOG.md - Document the fix
- Memory Bank files if present
- Any developer docs referencing performance modules

## Next Steps

Ready to proceed! Switch to code mode to implement these changes.

---

**Note**: This plan is based on the thorough analysis in [`memory_leak_investigation.md`](memory_leak_investigation.md) and aligns with your addon's core philosophy of simplicity and performance.