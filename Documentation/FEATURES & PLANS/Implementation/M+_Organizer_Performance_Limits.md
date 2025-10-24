# M+ Group Organizer - Performance Limits & Optimization

**Version:** 1.0  
**Status:** Reference Document  
**Priority:** CRITICAL - Must be enforced

---

## Overview

This document defines hard performance limits, optimization targets, and scale constraints for the Organizer feature. These limits must be enforced to prevent "script ran too long" errors and ensure smooth gameplay.

---

## 1. Hard Limits (Non-Negotiable)

### 1.1 Player Pool Size

**Maximum Supported Players:** 40  
**Recommended Maximum:** 30  
**Optimal Range:** 10-20  

**Enforcement:**
```lua
function RosterBoard:ValidatePlayerPoolSize(players)
    if #players > 40 then
        Debug:User("Player pool exceeds maximum (40). Please reduce raid size.")
        return false
    end
    
    if #players > 30 then
        Debug:User("Warning: Large player pool detected. Performance may vary.")
    end
    
    return true
end
```

### 1.2 Optimizer Execution Time

**Maximum Per-Batch:** 100ms  
**Total Timeout:** 2 minutes  
**Yield Frequency:** Every 50ms  

**Enforcement:**
```lua
function OptimizerWizard:ExecuteBatch()
    local startTime = debugprofilestop()
    local iterationsThisBatch = 0
    
    while iterationsThisBatch < 100 do
        -- Do work
        iterationsThisBatch = iterationsThisBatch + 1
        
        -- Check time
        if debugprofilestop() - startTime > 100 then
            -- Yield
            return "CONTINUE"
        end
    end
    
    return "COMPLETE"
end
```

### 1.3 Memory Constraints

**Baseline:** < 10MB  
**Peak (Active Session):** < 100MB  
**Per-Player Overhead:** ~2KB  

**Monitoring:**
```lua
function RosterBoard:MonitorMemoryUsage()
    UpdateAddOnMemoryUsage()
    local memory = GetAddOnMemoryUsage("NextKey")
    
    if memory > 100000 then -- 100MB
        Debug:Error("Memory limit exceeded:", memory, "KB")
        self:TriggerMemoryCleanup()
    end
end
```

### 1.4 Network Bandwidth

**Message Size Limit:** 4KB per message  
**Batch Interval:** 500ms  
**Max Messages/Second:** 10  

---

## 2. Performance Targets

### 2.1 UI Responsiveness

| Action | Target | Maximum |
|--------|--------|---------|
| Open Roster Board | <200ms | 500ms |
| Poll Group | <100ms | 200ms |
| Drag Card | <16ms | 33ms |
| Optimizer (Mode 2) | <5s | 15s |
| Optimizer (Mode 1, 10 players) | <30s | 60s |
| Announce Groups | <100ms | 200ms |

### 2.2 Synchronization Latency

| Operation | Target | Maximum |
|-----------|--------|---------|
| Card Move Sync | <500ms | 1s |
| Keystone Designation Sync | <500ms | 1s |
| Full State Sync | <1s | 3s |
| Poll Response Sync | <200ms | 500ms |

### 2.3 Frame Rate Impact

**Target:** 0% impact during normal use  
**Maximum:** 5% impact during optimizer execution  
**Combat:** ZERO impact (optimizer disabled in combat)

---

## 3. Scale Analysis by Player Count

### 3.1 Complexity Matrix

| Players | Combinations (Mode 1) | Memory | Time (Mode 1) | Time (Mode 2) |
|---------|----------------------|--------|---------------|---------------|
| 10 | ~252 | 20KB | 5s | 1s |
| 15 | ~3,003 | 30KB | 30s | 2s |
| 20 | ~15,504 | 40KB | 2min | 3s |
| 25 | ~53,130 | 50KB | >5min | 5s |
| 30 | ~142,506 | 60KB | >10min | 7s |

**Formula:** C(n, 5) = n! / (5! × (n-5)!)

### 3.2 Recommended Limits per Mode

**Mode 1 (Max Power):**
- Optimal: ≤ 15 players
- Maximum: 20 players
- Beyond 20: Use Mode 2 instead

**Mode 2 (Balanced):**
- Optimal: ≤ 30 players
- Maximum: 40 players
- Scales linearly

**Mode 3 (Vault):**
- Optimal: ≤ 20 players
- Maximum: 30 players
- Similar to Mode 1

---

## 4. Optimization Strategies

### 4.1 Combinatorial Pruning

**Strategy:** Early rejection of invalid combinations

