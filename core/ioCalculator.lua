-- MARK: IO Calculator
-- Rating calculation logic based on MythicPlanner.com algorithm
-- Implements the exact formulas used by mythicplanner.com for accurate IO gain predictions

local IOCalculator = {
    -- MARK: Player Score Storage
    -- Stores dungeon-specific scores for all players (real and fake)
    playerScores = {},
    fakePlayerScores = {},
    
    -- MARK: Refresh Cycle Memo
    -- Cache lookups within a single refresh cycle to avoid redundant API calls
    refreshCycleID = 0,
    scoreLookupCache = {},
    lastCacheReset = 0
}
NextKey222.IOCalculator = IOCalculator
NextKey222.RegisterModule("IOCalculator", IOCalculator)

-- MARK: Dungeon Base Scores
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

-- MARK: Initialization
--- Initializes the IOCalculator module.
--- This function resets the player score caches and logs the initialization.
function IOCalculator:Initialize()
    self.playerScores = {}
    self.fakePlayerScores = {}
    NextKey222.Debug:Dev("IOCalculator", "Initialized with MythicPlanner.com algorithm")
    return true
end

-- MARK: Score Estimation
-- These functions provide utility for score estimation and time approximation

--- Converts the number of chests from a Mythic+ run into an approximate fractional completion time.
--- For example, 3 chests is equivalent to completing the dungeon in 60% of the allotted time.
---@param chests number The number of chests (0-3).
---@return number The approximate fractional completion time (e.g., 0.6 for 3 chests).
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

--- Estimates the score of a Mythic+ run based on the TWW Season 1 formula.
--- Uses RaiderIO data (level, chests, fractionalTime) to calculate accurate per-dungeon scores.
---@param level number The keystone level.
---@param timed boolean Whether the run was completed within the timer (chests > 0).
---@param fractionalTime number|nil The ratio of time taken (0.0-1.0 = timed, >1.0 = overtime).
---@return number The estimated score.
function IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    level = tonumber(level) or 0
    if level < 2 then return 0 end
    
    -- TWW Season 1 Base Score Brackets
    local score = 0
    if level >= 12 then
        score = (level * 15) + 185
    elseif level >= 10 then
        score = (level * 15) + 170
    elseif level >= 7 then
        score = (level * 15) + 160
    elseif level >= 4 then
        score = (level * 15) + 145
    else -- Level 2-3
        score = (level * 15) + 135
    end
    
    -- Time Bonus/Penalty Logic
    if timed then
        -- Bonus for finishing fast (max 15 points for 40% time remaining)
        if fractionalTime and fractionalTime < 1.0 then
            local timeRemainingPct = math.max(0, 1.0 - fractionalTime)
            -- Bonus capped at 40% time remaining (fractionalTime <= 0.6)
            local bonusRatio = math.min(timeRemainingPct, 0.4) / 0.4
            score = score + (15 * bonusRatio)
        end
    else
        -- Penalty for overtime (simplified)
        score = score - 15
    end
    
    -- Clamp to 0
    return math.max(0, math.floor(score + 0.5))
end

-- Helper function to calculate Mythic+ score from level and chests
--- Calculates an approximate Mythic+ score based on keystone level and number of chests.
--- @param level number The keystone level.
--- @param chests number The number of chests earned (0-3).
--- @return number The calculated score.
function IOCalculator:CalculateMythicPlusScore(level, chests)
    if not level or level < 2 then
        return 0
    end

    local baseScore = 0
    if level <= 10 then
        baseScore = level * 15
    elseif level <= 15 then
        baseScore = 150 + (level - 10) * 20
    elseif level <= 20 then
        baseScore = 250 + (level - 15) * 25
    else
        baseScore = 375 + (level - 20) * 30
    end

    local chestMultiplier = {
        [0] = 0.6, -- Untimed penalty
        [1] = 1.0, -- Full score
        [2] = 1.2, -- 2+ chest bonus
        [3] = 1.2  -- 3 chest bonus (same as 2)
    }

    local multiplier = chestMultiplier[chests] or 1.0

    return math.floor(baseScore * multiplier)
end

-- MARK: Core Rating Calc
--- Calculates the precise Mythic+ score for a completed run using the MythicPlanner.com formula.
--- The formula considers the run time, time limit, and keystone level to provide an accurate score.
---@param runTime number The time taken to complete the dungeon, in seconds.
---@param timeLimit number The time limit for the dungeon, in seconds.
---@param keyLevel number The keystone level.
---@return number The calculated score.
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

-- MARK: Dungeon Metrics
--- Retrieves the base, minimum, and maximum possible scores for a given keystone level.
---@param keyLevel number The keystone level.
---@return table|nil A table with base, min, and max scores, or nil if the level is invalid.
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
--- Calculates the keystone level a player needs to complete to achieve a target score in a specific dungeon.
---@param targetScore number The desired Mythic+ score.
---@param dungeonTimeLimit number The time limit of the dungeon in seconds.
---@return table|nil A table with the required key level and time, or nil if the score is unachievable.
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

-- MARK: Time Requirements
--- Calculates the required completion time for a given keystone level to achieve a specific target score.
---@param targetScore number The target Mythic+ score.
---@param keyLevel number The keystone level.
---@param timeLimit number The time limit of the dungeon in seconds.
---@return number|nil The required completion time in seconds, or nil if the score is unachievable.
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

-- MARK: Player Improvement
--- Analyzes a player's profile to suggest dungeons they can run to improve their overall Mythic+ score.
---@param playerProfile table The player's profile, including their dungeon scores.
---@param targetOverallRating number The player's target overall score.
---@return table A sorted list of dungeon improvement suggestions.
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

