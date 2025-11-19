-- MARK: Performance Monitor
-- Provides commands to monitor and diagnose performance issues

local _, NextKey222 = ...

-- Performance monitoring functions
local PerformanceMonitor = {}

--- Shows current performance metrics
function PerformanceMonitor:ShowPerformanceMetrics()
    if not NextKey222.PerformanceOptimizer then
        NextKey222.Debug:User("Performance optimizer not available")
        return
    end
    
    local metrics = NextKey222.PerformanceOptimizer.metrics
    local avgFPS = metrics.totalFrames > 0 and (1 / metrics.averageFrameTime) or 0
    local slowFramePercent = metrics.totalFrames > 0 and (metrics.slowFrames / metrics.totalFrames * 100) or 0
    
    NextKey222.Debug:User("=== Performance Metrics ===")
    NextKey222.Debug:User(string.format("Average FPS: %.1f", avgFPS))
    NextKey222.Debug:User(string.format("Slow Frames: %.1f%% (%d/%d)", 
        slowFramePercent, metrics.slowFrames, metrics.totalFrames))
    NextKey222.Debug:User(string.format("Frame Time: %.1fms avg", metrics.averageFrameTime * 1000))
    
    -- Memory usage
    local memoryKB = collectgarbage("count")
    local memoryMB = memoryKB / 1024
    NextKey222.Debug:User(string.format("Memory Usage: %.2f MB", memoryMB))
    
    -- Profile cache stats
    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetCacheStats then
        local cacheStats = NextKey222.ProfilesService:GetCacheStats()
        NextKey222.Debug:User(string.format("Profile Cache: %d entries, %.1f%% hit rate", 
            cacheStats.cacheSize, cacheStats.hitRate * 100))
    end
    
    NextKey222.Debug:User("=== End Metrics ===")
end

--- Forces garbage collection and reports memory freed
function PerformanceMonitor:ForceGarbageCollection()
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    local freed = (before - after) / 1024
    
    NextKey222.Debug:User(string.format("Forced GC: freed %.2f MB (was %.2f MB, now %.2f MB)", 
        freed, before / 1024, after / 1024))
    
    return freed
end

--- Runs a performance diagnostic test
function PerformanceMonitor:RunDiagnosticTest()
    NextKey222.Debug:User("=== Performance Diagnostic Test ===")
    
    -- Test 1: UI rendering performance
    NextKey222.Debug:User("Test 1: UI Rendering Performance")
    local startTime = debugprofilestop()
    
    if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
        -- Force a UI refresh to measure performance
        NextKey.SafeRun(function()
            NextKey222.UI:RefreshResults()
        end, "Diagnostic UI refresh")
    else
        NextKey222.Debug:User("UI not visible - skipping rendering test")
    end
    
    local renderTime = debugprofilestop() - startTime
    NextKey222.Debug:User(string.format("UI refresh took: %.1fms", renderTime))
    
    -- Test 2: Profile building performance
    NextKey222.Debug:User("Test 2: Profile Building Performance")
    if NextKey222.ProfilesService then
        local playerName = UnitName("player") .. "-" .. GetRealmName()
        startTime = debugprofilestop()
        
        local profile = NextKey222.ProfilesService:BuildProfileForPlayer(playerName)
        
        local profileTime = debugprofilestop() - startTime
        NextKey222.Debug:User(string.format("Profile building took: %.1fms", profileTime))
        
        if profile then
            NextKey222.Debug:User(string.format("Profile built for %s: %s IO, %s class", 
                playerName, profile.io or 0, profile.class or "unknown"))
        else
            NextKey222.Debug:User("Profile building failed")
        end
    else
        NextKey222.Debug:User("Profiles service not available - skipping profile test")
    end
    
    -- Test 3: Memory check
    NextKey222.Debug:User("Test 3: Memory Check")
    local memoryBefore = collectgarbage("count")
    self:ForceGarbageCollection()
    local memoryAfter = collectgarbage("count")
    
    if memoryAfter > 50 * 1024 then -- 50MB threshold
        NextKey222.Debug:User("|cFFFF0000WARNING: High memory usage detected|r")
    else
        NextKey222.Debug:User("|cFF00FF00Memory usage is normal|r")
    end
    
    NextKey222.Debug:User("=== End Diagnostic Test ===")
end

--- Toggles performance monitoring on/off
function PerformanceMonitor:ToggleMonitoring()
    if not NextKey222.PerformanceOptimizer then
        NextKey222.Debug:User("Performance optimizer not available")
        return
    end
    
    if NextKey222.PerformanceOptimizer.monitoringFrame then
        NextKey222.PerformanceOptimizer.monitoringFrame:SetScript("OnUpdate", nil)
        NextKey222.PerformanceOptimizer.monitoringFrame = nil
        NextKey222.Debug:User("Performance monitoring disabled")
    else
        NextKey222.PerformanceOptimizer:StartPerformanceMonitoring()
        NextKey222.Debug:User("Performance monitoring enabled")
    end
end

-- Register slash commands
SLASH_NKPERF1 = "/nkperf"
SLASH_NKPERFORMANCE1 = "/nkperformance"
SlashCmdList["NKPERF"] = function(msg)
    local cmd = msg and msg:lower() or ""
    
    if cmd == "metrics" or cmd == "" then
        PerformanceMonitor:ShowPerformanceMetrics()
    elseif cmd == "gc" then
        PerformanceMonitor:ForceGarbageCollection()
    elseif cmd == "test" then
        PerformanceMonitor:RunDiagnosticTest()
    elseif cmd == "toggle" then
        PerformanceMonitor:ToggleMonitoring()
    else
        NextKey222.Debug:User("Performance Monitor Commands:")
        NextKey222.Debug:User("  /nkperf metrics - Show performance metrics")
        NextKey222.Debug:User("  /nkperf gc - Force garbage collection")
        NextKey222.Debug:User("  /nkperf test - Run diagnostic test")
        NextKey222.Debug:User("  /nkperf toggle - Toggle performance monitoring")
    end
end

-- Auto-enable performance monitoring when addon loads
C_Timer.After(2.0, function()
    if NextKey222.PerformanceOptimizer then
        NextKey222.PerformanceOptimizer:StartPerformanceMonitoring()
        NextKey222.Debug:Dev("performance", "Performance monitoring auto-enabled")
    end
end)

NextKey222.Debug:Dev("performance", "Performance Monitor debug tool loaded")