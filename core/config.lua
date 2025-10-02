local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- MARK: Configuration Functions
-- Configuration access and management

--- Get the current sort mode from settings
-- @return string The active sort mode, defaults to "HighestKeyLevel"
function NextKey:GetCurrentSortMode()
    if not self.db or not self.db.global then
        return "HighestKeyLevel"
    end
    return self.db.global.leaderSettings.defaultSortMode or "HighestKeyLevel"
end

--- Set the sort mode for dungeon listings
-- @param mode string The sort mode to set
function NextKey:SetSortMode(mode)
    if not self.db or not self.db.global then
        return
    end
    if type(mode) ~= "string" or mode == "" then
        return
    end
    self.db.global.leaderSettings.defaultSortMode = mode
end

--- Check if hearthstone is enabled in settings
-- @return boolean True if hearthstone functionality is enabled
function NextKey:IsHearthstoneEnabled()
    local tele = self.db and self.db.global and self.db.global.teleport
    return tele and tele.showHearthstone == true
end

-- MARK: Default Settings
-- Default configuration values used during initialization
NextKey222.Defaults = {
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
        preferences = {},
        mythicPlus = {
            activeSeason = nil,
            seasons = {},
        },
    },
}

return NextKey222.Defaults