-- MARK: Module Definition
-- Type definitions for M+ Group Organizer
-- Defines data structures for players, keystones, and groups

local _, NextKey222 = ...

-- Type definitions module - no registration needed as it's just data structures
local PlayerTypes = {}

-- MARK: Player Object Structure
-- Complete player data structure for Group Organizer
PlayerTypes.PlayerObject = {
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
    keystone = nil, -- Will be populated with KeystoneObject structure
    
    -- Scoring Data
    scores = {
        -- [dungeonID] = score, -- map of dungeon scores
        -- Example: [503] = 285.5
    },
    overallScore = 2850,
    
    -- Preferences (per character)
    preferences = {
        -- [dungeonID] = -1/0/1, -- -1=Dislike, 0=Neutral, 1=Like
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

-- MARK: Keystone Object Structure
-- Keystone data structure
PlayerTypes.KeystoneObject = {
    dungeonID = 503, -- integer
    level = 15, -- integer
    ownerID = "PlayerName-Realm" -- string
}

-- MARK: Group Object Structure
-- Group composition and scoring data
PlayerTypes.GroupObject = {
    -- Group Composition
    players = {}, -- list of 5 Player objects
    
    -- Keystone Selection
    chosenKeystone = PlayerTypes.KeystoneObject or nil,
    
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

-- MARK: Survey Response Structure
-- Data collected from participant survey
PlayerTypes.SurveyResponse = {
    pollID = "unique-poll-id",
    playerID = "PlayerName-Realm",
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
        keystone = PlayerTypes.KeystoneObject,
        scores = {}
    },
    timestamp = 1729742400
}

-- MARK: Communication Message Structures
-- Message formats for organizer communication

-- Poll Request Message
PlayerTypes.PollRequestMessage = {
    opcode = "ORG_POLL_REQUEST",
    version = "0.3.0",
    timestamp = GetTime(),
    sender = "LeaderName-Realm",
    data = {
        pollID = "unique-poll-id",
        timeout = 60 -- seconds to respond
    }
}

-- Poll Response Message
PlayerTypes.PollResponseMessage = {
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

-- Roster State Update (Delta) Message
PlayerTypes.RosterDeltaMessage = {
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

-- MARK: Validation Functions
-- Helper functions to validate data structures

--- Validate Player Object structure
-- @param player table Player object to validate
-- @return boolean isValid, table errors
function PlayerTypes.ValidatePlayerObject(player)
    local errors = {}
    
    -- Required fields
    if not player or type(player) ~= "table" then
        table.insert(errors, "Player object is not a table")
        return false, errors
    end
    
    if not player.id or type(player.id) ~= "string" then
        table.insert(errors, "Missing or invalid player ID")
    end
    
    if not player.name or type(player.name) ~= "string" then
        table.insert(errors, "Missing or invalid player name")
    end
    
    if not player.class or type(player.class) ~= "string" then
        table.insert(errors, "Missing or invalid player class")
    end
    
    if not player.roles or type(player.roles) ~= "table" or #player.roles == 0 then
        table.insert(errors, "Player must have at least one role")
    end
    
    -- Score validation
    if player.scores then
        for dungeonID, score in pairs(player.scores) do
            if type(score) ~= "number" or score < 0 then
                table.insert(errors, "Invalid score for dungeon " .. tostring(dungeonID))
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

--- Validate Keystone Object structure
-- @param keystone table Keystone object to validate
-- @return boolean isValid, table errors
function PlayerTypes.ValidateKeystoneObject(keystone)
    local errors = {}
    
    if not keystone or type(keystone) ~= "table" then
        table.insert(errors, "Keystone object is not a table")
        return false, errors
    end
    
    if not keystone.dungeonID or type(keystone.dungeonID) ~= "number" then
        table.insert(errors, "Missing or invalid dungeon ID")
    end
    
    if not keystone.level or type(keystone.level) ~= "number" then
        table.insert(errors, "Missing or invalid keystone level")
    elseif keystone.level < 2 or keystone.level > 40 then
        table.insert(errors, "Keystone level out of valid range (2-40)")
    end
    
    if not keystone.ownerID or type(keystone.ownerID) ~= "string" then
        table.insert(errors, "Missing or invalid owner ID")
    end
    
    return #errors == 0, errors
end

--- Validate Group Object structure
-- @param group table Group object to validate
-- @return boolean isValid, table errors
function PlayerTypes.ValidateGroupObject(group)
    local errors = {}
    
    if not group or type(group) ~= "table" then
        table.insert(errors, "Group object is not a table")
        return false, errors
    end
    
    if not group.players or type(group.players) ~= "table" then
        table.insert(errors, "Missing or invalid players list")
    elseif #group.players ~= 5 then
        table.insert(errors, "Group must have exactly 5 players")
    end
    
    -- Validate each player
    if group.players then
        for i, player in ipairs(group.players) do
            local isValid, playerErrors = PlayerTypes.ValidatePlayerObject(player)
            if not isValid then
                table.insert(errors, "Invalid player at position " .. i .. ": " .. table.concat(playerErrors, ", "))
            end
        end
    end
    
    -- Validate keystone if present
    if group.chosenKeystone then
        local isValid, keystoneErrors = PlayerTypes.ValidateKeystoneObject(group.chosenKeystone)
        if not isValid then
            table.insert(errors, "Invalid chosen keystone: " .. table.concat(keystoneErrors, ", "))
        end
    end
    
    return #errors == 0, errors
end

-- MARK: Utility Functions
-- Helper functions for working with data structures

--- Create a new player object with default values
-- @param id string Player ID
-- @param name string Player name
-- @param realm string Player realm
-- @param class string Player class
-- @return table New player object
function PlayerTypes.CreatePlayerObject(id, name, realm, class)
    return {
        id = id or "",
        name = name or "",
        realm = realm or "",
        class = class or "",
        level = 80,
        roles = {},
        utils = {},
        keystone = nil,
        scores = {},
        overallScore = 0,
        preferences = {},
        rankScore = 0,
        isTemporary = false,
        sourceCharacter = nil,
        dataSource = "unknown",
        hasAddon = false,
        dataFreshness = "unknown",
        surveyResponse = nil
    }
end

--- Create a new keystone object
-- @param dungeonID number Dungeon ID
-- @param level number Keystone level
-- @param ownerID string Owner player ID
-- @return table New keystone object
function PlayerTypes.CreateKeystoneObject(dungeonID, level, ownerID)
    return {
        dungeonID = dungeonID or 0,
        level = level or 0,
        ownerID = ownerID or ""
    }
end

--- Create a new group object
-- @param groupIndex number Group index (1-based)
-- @return table New group object
function PlayerTypes.CreateGroupObject(groupIndex)
    return {
        players = {},
        chosenKeystone = nil,
        totalGain = 0,
        totalScore = 0,
        isValid = true,
        validationErrors = {},
        groupIndex = groupIndex or 1,
        headerText = "M+ Grp. " .. (groupIndex or 1)
    }
end

--- Clone a player object (deep copy)
-- @param player table Player object to clone
-- @return table Cloned player object
function PlayerTypes.ClonePlayerObject(player)
    if not player then return nil end
    
    local clone = {}
    for key, value in pairs(player) do
        if type(value) == "table" then
            clone[key] = PlayerTypes.ClonePlayerObject(value) -- Recursive copy
        else
            clone[key] = value
        end
    end
    
    return clone
end

-- Export the types module
NextKey222.PlayerTypes = PlayerTypes

return PlayerTypes