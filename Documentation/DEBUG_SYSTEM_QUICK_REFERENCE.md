# NextKey Debug System - Quick Reference

## 🚀 IMMEDIATE START

**Access**: `/nk config` → Debug System tab  
**Test**: `/script NextKeyRunTests()`  
**Help**: Read `DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md`

---

## ⚡ ESSENTIAL DEBUG CALLS

### Always Use These
```lua
-- ERROR - Always shown, even in production
Debug:Error("Critical failure:", errorMessage)

-- USER - User-facing messages (release + debug)
Debug:User("Feature completed successfully")

-- DEV - Development messages (requires category)
Debug:Dev("category_name", "Processing data:", data)

-- TRACE - Verbose tracing (requires category)
Debug:Trace("category_name", "Function called with:", arg1, arg2)
```

### Performance Monitoring
```lua
-- Timer-based
local timer = Debug:StartPerformanceTimer("operation", "category")
-- ... your code ...
Debug:EndPerformanceTimer(timer)

-- Function wrapping
local result = Debug:MeasurePerformance("operation", "category", function()
    return ExpensiveFunction()
end)
```

---

## 📂 AVAILABLE CATEGORIES

### Core Systems
- `startup` - Addon loading and initialization
- `events` - Event handling and dispatching
- `performance` - Performance monitoring
- `database` - SavedVariables and data persistence
- `config` - Settings loading and management
- `options` - Options panel interactions

### Communications
- `communications` - Core communication system
- `comms` - Low-level message handling
- `libopenraid` - LibOpenRaid integration
- `raiderio` - RaiderIO data operations
- `blizzard` - Blizzard API interactions

### Features & UI
- `ui` - Main user interface
- `components` - UI components and widgets
- `tooltip` - Tooltip system
- `teleport` - Teleport functionality
- `lootwindow` - Loot tracking interface
- `profiles` - Profile management

### Data Processing
- `keystones` - Keystone data processing
- `season` - Seasonal information
- `IOCalculator` - Score calculations
- `ioc` - Detailed calculation operations
- `fakeplayerservice` - Testing data simulation

### Testing & Development
- `test` - Testing utilities
- `debug` - Debug system self-monitoring

---

## ❌ FORBIDDEN PATTERNS

### NEVER Use These
```lua
-- ❌ FORBIDDEN
print("Debug message")
ChatFrame1:AddMessage("Debug")
DEFAULT_CHAT_FRAME:AddMessage("Debug")
MyCustomDebug("Debug")
Debug:Dev("Message without category")  -- Missing category
```

### ALWAYS Use These Instead
```lua
-- ✅ CORRECT
Debug:User("Debug message")
Debug:Dev("category", "Debug message with category")
```

---

## 🎯 COMMON SCENARIOS

### Function Debugging
```lua
function ProcessData(data)
    Debug:Trace("keystones", "ProcessData() called with:", #data, "entries")
    
    if not data then
        Debug:Error("ProcessData: Invalid data received")
        return nil
    end
    
    Debug:Dev("keystones", "Processing data...")
    local result = ExpensiveOperation(data)
    Debug:Dev("keystones", "Processing complete, result:", result)
    
    return result
end
```

### Error Handling
```lua
local success, result = pcall(function()
    return RiskyOperation()
end)

if not success then
    Debug:Error("Operation failed:", result)
    Debug:User("Unable to complete operation. Please try again.")
    return false
end

Debug:Dev("category", "Operation completed successfully")
```

### Performance Monitoring
```lua
function UpdateUI()
    if Debug.enabled and Debug.categories.ui then
        local timer = Debug:StartPerformanceTimer("ui_update", "ui")
        
        -- UI update logic...
        
        Debug:EndPerformanceTimer(timer)
    else
        -- Production path - no debug overhead
        -- UI update logic...
    end
end
```

---

## 🔧 UI CONTROLS

