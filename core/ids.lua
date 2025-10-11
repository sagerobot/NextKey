-- MARK: Canonical ID Mapper Module
-- This module provides a single source of truth for all dungeon ID mappings
-- and conversions between different systems (Blizzard APIs, RaiderIO, NextKey internal, etc.)

local _, NextKey222 = ...

-- MARK: Core ID Mappings
-- Define the canonical mapping between different ID systems
local IDMappings = {
    -- Canonical NextKey Dungeon IDs -> Other Systems
    -- Format: [nextKeyDungeonID] = { challengeMapID, raiderIOID, keystoneID, blizzardMapID }
    [503] = { challengeMapID = 503, raiderIOID = 503, keystoneID = 503, blizzardMapID = 503 },  -- Ara-Kara, City of Echoes
    [505] = { challengeMapID = 524, raiderIOID = 542, keystoneID = 542, blizzardMapID = 524 },  -- The Dawnbreaker
    [542] = { challengeMapID = 526, raiderIOID = 542, keystoneID = 542, blizzardMapID = 526 },  -- Eco-Dome Al'dani  
    [378] = { challengeMapID = 377, raiderIOID = 378, keystoneID = 378, blizzardMapID = 377 },  -- Halls of Atonement
    [525] = { challengeMapID = 525, raiderIOID = 525, keystoneID = 525, blizzardMapID = 525 },  -- Operation: Floodgate
    [499] = { challengeMapID = 523, raiderIOID = 499, keystoneID = 499, blizzardMapID = 523 },  -- Priory of the Sacred Flame
    [391] = { challengeMapID = 401, raiderIOID = 391, keystoneID = 391, blizzardMapID = 401 },  -- Tazavesh: Streets of Wonder
    [392] = { challengeMapID = 402, raiderIOID = 392, keystoneID = 392, blizzardMapID = 402 },  -- Tazavesh: So'leah's Gambit
    [2441] = { challengeMapID = 402, raiderIOID = 392, keystoneID = 2441, blizzardMapID = 402 }, -- So'leah's Gambit (keystone form)
}

-- Reverse lookup tables (built dynamically)
local ChallengeMapToNextKey = {}
local RaiderIOToNextKey = {}
local KeystoneToNextKey = {}
local BlizzardMapToNextKey = {}

-- Build reverse lookup tables
for nextKeyID, mappings in pairs(IDMappings) do
    if mappings.challengeMapID then
        ChallengeMapToNextKey[mappings.challengeMapID] = nextKeyID
    end
    if mappings.raiderIOID then
        RaiderIOToNextKey[mappings.raiderIOID] = nextKeyID
    end
    if mappings.keystoneID then
        KeystoneToNextKey[mappings.keystoneID] = nextKeyID
    end
    if mappings.blizzardMapID then
        BlizzardMapToNextKey[mappings.blizzardMapID] = nextKeyID
    end
end

-- MARK: ID Conversion Functions
local IDMapper = {}

-- Convert any source ID to canonical NextKey dungeon ID
function IDMapper:ToDungeonID(sourceID, sourceType)
    if not sourceID then return nil end
    
    -- If no source type specified, try to auto-detect
    if not sourceType then
        -- First check if it's already a NextKey ID
        if IDMappings[sourceID] then
            return sourceID
        end
        
        -- Try other reverse lookups
        return ChallengeMapToNextKey[sourceID] or 
               RaiderIOToNextKey[sourceID] or 
               KeystoneToNextKey[sourceID] or 
               BlizzardMapToNextKey[sourceID] or 
               sourceID -- Fallback to original
    end
    
    -- Specific source type conversion
    if sourceType == "challenge" then
        return ChallengeMapToNextKey[sourceID] or sourceID
    elseif sourceType == "raiderio" then
        return RaiderIOToNextKey[sourceID] or sourceID
    elseif sourceType == "keystone" then
        return KeystoneToNextKey[sourceID] or sourceID
    elseif sourceType == "blizzard" then
        return BlizzardMapToNextKey[sourceID] or sourceID
    else
        return sourceID
    end
end

-- Convert NextKey dungeon ID to Challenge Mode map ID
function IDMapper:ChallengeMapToDungeonID(challengeMapID)
    return ChallengeMapToNextKey[challengeMapID] or challengeMapID
end

