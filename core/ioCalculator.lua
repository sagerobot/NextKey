-- MARK: IO Calculator Module
-- Rating calculation logic based on MythicPlanner.com algorithm
-- Implements the exact formulas used by mythicplanner.com for accurate IO gain predictions

local IOCalculator = {
    -- MARK: Player Score Storage
    -- Stores dungeon-specific scores for all players (real and fake)
    playerScores = {},
    fakePlayerScores = {}
}
NextKey222.IOCalculator = IOCalculator
NextKey222.RegisterModule("IOCalculator", IOCalculator)

-- MARK: Dungeon Base Score Matrix
-- Base scores for each key level (based on MythicPlanner.com data)
local dungeonMatrix = {
    [2] = { base = 155, min = 125, max = 170 },
    [3] = { base = 170, min = 140, max = 185 },
    [4] = { base = 200, min = 170, max = 215 },
    [5] = { base = 215, min = 185, max = 230 },
    [6] = { base = 230, min = 200, max = 245 },
    [7] = { base = 260, min = 230, max = 275 },
    [8] = { base = 275, min = 245, max = 290 },
    [9] = { base = 290, min = 260, max = 305 },
    [10] = { base = 320, min = 290, max = 335 },
    [11] = { base = 335, min = 290, max = 350 },
    [12] = { base = 365, min = 290, max = 380 },
    [13] = { base = 380, min = 290, max = 395 },
    [14] = { base = 395, min = 290, max = 410 },
    [15] = { base = 410, min = 290, max = 425 },
    [16] = { base = 425, min = 290, max = 440 },
    [17] = { base = 440, min = 290, max = 455 },
    [18] = { base = 455, min = 290, max = 470 },
    [19] = { base = 470, min = 290, max = 485 },
    [20] = { base = 485, min = 290, max = 500 },
}

-- MARK: Initialization & Setup
function IOCalculator:Initialize()
    self.playerScores = {}
    self.fakePlayerScores = {}
    NextKey222.Debug:Print("IOCalculator", "Initialized with MythicPlanner.com algorithm")
    return true
end

-- MARK: Utility Functions for Score Estimation
-- These functions provide utility for score estimation and time approximation

-- Convert number of chests achieved to approximate fractional completion time
function IOCalculator:ApproximateFractionalFromChests(chests)
    if not chests or chests < 0 then return 1.0 end
    if chests > 3 then chests = 3 end
    
    -- Convert number of chests to a fractional completion time
    local fractions = {
        [3] = 0.6,  -- 3 chests = 60% of timer (very fast)
        [2] = 0.75, -- 2 chests = 75% of timer (fast)  
        [1] = 0.9,  -- 1 chest  = 90% of timer (close)
        [0] = 1.0   -- 0 chests = 100% of timer (at timer)
    }
    
    return fractions[chests] or 1.0
end

-- Simple score estimation for debug/testing purposes
-- For accurate scoring, use CalculateDungeonScore() with actual run/time limit data
function IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    level = tonumber(level) or 0
    if level < 2 then return 0 end
    
    -- Get metrics for this key level to use as baseline
    local metrics = self:GetDungeonMetrics(level)
    if not metrics then return 0 end
    
    -- Start with base score for the level
    local score = metrics.base
    
    -- Apply timing modifier
    if not timed then
        -- Untimed runs get reduced score
        score = score * 0.5
    elseif fractionalTime and fractionalTime < 1.0 then
        -- Bonus for faster completion times
        local timeBonus = (1.0 - fractionalTime) * 0.4 * metrics.base
        score = score + timeBonus
    end
    
    return math.floor(score + 0.5)
end



