# Memory Usage Investigation & Recommendations

## 1. Introduction

This document outlines an investigation into memory usage issues reported in the `/nk` and `/nk organizer` windows. The primary issue observed was a steady "creep" in memory consumption, particularly when the windows were left open, which did not decrease even after the windows were closed.

The initial code review reveals a very high standard of UI memory management. The addon correctly implements critical best practices, including:

- **Thorough Frame Cleanup:** The `OnClose` and `CleanupNativeFrames` functions are meticulously designed to hide, unparent, and nil out script handlers for UI objects. This prevents the most common and severe types of memory leaks in WoW addons.
- **Debounced Rendering:** The use of `C_Timer` to schedule and debounce UI updates is an excellent performance optimization that prevents unnecessary re-renders.
- **Centralized State Management:** Separating UI state from the UI elements themselves helps maintain a clean and predictable data flow.

The existing code shows a sophisticated understanding of WoW's UI lifecycle and memory challenges. The issues identified are not related to these well-implemented patterns but stem from more subtle, addon-wide systems that create unintended side effects.

## 2. Analysis of Likely Causes

The investigation points to the `ui/performanceOptimizer.lua` module as the primary source of the memory creep. This module, while well-intentioned, introduces two patterns that are known to cause issues with Lua's garbage collector (GC).

### Suspect #1: Periodic, Forced Garbage Collection

The most likely cause is the `C_Timer.NewTicker` that forces a full garbage collection cycle every 60 seconds:

```lua
-- In PerformanceOptimizer:Initialize()
C_Timer.NewTicker(60, function()
    self:ForceGarbageCollection()
end)

function PerformanceOptimizer:ForceGarbageCollection()
    collectgarbage("collect")
    -- ...
end
```

**Why this is a problem:**

Lua's garbage collector is a finely-tuned, generational incremental collector. It is designed to run its collection cycles in small, non-disruptive steps to avoid causing noticeable frame drops. By calling `collectgarbage("collect")`, we are forcing a full, blocking garbage collection cycle.

Frequent, forced GCs can paradoxically lead to **increased memory usage** because they interrupt the collector's natural rhythm. The Lua engine may hold onto memory longer than it otherwise would, waiting for an optimal time to release it, but the forced cycle disrupts this process. This results in the "creeping" memory behavior observed, where memory slowly accumulates and is never fully released.

### Suspect #2: `OnUpdate` Script for Performance Monitoring

The performance optimizer also creates a frame with an `OnUpdate` script that runs on every single frame the game renders:

```lua
-- In PerformanceOptimizer:StartPerformanceMonitoring()
self.monitoringFrame = CreateFrame("Frame")
self.monitoringFrame:SetScript("OnUpdate", function()
    self:MonitorFramePerformance()
end)
```

The `MonitorFramePerformance` function performs calculations and, most importantly, inserts data into a table (`self.metrics.frameTimeHistory`).

**Why this is a problem:**

While the individual allocations are tiny, they occur on **every frame**. This is known as "memory churn." Even if the `frameTimeHistory` table is pruned, the constant creation of new table entries and other temporary variables can create significant pressure on the garbage collector. When combined with the forced GC from Suspect #1, this churn can easily contribute to the memory creep, as the GC is never given a chance to properly clean up the rapid, small allocations.

## 3. Recommendations

The addon's high-quality UI cleanup code should be trusted to do its job. The focus should be on removing the systems that interfere with Lua's natural memory management.

### Recommendation #1: Remove Forced Garbage Collection

The single most impactful change is to remove the periodic garbage collection timer. Lua's GC is highly efficient and should be allowed to run on its own schedule.

**Action:**
In `ui/performanceOptimizer.lua`, remove or comment out the following lines in the `Initialize` function:

```lua
-- In PerformanceOptimizer:Initialize()

-- C_Timer.NewTicker(60, function()
--     self:ForceGarbageCollection()
-- end)
```

This will stop the addon from interfering with the garbage collector and should eliminate the primary cause of the memory creep.

### Recommendation #2: Replace `OnUpdate` with a Timer-Based Monitor

The performance monitor is a useful debugging tool, but it doesn't need to run on every frame. It can be converted to a timer-based system that samples performance periodically, which is much more memory-friendly.

**Action:**
Replace the `OnUpdate` script with a `C_Timer.NewTicker` that runs every second or so.

**Current Implementation:**
```lua
-- In PerformanceOptimizer:StartPerformanceMonitoring()
self.monitoringFrame = CreateFrame("Frame")
self.monitoringFrame:SetScript("OnUpdate", function()
    self:MonitorFramePerformance()
end)
```

**Recommended Implementation:**
```lua
-- In PerformanceOptimizer:StartPerformanceMonitoring()
if self.monitoringTimer then
    self.monitoringTimer:Cancel()
end

-- Sample performance every 1 second
self.monitoringTimer = C_Timer.NewTicker(1, function()
    self:MonitorFramePerformance()
end)
```

This change will dramatically reduce memory churn by sampling performance data at a much lower frequency, giving the garbage collector ample time to clean up between samples.

## 4. Conclusion

The memory issues are not a result of flawed UI construction or cleanup, but rather the unintended consequences of an overly aggressive performance optimization module. By removing the forced garbage collection and converting the performance monitor to a timer-based system, the memory creep should be resolved, allowing the addon's otherwise excellent memory management to function as intended.
