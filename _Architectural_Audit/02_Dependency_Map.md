# Dependency Map & Hotspots (02)

This document maps the addon's dependency chain based on the `NextKey.toc` load order. It identifies "Hotspots" (files that are high-risk dependencies) and discusses potential "Circular Risks" that can arise from the current architecture.

## 1. Load Order Dependency Chain

The `.toc` file defines a sequential load order. Each file can be thought of as a link in a chain, where any link can "see" all the links that came before it. This creates a top-to-bottom dependency flow.

Here is a simplified view of the load order, grouped by function:

1.  **Libraries (`embeds.xml`)**:
    *   Loads all Ace3 and other third-party libraries. These are the foundational building blocks.

2.  **Pre-Boot Core (`core/config.lua`, `core/debugService.lua`, `core/debugUI.lua`)**:
    *   These files are loaded *before* the main addon object is created. They are **critical hotspots** because they set up foundational systems that `boot.lua` itself depends on.

3.  **The Bootstrapper (`boot.lua`)**:
    *   This is the **primary hotspot**. It initializes the addon's main table (e.g., `NextKey`) and likely loads and initializes all major modules. Everything loaded after this point depends on `boot.lua` having run successfully.

4.  **Core Systems & Services**:
    *   Includes files like `core/slashCommands.lua`, `core/utils.lua`, `core/constants.lua`, `core/raiderio.lua`, and the various adapter modules.
    *   These provide the core logic and services that the UI and other features will consume.

5.  **UI Foundation**:
    *   Loads foundational UI modules like `ui/frameRegistry.lua`, `ui/utilities.lua`, and `ui/components.lua`. These need to exist before any visible UI elements can be created.

6.  **Feature Modules (Organizer, PUG Helper)**:
    *   The files for these specific features are loaded. For example, `core/organizer/state.lua` and `core/pugHelper.lua`. They depend on the core systems and UI foundation.

7.  **Main UI & Event Handlers**:
    *   The main UI is initialized (`ui/main.lua`, `ui/mainWindow.lua`), and event handlers are registered (`events/handlers.lua`). This typically happens near the end of the load process to ensure all necessary systems are available.

8.  **Options & Debugging**:
    *   The addon's options panel (`options/main.lua`) and debugging tools (`debug/init.lua`) are loaded last.

## 2. Identified Hotspots

A "Hotspot" is a file that, if changed, has a high probability of causing bugs in many other parts of the addon. These are the files that everything else depends on.

*   **`boot.lua`**: The **#1 hotspot**. It's the central hub that connects everything. A single error here will likely prevent the entire addon from loading.
*   **`core/config.lua`**: As the foundation for the addon's configuration, any changes to how options are defined or retrieved will affect every feature that uses those options.
*   **`core/utils.lua`**: Utility files are classic hotspots. A change to a single, widely-used function in this file could have unintended consequences across dozens of other files.
*   **`core/constants.lua`**: If a constant value is changed, any part of the code that relies on the old value will break. This is especially risky for values that are used in logic (e.g., `if status == MY_CONSTANT then ...`).
*   **`ui/frameRegistry.lua`**: If this file is responsible for creating and managing UI frames, it's a critical UI hotspot. The entire UI likely depends on it to access and manipulate frames.
*   **`events/handlers.lua`**: This file is the central dispatch for game events. If the logic for a core event (like `PLAYER_LOGIN` or `GROUP_ROSTER_UPDATE`) is changed, it can affect any system that relies on that event.

## 3. Circular Dependency Risks

A circular dependency occurs when `Module A` depends on `Module B`, and `Module B` simultaneously depends on `Module A`. In a sequential load order like the one used here, this isn't technically possible at load time (you can't have `A.lua` load `B.lua` and vice-versa).

However, **logical circular dependencies** are a significant risk. Here’s how they can happen:

*   **Scenario**:
    1.  `core/dungeonCards.lua` is loaded. It contains logic for managing the data of a dungeon card.
    2.  `ui/dungeonCards.lua` is loaded later. It contains the logic for rendering the visual dungeon card and handling user input.
    3.  The `ui` module needs to call functions in the `core` module to get data (`ui` -> `core`).
    4.  But what if an action in the `core` module (e.g., data updating) needs to immediately trigger a redraw in the `ui` module? The `core` module would then need to call a function in the `ui` module (`core` -> `ui`).

*   **The Risk**: This creates a situation where the two modules are tightly intertwined and cannot be separated. The `core` logic is no longer independent of the `ui`. You can't, for example, easily create a new UI without rewriting the `core` logic because the `core` logic explicitly knows about and calls the `ui`.

This is the classic "spaghetti code" problem. The solution, which will be detailed in the `03_Refactor_Strategy.md` file, is to break these direct calls and use an intermediary, like an event bus (`AceEvent-3.0`), so that modules can announce changes without needing to know who is listening.