-- MARK: Core Rating Calculations
-- Calculate dungeon score using MythicPlanner.com formula
-- PT = Min[ (TLimit - TRun) / TLimit , 0.40 ]
-- Rating = BaseLevel + (PT * 37.5) - (overtime penalty of 15 if over time)
function IOCalculator:CalculateDungeonScore(runTime, timeLimit, keyLevel)
    if not runTime or not timeLimit or not keyLevel then
        return 0
    end
    
    -- Get base score for this key level
    local metrics = self:GetDungeonMetrics(keyLevel)
    if not metrics then
        return 0
    end
    
    -- Calculate time percentage (capped at 40%)
    local timeDiff = timeLimit - runTime
    local timePercent = timeDiff / timeLimit
    local cappedPercent = math.min(math.abs(timePercent), 0.4)
    
    -- Apply sign for over/under time
    local correctedPercent = cappedPercent * (timeDiff >= 0 and 1 or -1)
    
    -- Calculate final rating
    local rating = metrics.base + (correctedPercent * 37.5)
    
    -- Apply overtime penalty
    if runTime > timeLimit then
        rating = rating - 15
    end
    
    -- Ensure minimum rating (0 if over 40% time)
    if math.abs(timePercent) > 0.4 then
        return 0
    end
    
    return math.max(0, rating)
end

-- MARK: Dungeon Metrics Lookup
-- Get base/min/max scores for a key level
function IOCalculator:GetDungeonMetrics(keyLevel)
    if keyLevel <= 0 then
        return nil
    end
    
    -- Use predefined matrix for levels 2-20
    if dungeonMatrix[keyLevel] then
        return dungeonMatrix[keyLevel]
    end
    
    -- Calculate for higher levels (21+)
    -- Formula: Base = 145 + (level * 15) + 40 (for 4 affixes)
    if keyLevel > 20 then
        local base = 145 + (keyLevel * 15) + 40
        return {
            base = base,
            min = 290, -- Min stays at 290 for 11+
            max = base + 15
        }
    end
    
    return nil
end

-- MARK: Player Score Analysis
-- Calculate what key level a player needs for a target score in a specific dungeon
function IOCalculator:GetRequiredKeyLevel(targetScore, dungeonTimeLimit)
    if not targetScore or targetScore <= 0 then
        return nil
    end
    
    -- Try each key level to find the minimum one that can achieve target score
    for level = 2, 30 do
        local metrics = self:GetDungeonMetrics(level)
        if metrics and metrics.max >= targetScore then
            -- Calculate required time to achieve target score
            local requiredTime = self:GetRequiredTime(targetScore, level, dungeonTimeLimit)
            if requiredTime and requiredTime > 0 then
                return {
                    keyLevel = level,
                    requiredTime = requiredTime,
                    maxPossibleScore = metrics.max,
                    baseScore = metrics.base
                }
            end
        end
    end
    
    return nil
end

-- MARK: Time Requirement Calculations  
-- Calculate required completion time to achieve target score
function IOCalculator:GetRequiredTime(targetScore, keyLevel, timeLimit)
    local metrics = self:GetDungeonMetrics(keyLevel)
    if not metrics or not timeLimit then
        return nil
    end
    
    -- If target score is higher than max possible, can't be achieved
    if targetScore > metrics.max then
        return nil
    end
    
    -- If target score is the base score, finish exactly on time
    if targetScore == metrics.base then
        return timeLimit
    end
    
    -- Calculate required time percentage
    -- targetScore = base + (timePercent * 37.5) - overtime_penalty
    -- Rearrange: timePercent = (targetScore - base + overtime_penalty) / 37.5
    
    local overtimePenalty = 0
    local adjustedTarget = targetScore
    
    -- Check if this requires overtime (score below base - 15)
    if targetScore < (metrics.base - 15) then
        overtimePenalty = 15
        adjustedTarget = targetScore + 15
    end
    
    local requiredTimePercent = (adjustedTarget - metrics.base) / 37.5
    
    -- Cap at 40% (both positive and negative)
    if math.abs(requiredTimePercent) > 0.4 then
        return nil -- Impossible to achieve
    end
    
    -- Calculate actual completion time
    -- timePercent = (timeLimit - runTime) / timeLimit
    -- runTime = timeLimit - (timePercent * timeLimit)
    local requiredTime = timeLimit - (requiredTimePercent * timeLimit)
    
    return math.max(0, requiredTime)
end

