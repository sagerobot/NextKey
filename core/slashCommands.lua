-- ==============================================================================
-- NextKey Slash Commands - Centralized Command Handler
-- ==============================================================================
-- Provides /nextkey and /nk slash commands with organized subcommands
-- This file makes it easy to add, modify, and document commands in one place
-- ==============================================================================

local addonName, NextKey222 = ...

-- MARK: - Command Definitions
-- This table defines all available commands and their help text
-- Makes it easy to add new commands and keep help synchronized
local Commands = {
    -- Main commands
    {
        cmd = {"", "show"},
        desc = "Toggle/show the main window",
        handler = "ShowMainWindow"
    },
    {
        cmd = {"hide"},
        desc = "Hide the main window",
        handler = "HideMainWindow"
    },
    {
        cmd = {"help", "?"},
        desc = "Show this help message",
        handler = "ShowHelp"
    },
    {
        cmd = {"config", "options", "opt"},
        desc = "Open configuration",
        handler = "ShowConfig"
    },
    {
        cmd = {"version", "ver", "v"},
        desc = "Show addon version",
        handler = "ShowVersion"
    },
    {
        cmd = {"status"},
        desc = "Show system status",
        handler = "ShowStatus"
    },
    {
        cmd = {"reload"},
        desc = "Reload UI",
        handler = "ReloadUI"
    },
    
    -- Debug commands (subcommands handled separately)
    {
        cmd = {"debug"},
        desc = "Debug commands (use '/nk debug help' for details)",
        handler = "DebugCommands"
    },
    
    -- Testing commands
    {
        cmd = {"test"},
        desc = "Generate fake players for testing (use '/nk test help' for details)",
        handler = "TestCommands"
    },
    {
        cmd = {"components"},
        desc = "Test UI component system (use '/nk components help' for details)",
        handler = "ComponentCommands"
    },
    {
        cmd = {"validate", "validation"},
        desc = "Run Phase 7 validation tests (use '/nk validate help' for details)",
        handler = "ValidationCommands"
    },
    {
        cmd = {"scroll"},
        desc = "Test scroll bar visibility fix",
        handler = "TestScrollBar"
    },
    
    -- Developer commands
    {
        cmd = {"rio"},
        desc = "Debug RaiderIO data structure",
        handler = "DebugRaiderIO"
    },
    
    -- PUG Helper commands
    {
        cmd = {"pug"},
        desc = "PUG Helper commands (use '/nk pug help' for details)",
        handler = "PUGCommands"
    },
    
    -- Dungeon cards commands
    {
        cmd = {"dungeon", "dungeons", "cards"},
        desc = "Show the dungeon overview UI",
        handler = "ShowDungeonCards"
    },
    
}

-- Debug subcommands
local DebugCommands = {
    {
        cmd = {"", "help", "?"},
        desc = "Show debug command help",
        handler = "ShowDebugHelp"
    },
    {
        cmd = {"on", "enable"},
        desc = "Enable debug output",
        handler = "EnableDebug"
    },
    {
        cmd = {"off", "disable"},
        desc = "Disable debug output",
        handler = "DisableDebug"
    },
    {
        cmd = {"toggle"},
        desc = "Toggle debug on/off",
        handler = "ToggleDebug"
    },
    {
        cmd = {"level"},
        desc = "Set debug level (0-4): /nk debug level <0-4>",
        usage = "/nk debug level <0-4>",
        details = {
            "  0 = NONE (silent)",
            "  1 = ERROR (critical only)",
            "  2 = USER (user messages)",
            "  3 = DEV (development logs)",
            "  4 = TRACE (ultra-verbose)"
        },
        handler = "SetDebugLevel"
    },
    {
        cmd = {"category", "cat"},
        desc = "Toggle a debug category: /nk debug category <name>",
        usage = "/nk debug category <name>",
        handler = "ToggleDebugCategory"
    },
    {
        cmd = {"status"},
        desc = "Show current debug settings",
        handler = "ShowDebugStatus"
    },
    {
        cmd = {"list"},
        desc = "List all available debug categories",
        handler = "ListDebugCategories"
    }
}

-- Test subcommands
local TestCommands = {
    {
        cmd = {"", "realistic"},
        desc = "Generate 4 realistic fake players",
        handler = "GenerateRealistic"
    },
    {
        cmd = {"mixed"},
        desc = "Generate custom mix: /nk test mixed X Y Z",
        usage = "/nk test mixed <nextkey> <raiderio> <none>",
        details = {
            "  X = players with NextKey addon",
            "  Y = players with RaiderIO only",
            "  Z = players with no addons"
        },
        handler = "GenerateMixed"
    },
    {
        cmd = {"preset"},
        desc = "Generate preset team: /nk test preset <type>",
        usage = "/nk test preset <type>",
        details = {
            "  Types: mixed_skill, beginner, expert, high_keys"
        },
        handler = "GeneratePreset"
    },
    {
        cmd = {"clear"},
        desc = "Clear all fake players",
        handler = "ClearFakePlayers"
    },
    {
        cmd = {"status"},
        desc = "Show FakePlayerService status",
        handler = "ShowTestStatus"
    },
    {
        cmd = {"help", "?"},
        desc = "Show test command help",
        handler = "ShowTestHelp"
    }
}

