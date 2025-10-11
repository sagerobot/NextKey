-- MARK: Communications Module (Simplified - LibOpenRaid handles keystones)
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- Communications module for NextKey-specific data (preferences, settings, etc.)
local Communications = {
    throttleTimers = {},
    messageQueue = {},
    isProcessing = false,
    -- Storage for received IO data from other players
    playerIOCache = {}
}

NextKey222.Communications = Communications
NextKey222.RegisterModule("Communications", Communications)



-- MARK: Message Serialization
function Communications:SerializeSyncPayload(data)
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.SYNC,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        data = data
    }
    
    return AceSerializer:Serialize(payload)
end

function Communications:ParseSyncPayload(message)
    local success, payload = AceSerializer:Deserialize(message)
    if not success or not payload.opcode then
        return nil
    end
    return payload
end

-- MARK: Preference Sharing
function Communications:SharePreferences()
    if not IsInGroup() then
        NextKey222.Debug:Print("comms", "Not in group, cannot share preferences")
        return false
    end
    
    local preferences = NextKey.db and NextKey.db.char and NextKey.db.char.preferences
    if not preferences then
        NextKey222.Debug:Print("comms", "No preferences to share")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.PREFERENCE_UPDATE,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName,
        preferences = preferences
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
    NextKey222.Debug:Print("comms", "Shared preferences to", channel)
    return true
end

-- MARK: Player IO Data Sharing
function Communications:SharePlayerIOData()
    print("NextKey SHARE DEBUG: SharePlayerIOData called")
    
    local inGroup = IsInGroup()
    print("NextKey SHARE DEBUG: IsInGroup():", inGroup)
    
    -- We always want to cache the current player's IO data locally, even if not in a group
    -- Only skip if message is throttled AND we're trying to share (not just cache locally)
    if inGroup and not self:CanSendMessage("PLAYER_IO") then
        NextKey222.Debug:Print("comms", "Player IO message throttled")
        print("NextKey SHARE DEBUG: Message throttled, returning false")
        return false
    end
    
    -- Create standardized IO package for current player
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    print("NextKey SHARE DEBUG: Creating package for", playerName)
    local ioPackage = NextKey222.PlayerIODataStructure:CreatePlayerIOPackage(playerName, false)
    print("NextKey SHARE DEBUG: Initial package created, totalIO:", ioPackage and ioPackage.totalIO or "nil")
    
    -- Get current season dungeons and populate scores
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local dungeonCount = 0
    for _ in pairs(dungeons) do dungeonCount = dungeonCount + 1 end
    print("NextKey SHARE DEBUG: Found", dungeonCount, "dungeons to check")
    
    local totalScoresFound = 0
    for dungeonID, _ in pairs(dungeons) do
        local score = 0
        
        -- Use direct methods to avoid recursion (IOCalculator calls EnsureCurrentPlayerIOData)
        -- Try RaiderIO first, then UI methods, then WoW API
        if NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter.GetDungeonScore then
            score = NextKey222.RaiderIOAdapter:GetDungeonScore(dungeonID) or 0
            print("NextKey SHARE DEBUG: Dungeon", dungeonID, "RaiderIO returned:", score)
        elseif NextKey222.UI and NextKey222.UI.GetRaiderIODungeonScore then
            score = NextKey222.UI:GetRaiderIODungeonScore(dungeonID) or 0
            print("NextKey SHARE DEBUG: Dungeon", dungeonID, "UI RaiderIO returned:", score)
        elseif NextKey222.UI and NextKey222.UI.GetDungeonScore then
            score = NextKey222.UI:GetDungeonScore(dungeonID) or 0
            print("NextKey SHARE DEBUG: Dungeon", dungeonID, "UI GetDungeonScore returned:", score)
        else
            -- Fallback to WoW API directly
            local mapID = NextKey222.Utils and NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID) or dungeonID
            local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
            if intimeInfo and intimeInfo.level then
                score = intimeInfo.level * 10 + (intimeInfo.level > 10 and (intimeInfo.level - 10) * 5 or 0)
            elseif overtimeInfo and overtimeInfo.level then
                score = overtimeInfo.level * 8
            end
            print("NextKey SHARE DEBUG: Dungeon", dungeonID, "WoW API returned:", score)
        end
        
        -- Always add dungeon to cache, even with 0 score, to prevent fallback inconsistencies
        totalScoresFound = totalScoresFound + 1
        print("NextKey SHARE DEBUG: Adding score", score, "for dungeon", dungeonID, "(including 0 scores)")
        -- Get level and chest data if available
        local level, chests, isInTime = self:GetDungeonRunDetails(dungeonID)
        NextKey222.PlayerIODataStructure:AddDungeonScore(ioPackage, dungeonID, score, level, chests, isInTime)
    end
    
    print("NextKey SHARE DEBUG: Added", totalScoresFound, "dungeon scores to package")
    
    -- Always store our own data locally first
    print("NextKey SHARE DEBUG: Final package totalIO:", ioPackage and ioPackage.totalIO or "nil")
    -- Store data as long as package exists, even if totalIO is 0 (ensures consistent cache state)
    if ioPackage then
        self.playerIOCache[playerName] = ioPackage
        NextKey222.Debug:Print("comms", "Stored current player IO data locally - Total IO:", ioPackage.totalIO)
        print("NextKey SHARE DEBUG: Successfully stored IO data for", playerName, "with totalIO:", ioPackage.totalIO)
        
        -- Then try to share with group if we're in one
        if inGroup then
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
            NextKey222.Debug:Print("comms", "Shared IO data to", channel, "- Total IO:", ioPackage.totalIO)
            print("NextKey SHARE DEBUG: Shared to", channel, "with totalIO:", ioPackage.totalIO)
        else
            NextKey222.Debug:Print("comms", "Not in group, stored IO data locally only")
            print("NextKey SHARE DEBUG: Not in group, stored IO data locally only")
        end
        return true
    else
        NextKey222.Debug:Print("comms", "No meaningful IO data to share or store")
        print("NextKey SHARE DEBUG: FAILURE - totalIO is", ioPackage and ioPackage.totalIO or "nil", "returning false")
        return false
    end
