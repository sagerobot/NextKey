-- MARK: Player IO Data Package Structure
-- Standardized structure for sharing IO data between players via AceComm
-- This ensures consistent calculations between dungeon view and tooltips

local _, NextKey222 = ...

---@class PlayerIOPackage
---@field playerName string Full player name with realm
---@field timestamp number When the data was last updated
---@field totalIO number Player's total IO score
---@field isFakePlayer boolean Whether this is generated fake player data
---@field dungeonScores table<number, DungeonIOData> Per-dungeon scoring data
---@field version string Data structure version for compatibility

---@class DungeonIOData  
---@field score number IO score for this dungeon
---@field level number Best key level completed
---@field chests number Chest count (0=overtime, 1=timed, 2=2-chest, 3=3-chest)
---@field isInTime boolean Whether the best run was completed in time
---@field timestamp number When this dungeon score was last updated

local PlayerIODataStructure = {
    -- Structure version for compatibility checking
    CURRENT_VERSION = "1.0.0",
    
    -- Communication protocol constants
    COMM_PREFIX = "NKIO", -- NextKey IO sharing
    COMM_OPCODES = {
        SHARE_IO = "SHARE_IO",
        REQUEST_IO = "REQUEST_IO"
    }
}

NextKey222.PlayerIODataStructure = PlayerIODataStructure

--- Creates a standardized IO package for a player
--- @param playerName string The full player name with realm
--- @param isFakePlayer boolean Whether this is fake player data
--- @return PlayerIOPackage The standardized IO data package
function PlayerIODataStructure:CreatePlayerIOPackage(playerName, isFakePlayer)
    return {
        playerName = playerName,
        timestamp = GetTime(),
        totalIO = 0,
        isFakePlayer = isFakePlayer or false,
        dungeonScores = {},
        version = self.CURRENT_VERSION
    }
end

--- Adds dungeon score data to an IO package
--- @param ioPackage PlayerIOPackage The IO package to update
--- @param dungeonID number The dungeon ID
--- @param score number The IO score
--- @param level number The key level
--- @param chests number Number of chests (0-3)
--- @param isInTime boolean Whether completed in time
function PlayerIODataStructure:AddDungeonScore(ioPackage, dungeonID, score, level, chests, isInTime)
    ioPackage.dungeonScores[dungeonID] = {
        score = score or 0,
        level = level or 0,
        chests = chests or 0,
        isInTime = isInTime or false,
        timestamp = GetTime()
    }
    
    -- Recalculate total IO (sum of all dungeon scores)
    ioPackage.totalIO = 0
    for _, dungeonData in pairs(ioPackage.dungeonScores) do
        ioPackage.totalIO = ioPackage.totalIO + (dungeonData.score or 0)
    end
    
    -- Update package timestamp
    ioPackage.timestamp = GetTime()
end

--- Gets dungeon score from an IO package
--- @param ioPackage PlayerIOPackage The IO package to query
--- @param dungeonID number The dungeon ID to get score for
--- @return number The IO score for this dungeon (0 if not found)
function PlayerIODataStructure:GetDungeonScore(ioPackage, dungeonID)
    if not ioPackage or not ioPackage.dungeonScores then
        return 0
    end
    
    local dungeonData = ioPackage.dungeonScores[dungeonID]
    return dungeonData and dungeonData.score or 0
end

--- Gets total IO score from an IO package
--- @param ioPackage PlayerIOPackage The IO package to query
--- @return number The total IO score
function PlayerIODataStructure:GetTotalScore(ioPackage)
    return ioPackage and ioPackage.totalIO or 0
end

--- Validates an IO package structure
--- @param ioPackage table The data to validate
--- @return boolean Whether the package is valid
function PlayerIODataStructure:ValidatePackage(ioPackage)
    if type(ioPackage) ~= "table" then
        return false
    end
    
    local required = {"playerName", "timestamp", "totalIO", "dungeonScores", "version"}
    for _, field in ipairs(required) do
        if ioPackage[field] == nil then
            return false
        end
    end
    
    -- Check version compatibility (major version must match)
    local packageMajor = ioPackage.version:match("^(%d+)")
    local currentMajor = self.CURRENT_VERSION:match("^(%d+)")
    
    return packageMajor == currentMajor
end

return PlayerIODataStructure