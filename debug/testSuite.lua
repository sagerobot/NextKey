-- ==============================================================================
-- NextKey Debug System Test Suite
-- ==============================================================================
-- Comprehensive testing module for the debug system to validate all functionality
-- ==============================================================================

local _, NextKey222 = ...
local DebugService = NextKey222.Debug
local DebugUI = NextKey222.DebugUI

local TestSuite = {
    testResults = {},
    currentTest = 0,
    totalTests = 0,
    startTime = 0,
    endTime = 0
}

-- Test utility functions
function TestSuite:Assert(condition, testName, message)
    self.totalTests = self.totalTests + 1
    if condition then
        self.testResults[testName] = { passed = true, message = message or "PASSED" }
        DebugService:User("|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12|t TEST:", testName, "- PASSED")
    else
        self.testResults[testName] = { passed = false, message = message or "FAILED" }
        DebugService:Error("|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12|t TEST:", testName, "- FAILED:", message)
    end
end

function TestSuite:AssertEquals(actual, expected, testName, message)
    local condition = actual == expected
    local fullMessage = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
    self:Assert(condition, testName, fullMessage)
end

function TestSuite:AssertNotNil(value, testName, message)
    local condition = value ~= nil
    local fullMessage = message or "Expected non-nil value"
    self:Assert(condition, testName, fullMessage)
end

function TestSuite:RunTest(testName, testFunction)
    DebugService:User("Running test:", testName)
    local success, result = pcall(testFunction, self)
    if not success then
        self:Assert(false, testName, "Test execution failed: " .. tostring(result))
    end
end

-- Core functionality tests
function TestSuite:TestBasicDebugLevels()
    -- Test ERROR level (always enabled)
    DebugService:Error("Test error message")
    
    -- Test USER level (enabled in production)
    DebugService:User("Test user message")
    
    -- Test DEV level (requires category)
    DebugService:EnableCategory("test")
    DebugService:Dev("test", "Test dev message")
    
    -- Test TRACE level (requires category)
    DebugService:Trace("test", "Test trace message")
    
    -- Clean up: disable test category to avoid interfering with other tests
    DebugService:DisableCategory("test")
    
    self:Assert(true, "BasicDebugLevels", "All debug levels tested successfully")
end

function TestSuite:TestCategoryManagement()
    -- Ensure test category is in a known state (disabled) before testing
    DebugService:DisableCategory("test")
    local initialCount = DebugService:GetEnabledCategoriesCount()
    
    -- Test enabling category
    DebugService:EnableCategory("test")
    local afterEnable = DebugService:GetEnabledCategoriesCount()
    self:AssertEquals(afterEnable, initialCount + 1, "EnableCategory", "Category count should increase")
    
    -- Test disabling category
    DebugService:DisableCategory("test")
    local afterDisable = DebugService:GetEnabledCategoriesCount()
    self:AssertEquals(afterDisable, initialCount, "DisableCategory", "Category count should return to original")
    
    -- Test category toggle
    DebugService:ToggleCategory("test")
    self:Assert(DebugService.categories.test, "ToggleCategory_Enable", "Category should be enabled after toggle")
    
    DebugService:ToggleCategory("test")
    self:Assert(not DebugService.categories.test, "ToggleCategory_Disable", "Category should be disabled after toggle")
end

function TestSuite:TestGroupManagement()
    -- Test group status
    local enabled, enabledCount, totalCount = DebugService:GetGroupStatus("Core Systems")
    self:AssertNotNil(enabled, "GetGroupStatus_Enabled", "Group status should return enabled flag")
    self:AssertNotNil(enabledCount, "GetGroupStatus_Count", "Group status should return count")
    self:AssertNotNil(totalCount, "GetGroupStatus_Total", "Group status should return total")
    
    -- Test group enable/disable
    local initialCount = DebugService:GetEnabledCategoriesCount()
    DebugService:EnableGroup("Core Systems")
    local afterEnable = DebugService:GetEnabledCategoriesCount()
    self:Assert(afterEnable >= initialCount, "EnableGroup", "Enabling group should not reduce category count")
    
    DebugService:DisableGroup("Core Systems")
    local afterDisable = DebugService:GetEnabledCategoriesCount()
    self:Assert(afterDisable <= afterEnable, "DisableGroup", "Disabling group should not increase category count")
end

