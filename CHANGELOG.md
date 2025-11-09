# Changelog

All notable changes to this project will be documented in this file.

## [v0.5.3] - 2025-11-09
### ⚡️ Optimizations
- **Memory Leak Fix:** Removed a problematic `OnUpdate` script from a performance optimization module that was causing significant memory leaks over long play sessions. This makes the addon much more stable.

## [v0.5.2] - 2025-11-09
### 🧪 Developer Features
- **Custom Fake Player Builder:** To accelerate testing, a new UI was added to build and customize fake players with specific roles, classes, and Raider.IO scores. Includes real-time validation to prevent impossible player configurations.
- **Options Menu Refactor:** The addon's options menu was restructured to isolate developer tools from the main user settings, creating a cleaner and more intuitive experience for end-users.

## [v0.5.1] - 2025-11-06
### ✨ Enhancements
- **M+ Group Organizer Animations:** Added smooth, animated transitions for players being moved into and out of M+ groups in the Organizer UI. This makes the drag-and-drop experience feel more responsive and polished.

## [v0.5.0] - 2025-11-05
### 🚀 Features
- **M+ Group Organizer - Network Handshake:** Implemented a new handshake protocol using `AceComm` to ensure that all players in a group have the same version of the addon and their Organizer data is in sync. This is a critical step for coordinated group building.

## [v0.4.0] - 2025-11-05
### 🚀 Features
- **M+ Group Organizer - Centralized State:** A new `OrganizerState` module was created to act as a single source of truth for the M+ Group Organizer. It uses a hybrid persistence model, saving data to the SavedVariables and synchronizing it across the group. This prevents data conflicts and ensures consistency.

## [v0.3.4] - 2025-11-04
### ✨ Enhancements
- **M+ Group Organizer - Modular UI:** The main `rosterBoard` for the Organizer was broken down into smaller, more manageable modules. This improves maintainability and makes it easier to add new features to the Organizer in the future.

## [v0.3.3] - 2025-11-03
### ⚡️ Optimizations
- **Spec Preference Consolidation:** The code responsible for generating player spec preferences was consolidated into a single, more efficient function, reducing code duplication.

## [v0.3.2] - 2025-11-03
### 🐛 Bug Fixes
- **Raid Organizer Bugs:** Fixed several outstanding bugs in the raid-to-M+ group organizer.
- **Spec Change Detection:** Resolved a timing issue where the UI would not correctly update when a player changed their specialization.

## [v0.3.1] - 2025-11-02
### ✨ Enhancements
- **Realistic Poll Responses:** The M+ Group Organizer's polling feature now generates more realistic and varied responses from fake players, making solo testing more effective.

## [v0.3.0] - 2025-11-01
### 🚀 Features
- **M+ Group Organizer - Auto Capture:** The Organizer can now automatically capture the current group composition when opened, saving the user from having to manually drag and drop every player.

## [v0.2.0] - 2025-10-31
### 🚀 Features
- **M+ Group Organizer - Drag and Drop UI:** The first major feature of the addon is here! A new UI window that allows users to form M+ breakout groups from a larger raid group using a simple and intuitive drag-and-drop interface.

## [v0.1.11] - 2025-10-28
### ⚡️ Optimizations
- **Comprehensive Performance Pass:** Implemented a series of optimizations across the addon to reduce CPU usage during combat and minimize memory footprint.
### ✨ Enhancements
- **Loot Tracking System:** Added a new system to track and display loot obtained from Mythic+ dungeons, helping users see their rewards over time.

## [v0.1.10] - 2025-10-21
### ⚡️ Optimizations
- **Opcode Removal:** Removed several deprecated communication opcodes from the constants file.
- **Conditional Refactor:** Complex `if/else` chains in the key rating logic were refactored into more readable and maintainable lookup tables.

## [v0.1.9] - 2025-10-20
### ✨ Enhancements
- **PUG Helper Modularization:** The main `pugHelper.lua` file was split into smaller, more focused modules to improve code organization.
- **Like/Dislike Feature Disabled:** The partially implemented and unused like/dislike feature was disabled to avoid confusion.

## [v0.1.8] - 2025-10-19
### ⚡️ Optimizations
- **Centralized UI Components:** Refactored the UI to use a centralized factory for creating AceGUI components, ensuring a consistent look and feel and reducing code duplication.
### 🧪 Developer Features
- **Hearthstone Data & UI:** Added data for Hearthstone locations and a basic UI for testing teleport functionality.

## [v0.1.7] - 2025-10-19
### ✨ Enhancements
- **Loot Window Integration:** The Loot Window is now more tightly integrated with the Dungeon Card UI, making for a smoother user experience.

## [v0.1.6] - 2025-10-12
### ✨ Enhancements
- **Loot Window Added:** A new UI window was added to display loot information for dungeons.
### ⚡️ Optimizations
- **Unused Code Removal:** Removed old, unused manual sorting logic from the DungeonCards module.

## [v0.1.5] - 2025-10-06
### ✨ Enhancements
- **Teleport Functionality:** The addon can now intelligently suggest the best portal to take to get to a selected dungeon, with improved matching logic.

## [v0.1.4] - 2025-10-05
### ⚡️ Optimizations
- **Centralized Services:** Refactored fake player handling and debug logging into centralized services (`FakePlayerService`, `Debug:Dev`) to improve code structure and reduce redundancy.

## [v0.1.3] - 2025-10-05
### 🧪 Developer Features
- **Fake Player Overhaul:** The system for creating fake players for testing was significantly overhauled to support more realistic Raider.IO score distributions and role assignments.
- **Debug System Enhancements:** Added new tools and visualizations to the debug system to make testing easier.

## [v0.1.2] - 2025-10-05
### 🐛 Bug Fixes
- **UI Visibility:** Fixed an issue where keystone buttons were incorrectly shown in the dungeon view.
- **Statistics Reset:** Prevented logging during statistics reset to avoid data corruption.

## [v0.1.1] - 2025-10-05
### ✨ Enhancements
- **PUG Mode:** Implemented the first version of PUG Mode, a feature designed to assist players in finding and joining pick-up groups through the LFG tool.

## [v0.1.0] - 2025-09-28
### 🚀 Features
- **Initial Commit:** The first version of the NextKey addon, including the basic framework and core logic for calculating Mythic+ key ratings.
### 🐛 Bug Fixes
- **Initialization Fix:** Corrected a critical bug that was preventing the addon from loading correctly.
