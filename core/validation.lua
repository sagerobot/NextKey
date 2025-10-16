-- MARK: Testing and Validation System
-- Comprehensive testing and validation for Phase 7 implementation
-- Validates all systems work correctly together

local _, NextKey222 = ...

local Validation = {}
NextKey222.Validation = Validation

-- Register with module system
NextKey222.RegisterModule("Validation", Validation)

-- MARK: Validation Constants
-- Standardized validation settings and thresholds

Validation.TEST_MODES = {
    UNIT = "unit",           -- Individual component tests
    INTEGRATION = "integration", -- System integration tests
    PERFORMANCE = "performance", -- Performance validation
    UI = "ui"                -- UI validation tests
}

Validation.RESULTS = {
    PASS = "PASS",
    FAIL = "FAIL",
    SKIP = "SKIP",
    ERROR = "ERROR"
}

Validation.TEST_CATEGORIES = {
    CONFIGURATION_CONTEXT = "configuration_context",
    TOOLTIP = "tooltip",
    THEME = "theme",
    UI_SCALE = "ui_scale",
    RESPONSIVE = "responsive",
    PERFORMANCE = "performance",
    COMPONENTS = "components",
    INTEGRATION = "integration"
}

-- MARK: Validation State
-- Current validation state and results

Validation.enabled = false
Validation.testResults = {}
Validation.currentTestSuite = nil
Validation.validationErrors = {}

-- MARK: Test Framework
-- Core testing framework functions

--- Creates a new test suite
-- @param name string The name of the test suite
-- @param description string Optional description
-- @return table Test suite object
function Validation:CreateTestSuite(name, description)
    local suite = {
        name = name,
        description = description or "",
        tests = {},
        results = {},
        startTime = nil,
        endTime = nil,
        passed = 0,
        failed = 0,
        skipped = 0,
        errors = 0
    }
    
    return suite
end

--- Adds a test to a test suite
-- @param suite table The test suite
-- @param name string The test name
-- @param testFunc function The test function
-- @param category string Optional test category
function Validation:AddTest(suite, name, testFunc, category)
    table.insert(suite.tests, {
        name = name,
        func = testFunc,
        category = category or "general",
        result = nil,
        message = "",
        time = 0
    })
end