function TestSuite:TestLevelManagement()
    -- Test level setting
    for level = 0, 4 do
        local success = DebugService:SetLevel(level)
        self:Assert(success, "SetLevel_" .. level, "Setting level " .. level .. " should succeed")
        self:AssertEquals(DebugService:GetLevel(), level, "GetLevel_" .. level, "Level should be " .. level)
    end
    
    -- Test invalid level
    local success = DebugService:SetLevel(99)
    self:Assert(not success, "SetLevel_Invalid", "Setting invalid level should fail")
end

function TestSuite:TestStatistics()
    -- Reset statistics
    DebugService:ResetStatistics()
    local stats = DebugService:GetStatistics()
    
    -- Test initial state (no debug logging to avoid contaminating stats)
    self:AssertEquals(stats.totalMessages, 0, "Stats_Initial_Total", "Total messages should start at 0")
    self:AssertEquals(stats.errorCount, 0, "Stats_Initial_Error", "Error count should start at 0")
    self:AssertEquals(stats.userCount, 0, "Stats_Initial_User", "User count should start at 0")
    
    -- Generate some messages for testing
    DebugService:Error("Test error")
    DebugService:User("Test user")
    DebugService:EnableCategory("test")
    DebugService:Dev("test", "Test dev")
    
    -- Check updated statistics
    stats = DebugService:GetStatistics()
    self:Assert(stats.totalMessages >= 3, "Stats_After_Total", "Total messages should be at least 3")
    self:Assert(stats.errorCount >= 1, "Stats_After_Error", "Error count should be at least 1")
    self:Assert(stats.userCount >= 1, "Stats_After_User", "User count should be at least 1")
end

function TestSuite:TestPerformanceMonitoring()
    -- Enable performance monitoring
    DebugService:EnablePerformanceMonitoring(true)
    self:Assert(DebugService.performanceData.enabled, "Performance_Enable", "Performance monitoring should be enabled")
    
    -- Test timer functionality
    local timerId = DebugService:StartPerformanceTimer("test_operation", "test")
    self:AssertNotNil(timerId, "Performance_StartTimer", "Timer ID should not be nil")
    
    -- Simulate some work
    local sum = 0
    for i = 1, 1000 do
        sum = sum + i
    end
    
    local measurement = DebugService:EndPerformanceTimer(timerId)
    self:AssertNotNil(measurement, "Performance_EndTimer", "Measurement should not be nil")
    self:Assert(measurement.duration > 0, "Performance_Duration", "Duration should be positive")
    
    -- Test performance stats
    local perfStats = DebugService:GetPerformanceStats()
    self:Assert(perfStats.enabled, "Performance_Stats_Enabled", "Performance stats should show enabled")
    self:Assert(perfStats.totalMeasurements >= 1, "Performance_Stats_Count", "Should have at least 1 measurement")
    
    -- Test thresholds
    DebugService:SetPerformanceThresholds(0.05, 0.2)
    self:AssertEquals(DebugService.performanceData.thresholds.warning, 0.05, "Performance_Threshold_Warning", "Warning threshold should be set")
    self:AssertEquals(DebugService.performanceData.thresholds.critical, 0.2, "Performance_Threshold_Critical", "Critical threshold should be set")
    
    -- Disable performance monitoring
    DebugService:EnablePerformanceMonitoring(false)
    self:Assert(not DebugService.performanceData.enabled, "Performance_Disable", "Performance monitoring should be disabled")
end

