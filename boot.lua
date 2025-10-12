-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NextKey Boot - Consolidated Initialization System
-- Following Details! Damage Meter architectural patterns with industry-standard single-file boot
-- Replaces preboot.lua + boot.lua + startup.lua for simplified architecture
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MARK: Early Module Registry Setup
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

-- MARK: Global Addon Initialization
-- Global addon declaration with proper namespace management
_G.NextKey = LibStub("AceAddon-3.0"):NewAddon("NextKey", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0")

-- Initialize AceDB manually (not embed-capable)
local AceDB = LibStub("AceDB-3.0")

-- Store reference to addon in namespace (available immediately)
NextKey222.Addon = NextKey

-- MARK: Attach Configuration Functions
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
NextKey.build_counter = 1
NextKey.version_major = 0
NextKey.version_minor = 2
NextKey.version_patch = 0
NextKey.game_version = version
NextKey.gametoc = tvs
NextKey.version = string.format("%d.%d.%d.%d", NextKey.version_major, NextKey.version_minor, NextKey.version_patch, NextKey.build_counter)

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
    
    local runToCompletion, result = pcall(func, ...)
    if not runToCompletion then
        -- Use debug system if available
        if NextKey222.Debug then
            NextKey222.Debug:Error("SafeRun failed:", executionName or "unknown", "-", result)
        end
        return false
    end
    return result ~= false and result or true
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

-- MARK: Configuration Defaults  
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
        
        -- Setup options interface
        if NextKey.SetupOptions then
            NextKey.SafeRun(NextKey.SetupOptions, "Setup Options", NextKey)
        end
        
        NextKey.isInitialized = true
        NextKey222.Debug:User("NextKey v" .. NextKey.version .. " initialized successfully")
    end
}

-- MARK: Core Event Frame
NextKey.eventFrame = CreateFrame("Frame", "NextKeyEventFrame", UIParent)
NextKey.eventFrame:SetFrameStrata("LOW")
NextKey.eventFrame:SetFrameLevel(1)

-- Utility functions live in core/utils.lua; avoid duplicating here

-- MARK: Initialization Phase Handlers
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
    
    NextKey222.Debug:Dev("startup", "Init phase completed")
end, 10) -- High priority for database initialization

-- Phase 3: PostInit - Initialize UI and other systems
NextKey222.StartUp:RegisterPhaseHandler("PostInit", function()
    NextKey222.Debug:Dev("startup", "=== PostInit Phase ===")
    
    -- Initialize UI system
    if NextKey222.UI and NextKey222.UI.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing UI system")
        NextKey.SafeRun(NextKey222.UI.Initialize, "Initialize UI system")
    else
        NextKey222.Debug:Error("Warning: UI system not available for initialization")
    end
    
    -- Initialize Communications
    if NextKey222.Communications and NextKey222.Communications.Initialize then
        NextKey222.Debug:Dev("startup", "Initializing Communications")
        NextKey.SafeRun(function() 
            NextKey222.Communications:Initialize() 
        end, "Initialize Communications")
    end
    
    NextKey222.Debug:Dev("startup", "PostInit phase completed")
end)

-- Phase 4: Enable - Activate systems
NextKey222.StartUp:RegisterPhaseHandler("Enable", function()
    NextKey222.Debug:Dev("startup", "=== Enable Phase ===")
    
    -- Enable event systems
    if NextKey222.Events and NextKey222.Events.Enable then
        NextKey222.Debug:Dev("startup", "Enabling Events system")
        NextKey.SafeRun(NextKey222.Events.Enable, "Enable Events system")
    end
    
    NextKey222.Debug:Dev("startup", "Enable phase completed")
end)

-- MARK: Slash Command Registration
-- Slash commands have been moved to core\slashCommands.lua for better organization
-- This keeps boot.lua focused on initialization while making commands easy to modify
-- See core\slashCommands.lua for all command definitions and handlers

-- Placeholder - actual command handler loaded from core\slashCommands.lua
SLASH_NEXTKEY1 = "/nextkey"
SLASH_NEXTKEY2 = "/nk"
-- SlashCmdList["NEXTKEY"] registered by core\slashCommands.lua

-- MARK: Enhanced Module Registration
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