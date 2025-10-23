--[[ 
NextKey PUG Mode Performance Test Suite
Tests and validates the performance optimizations implemented in PUG Mode

Usage:
/nk pug performance test    - Run all performance tests
/nk pug performance load    - Simulate high-load scenario
/nk pug performance monitor - Start real-time performance monitoring
]]

local _, NextKey222 = ...

local PUGPerformanceTest = {}
NextKey222.PUGPerformanceTest = PUGPerformanceTest

-- MARK: Test Configuration
local TEST_CONFIG = {
    LOAD_TEST_APPLICATIONS = 50,    -- Number of fake applications to create
    LOAD_TEST_UPDATES = 100,       -- Number of rapid updates to simulate
    LOAD_TEST_INTERVAL = 0.05,     -- Interval between updates (50ms)
    MONITOR_DURATION = 30,         -- Duration of performance monitoring in seconds
    FPS_WARNING_THRESHOLD = 30,    -- FPS below this is considered problematic
    MEMORY_WARNING_THRESHOLD = 50  -- Memory above this (MB) is concerning
}

-- MARK: Performance Metrics
local metrics = {
    startTime = 0,
    frameCount = 0,
    lastFrameTime = 0,
    fpsHistory = {},
    memoryHistory = {},
    eventCount = 0,
    lastEventTime = 0,
    testResults = {}
}