-- PUG Helper subcommands
local PUGCommands = {
    {
        cmd = {"", "help", "?"},
        desc = "Show PUG Helper command help",
        handler = "ShowPUGHelp"
    },
    {
        cmd = {"status"},
        desc = "Show PUG Helper status and current state",
        handler = "ShowPUGStatus"
    },
    {
        cmd = {"test"},
        desc = "Test PUG Helper application tracking",
        handler = "TestPUGTracking"
    },
    {
        cmd = {"detect"},
        desc = "Manually trigger LFG application detection",
        handler = "DetectApplications"
    },
    {
        cmd = {"simulate"},
        desc = "Simulate PUG workflow: /nk pug simulate <invite|join|complete>",
        usage = "/nk pug simulate <invite|join|complete>",
        details = {
            "  invite - Simulate receiving a group invite",
            "  join - Simulate joining a group",
            "  complete - Simulate completing a dungeon"
        },
        handler = "SimulatePUGWorkflow"
    },
    {
        cmd = {"enable"},
        desc = "Enable PUG Helper",
        handler = "EnablePUGHelper"
    },
    {
        cmd = {"disable"},
        desc = "Disable PUG Helper",
        handler = "DisablePUGHelper"
    },
    {
        cmd = {"reset"},
        desc = "Reset PUG Helper state",
        handler = "ResetPUGHelper"
    },
   {
       cmd = {"testui"},
       desc = "Test PUG UI components: /nk pug testui <invite|travel|getaway>",
       usage = "/nk pug testui <invite|travel|getaway>",
       details = {
           "  invite - Test invite notification UI",
           "  travel - Test travel assistant UI",
           "  getaway - Test getaway UI"
       },
       handler = "TestPUGUI"
   },
   {
       cmd = {"scenario"},
       desc = "Set test scenario: /nk pug scenario <invite|travel|getaway> <name>",
       usage = "/nk pug scenario <type> <name>",
       handler = "SetTestScenario"
   },
   {
       cmd = {"tracker"},
       desc = "Application tracker commands: /nk pug tracker <show|hide|toggle|enable>",
       usage = "/nk pug tracker <show|hide|toggle|enable>",
       details = {
           "  show - Show the application tracker window",
           "  hide - Hide the application tracker window",
           "  toggle - Toggle the application tracker window",
           "  enable - Force-enable the application tracker"
       },
       handler = "ApplicationTrackerCommands"
   },
   {
       cmd = {"fixes"},
       desc = "Test PUG Helper fixes for API issues",
       handler = "TestPUGHelperFixes"
   }
}

-- Component testing subcommands
local ComponentCommands = {
    {
        cmd = {"", "test", "run"},
        desc = "Run all component system tests",
        handler = "RunComponentTests"
    },
    {
        cmd = {"backdrop"},
        desc = "Test backdrop factory specifically",
        handler = "TestBackdropFactory"
    },
    {
        cmd = {"button"},
        desc = "Test button factory specifically",
        handler = "TestButtonFactory"
    },
    {
        cmd = {"frame"},
        desc = "Test frame factory specifically",
        handler = "TestFrameFactory"
    },
    {
        cmd = {"text", "label"},
        desc = "Test text/label factory specifically",
        handler = "TestTextFactory"
    },
    {
        cmd = {"icon"},
        desc = "Test icon factory specifically",
        handler = "TestIconFactory"
    },
    {
        cmd = {"integration"},
        desc = "Test component integration scenarios",
        handler = "TestComponentIntegration"
    },
    {
        cmd = {"performance", "perf"},
        desc = "Test component creation performance",
        handler = "TestComponentPerformance"
    },
    {
        cmd = {"validation"},
        desc = "Test component validation functions",
        handler = "TestComponentValidation"
    },
    {
        cmd = {"help", "?"},
        desc = "Show component testing help",
        handler = "ShowComponentHelp"
    }
}

-- Validation subcommands
local ValidationCommands = {
    {
        cmd = {"", "help", "?"},
        desc = "Show validation command help",
        handler = "ShowValidationHelp"
    },
    {
        cmd = {"all", "run"},
        desc = "Run all Phase 7 validation tests",
        handler = "RunAllValidations"
    },
    {
        cmd = {"unit"},
        desc = "Run unit tests for individual systems",
        handler = "RunUnitTests"
    },
    {
        cmd = {"integration"},
        desc = "Run integration tests for system interaction",
        handler = "RunIntegrationTests"
    },
    {
        cmd = {"performance"},
        desc = "Run performance validation tests",
        handler = "RunPerformanceTests"
    },
    {
        cmd = {"ui"},
        desc = "Run UI-specific validation tests",
        handler = "RunUITests"
    },
    {
        cmd = {"status"},
        desc = "Show validation system status",
        handler = "ShowValidationStatus"
    }
}