end

--- Gets detailed run information for a dungeon
--- @param dungeonID number The dungeon ID
--- @return number level The best key level completed
--- @return number chests Number of chests earned (0-3)
--- @return boolean isInTime Whether the best run was completed in time
function Communications:GetDungeonRunDetails(dungeonID)
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
            -- This is a rough estimation - actual chest calculation would need dungeon timer data
            local timeLimit = 1800 -- Default 30 minutes, should get actual from dungeon data
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

-- MARK: IO Data Access Methods
--- Gets stored IO data for a specific player
--- @param playerName string Full player name with realm
--- @return table|nil The player's IO data package
function Communications:GetPlayerIOData(playerName)
    return self.playerIOCache[playerName]
end

--- Gets total IO score for a specific player from shared data
--- @param playerName string Full player name with realm  
--- @return number The player's total IO score (0 if not available)
function Communications:GetPlayerTotalIO(playerName)
    local ioData = self.playerIOCache[playerName]
    if ioData then
        return NextKey222.PlayerIODataStructure:GetTotalScore(ioData)
    end
    return 0
end

--- Gets dungeon-specific IO score for a player from shared data
--- @param playerName string Full player name with realm
--- @param dungeonID number The dungeon ID
--- @return number The IO score for this dungeon (0 if not available)
function Communications:GetPlayerDungeonScore(playerName, dungeonID)
    local ioData = self.playerIOCache[playerName]
    if ioData then
        return NextKey222.PlayerIODataStructure:GetDungeonScore(ioData, dungeonID)
    end
    return 0
end

--- Checks if we have IO data for a specific player
--- @param playerName string Full player name with realm
--- @return boolean Whether we have IO data for this player
function Communications:HasIODataForPlayer(playerName)
    return self.playerIOCache[playerName] ~= nil
end

