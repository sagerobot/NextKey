-- MARK: Event Handlers
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- Events module
local Events = {}
NextKey222.Events = Events
NextKey222.RegisterModule("Events", Events)

-- MARK: Event Registration
function Events:RegisterCoreEvents()
    NextKey:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isLogin, isReload)
        self:OnPlayerEnteringWorld(isLogin, isReload)
    end)
    
    NextKey:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupRosterUpdate()
    end)
    
    -- Additional party-related events for better responsiveness
    NextKey:RegisterEvent("GROUP_JOINED", function()
        self:OnGroupJoined()
    end)
    
    NextKey:RegisterEvent("GROUP_LEFT", function()
        self:OnGroupLeft()
    end)
    
    NextKey:RegisterEvent("BAG_UPDATE_DELAYED", function()
        self:OnBagUpdateDelayed()
    end)
    
    NextKey:RegisterEvent("CHAT_MSG_ADDON", function(event, prefix, message, distribution, sender)
        self:OnChatMsgAddon(prefix, message, distribution, sender)
    end)
    
    -- PUG Helper events
    NextKey:RegisterEvent("LFG_LIST_APPLICATION_STATUS_CHANGED", function(_, resultID, newStatus, oldStatus)
        self:OnLFGApplicationStatusChanged(resultID, newStatus, oldStatus)
    end)
    
    NextKey:RegisterEvent("GROUP_INVITE_CONFIRMATION", function(_, name)
        self:OnGroupInviteConfirmation(name)
    end)
    
    NextKey:RegisterEvent("CHALLENGE_MODE_COMPLETED", function(_, mapID, level)
        self:OnChallengeModeCompleted(mapID, level)
    end)
    
    NextKey222.Debug:Dev("events", "Core events registered")
end

-- MARK: Core Event Handlers
function Events:OnPlayerEnteringWorld(isLogin, isReload)
    NextKey222.Performance:StartProfile("OnPlayerEnteringWorld")
    
    if isLogin or isReload then
        NextKey222.Debug:Dev("events", "Player entering world - login/reload")
        
        -- Initialize player data
        if NextKey.Keystones and NextKey.Keystones.ScanPlayerKeystones then
            NextKey.SafeRun(NextKey.Keystones.ScanPlayerKeystones, "Scan player keystones on login")
        end
        
        -- Setup UI if available
        if NextKey222.UI and NextKey222.UI.Initialize then
            NextKey.SafeRun(NextKey222.UI.Initialize, "Initialize UI on login")
        end
    end
    
    NextKey222.Performance:StopProfile("OnPlayerEnteringWorld")
end

-- MARK: Performance-Optimized Group Roster Update
-- Prevents cascading updates that cause FPS drops

-- Performance throttling variables
local lastRosterUpdate = 0
local ROSTER_UPDATE_THROTTLE = 1.0 -- 1 second minimum between updates
local pendingRosterUpdate = false

function Events:OnGroupRosterUpdate()
    local now = GetTime()
    
    -- PERFORMANCE FIX: Immediate throttling to prevent cascading updates
    if now - lastRosterUpdate < ROSTER_UPDATE_THROTTLE then
        if not pendingRosterUpdate then
            pendingRosterUpdate = true
            NextKey222.Debug:Dev("events", "Group roster update throttled - scheduling delayed processing")
            
            C_Timer.NewTimer(ROSTER_UPDATE_THROTTLE, function()
                self:ProcessRosterUpdate()
                pendingRosterUpdate = false
            end)
        else
            NextKey222.Debug:Dev("events", "Group roster update throttled - already pending")
        end
        return
    end
    
    self:ProcessRosterUpdate()
    lastRosterUpdate = now
end

