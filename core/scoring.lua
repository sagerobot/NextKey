-- MARK: Score Calculation Functions
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then
    return
end

-- MARK: Run Time Functions
function NextKey:ApproximateFractionalFromChests(chests)
    if not chests or chests < 0 then return 0 end
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

-- MARK: Score Estimation
function NextKey:EstimateRunScore(level, timed, fractionalTime)
    if not level or level < 2 then return 0 end
    
    -- Base score calculation
    local baseScore = (level - 2) * 7.5
    if level >= 20 then
        baseScore = baseScore * 1.5
    elseif level >= 15 then
        baseScore = baseScore * 1.2
    end
    
    -- Apply timing modifier
    if not timed then
        baseScore = baseScore * 0.4
    elseif fractionalTime then
        -- Bonus for faster times
        local timeBonus = (1 - fractionalTime) * 0.3
        baseScore = baseScore * (1 + timeBonus)
    end
    
    return math.floor(baseScore + 0.5)
end

-- MARK: Season Score Functions
function NextKey:GetRunScoreForLevel(level, timed)
    if not level or level < 2 then return 0 end
    return self:EstimateRunScore(level, timed, timed and 0.9 or nil)
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