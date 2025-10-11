-- MARK: Season Data Management
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- Season module
local Season = {}
NextKey222.Season = Season

-- Register with module system
NextKey222.RegisterModule("Season", Season)

---@class SeasonData
---@field currentScore number Current season M+ score
---@field previousScore number Previous season M+ score
---@field dungeonScores table<number, DungeonScores> Per-dungeon performance
---@field runCounts RunCounts Run counts at different key levels
---@field roleData table<string, RolePerformance> Performance by role

---@class DungeonScores
---@field fortified DungeonRunInfo? Fortified affix best run
---@field tyrannical DungeonRunInfo? Tyrannical affix best run

---@class DungeonRunInfo
---@field score number Run score
---@field level number Key level
---@field chests number Number of medals/chests (0-3)
---@field fractionalTime number? Time completion ratio

---@class RunCounts
---@field plus5 number Number of +5 or higher
---@field plus10 number Number of +10 or higher
---@field plus15 number Number of +15 or higher
---@field plus20 number Number of +20 or higher

---@class RolePerformance
---@field status "full"|"partial" Role completion status
---@field score number Role-specific score

---@class MapScore
---@field durationSec number Run duration in seconds
---@field completedInTime boolean Whether run was completed in time
---@field level number Keystone level
---@field fortifiedScore number? Score for fortified affix
---@field tyrannicalScore number? Score for tyrannical affix

---@class SeasonBestRun
---@field durationSec number Run duration in seconds
---@field level number Keystone level
---@field completedInTime boolean Whether run was completed in time
---@field affixIDs number[] Active affixes during the run

-- MARK: Season Initialization
function NextKey:EnsureSeasonData()
    -- Set current season key from MythicPlus API
    local currentSeason = C_MythicPlus.GetCurrentSeason()
    if currentSeason then
        self.CurrentSeasonKey = "S" .. tostring(currentSeason)
    else
        -- Fallback to default if API fails
        self.CurrentSeasonKey = "TWW_S3"
    end

    -- Cache dungeon IDs
    self.currentSeasonDungeons = self:GetActiveSeasonDungeonIDs()

    -- Initialize season scores
    local scoreData = self:GetCurrentSeasonData()
    self.currentSeasonScore = scoreData.currentScore
    self.previousSeasonScore = scoreData.previousScore
end

-- MARK: Season Data
function NextKey:GetActiveSeasonDungeonIDs()
    local dungeonIDs = {}
    local seasonID = C_MythicPlus.GetCurrentSeason()
    if not seasonID then
        return dungeonIDs
    end

    -- Get current season dungeons from the API
    local maps = C_ChallengeMode.GetMapTable()
    if maps then
        for _, mapID in ipairs(maps) do
            -- Verify the map is valid
            if C_ChallengeMode.GetMapUIInfo(mapID) then
                table.insert(dungeonIDs, mapID)
            end
        end
    end

    -- Fallback to hardcoded list if API fails
    if #dungeonIDs == 0 then
        dungeonIDs = { 503, 524, 526, 377, 525, 523, 401, 402 } -- Dawn of the Infinite, etc.
    end

    return dungeonIDs
end

-- MARK: Season Score Data 
function NextKey:GetCurrentSeasonData()
    local data = {
        currentScore = 0,
        previousScore = 0,
        dungeonScores = {},
        runCounts = {},
        roleData = {}
    }

    -- Get comprehensive RaiderIO data
    local profile = _G.RaiderIO and _G.RaiderIO.GetProfile and _G.RaiderIO.GetProfile("player")
    if profile then
        local p = profile.mythicKeystoneProfile
        data.currentScore = p.currentScore or 0
        data.previousScore = p.previousScore or 0
        
        -- Get per-dungeon scores
        if _G.RaiderIO and _G.RaiderIO.FormatDungeonScores then
            data.dungeonScores = _G.RaiderIO.FormatDungeonScores(profile)
        end
        
        -- Get run counts
        if _G.RaiderIO and _G.RaiderIO.GetRunCounts then
            data.runCounts = _G.RaiderIO.GetRunCounts(profile)
        end
        
        -- Get role performance data
        if _G.RaiderIO and _G.RaiderIO.GetRoleData then
            data.roleData = _G.RaiderIO.GetRoleData(profile)
        end
    end

    -- Fallback to game API for current score if needed
    if data.currentScore == 0 then
        local currentScore = C_ChallengeMode.GetOverallDungeonScore()
        if currentScore and currentScore > 0 then
            data.currentScore = currentScore
        end
    end

    return data
