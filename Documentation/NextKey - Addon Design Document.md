# NextKey - Addon Design Document

## 1. Project Overview

### 1.1. Addon Name

NextKey

### 1.2. Purpose

NextKey is a World of Warcraft addon designed to help Mythic+ groups intelligently select the best keystone to run next. It aggregates keystone, player score, and loot preference data from all party members, processes this data through various customizable ranking algorithms, and presents a clear, ranked list of suggestions to the group.

### 1.3. Core Philosophy

The addon will be built upon the Ace3 library suite. This approach ensures stability, efficiency, and a familiar user experience for configuration. All major systems—initialization, saved variables, inter-addon communication, and UI configuration—will leverage the Ace3 framework.

### 1.4. Hard Dependency

The addon must read player score data from the Raider.IO Mythic Plus Addon's SavedVariables. This is a non-negotiable dependency for score-based calculations.

## 2. Core Features & Ace3 Implementation

### 2.1. Data Collection & Communication (AceComm-3.0)

The addon's communication system will be handled by AceComm-3.0 to ensure reliable and efficient data transfer between party members.

- **Comm Prefix**: `NKEY`
- **Data Payload Structure**: A serialized Lua table containing:
    - `keystone`: `{dungeonID, level, ownerName}`
    - `scores`: A table of the player's best runs per dungeon, sourced from Raider.IO.
    - `liveRun`: A table containing the last completed run's data (dungeonID, level, timedSuccess) to ensure calculations are up-to-the-second accurate.
    - `lootTargets`: An array of ItemIDs the player has marked as needed.
- **Communication Triggers**:
    - **Proactive Broadcast**: On the `CHALLENGE_MODE_COMPLETED` event, each client will automatically broadcast its full data payload to the `PARTY` channel. This ensures all clients have the latest data (new key, updated live score) without a manual request.
    - **Sync on Roster Change**: On `GROUP_ROSTER_UPDATE`, a request for data is sent to synchronize all party members.
    - **Manual Refresh**: A UI button will trigger a manual data sync.

### 2.2. Saved Data Management (AceDB-3.0)

All persistent data will be managed by AceDB-3.0.

- **Database Name**: `NextKeyDB`
- **Default Profile Structure**:
    - `db.global`: Global settings accessible by all characters.
        - `leaderSettings`: `{ autoSuggestEnabled = false, defaultSortMode = "SmartSort" }`
    - `db.char`: Character-specific data.
        - `liveRuns`: `{}` -- Stores recently completed runs not yet in Raider.IO data.
        - `targetedItems`: `{}` -- List of targeted ItemIDs.
        - `dungeonRunCounts`: `{}` -- Maps dungeonID to run counts for loot tracking.

### 2.3. Ranking & Sorting Algorithms

This remains the core logic of the addon, processing the collected data. A central function will first calculate all necessary metrics for each available keystone.

- **Metrics to Calculate per Key**: `totalGain`, `playerCount`, `itemNeed`, `keyLevel`.
- **Sorting Modes**:
    - **Max Group IO**: Ranks by `totalGain` (desc).
    - **Max Player Coverage**: Ranks by `playerCount` (desc), tie-break with `totalGain`. If a player has not timed the key or can gain in it that means they want to run the key. If they cannot gain IO that means they dont want to run the key
    - **Highest Key Level**: Ranks by `keyLevel` (desc), tie-break with `playerCount`.
    - **Max Item Need**: Ranks by `itemNeed` (desc), tie-break with `playerCount`.
    - **Smart Sort (Borda Count)**: Ranks keys based on a point system derived from their rank in the other four sorts. The tooltip for a key in this mode will show a breakdown of its rank in each category.

### 2.4. Loot Targeting & Tracking

- **Internal Database**: A `LootDB.lua` file will map dungeon IDs to all available loot for the current Mythic+ season.
- **UI (AceConfig-3.0 & AceGUI-3.0)**: Loot selection will be managed within the addon's options panel. It will feature a TreeGroup or similar widget where each dungeon is a top-level entry, and its loot items are selectable children.
- **Loot Drop Detection**: Listens to `CHAT_MSG_LOOT`. If a looted item matches a player's target list, it announces a celebratory message to the party, including the run count from `NextKeyDB.char.dungeonRunCounts`.

### 2.5. Auto-Suggest & Travel Assistant