-- Visual testing subcommands
local VisualCommands = {
   {
       cmd = {"", "help", "?"},
       desc = "Show visual testing command help",
       handler = "ShowVisualHelp"
   },
   {
       cmd = {"keystones", "keys"},
       desc = "Test keystone detection and management visually",
       handler = "TestKeystonesVisual"
   },
   {
       cmd = {"communication", "comm"},
       desc = "Test communication system visually",
       handler = "TestCommunicationVisual"
   },
   {
       cmd = {"ui", "components"},
       desc = "Test UI components visually",
       handler = "TestUIComponentsVisual"
   },
   {
       cmd = {"pug", "workflow"},
       desc = "Test PUG Mode workflow visually",
       handler = "TestPUGWorkflowVisual"
   },
   {
       cmd = {"all", "complete"},
       desc = "Run all visual tests in sequence",
       handler = "RunAllVisualTests"
   },
   {
       cmd = {"status"},
       desc = "Show visual testing status",
       handler = "ShowVisualStatus"
   }
}

-- MARK: - Command Handlers

local SlashCommands = {}

-- Main window commands
function SlashCommands:ShowMainWindow()
    NextKey222.Debug:Dev("slashcommands", "ShowMainWindow called - UI available:", NextKey222.UI and "YES" or "NO")
    
    if NextKey222.UI and NextKey222.UI.ShowMainFrame then
        NextKey222.Debug:Dev("slashcommands", "Using ShowMainFrame method")
        NextKey222.UI:ShowMainFrame()
    elseif NextKey222.UI and NextKey222.UI.ToggleMainFrame then
        NextKey222.Debug:Dev("slashcommands", "Using ToggleMainFrame method")
        NextKey222.UI:ToggleMainFrame()
    elseif NextKey222.UI and NextKey222.UI.CreateMainFrame then
        NextKey222.Debug:Dev("slashcommands", "Using CreateMainFrame method")
        NextKey222.UI:CreateMainFrame()
    else
        NextKey222.Debug:User("UI not ready yet")
    end
end

function SlashCommands:HideMainWindow()
    if NextKey222.UI and NextKey222.UI.mainFrame then
        NextKey222.UI.mainFrame:Hide()
        NextKey222.Debug:User("Main frame hidden")
    else
        NextKey222.Debug:User("No frame to hide")
    end
end

-- Help commands
function SlashCommands:ShowHelp()
    NextKey222.Debug:User("=== NextKey Commands ===")
    for _, cmd in ipairs(Commands) do
        local cmdStr = "/" .. "nk " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
    end
    NextKey222.Debug:User(" ")
    NextKey222.Debug:User("Use '/nk help' to see this message again")
end

-- Configuration
function SlashCommands:ShowConfig()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog then
        AceConfigDialog:Open("NextKey")
    else
        NextKey222.Debug:Error("Config interface not available")
    end
end

-- Version info
function SlashCommands:ShowVersion()
    if NextKey222.Addon then
        NextKey222.Debug:User("NextKey version:", NextKey222.Addon.version or "unknown")
        NextKey222.Debug:User("Game version:", NextKey222.Addon.game_version or "unknown")
    else
        NextKey222.Debug:User("Version information not available")
    end
end

-- Status
function SlashCommands:ShowStatus()
    NextKey222.Debug:User("=== NextKey Status ===")
    NextKey222.Debug:User("- UI Ready:", NextKey222.UI and "Yes" or "No")
    NextKey222.Debug:User("- Events Ready:", NextKey222.Events and "Yes" or "No")
    NextKey222.Debug:User("- Communications Ready:", NextKey222.Communications and "Yes" or "No")
    NextKey222.Debug:User("- Debug Ready:", NextKey222.Debug and "Yes" or "No")
    NextKey222.Debug:User("- IOCalculator Ready:", NextKey222.IOCalculator and "Yes" or "No")
    NextKey222.Debug:User("- PUG Helper Ready:", NextKey222.PUGHelper and "Yes" or "No")
    if NextKey222.PUGHelper then
        NextKey222.Debug:User("- PUG Helper Enabled:", NextKey222.PUGHelper:IsEnabled() and "Yes" or "No")
        NextKey222.Debug:User("- PUG Helper State:", NextKey222.PUGHelper:GetState())
    end
end

-- Reload
function SlashCommands:ReloadUI()
    ReloadUI()
end

-- MARK: - Debug Command Handlers

function SlashCommands:ShowDebugHelp()
    NextKey222.Debug:User("=== Debug Commands ===")
    for _, cmd in ipairs(DebugCommands) do
        local cmdStr = "/" .. "nk debug " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk debug"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
        if cmd.details then
            for _, detail in ipairs(cmd.details) do
                NextKey222.Debug:User(detail)
            end
        end
    end
end

function SlashCommands:EnableDebug()
    if NextKey222.Debug and NextKey222.Debug.SetEnabled then
        NextKey222.Debug:SetEnabled(true)
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

