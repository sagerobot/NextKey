-- MARK: Season Data Management
local _, NS = ...
local NextKey = NS.Addon

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
        previousScore = 0
    }

    -- Try to get score from Raider.IO if available
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local profile = _G.RaiderIO.GetProfile("player")
        if profile then
            data.currentScore = profile.mythicKeystoneScore or 0
            data.previousScore = profile.previousScore or 0
        end
    end

    -- Fallback to game API
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
    local info = C_ChallengeMode.GetMapUIInfo(dungeonID)
    return info
end

-- MARK: Season Best Data
function NextKey:GetSeasonBestEntry(dungeonID)
    if not dungeonID then return nil end

    local mapScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(dungeonID)
    if not mapScore then return nil end

    local bestRunLevel = C_MythicPlus.GetSeasonBestForMap(dungeonID)
    return {
        dungeonID = dungeonID,
        level = bestRunLevel and bestRunLevel.level or 0,
        score = mapScore.score or 0
    }
end