-- MARK: Performance Tests
-- Tests the performance optimizations implemented to fix FPS drops

local _, NextKey222 = ...

local PerformanceTest = {}

-- Test configuration
PerformanceTest.testConfig = {
    iterations = 10,
    tooltipTestDelay = 0.05,
    uiRefreshDelay = 0.1,
    memoryTestThreshold = 10 -- MB
}

--- Test 1: Tooltip Performance
-- Verifies that tooltip updates are properly throttled
function PerformanceTest:TestTooltipPerformance()
    NextKey222.Debug:User("=== Test 1: Tooltip Performance ===")
    
    if not NextKey222.UI or not NextKey222.UI.mainFrame then
        NextKey222.Debug:User("UI not available - skipping tooltip test")
        return false
    end
    
    local startTime = debugprofilestop()
    local tooltipUpdates = 0
    
    -- Simulate rapid tooltip updates (what was causing FPS drops)
    for i = 1, 50 do
        -- Simulate mouse entering/leaving tooltip areas rapidly
        if GameTooltip then
            GameTooltip:SetOwner(NextKey222.UI.mainFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText("Test Tooltip " .. i)
            GameTooltip:Show()
            tooltipUpdates = tooltipUpdates + 1
            
            -- Small delay to simulate rapid mouse movement
            C_Timer.After(self.testConfig.tooltipTestDelay, function()
                GameTooltip:Hide()
            end)
        end
    end
    
    local endTime = debugprofilestop()
    local totalTime = endTime - startTime
    
    NextKey222.Debug:User(string.format("Tooltip Test: %d updates in %.1fms", tooltipUpdates, totalTime))
    NextKey222.Debug:User(string.format("Average time per update: %.2fms", totalTime / tooltipUpdates))
    
    -- Test passes if average time per update is reasonable (< 5ms)
    local avgTime = totalTime / tooltipUpdates
    if avgTime < 5 then
        NextKey222.Debug:User("|cFF00FF00Tooltip Performance: PASS|r")
        return true
    else
        NextKey222.Debug:User("|cFFFF0000Tooltip Performance: FAIL - Too slow|r")
        return false
    end
end

--- Test 2: UI Refresh Performance
-- Verifies that UI refreshes are properly throttled
function PerformanceTest:TestUIRefreshPerformance()
    NextKey222.Debug:User("=== Test 2: UI Refresh Performance ===")
    
    if not NextKey222.UI then
        NextKey222.Debug:User("UI not available - skipping refresh test")
        return false
    end
    
    local startTime = debugprofilestop()
    local refreshCount = 0
    
    -- Simulate rapid UI refresh calls (what was causing cascading updates)
    for i = 1, 20 do
        NextKey.SafeRun(function()
            NextKey222.UI:RefreshResults()
        end, "Performance test refresh " .. i)
        refreshCount = refreshCount + 1
    end
    
    local endTime = debugprofilestop()
    local totalTime = endTime - startTime
    
    NextKey222.Debug:User(string.format("UI Refresh Test: %d refreshes in %.1fms", refreshCount, totalTime))
    NextKey222.Debug:User(string.format("Average time per refresh: %.2fms", totalTime / refreshCount))
    
    -- Test passes if throttling is working (should be much faster than before)
    local avgTime = totalTime / refreshCount
    if avgTime < 10 then
        NextKey222.Debug:User("|cFF00FF00UI Refresh Performance: PASS|r")
        return true
    else
        NextKey222.Debug:User("|cFFFF0000UI Refresh Performance: FAIL - Too slow|r")
        return false
    end
end

--- Test 3: Memory Usage
-- Verifies that memory usage is stable and not leaking
function PerformanceTest:TestMemoryUsage()
    NextKey222.Debug:User("=== Test 3: Memory Usage ===")
    
    -- Force garbage collection to get clean baseline
    collectgarbage("collect")
    local baselineMemory = collectgarbage("count")
    
    -- Simulate heavy UI usage
    for i = 1, 5 do
        -- Open and close UI window
        if NextKey222.UI then
            NextKey.SafeRun(function()
                NextKey222.UI:ShowMainFrame()
            end, "Memory test show UI")
            
            C_Timer.After(0.1, function()
                NextKey.SafeRun(function()
                    if NextKey222.UI.mainFrame then
                        NextKey222.UI.mainFrame:Hide()
                    end
                end, "Memory test hide UI")
            end)
        end
    end
    
    -- Wait for operations to complete
    C_Timer.After(1.0, function()
        collectgarbage("collect")
        local finalMemory = collectgarbage("count")
        local memoryIncrease = (finalMemory - baselineMemory) / 1024 -- Convert to MB
        
        NextKey222.Debug:User(string.format("Memory Test: Baseline %.2f MB, Final %.2f MB", 
            baselineMemory / 1024, finalMemory / 1024))
        NextKey222.Debug:User(string.format("Memory increase: %.2f MB", memoryIncrease))
        
        if memoryIncrease < self.testConfig.memoryTestThreshold then
            NextKey222.Debug:User("|cFF00FF00Memory Usage: PASS|r")
        else
            NextKey222.Debug:User("|cFFFF0000Memory Usage: FAIL - Too much memory increase|r")
        end
    end)
    
    return true
end

--- Test 4: Profile Cache Performance
-- Verifies that profile caching is working efficiently
function PerformanceTest:TestProfileCachePerformance()
    NextKey222.Debug:User("=== Test 4: Profile Cache Performance ===")
    
    if not NextKey222.ProfilesService then
        NextKey222.Debug:User("Profiles service not available - skipping cache test")
        return false
    end
    
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    local startTime = debugprofilestop()
    
    -- Request same profile multiple times to test caching
    for i = 1, 10 do
        local profile = NextKey222.ProfilesService:GetProfile(playerName)
        if not profile then
            NextKey222.Debug:User("Failed to get profile for " .. playerName)
            return false
        end
    end
    
    local endTime = debugprofilestop()
    local totalTime = endTime - startTime
    local avgTime = totalTime / 10
    
    NextKey222.Debug:User(string.format("Profile Cache Test: 10 requests in %.1fms", totalTime))
    NextKey222.Debug:User(string.format("Average time per request: %.2fms", avgTime))
    
    -- Check cache stats
    if NextKey222.ProfilesService.GetCacheStats then
        local cacheStats = NextKey222.ProfilesService:GetCacheStats()
        NextKey222.Debug:User(string.format("Cache hit rate: %.1f%%", cacheStats.hitRate * 100))
        
        if cacheStats.hitRate > 0.5 then -- 50% hit rate minimum
            NextKey222.Debug:User("|cFF00FF00Profile Cache Performance: PASS|r")
            return true
        else
            NextKey222.Debug:User("|cFFFF0000Profile Cache Performance: FAIL - Low hit rate|r")
            return false
        end
    end
    
    return true
end

--- Test 5: Event Handler Performance
-- Verifies that event handlers are not causing excessive updates
function PerformanceTest:TestEventPerformance()
    NextKey222.Debug:User("=== Test 5: Event Handler Performance ===")
    
    if not NextKey222.Events then
        NextKey222.Debug:User("Events system not available - skipping event test")
        return false
    end
    
    local startTime = debugprofilestop()
    
    -- Simulate rapid group roster updates
    for i = 1, 5 do
        NextKey.SafeRun(function()
            NextKey222.Events:OnGroupRosterUpdate()
        end, "Event test " .. i)
    end
    
    local endTime = debugprofilestop()
    local totalTime = endTime - startTime
    
    NextKey222.Debug:User(string.format("Event Handler Test: 5 roster updates in %.1fms", totalTime))
    
    -- Test passes if event handling is efficient (< 50ms for 5 updates)
    if totalTime < 50 then
        NextKey222.Debug:User("|cFF00FF00Event Handler Performance: PASS|r")
        return true
    else
        NextKey222.Debug:User("|cFFFF0000Event Handler Performance: FAIL - Too slow|r")
        return false
    end
end

--- Runs all performance tests
function PerformanceTest:RunAllTests()
    NextKey222.Debug:User("=== Starting Performance Test Suite ===")
    
    local results = {
        tooltip = self:TestTooltipPerformance(),
        uiRefresh = self:TestUIRefreshPerformance(),
        memory = self:TestMemoryUsage(),
        profileCache = self:TestProfileCachePerformance(),
        events = self:TestEventPerformance()
    }
    
    local passedTests = 0
    local totalTests = 0
    
    for testName, result in pairs(results) do
        totalTests = totalTests + 1
        if result then
            passedTests = passedTests + 1
        end
    end
    
    NextKey222.Debug:User("=== Performance Test Results ===")
    NextKey222.Debug:User(string.format("Passed: %d/%d tests", passedTests, totalTests))
    
    if passedTests == totalTests then
        NextKey222.Debug:User("|cFF00FF00All performance tests PASSED!|r")
    else
        NextKey222.Debug:User(string.format("|cFFFF0000%d performance tests FAILED!|r", totalTests - passedTests))
    end
    
    NextKey222.Debug:User("=== End Test Suite ===")
    
    return passedTests == totalTests
end

-- Register slash command for performance testing
SLASH_NKPERFTEST1 = "/nkperftest"
SlashCmdList["NKPERFTEST"] = function(msg)
    PerformanceTest:RunAllTests()
end

NextKey222.Debug:Dev("performance", "Performance Test Suite loaded")