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
    frame.frame:Show()
    
    -- Start auto-hide timer
    self:StartNotificationTimer()
end

-- Hide the invite notification
function PUGInviteNotification:Hide()
    if frame then
        frame.frame:Hide()
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

-- Create the UI frame using AceGUI and configuration wrappers
function PUGInviteNotification:CreateFrame()
    if frame then
        return
    end
    
    -- Use UIComponents factory to create standardized dialog frame
    frame = NextKey222.UIComponents:CreateFrame("dialog", UIParent, {
        width = 400,
        height = 200,
        backdropType = "dark_dialog",
        colorScheme = "dark"
    })
    
    -- Set frame properties for proper layering
    frame.frame:SetFrameStrata("DIALOG")
    frame.frame:SetFrameLevel(100)
    
    -- Position it in the center of the screen
    frame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    
    -- Make it movable using AceGUI frame
    frame.frame:SetMovable(true)
    frame.frame:RegisterForDrag("LeftButton")
    frame.frame:SetScript("OnDragStart", frame.frame.StartMoving)
    frame.frame:SetScript("OnDragStop", frame.frame.StopMovingOrSizing)
    
    Debug:Dev("pughelper", "PUG invite notification frame created with AceGUI and configuration wrappers")
    
    -- Create title using UIComponents factory
    local title = NextKey222.UIComponents:CreateText("header", nil, {
        text = "NextKey - Dungeon Invite",
        width = 380
    })
    title.frame:SetPoint("TOP", frame.frame, "TOP", 0, -20)
    frame.title = title
    
    -- Create group name using UIComponents factory
    local groupName = NextKey222.UIComponents:CreateText("body", nil, {
        width = 380,
        justifyH = "CENTER"
    })
    groupName.frame:SetPoint("TOP", title.frame, "BOTTOM", 0, -15)
    frame.groupName = groupName
    
    -- Create dungeon info using UIComponents factory
    local dungeonInfo = NextKey222.UIComponents:CreateText("small", nil, {
        width = 380,
        justifyH = "CENTER"
    })
    dungeonInfo.frame:SetPoint("TOP", groupName.frame, "BOTTOM", 0, -10)
    frame.dungeonInfo = dungeonInfo
    
    -- Create key level info using UIComponents factory
    local keyLevelInfo = NextKey222.UIComponents:CreateText("small", nil, {
        width = 380,
        justifyH = "CENTER"
    })
    keyLevelInfo.frame:SetPoint("TOP", dungeonInfo.frame, "BOTTOM", 0, -5)
    frame.keyLevelInfo = keyLevelInfo
    
    -- Create comment info using UIComponents factory
    local commentInfo = NextKey222.UIComponents:CreateText("small", nil, {
        width = 380,
        justifyH = "CENTER"
    })
    commentInfo.frame:SetPoint("TOP", keyLevelInfo.frame, "BOTTOM", 0, -5)
    frame.commentInfo = commentInfo
    
    -- Create accept button using UIComponents factory
    local acceptButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Accept",
        onClick = function()
            self:AcceptInvite()
        end
    })
    acceptButton.frame:SetPoint("BOTTOMLEFT", frame.frame, "BOTTOM", 20, 20)
    frame.acceptButton = acceptButton
    
    -- Create decline button using UIComponents factory
    local declineButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Decline",
        onClick = function()
            self:DeclineInvite()
        end
    })
    declineButton.frame:SetPoint("BOTTOMRIGHT", frame.frame, "BOTTOM", -20, 20)
    frame.declineButton = declineButton
    
    -- Create close button using native close button (still needed for X button)
    local closeButton = CreateFrame("Button", nil, frame.frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame.frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    Debug:Dev("pughelper", "PUG invite notification buttons created with UIComponents factory")
    
    -- Hide initially
    frame.frame:Hide()
    
    Debug:Dev("pughelper", "Invite notification frame created with pure AceGUI components")
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