### Access Debug Settings
1. Type `/nk config` or Escape → Interface → Addons → NextKey
2. Click "Debug System" tab
3. Configure settings as needed

### Essential UI Sections
- **Control Panel**: Master toggle and debug level
- **Category Groups**: Enable/disable specific categories
- **Presets**: Quick configuration switching
- **Performance Monitoring**: Track operation performance
- **Statistics**: View usage and performance metrics

### Common Presets
- **Minimal**: Errors only
- **Standard**: Errors + user messages
- **Verbose**: All development messages
- **UI Testing**: Focus on interface debugging
- **Performance Testing**: Focus on performance tracking

---

## 🧪 TESTING YOUR DEBUG CODE

### Enable Your Category
1. `/nk config` → Debug System → Category Groups
2. Find your category group
3. Enable the category
4. Test your functionality

### Test All Levels
```lua
-- Test each level works
Debug:Error("Test error")
Debug:User("Test user")
Debug:Dev("your_category", "Test dev")
Debug:Trace("your_category", "Test trace")
```

### Run Test Suite
```lua
/script NextKeyRunTests()
```

### Validate Performance
```lua
-- Test performance monitoring
local timer = Debug:StartPerformanceTimer("test", "your_category")
-- Do work...
Debug:EndPerformanceTimer(timer)
```

---

## ⚡ PERFORMANCE TIPS

### Check Debug State First
```lua
-- GOOD - Performance aware
if Debug.enabled and Debug.categories.your_category then
    local expensiveData = ExpensiveCalculation()
    Debug:Dev("your_category", "Data:", expensiveData)
end
```

### Cache Debug Checks
```lua
-- GOOD - Cache the check
local debugEnabled = Debug.enabled and Debug.categories.your_category

if debugEnabled then
    Debug:Dev("your_category", "Step 1")
end

-- Later...
if debugEnabled then
    Debug:Dev("your_category", "Step 2")
end
```

---

## 🚨 TROUBLESHOOTING

### Messages Not Appearing
1. Check if debug is enabled: Control Panel → Enable Debug Mode
2. Check debug level: Set to appropriate level (DEV/TRACE for development)
3. Check category: Enable your category in Category Groups
4. Check filtering: Disable advanced filtering temporarily

### Performance Impact
1. Use "Optimize for Production" button
2. Disable performance monitoring
3. Run maintenance: Statistics → Optimization Tools → Perform Maintenance
4. Check for expensive debug operations

### UI Issues
1. Reload UI: `/reload`
2. Check for Lua errors
3. Run test suite: `/script NextKeyRunTests()`

---

## 📋 CODE REVIEW CHECKLIST

### Must Pass All Checks
- [ ] No direct `print()` calls
- [ ] No custom debug functions
- [ ] All DEV/TRACE calls have categories
- [ ] Appropriate categories used
- [ ] Performance-aware for expensive operations
- [ ] Context included in debug messages

### Reviewer Must Reject For
- ❌ Any `print()` usage
- ❌ Missing debug categories
- ❌ Custom debug functions
- ❌ Hardcoded debug behavior

---

## 🔗 ESSENTIAL DOCUMENTATION

- **User Guide**: `DEBUG_SYSTEM_USER_GUIDE.md`
- **Developer Guidelines**: `DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md`
- **Implementation Details**: `DEBUG_SYSTEM_IMPLEMENTATION_SUMMARY.md`
- **Category Mapping**: `DEBUG_CATEGORY_MAPPING.md`

---

## 🎯 ONE-LINER REMINDERS

- **Always use Debug:Error() for errors**
- **Always use Debug:User() for user messages**
- **Always include category for DEV/TRACE**
- **Never use print() - ever**
- **Check debug state for expensive operations**
- **Use UI for all debug configuration**
- **Test with /script NextKeyRunTests()**

---

**Remember**: The debug system is MANDATORY. Use it properly or don't use debug at all.