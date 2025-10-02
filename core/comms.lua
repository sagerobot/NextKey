-- MARK: Communications Module (Simplified - LibOpenRaid handles keystones)
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- Communications module for NextKey-specific data (preferences, settings, etc.)
local Communications = {
    throttleTimers = {},
    messageQueue = {},
    isProcessing = false
}

NextKey222.Communications = Communications
NextKey222.RegisterModule("Communications", Communications)

-- MARK: Message Serialization
function Communications:SerializeSyncPayload(data)
    local payload = {
        opcode = NextKey222.Constants.COMM_OPCODES.SYNC,
        version = NextKey.version or "1.0.0",
        timestamp = NextKey222.Utils.GetTime(),
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
        timestamp = NextKey222.Utils.GetTime(),
        sender = NextKey.playerFullName,
        preferences = preferences
    }
    
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
    NextKey222.Debug:Print("comms", "Shared preferences to", channel)
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
    
    -- Handle different message types
    if payload.opcode == NextKey222.Constants.COMM_OPCODES.SYNC then
        self:ProcessSync(payload, sender)
    elseif payload.opcode == NextKey222.Constants.COMM_OPCODES.PREFERENCE_UPDATE then
        self:ProcessPreferenceUpdate(payload, sender)
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

-- MARK: Utility Functions
function Communications:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- MARK: Throttling (if needed for future features)
function Communications:CanSendMessage(messageType)
    local now = GetTime()
    local lastSent = self.throttleTimers[messageType] or 0
    local throttleInterval = 5 -- 5 seconds between messages of the same type
    
    if now - lastSent < throttleInterval then
        NextKey222.Debug:Print("comms", "Message throttled:", messageType, "- wait", throttleInterval - (now - lastSent), "seconds")
        return false
    end
    
    self.throttleTimers[messageType] = now
    return true
end

return Communications