# M+ Group Organizer - Phase 0: Foundation

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** None (Foundation Phase)  
**Estimated Complexity:** High  
**Implementation Priority:** CRITICAL - Must complete before all other phases

---

## Overview

This document defines the foundational data structures, storage systems, and core infrastructure required for the M+ Group Organizer feature. This phase establishes the data layer that all subsequent phases depend on.

**Key Deliverables:**
1. Account-wide character storage expansion
2. Player object structure and data model
3. Communication protocol extensions
4. Auto-detection system for non-addon players
5. Data acquisition pipeline

---

## 1. SavedVariables Schema Expansion

### 1.1 Current Structure Reference

NextKey currently uses [`NextKeyDB`](../../../NextKey.toc:7) with the following structure:
```lua
NextKeyDB = {
    global = { ... },
    char = {
        liveRuns = {},
        preferences = {},
        targetedItems = {},
        dungeonRunCounts = {},
        mythicPlus = { activeSeason, seasons = {...} }
    }
}
```

### 1.2 New Account-Wide Storage (AceDB Profile)

**Location:** `NextKeyDB.profile.characters`

**Structure:**
```lua
NextKeyDB.profile = {
    characters = {
        -- Key: "CharacterName-Realm"
        ["PlayerOne-Stormrage"] = {
            name = "PlayerOne",
            realm = "Stormrage",
            class = "WARRIOR",
            level = 80,
            
            -- Role Configuration (NEW - needs Options UI)
            availableRoles = {
                ["Tank"] = true,
                ["Healer"] = false,
                ["DPS"] = true
            },
            
            -- Automatically derived utilities
            utilities = {
                ["Lust"] = false,
                ["Brez"] = false
            },
            
            -- Keystone data
            currentKeystone = {
                dungeonID = 503,
                level = 15,
                lastUpdated = 1729742400 -- timestamp
            },
            
            -- M+ Rating
            overallScore = 2850,
            
            -- Individual dungeon scores (from RaiderIO/Blizzard API)
            dungeonScores = {
                [503] = {
                    bestScore = 285.5,
                    bestLevel = 18,
                    fortifiedScore = 285.5,
                    tyrannicalScore = 280.0
                },
                -- ... all 8 dungeons
            },
            
            -- Last seen/updated timestamp
            lastSeen = 1729742400,
            
            -- Data freshness indicator
            dataVersion = 1 -- increment on structure changes
        }
    }
}
```

### 1.3 Migration Strategy

**File:** `core/characterStorage.lua` (NEW)

```lua
-- MARK: Module Definition
local CharacterStorage = {}
NextKey222.CharacterStorage = CharacterStorage
NextKey222.RegisterModule("CharacterStorage", CharacterStorage)

function CharacterStorage:Initialize()
    return NextKey222.SafeRun(function()
        -- Initialize profile namespace if missing
        if not self.db.profile.characters then
            self.db.profile.characters = {}
            Debug:Dev("storage", "Initialized character storage")
        end
        
        -- Migrate existing character data if needed
        self:MigrateExistingData()
        
        return true
    end, "CharacterStorage:Initialize")
end

function CharacterStorage:MigrateExistingData()
    -- Check data version and migrate if needed
    -- This handles upgrades from older addon versions
end
```

### 1.4 Data Freshness Management

**Requirements:**
- Keystone data expires after Tuesday server reset (region-specific)
- Score data refreshed every login
- Stale data flagged with warning indicator in UI
- Manual refresh command: `/nk refresh characters`

**Implementation:**
```lua
function CharacterStorage:IsKeystoneDataStale(charData)
    -- Calculate last Tuesday reset time for region
    local lastReset = self:GetLastServerReset()
    return charData.currentKeystone.lastUpdated < lastReset
end

function CharacterStorage:GetLastServerReset()
    -- US: Tuesday 15:00 UTC
    -- EU: Wednesday 07:00 UTC
    -- etc.
end
```

---

## 2. Core Data Structures

### 2.1 Player Object (Extended)

**File:** Create new type definition file `core/types/player.lua`

