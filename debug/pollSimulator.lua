-- MARK: Poll Simulator
-- Debug module for simulating poll responses without requiring a real group
-- Enables testing of the M+ Group Organizer survey system with fake players

local _, NextKey222 = ...

-- MARK: Module Definition
local PollSimulator = {}
NextKey222.PollSimulator = PollSimulator

-- Register with module system
NextKey222.RegisterModule("PollSimulator", PollSimulator)

-- MARK: Module State
local isInitialized = false
local activeSimulation = nil
local simulationTimer = nil

-- MARK: Constants
local RESPONSE_PATTERNS = {
    instant = {
        name = "Instant",
        description = "All responses within 0-2 seconds",
        minDelay = 0,
        maxDelay = 2,
        optInRate = 0.70,    -- 70% opt-in
        optOutRate = 0.20,   -- 20% opt-out
        timeoutRate = 0.10   -- 10% timeout
    },
    realistic = {
        name = "Realistic",
        description = "Staggered responses over 0-60 seconds",
        minDelay = 0,
        maxDelay = 60,
        optInRate = 0.70,
        optOutRate = 0.20,
        timeoutRate = 0.10
    }
}

-- MARK: Utility Functions

local function generateAltName(parentName)
    -- NEW: Use Alt01FP, Alt02FP format to match new naming scheme
    -- Extract the number from the parent name (e.g., "01FP" -> "01")
    local baseName = parentName:match("^([^%-]+)")
    if baseName:match("^%d+FP$") then
        -- It's a numbered fake player - use Alt prefix
        return "Alt" .. baseName
    else
        -- Real player or other format - use legacy format
        return baseName .. "Alt"
    end
end

local function getRandomResponse(pattern)
    local rand = math.random()
    if rand < pattern.optInRate then
        return "opt_in", false  -- opt-in, not an alt
    elseif rand < (pattern.optInRate + pattern.optOutRate) then
        return "opt_out", false
    else
        return "timeout", false
    end
end

local function getRandomAltResponse(pattern)
    -- 30% chance of selecting alt instead of main when opting in
    local rand = math.random()
    if rand < pattern.optInRate then
        if math.random() < 0.3 then
            return "opt_in", true  -- opt-in with alt
        else
            return "opt_in", false  -- opt-in with main
        end
    elseif rand < (pattern.optInRate + pattern.optOutRate) then
        return "opt_out", false
    else
        return "timeout", false
    end
end

-- MARK: Response Simulation

local function generateSpecPreferences(playerData)
    -- Generate realistic spec preferences based on player's role
    local specPreferences = {}
    local specDetails = {}  -- NEW: Track spec-level details for tooltips
    
    -- CRITICAL FIX: Use OrganizerPlayerDataBuilder to generate REALISTIC POLL RESPONSE
    -- NOT default spec preferences (which are for pre-poll display only)
    if NextKey222.OrganizerPlayerDataBuilder and
       NextKey222.OrganizerPlayerDataBuilder.GenerateRealisticPollResponse then
        
        -- CRITICAL: playerData.name is ALREADY in "Name-Realm" format for fake players
        -- Don't append realm again or we get "01FP-Dalaran-Dalaran"
        local characterID = playerData.name
        local success, specPrefs, specDets = NextKey222.OrganizerPlayerDataBuilder:GenerateRealisticPollResponse(characterID)
        
        if success and specPrefs and specDets then
            NextKey222.Debug:Dev("organizer", "Poll: Generated REALISTIC poll response for", characterID, "using OrganizerPlayerDataBuilder")
            return specPrefs, specDets
        else
            NextKey222.Debug:Error("Poll: Failed to generate realistic poll response for", characterID, "- falling back to simple generation")
        end
    end
    
    -- FALLBACK: If OrganizerPlayerDataBuilder fails, use simple role generation
    -- This path should rarely be used now
    if true then
        local classRoles = {}
        if NextKey222.CharacterStorage then
            classRoles = NextKey222.CharacterStorage:GetClassRoles(playerData.class)
        end
        
        if #classRoles == 0 then
            classRoles = {playerData.role or "DAMAGER"}
        end
        
        -- Generate simple role preferences without spec details
        for _, role in ipairs(classRoles) do
            local rand = math.random()
            if role == playerData.role then
                specPreferences[role] = rand < 0.70 and "play" or (rand < 0.90 and "fill" or "none")
            else
                specPreferences[role] = rand < 0.30 and "play" or (rand < 0.70 and "fill" or "none")
            end
        end
        
        return specPreferences, specDetails
    end
    
    -- Generate spec-level preferences (matching surveyDialog.lua logic)
    local priorityMap = { play = 3, fill = 2, none = 1 }
    
    for _, specInfo in ipairs(availableSpecs) do
        local rand = math.random()
        local preference = "none"
        
        -- Primary role/spec: 70% will play, 20% fill, 10% none
        if specInfo.role == playerData.role then
            if rand < 0.70 then
                preference = "play"
            elseif rand < 0.90 then
                preference = "fill"
            else
                preference = "none"
            end
        else
            -- Off-spec: 30% will play, 40% fill, 30% none
            if rand < 0.30 then
                preference = "play"
            elseif rand < 0.70 then
                preference = "fill"
            else
                preference = "none"
            end
        end
        
        -- Track spec details for tooltips
        -- CRITICAL: Normalize role to uppercase for consistent keying
        local normalizedRole = specInfo.role:upper()
        
        if not specDetails[normalizedRole] then
            specDetails[normalizedRole] = {}
        end
        table.insert(specDetails[normalizedRole], {
            specName = specInfo.specName,
            preference = preference
        })
        
        -- Store by role with priority (highest priority wins)
        if preference ~= "none" then
            local currentPriority = priorityMap[specPreferences[normalizedRole]] or 0
            local newPriority = priorityMap[preference] or 0
            
            if newPriority > currentPriority then
                specPreferences[normalizedRole] = preference
            end
        end
    end
    
    return specPreferences, specDetails
