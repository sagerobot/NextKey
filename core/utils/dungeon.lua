-- MARK: Module Definition
local _, NextKey222 = ...

local DungeonUtils = {}
NextKey222.DungeonUtils = DungeonUtils
NextKey222.RegisterModule("DungeonUtils", DungeonUtils)

-- MARK: Dungeon ID Conversion Functions

--- Normalizes map ID to number if possible
-- @param mapID any Map ID to normalize
-- @return number|any Normalized map ID
function DungeonUtils.normalizeMapID(mapID)
    local asNumber = tonumber(mapID)
    return asNumber or mapID
end

--- Helper function to get season dungeon index for RaiderIO array access
-- @param dungeonID number NextKey dungeon ID
-- @return number|nil RaiderIO array position (1-8)
function DungeonUtils:GetSeasonDungeonIndex(dungeonID)
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

--- Helper to convert NextKey dungeon IDs to RaiderIO keystone_instance IDs
-- @param dungeonID number NextKey dungeon ID
-- @return number RaiderIO keystone_instance ID
function DungeonUtils:ConvertToRaiderIOKeystoneID(dungeonID)
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

--- DEPRECATED: Portal data now uses Blizzard challenge map IDs directly
-- No conversion needed - kept for backward compatibility only
-- @param challengeMapID number Challenge map ID
-- @return number Same ID (no conversion needed)
function DungeonUtils:ConvertChallengeMapToKeystoneID(challengeMapID)
    -- Portal data updated to use correct Blizzard IDs (499, 542, 378, 525, 503, 392, 391, 505)
    -- No conversion needed, return ID as-is
    return challengeMapID
end

--- Reverse mapping: Find NextKey dungeon ID from RaiderIO dungeon data
-- @param rioData table RaiderIO dungeon data
-- @return number|nil NextKey dungeon ID
function DungeonUtils:FindNextKeyDungeonID(rioData)
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

--- Gets dungeon abbreviation for compact display
-- @param dungeonID number Dungeon ID
-- @return string Dungeon abbreviation (3-letter code)
function DungeonUtils:GetDungeonAbbreviation(dungeonID)
    -- Access global alias data from portals.lua
    if NextKey_DungeonAliases and NextKey_DungeonAliases[dungeonID] then
        return NextKey_DungeonAliases[dungeonID]
    end
    return "???"
end

--- Gets full dungeon name
-- @param dungeonID number Dungeon ID
-- @return string Full dungeon name
function DungeonUtils:GetDungeonFullName(dungeonID)
    -- Access global name data from portals.lua
    if NextKey_DungeonNames and NextKey_DungeonNames[dungeonID] then
        return NextKey_DungeonNames[dungeonID]
    end
    return "Unknown Dungeon"
end

-- MARK: Module Interface

function DungeonUtils:Initialize()
    return true
end

return DungeonUtils