-- MARK: Player Improvement Analysis
-- Analyze a player's current scores and suggest improvements
function IOCalculator:AnalyzePlayerImprovement(playerProfile, targetOverallRating)
    if not playerProfile or not targetOverallRating then
        return {}
    end
    
    local suggestions = {}
    local currentTotal = 0
    local dungeonCount = 0
    
    -- Calculate current total and count dungeons
    for dungeonId, scoreData in pairs(playerProfile.dungeonScores or {}) do
        currentTotal = currentTotal + (scoreData.bestScore or 0)
        dungeonCount = dungeonCount + 1
    end
    
    -- If already at target, no suggestions needed
    if currentTotal >= targetOverallRating then
        return {}
    end
    
    local ratingNeeded = targetOverallRating - currentTotal
    local averageNeeded = ratingNeeded / math.max(1, dungeonCount)
    
    -- Analyze each dungeon for improvement potential
    for dungeonId, scoreData in pairs(playerProfile.dungeonScores or {}) do
        local currentScore = scoreData.bestScore or 0
        local targetScore = currentScore + averageNeeded
        
        -- Find minimum key level needed
        local requirement = self:GetRequiredKeyLevel(targetScore, scoreData.timeLimit)
        if requirement then
            table.insert(suggestions, {
                dungeonId = dungeonId,
                currentScore = currentScore,
                targetScore = targetScore,
                scorePotential = targetScore - currentScore,
                keyLevel = requirement.keyLevel,
                requiredTime = requirement.requiredTime,
                timeLimitMs = scoreData.timeLimit
            })
        end
    end
    
    -- Sort by score potential (highest gains first)
    table.sort(suggestions, function(a, b)
        return a.scorePotential > b.scorePotential
    end)
    
    return suggestions
end

-- MARK: Range-Based IO Calculations
-- Calculate IO gain range (min/max/expected) for a player on a specific keystone
function IOCalculator:CalculateIORange(keystoneData, playerProfile)
    if not keystoneData or not playerProfile then
        NextKey222.Debug:Print("IOCalculator", "CalculateIORange: Missing keystoneData or playerProfile")
        return { min = 0, max = 0, expected = 0 }
    end
    
    local dungeonId = keystoneData.dungeonID
    local keyLevel = keystoneData.level
    local playerName = playerProfile.name or "Unknown"
    
    -- Try to get score from unified system first, then fallback to profile data
    local currentScore = 0
    
    -- Method 1: Try profile data structure (existing approach)
    local playerScores = playerProfile.dungeonScores or {}
    local profileScore = (playerScores[dungeonId] and playerScores[dungeonId].bestScore) or 0
    print("NextKey IOCalc DEBUG:", playerName, "profileScore for dungeon", dungeonId, "=", profileScore)
    
    -- Method 2: Try unified scoring system
    local unifiedScore = 0
    if playerName then
        unifiedScore = self:GetPlayerDungeonScore(playerName, dungeonId)
        print("NextKey IOCalc DEBUG:", playerName, "unifiedScore for dungeon", dungeonId, "=", unifiedScore)
    end
    
    -- Use the higher of the two scores (handles both fake players and real players)
    currentScore = math.max(profileScore, unifiedScore)
    print("NextKey IOCalc DEBUG:", playerName, "FINAL currentScore for dungeon", dungeonId, "=", currentScore, "(profile:", profileScore, "unified:", unifiedScore .. ")")
    
    -- Get metrics for this key level
    local metrics = self:GetDungeonMetrics(keyLevel)
    if not metrics then
        return { min = 0, max = 0, expected = 0 }
    end
    
    -- Calculate potential gain ranges
    local minGain = math.max(0, metrics.min - currentScore)      -- Worst case (untimed/failed)
    local maxGain = math.max(0, metrics.max - currentScore)      -- Best case (perfect 3-chest)
    local expectedGain = math.max(0, metrics.base - currentScore) -- Expected (timed completion)
    
    return {
        min = minGain,
        max = maxGain,
        expected = expectedGain,
        currentScore = currentScore,
        targetScores = {
            min = metrics.min,
            max = metrics.max,
            expected = metrics.base
        }
    }
end

-- MARK: Keystone Value Analysis (Legacy compatibility)
-- Calculate the value of completing a specific keystone for IO gain
function IOCalculator:CalculateKeystoneValue(keystoneData, playerProfile)
    -- Return expected value for backward compatibility
    local range = self:CalculateIORange(keystoneData, playerProfile)
    return range.expected
