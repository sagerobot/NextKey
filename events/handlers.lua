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
    NextKey:RegisterEvent("LFG_LIST_APPLICATION_LIST_UPDATED", function()
        self:OnLFGApplicationListUpdated()
    end)
    
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

function Events:OnGroupRosterUpdate()
    NextKey222.Performance:StartProfile("OnGroupRosterUpdate")
    
    NextKey222.Debug:Dev("events", "Group roster updated - refreshing party composition")
    
    -- Update group composition
    if NextKey222.Communications and NextKey222.Communications.SendSync then
        -- Throttled sync when group changes
        C_Timer.After(2, function()
            NextKey.SafeRun(NextKey222.Communications.SendSync, "Auto sync on group change")
        end)
    end
    
    -- Update and share dungeon scores for IOCalculator
    if NextKey222.IOCalculator then
        C_Timer.After(1, function()
            NextKey.SafeRun(function()
                NextKey222.IOCalculator:UpdateCurrentPlayerScores()
            end, "Update dungeon scores on roster change")
        end)
    end
    
    -- Refresh UI if visible (party changes affect keystone display and IO calculations)
    if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
        -- Add extra notice for IO Gain Potential mode
        if NextKey222.UI.IsPartySensitiveSortMode and NextKey222.UI:IsPartySensitiveSortMode() then
            NextKey222.Debug:Dev("events", "Party change affects IO Gain Potential calculations - full refresh needed")
        end
        
        NextKey222.Debug:Dev("events", "Refreshing UI due to party change")
        C_Timer.After(1, function()
            NextKey.SafeRun(function()
                NextKey222.UI:RefreshResults()
            end, "Auto refresh UI on group change")
        end)
    end
    
    NextKey222.Performance:StopProfile("OnGroupRosterUpdate")
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
    
    -- Forward to PUG Helper if available
    if NextKey222.PUGHelper and NextKey222.PUGHelper.OnGroupInvite then
        NextKey.SafeRun(NextKey222.PUGHelper.OnGroupInvite, "PUG Helper group invite", NextKey222.PUGHelper, name)
    end
    
    NextKey222.Performance:StopProfile("OnGroupInviteConfirmation")
end

function Events:OnChallengeModeCompleted(mapID, level)
    NextKey222.Performance:StartProfile("OnChallengeModeCompleted")
    
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

return Events