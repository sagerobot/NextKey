-- MARK: Blizzard API Profile Adapter
-- Adapter for converting Blizzard Challenge Mode APIs into standard PlayerProfile format

local _, NextKey222 = ...

local BlizzardAdapter = {}

-- MARK: Blizzard API Integration
function BlizzardAdapter:IsAvailable()
    return C_ChallengeMode and 
           C_ChallengeMode.GetMapUIInfo and 
           C_ChallengeMode.GetMapTable and
           C_MythicPlus and
           C_MythicPlus.GetCurrentSeason
end

-- MARK: Profile Building
function BlizzardAdapter:GetProfile(playerName)
    if not self:IsAvailable() then
        return nil
    end
    
    -- Check if this is the current player (Blizzard APIs mainly work for self)
    local currentPlayerName = UnitName("player")
    local currentRealm = GetRealmName()
    local currentFullName = currentPlayerName .. "-" .. currentRealm
    
    if playerName ~= currentFullName and playerName ~= currentPlayerName then
        -- Blizzard APIs don't provide data for other players in most cases
        return nil
    end
    
    -- Build profile for current player
    local currentSpec = GetSpecialization() or 0
    local specID = GetSpecializationInfo and select(1, GetSpecializationInfo(currentSpec))

    -- Debug logging for current player spec detection
    if NextKey222.Debug then
        local specName = GetSpecializationInfo and select(2, GetSpecializationInfo(currentSpec)) or "Unknown"
        local role = GetSpecializationInfo and select(5, GetSpecializationInfo(currentSpec)) or "Unknown"
        NextKey222.Debug:Dev("blizzard_adapter", string.format("Current Player Debug: playerName=%s, currentSpec=%d, specID=%d, specName=%s, role=%s",
            playerName, currentSpec, specID or 0, specName, role))
    end
    
    local profile = {
        name = playerName,
        class = select(2, UnitClass("player")),
        specID = specID,
        io = 0, -- Will be calculated from dungeon scores
        dataSource = "blizzard",
        dungeonScores = {},
        addonStatus = { nextkey = true, raiderio = false }
    }
    
    -- Get mythic plus data
    self:LoadMythicPlusData(profile)
    
    return profile
end

-- MARK: Mythic Plus Data Loading
function BlizzardAdapter:LoadMythicPlusData(profile)
    local currentSeason = C_MythicPlus.GetCurrentSeason()
    if not currentSeason then
        return
    end
    
    -- Get available maps for current season
    local maps = C_ChallengeMode.GetMapTable()
    if not maps then
        return
    end
    
    local totalIO = 0
    
    for _, challengeMapID in ipairs(maps) do
        local mapInfo = C_ChallengeMode.GetMapUIInfo(challengeMapID)
        if mapInfo then
            -- Get best run for this map
            local bestRun = self:GetBestRunForMap(challengeMapID)
            if bestRun then
                -- Convert challenge map ID to NextKey canonical ID
                local dungeonID = challengeMapID
                if NextKey222.IDMapper then
                    dungeonID = NextKey222.IDMapper:ChallengeMapToDungeonID(challengeMapID) or challengeMapID
                end
                
                -- Calculate score from run data
                local score = self:CalculateScoreFromRun(bestRun)
                
                profile.dungeonScores[dungeonID] = {
                    bestScore = score,
                    bestLevel = bestRun.level,
                    timeLimit = bestRun.timeLimit or 1800000,
                    dataSource = "blizzard_api",
                    timed = bestRun.timed,
                    chests = bestRun.chests,
                    completionTime = bestRun.completionTime,
                    originalMapID = challengeMapID
                }
                
                totalIO = totalIO + score
            end
        end
    end
    
    profile.io = totalIO
end

-- MARK: Challenge Mode Data Access
function BlizzardAdapter:GetBestRunForMap(challengeMapID)
    -- Try different methods to get best run data
    
    -- Method 1: GetDungeonScoreRarityColor (if available)
    if C_ChallengeMode.GetDungeonScoreRarityColor then
        local overallScore, isMapScore = C_ChallengeMode.GetOverallDungeonScore()
        if overallScore and isMapScore then
            -- This gives us overall score but not per-dungeon breakdown
            -- We need individual run data
        end
    end
    
    -- Method 2: Check completion history (limited data available)
    if C_ChallengeMode.GetCompletionHistory then
        local history = C_ChallengeMode.GetCompletionHistory()
        if history then
            for _, run in ipairs(history) do
                if run.mapChallengeModeID == challengeMapID then
                    return {
                        level = run.level,
                        timed = run.onTime,
                        chests = run.keystoneUpgradeLevels or 0,
                        completionTime = run.completionMilliseconds,
                        timeLimit = run.timeLimit
                    }
                end
            end
        end
    end
    
    -- Method 3: Try to get from keystone data (current keystones only)
    local currentKeystone = self:GetCurrentKeystone()
    if currentKeystone and currentKeystone.challengeMapID == challengeMapID then
        return {
            level = currentKeystone.level,
            timed = false, -- Unknown for current keystone
            chests = 0,
            timeLimit = 1800000 -- Default
        }
    end
    
    return nil
end

function BlizzardAdapter:GetCurrentKeystone()
    if C_MythicPlus.GetOwnedKeystoneChallengeMapID then
        local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        local level = C_MythicPlus.GetOwnedKeystoneLevel()
        
        if mapID and level then
            return {
                challengeMapID = mapID,
                level = level
            }
        end
    end
    
    return nil
end

-- MARK: Score Calculation
function BlizzardAdapter:CalculateScoreFromRun(runData)
    if not runData or not runData.level then
        return 0
    end
    
    -- Use IOCalculator if available for consistent scoring
    if NextKey222.IOCalculator then
        local timed = runData.timed ~= false -- Default to timed if unknown
        local chests = runData.chests or (timed and 1 or 0)
        return NextKey222.IOCalculator:EstimateRunScore(runData.level, timed, chests)
    end
    
    -- Fallback calculation (basic approximation)
    local baseScore = runData.level * 25
    local timingMultiplier = runData.timed and 1.0 or 0.6
    local chestBonus = (runData.chests or 0) * 5
    
    return math.floor(baseScore * timingMultiplier + chestBonus)
end

-- MARK: Group Data Access
function BlizzardAdapter:GetGroupMembers()
    local members = {}
    
    -- Add current player
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    if playerName and realmName then
        table.insert(members, playerName .. "-" .. realmName)
    end
    
    -- Note: Blizzard APIs don't provide detailed M+ data for other group members
    -- This adapter primarily works for the current player only
    
    return members
end

-- MARK: Player Detection
function BlizzardAdapter:HasPlayerData(playerName)
    -- Only has data for current player
    local currentPlayerName = UnitName("player")
    local currentRealm = GetRealmName()
    local currentFullName = currentPlayerName .. "-" .. currentRealm
    
    return playerName == currentFullName or playerName == currentPlayerName
end

-- MARK: Season Information
function BlizzardAdapter:GetCurrentSeasonInfo()
    if not self:IsAvailable() then
        return nil
    end
    
    local seasonID = C_MythicPlus.GetCurrentSeason()
    local maps = C_ChallengeMode.GetMapTable()
    
    return {
        seasonID = seasonID,
        maps = maps,
        isActive = seasonID ~= nil
    }
end

-- MARK: Export
NextKey222.BlizzardAdapter = BlizzardAdapter