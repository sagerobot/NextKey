-- MARK: Configuration Context Manager
-- Dynamic configuration system that adapts UI based on context
-- Reduces conditional code by providing centralized context-aware configuration

local _, NextKey222 = ...

local ConfigurationContext = {}
NextKey222.ConfigurationContext = ConfigurationContext

-- Register with module system
NextKey222.RegisterModule("ConfigurationContext", ConfigurationContext)

-- MARK: Context State Tracking
-- Tracks all relevant UI state that affects configuration

ConfigurationContext.context = {
    -- Debug state
    isDebugMode = false,
    hasFakeService = false,
    
    -- View state
    viewMode = "keystones", -- "keystones" or "dungeons"
    
    -- Party state
    partySize = 0,
    cachedItemsCount = 0,
    useCompactMode = false,
    
    -- UI state
    mainFrameExists = false,
    showGuildKeys = false,
    
    -- Filter state
    currentSortMode = "HighestKeyLevel",
    
    -- Context validity flag
    isValid = false
}

-- MARK: Configuration Resolution System
-- Merges base configuration with context-specific overrides

ConfigurationContext.baseConfig = {
    -- Window configuration - all values now read from UIConfig
    window = {
        base = {
            width = function() return NextKey222.UIConfig and NextKey222.UIConfig.WINDOW.WIDTH or 600 end,
            height = function() return NextKey222.UIConfig and NextKey222.UIConfig.WINDOW.BASE_HEIGHT or 645 end
        },
        viewModes = {
            keystones = {
                height = function() return NextKey222.UIConfig and NextKey222.UIConfig.WINDOW.PLAYER_VIEW_HEIGHT or 645 end,
                showKeystoneControls = true,
                showDebugControls = false
            },
            dungeons = {
                height = function() return NextKey222.UIConfig and NextKey222.UIConfig.WINDOW.DUNGEON_VIEW_HEIGHT or 760 end,
                showKeystoneControls = false,
                showDebugControls = false
            }
        },
        debug = {
            height = function() return NextKey222.UIConfig and NextKey222.UIConfig.WINDOW.PLAYER_VIEW_HEIGHT_DEBUG or 675 end,
            showDebugControls = true
        },
        compact = {
            useCompactMode = true
        }
    },
    
    -- Controls configuration
    controls = {
        debug = {
            visible = false,
            requiredContext = {
                isDebugMode = true,
                hasFakeService = true,
                isNotDungeonView = true
            }
        },
        keystone = {
            visible = false,
            requiredContext = {
                isNotDungeonView = true
            },
            children = {
                guildToggle = {
                    visible = false,
                    requiredContext = {
                        showKeystoneControls = true
                    }
                }
            }
        },
        ioDisplayMode = {
            visible = false,
            requiredContext = {
                currentSortMode = "IOGainPotential"
            }
        }
    },
    
    -- Performance configuration
    performance = {
        enableCaching = true,
        cacheTimeout = 300, -- 5 minutes
        batchUpdates = true,
        throttleInterval = 0.1
    }
}

-- MARK: Context Update Functions
-- Functions to update context state and invalidate cache

--- Updates the debug mode state in context
-- @param isDebug boolean Whether debug mode is enabled
function ConfigurationContext:SetDebugMode(isDebug)
    if self.context.isDebugMode ~= isDebug then
        self.context.isDebugMode = isDebug
        self:InvalidateCache()
        Debug:Dev("config", "Context debug mode updated:", isDebug)
    end
end

--- Updates the view mode state in context
-- @param viewMode string The current view mode ("keystones" or "dungeons")
function ConfigurationContext:SetViewMode(viewMode)
    if self.context.viewMode ~= viewMode then
        self.context.viewMode = viewMode
        self:InvalidateCache()
        Debug:Dev("config", "Context view mode updated:", viewMode)
    end
end

--- Updates the party size state in context
-- @param partySize number The current party size
function ConfigurationContext:SetPartySize(partySize)
    if self.context.partySize ~= partySize then
        self.context.partySize = partySize
        self.context.useCompactMode = partySize > 5
        self:InvalidateCache()
        Debug:Dev("config", "Context party size updated:", partySize)
    end
end

--- Updates the cached items count in context
-- @param count number The number of cached items
function ConfigurationContext:SetCachedItemsCount(count)
    if self.context.cachedItemsCount ~= count then
        self.context.cachedItemsCount = count
        self:InvalidateCache()
        Debug:Dev("config", "Context cached items count updated:", count)
    end
end

--- Updates the fake service availability in context
-- @param hasService boolean Whether fake player service is available
function ConfigurationContext:SetFakeServiceAvailable(hasService)
    if self.context.hasFakeService ~= hasService then
        self.context.hasFakeService = hasService
        self:InvalidateCache()
        Debug:Dev("config", "Context fake service updated:", hasService)
    end
end

--- Updates the main frame existence state in context
-- @param exists boolean Whether the main frame exists
function ConfigurationContext:SetMainFrameExists(exists)
    if self.context.mainFrameExists ~= exists then
        self.context.mainFrameExists = exists
        self:InvalidateCache()
        Debug:Dev("config", "Context main frame existence updated:", exists)
    end
end

--- Updates the guild filter state in context
-- @param showGuild boolean Whether guild keys are shown
function ConfigurationContext:SetGuildFilter(showGuild)
    if self.context.showGuildKeys ~= showGuild then
        self.context.showGuildKeys = showGuild
        self:InvalidateCache()
        Debug:Dev("config", "Context guild filter updated:", showGuild)
    end
end

--- Updates the current sort mode in context
-- @param sortMode string The current sort mode
function ConfigurationContext:SetSortMode(sortMode)
    if self.context.currentSortMode ~= sortMode then
        self.context.currentSortMode = sortMode
        self:InvalidateCache()
        Debug:Dev("config", "Context sort mode updated:", sortMode)
    end
