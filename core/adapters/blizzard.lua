-- MARK: Blizzard API Profile Adapter
-- Adapter for converting Blizzard Challenge Mode APIs into standard PlayerProfile format

local _, NextKey222 = ...

local BlizzardAdapter = {}

-- Get LibGroupInSpecT if available
local LibGroupInSpecT = LibStub and LibStub:GetLibrary("LibGroupInSpecT-1.1", true)

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
    
    local isCurrentPlayer = (playerName == currentFullName or playerName == currentPlayerName)
    
    -- Try to get spec data for group members
    local specID, className, role
    if isCurrentPlayer then
        -- Current player: use GetSpecialization
        local currentSpec = GetSpecialization() or 0
        specID = GetSpecializationInfo and select(1, GetSpecializationInfo(currentSpec))
        className = select(2, UnitClass("player"))
        role = GetSpecializationInfo and select(5, GetSpecializationInfo(currentSpec))
        
        -- Debug logging for current player spec detection
        if NextKey222.Debug then
            local specName = GetSpecializationInfo and select(2, GetSpecializationInfo(currentSpec)) or "Unknown"
            NextKey222.Debug:Dev("blizzard_adapter", string.format("Current Player Debug: playerName=%s, currentSpec=%d, specID=%d, specName=%s, role=%s",
                playerName, currentSpec, specID or 0, specName, role or "nil"))
        end
    else
        -- Group member: try to find unit ID and get spec
        local unitID = self:FindUnitIDForPlayer(playerName)
        if unitID then
            className = select(2, UnitClass(unitID))
            
            -- PRIORITY 1: Try LibGroupInSpecT if available (best source for group member specs)
            if LibGroupInSpecT then
                local guid = UnitGUID(unitID)
                local info = guid and LibGroupInSpecT:GetCachedInfo(guid)
                
                if info then
                    specID = info.global_spec_id
                    specName = info.spec_name_localized
                    role = info.spec_role
                    
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("blizzard_adapter", string.format("LibGroupInSpecT: playerName=%s, specID=%s, specName=%s, role=%s",
                            playerName, tostring(specID or 0), tostring(specName or "nil"), tostring(role or "nil")))
                    end
                end
            end
            
            -- PRIORITY 2: Fall back to standard APIs if LibGroupInSpecT didn't have data
            if not specID or specID == 0 then
                specID = GetInspectSpecialization(unitID)
                
                -- Use UnitGroupRolesAssigned as fallback
                if UnitGroupRolesAssigned then
                    role = UnitGroupRolesAssigned(unitID)
                    
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("blizzard_adapter", string.format("UnitGroupRolesAssigned(%s) returned: %s",
                            unitID, tostring(role)))
                    end
                end
                
                -- If we got a valid specID from inspection, get the spec name
                if specID and specID > 0 and GetSpecializationInfoByID then
                    local _, name = GetSpecializationInfoByID(specID)
                    specName = name
                    -- Also verify role matches spec
                    local specRole = GetSpecializationRoleByID(specID)
                    if specRole and (not role or role == "NONE") then
                        role = specRole
                    end
                end
            end
            
            if NextKey222.Debug then
                NextKey222.Debug:Dev("blizzard_adapter", string.format("Group Member Final: playerName=%s, unitID=%s, specID=%s, specName=%s, class=%s, role=%s",
                    playerName, unitID, tostring(specID or 0), tostring(specName or "nil"), tostring(className), tostring(role)))
            end
        else
            -- Can't find unit ID, return nil for non-current player
            return nil
        end
    end
    
    local profile = {
        name = playerName,
        class = className,
        specID = specID,
        specName = specName,  -- Include spec name for tooltips
        role = role,  -- CRITICAL: Include role from spec detection
        io = 0, -- Will be calculated from dungeon scores
        dataSource = "blizzard",
        dungeonScores = {},
        addonStatus = { nextkey = true, raiderio = false }
    }
    
    -- Only load M+ data for current player (Blizzard APIs don't provide this for others)
    if isCurrentPlayer then
        self:LoadMythicPlusData(profile)
    end
    
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

-- MARK: Unit ID Lookup
function BlizzardAdapter:FindUnitIDForPlayer(playerName)
    -- Try to find the unit ID for a player name (for group members)
    local shortName = playerName:match("^([^%-]+)") or playerName
    
    -- Check party members
    if IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            local name = UnitName(unit)
            if name == shortName or name == playerName then
                return unit
            end
        end
    end
    
    -- Check raid members
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local name = UnitName(unit)
            if name == shortName or name == playerName then
                return unit
            end
        end
    end
    
    return nil
end

-- MARK: Player Detection
function BlizzardAdapter:HasPlayerData(playerName)
    -- Has data for current player
    local currentPlayerName = UnitName("player")
    local currentRealm = GetRealmName()
    local currentFullName = currentPlayerName .. "-" .. currentRealm
    
    if playerName == currentFullName or playerName == currentPlayerName then
        return true
    end
    
    -- Also has basic spec data for group members
    return self:FindUnitIDForPlayer(playerName) ~= nil
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