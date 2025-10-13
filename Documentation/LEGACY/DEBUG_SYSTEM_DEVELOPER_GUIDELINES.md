# NextKey Debug System - Developer Guidelines & Standards

## 🚨 MANDATORY DEBUG SYSTEM USAGE

**Effective immediately, ALL debugging in NextKey MUST use the official debug system. No exceptions.**

This document establishes the authoritative standards for debugging in the NextKey codebase. All developers MUST follow these guidelines without exception.

---

## 📋 TABLE OF CONTENTS

1. [Mandatory Requirements](#mandatory-requirements)
2. [Debug System API Reference](#debug-system-api-reference)
3. [Category Usage Guidelines](#category-usage-guidelines)
4. [Code Examples by Scenario](#code-examples-by-scenario)
5. [Migration from Old Debug Methods](#migration-from-old-debug-methods)
6. [Code Review Checklist](#code-review-checklist)
7. [Performance Guidelines](#performance-guidelines)
8. [Testing and Validation](#testing-and-validation)

---

## 🚨 MANDATORY REQUIREMENTS

### 1. NO DIRECT PRINT() USAGE
❌ **FORBIDDEN**: `print("Debug message")`
✅ **REQUIRED**: `Debug:User("system", "Debug message with context")`

### 2. NO CUSTOM DEBUG FUNCTIONS
❌ **FORBIDDEN**: Creating custom debug logging functions
✅ **REQUIRED**: Use the official DebugService API only

### 3. NO HARDCODED DEBUG LEVELS
❌ **FORBIDDEN`: Hardcoding debug behavior in functions
✅ **REQUIRED**: All debug controls through the UI system

### 4. CATEGORY IS MANDATORY
❌ **FORBIDDEN**: `Debug:Dev("Message without category")`
✅ **REQUIRED**: `Debug:Dev("proper_category", "Message with category")`

### 5. UI CONTROLS ONLY
❌ **FORBIDDEN**: Slash commands for debug control
✅ **REQUIRED**: All debug configuration via `/nk config` → Debug System

---

## 🔧 DEBUG SYSTEM API REFERENCE

### Basic Usage (Always Available)
```lua
-- ERROR LEVEL - Always shown, even in production
Debug:Error("Critical system failure:", errorMessage)

-- USER LEVEL - Shown in release and debug
Debug:User("Feature completed successfully")
```

### Development Usage (Requires Category)
```lua
-- DEV LEVEL - Development messages
Debug:Dev("category_name", "Processing player data:", playerName)

-- TRACE LEVEL - Ultra-verbose tracing
Debug:Trace("category_name", "Function called with args:", arg1, arg2)
```

### Performance Monitoring
```lua
-- Start timer
local timerId = Debug:StartPerformanceTimer("operation_name", "category")

-- ... your code here ...

-- End timer (automatically logs if thresholds exceeded)
local measurement = Debug:EndPerformanceTimer(timerId)

-- Or wrap entire function
local result = Debug:MeasurePerformance("operation_name", "category", function()
    -- ... your code here ...
    return result
end)
```

### Advanced Usage
```lua
-- Check if debugging is enabled (performance optimization)
if Debug.enabled and Debug.categories.your_category then
    -- Expensive debug operations
end

-- Performance logging (for performance warnings)
Debug:Performance("operation", "Performance warning message", "category", level)
```

---

## 📂 CATEGORY USAGE GUIDELINES

### Use Existing Categories FIRST
Before creating new debug output, check these existing categories:

#### Core Systems
- `startup` - Addon loading, initialization
- `events` - Event handling and dispatching
- `performance` - Performance monitoring and metrics
- `database` - SavedVariables and data persistence
- `config` - Settings loading and management
- `options` - Options panel interactions

#### Communications
- `communications` - Core communication system
- `comms` - Low-level message handling
- `libopenraid` - LibOpenRaid integration
- `raiderio` - RaiderIO data operations
- `blizzard` - Blizzard API interactions

#### Features & UI
- `ui` - Main user interface
- `components` - UI components and widgets
- `tooltip` - Tooltip system
- `teleport` - Teleport functionality
- `lootwindow` - Loot tracking interface
- `profiles` - Profile management

#### Data Processing
- `keystones` - Keystone data processing
- `season` - Seasonal information
- `IOCalculator` - Score calculations
- `ioc` - Detailed calculation operations
- `fakeplayerservice` - Testing data simulation

#### Testing & Development
- `test` - Testing utilities
- `debug` - Debug system self-monitoring

### Creating NEW Categories
If you MUST create a new category:

1. **Check existing categories first** - 95% of cases fit existing categories
2. **Use descriptive names** - `playerdata` not `pd`
3. **Add to DebugService.categories** - Register in the core system
4. **Document usage** - Explain when and why to use this category
5. **Update documentation** - Add to category mapping documents

```lua
-- In core/debugService.lua, add to categories table:
categories = {
    -- ... existing categories ...
    new_category = false,  -- Add your new category here
}
```

---

## 💻 CODE EXAMPLES BY SCENARIO

### Scenario 1: Function Entry/Exit
```lua
function ProcessPlayerData(playerName, data)
    -- Function entry
    Debug:Trace("keystones", "ProcessPlayerData() called for:", playerName)
    
    -- Validate input
    if not playerName or not data then
        Debug:Error("ProcessPlayerData: Invalid input - playerName:", playerName, "data:", data)
        return nil
    end
    
    -- Processing logic
    Debug:Dev("keystones", "Processing", #data, "entries for", playerName)
    
    -- Performance monitoring for expensive operations
    local timerId = Debug:StartPerformanceTimer("process_player_data", "keystones")
    
    -- ... your processing logic ...
    
    Debug:EndPerformanceTimer(timerId)
    Debug:Dev("keystones", "Processed player data for:", playerName, "result:", result)
    
    return result
end
```

### Scenario 2: Event Handling
```lua
local function OnPlayerJoinedParty(event, playerName)
    Debug:Dev("events", "Party join event received for:", playerName)
    
    -- Validate player
    if not playerName or playerName == "" then
        Debug:Error("OnPlayerJoinedParty: Invalid player name received")
        return
    end
    
    -- Update UI
    Debug:Dev("ui", "Updating party display for new member:", playerName)
    UpdatePartyDisplay()
    
    -- Notify other systems
    Debug:Dev("communications", "Notifying group systems about new member:", playerName)
    NotifyGroupSystems(playerName)
    
    Debug:User(playerName, "joined the party")  -- User-facing message
end
```

### Scenario 3: Error Handling
```lua
function LoadKeystoneData()
    Debug:Dev("database", "Loading keystone data from SavedVariables")
    
    local success, data = pcall(function()
        return NextKeyDB.keystones or {}
    end)
    
    if not success then
        Debug:Error("Failed to load keystone data:", data)
        Debug:User("Unable to load keystone data. Please restart the addon.")
        return {}
    end
    
    Debug:Dev("database", "Loaded", #data, "keystone entries")
    return data
end
```

### Scenario 4: Performance Critical Code
```lua
function UpdateScoreCalculations()
    -- Only perform debug operations if enabled
    if Debug.enabled and Debug.categories.ioc then
        Debug:Dev("ioc", "Starting score calculation update")
        local timerId = Debug:StartPerformanceTimer("score_update", "ioc")
        
        -- ... calculation logic ...
        
        Debug:EndPerformanceTimer(timerId)
    else
        -- Production path - no debug overhead
        -- ... calculation logic ...
    end
end
```

### Scenario 5: Network Communication
```lua
function SendKeystoneData(targetPlayer, keystoneData)
    Debug:Dev("communications", "Sending keystone data to:", targetPlayer)
    
    -- Validate data
    if not keystoneData or not keystoneData.level then
        Debug:Error("SendKeystoneData: Invalid keystone data:", keystoneData)
        return false
    end
    
    -- Compress data if large
    local dataSize = #tostring(keystoneData)
    if dataSize > 1000 then
        Debug:Dev("communications", "Compressing large keystone data (", dataSize, " bytes)")
        keystoneData = CompressData(keystoneData)
    end
    
    -- Send data
    local success = SendCommMessage("NEXTKEY_KEystone", keystoneData, "WHISPER", targetPlayer)
    
    if success then
        Debug:Dev("communications", "Successfully sent keystone data to:", targetPlayer)
    else
        Debug:Error("Failed to send keystone data to:", targetPlayer)
    end
    
    return success
end
```

---

## 🔄 MIGRATION FROM OLD DEBUG METHODS

### Step 1: Find All Debug Code
Search for these patterns in your code:
- `print(`
- `ChatFrame1:AddMessage(`
- `DEFAULT_CHAT_FRAME:AddMessage(`
- Custom debug function calls

### Step 2: Replace with Debug System

#### Before (OLD WAY)
```lua
print("Loading player data...")
ChatFrame1:AddMessage("Error: Invalid data", 1, 0, 0)  -- Red text
MyCustomDebug("Processing complete")
```

#### After (CORRECT WAY)
```lua
Debug:Dev("database", "Loading player data...")
Debug:Error("Invalid data")  -- Automatically colored appropriately
Debug:Dev("category_name", "Processing complete")
```

### Step 3: Add Appropriate Categories
```lua
-- Before
print("UI updated")

-- After
Debug:Dev("ui", "UI updated")

-- Before
print("Network message received")

-- After
Debug:Dev("communications", "Network message received")
```

### Step 4: Add Context and Structure
```lua
-- Before
print("Processing keystone")

-- After
Debug:Dev("keystones", "Processing keystone for player:", playerName, "level:", level)
```

---

## ✅ CODE REVIEW CHECKLIST

### Reviewer MUST check for:

#### Debug System Compliance
- [ ] No direct `print()` calls
- [ ] No custom debug functions
- [ ] All debug calls use official DebugService API
- [ ] All DEV/TRACE calls have proper categories
- [ ] Error messages use `Debug:Error()`
- [ ] User messages use `Debug:User()`

#### Category Usage
- [ ] Appropriate category for each debug call
- [ ] No hardcoded debug behavior
- [ ] Performance-critical code checks debug state
- [ ] Existing categories used when possible

#### Best Practices
- [ ] Contextual information in debug messages
- [ ] Performance monitoring for expensive operations
- [ ] Proper error handling with debug output
- [ ] User-facing messages use USER level

### Code MUST be rejected if:
- ❌ Any direct `print()` calls found
- ❌ Custom debug functions used
- ❌ Missing categories on DEV/TRACE calls
- ❌ Hardcoded debug behavior
- ❌ No context in debug messages

---

## ⚡ PERFORMANCE GUIDELINES

### Always Use Performance Checks
```lua
-- GOOD - Performance aware
if Debug.enabled and Debug.categories.your_category then
    -- Expensive debug operations
    local expensiveData = ExpensiveCalculation()
    Debug:Dev("your_category", "Result:", expensiveData)
end

-- BAD - Always executes expensive operations
local expensiveData = ExpensiveCalculation()
Debug:Dev("your_category", "Result:", expensiveData)
```

### Use Performance Monitoring
```lua
-- For expensive operations, always monitor performance
local timerId = Debug:StartPerformanceTimer("expensive_operation", "category")

-- ... your expensive code ...

Debug:EndPerformanceTimer(timerId)
```

### Cache Debug Checks
```lua
-- Cache the check if used multiple times
local debugEnabled = Debug.enabled and Debug.categories.your_category

if debugEnabled then
    Debug:Dev("your_category", "Step 1 complete")
end

-- ... later ...

if debugEnabled then
    Debug:Dev("your_category", "Step 2 complete")
end
```

---

## 🧪 TESTING AND VALIDATION

### Mandatory Testing Steps

#### 1. Enable Your Category
```lua
-- In game: /nk config → Debug System → Category Groups → [Your Group] → [Your Category]
Debug:EnableCategory("your_category")
```

#### 2. Test All Debug Levels
```lua
-- Test each level works
Debug:Error("Test error message")
Debug:User("Test user message")
Debug:Dev("your_category", "Test dev message")
Debug:Trace("your_category", "Test trace message")
```

#### 3. Test Performance Monitoring
```lua
-- Test performance tracking works
local timer = Debug:StartPerformanceTimer("test_operation", "your_category")
-- ... do something ...
Debug:EndPerformanceTimer(timer)
```

#### 4. Run Test Suite
```lua
-- Run comprehensive tests
/script NextKeyRunTests()
```

### Validation Requirements
- ✅ All debug messages appear when category is enabled
- ✅ Messages are hidden when category is disabled
- ✅ Performance monitoring tracks operations correctly
- ✅ No performance impact when debug is disabled
- ✅ Error messages always appear regardless of settings

---

## 🚨 ENFORCEMENT POLICY

### Automatic Detection
The build system and test suite will automatically detect:
- Direct `print()` calls
- Custom debug function usage
- Missing debug categories
- Hardcoded debug behavior

### Code Review Requirements
- All code changes MUST be reviewed for debug system compliance
- Any violation MUST be fixed before merge
- Reviewers MUST use the provided checklist

### Consequences
- Code with debug violations will be rejected
- Repeated violations will require additional review
- Debug system compliance is a condition of contribution

---

## 📞 GETTING HELP

### Debug System Issues
1. Check the UI: `/nk config` → Debug System
2. Run tests: `/script NextKeyRunTests()`
3. Check documentation: `DEBUG_SYSTEM_USER_GUIDE.md`
4. Ask for help in development channels

### Category Questions
1. Check existing categories first
2. Review category mapping documentation
3. Ask senior developers for guidance
4. Document new categories appropriately

---

## 🔗 QUICK REFERENCE

### Essential Debug Calls
```lua
Debug:Error("Critical error message")                    -- Always shown
Debug:User("User-facing message")                      -- Release + Debug
Debug:Dev("category", "Development message")           -- Debug only
Debug:Trace("category", "Verbose trace message")       -- Debug only

-- Performance monitoring
local timer = Debug:StartPerformanceTimer("operation", "category")
Debug:EndPerformanceTimer(timer)

-- Performance wrapping
local result = Debug:MeasurePerformance("operation", "category", function()
    return ExpensiveFunction()
end)
```

### UI Access
```
/nk config → Debug System tab
```

### Testing
```lua
/script NextKeyRunTests()
```

---

**REMEMBER**: The debug system is MANDATORY for ALL debugging in NextKey. No exceptions, no workarounds, no alternatives. Use it properly or use it not at all.

This system ensures consistent, professional debugging across the entire codebase while maintaining excellent performance and user experience.