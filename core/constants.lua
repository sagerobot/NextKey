-- NextKey constants and configuration
local _, NextKey222 = ...

-- MARK: Constants Module Definition
-- Following NextKey222 standards for centralized constants
local Constants = {
    -- MARK: Communication Constants
    -- Single source of truth for all communication settings
    COMM_PREFIX = "NKEY1", -- NextKey communication prefix (versioned)
    
    -- Communication opcodes for inter-player messaging
    COMM_OPCODES = {
        SELECT = "SELECT",           -- Leader selects a keystone for the group
        SYNC = "SYNC",              -- Request/send party member data sync
        KEYSTONE_UPDATE = "KEYSTONE_UPDATE", -- Deprecated - LibOpenRaid handles keystones
        SUGGEST = "SUGGEST",        -- Auto-suggest keystone from leader
        PREFERENCE = "PREFERENCE",  -- Player dungeon preference updates
        LOOT_TARGET = "LOOT_TARGET", -- Player loot target updates
        PREFERENCE_UPDATE = "PREFERENCE_UPDATE", -- Legacy preference update opcode
        DUNGEON_SCORES = "DUNGEON_SCORES", -- Dungeon score synchronization (legacy)
        PLAYER_IO_UPDATE = "PLAYER_IO_UPDATE", -- New standardized IO data sharing
        REQUEST_PLAYER_IO = "REQUEST_PLAYER_IO" -- Request IO data from party members
    },
    
    -- Message throttling and reliability settings
    COMM_SETTINGS = {
        THROTTLE_INTERVAL = 2,      -- Seconds between messages per player
        MAX_RETRIES = 3,            -- Maximum retry attempts for failed sends
        TIMEOUT = 10,               -- Message response timeout in seconds
        MAX_MESSAGE_SIZE = 8192     -- Maximum serialized message size
    }
}

NextKey222.Constants = Constants
NextKey222.RegisterModule("Constants", Constants)

-- Module interface
function Constants:Initialize()
    return true
end

-- REMOVED: Deprecated GetDefaults() function
-- Use NextKey222.Defaults from core/config.lua directly

return Constants