function SlashCommands:DisableDebug()
    if NextKey222.Debug and NextKey222.Debug.SetEnabled then
        NextKey222.Debug:SetEnabled(false)
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

function SlashCommands:ToggleDebug()
    if NextKey222.Debug and NextKey222.Debug.Toggle then
        NextKey222.Debug:Toggle()
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

function SlashCommands:SetDebugLevel(level)
    if not level then
        NextKey222.Debug:User("Usage: /nk debug level <0-4>")
        NextKey222.Debug:User("  0 = NONE, 1 = ERROR, 2 = USER, 3 = DEV, 4 = TRACE")
        return
    end
    
    local levelNum = tonumber(level)
    if levelNum and NextKey222.Debug and NextKey222.Debug.SetLevel then
        NextKey222.Debug:SetLevel(levelNum)
    else
        NextKey222.Debug:User("Usage: /nk debug level <0-4>")
        NextKey222.Debug:User("  0 = NONE, 1 = ERROR, 2 = USER, 3 = DEV, 4 = TRACE")
    end
end

function SlashCommands:ToggleDebugCategory(category)
    if not category or category == "" then
        NextKey222.Debug:User("Usage: /nk debug category <name>")
        NextKey222.Debug:User("Use '/nk debug list' to see available categories")
        return
    end
    
    if NextKey222.Debug and NextKey222.Debug.ToggleCategory then
        NextKey222.Debug:ToggleCategory(category)
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

function SlashCommands:ShowDebugStatus()
    if NextKey222.Debug and NextKey222.Debug.PrintStatus then
        NextKey222.Debug:PrintStatus()
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

function SlashCommands:ListDebugCategories()
    if NextKey222.Debug and NextKey222.Debug.ListCategories then
        NextKey222.Debug:ListCategories()
    else
        NextKey222.Debug:Error("Debug system not ready")
    end
end

-- MARK: - Test Command Handlers

function SlashCommands:GenerateRealistic()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateRandomPlayers(4, { nextkey = 2, raiderio = 1, none = 1 })
    NextKey222.Debug:User("Generated " .. count .. " realistic fake players")
    NextKey222.Debug:User("  - 2 with NextKey addon")
    NextKey222.Debug:User("  - 1 with RaiderIO only")
    NextKey222.Debug:User("  - 1 with no addons")
end

function SlashCommands:GenerateMixed(args)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    local nextkey_count = tonumber(args[1]) or 2
    local rio_count = tonumber(args[2]) or 1
    local none_count = tonumber(args[3]) or 1
    local total = nextkey_count + rio_count + none_count
    
    local count = NextKey222.FakePlayerService:GenerateRandomPlayers(total, {
        nextkey = nextkey_count,
        raiderio = rio_count,
        none = none_count
    })
    NextKey222.Debug:User(string.format("Generated %d fake players (%d NextKey, %d RaiderIO, %d None)",
        count, nextkey_count, rio_count, none_count))
end

function SlashCommands:GeneratePreset(presetType)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    presetType = presetType or "mixed_skill"
    local count = NextKey222.FakePlayerService:GeneratePreset(presetType)
    NextKey222.Debug:User("Generated preset '" .. presetType .. "' with " .. count .. " players")
end

function SlashCommands:ClearFakePlayers()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    local count = NextKey222.FakePlayerService:ClearAllPlayers()
    NextKey222.Debug:User("Cleared " .. count .. " fake players")
end

function SlashCommands:ShowTestStatus()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    NextKey222.FakePlayerService:LogStats()
end

function SlashCommands:ShowTestHelp()
    NextKey222.Debug:User("=== Test Commands ===")
    for _, cmd in ipairs(TestCommands) do
        local cmdStr = "/" .. "nk test " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk test"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
        if cmd.details then
            for _, detail in ipairs(cmd.details) do
                NextKey222.Debug:User(detail)
            end
        end
    end
end

-- RaiderIO debug
function SlashCommands:DebugRaiderIO()
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        NextKey222.Debug:Dev("raiderio", "Checking RaiderIO for", playerName .. "-" .. realmName)
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            NextKey222.Debug:User("RaiderIO Profile found!")
            NextKey222.Debug:User("  currentScore:", mp.currentScore or "nil")
        else
            NextKey222.Debug:User("No RaiderIO profile found")
        end
    else
        NextKey222.Debug:User("RaiderIO addon not found")
    end
end

-- MARK: - PUG Helper Command Handlers

function SlashCommands:ShowPUGHelp()
    NextKey222.Debug:User("=== PUG Helper Commands ===")
    for _, cmd in ipairs(PUGCommands) do
        local cmdStr = "/" .. "nk pug " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk pug"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
        if cmd.details then
            for _, detail in ipairs(cmd.details) do
                NextKey222.Debug:User(detail)
            end
        end
    end
end