-- MARK: Mock Data Generation
local function generateMockApplications(count)
    local applications = {}
    local dungeons = {
        {name = "M+10 Ara-Kara", keyLevel = 10, dungeonID = 501},
        {name = "M+12 City of Threads", keyLevel = 12, dungeonID = 502},
        {name = "M+15 The Dawnbreaker", keyLevel = 15, dungeonID = 503},
        {name = "M+11 The Stonevault", keyLevel = 11, dungeonID = 504},
        {name = "M+13 Nerub-ar Palace", keyLevel = 13, dungeonID = 505}
    }
    
    local leaders = {"TankPlayer", "HealPlayer", "DPSPlayer1", "DPSPlayer2", "DPSPlayer3"}
    
    for i = 1, count do
        local dungeon = dungeons[math.random(1, #dungeons)]
        local leader = leaders[math.random(1, #leaders)] .. math.random(100, 999)
        
        table.insert(applications, {
            id = tostring(100000 + i),
            name = dungeon.name,
            leader = leader,
            dungeonID = dungeon.dungeonID,
            keyLevel = dungeon.keyLevel,
            activityID = dungeon.dungeonID,
            comment = "Test application " .. i,
            voiceChat = "Discord",
            iLevel = 600,
            honorLevel = 0,
            appliedAt = time(),
            status = "pending",
            statusHistory = {
                {status = "pending", timestamp = time()}
            }
        })
    end
    
    return applications
end

-- MARK: Performance Monitoring
local function startPerformanceMonitoring()
    metrics.startTime = GetTime()
    metrics.lastFrameTime = metrics.startTime
    metrics.frameCount = 0
    metrics.fpsHistory = {}
    metrics.memoryHistory = {}
    metrics.eventCount = 0
    
    if not PUGPerformanceTest.monitorFrame then
        PUGPerformanceTest.monitorFrame = CreateFrame("Frame")
    end
    
    PUGPerformanceTest.monitorFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        local frameDelta = now - metrics.lastFrameTime
        metrics.lastFrameTime = now
        metrics.frameCount = metrics.frameCount + 1
        
        -- Calculate FPS
        local fps = 1 / frameDelta
        table.insert(metrics.fpsHistory, fps)
        if #metrics.fpsHistory > 60 then -- Keep last 60 frames
            table.remove(metrics.fpsHistory, 1)
        end
        
        -- Track memory every 10 frames
        if metrics.frameCount % 10 == 0 then
            local memoryKB = collectgarbage("count")
            local memoryMB = memoryKB / 1024
            table.insert(metrics.memoryHistory, memoryMB)
            if #metrics.memoryHistory > 30 then -- Keep last 30 samples
                table.remove(metrics.memoryHistory, 1)
            end
        end
        
        -- Check for performance issues
        if fps < TEST_CONFIG.FPS_WARNING_THRESHOLD then
            NextKey222.Debug:Dev("performance", "WARNING: Low FPS detected: " .. string.format("%.1f", fps))
        end
    end)
    
    NextKey222.Debug:User("PUG Performance Test: Monitoring started")
end

local function stopPerformanceMonitoring()
    if PUGPerformanceTest.monitorFrame then
        PUGPerformanceTest.monitorFrame:SetScript("OnUpdate", nil)
    end
    
    local totalTime = GetTime() - metrics.startTime
    local avgFPS = metrics.frameCount / totalTime
    
    -- Calculate average memory usage
    local totalMemory = 0
    for _, memory in ipairs(metrics.memoryHistory) do
        totalMemory = totalMemory + memory
    end
    local avgMemory = #metrics.memoryHistory > 0 and (totalMemory / #metrics.memoryHistory) or 0
    
    -- Find minimum FPS
    local minFPS = math.min(unpack(metrics.fpsHistory))
    
    return {
        duration = totalTime,
        avgFPS = avgFPS,
        minFPS = minFPS,
        avgMemoryMB = avgMemory,
        frameCount = metrics.frameCount,
        eventCount = metrics.eventCount
    }
end

-- MARK: Test Functions
function PUGPerformanceTest:TestEventThrottling()
    NextKey222.Debug:User("PUG Performance Test: Testing event throttling...")
    
    local testStart = GetTime()
    local eventCount = 0
    
    -- Simulate rapid group roster updates
    for i = 1, 20 do
        if NextKey222.Events and NextKey222.Events.OnGroupRosterUpdate then
            NextKey222.Events.OnGroupRosterUpdate()
            eventCount = eventCount + 1
        end
    end
    
    local testEnd = GetTime()
    local testDuration = testEnd - testStart
    
    -- Wait for throttling to complete
    C_Timer.After(2, function()
        local results = {
            testType = "Event Throttling",
            eventsSent = eventCount,
            testDuration = testDuration,
            successful = testDuration < 0.1 -- Should complete quickly due to throttling
        }
        
        table.insert(metrics.testResults, results)
        NextKey222.Debug:User("PUG Performance Test: Event throttling test completed - " .. 
            (results.successful and "PASSED" or "FAILED"))
    end)
end

function PUGPerformanceTest:TestLFGUpdateBatching()
    NextKey222.Debug:User("PUG Performance Test: Testing LFG update batching...")
    
    local testStart = GetTime()
    local updateCount = 0
    
    -- Simulate rapid LFG updates
    for i = 1, 10 do
        if NextKey222.PUGHelper and NextKey222.PUGHelper.OnApplicationListUpdated then
            NextKey222.PUGHelper.OnApplicationListUpdated()
            updateCount = updateCount + 1
        end
    end
    
    local testEnd = GetTime()
    local testDuration = testEnd - testStart
    
    local results = {
        testType = "LFG Update Batching",
        updatesSent = updateCount,
        testDuration = testDuration,
        successful = testDuration < 0.05 -- Should complete very quickly due to batching
    }
    
    table.insert(metrics.testResults, results)
    NextKey222.Debug:User("PUG Performance Test: LFG batching test completed - " .. 
        (results.successful and "PASSED" or "FAILED"))
end

function PUGPerformanceTest:TestUIObjectPooling()
    NextKey222.Debug:User("PUG Performance Test: Testing UI object pooling...")
    
    if not NextKey222.PUGApplicationTracker then
        NextKey222.Debug:Error("PUG Application Tracker not available for pooling test")
        return
    end
    
    local testStart = GetTime()
    
    -- Generate mock applications
    local mockApps = generateMockApplications(TEST_CONFIG.LOAD_TEST_APPLICATIONS)
    
    -- Simulate multiple UI updates
    for i = 1, 5 do
        -- Mock the tracked applications
        NextKey222.PUGHelper.trackedApplications = {}
        for j = 1, math.min(10, #mockApps) do
            NextKey222.PUGHelper.trackedApplications[mockApps[j].id] = mockApps[j]
        end
        
        -- Trigger UI update
        if NextKey222.PUGApplicationTracker.UpdateDisplay then
            NextKey222.PUGApplicationTracker:UpdateDisplay()
        end
    end
    
    local testEnd = GetTime()
    local testDuration = testEnd - testStart
    
    local results = {
        testType = "UI Object Pooling",
        applicationsProcessed = #mockApps,
        updateCycles = 5,
        testDuration = testDuration,
        successful = testDuration < 0.5 -- Should complete quickly with pooling
    }
    
    table.insert(metrics.testResults, results)
    NextKey222.Debug:User("PUG Performance Test: UI pooling test completed - " .. 
        (results.successful and "PASSED" or "FAILED"))
end

function PUGPerformanceTest:RunLoadTest()
    NextKey222.Debug:User("PUG Performance Test: Starting load test with " .. 
        TEST_CONFIG.LOAD_TEST_APPLICATIONS .. " applications...")
    
    startPerformanceMonitoring()
    
    -- Generate mock applications
    local mockApps = generateMockApplications(TEST_CONFIG.LOAD_TEST_APPLICATIONS)
    
    -- Simulate rapid LFG updates
    local updateCount = 0
    local loadTestTimer = C_Timer.NewTicker(TEST_CONFIG.LOAD_TEST_INTERVAL, function()
        if updateCount >= TEST_CONFIG.LOAD_TEST_UPDATES then
            loadTestTimer:Cancel()
            
            -- Stop monitoring and report results
            C_Timer.After(1, function()
                local perfResults = stopPerformanceMonitoring()
                
                local results = {
                    testType = "Load Test",
                    applications = TEST_CONFIG.LOAD_TEST_APPLICATIONS,
                    updates = TEST_CONFIG.LOAD_TEST_UPDATES,
                    interval = TEST_CONFIG.LOAD_TEST_INTERVAL,
                    avgFPS = perfResults.avgFPS,
                    minFPS = perfResults.minFPS,
                    avgMemoryMB = perfResults.avgMemoryMB,
                    successful = perfResults.minFPS > 20 and perfResults.avgMemoryMB < TEST_CONFIG.MEMORY_WARNING_THRESHOLD
                }
                
                table.insert(metrics.testResults, results)
                
                NextKey222.Debug:User("PUG Performance Test: Load test completed")
                NextKey222.Debug:User("  - Average FPS: " .. string.format("%.1f", perfResults.avgFPS))
                NextKey222.Debug:User("  - Minimum FPS: " .. string.format("%.1f", perfResults.minFPS))
                NextKey222.Debug:User("  - Average Memory: " .. string.format("%.1f MB", perfResults.avgMemoryMB))
                NextKey222.Debug:User("  - Result: " .. (results.successful and "PASSED" or "FAILED"))
                
                PUGPerformanceTest:PrintSummary()
            end)
            return
        end
        
        -- Update applications with random changes
        NextKey222.PUGHelper.trackedApplications = {}
        for i = 1, math.min(15, #mockApps) do
            local app = mockApps[math.random(1, #mockApps)]
            app.status = (math.random() > 0.8) and "invited" or "pending"
            NextKey222.PUGHelper.trackedApplications[app.id] = app
        end
        
        -- Trigger update
        if NextKey222.PUGHelper and NextKey222.PUGHelper.OnApplicationListUpdated then
            NextKey222.PUGHelper.OnApplicationListUpdated()
        end
        
        updateCount = updateCount + 1
        metrics.eventCount = metrics.eventCount + 1
    end)
end

function PUGPerformanceTest:PrintSummary()
    NextKey222.Debug:User("=== PUG Performance Test Summary ===")
    
    local totalTests = #metrics.testResults
    local passedTests = 0
    
    for _, result in ipairs(metrics.testResults) do
        if result.successful then
            passedTests = passedTests + 1
        end
        
        NextKey222.Debug:User(string.format("%s: %s", result.testType, 
            result.successful and "PASSED" or "FAILED"))
        
        if result.avgFPS then
            NextKey222.Debug:User(string.format("  - FPS: Avg %.1f, Min %.1f", 
                result.avgFPS, result.minFPS or 0))
        end
        
        if result.avgMemoryMB then
            NextKey222.Debug:User(string.format("  - Memory: %.1f MB", result.avgMemoryMB))
        end
    end
    
    NextKey222.Debug:User(string.format("Overall: %d/%d tests passed (%.1f%%)", 
        passedTests, totalTests, (passedTests / totalTests) * 100))
    
    if passedTests == totalTests then
        NextKey222.Debug:User("All performance tests PASSED! PUG Mode is optimized.")
    else
        NextKey222.Debug:User("Some performance tests FAILED. Review optimization implementation.")
    end
end

-- MARK: Test Commands
function PUGPerformanceTest:RunAllTests()
    NextKey222.Debug:User("PUG Performance Test: Running all performance tests...")
    
    -- Clear previous results
    metrics.testResults = {}
    
    -- Run individual tests with delays
    C_Timer.After(0.5, function()
        PUGPerformanceTest:TestEventThrottling()
    end)
    
    C_Timer.After(1.0, function()
        PUGPerformanceTest:TestLFGUpdateBatching()
    end)
    
    C_Timer.After(1.5, function()
        PUGPerformanceTest:TestUIObjectPooling()
    end)
    
    C_Timer.After(2.0, function()
        PUGPerformanceTest:RunLoadTest()
    end)
end

-- MARK: Slash Command Integration
local function handlePUGPerformanceCommand(args)
    local command = args and string.lower(args) or ""
    
    if command == "test" then
        PUGPerformanceTest:RunAllTests()
    elseif command == "load" then
        PUGPerformanceTest:RunLoadTest()
    elseif command == "monitor" then
        startPerformanceMonitoring()
        NextKey222.Debug:User("Performance monitoring started for " .. TEST_CONFIG.MONITOR_DURATION .. " seconds")
        
        C_Timer.After(TEST_CONFIG.MONITOR_DURATION, function()
            local results = stopPerformanceMonitoring()
            NextKey222.Debug:User("Monitoring Results:")
            NextKey222.Debug:User("  - Average FPS: " .. string.format("%.1f", results.avgFPS))
            NextKey222.Debug:User("  - Average Memory: " .. string.format("%.1f MB", results.avgMemoryMB))
        end)
    else
        NextKey222.Debug:User("PUG Performance Test Commands:")
        NextKey222.Debug:User("  /nk pug performance test    - Run all performance tests")
        NextKey222.Debug:User("  /nk pug performance load    - Run high-load test")
        NextKey222.Debug:User("  /nk pug performance monitor - Start performance monitoring")
    end
end

-- Register slash command
if NextKey222 and NextKey222.Addon and NextKey222.Addon.RegisterSlashCommand then
    NextKey222.Addon:RegisterSlashCommand("pug performance", handlePUGPerformanceCommand)
end

return PUGPerformanceTest