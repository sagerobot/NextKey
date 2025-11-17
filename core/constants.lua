-- NextKey constants and configuration
local _, NextKey222 = ...

-- MARK: Constants Module Definition
-- Following NextKey222 standards for centralized constants
-- Phase 1 Refactor: Enhanced domain namespacing for better organization

local Constants = {
    -- MARK: Communication Constants
    -- Single source of truth for all communication settings
    COMM_PREFIX = "NKEY1", -- NextKey communication prefix (versioned)
    
    -- Communication opcodes for inter-player messaging
    COMM_OPCODES = {
        SELECT = "SELECT",           -- Leader selects a keystone for the group
        SYNC = "SYNC",              -- Request/send party member data sync
        SUGGEST = "SUGGEST",        -- Auto-suggest keystone from leader
        PREFERENCE = "PREFERENCE",  -- Player dungeon preference updates
        LOOT_TARGET = "LOOT_TARGET", -- Player loot target updates
        PLAYER_IO_UPDATE = "PLAYER_IO_UPDATE", -- New standardized IO data sharing
        REQUEST_PLAYER_IO = "REQUEST_PLAYER_IO", -- Request IO data from party members
        
        -- Organizer opcodes
        ORG_POLL_REQUEST = "ORG_POLL_REQUEST",   -- Organizer poll request
        ORG_POLL_RESPONSE = "ORG_POLL_RESPONSE", -- Organizer poll response
        ORGANIZER_DATA = "ORGANIZER_DATA",       -- Organizer data sharing
        REQUEST_ORGANIZER_DATA = "REQUEST_ORGANIZER_DATA", -- Request organizer data
        
        -- Legacy opcodes
        PREFERENCE_UPDATE = "PREFERENCE_UPDATE",
        DUNGEON_SCORES = "DUNGEON_SCORES"
    },
    
    -- Phase 4 Refactor: Communication events for event-driven architecture
    -- These events are announced by Communications and consumed by domain modules
    COMM_EVENTS = {
        -- Player IO Events
        PLAYER_IO_RECEIVED = "COMM_PLAYER_IO_RECEIVED",
        PLAYER_IO_REQUEST = "COMM_PLAYER_IO_REQUEST",
        
        -- Keystone Events
        KEYSTONE_RECEIVED = "COMM_KEYSTONE_RECEIVED",
        KEYSTONE_REQUEST = "COMM_KEYSTONE_REQUEST",
        
        -- Teleport Events
        TELEPORT_SELECT = "COMM_TELEPORT_SELECT",
        
        -- Organizer Events
        ORG_POLL_REQUEST = "COMM_ORG_POLL_REQUEST",
        ORG_POLL_RESPONSE = "COMM_ORG_POLL_RESPONSE",
        ORG_ADDON_PING = "COMM_ORG_ADDON_PING",
        ORG_ADDON_PONG = "COMM_ORG_ADDON_PONG",
        ORG_DATA = "COMM_ORG_DATA",
        ORG_DATA_REQUEST = "COMM_ORG_DATA_REQUEST",
        
        -- Preference Events
        PREFERENCE_UPDATE = "COMM_PREFERENCE_UPDATE",
        
        -- Legacy Events
        DUNGEON_SCORES = "COMM_DUNGEON_SCORES",
        SYNC = "COMM_SYNC"
    },
    
    -- Phase 4.2: Keystone state change events for event-driven architecture
    -- These events are announced by Keystones module when keystone state changes
    KEYSTONE_EVENTS = {
        -- Player Keystone Events
        PLAYER_DETECTED = "NEXTKEY_KEYSTONE_PLAYER_DETECTED",
        PLAYER_REMOVED = "NEXTKEY_KEYSTONE_PLAYER_REMOVED",
        
        -- Party/Guild Keystone Events
        SCAN_COMPLETE = "NEXTKEY_KEYSTONE_SCAN_COMPLETE",
        GUILD_RECEIVED = "NEXTKEY_KEYSTONE_GUILD_RECEIVED",
        
        -- Teleport Target Events
        TELEPORT_SELECTED = "NEXTKEY_KEYSTONE_TELEPORT_SELECTED",
        TELEPORT_CLEARED = "NEXTKEY_KEYSTONE_TELEPORT_CLEARED"
    },
    
    -- Message throttling and reliability settings
    COMM_SETTINGS = {
        THROTTLE_INTERVAL = 2,      -- Seconds between messages per player
        MAX_RETRIES = 3,            -- Maximum retry attempts for failed sends
        TIMEOUT = 10,               -- Message response timeout in seconds
        MAX_MESSAGE_SIZE = 8192     -- Maximum serialized message size
    },
    
    -- MARK: UI Constants
    -- User interface configuration and display settings
    UI = {
        -- Window dimensions and layout
        WINDOW_WIDTH = 800,
        WINDOW_HEIGHT = 645,
        
        -- Compact mode thresholds
        COMPACT_MODE_PLAYER_THRESHOLD = 5,
        
        -- Animation and timing
        DEBOUNCE_DELAY = 0.3,       -- Seconds to wait before rendering updates
        FADE_DURATION = 0.15,       -- UI element fade in/out duration
        
        -- Frame pacing for performance
        MAX_WORK_ITEMS_PER_FRAME = 5, -- Maximum operations per frame tick
    },
    
    -- MARK: Performance Constants
    -- Performance limits and optimization thresholds
    PERFORMANCE = {
        -- Memory management
        MAX_MEMORY_BASELINE = 10 * 1024 * 1024,  -- 10MB baseline (bytes)
        MAX_MEMORY_PEAK = 50 * 1024 * 1024,      -- 50MB peak (bytes)
        
        -- Timing targets
        MAX_LOAD_TIME = 2.0,        -- Maximum addon load time (seconds)
        MAX_UI_RESPONSE = 0.1,      -- Maximum UI response time (seconds)
        
        -- Cache lifetimes
        PROFILE_CACHE_TTL = 300,    -- Profile cache TTL (5 minutes)
        IO_CACHE_TTL = 300,          -- IO data cache TTL (5 minutes)
        
        -- Throttling intervals
        ROSTER_UPDATE_THROTTLE = 1.0,  -- Group roster update throttle (seconds)
        LFG_UPDATE_THROTTLE = 0.5,     -- LFG list update throttle (seconds)
    },
    
    -- MARK: Keystone Constants
    -- Mythic+ keystone and dungeon configuration
    KEYSTONES = {
        -- Level ranges
        MIN_KEY_LEVEL = 2,
        MAX_KEY_LEVEL = 35,
        
        -- Reward thresholds
        HERO_TRACK_MIN_LEVEL = 7,   -- Minimum level for Hero track rewards
        MYTH_TRACK_MIN_LEVEL = 10,  -- Minimum level for Myth track rewards
        
        -- MARK: Item Bonus IDs (The War Within Season 3)
        -- Based on real in-game item data analysis
        -- Using common bonus IDs that mark items as Hero track without forcing specific ilvls
        ITEM_BONUS_IDS = {
            -- Hero Track M+ - Common subset from all Hero items
            -- 12350 = Hero 1/8 upgrade level
            -- 10390 = Mythic+ difficulty marker
            -- 6652 = Season 3 marker
            -- 10255 = Can be upgraded marker
            HERO_TRACK = "12350:10390:6652:10255",
            
            -- Future-proofing for other difficulties
            MYTH_TRACK = "12350:10390:6652:10255",  -- Placeholder
        },
    },
    
    -- MARK: Organizer Constants
    -- M+ Group Organizer configuration
    ORGANIZER = {
        -- Group composition
        MAX_GROUPS = 8,
        PLAYERS_PER_GROUP = 5,
        
        -- Role requirements per group
        TANKS_PER_GROUP = 1,
        HEALERS_PER_GROUP = 1,
        DPS_PER_GROUP = 3,
        
        -- Poll/survey settings
        POLL_TIMEOUT = 60,          -- Poll timeout (seconds)
        
        -- Animation timing
        CARD_MOVE_DURATION = 0.2,   -- Card movement animation duration
    },
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