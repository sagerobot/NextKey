--[[
NextKey PUG Getaway UI
Provides quick exit options after dungeon completion

This UI component helps players quickly leave the dungeon
after completing a Mythic+ run with a PUG group.

Author: NextKey Team
Version: 0.2.0.1
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGGetawayUI = {}
NextKey222.PUGGetawayUI = PUGGetawayUI

-- MARK: Dependencies
local Debug = NextKey222.Debug
local Constants = NextKey222.Constants
local Utils = NextKey222.Utils

-- MARK: Private Variables
local frame = nil
local currentGroupInfo = nil
local hearthstoneInfo = {}

-- MARK: Module Registration
NextKey222.RegisterModule("PUGGetawayUI", PUGGetawayUI)

-- MARK: Public Interface

-- Initialize the getaway UI module
function PUGGetawayUI:Initialize()
    Debug:Dev("pughelper", "PUGGetawayUI:Initialize() called")
    
    -- Create the UI frame
    self:CreateFrame()
    
    Debug:Dev("pughelper", "PUG Getaway UI initialized")
    return true
end

-- Show the getaway UI
function PUGGetawayUI:Show(groupInfo)
    if not frame or not groupInfo then
        Debug:Dev("pughelper", "Cannot show getaway UI: missing frame or group info")
        return
    end
    
    Debug:Dev("pughelper", "Showing getaway UI for: " .. (groupInfo.name or "Unknown"))
    
    currentGroupInfo = groupInfo
    
    -- Update hearthstone information
    self:UpdateHearthstoneInfo()
    
    -- Update the UI with group information
    self:UpdateGetawayInfo()
    
    -- Show the frame
    frame:Show()
end

-- Hide the getaway UI
function PUGGetawayUI:Hide()
    if frame then
        frame:Hide()
    end
    
    currentGroupInfo = nil
    Debug:Dev("pughelper", "Getaway UI hidden")
end

-- MARK: Private Implementation

-- Create the UI frame
function PUGGetawayUI:CreateFrame()
    if frame then
        return
    end
    
    -- Create main frame
    frame = CreateFrame("Frame", "NextKeyPUGGetawayUI", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(95)
    
    -- Position it in the center of the screen
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Set backdrop
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Make it movable
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("NextKey - Dungeon Complete!")
    frame.title = title
    
    -- Create completion message
    local completionMessage = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    completionMessage:SetPoint("TOP", title, "BOTTOM", 0, -15)
    completionMessage:SetWidth(380)
    completionMessage:SetJustifyH("CENTER")
    frame.completionMessage = completionMessage
    
    -- Create results section
    local resultsSection = CreateFrame("Frame", nil, frame)
    resultsSection:SetWidth(380)
    resultsSection:SetHeight(60)
    resultsSection:SetPoint("TOP", completionMessage, "BOTTOM", 0, -15)
    frame.resultsSection = resultsSection
    
    -- Results section title
    local resultsTitle = resultsSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    resultsTitle:SetPoint("TOP", resultsSection, "TOP", 0, 0)
    resultsTitle:SetText("Run Results")
    resultsSection.title = resultsTitle
    
    -- Dungeon name and level
    local dungeonInfo = resultsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dungeonInfo:SetPoint("TOP", resultsTitle, "BOTTOM", 0, -5)
    dungeonInfo:SetWidth(380)
    dungeonInfo:SetJustifyH("CENTER")
    resultsSection.dungeonInfo = dungeonInfo
    
    -- Completion time (placeholder - would need to be tracked)
    local completionTime = resultsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    completionTime:SetPoint("TOP", dungeonInfo, "BOTTOM", 0, -5)
    completionTime:SetWidth(380)
    completionTime:SetJustifyH("CENTER")
    resultsSection.completionTime = completionTime
    
    -- Create exit options section
    local exitOptionsSection = CreateFrame("Frame", nil, frame)
    exitOptionsSection:SetWidth(380)
    exitOptionsSection:SetHeight(120)
    exitOptionsSection:SetPoint("TOP", resultsSection, "BOTTOM", 0, -15)
    frame.exitOptionsSection = exitOptionsSection
    
    -- Exit options title
    local exitOptionsTitle = exitOptionsSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    exitOptionsTitle:SetPoint("TOP", exitOptionsSection, "TOP", 0, 0)
    exitOptionsTitle:SetText("Quick Exit Options")
    exitOptionsSection.title = exitOptionsTitle
    
    -- Hearthstone button
    local hearthButton = CreateFrame("Button", nil, exitOptionsSection, "UIPanelButtonTemplate")
    hearthButton:SetWidth(150)
    hearthButton:SetHeight(25)
    hearthButton:SetPoint("TOP", exitOptionsTitle, "BOTTOM", -80, -10)
    hearthButton:SetText("Use Hearthstone")
    hearthButton:SetScript("OnClick", function()
        self:UseHearthstone()
    end)
    exitOptionsSection.hearthButton = hearthButton
    
    -- Hearthstone status
    local hearthStatus = exitOptionsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hearthStatus:SetPoint("TOP", hearthButton, "BOTTOM", 0, -5)
    hearthStatus:SetWidth(150)
    hearthStatus:SetJustifyH("CENTER")
    exitOptionsSection.hearthStatus = hearthStatus
    
    -- Leave group button
    local leaveButton = CreateFrame("Button", nil, exitOptionsSection, "UIPanelButtonTemplate")
    leaveButton:SetWidth(150)
    leaveButton:SetHeight(25)
    leaveButton:SetPoint("TOP", exitOptionsTitle, "BOTTOM", 80, -10)
    leaveButton:SetText("Leave Group")
    leaveButton:SetScript("OnClick", function()
        self:LeaveGroup()
    end)
    exitOptionsSection.leaveButton = leaveButton
    
    -- Leave group info
    local leaveInfo = exitOptionsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    leaveInfo:SetPoint("TOP", leaveButton, "BOTTOM", 0, -5)
    leaveInfo:SetWidth(150)
    leaveInfo:SetJustifyH("CENTER")
    leaveInfo:SetText("Leave party and return to own realm")
    exitOptionsSection.leaveInfo = leaveInfo
    
    -- Exit dungeon button
    local exitButton = CreateFrame("Button", nil, exitOptionsSection, "UIPanelButtonTemplate")
    exitButton:SetWidth(150)
    exitButton:SetHeight(25)
    exitButton:SetPoint("TOP", hearthButton, "BOTTOM", 0, -25)
    exitButton:SetText("Exit Dungeon")
    exitButton:SetScript("OnClick", function()
        self:ExitDungeon()
    end)
    exitOptionsSection.exitButton = exitButton
    
    -- Exit dungeon info
    local exitInfo = exitOptionsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    exitInfo:SetPoint("TOP", exitButton, "BOTTOM", 0, -5)
    exitInfo:SetWidth(150)
    exitInfo:SetJustifyH("CENTER")
    exitInfo:SetText("Teleport out of dungeon")
    exitOptionsSection.exitInfo = exitInfo
    
    -- Stay in group button
    local stayButton = CreateFrame("Button", nil, exitOptionsSection, "UIPanelButtonTemplate")
    stayButton:SetWidth(150)
    stayButton:SetHeight(25)
    stayButton:SetPoint("TOP", leaveButton, "BOTTOM", 0, -25)
    stayButton:SetText("Stay in Group")
    stayButton:SetScript("OnClick", function()
        self:StayInGroup()
    end)
    exitOptionsSection.stayButton = stayButton
    
    -- Stay in group info
    local stayInfo = exitOptionsSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    stayInfo:SetPoint("TOP", stayButton, "BOTTOM", 0, -5)
    stayInfo:SetWidth(150)
    stayInfo:SetJustifyH("CENTER")
    stayInfo:SetText("Continue with current group")
    exitOptionsSection.stayInfo = stayInfo
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Hide initially
    frame:Hide()
    
    Debug:Dev("pughelper", "Getaway UI frame created")
end

-- Update getaway information in the UI
function PUGGetawayUI:UpdateGetawayInfo()
    if not frame or not currentGroupInfo then
        return
    end
    
    -- Update completion message
    frame.completionMessage:SetText("Congratulations on completing the dungeon!")
    
    -- Update results section
    self:UpdateResultsSection()
    
    -- Update exit options
    self:UpdateExitOptions()
    
    Debug:Dev("pughelper", "Getaway UI updated")
end

-- Update results section
function PUGGetawayUI:UpdateResultsSection()
    if not currentGroupInfo or not frame.resultsSection then
        return
    end
    
    -- Update dungeon info
    local dungeonInfo = NextKey222.PUGHelper:GetDungeonInfo(currentGroupInfo.completedMapID or currentGroupInfo.dungeonID)
    local dungeonName = dungeonInfo and dungeonInfo.name or "Unknown Dungeon"
    local keyLevel = currentGroupInfo.completedLevel or currentGroupInfo.keyLevel or "Unknown"
    
    frame.resultsSection.dungeonInfo:SetText(dungeonName .. " - Key Level " .. keyLevel)
    
    -- Update completion time (placeholder - would need to be tracked during the run)
    if currentGroupInfo.completedAt and currentGroupInfo.joinedAt then
        local duration = currentGroupInfo.completedAt - currentGroupInfo.joinedAt
        frame.resultsSection.completionTime:SetText("Completion time: " .. SecondsToTime(duration))
    else
        frame.resultsSection.completionTime:SetText("Completion time: Unknown")
    end
end

-- Update exit options
function PUGGetawayUI:UpdateExitOptions()
    if not frame.exitOptionsSection then
        return
    end
    
    -- Update hearthstone option
    self:UpdateHearthstoneOption()
    
    -- Update leave group option
    self:UpdateLeaveGroupOption()
    
    -- Update exit dungeon option
    self:UpdateExitDungeonOption()
end

-- Update hearthstone information
function PUGGetawayUI:UpdateHearthstoneInfo()
    hearthstoneInfo = {
        hasItem = false,
        itemName = "Hearthstone",
        cooldownRemaining = 0,
        bindLocation = "Unknown"
    }
    
    -- Check for Hearthstone in bags
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot)
            if itemID == 6948 then -- Hearthstone item ID
                hearthstoneInfo.hasItem = true
                break
            end
        end
        if hearthstoneInfo.hasItem then
            break
        end
    end
    
    -- Check for Innkeeper's Daughter or other hearthstone alternatives
    if not hearthstoneInfo.hasItem then
        -- Check for alternatives (can be expanded)
        local alternatives = {
            64488 -- The Innkeeper's Daughter
        }
        
        for _, itemID in ipairs(alternatives) do
            if IsEquippedItem(itemID) then
                hearthstoneInfo.hasItem = true
                hearthstoneInfo.itemName = select(1, GetItemInfo(itemID))
                break
            end
        end
    end
    
    -- Check for hearthstone spell (if using Garrison Hearthstone, etc.)
    if not hearthstoneInfo.hasItem then
        -- Check for hearthstone spell
        if IsSpellKnown(8690) then -- Hearthstone spell ID
            hearthstoneInfo.hasItem = true
        end
    end
    
    -- Check cooldown
    if hearthstoneInfo.hasItem then
        local start, duration = GetSpellCooldown(8690) -- Hearthstone spell ID
        if start and duration and start > 0 then
            hearthstoneInfo.cooldownRemaining = duration - (GetTime() - start)
        end
        
        -- Get bind location
        hearthstoneInfo.bindLocation = GetBindLocation()
    end
    
    Debug:Dev("pughelper", "Hearthstone info updated: " .. (hearthstoneInfo.hasItem and "Available" or "Not available"))
end

-- Update hearthstone option
function PUGGetawayUI:UpdateHearthstoneOption()
    if not frame.exitOptionsSection then
        return
    end
    
    if hearthstoneInfo.hasItem then
        if hearthstoneInfo.cooldownRemaining > 0 then
            frame.exitOptionsSection.hearthButton:Disable()
            frame.exitOptionsSection.hearthStatus:SetText("Cooldown: " .. SecondsToTime(hearthstoneInfo.cooldownRemaining))
        else
            frame.exitOptionsSection.hearthButton:Enable()
            frame.exitOptionsSection.hearthStatus:SetText("Bound to: " .. hearthstoneInfo.bindLocation)
        end
    else
        frame.exitOptionsSection.hearthButton:Disable()
        frame.exitOptionsSection.hearthStatus:SetText("No hearthstone available")
    end
end

-- Update leave group option
function PUGGetawayUI:UpdateLeaveGroupOption()
    if not frame.exitOptionsSection then
        return
    end
    
    -- Check if player is in a group
    if IsInGroup() then
        frame.exitOptionsSection.leaveButton:Enable()
        
        -- Check if player is group leader
        if UnitIsGroupLeader("player") then
            frame.exitOptionsSection.leaveInfo:SetText("Leave party (you are leader)")
        else
            frame.exitOptionsSection.leaveInfo:SetText("Leave party")
        end
    else
        frame.exitOptionsSection.leaveButton:Disable()
        frame.exitOptionsSection.leaveInfo:SetText("Not in a group")
    end
end

-- Update exit dungeon option
function PUGGetawayUI:UpdateExitDungeonOption()
    if not frame.exitOptionsSection then
        return
    end
    
    -- Check if player is in a dungeon
    local _, instanceType = GetInstanceInfo()
    if instanceType == "scenario" or instanceType == "party" then
        frame.exitOptionsSection.exitButton:Enable()
        frame.exitOptionsSection.exitInfo:SetText("Teleport out of dungeon")
    else
        frame.exitOptionsSection.exitButton:Disable()
        frame.exitOptionsSection.exitInfo:SetText("Not in a dungeon")
    end
end

-- Use hearthstone
function PUGGetawayUI:UseHearthstone()
    if not hearthstoneInfo.hasItem then
        Debug:User("No hearthstone available")
        return
    end
    
    if hearthstoneInfo.cooldownRemaining > 0 then
        Debug:User("Hearthstone is on cooldown: " .. SecondsToTime(hearthstoneInfo.cooldownRemaining))
        return
    end
    
    -- Use hearthstone
    UseItemByName(hearthstoneInfo.itemName)
    Debug:User("Using hearthstone: " .. hearthstoneInfo.itemName)
    
    -- Hide UI after using
    C_Timer.After(2, function()
        self:Hide()
    end)
end

-- Leave group
function PUGGetawayUI:LeaveGroup()
    if not IsInGroup() then
        Debug:User("Not in a group")
        return
    end
    
    -- Leave group
    LeaveParty()
    Debug:User("Leaving group")
    
    -- Hide UI after leaving
    C_Timer.After(2, function()
        self:Hide()
    end)
end

-- Exit dungeon
function PUGGetawayUI:ExitDungeon()
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "scenario" and instanceType ~= "party" then
        Debug:User("Not in a dungeon")
        return
    end
    
    -- Exit dungeon
    LFGTeleport(true) -- true means leave the instance
    Debug:User("Exiting dungeon")
    
    -- Hide UI after exiting
    C_Timer.After(2, function()
        self:Hide()
    end)
end

-- Stay in group
function PUGGetawayUI:StayInGroup()
    Debug:User("Staying in group")
    
    -- Just hide the UI
    self:Hide()
end

-- MARK: Cleanup
function PUGGetawayUI:Cleanup()
    Debug:Dev("pughelper", "PUGGetawayUI cleanup called")
    
    -- Hide the frame
    self:Hide()
end