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
    frame.frame:Show()
end

-- Hide the getaway UI
function PUGGetawayUI:Hide()
    if frame then
        frame.frame:Hide()
    end
    
    currentGroupInfo = nil
    Debug:Dev("pughelper", "Getaway UI hidden")
end

-- MARK: Private Implementation

-- Create the UI frame using AceGUI and configuration wrappers
function PUGGetawayUI:CreateFrame()
    if frame then
        return
    end
    
    -- Use UIComponents factory to create standardized dialog frame
    frame = NextKey222.UIComponents:CreateFrame("dialog", UIParent, {
        width = 400,
        height = 300,
        backdropType = "dark_dialog",
        colorScheme = "dark"
    })
    
    -- Set frame properties for proper layering
    frame.frame:SetFrameStrata("DIALOG")
    frame.frame:SetFrameLevel(95)
    
    -- Position it in the center of the screen
    frame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Make it movable using AceGUI frame
    frame.frame:SetMovable(true)
    frame.frame:RegisterForDrag("LeftButton")
    frame.frame:SetScript("OnDragStart", frame.frame.StartMoving)
    frame.frame:SetScript("OnDragStop", frame.frame.StopMovingOrSizing)
    
    Debug:Dev("pughelper", "PUG getaway UI frame created with AceGUI and configuration wrappers")
    
    -- Create title using UIComponents factory
    local title = NextKey222.UIComponents:CreateText("header", nil, {
        text = "NextKey - Dungeon Complete!",
        width = 380
    })
    title.frame:SetPoint("TOP", frame.frame, "TOP", 0, -20)
    frame.title = title
    
    -- Create completion message using UIComponents factory
    local completionMessage = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Congratulations on completing the dungeon!",
        width = 380,
        justifyH = "CENTER"
    })
    completionMessage.frame:SetPoint("TOP", title.frame, "BOTTOM", 0, -15)
    frame.completionMessage = completionMessage
    
    -- Create results section using UIComponents factory
    local resultsSection = NextKey222.UIComponents:CreateFrame("panel", frame.frame, {
        width = 380,
        height = 60,
        backdropType = "tooltip",
        colorScheme = "standard"
    })
    resultsSection.frame:SetPoint("TOP", completionMessage.frame, "BOTTOM", 0, -15)
    frame.resultsSection = resultsSection
    
    -- Results section title using UIComponents factory
    local resultsTitle = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Run Results",
        width = 380,
        justifyH = "CENTER"
    })
    resultsTitle.frame:SetPoint("TOP", resultsSection.frame, "TOP", 0, -5)
    resultsSection.title = resultsTitle
    
    -- Dungeon name and level using UIComponents factory
    local dungeonInfo = NextKey222.UIComponents:CreateText("small", nil, {
        width = 380,
        justifyH = "CENTER"
    })
    dungeonInfo.frame:SetPoint("TOP", resultsTitle.frame, "BOTTOM", 0, -5)
    resultsSection.dungeonInfo = dungeonInfo
    
    -- Completion time using UIComponents factory
    local completionTime = NextKey222.UIComponents:CreateText("small", nil, {
        text = "Completion time: Unknown",
        width = 380,
        justifyH = "CENTER"
    })
    completionTime.frame:SetPoint("TOP", dungeonInfo.frame, "BOTTOM", 0, -5)
    resultsSection.completionTime = completionTime
    
    -- Create exit options section using UIComponents factory
    local exitOptionsSection = NextKey222.UIComponents:CreateFrame("panel", frame.frame, {
        width = 380,
        height = 120,
        backdropType = "tooltip",
        colorScheme = "standard"
    })
    exitOptionsSection.frame:SetPoint("TOP", resultsSection.frame, "BOTTOM", 0, -15)
    frame.exitOptionsSection = exitOptionsSection
    
    -- Exit options title using UIComponents factory
    local exitOptionsTitle = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Quick Exit Options",
        width = 380,
        justifyH = "CENTER"
    })
    exitOptionsTitle.frame:SetPoint("TOP", exitOptionsSection.frame, "TOP", 0, -5)
    exitOptionsSection.title = exitOptionsTitle
    
    -- Exit options title using UIComponents factory
    local exitOptionsTitle = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Quick Exit Options",
        width = 380,
        justifyH = "CENTER"
    })
    exitOptionsTitle.frame:SetPoint("TOP", exitOptionsSection.frame, "TOP", 0, -5)
    exitOptionsSection.title = exitOptionsTitle
    
    Debug:Dev("pughelper", "Creating buttons with UIComponents factory for PUG getaway UI")
    
    -- Hearthstone button using UIComponents factory
    local hearthButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Use Hearthstone",
        onClick = function()
            self:UseHearthstone()
        end
    })
    hearthButton.frame:SetPoint("TOP", exitOptionsTitle.frame, "BOTTOM", -80, -10)
    exitOptionsSection.hearthButton = hearthButton
    
    -- Leave group button using UIComponents factory
    local leaveButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Leave Group",
        onClick = function()
            self:LeaveGroup()
        end
    })
    leaveButton.frame:SetPoint("TOP", exitOptionsTitle.frame, "BOTTOM", 80, -10)
    exitOptionsSection.leaveButton = leaveButton
    
    -- Exit dungeon button using UIComponents factory
    local exitButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Exit Dungeon",
        onClick = function()
            self:ExitDungeon()
        end
    })
    exitButton.frame:SetPoint("TOP", hearthButton.frame, "BOTTOM", 0, -25)
    exitOptionsSection.exitButton = exitButton
    
    -- Stay in group button using UIComponents factory
    local stayButton = NextKey222.UIComponents:CreateButton("select", nil, {
        text = "Stay in Group",
        onClick = function()
            self:StayInGroup()
        end
    })
    stayButton.frame:SetPoint("TOP", leaveButton.frame, "BOTTOM", 0, -25)
    exitOptionsSection.stayButton = stayButton
    
    -- Hearthstone status using UIComponents factory
    local hearthStatus = NextKey222.UIComponents:CreateText("small", nil, {
        width = 150,
        justifyH = "CENTER"
    })
    hearthStatus.frame:SetPoint("TOP", hearthButton.frame, "BOTTOM", 0, -5)
    exitOptionsSection.hearthStatus = hearthStatus
    
    -- Leave group info using UIComponents factory
    local leaveInfo = NextKey222.UIComponents:CreateText("small", nil, {
        text = "Leave party and return to own realm",
        width = 150,
        justifyH = "CENTER"
    })
    leaveInfo.frame:SetPoint("TOP", leaveButton.frame, "BOTTOM", 0, -5)
    exitOptionsSection.leaveInfo = leaveInfo
    
    -- Exit dungeon info using UIComponents factory
    local exitInfo = NextKey222.UIComponents:CreateText("small", nil, {
        text = "Teleport out of dungeon",
        width = 150,
        justifyH = "CENTER"
    })
    exitInfo.frame:SetPoint("TOP", exitButton.frame, "BOTTOM", 0, -5)
    exitOptionsSection.exitInfo = exitInfo
    
    -- Stay in group info using UIComponents factory
    local stayInfo = NextKey222.UIComponents:CreateText("small", nil, {
        text = "Continue with current group",
        width = 150,
        justifyH = "CENTER"
    })
    stayInfo.frame:SetPoint("TOP", stayButton.frame, "BOTTOM", 0, -5)
    exitOptionsSection.stayInfo = stayInfo
    
    -- Create close button using native close button (still needed for X button)
    local closeButton = CreateFrame("Button", nil, frame.frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame.frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Hide initially
    frame.frame:Hide()
    
    Debug:Dev("pughelper", "Getaway UI frame created with pure AceGUI components")
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
    local numBagSlots = NUM_BAG_SLOTS or 4
    for bag = 0, numBagSlots do
        local numSlots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemID = GetContainerItemID and GetContainerItemID(bag, slot)
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