-- Convert NextKey dungeon ID to specific target system
function IDMapper:ToTargetID(nextKeyDungeonID, targetType)
    local mappings = IDMappings[nextKeyDungeonID]
    if not mappings then return nextKeyDungeonID end
    
    if targetType == "challenge" then
        return mappings.challengeMapID
    elseif targetType == "raiderio" then
        return mappings.raiderIOID
    elseif targetType == "keystone" then
        return mappings.keystoneID
    elseif targetType == "blizzard" then
        return mappings.blizzardMapID
    else
        return nextKeyDungeonID
    end
end

-- MARK: Active Season Functions
-- Get list of active season dungeon IDs (canonical NextKey format)
function IDMapper:GetActiveSeasonDungeonIDs()
    local dungeonIDs = {}
    
    -- First try to get from Blizzard API
    local seasonID = C_MythicPlus and C_MythicPlus.GetCurrentSeason and C_MythicPlus.GetCurrentSeason()
    if seasonID then
        local maps = C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable()
        if maps then
            for _, challengeMapID in ipairs(maps) do
                -- Verify the map is valid and convert to NextKey ID
                if C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(challengeMapID) then
                    local nextKeyID = self:ChallengeMapToDungeonID(challengeMapID)
                    if nextKeyID then
                        table.insert(dungeonIDs, nextKeyID)
                    end
                end
            end
        end
    end
    
    -- Fallback to hardcoded list from portal data
    if #dungeonIDs == 0 then
        -- Get from NextKey.PortalData if available
        if NextKey222.Addon and NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons then
            for dungeonID, _ in pairs(NextKey222.Addon.PortalData.dungeons) do
                table.insert(dungeonIDs, dungeonID)
            end
        else
            -- Ultimate fallback - hardcoded current season (TWW S3)
            dungeonIDs = { 503, 524, 526, 377, 525, 523, 401, 402 }
        end
    end
    
    -- Sort for consistency
    table.sort(dungeonIDs)
    return dungeonIDs
end

-- Validate if a dungeon ID is part of the current season
function IDMapper:IsActiveSeasonDungeon(dungeonID)
    local activeDungeons = self:GetActiveSeasonDungeonIDs()
    for _, activeDungeonID in ipairs(activeDungeons) do
        if activeDungeonID == dungeonID then
            return true
        end
    end
    return false
end

-- Get comprehensive mapping info for a dungeon ID
function IDMapper:GetMappingInfo(dungeonID)
    local mappings = IDMappings[dungeonID]
    if not mappings then
        -- Try reverse lookup
        local nextKeyID = self:ToDungeonID(dungeonID)
        mappings = IDMappings[nextKeyID]
    end
    
    return mappings and {
        nextKeyID = dungeonID,
        challengeMapID = mappings.challengeMapID,
        raiderIOID = mappings.raiderIOID,
        keystoneID = mappings.keystoneID,
        blizzardMapID = mappings.blizzardMapID
    } or nil
end

-- MARK: Legacy Compatibility Functions
-- These maintain compatibility with existing code during transition

-- Legacy function: ConvertToRaiderIOKeystoneID
function IDMapper:ConvertToRaiderIOKeystoneID(dungeonID)
    return self:ToTargetID(dungeonID, "raiderio")
end

-- Legacy function: ConvertChallengeMapToKeystoneID
function IDMapper:ConvertChallengeMapToKeystoneID(challengeMapID)
    local nextKeyID = self:ChallengeMapToDungeonID(challengeMapID)
    return self:ToTargetID(nextKeyID, "keystone")
end

-- MARK: Export to NextKey222 namespace
NextKey222.IDMapper = IDMapper

-- Also attach to addon instance when available for backward compatibility
if NextKey222.Addon then
    NextKey222.Addon.IDMapper = IDMapper
    
    -- Provide legacy method access
    NextKey222.Addon.GetActiveSeasonDungeonIDs = function(self)
        return IDMapper:GetActiveSeasonDungeonIDs()
    end
    
    NextKey222.Addon.ConvertToRaiderIOKeystoneID = function(self, dungeonID)
        return IDMapper:ConvertToRaiderIOKeystoneID(dungeonID)
    end
    
    NextKey222.Addon.ConvertChallengeMapToKeystoneID = function(self, challengeMapID)
        return IDMapper:ConvertChallengeMapToKeystoneID(challengeMapID)
    end
end