function Events:ProcessRosterUpdate()
    NextKey222.Performance:StartProfile("ProcessRosterUpdate")
    
    -- Event coalescing: Batch rapid-fire roster updates
    if not self.rosterUpdateTimer then
        self.rosterUpdateTimer = {}
    end
    
    -- Cancel pending update if one exists
    if self.rosterUpdateTimer.handle then
        self.rosterUpdateTimer.handle:Cancel()
    end
    
    -- PHASE 3: Optimize for offline players in mixed groups
    local groupSize = GetNumGroupMembers() or 1
    local onlineCount = self:GetOnlineGroupMembers()
    
    -- Use online player count for throttling if significant offline presence
    local effectiveSize = onlineCount
    if groupSize - onlineCount >= 3 then
        -- 3+ offline players: use online count for performance
        effectiveSize = onlineCount
        NextKey222.Debug:Dev("events", string.format("Mixed group detected: %d total, %d online - using online count for throttling",
            groupSize, onlineCount))
    end
    
    local baseDelay = 0.5
    local scaledDelay = baseDelay + (effectiveSize > 5 and (effectiveSize - 5) * 0.1 or 0)
    local maxDelay = 2.0
    local coalescingDelay = math.min(scaledDelay, maxDelay)
    
    NextKey222.Debug:Dev("events", string.format("Group roster update - coalescing for %.1fs (total: %d, online: %d, effective: %d)",
        coalescingDelay, groupSize, onlineCount, effectiveSize))
    
    -- Schedule coalesced update
    self.rosterUpdateTimer.handle = C_Timer.NewTimer(coalescingDelay, function()
        NextKey222.Debug:Dev("events", "Executing coalesced roster update")
        
        -- Update group composition
        if NextKey222.Communications and NextKey222.Communications.SendSync then
            NextKey.SafeRun(NextKey222.Communications.SendSync, "Auto sync on group change")
        end
        
        -- Update and share dungeon scores for IOCalculator
        if NextKey222.IOCalculator then
            NextKey.SafeRun(function()
                NextKey222.IOCalculator:UpdateCurrentPlayerScores()
            end, "Update dungeon scores on roster change")
        end
        
        -- Refresh UI if visible (party changes affect keystone display and IO calculations)
        if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
            -- Add extra notice for IO Gain Potential mode
            if NextKey222.UI.IsPartySensitiveSortMode and NextKey222.UI:IsPartySensitiveSortMode() then
                NextKey222.Debug:Dev("events", "Party change affects IO Gain Potential calculations - full refresh needed")
            end
            
            NextKey222.Debug:Dev("events", "Refreshing UI due to party change")
            NextKey.SafeRun(function()
                NextKey222.UI:RefreshResults()
            end, "Auto refresh UI on group change")
        end
        
        self.rosterUpdateTimer.handle = nil
    end)
    
    NextKey222.Performance:StopProfile("ProcessRosterUpdate")
end

function Events:OnGroupJoined()
    NextKey222.Performance:StartProfile("OnGroupJoined")
    NextKey222.Debug:Dev("events", "Player joined a group")
    
    -- Force immediate keystone scan when joining group
    if NextKey.Keystones and NextKey.Keystones.ScanAllKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanAllKeystones, "Scan all keystones on group join")
    end
    
    -- Update and share dungeon scores immediately
    if NextKey222.IOCalculator then
        NextKey.SafeRun(function()
            NextKey222.IOCalculator:UpdateCurrentPlayerScores()
        end, "Update and share scores on group join")
    end
    
    -- Refresh UI immediately if visible
    if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
        C_Timer.After(0.5, function()
            NextKey.SafeRun(NextKey222.UI.RefreshResults, "Refresh UI on group join", NextKey222.UI)
        end)
    end
    
    NextKey222.Performance:StopProfile("OnGroupJoined")
end

function Events:OnGroupLeft()
    NextKey222.Performance:StartProfile("OnGroupLeft")
    NextKey222.Debug:Dev("events", "Player left group")
    
    -- Clear party-only keystones and refresh
    if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
        NextKey.SafeRun(NextKey222.UI.RefreshResults, "Refresh UI on group leave", NextKey222.UI)
    end
    
    NextKey222.Performance:StopProfile("OnGroupLeft")
end

function Events:OnBagUpdateDelayed()
    NextKey222.Performance:StartProfile("OnBagUpdateDelayed")
    
    -- Scan for new keystones
    if NextKey.Keystones and NextKey.Keystones.ScanPlayerKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanPlayerKeystones, "Scan keystones on bag update")
    end
    
    NextKey222.Performance:StopProfile("OnBagUpdateDelayed")
