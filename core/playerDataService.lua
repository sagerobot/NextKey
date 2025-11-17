-- MARK: Player Data Service Module
-- Handles all player IO data management, caching, and sharing
-- Extracted from Communications module as part of Phase 4 refactoring

local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- MARK: Module Definition
local PlayerDataService = {
    playerIOCache = {},
    lastCacheCleanup = 0,
    cacheCleanupInterval = 600, -- 10 minutes
    cacheMaxAge = 600, -- 10 minutes
}

NextKey222.PlayerDataService = PlayerDataService
NextKey222.RegisterModule("PlayerDataService", PlayerDataService)

-- MARK: Public API - IO Data Access

--- Gets stored IO data for a specific player
--- @param playerName string Full player name with realm
--- @return table|nil The player's IO data package
function PlayerDataService:GetPlayerIOData(playerName)
    return self.playerIOCache[playerName]
end

--- Gets total IO score for a specific player from cached data
--- @param playerName string Full player name with realm  
--- @return number The player's total IO score (0 if not available)
function PlayerDataService:GetPlayerTotalIO(playerName)
    local ioData = self.playerIOCache[playerName]
    if ioData then
        return NextKey222.PlayerIODataStructure:GetTotalScore(ioData)
    end
    return 0
end

--- Gets dungeon-specific IO score for a player from cached data
--- @param playerName string Full player name with realm
--- @param dungeonID number The dungeon ID
--- @return number The IO score for this dungeon (0 if not available)
function PlayerDataService:GetPlayerDungeonScore(playerName, dungeonID)
    local ioData = self.playerIOCache[playerName]
    if ioData then
        return NextKey222.PlayerIODataStructure:GetDungeonScore(ioData, dungeonID)
    end
    return 0
end

--- Checks if we have IO data for a specific player
--- @param playerName string Full player name with realm
--- @return boolean Whether we have IO data for this player
function PlayerDataService:HasIODataForPlayer(playerName)
    return self.playerIOCache[playerName] ~= nil
end

-- MARK: Public API - IO Data Creation and Sharing

--- Creates an IO package for the specified player
--- @param playerName string Full player name with realm
--- @return table|nil The created IO package, or nil if creation failed
function PlayerDataService:CreateIOPackage(playerName)
    NextKey222.Debug:Dev("player_data", "Creating IO package for", playerName)
    
    -- Create standardized IO package
    local ioPackage = NextKey222.PlayerIODataStructure:CreatePlayerIOPackage(playerName, false)
    
    -- Get current season dungeons and populate scores
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local dungeonCount = 0
    for _ in pairs(dungeons) do dungeonCount = dungeonCount + 1 end
    
    NextKey222.Debug:Dev("player_data", "Found", dungeonCount, "dungeons to check")
    
    local totalScoresFound = 0
    for dungeonID, _ in pairs(dungeons) do
        local score = 0
        
        -- Use direct methods to avoid recursion
        -- Try RaiderIO first, then UI methods, then WoW API
        if NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter.GetDungeonScore then
            score = NextKey222.RaiderIOAdapter:GetDungeonScore(dungeonID) or 0
        elseif NextKey222.UI and NextKey222.UI.GetRaiderIODungeonScore then
            score = NextKey222.UI:GetRaiderIODungeonScore(dungeonID) or 0
        elseif NextKey222.UI and NextKey222.UI.GetDungeonScore then
            score = NextKey222.UI:GetDungeonScore(dungeonID) or 0
        else
            -- Fallback to WoW API directly
            local mapID = NextKey222.Utils and NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID) or dungeonID
            local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
            if intimeInfo and intimeInfo.level then
                score = intimeInfo.level * 10 + (intimeInfo.level > 10 and (intimeInfo.level - 10) * 5 or 0)
            elseif overtimeInfo and overtimeInfo.level then
                score = overtimeInfo.level * 8
            end
        end
        
        -- Always add dungeon to cache, even with 0 score
        totalScoresFound = totalScoresFound + 1
        
        -- Get level and chest data if available
        local level, chests, isInTime = self:GetDungeonRunDetails(dungeonID)
        NextKey222.PlayerIODataStructure:AddDungeonScore(ioPackage, dungeonID, score, level, chests, isInTime)
    end
    
    NextKey222.Debug:Dev("player_data", "Added", totalScoresFound, "dungeon scores to package")
    NextKey222.Debug:Dev("player_data", "Final package totalIO:", ioPackage and ioPackage.totalIO or "nil")
    
    return ioPackage
end

