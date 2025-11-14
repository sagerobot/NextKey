local _, NextKey222 = ...

-- MARK: Backward Compatibility Shim
-- This file maintains backward compatibility while utils are split into domain-specific modules.
-- All functions forward to their respective specialized modules.
-- TODO: Remove this shim after all modules are updated to use specialized utils directly.

local Utils = {}
NextKey222.Utils = Utils
NextKey222.RegisterModule("Utils", Utils)

-- MARK: Time Utilities (forwarded to TimeUtils)

function Utils.currentTime()
    if NextKey222.TimeUtils then
        return NextKey222.TimeUtils.currentTime()
    end
    -- Fallback implementation
    if type(GetServerTime) == "function" then
        local ok, value = pcall(GetServerTime)
        if ok and type(value) == "number" then
            return value
        end
    end
    if type(time) == "function" then
        return time()
    end
    return 0
end

function Utils:GetTime()
    if NextKey222.TimeUtils then
        return NextKey222.TimeUtils:GetTime()
    end
    return self.currentTime()
end

-- MARK: Player Utilities (forwarded to PlayerUtils)

function Utils.safeGetClass(unit)
    if NextKey222.PlayerUtils then
        return NextKey222.PlayerUtils.safeGetClass(unit)
    end
    -- Fallback implementation
    if type(UnitClass) ~= "function" then
        return ""
    end
    local _, class = UnitClass(unit)
    return class or ""
end

function Utils.safeGetName(unit)
    if NextKey222.PlayerUtils then
        return NextKey222.PlayerUtils.safeGetName(unit)
    end
    -- Fallback implementation
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            if realm and realm ~= "" then
                return string.format("%s-%s", name, realm)
            end
            return name
        end
    end
    if type(UnitName) == "function" then
        local name = UnitName(unit)
        if name and name ~= "" then
            return name
        end
    end
    return unit or "Unknown"
end

function Utils.getShortName(fullName)
    if NextKey222.PlayerUtils then
        return NextKey222.PlayerUtils.getShortName(fullName)
    end
    -- Fallback implementation
    if not fullName or fullName == "" then
        return "Unknown"
    end
    return fullName:match("^([^%-]+)") or fullName
end

-- MARK: Communication Utilities (forwarded to CommunicationUtils)

function Utils.encodeTuple(parts)
    if NextKey222.CommunicationUtils then
        return NextKey222.CommunicationUtils.encodeTuple(parts)
    end
    -- Fallback implementation
    for index, value in ipairs(parts) do
        parts[index] = tostring(value or "")
    end
    return table.concat(parts, "|")
end

function Utils.decodeTuple(message)
    if NextKey222.CommunicationUtils then
        return NextKey222.CommunicationUtils.decodeTuple(message)
    end
    -- Fallback implementation
    if type(message) ~= "string" or message == "" then
        return {}
    end
    local fields, index = {}, 1
    for field in message:gmatch("([^|]*)") do
        fields[index] = field
        index = index + 1
    end
    return fields
end

function Utils.chooseCommChannel()
    if NextKey222.CommunicationUtils then
        return NextKey222.CommunicationUtils.chooseCommChannel()
    end
    -- Fallback implementation
    if type(IsInGroup) == "function" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        if type(IsInRaid) == "function" and IsInRaid() then
            return "RAID"
        end
        if IsInGroup() then
            return "PARTY"
        end
    end
    return nil
end

-- MARK: Dungeon Utilities (forwarded to DungeonUtils)

function Utils.normalizeMapID(mapID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils.normalizeMapID(mapID)
    end
    -- Fallback implementation
    local asNumber = tonumber(mapID)
    return asNumber or mapID
end

function Utils:GetSeasonDungeonIndex(dungeonID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:GetSeasonDungeonIndex(dungeonID)
    end
    -- Fallback: return nil
    return nil
end

function Utils:ConvertToRaiderIOKeystoneID(dungeonID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:ConvertToRaiderIOKeystoneID(dungeonID)
    end
    -- Fallback: return ID as-is
    return dungeonID
end

function Utils:ConvertChallengeMapToKeystoneID(challengeMapID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:ConvertChallengeMapToKeystoneID(challengeMapID)
    end
    -- Fallback: return ID as-is
    return challengeMapID
end

function Utils:FindNextKeyDungeonID(rioData)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:FindNextKeyDungeonID(rioData)
    end
    -- Fallback: return nil
    return nil
end

function Utils:GetDungeonAbbreviation(dungeonID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:GetDungeonAbbreviation(dungeonID)
    end
    -- Fallback implementation
    if NextKey_DungeonAliases and NextKey_DungeonAliases[dungeonID] then
        return NextKey_DungeonAliases[dungeonID]
    end
    return "???"
end

function Utils:GetDungeonFullName(dungeonID)
    if NextKey222.DungeonUtils then
        return NextKey222.DungeonUtils:GetDungeonFullName(dungeonID)
    end
    -- Fallback implementation
    if NextKey_DungeonNames and NextKey_DungeonNames[dungeonID] then
        return NextKey_DungeonNames[dungeonID]
    end
    return "Unknown Dungeon"
end

-- MARK: Item Utilities (forwarded to ItemUtils)

function Utils:GetHeroTrackItemLink(itemID)
    if NextKey222.ItemUtils then
        return NextKey222.ItemUtils:GetHeroTrackItemLink(itemID)
    end
    -- Fallback implementation
    local itemLevel = 710
    return string.format("item:%d::::::%d", itemID, itemLevel)
end

-- MARK: Scoring Utilities (forwarded to ScoringUtils)

function Utils:GetIOScoreColor(score)
    if NextKey222.ScoringUtils then
        return NextKey222.ScoringUtils:GetIOScoreColor(score)
    end
    -- Fallback implementation
    local r, g, b = 1, 1, 1
    
    if C_ChallengeMode and C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor then
        local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(score or 0)
        if color then
            r, g, b = color.r or r, color.g or g, color.b or b
        end
    end
    
    if (r == 1 and g == 1 and b == 1) and NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        local rioR, rioG, rioB = NextKey222.RaiderIO:GetScoreColor(score or 0)
        if rioR and rioG and rioB then
            r, g, b = rioR, rioG, rioB
        end
    end
    
    return r, g, b
end

-- MARK: Module Interface

function Utils:Initialize()
    return true
end

return Utils