function SlashCommands:ShowPUGStatus()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    NextKey222.Debug:User("=== PUG Helper Status ===")
    NextKey222.Debug:User("- Enabled:", NextKey222.PUGHelper:IsEnabled() and "Yes" or "No")
    NextKey222.Debug:User("- Current State:", NextKey222.PUGHelper:GetState())
    
    local config = NextKey222.PUGHelper:GetConfig()
    NextKey222.Debug:User("- Show Notifications:", config.showNotifications and "Yes" or "No")
    NextKey222.Debug:User("- Auto Accept Invites:", config.autoAcceptInvites and "Yes" or "No")
    NextKey222.Debug:User("- Travel Assistant:", config.travelAssistant and "Yes" or "No")
    NextKey222.Debug:User("- Getaway UI:", config.getawayUI and "Yes" or "No")
end

function SlashCommands:TestPUGTracking()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    if NextKey222.PUGHelper.TestApplicationTracking then
        NextKey222.PUGHelper:TestApplicationTracking()
        NextKey222.Debug:User("PUG Helper: Test application tracking activated")
    else
        NextKey222.Debug:User("PUG Helper: Test function not available")
    end
end

function SlashCommands:DetectApplications()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    print("NextKey PUG: Manually triggering application detection...")
    if NextKey222.PUGHelper.OnApplicationListUpdated then
        NextKey222.PUGHelper:OnApplicationListUpdated()
        NextKey222.Debug:User("PUG Helper: Manual application detection triggered")
    else
        NextKey222.Debug:User("PUG Helper: OnApplicationListUpdated function not available")
    end
end

function SlashCommands:SimulatePUGWorkflow(action)
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    if not action or action == "" then
        NextKey222.Debug:User("Usage: /nk pug simulate <invite|join|complete>")
        return
    end
    
    action = string.lower(action)
    
    if action == "invite" then
        -- Simulate receiving an invite
        NextKey222.Debug:User("PUG Helper: Simulating group invite...")
        if NextKey222.Events and NextKey222.Events.OnGroupInviteConfirmation then
            NextKey222.Events:OnGroupInviteConfirmation("TestLeader-Realm")
        end
    elseif action == "join" then
        -- Simulate joining a group
        NextKey222.Debug:User("PUG Helper: Simulating group join...")
        if NextKey222.Events and NextKey222.Events.OnGroupJoined then
            NextKey222.Events:OnGroupJoined()
        end
    elseif action == "complete" then
        -- Simulate completing a dungeon
        NextKey222.Debug:User("PUG Helper: Simulating dungeon completion...")
        if NextKey222.Events and NextKey222.Events.OnChallengeModeCompleted then
            NextKey222.Events:OnChallengeModeCompleted(503, 10) -- Ara-Kara, level 10
        end
    else
        NextKey222.Debug:User("Usage: /nk pug simulate <invite|join|complete>")
        NextKey222.Debug:User("  invite - Simulate receiving a group invite")
        NextKey222.Debug:User("  join - Simulate joining a group")
        NextKey222.Debug:User("  complete - Simulate completing a dungeon")
    end
end

function SlashCommands:EnablePUGHelper()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    NextKey222.PUGHelper:SetEnabled(true)
    NextKey222.Debug:User("PUG Helper enabled")
end

function SlashCommands:DisablePUGHelper()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    NextKey222.PUGHelper:SetEnabled(false)
    NextKey222.Debug:User("PUG Helper disabled")
end

function SlashCommands:ResetPUGHelper()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    if NextKey222.PUGHelper.ResetState then
        NextKey222.PUGHelper:ResetState()
        NextKey222.Debug:User("PUG Helper state reset")
    else
        NextKey222.Debug:User("PUG Helper: Reset function not available")
    end
end

function SlashCommands:TestPUGUI(uiType)
   NextKey222.Debug:User("PUG UI testing functionality has been removed")
   NextKey222.Debug:User("Use the basic PUG Helper commands for testing")
end

function SlashCommands:SetTestScenario(scenarioType, scenarioName)
   NextKey222.Debug:User("PUG test scenario functionality has been removed")
   NextKey222.Debug:User("Use the basic PUG Helper commands for testing")
end

function SlashCommands:ApplicationTrackerCommands(action)
   if not NextKey222.PUGApplicationTracker then
       NextKey222.Debug:User("Application Tracker module not available")
       return
   end
   
   if not action or action == "" then
       NextKey222.Debug:User("Usage: /nk pug tracker <show|hide|toggle|enable>")
       return
   end
   
   action = string.lower(action)
   
   if action == "show" then
       -- Force enable before showing
       NextKey222.PUGApplicationTracker:SetEnabled(true)
       NextKey222.PUGApplicationTracker:Show()
       NextKey222.Debug:User("Application tracker shown (force-enabled)")
   elseif action == "hide" then
       NextKey222.PUGApplicationTracker:Hide()
       NextKey222.Debug:User("Application tracker hidden")
   elseif action == "toggle" then
       -- Force enable before toggling
       NextKey222.PUGApplicationTracker:SetEnabled(true)
       NextKey222.PUGApplicationTracker:Toggle()
       NextKey222.Debug:User("Application tracker toggled (force-enabled)")
   elseif action == "enable" then
       NextKey222.PUGApplicationTracker:SetEnabled(true)
       NextKey222.Debug:User("Application tracker force-enabled")
   else
       NextKey222.Debug:User("Usage: /nk pug tracker <show|hide|toggle|enable>")
       NextKey222.Debug:User("  show - Show the application tracker window")
       NextKey222.Debug:User("  hide - Hide the application tracker window")
       NextKey222.Debug:User("  toggle - Toggle the application tracker window")
       NextKey222.Debug:User("  enable - Force-enable the application tracker")
   end