end

-- MARK: Group Range Calculations
-- Calculate total group IO gain range for a specific keystone
function IOCalculator:CalculateGroupIORange(keystoneData, partyProfiles)
    local groupRange = {
        min = 0,
        max = 0,
        expected = 0,
        keystoneDungeonID = keystoneData and keystoneData.dungeonID or nil,
        playerBreakdown = {}
    }
    
    for playerName, profile in pairs(partyProfiles or {}) do
        local playerRange = self:CalculateIORange(keystoneData, profile)
        
        -- Add to totals
        groupRange.min = groupRange.min + (playerRange.min or 0)
        groupRange.max = groupRange.max + (playerRange.max or 0)
        groupRange.expected = groupRange.expected + (playerRange.expected or 0)
        
        -- Store individual breakdown for tooltip
        groupRange.playerBreakdown[playerName] = {
            current = playerRange.currentScore or 0,
            range = playerRange,
            min = playerRange.min,
            max = playerRange.max, 
            expected = playerRange.expected,
            gainText = string.format("%d → %d-%d (+%d-%d)",
                playerRange.currentScore or 0,
                (playerRange.targetScores and playerRange.targetScores.min) or 0,
                (playerRange.targetScores and playerRange.targetScores.max) or 0,
                playerRange.min or 0,
                playerRange.max or 0)
        }
    end
    
    return groupRange
end

-- MARK: Unified Dungeon Scoring System
-- Handles both real and fake player dungeon scores in a unified way

-- Helper function to get table keys
function IOCalculator:GetKeys(t)
    local keys = {}
    for k, _ in pairs(t or {}) do
        table.insert(keys, tostring(k))
    end
    return keys
end

-- Store real player's dungeon score (from communications or current player)
function IOCalculator:StorePlayerDungeonScore(playerName, dungeonID, score, level)
    if not self.playerScores[playerName] then
        self.playerScores[playerName] = {}
    end
    
    self.playerScores[playerName][dungeonID] = {
        score = score or 0,
        level = level or 0,
        timestamp = GetTime()
    }
    
    NextKey222.Debug:Print("IOCalculator", "Stored score for", playerName, "dungeon", dungeonID .. ":", score)
end

