-- ==============================================================================
-- NextKey Slash Commands - Centralized Command Handler
-- ==============================================================================
-- Provides /nextkey and /nk slash commands with organized subcommands
-- This file makes it easy to add, modify, and document commands in one place
-- ==============================================================================

local addonName, NextKey222 = ...

-- MARK: Role Test (Debug)
-- Separate slash command for role detection testing
SLASH_NKTESTROLE1 = "/nktestrole"
SlashCmdList["NKTESTROLE"] = function(msg)
    NextKey222.Debug:User("=== Role Detection Test ===")
    
    -- Get current player info
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local fullName = playerName .. "-" .. realmName
    
    NextKey222.Debug:User("Testing role detection for: " .. fullName)
    
    -- Test 1: Check GetSpecializationInfo directly
    local specIndex = GetSpecialization()
    if specIndex then
        local specID, specName, _, _, role = GetSpecializationInfo(specIndex)
        NextKey222.Debug:User("Blizzard API GetSpecializationInfo:")
        NextKey222.Debug:User("  - Spec ID: " .. tostring(specID))
        NextKey222.Debug:User("  - Spec Name: " .. tostring(specName))
        NextKey222.Debug:User("  - Role: " .. tostring(role))
    else
        NextKey222.Debug:Error("No specialization selected!")
        return
    end
    
    -- Test 2: Force profile cache invalidation and rebuild
    if NextKey222.ProfilesService then
        NextKey222.Debug:User("Invalidating profile cache...")
        
        -- Clear the profile cache for current player
        if NextKey222.ProfilesService.profileCache then
            NextKey222.ProfilesService.profileCache[fullName] = nil
            NextKey222.Debug:User("  - Profile cache cleared")
        end
        
        -- Test 3: Build fresh profile using BuildProfileForPlayer
        NextKey222.Debug:User("Building fresh profile...")
        local profile = NextKey222.ProfilesService:BuildProfileForPlayer(fullName)
        
        if profile then
            NextKey222.Debug:User("Standard Profile (BuildProfileForPlayer):")
            NextKey222.Debug:User("  - profile.role: " .. tostring(profile.role))
            NextKey222.Debug:User("  - profile.specID: " .. tostring(profile.specID))
            NextKey222.Debug:User("  - profile.specName: " .. tostring(profile.specName))
        else
            NextKey222.Debug:Error("Failed to build standard profile!")
        end
        
        -- Test 4: Build organizer profile using GetOrganizerProfile
        NextKey222.Debug:User("Building organizer profile...")
        local orgProfile = NextKey222.ProfilesService:GetOrganizerProfile(fullName)
        
        if orgProfile then
            NextKey222.Debug:User("Organizer Profile (GetOrganizerProfile):")
            NextKey222.Debug:User("  - profile.role: " .. tostring(orgProfile.role))
            NextKey222.Debug:User("  - profile.specID: " .. tostring(orgProfile.specID))
            NextKey222.Debug:User("  - profile.specName: " .. tostring(orgProfile.specName))
            
            if orgProfile.roles then
                NextKey222.Debug:User("  - profile.roles array:")
                for _, role in ipairs(orgProfile.roles) do
                    NextKey222.Debug:User("    * " .. tostring(role))
                end
            else
                NextKey222.Debug:User("  - profile.roles: nil")
            end
        else
            NextKey222.Debug:Error("Failed to build organizer profile!")
        end
        
        NextKey222.Debug:User("=== Test Complete ===")
        NextKey222.Debug:User("Check the debug output above for any mismatches.")
        NextKey222.Debug:User("Expected: All role values should be 'HEALER' for Preservation Evoker")
    else
        NextKey222.Debug:Error("ProfilesService not available!")
    end
end

-- MARK: Bonus ID Helpers

--- Extract Bonus IDs from an item link
local function ExtractBonusIDs(itemLink)
    if not itemLink or itemLink == "" then
        return nil
    end
    
    -- Parse the item link to extract bonus IDs
    local ids = {string.match(itemLink, "item:%d+:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:%d*:(%d+):([%d:]+)")}
    
    if ids[1] and ids[2] then
        return tonumber(ids[1]), ids[2]
    end
    
    return nil
end

