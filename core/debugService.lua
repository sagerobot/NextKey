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

-- MARK: - Debug Service Configuration
local DebugService = {
    -- ⚠️ CRITICAL: SET TO FALSE BEFORE RELEASE!
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
        traceCount = 0
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

-- Check if a message should be printed based on level and category
local function shouldPrint(level, category)
    -- Always show ERROR level
    if level == NextKey222.DebugLevel.ERROR then
        return true
    end
    
    -- Check if debug is globally enabled
    if not DebugService.enabled then
        -- In production mode, still show USER level
        return level == NextKey222.DebugLevel.USER
    end
    
    -- Check level threshold
    if level > DebugService.level then
        return false
    end
    
    -- For DEV and TRACE, check category filter
    if level >= NextKey222.DebugLevel.DEV and category then
        return DebugService.categories[category] == true
    end
    
    return true
end

-- MARK: - Public API

-- Print with explicit level and optional category
function DebugService:Print(level, category, ...)
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
    
    -- Check if we should print
    if not shouldPrint(level, actualCategory) then
        return
    end
    
    -- Update statistics
    if level == NextKey222.DebugLevel.ERROR then
        self.stats.errorCount = self.stats.errorCount + 1
    elseif level == NextKey222.DebugLevel.USER then
        self.stats.userCount = self.stats.userCount + 1
    elseif level == NextKey222.DebugLevel.DEV then
        self.stats.devCount = self.stats.devCount + 1
    elseif level == NextKey222.DebugLevel.TRACE then
        self.stats.traceCount = self.stats.traceCount + 1
    end
    
    -- Format and print message
    formatMessage(level, actualCategory, unpack(messages))
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
    
    return true
end

-- Toggle debug on/off
function DebugService:Toggle()
    return self:SetEnabled(not self.enabled)
end

-- Enable a debug category
function DebugService:EnableCategory(category)
    if not self.categories[category] then
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
    if not self.categories[category] then
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
    if not self.categories[category] then
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
    
    self:Dev("debug", "Debug service initialized")
    self:Dev("debug", "  Enabled:", self.enabled)
    self:Dev("debug", "  Level:", self.level)
    self:Dev("debug", "  DEV_MODE:", self.DEV_MODE)
    
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
