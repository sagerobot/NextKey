--[[
NextKey PUG Helper Group Detection
Determines if current group is PUG (via LFG) vs Guild/Premade
]]

local _, NextKey222 = ...
local PUGHelper = NextKey222.PUGHelper
local Debug = NextKey222.Debug

if not PUGHelper then
    Debug:Error("PUG Helper module not found, cannot add group detection.")
    return
end

-- MARK: Detection

-- Determine if the current group was formed via LFG system (PUG)
-- Returns: "PUG", "GUILD", "PREMADE", or "SOLO"
function PUGHelper:DetectGroupType()
    -- Check for simulated group type (from test UI)
    if NextKey222.PUGHelperTestUI and NextKey222.PUGHelperTestUI.GetSimulatedGroupType then
        local simulated = NextKey222.PUGHelperTestUI:GetSimulatedGroupType()
        if simulated then
            Debug:Dev("pughelper", "Using SIMULATED group type: " .. simulated)
            return simulated
        end
    end
    
    -- Not in a group
    if not IsInGroup() then
        return "SOLO"
    end
    
    -- Check if formed via LFG system
    -- If C_LFGList.GetActiveEntryInfo() returns data, we're in an LFG-formed group
    local lfgActive = C_LFGList.GetActiveEntryInfo()
    if lfgActive then
        Debug:Dev("pughelper", "Group type detected: PUG (has active LFG entry)")
        return "PUG"
    end
    
    -- Check if we have a tracked application that led to this group
    if self.currentGroupInfo and self.currentGroupInfo.viaPUGHelper then
        Debug:Dev("pughelper", "Group type detected: PUG (via PUG Helper tracking)")
        return "PUG"
    end
    
    -- Check if we're in a guild group
    -- Count guild members in the group
    local guildMemberCount = 0
    local totalMembers = 0
    
    local groupType = IsInRaid() and "raid" or "party"
    local numMembers = GetNumGroupMembers()
    
    for i = 1, numMembers do
        local unit = groupType .. i
        if UnitExists(unit) then
            totalMembers = totalMembers + 1
            if UnitIsInMyGuild(unit) then
                guildMemberCount = guildMemberCount + 1
            end
        end
    end
    
    -- If majority are guild members, it's a guild group
    if guildMemberCount >= (totalMembers / 2) then
        Debug:Dev("pughelper", "Group type detected: GUILD (" .. guildMemberCount .. "/" .. totalMembers .. " guild members)")
        return "GUILD"
    end
    
    -- Check if player is in guild members
    if UnitIsInMyGuild("player") and guildMemberCount > 0 then
        Debug:Dev("pughelper", "Group type detected: GUILD (has guild members)")
        return "GUILD"
    end
    
    -- Default: premade group (friends, manual invites, etc.)
    Debug:Dev("pughelper", "Group type detected: PREMADE (default)")
    return "PREMADE"
end

-- Mark current group as PUG-formed (called when accepting LFG invite)
function PUGHelper:MarkGroupAsPUG()
    if not self.currentGroupInfo then
        self.currentGroupInfo = {}
    end
    self.currentGroupInfo.viaPUGHelper = true
    Debug:Dev("pughelper", "Group marked as PUG")
end

-- Get group type info for UI display
function PUGHelper:GetGroupTypeInfo()
    local groupType = self:DetectGroupType()
    
    local info = {
        type = groupType,
        isPUG = (groupType == "PUG"),
        isGuild = (groupType == "GUILD"),
        isPremade = (groupType == "PREMADE"),
        isSolo = (groupType == "SOLO"),
    }
    
    -- Add display text
    if groupType == "PUG" then
        info.displayText = "PUG Group (via LFG)"
        info.color = { r = 0.0, g = 0.8, b = 1.0 } -- Cyan
    elseif groupType == "GUILD" then
        info.displayText = "Guild Group"
        info.color = { r = 0.2, g = 1.0, b = 0.2 } -- Green
    elseif groupType == "PREMADE" then
        info.displayText = "Premade Group"
        info.color = { r = 1.0, g = 0.8, b = 0.0 } -- Gold
    else
        info.displayText = "Solo"
        info.color = { r = 0.7, g = 0.7, b = 0.7 } -- Gray
    end
    
    return info
end