```lua
-- Player Object Structure for Group Organizer
local PlayerObject = {
    -- Unique Identifier
    id = "PlayerName-Realm", -- string
    
    -- Basic Info
    name = "PlayerName",
    realm = "Stormrage",
    class = "WARRIOR", -- WoW class token
    level = 80,
    
    -- Role & Utility
    roles = {"Tank", "DPS"}, -- list of performable roles
    utils = {"Lust"}, -- list of provided utilities
    
    -- Keystone
    keystone = KeystoneObject or nil,
    
    -- Scoring Data
    scores = {
        [dungeonID] = score, -- map of dungeon scores
        -- Example: [503] = 285.5
    },
    overallScore = 2850,
    
    -- Preferences (per character)
    preferences = {
        [dungeonID] = -1/0/1, -- -1=Dislike, 0=Neutral, 1=Like
    },
    
    -- Organizer-Specific Fields
    rankScore = 0, -- Used by Mode 2 (Balanced)
    isTemporary = false, -- True if this is a fake player card for an alt
    sourceCharacter = nil, -- If temporary, points to real character ID
    
    -- Data Source Metadata
    dataSource = "combined", -- "addon" | "auto-detected" | "temporary"
    hasAddon = true, -- false if auto-detected
    dataFreshness = "current", -- "current" | "stale" | "unknown"
    
    -- Survey Response Data (if applicable)
    surveyResponse = {
        optedIn = true,
        selectedCharacter = "PlayerName-Realm", -- Could be alt
        rolePreferences = {
            Tank = "Will Play",
            DPS = "Will Play",
            Healer = "Fill"
        },
        timestamp = 1729742400
    }
}
```

### 2.2 Keystone Object (Unchanged)

```lua
local KeystoneObject = {
    dungeonID = 503, -- integer
    level = 15, -- integer
    ownerID = "PlayerName-Realm" -- string
}
```

### 2.3 Group Object (Extended)

```lua
local GroupObject = {
    -- Group Composition
    players = {}, -- list of 5 Player objects
    
    -- Keystone Selection
    chosenKeystone = KeystoneObject or nil,
    
    -- Scoring
    totalGain = 0, -- Total IO gain for group
    totalScore = 0, -- Final score (Gain + Preference)
    
    -- Validation State
    isValid = true,
    validationErrors = {}, -- list of error strings
    
    -- UI State
    groupIndex = 1, -- 1-based group number
    headerText = "M+ Grp. 1" -- or "ARA: +10" when keystone set
}
```

### 2.4 Temporary Player Card Logic

**Purpose:** When a participant selects an alt in the survey, create a "fake" player object with the alt's data.

```lua
function CharacterStorage:CreateTemporaryPlayerCard(altCharacterID, sourceCharacterID)
    return NextKey222.SafeRun(function()
        local altData = self.db.profile.characters[altCharacterID]
        if not altData then
            error("Alt character data not found: " .. altCharacterID)
        end
        
        -- Clone the alt's data
        local tempPlayer = {
            id = altCharacterID .. "_TEMP", -- Unique temporary ID
            name = altData.name,
            realm = altData.realm,
            class = altData.class,
            level = altData.level,
            roles = self:DeriveRoles(altData),
            utils = altData.utilities,
            keystone = altData.currentKeystone,
            scores = altData.dungeonScores,
            overallScore = altData.overallScore,
            preferences = {}, -- Use source character's preferences
            
            -- Temporary flags
            isTemporary = true,
            sourceCharacter = sourceCharacterID,
            dataSource = "temporary",
            dataFreshness = self:CheckDataFreshness(altData)
        }
        
        Debug:Dev("organizer", "Created temporary player card for", altCharacterID)
        return tempPlayer
    end, "CharacterStorage:CreateTemporaryPlayerCard")
end
```

---

## 3. Communication Protocol Extensions

### 3.1 New Message Types

**File:** Extend [`core/comms.lua`](../../../core/comms.lua:1)

