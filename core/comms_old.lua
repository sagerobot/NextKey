-- MARK: Communications Module
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- Communications module
local Communications = {
    throttleTimers = {},
    messageQueue = {},
    isProcessing = false
}

NextKey222.Communications = Communications
NextKey222.RegisterModule("Communications", Communications)

-- MARK: Message Serialization
function Communications:SerializeSyncPayload(keystoneData)
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.SYNC,
        version = NextKey.version or "1.0.0",
        timestamp = NextKey222.Utils.GetTime()
    }
    
    if keystoneData then
        payload.keystone = {
            dungeonID = keystoneData.dungeonID or 0,
            level = keystoneData.level or 0,
            ownerName = keystoneData.ownerName or NextKey.playerFullName,
            class = keystoneData.class or NextKey.playerClass,
            timestamp = NextKey222.Utils.GetTime()
        }
    end
    
    return AceSerializer:Serialize(payload)
end

function Communications:ParseSyncPayload(message)
    local success, payload = AceSerializer:Deserialize(message)
    if not success or not payload.opcode then
        return nil
    end
    return payload
end

-- MARK: Keystone Communication (Details!-style)
function Communications:RequestKeystones()
    if not IsInGroup() then
        NextKey222.Debug:Print("comms", "Not in group, cannot request keystones")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local requestPayload = {
        opcode = NextKey222.Constants.COMM_OPCODES.KEYSTONE_REQUEST,
        version = NextKey.version or "1.0.0",
        timestamp = NextKey222.Utils.GetTime(),
        sender = NextKey.playerFullName
    }
    
    local serialized = AceSerializer:Serialize(requestPayload)
    NextKey:SendCommMessage("NKEY", serialized, channel)
    NextKey222.Debug:Print("comms", "Sent keystone request to", channel)
    return true
end

function Communications:ShareKeystone(keystoneData)
    if not IsInGroup() then
        NextKey222.Debug:Print("comms", "Not in group, cannot share keystone")
        return false
    end
    
    local channel = IsInRaid() and "RAID" or "PARTY"
    local sharePayload = {
        opcode = NextKey222.Constants.COMM_OPCODES.KEYSTONE_SHARE,
        version = NextKey.version or "1.0.0",
        timestamp = NextKey222.Utils.GetTime(),
        sender = NextKey.playerFullName,
        keystone = {
            dungeonID = keystoneData.dungeonID or 0,
            level = keystoneData.level or 0,
            ownerName = keystoneData.ownerName or NextKey.playerFullName,
            class = keystoneData.class or NextKey.playerClass,
            mapID = keystoneData.mapID or keystoneData.dungeonID
        }
    }
    
    -- Add M+ rating if available
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if summary and summary.currentSeasonScore then
            sharePayload.keystone.rating = summary.currentSeasonScore
        end
    end
    
    local serialized = AceSerializer:Serialize(sharePayload)
    NextKey:SendCommMessage("NKEY", serialized, channel)
    NextKey222.Debug:Print("comms", "Shared keystone:", sharePayload.keystone.dungeonID, "level", sharePayload.keystone.level)
    return true
end

-- MARK: Core Communication Functions
function Communications:SendSync()
    local channel = IsInRaid() and "RAID" or "PARTY"
    if not IsInGroup() then
        NextKey:Print("No group to sync with")
        return false
    end
    
    local keystoneData = nil
    if NextKey.Keystones and NextKey.Keystones.GetPlayerKeystone then
        keystoneData = NextKey.Keystones:GetPlayerKeystone()
    end
    
    local serializedData = self:SerializeSyncPayload(keystoneData)
    if serializedData then
        NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serializedData, channel)
        NextKey:Print("Sync sent to group")
        return true
    end
    
    return false
end

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
    
    -- Handle different message types
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.SYNC then
        self:ProcessKeystoneSync(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.KEYSTONE_REQUEST then
        self:ProcessKeystoneRequest(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.KEYSTONE_SHARE then
        self:ProcessKeystoneShare(payload, sender)
    else
        NextKey222.Debug:Print("comms", "Unknown opcode:", payload.opcode, "from", sender)
    end
end

function Communications:ProcessKeystoneRequest(payload, sender)
    NextKey222.Debug:Print("comms", "Received keystone request from", sender)
    
    -- Get our current keystone and share it
    local myKeystone = NextKey:ScanPlayerKeystone()
    if myKeystone and myKeystone.dungeonID > 0 then
        C_Timer.After(math.random(1, 3), function() -- Random delay to prevent spam
            self:ShareKeystone(myKeystone)
        end)
    else
        NextKey222.Debug:Print("comms", "No keystone to share in response to request")
    end
end

function Communications:ProcessKeystoneShare(payload, sender)
    if not payload.keystone then 
        NextKey222.Debug:Print("comms", "Invalid keystone share from", sender)
        return 
    end
    
    NextKey222.Debug:Print("comms", "Received keystone share from", sender, "- Dungeon:", payload.keystone.dungeonID, "Level:", payload.keystone.level)
    
    -- Store received keystone in cache
    if not NextKey.keystoneCache then
        NextKey.keystoneCache = {}
    end
    
    NextKey.keystoneCache[sender] = {
        dungeonID = payload.keystone.dungeonID,
        level = payload.keystone.level,
        ownerName = payload.keystone.ownerName or sender,
        ownerShort = (payload.keystone.ownerName or sender):match("^([^%-]+)"),
        class = payload.keystone.class,
        rating = payload.keystone.rating,
        source = "nextkey-comm",
        timestamp = payload.timestamp
    }
    
    -- Trigger UI refresh if main window is open
    if NextKey222.UI and NextKey222.UI.MainFrame and NextKey222.UI.MainFrame:IsShown() then
        NextKey222.UI:RenderResults()
    end
end

function Communications:ProcessKeystoneSync(payload, sender)
    if not payload.keystone then return end
    
    local keystoneData = {
        dungeonID = payload.keystone.dungeonID,
        level = payload.keystone.level,
        ownerName = payload.keystone.ownerName or sender,
        ownerShort = (payload.keystone.ownerName or sender):match("^([^%-]+)"),
        class = payload.keystone.class,
        source = "comm",
        timestamp = payload.timestamp
    }
    
    if not NextKey.keystoneCache then
        NextKey.keystoneCache = {}
    end
    NextKey.keystoneCache[sender] = keystoneData
end

-- MARK: Module Interface
function Communications:Initialize()
    NextKey222.Debug:Print("communications", "Communications module initialized")
    return true
end

return Communications
