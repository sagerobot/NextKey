--[[
NextKey PUG Helper
Automatically assists with LFG (Pick Up Group) workflow

This module provides automatic assistance when using the LFG tool:
- Tracks LFG applications and matches them to received invites
- Provides contextual information about dungeon invites
- Offers travel assistance when joining groups
- Provides post-run getaway options

Author: NextKey Team
Version: 0.2.0.1
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGHelper = {}
NextKey222.PUGHelper = PUGHelper

-- MARK: Dependencies
local Debug = NextKey222.Debug
local Constants = NextKey222.Constants
local Utils = NextKey222.Utils

-- MARK: Constants
PUGHelper.STATE = {
    IDLE = "idle",                    -- Not tracking any LFG activity
    TRACKING = "tracking",            -- Applied to groups, tracking applications
    INVITE_RECEIVED = "invite",       -- Received invite, showing notification
    IN_GROUP = "in_group",            -- Joined group, providing travel assistance
    RUN_COMPLETE = "run_complete"     -- Dungeon completed, providing getaway options
}

-- State transition matrix - defines valid state transitions
PUGHelper.VALID_TRANSITIONS = {
    [PUGHelper.STATE.IDLE] = {
        [PUGHelper.STATE.TRACKING] = true
    },
    [PUGHelper.STATE.TRACKING] = {
        [PUGHelper.STATE.IDLE] = true,
        [PUGHelper.STATE.INVITE_RECEIVED] = true
    },
    [PUGHelper.STATE.INVITE_RECEIVED] = {
        [PUGHelper.STATE.TRACKING] = true,  -- Invite timeout/declined
        [PUGHelper.STATE.IN_GROUP] = true   -- Invite accepted
    },
    [PUGHelper.STATE.IN_GROUP] = {
        [PUGHelper.STATE.IDLE] = true,        -- Left group
        [PUGHelper.STATE.RUN_COMPLETE] = true -- Dungeon completed
    },
    [PUGHelper.STATE.RUN_COMPLETE] = {
        [PUGHelper.STATE.IDLE] = true         -- Getaway UI closed/timed out
    }
}

PUGHelper.INVITE_TIMEOUT = 60 -- seconds
PUGHelper.GETAWAY_TIMEOUT = 120 -- seconds

-- MARK: Private Variables
local currentState = PUGHelper.STATE.IDLE
local trackedApplications = {} -- Cache of applied groups
local currentInvite = nil -- Current invite being processed
local currentGroupInfo = nil -- Information about current group
local inviteTimer = nil -- Timer for invite timeout
local getawayTimer = nil -- Timer for getaway UI timeout
local pugConfig = {
    enabled = true,
    autoAcceptInvites = false,
    showNotifications = true,
    travelAssistant = true,
    getawayUI = true
}

-- MARK: Module Registration
NextKey222.RegisterModule("PUGHelper", PUGHelper)

-- MARK: Public Interface

-- Initialize the PUG Helper module
function PUGHelper:Initialize()
    Debug:Dev("pughelper", "PUGHelper:Initialize() called")
    
    -- Register for LFG events (if any)
    self:RegisterEvents()
    
    -- Load configuration
    self:LoadConfig()
    
    -- Enable the LFG hook
    self:SetHookEnabled(true)
    
    -- DEBUG: Log initialization status
    Debug:User("PUG Helper initialized - Enabled: " .. (pugConfig.enabled and "YES" or "NO"))
    Debug:User("PUG Helper config - Auto Show: " .. (pugConfig.enabled and "ENABLED" or "DISABLED"))
    Debug:User("PUG Helper state: " .. currentState)
    
    return true
end

-- Check if PUG Helper is enabled
function PUGHelper:IsEnabled()
    return pugConfig.enabled
end

-- Get current state
function PUGHelper:GetState()
    return currentState
end

-- Enable/disable PUG Helper
function PUGHelper:SetEnabled(enabled)
    pugConfig.enabled = enabled
    
    if not enabled then
        -- Reset state if disabled
        self:ResetState()
    end
    
    -- The hook will now be active or inactive based on this setting
    Debug:Dev("pughelper", "PUG Helper " .. (enabled and "enabled" or "disabled"))
end

-- Configure PUG Helper settings
function PUGHelper:Configure(settings)
    for key, value in pairs(settings) do
        if pugConfig[key] ~= nil then
            pugConfig[key] = value
            Debug:Dev("pughelper", "PUG Helper config updated: " .. key .. " = " .. tostring(value))
        end
    end
end

-- Get current configuration
function PUGHelper:GetConfig()
    -- Return a copy to prevent external modification
    local configCopy = {}
    for key, value in pairs(pugConfig) do
        configCopy[key] = value
    end
    return configCopy
end

-- Get state information for debugging
function PUGHelper:GetStateInfo()
    return {
        current = currentState,
        applicationsCount = trackedApplications and #trackedApplications or 0,
        hasInvite = currentInvite ~= nil,
        hasGroupInfo = currentGroupInfo ~= nil,
        inviteTimerActive = inviteTimer ~= nil,
        getawayTimerActive = getawayTimer ~= nil,
        enabled = pugConfig.enabled
    }
end

-- Check if PUG Helper is in an active state
function PUGHelper:IsActive()
    return currentState ~= PUGHelper.STATE.IDLE
end

-- Check if PUG Helper can accept new applications
function PUGHelper:CanAcceptApplications()
    return currentState == PUGHelper.STATE.IDLE or currentState == PUGHelper.STATE.TRACKING
end

-- Check if PUG Helper is waiting for an invite decision
function PUGHelper:IsWaitingForInvite()
    return currentState == PUGHelper.STATE.INVITE_RECEIVED
end

-- Check if PUG Helper is currently in a group
function PUGHelper:IsInGroup()
    return currentState == PUGHelper.STATE.IN_GROUP or currentState == PUGHelper.STATE.RUN_COMPLETE
end

-- Get human-readable state name
function PUGHelper:GetStateDisplayName()
    local stateNames = {
        [PUGHelper.STATE.IDLE] = "Idle",
        [PUGHelper.STATE.TRACKING] = "Tracking Applications",
        [PUGHelper.STATE.INVITE_RECEIVED] = "Invite Received",
        [PUGHelper.STATE.IN_GROUP] = "In Group",
        [PUGHelper.STATE.RUN_COMPLETE] = "Run Complete"
    }
    return stateNames[currentState] or "Unknown"
end

-- Get tracked applications for external modules
function PUGHelper:GetTrackedApplications()
    local applications = {}
    
    for appID, appData in pairs(trackedApplications) do
        -- Create a copy to avoid external modification
        local appCopy = {}
        for key, value in pairs(appData) do
            if type(value) == "table" then
                appCopy[key] = CopyTable(value)
            else
                appCopy[key] = value
            end
        end
        applications[appID] = appCopy
    end
    
    return applications
end

-- Get application count
function PUGHelper:GetApplicationCount()
    local count = 0
    for _ in pairs(trackedApplications) do
        count = count + 1
    end
    return count
end

-- Get applications as an array for easier iteration
function PUGHelper:GetApplicationsAsArray()
    local applications = {}
    
    for _, appData in pairs(trackedApplications) do
        table.insert(applications, appData)
    end
    
    -- Sort by applied time (newest first)
    table.sort(applications, function(a, b)
        return (a.appliedAt or 0) > (b.appliedAt or 0)
    end)
    
    return applications
end

-- Manually trigger application tracking (for testing)
function PUGHelper:TestApplicationTracking()
    if not pugConfig.enabled then
        Debug:User("PUG Helper is disabled")
        return
    end
    
    Debug:Dev("pughelper", "Test: Simulating application tracking")
    
    -- Create fake application data for testing
    local fakeApp = {
        id = "test-" .. time(),
        name = "Test Group - Ara-Kara, City of Echoes",
        leader = "TestLeader-Realm",
        dungeonID = 503,
        keyLevel = 10,
        activityID = 1329,
        comment = "Test group for PUG Helper"
    }
    
    trackedApplications[fakeApp.id] = fakeApp
    currentState = PUGHelper.STATE.TRACKING
    
    Debug:User("Test application added: " .. fakeApp.name)
end

-- Test function to validate PUG Helper fixes
function PUGHelper:TestPUGHelperFixes()
    Debug:User("=== PUG Helper Fix Validation Test ===")
    
    -- Test 1: Check if PUG Helper initializes without errors
    Debug:User("Test 1: Checking PUG Helper initialization...")
    local initSuccess = pcall(function()
        return self:Initialize()
    end)
    
    if initSuccess then
        Debug:User("✓ PUG Helper initialization successful")
    else
        Debug:Error("✗ PUG Helper initialization failed")
        return false
    end
    
    -- Test 2: Check if event registration works without errors
    Debug:User("Test 2: Checking event registration...")
    local eventSuccess = pcall(function()
        self:RegisterLFGEvents()
    end)
    
    if eventSuccess then
        Debug:User("✓ Event registration successful")
    else
        Debug:Error("✗ Event registration failed")
        return false
    end
    
    -- Test 3: Check if hooking setup works without errors
    Debug:User("Test 3: Checking hook setup...")
    local hookSuccess = pcall(function()
        self:SetHookEnabled(true)
    end)
    
    if hookSuccess then
        Debug:User("✓ Hook setup successful (no errors)")
    else
        Debug:Error("✗ Hook setup failed")
        return false
    end
    
    -- Test 4: Check state transitions
    Debug:User("Test 4: Checking state transitions...")
    local stateSuccess = pcall(function()
        self:TransitionToState(PUGHelper.STATE.TRACKING, "test")
        self:TransitionToState(PUGHelper.STATE.IDLE, "test")
    end)
    
    if stateSuccess then
        Debug:User("✓ State transitions successful")
    else
        Debug:Error("✗ State transitions failed")
        return false
    end
    
    -- Test 5: Check application tracking
    Debug:User("Test 5: Checking application tracking...")
    local trackingSuccess = pcall(function()
        self:TestApplicationTracking()
    end)
    
    if trackingSuccess then
        Debug:User("✓ Application tracking successful")
    else
        Debug:Error("✗ Application tracking failed")
        return false
    end
    
    Debug:User("=== All PUG Helper tests passed! ===")
    return true
end

-- MARK: Private Implementation

-- Load configuration from saved variables
function PUGHelper:LoadConfig()
    -- Use the proper database reference through NextKey.db
    local db = NextKey222.Addon and NextKey222.Addon.db
    if not db then
        Debug:Dev("pughelper", "Database not available, using default config")
        return
    end
    
    local savedConfig = db.global and db.global.pugHelper
    
    if savedConfig then
        for key, value in pairs(savedConfig) do
            if pugConfig[key] ~= nil then
                pugConfig[key] = value
            end
        end
    end
    
    Debug:Dev("pughelper", "PUG Helper configuration loaded")
end

-- Save configuration to saved variables
function PUGHelper:SaveConfig()
    -- Use the proper database reference through NextKey.db
    local db = NextKey222.Addon and NextKey222.Addon.db
    if not db then
        Debug:Dev("pughelper", "Database not available, cannot save config")
        return
    end
    
    if not db.global.pugHelper then
        db.global.pugHelper = {}
    end
    
    for key, value in pairs(pugConfig) do
        db.global.pugHelper[key] = value
    end
    
    Debug:Dev("pughelper", "PUG Helper configuration saved")
end

-- Note: Events are registered in events/handlers.lua and forwarded to PUG Helper
-- This approach follows the NextKey architecture pattern
function PUGHelper:RegisterEvents()
    Debug:Dev("pughelper", "PUG Helper events registered via events/handlers.lua")
end

-- Register LFG events for application tracking
function PUGHelper:RegisterLFGEvents()
    Debug:Dev("pughelper", "Registering LFG events for application tracking")
    
    -- Create a simple event frame for LFG events
    if not self.lfgEventFrame then
        self.lfgEventFrame = CreateFrame("Frame")
        
        -- Use only confirmed working events from the WoW API
        -- These events are documented and should be available
        local validEvents = {
            "LFG_UPDATE",                           -- Fires when LFG state changes
            "LFG_LIST_APPLICATION_STATUS_UPDATED", -- Fires when application status changes
            "LFG_LIST_SEARCH_RESULT_UPDATED",      -- Fires when search results are updated (corrected name)
            "LFG_LIST_APPLICANT_UPDATED",          -- Fires when applicants are updated
            "GROUP_ROSTER_UPDATE"                  -- Fires when group composition changes
        }
        
        for _, eventName in ipairs(validEvents) do
            Debug:Dev("pughelper", "Registering event: " .. eventName)
            self.lfgEventFrame:RegisterEvent(eventName)
        end
        
        self.lfgEventFrame:SetScript("OnEvent", function(_, event, ...)
            if not pugConfig.enabled then
                return
            end
            
            Debug:Dev("pughelper", "LFG event received: " .. event)
            
            if event == "LFG_UPDATE" or event == "LFG_LIST_SEARCH_RESULT_UPDATED" then
                -- Application list might have been updated
                self:OnApplicationListUpdated()
            elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
                local resultID, newStatus, oldStatus = ...
                self:OnApplicationStatusChanged(resultID, newStatus, oldStatus)
            elseif event == "LFG_LIST_APPLICANT_UPDATED" then
                -- Applicants updated, check if our applications changed
                self:OnApplicationListUpdated()
            elseif event == "GROUP_ROSTER_UPDATE" then
                -- Group changed, check if we joined a group we applied to
                self:OnGroupRosterUpdate()
            end
        end)
        
        Debug:Dev("pughelper", "LFG event frame registered successfully")
    end
end

-- Safely hook into a function
local function hook(owner, funcName, detour)
    if type(owner) ~= "table" then
        Debug:Error("Cannot hook '" .. tostring(funcName) .. "': owner is not a table.")
        return
    end

    local original = owner[funcName]
    if type(original) ~= "function" then
        Debug:Error("Cannot hook '" .. tostring(funcName) .. "': original is not a function.")
        return
    end

    owner[funcName] = function(...)
        local continue = detour(...)
        if continue ~= false then
            return original(...)
        end
    end
    Debug:Dev("pughelper", "Successfully hooked " .. tostring(funcName))
end

-- Enable/disable the LFG hook
function PUGHelper:SetHookEnabled(enabled)
    if enabled then
        -- REMOVED: LFGListUtil.CycleSearchResults hooking as this function doesn't exist in current WoW API
        Debug:Dev("pughelper", "LFG hook functionality disabled - CycleSearchResults function not available in current API")
        
        -- Use event-based approach instead of hooking
        Debug:Dev("pughelper", "Using event-based approach for LFG tracking")
        self:RegisterLFGEvents()
    else
        -- NOTE: Unhooking is not implemented to avoid complexity.
        -- The hook will simply do nothing if the feature is disabled.
        Debug:Dev("pughelper", "LFG hook disabled")
    end
end

-- Validate state transition
function PUGHelper:ValidateStateTransition(fromState, toState)
    if not fromState or not toState then
        Debug:Dev("pughelper", "Invalid state transition: missing states")
        return false
    end
    
    if fromState == toState then
        Debug:Dev("pughelper", "State transition to same state: " .. toState)
        return true -- Allow staying in same state
    end
    
    local validTransitions = PUGHelper.VALID_TRANSITIONS[fromState]
    if not validTransitions then
        Debug:Dev("pughelper", "No valid transitions defined from state: " .. fromState)
        return false
    end
    
    local isValid = validTransitions[toState] or false
    if not isValid then
        Debug:Dev("pughelper", "Invalid state transition: " .. fromState .. " -> " .. toState)
    else
        Debug:Dev("pughelper", "Valid state transition: " .. fromState .. " -> " .. toState)
    end
    
    return isValid
end

-- Transition to new state with validation
function PUGHelper:TransitionToState(newState, context)
    context = context or "unknown"
    
    if not self:ValidateStateTransition(currentState, newState) then
        Debug:Error("PUG Helper: Invalid state transition attempted: " .. currentState .. " -> " .. newState .. " (context: " .. context .. ")")
        return false
    end
    
    local oldState = currentState
    currentState = newState
    
    Debug:Dev("pughelper", "PUG Helper state transition: " .. oldState .. " -> " .. newState .. " (context: " .. context .. ")")
    
    -- Trigger state change handlers
    self:OnStateChanged(oldState, newState, context)
    
    return true
end

-- Handle state changes
function PUGHelper:OnStateChanged(oldState, newState, context)
    local leaveActions = {
        [self.STATE.INVITE_RECEIVED] = function()
            if inviteTimer then
                inviteTimer:Cancel()
                inviteTimer = nil
            end
        end,
        [self.STATE.RUN_COMPLETE] = function()
            if getawayTimer then
                getawayTimer:Cancel()
                getawayTimer = nil
            end
        end,
    }

    local enterActions = {
        [self.STATE.IDLE] = function()
            trackedApplications = {}
            currentInvite = nil
            currentGroupInfo = nil
        end,
    }

    if leaveActions[oldState] then
        leaveActions[oldState]()
    end

    if enterActions[newState] then
        enterActions[newState]()
    end
end

-- Reset PUG Helper state
function PUGHelper:ResetState()
    Debug:Dev("pughelper", "Resetting PUG Helper state from: " .. currentState)
    
    -- Clear timers
    if inviteTimer then
        inviteTimer:Cancel()
        inviteTimer = nil
    end
    
    if getawayTimer then
        getawayTimer:Cancel()
        getawayTimer = nil
    end
    
    -- Clear tracked data
    trackedApplications = {}
    currentInvite = nil
    currentGroupInfo = nil
    
    -- Reset state (using transition system for consistency)
    currentState = PUGHelper.STATE.IDLE
    
    Debug:Dev("pughelper", "PUG Helper state reset to IDLE")
end

-- Match invite to tracked applications
function PUGHelper:MatchInviteToApplication(inviteName)
    Debug:Dev("pughelper", "Matching invite to applications: " .. inviteName)
    
    -- Try to find matching application by leader name
    for appID, appData in pairs(trackedApplications) do
        if appData.leader == inviteName then
            Debug:Dev("pughelper", "Found matching application: " .. appData.name)
            return appData
        end
    end
    
    -- Try to match by group name (extract leader from invite)
    for appID, appData in pairs(trackedApplications) do
        if string.find(inviteName, appData.leader, 1, true) or
           string.find(appData.name, string.gsub(inviteName, "-.*", ""), 1, true) then
            Debug:Dev("pughelper", "Found partial match: " .. appData.name)
            return appData
        end
    end
    
    Debug:Dev("pughelper", "No matching application found for: " .. inviteName)
    return nil
end

-- Get dungeon information
function PUGHelper:GetDungeonInfo(dungeonID)
    -- Use the portals data as the source of truth for dungeon information
    if NextKey222.Portals and NextKey222.Portals.GetDungeonInfo then
        return NextKey222.Portals:GetDungeonInfo(dungeonID)
    end
    
    -- Fallback to constants if portals is not available
    if NextKey222.Constants and NextKey222.Constants.DUNGEONS then
        return NextKey222.Constants.DUNGEONS[dungeonID] or NextKey222.Constants.MAPS[dungeonID]
    end
    
    -- Return a minimal fallback if neither is available
    return {
        name = "Unknown Dungeon",
        alias = "Unknown"
    }
end

-- MARK: Event Handlers

-- Handle LFG application list updates
function PUGHelper:OnApplicationListUpdated()
    -- ALWAYS log to chat for debugging
    print("NextKey PUG: Application refresh detected via hook.")
    
    if not pugConfig.enabled then
        print("NextKey PUG: PUG Helper is disabled - ignoring applications.")
        Debug:Dev("pughelper", "Application refresh detected but PUG Helper is disabled.")
        return
    end
    
    print("NextKey PUG: Processing LFG applications...")
    Debug:Dev("pughelper", "LFG application list updated")
    
    -- Clear existing applications
    trackedApplications = {}
    
    -- Get current applications
    local results = C_LFGList.GetApplications()
    print("NextKey PUG: Found " .. #results .. " LFG applications via C_LFGList.GetApplications()")
    Debug:User("PUG Helper: Found " .. #results .. " LFG applications")
    
    for i = 1, #results do
        local resultID = results[i]
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
        
        if searchResultInfo then
            local appData = {
                id = tostring(resultID),
                name = searchResultInfo.name,
                leader = searchResultInfo.leaderName,
                dungeonID = searchResultInfo.activityID,
                keyLevel = 0, -- Will be extracted from name if possible
                activityID = searchResultInfo.activityID,
                comment = searchResultInfo.comment or "",
                voiceChat = searchResultInfo.voiceChat,
                iLevel = searchResultInfo.requiredItemLevel,
                honorLevel = searchResultInfo.requiredHonorLevel,
                
                -- New fields for enhanced tracking
                appliedAt = time(), -- When application was submitted
                status = "pending", -- pending, invited, declined, cancelled, failed
                statusHistory = {
                    {status = "pending", timestamp = time()}
                }
            }
            
            -- Try to extract key level from group name
            local keyLevel = string.match(appData.name, "(%d+)")
            if keyLevel then
                appData.keyLevel = tonumber(keyLevel)
            end
            
            trackedApplications[appData.id] = appData
            
            -- CHAT OUTPUT: Show application details
            print("NextKey PUG: Application #" .. i .. " - Leader: " .. (appData.leader or "Unknown") ..
                  ", Dungeon: " .. (appData.name or "Unknown") ..
                  ", Key Level: +" .. (appData.keyLevel or "?"))
            
            Debug:User("PUG Helper: Tracking application: " .. appData.name .. " (ID: " .. appData.id .. ")")
        else
            print("NextKey PUG: ERROR - Could not get search result info for resultID: " .. tostring(resultID))
        end
    end
    
    print("NextKey PUG: Total applications tracked: " .. self:GetApplicationCount())
    
    -- Update state based on applications
    local hasApplications = next(trackedApplications)
    if hasApplications and currentState == PUGHelper.STATE.IDLE then
        self:TransitionToState(PUGHelper.STATE.TRACKING, "applications_detected")
        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end
    elseif not hasApplications and currentState == PUGHelper.STATE.TRACKING then
        self:TransitionToState(PUGHelper.STATE.IDLE, "no_applications")
        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end
    end
end

-- Handle application status changes
function PUGHelper:OnApplicationStatusChanged(resultID, newStatus, oldStatus)
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Application status changed: " .. resultID .. " from " .. (oldStatus or "nil") .. " to " .. (newStatus or "nil"))
    
    local appID = tostring(resultID)
    local appData = trackedApplications[appID]
    
    if appData then
        local oldStatus = appData.status
        appData.status = newStatus
        
        -- Add to status history
        table.insert(appData.statusHistory, {
            status = newStatus,
            timestamp = time()
        })
        
        -- Notify application tracker of status change
        if NextKey222.PUGApplicationTracker then
            NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
        end
        
        -- If application was declined or cancelled, remove from tracking
        local isFinished = newStatus == "declined" or newStatus == "cancelled" or newStatus == "failed"
        if isFinished then
            trackedApplications[appID] = nil
            
            if NextKey222.PUGApplicationTracker then
                NextKey222.PUGApplicationTracker:AutoShowIfNeeded()
            end
            
            if not next(trackedApplications) and currentState == PUGHelper.STATE.TRACKING then
                self:TransitionToState(PUGHelper.STATE.IDLE, "all_applications_failed")
            end
        end
    end
end

-- Handle group roster updates (for detecting when we join a group)
function PUGHelper:OnGroupRosterUpdate()
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Group roster updated in PUG Helper")
    
    -- Check if we're now in a group and were tracking applications
    if IsInGroup() and currentState == PUGHelper.STATE.TRACKING then
        Debug:Dev("pughelper", "We joined a group while tracking applications")
        
        -- Try to find which application we joined
        local groupLeader = UnitName("party1") or UnitName("raid1")
        if groupLeader then
            Debug:Dev("pughelper", "Group leader detected: " .. groupLeader)
            
            -- Try to match to an application
            local matchedApp = self:MatchInviteToApplication(groupLeader)
            if matchedApp then
                Debug:Dev("pughelper", "Joined group matches application: " .. matchedApp.name)
                self:OnGroupJoined()
            else
                Debug:Dev("pughelper", "Joined group but no matching application found")
            end
        end
    end
end

-- Handle group invitations
function PUGHelper:OnGroupInvite(inviteName)
    if not pugConfig.enabled then
        Debug:User("PUG Helper: Group invite received but PUG Helper is disabled: " .. inviteName)
        return
    end
    
    Debug:User("PUG Helper: Group invite received: " .. inviteName)
    Debug:User("PUG Helper: Current state: " .. currentState)
    Debug:User("PUG Helper: Tracked applications count: " .. self:GetApplicationCount())
    
    -- Try to match invite to tracked applications
    local matchedApp = self:MatchInviteToApplication(inviteName)
    
    if matchedApp then
        -- We have context for this invite
        currentInvite = {
            name = inviteName,
            application = matchedApp,
            timestamp = time()
        }
        
        Debug:User("PUG Helper: Invite matched to application: " .. matchedApp.name)
        self:TransitionToState(PUGHelper.STATE.INVITE_RECEIVED, "invite_matched")
        
        -- Show contextual invite notification
        if pugConfig.showNotifications then
            Debug:User("PUG Helper: Showing invite notification")
            self:ShowInviteNotification(currentInvite)
        else
            Debug:Dev("pughelper", "Invite notifications disabled")
        end
        
        -- Set invite timeout
        inviteTimer = C_Timer.NewTimer(PUGHelper.INVITE_TIMEOUT, function()
            Debug:User("PUG Helper: Invite timed out: " .. inviteName)
            self:HandleInviteTimeout()
        end)
        
        -- Auto-accept if enabled
        if pugConfig.autoAcceptInvites then
            Debug:User("PUG Helper: Auto-accepting invite: " .. inviteName)
            AcceptGroup()
        end
    else
        -- No context, might be a regular invite
        Debug:User("PUG Helper: Invite has no application context: " .. inviteName)
    end
end

-- Handle group joined
function PUGHelper:OnGroupJoined()
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Joined group")
    
    -- Clear invite timer
    if inviteTimer then
        inviteTimer:Cancel()
        inviteTimer = nil
    end
    
    self:TransitionToState(PUGHelper.STATE.IN_GROUP, "group_joined")
    
    -- Store group information
    if currentInvite and currentInvite.application then
        currentGroupInfo = {
            name = currentInvite.application.name,
            dungeonID = currentInvite.application.dungeonID,
            keyLevel = currentInvite.application.keyLevel,
            joinedAt = time()
        }
        
        Debug:Dev("pughelper", "Group info stored: " .. currentGroupInfo.name)
        
        -- Show travel assistant if enabled
        if pugConfig.travelAssistant then
            self:ShowTravelAssistant(currentGroupInfo)
        end
    end
    
    -- Clear current invite
    currentInvite = nil
end

-- Handle group left
function PUGHelper:OnGroupLeft()
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Left group")
    
    -- Reset state
    self:ResetState()
end

-- Handle challenge mode completed
function PUGHelper:OnChallengeModeCompleted(mapID, level)
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Challenge mode completed: " .. tostring(mapID) .. " level " .. tostring(level))
    
    -- Update group info with completion data
    if currentGroupInfo then
        currentGroupInfo.completedAt = time()
        currentGroupInfo.completedMapID = mapID
        currentGroupInfo.completedLevel = level
        
        Debug:Dev("pughelper", "Run completed: " .. (currentGroupInfo.name or "Unknown"))
        
        -- Change state to run complete
        self:TransitionToState(PUGHelper.STATE.RUN_COMPLETE, "dungeon_completed")
        
        -- Show getaway UI if enabled
        if pugConfig.getawayUI then
            self:ShowGetawayUI(currentGroupInfo)
        end
        
        -- Set getaway timeout
        getawayTimer = C_Timer.NewTimer(PUGHelper.GETAWAY_TIMEOUT, function()
            Debug:Dev("pughelper", "Getaway UI timed out")
            self:HideGetawayUI()
            self:TransitionToState(PUGHelper.STATE.IDLE, "getaway_timeout")
        end)
    end
end

-- MARK: UI Methods (placeholders - will be implemented in separate UI files)

-- Show contextual invite notification
function PUGHelper:ShowInviteNotification(invite)
    Debug:Dev("pughelper", "ShowInviteNotification called")
    -- This will be implemented in ui/pugInviteNotification.lua
    if NextKey222.PUGInviteNotification then
        NextKey222.PUGInviteNotification:Show(invite)
    end
end

-- Show travel assistant
function PUGHelper:ShowTravelAssistant(groupInfo)
    Debug:Dev("pughelper", "ShowTravelAssistant called")
    -- This will be implemented in ui/pugTravelAssistant.lua
    if NextKey222.PUGTravelAssistant then
        NextKey222.PUGTravelAssistant:Show(groupInfo)
    end
end

-- Show getaway UI
function PUGHelper:ShowGetawayUI(groupInfo)
    Debug:Dev("pughelper", "ShowGetawayUI called")
    -- This will be implemented in ui/pugGetawayUI.lua
    if NextKey222.PUGGetawayUI then
        NextKey222.PUGGetawayUI:Show(groupInfo)
    end
end

-- Hide getaway UI
function PUGHelper:HideGetawayUI()
    Debug:Dev("pughelper", "HideGetawayUI called")
    -- This will be implemented in ui/pugGetawayUI.lua
    if NextKey222.PUGGetawayUI then
        NextKey222.PUGGetawayUI:Hide()
    end
end

-- Handle invite timeout
function PUGHelper:HandleInviteTimeout()
    Debug:Dev("pughelper", "Handling invite timeout")
    
    -- Clear invite
    currentInvite = nil
    
    -- Reset state (using transition system for consistency)
    self:TransitionToState(PUGHelper.STATE.TRACKING, "invite_timeout")
end

-- MARK: Cleanup
function PUGHelper:Cleanup()
    Debug:Dev("pughelper", "PUGHelper cleanup called")
    
    -- Save configuration
    self:SaveConfig()
    
    -- Reset state
    self:ResetState()
end