- **Leader-Only Feature**: A setting in the AceConfig options panel, visible only to the party leader, enables "Auto-Suggest."
- **Logic**: Upon `CHALLENGE_MODE_COMPLETED`, the leader's client detects the new keystone via `BAG_UPDATE`, runs a ranking with the default sort mode, and broadcasts the top-ranked key via an AceComm message.
- **UI (AceGUI-3.0)**: All clients receive a compact pop-up (`AceGUI-3.0:Create("Frame")`) displaying the suggestion and two buttons: a dynamic "Teleport/Hearthstone" button and an "Announce" button.

### 2.6. Configuration Panel (AceConfig-3.0)

All user-facing settings will be managed in a standard Ace3 options panel, accessible via a slash command. This removes the need for settings buttons on the main UI.

**Options Table Structure (options.lua)**:

```lua
local options = {
    name = "NextKey",
    handler = NextKey,
    type = 'group',
    args = {
        general = {
            type = 'group',
            name = 'General Settings',
            args = {
                defaultSort = {
                    type = 'select',
                    name = 'Default Sort Mode',
                    values = { SmartSort = "Smart Sort", MaxGroupIO = "Max Group IO", ... },
                    -- getters and setters for NextKeyDB.global.leaderSettings
                },
                autoSuggest = {
                    type = 'toggle',
                    name = 'Enable Auto-Suggest (Leader Only)',
                    -- getters and setters for NextKeyDB.global.leaderSettings
                },
            },
        },
        loot = {
            type = 'group',
            name = 'Loot Targets',
            args = {
                -- This group will be dynamically populated from LootDB.lua
                -- using AceGUI widgets within AceConfig.
            },
        },
    },
}
```

### 2.7. Main UI (AceGUI-3.0)

The main ranking window will be built with AceGUI-3.0 widgets.

- **Frame**: A movable, closable Frame widget.
- **Controls**: A SimpleGroup containing Button widgets for each of the 5 sort modes.
- **Results Panel**: A ScrollFrame containing a list of ranked keys. Each key will be an InteractiveLabel or Button widget that shows the enhanced tooltip on hover.
- **Action Buttons**: Button widgets for "Refresh" and "Dice Roll". The "Set Loot" button is removed, as this is now handled in the options panel.

## 3. Technical Specifications

### 3.1. Addon Initialization (AceAddon-3.0)

The addon will be structured as an AceAddon-3.0 object.

```lua
local addon = LibStub("AceAddon-3.0"):NewAddon("NextKey", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
```

- `addon:OnInitialize()`: Register slash commands, set up AceDB, AceComm, and AceConfig.
- `addon:OnEnable()`: Register WoW API events and hooks.
- `addon:OnDisable()`: Unregister events and hooks.

### 3.2. Slash Commands (AceConsole-3.0)

- `/nextkey` or `/nk`: Opens the main ranking window.
- `/nextkey config`: Opens the AceConfig-3.0 options panel.

### 3.3. File Structure (.toc)

```
## Interface: 100205
## Title: NextKey
## Notes: Intelligently ranks Mythic+ keys for your group.
## Author: Gemini & User
## Version: 1.0.0
## SavedVariables: NextKeyDB
## OptionalDeps: RaiderIO

## X-Category: Dungeons

#@no-lib-strip@
Libs\LibStub\LibStub.lua
Libs\CallbackHandler-1.0\CallbackHandler-1.0.xml
Libs\AceAddon-3.0\AceAddon-3.0.xml
Libs\AceGUI-3.0\AceGUI-3.0.xml
Libs\AceConfig-3.0\AceConfig-3.0.xml
Libs\AceComm-3.0\AceComm-3.0.xml
Libs\AceConsole-3.0\AceConsole-3.0.xml
Libs\AceDB-3.0\AceDB-3.0.xml
Libs\AceEvent-3.0\AceEvent-3.0.xml
Libs\AceSerializer-3.0\AceSerializer-3.0.xml
#@end-no-lib-strip@

Locale.lua
Databases\LootDB.lua
Databases\PortalDB.lua
Core.lua
Options.lua
UI.lua
```

### 3.4. Key WoW API & Events

- **Events**: `ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, `GROUP_ROSTER_UPDATE`, `CHALLENGE_MODE_COMPLETED`, `BAG_UPDATE`, `CHAT_MSG_LOOT`.
- **Functions**: Standard WoW API for bags, spells, and group information. Ace3 libraries will wrap most event and communication functions.