--- Requests IO data from all party members
function Communications:RequestPartyIOData()
    if not IsInGroup() then
        NextKey222.Debug:Print("comms", "Not in group, cannot request IO data")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.REQUEST_PLAYER_IO,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = UnitName("player") .. "-" .. GetRealmName()
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
    NextKey222.Debug:Print("comms", "Requested IO data from", channel)
    return true
end

--- Ensures current player's IO data is generated and stored locally
--- This should be called when the addon loads or when UI needs current player data
function Communications:EnsureCurrentPlayerIOData()
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    
    -- Check if we already have recent data for current player
    local existingData = self.playerIOCache[playerName]
    if existingData and existingData.timestamp and (GetTime() - existingData.timestamp) < 300 then
        NextKey222.Debug:Print("comms", "Current player IO data is recent, skipping regeneration")
        return true
    end
    
    NextKey222.Debug:Print("comms", "Generating current player IO data...")
    
    -- Generate and store current player's IO data
    local success = self:SharePlayerIOData()
    
    if success then
        NextKey222.Debug:Print("comms", "Successfully generated current player IO data")
        
        -- Trigger UI refresh if available
        if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
            NextKey222.UI:OnPlayerIOUpdated(playerName, self.playerIOCache[playerName])
        end
    else
        NextKey222.Debug:Print("comms", "Failed to generate current player IO data")
    end
    
    return success
end

-- MARK: Dungeon Score Sharing (Legacy - maintained for compatibility)
function Communications:ShareDungeonScores()
    -- Delegate to new IO data sharing method
    return self:SharePlayerIOData()
end

-- MARK: Synchronization
function Communications:SendSync()
    if not IsInGroup() then
        NextKey222.Debug:Print("comms", "Not in group, cannot sync")
        return false
    end
    
    if not self:CanSendMessage("SYNC") then
        NextKey222.Debug:Print("comms", "Sync message throttled")
        return false
    end
    
    -- Use LibOpenRaid for keystone sharing since that's the primary data
    if NextKey222.LibOpenRaid then
        NextKey.SafeRun(NextKey222.LibOpenRaid.RequestKeystoneDataFromParty, "Request keystone data from party")
    end
    
    -- Share our preferences and dungeon scores
    self:SharePreferences()
    self:ShareDungeonScores()
    
    NextKey222.Debug:Print("comms", "Sync requested")
    return true
end