--- Gets detailed run information for a dungeon
--- @param dungeonID number The dungeon ID
--- @return number level The best key level completed
--- @return number chests Number of chests earned (0-3)
--- @return boolean isInTime Whether the best run was completed in time
function PlayerDataService:GetDungeonRunDetails(dungeonID)
    -- Convert NextKey dungeon ID to Challenge Mode map ID
    local mapID = NextKey222.Utils and NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID) or dungeonID
    
    -- Use WoW API to get detailed run information
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    local bestLevel = 0
    local chests = 0
    local isInTime = false
    
    if intimeInfo and intimeInfo.level then
        bestLevel = intimeInfo.level
        isInTime = true
        
        -- Estimate chests based on completion time if available
        if intimeInfo.durationSec and intimeInfo.durationSec > 0 then
            local timeLimit = 1800 -- Default 30 minutes
            local completion = intimeInfo.durationSec / timeLimit
            
            if completion <= 0.6 then
                chests = 3 -- 3+ chests (40% time remaining)
            elseif completion <= 0.8 then
                chests = 2 -- 2 chests (20% time remaining)
            else
                chests = 1 -- 1 chest (barely in time)
            end
        else
            chests = 1 -- Default to 1 chest if in-time but no duration data
        end
    end
    
    if overtimeInfo and overtimeInfo.level and overtimeInfo.level > bestLevel then
        bestLevel = overtimeInfo.level
        chests = 0 -- Overtime = no chests
        isInTime = false
    end
    
    return bestLevel, chests, isInTime
end

--- Shares current player's IO data to the group
--- @return boolean True if sharing was successful
function PlayerDataService:SharePlayerIOData()
    NextKey222.Debug:Dev("player_data", "SharePlayerIOData called")
    
    local inGroup = IsInGroup()
    NextKey222.Debug:Dev("player_data", "IsInGroup():", inGroup)
    
    -- Create IO package for current player
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    NextKey222.Debug:Dev("player_data", "Creating package for", playerName)
    
    local ioPackage = self:CreateIOPackage(playerName)
    NextKey222.Debug:Dev("player_data", "Initial package created, totalIO:", ioPackage and ioPackage.totalIO or "nil")
    
    -- Always store our own data locally first
    if ioPackage then
        self.playerIOCache[playerName] = ioPackage
        NextKey222.Debug:Dev("player_data", "Stored current player IO data locally - Total IO:", ioPackage.totalIO)
        
        -- Announce event for UI updates
        self:AnnounceEvent("PLAYER_IO_UPDATED", {
            playerName = playerName,
            ioData = ioPackage,
            timestamp = GetTime()
        })
        
        -- Then try to share with group if we're in one
        if inGroup then
            -- Check throttling via Communications
            if NextKey222.Communications and NextKey222.Communications.CanSendMessage then
                if not NextKey222.Communications:CanSendMessage("PLAYER_IO") then
                    NextKey222.Debug:Dev("player_data", "Message throttled, skipping group share")
                    return true -- Still success since we cached locally
                end
            end
            
            local channel = IsInRaid() and "RAID" or "PARTY"
            local payload = {
                opcode = NextKey222.Constants.COMM_OPCODES.PLAYER_IO_UPDATE,
                version = NextKey.version or "1.0.0",
                timestamp = GetTime(),
                sender = playerName,
                ioData = ioPackage
            }
            
            local serialized = AceSerializer:Serialize(payload)
            NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
            NextKey222.Debug:Dev("player_data", "Shared IO data to", channel, "- Total IO:", ioPackage.totalIO)
        else
            NextKey222.Debug:Dev("player_data", "Not in group, stored IO data locally only")
        end
        
        return true
    else
        NextKey222.Debug:Dev("player_data", "Failed to create IO package")
        return false
    end
end

--- Ensures current player's IO data is generated and stored locally
--- This should be called when the addon loads or when UI needs current player data
--- @return boolean True if data is available (either already cached or newly generated)
function PlayerDataService:EnsureCurrentPlayerIOData()
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    
    -- Check if we already have recent data for current player
    local existingData = self.playerIOCache[playerName]
    if existingData and existingData.timestamp and (GetTime() - existingData.timestamp) < 300 then
        NextKey222.Debug:Dev("player_data", "Current player IO data is recent, skipping regeneration")
        return true
    end
    
    NextKey222.Debug:Dev("player_data", "Generating current player IO data...")
    
    -- Generate and store current player's IO data
    local success = self:SharePlayerIOData()
    
    if success then
        NextKey222.Debug:Dev("player_data", "Successfully generated current player IO data")
    else
        NextKey222.Debug:Dev("player_data", "Failed to generate current player IO data")
    end
    
    return success
end

-- MARK: Event Handling

