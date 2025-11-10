--[[
NextKey PUG Travel Assistant
Provides travel assistance when joining a PUG group

This UI component helps players quickly travel to the dungeon
when they join a new PUG group.

Author: NextKey Team
Version: 0.5.32
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
    
    -- Initialize teleport spells
    self:InitializeTeleportSpells()
    
    -- Create the UI frame
    self:CreateFrame()
    
    Debug:Dev("pughelper", "PUG Travel Assistant initialized")
    return true
end

-- Show the travel assistant
function PUGTravelAssistant:Show(groupInfo)
    Debug:User("PUG Travel Assistant: Show called for dungeon ID: " .. tostring(groupInfo and groupInfo.dungeonID))

    if not groupInfo or not groupInfo.dungeonID then
        Debug:Error("PUG Travel Assistant: Show - Missing groupInfo or dungeonID")
        return
    end

    Debug:User("PUG Travel Assistant: Group info - Name: " .. (groupInfo.name or "Unknown") ..
               ", Dungeon ID: " .. tostring(groupInfo.dungeonID) ..
               ", Key Level: " .. tostring(groupInfo.keyLevel or 0))

    -- Create a fake keystone object to pass to the teleport window
    -- This makes the teleport window think it's a regular keystone teleport
    local fakeKeyInfo = {
        dungeonID = groupInfo.dungeonID,
        level = groupInfo.keyLevel or 0,
        ownerName = "PUG Group",
        source = "dungeon_portal", -- Use dungeon_portal source to indicate it's not a real player key
    }

    Debug:User("PUG Travel Assistant: Setting teleport target key for PUG mode to dungeon ID: " .. tostring(fakeKeyInfo.dungeonID))

    -- Set the teleport target using the existing system
    if NextKey222.Addon and NextKey222.Addon.SetTeleportTargetKey then
        NextKey222.Addon:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
        Debug:User("PUG Travel Assistant: Teleport target set successfully")
    else
        Debug:Error("PUG Travel Assistant: Cannot set teleport target - Addon or SetTeleportTargetKey not available")
        return
    end
    
    -- CRITICAL: Set PUG context before showing window
    Debug:User("PUG Travel Assistant: Setting PUG mode context for teleport window")
    if NextKey222.Addon and NextKey222.Addon.SetTeleportWindowContext then
        NextKey222.Addon:SetTeleportWindowContext({ mode = "PUG" })
    else
        Debug:Error("PUG Travel Assistant: Cannot set PUG context - SetTeleportWindowContext not available")
    end

    -- Toggle the main teleport window
    if NextKey222.Addon and NextKey222.Addon.ToggleTeleportWindow then
        NextKey222.Addon:ToggleTeleportWindow()
        Debug:User("PUG Travel Assistant: Main teleport window toggled for PUG travel")
    else
        Debug:Error("PUG Travel Assistant: Cannot toggle teleport window - Addon or ToggleTeleportWindow not available")
    end
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

-- REMOVED: InitializeTeleportSpells, as this is now handled by the main teleport window
function PUGTravelAssistant:InitializeTeleportSpells()
    -- This function is no longer needed. The main teleport window handles all teleport spell logic.
    Debug:Dev("pughelper", "InitializeTeleportSpells is deprecated.")
end

-- REMOVED: CreateFrame, as this is now handled by the main teleport window
function PUGTravelAssistant:CreateFrame()
    -- This function is no longer needed. The main teleport window is used instead.
    Debug:Dev("pughelper", "CreateFrame is deprecated.")
end

-- REMOVED: UpdateTravelInfo and related UI update functions
function PUGTravelAssistant:UpdateTravelInfo()
    -- This function is no longer needed. The main teleport window manages its own UI updates.
    Debug:Dev("pughelper", "UpdateTravelInfo is deprecated.")
end

-- REMOVED: All UI update and action functions, as they are now handled by the main teleport window.
-- The main teleport window already has logic for cooldowns, spell checking, and casting.

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