-- MARK: Communications Module
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- Communications module for NextKey-specific data (preferences, settings, etc.)
-- PHASE 4: Transitioning to pure message router pattern
-- Business logic being extracted to domain modules (PlayerDataService, etc.)
local Communications = {
    throttleTimers = {},
    messageQueue = {},
    isProcessing = false,
    -- Storage for received IO data from other players (LEGACY - being moved to PlayerDataService)
    playerIOCache = {},
    
    -- PHASE 3: Communication Batching System
    batchQueue = {},
    batchTimer = nil,
    batchInterval = 2.0, -- Process batches every 2 seconds
    maxBatchSize = 5, -- Maximum messages per batch
    
    -- PHASE 3: Expensive Operation Throttling
    expensiveOpTimer = nil,
    expensiveOpInterval = 3.0, -- Expensive ops every 3 seconds
    lastExpensiveOp = 0,
    
    -- PHASE 3: Frame Pacing
    lastFrameTime = 0,
    frameBudget = 16, -- 16ms budget for 60 FPS
    workQueue = {}
}

NextKey222.Communications = Communications
NextKey222.RegisterModule("Communications", Communications)

-- MARK: Event Announcement
--- Announces communication events via AceEvent system
--- @param eventName string The event name from COMM_EVENTS
--- @param payload table The event payload data
function Communications:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            NextKey222.Debug:Dev("comms", "Cannot announce event - AceEvent not ready:", eventName)
            return
        end
        
        NextKey222.Debug:Dev("comms", "Announcing event:", eventName)
        NextKey222.Addon:SendMessage(eventName, payload)
    end, "Communications:AnnounceEvent")
end

-- MARK: Teleport Broadcast
-- Broadcasts the currently selected teleport key from the leader so all clients
-- can align their teleport window with the leader's choice.
-- Single-source-of-truth: all flows MUST call NextKey:SetTeleportTargetKey(key, { broadcast = true })
-- from the leader; this helper only serializes and sends the message.
function Communications:BroadcastTeleportSelection(key)
    -- Validate keystone data
    if not key or not key.dungeonID or not key.level then
        NextKey222.Debug:Dev("teleport", "BroadcastTeleportSelection: invalid key payload")
        return
    end

    -- Only group leader (or solo, for testing) may broadcast selection
    if not NextKey or not NextKey.IsLeaderOrSolo or not NextKey:IsLeaderOrSolo() then
        NextKey222.Debug:Dev("teleport", "BroadcastTeleportSelection: caller is not leader/solo - blocked")
        return
    end

    -- Require an actual group context for network broadcast
    if not IsInGroup() and not IsInRaid() then
        NextKey222.Debug:Dev("teleport", "BroadcastTeleportSelection: not in group/raid - no broadcast")
        return
    end

    -- Lightweight Details-style usage of existing prefix (no extra throttling needed)
    local channel = IsInRaid() and "RAID" or "PARTY"

    local payload = {
        opcode = "TELEPORT_SELECT",
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName or (UnitName("player") .. "-" .. GetRealmName()),
        key = {
            dungeonID = key.dungeonID,
            level = key.level,
            ownerName = key.ownerName,
            ownerShort = key.ownerShort,
            class = key.class,
            io = key.io,
            source = key.source or "leader_select",
        }
    }

    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)

    NextKey222.Debug:Dev("teleport",
        string.format("BroadcastTeleportSelection → %s (dungeonID=%s, level=%s)",
            channel, tostring(key.dungeonID), tostring(key.level)))
end



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
        NextKey222.Debug:Dev("comms", "Not in group, cannot share preferences")
        return false
    end
    
    local preferences = NextKey.db and NextKey.db.char and NextKey.db.char.preferences
    if not preferences then
        NextKey222.Debug:Dev("comms", "No preferences to share")
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
    NextKey222.Debug:Dev("comms", "Shared preferences to", channel)
    return true
end

-- MARK: Player IO Data Sharing
function Communications:SharePlayerIOData()
    -- PHASE 3: Check if this should be batched for performance
    if self:ShouldBatchOperation("PLAYER_IO") then
        self:QueueBatchOperation("PLAYER_IO", {})
        return true -- Pretend success for batching
    end
    
    print("NextKey SHARE DEBUG: SharePlayerIOData called")
    
    local inGroup = IsInGroup()
    print("NextKey SHARE DEBUG: IsInGroup():", inGroup)
    
    -- We always want to cache the current player's IO data locally, even if not in a group
    -- Only skip if message is throttled AND we're trying to share (not just cache locally)
    if inGroup and not self:CanSendMessage("PLAYER_IO") then
        NextKey222.Debug:Dev("comms", "Player IO message throttled")
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
            local mapID = NextKey222.DungeonUtils and NextKey222.DungeonUtils:ConvertToRaiderIOKeystoneID(dungeonID) or dungeonID
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
        NextKey222.Debug:Dev("comms", "Stored current player IO data locally - Total IO:", ioPackage.totalIO)
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
            NextKey222.Debug:Dev("comms", "Shared IO data to", channel, "- Total IO:", ioPackage.totalIO)
            print("NextKey SHARE DEBUG: Shared to", channel, "with totalIO:", ioPackage.totalIO)
        else
            NextKey222.Debug:Dev("comms", "Not in group, stored IO data locally only")
            print("NextKey SHARE DEBUG: Not in group, stored IO data locally only")
        end
        return true
    else
        NextKey222.Debug:Dev("comms", "No meaningful IO data to share or store")
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
    local mapID = NextKey222.DungeonUtils and NextKey222.DungeonUtils:ConvertToRaiderIOKeystoneID(dungeonID) or dungeonID
    
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