```lua
function OptimizerMode1:GenerateCombinationsWithPruning(playerPool, constraints)
    -- Pre-filter by role
    local tanks = self:FilterByRole(playerPool, "Tank")
    if #tanks == 0 then
        return {} -- Cannot form any groups
    end
    
    -- Pre-filter by utility
    if constraints.RequireLust then
        local lustPlayers = self:FilterByUtility(playerPool, "Lust")
        if #lustPlayers == 0 then
            return {} -- Cannot meet constraints
        end
    end
    
    -- Now generate combinations from pre-filtered pool
    return self:GenerateCombinations(playerPool, constraints)
end
```

**Impact:** 30-50% reduction in combinations to check

### 4.2 Memoization

**Strategy:** Cache Gain() calculations

```lua
-- Already implemented in Phase 0.5
IOCalculator:CalculatePlayerGainCached(player, keystone)
```

**Impact:** 10x speedup for Mode 1

### 4.3 Parallel Keystone Evaluation

**Strategy:** Process multiple keystones per batch

```lua
function OptimizerMode1:FindBestGroupBatched(playerPool, keystones, batchSize)
    local startIdx = self.state.currentKeystoneIndex or 1
    local endIdx = math.min(startIdx + batchSize - 1, #keystones)
    
    for i = startIdx, endIdx do
        self:EvaluateKeystone(keystones[i], playerPool)
    end
    
    if endIdx < #keystones then
        self.state.currentKeystoneIndex = endIdx + 1
        return "CONTINUE"
    else
        return "COMPLETE"
    end
end
```

**Impact:** Enables yielding, prevents timeout

### 4.4 Component Pooling

**Strategy:** Reuse player card widgets

```lua
-- Already implemented in Phase 1
PlayerCard:AcquireCard() / :ReleaseCard()
```

**Impact:** 50% reduction in garbage collection

### 4.5 Lazy Rendering

**Strategy:** Staggered card rendering

```lua
-- Already implemented in Phase 1
RosterBoard:PopulateBenchStaggered(players, batchSize=5)
```

**Impact:** 70% reduction in initial load lag

---

## 5. Performance Monitoring

### 5.1 Instrumentation Points

```lua
local PROFILE_POINTS = {
    "RosterBoard:Initialize",
    "RosterBoard:PollGroup",
    "OptimizerMode1:FindBestGroup",
    "OptimizerMode2:ExecuteDraft",
    "OptimizerMode3:FindHappiestGroup",
    "RosterBoard:ApplyOptimizerResults",
    "PlayerCard:Create",
    "DragManager:ProcessDrop"
}

for _, point in ipairs(PROFILE_POINTS) do
    NextKey222.Performance:StartProfile(point)
    -- ... code ...
    NextKey222.Performance:StopProfile(point)
end
```

### 5.2 Performance Dashboard

**File:** `ui/organizer/performanceDashboard.lua` (NEW - Optional)

```lua
function PerformanceDashboard:Show()
    -- Display real-time metrics:
    -- - Current FPS
    -- - Memory usage
    -- - Active card count
    -- - Sync message queue size
    -- - Optimizer progress
end
```

### 5.3 Automated Performance Tests

**File:** `debug/organizer_performance_tests.lua` (NEW)

```lua
function TestOptimizerPerformance()
    local scenarios = {
        {players = 10, mode = "mode1", target = 5000},
        {players = 15, mode = "mode1", target = 30000},
        {players = 20, mode = "mode2", target = 3000},
        {players = 30, mode = "mode2", target = 7000}
    }
    
    for _, scenario in ipairs(scenarios) do
        local startTime = debugprofilestop()
        
        -- Run optimizer
        local groups = RunOptimizer(scenario.players, scenario.mode)
        
        local elapsed = debugprofilestop() - startTime
        
        assert(elapsed < scenario.target, 
            string.format("Performance regression: %dms > %dms", elapsed, scenario.target))
    end
end
```

---

## 6. Degraded Mode Operations

### 6.1 Low-End Hardware Mode

**Triggers:**
- FPS < 20
- Memory > 80MB
- CPU usage > 80%

**Adjustments:**
```lua
function RosterBoard:EnableLowPerformanceMode()
    -- Disable animations
    self.animationsEnabled = false
    
    -- Reduce sync frequency
    self.syncInterval = 1000 -- 1 second
    
    -- Disable participant view updates
    self.broadcastUpdates = false
    
    -- Simplify card rendering
    PlayerCard.detailedMode = false
    
    Debug:User("Performance mode enabled due to low FPS")
end
```