end

local function simulatePlayerResponse(playerName, responseType, useAlt, pollID)
    NextKey222.Debug:Dev("organizer", "Simulating response for", playerName, "type:", responseType, "useAlt:", useAlt)
    
    -- Get player data from FakePlayerService
    local playerData = NextKey222.FakePlayerService:GetPlayer(playerName)
    if not playerData then
        NextKey222.Debug:Error("PollSimulator: Player not found:", playerName)
        return false
    end
    
    if responseType == "timeout" then
        -- Don't send any response for timeout simulation
        NextKey222.Debug:Dev("organizer", "Player", playerName, "timed out (no response)")
        return true
    end
    
    -- Build response data
    local responseData = {
        pollID = pollID,
        participation = responseType == "opt_in" and "in" or "out",
        selectedCharacter = playerName,
        useAlt = useAlt,
        roles = { playerData.role },  -- Use player's primary role
        specPreferences = {}  -- Will be populated for opt-in responses
    }
    
    -- Generate spec preferences for opt-in responses
    if responseType == "opt_in" then
        local specPreferences, specDetails = generateSpecPreferences(playerData)
        responseData.specPreferences = specPreferences
        responseData.specDetails = specDetails  -- NEW: Include spec details for tooltips
        NextKey222.Debug:Dev("organizer", "Generated spec preferences for", playerName, ":", responseData.specPreferences)
    end
    
    -- If using alt, modify response
    if useAlt and responseType == "opt_in" then
        local altName = generateAltName(playerName)
        responseData.selectedCharacter = altName
        responseData.altOfPlayer = playerName
        
        -- Generate character data for alt (simplified)
        responseData.characterData = {
            name = altName,
            class = playerData.class,
            io = playerData.io and (playerData.io - 200) or 1000,  -- Alt has lower IO
            itemLevel = 610,
            keystone = nil
        }
        
        NextKey222.Debug:Dev("organizer", "Player", playerName, "selected alt:", altName)
    end
    
    -- Send response through survey module
    if NextKey222.ParticipantSurvey then
        -- Simulate receiving the response (bypass network)
        -- Build message structure that matches the real communication format
        local message = responseData
        NextKey222.ParticipantSurvey:OnPollResponseReceived(message, playerName)
        return true
    else
        NextKey222.Debug:Error("PollSimulator: ParticipantSurvey module not available")
        return false
    end
end

local function scheduleResponse(playerName, delay, responseType, useAlt, pollID)
    C_Timer.After(delay, function()
        NextKey222.SafeRun(function()
            simulatePlayerResponse(playerName, responseType, useAlt, pollID)
        end, "PollSimulator:ScheduleResponse")
    end)
end

-- MARK: Public API