-- MARK: Range-Based IO Calc
--- Calculates the potential IO gain range (minimum, maximum, and expected) for a player completing a specific keystone.
--- Returns nil for players without addon data (to exclude them from calculations).
---@param keystoneData table The data for the keystone being considered.
---@param playerProfile table The profile of the player.
---@return table|nil A table containing the min, max, and expected IO gain, or nil if player has no addon data.
function IOCalculator:CalculateIORange(keystoneData, playerProfile)
    if not keystoneData or not playerProfile then
        NextKey222.Debug:Dev("IOCalculator", "CalculateIORange: Missing keystoneData or playerProfile")
        return { min = 0, max = 0, expected = 0 }
    end
    
    local dungeonId = keystoneData.dungeonID
    local keyLevel = keystoneData.level
    local playerName = playerProfile.name or "Unknown"
    
    -- CRITICAL: Check if player has addon data before calculating
    -- Return nil for players without addons (excludes them from group calculations)
    if not self:HasPlayerAddonData(playerName) then
        NextKey222.Debug:Dev("IOCalculator", string.format(
            "CalculateIORange: Excluding %s (no addon data) from dungeon %d calculations",
            playerName, dungeonId))
        return nil
    end
    
    -- Try to get score from unified system first, then fallback to profile data
    local currentScore = 0
    
    -- Method 1: Try profile data structure (PRIMARY - most reliable)
    local playerScores = playerProfile.dungeonScores or {}
    local profileScore = (playerScores[dungeonId] and playerScores[dungeonId].bestScore) or 0
    
    -- Method 2: Explicit fake player check (for testing with FakePlayerService)
    local fakeScore = 0
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService:IsFakePlayer(playerName) then
        local fakeProfile = NextKey222.FakePlayerService:GetProfile(playerName)
        if fakeProfile and fakeProfile.dungeonScores and fakeProfile.dungeonScores[dungeonId] then
            fakeScore = fakeProfile.dungeonScores[dungeonId].bestScore or 0
            NextKey222.Debug:Dev("IOCalculator", "Fake player", playerName, "dungeon", dungeonId, "score:", fakeScore)
        end
    end
    
    -- Method 3: Try unified scoring system (fallback for real players)
    local unifiedScore = 0
    if playerName and fakeScore == 0 then  -- Skip if fake player already found
        local score = self:GetPlayerDungeonScore(playerName, dungeonId)
        -- Handle nil return (no addon data) vs 0 (fresh character)
        unifiedScore = score or 0
    end
    
    -- Use the highest score from all methods
    currentScore = math.max(profileScore, fakeScore, unifiedScore)
    
    -- Debug output for troubleshooting
    if playerName and (playerName:match("^FakePlayer") or profileScore > 0 or fakeScore > 0) then
        NextKey222.Debug:Dev("IOCalculator", string.format("%s dungeon %d: profile=%d, fake=%d, unified=%d → final=%d", 
            playerName, dungeonId, profileScore, fakeScore, unifiedScore, currentScore))
    end
    
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

-- MARK: Keystone Value
--- Calculates the expected IO gain from completing a specific keystone for a player.
--- This is a legacy function for backward compatibility.
---@param keystoneData table The data for the keystone.
---@param playerProfile table The profile of the player.
---@return number The expected IO gain.
function IOCalculator:CalculateKeystoneValue(keystoneData, playerProfile)
    -- Return expected value for backward compatibility
    local range = self:CalculateIORange(keystoneData, playerProfile)
    return range.expected
end

-- MARK: Group Range Calc
--- Calculates the total IO gain range for a group of players for a specific keystone.
--- Automatically excludes players without addon data from calculations.
---@param keystoneData table The keystone being considered.
---@param partyProfiles table A table of player profiles for the party.
---@return table A table with the total min, max, and expected IO gain for the group, and a player-by-player breakdown.
function IOCalculator:CalculateGroupIORange(keystoneData, partyProfiles)
    local groupRange = {
        min = 0,
        max = 0,
        expected = 0,
        keystoneDungeonID = keystoneData and keystoneData.dungeonID or nil,
        playerBreakdown = {},
        excludedPlayers = {}  -- Track players excluded due to no addon data
    }
    
    for playerName, profile in pairs(partyProfiles or {}) do
            local playerRange = self:CalculateIORange(keystoneData, profile)

            -- CRITICAL: Exclude players with no addon data (playerRange will be nil)
            if playerRange == nil then
                NextKey222.Debug:Dev("IOCalculator", string.format(
                    "CalculateGroupIORange: Excluding %s from group totals (no addon data)",
                    playerName))
                table.insert(groupRange.excludedPlayers, playerName)
                -- Skip this player - don't add to breakdown or totals
            else
                -- Add to totals
                groupRange.min = groupRange.min + (playerRange.min or 0)
                groupRange.max = groupRange.max + (playerRange.max or 0)
                groupRange.expected = groupRange.expected + (playerRange.expected or 0)

                -- Always use the correct per-dungeon score for 'current' value
                local dungeonId = keystoneData and keystoneData.dungeonID
                local currentDungeonScore = 0
                if profile and profile.dungeonScores and dungeonId and profile.dungeonScores[dungeonId] then
                    currentDungeonScore = profile.dungeonScores[dungeonId].bestScore or 0
                end
                groupRange.playerBreakdown[playerName] = {
                    current = currentDungeonScore,
                    range = playerRange,
                    min = playerRange.min,
                    max = playerRange.max,
                    expected = playerRange.expected,
                    gainText = string.format("%d → %d-%d (+%d-%d)",
                        currentDungeonScore,
                        (playerRange.targetScores and playerRange.targetScores.min) or 0,
                        (playerRange.targetScores and playerRange.targetScores.max) or 0,
                        playerRange.min or 0,
                        playerRange.max or 0)
                }
            end
    end
    
    -- Log summary of excluded players
    if #groupRange.excludedPlayers > 0 then
        NextKey222.Debug:User("IOCalculator", string.format(
            "Group calculation excluded %d player(s) without addon data: %s",
            #groupRange.excludedPlayers,
            table.concat(groupRange.excludedPlayers, ", ")))
    end
    
    return groupRange
end

-- MARK: Unified Dungeon Score
-- Handles both real and fake player dungeon scores in a unified way

--- A helper function to get the keys of a table.
---@param t table The table to get the keys from.
---@return table A list of the table's keys.
function IOCalculator:GetKeys(t)
    local keys = {}
    for k, _ in pairs(t or {}) do
        table.insert(keys, tostring(k))
    end
    return keys
end

--- Stores a player's score for a specific dungeon.
---@param playerName string The name of the player.
---@param dungeonID number The ID of the dungeon.
---@param score number The player's score in the dungeon.
---@param level number|nil The keystone level of the run.
function IOCalculator:StorePlayerDungeonScore(playerName, dungeonID, score, level)
    if not self.playerScores[playerName] then
        self.playerScores[playerName] = {}
    end
    
    self.playerScores[playerName][dungeonID] = {
        score = score or 0,
        level = level or 0,
        timestamp = GetTime()
    }
    
    NextKey222.Debug:Dev("IOCalculator", "Stored score for", playerName, "dungeon", dungeonID .. ":", score)
end

