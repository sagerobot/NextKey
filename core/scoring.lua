-- MARK: Score Calculation Functions
-- All score calculation now handled by IOCalculator module
-- This file maintains only the remaining player score tracking functions
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then
    return
end

-- MARK: Season Score Functions  
-- MARK: Season Score Functions
--- Estimates the Mythic+ score for a given keystone level and timing.
--- @param level number The keystone level.
--- @param timed boolean Whether the run was completed within the timer.
--- @return number The estimated score.
function NextKey:GetRunScoreForLevel(level, timed)
    if not level or level < 2 then return 0 end
    -- Use IOCalculator directly for score estimation
    if NextKey222.IOCalculator then
        local fractionalTime = timed and 0.9 or nil
        return NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    end
    return 0
end

--- Gets the player's best keystone level for a specific dungeon this season.
--- @param dungeonID number The ID of the dungeon.
--- @return number|nil The player's best keystone level for the dungeon, or nil if not found.
function NextKey:GetSeasonBestLevel(dungeonID)
    if not dungeonID then return nil end
    local bestRun = C_MythicPlus.GetSeasonBestForMap(dungeonID)
    return bestRun and bestRun.level or nil
end

-- MARK: Score Functions
--- Gets the player's current Mythic+ score.
--- @return number The player's current score.
function NextKey:GetCurrentScore()
    return self.currentSeasonScore or 0
end

--- Gets the player's Mythic+ score from the previous season.
--- @return number The player's previous season score.
function NextKey:GetPreviousScore()
    return self.previousSeasonScore or 0
end

--- Updates the player's current and previous Mythic+ scores from the game API and Raider.IO.
function NextKey:UpdatePlayerScore()
    -- Get base score from game API
    self.currentSeasonScore = C_ChallengeMode.GetOverallDungeonScore() or 0
    
    -- Try to get RaiderIO score if available
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local profile = _G.RaiderIO.GetProfile("player")
        if profile then
            self.currentSeasonScore = profile.mythicKeystoneScore or self.currentSeasonScore
            self.previousSeasonScore = profile.previousScore or 0
        end
    end
    
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        self:Print("Score updated:", self.currentSeasonScore)
    end
end

-- MARK: RaiderIO Integration Functions
--- Gets the player's total Mythic+ score from Raider.IO.
--- @return number The player's Raider.IO score.
function NextKey:GetRaiderIOTotalScore()
    if not _G.RaiderIO or not _G.RaiderIO.GetProfile then
        return 0
    end
    
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local profile = _G.RaiderIO.GetProfile(playerName, realmName)
    
    if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
        return profile.mythicKeystoneProfile.currentScore
    end
    
    return 0
end

-- Helper function to calculate Mythic+ score from level and chests
--- Calculates an approximate Mythic+ score based on keystone level and number of chests.
--- @param level number The keystone level.
--- @param chests number The number of chests earned (0-3).
--- @return number The calculated score.
function NextKey:CalculateMythicPlusScore(level, chests)
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