end

function Events:OnChatMsgAddon(prefix, message, distribution, sender)
    NextKey222.Performance:StartProfile("OnChatMsgAddon")
    
    -- Route addon messages to communications
    if NextKey222.Communications and NextKey222.Communications.ProcessMessage then
        NextKey.SafeRun(NextKey222.Communications.ProcessMessage, "Process addon message", prefix, message, distribution, sender)
    end
    
    NextKey222.Performance:StopProfile("OnChatMsgAddon")
end

-- MARK: PUG Helper Event Handlers
function Events:OnLFGApplicationListUpdated()
    NextKey222.Performance:StartProfile("OnLFGApplicationListUpdated")
    
    -- Forward to PUG Helper if available
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnApplicationListUpdated then
        NextKey.SafeRun(NextKey222.PUGHelper.OnApplicationListUpdated, "PUG Helper application list updated", NextKey222.PUGHelper)
    end
    
    NextKey222.Performance:StopProfile("OnLFGApplicationListUpdated")
end

function Events:OnLFGApplicationStatusChanged(resultID, newStatus, oldStatus)
    NextKey222.Performance:StartProfile("OnLFGApplicationStatusChanged")
    
    -- Forward to PUG Helper if available
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnApplicationStatusChanged then
        NextKey.SafeRun(NextKey222.PUGHelper.OnApplicationStatusChanged, "PUG Helper application status changed", NextKey222.PUGHelper, resultID, newStatus, oldStatus)
    end
    
    NextKey222.Performance:StopProfile("OnLFGApplicationStatusChanged")
end

function Events:OnGroupInviteConfirmation(name)
    NextKey222.Performance:StartProfile("OnGroupInviteConfirmation")
    
    NextKey222.Debug:User("EVENTS: Group invite confirmation received for: " .. name)
    
    -- Forward to PUG Helper if available
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnGroupInvite then
        NextKey.SafeRun(NextKey222.PUGHelper.OnGroupInvite, "PUG Helper group invite", NextKey222.PUGHelper, name)
    else
        NextKey222.Debug:Error("EVENTS: PUG Helper not available for group invite")
    end
    
    -- NEW: Auto-show travel window for PUG context when invite popup appears
    if NextKey222.PUGHelper and NextKey222.PUGHelper:IsEnabled() then
        NextKey222.Debug:User("EVENTS: PUG Helper enabled - checking for application match")
        local matchedApp = NextKey222.PUGHelper:MatchInviteToApplication(name)
        if matchedApp then
            NextKey222.Debug:User("EVENTS: Matched invite to application: " .. (matchedApp.name or "Unknown"))
            NextKey222.Debug:User("EVENTS: Dungeon ID: " .. (matchedApp.dungeonID or "nil") .. ", Key Level: " .. (matchedApp.keyLevel or "nil"))
            
            -- Show travel window with PUG context after a short delay
            -- This ensures the travel window appears alongside Blizzard's invite popup
            C_Timer.After(0.5, function()
                NextKey222.Debug:User("EVENTS: Triggering teleport window for PUG invite")
                if NextKey222.Addon and NextKey222.Addon.ToggleTeleportWindow then
                    -- Create fake keystone info for PUG context
                    local fakeKeyInfo = {
                        dungeonID = matchedApp.dungeonID,
                        level = matchedApp.keyLevel or 0,
                        ownerName = "PUG Group",
                        source = "dungeon_portal",
                    }
                    
                    NextKey222.Debug:User("EVENTS: Setting teleport target for PUG context")
                    -- Set teleport target and show window
                    NextKey222.Addon:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
                    
                    -- CRITICAL: Set PUG context before showing window
                    NextKey222.Debug:User("EVENTS: Setting PUG mode context for teleport window")
                    NextKey222.Addon:SetTeleportWindowContext({ mode = "PUG" })
                    
                    NextKey222.Addon:ToggleTeleportWindow()
                    
                    NextKey222.Debug:User("EVENTS: Travel window shown for PUG invite: " .. (matchedApp.name or "Unknown"))
                else
                    NextKey222.Debug:Error("EVENTS: Cannot show teleport window - Addon or ToggleTeleportWindow not available")
                end
            end)
        else
            NextKey222.Debug:User("EVENTS: Invite has no matching application: " .. name)
        end
    else
        NextKey222.Debug:User("EVENTS: PUG Helper not enabled - skipping auto travel window")
    end
    
    NextKey222.Performance:StopProfile("OnGroupInviteConfirmation")
