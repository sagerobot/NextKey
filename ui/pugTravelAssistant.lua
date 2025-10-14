--[[
NextKey PUG Travel Assistant
Provides travel assistance when joining a PUG group

This UI component helps players quickly travel to the dungeon
when they join a new PUG group.

Author: NextKey Team
Version: 0.2.0.1
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGTravelAssistant = {}
NextKey222.PUGTravelAssistant = PUGTravelAssistant

-- MARK: Dependencies
local Debug = NextKey222.Debug
local Constants = NextKey222.Constants
local Utils = NextKey222.Utils

-- MARK: Private Variables
local frame = nil
local currentGroupInfo = nil
local teleportSpells = {}
local hearthstoneInfo = {}
local SUMMON_REQUEST_COOLDOWN = 30 -- seconds
local lastSummonRequest = 0

-- MARK: Module Registration
NextKey222.RegisterModule("PUGTravelAssistant", PUGTravelAssistant)

-- MARK: Public Interface

-- Initialize the travel assistant module
function PUGTravelAssistant:Initialize()
    Debug:Dev("pughelper", "PUGTravelAssistant:Initialize() called")
    Debug:Dev("pughelper", "UIParent is available: " .. tostring(UIParent ~= nil))
    Debug:Dev("pughelper", "Current time: " .. GetTime())
    
    -- Initialize teleport spells
    self:InitializeTeleportSpells()
    
    -- Create the UI frame
    self:CreateFrame()
    
    Debug:Dev("pughelper", "PUG Travel Assistant initialized")
    return true
end

-- Show the travel assistant
function PUGTravelAssistant:Show(groupInfo)
    if not frame or not groupInfo then
        Debug:Dev("pughelper", "Cannot show travel assistant: missing frame or group info")
        return
    end
    
    Debug:Dev("pughelper", "Showing travel assistant for: " .. (groupInfo.name or "Unknown"))
    
    currentGroupInfo = groupInfo
    
    -- Update hearthstone information
    self:UpdateHearthstoneInfo()
    
    -- Update the UI with group information
    self:UpdateTravelInfo()
    
    -- Show the frame
    frame:Show()
end

-- Hide the travel assistant
function PUGTravelAssistant:Hide()
    if frame then
        frame:Hide()
    end
    
    currentGroupInfo = nil
    Debug:Dev("pughelper", "Travel assistant hidden")
end

-- MARK: Private Implementation

-- Initialize teleport spell information
function PUGTravelAssistant:InitializeTeleportSpells()
    -- Initialize teleport spells for current season dungeons
    -- This will be populated based on the current season data
    
    teleportSpells = {
        -- Example: Ara-Kara, City of Echoes (503)
        [503] = {
            spellName = "Teleport: Ara-Kara",
            spellID = 445424, -- This would be the actual spell ID
            castTime = 5, -- seconds
            cooldown = 1800 -- seconds (30 minutes)
        },
        -- Example: Cinderbrew Meadery (506)
        [506] = {
            spellName = "Teleport: Cinderbrew Meadery",
            spellID = 445418,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: The Stonevault (511)
        [511] = {
            spellName = "Teleport: The Stonevault",
            spellID = 445423,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: City of Threads (507)
        [507] = {
            spellName = "Teleport: City of Threads",
            spellID = 445416,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: The Dawnbreaker (512)
        [512] = {
            spellName = "Teleport: The Dawnbreaker",
            spellID = 445426,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: The Rookery (508)
        [508] = {
            spellName = "Teleport: The Rookery",
            spellID = 445417,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: Darkflame Rift (513)
        [513] = {
            spellName = "Teleport: Darkflame Rift",
            spellID = 445419,
            castTime = 5,
            cooldown = 1800
        },
        -- Example: Priory of the Sacred Flame (505)
        [505] = {
            spellName = "Teleport: Priory of the Sacred Flame",
            spellID = 445414,
            castTime = 5,
            cooldown = 1800
        }
    }
    
    Debug:Dev("pughelper", "Teleport spells initialized")
end

-- Create the UI frame
function PUGTravelAssistant:CreateFrame()
    if frame then
        return
    end
    
    -- Create main frame
    frame = CreateFrame("Frame", "NextKeyPUGTravelAssistant", UIParent)
    frame:SetWidth(350)
    frame:SetHeight(250)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(90)
    
    -- Position it on the right side of the screen
    frame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
    
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
    title:SetText("NextKey - Travel Assistant")
    frame.title = title
    
    -- Create dungeon name
    local dungeonName = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dungeonName:SetPoint("TOP", title, "BOTTOM", 0, -15)
    dungeonName:SetWidth(330)
    dungeonName:SetJustifyH("CENTER")
    frame.dungeonName = dungeonName
    
    -- Create teleport section
    local teleportSection = CreateFrame("Frame", nil, frame)
    teleportSection:SetWidth(330)
    teleportSection:SetHeight(60)
    teleportSection:SetPoint("TOP", dungeonName, "BOTTOM", 0, -15)
    frame.teleportSection = teleportSection
    
    -- Teleport section title
    local teleportTitle = teleportSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    teleportTitle:SetPoint("TOP", teleportSection, "TOP", 0, 0)
    teleportTitle:SetText("Dungeon Teleport")
    teleportSection.title = teleportTitle
    
    -- Teleport button
    local teleportButton = CreateFrame("Button", nil, teleportSection, "UIPanelButtonTemplate")
    teleportButton:SetWidth(120)
    teleportButton:SetHeight(25)
    teleportButton:SetPoint("TOP", teleportTitle, "BOTTOM", 0, -5)
    teleportButton:SetText("Cast Teleport")
    teleportButton:SetScript("OnClick", function()
        self:CastTeleportSpell()
    end)
    teleportSection.teleportButton = teleportButton
    
    -- Teleport status
    local teleportStatus = teleportSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    teleportStatus:SetPoint("TOP", teleportButton, "BOTTOM", 0, -5)
    teleportStatus:SetWidth(330)
    teleportStatus:SetJustifyH("CENTER")
    teleportSection.teleportStatus = teleportStatus
    
    -- Create hearthstone section
    local hearthSection = CreateFrame("Frame", nil, frame)
    hearthSection:SetWidth(330)
    hearthSection:SetHeight(60)
    hearthSection:SetPoint("TOP", teleportSection, "BOTTOM", 0, -10)
    frame.hearthSection = hearthSection
    
    -- Hearthstone section title
    local hearthTitle = hearthSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hearthTitle:SetPoint("TOP", hearthSection, "TOP", 0, 0)
    hearthTitle:SetText("Hearthstone")
    hearthSection.title = hearthTitle
    
    -- Hearthstone button
    local hearthButton = CreateFrame("Button", nil, hearthSection, "UIPanelButtonTemplate")
    hearthButton:SetWidth(120)
    hearthButton:SetHeight(25)
    hearthButton:SetPoint("TOP", hearthTitle, "BOTTOM", 0, -5)
    hearthButton:SetText("Use Hearthstone")
    hearthButton:SetScript("OnClick", function()
        self:UseHearthstone()
    end)
    hearthSection.hearthButton = hearthButton
    
    -- Hearthstone status
    local hearthStatus = hearthSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hearthStatus:SetPoint("TOP", hearthButton, "BOTTOM", 0, -5)
    hearthStatus:SetWidth(330)
    hearthStatus:SetJustifyH("CENTER")
    hearthSection.hearthStatus = hearthStatus
    
    -- Create summon section
    local summonSection = CreateFrame("Frame", nil, frame)
    summonSection:SetWidth(330)
    summonSection:SetHeight(60)
    summonSection:SetPoint("TOP", hearthSection, "BOTTOM", 0, -10)
    frame.summonSection = summonSection
    
    -- Summon section title
    local summonTitle = summonSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    summonTitle:SetPoint("TOP", summonSection, "TOP", 0, 0)
    summonTitle:SetText("Summon Request")
    summonSection.title = summonTitle
    
    -- Summon button
    local summonButton = CreateFrame("Button", nil, summonSection, "UIPanelButtonTemplate")
    summonButton:SetWidth(120)
    summonButton:SetHeight(25)
    summonButton:SetPoint("TOP", summonTitle, "BOTTOM", 0, -5)
    summonButton:SetText("Request Summon")
    summonButton:SetScript("OnClick", function()
        self:RequestSummon()
    end)
    summonSection.summonButton = summonButton
    
    -- Summon status
    local summonStatus = summonSection:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    summonStatus:SetPoint("TOP", summonButton, "BOTTOM", 0, -5)
    summonStatus:SetWidth(330)
    summonStatus:SetJustifyH("CENTER")
    summonSection.summonStatus = summonStatus
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Hide initially
    frame:Hide()
    
    Debug:Dev("pughelper", "Travel assistant frame created")
end

-- Update travel information in the UI
function PUGTravelAssistant:UpdateTravelInfo()
    if not frame or not currentGroupInfo then
        return
    end
    
    -- Update dungeon name
    local dungeonInfo = NextKey222.PUGHelper:GetDungeonInfo(currentGroupInfo.dungeonID)
    local dungeonName = dungeonInfo and dungeonInfo.name or "Unknown Dungeon"
    frame.dungeonName:SetText("Dungeon: " .. dungeonName)
    
    -- Update teleport section
    self:UpdateTeleportSection()
    
    -- Update hearthstone section
    self:UpdateHearthstoneSection()
    
    -- Update summon section
    self:UpdateSummonSection()
    
    Debug:Dev("pughelper", "Travel assistant updated for: " .. dungeonName)
end

-- Update teleport section
function PUGTravelAssistant:UpdateTeleportSection()
    if not currentGroupInfo or not frame.teleportSection then
        return
    end
    
    local dungeonID = currentGroupInfo.dungeonID
    local teleportInfo = teleportSpells[dungeonID]
    
    if teleportInfo then
        -- Check if player has the spell
        local spellName = teleportInfo.spellName
        local hasSpell = IsSpellKnown(teleportInfo.spellID)
        
        if hasSpell then
            -- Check cooldown
            local start, duration = GetSpellCooldown(teleportInfo.spellID)
            local cooldownRemaining = 0
            
            if start and duration and start > 0 then
                cooldownRemaining = duration - (GetTime() - start)
            end
            
            if cooldownRemaining > 0 then
                frame.teleportSection.teleportButton:Disable()
                frame.teleportSection.teleportStatus:SetText("Cooldown: " .. SecondsToTime(cooldownRemaining))
            else
                frame.teleportSection.teleportButton:Enable()
                frame.teleportSection.teleportStatus:SetText("Ready to cast")
            end
        else
            frame.teleportSection.teleportButton:Disable()
            frame.teleportSection.teleportStatus:SetText("Spell not learned")
        end
    else
        frame.teleportSection.teleportButton:Disable()
        frame.teleportSection.teleportStatus:SetText("No teleport available")
    end
end

-- Update hearthstone information
function PUGTravelAssistant:UpdateHearthstoneInfo()
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

-- Update hearthstone section
function PUGTravelAssistant:UpdateHearthstoneSection()
    if not frame.hearthSection then
        return
    end
    
    if hearthstoneInfo.hasItem then
        if hearthstoneInfo.cooldownRemaining > 0 then
            frame.hearthSection.hearthButton:Disable()
            frame.hearthSection.hearthStatus:SetText("Cooldown: " .. SecondsToTime(hearthstoneInfo.cooldownRemaining))
        else
            frame.hearthSection.hearthButton:Enable()
            frame.hearthSection.hearthStatus:SetText("Bound to: " .. hearthstoneInfo.bindLocation)
        end
    else
        frame.hearthSection.hearthButton:Disable()
        frame.hearthSection.hearthStatus:SetText("No hearthstone available")
    end
end

-- Update summon section
function PUGTravelAssistant:UpdateSummonSection()
    if not frame.summonSection then
        return
    end
    
    local timeSinceLastRequest = GetTime() - lastSummonRequest
    local cooldownRemaining = SUMMON_REQUEST_COOLDOWN - timeSinceLastRequest
    
    if cooldownRemaining > 0 then
        frame.summonSection.summonButton:Disable()
        frame.summonSection.summonStatus:SetText("Cooldown: " .. SecondsToTime(cooldownRemaining))
    else
        frame.summonSection.summonButton:Enable()
        frame.summonSection.summonStatus:SetText("Ready to request summon")
    end
end

-- Cast teleport spell
function PUGTravelAssistant:CastTeleportSpell()
    if not currentGroupInfo then
        return
    end
    
    local dungeonID = currentGroupInfo.dungeonID
    local teleportInfo = teleportSpells[dungeonID]
    
    if not teleportInfo then
        Debug:User("No teleport spell available for this dungeon")
        return
    end
    
    -- Check if player has the spell
    if not IsSpellKnown(teleportInfo.spellID) then
        Debug:User("You don't have the teleport spell for this dungeon")
        return
    end
    
    -- Check cooldown
    local start, duration = GetSpellCooldown(teleportInfo.spellID)
    if start and duration and start > 0 then
        local cooldownRemaining = duration - (GetTime() - start)
        Debug:User("Teleport spell is on cooldown: " .. SecondsToTime(cooldownRemaining))
        return
    end
    
    -- Cast the spell
    CastSpellByName(teleportInfo.spellName)
    Debug:User("Casting teleport spell: " .. teleportInfo.spellName)
    
    -- Update UI after casting
    C_Timer.After(1, function()
        self:UpdateTeleportSection()
    end)
end

-- Use hearthstone
function PUGTravelAssistant:UseHearthstone()
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
    
    -- Update UI after using
    C_Timer.After(1, function()
        self:UpdateHearthstoneInfo()
        self:UpdateHearthstoneSection()
    end)
end

-- Request summon
function PUGTravelAssistant:RequestSummon()
    local timeSinceLastRequest = GetTime() - lastSummonRequest
    local cooldownRemaining = SUMMON_REQUEST_COOLDOWN - timeSinceLastRequest
    
    if cooldownRemaining > 0 then
        Debug:User("Summon request is on cooldown: " .. SecondsToTime(cooldownRemaining))
        return
    end
    
    -- Send summon request to party chat
    SendChatMessage("Summon request for " .. (currentGroupInfo and currentGroupInfo.name or "dungeon"), "PARTY")
    lastSummonRequest = GetTime()
    
    Debug:User("Summon request sent to party")
    
    -- Update UI
    self:UpdateSummonSection()
end

-- MARK: Cleanup
function PUGTravelAssistant:Cleanup()
    Debug:Dev("pughelper", "PUGTravelAssistant cleanup called")
    
    -- Hide the frame
    self:Hide()
end