# PUG Mode Performance Optimization Implementation Plan

## Overview

This document outlines the specific implementation steps to address the performance issues identified in the PUG Mode analysis. The plan is prioritized by impact and implementation complexity.

## Phase 1: Critical Performance Fixes (Immediate Implementation)

### Fix 1: Event Throttling System

**Target**: [`events/handlers.lua:74-141`](events/handlers.lua:74-141)

**Implementation**: Add intelligent throttling to prevent cascading updates.

```lua
-- Add to Events module
local lastRosterUpdate = 0
local ROSTER_UPDATE_THROTTLE = 1.0 -- 1 second minimum
local pendingRosterUpdate = false

function Events:OnGroupRosterUpdate()
    local now = GetTime()
    
    -- Immediate return if throttled
    if now - lastRosterUpdate < ROSTER_UPDATE_THROTTLE then
        if not pendingRosterUpdate then
            pendingRosterUpdate = true
            C_Timer.NewTimer(ROSTER_UPDATE_THROTTLE, function()
                self:ProcessRosterUpdate()
                pendingRosterUpdate = false
            end)
        end
        return
    end
    
    self:ProcessRosterUpdate()
    lastRosterUpdate = now
end

function Events:ProcessRosterUpdate()
    -- Existing logic moved here
    -- Add performance monitoring
    NextKey222.Performance:StartProfile("ProcessRosterUpdate")
    -- ... existing code ...
    NextKey222.Performance:StopProfile("ProcessRosterUpdate")
end
```

### Fix 2: Debug Logging Optimization

**Target**: [`core/pugHelper_applications.lua`](core/pugHelper_applications.lua)

**Implementation**: Replace all `print()` statements with proper debug system.

```lua
-- Replace all instances of:
print("NextKey PUG: " .. message)

-- With:
Debug:Dev("pughelper", message)

-- For user-facing messages:
Debug:User("PUG Helper: " .. message)

-- For errors:
Debug:Error("PUG Helper: " .. message)
```

### Fix 3: LFG Update Batching

**Target**: [`core/pugHelper_applications.lua:26-112`](core/pugHelper_applications.lua:26-112)

**Implementation**: Add batching and caching for LFG updates.

```lua
-- Add to PUGHelper module
local lastLFGUpdate = 0
local LFG_UPDATE_THROTTLE = 0.5 -- 500ms minimum
local pendingLFGUpdate = false
local cachedApplications = {}

function PUGHelper:OnApplicationListUpdated()
    local now = GetTime()
    
    if now - lastLFGUpdate < LFG_UPDATE_THROTTLE then
        if not pendingLFGUpdate then
            pendingLFGUpdate = true
            C_Timer.NewTimer(LFG_UPDATE_THROTTLE, function()
                self:ProcessLFGUpdate()
                pendingLFGUpdate = false
            end)
        end
        return
    end
    
    self:ProcessLFGUpdate()
    lastLFGUpdate = now
end

function PUGHelper:ProcessLFGUpdate()
    -- Compare with cache to avoid unnecessary processing
    local currentResults = C_LFGList.GetApplications()
    local resultsHash = table.concat(currentResults, ",")
    
    if resultsHash == cachedApplications.hash then
        Debug:Dev("pughelper", "LFG applications unchanged - skipping processing")
        return
    end
    
    -- Process only if changed
    self:ProcessApplications(currentResults)
    cachedApplications = {
        hash = resultsHash,
        timestamp = GetTime()
    }
end
```

## Phase 2: UI Performance Optimization

### Fix 4: Application Tracker Object Pooling

**Target**: [`ui/pugApplicationTracker.lua:440-486`](ui/pugApplicationTracker.lua:440-486)

**Implementation**: Implement object pooling for UI elements.

```lua
-- Add to PUGApplicationTracker module
local entryPool = {}
local poolSize = 0
local maxPoolSize = 20

function PUGApplicationTracker:GetPooledEntry()
    if poolSize > 0 then
        local entry = entryPool[poolSize]
        entryPool[poolSize] = nil
        poolSize = poolSize - 1
        return entry
    end
    
    -- Create new entry if pool empty
    return self:CreateApplicationEntry(frame.content, 1)
end

function PUGApplicationTracker:ReturnToPool(entry)
    if poolSize < maxPoolSize then
        entry.frame:Hide()
        poolSize = poolSize + 1
        entryPool[poolSize] = entry
    end
end

function PUGApplicationTracker:UpdateDisplay()
    if not frame or not isVisible then return end
    
    local applications = self:GetActiveApplications()
    local config = self.TRACKER_CONFIG
    
    -- Update title
    frame.title:SetText("NextKey - Applications (" .. #applications .. ")")
    
    -- Clear existing content children
    frame.content:ReleaseChildren()
    
    -- Return excess entries to pool
    for i = #applications + 1, #applicationEntries do
        self:ReturnToPool(applicationEntries[i])
    end
    
    -- Update or create entries
    for i = 1, #applications do
        local app = applications[i]
        local entry
        
        if i <= #applicationEntries then
            entry = applicationEntries[i]
        else
            entry = self:GetPooledEntry()
            table.insert(applicationEntries, entry)
        end
        
        self:UpdateApplicationEntry(entry, app)
        entry.frame:Show()
        frame.content:AddChild(entry)
    end
end
```

