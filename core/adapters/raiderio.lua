-- MARK: RaiderIO Adapter
-- Adapter for converting RaiderIO player data into standard PlayerProfile format

local _, NextKey222 = ...

local RaiderIOAdapter = {}

-- MARK: RaiderIO Integration
function RaiderIOAdapter:IsAvailable()
    return _G.RaiderIO and _G.RaiderIO.GetProfile ~= nil
end

-- MARK: Profile Building
function RaiderIOAdapter:GetProfile(playerName)
    if not self:IsAvailable() then
        return nil
    end
    
    -- Parse player name and realm
    local name, realm
    if playerName:find("-") then
        name, realm = playerName:match("(.+)-(.+)")
    else
        name = playerName
        realm = GetRealmName()
    end
    
    if not name then
        return nil
    end
    
    -- Get RaiderIO profile
    local rioProfile = _G.RaiderIO.GetProfile(name, realm)
    if not rioProfile or not rioProfile.mythicKeystoneProfile then
        return nil
    end
    
    local mkProfile = rioProfile.mythicKeystoneProfile
    
    -- Build standard profile
    local profile = {
        name = playerName,
        class = rioProfile.class,
        specID = mkProfile.specID,
        io = mkProfile.currentScore or 0,
        dataSource = "raiderio",
        dungeonScores = {},
        addonStatus = { nextkey = false, raiderio = true }
    }
    
    -- Convert dungeon scores from RaiderIO format
    self:ConvertDungeonScores(profile, mkProfile)
    
    return profile
end

-- MARK: Dungeon Score Conv.
function RaiderIOAdapter:ConvertDungeonScores(profile, mkProfile)
    -- CRITICAL: RaiderIO does NOT provide per-dungeon scores directly
    -- We must calculate them from level, chests, and fractionalTime data
    
    -- Get sorted dungeons array which contains level, chests, fractionalTime per dungeon
    local sortedDungeons = mkProfile.sortedDungeons or {}
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("raiderio", string.format("Converting RaiderIO dungeon data for %s: %d dungeons found",
            profile.name, #sortedDungeons))
    end
    
    -- Process each dungeon
    for _, dungeonProfile in ipairs(sortedDungeons) do
        if dungeonProfile.dungeon and dungeonProfile.level then
            local dungeon = dungeonProfile.dungeon
            local level = dungeonProfile.level
            local chests = dungeonProfile.chests or 0
            local fractionalTime = dungeonProfile.fractionalTime
            
            -- CRITICAL: Skip dungeons with level=0 (no data available, not a legitimate run)
            -- level=0 means the player has never run this dungeon, not that they have a 0 score
            if level == 0 then
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("raiderio", string.format("Skipping %s (ID:%d) for %s: level=0 (no run data)",
                        dungeon.shortName or "unknown", dungeon.id, profile.name))
                end
                -- Don't add to dungeonScores - this indicates no data, not a 0 score
            else
                -- Calculate score using IOCalculator with TWW Season 1 formula
                local calculatedScore = 0
                if NextKey222.IOCalculator and NextKey222.IOCalculator.EstimateRunScore then
                    -- Determine if the run was timed (chests > 0 means timed)
                    local timed = chests > 0
                    calculatedScore = NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
                    
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("raiderio", string.format("TWW S1 Score for %s (ID:%d): level=%d, chests=%d, fractional=%.2f, timed=%s -> score=%d",
                            dungeon.shortName or "unknown", dungeon.id, level, chests,
                            fractionalTime or 0, tostring(timed), calculatedScore))
                    end
                else
                    -- Fallback warning if IOCalculator is not available
                    if NextKey222.Debug then
                        NextKey222.Debug:Error("RaiderIO adapter: IOCalculator not available for score calculation")
                    end
                end
                
                -- Convert RaiderIO dungeon ID to NextKey canonical ID
                local dungeonID = dungeon.id
                if NextKey222.IDMapper then
                    dungeonID = NextKey222.IDMapper:ToDungeonID(dungeon.id, "raiderio") or dungeon.id
                end
                
                profile.dungeonScores[dungeonID] = {
                    bestScore = calculatedScore,
                    bestLevel = level,
                    timeLimit = 1800000, -- Default 30 minutes
                    dataSource = "raiderio_calculated",
                    chests = chests,
                    fractionalTime = fractionalTime,
                    originalRioID = dungeon.id -- Keep original for debugging
                }
            end
        end
    end
    
    if NextKey222.Debug then
        -- Calculate sum of all dungeon scores we calculated
        local calculatedTotal = 0
        if profile.dungeonScores then
            for dungeonID, scoreData in pairs(profile.dungeonScores) do
                calculatedTotal = calculatedTotal + (scoreData.bestScore or 0)
            end
        end
        
        -- Log comparison with RaiderIO's total IO
        local rioTotal = profile.io or 0
        local difference = rioTotal - calculatedTotal
        
        NextKey222.Debug:Dev("raiderio", string.format("Conversion complete: %d dungeon scores calculated for %s",
            profile.dungeonScores and NextKey222.ProfilesService:CountTable(profile.dungeonScores) or 0, profile.name))
        NextKey222.Debug:Dev("raiderio", string.format("  [SCORE CHECK] %s: RaiderIO Total=%d, Calculated Sum=%d, Difference=%d",
            profile.name, rioTotal, calculatedTotal, difference))
        
        if difference > 50 or difference < -50 then
            NextKey222.Debug:User("raiderio", string.format("WARNING: Large score discrepancy for %s! RaiderIO=%d, Calculated=%d (diff=%d)",
                profile.name, rioTotal, calculatedTotal, difference))
        end
    end
end

-- MARK: Batch Profile Access
function RaiderIOAdapter:GetGroupProfiles(playerNames)
    if not self:IsAvailable() then
        return {}
    end
    
    local profiles = {}
    
    for _, playerName in ipairs(playerNames or {}) do
        local profile = self:GetProfile(playerName)
        if profile then
            profiles[playerName] = profile
        end
    end
    
    return profiles
end

-- MARK: Player Detection
function RaiderIOAdapter:HasPlayerData(playerName)
    if not self:IsAvailable() then
        return false
    end
    
    -- Parse player name
    local name, realm
    if playerName:find("-") then
        name, realm = playerName:match("(.+)-(.+)")
    else
        name = playerName
        realm = GetRealmName()
    end
    
    if not name then
        return false
    end
    
    -- Quick check for RaiderIO data
    local rioProfile = _G.RaiderIO.GetProfile(name, realm)
    return rioProfile and rioProfile.mythicKeystoneProfile ~= nil
end

-- MARK: Utility Functions
function RaiderIOAdapter:GetScoreColor(score)
    if self:IsAvailable() and _G.RaiderIO.GetScoreColor then
        return _G.RaiderIO.GetScoreColor(score)
    end
    return 1, 1, 1 -- White fallback
end

-- MARK: Export
NextKey222.RaiderIOAdapter = RaiderIOAdapter