end

-- MARK: Dungeon Names
function NextKey:GetDungeonName(dungeonID)
    if not dungeonID then return nil end
    
    -- Hardcoded mappings for known problematic IDs
    local knownMappings = {
        [2441] = "Tazavesh: So'leah's Gambit",  -- mapID (based on user feedback)
        [391] = "Tazavesh: So'leah's Gambit"    -- challengeMapID (based on Details addon test data)
    }
    
    if knownMappings[dungeonID] then
        NextKey222.Debug:Print("season", "GetDungeonName: Using hardcoded mapping for " .. dungeonID .. " = " .. knownMappings[dungeonID])
        return knownMappings[dungeonID]
    end
    
    -- Try Challenge Mode API first
    local info = C_ChallengeMode.GetMapUIInfo(dungeonID)
    if info then
        NextKey222.Debug:Print("season", "GetDungeonName: C_ChallengeMode.GetMapUIInfo(" .. dungeonID .. ") = " .. info)
        return info
    end
    
    -- Try alternative APIs for dungeon names
    if C_LFGInfo and C_LFGInfo.GetDungeonInfo then
        local dungeonInfo = C_LFGInfo.GetDungeonInfo(dungeonID)
        if dungeonInfo and dungeonInfo.name then
            NextKey222.Debug:Print("season", "GetDungeonName: C_LFGInfo.GetDungeonInfo(" .. dungeonID .. ") = " .. dungeonInfo.name)
            return dungeonInfo.name
        end
    end
    
    -- Try map name API
    if C_Map and C_Map.GetMapInfo then
        local mapInfo = C_Map.GetMapInfo(dungeonID)
        if mapInfo and mapInfo.name then
            NextKey222.Debug:Print("season", "GetDungeonName: C_Map.GetMapInfo(" .. dungeonID .. ") = " .. mapInfo.name)
            return mapInfo.name
        end
    end
    
    NextKey222.Debug:Print("season", "GetDungeonName: No name found for dungeonID " .. dungeonID)
    return nil
end

-- MARK: Season Best Data
function NextKey:GetSeasonBestEntry(dungeonID)
    if not dungeonID then return nil end

    local seasonData = self:GetCurrentSeasonData()
    if seasonData.dungeonScores and seasonData.dungeonScores[dungeonID] then
        -- Get best score between fortified and tyrannical
        local fort = seasonData.dungeonScores[dungeonID].fortified
        local tyr = seasonData.dungeonScores[dungeonID].tyrannical
        
        local bestScore = 0
        local bestLevel = 0
        
        if fort then
            bestScore = fort.score
            bestLevel = fort.level
        end
        
        if tyr and tyr.score > bestScore then
            bestScore = tyr.score
            bestLevel = tyr.level
        end
        
        return {
            dungeonID = dungeonID,
            level = bestLevel,
            score = bestScore
        }
    end
    
    -- Fallback to game API if no RaiderIO data
    local mapScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(dungeonID)
    local bestRunLevel = C_MythicPlus.GetSeasonBestForMap(dungeonID)
    
    if mapScore and bestRunLevel then
        return {
            dungeonID = dungeonID,
            level = bestRunLevel.level or 0,
            score = (mapScore.fortifiedScore or mapScore.tyrannicalScore or 0)
        }
    end
    
    return nil
end