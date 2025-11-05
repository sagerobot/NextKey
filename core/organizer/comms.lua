-- MARK: Module Definition
-- Organizer Communications for M+ Group Organizer
-- Extends existing communications with organizer-specific message types

local _, NextKey222 = ...

local OrganizerComms = {}
NextKey222.OrganizerComms = OrganizerComms

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("OrganizerComms", OrganizerComms)

-- MARK: Private Implementation

-- Organizer-specific opcodes
local ORGANIZER_OPCODES = {
    -- Discovery Protocol (NEW - Handshake System)
    ADDON_PING = "ORG_ADDON_PING",     -- Organizer → All: "Who has addon?"
    ADDON_PONG = "ORG_ADDON_PONG",     -- Participant → Organizer: "I do!"
    
    -- Survey System
    POLL_REQUEST = "ORG_POLL_REQUEST",
    POLL_RESPONSE = "ORG_POLL_RESPONSE",
    
    -- Roster Synchronization
    ROSTER_STATE_FULL = "ORG_ROSTER_FULL", -- Complete roster state
    ROSTER_STATE_DELTA = "ORG_ROSTER_DELTA", -- Incremental update
    PLAYER_CARD_MOVED = "ORG_CARD_MOVED",
    KEYSTONE_DESIGNATED = "ORG_KEY_SET",
    
    -- Optimizer Status
    OPTIMIZER_STARTED = "ORG_OPT_START",
    OPTIMIZER_PROGRESS = "ORG_OPT_PROGRESS",
    OPTIMIZER_COMPLETE = "ORG_OPT_COMPLETE"
}

-- Message queue for batching
local pendingUpdates = {}
local updateQueueTimer = nil
local BATCH_INTERVAL = 0.5 -- 500ms

-- MARK: Public Interface

--- Initialize Organizer Communications module
-- @return boolean True if initialization successful
function OrganizerComms:Initialize()
    return NextKey222.SafeRun(function()
        -- Register organizer-specific message handlers
        self:RegisterOrganizerHandlers()
        
        Debug:Dev("org_comms", "OrganizerComms initialized")
        return true
    end, "OrganizerComms:Initialize")
end

--- Register organizer-specific message handlers
function OrganizerComms:RegisterOrganizerHandlers()
    return NextKey222.SafeRun(function()
        if not NextKey222.Communications then
            Debug:Error("OrganizerComms:RegisterOrganizerHandlers - Communications module not available")
            return false
        end
        
        -- Handler registration removed - Communications module routes organizer messages directly
        -- via ProcessOrganizerPollRequest, ProcessOrganizerPollResponse, and ProcessOrganizerData
        -- The Communications:ProcessMessage function handles routing based on opcodes
        
        Debug:Dev("org_comms", "Organizer message handlers ready (routed via Communications module)")
        return true
    end, "OrganizerComms:RegisterOrganizerHandlers")
end

--- Send organizer message
-- @param opcode string Message opcode
-- @param data table Message data
-- @param channel string Communication channel (PARTY, RAID, GUILD, WHISPER)
-- @param target string Target for whisper messages
-- @return boolean True if send successful
function OrganizerComms:SendOrganizerMessage(opcode, data, channel, target)
    return NextKey222.SafeRun(function()
        local NextKey = NextKey222.Addon
        if not NextKey or not NextKey.SendCommMessage then
            Debug:Error("OrganizerComms:SendOrganizerMessage - Addon not available")
            return false
        end
        
        -- Get AceSerializer library
        local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
        if not AceSerializer then
            Debug:Error("OrganizerComms:SendOrganizerMessage - AceSerializer not available")
            return false
        end
        
        -- Create message payload
        local payload = {
            opcode = opcode,
            version = NextKey.version or "0.3.0",
            timestamp = GetTime(),
            sender = UnitName("player") .. "-" .. GetRealmName(),
            data = data or {}
        }
        
        -- Serialize the message
        local serialized = AceSerializer:Serialize(payload)
        
        -- Send via AceComm
        NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel or "PARTY", target)
        
        Debug:Dev("org_comms", "Sent organizer message:", opcode, "to", channel or "PARTY")
        return true
    end, "OrganizerComms:SendOrganizerMessage")
end

--- Send poll request to group
-- @param pollID string Unique poll identifier
-- @param timeout number Response timeout in seconds
-- @return boolean True if send successful
function OrganizerComms:SendPollRequest(pollID, timeout)
    return NextKey222.SafeRun(function()
        local data = {
            pollID = pollID,
            timeout = timeout or 60
        }
        
        return self:SendOrganizerMessage(ORGANIZER_OPCODES.POLL_REQUEST, data, "PARTY")
    end, "OrganizerComms:SendPollRequest")
end

