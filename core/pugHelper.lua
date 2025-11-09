--[[
NextKey PUG Helper
Main coordinator for the PUG (Pick Up Group) workflow.
Orchestrates the state, application, and UI modules.
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGHelper = {}
NextKey222.PUGHelper = PUGHelper

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Private Variables
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

function PUGHelper:Initialize()
    Debug:Dev("pughelper", "PUGHelper:Initialize() called")
    self:RegisterEvents()
    self:LoadConfig()
    self:SetHookEnabled(true)
    Debug:User("PUG Helper initialized - Enabled: " .. (pugConfig.enabled and "YES" or "NO"))
    return true
end

function PUGHelper:IsEnabled()
    return pugConfig.enabled
end

function PUGHelper:SetEnabled(enabled)
    pugConfig.enabled = enabled
    if not enabled then
        self:ResetState()
    end
    Debug:Dev("pughelper", "PUG Helper " .. (enabled and "enabled" or "disabled"))
end

function PUGHelper:Configure(settings)
    for key, value in pairs(settings) do
        if pugConfig[key] ~= nil then
            pugConfig[key] = value
        end
    end
end

function PUGHelper:GetConfig()
    local configCopy = {}
    for key, value in pairs(pugConfig) do
        configCopy[key] = value
    end
    return configCopy
end

-- MARK: Private Implementation

function PUGHelper:LoadConfig()
    local db = NextKey222.Addon and NextKey222.Addon.db
    if db and db.global and db.global.pugHelper then
        for key, value in pairs(db.global.pugHelper) do
            if pugConfig[key] ~= nil then
                pugConfig[key] = value
            end
        end
    end
end

function PUGHelper:SaveConfig()
    local db = NextKey222.Addon and NextKey222.Addon.db
    if db and not db.global.pugHelper then
        db.global.pugHelper = {}
    end
    if db then
        for key, value in pairs(pugConfig) do
            db.global.pugHelper[key] = value
        end
    end
end

function PUGHelper:RegisterEvents()
    Debug:Dev("pughelper", "PUG Helper events registered via events/handlers.lua")
end

function PUGHelper:RegisterLFGEvents()
    if not self.lfgEventFrame then
        self.lfgEventFrame = CreateFrame("Frame")
        local events = {
            "LFG_UPDATE",
            "LFG_LIST_APPLICATION_STATUS_UPDATED",
            "LFG_LIST_SEARCH_RESULT_UPDATED",
            "LFG_LIST_APPLICANT_UPDATED",
            "GROUP_ROSTER_UPDATE"
        }
        for _, eventName in ipairs(events) do
            self.lfgEventFrame:RegisterEvent(eventName)
        end
        self.lfgEventFrame:SetScript("OnEvent", function(_, event, ...)
            if not pugConfig.enabled then return end
            if event == "LFG_UPDATE" or event == "LFG_LIST_SEARCH_RESULT_UPDATED" or event == "LFG_LIST_APPLICANT_UPDATED" then
                self:OnApplicationListUpdated()
            elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
                self:OnApplicationStatusChanged(...)
            elseif event == "GROUP_ROSTER_UPDATE" then
                self:OnGroupRosterUpdate()
            end
        end)
    end
end

function PUGHelper:SetHookEnabled(enabled)
    if enabled then
        self:RegisterLFGEvents()
    end
end

-- MARK: Event Handlers

function PUGHelper:OnGroupRosterUpdate()
    if self:IsEnabled() and IsInGroup() and self:GetState() == self.STATE.TRACKING then
        local groupLeader = UnitName("party1") or UnitName("raid1")
        if groupLeader then
            local matchedApp = self:MatchInviteToApplication(groupLeader)
            if matchedApp then
                self:OnGroupJoined()
            end
        end
    end
end

function PUGHelper:OnGroupInvite(inviteName)
    if not self:IsEnabled() then return end
    
    local matchedApp = self:MatchInviteToApplication(inviteName)
    if matchedApp then
        self.currentInvite = { name = inviteName, application = matchedApp, timestamp = time() }
        self:TransitionToState(self.STATE.INVITE_RECEIVED, "invite_matched")
        
        if pugConfig.showNotifications then
            self:ShowInviteNotification(self.currentInvite)
        end
        
        self.inviteTimer = C_Timer.NewTimer(PUGHelper.INVITE_TIMEOUT, function()
            self:HandleInviteTimeout()
        end)
        
        if pugConfig.autoAcceptInvites then
            AcceptGroup()
        end
    end
end

function PUGHelper:OnGroupJoined()
    if not self:IsEnabled() then return end
    
    if self.inviteTimer then
        self.inviteTimer:Cancel()
        self.inviteTimer = nil
    end
    
    self:TransitionToState(self.STATE.IN_GROUP, "group_joined")
    
    if self.currentInvite and self.currentInvite.application then
        self.currentGroupInfo = {
            name = self.currentInvite.application.name,
            dungeonID = self.currentInvite.application.dungeonID,
            keyLevel = self.currentInvite.application.keyLevel,
            joinedAt = time()
        }
        
        if pugConfig.travelAssistant then
            self:ShowTravelAssistant(self.currentGroupInfo)
        end
    end
    
    self.currentInvite = nil
end

function PUGHelper:OnGroupLeft()
    if self:IsEnabled() then
        self:ResetState()
    end
end

-- MARK: End-of-Dungeon Handling (Details-style)
-- Called from Events:OnChallengeModeCompleted() after any Mythic+ completion.
-- Responsibilities:
-- - Only mark RUN_COMPLETE for valid tracked PUG runs.
-- - Only set PUG-specific teleport context; do NOT decide generic auto-show here.
function PUGHelper:OnChallengeModeCompleted(mapID, level)
    if not self:IsEnabled() then
        return
    end

    Debug:Dev("pughelper", "OnChallengeModeCompleted: mapID=" .. tostring(mapID) .. ", level=" .. tostring(level))

    -- Require a consistent PUG classification
    local group_type = "SOLO"
    if self.DetectGroupType then
        group_type = self:DetectGroupType()
    end

    if group_type ~= "PUG" then
        Debug:Dev("pughelper", "Completion detected, but group_type=" .. tostring(group_type) .. " (PUG-only behavior skipped)")
        return
    end

    -- Require we were actually in a tracked run
    if not self.GetState or self:GetState() ~= self.STATE.IN_GROUP then
        Debug:Dev("pughelper", "Completion detected for PUG, but state is not IN_GROUP (state=" .. tostring(self.GetState and self:GetState() or "nil") .. ")")
        return
    end

    local NextKey = NextKey222.Addon
    if not NextKey or not NextKey.SetTeleportTargetKey or not NextKey.SetTeleportWindowContext then
        Debug:Dev("pughelper", "Teleport APIs not available on completion; skipping PUG summary setup")
        return
    end

    -- Derive owner/leader for context; fall back gracefully
    local owner_name = "Completed Run"
    if self.currentGroupInfo and self.currentGroupInfo.leader then
        owner_name = self.currentGroupInfo.leader
    elseif self.currentGroupInfo and self.currentGroupInfo.name then
        owner_name = self.currentGroupInfo.name
    end

    local key_info = {
        dungeonID = mapID,
        level = level,
        ownerName = owner_name,
    }

    Debug:Dev("pughelper", "Marking PUG run complete and configuring teleport context")

    -- Mark state as run complete (Details-style: explicit lifecycle)
    if self.TransitionToState then
        self:TransitionToState(self.STATE.RUN_COMPLETE, "mplus_completed")
    end

    -- Set teleport target and PUG completion context
    NextKey:SetTeleportTargetKey(key_info, { broadcast = false })
    NextKey:SetTeleportWindowContext({
        mode = "PUG",
        dungeonComplete = true,
    })

    -- NOTE:
    -- We DO NOT call ToggleTeleportWindow() here.
    -- Generic auto-show behavior is owned by Events:OnChallengeModeCompleted(),
    -- which will open the teleport window once using the context we just set.
end

-- MARK: UI Methods

function PUGHelper:ShowInviteNotification(invite)
    if NextKey222.PUGInviteNotification then
        NextKey222.PUGInviteNotification:Show(invite)
    end
end

function PUGHelper:ShowTravelAssistant(groupInfo)
    if NextKey222.PUGTravelAssistant then
        NextKey222.PUGTravelAssistant:Show(groupInfo)
    end
end


function PUGHelper:HandleInviteTimeout()
    self.currentInvite = nil
    self:TransitionToState(self.STATE.TRACKING, "invite_timeout")
end

-- MARK: Helper Methods

-- Get dungeon information for a given dungeon ID
function PUGHelper:GetDungeonInfo(dungeonID)
    if not dungeonID then
        Debug:Dev("pughelper", "GetDungeonInfo called with nil dungeonID")
        return nil
    end
    
    local dungeonName = nil
    
    -- Try C_ChallengeMode API first (most reliable)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name = C_ChallengeMode.GetMapUIInfo(dungeonID)
        if name then
            dungeonName = name
            Debug:Dev("pughelper", "Found dungeon name via C_ChallengeMode: " .. name)
        end
    end
    
    -- Try DungeonNameService
    if not dungeonName and NextKey222.DungeonNameService and NextKey222.DungeonNameService.GetDungeonName then
        dungeonName = NextKey222.DungeonNameService:GetDungeonName(dungeonID)
        if dungeonName then
            Debug:Dev("pughelper", "Found dungeon name via DungeonNameService: " .. dungeonName)
        end
    end
    
    -- Fallback to portal data if available
    if not dungeonName and NextKey222.PortalData then
        local activeSeason = NextKey222.PortalData.activeSeasonKey
        if activeSeason and NextKey222.PortalData[activeSeason] then
            local dungeons = NextKey222.PortalData[activeSeason].dungeons
            if dungeons and dungeons[dungeonID] then
                dungeonName = dungeons[dungeonID].name
                Debug:Dev("pughelper", "Found dungeon name via PortalData: " .. dungeonName)
            end
        end
    end
    
    if not dungeonName then
        Debug:Dev("pughelper", "Could not find dungeon name for ID: " .. tostring(dungeonID))
    end
    
    -- Return dungeon info structure
    return {
        id = dungeonID,
        name = dungeonName or "Unknown Dungeon"
    }
end

-- MARK: Cleanup

function PUGHelper:Cleanup()
    self:SaveConfig()
    self:ResetState()
end