local _, NextKey222 = ...

-- MARK: Module Definition
-- DungeonNameMatcher - Parse dungeon names from LFG group titles
-- Matches common abbreviations and patterns against season dungeon data
local DungeonNameMatcher = {}
NextKey222.DungeonNameMatcher = DungeonNameMatcher
NextKey222.RegisterModule("DungeonNameMatcher", DungeonNameMatcher)

-- MARK: Private Implementation

-- Common abbreviation patterns for TWW Season 3 dungeons
local ABBREVIATION_PATTERNS = {
    -- TWW Season 3 dungeons
    ["priory"] = true, ["psf"] = true, ["sacred flame"] = true, ["priory of the sacred flame"] = true,
    ["dawnbreaker"] = true, ["db"] = true, ["dawn"] = true, ["the dawnbreaker"] = true,
    ["eco"] = true, ["eco-dome"] = true, ["aldani"] = true, ["eco-dome aldani"] = true,
    ["taza"] = true, ["tazavesh"] = true, ["streets"] = true, ["tazavesh streets"] = true,
    ["ara"] = true, ["kara"] = true, ["ara-kara"] = true, ["city of echoes"] = true,
    ["gambit"] = true, ["tazavesh gambit"] = true, ["so'leah"] = true,
    ["flood"] = true, ["floodgate"] = true, ["opf"] = true, ["operation floodgate"] = true, ["operation: floodgate"] = true,
    ["halls"] = true, ["hoa"] = true, ["atonement"] = true, ["halls of atonement"] = true,
    
    -- Legacy Season 1 patterns (still valid if these dungeons return)
    ["city of threads"] = true, ["cot"] = true, ["threads"] = true,
    ["stonevault"] = true, ["sv"] = true, ["vault"] = true,
    ["mists"] = true, ["tirna scithe"] = true, ["mists of tirna scithe"] = true,
    ["necrotic wake"] = true, ["nw"] = true, ["wake"] = true,
    ["siege of boralus"] = true, ["sob"] = true, ["boralus"] = true,
    ["grim batol"] = true, ["gb"] = true, ["batol"] = true,
}

-- Strip common formatting and normalize text
local function normalize_text(text)
    if not text then return "" end
    
    -- Remove WoW color codes like |cFFFFFFFF or |r
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    
    -- Remove item links like |Hkeystone:... or |Kq630|k
    text = string.gsub(text, "|H.-|h.-|h", "")
    text = string.gsub(text, "|K.-|k", "")
    
    -- Remove + and numbers (key levels)
    text = string.gsub(text, "%+%d+", "")
    text = string.gsub(text, "%d+", "")
    
    -- Convert to lowercase and trim
    text = string.lower(text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    
    return text
end

-- Check if text contains a known abbreviation
local function find_abbreviation(text)
    if not text or text == "" then return nil end
    
    local normalized = normalize_text(text)
    
    -- Check exact matches first
    if ABBREVIATION_PATTERNS[normalized] then
        NextKey222.Debug:Dev("dungeonNameMatcher", "Exact match found:", normalized)
        return normalized
    end
    
    -- Check if any pattern is contained in the text
    for pattern, _ in pairs(ABBREVIATION_PATTERNS) do
        if string.find(normalized, pattern, 1, true) then -- plain text search
            NextKey222.Debug:Dev("dungeonNameMatcher", "Pattern match found:", pattern, "in", normalized)
            return pattern
        end
    end
    
    return nil
end

-- Map abbreviation to dungeon ID by checking portal data
local function map_abbreviation_to_dungeon_id(abbreviation)
    if not abbreviation then return nil end
    
    local portalData = NextKey222.Addon and NextKey222.Addon.PortalData
    if not portalData or not portalData.dungeons then
        NextKey222.Debug:Error("DungeonNameMatcher: PortalData not available")
        return nil
    end
    
    local abbrev_lower = string.lower(abbreviation)
    
    -- Search through all dungeons
    for dungeonID, data in pairs(portalData.dungeons) do
        local name_lower = string.lower(data.name or "")
        local alias_lower = string.lower(data.alias or "")
        
        -- Check if abbreviation matches name or alias
        if string.find(name_lower, abbrev_lower, 1, true) or 
           string.find(alias_lower, abbrev_lower, 1, true) or
           string.find(abbrev_lower, alias_lower, 1, true) then
            NextKey222.Debug:Dev("dungeonNameMatcher", "Mapped", abbreviation, "to dungeon ID", dungeonID, "(" .. data.name .. ")")
            return dungeonID
        end
    end
    
    return nil
end

-- MARK: Public API

--- Try to extract dungeon ID from a group name/title
--- @param groupName string The LFG group name/title
--- @return number|nil dungeonID The matched dungeon ID, or nil if no match
function DungeonNameMatcher:ParseGroupName(groupName)
    NextKey222.Debug:Dev("dungeonNameMatcher", "Parsing group name:", groupName)
    
    if not groupName or groupName == "" then
        NextKey222.Debug:Dev("dungeonNameMatcher", "Empty group name, cannot parse")
        return nil
    end
    
    -- Find abbreviation in the text
    local abbreviation = find_abbreviation(groupName)
    if not abbreviation then
        NextKey222.Debug:Dev("dungeonNameMatcher", "No known abbreviation found in:", groupName)
        return nil
    end
    
    -- Map abbreviation to dungeon ID
    local dungeonID = map_abbreviation_to_dungeon_id(abbreviation)
    if dungeonID then
        NextKey222.Debug:User("dungeonNameMatcher", "Matched '" .. groupName .. "' to dungeon ID " .. dungeonID)
        return dungeonID
    end
    
    NextKey222.Debug:Dev("dungeonNameMatcher", "Could not map abbreviation", abbreviation, "to dungeon ID")
    return nil
end

--- Try to extract key level from a group name
--- @param groupName string The LFG group name/title
--- @return number|nil level The key level, or nil if not found
function DungeonNameMatcher:ParseKeyLevel(groupName)
    if not groupName then return nil end
    
    -- Look for +N or N+ patterns
    local level = string.match(groupName, "%+(%d+)")
    if level then
        return tonumber(level)
    end
    
    level = string.match(groupName, "(%d+)%+")
    if level then
        return tonumber(level)
    end
    
    -- Look for standalone numbers (less reliable)
    level = string.match(groupName, "(%d+)")
    if level and tonumber(level) >= 2 and tonumber(level) <= 35 then
        return tonumber(level)
    end
    
    return nil
end

-- MARK: Module Initialization

function DungeonNameMatcher:Initialize()
    NextKey222.Debug:Dev("dungeonNameMatcher", "DungeonNameMatcher initialized")
    return true
end

return DungeonNameMatcher