```lua
-- New Opcodes for Organizer
local ORGANIZER_OPCODES = {
    -- Survey System
    POLL_REQUEST = "ORG_POLL_REQUEST",
    POLL_RESPONSE = "ORG_POLL_RESPONSE",
    
    -- Roster Synchronization
    ROSTER_STATE_FULL = "ORG_ROSTER_FULL", -- Complete roster state
    ROSTER_STATE_DELTA = "ORG_ROSTER_DELTA", -- Incremental update
    PLAYER_CARD_MOVED = "ORG_CARD_MOVED",
    KEYSTONE_DESIGNATED = "ORG_KEY_SET",
    
    -- Optimizer Status
    OPTIMIZER_STARTED = "ORG_OPT_START",
    OPTIMIZER_PROGRESS = "ORG_OPT_PROGRESS",
    OPTIMIZER_COMPLETE = "ORG_OPT_COMPLETE"
}
```

### 3.2 Message Structure Examples

#### Poll Request
```lua
{
    opcode = "ORG_POLL_REQUEST",
    version = "0.3.0",
    timestamp = GetTime(),
    sender = "LeaderName-Realm",
    data = {
        pollID = "unique-poll-id",
        timeout = 60 -- seconds to respond
    }
}
```

#### Poll Response
```lua
{
    opcode = "ORG_POLL_RESPONSE",
    version = "0.3.0",
    timestamp = GetTime(),
    sender = "PlayerName-Realm",
    data = {
        pollID = "unique-poll-id",
        optedIn = true,
        selectedCharacter = "AltName-Realm", -- or sender if current char
        rolePreferences = {
            Tank = "Will Play",
            DPS = "Will Play",
            Healer = "Fill"
        },
        characterData = { -- If alt selected, include their data
            name = "AltName",
            realm = "Realm",
            class = "PALADIN",
            keystone = {...},
            scores = {...}
        }
    }
}
```

#### Roster State Update (Delta)
```lua
{
    opcode = "ORG_ROSTER_DELTA",
    version = "0.3.0",
    timestamp = GetTime(),
    sender = "LeaderName-Realm",
    data = {
        action = "CARD_MOVED", -- or "KEY_SET", "CARD_ADDED", "CARD_REMOVED"
        playerID = "PlayerName-Realm",
        fromLocation = "bench",
        toLocation = "group1_dps1",
        metadata = {} -- Additional action-specific data
    }
}
```

### 3.3 Throttling & Bandwidth Management

**Challenge:** Real-time roster sync for 20+ players = high message volume

**Strategy:**
```lua
-- Batch delta updates every 500ms
local ROSTER_UPDATE_BATCH_INTERVAL = 0.5

-- Queue updates instead of sending immediately
function OrganizerComms:QueueRosterUpdate(updateData)
    table.insert(self.pendingUpdates, updateData)
end

-- Flush queue on timer
function OrganizerComms:FlushUpdateQueue()
    if #self.pendingUpdates == 0 then return end
    
    -- Combine multiple updates into single message
    local batchMessage = {
        opcode = "ORG_ROSTER_DELTA_BATCH",
        data = {
            updates = self.pendingUpdates
        }
    }
    
    self:SendMessage(batchMessage, "RAID")
    self.pendingUpdates = {}
end
```

---

## 4. Auto-Detection System

### 4.1 Detection Logic

**File:** `core/organizer/autoDetection.lua` (NEW)

```lua
-- MARK: Module Definition
local AutoDetection = {}
NextKey222.OrganizerAutoDetection = AutoDetection
NextKey222.RegisterModule("OrganizerAutoDetection", AutoDetection)

function AutoDetection:ScanForNonAddonPlayers()
    return NextKey222.SafeRun(function()
        local raidSize = GetNumGroupMembers()
        local detectedPlayers = {}
        
        for i = 1, raidSize do
            local unit = "raid" .. i
            local name, realm = UnitName(unit)
            local fullName = name .. "-" .. (realm or GetRealmName())
            
            -- Check if they have the addon
            if not self:HasAddon(fullName) then
                local playerData = self:BuildPlayerDataFromAPIs(unit, fullName)
                table.insert(detectedPlayers, playerData)
                
                Debug:Dev("autodetect", "Detected non-addon player:", fullName)
            end
        end
        
        return detectedPlayers
    end, "AutoDetection:ScanForNonAddonPlayers")
end

function AutoDetection:HasAddon(playerID)
    -- Use existing addon detection from Communications module
    return NextKey222.Communications and 
           NextKey222.Communications:IsPlayerOnline(playerID)
end

function AutoDetection:BuildPlayerDataFromAPIs(unit, fullName)
    -- Use existing adapters from ProfilesService
    local profile = NextKey222.ProfilesService:GetProfile(fullName)
    
    return {
        id = fullName,
        name = profile.name,
        realm = profile.realm or GetRealmName(),
        class = profile.class,
        level = UnitLevel(unit),
        roles = self:DeriveRoles(profile),
        utils = self:DeriveUtilities(profile),
        keystone = self:GetKeystoneFromLibOpenRaid(fullName),
        scores = profile.dungeonScores or {},
        overallScore = profile.io or 0,
        preferences = {}, -- Cannot know preferences for non-addon users
        
        -- Auto-detected flags
        dataSource = "auto-detected",
        hasAddon = false,
        dataFreshness = "current"
    }
end
```

