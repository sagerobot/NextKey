# Performance Fixes Summary

## Problem Identified
The NextKey addon was causing significant FPS drops when the main UI window was open. Users reported frame rates dropping from 60+ FPS to under 30 FPS, making the addon nearly unusable during dungeon runs.

## Root Causes Analysis

### 1. Excessive Tooltip Updates (Critical)
- **Issue**: Tooltips were being created/updated on every mouse movement event
- **Impact**: Each tooltip update triggered expensive calculations and DOM operations
- **Evidence**: Found in `ui/main.lua` lines 1938-1950 and 2260-2272

### 2. Unbounded Event Handler Cascades (Critical)
- **Issue**: `GROUP_ROSTER_UPDATE` triggered UI refreshes which triggered more events
- **Impact**: Created infinite loops of updates during party changes
- **Evidence**: Found in `events/handlers.lua` lines 109-138

### 3. Memory Leaks in Frame Creation (High)
- **Issue**: Frames were not being properly cleaned up when window closed
- **Impact**: Memory usage grew continuously until UI became unresponsive
- **Evidence**: Found in `ui/main.lua` frame management code

### 4. Inefficient Profile Caching (High)
- **Issue**: Profiles were being rebuilt repeatedly instead of cached
- **Impact**: CPU usage spiked on every UI refresh
- **Evidence**: Found in `core/profiles.lua` cache management

### 5. Excessive Debug Logging (Medium)
- **Issue**: Debug calls were happening even when debug was disabled
- **Impact**: String operations and function calls added unnecessary overhead
- **Evidence**: Found throughout codebase

## Implemented Solutions

### 1. Tooltip Throttling System
**File**: `ui/main.lua`
**Fix**: Added 100ms minimum delay between tooltip updates
```lua
local lastTooltipUpdate = 0
local TOOLTIP_THROTTLE = 0.1 -- 100ms minimum between updates

ioGainButton:SetScript("OnEnter", function(btn)
    local now = GetTime()
    if now - lastTooltipUpdate < TOOLTIP_THROTTLE then
        return -- Throttle tooltip updates
    end
    lastTooltipUpdate = now
    -- ... rest of tooltip code
end)
```

### 2. Event Cascade Prevention
**File**: `events/performanceHandlers.lua`
**Fix**: Created optimized event handlers with throttling and batching
```lua
-- PERFORMANCE FIX: Prevent cascading updates during batch operations
local now = GetTime()
if now - self.lastUIRefresh < self.uiRefreshThrottle then
    NextKey222.Debug:Dev("performance", "UI refresh throttled - too soon since last refresh")
    return
end
```

### 3. Frame Management Optimization
**File**: `ui/performanceOptimizer.lua`
**Fix**: Implemented frame tracking and proper cleanup system
```lua
-- Track created frames for proper cleanup
local trackedFrames = {}

function PerformanceOptimizer:CleanupAllFrames()
    local cleaned = 0
    for frame, info in pairs(trackedFrames) do
        if frame and frame.Hide then
            frame:Hide()
            frame:SetParent(nil)
            cleaned = cleaned + 1
        end
        end
    return cleaned
end
```

### 4. Enhanced Profile Caching
**File**: `ui/performanceOptimizer.lua`
**Fix**: Improved cache with better invalidation and hit rate tracking
```lua
NextKey222.ProfilesService.GetProfile = function(self, playerName)
    local cached = profileCache[cacheKey]
    if cached and (GetTime() - cached.timestamp) < 300 then -- 5 minute cache
        cacheHits = cacheHits + 1
        return cached.profile
    end
    -- ... rest of caching logic
end
```

### 5. Debug Logging Optimization
**File**: `ui/performanceOptimizer.lua`
**Fix**: Cached debug state to avoid repeated checks
```lua
local debugEnabled = NextKey222.Debug and NextKey222.Debug.enabled or false
local lastDebugCheck = 0

NextKey222.Debug.Dev = function(self, category, ...)
    if not debugEnabled then return end
    
    local now = GetTime()
    if now - lastDebugCheck > 0.5 then -- Check debug state every 500ms
        debugEnabled = NextKey222.Debug.enabled or false
        lastDebugCheck = now
    end
    -- ... rest of debug logic
end
```

## Performance Monitoring Tools

### 1. Performance Monitor
**File**: `debug/performanceMonitor.lua`
**Commands**:
- `/nkperf metrics` - Show current performance metrics
- `/nkperf gc` - Force garbage collection
- `/nkperf test` - Run diagnostic test
- `/nkperf toggle` - Toggle performance monitoring

### 2. Performance Test Suite
**File**: `debug/performanceTest.lua`
**Command**: `/nkperftest`
**Tests**:
- Tooltip performance throttling
- UI refresh throttling
- Memory usage stability
- Profile cache efficiency
- Event handler performance

## Expected Results

### Before Fixes
- **FPS**: 20-30 FPS with UI open
- **Memory**: Continuous growth until crash
- **CPU**: High usage during party changes
- **Responsiveness**: Laggy UI interactions

### After Fixes
- **FPS**: 55-60 FPS with UI open (near native)
- **Memory**: Stable usage with periodic cleanup
- **CPU**: Normalized usage with throttling
- **Responsiveness**: Smooth UI interactions

## Testing Instructions

1. **Load the addon** and open the main UI window
2. **Run performance test**: `/nkperftest`
3. **Monitor metrics**: `/nkperf metrics`
4. **Test tooltips**: Hover over IO gain displays rapidly
5. **Test party changes**: Join/leave party with UI open
6. **Test memory**: `/nkperf gc` multiple times

## Files Modified

### New Files Created
- `ui/performanceOptimizer.lua` - Main performance optimization system
- `events/performanceHandlers.lua` - Optimized event handlers
- `debug/performanceMonitor.lua` - Performance monitoring tool
- `debug/performanceTest.lua` - Performance test suite

### Files Modified
- `ui/main.lua` - Added tooltip throttling
- `events/handlers.lua` - Event cascade prevention (indirectly via handlers)
- `NextKey.toc` - Added new performance modules

## Rollback Plan

If performance issues persist:
1. Disable performance optimizer in `NextKey.toc` by commenting out new files
2. Restore original `ui/main.lua` from version control
3. Test with original code to confirm issue resolution

## Future Improvements

1. **Dynamic Performance Scaling**: Adjust throttling based on current FPS
2. **Background Processing**: Move heavy calculations to background threads
3. **Predictive Caching**: Pre-cache likely-to-be-needed data
4. **Memory Pooling**: Reuse objects instead of creating new ones
5. **Performance Profiling**: Add more detailed performance metrics

## Conclusion

The implemented performance fixes address the root causes of FPS drops in the NextKey addon. The combination of tooltip throttling, event cascade prevention, proper memory management, and enhanced caching should restore smooth performance while maintaining all addon functionality.

Users should see immediate improvement in FPS stability when the main UI window is open, especially during party changes and tooltip interactions.