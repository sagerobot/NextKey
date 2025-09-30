-- NextKey constants and configuration
local _, NS = ...

-- Communication constants
NS.COMM_PREFIX = "NKEY1"
NS.COMM_OPCODE = {
    SELECT = "SELECT",
    SYNC = "SYNC"
}

-- Default settings
NS.DEFAULTS = {
    global = {
        leaderSettings = {
            autoSuggestEnabled = false,
            defaultSortMode = "HighestKeyLevel",
        },
        teleport = {
            showHearthstone = false,
        },
        debug = {
            enabled = false,
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

return NS