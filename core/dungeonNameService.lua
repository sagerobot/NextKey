local _, NextKey222 = ...

-- MARK: Module Definition
-- DungeonNameService - Centralized dungeon name and metadata lookup
-- Single source of truth for all dungeon-related display and metadata
local DungeonNameService = {}
NextKey222.DungeonNameService = DungeonNameService
NextKey222.RegisterModule("DungeonNameService", DungeonNameService)

-- MARK: Private Implementation

-- Get dungeon data from portal system
-- Portal data now uses Blizzard challenge map IDs directly - no conversion needed
local function get_dungeon_data(dungeonID)
    if not dungeonID then
        return nil
    end
    
    -- Convert to number if string
    local dungeonIDNum = tonumber(dungeonID)
    if not dungeonIDNum then
        Debug:Dev("dungeonNameService", "Invalid dungeonID (not a number):", dungeonID)
        return nil
    end
    
    -- Access NextKey.PortalData which is set by data/portals.lua
    local portalData = NextKey222.Addon and NextKey222.Addon.PortalData
    if not portalData or not portalData.dungeons then
        Debug:Error("DungeonNameService: PortalData not available")
        return nil
    end
    
    -- Direct lookup - portal data uses Blizzard challenge map IDs
    return portalData.dungeons[dungeonIDNum]
end

-- Validate dungeon ID and return error message if invalid
local function validate_dungeon_id(dungeonID)
    if not dungeonID then
        return false, "dungeonID is nil"
    end
    
    local dungeonIDNum = tonumber(dungeonID)
    if not dungeonIDNum then
        return false, "dungeonID is not a number: " .. tostring(dungeonID)
    end
    
    local data = get_dungeon_data(dungeonIDNum)
    if not data then
        return false, "No dungeon data found for ID: " .. tostring(dungeonIDNum)
    end
    
    return true, nil
end

-- MARK: Public API

--- Get the full name of a dungeon
--- @param dungeonID number The dungeon ID
--- @return string The full dungeon name (e.g., "Ara-Kara, City of Echoes")
function DungeonNameService:GetFullName(dungeonID)
    local data = get_dungeon_data(dungeonID)
    if data and data.name then
        Debug:Trace("dungeonNameService", "GetFullName(" .. tostring(dungeonID) .. ") =", data.name)
        return data.name
    end
    
    local fallback = self:GetFallbackName(dungeonID)
    Debug:Dev("dungeonNameService", "GetFullName(" .. tostring(dungeonID) .. ") using fallback:", fallback)
    return fallback
end

--- Get the abbreviated alias of a dungeon
--- @param dungeonID number The dungeon ID
--- @return string The dungeon alias (e.g., "Ara")
function DungeonNameService:GetAlias(dungeonID)
    local data = get_dungeon_data(dungeonID)
    if data and data.alias then
        Debug:Trace("dungeonNameService", "GetAlias(" .. tostring(dungeonID) .. ") =", data.alias)
        return data.alias
    end
    
    Debug:Dev("dungeonNameService", "GetAlias(" .. tostring(dungeonID) .. ") not found, returning '???'")
    return "???"
end

--- Get a formatted dungeon name with level
--- @param dungeonID number The dungeon ID
--- @param level number The keystone level (optional)
--- @return string Formatted name (e.g., "Ara-Kara +15" or "Ara +15")
function DungeonNameService:GetFormattedName(dungeonID, level, useAlias)
    local name
    if useAlias then
        name = self:GetAlias(dungeonID)
    else
        name = self:GetFullName(dungeonID)
    end
    
    if level and tonumber(level) then
        local formatted = string.format("%s +%d", name, level)
        Debug:Trace("dungeonNameService", "GetFormattedName(" .. tostring(dungeonID) .. ", " .. tostring(level) .. ") =", formatted)
        return formatted
    end
    
    return name
end

--- Get the map art ID for a dungeon (used for icon display)
--- @param dungeonID number The dungeon ID
--- @return number|nil The map art ID for textures
function DungeonNameService:GetMapArtID(dungeonID)
    local data = get_dungeon_data(dungeonID)
    if data and data.mapArtID then
        Debug:Trace("dungeonNameService", "GetMapArtID(" .. tostring(dungeonID) .. ") =", data.mapArtID)
        return data.mapArtID
    end
    
    Debug:Dev("dungeonNameService", "GetMapArtID(" .. tostring(dungeonID) .. ") not found")
    return nil
