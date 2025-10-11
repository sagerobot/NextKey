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
NextKey222.Debug = {}
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
        if NextKey.db and NextKey.db.global and NextKey.db.global.debug and NextKey.db.global.debug.enabled then
            NextKey:Print("SafeRun error: not a function -", executionName or "unknown")
        end
        return false
    end
    
    local runToCompletion, result = pcall(func, ...)
    if not runToCompletion then
        if NextKey.db and NextKey.db.global and NextKey.db.global.debug and NextKey.db.global.debug.enabled then
            NextKey:Print("SafeRun failed:", executionName or "unknown", "-", result)
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
NextKey222.Debug = {
    enabled = false,
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
    
    Print = function(self, category, ...)
        if not self.enabled or not self.categories[category] then return end
        
        local args = {...}
        local message = "|cFFFFAA00NextKey Debug [" .. (category or "General") .. "]:|r"
        for i, arg in ipairs(args) do
            message = message .. " " .. tostring(arg)
        end
        print(message)
    end,
    
    EnableCategory = function(self, category)
        if self.categories[category] ~= nil then
            self.categories[category] = true
            self.enabled = true
        end
    end,
    
    DisableCategory = function(self, category)
        if self.categories[category] ~= nil then
            self.categories[category] = false
        end
        
        -- Check if any category is still enabled
        local anyEnabled = false
        for _, enabled in pairs(self.categories) do
            if enabled then anyEnabled = true break end
        end
        self.enabled = anyEnabled
    end
}

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
        NextKey222.Debug:Print("startup", "Executing phase:", phase)
        
        local handlers = self.phaseHandlers[phase]
        if not handlers then return end
        
        for _, handlerData in ipairs(handlers) do
            NextKey.SafeRun(handlerData.handler, "StartUp phase: " .. phase, NextKey)
        end
    end,
    
    Start = function(self)
        if NextKey.isInitialized then return end
        
        print("NextKey: StartUp:Start() called - executing phases")
        for i, phase in ipairs(self.phases) do
            print("NextKey: Executing phase " .. i .. ": " .. phase)
            self.currentPhase = i
            self:ExecutePhase(phase)
        end
        
        -- Setup options interface
        if NextKey.SetupOptions then
            NextKey.SafeRun(NextKey.SetupOptions, "Setup Options", NextKey)
        end
        
        NextKey.isInitialized = true
        print("NextKey v" .. NextKey.version .. " initialized successfully")
        NextKey:Print("NextKey v" .. NextKey.version .. " initialized successfully")
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
    NextKey222.Debug:Print("startup", "=== Init Phase ===")
    
    -- Verify configuration defaults are available
    if NextKey222.Defaults then
        NextKey222.Debug:Print("startup", "✅ NextKey222.Defaults loaded from core/config.lua")
    else
        NextKey222.Debug:Print("startup", "❌ NextKey222.Defaults not available - check core/config.lua loading")
    end
    
    -- Initialize AceDB database
    if not NextKey.db then
        NextKey222.Debug:Print("startup", "Initializing AceDB with NextKeyDB")
        NextKey.db = AceDB:New("NextKeyDB", NextKey222.Defaults, true)
        NextKey222.Debug:Print("startup", "Database initialized successfully")
    else
        NextKey222.Debug:Print("startup", "Database already initialized")
    end
    
    -- Initialize LibOpenRaid integration
    if NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration.Initialize then
        NextKey222.Debug:Print("startup", "Initializing LibOpenRaidIntegration")
        NextKey.SafeRun(function() 
            NextKey222.LibOpenRaidIntegration:Initialize() 
        end, "Initialize LibOpenRaidIntegration")
    end
    
    NextKey222.Debug:Print("startup", "Init phase completed")
end, 10) -- High priority for database initialization

