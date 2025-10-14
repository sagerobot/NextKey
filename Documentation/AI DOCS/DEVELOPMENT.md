# NextKey Development Guide

## 🚨 CRITICAL: This is the ONLY authoritative guide for AI agents working on NextKey. All code must follow these standards without exception.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [NextKey222 Architecture (MANDATORY)](#nextkey222-architecture-mandatory)
3. [Error Handling Standards (MANDATORY)](#error-handling-standards-mandatory)
4. [Performance Monitoring Standards (MANDATORY)](#performance-monitoring-standards-mandatory)
5. [Debug System Standards (MANDATORY)](#debug-system-standards-mandatory)
6. [File Organization & Code Structure](#file-organization--code-structure)
7. [Current Project Architecture](#current-project-architecture)
8. [Key Data Structures](#key-data-structures)
9. [WoW API Integration Patterns](#wow-api-integration-patterns)
10. [Testing Requirements](#testing-requirements)
11. [Critical Implementation Requirements](#critical-implementation-requirements)
12. [Code Review Checklist](#code-review-checklist)
13. [Reference Resources](#reference-resources)
14. [Non-Negotiable Requirements](#non-negotiable-requirements)

---

## 🔥 MANDATORY DEBUG SYSTEM - READ FIRST

**⚠️ CRITICAL**: NextKey uses a professional debug system. **ALL debugging MUST use this system. NO EXCEPTIONS.**

### 🚨 **ABSOLUTE REQUIREMENTS**
- **NEVER use `print()` - EVER**
- **NEVER use custom debug functions - EVER**
- **ALWAYS use `Debug:Error()`, `Debug:User()`, `Debug:Dev()`, `Debug:Trace()`**
- **ALWAYS include categories for DEV/TRACE calls**
- **ALL debug configuration via UI: `/nk config` → Debug System**

### ⚡ **QUICK START**
```lua
-- ✅ CORRECT - ALWAYS USE THESE
Debug:Error("Critical error message")                    -- Always shown
Debug:User("User-facing message")                      -- Release + Debug
Debug:Dev("category_name", "Development message")       -- Debug only
Debug:Trace("category_name", "Verbose trace message")   -- Debug only

-- ❌ FORBIDDEN - NEVER USE THESE
print("Debug message")  -- NEVER!
ChatFrame1:AddMessage("Debug")  -- NEVER!
MyCustomDebug("Debug")  -- NEVER!
```

### 📚 **REQUIRED READING**
1. **[DEBUG_SYSTEM.md](DEBUG_SYSTEM.md)** - **🔥 MANDATORY**
2. **[DEBUG_SYSTEM_USER_GUIDE.md](DEBUG_SYSTEM_USER_GUIDE.md)** - **📖 USER DOCUMENTATION**

### 🧪 **TESTING**
- Test your debug: `/script NextKeyRunTests()`
- Access debug UI: `/nk config` → Debug System
- Enable categories in Category Groups section

### 🚨 **ENFORCEMENT**
- Code WILL be rejected for debug violations
- NO exceptions, NO workarounds, NO alternatives
- Code review checklist includes debug compliance

---

## 🎯 Project Overview

NextKey is a World of Warcraft Mythic+ keystone optimization addon that helps groups intelligently choose their next dungeon run by analyzing party members' keystones, scores, and loot preferences.

### Core Purpose
- **Problem**: Groups waste time deciding which keystone to run next
- **Solution**: Automatic ranking of available keys with travel assistance
- **Result**: Groups spend <30 seconds deciding next key, improve scores efficiently

### Operating Modes
1. **Premade Group Mode** (Default): Full functionality with automatic key sharing, score syncing, complex sorting
2. **PUG Mode**: Simplified travel assistance focused interface for group finder groups

---

## 🏗️ NextKey222 Architecture (MANDATORY)

NextKey follows the **Details! Damage Meter architectural patterns** for enterprise-grade addon development. **ALL CODE must adhere to these patterns.**

### Core Architecture Principles
1. **NextKey222 Namespace**: All modules organized under NextKey222 hierarchy
2. **Module Registration**: Every component must register with `NextKey222.RegisterModule()`
3. **Error Resilience**: All critical operations use `NextKey222.SafeRun()` wrapper
4. **Performance Monitoring**: Critical paths profiled with `NextKey222.Performance`
5. **Centralized Debug**: Module-specific logging via `NextKey222.Debug`

### ✅ Architectural Consolidation Status (COMPLETED)
- **Previous**: Three-file boot process (preboot.lua → boot.lua → startup.lua)
- **Current**: Single boot.lua file following industry standards
- **Benefits**: Simplified architecture, better performance, easier maintenance
- **Implementation**: All major WoW addons use single initialization files

---

## 🔒 MANDATORY Module Registration Pattern

### ✅ REQUIRED Structure (NO EXCEPTIONS)
```lua
local _, NextKey222 = ...

-- MARK: Module Definition
local MyModule = {}
NextKey222.MyModule = MyModule

-- Register with module system (MANDATORY - CODE WILL BE REJECTED WITHOUT THIS)
NextKey222.RegisterModule("MyModule", MyModule)

-- MARK: Module State
local isInitialized = false
local moduleData = {}

-- MARK: Public Interface
-- Initialization function (REQUIRED for all modules)
function MyModule:Initialize()
    if isInitialized then return true end
    
    NextKey222.Debug:Print("startup", "MyModule initializing...")
    
    local success = NextKey222.SafeRun(function()
        -- Initialize module data
        moduleData = {}
        
        -- Setup event handlers if needed
        -- Register callbacks if needed
        
        isInitialized = true
        return true
    end, "MyModule:Initialize")
    
    NextKey222.Debug:Print("startup", "MyModule initialization", success and "successful" or "failed")
    return success
end

function MyModule:IsInitialized()
    return isInitialized
end

-- All public functions must use SafeRun for critical operations
function MyModule:DoSomethingCritical(param1, param2)
    if not isInitialized then
        NextKey222.Debug:Print("mymodule", "Module not initialized")
        return false
    end
    
    return NextKey222.SafeRun(function()
        -- Validate inputs
        if not param1 or not param2 then
            error("Invalid parameters provided")
        end
        
        -- Critical operation logic
        NextKey222.Debug:Print("mymodule", "Processing critical operation")
        local result = processData(param1, param2)
        return result
    end, "MyModule:DoSomethingCritical")
end

-- MARK: Private Implementation
local function processData(data1, data2)
    -- Helper logic - private functions use snake_case
    return combinedData
end

-- MARK: Event Handlers (if needed)
function MyModule:OnEventName(...)
    if not isInitialized then return end
    
    NextKey222.SafeRun(function()
        NextKey222.Debug:Print("mymodule", "Handling event with args:", ...)
        -- Event handling logic
    end, "MyModule:OnEventName")
end

return MyModule
```

### ❌ FORBIDDEN Patterns (CODE WILL BE REJECTED)
- Direct global assignment without NextKey222 registration
- Functions without error handling in critical paths
- Modules that don't implement Initialize() function
- Code outside NextKey222 namespace hierarchy
- Silent failures without debug output
- Missing input validation

---

## 🛡️ Error Handling Standards (MANDATORY)

### ✅ REQUIRED: SafeRun for All Critical Operations
```lua
-- For any function that could fail and affect addon stability
function MyModule:ProcessKeystoneData(keystoneData)
    return NextKey222.SafeRun(function()
        -- Always validate inputs first
        if not keystoneData or type(keystoneData) ~= "table" then
            error("Invalid keystone data: " .. tostring(keystoneData))
        end
        
        if not keystoneData.dungeonID or not keystoneData.level then
            error("Missing required keystone fields")
        end
        
        -- Process the data
        local result = computeKeystoneMetrics(keystoneData)
        NextKey222.Debug:Print("keystones", "Processed keystone", keystoneData.dungeonID, "level", keystoneData.level)
        return result
    end, "MyModule:ProcessKeystoneData")
end

-- Validation functions with proper fallback
function MyModule:ValidatePlayerData(playerData)
    if not playerData then
        NextKey222.Debug:Print("mymodule", "Player data is nil, using defaults")
        return MyModule:GetDefaultPlayerData()
    end
    
    if type(playerData) ~= "table" then
        NextKey222.Debug:Print("mymodule", "Invalid player data type:", type(playerData))
        return MyModule:GetDefaultPlayerData()
    end
    
    -- Validate required fields
    local required = {"name", "class", "realm"}
    for _, field in ipairs(required) do
        if not playerData[field] then
            NextKey222.Debug:Print("mymodule", "Missing required field:", field)
            return false
        end
    end
    
    return true
end

-- Always provide graceful degradation
function MyModule:GetPlayerScoreWithFallback(playerName)
    -- Try primary data source
    local score = NextKey222.SafeRun(function()
        return RaiderIOAPI.GetPlayerScore(playerName)
    end, "MyModule:GetPlayerScoreWithFallback:RaiderIO")
    
    if score then
        NextKey222.Debug:Print("mymodule", "Got RaiderIO score for", playerName, ":", score)
        return score
    end
    
    -- Try LibOpenRaid fallback
    score = NextKey222.SafeRun(function()
        return LibOpenRaidAPI.GetPlayerScore(playerName)
    end, "MyModule:GetPlayerScoreWithFallback:LibOpenRaid")
    
    if score then
        NextKey222.Debug:Print("mymodule", "Got LibOpenRaid score for", playerName, ":", score)
        return score
    end
    
    -- Use Blizzard API as last resort
    score = NextKey222.SafeRun(function()
        return BlizzardAPI.GetPlayerScore(playerName)
    end, "MyModule:GetPlayerScoreWithFallback:Blizzard")
    
    if score then
        NextKey222.Debug:Print("mymodule", "Got Blizzard score for", playerName, ":", score)
        return score
    end
    
    -- Final fallback
    NextKey222.Debug:Print("mymodule", "No score found for", playerName, "using default")
    return 0
end
```

---

## ⚡ Performance Monitoring Standards (MANDATORY)

### ✅ REQUIRED: Profile All Critical Paths
```lua
function MyModule:ExpensiveCalculation(largeDataset)
    -- Start profiling before any expensive operation
    NextKey222.Performance:StartProfile("MyModule:ExpensiveCalculation")
    
    local result = NextKey222.SafeRun(function()
        -- Validate input size
        if not largeDataset or #largeDataset == 0 then
            return {}
        end
        
        NextKey222.Debug:Print("mymodule", "Processing", #largeDataset, "items")
        
        local processedData = {}
        
        -- Process data efficiently
        for i = 1, #largeDataset do
            local item = largeDataset[i]
            if item and item.valid then
                processedData[#processedData + 1] = calculateMetrics(item)
            end
        end
        
        NextKey222.Debug:Print("mymodule", "Processed", #processedData, "valid items")
        return processedData
    end, "MyModule:ExpensiveCalculation")
    
    -- Always stop profiling
    NextKey222.Performance:StopProfile("MyModule:ExpensiveCalculation")
    return result or {}
end

-- Cache expensive lookups
local scoreCache = {}
local cacheTimeout = 300 -- 5 minutes

function MyModule:GetCachedPlayerScore(playerName)
    local now = GetTime()
    local cached = scoreCache[playerName]
    
    -- Return cached result if still valid
    if cached and (now - cached.timestamp) < cacheTimeout then
        NextKey222.Debug:Print("mymodule", "Using cached score for", playerName)
        return cached.score
    end
    
    -- Fetch new score with profiling
    NextKey222.Performance:StartProfile("MyModule:GetCachedPlayerScore:Fetch")
    
    local score = NextKey222.SafeRun(function()
        return fetchPlayerScore(playerName)
    end, "MyModule:GetCachedPlayerScore")
    
    NextKey222.Performance:StopProfile("MyModule:GetCachedPlayerScore:Fetch")
    
    -- Cache the result
    if score then
        scoreCache[playerName] = {
            score = score,
            timestamp = now
        }
        NextKey222.Debug:Print("mymodule", "Cached new score for", playerName, ":", score)
    end
    
    return score or 0
end
```

### Performance Guidelines
- **Cache frequently accessed data** (player scores, dungeon info)
- **Use table pools** for frequent create/destroy cycles
- **Batch UI updates** instead of individual changes
- **Profile before optimizing** - measure first
- **Throttle communication messages** to prevent spam
- **Minimize string concatenations** in loops

---

## 🐛 Debug System Standards (MANDATORY - ENHANCED)

**⚠️ CRITICAL**: NextKey uses a professional debug system with UI controls. **NEVER use direct print() statements.**

### 🔥 **ENHANCED DEBUG SYSTEM ARCHITECTURE**

NextKey now includes a **comprehensive professional debug system** with:
- ✅ **5-level debug system** with UI-based configuration
- ✅ **23 organized categories** in 5 logical groups
- ✅ **Advanced filtering** with patterns, time ranges, and thresholds
- ✅ **Performance monitoring** with microsecond precision
- ✅ **Preset system** for quick configuration switching
- ✅ **Professional UI** accessible via `/nk config` → Debug System

### 📋 **MANDATORY DEBUG USAGE PATTERNS**

#### **NEW UI-First Approach**
```lua
-- ❌ OLD - Manual debug configuration
if self.db.global.debug.enabled then
    print("Debug message")
end

-- ✅ NEW - UI-controlled debugging
Debug:Dev("category", "Debug message")  -- Controlled via UI
```

#### **Enhanced Debug Levels with UI Controls**
```lua
-- All levels now controlled via UI: /nk config → Debug System → Control Panel
Debug:Error("Critical error")     -- Always shown, UI toggle has no effect
Debug:User("User message")        -- Shown based on UI level setting
Debug:Dev("category", "Dev msg")  -- Controlled by UI level + category toggle
Debug:Trace("category", "Trace")  -- Controlled by UI level + category toggle
```

### 🎯 **ENHANCED CATEGORY SYSTEM**

Categories are now organized into logical groups in the UI:

#### **Core Systems** Group
- `startup` - Addon loading and initialization
- `events` - Event handling and dispatching
- `performance` - Performance monitoring and metrics
- `database` - SavedVariables and data persistence
- `config` - Settings loading and management
- `options` - Options panel interactions

#### **Communications** Group
- `communications` - Core communication system
- `comms` - Low-level message handling
- `libopenraid` - LibOpenRaid integration
- `raiderio` - RaiderIO data operations
- `blizzard` - Blizzard API interactions

#### **Features & UI** Group
- `ui` - Main user interface
- `components` - UI components and widgets
- `tooltip` - Tooltip system
- `teleport` - Teleport functionality
- `lootwindow` - Loot tracking interface
- `profiles` - Profile management

#### **Data Processing** Group
- `keystones` - Keystone data processing
- `season` - Seasonal information
- `IOCalculator` - Score calculations
- `ioc` - Detailed calculation operations
- `fakeplayerservice` - Testing data simulation

#### **Testing & Development** Group
- `test` - Testing utilities
- `debug` - Debug system self-monitoring

### ✅ **ENHANCED REQUIRED USAGE PATTERNS**

#### **Level 1: ERROR - Critical Errors**
```lua
-- Use for addon-breaking errors
Debug:Error("FakePlayerService failed to initialize!")
Debug:Error("Database corruption detected:", errorMessage)

-- ❌ NEVER use direct print
print("NextKey: Error - Something broke")  -- FORBIDDEN

-- ✅ ALWAYS use debug system
Debug:Error("Something broke:", errorDetails)
```

#### **Level 2: USER - User Messages**
```lua
-- Use for helpful user information
Debug:User("NextKey v" .. version .. " loaded successfully")
Debug:User("Refreshed keystone data")

-- ❌ NEVER leave debug strings in user messages
print("NextKey TELEPORT DEBUG: processing...")  -- FORBIDDEN

-- ✅ ALWAYS use user-appropriate messages
Debug:User("Teleport button ready")
```

#### **Level 3: DEV - Development Logging**
```lua
-- Use for development logging (controlled by UI)
Debug:Dev("keystones", "Processing keystone:", dungeonID, "level:", level)
Debug:Dev("ui", "Refreshing display with", count, "items")

-- ❌ NEVER use manual debug checks
if self.db.global.debug.enabled then  -- FORBIDDEN
    print("NextKey: Debug info")
end

-- ✅ ALWAYS use automatic category checking
Debug:Dev("category", "Debug info")  -- Controlled by UI
```

#### **Level 4: TRACE - Ultra-Verbose**
```lua
-- Use for detailed tracing (controlled by UI)
Debug:Trace("ui", "RefreshUI() called")
Debug:Trace("profiles", "BuildProfile() entry, player:", playerName)
```

### 🚫 **STRICTLY FORBIDDEN PATTERNS**

```lua
-- ❌ NEVER use direct print() - EVER
print("NextKey: Something happened")

-- ❌ NEVER use ChatFrame for debug
ChatFrame1:AddMessage("NextKey: Debug")

-- ❌ NEVER use manual debug checks
if self.db.global.debug.enabled then
    print("Debug message")
end

-- ❌ NEVER create custom debug functions
function MyCustomDebug(msg)
    print(msg)  -- FORBIDDEN
end

-- ❌ NEVER hardcode debug behavior
if isDebugMode then  -- FORBIDDEN - use UI controls
    Debug:Dev("category", "message")
end
```

### 🎯 **NEW UI ACCESS METHODS**

```lua
-- Access debug system via UI (REQUIRED METHOD)
/nk config → Debug System

-- Test the debug system
/script NextKeyRunTests()

-- Enable specific categories via UI
-- /nk config → Debug System → Category Groups → [Group Name] → [Category]
```

### 🧪 **ENHANCED TESTING REQUIREMENTS**

```lua
-- Test all debug levels via UI
/nk config → Debug System → Control Panel
-- Set debug level to test
-- Enable relevant categories
-- Test functionality

-- Run comprehensive test suite
/script NextKeyRunTests()

-- Test performance monitoring
-- Enable performance monitoring in UI
-- Perform operations that should be tracked
-- Check Statistics & Monitoring section
```

### 📋 **ENHANCED CODE REVIEW CHECKLIST**

#### **Debug System Compliance (MANDATORY)**
- [ ] **NO direct print() calls anywhere in code**
- [ ] **NO custom debug functions**
- [ ] **ALL DEV/TRACE calls have proper categories**
- [ ] **Appropriate debug levels used**
- [ ] **No manual debug state checking**
- [ ] **No hardcoded debug behavior**
- [ ] **UI controls used for all debug configuration**

#### **Professional Debug System Usage**
- [ ] **Performance monitoring used for expensive operations**
- [ ] **Appropriate categories from organized groups**
- [ ] **Context included in all debug messages**
- [ ] **User messages are user-friendly**
- [ ] **Error messages are clear and actionable**

### 🚨 **CRITICAL ENFORCEMENT POLICY**

**Code WILL be REJECTED for ANY debug system violations:**
- ❌ Any direct `print()` usage
- ❌ Any custom debug function
- ❌ Missing debug categories
- ❌ Manual debug state checking
- ❌ Hardcoded debug behavior

**NO EXCEPTIONS - NO WORKAROUNDS - NO ALTERNATIVES**

**📚 COMPLETE DEBUG SYSTEM DOCUMENTATION:**
- **[DEBUG_SYSTEM.md](DEBUG_SYSTEM.md)** - **🔥 MANDATORY READING**
- **[DEBUG_SYSTEM_USER_GUIDE.md](DEBUG_SYSTEM_USER_GUIDE.md)** - **📖 USER DOCUMENTATION**

**🎯 DEBUG SYSTEM IS MANDATORY - USE IT PROPERLY OR DON'T USE DEBUG AT ALL**

---

## 📁 File Organization & Code Structure

### MARK Comments for Navigation
All files must use `-- MARK:` comments for VS Code navigation:

```lua
-- MARK: Module Definition
-- Core module setup and registration

-- MARK: Public Interface  
-- Public API methods and properties

-- MARK: Private Implementation
-- Internal helper functions and state

-- MARK: Event Handlers
-- Event callback implementations

-- MARK: State Management
-- Data manipulation and state updates

-- MARK: UI Components (for UI files)
-- Frame creation and layout

-- MARK: Communication (for comm files)
-- Message handling and protocol

-- MARK: Data Validation
-- Input validation and sanitization

-- MARK: Performance Optimizations
-- Caching and performance-critical code
```

### Naming Conventions (STRICTLY ENFORCED)
- **Functions**: `snake_case` - `process_keystone_data()`, `update_player_score()`
- **Variables**: `snake_case` - `player_data`, `keystone_list`, `current_season`  
- **Modules**: `PascalCase` - `Keystones`, `Communications`, `IOCalculator`
- **Constants**: `UPPER_SNAKE_CASE` - `MAX_KEY_LEVEL`, `COMM_PREFIX`, `DEFAULT_TIMEOUT`
- **Private functions**: Prefix with underscore - `_validate_input()`, `_cache_result()`
- **Event handlers**: Start with "On" - `OnKeystoneUpdate()`, `OnPlayerJoined()`

---

## 🗂️ Current Project Architecture

### File Structure
```
NextKey/
├── boot.lua                    # Single consolidated initialization
├── core/
│   ├── keystones.lua          # Keystone detection and management
│   ├── communications.lua     # Inter-player messaging
│   ├── ioCalculator.lua       # Score calculations
│   ├── config.lua             # Configuration management
│   ├── constants.lua          # Shared constants
│   ├── utils.lua              # Utility functions
│   ├── season.lua             # Season data handling
│   └── raiderio.lua           # RaiderIO integration
├── ui/
│   ├── main.lua               # Main UI interface
│   ├── dungeonCards.lua       # Card-based dungeon display
│   └── teleport.lua           # Travel assistance UI
├── options/
│   ├── main.lua               # AceConfig options
│   └── mythic_plus.lua        # M+ specific options
├── data/
│   └── portals.lua            # Dungeon teleport data
└── events/
    └── handlers.lua           # Event handling
```

### Critical Dependencies
- **Hard Dependency**: RaiderIO addon for score data
- **Ace3 Framework**: AceAddon, AceComm, AceDB, AceConfig, AceGUI
- **Optional**: LibOpenRaid for additional score sources

---

## 💾 Key Data Structures

### Communication Payload (AceComm Protocol)
```lua
{
    -- Core keystone data (REQUIRED)
    keystone = {
        dungeonID = number,      -- Valid dungeon ID from current season
        level = number,          -- Key level (2-30)
        ownerName = string       -- Full player name with realm
    },
    
    -- Score tracking (REQUIRED)
    scores = {
        [dungeonID] = {
            bestScore = number,         -- Best score for this dungeon
            bestLevel = number,         -- Highest level completed
            weeklyBest = number,        -- Best run this week
            totalRuns = number          -- Total attempts
        }
    },
    
    -- Live run data (OPTIONAL)
    liveRun = {
        dungeonID = number,
        level = number,
        timedSuccess = boolean,
        completionTime = number,
        affixes = { number }            -- Current week's affixes
    },
    
    -- Loot preferences (OPTIONAL)
    lootTargets = {
        [itemID] = {
            priority = number,          -- 1-3, higher is more important  
            attempts = number,          -- Number of runs for this item
            lastSeen = timestamp        -- Last time item was available
        }
    },
    
    -- Dungeon preferences (OPTIONAL)
    preferences = {
        [dungeonID] = {
            liked = boolean,
            disliked = boolean,
            reason = string,            -- Required if disliked
            lastUpdated = timestamp
        }
    },
    
    -- Protocol metadata (REQUIRED)
    meta = {
        version = string,               -- Addon version for compatibility
        timestamp = number,             -- Message timestamp  
        sequenceID = number            -- For ordering/deduplication
    }
}
```

### SavedVariables Structure (NextKeyDB)
```lua
{
    global = {
        -- Leader settings
        leaderSettings = {
            autoSuggestEnabled = boolean,
            defaultSortMode = string,        -- "smart", "score", "coverage", "level", "loot"
            suggestionDelay = number         -- Seconds to wait before suggesting
        },
        
        -- UI preferences  
        ui = {
            cardViewEnabled = boolean,
            animationsEnabled = boolean,
            framePosition = { x = number, y = number },
            frameSize = { width = number, height = number }
        },
        
        -- Communication settings
        comms = {
            throttleInterval = number,       -- Message throttling
            maxRetries = number,            -- Failed message retry limit
            timeout = number                -- Response timeout
        },
        
        -- Debug settings
        debug = {
            enabled = boolean,
            categories = {
                keystones = boolean,
                comms = boolean,
                ui = boolean,
                -- ... all debug categories
            }
        }
    },
    
    char = {
        -- Character-specific run history
        liveRuns = {
            [dungeonID] = {
                level = number,
                timedSuccess = boolean,
                completionTime = number,
                timestamp = number
            }
        },
        
        -- Targeted loot items
        targetedItems = {
            [itemID] = {
                priority = number,
                dungeonID = number,
                attempts = number
            }
        },
        
        -- Per-dungeon run counts for loot tracking
        dungeonRunCounts = {
            [dungeonID] = number
        },
        
        -- Personal dungeon preferences
        dungeonPreferences = {
            [dungeonID] = {
                liked = boolean,
                disliked = boolean,
                reason = string,
                lastUpdated = timestamp
            }
        }
    }
}
```

### Validation Rules (STRICTLY ENFORCED)
```lua
-- Keystone validation
function validateKeystoneData(keystone)
    if not keystone or type(keystone) ~= "table" then
        return false, "Keystone must be a table"
    end
    
    if not keystone.dungeonID or type(keystone.dungeonID) ~= "number" then
        return false, "dungeonID must be a number"
    end
    
    if keystone.dungeonID < 1 or keystone.dungeonID > 1000 then
        return false, "dungeonID out of valid range"
    end
    
    if not keystone.level or type(keystone.level) ~= "number" then
        return false, "level must be a number"
    end
    
    if keystone.level < 2 or keystone.level > 30 then
        return false, "level must be between 2-30"
    end
    
    if not keystone.ownerName or type(keystone.ownerName) ~= "string" then
        return false, "ownerName must be a string"
    end
    
    if not string.match(keystone.ownerName, "^[^%-]+%-.+$") then
        return false, "ownerName must include realm (Name-Realm format)"
    end
    
    return true, "Valid keystone"
end

-- Score validation  
function validateScoreData(scores)
    if not scores or type(scores) ~= "table" then
        return false, "Scores must be a table"
    end
    
    for dungeonID, scoreData in pairs(scores) do
        if type(dungeonID) ~= "number" then
            return false, "Dungeon ID must be number"
        end
        
        if not scoreData.bestScore or scoreData.bestScore < 0 then
            return false, "bestScore must be non-negative"
        end
        
        if scoreData.weeklyBest and scoreData.weeklyBest > scoreData.bestScore then
            return false, "weeklyBest cannot exceed bestScore"
        end
        
        if scoreData.totalRuns and scoreData.totalRuns < 0 then
            return false, "totalRuns must be non-negative"
        end
    end
    
    return true, "Valid scores"
end
```

---

## 🎮 WoW API Integration Patterns

### Event Handling (MANDATORY Pattern)
```lua
-- Event registration through NextKey addon
function MyModule:RegisterEvents()
    local nextkey = NextKey222.Addon
    if not nextkey then
        NextKey222.Debug:Print("events", "NextKey addon not available for event registration")
        return false
    end
    
    -- Register events with proper error handling
    NextKey222.SafeRun(function()
        nextkey:RegisterEvent("CHALLENGE_MODE_COMPLETED", function(...)
            MyModule:OnMythicPlusCompleted(...)
        end)
        
        nextkey:RegisterEvent("GROUP_ROSTER_UPDATE", function(...)  
            MyModule:OnGroupRosterUpdate(...)
        end)
        
        nextkey:RegisterEvent("BAG_UPDATE", function(...)
            MyModule:OnBagUpdate(...)
        end)
        
        NextKey222.Debug:Print("events", "MyModule events registered successfully")
    end, "MyModule:RegisterEvents")
    
    return true
end

-- Event handlers with full error protection
function MyModule:OnMythicPlusCompleted(event, ...)
    NextKey222.Debug:Print("events", "Mythic+ completed event received")
    
    NextKey222.SafeRun(function()
        -- Process completion data
        local completionData = self:ProcessCompletionData(...)
        if completionData then
            -- Update player scores
            self:UpdatePlayerScores(completionData)
            
            -- Trigger keystone detection
            self:TriggerKeystoneDetection()
            
            -- Send updated data to party
            NextKey222.Communications:BroadcastUpdate()
        end
    end, "MyModule:OnMythicPlusCompleted")
end
```

### API Usage Patterns
```lua
-- Keystone detection with multiple API fallbacks
function MyModule:DetectPlayerKeystone()
    NextKey222.Performance:StartProfile("MyModule:DetectPlayerKeystone")
    
    local keystone = NextKey222.SafeRun(function()
        -- Try Blizzard API first
        local challengeModeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        if challengeModeMapID then
            local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()  
            if keystoneLevel then
                NextKey222.Debug:Print("keystones", "Found keystone via Blizzard API:", challengeModeMapID, "level", keystoneLevel)
                return {
                    dungeonID = challengeModeMapID,
                    level = keystoneLevel,
                    ownerName = UnitName("player") .. "-" .. GetRealmName(),
                    source = "BlizzardAPI"
                }
            end
        end
        
        -- Fallback to bag scanning
        return self:ScanBagsForKeystone()
    end, "MyModule:DetectPlayerKeystone")
    
    NextKey222.Performance:StopProfile("MyModule:DetectPlayerKeystone")
    return keystone
end

-- Bag scanning with proper item link parsing
function MyModule:ScanBagsForKeystone()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local keystone = NextKey222.SafeRun(function()
                    return self:ParseKeystoneLink(itemLink)
                end, "MyModule:ScanBagsForKeystone:ParseLink")
                
                if keystone then
                    NextKey222.Debug:Print("keystones", "Found keystone in bag", bag, "slot", slot, ":", keystone.dungeonID, "level", keystone.level)
                    return keystone
                end
            end
        end
    end
    
    NextKey222.Debug:Print("keystones", "No keystone found in bags")
    return nil
end
```

---

## 🧪 Testing Requirements

### Module Testing Pattern
```lua
-- Test framework integration (minimal test requirements)
function MyModule:RunSelfTest()
    NextKey222.Debug:Print("startup", "Running MyModule self-test")
    
    local tests = {
        {
            name = "Initialize",
            test = function() return self:Initialize() end
        },
        {
            name = "ValidateInput", 
            test = function()
                return self:ValidateInput({valid = true}) and
                       not self:ValidateInput(nil) and
                       not self:ValidateInput({invalid = true})
            end
        },
        {
            name = "ProcessData",
            test = function()
                local result = self:ProcessSampleData()
                return result and #result > 0
            end
        }
    }
    
    local passed, failed = 0, 0
    
    for _, test in ipairs(tests) do
        local success = NextKey222.SafeRun(test.test, "MyModule:SelfTest:" .. test.name)
        if success then
            passed = passed + 1
            NextKey222.Debug:Print("startup", "✅ Test passed:", test.name)
        else
            failed = failed + 1
            NextKey222.Debug:Print("startup", "❌ Test failed:", test.name)
        end
    end
    
    NextKey222.Debug:Print("startup", "MyModule self-test complete:", passed, "passed,", failed, "failed")
    return failed == 0
end

-- Integration testing helpers
function MyModule:GenerateTestData()
    return {
        testKeystones = {
            {dungeonID = 375, level = 15, ownerName = "TestPlayer-Realm"},
            {dungeonID = 376, level = 18, ownerName = "TestPlayer2-Realm"}
        },
        testPlayers = {
            {name = "TestPlayer-Realm", class = "PALADIN", score = 2500},
            {name = "TestPlayer2-Realm", class = "HUNTER", score = 2200}
        }
    }
end
```

### Testing Checklists

#### Basic Functionality Testing
- [ ] Module loads without errors (`/console scriptErrors 1`)
- [ ] All slash commands work (`/nk`, `/nk config`)
- [ ] UI frames open/close properly
- [ ] Debug categories produce output when enabled
- [ ] SavedVariables persist across reloads

#### Party Integration Testing  
- [ ] Communication sync works in 5-player party
- [ ] Cross-realm messaging functions properly
- [ ] Mixed addon versions handled gracefully
- [ ] Leader vs member functionality correct
- [ ] Disconnection/reconnection handled properly

#### Data Validation Testing
- [ ] Invalid keystone data rejected gracefully
- [ ] Missing RaiderIO data handled with fallbacks
- [ ] Extreme values (level 30+ keys) processed correctly
- [ ] Empty/nil inputs don't cause errors
- [ ] Malformed communication messages filtered out

#### Performance Testing
- [ ] Large party datasets process within 1 second
- [ ] UI updates feel responsive under load
- [ ] Memory usage remains stable over long sessions
- [ ] No frame rate impact during combat
- [ ] Cache systems prevent redundant calculations

---

## 🚨 Critical Implementation Requirements

### 1. NEVER Write Code That Doesn't Follow NextKey222 Patterns
- **Registration**: Every module MUST call `NextKey222.RegisterModule()`
- **Error Handling**: Every critical function MUST use `NextKey222.SafeRun()`
- **Debug Integration**: Every module MUST support debug categories
- **Performance**: Every expensive operation MUST be profiled
- **Validation**: Every public function MUST validate inputs

### 2. Communication Protocol Compliance
- Always use versioned payloads for backward compatibility
- Implement proper throttling (max 1 message per second per player)
- Handle message ordering with sequence IDs
- Validate all incoming data before processing
- Provide graceful degradation when comms fail

### 3. UI Standards Compliance
- Support UI scaling (all sizes from 0.5x to 2.0x)
- Provide tooltips for all interactive elements
- Use consistent color scheme throughout
- Support colorblind accessibility
- Implement smooth animations for state changes
- Handle frame positioning persistence

### 4. Performance Requirements
- Initial addon load: <2 seconds
- UI updates: <100ms response time
- Communication sync: <1 second for full party
- Memory usage: <10MB baseline, <50MB peak
- Zero impact on combat frame rates

### 5. Error Recovery Requirements
- Individual module failures must not crash addon
- Network failures must not break UI functionality
- Invalid data must be sanitized or rejected
- Missing dependencies must be handled gracefully
- User errors must provide helpful feedback

---

## 🎯 Code Review Checklist

Before committing ANY code, verify ALL items:

### Architecture Compliance
- [ ] Module registered with `NextKey222.RegisterModule()`
- [ ] Module implements `Initialize()` function that returns boolean
- [ ] All critical operations wrapped in `NextKey222.SafeRun()`
- [ ] Performance-critical paths use `NextKey222.Performance` profiling
- [ ] **Debug system uses ONLY Debug:Error/User/Dev/Trace (NO direct print() calls)**
- [ ] **Debug level appropriate (ERROR/USER for production, DEV/TRACE for development)**
- [ ] Debug category names match defined categories
- [ ] Code exists within NextKey222 namespace hierarchy
- [ ] No direct global assignments outside namespace

### Error Handling & Validation
- [ ] All function inputs validated at entry point
- [ ] Graceful fallback behavior for all error conditions
- [ ] Critical errors use `Debug:Error()` (always shown to users)
- [ ] **No manual debug checks (no `if db.global.debug.enabled then` patterns)**
- [ ] Meaningful error messages for debugging
- [ ] No silent failures - all errors logged appropriately
- [ ] Proper handling of nil/missing data
- [ ] Resource cleanup in error paths

### Code Quality
- [ ] Functions use snake_case naming convention
- [ ] Modules use PascalCase naming convention
- [ ] Constants use UPPER_SNAKE_CASE
- [ ] Private functions prefixed with underscore
- [ ] Proper MARK comments for code navigation
- [ ] Self-documenting variable and function names

### Integration
- [ ] WoW API usage follows established patterns
- [ ] Event handlers properly registered and unregistered
- [ ] Communication payloads follow documented schema
- [ ] SavedVariables integration uses proper defaults
- [ ] Ace3 library usage follows conventions

### Performance & Testing
- [ ] No obvious performance bottlenecks
- [ ] Appropriate caching for expensive operations
- [ ] Memory leaks prevented (proper cleanup)
- [ ] **Dev/Trace debug removed or verified to strip with DEV_MODE = false**
- [ ] Basic functionality tested in-game
- [ ] Error conditions tested and handled
- [ ] Debug output tested at all levels (NONE/ERROR/USER/DEV/TRACE)

### 🚨 Release Checklist (CRITICAL)
- [ ] **DEV_MODE = false set in core/debugService.lua**
- [ ] No `print()` statements remain in code (search entire project)
- [ ] No "DEBUG:" strings in user-facing messages
- [ ] User messages (Debug:User) are appropriate for production
- [ ] Error messages (Debug:Error) are clear and actionable
- [ ] Test with `/nk debug level 0` (NONE) - should be silent
- [ ] Test with `/nk debug level 2` (USER) - only helpful messages

---

## 📚 Reference Resources

### Required Reading
- **Debug System**: `DEBUG_SYSTEM.md`
- **Fake Players**: `FAKE_PLAYERS.md`
- **Design**: `DESIGN.md`
- **WoW API Reference**: Current expansion API documentation
- **Project Roadmap**: `DESIGN.md` roadmap section
- **Current Plan**: `PLAN.md` for active cleanup phases

### Key Files to Understand
- `boot.lua` - Consolidated initialization system
- `core/keystones.lua` - Keystone detection and management example
- `core/communications.lua` - Inter-player messaging protocol
- `ui/main.lua` - Main UI implementation patterns

### Debug Commands
- `/nk debug enable <category>` - Enable debug category
- `/nk debug disable <category>` - Disable debug category  
- `/nk perf report` - Show performance profiling results
- `/console scriptErrors 1` - Enable Lua error display
- `/framestack` - Debug UI frame hierarchy
- `/fstack` - Alternative frame stack tool

---

## 🎯 Summary: Non-Negotiable Requirements

**Every line of code you write MUST:**

1. **✅ Register properly** - `NextKey222.RegisterModule()` for all modules
2. **🛡️ Handle errors** - `NextKey222.SafeRun()` for critical operations  
3. **📊 Monitor performance** - Profile expensive operations
4. **🐛 Support debugging** - Use appropriate debug categories
5. **📏 Follow naming** - snake_case functions, PascalCase modules
6. **🏗️ Respect architecture** - Stay within NextKey222 namespace
7. **✨ Validate inputs** - Never trust external data
8. **🎯 Provide fallbacks** - Graceful degradation always
9. **📝 Document with MARK** - Code navigation comments
10. **🧪 Include basic tests** - At minimum, Initialize() validation

**Code that violates these standards WILL BE REJECTED.**

This document is the **single source of truth** for NextKey development. When in doubt, refer to these patterns and standards.