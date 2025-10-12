-- ==============================================================================
-- NextKey Debug Service - Centralized Debug System with Compile-Time Stripping
-- ==============================================================================
-- Provides 5-level debug system with category filtering and compile-time stripping
--
-- Debug Levels:
--   NONE  (0) - Production/Release (completely silent)
--   ERROR (1) - Critical errors only (ALWAYS shown to users)
--   USER  (2) - User-facing informational messages (shown in release)
--   DEV   (3) - Development logging (stripped from release builds)
--   TRACE (4) - Ultra-verbose tracing (stripped from release builds)
--
-- Usage:
--   Debug:Error("Critical failure!")                  -- Always shown
--   Debug:User("Addon loaded successfully")            -- User messages
--   Debug:Dev("keystones", "Processing keystone...")   -- Dev logging
--   Debug:Trace("ui", "RefreshUI() called")           -- Verbose tracing
-- ==============================================================================

local addonName, NextKey222 = ...

-- MARK: - Debug Levels
NextKey222.DebugLevel = {
    NONE = 0,   -- Production (silent)
    ERROR = 1,  -- Critical errors (always show)
    USER = 2,   -- User messages (release-appropriate)
    DEV = 3,    -- Development logging (stripped from release)
    TRACE = 4   -- Ultra-verbose tracing (stripped from release)
}

-- MARK: - Debug Category Groups Configuration
local DEBUG_CATEGORY_GROUPS = {
    ["Core Systems"] = {
        description = "Fundamental addon functionality and initialization",
        icon = "Interface\\Icons\\INV_Gizmo_01",
        order = 1,
        categories = {
            startup = { name = "Startup & Initialization", description = "Addon loading, initialization sequence, and startup events" },
            events = { name = "Event Handling", description = "Event registration, dispatching, and processing" },
            performance = { name = "Performance Monitoring", description = "Performance tracking, optimization metrics, and timing" },
            database = { name = "Database Operations", description = "SavedVariables access, data persistence, and storage" },
            config = { name = "Configuration Management", description = "Settings loading, validation, and management" },
            options = { name = "Options Interface", description = "Options panel rendering and user preferences" }
        }
    },

    ["Communications"] = {
        description = "Network and addon-to-addon communication systems",
        icon = "Interface\\Icons\\INV_Misc_Net_01",
        order = 2,
        categories = {
            communications = { name = "Core Communications", description = "Main addon communication system" },
            comms = { name = "Communication Protocols", description = "Low-level message handling and protocols" },
            libopenraid = { name = "LibOpenRaid Integration", description = "LibOpenRaid API interactions and data exchange" },
            raiderio = { name = "RaiderIO Integration", description = "RaiderIO data fetching and processing" },
            blizzard = { name = "Blizzard API Integration", description = "Blizzard API calls and data retrieval" }
        }
    },

    ["Features & UI"] = {
        description = "User-facing features and interface elements",
        icon = "Interface\\Icons\\INV_Misc_Toy_07",
        order = 3,
        categories = {
            ui = { name = "Main UI", description = "Primary user interface rendering and interaction" },
            components = { name = "UI Components", description = "Reusable UI component system and widgets" },
            tooltip = { name = "Tooltip System", description = "Tooltip creation, positioning, and content" },
            teleport = { name = "Teleport System", description = "Teleport functionality and spell management" },
            lootwindow = { name = "Loot Tracking", description = "Loot window and item tracking interface" },
            profiles = { name = "Profile Management", description = "Player profile creation and management" }
        }
    },

    ["Data Processing"] = {
        description = "Data calculation and processing systems",
        icon = "Interface\\Icons\\INV_Enchant_DessertCrystals",
        order = 4,
        categories = {
            keystones = { name = "Keystone Processing", description = "Keystone data collection and processing" },
            season = { name = "Seasonal Data", description = "Season information and dungeon management" },
            IOCalculator = { name = "IO Score Calculator", description = "IO score calculation algorithms and data" },
            ioc = { name = "IO Calculation Operations", description = "Detailed IO calculation operations and steps" },
            fakeplayerservice = { name = "Fake Player Service", description = "Testing data generation and fake player simulation" }
        }
    },

    ["Testing & Development"] = {
        description = "Development tools and testing utilities",
        icon = "Interface\\Icons\\INV_Eng_Gears",
        order = 5,
        categories = {
            test = { name = "Testing Utilities", description = "General testing tools and utilities" },
            debug = { name = "Meta-Debug", description = "Debug system self-monitoring and diagnostics" }
        }
    }
}

-- MARK: - Debug Service Configuration
local DebugService = {
    -- [!] CRITICAL: SET TO FALSE BEFORE RELEASE!
    -- When false, Dev() and Trace() become no-ops (zero performance cost)
    DEV_MODE = true,

    -- Current debug settings
    enabled = false,
    level = NextKey222.DebugLevel.USER,  -- Default: show errors and user messages

    -- Debug categories (all start disabled)
    categories = {
        -- Core functionality
        keystones = false,
        communications = false,
        comms = false,
        ui = false,
        profiles = false,
        season = false,
        startup = false,
        events = false,

        -- Integrations
        raiderio = false,
        libopenraid = false,
        blizzard = false,

        -- System components
        performance = false,
        options = false,
        config = false,
        database = false,

        -- Features
        teleport = false,
        tooltip = false,
        components = false,
        lootwindow = false,

        -- Testing & Development
        fakeplayerservice = false,
        IOCalculator = false,
        ioc = false,
        test = false,
        debug = false  -- Meta-debug for debug system itself
    },

    -- Statistics (for debugging the debug system)
    stats = {
        errorCount = 0,
        userCount = 0,
        devCount = 0,
        traceCount = 0,
        startTime = time()  -- Track when debug system started
    }
}

