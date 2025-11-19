local _, NextKey222 = ...

-- MARK: Score Calculations
-- =====================================================
-- Score retrieval and color calculation functions
-- Extracted from ui/main.lua for better organization
-- =====================================================

local ScoreCalculations = {}
NextKey222.ScoreCalculations = ScoreCalculations
NextKey222.RegisterModule("ScoreCalculations", ScoreCalculations)

-- MARK: Module State
-- Cache for dungeon level/chest data
ScoreCalculations.dungeonLevelCache = {}

-- MARK: Color Functions

--- Gets appropriate color for individual dungeon scores (proportional system)
-- @param score number The individual dungeon IO score
-- @return table RGB color values {r, g, b} (0-1)
function ScoreCalculations:GetDungeonScoreColor(score)
    if not score or score <= 0 then
        return {0.5, 0.5, 0.5} -- Gray for no score
    end
    
    -- Option 1: Try RaiderIO's system but scale appropriately for individual dungeons
    -- RaiderIO expects total scores, so multiply individual score to fit their ranges
    if NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        -- Scale individual score to RaiderIO's total score range
        -- Typical individual: 0-300, typical total: 0-4000
        -- So multiply by ~13 to get proportional coloring
        local scaledScore = score * 13
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(scaledScore)
        return {r, g, b}
    end
    
    -- Option 2: Use WoW's built-in dungeon score color system
    local color = C_ChallengeMode.GetDungeonScoreRarityColor(score * 13) -- Scale for better colors
    if color then
        return {color.r, color.g, color.b}
    end
    
    -- Option 3: Custom gradient system based on typical individual dungeon score ranges
    -- Individual dungeon scores typically range from 0-300+
    if score >= 250 then
        -- Legendary (orange/gold) - very high individual score
        return {1.0, 0.5, 0.0}
    elseif score >= 200 then
        -- Epic (purple) - high score  
        return {0.64, 0.21, 0.93}
    elseif score >= 150 then
        -- Rare (blue) - good score
        return {0.0, 0.44, 0.87}
    elseif score >= 100 then
        -- Uncommon (green) - decent score
        return {0.12, 1.0, 0.0}
    elseif score >= 50 then
        -- Common (white) - low score
        return {1.0, 1.0, 1.0}
    else
        -- Poor (gray) - very low score
        return {0.62, 0.62, 0.62}
    end
end