-- MARK: IO Data Access
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
        NextKey222.Debug:Dev("comms", "Not in group, cannot request IO data")
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
    NextKey222.Debug:Dev("comms", "Requested IO data from", channel)
    return true
end

--- Ensures current player's IO data is generated and stored locally
--- This should be called when the addon loads or when UI needs current player data
function Communications:EnsureCurrentPlayerIOData()
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    
    -- Check if we already have recent data for current player
    local existingData = self.playerIOCache[playerName]
    if existingData and existingData.timestamp and (GetTime() - existingData.timestamp) < 300 then
        NextKey222.Debug:Dev("comms", "Current player IO data is recent, skipping regeneration")
        return true
    end
    
    NextKey222.Debug:Dev("comms", "Generating current player IO data...")
    
    -- Generate and store current player's IO data
    local success = self:SharePlayerIOData()
    
    if success then
        NextKey222.Debug:Dev("comms", "Successfully generated current player IO data")
        
        -- Trigger UI refresh if available
        if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
            NextKey222.UI:OnPlayerIOUpdated(playerName, self.playerIOCache[playerName])
        end
    else
        NextKey222.Debug:Dev("comms", "Failed to generate current player IO data")
    end
    
    return success
end

-- MARK: Dungeon Score Sharing
function Communications:ShareDungeonScores()
    -- Delegate to new IO data sharing method
    return self:SharePlayerIOData()
end

