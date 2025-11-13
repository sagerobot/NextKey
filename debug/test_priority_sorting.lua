-- Test: Simple Sort Priority - "Want to Play" > "Fill" across all roles
-- This test validates that players who select "play" for a role are assigned
-- before players who select "fill" for all roles.

local _, NextKey222 = ...

local function test_priority_sorting()
    print("\n=== Testing Priority Sorting: 'Play' > 'Fill' ===\n")
    
    -- Test Case 1: Fill-all player vs Play-specific player
    print("Test Case 1: Fill-all vs Play-specific")
    
    local benchPlayers = {
        -- Player A: Fill on all roles
        {
            id = "PlayerA-Realm",
            name = "PlayerA",
            class = "PALADIN",
            roles = {"TANK", "HEALER", "DAMAGER"},
            specPreferences = {
                TANK = "fill",
                HEALER = "fill",
                DAMAGER = "fill"
            }
        },
        -- Player B: Play Healer only
        {
            id = "PlayerB-Realm",
            name = "PlayerB",
            class = "PRIEST",
            roles = {"HEALER"},
            specPreferences = {
                TANK = "none",
                HEALER = "play",
                DAMAGER = "none"
            }
        },
        -- Player C: Play Tank only
        {
            id = "PlayerC-Realm",
            name = "PlayerC",
            class = "WARRIOR",
            roles = {"TANK"},
            specPreferences = {
                TANK = "play",
                HEALER = "none",
                DAMAGER = "none"
            }
        },
        -- Player D: Play DPS only
        {
            id = "PlayerD-Realm",
            name = "PlayerD",
            class = "MAGE",
            roles = {"DAMAGER"},
            specPreferences = {
                TANK = "none",
                HEALER = "none",
                DAMAGER = "play"
            }
        }
    }
    
    local assignments = NextKey222.OrganizerSorting:CalculateSequentialAssignment(benchPlayers, 1)
    
    print("Expected behavior:")
    print("  - PlayerC should be Tank (play preference)")
    print("  - PlayerB should be Healer (play preference)")
    print("  - PlayerD should be DPS slot 1 (play preference)")
    print("  - PlayerA should be DPS slot 2 or 3 (fill preference)")
    print("")
    
    print("Actual assignments:")
    for i, assignment in ipairs(assignments) do
        local player = assignment.player
        print(string.format("  %d. %s -> Group %d, Slot %d (%s) - Preference: %s",
            i, player.name, assignment.groupIndex, assignment.slotIndex, 
            assignment.role, assignment.assignedFromPreference or "unknown"))
    end
    
    -- Validate results
    local tankAssignment = assignments[1]
    local healerAssignment = assignments[2]
    local dpsAssignment1 = assignments[3]
    
    local success = true
    
    if tankAssignment.player.name ~= "PlayerC" then
        print("\n[FAIL] Tank should be PlayerC (play), got " .. tankAssignment.player.name)
        success = false
    end
    
    if healerAssignment.player.name ~= "PlayerB" then
        print("\n[FAIL] Healer should be PlayerB (play), got " .. healerAssignment.player.name)
        success = false
    end
    
    if dpsAssignment1.player.name ~= "PlayerD" then
        print("\n[FAIL] DPS slot 1 should be PlayerD (play), got " .. dpsAssignment1.player.name)
        success = false
    end
    
    -- PlayerA should NOT be assigned to Tank or Healer (those should go to play preferences)
    for i = 1, 2 do
        if assignments[i].player.name == "PlayerA" then
            print("\n[FAIL] PlayerA (fill-all) was assigned to " .. assignments[i].role .. " before play-specific players")
            success = false
        end
    end
    
    if success then
        print("\n[OK] All priority checks passed!")
    end
    
    print("\n=== Test Complete ===\n")
    return success
end

-- Test Case 2: Multiple fill-all players
local function test_multiple_fill_players()
    print("\n=== Test Case 2: Multiple Fill-All Players ===\n")
    
    local benchPlayers = {
        -- Fill players
        {
            id = "FillPlayer1-Realm",
            name = "FillPlayer1",
            class = "DRUID",
            roles = {"TANK", "HEALER", "DAMAGER"},
            specPreferences = {TANK = "fill", HEALER = "fill", DAMAGER = "fill"}
        },
        {
            id = "FillPlayer2-Realm",
            name = "FillPlayer2",
            class = "PALADIN",
            roles = {"TANK", "HEALER", "DAMAGER"},
            specPreferences = {TANK = "fill", HEALER = "fill", DAMAGER = "fill"}
        },
        -- Play-specific players
        {
            id = "TankPlayer-Realm",
            name = "TankPlayer",
            class = "WARRIOR",
            roles = {"TANK"},
            specPreferences = {TANK = "play", HEALER = "none", DAMAGER = "none"}
        },
        {
            id = "HealerPlayer-Realm",
            name = "HealerPlayer",
            class = "PRIEST",
            roles = {"HEALER"},
            specPreferences = {TANK = "none", HEALER = "play", DAMAGER = "none"}
        }
    }
    
    local assignments = NextKey222.OrganizerSorting:CalculateSequentialAssignment(benchPlayers, 1)
    
    print("Assignments:")
    for i, assignment in ipairs(assignments) do
        print(string.format("  %d. %s -> %s (pref: %s)",
            i, assignment.player.name, assignment.role, assignment.assignedFromPreference))
    end
    
    local success = true
    
    if assignments[1].player.name ~= "TankPlayer" then
        print("\n[FAIL] Tank should be TankPlayer (play)")
        success = false
    end
    
    if assignments[2].player.name ~= "HealerPlayer" then
        print("\n[FAIL] Healer should be HealerPlayer (play)")
        success = false
    end
    
    if success then
        print("\n[OK] Multiple fill-all test passed!")
    end
    
    return success
end

-- Global test runner
function NextKeyTestPrioritySorting()
    local test1 = test_priority_sorting()
    local test2 = test_multiple_fill_players()
    
    if test1 and test2 then
        print("\n=== ALL TESTS PASSED ===")
    else
        print("\n=== SOME TESTS FAILED ===")
    end
end

-- Slash command for easy testing
SLASH_NKTESTPRIORITY1 = "/nktestpriority"
SlashCmdList["NKTESTPRIORITY"] = function()
    NextKeyTestPrioritySorting()
end

if NextKey222.Debug and NextKey222.Debug.DEV_MODE then
    print("Priority sorting test loaded. Use /nktestpriority to run tests.")
end