--- Find Hero track Bonus IDs from chat messages
local function FindHeroTrackBonusIDs()
    print("=== NextKey: Finding Hero Track Bonus IDs ===")
    print("Instructions:")
    print("1. Open Dungeon Journal (Shift+J)")
    print("2. Select any M+ dungeon")
    print("3. Set difficulty to Mythic")
    print("4. Shift-click any item into chat")
    print("5. Press Enter to send the link")
    print(" ")
    print("Waiting for item link in chat...")
    
    -- Register a temporary event listener for chat messages
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SAY")
    frame:RegisterEvent("CHAT_MSG_YELL")
    frame:RegisterEvent("CHAT_MSG_PARTY")
    frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    frame:RegisterEvent("CHAT_MSG_RAID")
    frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    frame:RegisterEvent("CHAT_MSG_GUILD")
    
    frame:SetScript("OnEvent", function(self, event, message, sender)
        -- Look for item link in the message
        local itemLink = message:match("|H(item[^|]+)|h")
        
        if itemLink then
            itemLink = "|H" .. itemLink .. "|h"
            
            local numBonuses, bonusIDString = ExtractBonusIDs(itemLink)
            
            if numBonuses and bonusIDString then
                print(" ")
                print("=== FOUND BONUS IDs ===")
                print("Number of Bonus IDs:", numBonuses)
                print("Bonus IDs:", bonusIDString)
                print(" ")
                print("Update core/utils/item.lua lines 27-31:")
                print("local bonusIDs = {")
                
                for bonusID in bonusIDString:gmatch("(%d+)") do
                    print(string.format("    %s,", bonusID))
                end
                
                print("}")
                print(" ")
                
                -- Unregister events
                self:UnregisterAllEvents()
                self:SetScript("OnEvent", nil)
            else
                print("Could not extract Bonus IDs from item link")
            end
        end
    end)
    
    -- Auto-cleanup after 60 seconds
    C_Timer.After(60, function()
        if frame:GetScript("OnEvent") then
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            print("NextKey: Bonus ID finder timed out after 60 seconds")
        end
    end)
end

