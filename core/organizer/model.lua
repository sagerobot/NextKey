-- core/organizer/model.lua
-- The Single Source of Truth for the Organizer feature.
-- Manages players and their assignments (Bench, Opt-Out, Slots).

local _, NextKey222 = ...

local Model = {}
NextKey222.OrganizerModel = Model

-- Event Handling
local EventRegistry = CreateFrame("Frame")
Model.EventRegistry = EventRegistry

-- Constants
local EVENT_UPDATE = "NEXTKEY_ORGANIZER_UPDATE"

-- State
Model.players = {}      -- {[playerID] = PlayerData}
Model.assignments = {}  -- {[playerID] = Location}
Model.keystones = {}    -- {[groupIndex] = {keystone, playerID}}
-- Location Schema:
-- { type = "bench" }
-- { type = "opt_out" }
-- { type = "slot", groupIndex = 1, slotIndex = 1 }

-- Logging
local function Log(msg, ...)
    if NextKey222.Debug then
        NextKey222.Debug:Dev("organizer_model", string.format(msg, ...))
    end
end

-- MARK: Public API

--- Initialize the model (load data)
function Model:Initialize()
    self:Load()
    Log("Model initialized")
end

--- Get a player's data
-- @param playerID string
-- @return table|nil PlayerData
function Model:GetPlayer(playerID)
    return self.players[playerID]
end

--- Get all players
-- @return table {[playerID] = PlayerData}
function Model:GetAllPlayers()
    return self.players
end

--- Get a player's assignment
-- @param playerID string
-- @return table Location
function Model:GetAssignment(playerID)
    return self.assignments[playerID] or { type = "bench" } -- Default to bench
end

--- Update or add a player
-- @param playerID string
-- @param data table PlayerData
function Model:SetPlayer(playerID, data)
    if not playerID or not data then return end
    
    self.players[playerID] = data
    
    -- If no assignment exists, default to bench
    if not self.assignments[playerID] then
        self.assignments[playerID] = { type = "bench" }
    end
    
    self:FireUpdate("player", playerID)
    self:Save()
end

--- Set a player's assignment (Move)
-- @param playerID string
-- @param location table {type=..., groupIndex=..., slotIndex=...}
function Model:SetAssignment(playerID, location)
    if not playerID or not location then return end
    if not self.players[playerID] then
        Log("Error: Cannot assign unknown player %s", playerID)
        return
    end
    
    -- Validate location
    if location.type == "slot" then
        if not location.groupIndex or not location.slotIndex then
            Log("Error: Invalid slot location for %s", playerID)
            return
        end
        
        -- Check if slot is occupied (swap logic could go here, but for now we overwrite/clobber)
        -- Ideally, the controller handles swaps. The model just does what it's told.
        -- However, to enforce consistency, we should probably clear the previous owner of this slot.
        local previousOwner = self:GetPlayerInSlot(location.groupIndex, location.slotIndex)
        if previousOwner and previousOwner ~= playerID then
            Log("Slot occupied by %s, moving them to bench", previousOwner)
            self:SetAssignment(previousOwner, { type = "bench" })
        end
    end
    
    self.assignments[playerID] = location
    
    Log("Assigned %s to %s", playerID, location.type)
    self:FireUpdate("assignment", playerID)
    self:Save()
end

--- Get the player assigned to a specific slot
-- @param groupIndex number
-- @param slotIndex number
-- @return string|nil playerID
function Model:GetPlayerInSlot(groupIndex, slotIndex)
    for playerID, loc in pairs(self.assignments) do
        if loc.type == "slot" and loc.groupIndex == groupIndex and loc.slotIndex == slotIndex then
            return playerID
        end
    end
    return nil
end

--- Get all players in a specific group
-- @param groupIndex number
-- @return table { [slotIndex] = playerID }
function Model:GetGroup(groupIndex)
    local group = {}
    for playerID, loc in pairs(self.assignments) do
        if loc.type == "slot" and loc.groupIndex == groupIndex then
            group[loc.slotIndex] = playerID
        end
    end
    return group
