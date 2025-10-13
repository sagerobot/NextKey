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
    
    -- Register for LFG events
    self:RegisterEvents()
    
    -- Load configuration
    self:LoadConfig()
    
    Debug:Dev("pughelper", "PUG Helper initialized")
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

-- MARK: Private Implementation

-- Load configuration from saved variables
function PUGHelper:LoadConfig()
    local savedConfig = NextKey222DB.global.pugHelper
    
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
    if not NextKey222DB.global.pugHelper then
        NextKey222DB.global.pugHelper = {}
    end
    
    for key, value in pairs(pugConfig) do
        NextKey222DB.global.pugHelper[key] = value
    end
    
    Debug:Dev("pughelper", "PUG Helper configuration saved")
end

-- Note: Events are registered in events/handlers.lua and forwarded to PUG Helper
-- This approach follows the NextKey architecture pattern
function PUGHelper:RegisterEvents()
    Debug:Dev("pughelper", "PUG Helper events registered via events/handlers.lua")
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
    
    -- Reset state
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
    return NextKey222.Constants.DUNGEONS[dungeonID] or NextKey222.Constants.MAPS[dungeonID]
end

-- MARK: Event Handlers

-- Handle LFG application list updates
function PUGHelper:OnApplicationListUpdated()
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "LFG application list updated")
    
    -- Clear existing applications
    trackedApplications = {}
    
    -- Get current applications
    local results = C_LFGList.GetApplications()
    
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
                honorLevel = searchResultInfo.requiredHonorLevel
            }
            
            -- Try to extract key level from group name
            local keyLevel = string.match(appData.name, "(%d+)")
            if keyLevel then
                appData.keyLevel = tonumber(keyLevel)
            end
            
            trackedApplications[appData.id] = appData
            Debug:Dev("pughelper", "Tracking application: " .. appData.name .. " (ID: " .. appData.id .. ")")
        end
    end
    
    -- Update state based on applications
    if next(trackedApplications) and currentState == PUGHelper.STATE.IDLE then
        currentState = PUGHelper.STATE.TRACKING
        Debug:Dev("pughelper", "State changed to TRACKING")
    elseif not next(trackedApplications) and currentState == PUGHelper.STATE.TRACKING then
        currentState = PUGHelper.STATE.IDLE
        Debug:Dev("pughelper", "State changed to IDLE (no applications)")
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
        appData.status = newStatus
        
        -- If application was declined or cancelled, remove from tracking
        if newStatus == "declined" or newStatus == "cancelled" or newStatus == "failed" then
            trackedApplications[appID] = nil
            Debug:Dev("pughelper", "Removed application: " .. appData.name)
            
            -- Update state if no more applications
            if not next(trackedApplications) and currentState == PUGHelper.STATE.TRACKING then
                currentState = PUGHelper.STATE.IDLE
                Debug:Dev("pughelper", "State changed to IDLE (all applications failed)")
            end
        end
    end
end

-- Handle group invitations
function PUGHelper:OnGroupInvite(inviteName)
    if not pugConfig.enabled then
        return
    end
    
    Debug:Dev("pughelper", "Group invite received: " .. inviteName)
    
    -- Try to match invite to tracked applications
    local matchedApp = self:MatchInviteToApplication(inviteName)
    
    if matchedApp then
        -- We have context for this invite
        currentInvite = {
            name = inviteName,
            application = matchedApp,
            timestamp = time()
        }
        
        currentState = PUGHelper.STATE.INVITE_RECEIVED
        
        Debug:Dev("pughelper", "Invite matched to application: " .. matchedApp.name)
        
        -- Show contextual invite notification
        if pugConfig.showNotifications then
            self:ShowInviteNotification(currentInvite)
        end
        
        -- Set invite timeout
        inviteTimer = C_Timer.NewTimer(PUGHelper.INVITE_TIMEOUT, function()
            Debug:Dev("pughelper", "Invite timed out: " .. inviteName)
            self:HandleInviteTimeout()
        end)
        
        -- Auto-accept if enabled
        if pugConfig.autoAcceptInvites then
            Debug:Dev("pughelper", "Auto-accepting invite: " .. inviteName)
            AcceptGroup()
        end
    else
        -- No context, might be a regular invite
        Debug:Dev("pughelper", "Invite has no application context: " .. inviteName)
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
    
    currentState = PUGHelper.STATE.IN_GROUP
    
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
        currentState = PUGHelper.STATE.RUN_COMPLETE
        
        -- Show getaway UI if enabled
        if pugConfig.getawayUI then
            self:ShowGetawayUI(currentGroupInfo)
        end
        
        -- Set getaway timeout
        getawayTimer = C_Timer.NewTimer(PUGHelper.GETAWAY_TIMEOUT, function()
            Debug:Dev("pughelper", "Getaway UI timed out")
            self:HideGetawayUI()
            currentState = PUGHelper.STATE.IDLE
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
    
    -- Reset state
    currentState = PUGHelper.STATE.TRACKING
end

-- MARK: Cleanup
function PUGHelper:Cleanup()
    Debug:Dev("pughelper", "PUGHelper cleanup called")
    
    -- Save configuration
    self:SaveConfig()
    
    -- Reset state
    self:ResetState()
end