-- MARK: Synchronization
function Communications:SendSync()
    if not IsInGroup() then
        NextKey222.Debug:Dev("comms", "Not in group, cannot sync")
        return false
    end
    
    if not self:CanSendMessage("SYNC") then
        NextKey222.Debug:Dev("comms", "Sync message throttled")
        return false
    end
    
    -- PERFORMANCE FIX: Prevent nil self error
    if not NextKey222.LibOpenRaid then
        NextKey222.Debug:Dev("comms", "LibOpenRaid not available")
        return false
    end
    
    -- Use LibOpenRaid for keystone sharing since that's the primary data
    NextKey.SafeRun(NextKey222.LibOpenRaid.RequestKeystoneDataFromParty, "Request keystone data from party")
    
    -- Share our preferences and dungeon scores
    self:SharePreferences()
    self:ShareDungeonScores()
    
    NextKey222.Debug:Dev("comms", "Sync requested")
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
        NextKey222.Debug:Dev("comms", "Failed to parse message from", sender)
        return
    end
    
    -- PHASE 4: Announce raw message event for all opcodes
    -- This allows modules to listen for specific message types
    local eventName = self:GetEventNameForOpcode(payload.opcode)
    if eventName then
        self:AnnounceEvent(eventName, {
            opcode = payload.opcode,
            sender = sender,
            distribution = distribution,
            payload = payload,
            timestamp = GetTime()
        })
    end

    -- Handle leader-selected teleport sync (TELEPORT_SELECT)
    if payload.opcode == "TELEPORT_SELECT" and type(payload.key) == "table" then
        local my_name = NextKey.playerFullName or (UnitName("player") .. "-" .. GetRealmName())

        -- Ignore echoes of our own broadcast
        if sender == my_name then
            return
        end

        -- Defensive validation of received key payload
        local k = payload.key
        if not k.dungeonID or not k.level then
            NextKey222.Debug:Dev("teleport", "TELEPORT_SELECT: invalid key from", sender)
            return
        end

        NextKey222.Debug:Dev("teleport", "Received TELEPORT_SELECT from", sender,
            "dungeonID=", k.dungeonID, "level=", k.level)

        -- Apply remote selection using the single-source API without rebroadcast
        if NextKey and NextKey.SetTeleportTargetKey then
            NextKey:SetTeleportTargetKey(k, {
                source = "remote_select",
                broadcast = false,
                receivedFrom = sender
            })
        end

        -- Ensure teleport UI reflects the synced selection:
        -- - If window is not visible, open it to show the chosen key
        -- - If already visible, the teleport module's Refresh logic will display updated data
        if NextKey and NextKey.ToggleTeleportWindow then
            local window = NextKey.teleportWindow and NextKey.teleportWindow.frame
            if not window or not window:IsShown() then
                NextKey:ToggleTeleportWindow()
            end
        end

        return
    end

    -- Process dungeon scores from other players (legacy path)
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.DUNGEON_SCORES then
        if NextKey222.IOCalculator and payload.dungeonScores then
            NextKey222.IOCalculator:ReceivePlayerDungeonScores(payload.sender, payload.dungeonScores)
        end
        return
    end

    -- PHASE 4: Route messages to appropriate handlers
    -- Legacy direct processing maintained for backward compatibility during migration
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.SYNC then
        self:ProcessSync(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.PREFERENCE_UPDATE then
        self:ProcessPreferenceUpdate(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.DUNGEON_SCORES then
        self:ProcessDungeonScores(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.PLAYER_IO_UPDATE then
        -- PHASE 4: Legacy handler maintained for backward compatibility
        self:ProcessPlayerIOUpdate(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.REQUEST_PLAYER_IO then
        -- PHASE 4: Legacy handler maintained for backward compatibility
        self:ProcessPlayerIORequest(payload, sender)
    elseif payload.opcode == "KEYSTONE_REQUEST" then
        self:ProcessKeystoneRequest(payload, sender)
    elseif payload.opcode == "KEYSTONE_SHARE" then
        self:ProcessKeystoneShare(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.ORG_POLL_REQUEST then
        self:ProcessOrganizerPollRequest(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.ORG_POLL_RESPONSE then
        self:ProcessOrganizerPollResponse(payload, sender)
    elseif payload.opcode == "ORG_ADDON_PING" then
        self:ProcessAddonPing(payload, sender)
    elseif payload.opcode == "ORG_ADDON_PONG" then
        self:ProcessAddonPong(payload, sender)
    else
        NextKey222.Debug:Dev("comms", "Unknown opcode:", payload.opcode, "from", sender)
    end
end

-- MARK: Opcode to Event Map
--- Maps communication opcodes to event names
--- @param opcode string The communication opcode
--- @return string|nil The event name or nil if no mapping exists
function Communications:GetEventNameForOpcode(opcode)
    -- Map opcodes to COMM_EVENTS constants
    local mapping = {
        [NextKey222.Constants.COMM_OPCODES.PLAYER_IO_UPDATE] = NextKey222.Constants.COMM_EVENTS.PLAYER_IO_RECEIVED,
        [NextKey222.Constants.COMM_OPCODES.REQUEST_PLAYER_IO] = NextKey222.Constants.COMM_EVENTS.PLAYER_IO_REQUEST,
        ["KEYSTONE_SHARE"] = NextKey222.Constants.COMM_EVENTS.KEYSTONE_RECEIVED,
        ["KEYSTONE_REQUEST"] = NextKey222.Constants.COMM_EVENTS.KEYSTONE_REQUEST,
        ["TELEPORT_SELECT"] = NextKey222.Constants.COMM_EVENTS.TELEPORT_SELECT,
        [NextKey222.Constants.COMM_OPCODES.ORG_POLL_REQUEST] = NextKey222.Constants.COMM_EVENTS.ORG_POLL_REQUEST,
        [NextKey222.Constants.COMM_OPCODES.ORG_POLL_RESPONSE] = NextKey222.Constants.COMM_EVENTS.ORG_POLL_RESPONSE,
        ["ORG_ADDON_PING"] = NextKey222.Constants.COMM_EVENTS.ORG_ADDON_PING,
        ["ORG_ADDON_PONG"] = NextKey222.Constants.COMM_EVENTS.ORG_ADDON_PONG,
        [NextKey222.Constants.COMM_OPCODES.PREFERENCE_UPDATE] = NextKey222.Constants.COMM_EVENTS.PREFERENCE_UPDATE,
        [NextKey222.Constants.COMM_OPCODES.DUNGEON_SCORES] = NextKey222.Constants.COMM_EVENTS.DUNGEON_SCORES,
        [NextKey222.Constants.COMM_OPCODES.SYNC] = NextKey222.Constants.COMM_EVENTS.SYNC,
    }
    
    return mapping[opcode]
end

function Communications:ProcessSync(payload, sender)
    NextKey222.Debug:Dev("comms", "Received sync from", sender)
    -- Handle general sync data if needed
end

function Communications:ProcessPreferenceUpdate(payload, sender)
    NextKey222.Debug:Dev("comms", "Received preference update from", sender)
    
    if payload.preferences then
        -- Store or process received preferences if needed
        -- This could be used for group-wide preference sharing/voting
        NextKey222.Debug:Dev("comms", "Preferences received from", sender, "- count:", self:CountTable(payload.preferences))
    end
end

-- MARK: IO Data Handlers
function Communications:ProcessPlayerIOUpdate(payload, sender)
    NextKey222.Debug:Dev("comms", "Received IO data from", sender)
    
    if payload.ioData then
        local ioPackage = payload.ioData
        
        -- Validate the IO package structure
        if NextKey222.PlayerIODataStructure:ValidatePackage(ioPackage) then
            -- Store the IO data in our cache
            self.playerIOCache[sender] = ioPackage
            
            NextKey222.Debug:Dev("comms", "Stored IO data for", sender, "- Total IO:", ioPackage.totalIO)
            NextKey222.Debug:Dev("comms", "Dungeon count:", self:CountTable(ioPackage.dungeonScores or {}))
            
            -- Notify UI that we have new IO data (for potential refresh)
            if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
                NextKey222.UI:OnPlayerIOUpdated(sender, ioPackage)
            end
        else
            NextKey222.Debug:Dev("comms", "Invalid IO data received from", sender, "- skipping")
        end
    end
end

function Communications:ProcessPlayerIORequest(payload, sender)
    NextKey222.Debug:Dev("comms", "Received IO data request from", sender)
    
    -- Respond by sharing our IO data
    self:SharePlayerIOData()
end

function Communications:ProcessDungeonScores(payload, sender)
    NextKey222.Debug:Dev("comms", "Received legacy dungeon scores from", sender)
    
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
        NextKey222.Debug:Dev("comms", "Stored", scoreCount, "legacy dungeon scores for", sender)
        
        -- Notify UI that we have new score data (for potential refresh)
        if NextKey222.UI and NextKey222.UI.OnPartyScoresUpdated then
            NextKey222.UI:OnPartyScoresUpdated(sender, payload.dungeonScores)
        end
    end
end

-- MARK: Score Access
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

-- MARK: Module Interface
function Communications:Initialize()
    NextKey222.Debug:Dev("startup", "Communications module initializing...")
    
    -- Register communication prefix with AceComm
    local nextkey = NextKey222.Addon
    if nextkey and nextkey.RegisterComm then
        NextKey222.SafeRun(function()
            nextkey:RegisterComm(NextKey222.Constants.COMM_PREFIX, function(prefix, message, distribution, sender)
                Communications:ProcessMessage(prefix, message, distribution, sender)
            end)
            NextKey222.Debug:Dev("startup", "Registered comm prefix:", NextKey222.Constants.COMM_PREFIX)
        end, "Communications:Initialize:RegisterComm")
    else
        NextKey222.Debug:Dev("startup", "[!] Cannot register comm prefix - NextKey addon not ready")
    end
    
    -- PHASE 4: Register event listeners for backward compatibility
    -- These allow Communications to respond to events from new domain modules
    self:RegisterEventListeners()
    
    -- Initialize storage
    self.throttleTimers = {}
    self.partyDungeonScores = {}
    self.playerIOCache = {}  -- LEGACY: Being migrated to PlayerDataService
    
    -- PHASE 3: Initialize batching system
    self.batchQueue = {}
    self.workQueue = {}
    self.lastFrameTime = 0
    
    -- Start batch processing timer
    self.batchTimer = C_Timer.NewTicker(self.batchInterval, function()
        self:ProcessBatchQueue()
    end)
    
    -- Start expensive operations timer
    self.expensiveOpTimer = C_Timer.NewTicker(self.expensiveOpInterval, function()
        self:ProcessExpensiveOperations()
    end)
    
    -- Auto-share IO data when joining groups or when scores change
    if NextKey222.IOCalculator then
        -- Share IO data when current player's scores are updated
        NextKey222.IOCalculator.OnScoresUpdated = function()
            self:SharePlayerIOData()
        end
    end
    
    -- Note: Current player IO data will be generated on-demand to avoid initialization recursion
    -- EnsureCurrentPlayerIOData() is called when actually needed by IOCalculator
    
    NextKey222.Debug:Dev("startup", "Communications module initialized successfully with event-driven architecture (Phase 4)")
    return true
end

-- MARK: Event Listener Reg
--- Registers event listeners for communication events
--- This allows Communications to maintain backward compatibility during migration
function Communications:RegisterEventListeners()
    if not NextKey222.Addon or not NextKey222.Addon.RegisterMessage then
        NextKey222.Debug:Error("Cannot register event listeners - AceEvent not ready")
        return false
    end
    
    NextKey222.SafeRun(function()
        -- Listen for PLAYER_IO_RECEIVED events (from PlayerDataService)
        -- This maintains UI refresh compatibility during migration
        NextKey222.Addon:RegisterMessage(NextKey222.Constants.COMM_EVENTS.PLAYER_IO_RECEIVED, function(event, payload)
            Communications:OnPlayerIOReceived(payload)
        end)
        
        NextKey222.Debug:Dev("comms", "Event listeners registered for Phase 4 migration")
    end, "Communications:RegisterEventListeners")
    
    return true
end

-- MARK: Event Handlers
--- Handles PLAYER_IO_RECEIVED events
--- Maintains backward compatibility by triggering UI refresh
function Communications:OnPlayerIOReceived(payload)
    NextKey222.SafeRun(function()
        if not payload or not payload.sender or not payload.payload then
            return
        end
        
        local sender = payload.sender
        local ioData = payload.payload.ioData
        
        NextKey222.Debug:Dev("comms", "Event handler: PLAYER_IO_RECEIVED from", sender)
        
        -- Trigger UI refresh if available (legacy compatibility)
        if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
            NextKey222.UI:OnPlayerIOUpdated(sender, ioData)
        end
    end, "Communications:OnPlayerIOReceived")
end

-- MARK: Communication Batching
function Communications:ShouldBatchOperation(operationType)
    -- PHASE 3: Batch expensive operations in large groups (considering online players only)
    local groupSize = GetNumGroupMembers() or 1
    local effectiveSize = groupSize
    
    -- Check for significant offline presence and use online count
    if NextKey222.Events and NextKey222.Events.HasSignificantOfflinePlayers then
        if NextKey222.Events:HasSignificantOfflinePlayers() then
            effectiveSize = NextKey222.Events:GetOnlineGroupMembers()
            NextKey222.Debug:Dev("comms", string.format("Batching decision optimized: %d total, %d online, using %d effective size",
                groupSize, NextKey222.Events:GetOnlineGroupMembers(), effectiveSize))
        end
    end
    
    return effectiveSize >= 10 and (operationType == "PLAYER_IO" or operationType == "SYNC")
end

function Communications:QueueBatchOperation(operationType, data)
    table.insert(self.batchQueue, {
        type = operationType,
        data = data,
        timestamp = GetTime()
    })
    
    NextKey222.Debug:Dev("comms", "Queued batch operation:", operationType, "Queue size:", #self.batchQueue)
end

function Communications:ProcessBatchQueue()
    if #self.batchQueue == 0 then
        return
    end
    
    NextKey222.Debug:Dev("comms", "Processing batch queue with", #self.batchQueue, "operations")
    
    -- Process up to maxBatchSize operations
    local processed = 0
    local operationsToRemove = {}
    
    for i = 1, math.min(#self.batchQueue, self.maxBatchSize) do
        local operation = self.batchQueue[i]
        
        -- Execute the operation
        if operation.type == "PLAYER_IO" then
            self:_ExecuteSharePlayerIOData()
        elseif operation.type == "SYNC" then
            self:_ExecuteSync()
        end
        
        table.insert(operationsToRemove, i)
        processed = processed + 1
    end
    
    -- Remove processed operations (in reverse order to maintain indices)
    for i = #operationsToRemove, 1, -1 do
        table.remove(self.batchQueue, operationsToRemove[i])
    end
    
    NextKey222.Debug:Dev("comms", "Processed", processed, "batch operations")
end

function Communications:_ExecuteSharePlayerIOData()
    -- Execute the actual sharing logic without batching checks
    local inGroup = IsInGroup()
    if not inGroup or not self:CanSendMessage("PLAYER_IO") then
        return false
    end
    
    -- Execute the original SharePlayerIOData logic (simplified)
    local playerName = UnitName("player") .. "-" .. GetRealmName()
    local ioPackage = NextKey222.PlayerIODataStructure:CreatePlayerIOPackage(playerName, false)
    
    if ioPackage then
        self.playerIOCache[playerName] = ioPackage
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
        return true
    end
    
    return false
end

function Communications:_ExecuteSync()
    -- Execute the actual sync logic without batching checks
    if not IsInGroup() or not self:CanSendMessage("SYNC") then
        return false
    end
    
    -- Use LibOpenRaid for keystone sharing
    if NextKey222.LibOpenRaid then
        NextKey.SafeRun(NextKey222.LibOpenRaid.RequestKeystoneDataFromParty, "Request keystone data from party")
    end
    
    -- Share preferences and dungeon scores
    self:SharePreferences()
    self:_ExecuteSharePlayerIOData()
    
    return true
end

-- MARK: Operations Throttling
function Communications:ProcessExpensiveOperations()
    local now = GetTime()
    if now - self.lastExpensiveOp < self.expensiveOpInterval then
        return
    end
    
    self.lastExpensiveOp = now
    
    -- Process expensive operations that don't need to run every frame
    -- This includes cache cleanup, data validation, etc.
    
    -- Clean up old cache entries
    self:CleanupOldCacheEntries()
    
    -- Log cache cleanup statistics if any work was done
    local cacheCount = 0
    for _ in pairs(self.playerIOCache) do
        cacheCount = cacheCount + 1
    end
    
    NextKey222.Debug:Dev("comms", string.format(
        "Cache maintenance completed - %d entries cached, %d cleaned",
        cacheCount,
        cleaned or 0
    ))
end

function Communications:CleanupOldCacheEntries()
    local now = GetTime()
    local maxAge = 600 -- 10 minutes
    local cleaned = 0
    
    for playerName, ioData in pairs(self.playerIOCache) do
        if ioData.timestamp and (now - ioData.timestamp) > maxAge then
            self.playerIOCache[playerName] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        NextKey222.Debug:Dev("comms", "Cleaned", cleaned, "old cache entries")
    end
end

-- MARK: Frame Pacing System
function Communications:UpdateFramePacing()
    local now = GetTime()
    local frameDelta = now - self.lastFrameTime
    
    -- Only process work if we have frame budget available
    if frameDelta < (self.frameBudget / 1000) then
        return false -- Not enough time in this frame
    end
    
    self.lastFrameTime = now
    
    -- Process queued work within frame budget
    local workStartTime = GetTime()
    local processed = 0
    
    while #self.workQueue > 0 and (GetTime() - workStartTime) < (self.frameBudget / 1000) do
        local work = table.remove(self.workQueue, 1)
        self:ExecuteWorkItem(work)
        processed = processed + 1
    end
    
    if processed > 0 then
        NextKey222.Debug:Dev("comms", "Processed", processed, "work items in frame")
    end
    
    return processed > 0
end

function Communications:QueueWorkItem(workType, data)
    table.insert(self.workQueue, {
        type = workType,
        data = data,
        timestamp = GetTime()
    })
end

function Communications:ExecuteWorkItem(workItem)
    if workItem.type == "CACHE_CLEANUP" then
        self:CleanupOldCacheEntries()
    elseif workItem.type == "DATA_VALIDATION" then
        self:ValidateCachedData()
    end
end

function Communications:ValidateCachedData()
    -- Validate cached data structure integrity
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
        NextKey222.Debug:Dev("comms", "Removed", invalid, "invalid cache entries, validated", validated)
    end
end

-- MARK: Throttling
function Communications:CanSendMessage(messageType)
    local now = GetTime()
    local lastSent = self.throttleTimers[messageType] or 0
    
    -- PHASE 3: Optimize for offline players in communications
    local groupSize = GetNumGroupMembers() or 1
    local effectiveSize = groupSize
    
    -- Check for significant offline presence and use online count
    if NextKey222.Events and NextKey222.Events.HasSignificantOfflinePlayers then
        if NextKey222.Events:HasSignificantOfflinePlayers() then
            effectiveSize = NextKey222.Events:GetOnlineGroupMembers()
            NextKey222.Debug:Dev("comms", string.format("Communications optimized for mixed group: %d total, %d online, using %d effective size",
                groupSize, NextKey222.Events:GetOnlineGroupMembers(), effectiveSize))
        end
    end
    
    local throttleSettings = NextKey222.Constants.COMM_SETTINGS
    local baseInterval = throttleSettings and throttleSettings.THROTTLE_INTERVAL or 5
    
    -- Scale throttle interval: 5 players = 5s, 10 players = 10s, 20+ players = 20s
    local scaledInterval = baseInterval
    if effectiveSize > 5 then
        scaledInterval = math.min(baseInterval + (effectiveSize - 5) * 1.0, 20)
    end
    
    if now - lastSent < scaledInterval then
        local remaining = scaledInterval - (now - lastSent)
        NextKey222.Debug:Dev("comms", string.format("Message throttled: %s - wait %.1fs (total: %d, online: %d, interval: %.1fs)",
            messageType, remaining, groupSize, effectiveSize, scaledInterval))
        return false
    end
    
    self.throttleTimers[messageType] = now
    NextKey222.Debug:Dev("comms", string.format("Message allowed: %s (total: %d, online: %d, throttle: %.1fs)",
        messageType, groupSize, effectiveSize, scaledInterval))
    return true
end

-- MARK: Guild Keystone Comm
function Communications:ProcessKeystoneRequest(payload, sender)
    NextKey222.Debug:Dev("comms", "Received keystone request from", sender)
    
    -- Share our keystone if we have one
    local playerKeystone = NextKey222.Keystones and NextKey222.Keystones:ScanPlayerKeystone()
    if playerKeystone and playerKeystone.dungeonID and playerKeystone.level then
        NextKey222.Debug:Dev("comms", "Responding with keystone Level", playerKeystone.level, "dungeon", playerKeystone.dungeonID)
        self:ShareKeystone(playerKeystone)
    else
        NextKey222.Debug:Dev("comms", "No keystone to share")
    end
end

function Communications:ProcessKeystoneShare(payload, sender)
    if not payload.keystoneData then return end
    
    local keyData = payload.keystoneData
    NextKey222.Debug:Dev("comms", "Received keystone from", sender, "- Level", keyData.level, "dungeon", keyData.dungeonID)
    
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
    
    NextKey222.Debug:Dev("comms", "Shared keystone Level", keystoneData.level, "to guild")
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
        NextKey222.Debug:Dev("comms", "Not in guild, cannot request keystones")
        return false
    end
    
    -- Throttle: Don't send requests more than once every 10 seconds
    local currentTime = GetTime()
    if self.lastGuildKeystoneRequest and (currentTime - self.lastGuildKeystoneRequest) < 10 then
        local cooldown = 10 - (currentTime - self.lastGuildKeystoneRequest)
        NextKey222.Debug:Dev("comms", string.format("Guild keystone request throttled (%.1fs remaining)", cooldown))
        return false
    end
    
    self.lastGuildKeystoneRequest = currentTime
    NextKey222.Debug:Dev("comms", "Requesting keystones from guild members...")
    
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

-- MARK: Visual Testing

---Visual test for communication system
---Follows "In-Game First" testing protocol
function Communications:TestVisualCommunication()
    NextKey222.Debug:Dev("comms", "Starting visual communication test")
    
    -- Create visual test frame for user interaction
    local testFrame = CreateFrame("Frame", "NextKeyCommTestFrame", UIParent, "BackdropTemplate")
    testFrame:SetSize(450, 350)
    testFrame:SetPoint("CENTER")
    testFrame:SetFrameStrata("DIALOG")
    testFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title
    local title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Visual Communication Test")
    
    -- Instructions
    local instructions = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -15)
    instructions:SetWidth(430)
    instructions:SetText("This test validates the communication system through visual confirmation:\n\n" ..
                       "1. Join a party or create one with friends\n" ..
                       "2. Click 'Send Test Message' below\n" ..
                       "3. Ask party members if they received the message\n" ..
                       "4. Check chat for communication logs\n\n" ..
                       "Expected visual results:\n" ..
                       "• Test messages should appear in chat\n" ..
                       "• Party members should receive data\n" ..
                       "• IO scores should sync between players\n" ..
                       "• No error messages should appear")
    
    -- Test status display
    local statusDisplay = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusDisplay:SetPoint("TOP", instructions, "BOTTOM", 0, -15)
    statusDisplay:SetWidth(430)
    statusDisplay:SetText("|cFF888888Status: Ready to test|r")
    
    -- Test buttons
    local sendTestButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    sendTestButton:SetSize(140, 25)
    sendTestButton:SetPoint("BOTTOMLEFT", 20, 60)
    sendTestButton:SetText("Send Test Message")
    sendTestButton:SetScript("OnClick", function()
        NextKey222.Debug:Dev("comms", "Manual communication test triggered")
        statusDisplay:SetText("|cFFFFFF00Status: Sending test message...|r")
        
        -- Send test IO data
        local success = self:SharePlayerIOData()
        if success then
            NextKey:User("Test communication message sent successfully")
            statusDisplay:SetText("|cFF00FF00Status: Test message sent! Check chat logs.|r")
        else
            NextKey:User("Test communication failed - not in group or throttled")
            statusDisplay:SetText("|cFFFF4444Status: Failed - Join a party and try again|r")
        end
    end)
    
    local syncButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    syncButton:SetSize(140, 25)
    syncButton:SetPoint("BOTTOM", 0, 60)
    syncButton:SetText("Sync Party Data")
    syncButton:SetScript("OnClick", function()
        NextKey222.Debug:Dev("comms", "Manual party sync triggered")
        statusDisplay:SetText("|cFFFFFF00Status: Syncing party data...|r")
        
        -- Trigger party sync
        local success = self:SendSync()
        if success then
            NextKey:User("Party sync initiated successfully")
            statusDisplay:SetText("|cFF00FF00Status: Sync sent! Watch for data updates.|r")
        else
            NextKey:User("Party sync failed - not in group or throttled")
            statusDisplay:SetText("|cFFFF4444Status: Sync failed - Join a party and try again|r")
        end
    end)
    
    local checkCacheButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    checkCacheButton:SetSize(140, 25)
    checkCacheButton:SetPoint("BOTTOMRIGHT", -20, 60)
    checkCacheButton:SetText("Check Data Cache")
    checkCacheButton:SetScript("OnClick", function()
        NextKey222.Debug:Dev("comms", "Checking communication data cache")
        
        local cacheCount = 0
        local playerList = {}
        
        for playerName, ioData in pairs(self.playerIOCache) do
            cacheCount = cacheCount + 1
            table.insert(playerList, string.format("%s: %d IO", playerName, ioData.totalIO or 0))
        end
        
        if cacheCount > 0 then
            NextKey:User(string.format("Data cache contains %d players:", cacheCount))
            for _, playerInfo in ipairs(playerList) do
                NextKey:User("  " .. playerInfo)
            end
            statusDisplay:SetText(string.format("|cFF00FF00Status: Found %d players in cache|r", cacheCount))
        else
            NextKey:User("No player data in cache - try sending test messages first")
            statusDisplay:SetText("|cFF888888Status: No data in cache - Send messages first|r")
        end
    end)
    
    -- Request data button
    local requestDataButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    requestDataButton:SetSize(200, 25)
    requestDataButton:SetPoint("BOTTOM", 0, 25)
    requestDataButton:SetText("Request Party IO Data")
    requestDataButton:SetScript("OnClick", function()
        NextKey222.Debug:Dev("comms", "Manual IO data request triggered")
        statusDisplay:SetText("|cFFFFFF00Status: Requesting IO data from party...|r")
        
        -- Request IO data from party
        local success = self:RequestPartyIOData()
        if success then
            NextKey:User("IO data request sent to party")
            statusDisplay:SetText("|cFF00FF00Status: Request sent! Wait for responses.|r")
        else
            NextKey:User("IO data request failed - not in group")
            statusDisplay:SetText("|cFFFF4444Status: Failed - Join a party and try again|r")
        end
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, testFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        testFrame:Hide()
    end)
    
    testFrame:Show()
    
    -- Auto-refresh timer to monitor incoming messages
    local lastCacheCount = 0
    testFrame:SetScript("OnUpdate", function(self, elapsed)
        -- Check cache count every 2 seconds
        local currentCacheCount = 0
        for _ in pairs(self.playerIOCache) do
            currentCacheCount = currentCacheCount + 1
        end
        
        if currentCacheCount ~= lastCacheCount then
            lastCacheCount = currentCacheCount
            if currentCacheCount > 0 then
                statusDisplay:SetText(string.format("|cFF00FF00Status: %d players in cache - Data received!|r", currentCacheCount))
            end
        end
    end)
    
    NextKey222.Debug:Dev("comms", "Visual communication test frame created")
end

--- Sends organizer data to party members
-- @param organizerData table The organizer data to send
-- @return boolean True if sent successfully
function Communications:ShareOrganizerData(organizerData)
    if not IsInGroup() then
        NextKey222.Debug:Dev("comms", "Not in group, cannot share organizer data")
        return false
    end
    
    -- Check if message should be throttled
    if not self:CanSendMessage("ORGANIZER_DATA") then
        NextKey222.Debug:Dev("comms", "Organizer data message throttled")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.ORGANIZER_DATA,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName,
        organizerData = organizerData
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
    NextKey222.Debug:Dev("comms", "Shared organizer data to", channel)
    return true
end

--- Requests organizer data from party members
-- @return boolean True if sent successfully
function Communications:RequestOrganizerData()
    if not IsInGroup() then
        NextKey222.Debug:Dev("comms", "Not in group, cannot request organizer data")
        return false
    end
    
    -- Check if message should be throttled
    if not self:CanSendMessage("ORGANIZER_DATA") then
        NextKey222.Debug:Dev("comms", "Organizer data request throttled")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.REQUEST_ORGANIZER_DATA,
        version = NextKey.version or "1.0.0",
        timestamp = GetTime(),
        sender = NextKey.playerFullName
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
    NextKey222.Debug:Dev("comms", "Requested organizer data from", channel)
    return true
end

--- Processes organizer data messages
-- @param payload table The message payload
-- @param sender string The message sender
function Communications:ProcessOrganizerData(payload, sender)
    NextKey222.Debug:Dev("comms", "Received organizer data from", sender)
    
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.ORGANIZER_DATA then
        if payload.organizerData then
            -- Store organizer data for this player
            if NextKey222.OrganizerData then
                NextKey222.OrganizerData:StoreData(payload.organizerData)
            end
            
            -- Notify UI that organizer data has been updated
            if NextKey222.UI and NextKey222.UI.OnOrganizerDataUpdated then
                NextKey222.UI:OnOrganizerDataUpdated(sender, payload.organizerData)
            end
        end
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.REQUEST_ORGANIZER_DATA then
        -- Respond by sharing our organizer data
        if NextKey222.OrganizerData then
            local ourData = NextKey222.OrganizerData:GetData()
            if ourData then
                self:ShareOrganizerData(ourData)
            end
        end
    end
end

-- MARK: Survey System Handlers
--- Processes organizer poll request messages
-- @param payload table The message payload
-- @param sender string The message sender
function Communications:ProcessOrganizerPollRequest(payload, sender)
    NextKey222.Debug:Dev("organizer", "Received poll request from", sender)
    
    -- Forward to survey module if available
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnPollRequestReceived(payload, sender)
    else
        NextKey222.Debug:Dev("organizer", "ParticipantSurvey module not available")
    end
end

--- Processes organizer poll response messages
-- @param payload table The message payload
-- @param sender string The message sender
function Communications:ProcessOrganizerPollResponse(payload, sender)
    NextKey222.Debug:Dev("organizer", "Received poll response from", sender)
    
    -- Forward to survey module if available
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnPollResponseReceived(payload, sender)
    else
        NextKey222.Debug:Dev("organizer", "ParticipantSurvey module not available")
    end
    
    -- Update RosterBoard poll progress if active
    if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
        -- Add response to active poll
        table.insert(NextKey222.RosterBoard.activePoll.responses, {
            sender = sender,
            data = payload.data,
            timestamp = GetTime()
        })
        
        -- Update progress UI
        NextKey222.RosterBoard:UpdatePollProgress()
    end
end

--- Registers organizer message handlers (called during initialization)
function Communications:RegisterOrganizerHandlers()
    NextKey222.Debug:Dev("organizer", "Organizer communication handlers registered")
    -- Handlers are integrated into main ProcessMessage() function
    return true
end

-- MARK: Addon Discovery
function Communications:ProcessAddonPing(payload, sender)
    -- Forward to ParticipantSurvey module
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnAddonPing(payload, sender)
    end
end

function Communications:ProcessAddonPong(payload, sender)
    -- Forward to ParticipantSurvey module
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnAddonPong(payload, sender)
    end
end

return Communications