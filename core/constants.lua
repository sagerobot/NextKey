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
        REQUEST_PLAYER_IO = "REQUEST_PLAYER_IO" -- Request IO data from party members
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