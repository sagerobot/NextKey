# Changelog

All notable changes to this project will be documented in this file.

## [v0.5.32] - 2025-11-09
### ✨ Enhancements
- **Category-Based Debug Profiles:** Replaced generic level-based debug presets (minimal, standard, verbose, full) with targeted category-based profiles designed for specific bug types. New profiles include: UI Issues, Organizer Issues, Keystone & Scoring Issues, PUG Helper Issues, Sync & Communication Issues, Loot Tracking Issues, and Teleport Issues. This provides beta testers and bug reporters with focused debug output relevant to their specific issue category.

## [v0.5.29] - 2025-11-09
### ✨ Enhancements
- **Debug UI Improvements:** Disabled automatic debug statistics refresh to prevent interrupting user text input. Statistics now update only via manual refresh button or when debug controls are used.
- **Player Card Vertical Centering:** Improved player card rendering with proper CENTER-based vertical anchoring instead of TOPLEFT anchors, fixing alignment issues in compact bench cards.
- **Opt-Out Card Redesign:** Redesigned opt-out card layout with corner-anchored elements for better visual consistency.
### 🐛 Bug Fixes
- **Fake Player Tools Visibility:** Restricted fake player tools visibility to DEV_MODE only to avoid confusion for end users.

## [v0.5.19] - 2025-11-09
### ⚡️ Optimizations
- **Memory Leak Fix:** Removed a problematic `OnUpdate` script from a performance optimization module that was causing significant memory leaks over long play sessions. This makes the addon much more stable.

## [v0.5.17] - 2025-11-09
### ✨ Enhancements
- **Custom Fake Player Builder:** To accelerate testing, a new UI was added to build and customize fake players with specific roles, classes, and Raider.IO scores. Includes real-time validation to prevent impossible player configurations.
- **Options Menu Refactor:** The addon's options menu was restructured to isolate developer tools from the main user settings, creating a cleaner and more intuitive experience for end-users.

## [v0.5.11] - 2025-11-08
### 📚 Documentation
- **Memory Bank Documentation:** Completed comprehensive memory bank documentation covering OrganizerState architecture, teleport sync system, and PUG mode hardening.

## [v0.5.10] - 2025-10-31
### ✨ Enhancements
- **Loot Tracking System:** Added a new system to track and display loot obtained from Mythic+ dungeons.

## [v0.5.7] - 2025-11-06
### ✨ Enhancements
- **M+ Group Organizer Animations:** Added smooth, animated transitions for players being moved into and out of M+ groups in the Organizer UI.

## [v0.5.4] - 2025-11-05
### ✨ Enhancements
- **M+ Group Organizer - Centralized State:** A new `OrganizerState` module was created to act as a single source of truth for the M+ Group Organizer with hybrid persistence.
- **M+ Group Organizer - Network Handshake:** Implemented a handshake protocol using `AceComm` to ensure that all players in a group are in sync.

## [v0.5.3] - 2025-11-04
### ✨ Enhancements
- **M+ Group Organizer - Modular UI:** The main `rosterBoard` for the Organizer was broken down into smaller, more manageable modules.

## [v0.5.2] - 2025-11-03
### ⚡️ Optimizations
- **Spec Preference Consolidation:** The code responsible for generating player spec preferences was consolidated into a single, more efficient function.
### 🐛 Bug Fixes
- **Raid Organizer Bugs:** Fixed several outstanding bugs in the raid-to-M+ group organizer.
- **Spec Change Detection:** Resolved a timing issue where the UI would not correctly update when a player changed their specialization.

## [v0.5.1] - 2025-11-02
### ✨ Enhancements
- **Realistic Poll Responses:** The M+ Group Organizer's polling feature now generates more realistic and varied responses from fake players for better solo testing.

## [v0.5.0] - 2025-10-27
### 🚀 Features
- **M+ Group Organizer:** A new UI window that allows users to form M+ breakout groups from a larger raid group using a drag-and-drop interface.

## [v0.4.20] - 2025-11-01
### ✨ Enhancements
- **M+ Group Organizer - Auto Capture:** The Organizer can now automatically capture the current group composition when opened.

## [v0.4.18] - 2025-10-23
### ⚡️ Optimizations
- **Comprehensive Performance Pass:** Implemented a series of optimizations across the addon to reduce CPU usage during combat and minimize memory footprint.

## [v0.4.16] - 2025-10-21
### ⚡️ Optimizations
- **Opcode Removal:** Removed several deprecated communication opcodes from the constants file.
- **Conditional Refactor:** Complex `if/else` chains in the key rating logic were refactored into more readable and maintainable lookup tables.

## [v0.4.13] - 2025-10-20
### ✨ Enhancements
- **PUG Helper Modularization:** The main `pugHelper.lua` file was split into smaller, more focused modules to improve code organization.
- **Like/Dislike Feature Disabled:** The partially implemented and unused like/dislike feature was disabled to avoid confusion.
- **Loot Window Integration:** The Loot Window is now more tightly integrated with the Dungeon Card UI.

## [v0.4.3] - 2025-10-19
### ✨ Enhancements
- **Centralized UI Components:** Refactored the UI to use a centralized factory for creating AceGUI components, ensuring a consistent look and feel and reducing code duplication.

## [v0.4.0] - 2025-10-19
### 🚀 Features
- **Hearthstone Selector:** Added a new UI that allows players to select from their unlocked hearthstones when using the teleport system, providing more travel flexibility and convenience.