end

--- Get all players on the bench
-- @return table { playerID, ... }
function Model:GetBench()
    local bench = {}
    for playerID, loc in pairs(self.assignments) do
        if loc.type == "bench" then
            table.insert(bench, playerID)
        end
    end
    return bench
end

--- Get all opted-out players
-- @return table { playerID, ... }
function Model:GetOptOut()
    local optOut = {}
    for playerID, loc in pairs(self.assignments) do
        if loc.type == "opt_out" then
            table.insert(optOut, playerID)
        end
    end
    return optOut
end

--- Get designated keystone for a group
-- @param groupIndex number
-- @return table|nil {keystone, playerID}
function Model:GetKeystone(groupIndex)
    return self.keystones[groupIndex]
end

--- Set designated keystone for a group
-- @param groupIndex number
-- @param data table|nil {keystone, playerID}
function Model:SetKeystone(groupIndex, data)
    self.keystones[groupIndex] = data
    self:FireUpdate("keystone", groupIndex)
    self:Save()
end

--- Remove a player completely
-- @param playerID string
function Model:RemovePlayer(playerID)
    self.players[playerID] = nil
    self.assignments[playerID] = nil
    self:FireUpdate("player", playerID)
    self:Save()
end

--- Clear all data (Reset)
function Model:Clear()
    self.players = {}
    self.assignments = {}
    self.keystones = {}
    self:FireUpdate("reset")
    self:Save()
end

--- Clear persisted data (Alias for Clear, used by UI)
function Model:ClearPersistedData()
    self:Clear()
end

--- Update player data from a poll response
-- @param playerID string
-- @param response table Poll response data
function Model:UpdatePlayerFromPollResponse(playerID, response)
    if not playerID or not response then return end
    
    local data = self.players[playerID] or { id = playerID }
    
    -- Update basic info if provided
    if response.characterData then
        data.name = response.characterData.name or data.name
        data.class = response.characterData.class or data.class
        data.overallScore = response.characterData.io or data.overallScore
        data.itemLevel = response.characterData.itemLevel or data.itemLevel
        
        -- Update keystone if provided
        if response.characterData.keystone then
            data.keystone = response.characterData.keystone
        end
    end
    
    -- Update spec preferences
    if response.specPreferences then
        data.specPreferences = response.specPreferences
    end
    
    -- Update spec details
    if response.specDetails then
        data.specDetails = response.specDetails
    end
    
    self:SetPlayer(playerID, data)
end

--- Save to persistence (Alias for Save, used by UI)
function Model:SaveToPersistence()
    self:Save()
    return true
end

-- MARK: Persistence

function Model:Save()
    if not NextKey222_DB then NextKey222_DB = {} end
    NextKey222_DB.OrganizerModel = {
        players = self.players,
        assignments = self.assignments,
        keystones = self.keystones
    }
end

function Model:Load()
    if NextKey222_DB and NextKey222_DB.OrganizerModel then
        self.players = NextKey222_DB.OrganizerModel.players or {}
        self.assignments = NextKey222_DB.OrganizerModel.assignments or {}
        self.keystones = NextKey222_DB.OrganizerModel.keystones or {}
    else
        self.players = {}
        self.assignments = {}
        self.keystones = {}
    end
end

-- MARK: Events

--- Register a callback for updates
-- @param callback function(event, payload)
function Model:RegisterCallback(callback)
    -- Simple callback registry
    if not self.callbacks then self.callbacks = {} end
    table.insert(self.callbacks, callback)
end

--- Fire an update event
-- @param type string "player" | "assignment" | "reset"
-- @param id string|nil
function Model:FireUpdate(type, id)
    local payload = { type = type, id = id }
    
    -- Notify internal callbacks
    if self.callbacks then
        for _, cb in ipairs(self.callbacks) do
            cb(EVENT_UPDATE, payload)
        end
    end
    
    -- Fire global AceEvent if needed (optional, but good for decoupling)
    -- NextKey222:SendMessage(EVENT_UPDATE, payload)
end
