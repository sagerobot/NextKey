# NextKey AI Coding Agent Instructions

## Big Picture Architecture
- All code is organized under the `NextKey222` namespace. Modules must register via `NextKey222.RegisterModule()` and use `NextKey222.SafeRun()` for error resilience.
- The project follows the Details! Damage Meter architectural patterns: strict module boundaries, centralized error handling, and performance monitoring via `NextKey222.Performance`.
- Initialization is handled in a single `boot.lua` file. All modules are loaded and registered here.
- Debugging is strictly enforced via the custom DebugService. **Never use `print()` or custom debug functions.** Use `Debug:Error()`, `Debug:User()`, `Debug:Dev(category, ...)`, and `Debug:Trace(category, ...)` only.
- Debug categories are mandatory for DEV/TRACE calls. See `core/debugService.lua` and [DEBUG_SYSTEM.md](Documentation/AI DOCS/DEBUG_SYSTEM.md) for category lists and usage.

## Developer Workflows
- **Debugging:** Use `/nk config` → Debug System tab to enable/disable categories. All debug output must use the official API. Run `/script NextKeyRunTests()` for automated debug tests.
- **Testing:** Use the fake player system (`DEV DOCS/FAKE_PLAYERS.md`) and `/script NextKeyRunTests()` for validation. All debug messages must be validated with categories enabled/disabled.
- **Error Handling:** All critical functions must use `NextKey222.SafeRun()` wrappers. Silent failures and missing debug output are forbidden.
- **Performance:** Profile expensive operations with `Debug:StartPerformanceTimer()` and `Debug:EndPerformanceTimer()`. Only run debug code if `Debug.enabled` and the relevant category is enabled.

## Project-Specific Conventions
- **Naming:**
  - Functions/variables: `snake_case`
  - Modules: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Private functions: prefix with `_`
  - Event handlers: start with `On`
- **MARK Comments:** Use `-- MARK:` comments for navigation in all files.
- **Module Structure:**
  - Each module must implement `:Initialize()` and register itself.
  - All public functions in modules must use SafeRun for critical operations.

## Integration Points & Dependencies
- **External Libraries:**
  - Ace3, RaiderIO, LibOpenRaid, LibStub, CallbackHandler (see `Libs/` and `Library Docs/`)
  - All communication with external APIs must use the appropriate adapter in `core/adapters/`.
- **Data Flow:**
  - Keystone, score, and profile data are processed in `core/` and surfaced via UI in `ui/`.
  - Debug and test data can be simulated using the fake player system.

## Key Files & Directories
- `boot.lua`: Main entry point and initialization
- `core/`: Main business logic modules
- `core/debugService.lua`: Debug system implementation
- `Documentation/AI DOCS/DEBUG_SYSTEM.md`: Debug system rules and API
- `.kilocode/rules/architecture.md`: Architecture and naming conventions
- `DEV DOCS/FAKE_PLAYERS.md`: Fake player system for testing
- `Libs/`: External libraries
- `ui/`: User interface components

## Example Patterns
```lua
-- Module registration
local _, NextKey222 = ...
local MyModule = {}
NextKey222.MyModule = MyModule
NextKey222.RegisterModule("MyModule", MyModule)

-- Debug output
Debug:Dev("keystones", "Processing keystone for player:", playerName)

-- Error handling
return NextKey222.SafeRun(function()
  -- ...
end, "MyModule:FunctionName")
```

## Enforcement
- Code violating debug, error handling, or architecture rules will be rejected.
- All contributions must pass the debug system test suite and code review checklist.

---
**For more details, see:**
- [DEBUG_SYSTEM.md](Documentation/AI DOCS/DEBUG_SYSTEM.md)
- [DEVELOPMENT.md](Documentation/AI DOCS/DEVELOPMENT.md)
- [Architecture Standards](.kilocode/rules/architecture.md)
- [Debug System User Guide](README/DEBUG_SYSTEM_USER_GUIDE.md)

---
*If any section is unclear or missing, please provide feedback to improve these instructions.*
