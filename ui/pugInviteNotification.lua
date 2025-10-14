--[[
NextKey PUG Invite Notification
Shows contextual information when receiving a group invite from LFG

This UI component displays enhanced invite information when a tracked
LFG application results in a group invitation.

Author: NextKey Team
Version: 0.2.0.1
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGInviteNotification = {}
NextKey222.PUGInviteNotification = PUGInviteNotification

-- MARK: Dependencies
local Debug = NextKey222.Debug
local Constants = NextKey222.Constants
local Utils = NextKey222.Utils

-- MARK: Private Variables
local frame = nil
local currentInvite = nil
local notificationTimer = nil
local NOTIFICATION_DURATION = 15 -- seconds

-- MARK: Module Registration
NextKey222.RegisterModule("PUGInviteNotification", PUGInviteNotification)

-- MARK: Public Interface

-- Initialize the invite notification module
function PUGInviteNotification:Initialize()
    Debug:Dev("pughelper", "PUGInviteNotification:Initialize() called")
    Debug:Dev("pughelper", "UIParent is available: " .. tostring(UIParent ~= nil))
    Debug:Dev("pughelper", "Current time: " .. GetTime())
    
    -- Create the UI frame
    self:CreateFrame()
    
    Debug:Dev("pughelper", "PUG Invite Notification initialized")
    return true
end

-- Show the invite notification
function PUGInviteNotification:Show(invite)
    if not frame or not invite or not invite.application then
        Debug:Dev("pughelper", "Cannot show invite notification: missing frame or invite data")
        return
    end
    
    Debug:Dev("pughelper", "Showing invite notification for: " .. invite.application.name)
    
    currentInvite = invite
    
    -- Update the UI with invite information
    self:UpdateInviteInfo()
    
    -- Show the frame
    frame:Show()
    
    -- Start auto-hide timer
    self:StartNotificationTimer()
end

-- Hide the invite notification
function PUGInviteNotification:Hide()
    if frame then
        frame:Hide()
    end
    
    -- Clear timer
    if notificationTimer then
        notificationTimer:Cancel()
        notificationTimer = nil
    end
    
    currentInvite = nil
    Debug:Dev("pughelper", "Invite notification hidden")
end

-- MARK: Private Implementation

-- Create the UI frame
function PUGInviteNotification:CreateFrame()
    if frame then
        return
    end
    
    -- Create main frame
    frame = CreateFrame("Frame", "NextKeyPUGInviteNotification", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(200)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    
    -- Position it in the center of the screen
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    
    -- Set backdrop with error handling
    Debug:Dev("pughelper", "Frame type: " .. type(frame))
    Debug:Dev("pughelper", "SetBackdrop method exists: " .. tostring(frame.SetBackdrop ~= nil))
    Debug:Dev("pughelper", "SetBackdropColor method exists: " .. tostring(frame.SetBackdropColor ~= nil))
    Debug:Dev("pughelper", "SetBackdropBorderColor method exists: " .. tostring(frame.SetBackdropBorderColor ~= nil))
    
    if frame.SetBackdrop then
        Debug:Dev("pughelper", "Setting backdrop with SetBackdrop method")
        frame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
    else
        Debug:Dev("pughelper", "SetBackdrop not available, attempting alternative background")
        -- Try alternative background methods
        if frame.SetBackdropColor then
            frame:SetBackdropColor(0, 0, 0, 0.8)
        else
            Debug:Dev("pughelper", "SetBackdropColor also not available, skipping background")
        end
        
        if frame.SetBackdropBorderColor then
            frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        else
            Debug:Dev("pughelper", "SetBackdropBorderColor also not available, skipping border")
        end
    end
    
    -- Make it movable
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("NextKey - Dungeon Invite")
    frame.title = title
    
    -- Create group name
    local groupName = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupName:SetPoint("TOP", title, "BOTTOM", 0, -15)
    groupName:SetWidth(380)
    groupName:SetJustifyH("CENTER")
    frame.groupName = groupName
    
    -- Create dungeon info
    local dungeonInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dungeonInfo:SetPoint("TOP", groupName, "BOTTOM", 0, -10)
    dungeonInfo:SetWidth(380)
    dungeonInfo:SetJustifyH("CENTER")
    frame.dungeonInfo = dungeonInfo
    
    -- Create key level info
    local keyLevelInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    keyLevelInfo:SetPoint("TOP", dungeonInfo, "BOTTOM", 0, -5)
    keyLevelInfo:SetWidth(380)
    keyLevelInfo:SetJustifyH("CENTER")
    frame.keyLevelInfo = keyLevelInfo
    
    -- Create comment info
    local commentInfo = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    commentInfo:SetPoint("TOP", keyLevelInfo, "BOTTOM", 0, -5)
    commentInfo:SetWidth(380)
    commentInfo:SetJustifyH("CENTER")
    frame.commentInfo = commentInfo
    
    -- Create accept button
    local acceptButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    acceptButton:SetWidth(100)
    acceptButton:SetHeight(25)
    acceptButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 20, 20)
    acceptButton:SetText("Accept")
    acceptButton:SetScript("OnClick", function()
        self:AcceptInvite()
    end)
    frame.acceptButton = acceptButton
    
    -- Create decline button
    local declineButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    declineButton:SetWidth(100)
    declineButton:SetHeight(25)
    declineButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -20, 20)
    declineButton:SetText("Decline")
    declineButton:SetScript("OnClick", function()
        self:DeclineInvite()
    end)
    frame.declineButton = declineButton
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Hide initially
    frame:Hide()
    
    Debug:Dev("pughelper", "Invite notification frame created")
end

-- Update invite information in the UI
function PUGInviteNotification:UpdateInviteInfo()
    if not frame or not currentInvite or not currentInvite.application then
        return
    end
    
    local app = currentInvite.application
    
    -- Update group name
    frame.groupName:SetText(app.name)
    
    -- Get dungeon information
    local dungeonInfo = NextKey222.PUGHelper:GetDungeonInfo(app.dungeonID)
    local dungeonName = dungeonInfo and dungeonInfo.name or "Unknown Dungeon"
    
    -- Update dungeon info
    frame.dungeonInfo:SetText("Dungeon: " .. dungeonName)
    
    -- Update key level info
    local keyText = "Key Level: " .. (app.keyLevel > 0 and tostring(app.keyLevel) or "Unknown")
    frame.keyLevelInfo:SetText(keyText)
    
    -- Update comment info
    local commentText = ""
    if app.comment and app.comment ~= "" then
        commentText = "Comment: " .. app.comment
    elseif app.voiceChat and app.voiceChat ~= "" then
        commentText = "Voice: " .. app.voiceChat
    end
    frame.commentInfo:SetText(commentText)
    
    Debug:Dev("pughelper", "Invite notification updated with: " .. app.name)
end

-- Start the auto-hide timer
function PUGInviteNotification:StartNotificationTimer()
    -- Clear existing timer
    if notificationTimer then
        notificationTimer:Cancel()
    end
    
    -- Start new timer
    notificationTimer = C_Timer.NewTimer(NOTIFICATION_DURATION, function()
        Debug:Dev("pughelper", "Invite notification auto-hide timer expired")
        self:Hide()
    end)
end

-- Accept the invite
function PUGInviteNotification:AcceptInvite()
    if not currentInvite then
        return
    end
    
    Debug:Dev("pughelper", "Accepting invite: " .. currentInvite.name)
    
    -- Accept the group invite
    AcceptGroup()
    
    -- Hide the notification
    self:Hide()
end

-- Decline the invite
function PUGInviteNotification:DeclineInvite()
    if not currentInvite then
        return
    end
    
    Debug:Dev("pughelper", "Declining invite: " .. currentInvite.name)
    
    -- Decline the group invite
    DeclineGroup()
    
    -- Hide the notification
    self:Hide()
end

-- MARK: Cleanup
function PUGInviteNotification:Cleanup()
    Debug:Dev("pughelper", "PUGInviteNotification cleanup called")
    
    -- Hide the frame
    self:Hide()
    
    -- Clear timer
    if notificationTimer then
        notificationTimer:Cancel()
        notificationTimer = nil
    end
end