--- Retrieves a player's score for a specific dungeon from various sources.
--- The function checks the profile service, communication cache, Raider.IO data, and fake player data.
--- Returns nil if the player has no addon data available (to distinguish from legitimate 0 scores).
---@param playerName string The name of the player.
---@param dungeonID number The ID of the dungeon.
---@return number|nil The player's score for the dungeon, or nil if player has no addon data.
function IOCalculator:GetPlayerDungeonScore(playerName, dungeonID)
    if not playerName or not dungeonID then
        return 0
    end
    
    -- CRITICAL: Check if player has ANY addon data before attempting score lookup
    -- This distinguishes between:
    --   - Real 0 (fresh character with RaiderIO but no runs) -> return 0
    --   - No-addon 0 (no RaiderIO, no NextKey) -> return nil
    if not self:HasPlayerAddonData(playerName) then
        NextKey222.Debug:Dev("IOCalculator", string.format(
            "Player %s has no addon data (no RaiderIO, no NextKey) - excluding from calculations",
            playerName))
        return nil
    end
    
    -- PHASE 2: Memoization - check if we already looked this up in the current refresh cycle
    local now = GetTime()
    if now - self.lastCacheReset > 5 then
        -- Reset cache every 5 seconds to prevent stale data
        self.refreshCycleID = self.refreshCycleID + 1
        self.scoreLookupCache = {}
        self.lastCacheReset = now
    end
    
    local cacheKey = string.format("%s:%d:%d", playerName, dungeonID, self.refreshCycleID)
    if self.scoreLookupCache[cacheKey] then
        -- Return cached result from this refresh cycle
        return self.scoreLookupCache[cacheKey]
    end
    
    -- Call internal implementation and cache the result
    local result = self:_GetPlayerDungeonScore_Internal(playerName, dungeonID)
    self.scoreLookupCache[cacheKey] = result
    return result
end