--- Send poll response
-- @param pollID string Poll identifier to respond to
-- @param responseData table Response data
-- @return boolean True if send successful
function OrganizerComms:SendPollResponse(pollID, responseData)
    return NextKey222.SafeRun(function()
        local data = {
            pollID = pollID,
            optedIn = responseData.optedIn,
            selectedCharacter = responseData.selectedCharacter,
            rolePreferences = responseData.rolePreferences,
            characterData = responseData.characterData
        }
        
        return self:SendOrganizerMessage(ORGANIZER_OPCODES.POLL_RESPONSE, data, "PARTY")
    end, "OrganizerComms:SendPollResponse")
end

--- Queue roster update for batching
-- @param updateData table Update data to queue
function OrganizerComms:QueueRosterUpdate(updateData)
    return NextKey222.SafeRun(function()
        table.insert(pendingUpdates, updateData)
        
        -- Start batch timer if not already running
        if not updateQueueTimer then
            updateQueueTimer = C_Timer.NewTimer(BATCH_INTERVAL, function()
                self:FlushUpdateQueue()
            end)
        end
        
        Debug:Dev("org_comms", "Queued roster update. Queue size:", #pendingUpdates)
    end, "OrganizerComms:QueueRosterUpdate")
end

--- Flush queued updates as batch
function OrganizerComms:FlushUpdateQueue()
    return NextKey222.SafeRun(function()
        if #pendingUpdates == 0 then 
            updateQueueTimer = nil
            return 
        end
        
        -- Create batch message
        local batchData = {
            updates = pendingUpdates,
            batchID = self:GenerateBatchID()
        }
        
        -- Send batch
        local success = self:SendOrganizerMessage(ORGANIZER_OPCODES.ROSTER_STATE_DELTA, batchData, "PARTY")
        
        if success then
            Debug:Dev("org_comms", "Sent batch with", #pendingUpdates, "updates")
        else
            Debug:Error("OrganizerComms:FlushUpdateQueue - Failed to send batch")
        end
        
        -- Clear queue and timer
        pendingUpdates = {}
        updateQueueTimer = nil
    end, "OrganizerComms:FlushUpdateQueue")
end

--- Send full roster state
-- @param rosterData table Complete roster data
-- @return boolean True if send successful
function OrganizerComms:SendFullRosterState(rosterData)
    return NextKey222.SafeRun(function()
        local data = {
            groups = rosterData.groups or {},
            bench = rosterData.bench or {},
            optOut = rosterData.optOut or {},
            timestamp = GetTime()
        }
        
        return self:SendOrganizerMessage(ORGANIZER_OPCODES.ROSTER_STATE_FULL, data, "PARTY")
    end, "OrganizerComms:SendFullRosterState")
end

--- Send player card move update
-- @param playerID string Player being moved
-- @param fromLocation string Source location
-- @param toLocation string Destination location
-- @return boolean True if send successful
function OrganizerComms:SendPlayerCardMove(playerID, fromLocation, toLocation)
    return NextKey222.SafeRun(function()
        local data = {
            action = "CARD_MOVED",
            playerID = playerID,
            fromLocation = fromLocation,
            toLocation = toLocation
        }
        
        return self:SendOrganizerMessage(ORGANIZER_OPCODES.PLAYER_CARD_MOVED, data, "PARTY")
    end, "OrganizerComms:SendPlayerCardMove")
end

--- Send keystone designation update
-- @param groupIndex number Group index
-- @param keystone table Keystone data
-- @return boolean True if send successful
function OrganizerComms:SendKeystoneDesignation(groupIndex, keystone)
    return NextKey222.SafeRun(function()
        local data = {
            groupIndex = groupIndex,
            keystone = keystone
        }
        
        return self:SendOrganizerMessage(ORGANIZER_OPCODES.KEYSTONE_DESIGNATED, data, "PARTY")
    end, "OrganizerComms:SendKeystoneDesignation")
end

--- Send optimizer status update
-- @param status string Status type ("STARTED", "PROGRESS", "COMPLETE")
-- @param statusData table Status-specific data
-- @return boolean True if send successful
function OrganizerComms:SendOptimizerStatus(status, statusData)
    return NextKey222.SafeRun(function()
        local opcode
        if status == "STARTED" then
            opcode = ORGANIZER_OPCODES.OPTIMIZER_STARTED
        elseif status == "PROGRESS" then
            opcode = ORGANIZER_OPCODES.OPTIMIZER_PROGRESS
        elseif status == "COMPLETE" then
            opcode = ORGANIZER_OPCODES.OPTIMIZER_COMPLETE
        else
            Debug:Error("OrganizerComms:SendOptimizerStatus - Unknown status:", status)
            return false
        end
        
        local data = statusData or {}
        data.status = status
        
        return self:SendOrganizerMessage(opcode, data, "PARTY")
    end, "OrganizerComms:SendOptimizerStatus")
end

--- Generate unique batch ID
-- @return string Unique batch identifier
function OrganizerComms:GenerateBatchID()
    return NextKey222.SafeRun(function()
        return "BATCH_" .. time() .. "_" .. math.random(1000, 9999)
    end, "OrganizerComms:GenerateBatchID")
end

--- Generate unique poll ID
-- @return string Unique poll identifier
function OrganizerComms:GeneratePollID()
    return NextKey222.SafeRun(function()
        return "POLL_" .. time() .. "_" .. math.random(1000, 9999)
    end, "OrganizerComms:GeneratePollID")
end

-- MARK: Message Handlers

--- Handle poll request received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnPollRequestReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received poll request from", sender)
        
        -- Trigger poll dialog if UI is available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.ShowSurveyDialog then
            NextKey222.OrganizerUI:ShowSurveyDialog(message.data, sender)
        end
    end, "OrganizerComms:OnPollRequestReceived")
end

--- Handle poll response received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnPollResponseReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received poll response from", sender)
        
        -- Process response through survey system
        if NextKey222.OrganizerSurvey and NextKey222.OrganizerSurvey.ProcessResponse then
            NextKey222.OrganizerSurvey:ProcessResponse(message.data, sender)
        end
    end, "OrganizerComms:OnPollResponseReceived")