### 4.2 Role & Utility Derivation

```lua
function AutoDetection:DeriveRoles(profile)
    -- Use existing logic from core/utils.lua
    local class = profile.class
    local specID = profile.specID
    
    -- Map spec to roles using Blizzard API
    local role = GetSpecializationRoleByID(specID)
    
    -- Some classes are multi-role
    local roles = {}
    if role == "TANK" then table.insert(roles, "Tank") end
    if role == "HEALER" then table.insert(roles, "Healer") end
    if role == "DAMAGER" then table.insert(roles, "DPS") end
    
    return roles
end

function AutoDetection:DeriveUtilities(profile)
    -- Use existing capability detection from ProfilesService
    return profile.capabilities or {}
end
```

---

## 5. Data Acquisition Pipeline

### 5.1 Priority Order

For **addon users** (survey respondents):
1. **Preferences:** `NextKeyDB.char.preferences` (highest priority)
2. **Scores:** ProfilesService → RaiderIO → LibOpenRaid → Blizzard API
3. **Keystones:** Existing detection in [`core/keystones.lua`](../../../core/keystones.lua:1)
4. **Roles/Utils:** Derived from class/spec

For **auto-detected users**:
1. **Scores:** LibOpenRaid → Blizzard API (no RaiderIO for offline)
2. **Keystones:** LibOpenRaid only
3. **Roles/Utils:** Derived from inspected spec
4. **Preferences:** Empty (unknown)

### 5.2 Centralized Data Builder

**File:** `core/organizer/playerDataBuilder.lua` (NEW)

```lua
local PlayerDataBuilder = {}
NextKey222.OrganizerPlayerDataBuilder = PlayerDataBuilder

function PlayerDataBuilder:BuildPlayerObject(playerID, dataSource)
    return NextKey222.SafeRun(function()
        local playerData = {
            id = playerID,
            dataSource = dataSource
        }
        
        -- Route to appropriate builder
        if dataSource == "addon" then
            return self:BuildFromSurveyResponse(playerID)
        elseif dataSource == "auto-detected" then
            return self:BuildFromAutoDetection(playerID)
        elseif dataSource == "temporary" then
            return self:BuildFromCharacterStorage(playerID)
        end
        
        error("Unknown data source: " .. tostring(dataSource))
    end, "PlayerDataBuilder:BuildPlayerObject")
end

function PlayerDataBuilder:BuildFromSurveyResponse(playerID)
    -- Use survey response data + ProfilesService
    local profile = NextKey222.ProfilesService:GetProfile(playerID)
    local preferences = NextKey222.Config:GetPreferences(playerID)
    
    return self:AssemblePlayerObject(profile, preferences, "addon")
end

function PlayerDataBuilder:AssemblePlayerObject(profile, preferences, source)
    -- Central assembly logic
    -- Validates all required fields
    -- Applies defaults for missing data
end
```

---

## 6. Module Registration & Initialization

### 6.1 New Modules to Register

All new modules must follow NextKey's architecture pattern:

```lua
-- In boot.lua, add to initialization sequence:
NextKey222.RegisterModule("CharacterStorage", CharacterStorage)
NextKey222.RegisterModule("OrganizerAutoDetection", AutoDetection)
NextKey222.RegisterModule("OrganizerPlayerDataBuilder", PlayerDataBuilder)
NextKey222.RegisterModule("OrganizerComms", OrganizerComms)
```

### 6.2 Load Order Dependencies