### Fix 5: Timer Management

**Target**: [`ui/pugApplicationTracker.lua:557-590`](ui/pugApplicationTracker.lua:557-590)

**Implementation**: Proper timer tracking and cleanup.

```lua
-- Add to PUGApplicationTracker module
local activeTimers = {}

function PUGApplicationTracker:StartRefreshTimer()
    self:StopRefreshTimer()
    
    local config = self.TRACKER_CONFIG
    local timer = C_Timer.NewTimer(config.refresh_interval, function()
        if isVisible then
            self:UpdateDisplay()
            self:StartRefreshTimer() -- Recursive timer creation
        end
        activeTimers.refresh = nil
    end)
    
    activeTimers.refresh = timer
end

function PUGApplicationTracker:StopRefreshTimer()
    if activeTimers.refresh then
        activeTimers.refresh:Cancel()
        activeTimers.refresh = nil
    end
end

function PUGApplicationTracker:StartAutoHideTimer()
    if activeTimers.autoHide then
        activeTimers.autoHide:Cancel()
    end
    
    activeTimers.autoHide = C_Timer.NewTimer(self.TRACKER_CONFIG.auto_hide_delay, function()
        local applications = self:GetActiveApplications()
        if #applications == 0 then
            self:Hide()
        end
        activeTimers.autoHide = nil
    end)
end

function PUGApplicationTracker:Cleanup()
    -- Cancel all active timers
    for _, timer in pairs(activeTimers) do
        if timer then
            timer:Cancel()
        end
    end
    activeTimers = {}
    
    -- Clear pools
    entryPool = {}
    poolSize = 0
    
    self:Hide()
end
```

## Phase 3: Memory and Cache Optimization

### Fix 6: Profile Cache Enhancement

**Target**: [`core/profiles.lua`](core/profiles.lua)

**Implementation**: Enhanced caching with intelligent invalidation.

```lua
-- Add to ProfilesService module
local profileCache = {}
local cacheStats = { hits = 0, misses = 0, invalidations = 0 }
local lastCacheCleanup = 0

function ProfilesService:GetProfile(playerName)
    if not playerName then return nil end
    
    local cacheKey = playerName
    local cached = profileCache[cacheKey]
    
    -- Check cache validity
    if cached and (GetTime() - cached.timestamp) < 300 then -- 5 minute TTL
        cacheStats.hits = cacheStats.hits + 1
        return cached.profile
    end
    
    cacheStats.misses = cacheStats.misses + 1
    local profile = self:BuildProfile(playerName)
    
    if profile then
        profileCache[cacheKey] = {
            profile = profile,
            timestamp = GetTime()
        }
    end
    
    -- Periodic cache cleanup
    local now = GetTime()
    if now - lastCacheCleanup > 60 then -- Cleanup every minute
        self:CleanupCache()
        lastCacheCleanup = now
    end
    
    return profile
end

function ProfilesService:CleanupCache()
    local now = GetTime()
    local cleaned = 0
    
    for key, cached in pairs(profileCache) do
        if now - cached.timestamp > 300 then -- Remove expired entries
            profileCache[key] = nil
            cleaned = cleaned + 1
        end
    end
    
    Debug:Dev("profiles", "Cache cleanup: removed " .. cleaned .. " expired entries")
end

function ProfilesService:InvalidateCache(playerName)
    if playerName then
        if profileCache[playerName] then
            profileCache[playerName] = nil
            cacheStats.invalidations = cacheStats.invalidations + 1
        end
    else
        -- Full cache invalidation with throttling
        local now = GetTime()
        if not self.lastFullInvalidation or now - self.lastFullInvalidation > 30 then
            profileCache = {}
            self.lastFullInvalidation = now
            cacheStats.invalidations = cacheStats.invalidations + 1
        end
    end
end
```

## Implementation Priority and Testing

### Priority Order:
1. **Fix 1**: Event throttling (highest impact)
2. **Fix 2**: Debug logging (easy win, reduces spam)
3. **Fix 3**: LFG batching (critical for active users)
4. **Fix 4**: UI object pooling (memory efficiency)
5. **Fix 5**: Timer management (memory leak prevention)
6. **Fix 6**: Profile caching (overall performance)

### Testing Strategy:
1. Load test with 20+ LFG applications
2. Monitor FPS during rapid group changes
3. Memory profiling during extended sessions
4. CPU usage analysis with performance monitoring

### Success Metrics:
- 50% reduction in FPS drops during group changes
- 70% reduction in debug spam
- 30% memory usage reduction during active PUG mode
- Elimination of timer-related memory leaks

## Rollout Plan

1. **Phase 1** (Week 1): Implement critical fixes 1-3
2. **Phase 2** (Week 2): Implement UI optimizations 4-5
3. **Phase 3** (Week 3): Implement cache optimization 6
4. **Testing** (Week 4): Comprehensive performance testing
5. **Release** (Week 5): Deploy optimized PUG Mode

## Monitoring and Validation

After implementation, monitor:
- Average FPS during PUG Mode usage
- Memory usage patterns
- Event handler execution frequency
- User-reported performance issues

This optimization plan should result in significantly improved PUG Mode performance, especially during active group finding scenarios.