end

--- Get the spell ID for a dungeon (used for teleport functionality)
--- @param dungeonID number The dungeon ID
--- @return number|nil The spell ID for teleport
function DungeonNameService:GetSpellID(dungeonID)
    local data = get_dungeon_data(dungeonID)
    if data and data.spellID then
        Debug:Trace("dungeonNameService", "GetSpellID(" .. tostring(dungeonID) .. ") =", data.spellID)
        return data.spellID
    end
    
    Debug:Dev("dungeonNameService", "GetSpellID(" .. tostring(dungeonID) .. ") not found")
    return nil
end

--- Get all season data for a dungeon
--- @param dungeonID number The dungeon ID
--- @return table|nil Complete dungeon data table { name, alias, spellID, mapArtID }
function DungeonNameService:GetSeasonData(dungeonID)
    local data = get_dungeon_data(dungeonID)
    if data then
        Debug:Trace("dungeonNameService", "GetSeasonData(" .. tostring(dungeonID) .. ") found")
        return data
    end
    
    Debug:Dev("dungeonNameService", "GetSeasonData(" .. tostring(dungeonID) .. ") not found")
    return nil
end

--- Validate a dungeon ID
--- @param dungeonID number The dungeon ID to validate
--- @return boolean valid True if valid, false otherwise
--- @return string|nil error Error message if invalid
function DungeonNameService:ValidateDungeonID(dungeonID)
    return validate_dungeon_id(dungeonID)
end

--- Convert a Challenge Mode Map ID to internal keystone ID
--- @param mapID number The challenge mode map ID
--- @return number The keystone dungeon ID
function DungeonNameService:ConvertChallengeMapID(mapID)
    -- Use Utils conversion if available
    if NextKey222.Utils and NextKey222.Utils.ConvertChallengeMapToKeystoneID then
        local converted = NextKey222.Utils:ConvertChallengeMapToKeystoneID(mapID)
        Debug:Trace("dungeonNameService", "ConvertChallengeMapID(" .. tostring(mapID) .. ") =", converted)
        return converted
    end
    
    -- Fallback: assume same ID
    Debug:Dev("dungeonNameService", "ConvertChallengeMapID(" .. tostring(mapID) .. ") using passthrough (Utils not available)")
    return mapID
end

--- Get a consistent fallback name for unknown dungeons
--- @param dungeonID number The dungeon ID
--- @return string Fallback name with ID for debugging
function DungeonNameService:GetFallbackName(dungeonID)
    if dungeonID then
        return string.format("Unknown Dungeon (ID: %s)", tostring(dungeonID))
    end
    return "Unknown Dungeon"
end

--- Get all current season dungeons
--- @return table|nil Table of dungeon IDs and data for current season
function DungeonNameService:GetAllSeasonDungeons()
    local portalData = NextKey222.Addon and NextKey222.Addon.PortalData
    if not portalData or not portalData.dungeons then
        Debug:Error("DungeonNameService: PortalData not available")
        return nil
    end
    
    Debug:Trace("dungeonNameService", "GetAllSeasonDungeons() found", #portalData.dungeons, "dungeons")
    return portalData.dungeons
end

--- Check if a dungeon exists in the current season
--- @param dungeonID number The dungeon ID to check
--- @return boolean exists True if dungeon exists in current season
function DungeonNameService:DungeonExists(dungeonID)
    local data = get_dungeon_data(dungeonID)
    return data ~= nil
end

-- MARK: Module Initialization

function DungeonNameService:Initialize()
    Debug:Dev("dungeonNameService", "DungeonNameService initialized")
    
    -- Verify portal data is available
    local portalData = NextKey222.Addon and NextKey222.Addon.PortalData
    if not portalData then
        Debug:Error("DungeonNameService: NextKey.PortalData not available at initialization")
        return false
    end
    
    if not portalData.dungeons then
        Debug:Error("DungeonNameService: NextKey.PortalData.dungeons not available")
        return false
    end
    
    -- Log available dungeons
    local count = 0
    for dungeonID, data in pairs(portalData.dungeons) do
        count = count + 1
        Debug:Trace("dungeonNameService", string.format("  [%d] %s (%s)", dungeonID, data.name, data.alias))
    end
    
    Debug:Dev("dungeonNameService", "Loaded", count, "dungeons for season:", portalData.name or "Unknown")
    return true
end

return DungeonNameService