--- Formats total IO score with appropriate coloring (no scaling for total scores)
-- Uses the same color logic as player keystone cards for consistency
-- @param totalScore number The total IO score
-- @return string Colored total score text
function ScoreCalculations:FormatColoredTotalScore(totalScore)
    if not totalScore or totalScore <= 0 then
        return "|cFF808080Total IO: 0|r" -- Gray for zero
    end
    
    -- Use the same color logic as FormatPlayerNameWithScore for consistency
    local r, g, b = 1, 1, 1
    local colorHex

    -- Prefer Blizzard's official score color if available (same as player cards)
    if C_ChallengeMode and C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor then
        local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(totalScore)
        if color then
            r, g, b = color.r or r, color.g or g, color.b or b
        end
    end

    -- Fallback to RaiderIO gradient if Blizzard color unavailable (same as player cards)
    if (r == 1 and g == 1 and b == 1) and NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        local rioR, rioG, rioB = NextKey222.RaiderIO:GetScoreColor(totalScore)
        if rioR and rioG and rioB then
            r, g, b = rioR, rioG, rioB
        end
    end

    local function clampColorComponent(value, fallback)
        if type(value) ~= "number" then return fallback end
        if value < 0 then return 0 end
        if value > 1 then return 1 end
        return value
    end

    r = clampColorComponent(r, 1)
    g = clampColorComponent(g, 1)
    b = clampColorComponent(b, 1)

    colorHex = string.format("%02X%02X%02X", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    return string.format("|cFF%sTotal IO: %.0f|r", colorHex, totalScore)
end

-- MARK: Score Retrieval

--- Helper function to get dungeon score from WoW API (MrMythical approach)
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score for this dungeon from WoW API (0 if none)
function ScoreCalculations:GetRaiderIODungeonScore(dungeonID)
    -- Debug: Only for Ara-Kara to see WoW API data structure  
    local shouldDebug = (dungeonID == 503) -- Only Ara-Kara for cleaner output
    
    -- Convert NextKey dungeon ID to Challenge Mode map ID
    local mapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
    
    if shouldDebug then
        local playerName = UnitName("player")
        Debug:Dev("ui", "[Score Debug] Getting scores for dungeon " .. dungeonID .. " (mapID: " .. mapID .. ") for " .. playerName)
    end
    
    -- Use official WoW API to get season best scores (MrMythical addon approach)
    -- This is much simpler and more reliable than parsing RaiderIO data structures!
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    if shouldDebug then
        Debug:Dev("ui", "[Score Debug] C_MythicPlus.GetSeasonBestForMap(" .. mapID .. ") Results:")
        if intimeInfo then
            Debug:Dev("ui", "[Score Debug]   intimeInfo: level=" .. (intimeInfo.level or "nil") .. ", score=" .. (intimeInfo.dungeonScore or "nil"))
            if intimeInfo.durationSec then
                Debug:Dev("ui", "[Score Debug]   intimeInfo: duration=" .. intimeInfo.durationSec .. " seconds")
            end
        else
            Debug:Dev("ui", "[Score Debug]   intimeInfo: nil")
        end
        if overtimeInfo then
            Debug:Dev("ui", "[Score Debug]   overtimeInfo: level=" .. (overtimeInfo.level or "nil") .. ", score=" .. (overtimeInfo.dungeonScore or "nil"))
            if overtimeInfo.durationSec then
                Debug:Dev("ui", "[Score Debug]   overtimeInfo: duration=" .. overtimeInfo.durationSec .. " seconds")
            end
        else
            Debug:Dev("ui", "[Score Debug]   overtimeInfo: nil")
        end
    end
    
    -- Find the highest score between in-time and overtime runs
    local bestScore = 0
    local bestLevel = 0
    local isInTime = false
    
    if intimeInfo and intimeInfo.dungeonScore then
        bestScore = intimeInfo.dungeonScore
        bestLevel = intimeInfo.level or 0
        isInTime = true
    end
    
    if overtimeInfo and overtimeInfo.dungeonScore and overtimeInfo.dungeonScore > bestScore then
        bestScore = overtimeInfo.dungeonScore
        bestLevel = overtimeInfo.level or 0
        isInTime = false
    end
    
    if shouldDebug and bestScore > 0 then
        Debug:Dev("ui", "[Score Debug] Best score found: " .. bestScore .. " (level +" .. bestLevel .. ", " .. (isInTime and "in-time" or "overtime") .. ")")
    elseif shouldDebug then
        Debug:Dev("ui", "[Score Debug] No runs found for this dungeon")
    end
    
    -- Store level info for display formatting if we found data
    if bestScore > 0 then
        -- Estimate chests based on timing: in-time = at least 1 chest, overtime = 0 chests
        local estimatedChests = isInTime and 1 or 0
        self.dungeonLevelCache[dungeonID] = {level = bestLevel, chests = estimatedChests}
        
        if shouldDebug then
            Debug:Dev("ui", "[Score Debug] Cached level info: +" .. bestLevel .. " (" .. estimatedChests .. " chests)")
        end
        
        return bestScore
    end
    
    if shouldDebug then
        Debug:Dev("ui", "[Score Debug] No score found via WoW API for dungeon " .. dungeonID)
    end
    
    return 0
end

--- Retrieves the player's best score for a specific dungeon
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
function ScoreCalculations:GetDungeonScore(dungeonID)
    -- First try to get score from RaiderIO data (most current)
    local raiderIOScore = self:GetRaiderIODungeonScore(dungeonID)
    if raiderIOScore and raiderIOScore > 0 then
        return raiderIOScore
    end
    
    -- Fallback to saved data if RaiderIO data not available
    local addon = NextKey222.Addon
    if not (addon.db and addon.db.char and addon.db.char.mythicPlus) then
        if addon.db and addon.db.global and addon.db.global.debug and addon.db.global.debug.enabled then
            Debug:Dev("ui", " No mythicPlus data for dungeon score")
        end
        return 0
    end
    
    local seasonData = addon.db.char.mythicPlus.seasons
    local activeSeason = addon.db.char.mythicPlus.activeSeason
    
    if seasonData and activeSeason and seasonData[activeSeason] and seasonData[activeSeason].bestLevels then
        local dungeonScores = seasonData[activeSeason].bestLevels[dungeonID]
        if dungeonScores then
            -- Return the higher of fortified/tyrannical scores
            local fort = dungeonScores.fortified and dungeonScores.fortified.score or 0
            local tyr = dungeonScores.tyrannical and dungeonScores.tyrannical.score or 0
            return math.max(fort, tyr)
        end
    end
    return 0
end

--- Helper function to get best key level from RaiderIO profile data
-- @param dungeonID number The dungeon ID to get the level for
-- @return number The best key level for this dungeon from RaiderIO data (0 if none)
function ScoreCalculations:GetRaiderIOBestLevel(dungeonID)
    -- Try direct RaiderIO API access first
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            
            -- Method 1: Try sortedDungeons (most reliable)
            if mp.sortedDungeons and type(mp.sortedDungeons) == "table" then
                for _, dungeonProfile in ipairs(mp.sortedDungeons) do
                    if dungeonProfile.dungeon then
                        local dungeon = dungeonProfile.dungeon
                        -- Try multiple ID matching strategies
                        local matches = (
                            dungeon.keystone_instance == dungeonID or
                            dungeon.id == dungeonID or
                            dungeon.instance_map_id == dungeonID
                        )
                        
                        if matches then
                            return dungeonProfile.level or 0
                        end
                    end
                end
            end
            
            -- Method 2: Try dungeon level arrays
            if mp.dungeonTimes and mp.dungeonUpgrades then
                local seasonIndex = NextKey222.Utils:GetSeasonDungeonIndex(dungeonID)
                if seasonIndex then
                    -- Get level from upgrades (which correlates to key level)
                    local upgrades = mp.dungeonUpgrades[seasonIndex] or 0
                    if upgrades > 0 then
                        -- Upgrades typically correspond to key levels in some fashion
                        return upgrades + 1 -- Rough approximation
                    end
                end
            end
        end
    end
    
    -- Fallback to NextKey222 RaiderIO module
    if NextKey222.RaiderIO then
        local profile = NextKey222.RaiderIO:GetProfile(UnitName("player"), GetRealmName())
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            local bestLevel = 0
            
            if mp.fortifiedDungeonScores and mp.fortifiedDungeonScores[dungeonID] then
                bestLevel = math.max(bestLevel, mp.fortifiedDungeonScores[dungeonID].level or 0)
            end
            if mp.tyrannicalDungeonScores and mp.tyrannicalDungeonScores[dungeonID] then
                bestLevel = math.max(bestLevel, mp.tyrannicalDungeonScores[dungeonID].level or 0)
            end
            
            return bestLevel
        end
    end
    
    return 0
end

--- Retrieves the player's best key level for a specific dungeon
-- @param dungeonID number The dungeon ID to get the best level for
-- @return number The highest key level completed for this dungeon (0 if none)
function ScoreCalculations:GetBestLevel(dungeonID)
    -- First try to get level from RaiderIO data (most current)
    local raiderIOLevel = self:GetRaiderIOBestLevel(dungeonID)
    if raiderIOLevel and raiderIOLevel > 0 then
        return raiderIOLevel
    end
    
    -- Fallback to saved data if RaiderIO data not available
    local addon = NextKey222.Addon
    if not (addon.db and addon.db.char and addon.db.char.mythicPlus) then
        return 0
    end
    
    local seasonData = addon.db.char.mythicPlus.seasons
    local activeSeason = addon.db.char.mythicPlus.activeSeason
    
    if seasonData and activeSeason and seasonData[activeSeason] and seasonData[activeSeason].bestLevels then
        local dungeonScores = seasonData[activeSeason].bestLevels[dungeonID]
        if dungeonScores then
            -- Return the higher level of fortified/tyrannical runs
            local fortLevel = dungeonScores.fortified and dungeonScores.fortified.level or 0
            local tyrLevel = dungeonScores.tyrannical and dungeonScores.tyrannical.level or 0
            return math.max(fortLevel, tyrLevel)
        end
    end
    
    return 0
end

--- Retrieves the player's IO score contribution from a specific dungeon
-- @param dungeonID number The dungeon ID to get the IO score for
-- @return number The IO score from this dungeon (0 if none)
function ScoreCalculations:GetDungeonIOScore(dungeonID)
    local currentPlayerName = UnitName("player")
    
    -- Use IOCalculator unified method if available
    if NextKey222.IOCalculator and currentPlayerName then
        local score = NextKey222.IOCalculator:GetPlayerDungeonScore(currentPlayerName, dungeonID)
        if score > 0 then
            return score
        end
    end
    
    -- Fallback to direct RaiderIO integration for current player
    local ioScore = self:GetRaiderIODungeonScore(dungeonID)
    
    if ioScore and ioScore > 0 then
        -- Store in IOCalculator for future use
        if NextKey222.IOCalculator and currentPlayerName then
            NextKey222.IOCalculator:StorePlayerDungeonScore(currentPlayerName, dungeonID, ioScore)
        end
        return ioScore
    end
    
    -- Final fallback to regular dungeon score
    return self:GetDungeonScore(dungeonID) or 0
end

--- Gets the best level and chests for a dungeon (for display purposes)
-- @param dungeonID number The dungeon ID
-- @return number, number level, chests (0 if not found)
function ScoreCalculations:GetDungeonLevelAndChests(dungeonID)
    -- Check cache first (populated during score calculation)
    if self.dungeonLevelCache and self.dungeonLevelCache[dungeonID] then
        local cached = self.dungeonLevelCache[dungeonID]
        return cached.level or 0, cached.chests or 0
    end
    
    -- Try to get from RaiderIO directly
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            local bestLevel = 0
            local bestChests = 0
            
            -- Use sortedDungeons to find best level and chests
            if mp.sortedDungeons and type(mp.sortedDungeons) == "table" then
                local rioKeystoneID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
                for _, dungeonProfile in ipairs(mp.sortedDungeons) do
                    if dungeonProfile.dungeon then
                        local dungeon = dungeonProfile.dungeon
                        if dungeon.keystone_instance == rioKeystoneID then
                            local level = dungeonProfile.level or 0
                            local chests = dungeonProfile.chests or 0
                            if level > bestLevel then
                                bestLevel = level
                                bestChests = chests
                            end
                        end
                    end
                end
            end
            
            return bestLevel, bestChests
        end
    end
    
    return 0, 0
end

-- MARK: Initialization

function ScoreCalculations:Initialize()
    Debug:Dev("scorecalculations", "ScoreCalculations module initialized")
    return true
end

return ScoreCalculations