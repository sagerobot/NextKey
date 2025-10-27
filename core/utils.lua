local _, NextKey222 = ...

-- MARK: Utility Functions
local Utils = {}
NextKey222.Utils = Utils
NextKey222.RegisterModule("Utils", Utils)

function Utils.currentTime()
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

function Utils.normalizeMapID(mapID)
    local asNumber = tonumber(mapID)
    return asNumber or mapID
end

function Utils.safeGetClass(unit)
    if type(UnitClass) ~= "function" then
        return ""
    end
    local _, class = UnitClass(unit)
    return class or ""
end

function Utils.safeGetName(unit)
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

function Utils.encodeTuple(parts)
    for index, value in ipairs(parts) do
        parts[index] = tostring(value or "")
    end
    return table.concat(parts, "|")
end

function Utils.decodeTuple(message)
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

function Utils.getShortName(fullName)
    if not fullName or fullName == "" then
        return "Unknown"
    end
    return fullName:match("^([^%-]+)") or fullName
end

-- MARK: Dungeon ID Conversion Functions
-- Helper function to get season dungeon index for RaiderIO array access
function Utils:GetSeasonDungeonIndex(dungeonID)
    -- TWW Season 3 dungeon mapping using NextKey dungeon IDs as keys
    -- Maps NextKey IDs to RaiderIO array positions (1-8)
    local dungeonOrder = {
        [503] = 1,  -- Ara-Kara, City of Echoes (NextKey: 503 → RaiderIO keystone_instance: 503)
        [524] = 2,  -- The Dawnbreaker (NextKey: 524 → RaiderIO keystone_instance: 505)
        [526] = 3,  -- Eco-Dome Al'dani (NextKey: 526 → RaiderIO keystone_instance: 542)
        [377] = 4,  -- Halls of Atonement (NextKey: 377 → RaiderIO keystone_instance: 378)
        [525] = 5,  -- Operation: Floodgate (NextKey: 525 → RaiderIO keystone_instance: 525)
        [523] = 6,  -- Priory of the Sacred Flame (NextKey: 523 → RaiderIO keystone_instance: 499)
        [401] = 7,  -- Tazavesh: Streets of Wonder (NextKey: 401 → RaiderIO keystone_instance: 391)
        [402] = 8,  -- Tazavesh: So'leah's Gambit (NextKey: 402 → RaiderIO keystone_instance: 392)
    }
    return dungeonOrder[dungeonID]
end

-- Helper to convert NextKey dungeon IDs to RaiderIO keystone_instance IDs
function Utils:ConvertToRaiderIOKeystoneID(dungeonID)
    -- Mapping from NextKey dungeon IDs to RaiderIO keystone_instance IDs
    local idMapping = {
        [503] = 503,  -- Ara-Kara, City of Echoes
        [524] = 505,  -- The Dawnbreaker: NextKey uses 524, RaiderIO uses 505
        [526] = 542,  -- Eco-Dome Al'dani: NextKey uses 526, RaiderIO uses 542  
        [377] = 378,  -- Halls of Atonement
        [525] = 525,  -- Operation: Floodgate (same)
        [523] = 499,  -- Priory of the Sacred Flame: NextKey uses 523, RaiderIO uses 499
        [401] = 391,  -- Tazavesh: Streets of Wonder: NextKey uses 401, RaiderIO uses 391
        [402] = 392,  -- Tazavesh: So'leah's Gambit: NextKey uses 402, RaiderIO uses 392
        [2441] = 392, -- Tazavesh: So'leah's Gambit (keystone form): Maps to same RaiderIO ID as 402
    }
    return idMapping[dungeonID] or dungeonID
end

-- DEPRECATED: Portal data now uses Blizzard challenge map IDs directly
-- No conversion needed - kept for backward compatibility only
function Utils:ConvertChallengeMapToKeystoneID(challengeMapID)
    -- Portal data updated to use correct Blizzard IDs (499, 542, 378, 525, 503, 392, 391, 505)
    -- No conversion needed, return ID as-is
    return challengeMapID
end

-- Reverse mapping: Find NextKey dungeon ID from RaiderIO dungeon data
function Utils:FindNextKeyDungeonID(rioData)
    if not rioData or not rioData.dungeon then
        return nil
    end
    
    local dungeon = rioData.dungeon
    
    -- Create reverse mapping: RaiderIO keystone_instance/id -> NextKey dungeon ID
    local reverseMapping = {
        [503] = 503,  -- Ara-Kara, City of Echoes
        [505] = 524,  -- The Dawnbreaker  
        [542] = 526,  -- Eco-Dome Al'dani
        [378] = 377,  -- Halls of Atonement
        [525] = 525,  -- Operation: Floodgate
        [499] = 523,  -- Priory of the Sacred Flame
        [391] = 401,  -- Tazavesh: Streets of Wonder
        [392] = 402,  -- Tazavesh: So'leah's Gambit
        
        -- RaiderIO id field -> NextKey dungeon ID
        [15093] = 503,  -- Ara-Kara
        [14971] = 524,  -- The Dawnbreaker
        [16104] = 526,  -- Eco-Dome Al'dani
        [12831] = 377,  -- Halls of Atonement
        [15452] = 525,  -- Operation: Floodgate
        [14954] = 523,  -- Priory of the Sacred Flame
        [1000001] = 402,  -- Tazavesh: So'leah's Gambit
        [1000000] = 401,  -- Tazavesh: Streets of Wonder
    }
    
    return reverseMapping[dungeon.keystone_instance] or reverseMapping[dungeon.id]
end

-- MARK: Dungeon Name Helpers
function Utils:GetDungeonAbbreviation(dungeonID)
    -- Access global alias data from portals.lua
    if NextKey_DungeonAliases and NextKey_DungeonAliases[dungeonID] then
        return NextKey_DungeonAliases[dungeonID]
    end
    return "???"
end

function Utils:GetDungeonFullName(dungeonID)
    -- Access global name data from portals.lua
    if NextKey_DungeonNames and NextKey_DungeonNames[dungeonID] then
        return NextKey_DungeonNames[dungeonID]
    end
    return "Unknown Dungeon"
end

-- Module interface
function Utils:Initialize()
    return true
end

function Utils:GetTime()
    return self.currentTime()
end

--- Generates a hyperlink for an item with a specific item level.
--- This is used to display the correct Hero track item level in tooltips.
---@param itemID number The base item ID.
---@return string itemLink The formatted item hyperlink.
function Utils:GetHeroTrackItemLink(itemID)
    -- As of TWW S3, Hero track items from M+ are ilvl 710.
    -- Try different approaches for Hero track display
    local itemLevel = 710
    
    -- Method 1: Try with a single bonus ID that might work for Hero track
    -- Method 2: Try with just the item level (no bonus IDs)
    -- Method 3: Try with different bonus ID combinations
    
    -- Let's try a simpler approach first - just set the level
    -- The hyperlink format is: "item:itemID:enchantID:gemID1:gemID2:gemID3:gemID4:suffixID:uniqueID:level:specializationID:rarityID:..."
    -- Format: item:itemID::::::level
    return string.format("item:%d::::::%d", itemID, itemLevel)
end

return Utils