end

--- Handle full roster state received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnRosterStateFullReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received full roster state from", sender)
        
        -- Apply roster state if UI is available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.ApplyFullRosterState then
            NextKey222.OrganizerUI:ApplyFullRosterState(message.data, sender)
        end
    end, "OrganizerComms:OnRosterStateFullReceived")
end

--- Handle roster state delta received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnRosterStateDeltaReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received roster delta from", sender, "with", #message.data.updates, "updates")
        
        -- Apply delta updates if UI is available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.ApplyRosterDelta then
            NextKey222.OrganizerUI:ApplyRosterDelta(message.data, sender)
        end
    end, "OrganizerComms:OnRosterStateDeltaReceived")
end

--- Handle player card move received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnPlayerCardMovedReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received player card move from", sender)
        
        -- Apply card move if UI is available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.ApplyCardMove then
            NextKey222.OrganizerUI:ApplyCardMove(message.data, sender)
        end
    end, "OrganizerComms:OnPlayerCardMovedReceived")
end

--- Handle keystone designation received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnKeystoneDesignatedReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received keystone designation from", sender)
        
        -- Apply keystone designation if UI is available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.ApplyKeystoneDesignation then
            NextKey222.OrganizerUI:ApplyKeystoneDesignation(message.data, sender)
        end
    end, "OrganizerComms:OnKeystoneDesignatedReceived")
end

--- Handle optimizer started received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnOptimizerStartedReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received optimizer started from", sender)
        
        -- Update UI if available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.OnOptimizerStarted then
            NextKey222.OrganizerUI:OnOptimizerStarted(message.data, sender)
        end
    end, "OrganizerComms:OnOptimizerStartedReceived")
end

--- Handle optimizer progress received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnOptimizerProgressReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received optimizer progress from", sender)
        
        -- Update UI if available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.OnOptimizerProgress then
            NextKey222.OrganizerUI:OnOptimizerProgress(message.data, sender)
        end
    end, "OrganizerComms:OnOptimizerProgressReceived")
end

--- Handle optimizer complete received
-- @param message table Message data
-- @param sender string Message sender
function OrganizerComms:OnOptimizerCompleteReceived(message, sender)
    return NextKey222.SafeRun(function()
        Debug:Dev("org_comms", "Received optimizer complete from", sender)
        
        -- Update UI if available
        if NextKey222.OrganizerUI and NextKey222.OrganizerUI.OnOptimizerComplete then
            NextKey222.OrganizerUI:OnOptimizerComplete(message.data, sender)
        end
    end, "OrganizerComms:OnOptimizerCompleteReceived")
end

--- Test organizer communications
function OrganizerComms:Test()
    return NextKey222.SafeRun(function()
        Debug:User("=== Organizer Communications Test ===")
        
        -- Test poll request
        local pollID = self:GeneratePollID()
        Debug:User("Generated poll ID:", pollID)
        
        -- Test batch ID generation
        local batchID = self:GenerateBatchID()
        Debug:User("Generated batch ID:", batchID)
        
        -- Test message queuing
        self:QueueRosterUpdate({action = "TEST", data = "test1"})
        self:QueueRosterUpdate({action = "TEST", data = "test2"})
        
        Debug:User("Queued", #pendingUpdates, "updates")
        
        -- Test flush
        self:FlushUpdateQueue()
        
        Debug:User("=== Test Complete ===")
    end, "OrganizerComms:Test")
end

-- MARK: Event Handlers
function OrganizerComms:OnEnable()
    -- Register for events if needed
end

function OrganizerComms:OnDisable()
    -- Cleanup if needed
    if updateQueueTimer then
        updateQueueTimer:Cancel()
        updateQueueTimer = nil
    end
    
    pendingUpdates = {}
end

return OrganizerComms