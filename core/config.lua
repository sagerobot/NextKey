local _, NextKey222 = ...

-- MARK: Configuration Functions
-- Configuration access and management
-- Note: This file loads before boot.lua, so functions are attached later

-- Store config functions in namespace for later attachment
NextKey222.ConfigFunctions = NextKey222.ConfigFunctions or {}

-- MARK: Feature Flags
-- Feature flags for gradual rollout and safety
NextKey222.FeatureFlags = {
    profilesService = true,          -- Enable centralized profiles service
    idMapper = true,                 -- Enable centralized ID mapping
    enhancedCaching = true,          -- Enable advanced profile caching
    debugMode = true                 -- Enable enhanced debug output
}

--- Get the current sort mode from settings
-- @return string The active sort mode, defaults to "HighestKeyLevel"
function NextKey222.ConfigFunctions.GetCurrentSortMode(self)
    if not self.db or not self.db.global then
        return "HighestKeyLevel"
    end
    return self.db.global.leaderSettings.defaultSortMode or "HighestKeyLevel"
end

--- Set the sort mode for dungeon listings
-- @param mode string The sort mode to set
function NextKey222.ConfigFunctions.SetSortMode(self, mode)
    if not self.db or not self.db.global then
        return
    end
    if type(mode) ~= "string" or mode == "" then
        return
    end
    self.db.global.leaderSettings.defaultSortMode = mode
end

--- Check if a feature flag is enabled
-- @param feature string The feature flag name
-- @return boolean True if feature is enabled
function NextKey222.ConfigFunctions.IsFeatureEnabled(self, feature)
    if not feature then return false end
    
    -- Check user settings first (if saved)
    if self.db and self.db.global and self.db.global.features then
        local userSetting = self.db.global.features[feature]
        if userSetting ~= nil then
            return userSetting
        end
    end
    
    -- Fall back to default feature flags
    return NextKey222.FeatureFlags[feature] or false
end

--- Set a feature flag (persisted to saved variables)
-- @param feature string The feature flag name
-- @param enabled boolean Whether to enable the feature
function NextKey222.ConfigFunctions.SetFeatureEnabled(self, feature, enabled)
    if not feature then return end
    
    if not self.db or not self.db.global then
        return
    end
    
    -- Initialize features table if needed
    self.db.global.features = self.db.global.features or {}
    self.db.global.features[feature] = enabled
end

--- Check if hearthstone is enabled in settings
-- @return boolean True if hearthstone functionality is enabled
function NextKey222.ConfigFunctions.IsHearthstoneEnabled(self)
    local tele = self.db and self.db.global and self.db.global.teleport
    return tele and tele.showHearthstone == true
end

--- Ensure debug data structure exists
-- @return table Debug data structure or nil if database not available
function NextKey222.ConfigFunctions.EnsureDebug(self)
    if not self.db or not self.db.global then
        return nil
    end
    local dbg = self.db.global.debug
    dbg.players = dbg.players or {}
    dbg.addForm = dbg.addForm or { best = {} }
    return dbg
end

--- Ensure debug add form data structure exists
-- @return table Debug add form structure
function NextKey222.ConfigFunctions.EnsureDebugAddForm(self)
    local dbg = self:EnsureDebug()
    if dbg then
        dbg.addForm = dbg.addForm or { best = {} }
        return dbg.addForm
    end
    return { best = {} }
end

-- MARK: Default Settings  
-- CANONICAL source of truth for all NextKey defaults
-- Following NextKey222 standards for centralized configuration
NextKey222.Defaults = {
    global = {
        -- Leader settings
        leaderSettings = {
            autoSuggestEnabled = false,
            defaultSortMode = "HighestKeyLevel",
            suggestionDelay = 3
        },
        
        -- Group composition preferences
        groupPreferences = {
            prioritizeHeroism = true,
            prioritizeBattleRes = true
        },
        
        -- Teleport/travel settings
        teleport = {
            showHearthstone = false,
            compactMode = false,
            selectedHearthstoneID = 6948,  -- Default to standard Hearthstone
        },
        
        -- UI preferences
        ui = {
            cardViewEnabled = true,
            showAnimations = true,
            colorblindMode = false,
            framePosition = { x = 0, y = 0 },
            scale = 1.0
        },
        
        -- Communication settings
        communications = {
            throttleInterval = 2,
            maxRetries = 3,
            debugLevel = 0,
            autoSync = true
        },
        
        -- Debug settings
        debug = {
            enabled = false,  -- Disabled by default for release
            categories = {
                keystones = false,
                communications = false,
                comms = false,
                ui = false,
                options = false,
                raiderio = false,
                performance = false,
                events = false,
                startup = false,
                season = false,
                libopenraid = false,
                IOCalculator = false,
                ioc = false
            },
            players = {},
            addForm = { best = {} }
        },
        
        -- Performance monitoring
        performance = {
            enabled = false,
            profileFunctions = false
        },
       
       -- PUG Helper settings
       pugHelper = {
           enabled = true,
           autoAcceptInvites = false,
           showNotifications = true,
           travelAssistant = true,
           getawayUI = true
       },
       
       -- PUG Testing settings
       pugTestScenarios = {
           currentScenarios = {
               invite = "standard",
               travel = "standard",
               getaway = "success"
           },
           eventLogging = false
       }
    },
    
    char = {
        -- Run history and live data
        liveRuns = {},
        keystoneHistory = {},
        
        -- Player preferences
        preferences = {},
        dungeonPreferences = {},
        
        -- Loot tracking
        targetedItems = {},
        dungeonRunCounts = {},
        
        -- Season and score data
        mythicPlus = {
            activeSeason = nil,
            seasons = {},
        },
        seasonData = {
            currentSeason = nil,
            dungeonScores = {},
            runCounts = {}
        }
    },
}

return NextKey222.Defaults