```
1. core/config.lua (existing)
2. core/characterStorage.lua (NEW)
3. core/organizer/autoDetection.lua (NEW)
4. core/organizer/playerDataBuilder.lua (NEW)
5. core/organizer/comms.lua (NEW - extends core/comms.lua)
```

Update [`NextKey.toc`](../../../NextKey.toc:1) accordingly.

---

## 7. Options UI for Role Configuration

### 7.1 New Options Panel

**File:** Extend [`options/main.lua`](../../../options/main.lua:1)

Add new AceConfig options table:

```lua
characterRoles = {
    type = "group",
    name = "Character Roles",
    desc = "Configure which roles each character can perform",
    args = {
        info = {
            type = "description",
            name = "Set the roles you can perform on each character. This is used by the Group Organizer feature.",
            order = 1
        },
        -- Dynamically generate options for each character
        -- See characterSelection implementation below
    }
}
```

### 7.2 Character Selection Widget

```lua
function Options:BuildCharacterRoleOptions()
    local chars = NextKey222.CharacterStorage:GetAllCharacters()
    local options = {}
    
    for charID, charData in pairs(chars) do
        options[charID] = {
            type = "multiselect",
            name = charData.name .. " - " .. charData.class,
            values = {
                Tank = "Tank",
                Healer = "Healer",
                DPS = "DPS"
            },
            get = function(info, key)
                return charData.availableRoles[key]
            end,
            set = function(info, key, value)
                NextKey222.CharacterStorage:SetRole(charID, key, value)
            end
        }
    end
    
    return options
end
```

---

## 8. Data Validation & Integrity

### 8.1 Validation Rules

**File:** `core/organizer/validation.lua` (NEW)

```lua
local Validation = {}
NextKey222.OrganizerValidation = Validation

function Validation:ValidatePlayerObject(player)
    local errors = {}
    
    -- Required fields
    if not player.id then
        table.insert(errors, "Missing player ID")
    end
    
    if not player.roles or #player.roles == 0 then
        table.insert(errors, "Player must have at least one role")
    end
    
    -- Score validation
    if player.scores then
        for dungeonID, score in pairs(player.scores) do
            if type(score) ~= "number" or score < 0 then
                table.insert(errors, "Invalid score for dungeon " .. dungeonID)
            end
        end
    end
    
    -- Preference validation
    if player.preferences then
        for dungeonID, pref in pairs(player.preferences) do
            if pref ~= -1 and pref ~= 0 and pref ~= 1 then
                table.insert(errors, "Invalid preference value: " .. tostring(pref))
            end
        end
    end
    
    return #errors == 0, errors
end

function Validation:ValidateKeystoneData(keystone)
    -- Validate keystone structure
    -- Check level bounds (2-40)
    -- Validate dungeon ID against season data
end
```

---

## 9. Testing Strategy for Phase 0

### 9.1 Unit Tests

**File:** `debug/organizer_foundation_tests.lua` (NEW)

```lua
function TestCharacterStorage()
    -- Test character CRUD operations
    -- Test data migration
    -- Test freshness checks
end

function TestTemporaryPlayerCards()
    -- Test alt card creation
    -- Test data cloning
    -- Verify source character linkage
end

function TestAutoDetection()
    -- Test non-addon player detection
    -- Test API data population
    -- Verify role derivation
end

function TestDataValidation()
    -- Test all validation rules
    -- Test error handling
end
```

### 9.2 Integration Tests

```lua
function TestDataAcquisitionPipeline()
    -- Test full pipeline: Survey → Storage → Player Object
    -- Test fallback chain: RaiderIO → LibOpenRaid → Blizzard
end

function TestCommunicationProtocol()
    -- Test message serialization
    -- Test poll request/response cycle
    -- Test roster sync messages
end
```

---

## 10. Performance Considerations

### 10.1 Memory Management

**Concerns:**
- 20 players × 8 dungeons × score data = ~2KB per player
- 20 players with 3 alts each = 80 character records
- Temporary player cards duplicate data

