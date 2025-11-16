# NextKey Architecture & Naming Conventions

## 🏗️ NextKey222 Architecture (MANDATORY)

All code MUST adhere to the **Details! Damage Meter architectural patterns**.

### Core Architecture Principles
1.  **NextKey222 Namespace**: All modules organized under `NextKey222` hierarchy.
2.  **Module Registration**: Every component **MUST** register with `NextKey222.RegisterModule()`.
3.  **Error Resilience**: All critical operations **MUST** use `NextKey222.SafeRun()` wrapper.
4.  **Performance Monitoring**: Critical paths should be profiled with `NextKey222.Performance`.
5.  **Separation of Concerns**: UI modules handle display/input only. Business logic lives in core services. UI must never contain data processing or business rules.

---

## 🔒 MANDATORY Module Registration Pattern

```lua
local _, NextKey222 = ...

-- MARK: Module Definition
local MyModule = {}
NextKey222.MyModule = MyModule

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("MyModule", MyModule)

function MyModule:Initialize()
    -- Initialization logic
    return true
end
```

---

## 🛡️ Error Handling Standard (MANDATORY)

All functions that can fail or impact addon stability must be wrapped in `SafeRun`.

```lua
function MyModule:ProcessData(data)
    return NextKey222.SafeRun(function()
        if not data then
            error("Invalid data provided")
        end
        -- ... processing logic ...
    end, "MyModule:ProcessData")
end
```

---

## 📏 Naming Conventions (STRICTLY ENFORCED)

-   **Functions**: `snake_case` (e.g., `process_keystone_data()`)
-   **Variables**: `snake_case` (e.g., `player_data`, `keystone_list`)
-   **Modules**: `PascalCase` (e.g., `Keystones`, `IOCalculator`)
-   **Constants**: `UPPER_SNAKE_CASE` (e.g., `MAX_KEY_LEVEL`, `COMM_PREFIX`)
-   **Private functions**: Prefix with underscore (e.g., `_validate_input()`)
-   **Event handlers**: Start with "On" (e.g., `OnKeystoneUpdate()`)

---

## 📂 MARK Comments for Navigation

All files **MUST** use `-- MARK:` comments for code navigation.

```lua
-- MARK: Module Definition
-- MARK: Public Interface
-- MARK: Private Implementation
-- MARK: Event Handlers
```

---

## 🧹 Code Health Standards (MANDATORY)

### Dead Code Removal
-   **Remove unused functions/variables**: Search codebase to confirm usage before removing
-   **Version control is your safety net**: Be brave about deletion

### Code Simplification
-   **Simplify complex if/else chains**: Use patterns (strategy, registry, state machines)
-   **Extract complex logic**: Move to well-named functions

### Comments & Documentation
-   **Comment Philosophy**: ALL code should have comments explaining **both WHAT and WHY**
    -   **WHAT**: Describe what the code does (helps new developers understand flow)
    -   **WHY**: Explain rationale, design decisions, non-obvious choices
-   **Example**:
    ```lua
    -- WHAT: Cache the player's dungeon score using their name and dungeon ID as key
    -- WHY: Score lookups are expensive (multiple API calls), so we cache to avoid repeated lookups within the same refresh cycle
    local cacheKey = string.format("%s:%d:%d", playerName, dungeonID, self.refreshCycleID)
    if self.scoreLookupCache[cacheKey] then
        return self.scoreLookupCache[cacheKey]
    end
    ```
-   **When to Skip Comments**: Only skip for trivial, self-explanatory code like `local count = 0`

### Self-Documenting Code
-   **Use descriptive names**: `CalculatePlayerIOGainForDungeon()` not `calc()`
-   **Break complex operations into named functions**: Each function should have a clear, single purpose
-   **Prefer clarity over cleverness**: Readable code > clever one-liners