end

function SlashCommands:TestPUGHelperFixes()
    if not NextKey222.PUGHelper then
        NextKey222.Debug:User("PUG Helper module not available")
        return
    end
    
    if NextKey222.PUGHelper.TestPUGHelperFixes then
        NextKey222.Debug:User("Testing PUG Helper fixes...")
        local success = NextKey222.PUGHelper:TestPUGHelperFixes()
        if success then
            NextKey222.Debug:User("✓ All PUG Helper fix tests passed!")
        else
            NextKey222.Debug:User("✗ Some PUG Helper fix tests failed")
        end
    else
        NextKey222.Debug:User("PUG Helper: TestPUGHelperFixes function not available")
    end
end


-- MARK: - Component Command Handlers

function SlashCommands:ShowComponentHelp()
    NextKey222.Debug:User("=== Component Testing Commands ===")
    for _, cmd in ipairs(ComponentCommands) do
        local cmdStr = "/" .. "nk components " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk components"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
    end
end

function SlashCommands:RunComponentTests()
    if NextKeyRunComponentTests then
        NextKey222.Debug:User("Running all component system tests...")
        local success = NextKeyRunComponentTests()
        
        local results = NextKeyGetComponentTestResults()
        if results then
            NextKey222.Debug:User(string.format("Component Tests Complete: %d/%d passed",
                results.passed, results.total))
            
            if results.failed > 0 then
                NextKey222.Debug:User("Failed tests:")
                for _, failure in ipairs(results.failures) do
                    NextKey222.Debug:User("  - " .. failure)
                end
            end
        end
        
        if success then
            NextKey222.Debug:User("✓ All component tests passed!")
        else
            NextKey222.Debug:User("✗ Some component tests failed")
        end
    else
        NextKey222.Debug:User("Component tests not available")
    end
end

function SlashCommands:TestBackdropFactory()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestBackdropFactory then
        NextKey222.Debug:User("Testing backdrop factory...")
        local success = NextKey222.ComponentTests:TestBackdropFactory()
        NextKey222.Debug:User(success and "✓ Backdrop factory tests passed" or "✗ Backdrop factory tests failed")
    else
        NextKey222.Debug:User("Backdrop factory tests not available")
    end
end

function SlashCommands:TestButtonFactory()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestButtonFactory then
        NextKey222.Debug:User("Testing button factory...")
        local success = NextKey222.ComponentTests:TestButtonFactory()
        NextKey222.Debug:User(success and "✓ Button factory tests passed" or "✗ Button factory tests failed")
    else
        NextKey222.Debug:User("Button factory tests not available")
    end
end

function SlashCommands:TestFrameFactory()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestFrameFactory then
        NextKey222.Debug:User("Testing frame factory...")
        local success = NextKey222.ComponentTests:TestFrameFactory()
        NextKey222.Debug:User(success and "✓ Frame factory tests passed" or "✗ Frame factory tests failed")
    else
        NextKey222.Debug:User("Frame factory tests not available")
    end
end

function SlashCommands:TestTextFactory()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestTextFactory then
        NextKey222.Debug:User("Testing text/label factory...")
        local success = NextKey222.ComponentTests:TestTextFactory()
        NextKey222.Debug:User(success and "✓ Text factory tests passed" or "✗ Text factory tests failed")
    else
        NextKey222.Debug:User("Text factory tests not available")
    end
end

function SlashCommands:TestIconFactory()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestIconFactory then
        NextKey222.Debug:User("Testing icon factory...")
        local success = NextKey222.ComponentTests:TestIconFactory()
        NextKey222.Debug:User(success and "✓ Icon factory tests passed" or "✗ Icon factory tests failed")
    else
        NextKey222.Debug:User("Icon factory tests not available")
    end
end

function SlashCommands:TestComponentIntegration()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestComponentIntegration then
        NextKey222.Debug:User("Testing component integration...")
        local success = NextKey222.ComponentTests:TestComponentIntegration()
        NextKey222.Debug:User(success and "✓ Integration tests passed" or "✗ Integration tests failed")
    else
        NextKey222.Debug:User("Integration tests not available")
    end
end

function SlashCommands:TestComponentPerformance()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestComponentPerformance then
        NextKey222.Debug:User("Testing component performance...")
        local success = NextKey222.ComponentTests:TestComponentPerformance()
        NextKey222.Debug:User(success and "✓ Performance tests passed" or "✗ Performance tests failed")
    else
        NextKey222.Debug:User("Performance tests not available")
    end