end

function Events:OnChallengeModeCompleted(mapID, level)
    NextKey222.Performance:StartProfile("OnChallengeModeCompleted")
    
    -- Only count runs at +7 or higher
    if not level or level < 7 then
        NextKey222.Debug:Dev("events", "Skipping run counter for level", level, "- only +7 and higher count")
        NextKey222.Performance:StopProfile("OnChallengeModeCompleted")
        return
    end
    
    -- Increment run counters for tracked items in this dungeon
    if NextKey.DungeonCards then
        NextKey.SafeRun(function()
            local card = NextKey.DungeonCards.dungeons[mapID]
            if not card then
                NextKey222.Debug:Dev("events", "No dungeon card found for mapID", mapID)
                NextKey222.Performance:StopProfile("OnChallengeModeCompleted")
                return
            end
            
            -- Increment counters for all tracked items (both default and custom)
            for itemID in pairs(card.trackedItems) do
                NextKey.DungeonCards:IncrementRunCounter(mapID, itemID)
                NextKey222.Debug:Dev("events", "Incremented run counter for tracked item", itemID, "in dungeon", mapID)
            end
            
            for itemID in pairs(card.customTrackedItems) do
                NextKey.DungeonCards:IncrementRunCounter(mapID, itemID)
                NextKey222.Debug:Dev("events", "Incremented run counter for custom tracked item", itemID, "in dungeon", mapID)
            end
            
            -- Save updated run counters to persist them
            NextKey.DungeonCards:SaveLootTracking()
            
            NextKey222.Debug:Dev("events", "Incremented run counters for dungeon", mapID, "level", level, "(+7 or higher)")
        end, "Increment run counters on dungeon completion")
    end
    
    -- Forward to PUG Helper if available
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnChallengeModeCompleted then
        NextKey.SafeRun(NextKey222.PUGHelper.OnChallengeModeCompleted, "PUG Helper challenge mode completed", NextKey222.PUGHelper, mapID, level)
    end
    
    NextKey222.Performance:StopProfile("OnChallengeModeCompleted")
end

-- MARK: Module Interface
function Events:Initialize()
    self:RegisterCoreEvents()
    NextKey222.Debug:Dev("events", "Events module initialized")
    return true
end

function Events:Enable()
    NextKey222.Debug:Dev("events", "Events module enabled")
    return true
end

-- MARK: PHASE 3 - Offline Player Optimization
--- Counts online group members to optimize performance for mixed groups
-- @return number Number of online group members
function Events:GetOnlineGroupMembers()
    local totalMembers = GetNumGroupMembers() or 0
    local onlineCount = 0
    
    for i = 1, totalMembers do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
        if online then
            onlineCount = onlineCount + 1
        end
    end
    
    -- If not in raid, check party members
    if totalMembers == 0 then
        local partyMembers = GetPartyMembers()
        if partyMembers then
            for _, unit in ipairs(partyMembers) do
                if UnitIsConnected(unit) then
                    onlineCount = onlineCount + 1
                end
            end
        end
        -- Add current player if in party
        if IsInGroup() then
            onlineCount = onlineCount + 1
        end
    end
    
    return onlineCount
end

--- Checks if the group has significant offline player presence
-- @return boolean true if 3+ players are offline
function Events:HasSignificantOfflinePlayers()
    local totalMembers = GetNumGroupMembers() or 0
    local onlineCount = self:GetOnlineGroupMembers()
    return (totalMembers - onlineCount) >= 3
end