-- Get any player's dungeon score (real or fake) using unified data source
function IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
    -- Check if this is the current player
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local isCurrentPlayer = (playerName == currentPlayer) or 
                          (playerName:match("^([^%-]+)") == UnitName("player"))
    
    -- For current player, use the same reliable method as the UI
    if isCurrentPlayer and NextKey222.UI then
        local currentScore = NextKey222.UI:GetDungeonScore(dungeonID)
        print("NextKey IOCalc DEBUG: Current player", playerName, "dungeon", dungeonID, "score via UI method:", currentScore)
        if currentScore and currentScore > 0 then
            return currentScore
        end
    end
    
    -- First priority: Check shared IO data from communications
    print("NextKey IOCalc DEBUG: Checking Communications for", playerName, "dungeon", dungeonID)
    if NextKey222.Communications then
        local hasData = NextKey222.Communications:HasIODataForPlayer(playerName)
        print("NextKey IOCalc DEBUG: Communications HasIODataForPlayer(", playerName .. "):", hasData)
        
        if hasData then
            local score = NextKey222.Communications:GetPlayerDungeonScore(playerName, dungeonID)
            print("NextKey IOCalc DEBUG: Communications GetPlayerDungeonScore returned:", score)
            
            -- Debug: Show what dungeons are in the Communications cache for Ryuza
            if playerName:match("Ryuza") then
                print("NextKey CACHE CONTENT DEBUG: Dungeons in Communications cache for", playerName .. ":")
                local playerData = NextKey222.Communications.playerIOCache[playerName]
                if playerData and playerData.dungeons then
                    local dungeonCount = 0
                    for dungID, scoreData in pairs(playerData.dungeons) do
                        print("NextKey CACHE CONTENT DEBUG:   Dungeon", dungID .. ":", scoreData.score or "no score")
                        dungeonCount = dungeonCount + 1
                    end
                    print("NextKey CACHE CONTENT DEBUG: Total dungeons in cache:", dungeonCount)
                else
                    print("NextKey CACHE CONTENT DEBUG: No dungeon data found in cache")
                end
            end
            
            NextKey222.Debug:Print("IOCalculator", "Shared IO score for", playerName, "dungeon", dungeonID .. ":", score)
            return score
        else
            -- Debug: Check what's in the cache
            if NextKey222.Communications.playerIOCache then
                local cacheCount = 0
                print("NextKey IOCalc DEBUG: Communications cache contents:")
                for cacheName, _ in pairs(NextKey222.Communications.playerIOCache) do
                    cacheCount = cacheCount + 1
                    print("NextKey IOCalc DEBUG:   Cache has:", cacheName)
                end
                print("NextKey IOCalc DEBUG: Total cache entries:", cacheCount)
            end
        end
    end
    
    -- Second priority: Check RaiderIO data for real players without NextKey
    if not playerName:match("^FakePlayer") and NextKey222.RaiderIOAdapter then
        if NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
            print("NextKey IOCalc DEBUG: Checking RaiderIO for", playerName, "dungeon", dungeonID)
            
            -- Get profile and extract dungeon score
            local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
            if profile and profile.dungeonScores and profile.dungeonScores[dungeonID] then
                local dungeonScore = profile.dungeonScores[dungeonID].bestScore or 0
                print("NextKey IOCalc DEBUG: RaiderIO score for", playerName, "dungeon", dungeonID .. ":", dungeonScore)
                NextKey222.Debug:Print("IOCalculator", "RaiderIO score for", playerName, "dungeon", dungeonID .. ":", dungeonScore)
                return dungeonScore
            else
                print("NextKey IOCalc DEBUG: No RaiderIO score found for", playerName, "dungeon", dungeonID)
            end
        else
            print("NextKey IOCalc DEBUG: No RaiderIO data available for", playerName)
        end
    end
    
    -- Third priority: Check fake players through legacy method
    print("NextKey IOCalc DEBUG: Checking fake player data for", playerName)
    print("NextKey IOCalc DEBUG: NextKey222.Addon.UI exists:", NextKey222.Addon.UI and "yes" or "no")
    
    local fakePlayerData = NextKey222.Addon.UI and NextKey222.Addon.UI:GetFakePlayerData(playerName)
    print("NextKey IOCalc DEBUG: GetFakePlayerData returned:", fakePlayerData and "data found" or "nil")
    
    if fakePlayerData then
        print("NextKey IOCalc DEBUG: fakePlayerData.best exists:", fakePlayerData.best and "yes" or "no")
        if fakePlayerData.best then
            print("NextKey IOCalc DEBUG: Fake player dungeons available:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
    end
    
    if fakePlayerData and fakePlayerData.best then
        -- Debug ID mapping for fake players
        if dungeonID == 2441 or dungeonID == 402 or dungeonID == 391 or dungeonID == 392 then
            NextKey222.Debug:Print("IOCalculator", "ID mapping check for", playerName, "looking for dungeonID:", dungeonID)
            NextKey222.Debug:Print("IOCalculator", "Fake player has dungeons:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
        
        if fakePlayerData.best[dungeonID] then
            return fakePlayerData.best[dungeonID].score or 0
        end
        
        -- Try alternative IDs for So'leah's Gambit mapping (392 and 2441 are the same dungeon)
        if dungeonID == 2441 then
            -- Try the M+ challenge map ID for So'leah's Gambit
            if fakePlayerData.best[392] then
                NextKey222.Debug:Print("IOCalculator", "Found alternative ID 392 (So'leah's Gambit) for", playerName)
                return fakePlayerData.best[392].score or 0
            end
        elseif dungeonID == 392 then
            -- Try the keystone form ID for So'leah's Gambit  
            if fakePlayerData.best[2441] then
                NextKey222.Debug:Print("IOCalculator", "Found alternative ID 2441 (So'leah's Gambit keystone) for", playerName)
                return fakePlayerData.best[2441].score or 0
            end
        end
        
        -- Note: Streets of Wonder (391) is a separate dungeon, no cross-mapping with So'leah's Gambit
    end
    
    -- Fourth priority: Check stored real player scores (legacy)
    if self.playerScores[playerName] and self.playerScores[playerName][dungeonID] then
        return self.playerScores[playerName][dungeonID].score or 0
    end
    
    -- Fifth priority: For current player, get live score if no stored data
    local currentPlayerName = UnitName("player")
    local isCurrentPlayer = (playerName == currentPlayerName) or 
                          (playerName:match("^([^%-]+)") == currentPlayerName)
    
    -- Debug current player lookup
    if playerName == "Ryuza-Dalaran" or playerName:match("^Ryuza") then
        NextKey222.Debug:Print("IOCalculator", "Current player check:", playerName, "vs", currentPlayerName, "isCurrentPlayer:", isCurrentPlayer)
    end
    
    if isCurrentPlayer and NextKey222.Addon.UI then
        local liveScore = NextKey222.Addon.UI:GetRaiderIODungeonScore(dungeonID)
        NextKey222.Debug:Print("IOCalculator", "Live score for", playerName, "dungeon", dungeonID .. ":", liveScore or "nil")
        if liveScore and liveScore > 0 then
            -- Store it for future use
            self:StorePlayerDungeonScore(playerName, dungeonID, liveScore)
            return liveScore
        end
    end
    
    return 0
end

-- Get player's overall IO score (for both real and fake players) using unified data source
function IOCalculator:GetPlayerTotalIO(playerName)
    NextKey222.Debug:Print("IOCalculator", "GetPlayerTotalIO called for:", playerName)
    
    -- Check if this is the current player and ensure their data is generated
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local isCurrentPlayer = (playerName == currentPlayer) or 
                          (playerName:match("^([^%-]+)") == UnitName("player"))
    
    if isCurrentPlayer and NextKey222.Communications then
        -- Ensure current player's IO data is available
        print("NextKey IOCalc DEBUG: Calling EnsureCurrentPlayerIOData for", playerName, "(total IO)")
        local success = NextKey222.Communications:EnsureCurrentPlayerIOData()
        print("NextKey IOCalc DEBUG: EnsureCurrentPlayerIOData returned:", success, "(total IO)")
    end
    
    -- First priority: Check shared IO data from communications
    if NextKey222.Communications and NextKey222.Communications:HasIODataForPlayer(playerName) then
        local totalIO = NextKey222.Communications:GetPlayerTotalIO(playerName)
        NextKey222.Debug:Print("IOCalculator", "Shared IO total for", playerName .. ":", totalIO)
        return totalIO
    end
    
    -- Second priority: Check RaiderIO data for real players without NextKey
    if not playerName:match("^FakePlayer") and NextKey222.RaiderIOAdapter then
        if NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
            local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
            if profile and profile.io then
                NextKey222.Debug:Print("IOCalculator", "RaiderIO total for", playerName .. ":", profile.io)
                return profile.io
            end
        end
    end

    -- Third priority: For fake players, get their calculated total IO (legacy fallback)
    local fakePlayerData = NextKey222.Addon.UI and NextKey222.Addon.UI:GetFakePlayerData(playerName)
    NextKey222.Debug:Print("IOCalculator", "Fake player data found:", fakePlayerData ~= nil)
    
    if fakePlayerData then
        NextKey222.Debug:Print("IOCalculator", "Fake player data fields - io:", fakePlayerData.io, "score:", fakePlayerData.score)
        -- Use the calculated io field from RecalculateFakePlayerScore
        local totalIO = fakePlayerData.io or fakePlayerData.score or 0
        NextKey222.Debug:Print("IOCalculator", "Fake player", playerName, "total IO:", totalIO)
        return totalIO
    end
    
    -- Fourth priority: For current player, try UI method
    local currentPlayer = UnitName("player")
    NextKey222.Debug:Print("IOCalculator", "Current player check:", currentPlayer, "vs", playerName)
    if playerName == currentPlayer then
        if NextKey222.UI and NextKey222.UI.GetTotalIOScore then
            local uiTotal = NextKey222.UI:GetTotalIOScore()
            NextKey222.Debug:Print("IOCalculator", "Current player", playerName, "UI total:", uiTotal)
            return uiTotal or 0
        end
    end
    
    NextKey222.Debug:Print("IOCalculator", "No total IO found for", playerName, "returning 0")
    return 0
end

-- Debug function to test RaiderIO integration for a player
function IOCalculator:DebugRaiderIOIntegration(playerName)
    if not NextKey222.RaiderIOAdapter then
        print("NextKey DEBUG: RaiderIO adapter not available")
        return
    end
    
    print("NextKey DEBUG: Testing RaiderIO integration for", playerName)
    
    local hasData = NextKey222.RaiderIOAdapter:HasPlayerData(playerName)
    print("NextKey DEBUG: HasPlayerData:", hasData)
    
    if hasData then
        local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
        if profile then
            print("NextKey DEBUG: Profile found - Total IO:", profile.io)
            print("NextKey DEBUG: Data source:", profile.dataSource)
            if profile.dungeonScores then
                local count = 0
                for dungeonID, scoreData in pairs(profile.dungeonScores) do
                    count = count + 1
                    print("NextKey DEBUG:   Dungeon", dungeonID .. ":", scoreData.bestScore, "(level +" .. (scoreData.bestLevel or 0) .. ")")
                end
                print("NextKey DEBUG: Total dungeons with scores:", count)
            end
        else
            print("NextKey DEBUG: Failed to get profile")
        end
    end
end

-- Update current player's scores for all dungeons
function IOCalculator:UpdateCurrentPlayerScores()
    local playerName = UnitName("player")
    if not playerName or not NextKey222.Addon.UI then
        return false
    end
    
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local updated = false
    
    for dungeonID, _ in pairs(dungeons) do
        local score = NextKey222.Addon.UI:GetRaiderIODungeonScore(dungeonID)
        if score and score > 0 then
            self:StorePlayerDungeonScore(playerName, dungeonID, score)
            updated = true
        end
    end
    
    if updated then
        -- Trigger communication to share scores with group
        if NextKey222.Communications and NextKey222.Communications.ShareDungeonScores then
            NextKey222.Communications:ShareDungeonScores()
        end
    end
    
    return updated
end

-- Get stored scores for communications
function IOCalculator:GetCurrentPlayerDungeonScores()
    local playerName = UnitName("player")
    if not playerName then return {} end
    
    return self.playerScores[playerName] or {}
end

-- Receive dungeon scores from communications
function IOCalculator:ReceivePlayerDungeonScores(playerName, dungeonScores)
    if not playerName or not dungeonScores then return end
    
    for dungeonID, scoreData in pairs(dungeonScores) do
        self:StorePlayerDungeonScore(playerName, dungeonID, scoreData.score, scoreData.level)
    end
    
    NextKey222.Debug:Print("IOCalculator", "Received dungeon scores from", playerName)
end

-- MARK: Group Recommendation Logic
-- Generate recommendations for a group based on available keystones
function IOCalculator:GenerateGroupRecommendations(availableKeystones, partyProfiles, sortMode)
    local recommendations = {}
    
    for _, keystone in ipairs(availableKeystones or {}) do
        local groupRange = self:CalculateGroupIORange(keystone, partyProfiles)
        
        local recommendation = {
            keystone = keystone,
            groupRange = groupRange,
            totalValue = groupRange.expected, -- For backward compatibility
            playerValues = {},
            playerCount = 0
        }
        
        -- Count players who would benefit and create legacy format
        for playerName, breakdown in pairs(groupRange.playerBreakdown) do
            if breakdown.range.expected > 0 then
                recommendation.playerValues[playerName] = breakdown.range.expected
                recommendation.playerCount = recommendation.playerCount + 1
            end
        end
        
        -- Only include keystones that benefit at least one player
        if recommendation.totalValue > 0 then
            table.insert(recommendations, recommendation)
        end
    end
    
    -- Sort recommendations based on mode
    local sortValue = function(rec)
        if sortMode == "min" then return rec.groupRange.min
        elseif sortMode == "max" then return rec.groupRange.max
        elseif sortMode == "players" then return rec.playerCount
        else return rec.groupRange.expected end -- default
    end
    
    table.sort(recommendations, function(a, b)
        return sortValue(a) > sortValue(b)
    end)
    
    return recommendations
end

return IOCalculator