# NextKey Debug System Rules

## 🚨 MANDATORY DEBUG SYSTEM USAGE

**Effective immediately, ALL debugging in NextKey MUST use the official debug system. No exceptions.**

---

## 🚨 MANDATORY REQUIREMENTS

### 1. NO DIRECT PRINT() USAGE
❌ **FORBIDDEN**: `print("Debug message")`
✅ **REQUIRED**: `Debug:User("system", "Debug message with context")`

### 2. NO CUSTOM DEBUG FUNCTIONS
❌ **FORBIDDEN**: Creating custom debug logging functions
✅ **REQUIRED**: Use the official DebugService API only

### 3. NO HARDCODED DEBUG LEVELS
❌ **FORBIDDEN**: Hardcoding debug behavior in functions
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

---

## 🎨 VISUAL STANDARDS

### 1. NO UNRENDERABLE CHARACTERS
❌ **FORBIDDEN**: Using emojis or special characters that do not render correctly in the default WoW chat UI (e.g., `✅`, `❌`, `⚠`).
✅ **REQUIRED**: Use plain ASCII text or WoW-supported texture strings for all visual indicators.

**Example**:
- **Bad**: `print("✅ Success!")`
- **Good**: `print("[OK] Success!")`
- **Best**: `print("|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t Success!")`