-- MARK: - Private Helpers

-- Format and print message with level prefix
local function formatMessage(level, category, ...)
    local prefix
    if level == NextKey222.DebugLevel.ERROR then
        prefix = "|cFFFF0000[NextKey ERROR]|r"
    elseif level == NextKey222.DebugLevel.USER then
        prefix = "|cFF00FF00[NextKey]|r"
    elseif level == NextKey222.DebugLevel.DEV then
        prefix = "|cFFFFFF00[NextKey DEV]|r"
        if category then
            prefix = prefix .. " |cFF888888[" .. category .. "]|r"
        end
    elseif level == NextKey222.DebugLevel.TRACE then
        prefix = "|cFF888888[NextKey TRACE]|r"
        if category then
            prefix = prefix .. " |cFF444444[" .. category .. "]|r"
        end
    else
        prefix = "[NextKey]"
    end
    
    -- Convert all arguments to strings and filter out nils
    local parts = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            parts[#parts + 1] = tostring(v)
        end
    end
    local message = table.concat(parts, " ")
    print(prefix, message)
end

-- Performance-optimized check if a message should be printed
local function shouldPrint(level, category)
    -- Fast path: Always show ERROR level
    if level == NextKey222.DebugLevel.ERROR then
        return true
    end
    
    -- Fast path: Check if debug is globally enabled
    if not DebugService.enabled then
        -- In production mode, still show USER level
        return level == NextKey222.DebugLevel.USER
    end
    
    -- Fast path: Check level threshold
    if level > DebugService.level then
        return false
    end
    
    -- For DEV and TRACE, check category filter (most expensive check)
    if level >= NextKey222.DebugLevel.DEV and category then
        return DebugService.categories[category] == true
    end
    
    return true
end

-- Performance-optimized message formatting cache
local messageCache = {}
local cacheMaxSize = 100
local cacheHits = 0
local cacheMisses = 0

local function getCachedMessage(level, category, ...)
    -- Create cache key
    local key = tostring(level) .. "|" .. tostring(category) .. "|"
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            key = key .. tostring(v) .. "|"
        end
    end
    
    -- Check cache
    if messageCache[key] then
        cacheHits = cacheHits + 1
        return messageCache[key]
    end
    
    -- Cache miss - format message
    cacheMisses = cacheMisses + 1
    local prefix
    if level == NextKey222.DebugLevel.ERROR then
        prefix = "|cFFFF0000[NextKey ERROR]|r"
    elseif level == NextKey222.DebugLevel.USER then
        prefix = "|cFF00FF00[NextKey]|r"
    elseif level == NextKey222.DebugLevel.DEV then
        prefix = "|cFFFFFF00[NextKey DEV]|r"
        if category then
            prefix = prefix .. " |cFF888888[" .. category .. "]|r"
        end
    elseif level == NextKey222.DebugLevel.TRACE then
        prefix = "|cFF888888[NextKey TRACE]|r"
        if category then
            prefix = prefix .. " |cFF444444[" .. category .. "]|r"
        end
    else
        prefix = "[NextKey]"
    end
    
    -- Convert all arguments to strings and filter out nils
    local parts = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            parts[#parts + 1] = tostring(v)
        end
    end
    local message = prefix .. " " .. table.concat(parts, " ")
    
    -- Add to cache (with size management)
    if #messageCache >= cacheMaxSize then
        -- Remove oldest entry (simple FIFO)
        table.remove(messageCache, 1)
    end
    messageCache[key] = message
    
    return message
end

-- Performance monitoring for the debug system itself
local debugPerformanceStats = {
    totalCalls = 0,
    filteredCalls = 0,
    averageFormatTime = 0,
    lastCleanup = time()
}

-- MARK: - Public API

-- Performance-optimized print with explicit level and optional category
function DebugService:Print(level, category, ...)
    debugPerformanceStats.totalCalls = debugPerformanceStats.totalCalls + 1
    
    -- Handle variable arguments (category is optional)
    local actualCategory, messages
    if type(category) == "string" and select("#", ...) > 0 then
        -- Category provided
        actualCategory = category
        messages = {...}
    else
        -- No category, category param is actually first message
        actualCategory = nil
        messages = {category, ...}
    end
    
    -- Fast path: Check if we should print (most common early exit)
    if not shouldPrint(level, actualCategory) then
        debugPerformanceStats.filteredCalls = debugPerformanceStats.filteredCalls + 1
        return
    end
    
    -- Update statistics (minimal overhead)
    if level == NextKey222.DebugLevel.ERROR then
        self.stats.errorCount = self.stats.errorCount + 1
    elseif level == NextKey222.DebugLevel.USER then
        self.stats.userCount = self.stats.userCount + 1
    elseif level == NextKey222.DebugLevel.DEV then
        self.stats.devCount = self.stats.devCount + 1
    elseif level == NextKey222.DebugLevel.TRACE then
        self.stats.traceCount = self.stats.traceCount + 1
    end
    
    -- Use cached message formatting for better performance
    local startTime = debugprofilestop()
    local message = getCachedMessage(level, actualCategory, unpack(messages))
    local formatTime = debugprofilestop() - startTime
    
    -- Update performance stats (periodically to avoid overhead)
    if debugPerformanceStats.totalCalls % 100 == 0 then
        debugPerformanceStats.averageFormatTime =
            (debugPerformanceStats.averageFormatTime + formatTime) / 2
    end
    
    -- Print message
    print(message)
end

-- ERROR level - Critical errors (always shown)
function DebugService:Error(...)
    self:Print(NextKey222.DebugLevel.ERROR, nil, ...)
end

-- USER level - User-facing messages (shown in production)
function DebugService:User(...)
    self:Print(NextKey222.DebugLevel.USER, nil, ...)
end

-- DEV level - Development logging (stripped when DEV_MODE = false)
if DebugService.DEV_MODE then
    function DebugService:Dev(category, ...)
        self:Print(NextKey222.DebugLevel.DEV, category, ...)
    end
else
    -- No-op when DEV_MODE is false
    function DebugService:Dev(category, ...)
        -- Intentionally empty - zero performance cost
    end
end

-- TRACE level - Ultra-verbose tracing (stripped when DEV_MODE = false)
if DebugService.DEV_MODE then
    function DebugService:Trace(category, ...)
        self:Print(NextKey222.DebugLevel.TRACE, category, ...)
    end
else
    -- No-op when DEV_MODE is false
    function DebugService:Trace(category, ...)
        -- Intentionally empty - zero performance cost
    end
end

-- MARK: - Configuration Management

-- Set debug level (0-4)
function DebugService:SetLevel(level)
    if level < NextKey222.DebugLevel.NONE or level > NextKey222.DebugLevel.TRACE then
        self:Error("Invalid debug level:", level, "(must be 0-4)")
        return false
    end
    
    self.level = level
    
    -- Sync to SavedVariables if addon is loaded
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.level = level
    end
    
    local levelNames = {"NONE", "ERROR", "USER", "DEV", "TRACE"}
    self:User("Debug level set to", levelNames[level + 1] or "UNKNOWN")
    
    return true
end

-- Get current debug level
function DebugService:GetLevel()
    return self.level
end

-- Enable/disable debug system
function DebugService:SetEnabled(enabled)
    self.enabled = enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.enabled = enabled
    end
    
    self:User("Debug", enabled and "enabled" or "disabled")

    if NextKey222.UI and NextKey222.UI.OnDebugModeChanged then
        NextKey222.UI:OnDebugModeChanged()
    end
    
    return true
end

-- Toggle debug on/off
function DebugService:Toggle()
    return self:SetEnabled(not self.enabled)
end

-- Enable a debug category
function DebugService:EnableCategory(category)
    -- Check if the category exists as a key (nil check, not false check)
    if self.categories[category] == nil then
        self:Error("Unknown debug category:", category)
        return false
    end
    
    self.categories[category] = true
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.categories[category] = true
    end
    
    self:User("Enabled debug category:", category)
    return true
end

-- Disable a debug category
function DebugService:DisableCategory(category)
    -- Check if the category exists as a key (nil check, not false check)
    if self.categories[category] == nil then
        self:Error("Unknown debug category:", category)
        return false
    end
    
    self.categories[category] = false
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.categories[category] = false
    end
    
    self:User("Disabled debug category:", category)
    return true
end

-- Toggle a debug category
function DebugService:ToggleCategory(category)
    -- Check if the category exists as a key (nil check, not false check)
    if self.categories[category] == nil then
        self:Error("Unknown debug category:", category)
        return false
    end
    
    local newState = not self.categories[category]
    self.categories[category] = newState
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.categories[category] = newState
    end
    
    self:User("Category", category, newState and "enabled" or "disabled")
    return true
end

-- MARK: - Group Management Functions

-- Get all category groups
function DebugService:GetCategoryGroups()
    return DEBUG_CATEGORY_GROUPS
end

-- Enable entire group
function DebugService:EnableGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end

    local enabledCount = 0
    for categoryName, _ in pairs(group.categories) do
        if self:EnableCategory(categoryName) then
            enabledCount = enabledCount + 1
        end
    end

    self:User("Enabled debug group:", groupName, "(" .. enabledCount .. " categories)")
    return true
end

-- Disable entire group
function DebugService:DisableGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end

    local disabledCount = 0
    for categoryName, _ in pairs(group.categories) do
        if self:DisableCategory(categoryName) then
            disabledCount = disabledCount + 1
        end
    end

    self:User("Disabled debug group:", groupName, "(" .. disabledCount .. " categories)")
    return true
end

-- Toggle entire group
function DebugService:ToggleGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end

    local currentState = self:GetGroupStatus(groupName)
    if currentState then
        return self:DisableGroup(groupName)
    else
        return self:EnableGroup(groupName)
    end
end

-- Get group status (enabled, enabledCount, totalCount)
function DebugService:GetGroupStatus(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        return nil
    end

    local enabledCount = 0
    local totalCount = 0

    for categoryName, _ in pairs(group.categories) do
        totalCount = totalCount + 1
        if self.categories[categoryName] then
            enabledCount = enabledCount + 1
        end
    end

    return enabledCount > 0, enabledCount, totalCount
end

-- Get all categories in a group
function DebugService:GetGroupCategories(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        return {}
    end

    local categories = {}
    for categoryName, _ in pairs(group.categories) do
        table.insert(categories, categoryName)
    end

    return categories
end

-- Get which group a category belongs to
function DebugService:GetCategoryGroup(categoryName)
    for groupName, group in pairs(DEBUG_CATEGORY_GROUPS) do
        if group.categories[categoryName] then
            return groupName
        end
    end
    return nil
end

-- MARK: - Enhanced Statistics Functions

-- Get comprehensive statistics with performance metrics
function DebugService:GetStatistics()
    return {
        totalMessages = self.stats.errorCount + self.stats.userCount +
                       self.stats.devCount + self.stats.traceCount,
        errorCount = self.stats.errorCount,
        userCount = self.stats.userCount,
        devCount = self.stats.devCount,
        traceCount = self.stats.traceCount,
        enabledCategories = self:GetEnabledCategoriesCount(),
        totalCategories = self:GetTotalCategoriesCount(),
        currentLevel = self.level,
        enabled = self.enabled,
        uptime = self:GetUptime(),
        memoryUsage = self:GetMemoryUsage(),
        -- Performance metrics
        performanceMetrics = {
            totalCalls = debugPerformanceStats.totalCalls,
            filteredCalls = debugPerformanceStats.filteredCalls,
            filterEfficiency = debugPerformanceStats.totalCalls > 0 and
                (debugPerformanceStats.filteredCalls / debugPerformanceStats.totalCalls * 100) or 0,
            averageFormatTime = debugPerformanceStats.averageFormatTime,
            cacheHits = cacheHits,
            cacheMisses = cacheMisses,
            cacheEfficiency = (cacheHits + cacheMisses) > 0 and
                (cacheHits / (cacheHits + cacheMisses) * 100) or 0
        }
    }
end

-- Get count of enabled categories
function DebugService:GetEnabledCategoriesCount()
    local count = 0
    for _, enabled in pairs(self.categories) do
        if enabled then
            count = count + 1
        end
    end
    return count
end

-- Get total number of categories
function DebugService:GetTotalCategoriesCount()
    local count = 0
    for _ in pairs(self.categories) do
        count = count + 1
    end
    return count
end

-- Get addon uptime
function DebugService:GetUptime()
    if self.stats.startTime then
        return time() - self.stats.startTime
    end
    return 0
end

-- Get memory usage
function DebugService:GetMemoryUsage()
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        return GetAddOnMemoryUsage("NextKey")
    end
    return 0
end

-- Reset statistics
function DebugService:ResetStatistics()
    self.stats.errorCount = 0
    self.stats.userCount = 0
    self.stats.devCount = 0
    self.stats.traceCount = 0
    self.stats.startTime = time()
    
    -- Clear performance data
    if self.performanceData then
        self.performanceData.measurements = {}
        self.performanceData.history = {}
    end
    
    -- Reset debug system performance stats
    debugPerformanceStats.totalCalls = 0
    debugPerformanceStats.filteredCalls = 0
    debugPerformanceStats.averageFormatTime = 0
    debugPerformanceStats.lastCleanup = time()
    
    -- Clear message cache
    messageCache = {}
    cacheHits = 0
    cacheMisses = 0
    
    -- Don't log during reset to avoid contaminating statistics
    -- Use direct print instead of debug service
    print("|cFF00FF00[NextKey]|r Debug statistics reset")
end

-- Periodic cleanup function to prevent memory leaks
function DebugService:PerformMaintenance()
    local currentTime = time()
    
    -- Clean up message cache if it's getting large
    if #messageCache > cacheMaxSize * 0.8 then
        -- Remove oldest half of entries
        local removeCount = math.floor(#messageCache / 2)
        for i = 1, removeCount do
            table.remove(messageCache, 1)
        end
        self:Dev("debug", "Cleaned up message cache, removed", removeCount, "entries")
    end
    
    -- Clean up performance data history if it's getting large
    if #self.performanceData.history > 1000 then
        local removeCount = 500
        for i = 1, removeCount do
            table.remove(self.performanceData.history, 1)
        end
        self:Dev("debug", "Cleaned up performance history, removed", removeCount, "entries")
    end
    
    -- Clean up filtering buffer
    self:CleanupMessageBuffer()
    
    debugPerformanceStats.lastCleanup = currentTime
end

-- Optimize debug system for production use
function DebugService:OptimizeForProduction()
    -- Disable expensive features
    self.DEV_MODE = false
    self.enabled = false
    self.level = NextKey222.DebugLevel.USER
    
    -- Clear all enabled categories
    for category, _ in pairs(self.categories) do
        self.categories[category] = false
    end
    
    -- Disable performance monitoring
    self:EnablePerformanceMonitoring(false)
    
    -- Disable advanced filtering
    self:EnableFiltering(false)
    
    -- Clear caches
    messageCache = {}
    
    self:User("Debug system optimized for production use")
end

-- Get memory usage breakdown
function DebugService:GetMemoryBreakdown()
    local breakdown = {
        messageCache = 0,
        performanceHistory = 0,
        filteringBuffer = 0,
        total = 0
    }
    
    -- Estimate message cache size
    for _, _ in pairs(messageCache) do
        breakdown.messageCache = breakdown.messageCache + 1
    end
    
    -- Estimate performance history size
    breakdown.performanceHistory = #self.performanceData.history
    
    -- Estimate filtering buffer size
    breakdown.filteringBuffer = #self.filtering.messageBuffer
    
    breakdown.total = breakdown.messageCache + breakdown.performanceHistory + breakdown.filteringBuffer
    
    return breakdown
end

-- MARK: - Performance Monitoring Functions

-- Start performance timer
function DebugService:StartPerformanceTimer(operation, category)
    if not self.performanceData.enabled then
        return nil
    end
    
    local timerId = operation .. "_" .. GetTime()
    self.performanceData.measurements[timerId] = {
        operation = operation,
        category = category or "general",
        startTime = debugprofilestop(),
        startGameTime = GetTime()
    }
    
    return timerId
end

-- End performance timer
function DebugService:EndPerformanceTimer(timerId)
    if not timerId or not self.performanceData.measurements[timerId] then
        return nil
    end
    
    local measurement = self.performanceData.measurements[timerId]
    measurement.endTime = debugprofilestop()
    measurement.endGameTime = GetTime()
    measurement.duration = measurement.endTime - measurement.startTime
    measurement.gameDuration = measurement.endGameTime - measurement.startGameTime
    
    -- Store in history
    table.insert(self.performanceData.history, measurement)
    
    -- Keep only last 1000 measurements
    if #self.performanceData.history > 1000 then
        table.remove(self.performanceData.history, 1)
    end
    
    -- Check thresholds
    local level = 1
    if measurement.duration > self.performanceData.thresholds.critical then
        level = 3
    elseif measurement.duration > self.performanceData.thresholds.warning then
        level = 2
    end
    
    if level > 1 then
        self:Performance(measurement.operation,
            string.format("Performance warning: %.3fms (game: %.3fms)",
                measurement.duration, measurement.gameDuration * 1000),
            measurement.category, level)
    end
    
    -- Clean up
    self.performanceData.measurements[timerId] = nil
    
    return measurement
end

-- Measure performance of a function
function DebugService:MeasurePerformance(operation, category, func)
    if not self.performanceData.enabled or not func then
        if func then
            return func()
        end
        return
    end
    
    local timerId = self:StartPerformanceTimer(operation, category)
    local result = {pcall(func)}
    local success = table.remove(result, 1)
    local measurement = self:EndPerformanceTimer(timerId)
    
    if not success then
        self:Error("Performance measurement failed for", operation, ":", result[1])
        error(result[1])
    end
    
    return unpack(result)
end

-- Get performance statistics
function DebugService:GetPerformanceStats()
    local stats = {
        enabled = self.performanceData.enabled,
        totalMeasurements = #self.performanceData.history,
        thresholds = self.performanceData.thresholds,
        activeTimers = 0,
        averageDuration = 0,
        maxDuration = 0,
        slowestOperations = {},
        byCategory = {}
    }
    
    -- Count active timers
    for _ in pairs(self.performanceData.measurements) do
        stats.activeTimers = stats.activeTimers + 1
    end
    
    -- Calculate statistics from history
    if #self.performanceData.history > 0 then
        local totalDuration = 0
        local categoryData = {}
        
        for _, measurement in ipairs(self.performanceData.history) do
            totalDuration = totalDuration + measurement.duration
            stats.maxDuration = math.max(stats.maxDuration, measurement.duration)
            
            -- Track by category
            if not categoryData[measurement.category] then
                categoryData[measurement.category] = {
                    count = 0,
                    totalDuration = 0,
                    maxDuration = 0
                }
            end
            
            local cat = categoryData[measurement.category]
            cat.count = cat.count + 1
            cat.totalDuration = cat.totalDuration + measurement.duration
            cat.maxDuration = math.max(cat.maxDuration, measurement.duration)
        end
        
        stats.averageDuration = totalDuration / #self.performanceData.history
        
        -- Convert category data to stats format
        for category, data in pairs(categoryData) do
            stats.byCategory[category] = {
                count = data.count,
                averageDuration = data.totalDuration / data.count,
                maxDuration = data.maxDuration
            }
        end
        
        -- Find slowest operations
        local sortedHistory = {}
        for i, measurement in ipairs(self.performanceData.history) do
            sortedHistory[i] = measurement
        end
        
        table.sort(sortedHistory, function(a, b)
            return a.duration > b.duration
        end)
        
        for i = 1, math.min(10, #sortedHistory) do
            table.insert(stats.slowestOperations, {
                operation = sortedHistory[i].operation,
                category = sortedHistory[i].category,
                duration = sortedHistory[i].duration,
                timestamp = sortedHistory[i].startTime
            })
        end
    end
    
    return stats
end

-- Set performance thresholds
function DebugService:SetPerformanceThresholds(warning, critical)
    self.performanceData.thresholds.warning = warning or 0.1
    self.performanceData.thresholds.critical = critical or 0.5
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.performanceThresholds = self.performanceData.thresholds
    end
    
    self:User("Performance thresholds updated: warning=", warning, "critical=", critical)
end

-- Enable/disable performance monitoring
function DebugService:EnablePerformanceMonitoring(enabled)
    self.performanceData.enabled = enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.performanceEnabled = enabled
    end
    
    self:User("Performance monitoring", enabled and "enabled" or "disabled")
end

-- Export performance data
function DebugService:ExportPerformanceData()
    local data = {
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        stats = self:GetPerformanceStats(),
        history = self.performanceData.history
    }
    
    return data
end

-- Performance level logging (for performance warnings)
function DebugService:Performance(operation, message, category, level)
    if self.performanceData.enabled and shouldPrint(level or 2, category) then
        self:Dev(category or "performance", operation .. ": " .. message)
    end
end

-- MARK: - Advanced Filtering Functions

-- Add a filter pattern
function DebugService:AddFilterPattern(name, pattern, patternType, enabled)
    patternType = patternType or "text"  -- text, regex, wildcard
    enabled = enabled ~= false  -- default to true
    
    self.filtering.patterns[name] = {
        pattern = pattern,
        type = patternType,
        enabled = enabled,
        matchCount = 0,
        lastMatch = nil
    }
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringPatterns = self.filtering.patterns
    end
    
    self:User("Added filter pattern:", name, "(", patternType, "):", pattern)
    return true
end

-- Remove a filter pattern
function DebugService:RemoveFilterPattern(name)
    if self.filtering.patterns[name] then
        self.filtering.patterns[name] = nil
        
        -- Sync to SavedVariables
        if NextKey222.Addon and NextKey222.Addon.db then
            NextKey222.Addon.db.global.debug.filteringPatterns = self.filtering.patterns
        end
        
        self:User("Removed filter pattern:", name)
        return true
    end
    
    self:Error("Filter pattern not found:", name)
    return false
end

-- Toggle a filter pattern
function DebugService:ToggleFilterPattern(name, enabled)
    if not self.filtering.patterns[name] then
        self:Error("Filter pattern not found:", name)
        return false
    end
    
    self.filtering.patterns[name].enabled = enabled ~= nil and enabled or not self.filtering.patterns[name].enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringPatterns = self.filtering.patterns
    end
    
    self:User("Filter pattern", name, self.filtering.patterns[name].enabled and "enabled" or "disabled")
    return true
end

-- Check if a message matches any filter patterns
function DebugService:MatchesFilter(message, level, category)
    if not self.filtering.enabled then
        return false
    end
    
    local messageText = type(message) == "string" and message or ""
    
    for name, filter in pairs(self.filtering.patterns) do
        if not filter.enabled then
            -- Skip disabled filters
        else
            local matches = false
            
            if filter.type == "text" then
                matches = string.find(string.lower(messageText), string.lower(filter.pattern), 1, true)
            elseif filter.type == "regex" then
                local success, match = pcall(string.match, messageText, filter.pattern)
                matches = success and match ~= nil
            elseif filter.type == "wildcard" then
                -- Convert wildcard to regex pattern
                local regexPattern = string.gsub(filter.pattern, "%*", ".*")
                regexPattern = "^" .. regexPattern .. "$"
                local success, match = pcall(string.match, messageText, regexPattern)
                matches = success and match ~= nil
            end
            
            if matches then
                filter.matchCount = filter.matchCount + 1
                filter.lastMatch = time()
                return true
            end
        end
    end
    
    return false
end

-- Set time range filter
function DebugService:SetTimeRangeFilter(startTime, endTime)
    self.filtering.timeRange = {
        enabled = startTime ~= nil and endTime ~= nil,
        startTime = startTime,
        endTime = endTime
    }
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringTimeRange = self.filtering.timeRange
    end
    
    self:User("Time range filter", self.filtering.timeRange.enabled and "enabled" or "disabled")
    return true
end

-- Check if current time is within filter range
function DebugService:IsInTimeRange()
    if not self.filtering.timeRange.enabled then
        return true
    end
    
    local currentTime = time()
    return currentTime >= self.filtering.timeRange.startTime and currentTime <= self.filtering.timeRange.endTime
end

-- Set level filter
function DebugService:SetLevelFilter(level, enabled)
    self.filtering.levelFilters[level] = enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringLevelFilters = self.filtering.levelFilters
    end
    
    self:User("Level filter for", level, "set to", enabled and "enabled" or "disabled")
    return true
end

-- Check if level is filtered
function DebugService:IsLevelFiltered(level)
    if not self.filtering.enabled then
        return false
    end
    
    return self.filtering.levelFilters[level] == false
end

-- Set category filter
function DebugService:SetCategoryFilter(category, enabled)
    self.filtering.categoryFilters[category] = enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringCategoryFilters = self.filtering.categoryFilters
    end
    
    self:User("Category filter for", category, "set to", enabled and "enabled" or "disabled")
    return true
end

-- Check if category is filtered
function DebugService:IsCategoryFiltered(category)
    if not self.filtering.enabled then
        return false
    end
    
    return self.filtering.categoryFilters[category] == false
end

-- Enable/disable advanced filtering
function DebugService:EnableFiltering(enabled)
    self.filtering.enabled = enabled
    
    -- Sync to SavedVariables
    if NextKey222.Addon and NextKey222.Addon.db then
        NextKey222.Addon.db.global.debug.filteringEnabled = enabled
    end
    
    self:User("Advanced filtering", enabled and "enabled" or "disabled")
    return true
end

-- Add message to buffer for filtering analysis
function DebugService:BufferMessage(level, category, message, timestamp)
    local bufferEntry = {
        level = level,
        category = category,
        message = message,
        timestamp = timestamp or time(),
        filtered = false
    }
    
    table.insert(self.filtering.messageBuffer, bufferEntry)
    
    -- Maintain buffer size
    if #self.filtering.messageBuffer > self.filtering.bufferSize then
        table.remove(self.filtering.messageBuffer, 1)
    end
    
    -- Periodic cleanup
    if time() - self.filtering.lastCleanup > 300 then  -- 5 minutes
        self:CleanupMessageBuffer()
        self.filtering.lastCleanup = time()
    end
end

-- Clean up old messages from buffer
function DebugService:CleanupMessageBuffer()
    local cutoff = time() - 3600  -- 1 hour ago
    local newBuffer = {}
    
    for _, entry in ipairs(self.filtering.messageBuffer) do
        if entry.timestamp > cutoff then
            table.insert(newBuffer, entry)
        end
    end
    
    self.filtering.messageBuffer = newBuffer
end

-- Get filtered message statistics
function DebugService:GetFilteringStats()
    local stats = {
        enabled = self.filtering.enabled,
        totalPatterns = 0,
        enabledPatterns = 0,
        totalMatches = 0,
        bufferSize = #self.filtering.messageBuffer,
        timeRangeEnabled = self.filtering.timeRange.enabled,
        levelFiltersCount = 0,
        categoryFiltersCount = 0,
        patterns = {}
    }
    
    -- Count patterns
    for name, pattern in pairs(self.filtering.patterns) do
        stats.totalPatterns = stats.totalPatterns + 1
        if pattern.enabled then
            stats.enabledPatterns = stats.enabledPatterns + 1
        end
        stats.totalMatches = stats.totalMatches + pattern.matchCount
        
        table.insert(stats.patterns, {
            name = name,
            pattern = pattern.pattern,
            type = pattern.type,
            enabled = pattern.enabled,
            matchCount = pattern.matchCount,
            lastMatch = pattern.lastMatch
        })
    end
    
    -- Count level filters
    for level, enabled in pairs(self.filtering.levelFilters) do
        if enabled == false then
            stats.levelFiltersCount = stats.levelFiltersCount + 1
        end
    end
    
    -- Count category filters
    for category, enabled in pairs(self.filtering.categoryFilters) do
        if enabled == false then
            stats.categoryFiltersCount = stats.categoryFiltersCount + 1
        end
    end
    
    return stats
end

-- Enhanced print function with filtering support
function DebugService:PrintWithFiltering(level, category, ...)
    -- Check basic filtering first
    if not shouldPrint(level, category) then
        return
    end
    
    -- Advanced filtering checks
    if self.filtering.enabled then
        local message = table.concat({...}, " ")
        
        -- Check pattern filtering
        if self:MatchesFilter(message, level, category) then
            return  -- Message filtered out
        end
        
        -- Check time range filtering
        if not self:IsInTimeRange() then
            return  -- Message filtered out
        end
        
        -- Check level filtering
        if self:IsLevelFiltered(level) then
            return  -- Message filtered out
        end
        
        -- Check category filtering
        if self:IsCategoryFiltered(category) then
            return  -- Message filtered out
        end
        
        -- Buffer the message for analysis
        self:BufferMessage(level, category, message)
    end
    
    -- If we get here, the message passed all filters
    self:Print(level, category, ...)
end

-- Export filtering data
function DebugService:ExportFilteringData()
    local data = {
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        stats = self:GetFilteringStats(),
        patterns = self.filtering.patterns,
        timeRange = self.filtering.timeRange,
        levelFilters = self.filtering.levelFilters,
        categoryFilters = self.filtering.categoryFilters,
        recentMessages = {}
    }
    
    -- Add recent messages from buffer
    local recentCount = math.min(100, #self.filtering.messageBuffer)
    for i = #self.filtering.messageBuffer - recentCount + 1, #self.filtering.messageBuffer do
        table.insert(data.recentMessages, self.filtering.messageBuffer[i])
    end
    
    return data
end

-- MARK: - Status & Diagnostics

-- Print current debug status
function DebugService:PrintStatus()
    local levelNames = {"NONE", "ERROR", "USER", "DEV", "TRACE"}

    self:User("=== NextKey Debug Status ===")
    self:User("Enabled:", self.enabled and "YES" or "NO")
    self:User("Level:", levelNames[self.level + 1] or "UNKNOWN", "(" .. self.level .. ")")
    self:User("DEV_MODE:", self.DEV_MODE and "YES" or "NO")

    -- Count enabled categories
    local enabledCategories = {}
    for category, enabled in pairs(self.categories) do
        if enabled then
            table.insert(enabledCategories, category)
        end
    end

    if #enabledCategories > 0 then
        table.sort(enabledCategories)
        self:User("Enabled Categories (" .. #enabledCategories .. "):", table.concat(enabledCategories, ", "))
    else
        self:User("Enabled Categories: None")
    end

    -- Show statistics
    self:User("Statistics:")
    self:User("  Errors:", self.stats.errorCount)
    self:User("  User Messages:", self.stats.userCount)
    self:User("  Dev Messages:", self.stats.devCount)
    self:User("  Trace Messages:", self.stats.traceCount)
end

-- List all available categories
function DebugService:ListCategories()
    local categories = {}
    for category, _ in pairs(self.categories) do
        table.insert(categories, category)
    end
    table.sort(categories)

    self:User("Available debug categories (" .. #categories .. "):")
    for _, category in ipairs(categories) do
        local status = self.categories[category] and "|cFF00FF00ON|r" or "|cFF888888OFF|r"
        self:User("  " .. category .. ":", status)
    end
end

-- MARK: - Initialization

-- Initialize debug service from SavedVariables
function DebugService:Initialize(db)
    if not db or not db.global or not db.global.debug then
        self:Error("Debug service initialization failed: invalid database")
        return false
    end
    
    -- Load settings from database
    self.enabled = db.global.debug.enabled or false
    self.level = db.global.debug.level or NextKey222.DebugLevel.USER
    
    -- Load category states
    if db.global.debug.categories then
        for category, enabled in pairs(db.global.debug.categories) do
            if self.categories[category] ~= nil then
                self.categories[category] = enabled
            end
        end
    end
    
    -- Initialize missing categories in database
    if not db.global.debug.categories then
        db.global.debug.categories = {}
    end
    for category, _ in pairs(self.categories) do
        if db.global.debug.categories[category] == nil then
            db.global.debug.categories[category] = false
        end
    end
    
    -- Initialize level in database if missing
    if not db.global.debug.level then
        db.global.debug.level = NextKey222.DebugLevel.USER
    end
    
    -- Initialize performance monitoring
    self.performanceData = {
        enabled = db.global.debug.performanceEnabled or false,
        measurements = {},
        history = {},
        thresholds = {
            warning = db.global.debug.performanceThresholds and db.global.debug.performanceThresholds.warning or 0.1,  -- 100ms
            critical = db.global.debug.performanceThresholds and db.global.debug.performanceThresholds.critical or 0.5  -- 500ms
        }
    }
    
    -- Initialize advanced filtering
    self.filtering = {
        enabled = db.global.debug.filteringEnabled or false,
        patterns = db.global.debug.filteringPatterns or {},
        timeRange = db.global.debug.filteringTimeRange or {},
        levelFilters = db.global.debug.filteringLevelFilters or {},
        categoryFilters = db.global.debug.filteringCategoryFilters or {},
        messageBuffer = {},
        bufferSize = 1000,
        lastCleanup = time()
    }
    
    -- Initialize performance settings in database if missing
    if not db.global.debug.performanceEnabled then
        db.global.debug.performanceEnabled = false
    end
    if not db.global.debug.performanceThresholds then
        db.global.debug.performanceThresholds = {
            warning = 0.1,
            critical = 0.5
        }
    end
    
    -- Initialize filtering settings in database if missing
    if not db.global.debug.filteringEnabled then
        db.global.debug.filteringEnabled = false
    end
    if not db.global.debug.filteringPatterns then
        db.global.debug.filteringPatterns = {}
    end
    if not db.global.debug.filteringTimeRange then
        db.global.debug.filteringTimeRange = {}
    end
    if not db.global.debug.filteringLevelFilters then
        db.global.debug.filteringLevelFilters = {}
    end
    if not db.global.debug.filteringCategoryFilters then
        db.global.debug.filteringCategoryFilters = {}
    end
    
    self:Dev("debug", "Debug service initialized")
    self:Dev("debug", "  Enabled:", self.enabled)
    self:Dev("debug", "  Level:", self.level)
    self:Dev("debug", "  DEV_MODE:", self.DEV_MODE)
    self:Dev("debug", "  Performance Monitoring:", self.performanceData.enabled)
    
    return true
end

-- MARK: - Registration

-- Register debug service directly (before RegisterModule is enhanced with Debug logging)
NextKey222.Debug = DebugService

-- Register in module registry manually to avoid circular dependency
NextKey222.moduleRegistry = NextKey222.moduleRegistry or {}
NextKey222.moduleRegistry["Debug"] = DebugService

-- Create convenient global reference for all modules
_G.Debug = NextKey222.Debug
