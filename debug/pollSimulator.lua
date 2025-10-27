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
    -- Remove realm suffix for alt name
    local baseName = parentName:match("^([^%-]+)")
    return baseName .. "Alt"
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
        preferences = {}  -- Empty for simulation
    }
    
    -- If using alt, modify response
    if useAlt and responseType == "opt_in" then
        local altName = generateAltName(playerName)
        responseData.selectedCharacter = altName
        responseData.altOfPlayer = playerName
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