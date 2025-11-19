local _, NextKey222 = ...

-- MARK: Activity to Map ID
-- Maps LFG activity IDs to Blizzard challenge mode map IDs
-- This allows us to convert from C_LFGList activity IDs to portal data keys

local ActivityToDungeonMap = {}
NextKey222.ActivityToDungeonMap = ActivityToDungeonMap
NextKey222.RegisterModule("ActivityToDungeonMap", ActivityToDungeonMap)

-- MARK: TWW S3 Activity Map
-- Activity IDs from C_LFGList.GetActivityInfoTable() -> Challenge Map IDs from C_ChallengeMode
local activityToMapID = {
    -- TWW Season 3 dungeons (ALL CONFIRMED from debug output!)
    [1281] = 499,  -- Priory of the Sacred Flame
    [1285] = 505,  -- The Dawnbreaker
    [1694] = 542,  -- Eco-Dome Al'dani
    [1016] = 391,  -- Tazavesh: Streets of Wonder
    [1284] = 503,  -- Ara-Kara, City of Echoes
    [1017] = 392,  -- Tazavesh: So'leah's Gambit
    [1550] = 525,  -- Operation: Floodgate
    [699] = 378,   -- Halls of Atonement
}

--- Convert LFG activity ID to challenge mode map ID
--- @param activityID number The LFG activity ID
--- @return number|nil The challenge mode map ID, or nil if not found
function ActivityToDungeonMap:GetMapIDFromActivityID(activityID)
    if not activityID then return nil end
    
    local mapID = activityToMapID[activityID]
    if mapID then
        NextKey222.Debug:Dev("activitymap", "Converted activityID " .. activityID .. " to mapID " .. mapID)
        return mapID
    end
    
    NextKey222.Debug:Dev("activitymap", "No mapping found for activityID " .. activityID)
    return nil
end

--- Get dungeon name from activity ID (via map ID lookup)
--- @param activityID number The LFG activity ID
--- @return string|nil The dungeon name, or nil if not found
function ActivityToDungeonMap:GetDungeonNameFromActivityID(activityID)
    local mapID = self:GetMapIDFromActivityID(activityID)
    if not mapID then return nil end
    
    if NextKey222.DungeonNameService then
        return NextKey222.DungeonNameService:GetFullName(mapID)
    end
    
    return nil
end

-- MARK: Module Init
function ActivityToDungeonMap:Initialize()
    local count = 0
    for _ in pairs(activityToMapID) do count = count + 1 end
    NextKey222.Debug:Dev("activitymap", "ActivityToDungeonMap initialized with " .. count .. " mappings")
    return true
end

return ActivityToDungeonMap