--- Initializes the poll simulator
-- @return boolean Success status
function PollSimulator:Initialize()
    if isInitialized then
        NextKey222.Debug:Dev("organizer", "PollSimulator already initialized")
        return true
    end
    
    NextKey222.Debug:Dev("startup", "PollSimulator initializing...")
    
    local success = NextKey222.SafeRun(function()
        activeSimulation = nil
        simulationTimer = nil
        isInitialized = true
        return true
    end, "PollSimulator:Initialize")
    
    NextKey222.Debug:Dev("startup", "PollSimulator initialization", success and "successful" or "failed")
    return success
end

--- Simulates a poll with the specified pattern
-- @param patternType string "instant" or "realistic"
-- @param pollID string The poll ID to simulate responses for
-- @return boolean Success status
function PollSimulator:SimulatePoll(patternType, pollID)
    if not isInitialized then
        NextKey222.Debug:Error("PollSimulator not initialized")
        return false
    end
    
    return NextKey222.SafeRun(function()
        local pattern = RESPONSE_PATTERNS[patternType]
        if not pattern then
            NextKey222.Debug:Error("Unknown pattern type:", patternType)
            return false
        end
        
        -- Get all fake players
        local fakePlayers = NextKey222.FakePlayerService:GetAllPlayerNames()
        if #fakePlayers == 0 then
            NextKey222.Debug:Error("No fake players available for simulation")
            return false
        end
        
        NextKey222.Debug:User(string.format(
            "Starting %s poll simulation with %d players (poll ID: %s)",
            pattern.name,
            #fakePlayers,
            pollID
        ))
        
        -- Schedule responses for each player
        local scheduledCount = 0
        for _, playerName in ipairs(fakePlayers) do
            local delay = math.random() * (pattern.maxDelay - pattern.minDelay) + pattern.minDelay
            local responseType, useAlt = getRandomAltResponse(pattern)
            
            scheduleResponse(playerName, delay, responseType, useAlt, pollID)
            scheduledCount = scheduledCount + 1
            
            NextKey222.Debug:Dev("organizer", string.format(
                "Scheduled %s response for %s in %.1fs%s",
                responseType,
                playerName,
                delay,
                useAlt and " (alt)" or ""
            ))
        end
        
        NextKey222.Debug:User(string.format(
            "Scheduled %d responses (%.0f%% opt-in, %.0f%% opt-out, %.0f%% timeout)",
            scheduledCount,
            pattern.optInRate * 100,
            pattern.optOutRate * 100,
            pattern.timeoutRate * 100
        ))
        
        activeSimulation = {
            pollID = pollID,
            pattern = patternType,
            playerCount = #fakePlayers,
            startTime = GetTime()
        }
        
        return true
    end, "PollSimulator:SimulatePoll")
end

--- Simulates an instant poll (0-2 second responses)
-- @param pollID string The poll ID
-- @return boolean Success status
function PollSimulator:SimulateInstantPoll(pollID)
    return self:SimulatePoll("instant", pollID)
end

--- Simulates a realistic poll (0-60 second staggered responses)
-- @param pollID string The poll ID
-- @return boolean Success status
function PollSimulator:SimulateRealisticPoll(pollID)
    return self:SimulatePoll("realistic", pollID)
end

--- Gets the current simulation status
-- @return table|nil Status information or nil if no active simulation
function PollSimulator:GetStatus()
    if not activeSimulation then
        return nil
    end
    
    local elapsed = GetTime() - activeSimulation.startTime
    return {
        pollID = activeSimulation.pollID,
        pattern = activeSimulation.pattern,
        playerCount = activeSimulation.playerCount,
        elapsed = elapsed
    }
end

--- Clears the current simulation
function PollSimulator:Clear()
    activeSimulation = nil
    if simulationTimer then
        simulationTimer:Cancel()
        simulationTimer = nil
    end
    NextKey222.Debug:Dev("organizer", "Cleared poll simulation")
end

--- Gets available response patterns
-- @return table Array of pattern information
function PollSimulator:GetPatterns()
    local patterns = {}
    for key, pattern in pairs(RESPONSE_PATTERNS) do
        table.insert(patterns, {
            key = key,
            name = pattern.name,
            description = pattern.description,
            optInRate = pattern.optInRate,
            optOutRate = pattern.optOutRate,
            timeoutRate = pattern.timeoutRate
        })
    end
    return patterns
end

-- MARK: Module Initialization Check
function PollSimulator:IsInitialized()
    return isInitialized
end

-- MARK: Export
return PollSimulator