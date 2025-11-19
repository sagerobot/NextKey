-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NextKey Boot - Consolidated Initialization System
-- Following Details! Damage Meter architectural patterns with industry-standard single-file boot
-- Replaces preboot.lua + boot.lua + startup.lua for simplified architecture
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MARK: Module Registry
-- Initialize basic module registry immediately (from preboot.lua)
local addonName, NextKey222 = ...
NextKey222 = NextKey222 or {}
_G.NextKey222 = NextKey222

-- Initialize basic module registry immediately
NextKey222.moduleRegistry = {}

-- Simple RegisterModule function available immediately  
local function RegisterModuleBasic(name, moduleTable)
    NextKey222.moduleRegistry = NextKey222.moduleRegistry or {}
    NextKey222.moduleRegistry[name] = moduleTable
    return true
end

NextKey222.RegisterModule = RegisterModuleBasic

function NextKey222.GetModule(name)
    return NextKey222.moduleRegistry and NextKey222.moduleRegistry[name]
end

-- MARK: Addon Initialization
-- Global addon declaration with proper namespace management
_G.NextKey = LibStub("AceAddon-3.0"):NewAddon("NextKey", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0")

-- Initialize AceDB manually (not embed-capable)
local AceDB = LibStub("AceDB-3.0")

-- Store reference to addon in namespace (available immediately)
NextKey222.Addon = NextKey

-- MARK: Config Functions
-- Attach config functions that were loaded before the addon was created
if NextKey222.ConfigFunctions then
    for funcName, func in pairs(NextKey222.ConfigFunctions) do
        NextKey[funcName] = func
    end
end

-- MARK: Module Aliases
-- Provide convenient access to commonly used modules  
NextKey.LibOpenRaid = NextKey222.LibOpenRaidIntegration

-- MARK: Version Information
-- Store version information
local version, build, date, tvs = GetBuildInfo()
NextKey.build_counter = 37
NextKey.version_major = 0
NextKey.version_minor = 6
NextKey.version_patch = 11
NextKey.version_stage = "alpha"  -- "alpha", "beta", or "" for release
NextKey.game_version = version
NextKey.gametoc = tvs

-- Build base version string
NextKey.version = string.format("%d.%d.%d", NextKey.version_major, NextKey.version_minor, NextKey.version_patch)

-- Build full version string with stage (if applicable)
if NextKey.version_stage and NextKey.version_stage ~= "" then
    NextKey.version_full = string.format("v%s-%s", NextKey.version, NextKey.version_stage)
else
    NextKey.version_full = "v" .. NextKey.version
end

-- MARK: Namespace Organization
-- Organized component namespaces
NextKey222.StartUp = {}
NextKey222.Keystones = {}
NextKey222.RaiderIO = {}
NextKey222.Communications = {}
NextKey222.UI = {}
-- NextKey222.Debug is set by core/debugService.lua (loaded before this file)
NextKey222.Performance = {}
NextKey222.Events = {}
NextKey222.Config = {}
NextKey222.Season = {}
NextKey222.Utils = {}
NextKey222.Cache = {}

-- MARK: Error Handling & Safety
-- Safe execution wrapper (Details! pattern)
function NextKey.SafeRun(func, executionName, ...)
    if type(func) ~= "function" then
        -- Use debug system if available, otherwise fail silently
        if NextKey222.Debug then
            NextKey222.Debug:Error("SafeRun error: not a function -", executionName or "unknown")
        end
        return false
    end
    
    -- Capture ALL return values from pcall
    local results = {pcall(func, ...)}
    local runToCompletion = table.remove(results, 1)  -- Extract success flag
    
    if not runToCompletion then
        -- results[1] now contains the error message
        if NextKey222.Debug then
            NextKey222.Debug:Error("SafeRun failed:", executionName or "unknown", "-", results[1])
        end
        return false
    end
    
    -- BACKWARD COMPATIBILITY: If only one result, return it directly (old behavior)
    -- If multiple results, return (true, result1, result2, ...) (new behavior)
    if #results == 0 then
        return true  -- Function returned nothing
    elseif #results == 1 then
        return results[1]  -- Backward compatible - single return value
    else
        return true, unpack(results)  -- Multiple return values - include success flag
    end
end

-- Expose SafeRun through NextKey222 namespace as well
NextKey222.SafeRun = NextKey.SafeRun

-- MARK: Performance Monitoring
NextKey222.Performance = {
    profiles = {},
    enabled = false,
    
    StartProfile = function(self, functionName)
        if not self.enabled then return end
        
        local profile = self.profiles[functionName]
        if not profile then
            self.profiles[functionName] = {
                elapsed = 0,
                startTime = 0,
                runs = 0,
                averageTime = 0
            }
            profile = self.profiles[functionName]
        end
        
        profile.startTime = debugprofilestop()
        profile.runs = profile.runs + 1
    end,
    
    StopProfile = function(self, functionName)
        if not self.enabled then return end
        
        local profile = self.profiles[functionName]
        if profile and profile.startTime > 0 then
            local elapsed = debugprofilestop() - profile.startTime
            profile.elapsed = profile.elapsed + elapsed
            profile.averageTime = profile.elapsed / profile.runs
        end
    end,
    
    GetReport = function(self)
        local report = {}
        for name, profile in pairs(self.profiles) do
            table.insert(report, {
                name = name,
                totalTime = profile.elapsed,
                runs = profile.runs,
                averageTime = profile.averageTime
            })
        end
        
        table.sort(report, function(a, b) return a.totalTime > b.totalTime end)
        return report
    end
}

-- MARK: Debug System
-- Debug system now loaded from core/debugService.lua (loaded before this file)
-- NextKey222.Debug should already be available
-- Access via NextKey222.Debug or global Debug variable

-- MARK: Config Defaults
-- Defaults loaded from core/config.lua (loaded before this file in .toc)
-- NextKey222.Defaults should be available from core/config.lua

-- Constants are defined in core/constants.lua; avoid duplicating here

-- MARK: Initialization Flags
NextKey.isInitialized = false
NextKey.isEnabled = false

-- MARK: Startup System
NextKey222.StartUp = {
    phases = {
        "PreInit",      -- Basic setup, constants, namespaces
        "Init",         -- Core systems, database
        "PostInit",     -- Module initialization
        "Enable",       -- Event registration, UI creation
        "Finalize"      -- Final setup, announce ready
    },
    
    currentPhase = 0,
    phaseHandlers = {},
    
    RegisterPhaseHandler = function(self, phase, handler, priority)
        priority = priority or 100
        if not self.phaseHandlers[phase] then
            self.phaseHandlers[phase] = {}
        end
        
        table.insert(self.phaseHandlers[phase], {
            handler = handler,
            priority = priority
        })
        
        -- Sort by priority
        table.sort(self.phaseHandlers[phase], function(a, b)
            return a.priority < b.priority
        end)
    end,
    
    ExecutePhase = function(self, phase)
        NextKey222.Debug:Trace("startup", "Executing phase:", phase)
        
        local handlers = self.phaseHandlers[phase]
        if not handlers then return end
        
        for _, handlerData in ipairs(handlers) do
            NextKey.SafeRun(handlerData.handler, "StartUp phase: " .. phase, NextKey)
        end
    end,
    
    Start = function(self)
        if NextKey.isInitialized then return end
        
        NextKey222.Debug:Dev("startup", "StartUp:Start() called - executing phases")
        for i, phase in ipairs(self.phases) do
            NextKey222.Debug:Dev("startup", "Executing phase " .. i .. ": " .. phase)
            self.currentPhase = i
            self:ExecutePhase(phase)
        end

        -- Setup options interface (AceConfig registration for "NextKey")
        if NextKey222.SetupOptions then
            NextKey.SafeRun(function()
                NextKey222.SetupOptions()
            end, "Setup Options")
        end
        
        NextKey.isInitialized = true
        NextKey222.Debug:User("NextKey " .. NextKey.version_full .. " initialized successfully")
    end
}

-- MARK: Core Event Frame
NextKey.eventFrame = CreateFrame("Frame", "NextKeyEventFrame", UIParent)
NextKey.eventFrame:SetFrameStrata("LOW")
NextKey.eventFrame:SetFrameLevel(1)

-- Utility functions live in core/utils.lua; avoid duplicating here

-- MARK: Phase Handlers
-- Register database initialization for Init phase
NextKey222.StartUp:RegisterPhaseHandler("Init", function()
    NextKey222.Debug:Dev("startup", "=== Init Phase ===")
    
    -- Verify configuration defaults are available
    if NextKey222.Defaults then
        NextKey222.Debug:Dev("startup", "✅ NextKey222.Defaults loaded from core/config.lua")
    else
        NextKey222.Debug:Error("❌ NextKey222.Defaults not available - check core/config.lua loading")
    end
    
    -- Initialize AceDB database
    if not NextKey.db then
        NextKey222.Debug:Dev("startup", "Initializing AceDB with NextKeyDB")
        NextKey.db = AceDB:New("NextKeyDB", NextKey222.Defaults, true)
        NextKey222.Debug:Dev("startup", "Database initialized successfully")
    else
        NextKey222.Debug:Dev("startup", "Database already initialized")
    end
    
    -- Initialize Debug Service with database
    if Debug and Debug.Initialize then
        NextKey222.Debug:Initialize(NextKey.db)
        NextKey222.Debug:Dev("startup", "Debug service initialized from database")
    end
    
    -- Initialize DebugUI after DebugService is ready
    if NextKey222.DebugUI and NextKey222.DebugUI.InitializeAfterLoad then
        NextKey222.DebugUI:InitializeAfterLoad()
        NextKey222.Debug:Dev("startup", "DebugUI initialized after DebugService")
    end
    
    -- Initialize FakePlayerService
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing FakePlayerService")
        NextKey.SafeRun(function() 
            NextKey222.FakePlayerService:Initialize() 
        end, "Initialize FakePlayerService")
    end
    
    -- Initialize LibOpenRaid integration
    if NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing LibOpenRaidIntegration")
        NextKey.SafeRun(function()
            NextKey222.LibOpenRaidIntegration:Initialize()
        end, "Initialize LibOpenRaidIntegration")
    end
    
    -- Initialize ProfilesService (critical for spec change detection)
    if NextKey222.ProfilesService and NextKey222.ProfilesService.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing ProfilesService")
        NextKey.SafeRun(function()
            NextKey222.ProfilesService:Initialize()
        end, "Initialize ProfilesService")
    end
    
    NextKey222.Debug:Dev("startup", "Init phase completed")
end, 10) -- High priority for database initialization

-- Phase 3: PostInit - Initialize UI and other systems
NextKey222.StartUp:RegisterPhaseHandler("PostInit", function()
    NextKey222.Debug:Dev("startup", "=== PostInit Phase ===")
    
    -- Initialize DungeonNameService (must be early, after portal data loaded)
    if NextKey222.DungeonNameService and NextKey222.DungeonNameService.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing DungeonNameService")
        NextKey.SafeRun(function() NextKey222.DungeonNameService:Initialize() end, "Initialize DungeonNameService")
    else
        NextKey222.Debug:Error("DungeonNameService not available for initialization")
    end
    
    -- Phase 7: Initialize Configuration Context (must be before UI)
    if NextKey222.ConfigurationContext then
        if NextKey222.ConfigurationContext.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing Configuration Context")
            NextKey.SafeRun(function() NextKey222.ConfigurationContext:Initialize() end, "Initialize Configuration Context")
        else
            NextKey222.Debug:Error("Configuration Context missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "Configuration Context not available - Phase 7 features disabled")
    end
    
    -- Phase 7: Initialize Tooltip System (must be before UI)
    if NextKey222.Tooltip then
        if NextKey222.Tooltip.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing Tooltip System")
            NextKey.SafeRun(function() NextKey222.Tooltip:Initialize() end, "Initialize Tooltip System")
        else
            NextKey222.Debug:Error("Tooltip System missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "Tooltip System not available - Phase 7 features disabled")
    end
    
    -- Phase 7: Initialize Theme System (must be before UI)
    if NextKey222.Theme then
        if NextKey222.Theme.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing Theme System")
            NextKey.SafeRun(function() NextKey222.Theme:Initialize() end, "Initialize Theme System")
        else
            NextKey222.Debug:Error("Theme System missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "Theme System not available - Phase 7 features disabled")
    end
    
    -- Phase 7: Initialize UI Scale System (must be before UI)
    if NextKey222.UIScale then
        if NextKey222.UIScale.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing UI Scale System")
            NextKey.SafeRun(function() NextKey222.UIScale:Initialize() end, "Initialize UI Scale System")
        else
            NextKey222.Debug:Error("UI Scale System missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "UI Scale System not available - Phase 7 features disabled")
    end
    
    -- Phase 7: Initialize Responsive Layout System (must be before UI)
    if NextKey222.Responsive then
        if NextKey222.Responsive.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing Responsive Layout System")
            NextKey.SafeRun(function() NextKey222.Responsive:Initialize() end, "Initialize Responsive Layout System")
        else
            NextKey222.Debug:Error("Responsive Layout System missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "Responsive Layout System not available - Phase 7 features disabled")
    end
    
    -- Phase 7: Initialize Validation System (must be before UI)
    if NextKey222.Validation then
        if NextKey222.Validation.Initialize then
            NextKey222.Debug:Dev("startup", "Initializing Validation System")
            NextKey.SafeRun(function() NextKey222.Validation:Initialize() end, "Initialize Validation System")
        else
            NextKey222.Debug:Error("Validation System missing Initialize function")
        end
    else
        NextKey222.Debug:Dev("startup", "Validation System not available - Phase 7 features disabled")
    end
    
    -- Initialize UI system
    if NextKey222.UI and NextKey222.UI.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing UI system")
        NextKey.SafeRun(function() NextKey222.UI:Initialize() end, "Initialize UI system")
    else
        NextKey222.Debug:Error("Warning: UI system not available for initialization")
    end
    
    -- Register teleport window event listeners
    if NextKey and NextKey.RegisterTeleportEventListeners then
        NextKey222.Debug:Dev("startup", "Registering teleport window event listeners")
        NextKey.SafeRun(function() NextKey:RegisterTeleportEventListeners() end, "Register teleport event listeners")
    end
    
    -- Initialize GroupSuggestions
    if NextKey222.GroupSuggestions and NextKey222.GroupSuggestions.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing GroupSuggestions")
        NextKey.SafeRun(function()
            NextKey222.GroupSuggestions:Initialize()
        end, "Initialize GroupSuggestions")
    end
    
    -- Initialize Communications
    if NextKey222.Communications and NextKey222.Communications.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing Communications")
        NextKey.SafeRun(function()
            NextKey222.Communications:Initialize()
        end, "Initialize Communications")
    end
    
    -- Initialize CharacterStorage (Phase 0 - M+ Organizer)
    if NextKey222.CharacterStorage then
        NextKey222.Debug:Dev("startup", "Initializing CharacterStorage")
        -- Set database reference
        NextKey222.CharacterStorage.db = NextKey.db
        if NextKey222.CharacterStorage.Initialize then
            NextKey.SafeRun(function()
                NextKey222.CharacterStorage:Initialize()
            end, "Initialize CharacterStorage")
        end
    end
    
    -- Initialize ParticipantSurvey (Phase 2 - M+ Organizer)
    if NextKey222.ParticipantSurvey and NextKey222.ParticipantSurvey.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing ParticipantSurvey")
        NextKey.SafeRun(function()
            NextKey222.ParticipantSurvey:Initialize()
        end, "Initialize ParticipantSurvey")
    end
    
    -- Initialize RosterBoard (Phase 1 - M+ Organizer)
    if NextKey222.RosterBoard and NextKey222.RosterBoard.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing RosterBoard")
        NextKey.SafeRun(function()
            NextKey222.RosterBoard:Initialize()
        end, "Initialize RosterBoard")
    end
    
    -- Initialize PollSimulator (Debug tool for Phase 2)
    if NextKey222.PollSimulator and NextKey222.PollSimulator.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing PollSimulator")
        NextKey.SafeRun(function()
            NextKey222.PollSimulator:Initialize()
        end, "Initialize PollSimulator")
    end
    
    -- Initialize PUG Helper Module
    if NextKey222.PUGHelper and NextKey222.PUGHelper.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing PUG Helper Module")
        NextKey.SafeRun(function()
            NextKey222.PUGHelper:Initialize()
        end, "Initialize PUG Helper Module")
    end
    
    -- Initialize DungeonCards (loads loot tracking data)
    if NextKey.DungeonCards and NextKey.DungeonCards.Init then
        NextKey222.Debug:Dev("startup", "Initializing DungeonCards")
        NextKey.SafeRun(function()
            NextKey.DungeonCards:Init()
        end, "Initialize DungeonCards")
    end
    
    NextKey222.Debug:Dev("startup", "PostInit phase completed")
end)

-- Phase 4: Enable - Activate systems
NextKey222.StartUp:RegisterPhaseHandler("Enable", function()
    NextKey222.Debug:Dev("startup", "=== Enable Phase ===")
    
    -- Enable event systems
    if NextKey222.Events and NextKey222.Events.Enable then
        NextKey222.Debug:Dev("startup", "Enabling Events system")
        NextKey.SafeRun(function() NextKey222.Events:Enable() end, "Enable Events system")
    end
    
    NextKey222.Debug:Dev("startup", "Enable phase completed")
end)

-- Phase 5: Finalize - Final setup and character data capture
NextKey222.StartUp:RegisterPhaseHandler("Finalize", function()
    NextKey222.Debug:Dev("startup", "=== Finalize Phase ===")
    
    -- Capture current character data now that all services are initialized
    -- This ensures ProfilesService and other dependencies are ready
    if NextKey222.CharacterStorage and NextKey222.Events then
        NextKey222.Debug:Dev("startup", "Capturing current character data in Finalize phase")
        NextKey.SafeRun(function()
            -- Use the CaptureCurrentCharacterData function with retry enabled
            -- This ensures we capture even if services aren't quite ready yet
            if NextKey222.Events.CaptureCurrentCharacterData then
                local success = NextKey222.Events:CaptureCurrentCharacterData(true) -- Enable retry on failure
                if success then
                    NextKey222.Debug:Dev("startup", "Character data captured successfully in Finalize phase")
                else
                    NextKey222.Debug:Dev("startup", "Character data capture deferred for retry in Finalize phase")
                end
            end
        end, "Capture character data in Finalize phase")
    end
    
    NextKey222.Debug:Dev("startup", "Finalize phase completed")
end)

-- MARK: Slash Commands
-- Slash commands have been moved to core\slashCommands.lua for better organization
-- This keeps boot.lua focused on initialization while making commands easy to modify
-- See core\slashCommands.lua for all command definitions and handlers

-- Placeholder - actual command handler loaded from core\slashCommands.lua
SLASH_NEXTKEY1 = "/nextkey"
SLASH_NEXTKEY2 = "/nk"
-- SlashCmdList["NEXTKEY"] registered by core\slashCommands.lua

-- MARK: Module Registration
-- Mark boot as ready and enhance RegisterModule
NextKey222.BootReady = true

-- Enhance RegisterModule with full functionality now that boot is complete
NextKey222.RegisterModule = function(name, moduleTable)
    NextKey222.moduleRegistry = NextKey222.moduleRegistry or {}
    if NextKey222.moduleRegistry[name] then
        NextKey222.Debug:Dev("startup", "Warning: Module", name, "already registered")
        return false
    end
    
    NextKey222.moduleRegistry[name] = moduleTable
    NextKey222.Debug:Dev("startup", "Registered module:", name)
    return true
end

-- MARK: AceAddon Integration
-- Called by AceAddon framework after addon is fully loaded
function NextKey:OnInitialize()
    NextKey222.Debug:Dev("startup", "OnInitialize called - starting initialization phases")
    
    -- Start the phased initialization system
    NextKey222.StartUp:Start()
    
    NextKey222.Debug:Dev("startup", "OnInitialize completed - slash commands registered")
end

-- Initialize basic systems immediately
NextKey222.Debug:Dev("startup", "NextKey consolidated boot.lua loaded, version", NextKey.version)

return NextKey