**Mitigation:**
```lua
-- Lazy load dungeon scores (don't load all upfront)
function CharacterStorage:GetDungeonScores(charID)
    if not self.scoreCache[charID] then
        self.scoreCache[charID] = self:LoadScoresFromDB(charID)
    end
    return self.scoreCache[charID]
end

-- Clear temporary cards when organizer closes
function Organizer:Cleanup()
    for _, player in ipairs(self.temporaryPlayers) do
        player = nil
    end
    self.temporaryPlayers = {}
end
```

### 10.2 Database Access Optimization

```lua
-- Batch character updates
function CharacterStorage:UpdateMultipleCharacters(updates)
    -- Use single transaction instead of multiple saves
    for charID, data in pairs(updates) do
        self:UpdateCharacterData(charID, data, false) -- Don't save yet
    end
    self:CommitChanges() -- Single save operation
end
```

---

## 11. Error Handling

### 11.1 Graceful Degradation

```lua
function PlayerDataBuilder:BuildPlayerObjectSafe(playerID)
    return NextKey222.SafeRun(function()
        local success, playerData = pcall(self.BuildPlayerObject, self, playerID)
        
        if not success then
            Debug:Error("Failed to build player object for", playerID, ":", playerData)
            
            -- Return minimal valid player object
            return {
                id = playerID,
                name = strsplit("-", playerID),
                roles = {"DPS"}, -- Assume DPS if unknown
                dataSource = "error",
                hasAddon = false,
                dataFreshness = "unknown"
            }
        end
        
        return playerData
    end, "PlayerDataBuilder:BuildPlayerObjectSafe")
end
```

---

## 12. Debug Integration

### 12.1 New Debug Categories

Add to [`core/debugService.lua`](../../../core/debugService.lua:1):

```lua
DEBUG_CATEGORIES = {
    -- Existing categories...
    
    -- New Organizer categories
    organizer = true,      -- General organizer activity
    storage = true,        -- Character storage operations
    autodetect = true,     -- Auto-detection system
    org_comms = true,      -- Organizer communication
    org_validation = true  -- Data validation
}
```

### 12.2 Debug Commands

```lua
-- Test character storage
/script NextKey222.CharacterStorage:DebugPrintAllCharacters()

-- Test auto-detection
/script NextKey222.OrganizerAutoDetection:TestScan()

-- Validate player data
/script NextKey222.OrganizerValidation:ValidateAllPlayers()
```

---

## 13. Implementation Checklist

- [ ] Create `core/characterStorage.lua` with AceDB profile integration
- [ ] Create character role configuration in Options UI
- [ ] Extend SavedVariables schema (migration logic)
- [ ] Create `core/types/player.lua` type definitions
- [ ] Create `core/organizer/autoDetection.lua` module
- [ ] Create `core/organizer/playerDataBuilder.lua` module
- [ ] Create `core/organizer/comms.lua` (extend existing comms)
- [ ] Add new communication opcodes
- [ ] Implement temporary player card logic
- [ ] Create `core/organizer/validation.lua` module
- [ ] Add debug categories and commands
- [ ] Write unit tests in `debug/organizer_foundation_tests.lua`
- [ ] Update `NextKey.toc` with new files
- [ ] Update load order in `boot.lua`
- [ ] Test data migration with existing saves
- [ ] Test with 20+ players (performance validation)

---

## 14. Dependencies for Next Phases

**Phase 1 (UI Framework) requires:**
- Player object structure (Section 2.1)
- Communication protocol (Section 3)
- Auto-detection system (Section 4)

**Phase 2 (Survey) requires:**
- Character storage (Section 1)
- Communication protocol (Section 3.2)
- Player data builder (Section 5)

**Phase 3 (Manual Mode) requires:**
- All Phase 0 components

**Phase 4 (Algorithms) requires:**
- Player object with scoring data (Section 2.1)
- Validation system (Section 8)

---

## 15. Known Limitations & Future Work

1. **Cross-Realm Alt Support:** Current design assumes alts are same-realm. Cross-realm requires additional API handling.
2. **Offline Alt Data:** No real-time updates for offline alts. Uses cached data.
3. **Role Configuration UI:** Basic implementation. Could be enhanced with spec auto-detection.
4. **Keystone Expiration:** Basic server reset detection. Could add dungeon-specific depletion tracking.

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** None  
**Next Document:** Phase 0.5 - Integration Strategy