--- Handles received IO data from other players
--- @param payload table Event payload with sender, data, timestamp
function PlayerDataService:OnIODataReceived(payload)
    NextKey222.Debug:Dev("player_data", "Received IO data from", payload.sender)
    
    if payload.data and payload.data.ioData then
        local ioPackage = payload.data.ioData
        
        -- Validate the IO package structure
        if NextKey222.PlayerIODataStructure:ValidatePackage(ioPackage) then
            -- Store the IO data in our cache
            self.playerIOCache[payload.sender] = ioPackage
            
            NextKey222.Debug:Dev("player_data", "Stored IO data for", payload.sender, "- Total IO:", ioPackage.totalIO)
            
            -- Announce event for UI updates
            self:AnnounceEvent("PLAYER_IO_UPDATED", {
                playerName = payload.sender,
                ioData = ioPackage,
                timestamp = GetTime()
            })
        else
            NextKey222.Debug:Dev("player_data", "Invalid IO data received from", payload.sender, "- skipping")
        end
    end
end

--- Handles requests for IO data from other players
--- @param payload table Event payload with sender
function PlayerDataService:OnIODataRequested(payload)
    NextKey222.Debug:Dev("player_data", "Received IO data request from", payload.sender)
    
    -- Respond by sharing our IO data
    self:SharePlayerIOData()
end

--- Announces an event via AceEvent system
--- @param eventName string The event name to announce
--- @param payload table The event payload
function PlayerDataService:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            NextKey222.Debug:Dev("player_data", "Cannot announce event - AceEvent not ready")
            return
        end
        
        NextKey222.Debug:Dev("player_data", string.format("Announcing event: %s", eventName))
        NextKey222.Addon:SendMessage(eventName, payload)
    end, "PlayerDataService:AnnounceEvent")
end

-- MARK: Cache Management

--- Cleans up old cache entries
function PlayerDataService:CleanupOldCacheEntries()
    local now = GetTime()
    local cleaned = 0
    
    for playerName, ioData in pairs(self.playerIOCache) do
        if ioData.timestamp and (now - ioData.timestamp) > self.cacheMaxAge then
            self.playerIOCache[playerName] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        NextKey222.Debug:Dev("player_data", "Cleaned", cleaned, "old cache entries")
        
        -- Announce cache cleanup event
        self:AnnounceEvent("PLAYER_IO_CACHE_CLEANED", {
            entriesCleaned = cleaned,
            timestamp = GetTime()
        })
    end
    
    self.lastCacheCleanup = now
end

--- Validates cached data structure integrity
function PlayerDataService:ValidateCachedData()
    local validated = 0
    local invalid = 0
    
    for playerName, ioData in pairs(self.playerIOCache) do
        if NextKey222.PlayerIODataStructure:ValidatePackage(ioData) then
            validated = validated + 1
        else
            self.playerIOCache[playerName] = nil
            invalid = invalid + 1
        end
    end
    
    if invalid > 0 then
        NextKey222.Debug:Dev("player_data", "Removed", invalid, "invalid cache entries, validated", validated)
    end
end

-- MARK: Module Initialization

function PlayerDataService:Initialize()
    NextKey222.Debug:Dev("startup", "PlayerDataService module initializing...")
    
    -- Initialize cache
    self.playerIOCache = {}
    self.lastCacheCleanup = GetTime()
    
    -- PHASE 4: Register event listeners for communication events
    NextKey222.SafeRun(function()
        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            -- Listen for received IO data (from Communications event announcements)
            NextKey222.Addon:RegisterMessage(NextKey222.Constants.COMM_EVENTS.PLAYER_IO_RECEIVED, function(event, payload)
                PlayerDataService:OnIODataReceived(payload)
            end)
            
            -- Listen for IO data requests (from Communications event announcements)
            NextKey222.Addon:RegisterMessage(NextKey222.Constants.COMM_EVENTS.PLAYER_IO_REQUEST, function(event, payload)
                PlayerDataService:OnIODataRequested(payload)
            end)
            
            NextKey222.Debug:Dev("startup", "PlayerDataService event listeners registered (Phase 4)")
        else
            NextKey222.Debug:Dev("startup", "[!] Cannot register event listeners - AceEvent not ready")
        end
    end, "PlayerDataService:Initialize:RegisterEvents")
    
    -- Auto-share IO data when scores are updated (if IOCalculator available)
    if NextKey222.IOCalculator then
        NextKey222.IOCalculator.OnScoresUpdated = function()
            PlayerDataService:SharePlayerIOData()
        end
    end
    
    NextKey222.Debug:Dev("startup", "PlayerDataService module initialized successfully")
    return true
end

return PlayerDataService