-- MARK: Message Processing
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if prefix ~= NextKey222.Constants.COMM_PREFIX then
        return
    end
    
    if sender == NextKey.playerFullName then
        return
    end
    
    local payload = self:ParseSyncPayload(message)
    if not payload then
        NextKey222.Debug:Print("comms", "Failed to parse message from", sender)
        return
    end
    
    -- Process dungeon scores from other players
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.DUNGEON_SCORES then
        if NextKey222.IOCalculator and payload.dungeonScores then
            NextKey222.IOCalculator:ReceivePlayerDungeonScores(payload.sender, payload.dungeonScores)
        end
        return
    end
    
    -- Handle different message types
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.SYNC then
        self:ProcessSync(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.PREFERENCE_UPDATE then
        self:ProcessPreferenceUpdate(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.DUNGEON_SCORES then
        self:ProcessDungeonScores(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.PLAYER_IO_UPDATE then
        self:ProcessPlayerIOUpdate(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.REQUEST_PLAYER_IO then
        self:ProcessPlayerIORequest(payload, sender)
    elseif payload.opcode == "KEYSTONE_REQUEST" then
        self:ProcessKeystoneRequest(payload, sender)
    elseif payload.opcode == "KEYSTONE_SHARE" then
        self:ProcessKeystoneShare(payload, sender)
    else
        NextKey222.Debug:Print("comms", "Unknown opcode:", payload.opcode, "from", sender)
    end
end

function Communications:ProcessSync(payload, sender)
    NextKey222.Debug:Print("comms", "Received sync from", sender)
    -- Handle general sync data if needed
end

function Communications:ProcessPreferenceUpdate(payload, sender)
    NextKey222.Debug:Print("comms", "Received preference update from", sender)
    
    if payload.preferences then
        -- Store or process received preferences if needed
        -- This could be used for group-wide preference sharing/voting
        NextKey222.Debug:Print("comms", "Preferences received from", sender, "- count:", self:CountTable(payload.preferences))
    end
end

-- MARK: IO Data Message Handlers
function Communications:ProcessPlayerIOUpdate(payload, sender)
    NextKey222.Debug:Print("comms", "Received IO data from", sender)
    
    if payload.ioData then
        local ioPackage = payload.ioData
        
        -- Validate the IO package structure
        if NextKey222.PlayerIODataStructure:ValidatePackage(ioPackage) then
            -- Store the IO data in our cache
            self.playerIOCache[sender] = ioPackage
            
            NextKey222.Debug:Print("comms", "Stored IO data for", sender, "- Total IO:", ioPackage.totalIO)
            NextKey222.Debug:Print("comms", "Dungeon count:", self:CountTable(ioPackage.dungeonScores or {}))
            
            -- Notify UI that we have new IO data (for potential refresh)
            if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
                NextKey222.UI:OnPlayerIOUpdated(sender, ioPackage)
            end
        else
            NextKey222.Debug:Print("comms", "Invalid IO data received from", sender, "- skipping")
        end
    end
end

function Communications:ProcessPlayerIORequest(payload, sender)
    NextKey222.Debug:Print("comms", "Received IO data request from", sender)
    
    -- Respond by sharing our IO data
    self:SharePlayerIOData()
end

function Communications:ProcessDungeonScores(payload, sender)
    NextKey222.Debug:Print("comms", "Received legacy dungeon scores from", sender)
    
    if payload.dungeonScores then
        -- Initialize party scores storage if needed
        if not self.partyDungeonScores then
            self.partyDungeonScores = {}
        end
        
        -- Store the scores for this player
        self.partyDungeonScores[sender] = {
            scores = payload.dungeonScores,
            timestamp = payload.timestamp or 0,
            version = payload.version
        }
        
        local scoreCount = self:CountTable(payload.dungeonScores)
        NextKey222.Debug:Print("comms", "Stored", scoreCount, "legacy dungeon scores for", sender)
        
        -- Notify UI that we have new score data (for potential refresh)
        if NextKey222.UI and NextKey222.UI.OnPartyScoresUpdated then
            NextKey222.UI:OnPartyScoresUpdated(sender, payload.dungeonScores)
        end
    end
end

-- MARK: Score Access Functions
function Communications:GetPartyMemberDungeonScore(playerName, dungeonID)
    if not self.partyDungeonScores or not self.partyDungeonScores[playerName] then
        return 0
    end
    
    local scores = self.partyDungeonScores[playerName].scores
    if scores and scores[dungeonID] then
        return scores[dungeonID].score or 0
    end
    
    return 0
end

function Communications:GetPartyMemberScores(playerName)
    if not self.partyDungeonScores or not self.partyDungeonScores[playerName] then
        return {}
    end
    
    return self.partyDungeonScores[playerName].scores or {}
end

function Communications:HasScoresForPlayer(playerName)
    return self.partyDungeonScores and 
           self.partyDungeonScores[playerName] and 
           self.partyDungeonScores[playerName].scores and
           next(self.partyDungeonScores[playerName].scores) ~= nil
end

-- MARK: Utility Functions
function Communications:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- MARK: NextKey222 Module Interface
function Communications:Initialize()
    NextKey222.Debug:Print("startup", "Communications module initializing...")
    
    -- Register communication prefix with AceComm
    local nextkey = NextKey222.Addon
    if nextkey and nextkey.RegisterComm then
        NextKey222.SafeRun(function()
            nextkey:RegisterComm(NextKey222.Constants.COMM_PREFIX, function(prefix, message, distribution, sender)
                Communications:ProcessMessage(prefix, message, distribution, sender)
            end)
            NextKey222.Debug:Print("startup", "Registered comm prefix:", NextKey222.Constants.COMM_PREFIX)
        end, "Communications:Initialize:RegisterComm")
    else
        NextKey222.Debug:Print("startup", "⚠️  Cannot register comm prefix - NextKey addon not ready")
    end
    
    -- Initialize storage
    self.throttleTimers = {}
    self.partyDungeonScores = {}
    self.playerIOCache = {}  -- New IO data cache
    
    -- Auto-share IO data when joining groups or when scores change
    if NextKey222.IOCalculator then
        -- Share IO data when current player's scores are updated
        NextKey222.IOCalculator.OnScoresUpdated = function()
            self:SharePlayerIOData()
        end
    end
    
    -- Note: Current player IO data will be generated on-demand to avoid initialization recursion
    -- EnsureCurrentPlayerIOData() is called when actually needed by IOCalculator
    
    NextKey222.Debug:Print("startup", "Communications module initialized successfully with IO data sharing")
    return true
end

-- MARK: Throttling
function Communications:CanSendMessage(messageType)
    local now = GetTime()
    local lastSent = self.throttleTimers[messageType] or 0
    local throttleSettings = NextKey222.Constants.COMM_SETTINGS
    local throttleInterval = throttleSettings and throttleSettings.THROTTLE_INTERVAL or 5
    
    if now - lastSent < throttleInterval then
        NextKey222.Debug:Print("comms", "Message throttled:", messageType, "- wait", throttleInterval - (now - lastSent), "seconds")
        return false
    end
    
    self.throttleTimers[messageType] = now
    return true
end

-- MARK: Guild Keystone Communication
function Communications:ProcessKeystoneRequest(payload, sender)
    print("NextKey GUILD COMM: Received keystone request from", sender)
    
    -- Share our keystone if we have one
    local playerKeystone = NextKey222.Keystones and NextKey222.Keystones:ScanPlayerKeystone()
    if playerKeystone and playerKeystone.dungeonID and playerKeystone.level then
        print("NextKey GUILD COMM: Responding with keystone Level", playerKeystone.level, "dungeon", playerKeystone.dungeonID)
        self:ShareKeystone(playerKeystone)
    else
        print("NextKey GUILD COMM: No keystone to share")
    end
end

function Communications:ProcessKeystoneShare(payload, sender)
    if not payload.keystoneData then return end
    
    local keyData = payload.keystoneData
    print("NextKey GUILD COMM: Received keystone from", sender, "- Level", keyData.level, "dungeon", keyData.dungeonID)
    
    -- Store the keystone data
    if NextKey222.Keystones and NextKey222.Keystones.StoreGuildKeystone then
        NextKey222.Keystones:StoreGuildKeystone(sender, keyData.dungeonID, keyData.level, "guild-comm")
    end
end

function Communications:ShareKeystone(keystoneData)
    if not IsInGuild() or not keystoneData then return false end
    
    local payload = {
        opcode = "KEYSTONE_SHARE",
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName or UnitName("player") .. "-" .. GetRealmName(),
        keystoneData = {
            dungeonID = keystoneData.dungeonID,
            level = keystoneData.level,
            source = "nextkey"
        }
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, "GUILD")
    
    print("NextKey GUILD COMM: Shared keystone Level", keystoneData.level, "to guild")
    return true
end

function Communications:SendGuildMessage(opcode, data)
    if not IsInGuild() then return false end
    
    local payload = {
        opcode = opcode,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName or UnitName("player") .. "-" .. GetRealmName(),
        data = data
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, "GUILD")
    
    return true
end

function Communications:RequestGuildKeystones()
    if not IsInGuild() then
        print("NextKey GUILD: Not in guild, cannot request keystones")
        return false
    end
    
    print("NextKey GUILD COMM: Requesting keystones from guild members...")
    
    local payload = {
        opcode = "KEYSTONE_REQUEST",
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName or UnitName("player") .. "-" .. GetRealmName(),
        data = { reason = "guild-scan" }
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, "GUILD")
    
    -- Also share our own keystone immediately
    local playerKeystone = NextKey222.Keystones and NextKey222.Keystones:ScanPlayerKeystone()
    if playerKeystone and playerKeystone.dungeonID and playerKeystone.level then
        self:ShareKeystone(playerKeystone)
    end
    
    return true
end

return Communications