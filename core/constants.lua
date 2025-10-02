-- NextKey constants and configuration
local _, NextKey222 = ...

-- Constants module
local Constants = {
    COMM_PREFIX = "NKEY1",
    COMM_OPCODES = {
        SELECT = "SELECT",
        SYNC = "SYNC",
        KEYSTONE_UPDATE = "KEYSTONE_UPDATE", -- Deprecated - LibOpenRaid handles keystones
        PREFERENCE_UPDATE = "PREFERENCE_UPDATE"
    }
}

NextKey222.Constants = Constants
NextKey222.RegisterModule("Constants", Constants)

-- Module interface
function Constants:Initialize()
    return true
end

-- Default settings
Constants.DEFAULTS = {
    global = {
        leaderSettings = {
            autoSuggestEnabled = false,
            defaultSortMode = "HighestKeyLevel",
        },
        teleport = {
            showHearthstone = false,
        },
        debug = {
            enabled = true,  -- Enable debug by default for testing
            players = {},
            addForm = { best = {} },
        },
    },
    char = {
        liveRuns = {},
        targetedItems = {},
        dungeonRunCounts = {},
        mythicPlus = {
            activeSeason = nil,
            seasons = {},
        },
    },
}

return Constants