## [v0.3.6] - 2025-10-14
### 📚 Documentation
- **Code Documentation:** Added comprehensive comments to core files to improve code readability and maintainability.
- **User Guide:** Created detailed user guide documentation to help players understand and utilize addon features.

## [v0.3.4] - 2025-10-14
### 📚 Documentation
- **Release Preparation Guide:** Added release preparation documentation covering build process, version management, and distribution.
- **GitHub README:** Created comprehensive GitHub README with project overview, installation instructions, and feature descriptions.

## [v0.3.2] - 2025-10-14
### 📚 Documentation
- **Technical Debt Analysis:** Created technical debt analysis report to guide future refactoring efforts.
- **Refactoring Suggestions:** Documented refactoring suggestions for improved code quality and maintainability.

## [v0.3.1] - 2025-10-13
### ⚡️ Optimizations
- **Unused Code Removal:** Removed old, unused manual sorting logic from the DungeonCards module.

## [v0.3.0] - 2025-10-13
### 🚀 Features
- **Loot Window:** A new UI window was added to display loot information for dungeons, helping players track which items they want from specific content.

## [v0.2.1] - 2025-10-13
### 📚 Documentation
- **PUG Mode Analysis:** Created PUG mode analysis document detailing workflow and implementation decisions.

## [v0.2.0] - 2025-10-13
### 🚀 Features
- **PUG Mode (Initial Release):** Implemented the first version of PUG Mode, a feature designed to assist players in finding and joining pick-up groups through the LFG tool with automatic workflow assistance. Note: This initial release had significant issues that were not resolved until later versions.

## [v0.1.24] - 2025-10-12
### 🐛 Bug Fixes
- **UI Visibility:** Fixed an issue where keystone buttons were incorrectly shown in the dungeon view.
- **Statistics Reset:** Prevented logging during statistics reset to avoid data corruption.

## [v0.1.22] - 2025-10-12
### 🧪 Developer Features
- **Fake Player System Enhancement:** Significantly overhauled the fake player generation system to support more realistic Raider.IO score distributions and role assignments.
- **Debug System Enhancement:** Added new tools and visualizations to the debug system.

## [v0.1.17] - 2025-10-12
### ✨ Enhancements
- **Role Detection & Live Spec Updates:** Implemented automatic role detection system with live UI updates when players change their specialization.

## [v0.1.14] - 2025-10-11
### ⚡️ Optimizations
- **Centralized Services:** Refactored fake player handling and debug logging into centralized services (`FakePlayerService`, `Debug:Dev`).

## [v0.1.12] - 2025-10-11
### 🧪 Developer Features
- **Debug System:** Created a comprehensive debug logging system with categorized output levels (Error, User, Dev, Trace) to facilitate development and troubleshooting.

## [v0.1.7] - 2025-10-10
### ✨ Enhancements
- **Teleport System:** The addon can now intelligently suggest the best portal and or show your hearthstone to use to reach a selected dungeon,or your home inn.

## [v0.1.4] - 2025-10-02
### 🐛 Bug Fixes
- **Addon Initialization:** Fixed a critical bug preventing the addon from loading correctly after initial release.

## [v0.1.3] - 2025-09-30
### ✨ Enhancements
- **Dungeon Overview UI:** Created a comprehensive UI window displaying a sortable overview of all Mythic+ dungeons for the current season, showing player's best runs and scores for each dungeon.

## [v0.1.0] - 2025-09-30
### 🚀 Features
- **Main UI Window:** Built the primary user interface using AceGUI, including the main window, scrollable keystone list, and initial sorting/filtering controls.
- **Keystone Cards System:** Implemented a card-based UI system for displaying keystones and dungeon information with sortable views.

## [v0.0.26] - 2025-09-30
### 🧪 Developer Features
- **Fake Player System:** Created initial fake player generation system for testing addon features without requiring a full party, enabling solo development and testing workflows.

## [v0.0.21] - 2025-09-30
### ✨ Enhancements
- **Communication System:** Established AceComm-based communication infrastructure for party/raid keystone and score sharing.
- **Profile System:** Created a player profile system to track and manage player stats, preferences, and Mythic+ performance data.

## [v0.0.18] - 2025-09-30
### ✨ Enhancements
- **IO Calculator:** Implemented the core logic for calculating Mythic+ key ratings and IO scores based on the MythicPlanner.com algorithm.

## [v0.0.12] - 2025-09-30
### ✨ Enhancements
- **RaiderIO Integration:** Integrated with RaiderIO addon to pull comprehensive player Mythic+ scores and dungeon-specific performance data.
- **Keystone Detection:** Implemented automatic keystone scanning from player bags using Blizzard APIs and LibOpenRaid.

## [v0.0.6] - 2025-09-30
### ✨ Enhancements
- **Database Integration:** Set up AceDB-3.0 for SavedVariables persistence and profile management.
- **Configuration System:** Implemented AceConfig-3.0 for addon options and settings management.

## [v0.0.3] - 2025-09-30
### ✨ Enhancements
- **Initial Project Setup:** Created the foundational NextKey addon structure using Ace3 libraries (AceAddon, AceComm, AceGUI) providing the base architecture for all future features.
- **Basic Addon Structure:** Established core file organization, TOC file, and basic addon initialization.