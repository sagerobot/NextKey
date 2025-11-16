-- MARK: Module Definition
local _, NextKey222 = ...

local OrganizerState = {}
NextKey222.OrganizerState = OrganizerState
NextKey222.RegisterModule("OrganizerState", OrganizerState)

local Debug = NextKey222.Debug

-- MARK: Event Announcement Helper
--- Announces an event to listeners via AceEvent system
-- @param eventName string - Event name (e.g., "ORGANIZER_PLAYER_ADDED")
-- @param payload table - Event payload with all necessary context
-- @return boolean - True if announcement successful
function OrganizerState:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            Debug:Error("Cannot announce event - AceEvent system not available:", eventName)
            return false
        end
        
        -- Ensure timestamp is set
        if not payload.timestamp then
            payload.timestamp = GetTime()
        end
        
        -- Announce event to all listeners
        NextKey222.Addon:SendMessage(eventName, payload)
        
        Debug:Dev("organizer_events", "Event announced:", eventName, "- playerID:", payload.playerID or "N/A")
        
        return true
    end, "OrganizerState:AnnounceEvent")
end

-- MARK: Module State
-- CRITICAL: This is the SINGLE SOURCE OF TRUTH for all player data
-- Cards only store playerID references and render from this state
OrganizerState.players = {}      -- {[playerID] = PlayerData} - Full player objects
OrganizerState.bench = {}        -- {[playerID] = true} - Set for fast bench lookup
OrganizerState.optOut = {}       -- {[playerID] = true} - Set for opt-out tracking
OrganizerState.groups = {}       -- {[groupIndex][slotIndex] = playerID} - Group assignments
OrganizerState.keystones = {}    -- {[groupIndex] = {keystone, playerID}} - Designated keystones
OrganizerState.activePoll = nil  -- {id, startTime, responses, timeout} - Active poll state

-- MARK: Initialization
function OrganizerState:Initialize()
    return NextKey222.SafeRun(function()
        Debug:User("⚠️ OrganizerState:Initialize() called - THIS SHOULD ONLY HAPPEN ONCE ON ADDON LOAD!")
        Debug:Dev("organizer_state", "Initializing OrganizerState module")
        
        -- Initialize data structures ONLY IF NOT ALREADY INITIALIZED
        if not self._initialized then
            self.players = {}
            self.bench = {}
            self.optOut = {}
            self.groups = {}
            self.keystones = {}
            self.activePoll = nil
            
            -- SESSION 4: Load persisted data
            self:LoadFromPersistence()
            
            self._initialized = true
            Debug:User("✓ OrganizerState initialized for the first time")
        else
            Debug:User("⚠️ OrganizerState:Initialize() called AGAIN - skipping reinitialization to preserve data!")
        end
        
        Debug:Dev("organizer_state", "OrganizerState initialized successfully")
        return true
    end, "OrganizerState:Initialize")
end

-- MARK: Player Management
--- Retrieve player data by ID
-- @param playerID string - Player identifier (Name-Realm)
-- @return table|nil - Player data object or nil if not found
-- @usage local playerData = OrganizerState:GetPlayer("PlayerName-Realm")
function OrganizerState:GetPlayer(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            Debug:Error("GetPlayer called with nil playerID")
            return nil
        end
        return self.players[playerID]
    end, "OrganizerState:GetPlayer")
end