-- Phase 3: PostInit - Initialize UI and other systems
NextKey222.StartUp:RegisterPhaseHandler("PostInit", function()
    NextKey222.Debug:Print("startup", "=== PostInit Phase ===")
    
    -- Initialize UI system
    if NextKey222.UI and NextKey222.UI.Initialize then
        NextKey222.Debug:Print("startup", "Initializing UI system")
        NextKey.SafeRun(NextKey222.UI.Initialize, "Initialize UI system")
    else
        NextKey222.Debug:Print("startup", "Warning: UI system not available for initialization")
    end
    
    -- Initialize Communications
    if NextKey222.Communications and NextKey222.Communications.Initialize then
        NextKey222.Debug:Print("startup", "Initializing Communications")
        NextKey.SafeRun(function() 
            NextKey222.Communications:Initialize() 
        end, "Initialize Communications")
    end
    
    NextKey222.Debug:Print("startup", "PostInit phase completed")
end)

-- Phase 4: Enable - Activate systems
NextKey222.StartUp:RegisterPhaseHandler("Enable", function()
    NextKey222.Debug:Print("startup", "=== Enable Phase ===")
    
    -- Enable event systems
    if NextKey222.Events and NextKey222.Events.Enable then
        NextKey222.Debug:Print("startup", "Enabling Events system")
        NextKey.SafeRun(NextKey222.Events.Enable, "Enable Events system")
    end
    
    NextKey222.Debug:Print("startup", "Enable phase completed")
end)

-- MARK: Slash Command Registration
-- Register slash commands for NextKey
SLASH_NEXTKEY1 = "/nextkey"
SLASH_NEXTKEY2 = "/nk"

SlashCmdList["NEXTKEY"] = function(input)
    local command = string.lower(string.trim and string.trim(input) or input or "")
    
    if command == "" or command == "show" then
        -- Show main UI
        if NextKey222.UI and NextKey222.UI.ToggleMainFrame then
            NextKey222.UI:ToggleMainFrame()
        elseif NextKey222.UI and NextKey222.UI.CreateMainFrame then
            NextKey222.UI:CreateMainFrame()
        else
            print("NextKey: UI not ready yet")
        end
    elseif command == "hide" then
        -- Hide main UI
        if NextKey222.UI and NextKey222.UI.mainFrame then
            NextKey222.UI.mainFrame:Hide()
            print("NextKey: Main frame hidden")
        else
            print("NextKey: No frame to hide")
        end
    elseif command == "config" or command == "options" or command == "opt" then
        -- Open config using AceConfigDialog
        local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
        if AceConfigDialog then
            AceConfigDialog:Open("NextKey")
        else
            print("NextKey: Config interface not available")
        end
    elseif command == "debug" then
        -- Toggle debug
        if NextKey222.Debug and NextKey222.Debug.ToggleLevel then
            NextKey222.Debug:ToggleLevel()
        else
            print("NextKey: Debug system not ready yet")
        end
    elseif command == "version" then
        -- Show version
        local version = NextKey.version or C_AddOns.GetAddOnMetadata("NextKey", "Version") or "Unknown"
        print("NextKey version:", version)
    elseif command == "status" then
        -- Show status
        print("NextKey Status:")
        print("- UI Ready:", NextKey222.UI and "Yes" or "No")
        print("- Events Ready:", NextKey222.Events and "Yes" or "No")
        print("- Communications Ready:", NextKey222.Communications and "Yes" or "No")
        print("- Debug Ready:", NextKey222.Debug and "Yes" or "No")
        print("- IOCalculator Ready:", NextKey222.IOCalculator and "Yes" or "No")
    elseif command == "reload" then
        -- Reload UI
        ReloadUI()
        elseif command == "rio" then
        -- Debug RaiderIO data structure (safe subset)
        if _G.RaiderIO and _G.RaiderIO.GetProfile then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            print("NextKey: Checking RaiderIO for", playerName .. "-" .. realmName)
            local profile = _G.RaiderIO.GetProfile(playerName, realmName)
            if profile and profile.mythicKeystoneProfile then
                local mp = profile.mythicKeystoneProfile
                print("NextKey: RaiderIO Profile found!")
                print("  currentScore:", mp.currentScore or "nil")
            else
                print("NextKey: No RaiderIO profile found")
            end
        else
            print("NextKey: RaiderIO addon not found")
        end
    elseif command:match("^test") then
        -- Enhanced fake player testing commands
        local args = {strsplit(" ", command)}
        local subcommand = args[2] or ""
        
        if subcommand == "realistic" or subcommand == "" then
            -- Generate 4 realistic fake players with mixed addon status
            NextKey222.Addon:AddRandomFakePlayers(4, { nextkey = 2, raiderio = 1, none = 1 })
            print("NextKey: Generated 4 realistic fake players")
            print("  - 2 with NextKey addon")
            print("  - 1 with RaiderIO only") 
            print("  - 1 with no addons")
        elseif subcommand == "mixed" then
            -- Custom mixed party based on args: /nk test mixed 2 1 1 (nextkey, rio, none)
            local nextkey_count = tonumber(args[3]) or 2
            local rio_count = tonumber(args[4]) or 1  
            local none_count = tonumber(args[5]) or 1
            local total = nextkey_count + rio_count + none_count
            
            NextKey222.Addon:AddRandomFakePlayers(total, { 
                nextkey = nextkey_count, 
                raiderio = rio_count, 
                none = none_count 
            })
            print(string.format("NextKey: Generated %d fake players (%d NextKey, %d RaiderIO, %d None)", 
                  total, nextkey_count, rio_count, none_count))
        elseif subcommand == "clear" then
            -- Clear all fake players
            NextKey222.Addon:ClearFakePlayers()
            print("NextKey: Cleared all fake players")
        elseif subcommand == "help" then
            print("NextKey Test Commands:")
            print("  /nk test (or realistic) - Generate 4 realistic fake players")
            print("  /nk test mixed X Y Z - Generate X NextKey + Y RaiderIO + Z None players")
            print("  /nk test clear - Clear all fake players")
        else
            print("NextKey: Unknown test command. Use '/nk test help' for options.")
        end
    else
        -- Help text
        print("NextKey Commands:")
        print("  /nk (or show) - Toggle/show the main window")
        print("  /nk hide - Hide the main window") 
        print("  /nk config (or opt) - Open configuration")
        print("  /nk debug - Toggle debug mode")
        print("  /nk version - Show version")
        print("  /nk status - Show system status")
        print("  /nk reload - Reload UI")
        print("  /nk rio - Debug RaiderIO data structure")
        print("  /nk test - Generate realistic fake players for testing")
    end
