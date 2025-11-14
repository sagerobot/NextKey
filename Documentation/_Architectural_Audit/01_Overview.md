# Architectural Overview (01)

This document provides a high-level overview of the NextKey addon's architecture. It assesses the current structure, identifies core files that present a high dependency risk, and groups files into logical features.

## 1. Current Architectural Assessment

The addon follows a **Sequential Load-Order** architecture, which is common for World of Warcraft addons. The load order is explicitly defined in the `NextKey.toc` file. This approach has several implications:

*   **Implicit Dependencies:** Any file loaded can be accessed by any file loaded after it. This creates a chain of implicit dependencies that can be hard to track. For example, a function defined in an early file like `core/utils.lua` can be called from anywhere later in the load order.
*   **Global Namespace Reliance:** The architecture relies on a global addon table (likely `NextKey`) being created early in the load process (in `boot.lua`). Modules then attach themselves to this table, which serves as the primary method of sharing code.
*   **Tight Coupling:** Because there's no enforced boundary between different parts of the addon, features are likely "tightly coupled." This means a change in one system (e.g., how dungeon data is structured) could require changes in many other seemingly unrelated systems (e.g., UI components, tooltips, scoring logic).

The current structure is functional but not inherently modular. It's more like a single, large application than a collection of independent "Lego bricks." The goal of refactoring will be to introduce clear boundaries between the different logical parts of the addon.

## 2. Core / Hub Files (High Dependency Risk)

These files are loaded early and/or provide widely-used functionality, making them "hubs" that many other files depend on. Changes to these files carry the highest risk of breaking other parts of the addon.

*   **`boot.lua`**: The central nervous system of the addon. It likely creates the main `NextKey` table and initializes all major systems. Everything depends on this file.
*   **`core/config.lua`**: Loaded before `boot.lua`, this file establishes the configuration framework that the rest of the addon will use.
*   **`core/utils.lua`**: A classic "utility" file. These often become a collection of helper functions used throughout the entire addon, creating a widespread dependency.
*   **`core/constants.lua`**: Contains shared values (like spell IDs, item IDs, or text strings) that are likely referenced by many different features.
*   **`core/debugService.lua`**: Provides debugging functionality that is likely used across the entire codebase during development.
*   **`ui/main.lua` & `ui/mainWindow.lua`**: These files likely manage the main addon window and act as the central hub for all UI-related operations.

## 3. Logical Feature Groups

The codebase can be broken down into the following logical "features" or "systems." The goal of a refactor would be to make these groups as independent as possible.

| Feature Group           | Files                                                                                                                                                             | Description                                                                                                                              |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Core Infrastructure** | `boot.lua`, `core/config.lua`, `core/debugService.lua`, `core/utils.lua`, `core/constants.lua`, `core/slashCommands.lua`                                              | Foundational services that the entire addon is built upon. Manages initialization, configuration, and shared utilities.                |
| **Data & Services**     | `data/*`, `core/dungeonNameService.lua`, `core/season.lua`, `core/raiderio.lua`, `core/ioCalculator.lua`, `core/scoring.lua`, `core/adapters/*`, `core/playerIOData.lua` | Handles all data management, including static data (loot, portals), external data (Raider.IO), and core game data (seasons, dungeons). |
| **UI System**           | All files in `ui/`, such as `ui/main.lua`, `ui/mainWindow.lua`, `ui/viewManager.lua`, `ui/dungeonCards.lua`, `ui/lootWindow.lua`                                      | Responsible for drawing and managing all user interface elements, from the main window to individual cards and tooltips.                 |
| **Organizer Feature**   | All files in `core/organizer/` and `ui/organizer/`                                                                                                                  | A self-contained feature for organizing players and groups into a roster. This is a prime candidate for modularization.                |
| **PUG Helper Feature**  | `core/pugHelper*.lua`, `ui/pug*.lua`                                                                                                                              | A distinct feature designed to assist with finding and managing Pick-Up Groups (PUGs). Also a strong candidate for modularization.     |
| **Event Handling**      | `events/handlers.lua`                                                                                                                                             | Centralized hub for handling game events.                                                                                                |
| **Options Panel**       | All files in `options/`                                                                                                                                           | Manages the addon's configuration panel in the game's interface options.                                                                 |
| **Debugging Tools**     | All files in `debug/`                                                                                                                                             | Contains test suites, performance monitors, and other tools used for development and debugging.                                          |
