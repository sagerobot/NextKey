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
            ui_contamination = { name = "UI Contamination Tracking", description = "Detect and prevent UI widget contamination between windows" },
            components = { name = "UI Components", description = "Reusable UI component system and widgets" },
            tooltip = { name = "Tooltip System", description = "Tooltip creation, positioning, and content" },
            teleport = { name = "Teleport System", description = "Teleport functionality and spell management" },
            lootwindow = { name = "Loot Tracking", description = "Loot window and item tracking interface" },
            hearthstoneSelector = { name = "Hearthstone Selector", description = "Hearthstone selection UI and management" },
            profiles = { name = "Profile Management", description = "Player profile creation and management" },
            pughelper = { name = "PUG Helper", description = "Pick Up Group workflow assistance and automation" }
        }
    },

    ["M+ Group Organizer"] = {
        description = "M+ Group Organizer system components",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        order = 4,
        categories = {
            organizer = { name = "Organizer Core", description = "Survey system, sorting algorithms, and player data building" },
            organizer_ui = { name = "Organizer UI", description = "Roster board UI, player cards, and visual elements" },
            org_sync = { name = "Organizer Sync", description = "Roster state synchronization and updates" },
            dragmanager = { name = "Drag Manager", description = "Drag and drop card management system" }
        }
    },

    ["Data Processing"] = {
        description = "Data calculation and processing systems",
        icon = "Interface\\Icons\\INV_Enchant_DessertCrystals",
        order = 5,
        categories = {
            keystones = { name = "Keystone Processing", description = "Keystone data collection and processing" },
            season = { name = "Seasonal Data", description = "Season information and dungeon management" },
            dungeonNameService = { name = "Dungeon Name Service", description = "Dungeon name lookup and mapping" },
            IOCalculator = { name = "IO Score Calculator", description = "IO score calculation algorithms and data" },
            ioc = { name = "IO Calculation Details", description = "Detailed IO calculation operations and steps" }
        }
    },

    ["Testing & Development"] = {
        description = "Development tools and testing utilities",
        icon = "Interface\\Icons\\INV_Eng_Gears",
        order = 6,
        categories = {
            test = { name = "Testing Utilities", description = "General testing tools and utilities" },
            fakeplayerservice = { name = "Fake Player Service", description = "Testing data generation and fake player simulation" },
            devtools = { name = "Developer Tools", description = "Developer utilities and testing interfaces" },
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
        hearthstoneSelector = false,
        pughelper = false,  -- PUG Helper functionality
        ui_contamination = false,  -- UI contamination tracking

        -- M+ Group Organizer
        organizer = false,  -- M+ Group Organizer core (survey, sorting, player data)
        organizer_ui = false,  -- M+ Group Organizer UI
        org_sync = false,  -- M+ Group Organizer sync system
        dragmanager = false,  -- Drag and drop manager

        -- Testing & Development
        fakeplayerservice = false,
        devtools = false,
        dungeonNameService = false,
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

-- Debug channel for Elephant logging compatibility
local DEBUG_CHANNEL_NAME = "NextKeyDebug"
local debugChannelID = nil
local debugChannelInitialized = false

-- Initialize debug channel (called once on first debug message)
local function initializeDebugChannel()
    if debugChannelInitialized then
        return debugChannelID ~= nil
    end
    
    debugChannelInitialized = true
    
    -- Try to join or create the debug channel
    local channelList = {GetChannelList()}
    for i = 1, #channelList, 3 do
        local id, name = channelList[i], channelList[i + 1]
        if name == DEBUG_CHANNEL_NAME then
            debugChannelID = id
            return true
        end
    end
    
    -- Channel doesn't exist, try to create it
    local id = JoinTemporaryChannel(DEBUG_CHANNEL_NAME)
    if id and id > 0 then
        debugChannelID = id
        return true
    end
    
    -- Failed to create channel
    return false
end

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
    
    -- Print message to both chat and debug channel (for Elephant addon compatibility)
    DEFAULT_CHAT_FRAME:AddMessage(message)
    
    -- Also send to debug channel if initialized (for Elephant logging)
    if initializeDebugChannel() and debugChannelID then
        -- Strip color codes for channel message (they don't work in channels)
        local plainMessage = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
        
        -- Send to channel (wrapped in pcall for safety)
        pcall(SendChatMessage, plainMessage, "CHANNEL", nil, debugChannelID)
    end
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
        -- Performance metrics (simplified)
        performanceMetrics = {
            totalCalls = debugPerformanceStats.totalCalls,
            filteredCalls = debugPerformanceStats.filteredCalls
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