end

-- MARK: Enhanced Module Registration
-- Mark boot as ready and enhance RegisterModule
NextKey222.BootReady = true

-- Enhance RegisterModule with full functionality now that boot is complete
NextKey222.RegisterModule = function(name, moduleTable)
    NextKey222.moduleRegistry = NextKey222.moduleRegistry or {}
    if NextKey222.moduleRegistry[name] then
        NextKey222.Debug:Print("startup", "Warning: Module", name, "already registered")
        return false
    end
    
    NextKey222.moduleRegistry[name] = moduleTable
    NextKey222.Debug:Print("startup", "Registered module:", name)
    return true
end

-- MARK: AceAddon Integration
-- Called by AceAddon framework after addon is fully loaded
function NextKey:OnInitialize()
    -- Print directly to chat to ensure we see initialization
    print("NextKey: OnInitialize called - starting initialization phases")
    NextKey222.Debug:Print("startup", "OnInitialize called - starting initialization phases")
    
    -- Start the phased initialization system
    NextKey222.StartUp:Start()
    
    -- Register slash commands
    print("NextKey: Slash commands /nk and /nextkey registered")
    
    -- Ensure we see completion
    print("NextKey: OnInitialize completed")
end

-- Initialize basic systems immediately
print("NextKey: Consolidated boot.lua loaded, version " .. NextKey.version)
NextKey222.Debug:Print("startup", "NextKey consolidated boot.lua loaded, version", NextKey.version)

return NextKey