--- Runs a test suite
-- @param suite table The test suite to run
-- @return table Test results
function Validation:RunTestSuite(suite)
    if not suite or not suite.tests then
        Debug:Error("Validation:RunTestSuite - Invalid test suite")
        return {}
    end
    
    suite.startTime = GetTime()
    Debug:Dev("validation", "Running test suite:", suite.name, "with", #suite.tests, "tests")
    
    for _, test in ipairs(suite.tests) do
        local testStartTime = GetTime()
        
        -- Run test with error handling
        local success, result, message = pcall(test.func)
        
        test.time = GetTime() - testStartTime
        
        if not success then
            test.result = self.RESULTS.ERROR
            test.message = "Test error: " .. tostring(result)
            suite.errors = suite.errors + 1
            Debug:Error("Validation: Test error in", test.name, ":", result)
        elseif result == true then
            test.result = self.RESULTS.PASS
            test.message = message or "Test passed"
            suite.passed = suite.passed + 1
            Debug:Dev("validation", "Test passed:", test.name)
        elseif result == false then
            test.result = self.RESULTS.FAIL
            test.message = message or "Test failed"
            suite.failed = suite.failed + 1
            Debug:Warn("Validation: Test failed:", test.name, "-", message)
        else
            test.result = self.RESULTS.SKIP
            test.message = message or "Test skipped"
            suite.skipped = suite.skipped + 1
            Debug:Dev("validation", "Test skipped:", test.name)
        end
    end
    
    suite.endTime = GetTime()
    suite.totalTime = suite.endTime - suite.startTime
    
    Debug:Dev("validation", "Test suite completed:", suite.name, 
              "Passed:", suite.passed, "Failed:", suite.failed, 
              "Skipped:", suite.skipped, "Errors:", suite.errors,
              "Time:", string.format("%.2f ms", suite.totalTime * 1000))
    
    return suite
end

--- Gets test suite summary
-- @param suite table The test suite
-- @return string Summary string
function Validation:GetTestSuiteSummary(suite)
    if not suite then return "No test suite" end
    
    local summary = string.format("Test Suite: %s\n", suite.name)
    summary = summary .. string.format("Total: %d, Passed: %d, Failed: %d, Skipped: %d, Errors: %d\n", 
        #suite.tests, suite.passed, suite.failed, suite.skipped, suite.errors)
    summary = summary .. string.format("Time: %.2f ms\n", suite.totalTime * 1000)
    
    if suite.failed > 0 or suite.errors > 0 then
        summary = summary .. "\nFailed Tests:\n"
        for _, test in ipairs(suite.tests) do
            if test.result == self.RESULTS.FAIL or test.result == self.RESULTS.ERROR then
                summary = summary .. string.format("  - %s: %s\n", test.name, test.message)
            end
        end
    end
    
    return summary
end

-- MARK: Configuration Context Tests
-- Tests for the Configuration Context system

function Validation:TestConfigurationContext()
    local suite = self:CreateTestSuite("Configuration Context Tests", 
        "Tests for the Configuration Context system")
    
    -- Test 1: Configuration Context Initialization
    self:AddTest(suite, "Configuration Context Initialization", function()
        if not NextKey222.ConfigurationContext then
            return false, "ConfigurationContext module not available"
        end
        
        if not NextKey222.ConfigurationContext.context then
            return false, "ConfigurationContext.context not initialized"
        end
        
        return true
    end, self.TEST_CATEGORIES.CONFIGURATION_CONTEXT)
    
    -- Test 2: Context State Management
    self:AddTest(suite, "Context State Management", function()
        local context = NextKey222.ConfigurationContext
        
        -- Test setting debug mode
        local originalDebugMode = context.context.isDebugMode
        context:SetDebugMode(true)
        if context.context.isDebugMode ~= true then
            return false, "Failed to set debug mode"
        end
        
        -- Test setting view mode
        context:SetViewMode("dungeons")
        if context.context.viewMode ~= "dungeons" then
            return false, "Failed to set view mode"
        end
        
        -- Restore original state
        context:SetDebugMode(originalDebugMode)
        
        return true
    end, self.TEST_CATEGORIES.CONFIGURATION_CONTEXT)
    
    -- Test 3: Configuration Resolution
    self:AddTest(suite, "Configuration Resolution", function()
        local context = NextKey222.ConfigurationContext
        
        -- Test window configuration resolution
        local windowConfig = context:GetResolvedConfig("window")
        if not windowConfig then
            return false, "Failed to resolve window configuration"
        end
        
        if not windowConfig.height then
            return false, "Window configuration missing height"
        end
        
        return true
    end, self.TEST_CATEGORIES.CONFIGURATION_CONTEXT)
    
    -- Test 4: Context Synchronization
    self:AddTest(suite, "Context Synchronization", function()
        local context = NextKey222.ConfigurationContext
        
        -- Test context synchronization
        if NextKey222.UI then
            context:SynchronizeWithUI(NextKey222.UI)
            return true
        else
            return self.RESULTS.SKIP, "UI not available for synchronization test"
        end
    end, self.TEST_CATEGORIES.CONFIGURATION_CONTEXT)
    
    return self:RunTestSuite(suite)
end

-- MARK: Tooltip System Tests
-- Tests for the Tooltip system

function Validation:TestTooltipSystem()
    local suite = self:CreateTestSuite("Tooltip System Tests", 
        "Tests for the Tooltip system")
    
    -- Test 1: Tooltip Module Initialization
    self:AddTest(suite, "Tooltip Module Initialization", function()
        if not NextKey222.Tooltip then
            return false, "Tooltip module not available"
        end
        
        if not NextKey222.Tooltip.TYPE_PLAYER then
            return false, "Tooltip type constants not defined"
        end
        
        return true
    end, self.TEST_CATEGORIES.TOOLTIP)
    
    -- Test 2: Tooltip Configuration
    self:AddTest(suite, "Tooltip Configuration", function()
        local tooltip = NextKey222.Tooltip
        
        -- Test tooltip configuration retrieval
        local config = tooltip.configs[tooltip.TYPE_PLAYER]
        if not config then
            return false, "Player tooltip configuration not found"
        end
        
        if not config.anchor then
            return false, "Tooltip configuration missing anchor"
        end
        
        return true
    end, self.TEST_CATEGORIES.TOOLTIP)
    
    -- Test 3: Tooltip Content Builders
    self:AddTest(suite, "Tooltip Content Builders", function()
        local tooltip = NextKey222.Tooltip
        
        -- Test content builder existence
        local builder = tooltip.contentBuilders[tooltip.TYPE_PLAYER]
        if not builder then
            return false, "Player tooltip content builder not found"
        end
        
        -- Test content builder function
        local testData = {
            name = "Test Player",
            classToken = "WARRIOR",
            specName = "Arms",
            role = "DAMAGER",
            io = 1500
        }
        
        local lines = builder(testData, {})
        if not lines or #lines == 0 then
            return false, "Content builder returned no lines"
        end
        
        return true
    end, self.TEST_CATEGORIES.TOOLTIP)
    
    return self:RunTestSuite(suite)
end

-- MARK: Theme System Tests
-- Tests for the Theme system

function Validation:TestThemeSystem()
    local suite = self:CreateTestSuite("Theme System Tests", 
        "Tests for the Theme system")
    
    -- Test 1: Theme Module Initialization
    self:AddTest(suite, "Theme Module Initialization", function()
        if not NextKey222.Theme then
            return false, "Theme module not available"
        end
        
        if not NextKey222.Theme.TYPE_DEFAULT then
            return false, "Theme type constants not defined"
        end
        
        return true
    end, self.TEST_CATEGORIES.THEME)
    
    -- Test 2: Theme Configuration
    self:AddTest(suite, "Theme Configuration", function()
        local theme = NextKey222.Theme
        
        -- Test theme configuration retrieval
        local config = theme.themes[theme.TYPE_DEFAULT]
        if not config then
            return false, "Default theme configuration not found"
        end
        
        if not config.window then
            return false, "Theme configuration missing window settings"
        end
        
        return true
    end, self.TEST_CATEGORIES.THEME)
    
    -- Test 3: Theme Resolution
    self:AddTest(suite, "Theme Resolution", function()
        local theme = NextKey222.Theme
        
        -- Test color resolution
        local color = theme:GetColor("text", "header")
        if not color or #color < 3 then
            return false, "Failed to resolve theme color"
        end
        
        -- Test font resolution
        local font = theme:GetFont("text", "header")
        if not font then
            return false, "Failed to resolve theme font"
        end
        
        return true
    end, self.TEST_CATEGORIES.THEME)
    
    return self:RunTestSuite(suite)
end

-- MARK: UI Scale Tests
-- Tests for the UI Scale system

function Validation:TestUIScaleSystem()
    local suite = self:CreateTestSuite("UI Scale System Tests", 
        "Tests for the UI Scale system")
    
    -- Test 1: UI Scale Module Initialization
    self:AddTest(suite, "UI Scale Module Initialization", function()
        if not NextKey222.UIScale then
            return false, "UI Scale module not available"
        end
        
        if NextKey222.UIScale.currentScale == nil then
            return false, "UI Scale current scale not initialized"
        end
        
        return true
    end, self.TEST_CATEGORIES.UI_SCALE)
    
    -- Test 2: Scale Range Validation
    self:AddTest(suite, "Scale Range Validation", function()
        local uiScale = NextKey222.UIScale
        
        -- Test setting valid scale
        local originalScale = uiScale:GetCurrentScale()
        local success = uiScale:SetScale(1.2)
        if not success then
            return false, "Failed to set valid scale"
        end
        
        -- Test setting invalid scale
        success = uiScale:SetScale(5.0)
        if success then
            return false, "Should not be able to set invalid scale"
        end
        
        -- Restore original scale
        uiScale:SetScale(originalScale)
        
        return true
    end, self.TEST_CATEGORIES.UI_SCALE)
    
    -- Test 3: Auto Scale Calculation
    self:AddTest(suite, "Auto Scale Calculation", function()
        local uiScale = NextKey222.UIScale
        
        local scale = uiScale:CalculateAutoScale()
        if not scale or scale < uiScale.MIN_SCALE or scale > uiScale.MAX_SCALE then
            return false, "Auto scale calculation returned invalid value"
        end
        
        return true
    end, self.TEST_CATEGORIES.UI_SCALE)
    
    return self:RunTestSuite(suite)
end

-- MARK: Responsive Layout Tests
-- Tests for the Responsive Layout system

function Validation:TestResponsiveSystem()
    local suite = self:CreateTestSuite("Responsive Layout Tests", 
        "Tests for the Responsive Layout system")
    
    -- Test 1: Responsive Module Initialization
    self:AddTest(suite, "Responsive Module Initialization", function()
        if not NextKey222.Responsive then
            return false, "Responsive module not available"
        end
        
        if not NextKey222.Responsive.breakpoints then
            return false, "Responsive breakpoints not defined"
        end
        
        return true
    end, self.TEST_CATEGORIES.RESPONSIVE)
    
    -- Test 2: Breakpoint Detection
    self:AddTest(suite, "Breakpoint Detection", function()
        local responsive = NextKey222.Responsive
        
        local breakpoint = responsive:GetCurrentBreakpoint()
        if not breakpoint then
            return false, "Failed to detect current breakpoint"
        end
        
        if not responsive.breakpoints[breakpoint] then
            return false, "Detected breakpoint not in breakpoints table"
        end
        
        return true
    end, self.TEST_CATEGORIES.RESPONSIVE)
    
    -- Test 3: Layout Mode Resolution
    self:AddTest(suite, "Layout Mode Resolution", function()
        local responsive = NextKey222.Responsive
        
        local mode = responsive:GetLayoutMode()
        if not mode then
            return false, "Failed to resolve layout mode"
        end
        
        local config = responsive:GetLayoutConfig("window")
        if not config then
            return false, "Failed to get layout configuration"
        end
        
        return true
    end, self.TEST_CATEGORIES.RESPONSIVE)
    
    return self:RunTestSuite(suite)
end

-- MARK: Performance Tests
-- Tests for the Performance system

function Validation:TestPerformanceSystem()
    local suite = self:CreateTestSuite("Performance System Tests", 
        "Tests for the Performance system")
    
    -- Test 1: Performance Module Initialization
    self:AddTest(suite, "Performance Module Initialization", function()
        if not NextKey222.Performance then
            return false, "Performance module not available"
        end
        
        if not NextKey222.Performance.profiles then
            return false, "Performance profiles not initialized"
        end
        
        return true
    end, self.TEST_CATEGORIES.PERFORMANCE)
    
    -- Test 2: Performance Profiling
    self:AddTest(suite, "Performance Profiling", function()
        local performance = NextKey222.Performance
        
        -- Test profiling a function
        local testFunc = function() return "test" end
        local result = performance:ProfileFunction(testFunc, "test_function")
        
        if result ~= "test" then
            return false, "Profiled function returned unexpected result"
        end
        
        -- Check if profile was created
        local profile = performance:GetMetrics("test_function")
        if not profile then
            return false, "Performance profile not created"
        end
        
        return true
    end, self.TEST_CATEGORIES.PERFORMANCE)
    
    -- Test 3: Caching System
    self:AddTest(suite, "Caching System", function()
        local performance = NextKey222.Performance
        
        -- Test cache set/get
        performance:CacheSet("test_key", "test_value")
        local value = performance:CacheGet("test_key")
        
        if value ~= "test_value" then
            return false, "Cache set/get failed"
        end
        
        -- Test cache statistics
        local stats = performance:CacheGetStats()
        if not stats then
            return false, "Failed to get cache statistics"
        end
        
        return true
    end, self.TEST_CATEGORIES.PERFORMANCE)
    
    return self:RunTestSuite(suite)
end

-- MARK: Integration Tests
-- Tests for system integration

function Validation:TestIntegration()
    local suite = self:CreateTestSuite("Integration Tests", 
        "Tests for system integration")
    
    -- Test 1: Component System Integration
    self:AddTest(suite, "Component System Integration", function()
        if not NextKey222.UIComponents then
            return false, "UI Components system not available"
        end
        
        -- Test component creation with configuration context
        if NextKey222.ConfigurationContext then
            local button = NextKey222.UIComponents:CreateButton("primary")
            if not button then
                return false, "Failed to create button with configuration context"
            end
        end
        
        -- Test component creation with theme
        if NextKey222.Theme then
            local text = NextKey222.UIComponents:CreateText("header")
            if not text then
                return false, "Failed to create text with theme"
            end
        end
        
        return true
    end, self.TEST_CATEGORIES.INTEGRATION)
    
    -- Test 2: UI System Integration
    self:AddTest(suite, "UI System Integration", function()
        if not NextKey222.UI then
            return false, "UI system not available"
        end
        
        -- Test UI with configuration context
        if NextKey222.ConfigurationContext then
            local shouldShowDebug = NextKey222.UI:ShouldShowDebugControls()
            if shouldShowDebug == nil then
                return false, "Failed to get debug controls visibility"
            end
        end
        
        -- Test UI with responsive layout
        if NextKey222.Responsive then
            local layoutConfig = NextKey222.Responsive:GetLayoutConfig("window")
            if not layoutConfig then
                return false, "Failed to get responsive layout configuration"
            end
        end
        
        return true
    end, self.TEST_CATEGORIES.INTEGRATION)
    
    -- Test 3: Cross-System Integration
    self:AddTest(suite, "Cross-System Integration", function()
        -- Test that all systems can work together
        local systemsAvailable = {
            ConfigurationContext = NextKey222.ConfigurationContext ~= nil,
            Tooltip = NextKey222.Tooltip ~= nil,
            Theme = NextKey222.Theme ~= nil,
            UIScale = NextKey222.UIScale ~= nil,
            Responsive = NextKey222.Responsive ~= nil,
            Performance = NextKey222.Performance ~= nil,
            UIComponents = NextKey222.UIComponents ~= nil,
            UI = NextKey222.UI ~= nil
        }
        
        local availableCount = 0
        for system, available in pairs(systemsAvailable) do
            if available then
                availableCount = availableCount + 1
            else
                Debug:Dev("validation", "System not available:", system)
            end
        end
        
        if availableCount < 5 then
            return false, "Too few systems available for integration test"
        end
        
        return true
    end, self.TEST_CATEGORIES.INTEGRATION)
    
    return self:RunTestSuite(suite)
end

-- MARK: Validation Runner
-- Functions to run all validations

--- Runs all validation tests
-- @param testMode string Optional test mode filter
-- @return table All test results
function Validation:RunAllValidations(testMode)
    testMode = testMode or "all"
    
    Debug:Dev("validation", "Starting Phase 7 validation with test mode:", testMode)
    
    local allResults = {}
    local startTime = GetTime()
    
    -- Run individual system tests
    if testMode == "all" or testMode == self.TEST_MODES.UNIT then
        allResults.configurationContext = self:TestConfigurationContext()
        allResults.tooltip = self:TestTooltipSystem()
        allResults.theme = self:TestThemeSystem()
        allResults.uiScale = self:TestUIScaleSystem()
        allResults.responsive = self:TestResponsiveSystem()
        allResults.performance = self:TestPerformanceSystem()
    end
    
    -- Run integration tests
    if testMode == "all" or testMode == self.TEST_MODES.INTEGRATION then
        allResults.integration = self:TestIntegration()
    end
    
    local endTime = GetTime()
    local totalTime = endTime - startTime
    
    -- Generate summary
    local summary = self:GenerateValidationSummary(allResults, totalTime)
    
    Debug:Dev("validation", "Phase 7 validation completed in", string.format("%.2f ms", totalTime * 1000))
    
    return allResults, summary
end

--- Generates validation summary
-- @param results table All test results
-- @param totalTime number Total execution time
-- @return table Validation summary
function Validation:GenerateValidationSummary(results, totalTime)
    local summary = {
        totalSuites = 0,
        totalTests = 0,
        totalPassed = 0,
        totalFailed = 0,
        totalSkipped = 0,
        totalErrors = 0,
        totalTime = totalTime,
        suites = {},
        success = true
    }
    
    for suiteName, suiteResult in pairs(results) do
        summary.totalSuites = summary.totalSuites + 1
        summary.totalTests = summary.totalTests + #suiteResult.tests
        summary.totalPassed = summary.totalPassed + suiteResult.passed
        summary.totalFailed = summary.totalFailed + suiteResult.failed
        summary.totalSkipped = summary.totalSkipped + suiteResult.skipped
        summary.totalErrors = summary.totalErrors + suiteResult.errors
        
        summary.suites[suiteName] = {
            name = suiteResult.name,
            passed = suiteResult.passed,
            failed = suiteResult.failed,
            skipped = suiteResult.skipped,
            errors = suiteResult.errors,
            success = suiteResult.failed == 0 and suiteResult.errors == 0
        }
        
        if suiteResult.failed > 0 or suiteResult.errors > 0 then
            summary.success = false
        end
    end
    
    return summary
end

--- Prints validation results
-- @param results table All test results
-- @param summary table Validation summary
function Validation:PrintValidationResults(results, summary)
    Debug:User("=== Phase 7 Validation Results ===")
    Debug:User("Total Suites:", summary.totalSuites)
    Debug:User("Total Tests:", summary.totalTests)
    Debug:User("Passed:", summary.totalPassed, "Failed:", summary.totalFailed, 
              "Skipped:", summary.totalSkipped, "Errors:", summary.totalErrors)
    Debug:User("Total Time:", string.format("%.2f ms", summary.totalTime * 1000))
    Debug:User("Overall Result:", summary.success and "SUCCESS" or "FAILURE")
    
    for suiteName, suiteResult in pairs(results) do
        if suiteResult.failed > 0 or suiteResult.errors > 0 then
            Debug:User("--- Failed Suite:", suiteResult.name, "---")
            Debug:User(self:GetTestSuiteSummary(suiteResult))
        end
    end
    
    Debug:User("=== End Validation Results ===")
end

-- MARK: Module Initialization
function Validation:Initialize()
    Debug:Dev("validation", "Validation module initialized")
    return true
end

return Validation