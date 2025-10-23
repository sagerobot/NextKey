-- MARK: Performance-Optimized Event Handlers
-- Replaces problematic event handlers with performance-optimized versions

local _, NextKey222 = ...

local PerformanceHandlers = {}
NextKey222.PerformanceHandlers = PerformanceHandlers
NextKey222.RegisterModule("PerformanceHandlers", PerformanceHandlers)

-- Performance tracking
PerformanceHandlers.lastUIRefresh = 0
PerformanceHandlers.uiRefreshThrottle = 0.5 -- Minimum 500ms between UI refreshes

-- MARK: Optimized Group Roster Update
-- Prevents cascading UI refreshes that cause FPS drops

function PerformanceHandlers:OnGroupRosterUpdate()
    NextKey222.Performance:StartProfile("OptimizedOnGroupRosterUpdate")
    
    -- Event coalescing: Batch rapid-fire roster updates
    if not self.rosterUpdateTimer then
        self.rosterUpdateTimer = {}
    end
    
    -- Cancel pending update if one exists
    if self.rosterUpdateTimer.handle then
        self.rosterUpdateTimer.handle:Cancel()
    end
    
    -- PHASE 3: Optimize for offline players in mixed groups
    local groupSize = GetNumGroupMembers() or 1
    local onlineCount = NextKey222.Events and NextKey222.Events:GetOnlineGroupMembers() or 1
    
    -- Use online player count for throttling if significant offline presence
    local effectiveSize = onlineCount
    if groupSize - onlineCount >= 3 then
        -- 3+ offline players: use online count for performance
        effectiveSize = onlineCount
        NextKey222.Debug:Dev("performance", string.format("Mixed group detected: %d total, %d online - using online count for throttling",
            groupSize, onlineCount))
    end
    
    local baseDelay = 0.5
    local scaledDelay = baseDelay + (effectiveSize > 5 and (effectiveSize - 5) * 0.1 or 0)
    local maxDelay = 2.0
    local coalescingDelay = math.min(scaledDelay, maxDelay)
    
    NextKey222.Debug:Dev("performance", string.format("Group roster update - coalescing for %.1fs (total: %d, online: %d, effective: %d)",
        coalescingDelay, groupSize, onlineCount, effectiveSize))
    
    -- Schedule coalesced update with performance optimization
    self.rosterUpdateTimer.handle = C_Timer.NewTimer(coalescingDelay, function()
        NextKey222.Debug:Dev("performance", "Executing optimized coalesced roster update")
        
        -- PERFORMANCE FIX: Prevent cascading updates during batch operations
        local now = GetTime()
        if now - self.lastUIRefresh < self.uiRefreshThrottle then
            NextKey222.Debug:Dev("performance", "UI refresh throttled - too soon since last refresh")
            self.rosterUpdateTimer.handle = nil
            return
        end
        
        -- Update group composition
        if NextKey222.Communications and NextKey222.Communications.SendSync then
            NextKey.SafeRun(NextKey222.Communications.SendSync, "Auto sync on group change")
        end
        
        -- Update and share dungeon scores for IOCalculator
        if NextKey222.IOCalculator then
            NextKey.SafeRun(function()
                NextKey222.IOCalculator:UpdateCurrentPlayerScores()
            end, "Update dungeon scores on roster change")
        end
        
        -- PERFORMANCE FIX: Only refresh UI if visible and enough time has passed
        if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
            self.lastUIRefresh = now
            
            -- Add extra notice for IO gain potential mode
            if NextKey222.UI.IsPartySensitiveSortMode and NextKey222.UI:IsPartySensitiveSortMode() then
                NextKey222.Debug:Dev("performance", "Party change affects IO Gain Potential calculations - full refresh needed")
            end
            
            NextKey222.Debug:Dev("performance", "Refreshing UI due to party change (throttled)")
            NextKey.SafeRun(function()
                NextKey222.UI:RefreshResults()
            end, "Auto refresh UI on group change")
        end
        
        self.rosterUpdateTimer.handle = nil
    end)
    
    NextKey222.Performance:StopProfile("OptimizedOnGroupRosterUpdate")
end

-- MARK: Optimized Profile Cache Invalidation
-- Prevents excessive cache clearing that causes performance issues

function PerformanceHandlers:OptimizeProfileInvalidation()
    if not NextKey222.ProfilesService then
        return
    end
    
    -- Hook profile invalidation to prevent excessive clearing
    local originalInvalidateCache = NextKey222.ProfilesService.InvalidateCache
    local lastFullInvalidation = 0
    local FULL_INVALIDATION_THROTTLE = 30.0 -- Minimum 30 seconds between full invalidations
    
    NextKey222.ProfilesService.InvalidateCache = function(self, playerName)
        local now = GetTime()
        
        -- Throttle full invalidations
        if not playerName then
            if now - lastFullInvalidation < FULL_INVALIDATION_THROTTLE then
                NextKey222.Debug:Dev("performance", "Full profile cache invalidation throttled")
                return
            end
            lastFullInvalidation = now
        end
        
        return originalInvalidateCache(self, playerName)
    end
    
    Debug:Dev("performance", "Profile cache invalidation optimized")
end

-- MARK: Optimized UI Refresh
-- Prevents excessive UI refreshes that cause FPS drops

function PerformanceHandlers:OptimizeUIRefresh()
    if not NextKey222.UI then
        return
    end
    
    -- Hook UI refresh to add throttling
    local originalRefreshResults = NextKey222.UI.RefreshResults
    
    NextKey222.UI.RefreshResults = function(self)
        local now = GetTime()
        
        -- Throttle UI refreshes
        if now - self.lastUIRefresh < self.uiRefreshThrottle then
            NextKey222.Debug:Dev("performance", "UI refresh throttled - too soon since last refresh")
            return
        end
        
        self.lastUIRefresh = now
        return originalRefreshResults(self)
    end
    
    Debug:Dev("performance", "UI refresh optimized with throttling")
end

-- MARK: Memory Cleanup Optimization
-- Prevents excessive garbage collection that causes frame drops

function PerformanceHandlers:OptimizeMemoryManagement()
    -- Override force garbage collection with throttling
    local lastGC = 0
    local GC_THROTTLE = 5.0 -- Minimum 5 seconds between forced GC
    
    function PerformanceHandlers:ForceGarbageCollection()
        local now = GetTime()
        if now - lastGC < GC_THROTTLE then
            NextKey222.Debug:Dev("performance", "Forced GC throttled")
            return 0
        end
        
        lastGC = now
        local before = collectgarbage("count")
        collectgarbage("collect")
        local after = collectgarbage("count")
        local freed = (before - after) / 1024
        
        NextKey222.Debug:Dev("performance", string.format("Forced GC: freed %.2f MB", freed))
        return freed
    end
    
    Debug:Dev("performance", "Memory management optimized")
end

-- MARK: Module Initialization
function PerformanceHandlers:Initialize()
    Debug:Dev("performance", "Initializing Performance Handlers")
    
    -- Apply all optimizations
    self:OptimizeProfileInvalidation()
    self:OptimizeUIRefresh()
    self:OptimizeMemoryManagement()
    
    -- Replace original event handlers with optimized versions
    if NextKey222.Events then
        NextKey222.Events.OnGroupRosterUpdate = function()
            return self:OnGroupRosterUpdate()
        end
        Debug:Dev("performance", "Replaced OnGroupRosterUpdate with optimized version")
    end
    
    Debug:Dev("performance", "Performance Handlers initialized with all optimizations")
    return true
end

return PerformanceHandlers