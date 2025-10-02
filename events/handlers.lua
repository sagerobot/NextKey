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
    
    NextKey222.Debug:Print("events", "Core events registered")
end

-- MARK: Core Event Handlers
function Events:OnPlayerEnteringWorld(isLogin, isReload)
    NextKey222.Performance:StartProfile("OnPlayerEnteringWorld")
    
    if isLogin or isReload then
        NextKey222.Debug:Print("events", "Player entering world - login/reload")
        
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
    
    NextKey222.Debug:Print("events", "Group roster updated - refreshing party composition")
    
    -- Update group composition
    if NextKey222.Communications and NextKey222.Communications.SendSync then
        -- Throttled sync when group changes
        C_Timer.After(2, function()
            NextKey.SafeRun(NextKey222.Communications.SendSync, "Auto sync on group change")
        end)
    end
    
    -- Refresh UI if visible (party changes affect keystone display and IO calculations)
    if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
        -- Add extra notice for IO Gain Potential mode
        if NextKey222.UI.IsPartySensitiveSortMode and NextKey222.UI:IsPartySensitiveSortMode() then
            NextKey222.Debug:Print("events", "Party change affects IO Gain Potential calculations - full refresh needed")
        end
        
        NextKey222.Debug:Print("events", "Refreshing UI due to party change")
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
    NextKey222.Debug:Print("events", "Player joined a group")
    
    -- Force immediate keystone scan when joining group
    if NextKey.Keystones and NextKey.Keystones.ScanAllKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanAllKeystones, "Scan all keystones on group join")
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
    NextKey222.Debug:Print("events", "Player left group")
    
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

-- MARK: Module Interface
function Events:Initialize()
    self:RegisterCoreEvents()
    NextKey222.Debug:Print("events", "Events module initialized")
    return true
end

return Events