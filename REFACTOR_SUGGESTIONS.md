# Refactoring Suggestions for NextKey

This document outlines potential areas for refactoring in the NextKey addon codebase to improve maintainability, reduce redundancy, and increase modularity.

## 1. Duplicated UI Logic

**Location:**
- `ui/main.lua`
- `ui/dungeonCards.lua`

**Observation:**
Both `ui/main.lua` and `ui/dungeonCards.lua` contain significant amounts of code for creating UI components. While `ui/main.lua` primarily uses the AceGUI framework and `ui/dungeonCards.lua` uses the native `CreateFrame` API, the underlying logic for defining UI elements like frames, buttons, and text labels is conceptually similar.

**Specific Duplications:**
- **Frame Creation:** Both files have boilerplate code for creating the main container frames for their respective UI views.
- **Button Creation:** Logic for creating buttons, setting their textures, and attaching tooltip handlers is present in both files.
- **Backdrop Styling:** The setup for backdrops (`SetBackdrop`) is repeated with similar parameters.
- **Text and Font Handling:** Creating `FontString` objects and setting their properties is a common, repeated task.

**Suggestion:**
Create a centralized UI component factory or library within the addon. This library could provide functions to create common UI elements like `CreateNextKeyButton`, `CreateNextKeyFrame`, etc. This would abstract away the differences between AceGUI and the native API where possible, and provide a consistent way to build the addon's UI. This would also make it easier to maintain a consistent look and feel across the entire addon.

## 2. Hardcoded ID Mappings

**Location:**
- `core/utils.lua`

**Observation:**
The `core/utils.lua` file contains several functions (`GetSeasonDungeonIndex`, `ConvertToRaiderIOKeystoneID`, `ConvertChallengeMapToKeystoneID`, `FindNextKeyDungeonID`) that use hardcoded Lua tables to map dungeon IDs between NextKey's internal IDs, Raider.IO IDs, and Blizzard's Challenge Mode Map IDs.

**Problem:**
This approach is inflexible and difficult to maintain. With each new Mythic+ season, these tables will need to be manually updated, which is error-prone and can lead to inconsistencies if a mapping is missed in one of the functions.

**Suggestion:**
Consolidate all ID mapping logic into a single, centralized data structure or module (e.g., enhancing `core/ids.lua` or creating a new `core/id_mapper.lua`). This module would be the single source of truth for all dungeon ID conversions. It could be designed to load season-specific data and provide a clear API for conversions (e.g., `IDMapper:GetRaiderIOID(nextKeyID)`, `IDMapper:GetNextKeyIDFromChallengeID(challengeID)`). This would make seasonal updates much simpler and more reliable.

## 3. Profile Handling Abstraction

**Location:**
- `core/adapters/blizzard.lua`
- `core/adapters/raiderio.lua`

**Observation:**
The `blizzard.lua` and `raiderio.lua` adapters are responsible for fetching data and converting it into a standardized `PlayerProfile` table. While the data sources are different, the structure of the resulting profile is the same, leading to repeated logic for creating and populating these profiles.

**Problem:**
Adding a new data source would require duplicating the boilerplate for profile creation. Changes to the `PlayerProfile` structure would need to be updated in multiple adapter files, increasing the maintenance overhead.

**Suggestion:**
Create a base `PlayerProfile` module or a factory that can be used by all adapters. This module would define the canonical structure of a player profile and provide helper functions for creating and populating it. Individual adapters would then only be responsible for fetching raw data and passing it to this central profile builder. This would reduce code duplication, ensure consistency, and make it easier to add new data sources.

## 4. Redundant UI Creation

**Location:**
- `ui/main.lua`

**Observation:**
The `CreateMainFrame` function in `ui/main.lua` is a large, monolithic function that handles the creation of the entire main window. Within this function, multiple UI elements like buttons (`refreshBtn`, `syncBtn`, `guildToggleBtn`) and dropdowns are created and configured individually, leading to a lot of repetitive boilerplate code.

**Problem:**
This monolithic approach makes the UI code difficult to read and modify. Adding a new control or changing the layout requires navigating a large block of code. The lack of reusable components means that similar elements are recreated from scratch, increasing the chance of inconsistencies.

**Suggestion:**
Adopt a more component-based approach. Break down the UI into smaller, reusable components with their own creation functions. For example, create a helper function like `UI:CreateControlButton(text, callback)` that encapsulates the common logic for creating the main control buttons. This would lead to a cleaner, more modular, and more maintainable UI codebase.

## 5. Inconsistent UI Component Creation

**Location:**
- `ui/main.lua` (uses AceGUI)
- `ui/dungeonCards.lua` (uses `CreateFrame`)

**Observation:**
The addon uses two different methods for creating UI components. `ui/main.lua` leverages the AceGUI-3.0 library, which provides a higher-level, object-oriented way to build UIs. In contrast, `ui/dungeonCards.lua` uses the lower-level, native `CreateFrame` API.

**Problem:**
This inconsistency leads to a fragmented and harder-to-maintain codebase. Developers need to be familiar with two different UI creation paradigms, and it's more difficult to create a consistent look and feel across the addon. Reusing UI components or styles between the two systems is also challenging.

**Suggestion:**
Standardize on a single UI creation method. Given that AceGUI is already in use and is a powerful, well-supported library, it would be the logical choice. Refactor `ui/dungeonCards.lua` to use AceGUI widgets. This will result in a more cohesive, maintainable, and visually consistent addon.