function TestSuite:TestAdvancedFiltering()
    -- Enable filtering
    DebugService:EnableFiltering(true)
    self:Assert(DebugService.filtering.enabled, "Filtering_Enable", "Advanced filtering should be enabled")
    
    -- Test pattern addition
    local success = DebugService:AddFilterPattern("test_pattern", "test", "text", true)
    self:Assert(success, "Filtering_AddPattern", "Adding filter pattern should succeed")
    
    -- Test pattern matching
    local matches = DebugService:MatchesFilter("this is a test message", 3, "test")
    self:Assert(matches, "Filtering_Match", "Pattern should match test message")
    
    local noMatch = DebugService:MatchesFilter("this is a different message", 3, "test")
    self:Assert(not noMatch, "Filtering_NoMatch", "Pattern should not match different message")
    
    -- Test pattern toggle
    DebugService:ToggleFilterPattern("test_pattern", false)
    local afterDisable = DebugService:MatchesFilter("this is a test message", 3, "test")
    self:Assert(not afterDisable, "Filtering_DisabledMatch", "Disabled pattern should not match")
    
    DebugService:ToggleFilterPattern("test_pattern", true)
    local afterEnable = DebugService:MatchesFilter("this is a test message", 3, "test")
    self:Assert(afterEnable, "Filtering_EnabledMatch", "Enabled pattern should match")
    
    -- Test pattern removal
    success = DebugService:RemoveFilterPattern("test_pattern")
    self:Assert(success, "Filtering_RemovePattern", "Removing filter pattern should succeed")
    
    local afterRemoval = DebugService:MatchesFilter("this is a test message", 3, "test")
    self:Assert(not afterRemoval, "Filtering_RemovedMatch", "Removed pattern should not match")
    
    -- Test time range filtering
    local now = time()
    DebugService:SetTimeRangeFilter(now - 300, now)  -- Last 5 minutes
    self:Assert(DebugService.filtering.timeRange.enabled, "Filtering_TimeRange_Enable", "Time range should be enabled")
    
    local inRange = DebugService:IsInTimeRange()
    self:Assert(inRange, "Filtering_TimeRange_InRange", "Current time should be in range")
    
    -- Test level filtering
    DebugService:SetLevelFilter(3, false)  -- Filter out DEV level
    local isFiltered = DebugService:IsLevelFiltered(3)
    self:Assert(isFiltered, "Filtering_Level", "DEV level should be filtered")
    
    -- Test category filtering
    DebugService:SetCategoryFilter("test", false)  -- Filter out test category
    local isCatFiltered = DebugService:IsCategoryFiltered("test")
    self:Assert(isCatFiltered, "Filtering_Category", "Test category should be filtered")
    
    -- Test filtering stats
    local filterStats = DebugService:GetFilteringStats()
    self:Assert(filterStats.enabled, "Filtering_Stats_Enabled", "Filtering stats should show enabled")
    
    -- Disable filtering
    DebugService:EnableFiltering(false)
    self:Assert(not DebugService.filtering.enabled, "Filtering_Disable", "Advanced filtering should be disabled")
end

function TestSuite:TestPresetSystem()
    -- Test preset application
    DebugUI:ApplyPreset("minimal")
    self:AssertEquals(DebugService.level, 1, "Preset_Minimal_Level", "Minimal preset should set level to 1")
    
    DebugUI:ApplyPreset("standard")
    self:AssertEquals(DebugService.level, 2, "Preset_Standard_Level", "Standard preset should set level to 2")
    
    DebugUI:ApplyPreset("verbose")
    self:AssertEquals(DebugService.level, 3, "Preset_Verbose_Level", "Verbose preset should set level to 3")
    
    DebugUI:ApplyPreset("full")
    self:AssertEquals(DebugService.level, 4, "Preset_Full_Level", "Full preset should set level to 4")
    
    -- Test UI testing preset
    DebugUI:ApplyPreset("ui_testing")
    local uiGroupStatus = DebugService:GetGroupStatus("Features & UI")
    self:Assert(uiGroupStatus, "Preset_UI_Group", "UI testing preset should enable Features & UI group")
    
    -- Test custom preset creation
    DebugService:SetLevel(2)
    DebugService:EnableCategory("test")
    DebugUI:SaveCurrentAsPreset("test_preset")
    
    -- Debug: Check if we can access the preset
    DebugService:User("DEBUG: Attempting to verify preset creation...")
    if DebugUI.DEBUG_PRESETS then
        DebugService:User("DEBUG: DebugUI.DEBUG_PRESETS exists, checking for test_preset...")
        local presetExists = DebugUI.DEBUG_PRESETS["test_preset"] ~= nil
        DebugService:User("DEBUG: Preset exists:", presetExists and "YES" or "NO")
        if presetExists then
            local preset = DebugUI.DEBUG_PRESETS["test_preset"]
            DebugService:User("DEBUG: Preset details - Level:", preset.level, "Description:", preset.description)
        end
        self:Assert(presetExists, "Preset_Custom_Create", "Custom preset should be created")
    else
        DebugService:User("DEBUG: DebugUI.DEBUG_PRESETS is nil or inaccessible")
        self:Assert(false, "Preset_Custom_Create", "DEBUG_PRESETS table is not accessible")
    end
end

