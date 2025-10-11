-- MARK: Score Calculation Functions
-- All score calculation now handled by IOCalculator module
-- This file maintains only the remaining player score tracking functions
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then
    return
end

-- MARK: Season Score Functions  
function NextKey:GetRunScoreForLevel(level, timed)
    if not level or level < 2 then return 0 end
    -- Use IOCalculator directly for score estimation
    if NextKey222.IOCalculator then
        local fractionalTime = timed and 0.9 or nil
        return NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    end
    return 0
end

function NextKey:GetSeasonBestLevel(dungeonID)
    if not dungeonID then return nil end
    local bestRun = C_MythicPlus.GetSeasonBestForMap(dungeonID)
    return bestRun and bestRun.level or nil
end

-- MARK: Score Functions
function NextKey:GetCurrentScore()
    return self.currentSeasonScore or 0
end

function NextKey:GetPreviousScore()
    return self.previousSeasonScore or 0
end

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
function NextKey:CalculateMythicPlusScore(level, chests)
    if not level or level <= 0 then
        return 0
    end
    
    -- Base score calculation (approximate WoW M+ scoring)
    -- Each level has a base score, with timing bonuses
    local baseScore = 0
    
    if level >= 2 then
        -- Rough approximation of WoW's M+ scoring system
        -- Base scores increase significantly with level
        if level <= 10 then
            baseScore = level * 15  -- Levels 2-10: 30-150 base
        elseif level <= 15 then
            baseScore = 150 + (level - 10) * 20  -- Levels 11-15: 170-250 base
        elseif level <= 20 then
            baseScore = 250 + (level - 15) * 25  -- Levels 16-20: 275-375 base
        else
            baseScore = 375 + (level - 20) * 30  -- Levels 21+: 405+ base
        end
        
        -- Apply timing multiplier based on chests (medals)
        -- 0 chests = not timed (40% penalty), 1+ chests = timed (full score or bonus)
        if chests == 0 then
            baseScore = baseScore * 0.6  -- Untimed penalty
        elseif chests >= 2 then
            baseScore = baseScore * 1.2  -- 2+ chest bonus
        elseif chests >= 1 then
            baseScore = baseScore * 1.0  -- 1 chest = full score
        end
    end
    
    return math.floor(baseScore)
end