-- MARK: Commands
-- This table defines all available commands and their help text
-- Makes it easy to add new commands and keep help synchronized
local Commands = {
    -- Teleport window commands
    {
        cmd = {"tp", "teleport"},
        desc = "Open the Teleport window (Hearthstone + next key). Context-aware; debug mode adds simulated views.",
        handler = "TeleportCommands"
    },
    -- Teleport window commands
    {
        cmd = {"tp", "teleport"},
        desc = "Open the Teleport window (Hearthstone + next key). Context-aware; debug mode adds simulated views.",
        handler = "TeleportCommands"
    },
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
        cmd = {"poll"},
        desc = "Poll testing commands (use '/nk poll help' for details)",
        handler = "PollCommands"
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
        cmd = {"dungeon", "dungeons", "dung", "cards"},
        desc = "Show the dungeon overview UI",
        handler = "ShowDungeonCards"
    },
    
    -- M+ Organizer commands
    {
        cmd = {"roster", "organizer", "org"},
        desc = "Show the M+ Group Organizer",
        handler = "ShowOrganizer"
    },
    
    -- Character storage commands
    {
        cmd = {"chars", "characters"},
        desc = "Character storage commands (use '/nk chars help' for details)",
        handler = "CharacterStorageCommands"
    },
    
    -- Drag test commands
    {
        cmd = {"drag", "dragtest"},
        desc = "Show the drag-and-drop test window",
        handler = "ShowDragTest"
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
        cmd = {"custom"},
        desc = "Create custom fake player: /nk test custom <name> <class> [specID] [io]",
        usage = "/nk test custom <name> <class> [specID] [io]",
        details = {
            "  name - Player name (no realm needed)",
            "  class - WARRIOR, PALADIN, HUNTER, etc.",
            "  specID - Optional: Specific spec ID (e.g., 1468 for Preservation)",
            "  io - Optional: Total IO score",
            "  For full customization, use /nk config → Debug System → Fake Player Tools"
        },
        handler = "CreateCustomPlayer"
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
            "  Types: mixed_skill, beginner, expert, high_keys, raid_group"
        },
        handler = "GeneratePreset"
    },
    {
        cmd = {"io-gap", "iogap"},
        desc = "Generate IO Gap team (1 expert + 3 beginners) to test Max Group IO vs Max Player Coverage",
        handler = "GenerateIOGapTeam"
    },
    {
        cmd = {"loot-focus", "lootfocus"},
        desc = "Generate Loot-Focused team to test Max Item Need sorting",
        handler = "GenerateLootFocusTeam"
    },
    {
        cmd = {"mixed-levels", "mixedlevels"},
        desc = "Generate Mixed Key Level team (keys +7 to +16) to test key level vs IO optimization",
        handler = "GenerateMixedKeyLevelTeam"
    },
    {
        cmd = {"uneven-benefit", "unevenbenefit"},
        desc = "Generate Uneven Benefit team (dungeon specialists) to test fairness vs efficiency",
        handler = "GenerateUnevenBenefitTeam"
    },
    {
        cmd = {"algorithm-test", "algotest"},
        desc = "Generate comprehensive Algorithm Test team to expose all sorting differences",
        handler = "GenerateAlgorithmTestTeam"
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

-- Poll testing subcommands
local PollCommands = {
    {
        cmd = {"", "help", "?"},
        desc = "Show poll testing command help",
        handler = "ShowPollHelp"
    },
    {
        cmd = {"test"},
        desc = "Test poll simulation: /nk poll test <instant|realistic>",
        usage = "/nk poll test <instant|realistic>",
        details = {
            "  instant - All responses within 0-2 seconds",
            "  realistic - Staggered responses over 0-60 seconds"
        },
        handler = "TestPollSimulation"
    },
    {
        cmd = {"status"},
        desc = "Show poll simulation status",
        handler = "ShowPollStatus"
    },
    {
        cmd = {"clear"},
        desc = "Clear poll simulation state",
        handler = "ClearPollSimulation"
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
           "  invite - (reserved)",
           "  travel - (reserved)",
           "  getaway - Show sample getaway UI without a real dungeon"
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

-- MARK: Command Handlers

-- Initialize SlashCommands table first
local SlashCommands = {}

-- MARK: Teleport Commands

function SlashCommands:TeleportCommands(sub_cmd, args)
    local addon = NextKey222.Addon
    local Debug = NextKey222.Debug

    if not addon or not addon.ToggleTeleportWindow then
        if Debug and Debug.Error then
            Debug:Error("Teleport window not available")
        end
        return
    end

    -- Router passes: handler(SlashCommands, subCmd, fullArgsTable)
    local main = sub_cmd or ""
    main = string.lower(main)

    -- Primary user path: `/nk tp` or `/nk teleport`
    if main == "" then
        if Debug and Debug.User then
            Debug:User("Opening Teleport window")
        end
        addon:ToggleTeleportWindow()
        return
    end

    -- Debug-only simulated modes: `/nk tp debug <premade|pug|postrun>`
    if main == "debug" then
        local is_debug_mode = addon.db
            and addon.db.global
            and addon.db.global.debug
            and addon.db.global.debug.enabled

        if not is_debug_mode then
            if Debug and Debug.User then
                Debug:User("Teleport debug views require Debug Mode enabled in /nk config")
            end
            addon:ToggleTeleportWindow()
            return
        end

        local mode_arg = args and args[2] and string.lower(args[2]) or ""

        if mode_arg == "premade" then
            if Debug and Debug.User then
                Debug:User("Teleport: Simulating premade context")
            end
            if addon.SetTeleportWindowContext then
                addon:SetTeleportWindowContext({ mode = "DEBUG_PREMADE" })
            end
            addon:ToggleTeleportWindow()
            return
        elseif mode_arg == "pug" then
            if Debug and Debug.User then
                Debug:User("Teleport: Simulating PUG context")
            end
            if addon.SetTeleportWindowContext then
                addon:SetTeleportWindowContext({ mode = "PUG" })
            end
            addon:ToggleTeleportWindow()
            return
        elseif mode_arg == "postrun" or mode_arg == "post_run" then
            if Debug and Debug.User then
                Debug:User("Teleport: Simulating post-run context")
            end
            if addon.SetTeleportWindowContext then
                addon:SetTeleportWindowContext({ mode = "DEBUG_POST_RUN" })
            end
            addon:ToggleTeleportWindow()
            return
        end

        if Debug and Debug.User then
            Debug:User("Usage: /nk tp debug &lt;premade|pug|postrun&gt;")
        end
        return
    end

    -- Fallback: unknown teleport subcommand
    if Debug and Debug.User then
        Debug:User("Unknown teleport command.")
        Debug:User("Usage:")
        Debug:User("  /nk tp                 - Open Teleport window (normal behavior)")
        Debug:User("  /nk teleport           - Same as /nk tp")
        if addon.db and addon.db.global and addon.db.global.debug and addon.db.global.debug.enabled then
            Debug:User("  /nk tp debug premade   - Simulate premade view")
            Debug:User("  /nk tp debug pug       - Simulate PUG view")
            Debug:User("  /nk tp debug postrun   - Simulate post-run view")
        end
    end

    addon:ToggleTeleportWindow()
end

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

-- Organizer commands
function SlashCommands:ShowOrganizer()
    print("[ORGANIZER DEBUG] ShowOrganizer called")
    print("[ORGANIZER DEBUG] NextKey222.RosterBoard exists:", NextKey222.RosterBoard and "YES" or "NO")
    
    NextKey222.Debug:Dev("slashcommands", "ShowOrganizer called - RosterBoard available:", NextKey222.RosterBoard and "YES" or "NO")
    
    if NextKey222.RosterBoard then
        print("[ORGANIZER DEBUG] RosterBoard exists, checking for Show method:", NextKey222.RosterBoard.Show and "YES" or "NO")
        
        if NextKey222.RosterBoard.Show then
            print("[ORGANIZER DEBUG] Calling RosterBoard:Show()...")
            NextKey222.Debug:Dev("slashcommands", "Using RosterBoard Show method")
            NextKey222.RosterBoard:Show()
            print("[ORGANIZER DEBUG] RosterBoard:Show() call completed")
        else
            print("[ORGANIZER DEBUG] ERROR: RosterBoard.Show method does not exist!")
            NextKey222.Debug:Error("RosterBoard.Show method not available")
        end
    else
        print("[ORGANIZER DEBUG] ERROR: RosterBoard module does not exist!")
        NextKey222.Debug:User("M+ Group Organizer not ready yet")
    end
end

-- Drag test command
function SlashCommands:ShowDragTest()
    NextKey222.Debug:Dev("slashcommands", "ShowDragTest called")
    
    -- Try simple drag test first (new pure native approach)
    if NextKey222.SimpleDragTest then
        if NextKey222.SimpleDragTest.Show then
            NextKey222.SimpleDragTest:Show()
        else
            NextKey222.Debug:Error("SimpleDragTest.Show method not available")
        end
    -- Fall back to original if simple not available
    elseif NextKey222.DragTest then
        if NextKey222.DragTest.Show then
            NextKey222.DragTest:Show()
        else
            NextKey222.Debug:Error("DragTest.Show method not available")
        end
    else
        NextKey222.Debug:User("Drag test window not ready yet")
    end
end

-- Dungeon cards commands
function SlashCommands:ShowDungeonCards()
    NextKey222.Debug:Dev("slashcommands", "ShowDungeonCards called")
    
    if NextKey222.DungeonWindow then
        if NextKey222.DungeonWindow.Show then
            NextKey222.DungeonWindow:Show()
        else
            NextKey222.Debug:Error("DungeonWindow.Show method not available")
        end
    else
        NextKey222.Debug:User("Dungeon window not ready yet")
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
        
        -- Start live updates for debug statistics when config is opened
        if NextKey222.DebugUI and NextKey222.DebugUI.StartLiveUpdates then
            NextKey222.DebugUI:StartLiveUpdates()
        end
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

-- MARK: Debug Commands

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

-- MARK: Test Commands

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
    NextKey222.Debug:User(" ")
    NextKey222.Debug:User("Algorithm Testing Teams:")
    NextKey222.Debug:User("  /nk test io-gap          - 1 expert + 3 beginners (tests coverage vs efficiency)")
    NextKey222.Debug:User("  /nk test loot-focus      - Loot targeting team (tests Max Item Need)")
    NextKey222.Debug:User("  /nk test mixed-levels    - Keys +7 to +16 (tests level vs IO)")
    NextKey222.Debug:User("  /nk test uneven-benefit  - Specialists (tests fairness)")
    NextKey222.Debug:User("  /nk test algorithm-test  - Comprehensive test for all algorithms")
    NextKey222.Debug:User(" ")
    NextKey222.Debug:User("For GUI-based custom player creation:")
    NextKey222.Debug:User("  /nk config → Debug System → Fake Player Tools → Custom Player Builder")
end

function SlashCommands:CreateCustomPlayer(args)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    -- Parse arguments
    local name = args[1]
    local class = args[2]
    local specID = tonumber(args[3])
    local io = tonumber(args[4])
    
    if not name or not class then
        NextKey222.Debug:User("Usage: /nk test custom <name> <class> [specID] [io]")
        NextKey222.Debug:User("Example: /nk test custom Ryuzaki EVOKER 1468 3200")
        NextKey222.Debug:User(" ")
        NextKey222.Debug:User("For full customization with dropdowns and preview:")
        NextKey222.Debug:User("  /nk config → Debug System → Fake Player Tools → Custom Player Builder")
        return
    end
    
    -- Validate name against Blizzard's official WoW character naming rules
    local baseName = name:match("^([^%-]+)") or name
    
    -- Rule 1: Length (2-12 characters)
    if #baseName < 2 or #baseName > 12 then
        NextKey222.Debug:Error("Player name must be 2-12 characters")
        return
    end
    
    -- Rule 2 & 3: Letters only (accented supported), no numbers/symbols
    if not baseName:match("^%a+$") then
        NextKey222.Debug:Error("Player name can only contain letters (no spaces, numbers, or symbols)")
        return
    end
    
    -- Rule 4: No mixed capitals (e.g., "TaNk")
    local isAllLower = baseName == baseName:lower()
    local isAllUpper = baseName == baseName:upper()
    local isProperCase = baseName:sub(1, 1) == baseName:sub(1, 1):upper() and baseName:sub(2) == baseName:sub(2):lower()
    
    if not (isAllLower or isAllUpper or isProperCase) then
        NextKey222.Debug:Error("Name cannot have mixed capitals (use 'Tank', 'TANK', or 'tank', not 'TaNk')")
        return
    end
    
    -- Build config
    local config = {
        name = name,
        class = string.upper(class),
        specID = specID,
        io = io,
    }
    
    -- Create player
    local playerName = NextKey222.FakePlayerService:CreatePlayer(config)
    
    if playerName then
        NextKey222.Debug:User(string.format("Created custom player: %s (%s)",
            playerName, config.class))
        
        -- Refresh UI
        if NextKey222.UI and NextKey222.UI.RenderResults then
            NextKey222.UI:RenderResults()
        end
    else
        NextKey222.Debug:Error("Failed to create player - name may already exist or invalid parameters")
    end
end

function SlashCommands:GenerateIOGapTeam()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    if not NextKey222.FakePlayerService.GenerateIOGapTeam then
        NextKey222.Debug:Error("GenerateIOGapTeam method not available - FakePlayerService may need updating")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateIOGapTeam()
    NextKey222.Debug:User("Generated IO Gap team with " .. count .. " players")
    NextKey222.Debug:User("  - 1 expert player (3200+ IO)")
    NextKey222.Debug:User("  - 3 beginner players (800-1200 IO)")
    NextKey222.Debug:User("This team tests Max Group IO vs Max Player Coverage sorting")
end

function SlashCommands:GenerateLootFocusTeam()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    if not NextKey222.FakePlayerService.GenerateLootFocusedTeam then
        NextKey222.Debug:Error("GenerateLootFocusedTeam method not available - FakePlayerService may need updating")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateLootFocusedTeam()
    NextKey222.Debug:User("Generated Loot-Focused team with " .. count .. " players")
    NextKey222.Debug:User("  - Players tracking specific items from different dungeons")
    NextKey222.Debug:User("This team tests Max Item Need sorting")
end

function SlashCommands:GenerateMixedKeyLevelTeam()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    if not NextKey222.FakePlayerService.GenerateMixedKeyLevelTeam then
        NextKey222.Debug:Error("GenerateMixedKeyLevelTeam method not available - FakePlayerService may need updating")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateMixedKeyLevelTeam()
    NextKey222.Debug:User("Generated Mixed Key Level team with " .. count .. " players")
    NextKey222.Debug:User("  - Keys ranging from +7 to +16")
    NextKey222.Debug:User("This team tests Highest Key Level vs Max Group IO sorting")
end

function SlashCommands:GenerateUnevenBenefitTeam()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    if not NextKey222.FakePlayerService.GenerateUnevenBenefitTeam then
        NextKey222.Debug:Error("GenerateUnevenBenefitTeam method not available - FakePlayerService may need updating")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateUnevenBenefitTeam()
    NextKey222.Debug:User("Generated Uneven Benefit team with " .. count .. " players")
    NextKey222.Debug:User("  - Players with specialized dungeon strengths/weaknesses")
    NextKey222.Debug:User("This team tests Max Player Coverage (fairness) vs Max Group IO (efficiency)")
end

function SlashCommands:GenerateAlgorithmTestTeam()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available")
        return
    end
    
    if not NextKey222.FakePlayerService.GenerateAlgorithmTestTeam then
        NextKey222.Debug:Error("GenerateAlgorithmTestTeam method not available - FakePlayerService may need updating")
        return
    end
    
    local count = NextKey222.FakePlayerService:GenerateAlgorithmTestTeam()
    NextKey222.Debug:User("Generated comprehensive Algorithm Test team with " .. count .. " players")
    NextKey222.Debug:User("  - Varied IO levels (800-3500)")
    NextKey222.Debug:User("  - Mixed key levels (+7 to +15)")
    NextKey222.Debug:User("  - Dungeon specialists and generalists")
    NextKey222.Debug:User("  - Loot targeting included")
    NextKey222.Debug:User("This team is designed to show differences across ALL sorting algorithms")
end

-- MARK: Poll Commands

function SlashCommands:ShowPollHelp()
    NextKey222.Debug:User("=== Poll Testing Commands ===")
    for _, cmd in ipairs(PollCommands) do
        local cmdStr = "/" .. "nk poll " .. cmd.cmd[1]
        if cmd.cmd[1] == "" then
            cmdStr = "/" .. "nk poll"
        end
        NextKey222.Debug:User("  " .. cmdStr .. " - " .. cmd.desc)
        if cmd.details then
            for _, detail in ipairs(cmd.details) do
                NextKey222.Debug:User(detail)
            end
        end
    end
end

function SlashCommands:TestPollSimulation(patternType)
    if not NextKey222.PollSimulator or not NextKey222.PollSimulator:IsInitialized() then
        NextKey222.Debug:User("Poll simulator not available")
        return
    end
    
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        NextKey222.Debug:User("FakePlayerService not available - generate fake players first")
        NextKey222.Debug:User("Use: /nk test preset raid_group")
        return
    end
    
    -- Check if we have fake players
    local playerCount = #NextKey222.FakePlayerService:GetAllPlayerNames()
    if playerCount == 0 then
        NextKey222.Debug:User("No fake players available - generate some first")
        NextKey222.Debug:User("Use: /nk test preset raid_group")
        return
    end
    
    patternType = patternType or "instant"
    
    if patternType ~= "instant" and patternType ~= "realistic" then
        NextKey222.Debug:User("Usage: /nk poll test <instant|realistic>")
        NextKey222.Debug:User("  instant - All responses within 0-2 seconds")
        NextKey222.Debug:User("  realistic - Staggered responses over 0-60 seconds")
        return
    end
    
    -- Generate a unique poll ID
    local pollID = "TEST_" .. tostring(math.random(1000, 9999))
    
    -- Start simulation
    NextKey222.Debug:User("Starting " .. patternType .. " poll simulation...")
    NextKey222.Debug:User("Poll ID: " .. pollID)
    NextKey222.Debug:User("Fake players: " .. playerCount)
    
    if NextKey222.PollSimulator:SimulatePoll(patternType, pollID) then
        NextKey222.Debug:User("Poll simulation started successfully")
        NextKey222.Debug:User("Responses will arrive over the next " .. (patternType == "instant" and "2" or "60") .. " seconds")
        NextKey222.Debug:User("Use '/nk poll status' to check progress")
    else
        NextKey222.Debug:Error("Failed to start poll simulation")
    end
end

function SlashCommands:ShowPollStatus()
    if not NextKey222.PollSimulator or not NextKey222.PollSimulator:IsInitialized() then
        NextKey222.Debug:User("Poll simulator not available")
        return
    end
    
    local status = NextKey222.PollSimulator:GetStatus()
    
    if not status then
        NextKey222.Debug:User("No active poll simulation")
        return
    end
    
    NextKey222.Debug:User("=== Poll Simulation Status ===")
    NextKey222.Debug:User("- Poll ID: " .. status.pollID)
    NextKey222.Debug:User("- Pattern: " .. status.pattern)
    NextKey222.Debug:User("- Players: " .. status.playerCount)
    NextKey222.Debug:User("- Elapsed: " .. string.format("%.1fs", status.elapsed))
end

function SlashCommands:ClearPollSimulation()
    if not NextKey222.PollSimulator or not NextKey222.PollSimulator:IsInitialized() then
        NextKey222.Debug:User("Poll simulator not available")
        return
    end
    
    NextKey222.PollSimulator:Clear()
    NextKey222.Debug:User("Poll simulation cleared")
end

-- RaiderIO debug
function SlashCommands:DebugRaiderIO()
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        NextKey222.Debug:User("=== RaiderIO Data Dump ===")
        NextKey222.Debug:User("Player: " .. playerName .. "-" .. realmName)
        
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            NextKey222.Debug:User("Profile Found!")
            NextKey222.Debug:User("  Total IO: " .. (mp.currentScore or "nil"))
            
            if mp.sortedDungeons then
                NextKey222.Debug:User("  Dungeons: " .. #mp.sortedDungeons)
                NextKey222.Debug:User("")
                NextKey222.Debug:User("Dungeon Details:")
                
                for i, dung in ipairs(mp.sortedDungeons) do
                    if dung and dung.dungeon then
                        NextKey222.Debug:User(string.format("  %d. %s (ID: %d)",
                            i, dung.dungeon.shortName or "Unknown", dung.dungeon.id))
                        NextKey222.Debug:User(string.format("      level: %d", dung.level or 0))
                        NextKey222.Debug:User(string.format("      chests: %d", dung.chests or 0))
                        NextKey222.Debug:User(string.format("      fractionalTime: %.4f", dung.fractionalTime or 0))
                        
                        -- Calculate our score
                        if NextKey222.IOCalculator and NextKey222.IOCalculator.EstimateRunScore then
                            local timed = (dung.chests or 0) > 0
                            local score = NextKey222.IOCalculator:EstimateRunScore(
                                dung.level, timed, dung.fractionalTime
                            )
                            NextKey222.Debug:User(string.format("      Our calculated score: %d", score))
                        end
                        NextKey222.Debug:User("")
                    end
                end
            else
                NextKey222.Debug:User("  No sortedDungeons data")
            end
        else
            NextKey222.Debug:User("No RaiderIO profile found")
        end
    else
        NextKey222.Debug:User("RaiderIO addon not found")
    end
end

-- MARK: PUG Commands

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
    if not uiType or uiType == "" then
        NextKey222.Debug:User("Usage: /nk pug testui <getaway>")
        return
    end

    uiType = string.lower(uiType)

    if uiType == "getaway" then
        if not NextKey222.PUGGetawayUI or not NextKey222.PUGGetawayUI.Show then
            NextKey222.Debug:Error("PUG Getaway UI module not available")
            return
        end

        local now = GetTime()
        local fakeInfo = {
            name = "Test Dungeon (Getaway Demo)",
            dungeonID = 9999,
            keyLevel = 10,
            joinedAt = now - 1800,
            completedAt = now,
            completedMapID = 9999,
            completedLevel = 10
        }

        NextKey222.Debug:User("Showing PUG Getaway UI test window (no real dungeon required)")
        NextKey222.PUGGetawayUI:Show(fakeInfo)
        return
    end

    NextKey222.Debug:User("Usage: /nk pug testui <getaway>")
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
       NextKey222.Debug:User("  enable - Force-enable the application tracker feature")
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


-- MARK: Component Commands

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

-- MARK: Validation Commands

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

-- MARK: Scroll Bar Test

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

-- MARK: Dungeon Cards Test

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

-- MARK: Char Storage
function SlashCommands:CharacterStorageCommands(args)
    if not args or args == "" then
        NextKey222.Debug:User("Character Storage Commands:")
        NextKey222.Debug:User("  /nk chars save - Capture current character data")
        NextKey222.Debug:User("  /nk chars list - List all saved characters")
        NextKey222.Debug:User("  /nk chars capture - Force character data capture")
        return
    end
    
    args = string.lower(args)
    
    if args == "save" or args == "capture" then
        -- Manually capture current character data
        if NextKey222.Events and NextKey222.Events.CaptureCurrentCharacterData then
            NextKey222.Events:CaptureCurrentCharacterData()
            NextKey222.Debug:User("Character data captured manually")
        else
            NextKey222.Debug:Error("Events module not available")
        end
    elseif args == "list" or args == "debug" then
        -- List all saved characters
        if NextKey222.CharacterStorage and NextKey222.CharacterStorage.DebugPrintAllCharacters then
            NextKey222.CharacterStorage:DebugPrintAllCharacters()
        else
            NextKey222.Debug:Error("CharacterStorage not available")
        end
    elseif args == "capture" then
        -- Force character data capture with multiple attempts
        if NextKey222.Events and NextKey222.Events.ScheduleCharacterCapture then
            NextKey222.Events:ScheduleCharacterCapture()
            NextKey222.Debug:User("Force character data capture scheduled")
        else
            NextKey222.Debug:Error("Events module not available")
        end
    else
        NextKey222.Debug:User("Unknown character storage command:", args)
        NextKey222.Debug:User("Available commands: save, list, capture")
    end
end

-- MARK: Main Handler

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
    
    local commandGroups = {
        debug = { commands = DebugCommands, help = "ShowDebugHelp" },
        test = { commands = TestCommands, help = "ShowTestHelp" },
        pug = { commands = PUGCommands, help = "ShowPUGHelp" },
        components = { commands = ComponentCommands, help = "ShowComponentHelp" },
        validate = { commands = ValidationCommands, help = "ShowValidationHelp" },
        chars = { commands = "CharacterStorageCommands", help = "CharacterStorageCommands" },
    }

    if commandGroups[mainCmd] then
        local group = commandGroups[mainCmd]
        
        -- Special handling for character storage commands (direct handler)
        if mainCmd == "chars" then
            local handler = SlashCommands[group.help]
            if handler then
                handler(SlashCommands, subCmd, subArgs)
                return
            end
        end
        
        -- Handle other command groups normally
        for _, cmdDef in ipairs(group.commands) do
            for _, cmdName in ipairs(cmdDef.cmd) do
                if subCmd == cmdName then
                    local handler = SlashCommands[cmdDef.handler]
                    if handler then
                        handler(SlashCommands, subArgs[1], subArgs)
                        return
                    end
                end
            end
        end
        SlashCommands[group.help](SlashCommands)
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

-- MARK: Registration

-- Register slash commands
SLASH_NEXTKEY1 = "/nextkey"
SLASH_NEXTKEY2 = "/nk"
SlashCmdList["NEXTKEY"] = HandleSlashCommand

-- UI debug/test helpers (Phase 6): delegate to UIDebugHelpers if available.
SLASH_NEXTKEYREFRESHDEBUG1 = "/nextkeyrefreshdebug"
SlashCmdList["NEXTKEYREFRESHDEBUG"] = function()
    if NextKey222.UIDebugHelpers and NextKey222.UIDebugHelpers.RefreshDebugControls then
        NextKey222.UIDebugHelpers:RefreshDebugControls()
    elseif NextKey222.UI and NextKey222.UI.RefreshDebugControls then
        NextKey222.UI:RefreshDebugControls()
    end
end

SLASH_NEXTKEYREFRESH1 = "/nextkeyrefresh"
SlashCmdList["NEXTKEYREFRESH"] = function()
    if NextKey222.UIDebugHelpers and NextKey222.UIDebugHelpers.RefreshUI then
        NextKey222.UIDebugHelpers:RefreshUI()
    elseif NextKey222.UI and NextKey222.UI.RefreshResults then
        NextKey222.UI:RefreshResults()
    end
end

SLASH_NEXTKEYTESTSPEC1 = "/nextkeytestspec"
SlashCmdList["NEXTKEYTESTSPEC"] = function()
    if NextKey222.UIDebugHelpers and NextKey222.UIDebugHelpers.SimulateSpecChange then
        NextKey222.UIDebugHelpers:SimulateSpecChange()
    end
end

SLASH_NEXTKEYROSTER1 = "/nkroster"
SlashCmdList["NEXTKEYROSTER"] = function()
    if NextKey222.UIDebugHelpers and NextKey222.UIDebugHelpers.OpenRosterBoard then
        NextKey222.UIDebugHelpers:OpenRosterBoard()
        return
    end

    if NextKey222.RosterBoard and NextKey222.RosterBoard.Show then
        local ui = NextKey222.UI
        if ui and ui.mainFrame and ui.mainFrame.IsShown and ui.mainFrame:IsShown() then
            ui.mainFrame:Hide()
        end
        NextKey222.RosterBoard:Show()
    else
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("RosterBoard module not available for /nkroster")
        end
    end
end

-- Bonus ID Finder Command
SLASH_NEXTKEYBONUSIDS1 = "/nkbonusids"
SLASH_NEXTKEYBONUSIDS2 = "/nk bonusids"
SlashCmdList["NEXTKEYBONUSIDS"] = function()
    FindHeroTrackBonusIDs()
end

-- Store reference for external access
NextKey222.SlashCommands = SlashCommands

if NextKey222.Debug and NextKey222.Debug.Dev then
    NextKey222.Debug:Dev("startup", "Slash commands registered")
end