# Modularity Checklist (04)

This checklist is a reusable tool to guide the refactoring of a single file or feature. Use it to ensure that every piece of the addon adheres to the new modular standards.

---

### File: `[Enter File Name Here]`

### Feature: `[Enter Feature Name Here]`

---

## ✅ 1. Code Isolation & Namespace

The goal is to ensure this file does not create or rely on unexpected global variables.

*   [ ] **Is all code wrapped in a local scope?**
    *   Every `.lua` file should start with `local AddonName, Addon = ...` and the main addon table should be passed in. This prevents the file from polluting the global `_G` table.

*   [ ] **Are all variables and functions `local` by default?**
    *   Unless a function truly needs to be accessed by another *legacy* module (before it's refactored), it should be declared `local`.

*   [ ] **Is the feature contained within its own sub-table?**
    *   Instead of attaching everything to the main `NextKey` table, the feature should live in a dedicated namespace, e.g., `NextKey.PUGHelper = {}`.

## ✅ 2. Communication & Coupling

This section ensures that the module communicates using events, not direct calls, breaking tight coupling.

*   [ ] **Does this module call functions in other modules directly?**
    *   If yes, replace the direct call (e.g., `NextKey.SomeModule:DoSomething()`) with a message: `NextKey:SendMessage("MSG_DO_SOMETHING")`.

*   [ ] **Does this module need to announce when it has completed a task or when its data has changed?**
    *   If yes, ensure it fires a clear, well-named message (e.g., `NextKey:SendMessage("PUGHELPER_NEW_GROUP_FOUND", groupInfo)`).

*   [ ] **Does this module listen for events from other modules?**
    *   Ensure it uses `NextKey:RegisterMessage("SOME_EVENT", handlerFunction)` to listen for messages, rather than having its functions called directly.

## ✅ 3. Separation of Concerns (UI vs. Logic)

This is the key to making both your code and UI more manageable and reusable.

*   [ ] **Does this file contain both UI-drawing code and data-processing logic?**
    *   If yes, plan to split them into two separate files (e.g., `core/myfeature.lua` for logic and `ui/myfeature.lua` for UI).

*   [ ] **Does the UI part of the module only handle UI tasks?**
    *   The UI module should be responsible for *displaying* data and capturing user *input*. It should not be responsible for fetching, saving, or processing that data. When a user clicks a button, the UI module should simply fire an event (e.g., `NextKey:SendMessage("USER_CLICKED_SAVE")`).

*   [ ] **Does the logic part of the module have zero knowledge of the UI?**
    *   The logic module should not know about frames, buttons, or textures. It should only deal with data. It listens for events from the UI and announces data changes via its own events. This allows you to completely replace the UI without touching the core logic.

## ✅ 4. Code Health & Simplicity

This addresses your goal of reducing bloat and keeping the code clean and understandable.

*   [ ] **Are there any functions or variables that are no longer used?**
    *   Search the codebase to see if the function is called anywhere. If not, remove it. Be brave! Version control is your safety net.

*   [ ] **Are there complex `if/else` chains or fallback methods that can be simplified?**
    *   Look for opportunities to simplify logic. If you have multiple functions that were attempts at a solution, choose the one that works and delete the others.

*   [ ] **Is the code clear and easy to understand?**
    *   Are the variable and function names descriptive? Does it need comments to explain what it's doing? ALL code should have comments explaining **both WHAT and WHY** for code readability (especially helpful for newer developers).