--- Store or update complete player data
-- @param playerID string - Player identifier
-- @param playerData table - Complete player data object
-- @usage OrganizerState:SetPlayer("PlayerName-Realm", {id="...", name="...", ...})
function OrganizerState:SetPlayer(playerID, playerData)
    return NextKey222.SafeRun(function()
        if not playerID or not playerData then
            Debug:Error("SetPlayer called with missing arguments")
            return
        end
        
        -- Check if this is a new player
        local isNewPlayer = self.players[playerID] == nil
        
        -- Ensure playerData has ID
        playerData.id = playerID
        
        -- BUG FIX: Normalize roles field to always be an array
        -- This prevents role icons from vanishing when cards are moved
        if playerData.role and (not playerData.roles or #playerData.roles == 0) then
            -- Convert singular role to array
            playerData.roles = {playerData.role}
            Debug:Dev("organizer_state", "Normalized singular role to array:", playerData.role)
        elseif not playerData.roles or #playerData.roles == 0 then
            -- No roles at all - try to get from profile
            local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(playerID)
            if profile and profile.role then
                playerData.roles = {profile.role}
                Debug:Dev("organizer_state", "Set roles from profile:", profile.role)
            else
                playerData.roles = {"DAMAGER"}  -- Safe default
                Debug:Dev("organizer_state", "Applied default role: DAMAGER")
            end
        end
        
        -- BUG FIX: Ensure specPreferences and specDetails are generated if missing
        -- This is critical for tooltip display to work correctly
        if (not playerData.specPreferences or not next(playerData.specPreferences)) and
           NextKey222.OrganizerPlayerDataBuilder and
           NextKey222.OrganizerPlayerDataBuilder.GenerateSpecPreferences then
            local specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(playerID, {randomize = false})
            playerData.specPreferences = specPrefs
            playerData.specDetails = specDetails
            Debug:Dev("organizer_state", "Generated missing spec preferences for:", playerID)
        end
        
        -- Store in players table
        self.players[playerID] = playerData
        
        Debug:Dev("organizer_state", "SetPlayer:", playerID, "- stored with roles:", playerData.roles and table.concat(playerData.roles, ",") or "NONE",
                  "specPreferences:", playerData.specPreferences ~= nil, "specDetails:", playerData.specDetails ~= nil)
        
        -- EVENT: Announce player added (only if new)
        if isNewPlayer then
            local location = self:GetPlayerLocation(playerID) or "bench"
            self:AnnounceEvent("ORGANIZER_PLAYER_ADDED", {
                playerID = playerID,
                playerData = playerData,
                location = location,
                source = "SetPlayer"
            })
        end
    end, "OrganizerState:SetPlayer")
end

--- Partially update player data (merge updates)
-- @param playerID string - Player identifier
-- @param updates table - Partial data to merge into existing player data
-- @usage OrganizerState:UpdatePlayer("PlayerName-Realm", {overallScore = 3000})
function OrganizerState:UpdatePlayer(playerID, updates)
    return NextKey222.SafeRun(function()
        if not playerID or not updates then
            Debug:Error("UpdatePlayer called with missing arguments")
            return
        end
        
        -- Get existing player data or create new entry
        local playerData = self.players[playerID] or {id = playerID}
        
        -- Merge updates
        for key, value in pairs(updates) do
            playerData[key] = value
        end
        
        -- Store updated data
        self.players[playerID] = playerData
        
        Debug:Dev("organizer_state", "UpdatePlayer:", playerID, "- updates applied")
        
        -- EVENT: Announce player updated
        self:AnnounceEvent("ORGANIZER_PLAYER_UPDATED", {
            playerID = playerID,
            updates = updates,
            playerData = playerData,
            updateType = "generic"
        })
    end, "OrganizerState:UpdatePlayer")
end

--- Update player data from poll response (CRITICAL BUG FIX)
-- This is the key function that prevents poll data loss
-- @param playerID string - Player identifier
-- @param response table - Poll response data containing specPreferences, specDetails, etc.
-- @usage OrganizerState:UpdatePlayerFromPollResponse("PlayerName-Realm", pollResponse)
function OrganizerState:UpdatePlayerFromPollResponse(playerID, response)
    return NextKey222.SafeRun(function()
        if not playerID or not response then
            Debug:Error("UpdatePlayerFromPollResponse called with missing arguments")
            return
        end
        
        -- Get or create player data
        local playerData = self.players[playerID] or {id = playerID}
        
        -- CRITICAL: Store poll response data (this prevents data loss!)
        if response.specPreferences then
            playerData.specPreferences = response.specPreferences
        end
        
        if response.specDetails then
            playerData.specDetails = response.specDetails
        end
        
        -- Store survey response metadata
        playerData.surveyResponse = {
            optedIn = response.optedIn,
            selectedCharacter = response.selectedCharacter,
            rolePreferences = response.rolePreferences or {},
            timestamp = GetTime()
        }
        
        -- Store benchedForAlt flag if present
        if response.benchedForAlt ~= nil then
            playerData.benchedForAlt = response.benchedForAlt
        end
        
        -- Save to state
        self.players[playerID] = playerData
        
        Debug:Dev("organizer_state", "UpdatePlayerFromPollResponse:", playerID,
                 "- specPreferences:", playerData.specPreferences ~= nil,
                 "specDetails:", playerData.specDetails ~= nil)
        
        -- EVENT: Announce poll response received (also fires PLAYER_UPDATED)
        local totalResponses = 0
        local expectedResponses = 0
        if self.activePoll then
            for _ in pairs(self.activePoll.responses) do
                totalResponses = totalResponses + 1
            end
            expectedResponses = self.activePoll.totalMembers or 0
        end
        
        self:AnnounceEvent("ORGANIZER_POLL_RESPONSE_RECEIVED", {
            playerID = playerID,
            response = response,
            playerData = playerData,
            totalResponses = totalResponses,
            expectedResponses = expectedResponses
        })
        
        self:AnnounceEvent("ORGANIZER_PLAYER_UPDATED", {
            playerID = playerID,
            updates = {
                specPreferences = response.specPreferences,
                specDetails = response.specDetails,
                surveyResponse = playerData.surveyResponse
            },
            playerData = playerData,
            updateType = "poll_response"
        })
    end, "OrganizerState:UpdatePlayerFromPollResponse")
end

--- Remove player from state entirely
-- @param playerID string - Player identifier
-- @return boolean - True if player was removed, false if not found
-- @usage OrganizerState:RemovePlayer("PlayerName-Realm")
function OrganizerState:RemovePlayer(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        local existed = self.players[playerID] ~= nil
        
        -- Remove from players table
        self.players[playerID] = nil
        
        -- Remove from location tracking
        self.bench[playerID] = nil
        self.optOut[playerID] = nil
        
        -- Remove from group assignments
        for groupIndex, slots in pairs(self.groups) do
            for slotIndex, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    self.groups[groupIndex][slotIndex] = nil
                end
            end
        end
        
        Debug:Dev("organizer_state", "RemovePlayer:", playerID, "- removed:", existed)
        return existed
        
    end, "OrganizerState:RemovePlayer")
end

--- Get all players in state
-- @return table - Array of all player data objects
-- @usage local allPlayers = OrganizerState:GetAllPlayers()
function OrganizerState:GetAllPlayers()
    return NextKey222.SafeRun(function()
        local players = {}
        
        for playerID, playerData in pairs(self.players) do
            table.insert(players, playerData)
        end
        
        return players
    end, "OrganizerState:GetAllPlayers")
end

--- Check if player exists in state
-- @param playerID string - Player identifier
-- @return boolean - True if player exists
-- @usage if OrganizerState:PlayerExists("PlayerName-Realm") then ... end
function OrganizerState:PlayerExists(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        return self.players[playerID] ~= nil
    end, "OrganizerState:PlayerExists")
end

-- MARK: Location Tracking
--- Get player's current location
-- @param playerID string - Player identifier
-- @return string|table - "bench", "opt_out", or {type="role_slot", groupIndex=N, slotIndex=N}
-- @usage local location = OrganizerState:GetPlayerLocation("PlayerName-Realm")
function OrganizerState:GetPlayerLocation(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return nil
        end
        
        -- Check bench
        if self.bench[playerID] then
            return "bench"
        end
        
        -- Check opt-out
        if self.optOut[playerID] then
            return "opt_out"
        end
        
        -- Check group slots
        for groupIndex, slots in pairs(self.groups) do
            for slotIndex, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    return {
                        type = "role_slot",
                        groupIndex = groupIndex,
                        slotIndex = slotIndex
                    }
                end
            end
        end
        
        return nil
    end, "OrganizerState:GetPlayerLocation")
end

--- Move player to bench
-- @param playerID string - Player identifier
-- @return boolean - True if successful
-- @usage OrganizerState:MoveToBench("PlayerName-Realm")
function OrganizerState:MoveToBench(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        -- Capture previous location
        local fromLocation = self:GetPlayerLocation(playerID)
        
        -- Remove from other locations
        self.optOut[playerID] = nil
        
        for groupIndex, slots in pairs(self.groups) do
            for slotIndex, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    self.groups[groupIndex][slotIndex] = nil
                end
            end
        end
        
        -- Add to bench
        self.bench[playerID] = true
        
        Debug:Dev("organizer_state", "MoveToBench:", playerID)
        
        -- EVENT: Announce player moved
        local playerData = self.players[playerID]
        if playerData then
            self:AnnounceEvent("ORGANIZER_PLAYER_MOVED", {
                playerID = playerID,
                fromLocation = fromLocation,
                toLocation = "bench",
                playerData = playerData,
                reason = "manual"
            })
        end
        
        return true
    end, "OrganizerState:MoveToBench")
end

--- Move player to opt-out list
-- @param playerID string - Player identifier
-- @return boolean - True if successful
-- @usage OrganizerState:MoveToOptOut("PlayerName-Realm")
function OrganizerState:MoveToOptOut(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        -- Capture previous location
        local fromLocation = self:GetPlayerLocation(playerID)
        
        -- Remove from other locations
        self.bench[playerID] = nil
        
        for groupIndex, slots in pairs(self.groups) do
            for slotIndex, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    self.groups[groupIndex][slotIndex] = nil
                end
            end
        end
        
        -- Add to opt-out
        self.optOut[playerID] = true
        
        Debug:Dev("organizer_state", "MoveToOptOut:", playerID)
        
        -- EVENT: Announce player moved
        local playerData = self.players[playerID]
        if playerData then
            self:AnnounceEvent("ORGANIZER_PLAYER_MOVED", {
                playerID = playerID,
                fromLocation = fromLocation,
                toLocation = "opt_out",
                playerData = playerData,
                reason = "manual"
            })
        end
        
        return true
    end, "OrganizerState:MoveToOptOut")
end

--- Move player to group slot
-- @param playerID string - Player identifier
-- @param groupIndex number - Group number (1-4)
-- @param slotIndex number - Slot number (1-5)
-- @return boolean - True if successful
-- @usage OrganizerState:MoveToSlot("PlayerName-Realm", 1, 2)
function OrganizerState:MoveToSlot(playerID, groupIndex, slotIndex)
    return NextKey222.SafeRun(function()
        if not playerID or not groupIndex or not slotIndex then
            return false
        end
        
        -- Capture previous location
        local fromLocation = self:GetPlayerLocation(playerID)
        
        -- Remove from other locations
        self.bench[playerID] = nil
        self.optOut[playerID] = nil
        
        -- Remove from any other slot
        for gIdx, slots in pairs(self.groups) do
            for sIdx, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    self.groups[gIdx][sIdx] = nil
                end
            end
        end
        
        -- Initialize group if needed
        if not self.groups[groupIndex] then
            self.groups[groupIndex] = {}
        end
        
        -- Assign to slot
        self.groups[groupIndex][slotIndex] = playerID
        
        Debug:Dev("organizer_state", "MoveToSlot:", playerID, "to group", groupIndex, "slot", slotIndex)
        Debug:User("IN-MEMORY ASSIGNMENT:", groupIndex, "slot", slotIndex, "=", playerID)
        
        -- Verify assignment succeeded
        local verifyAssignment = self.groups[groupIndex] and self.groups[groupIndex][slotIndex]
        Debug:User("VERIFY IN-MEMORY:", verifyAssignment)
        
        -- Auto-save after slot assignment
        Debug:User("AUTO-SAVE TRIGGERED for", playerID, "in group", groupIndex, "slot", slotIndex)
        self:SaveToPersistence()
        Debug:User("AUTO-SAVE COMPLETED")
        
        -- Verify state after save
        local totalSlots = 0
        for gIdx, slots in pairs(self.groups) do
            for sIdx, pID in pairs(slots) do
                totalSlots = totalSlots + 1
            end
        end
        Debug:User("AFTER SAVE - Total slots in memory:", totalSlots)
        
        -- EVENT: Announce player moved
        local playerData = self.players[playerID]
        if playerData then
            local toLocation = {
                type = "role_slot",
                groupIndex = groupIndex,
                slotIndex = slotIndex
            }
            self:AnnounceEvent("ORGANIZER_PLAYER_MOVED", {
                playerID = playerID,
                fromLocation = fromLocation,
                toLocation = toLocation,
                playerData = playerData,
                reason = "manual"
            })
        end
        
        return true
    end, "OrganizerState:MoveToSlot")
end

--- Get all players on bench
-- @return table - Array of playerIDs on bench
-- @usage local benchPlayers = OrganizerState:GetBenchPlayers()
function OrganizerState:GetBenchPlayers()
    return NextKey222.SafeRun(function()
        local players = {}
        
        for playerID, _ in pairs(self.bench) do
            table.insert(players, playerID)
        end
        
        return players
    end, "OrganizerState:GetBenchPlayers")
end

--- Get all players in opt-out list
-- @return table - Array of playerIDs who opted out
-- @usage local optOutPlayers = OrganizerState:GetOptOutPlayers()
function OrganizerState:GetOptOutPlayers()
    return NextKey222.SafeRun(function()
        local players = {}
        
        for playerID, _ in pairs(self.optOut) do
            table.insert(players, playerID)
        end
        
        return players
    end, "OrganizerState:GetOptOutPlayers")
end

--- Get all players in a specific group
-- @param groupIndex number - Group number (1-4)
-- @return table - Array of {slotIndex, playerID} pairs
-- @usage local groupPlayers = OrganizerState:GetSlotPlayers(1)
function OrganizerState:GetSlotPlayers(groupIndex)
    return NextKey222.SafeRun(function()
        local players = {}
        
        if not groupIndex or not self.groups[groupIndex] then
            return players
        end
        
        for slotIndex, playerID in pairs(self.groups[groupIndex]) do
            table.insert(players, {
                slotIndex = slotIndex,
                playerID = playerID
            })
        end
        
        return players
    end, "OrganizerState:GetSlotPlayers")
end

-- MARK: Group Management
--- Assign player to specific group slot
-- @param playerID string - Player identifier
-- @param groupIndex number - Group number (1-4)
-- @param slotIndex number - Slot number (1-5)
-- @return boolean - True if successful
-- @usage OrganizerState:AssignToGroup("PlayerName-Realm", 1, 2)
function OrganizerState:AssignToGroup(playerID, groupIndex, slotIndex)
    return NextKey222.SafeRun(function()
        if not playerID or not groupIndex or not slotIndex then
            Debug:Error("AssignToGroup called with missing arguments")
            return false
        end
        
        -- Initialize group if needed
        if not self.groups[groupIndex] then
            self.groups[groupIndex] = {}
        end
        
        -- Assign to slot
        self.groups[groupIndex][slotIndex] = playerID
        
        Debug:Dev("organizer_state", "AssignToGroup:", playerID, "to group", groupIndex, "slot", slotIndex)
        return true
    end, "OrganizerState:AssignToGroup")
end

--- Remove player from their current group slot
-- @param playerID string - Player identifier
-- @return boolean - True if player was in a group and removed
-- @usage OrganizerState:UnassignFromGroup("PlayerName-Realm")
function OrganizerState:UnassignFromGroup(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        local wasInGroup = false
        
        -- Remove from all group slots
        for groupIndex, slots in pairs(self.groups) do
            for slotIndex, assignedPlayerID in pairs(slots) do
                if assignedPlayerID == playerID then
                    self.groups[groupIndex][slotIndex] = nil
                    wasInGroup = true
                end
            end
        end
        
        Debug:Dev("organizer_state", "UnassignFromGroup:", playerID, "- was in group:", wasInGroup)
        return wasInGroup
    end, "OrganizerState:UnassignFromGroup")
end

--- Get all slot assignments for a group
-- @param groupIndex number - Group number (1-4)
-- @return table - {[slotIndex] = playerID} map
-- @usage local assignments = OrganizerState:GetGroupAssignments(1)
function OrganizerState:GetGroupAssignments(groupIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex then
            return {}
        end
        
        Debug:Dev("organizer_state", "GetGroupAssignments: group", groupIndex)
        return self.groups[groupIndex] or {}
    end, "OrganizerState:GetGroupAssignments")
end

--- Get player assigned to specific slot
-- @param groupIndex number - Group number (1-4)
-- @param slotIndex number - Slot number (1-5)
-- @return string|nil - PlayerID or nil if slot empty
-- @usage local playerID = OrganizerState:GetSlotPlayer(1, 2)
function OrganizerState:GetSlotPlayer(groupIndex, slotIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex or not slotIndex then
            return nil
        end
        
        if not self.groups[groupIndex] then
            return nil
        end
        
        local playerID = self.groups[groupIndex][slotIndex]
        Debug:Dev("organizer_state", "GetSlotPlayer: group", groupIndex, "slot", slotIndex, "->", playerID)
        return playerID
    end, "OrganizerState:GetSlotPlayer")
end

--- Check if a slot is empty
-- @param groupIndex number - Group number (1-4)
-- @param slotIndex number - Slot number (1-5)
-- @return boolean - True if slot is empty
-- @usage if OrganizerState:IsSlotEmpty(1, 2) then ... end
function OrganizerState:IsSlotEmpty(groupIndex, slotIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex or not slotIndex then
            return true
        end
        
        if not self.groups[groupIndex] then
            return true
        end
        
        local isEmpty = self.groups[groupIndex][slotIndex] == nil
        Debug:Dev("organizer_state", "IsSlotEmpty: group", groupIndex, "slot", slotIndex, "->", isEmpty)
        return isEmpty
    end, "OrganizerState:IsSlotEmpty")
end

-- MARK: Keystone Management
--- Designate a keystone for a group
-- @param groupIndex number - Group number (1-4)
-- @param playerID string - Player who owns the keystone
-- @param keystone table - Keystone data {dungeonID, level, ...}
-- @return boolean - True if successful
-- @usage OrganizerState:DesignateKeystone(1, "PlayerName-Realm", keystoneData)
function OrganizerState:DesignateKeystone(groupIndex, playerID, keystone)
    return NextKey222.SafeRun(function()
        if not groupIndex or not playerID or not keystone then
            Debug:Error("DesignateKeystone called with missing arguments")
            return false
        end
        
        -- Store keystone designation
        self.keystones[groupIndex] = {
            keystone = keystone,
            playerID = playerID
        }
        
        Debug:Dev("organizer_state", "DesignateKeystone: group", groupIndex, "keystone from", playerID)
        return true
    end, "OrganizerState:DesignateKeystone")
end

--- Clear designated keystone for a group
-- @param groupIndex number - Group number (1-4)
-- @return boolean - True if keystone was cleared
-- @usage OrganizerState:ClearKeystone(1)
function OrganizerState:ClearKeystone(groupIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex then
            return false
        end
        
        local hadKeystone = self.keystones[groupIndex] ~= nil
        self.keystones[groupIndex] = nil
        
        Debug:Dev("organizer_state", "ClearKeystone: group", groupIndex, "- had keystone:", hadKeystone)
        return hadKeystone
    end, "OrganizerState:ClearKeystone")
end

--- Get designated keystone for a group
-- @param groupIndex number - Group number (1-4)
-- @return table|nil - {keystone, playerID} or nil if no keystone designated
-- @usage local keystoneData = OrganizerState:GetDesignatedKeystone(1)
function OrganizerState:GetDesignatedKeystone(groupIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex then
            return nil
        end
        
        local keystoneData = self.keystones[groupIndex]
        Debug:Dev("organizer_state", "GetDesignatedKeystone: group", groupIndex, "->", keystoneData ~= nil)
        return keystoneData
    end, "OrganizerState:GetDesignatedKeystone")
end

--- Get player who owns the designated keystone for a group
-- @param groupIndex number - Group number (1-4)
-- @return string|nil - PlayerID or nil if no keystone designated
-- @usage local ownerID = OrganizerState:GetKeystoneOwner(1)
function OrganizerState:GetKeystoneOwner(groupIndex)
    return NextKey222.SafeRun(function()
        if not groupIndex then
            return nil
        end
        
        local keystoneData = self.keystones[groupIndex]
        local ownerID = keystoneData and keystoneData.playerID or nil
        
        Debug:Dev("organizer_state", "GetKeystoneOwner: group", groupIndex, "->", ownerID)
        return ownerID
    end, "OrganizerState:GetKeystoneOwner")
end

-- MARK: Poll Management
--- Start a new poll
-- @param pollID string - Unique poll identifier
-- @return boolean - True if poll started successfully
-- @usage OrganizerState:StartPoll("1234567890-5678")
function OrganizerState:StartPoll(pollID)
    return NextKey222.SafeRun(function()
        if not pollID then
            Debug:Error("StartPoll called with nil pollID")
            return false
        end
        
        -- Warn if poll already active
        if self.activePoll then
            Debug:Dev("organizer_state", "StartPoll: Warning - overwriting active poll", self.activePoll.id)
        end
        
        -- Initialize poll state
        self.activePoll = {
            id = pollID,
            startTime = GetTime(),
            responses = {},
            timeout = 60
        }
        
        Debug:Dev("organizer_state", "StartPoll:", pollID)
        return true
    end, "OrganizerState:StartPoll")
end

--- Add a poll response
-- @param playerID string - Player identifier
-- @param response table - Poll response data
-- @return boolean - True if response added
-- @usage OrganizerState:AddPollResponse("PlayerName-Realm", responseData)
function OrganizerState:AddPollResponse(playerID, response)
    return NextKey222.SafeRun(function()
        if not playerID or not response then
            Debug:Error("AddPollResponse called with missing arguments")
            return false
        end
        
        if not self.activePoll then
            Debug:Error("AddPollResponse called but no active poll")
            return false
        end
        
        -- Store response in active poll
        self.activePoll.responses[playerID] = {
            response = response,
            timestamp = GetTime()
        }
        
        -- CRITICAL: Update player data to prevent data loss
        self:UpdatePlayerFromPollResponse(playerID, response)
        
        local responseCount = 0
        for _ in pairs(self.activePoll.responses) do
            responseCount = responseCount + 1
        end
        
        Debug:Dev("organizer_state", "AddPollResponse:", playerID, "- total responses:", responseCount)
        return true
    end, "OrganizerState:AddPollResponse")
end

--- Get all poll responses
-- @return table - Array of {playerID, response, timestamp} entries
-- @usage local responses = OrganizerState:GetPollResponses()
function OrganizerState:GetPollResponses()
    return NextKey222.SafeRun(function()
        if not self.activePoll then
            Debug:Dev("organizer_state", "GetPollResponses: No active poll")
            return {}
        end
        
        local responses = {}
        
        for playerID, data in pairs(self.activePoll.responses) do
            table.insert(responses, {
                playerID = playerID,
                response = data.response,
                timestamp = data.timestamp
            })
        end
        
        Debug:Dev("organizer_state", "GetPollResponses: returning", #responses, "responses")
        return responses
    end, "OrganizerState:GetPollResponses")
end

--- Complete the active poll
-- @return boolean - True if poll was active and completed
-- @usage OrganizerState:CompletePoll()
function OrganizerState:CompletePoll()
    return NextKey222.SafeRun(function()
        local wasActive = self.activePoll ~= nil
        
        if wasActive then
            Debug:Dev("organizer_state", "CompletePoll: Completing poll", self.activePoll.id)
        end
        
        self.activePoll = nil
        
        Debug:Dev("organizer_state", "CompletePoll: was active:", wasActive)
        return wasActive
    end, "OrganizerState:CompletePoll")
end

-- MARK: Persistence (SESSION 4: Hybrid Approach)
--- Check if a player is a fake player (debug only)
-- Fake players match patterns: "NNN-NNNNFP-Realm" or "AltNNN-NNNNFP-Realm"
-- @param playerID string - Player identifier
-- @return boolean - True if player is a fake player
-- @usage if OrganizerState:IsFakePlayer(playerID) then ... end
function OrganizerState:IsFakePlayer(playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return false
        end
        
        -- Fake player patterns (from FakePlayerService):
        -- CORRECT patterns that won't match real players:
        -- 1. "Alt[digits]FP" (e.g., "Alt12FP", "Alt03FP") - ends with digits+FP
        -- 2. "[digits]-[digits]FP-[Realm]" (e.g., "123-4567FP-Dalaran") - has FP before realm
        --
        -- IMPORTANT: Real players like "07FP-Dalaran" or "19FP-Dalaran" are NOT fake players!
        -- They just have "FP" in their name coincidentally.
        --
        -- The key distinction: Fake players have "FP" IMMEDIATELY BEFORE the realm separator
        -- or at the very end (for Alt players), while real players have more characters after "FP".
        
        -- Pattern 1: Alt prefix fake players (e.g., "Alt12FP", "Alt03FP")
        -- Must end with Alt + digits + FP (no realm separator)
        local isAltFake = playerID:match("^Alt%d+FP$")
        
        -- Pattern 2: Numeric fake players with realm (e.g., "123-4567FP-Dalaran")
        -- Must have digits + FP immediately before the realm separator (hyphen)
        -- This specifically looks for: digits, then "FP-", then realm name
        local isNumericFake = playerID:match("%d+FP%-[%w]+$")
        
        local isFake = (isAltFake or isNumericFake) ~= nil
        
        if isFake then
            Debug:Dev("organizer_state", "IsFakePlayer: FAKE -", playerID)
        end
        
        return isFake
        
    end, "OrganizerState:IsFakePlayer")
end

--- Save state to SavedVariables (filters out fake players)
-- Only real players persist across /reload and logout
-- @usage OrganizerState:SaveToPersistence()
function OrganizerState:SaveToPersistence()
    return NextKey222.SafeRun(function()
        -- Validate database access (use NextKey.db, not NextKey222.db)
        local db_ref = NextKey222.Addon and NextKey222.Addon.db or NextKey.db
        if not db_ref or not db_ref.char then
            Debug:Dev("organizer_state", "Cannot save state - database not yet available (will retry later)")
            return false
        end
        
        -- Initialize organizerState if needed
        if not db_ref.char.organizerState then
            db_ref.char.organizerState = {
                players = {},
                groups = {},
                keystones = {},
                optOut = {},
                lastPoll = nil
            }
        end
        
        local db = db_ref.char.organizerState
        
        -- TESTING MODE: Save ALL players (including fake players for testing)
        local savedPlayersCount = 0
        
        db.players = {}
        for playerID, playerData in pairs(self.players) do
            db.players[playerID] = playerData
            savedPlayersCount = savedPlayersCount + 1
            Debug:Dev("organizer_state", "Saving player:", playerID)
        end
        
        -- Save ALL groups (including fake players for testing)
        db.groups = {}
        local savedGroupSlots = 0
        for groupIndex, slots in pairs(self.groups) do
            db.groups[groupIndex] = {}
            for slotIndex, playerID in pairs(slots) do
                db.groups[groupIndex][slotIndex] = playerID
                savedGroupSlots = savedGroupSlots + 1
                Debug:Dev("organizer_state", "Saving group assignment:", groupIndex, "slot", slotIndex, "->", playerID)
            end
        end
        
        -- Save ALL keystones (including fake players for testing)
        db.keystones = {}
        for groupIndex, keystoneData in pairs(self.keystones) do
            if keystoneData and keystoneData.playerID then
                db.keystones[groupIndex] = keystoneData
            end
        end
        
        -- Save ALL opt-out status (including fake players for testing)
        db.optOut = {}
        for playerID, _ in pairs(self.optOut) do
            db.optOut[playerID] = true
        end
        
        -- Save poll metadata
        db.lastPoll = self.activePoll
        
        Debug:Dev("organizer_state", "SaveToPersistence: Saved", savedPlayersCount, "players and", savedGroupSlots, "group slot assignments")
        
        return true
        
    end, "OrganizerState:SaveToPersistence")
end

--- Load state from SavedVariables
-- Restores real player data on addon load
-- @usage OrganizerState:LoadFromPersistence()
function OrganizerState:LoadFromPersistence()
    return NextKey222.SafeRun(function()
        -- Validate database access (use NextKey.db, not NextKey222.db)
        local db_ref = NextKey222.Addon and NextKey222.Addon.db or NextKey.db
        if not db_ref or not db_ref.char or not db_ref.char.organizerState then
            Debug:Dev("organizer_state", "LoadFromPersistence: No persisted data found")
            return false
        end
        
        local db = db_ref.char.organizerState
        
        -- CRITICAL FIX: Restore groups FIRST to know which players should NOT be on bench
        if db.groups then
            for groupIndex, slots in pairs(db.groups) do
                self.groups[groupIndex] = {}
                for slotIndex, playerID in pairs(slots) do
                    self.groups[groupIndex][slotIndex] = playerID
                end
            end
        end
        
        -- Restore players and assign to correct locations
        local restoredCount = 0
        if db.players then
            for playerID, playerData in pairs(db.players) do
                self.players[playerID] = playerData
                
                -- Check if player is in a group slot (check ALL groups)
                local isInGroup = false
                for groupIndex, slots in pairs(self.groups) do
                    for slotIndex, assignedPlayerID in pairs(slots) do
                        if assignedPlayerID == playerID then
                            isInGroup = true
                            break
                        end
                    end
                    if isInGroup then break end
                end
                
                -- Only add to bench if NOT in a group (groups and opt-out restored separately)
                if not isInGroup then
                    self.bench[playerID] = true
                end
                
                restoredCount = restoredCount + 1
            end
        end
        
        -- Restore keystones
        if db.keystones then
            for groupIndex, keystoneData in pairs(db.keystones) do
                self.keystones[groupIndex] = keystoneData
            end
        end
        
        -- SESSION 4 FIX: Restore opt-out status
        if db.optOut then
            for playerID, _ in pairs(db.optOut) do
                self.optOut[playerID] = true
                -- Remove from bench if they opted out
                self.bench[playerID] = nil
            end
        end
        
        -- Restore poll state
        self.activePoll = db.lastPoll
        
        Debug:Dev("organizer_state", "LoadFromPersistence: Restored", restoredCount, "players from SavedVariables")
        
        return true
        
    end, "OrganizerState:LoadFromPersistence")
end

--- Clear all persisted data (for "Clear Poll" button)
-- @usage OrganizerState:ClearPersistedData()
function OrganizerState:ClearPersistedData()
    return NextKey222.SafeRun(function()
        -- Capture data before clearing
        local clearedData = {
            playerCount = 0,
            benchCount = 0,
            optOutCount = 0,
            groupCount = 0,
            keystoneCount = 0,
            hadActivePoll = self.activePoll ~= nil
        }
        
        for _ in pairs(self.players) do clearedData.playerCount = clearedData.playerCount + 1 end
        for _ in pairs(self.bench) do clearedData.benchCount = clearedData.benchCount + 1 end
        for _ in pairs(self.optOut) do clearedData.optOutCount = clearedData.optOutCount + 1 end
        for _ in pairs(self.groups) do clearedData.groupCount = clearedData.groupCount + 1 end
        for _ in pairs(self.keystones) do clearedData.keystoneCount = clearedData.keystoneCount + 1 end
        
        -- Clear in-memory state
        self.players = {}
        self.bench = {}
        self.optOut = {}
        self.groups = {}
        self.keystones = {}
        self.activePoll = nil
        
        -- Clear SavedVariables (use NextKey.db, not NextKey222.db)
        local db_ref = NextKey222.Addon and NextKey222.Addon.db or NextKey.db
        if db_ref and db_ref.char and db_ref.char.organizerState then
            db_ref.char.organizerState = {
                players = {},
                groups = {},
                keystones = {},
                optOut = {},
                lastPoll = nil
            }
        end
        
        Debug:User("Poll data cleared successfully")
        Debug:Dev("organizer_state", "ClearPersistedData: All state cleared")
        
        -- EVENT: Announce state cleared
        self:AnnounceEvent("ORGANIZER_STATE_CLEARED", {
            reason = "manual_clear",
            clearedData = clearedData
        })
        
        return true
        
    end, "OrganizerState:ClearPersistedData")
end

-- MARK: Debug/Utilities
--- Print current state for diagnostics
-- @usage OrganizerState:PrintState()
function OrganizerState:PrintState()
    return NextKey222.SafeRun(function()
        print("=== OrganizerState Dump ===")
        
        -- Count players
        local playerCount = 0
        for _ in pairs(self.players) do
            playerCount = playerCount + 1
        end
        print("Players: " .. playerCount)
        
        -- Count bench
        local benchCount = 0
        for _ in pairs(self.bench) do
            benchCount = benchCount + 1
        end
        print("Bench: " .. benchCount)
        
        -- Count opt-out
        local optOutCount = 0
        for _ in pairs(self.optOut) do
            optOutCount = optOutCount + 1
        end
        print("Opt-Out: " .. optOutCount)
        
        -- Count groups
        local groupCount = 0
        for _ in pairs(self.groups) do
            groupCount = groupCount + 1
        end
        print("Groups: " .. groupCount)
        
        -- Active poll
        if self.activePoll then
            print("Active Poll: " .. self.activePoll.id)
        else
            print("No active poll")
        end
        
        print("=========================")
        
    end, "OrganizerState:PrintState")
end