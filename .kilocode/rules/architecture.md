# NextKey Architecture & Naming Conventions

## 🏗️ NextKey222 Architecture (MANDATORY)

All code MUST adhere to the **Details! Damage Meter architectural patterns**.

### Core Architecture Principles
1.  **NextKey222 Namespace**: All modules organized under `NextKey222` hierarchy.
2.  **Module Registration**: Every component **MUST** register with `NextKey222.RegisterModule()`.
3.  **Error Resilience**: All critical operations **MUST** use `NextKey222.SafeRun()` wrapper.
4.  **Performance Monitoring**: Critical paths should be profiled with `NextKey222.Performance`.

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