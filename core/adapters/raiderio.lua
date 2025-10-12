-- MARK: RaiderIO Profile Adapter
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

-- MARK: Dungeon Score Conversion
function RaiderIOAdapter:ConvertDungeonScores(profile, mkProfile)
    -- RaiderIO provides both Fortified and Tyrannical scores
    -- We'll use the best score for each dungeon
    
    local fortifiedScores = mkProfile.fortifiedDungeonScores or {}
    local tyrannicalScores = mkProfile.tyrannicalDungeonScores or {}
    
    -- Get all unique dungeon IDs from both affixes
    local allDungeonIDs = {}
    for dungeonID, _ in pairs(fortifiedScores) do
        allDungeonIDs[dungeonID] = true
    end
    for dungeonID, _ in pairs(tyrannicalScores) do
        allDungeonIDs[dungeonID] = true
    end
    
    -- Process each dungeon
    for rioID, _ in pairs(allDungeonIDs) do
        local fortScore = fortifiedScores[rioID]
        local tyrScore = tyrannicalScores[rioID]
        
        -- Pick the best score between both affixes
        local bestScore = nil
        if fortScore and tyrScore then
            bestScore = (fortScore.score > tyrScore.score) and fortScore or tyrScore
        else
            bestScore = fortScore or tyrScore
        end
        
        if bestScore then
            -- Convert RaiderIO dungeon ID to NextKey canonical ID
            local dungeonID = rioID
            if NextKey222.IDMapper then
                dungeonID = NextKey222.IDMapper:ToDungeonID(rioID, "raiderio") or rioID
            end
            
            profile.dungeonScores[dungeonID] = {
                bestScore = bestScore.score or 0,
                bestLevel = bestScore.level or 0,
                timeLimit = 1800000, -- Default 30 minutes
                dataSource = "raiderio",
                chests = bestScore.chests,
                fractionalTime = bestScore.fractionalTime,
                originalRioID = rioID -- Keep original for debugging
            }
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