function TestSuite:TestPerformanceOptimization()
    -- Test maintenance function
    DebugService:PerformMaintenance()
    self:Assert(true, "Maintenance_Execute", "Maintenance should execute without errors")
    
    -- Test memory breakdown
    local breakdown = DebugService:GetMemoryBreakdown()
    self:AssertNotNil(breakdown, "Memory_Breakdown", "Memory breakdown should not be nil")
    self:AssertNotNil(breakdown.messageCache, "Memory_MessageCache", "Message cache count should not be nil")
    self:AssertNotNil(breakdown.performanceHistory, "Memory_PerformanceHistory", "Performance history count should not be nil")
    self:AssertNotNil(breakdown.filteringBuffer, "Memory_FilteringBuffer", "Filtering buffer count should not be nil")
    
    -- Test production optimization
    DebugService:OptimizeForProduction()
    self:Assert(not DebugService.enabled, "Production_Disabled", "Debug should be disabled in production mode")
    self:AssertEquals(DebugService.level, 2, "Production_Level", "Level should be USER in production mode")
    self:Assert(not DebugService.DEV_MODE, "Production_DevMode", "DEV_MODE should be false in production")
end

function TestSuite:TestUIIntegration()
    -- Test UI refresh
    DebugUI:RefreshOptions()
    self:Assert(true, "UI_Refresh", "UI refresh should execute without errors")
    
    -- Test uptime formatting
    local uptime = DebugUI:FormatUptime(3661)  -- 1 hour, 1 minute, 1 second
    self:AssertEquals(uptime, "01:01:01", "UI_UptimeFormat", "Uptime should be formatted correctly")
    
    -- Test active group count
    local groupCount = DebugUI:GetActiveGroupCount()
    self:Assert(groupCount >= 0 and groupCount <= 5, "UI_GroupCount", "Group count should be between 0 and 5")
end

-- Main test runner
function TestSuite:RunAllTests()
    self.startTime = time()
    self.testResults = {}
    self.totalTests = 0
    
    DebugService:User("|TInterface\\ICONS\\INV_Misc_Book_09:16|t Starting NextKey Debug System Test Suite")
    DebugService:User("Test started at:", date("%Y-%m-%d %H:%M:%S"))
    
    -- Run all test categories
    self:RunTest("Basic Debug Levels", function() self:TestBasicDebugLevels() end)
    self:RunTest("Category Management", function() self:TestCategoryManagement() end)
    self:RunTest("Group Management", function() self:TestGroupManagement() end)
    self:RunTest("Level Management", function() self:TestLevelManagement() end)
    self:RunTest("Statistics", function() self:TestStatistics() end)
    self:RunTest("Performance Monitoring", function() self:TestPerformanceMonitoring() end)
    self:RunTest("Advanced Filtering", function() self:TestAdvancedFiltering() end)
    self:RunTest("Preset System", function() self:TestPresetSystem() end)
    self:RunTest("Performance Optimization", function() self:TestPerformanceOptimization() end)
    self:RunTest("UI Integration", function() self:TestUIIntegration() end)
    
    self.endTime = time()
    self:PrintResults()
end

function TestSuite:PrintResults()
    local passed = 0
    local failed = 0
    
    for testName, result in pairs(self.testResults) do
        if result.passed then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end
    
    local duration = self.endTime - self.startTime
    
    DebugService:User("|TInterface\\ICONS\\INV_Misc_Book_09:16|t Test Suite Results")
    DebugService:User("========================================")
    DebugService:User("Total Tests:", self.totalTests)
    DebugService:User("Passed:", string.format("|cFF00FF00%d|r", passed))
    DebugService:User("Failed:", string.format("|cFFFF0000%d|r", failed))
    DebugService:User("Duration:", string.format("%.2f seconds", duration))
    DebugService:User("Success Rate:", string.format("%.1f%%", (passed / self.totalTests) * 100))
    DebugService:User("========================================")
    
    if failed == 0 then
        DebugService:User("|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t |cFF00FF00ALL TESTS PASSED!|r")
    else
        DebugService:Error("|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16|t", failed, "TESTS FAILED")
        
        -- List failed tests
        DebugService:User("Failed tests:")
        for testName, result in pairs(self.testResults) do
            if not result.passed then
                DebugService:User("  -", testName .. ":", result.message)
            end
        end
    end
end

-- Register test suite
NextKey222.TestSuite = TestSuite

-- Create global convenience function
_G.NextKeyRunTests = function()
    TestSuite:RunAllTests()
end

DebugService:User("NextKey Debug System Test Suite loaded")
DebugService:User("Run tests with: /script NextKeyRunTests()")

return TestSuite