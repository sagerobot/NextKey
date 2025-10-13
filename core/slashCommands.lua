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
    }
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
    }
}

-- MARK: - Command Handlers

local SlashCommands = {}

-- Main window commands
function SlashCommands:ShowMainWindow()
    if NextKey222.UI and NextKey222.UI.ToggleMainFrame then
        NextKey222.UI:ToggleMainFrame()
    elseif NextKey222.UI and NextKey222.UI.CreateMainFrame then
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
