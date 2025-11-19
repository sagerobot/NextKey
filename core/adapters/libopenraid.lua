-- MARK: Adapter
-- Adapter for converting LibOpenRaid player data into standard PlayerProfile format

local _, NextKey222 = ...

local LibOpenRaidAdapter = {}

-- MARK: Integration
-- LibOpenRaid library reference and initialization
local openRaidLib = nil

function LibOpenRaidAdapter:Initialize()
    -- Get LibOpenRaid library
    if LibStub then
        local success, lib = pcall(LibStub.GetLibrary, LibStub, "LibOpenRaid-1.0")
        if success and lib then
            openRaidLib = lib
            return true
        end
    end
    return false
end

-- MARK: Profile Builder
-- Build player profile from LibOpenRaid data
function LibOpenRaidAdapter:GetProfile(playerName)
    if not openRaidLib then
        self:Initialize()
        if not openRaidLib then
            return nil
        end
    end
    
    -- Get player info from LibOpenRaid
    local playerInfo = openRaidLib.GetPlayerInfo and openRaidLib:GetPlayerInfo(playerName)
    if not playerInfo then
        return nil
    end
    
    local profile = {
        name = playerName,
        class = playerInfo.class,
        specID = playerInfo.specID,
        io = 0, -- Will be calculated from dungeon scores
        dataSource = "libopenraid",
        dungeonScores = {},
        addonStatus = { nextkey = false, raiderio = false }
    }
    
    -- Get keystones/dungeon data from LibOpenRaid
    local keystones = self:GetPlayerKeystones(playerName)
    if keystones then
        local totalIO = 0
        
        for _, keystoneData in pairs(keystones) do
            if keystoneData.mapID and keystoneData.level then
                -- Convert mapID to NextKey canonical ID
                local dungeonID = keystoneData.mapID
                if NextKey222.IDMapper then
                    dungeonID = NextKey222.IDMapper:ToDungeonID(keystoneData.mapID, "challenge") or keystoneData.mapID
                end
                
                -- Calculate or extract score
                local score = keystoneData.score
                if not score and NextKey222.IOCalculator then
                    -- Estimate score from level and completion status
                    local timed = keystoneData.timed ~= false -- Default to timed if unknown
                    local chests = keystoneData.chests or (timed and 1 or 0)
                    score = NextKey222.IOCalculator:EstimateRunScore(keystoneData.level, timed, chests)
                end
                
                profile.dungeonScores[dungeonID] = {
                    bestScore = score or 0,
                    bestLevel = keystoneData.level,
                    timeLimit = keystoneData.timeLimit or 1800000,
                    dataSource = "libopenraid",
                    timed = keystoneData.timed,
                    chests = keystoneData.chests,
                    originalMapID = keystoneData.mapID
                }
                
                totalIO = totalIO + (score or 0)
            end
        end
        
        profile.io = totalIO
    end
    
    return profile
end

-- MARK: Data Access
function LibOpenRaidAdapter:GetPlayerKeystones(playerName)
    if not openRaidLib then return nil end
    
    -- Try different LibOpenRaid methods to get keystone data
    local keystones = {}
    
    -- Method 1: Direct keystone access (if available)
    if openRaidLib.GetPlayerKeystones then
        local playerKeystones = openRaidLib:GetPlayerKeystones(playerName)
        if playerKeystones then
            for mapID, keystoneData in pairs(playerKeystones) do
                keystones[mapID] = keystoneData
            end
        end
    end
    
    -- Method 2: Get from unit info (if player is in group)
    local unitInfo = openRaidLib.GetUnitInfo and openRaidLib:GetUnitInfo(playerName)
    if unitInfo and unitInfo.mythicKeystoneMapID then
        local mapID = unitInfo.mythicKeystoneMapID
        local level = unitInfo.mythicKeystoneLevel or 0
        
        keystones[mapID] = {
            mapID = mapID,
            level = level,
            dataSource = "unit_info"
        }
    end
    
    -- Method 3: Check cached challenge mode data
    if openRaidLib.GetChallengeModeData then
        local challengeData = openRaidLib:GetChallengeModeData(playerName)
        if challengeData then
            for mapID, data in pairs(challengeData) do
                if data.level and data.level > 0 then
                    keystones[mapID] = {
                        mapID = mapID,
                        level = data.level,
                        score = data.score,
                        timed = data.timed,
                        chests = data.chests,
                        timeLimit = data.timeLimit,
                        dataSource = "challenge_cache"
                    }
                end
            end
        end
    end
    
    return (#keystones > 0) and keystones or nil
end

-- MARK: Detection
-- Check if player data is available in LibOpenRaid
function LibOpenRaidAdapter:HasPlayerData(playerName)
    if not openRaidLib then
        self:Initialize()
        if not openRaidLib then
            return false
        end
    end
    
    return (openRaidLib.GetPlayerInfo and openRaidLib:GetPlayerInfo(playerName) ~= nil) or
           (openRaidLib.GetUnitInfo and openRaidLib:GetUnitInfo(playerName) ~= nil)
end

-- MARK: Group Data
-- Access group member data from LibOpenRaid
function LibOpenRaidAdapter:GetGroupMembers()
    if not openRaidLib then return {} end
    
    local members = {}
    
    -- Get all known players from LibOpenRaid
    if openRaidLib.GetAllPlayers then
        local allPlayers = openRaidLib:GetAllPlayers()
        for playerName, _ in pairs(allPlayers or {}) do
            table.insert(members, playerName)
        end
    end
    
    return members
end

-- MARK: Export
NextKey222.LibOpenRaidAdapter = LibOpenRaidAdapter