end

function SlashCommands:TestComponentValidation()
    if NextKey222.ComponentTests and NextKey222.ComponentTests.TestComponentValidation then
        NextKey222.Debug:User("Testing component validation...")
        local success = NextKey222.ComponentTests:TestComponentValidation()
        NextKey222.Debug:User(success and "✓ Validation tests passed" or "✗ Validation tests failed")
    else
        NextKey222.Debug:User("Validation tests not available")
    end
end

-- MARK: - Validation Command Handlers

function SlashCommands:ShowValidationHelp()
    NextKey222.Debug:User("=== Phase 7 Validation Commands ===")
    for _, cmd in ipairs(ValidationCommands) do
        local cmdStr = "/" .. "nk validate " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk validate"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
    end
end

function SlashCommands:RunAllValidations()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Running Phase 7 Validation Tests ===")
    NextKey222.Debug:User("This may take a moment...")
    
    local results, summary = NextKey222.Validation:RunAllValidations("all")
    NextKey222.Validation:PrintValidationResults(results, summary)
    
    if summary.success then
        NextKey222.Debug:User("✓ All validation tests passed!")
    else
        NextKey222.Debug:User("✗ Some validation tests failed")
    end
end

function SlashCommands:RunUnitTests()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Running Unit Tests ===")
    
    local results, summary = NextKey222.Validation:RunAllValidations("unit")
    NextKey222.Validation:PrintValidationResults(results, summary)
    
    if summary.success then
        NextKey222.Debug:User("✓ All unit tests passed!")
    else
        NextKey222.Debug:User("✗ Some unit tests failed")
    end
end

function SlashCommands:RunIntegrationTests()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Running Integration Tests ===")
    
    local results, summary = NextKey222.Validation:RunAllValidations("integration")
    NextKey222.Validation:PrintValidationResults(results, summary)
    
    if summary.success then
        NextKey222.Debug:User("✓ All integration tests passed!")
    else
        NextKey222.Debug:User("✗ Some integration tests failed")
    end
end

function SlashCommands:RunPerformanceTests()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Running Performance Tests ===")
    
    -- Run performance-specific tests
    local results = {}
    results.performance = NextKey222.Validation:TestPerformanceSystem()
    
    local summary = NextKey222.Validation:GenerateValidationSummary(results, 0)
    NextKey222.Validation:PrintValidationResults(results, summary)
    
    if summary.success then
        NextKey222.Debug:User("✓ All performance tests passed!")
    else
        NextKey222.Debug:User("✗ Some performance tests failed")
    end
end

function SlashCommands:RunUITests()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Running UI Tests ===")
    
    -- Run UI-specific tests
    local results = {}
    results.tooltip = NextKey222.Validation:TestTooltipSystem()
    results.theme = NextKey222.Validation:TestThemeSystem()
    results.uiScale = NextKey222.Validation:TestUIScaleSystem()
    results.responsive = NextKey222.Validation:TestResponsiveSystem()
    
    local summary = NextKey222.Validation:GenerateValidationSummary(results, 0)
    NextKey222.Validation:PrintValidationResults(results, summary)
    
    if summary.success then
        NextKey222.Debug:User("✓ All UI tests passed!")
    else
        NextKey222.Debug:User("✗ Some UI tests failed")
    end
end

function SlashCommands:ShowValidationStatus()
    if not NextKey222.Validation then
        NextKey222.Debug:User("Validation system not available")
        return
    end
    
    NextKey222.Debug:User("=== Validation System Status ===")
    NextKey222.Debug:User("- Available:", "Yes")
    
    -- Check which systems are available for validation
    local systems = {
        "ConfigurationContext",
        "Tooltip",
        "Theme",
        "UIScale",
        "Responsive",
        "Performance",
        "UIComponents",
        "UI"
    }
    
    NextKey222.Debug:User("- Available Systems:")
    for _, system in ipairs(systems) do
        local available = NextKey222[system] ~= nil
        NextKey222.Debug:User("  - " .. system .. ": " .. (available and "✓" or "✗"))
    end
end

-- MARK: - Scroll Bar Test Command Handler