--- Handles organizer data updates from communications
-- @param sender string The player who sent the data
-- @param organizerData table The organizer data received
function Events:OnOrganizerDataUpdated(sender, organizerData)
    NextKey222.Performance:StartProfile("OnOrganizerDataUpdated")
    NextKey222.Debug:Dev("events", "Received organizer data from", sender)
    
    -- Store organizer data if available
    if NextKey222.OrganizerData then
        NextKey222.OrganizerData:StoreData(sender, organizerData)
    end
    
    -- Notify UI that organizer data has been updated
    if NextKey222.UI and NextKey222.UI.OnOrganizerDataUpdated then
        NextKey222.UI:OnOrganizerDataUpdated(sender, organizerData)
    end
    
    NextKey222.Performance:StopProfile("OnOrganizerDataUpdated")
end

--- Handles organizer data requests from communications
-- @param sender string The player who requested the data
function Events:OnOrganizerDataRequested(sender)
    NextKey222.Performance:StartProfile("OnOrganizerDataRequested")
    NextKey222.Debug:Dev("events", "Received organizer data request from", sender)
    
    -- Respond by sharing our organizer data
    if NextKey222.Communications and NextKey222.Communications.ShareOrganizerData then
        NextKey222.Communications:ShareOrganizerData()
    end
    
    NextKey222.Performance:StopProfile("OnOrganizerDataRequested")
end

--- Handles group optimization requests from communications
-- @param sender string The player who requested optimization
-- @param optimizationData table The optimization parameters
function Events:OnGroupOptimizationRequested(sender, optimizationData)
    NextKey222.Performance:StartProfile("OnGroupOptimizationRequested")
    NextKey222.Debug:Dev("events", "Received group optimization request from", sender)
    
    -- Process optimization request if available
    if NextKey222.Organizer then
        NextKey222.Organizer:ProcessOptimizationRequest(sender, optimizationData)
    end
    
    NextKey222.Performance:StopProfile("OnGroupOptimizationRequested")
end

--- Handles group optimization results from communications
-- @param sender string The player who sent the results
-- @param optimizationResults table The optimization results
function Events:OnGroupOptimizationResults(sender, optimizationResults)
    NextKey222.Performance:StartProfile("OnGroupOptimizationResults")
    NextKey222.Debug:Dev("events", "Received group optimization results from", sender)
    
    -- Store optimization results if available
    if NextKey222.Organizer then
        NextKey222.Organizer:StoreOptimizationResults(sender, optimizationResults)
    end
    
    -- Notify UI that optimization results are available
    if NextKey222.UI and NextKey222.UI.OnGroupOptimizationResults then
        NextKey222.UI:OnGroupOptimizationResults(sender, optimizationResults)
    end
    
    NextKey222.Performance:StopProfile("OnGroupOptimizationResults")
end

--- Registers organizer-specific events
function Events:RegisterOrganizerEvents()
    -- Register for organizer data updates
    if NextKey222.Communications then
        NextKey222.Communications:RegisterMessage("ORGANIZER_DATA", function(sender, data)
            Events:OnOrganizerDataUpdated(sender, data)
        end)
    end
    
    -- Register for organizer data requests
    if NextKey222.Communications then
        NextKey222.Communications:RegisterMessage("REQUEST_ORGANIZER_DATA", function(sender, data)
            Events:OnOrganizerDataRequested(sender)
        end)
    end
    
    -- Register for group optimization requests
    if NextKey222.Communications then
        NextKey222.Communications:RegisterMessage("GROUP_OPTIMIZATION_REQUEST", function(sender, data)
            Events:OnGroupOptimizationRequested(sender, data)
        end)
    end
    
    -- Register for group optimization results
    if NextKey222.Communications then
        NextKey222.Communications:RegisterMessage("GROUP_OPTIMIZATION_RESULTS", function(sender, data)
            Events:OnGroupOptimizationResults(sender, data)
        end)
    end
    
    NextKey222.Debug:Dev("events", "Organizer events registered")
end

--- Extends core event registration to include organizer events
function Events:RegisterCoreEvents()
    self:RegisterCoreEvents()
    
    -- Register organizer-specific events
    self:RegisterOrganizerEvents()
    
    NextKey222.Debug:Dev("events", "Core and organizer events registered")
end

return Events