-- MARK: IO Calculator Module
-- Rating calculation logic based on MythicPlanner.com algorithm
-- Implements the exact formulas used by mythicplanner.com for accurate IO gain predictions

local IOCalculator = {}
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
    NextKey222.Debug:Print("IOCalculator", "Initialized with MythicPlanner.com algorithm")
    return true
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
        return { min = 0, max = 0, expected = 0 }
    end
    
    local dungeonId = keystoneData.dungeonID
    local keyLevel = keystoneData.level
    local playerScores = playerProfile.dungeonScores or {}
    local currentScore = (playerScores[dungeonId] and playerScores[dungeonId].bestScore) or 0
    
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
        playerBreakdown = {}
    }
    
    for playerName, profile in pairs(partyProfiles or {}) do
        local playerRange = self:CalculateIORange(keystoneData, profile)
        
        -- Add to totals
        groupRange.min = groupRange.min + playerRange.min
        groupRange.max = groupRange.max + playerRange.max
        groupRange.expected = groupRange.expected + playerRange.expected
        
        -- Store individual breakdown for tooltip
        groupRange.playerBreakdown[playerName] = {
            current = playerRange.currentScore,
            range = playerRange,
            gainText = string.format("%d → %d-%d (+%d-%d)",
                playerRange.currentScore,
                playerRange.targetScores.min,
                playerRange.targetScores.max,
                playerRange.min,
                playerRange.max)
        }
    end
    
    return groupRange
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