function SlashCommands:TestScrollBar()
    NextKey222.Debug:User("Testing scroll bar visibility fix...")
    
    -- Check main UI frame
    if NextKey222.UI and NextKey222.UI.mainFrame then
        local mainVisible = NextKey222.UI.mainFrame:IsShown()
        NextKey222.Debug:User("Main UI frame visibility: " .. (mainVisible and "VISIBLE" or "HIDDEN"))
        
        if NextKey222.UI.resultsFrame and NextKey222.UI.resultsFrame.frame then
            local resultsVisible = NextKey222.UI.resultsFrame.frame:IsShown()
            NextKey222.Debug:User("Main results frame visibility: " .. (resultsVisible and "VISIBLE" or "HIDDEN"))
        end
    else
        NextKey222.Debug:User("Main UI frame not created")
    end
    
    -- Check PUG Application Tracker
    if NextKey222.PUGApplicationTracker and NextKey222.PUGApplicationTracker.frame then
        local pugVisible = NextKey222.PUGApplicationTracker.frame.frame:IsShown()
        NextKey222.Debug:User("PUG Application Tracker visibility: " .. (pugVisible and "VISIBLE" or "HIDDEN"))
        
        if NextKey222.PUGApplicationTracker.scrollFrame and NextKey222.PUGApplicationTracker.scrollFrame.frame then
            local pugScrollVisible = NextKey222.PUGApplicationTracker.scrollFrame.frame:IsShown()
            NextKey222.Debug:User("PUG Application Tracker scroll frame visibility: " .. (pugScrollVisible and "VISIBLE" or "HIDDEN"))
        end
    else
        NextKey222.Debug:User("PUG Application Tracker frame not created")
    end
    
    -- Check Loot Window
    if NextKey222.LootWindow and NextKey222.LootWindow.frame then
        local lootVisible = NextKey222.LootWindow.frame:IsShown()
        NextKey222.Debug:User("Loot Window visibility: " .. (lootVisible and "VISIBLE" or "HIDDEN"))
        
        if NextKey222.LootWindow.scrollFrame and NextKey222.LootWindow.scrollFrame.frame then
            local lootScrollVisible = NextKey222.LootWindow.scrollFrame.frame:IsShown()
            NextKey222.Debug:User("Loot Window scroll frame visibility: " .. (lootScrollVisible and "VISIBLE" or "HIDDEN"))
        end
    else
        NextKey222.Debug:User("Loot Window frame not created")
    end
    
    NextKey222.Debug:User("Scroll bar visibility test completed")
    NextKey222.Debug:User("If any scroll frames are visible when they shouldn't be, the fix may need adjustment")
end

-- MARK: - Dungeon Cards Test Command Handler

function SlashCommands:TestDungeonCards()
    NextKey222.Debug:User("Testing dungeon cards layout...")
    
    if not NextKey222.Addon.DungeonCardsUI then
        NextKey222.Debug:Error("DungeonCardsUI not available")
        return
    end
    
    if NextKey222.Addon.DungeonCardsUI.TestDungeonCards then
        NextKey222.Addon.DungeonCardsUI:TestDungeonCards()
        NextKey222.Debug:User("Dungeon cards test completed - check visual layout")
        NextKey222.Debug:User("Use '/nk dungeon' again to refresh the test")
    else
        NextKey222.Debug:Error("DungeonCardsUI.TestDungeonCards method not available")
    end
end

-- MARK: - Main Slash Command Handler

local function HandleSlashCommand(input)
    local command = string.lower(string.trim and string.trim(input) or input or "")
    
    -- Parse command and subcommands
    local args = {strsplit(" ", command)}
    local mainCmd = args[1] or ""
    local subCmd = args[2] or ""
    local subArgs = {}
    for i = 3, #args do
        table.insert(subArgs, args[i])
    end
    
    -- Handle debug commands
    if mainCmd == "debug" then
        for _, cmdDef in ipairs(DebugCommands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                    end
                    return
                end
            end
        end
        -- Unknown debug subcommand - show help
        SlashCommands:ShowDebugHelp()
        return
    end
    
    -- Handle test commands
    if mainCmd == "test" then
        for _, cmdDef in ipairs(TestCommands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                    end
                    return
                end
            end
        end
        -- Unknown test subcommand - show help
        SlashCommands:ShowTestHelp()
        return
    end
    
    -- Handle PUG commands
    if mainCmd == "pug" then
        for _, cmdDef in ipairs(PUGCommands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                    end
                    return
                end
            end
        end
        -- Unknown PUG subcommand - show help
        SlashCommands:ShowPUGHelp()
        return
    end
    
    -- Handle component commands
    if mainCmd == "components" then
        for _, cmdDef in ipairs(ComponentCommands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                    end
                    return
                end
            end
        end
        -- Unknown component subcommand - show help
        SlashCommands:ShowComponentHelp()
        return
    end
    
    -- Handle validation commands
    if mainCmd == "validate" then
        for _, cmdDef in ipairs(ValidationCommands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                    end
                    return
                end
            end
        end
        -- Unknown validation subcommand - show help
        SlashCommands:ShowValidationHelp()
        return
    end
    
    -- Handle main commands
    for _, cmdDef in ipairs(Commands) do
        for _, cmdName in ipairs(cmdDef.cmd) do
            if mainCmd == cmdName then
                local handler = SlashCommands[cmdDef.handler]
                if handler then
                    handler(SlashCommands, subCmd, args)
                end
                return
            end
        end
    end
    
    -- Unknown command - show help
    SlashCommands:ShowHelp()
end

-- MARK: - Registration

-- Register slash commands
SLASH_NEXTKEY1 = "/nextkey"
SLASH_NEXTKEY2 = "/nk"
SlashCmdList["NEXTKEY"] = HandleSlashCommand

-- Store reference for external access
NextKey222.SlashCommands = SlashCommands

NextKey222.Debug:Dev("startup", "Slash commands registered")