--- Internal implementation of dungeon score lookup (without memoization).
--- This function contains the actual lookup logic across all data sources.
---@param playerName string The name of the player.
---@param dungeonID number The ID of the dungeon.
---@return number|nil The player's score for the dungeon, or nil if not found.
function IOCalculator:_GetPlayerDungeonScore_Internal(playerName, dungeonID)
    if not playerName or not dungeonID then
        return 0
    end

    local function getScoreFromProfile(targetPlayer, targetDungeonID)
        if not NextKey222.ProfilesService or not NextKey222.ProfilesService.GetProfile then
            return nil
        end

        local profile = NextKey222.ProfilesService:GetProfile(targetPlayer)
        if not profile or not profile.dungeonScores then
            return nil
        end

        local function resolveScore(scoreEntry)
            if not scoreEntry then return nil end
            return scoreEntry.bestScore or scoreEntry.score or scoreEntry.current or nil
        end

        -- Direct lookup using canonical NextKey ID
        local scoreData = profile.dungeonScores[targetDungeonID]
        local resolved = resolveScore(scoreData)
        if resolved and resolved > 0 then
            return resolved
        end

        -- Try alternate identifiers for robustness (keystone/challenge IDs)
        if NextKey222.IDMapper then
            local mapping = NextKey222.IDMapper:GetMappingInfo(targetDungeonID)
            if mapping then
                local alternatives = {
                    mapping.challengeMapID,
                    mapping.keystoneID,
                    mapping.raiderIOID,
                    mapping.blizzardMapID
                }
                for _, altID in ipairs(alternatives) do
                    if altID and profile.dungeonScores[altID] then
                        local altResolved = resolveScore(profile.dungeonScores[altID])
                        if altResolved and altResolved > 0 then
                            return altResolved
                        end
                    end
                end
            end
        end

        return resolved
    end

    -- Primary source: ProfilesService (handles real and fake players)
    local profileScore = getScoreFromProfile(playerName, dungeonID)
    if profileScore and profileScore > 0 then
        NextKey222.Debug:Dev("IOCalculator", "Profile service score for", playerName, "dungeon", dungeonID .. ":", profileScore)
        return profileScore
    end

    -- Check if this is the current player
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local isCurrentPlayer = (playerName == currentPlayer) or
                          (playerName:match("^([^%-]+)") == UnitName("player"))
    
    -- For current player, use the same reliable method as the UI
    if isCurrentPlayer and NextKey222.UI then
        local currentScore = NextKey222.UI:GetDungeonScore(dungeonID)
        NextKey222.Debug:Dev("IOCalculator", "Current player", playerName, "dungeon", dungeonID, "score via UI method:", currentScore)
        if currentScore and currentScore > 0 then
            return currentScore
        end
    end
    
    -- First priority: Check shared IO data from communications
    NextKey222.Debug:Dev("IOCalculator", "Checking Communications for", playerName, "dungeon", dungeonID)
    if NextKey222.Communications then
        local hasData = NextKey222.Communications:HasIODataForPlayer(playerName)
        NextKey222.Debug:Dev("IOCalculator", "Communications HasIODataForPlayer(", playerName .. "):", hasData)
        
        if hasData then
            local score = NextKey222.Communications:GetPlayerDungeonScore(playerName, dungeonID)
            NextKey222.Debug:Dev("IOCalculator", "Communications GetPlayerDungeonScore returned:", score)
            
            -- Debug: Show what dungeons are in the Communications cache for Ryuza
            if playerName:match("Ryuza") then
                NextKey222.Debug:Dev("IOCalculator", "Dungeons in Communications cache for", playerName .. ":")
                local playerData = NextKey222.Communications.playerIOCache[playerName]
                if playerData and playerData.dungeons then
                    local dungeonCount = 0
                    for dungID, scoreData in pairs(playerData.dungeons) do
                        NextKey222.Debug:Dev("IOCalculator", "  Dungeon", dungID .. ":", scoreData.score or "no score")
                        dungeonCount = dungeonCount + 1
                    end
                    NextKey222.Debug:Dev("IOCalculator", "Total dungeons in cache:", dungeonCount)
                else
                    NextKey222.Debug:Dev("IOCalculator", "No dungeon data found in cache")
                end
            end
            
            NextKey222.Debug:Dev("IOCalculator", "Shared IO score for", playerName, "dungeon", dungeonID .. ":", score)
            return score
        else
            -- Debug: Check what's in the cache
            if NextKey222.Communications.playerIOCache then
                local cacheCount = 0
                NextKey222.Debug:Dev("IOCalculator", "Communications cache contents:")
                for cacheName, _ in pairs(NextKey222.Communications.playerIOCache) do
                    cacheCount = cacheCount + 1
                    NextKey222.Debug:Dev("IOCalculator", "  Cache has:", cacheName)
                end
                NextKey222.Debug:Dev("IOCalculator", "Total cache entries:", cacheCount)
            end
        end
    end
    
    -- Second priority: Check RaiderIO data for real players without NextKey
    if not playerName:match("^FakePlayer") and NextKey222.RaiderIOAdapter then
        if NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
            NextKey222.Debug:Dev("IOCalculator", "Checking RaiderIO for", playerName, "dungeon", dungeonID)
            
            -- Get profile and extract dungeon score
            local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
            if profile and profile.dungeonScores and profile.dungeonScores[dungeonID] then
                local dungeonScore = profile.dungeonScores[dungeonID].bestScore or 0
                NextKey222.Debug:Dev("IOCalculator", "RaiderIO score for", playerName, "dungeon", dungeonID .. ":", dungeonScore)
                NextKey222.Debug:Dev("IOCalculator", "RaiderIO score for", playerName, "dungeon", dungeonID .. ":", dungeonScore)
                return dungeonScore
            else
                NextKey222.Debug:Dev("IOCalculator", "No RaiderIO score found for", playerName, "dungeon", dungeonID)
            end
        else
            NextKey222.Debug:Dev("IOCalculator", "No RaiderIO data available for", playerName)
        end
    end
    
    -- Third priority: Check fake players through legacy method
    NextKey222.Debug:Dev("IOCalculator", "Checking fake player data for", playerName)
    NextKey222.Debug:Dev("IOCalculator", "NextKey222.Addon.UI exists:", NextKey222.Addon.UI and "yes" or "no")
    
    local fakePlayerData = NextKey222.Addon.UI and NextKey222.Addon.UI:GetFakePlayerData(playerName)
    NextKey222.Debug:Dev("IOCalculator", "GetFakePlayerData returned:", fakePlayerData and "data found" or "nil")
    
    if fakePlayerData then
        NextKey222.Debug:Dev("IOCalculator", "fakePlayerData.best exists:", fakePlayerData.best and "yes" or "no")
        if fakePlayerData.best then
            NextKey222.Debug:Dev("IOCalculator", "Fake player dungeons available:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
    end
    
    if fakePlayerData and fakePlayerData.best then
        -- Debug ID mapping for fake players
        if dungeonID == 2441 or dungeonID == 402 or dungeonID == 391 or dungeonID == 392 then
            NextKey222.Debug:Dev("IOCalculator", "ID mapping check for", playerName, "looking for dungeonID:", dungeonID)
            NextKey222.Debug:Dev("IOCalculator", "Fake player has dungeons:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
        
        if fakePlayerData.best[dungeonID] then
            return fakePlayerData.best[dungeonID].score or 0
        end
        
        -- Try alternative IDs for So'leah's Gambit mapping (392 and 2441 are the same dungeon)
        if dungeonID == 2441 then
            -- Try the M+ challenge map ID for So'leah's Gambit
            if fakePlayerData.best[392] then
                NextKey222.Debug:Dev("IOCalculator", "Found alternative ID 392 (So'leah's Gambit) for", playerName)
                return fakePlayerData.best[392].score or 0
            end
        elseif dungeonID == 392 then
            -- Try the keystone form ID for So'leah's Gambit
            if fakePlayerData.best[2441] then
                NextKey222.Debug:Dev("IOCalculator", "Found alternative ID 2441 (So'leah's Gambit keystone) for", playerName)
                return fakePlayerData.best[2441].score or 0
            end
        end
        
        -- Note: Streets of Wonder (391) is a separate dungeon, no cross-mapping with So'leah's Gambit
    end
    
    -- Fourth priority: Check stored real player scores (legacy)
    if self.playerScores[playerName] and self.playerScores[playerName][dungeonID] then
        local storedScore = self.playerScores[playerName][dungeonID].score or 0
        if storedScore > 0 then
            return storedScore
        end
    end

    -- Fifth priority: For current player, get live score if no stored data
    local currentPlayerName = UnitName("player")
    local isCurrentPlayer = (playerName == currentPlayerName) or
                          (playerName:match("^([^%-]+)") == currentPlayerName)
    
    -- Debug current player lookup
    if playerName == "Ryuza-Dalaran" or playerName:match("^Ryuza") then
        NextKey222.Debug:Dev("IOCalculator", "Current player check:", playerName, "vs", currentPlayerName, "isCurrentPlayer:", isCurrentPlayer)
    end
    
    if isCurrentPlayer and NextKey222.Addon.UI then
        local liveScore = NextKey222.Addon.UI:GetRaiderIODungeonScore(dungeonID)
        NextKey222.Debug:Dev("IOCalculator", "Live score for", playerName, "dungeon", dungeonID .. ":", liveScore or "nil")
        if liveScore and liveScore > 0 then
            -- Store it for future use
            self:StorePlayerDungeonScore(playerName, dungeonID, liveScore)
            return liveScore
        end
    end
    
    return 0
end

--- Internal implementation of dungeon score lookup (without memoization).
--- This function contains the actual lookup logic across all data sources.
---@param playerName string The name of the player.
---@param dungeonID number The ID of the dungeon.
---@return number|nil The player's score for the dungeon, or nil if not found.
function IOCalculator:_GetPlayerDungeonScore_Internal(playerName, dungeonID)
    if not playerName or not dungeonID then
        return 0
    end

    local function getScoreFromProfile(targetPlayer, targetDungeonID)
        if not NextKey222.ProfilesService or not NextKey222.ProfilesService.GetProfile then
            return nil
        end

        local profile = NextKey222.ProfilesService:GetProfile(targetPlayer)
        if not profile or not profile.dungeonScores then
            return nil
        end

        local function resolveScore(scoreEntry)
            if not scoreEntry then return nil end
            return scoreEntry.bestScore or scoreEntry.score or scoreEntry.current or nil
        end

        -- Direct lookup using canonical NextKey ID
        local scoreData = profile.dungeonScores[targetDungeonID]
        local resolved = resolveScore(scoreData)
        if resolved and resolved > 0 then
            return resolved
        end

        -- Try alternate identifiers for robustness (keystone/challenge IDs)
        if NextKey222.IDMapper then
            local mapping = NextKey222.IDMapper:GetMappingInfo(targetDungeonID)
            if mapping then
                local alternatives = {
                    mapping.challengeMapID,
                    mapping.keystoneID,
                    mapping.raiderIOID,
                    mapping.blizzardMapID
                }
                for _, altID in ipairs(alternatives) do
                    if altID and profile.dungeonScores[altID] then
                        local altResolved = resolveScore(profile.dungeonScores[altID])
                        if altResolved and altResolved > 0 then
                            return altResolved
                        end
                    end
                end
            end
        end

        return resolved
    end

    -- Primary source: ProfilesService (handles real and fake players)
    local profileScore = getScoreFromProfile(playerName, dungeonID)
    if profileScore and profileScore > 0 then
        NextKey222.Debug:Dev("IOCalculator", "Profile service score for", playerName, "dungeon", dungeonID .. ":", profileScore)
        return profileScore
    end

    -- Check if this is the current player
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local isCurrentPlayer = (playerName == currentPlayer) or
                          (playerName:match("^([^%-]+)") == UnitName("player"))
    
    -- For current player, use the same reliable method as the UI
    if isCurrentPlayer and NextKey222.UI then
        local currentScore = NextKey222.UI:GetDungeonScore(dungeonID)
        NextKey222.Debug:Dev("IOCalculator", "Current player", playerName, "dungeon", dungeonID, "score via UI method:", currentScore)
        if currentScore and currentScore > 0 then
            return currentScore
        end
    end
    
    -- First priority: Check shared IO data from communications
    NextKey222.Debug:Dev("IOCalculator", "Checking Communications for", playerName, "dungeon", dungeonID)
    if NextKey222.Communications then
        local hasData = NextKey222.Communications:HasIODataForPlayer(playerName)
        NextKey222.Debug:Dev("IOCalculator", "Communications HasIODataForPlayer(", playerName .. "):", hasData)
        
        if hasData then
            local score = NextKey222.Communications:GetPlayerDungeonScore(playerName, dungeonID)
            NextKey222.Debug:Dev("IOCalculator", "Communications GetPlayerDungeonScore returned:", score)
            
            -- Debug: Show what dungeons are in the Communications cache for Ryuza
            if playerName:match("Ryuza") then
                NextKey222.Debug:Dev("IOCalculator", "Dungeons in Communications cache for", playerName .. ":")
                local playerData = NextKey222.Communications.playerIOCache[playerName]
                if playerData and playerData.dungeons then
                    local dungeonCount = 0
                    for dungID, scoreData in pairs(playerData.dungeons) do
                        NextKey222.Debug:Dev("IOCalculator", "  Dungeon", dungID .. ":", scoreData.score or "no score")
                        dungeonCount = dungeonCount + 1
                    end
                    NextKey222.Debug:Dev("IOCalculator", "Total dungeons in cache:", dungeonCount)
                else
                    NextKey222.Debug:Dev("IOCalculator", "No dungeon data found in cache")
                end
            end
            
            NextKey222.Debug:Dev("IOCalculator", "Shared IO score for", playerName, "dungeon", dungeonID .. ":", score)
            return score
        else
            -- Debug: Check what's in the cache
            if NextKey222.Communications.playerIOCache then
                local cacheCount = 0
                NextKey222.Debug:Dev("IOCalculator", "Communications cache contents:")
                for cacheName, _ in pairs(NextKey222.Communications.playerIOCache) do
                    cacheCount = cacheCount + 1
                    NextKey222.Debug:Dev("IOCalculator", "  Cache has:", cacheName)
                end
                NextKey222.Debug:Dev("IOCalculator", "Total cache entries:", cacheCount)
            end
        end
    end
    
    -- Second priority: Check RaiderIO data for real players without NextKey
    if not playerName:match("^FakePlayer") and NextKey222.RaiderIOAdapter then
        if NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
            NextKey222.Debug:Dev("IOCalculator", "Checking RaiderIO for", playerName, "dungeon", dungeonID)
            
            -- Get profile and extract dungeon score
            local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
            if profile and profile.dungeonScores and profile.dungeonScores[dungeonID] then
                local dungeonScore = profile.dungeonScores[dungeonID].bestScore or 0
                NextKey222.Debug:Dev("IOCalculator", "RaiderIO score for", playerName, "dungeon", dungeonID .. ":", dungeonScore)
                return dungeonScore
            else
                NextKey222.Debug:Dev("IOCalculator", "No RaiderIO score found for", playerName, "dungeon", dungeonID)
            end
        else
            NextKey222.Debug:Dev("IOCalculator", "No RaiderIO data available for", playerName)
        end
    end
    
    -- Third priority: Check fake players through legacy method
    NextKey222.Debug:Dev("IOCalculator", "Checking fake player data for", playerName)
    NextKey222.Debug:Dev("IOCalculator", "NextKey222.Addon.UI exists:", NextKey222.Addon.UI and "yes" or "no")
    
    local fakePlayerData = NextKey222.Addon.UI and NextKey222.Addon.UI:GetFakePlayerData(playerName)
    NextKey222.Debug:Dev("IOCalculator", "GetFakePlayerData returned:", fakePlayerData and "data found" or "nil")
    
    if fakePlayerData then
        NextKey222.Debug:Dev("IOCalculator", "fakePlayerData.best exists:", fakePlayerData.best and "yes" or "no")
        if fakePlayerData.best then
            NextKey222.Debug:Dev("IOCalculator", "Fake player dungeons available:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
    end
    
    if fakePlayerData and fakePlayerData.best then
        -- Debug ID mapping for fake players
        if dungeonID == 2441 or dungeonID == 402 or dungeonID == 391 or dungeonID == 392 then
            NextKey222.Debug:Dev("IOCalculator", "ID mapping check for", playerName, "looking for dungeonID:", dungeonID)
            NextKey222.Debug:Dev("IOCalculator", "Fake player has dungeons:", table.concat(self:GetKeys(fakePlayerData.best), ", "))
        end
        
        if fakePlayerData.best[dungeonID] then
            return fakePlayerData.best[dungeonID].score or 0
        end
        
        -- Try alternative IDs for So'leah's Gambit mapping (392 and 2441 are the same dungeon)
        if dungeonID == 2441 then
            -- Try the M+ challenge map ID for So'leah's Gambit
            if fakePlayerData.best[392] then
                NextKey222.Debug:Dev("IOCalculator", "Found alternative ID 392 (So'leah's Gambit) for", playerName)
                return fakePlayerData.best[392].score or 0
            end
        elseif dungeonID == 392 then
            -- Try the keystone form ID for So'leah's Gambit
            if fakePlayerData.best[2441] then
                NextKey222.Debug:Dev("IOCalculator", "Found alternative ID 2441 (So'leah's Gambit keystone) for", playerName)
                return fakePlayerData.best[2441].score or 0
            end
        end
        
        -- Note: Streets of Wonder (391) is a separate dungeon, no cross-mapping with So'leah's Gambit
    end
    
    -- Fourth priority: Check stored real player scores (legacy)
    if self.playerScores[playerName] and self.playerScores[playerName][dungeonID] then
        local storedScore = self.playerScores[playerName][dungeonID].score or 0
        if storedScore > 0 then
            return storedScore
        end
    end

    -- Fifth priority: For current player, get live score if no stored data
    local currentPlayerName = UnitName("player")
    local isCurrentPlayer = (playerName == currentPlayerName) or
                          (playerName:match("^([^%-]+)") == currentPlayerName)
    
    -- Debug current player lookup
    if playerName == "Ryuza-Dalaran" or playerName:match("^Ryuza") then
        NextKey222.Debug:Dev("IOCalculator", "Current player check:", playerName, "vs", currentPlayerName, "isCurrentPlayer:", isCurrentPlayer)
    end
    
    if isCurrentPlayer and NextKey222.Addon.UI then
        local liveScore = NextKey222.Addon.UI:GetRaiderIODungeonScore(dungeonID)
        NextKey222.Debug:Dev("IOCalculator", "Live score for", playerName, "dungeon", dungeonID .. ":", liveScore or "nil")
        if liveScore and liveScore > 0 then
            -- Store it for future use
            self:StorePlayerDungeonScore(playerName, dungeonID, liveScore)
            return liveScore
        end
    end
    
    return 0
end

--- Retrieves a player's total Mythic+ IO score from various sources.
--- This function is the unified entry point for getting any player's total IO, whether they are real or fake.
---@param playerName string The name of the player.
---@return number The player's total IO score.
function IOCalculator:GetPlayerTotalIO(playerName)
    NextKey222.Debug:Dev("IOCalculator", "GetPlayerTotalIO called for:", playerName)
    
    -- Check if this is the current player and ensure their data is generated
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local isCurrentPlayer = (playerName == currentPlayer) or 
                          (playerName:match("^([^%-]+)") == UnitName("player"))
    
    if isCurrentPlayer and NextKey222.Communications then
        -- Ensure current player's IO data is available
        NextKey222.Debug:Dev("IOCalculator", "Calling EnsureCurrentPlayerIOData for", playerName, "(total IO)")
        local success = NextKey222.Communications:EnsureCurrentPlayerIOData()
        NextKey222.Debug:Dev("IOCalculator", "EnsureCurrentPlayerIOData returned:", success, "(total IO)")
    end
    
    -- First priority: Check shared IO data from communications
    if NextKey222.Communications and NextKey222.Communications:HasIODataForPlayer(playerName) then
        local totalIO = NextKey222.Communications:GetPlayerTotalIO(playerName)
        NextKey222.Debug:Dev("IOCalculator", "Shared IO total for", playerName .. ":", totalIO)
        return totalIO
    end
    
    -- Second priority: Check RaiderIO data for real players without NextKey
    if not playerName:match("^FakePlayer") and NextKey222.RaiderIOAdapter then
        if NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
            local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
            if profile and profile.io then
                NextKey222.Debug:Dev("IOCalculator", "RaiderIO total for", playerName .. ":", profile.io)
                return profile.io
            end
        end
    end

    -- Third priority: For fake players, get their calculated total IO (legacy fallback)
    local fakePlayerData = NextKey222.Addon.UI and NextKey222.Addon.UI:GetFakePlayerData(playerName)
    NextKey222.Debug:Dev("IOCalculator", "Fake player data found:", fakePlayerData ~= nil)
    
    if fakePlayerData then
        NextKey222.Debug:Dev("IOCalculator", "Fake player data fields - io:", fakePlayerData.io, "score:", fakePlayerData.score)
        -- Use the calculated io field from RecalculateFakePlayerScore
        local totalIO = fakePlayerData.io or fakePlayerData.score or 0
        NextKey222.Debug:Dev("IOCalculator", "Fake player", playerName, "total IO:", totalIO)
        return totalIO
    end
    
    -- Fourth priority: For current player, try UI method
    local currentPlayer = UnitName("player")
    NextKey222.Debug:Dev("IOCalculator", "Current player check:", currentPlayer, "vs", playerName)
    if playerName == currentPlayer then
        if NextKey222.UI and NextKey222.UI.GetTotalIOScore then
            local uiTotal = NextKey222.UI:GetTotalIOScore()
            NextKey222.Debug:Dev("IOCalculator", "Current player", playerName, "UI total:", uiTotal)
            return uiTotal or 0
        end
    end
    
    NextKey222.Debug:Dev("IOCalculator", "No total IO found for", playerName, "returning 0")
    return 0
end

--- A debug function to test the Raider.IO integration for a specific player.
--- It prints the player's profile data to the debug log.
---@param playerName string The name of the player to test.
function IOCalculator:DebugRaiderIOIntegration(playerName)
    if not NextKey222.RaiderIOAdapter then
        NextKey222.Debug:Dev("IOCalculator", "RaiderIO adapter not available")
        return
    end
    
    NextKey222.Debug:Dev("IOCalculator", "Testing RaiderIO integration for", playerName)
    
    local hasData = NextKey222.RaiderIOAdapter:HasPlayerData(playerName)
    NextKey222.Debug:Dev("IOCalculator", "HasPlayerData:", hasData)
    
    if hasData then
        local profile = NextKey222.RaiderIOAdapter:GetProfile(playerName)
        if profile then
            NextKey222.Debug:Dev("IOCalculator", "Profile found - Total IO:", profile.io)
            NextKey222.Debug:Dev("IOCalculator", "Data source:", profile.dataSource)
            if profile.dungeonScores then
                local count = 0
                for dungeonID, scoreData in pairs(profile.dungeonScores) do
                    count = count + 1
                    NextKey222.Debug:Dev("IOCalculator", "  Dungeon", dungeonID .. ":", scoreData.bestScore, "(level +" .. (scoreData.bestLevel or 0) .. ")")
                end
                NextKey222.Debug:Dev("IOCalculator", "Total dungeons with scores:", count)
            end
        else
            NextKey222.Debug:Dev("IOCalculator", "Failed to get profile")
        end
    end
end

--- Updates the current player's scores for all dungeons and shares them with the group.
---@return boolean True if any scores were updated, false otherwise.
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

--- Gets the current player's stored dungeon scores for sharing with the group.
---@return table A table of the player's dungeon scores.
function IOCalculator:GetCurrentPlayerDungeonScores()
    local playerName = UnitName("player")
    if not playerName then return {} end
    
    return self.playerScores[playerName] or {}
end

--- Receives and stores dungeon scores from other players in the group.
---@param playerName string The name of the player whose scores are being received.
---@param dungeonScores table A table of the player's dungeon scores.
function IOCalculator:ReceivePlayerDungeonScores(playerName, dungeonScores)
    if not playerName or not dungeonScores then return end
    
    for dungeonID, scoreData in pairs(dungeonScores) do
        self:StorePlayerDungeonScore(playerName, dungeonID, scoreData.score, scoreData.level)
    end
    
    NextKey222.Debug:Dev("IOCalculator", "Received dungeon scores from", playerName)
end

-- MARK: Group Recommendation
--- Generates and sorts keystone recommendations for a group based on potential IO gain.
---@param availableKeystones table A list of available keystones.
---@param partyProfiles table A table of player profiles for the party.
---@param sortMode string|nil The sorting mode ("min", "max", "players", or "expected").
---@return table A sorted list of keystone recommendations.
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

--- Calculates IO gain for a player completing a specific keystone
-- Optimized for batch processing with memoization
-- @param playerName string The player's name
-- @param keystoneData table The keystone data (dungeonID, level)
-- @return number The IO gain for this player
function IOCalculator:Gain(playerName, keystoneData)
    if not playerName or not keystoneData then
        return 0
    end
    
    Debug:Dev("IOCalculator", "Gain called for", playerName, "dungeon", keystoneData.dungeonID, "level", keystoneData.level)
    
    -- Get player's current score for this dungeon
    local currentScore = self:GetPlayerDungeonScore(playerName, keystoneData.dungeonID)
    
    -- Get metrics for this keystone level
    local metrics = self:GetDungeonMetrics(keystoneData.level)
    if not metrics then
        return 0
    end
    
    -- Calculate potential gain (base score - current score)
    local potentialGain = metrics.base - currentScore
    
    -- Apply timing modifier (untimed runs get 50% of base score)
    -- For simplicity, we'll assume timed completion
    local gain = potentialGain * 0.5
    
    Debug:Dev("IOCalculator", "Gain result for", playerName, ":", gain)
    return math.max(0, gain)
end

--- Calculates aggregate IO values for a group of players
-- Used by optimizer algorithms to evaluate group potential
-- @param playerNames table List of player names
-- @param keystoneData table The keystone data (dungeonID, level)
-- @return table Aggregate values {totalIO, totalGain, averageIO, playerBreakdown}
function IOCalculator:CalculateAggregateValues(playerNames, keystoneData)
    if not playerNames or not keystoneData then
        return {
            totalIO = 0,
            totalGain = 0,
            averageIO = 0,
            playerBreakdown = {}
        }
    end
    
    Debug:Dev("IOCalculator", "CalculateAggregateValues called for", #playerNames, "players")
    
    local aggregate = {
        totalIO = 0,
        totalGain = 0,
        playerBreakdown = {}
    }
    
    -- Calculate values for each player
    for _, playerName in ipairs(playerNames) do
        local playerIO = self:GetPlayerTotalIO(playerName)
        local playerGain = self:Gain(playerName, keystoneData)
        
        aggregate.totalIO = aggregate.totalIO + playerIO
        aggregate.totalGain = aggregate.totalGain + playerGain
        aggregate.playerBreakdown[playerName] = {
            io = playerIO,
            gain = playerGain
        }
    end
    
    -- Calculate averages
    aggregate.averageIO = #playerNames > 0 and (aggregate.totalIO / #playerNames) or 0
    
    Debug:Dev("IOCalculator", "Aggregate results:", "totalIO", aggregate.totalIO, "totalGain", aggregate.totalGain, "averageIO", aggregate.averageIO)
    
    return aggregate
end

--- Calculates weighted score for a player based on role preferences
-- Used by optimizer algorithms to prioritize players for specific roles
-- @param playerName string The player's name
-- @param roleWeights table Role weights {TANK=1.5, HEALER=1.2, DAMAGER=1.0}
-- @return number The weighted score
function IOCalculator:GetWeightedScore(playerName, roleWeights)
    if not playerName or not roleWeights then
        return 0
    end
    
    -- Get player's total IO
    local totalIO = self:GetPlayerTotalIO(playerName)
    
    -- Get player's preferred roles from ProfilesService
    local preferredRoles = {}
    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetAvailableRoles then
        preferredRoles = NextKey222.ProfilesService:GetAvailableRoles(playerName)
    end
    
    -- Calculate role weight based on player's capabilities
    local roleWeight = 1.0 -- Default weight
    if preferredRoles and #preferredRoles > 0 then
        -- Use highest weight from player's available roles
        for _, role in ipairs(preferredRoles) do
            if roleWeights[role] and roleWeights[role] > roleWeight then
                roleWeight = roleWeights[role]
            end
        end
    end
    
    -- Apply role weight to total IO
    local weightedScore = totalIO * roleWeight
    
    Debug:Dev("IOCalculator", "Weighted score for", playerName, ":", weightedScore, "(roleWeight:", roleWeight, ")")
    
    return weightedScore
end

--- Calculates utility score for a player based on utility capabilities
-- Used by optimizer algorithms to prioritize players with specific utilities
-- @param playerName string The player's name
-- @param utilityWeights table Utility weights {heroism=1.5, battleRes=1.2}
-- @return number The utility score
function IOCalculator:GetUtilityScore(playerName, utilityWeights)
    if not playerName or not utilityWeights then
        return 0
    end
    
    -- Get player's utilities from ProfilesService
    local utilities = { heroism = false, battleRes = false }
    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetUtilities then
        utilities = NextKey222.ProfilesService:GetUtilities(playerName)
    end
    
    -- Calculate utility score
    local utilityScore = 0
    if utilities.heroism then
        utilityScore = utilityScore + (utilityWeights.heroism or 1.5)
    end
    
    if utilities.battleRes then
        utilityScore = utilityScore + (utilityWeights.battleRes or 1.2)
    end
    
    Debug:Dev("IOCalculator", "Utility score for", playerName, ":", utilityScore)
    
    return utilityScore
end

--- Calculates combined score for a player (IO + role weight + utility)
-- Used by optimizer algorithms for comprehensive player evaluation
-- @param playerName string The player's name
-- @param roleWeights table Role weights
-- @param utilityWeights table Utility weights
-- @return number The combined score
function IOCalculator:GetCombinedScore(playerName, roleWeights, utilityWeights)
    if not playerName then
        return 0
    end
    
    local totalIO = self:GetPlayerTotalIO(playerName)
    local weightedScore = self:GetWeightedScore(playerName, roleWeights)
    local utilityScore = self:GetUtilityScore(playerName, utilityWeights)
    
    local combinedScore = totalIO + weightedScore + utilityScore
    
    Debug:Dev("IOCalculator", "Combined score for", playerName, ":", combinedScore,
              "(IO:", totalIO, ", weighted:", weightedScore, ", utility:", utilityScore, ")")
    
    return combinedScore
end

--- Calculates preference score for a player based on dungeon preferences
-- Used by optimizer algorithms to prioritize players based on dungeon likes/dislikes
-- @param playerName string The player's name
-- @param dungeonID number The dungeon ID to check preferences for
-- @param preferenceWeights table Preference weights {liked=1.5, disliked=-1.0}
-- @return number The preference score
function IOCalculator:GetPreferenceScore(playerName, dungeonID, preferenceWeights)
    if not playerName or not dungeonID then
        return 0
    end
    
    -- Get player's preferences from ProfilesService
    local preferences = { liked = {}, disliked = {} }
    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetPreferences then
        preferences = NextKey222.ProfilesService:GetPreferences(playerName)
    end
    
    -- Calculate preference score
    local preferenceScore = 0
    if preferences.liked and preferences.liked[dungeonID] then
        preferenceScore = preferenceScore + (preferenceWeights.liked or 1.5)
    end
    
    if preferences.disliked and preferences.disliked[dungeonID] then
        preferenceScore = preferenceScore + (preferenceWeights.disliked or -1.0)
    end
    
    Debug:Dev("IOCalculator", "Preference score for", playerName, "dungeon", dungeonID, ":", preferenceScore)
    
    return preferenceScore
end

-- MARK: Addon Data Detect
--- Checks if a player has any addon data available (NextKey or RaiderIO).
--- This is used to distinguish between:
---   - Fresh characters (legitimate 0 scores) who have RaiderIO
---   - Players with no addon data at all (should be excluded from calculations)
---@param playerName string The player's name.
---@return boolean True if player has NextKey or RaiderIO data, false otherwise.
function IOCalculator:HasPlayerAddonData(playerName)
    if not playerName then
        return false
    end
    
    -- Check if it's a fake player (always has data for testing)
    if playerName:match("^FakePlayer") then
        NextKey222.Debug:Dev("IOCalculator", "HasPlayerAddonData: FakePlayer detected -", playerName)
        return true
    end
    
    -- Method 1: Check ProfilesService for addon status
    if NextKey222.ProfilesService then
        local profile = NextKey222.ProfilesService:GetProfile(playerName)
        if profile and profile.addonStatus then
            local hasData = profile.addonStatus.nextkey or profile.addonStatus.raiderio
            NextKey222.Debug:Dev("IOCalculator", string.format(
                "HasPlayerAddonData via ProfilesService for %s: nextkey=%s, raiderio=%s -> %s",
                playerName,
                tostring(profile.addonStatus.nextkey),
                tostring(profile.addonStatus.raiderio),
                tostring(hasData)))
            return hasData
        end
    end
    
    -- Method 2: Direct check for NextKey via Communications
    if NextKey222.Communications and NextKey222.Communications:HasIODataForPlayer(playerName) then
        NextKey222.Debug:Dev("IOCalculator", "HasPlayerAddonData: Player has NextKey data -", playerName)
        return true
    end
    
    -- Method 3: Direct check for RaiderIO
    if NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter:HasPlayerData(playerName) then
        NextKey222.Debug:Dev("IOCalculator", "HasPlayerAddonData: Player has RaiderIO data -", playerName)
        return true
    end
    
    -- No addon data found
    NextKey222.Debug:Dev("IOCalculator", string.format(
        "HasPlayerAddonData: No addon data found for %s (no NextKey, no RaiderIO)",
        playerName))
    return false
end

-- MARK: RaiderIO Batch Proc
--- Retrieves RaiderIO profile and calculates scores for all best runs.
--- This function is specifically designed to work with players who don't have NextKey installed.
---@param playerName string The player's name (Name-Realm format).
---@param playerRealm string|nil Optional realm (extracted from playerName if not provided).
---@return table|nil A list of { name, level, score, isTimed } or nil if profile missing.
function IOCalculator:GetPlayerDungeonScores(playerName, playerRealm)
    -- Check RaiderIO dependency
    if not _G.RaiderIO then
        NextKey222.Debug:Dev("IOCalculator", "RaiderIO addon not available for GetPlayerDungeonScores")
        return nil
    end
    
    -- Parse player name and realm
    local name, realm
    if playerName:find("-") then
        name, realm = playerName:match("(.+)-(.+)")
    else
        name = playerName
        realm = playerRealm or GetRealmName()
    end
    
    if not name then
        NextKey222.Debug:Dev("IOCalculator", "Invalid player name format:", playerName)
        return nil
    end
    
    -- Fetch RaiderIO Profile
    local profile = _G.RaiderIO.GetProfile(name, realm)
    if not (profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons) then
        NextKey222.Debug:Dev("IOCalculator", "No RaiderIO profile found for", name, "-", realm)
        return nil
    end
    
    local scores = {}
    
    NextKey222.Debug:Dev("IOCalculator", string.format("Processing RaiderIO data for %s: %d dungeons",
        name, #profile.mythicKeystoneProfile.sortedDungeons))
    
    -- Iterate over best runs (sortedDungeons contains one entry per dungeon)
    for _, dungeonRun in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
        if dungeonRun and dungeonRun.dungeon then
            local isTimed = (dungeonRun.chests or 0) > 0
            local calculatedScore = self:EstimateRunScore(
                dungeonRun.level,
                isTimed,
                dungeonRun.fractionalTime
            )
            
            -- Map RaiderIO dungeon ID to NextKey canonical ID
            local dungeonID = dungeonRun.dungeon.id
            if NextKey222.IDMapper then
                dungeonID = NextKey222.IDMapper:ToDungeonID(dungeonRun.dungeon.id, "raiderio") or dungeonRun.dungeon.id
            end
            
            table.insert(scores, {
                dungeonID = dungeonID,
                name = dungeonRun.dungeon.shortName,
                level = dungeonRun.level,
                score = calculatedScore,
                isTimed = isTimed,
                chests = dungeonRun.chests or 0,
                fractionalTime = dungeonRun.fractionalTime,
                originalRioID = dungeonRun.dungeon.id
            })
            
            NextKey222.Debug:Dev("IOCalculator", string.format("  %s (ID:%d): level=%d, chests=%d, fractional=%.2f -> score=%d",
                dungeonRun.dungeon.shortName, dungeonID, dungeonRun.level,
                dungeonRun.chests or 0, dungeonRun.fractionalTime or 0, calculatedScore))
        end
    end
    
    NextKey222.Debug:Dev("IOCalculator", string.format("Calculated %d dungeon scores for %s", #scores, name))
    
    return scores
end

return IOCalculator