### 6.2 High Latency Mode

**Triggers:**
- Latency > 500ms

**Adjustments:**
```lua
function RosterBoard:EnableHighLatencyMode()
    -- Increase batch interval
    self.syncInterval = 1500
    
    -- Disable real-time sync
    self.realtimeSync = false
    
    -- Manual sync button
    self:ShowManualSyncButton()
    
    Debug:User("High latency detected, real-time sync disabled")
end
```

---

## 7. Combat Restrictions

### 7.1 Combat Detection

```lua
function RosterBoard:OnEnterCombat()
    -- Disable all organizer operations
    self:DisableAllControls()
    
    -- Pause optimizer if running
    if self.optimizerWizard and self.optimizerWizard:IsActive() then
        self.optimizerWizard:Pause()
    end
    
    -- Queue updates instead of executing
    self.combatMode = true
end

function RosterBoard:OnLeaveCombat()
    -- Re-enable controls
    self:EnableAllControls()
    
    -- Process queued updates
    self:ProcessQueuedUpdates()
    
    self.combatMode = false
end
```

---

## 8. Implementation Checklist

- [ ] Add player pool size validation
- [ ] Implement optimizer timeout system
- [ ] Add memory monitoring
- [ ] Enforce network bandwidth limits
- [ ] Build performance profiling
- [ ] Add FPS monitoring
- [ ] Implement combinatorial pruning
- [ ] Optimize memoization
- [ ] Add batch processing for Mode 1
- [ ] Build performance dashboard (optional)
- [ ] Create automated performance tests
- [ ] Implement low-performance mode
- [ ] Add high-latency mode
- [ ] Implement combat restrictions
- [ ] Document all performance limits
- [ ] Test at scale (10, 20, 30, 40 players)

---

## 9. Performance Testing Protocol

### 9.1 Regression Test Suite

**Run before every release:**

```lua
function RunPerformanceRegressionTests()
    TestRosterBoardInitialization() -- < 200ms
    TestPollGroup() -- < 100ms
    TestDragDrop() -- < 16ms per operation
    TestOptimizerMode1(10) -- < 5s
    TestOptimizerMode1(15) -- < 30s
    TestOptimizerMode2(20) -- < 3s
    TestOptimizerMode2(30) -- < 7s
    TestMemoryUsage() -- < 100MB peak
    TestSyncLatency() -- < 500ms
end
```

### 9.2 Stress Test Suite

**Run monthly:**

```lua
function RunStressTests()
    Test40Players() -- Maximum scale
    TestRapidOperations() -- 100 drags in 10s
    TestHighLatency() -- Simulate 500ms lag
    TestLowFPS() -- Simulate 15 FPS
    TestMemoryPressure() -- Other addons consuming memory
end
```

---

## 10. Scaling Recommendations

### 10.1 For Users

**Recommended Group Sizes:**
- **10-15 players:** All modes work well
- **16-20 players:** Use Mode 2 (Balanced) or Mode 3 (Vault)
- **21-30 players:** Use Mode 2 only
- **31-40 players:** Manual mode recommended

**Performance Tips:**
- Close other addons during organization
- Use Mode 2 for large groups
- Disable real-time sync if laggy
- Consider splitting into multiple raids

### 10.2 For Developers

**Before Adding Features:**
- Profile impact with 20+ players
- Test with 10 FPS environment
- Verify < 100ms UI response time
- Ensure no memory leaks

---

## 11. Future Optimization Opportunities

### 11.1 WebAssembly Integration (Hypothetical)

**Potential:** Offload combinatorial search to WASM  
**Speedup:** 10-100x  
**Complexity:** Very High  
**Feasibility:** Requires WoW API changes (unlikely)

### 11.2 Server-Side Processing (Hypothetical)

**Potential:** Run optimizer on external server  
**Speedup:** Unlimited  
**Complexity:** Very High  
**Concerns:** Security, privacy, TOS violation

### 11.3 GPU Acceleration (Not Possible)

WoW Lua has no GPU access.

### 11.4 Multi-Threading (Not Possible)

WoW Lua is single-threaded.

### 11.5 Practical Improvements

**Actually feasible:**
- Better pruning heuristics (10-20% speedup)
- Approximate algorithms for Mode 1 (50-90% speedup, slight accuracy loss)
- Cache optimizer results per player pool composition (instant re-runs)
- Incremental optimization (add players one at a time)

---

**Document Status:** Complete  
**Ready for Reference:** Yes  
**Testing Priority:** CRITICAL - Must validate all limits