end

-- MARK: Context Evaluation Functions
-- Functions to evaluate context conditions

--- Evaluates if debug controls should be shown
-- @return boolean True if debug controls should be visible
function ConfigurationContext:ShouldShowDebugControls()
    return self.context.isDebugMode and 
           self.context.hasFakeService and 
           self.context.viewMode ~= "dungeons"
end

--- Evaluates if keystone controls should be shown
-- @return boolean True if keystone controls should be visible
function ConfigurationContext:ShouldShowKeystoneControls()
    return self.context.viewMode ~= "dungeons"
end

--- Evaluates if IO display mode button should be shown
-- @return boolean True if IO display mode button should be visible
function ConfigurationContext:ShouldShowIODisplayMode()
    return self.context.currentSortMode == "IOGainPotential"
end

--- Evaluates if compact mode should be used
-- @return boolean True if compact mode should be enabled
function ConfigurationContext:ShouldUseCompactMode()
    return self.context.useCompactMode
end

-- MARK: Configuration Resolution Functions
-- Functions to resolve configuration based on context

--- Resolves window configuration based on current context
-- @return table Window configuration with width and height
function ConfigurationContext:GetWindowConfig()
    local windowConfig = self.baseConfig.window
    local viewConfig = windowConfig.viewModes[self.context.viewMode] or windowConfig.viewModes.keystones
    
    -- Start with base dimensions - call functions to get current UIConfig values
    local config = {
        width = type(windowConfig.base.width) == "function" and windowConfig.base.width() or windowConfig.base.width,
        height = type(viewConfig.height) == "function" and viewConfig.height() or viewConfig.height
    }
    
    -- Apply debug mode height adjustment
    if self:ShouldShowDebugControls() then
        local debugHeight = windowConfig.debug.height
        config.height = type(debugHeight) == "function" and debugHeight() or debugHeight
    end
    
    return config
end

--- Resolves controls visibility configuration based on current context
-- @return table Controls visibility configuration
function ConfigurationContext:GetControlsConfig()
    local controlsConfig = {}
    
    -- Debug controls
    controlsConfig.debug = {
        visible = self:ShouldShowDebugControls()
    }
    
    -- Keystone controls
    controlsConfig.keystone = {
        visible = self:ShouldShowKeystoneControls(),
        children = {
            guildToggle = {
                visible = self:ShouldShowKeystoneControls()
            }
        }
    }
    
    -- IO display mode control
    controlsConfig.ioDisplayMode = {
        visible = self:ShouldShowIODisplayMode()
    }
    
    return controlsConfig
end

--- Resolves complete configuration for a specific element type
-- @param elementType string The type of element ("window", "controls", etc.)
-- @return table Resolved configuration for the element
function ConfigurationContext:GetResolvedConfig(elementType)
    -- Check cache first
    if self.configCache and self.configCache[elementType] and self.context.isValid then
        return self.configCache[elementType]
    end
    
    -- Initialize cache if needed
    self.configCache = self.configCache or {}
    
    -- Resolve configuration based on element type
    local resolvedConfig
    if elementType == "window" then
        resolvedConfig = self:GetWindowConfig()
    elseif elementType == "controls" then
        resolvedConfig = self:GetControlsConfig()
    else
        -- Return base config for unknown element types
        resolvedConfig = self.baseConfig[elementType] or {}
    end
    
    -- Cache the result
    self.configCache[elementType] = resolvedConfig
    self.context.isValid = true
    
    return resolvedConfig
end

-- MARK: Cache Management
-- Functions to manage configuration cache

--- Invalidates the configuration cache
function ConfigurationContext:InvalidateCache()
    self.configCache = {}
    self.context.isValid = false
    Debug:Dev("config", "Configuration cache invalidated")
end

--- Clears the configuration cache and resets context
function ConfigurationContext:ClearCache()
    self.configCache = {}
    self.context.isValid = false
    Debug:Dev("config", "Configuration cache cleared")
end

-- MARK: Context Synchronization
-- Functions to synchronize context with actual UI state

--- Synchronizes context with current UI state
-- @param uiModule table The UI module to synchronize with
function ConfigurationContext:SynchronizeWithUI(uiModule)
    if not uiModule then return end
    
    -- Update debug mode
    self:SetDebugMode(uiModule:IsDebugMode())
    
    -- Update view mode
    self:SetViewMode(uiModule.viewMode or "keystones")
    
    -- Update party size with error handling
    local partySize = 0
    if NextKey222.Addon and NextKey222.Addon.GetPartyMemberNames then
        local partyMembers = NextKey222.Addon:GetPartyMemberNames() or {}
        partySize = #partyMembers
    end
    self:SetPartySize(partySize)
    
    -- Update cached items count
    self:SetCachedItemsCount(uiModule.cachedItemsCount or 0)
    
    -- Update fake service availability
    self:SetFakeServiceAvailable(NextKey222.FakePlayerService ~= nil)
    
    -- Update main frame existence
    self:SetMainFrameExists(uiModule.mainFrame ~= nil)
    
    -- Update guild filter state
    self:SetGuildFilter(uiModule.showGuildKeys or false)
    
    -- Update sort mode with error handling
    local sortMode = "HighestKeyLevel"
    if uiModule.GetCurrentSortMode then
        sortMode = uiModule:GetCurrentSortMode() or sortMode
    end
    self:SetSortMode(sortMode)
    
    Debug:Dev("config", "Context synchronized with UI state")
end

-- MARK: Module Initialization
function ConfigurationContext:Initialize()
    Debug:Dev("config", "Configuration Context module initialized")
    return true
end

return ConfigurationContext