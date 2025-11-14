# Refactor Strategy (03)

This document proposes a strategy to refactor the NextKey addon towards a more modular, "Lego-like" architecture. It defines the communication patterns, recommends a starting point, and provides a specific plan for making features like the sorting algorithms extensible.

## 1. The Core Principle: Events Over Direct Calls

To achieve a decoupled, modular architecture, we will adopt one primary rule:

> **Modules must not call each other directly. Instead, they must communicate through a centralized event bus using `AceEvent-3.0`.**

This is the most critical change we can make. It breaks the "spaghetti code" connections between different parts of the addon.

*   **How it Works Now (Direct Call):**
    *   The `core/scoring.lua` module calculates a new score.
    *   It then directly calls a function in `ui/dungeonCards.lua`, like `NextKey.UI.DungeonCards:UpdateScore(dungeonID, newScore)`.
    *   This means `core/scoring.lua` **must know** that `ui/dungeonCards.lua` exists and has that specific function. They are tightly coupled.

*   **How it Will Work (Event-Based):**
    *   The `core/scoring.lua` module calculates a new score.
    *   It then fires a global event, like `NextKey:SendMessage("SCORE_UPDATED", dungeonID, newScore)`.
    *   `core/scoring.lua` does **not** know or care who is listening. Its job is done.
    *   Meanwhile, the `ui/dungeonCards.lua` module has registered itself as a listener for the `SCORE_UPDATED` event. When it hears the event, it wakes up and runs its own internal function to update the UI.
    *   This means `ui/dungeonCards.lua` knows about `core/scoring.lua`'s events, but the reverse is not true. This is a **one-way dependency**, which is much healthier.

This "publish-subscribe" (or "pub/sub") pattern is the key to creating independent "Lego bricks."

## 2. Recommended First Refactor: The PUG Helper

The best place to start refactoring is with a feature that is relatively self-contained and has the fewest deep dependencies on core systems.

**The PUG Helper feature is the ideal candidate.**

*   **Why?**
    *   It is a distinct, high-level feature. Its job is to help with Pick-Up Groups, which is separate from the core job of scoring and organizing existing groups.
    *   It has its own UI elements (`ui/pug*.lua`) and its own logic (`core/pugHelper*.lua`).
    *   It likely depends on core data (like player info), but the core systems probably don't depend on it.

*   **The Goal:**
    *   Convert the entire PUG Helper feature into a standalone module.
    *   It should be initialized from `boot.lua` but should not have any of its functions called directly by other modules.
    *   Anywhere the PUG Helper needs to communicate with the rest of the addon, it will use `NextKey:SendMessage()`.
    *   Anywhere the rest of the addon needs to trigger something in the PUG Helper, it will also use `NextKey:SendMessage()`.

By isolating this one feature first, you can practice the event-based pattern in a controlled environment and achieve a quick, satisfying win.

## 3. A Standard Pattern for Extensible Sorting Algorithms

You mentioned wanting to easily add new sorting algorithms. A modular approach makes this simple. We will create a "pluggable" system for sorting.

*   **Step 1: Define a "Sorting Module" Registry**
    *   In a core file (perhaps `core/organizer/sorting.lua`), we will create a central registry for sorting algorithms.
    *   `NextKey.SortingRegistry = {}`
    *   We will define a function to add new sorting methods:
        ```lua
        function NextKey:RegisterSortingAlgorithm(name, sortFunction)
            NextKey.SortingRegistry[name] = sortFunction
        end
        ```

*   **Step 2: Create Each Algorithm as a Separate File/Module**
    *   Each sorting algorithm will live in its own file, e.g., `core/organizer/sorting/byScore.lua`, `core/organizer/sorting/byKeyLevel.lua`, etc.
    *   Each file will be responsible for one thing: registering its sorting algorithm.
        ```lua
        -- core/organizer/sorting/byScore.lua
        local function SortByScore(groupA, groupB)
            -- ... logic to compare groups by score
            return groupA.score > groupB.score
        end

        NextKey:RegisterSortingAlgorithm("By Score", SortByScore)
        ```

*   **Step 3: Use the Registry in the UI**
    *   The UI that allows the user to select a sorting method will not have hardcoded buttons.
    *   Instead, it will dynamically populate its dropdown menu or buttons by iterating over the `NextKey.SortingRegistry` table.
    *   When the user selects an option, the UI will retrieve the correct function from the registry and use it to sort the data.

*   **The Benefit:**
    *   To add a new sorting algorithm, you simply create a new file, write the sorting logic, and register it. You never have to touch the core sorting system or the UI code again. The system is now truly "Lego-like."

This strategy provides a clear path to a more modular, maintainable, and extensible codebase.
