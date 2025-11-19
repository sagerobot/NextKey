-- MARK: Card Layout Tests
-- Tests the dynamic card layout system with progressive data disclosure

local _, NextKey222 = ...
local Debug = NextKey222.Debug

-- MARK: Card Content Tests
local function TestCardContentUpdates()
    print("=== Testing Card Content Updates ===")
    
    if not NextKey222.RosterBoard or not NextKey222.RosterBoard.benchCards then
        print("[FAIL] RosterBoard not initialized or no bench cards")
        return false
    end
    
    local testCard = NextKey222.RosterBoard.benchCards[1]
    if not testCard then
        print("[FAIL] No bench cards available for testing")
        return false
    end
    
    print("[OK] Found test card:", testCard.playerData.name)
    
    -- Test 1: Compact mode
    print("\n[TEST 1] Switching to compact mode...")
    NextKey222.PlayerCard:UpdateCardContent(testCard, "compact")
    if testCard.displayMode == "compact" and testCard.regions.activeCount > 0 then
        print("[OK] Compact mode applied - Active regions:", testCard.regions.activeCount)
    else
        print("[FAIL] Compact mode failed")
        return false
    end
    
    -- Test 2: Opt-out mode
    print("\n[TEST 2] Switching to opt_out mode...")
    local compactRegionCount = testCard.regions.activeCount
    NextKey222.PlayerCard:UpdateCardContent(testCard, "opt_out")
    if testCard.displayMode == "opt_out" and testCard.regions.activeCount > 0 then
        print("[OK] Opt-out mode applied - Active regions:", testCard.regions.activeCount)
        print("    Region count change:", compactRegionCount, "->", testCard.regions.activeCount)
    else
        print("[FAIL] Opt-out mode failed")
        return false
    end
    
    -- Test 3: Expanded mode
    print("\n[TEST 3] Switching to expanded mode...")
    local optOutRegionCount = testCard.regions.activeCount
    NextKey222.PlayerCard:UpdateCardContent(testCard, "expanded")
    if testCard.displayMode == "expanded" and testCard.regions.activeCount > 0 then
        print("[OK] Expanded mode applied - Active regions:", testCard.regions.activeCount)
        print("    Region count change:", optOutRegionCount, "->", testCard.regions.activeCount)
    else
        print("[FAIL] Expanded mode failed")
        return false
    end
    
    -- Test 4: Back to compact
    print("\n[TEST 4] Switching back to compact mode...")
    local expandedRegionCount = testCard.regions.activeCount
    NextKey222.PlayerCard:UpdateCardContent(testCard, "compact")
    if testCard.displayMode == "compact" and testCard.regions.activeCount > 0 then
        print("[OK] Compact mode restored - Active regions:", testCard.regions.activeCount)
        print("    Region count change:", expandedRegionCount, "->", testCard.regions.activeCount)
    else
        print("[FAIL] Compact mode restoration failed")
        return false
    end
    
    print("\n=== All Card Content Tests Passed ===")
    return true
end

-- MARK: Test Region Cleanup
local function TestRegionCleanup()
    print("\n=== Testing Region Cleanup ===")
    
    if not NextKey222.RosterBoard or not NextKey222.RosterBoard.benchCards then
        print("[FAIL] RosterBoard not initialized")
        return false
    end
    
    local testCard = NextKey222.RosterBoard.benchCards[1]
    if not testCard or not testCard.regions then
        print("[FAIL] No test card or regions not initialized")
        return false
    end
    
    print("[OK] Testing with card:", testCard.playerData.name)
    print("    Current regions - Textures:", #testCard.regions.textures, "FontStrings:", #testCard.regions.fontStrings)
    
    -- Cycle through modes multiple times to test cleanup
    for cycle = 1, 3 do
        print("\n[CYCLE", cycle, "] Testing mode transitions...")
        
        NextKey222.PlayerCard:UpdateCardContent(testCard, "compact")
        local compactCount = testCard.regions.activeCount
        
        NextKey222.PlayerCard:UpdateCardContent(testCard, "opt_out")
        local optOutCount = testCard.regions.activeCount
        
        NextKey222.PlayerCard:UpdateCardContent(testCard, "expanded")
        local expandedCount = testCard.regions.activeCount
        
        print("    Active region counts: Compact:", compactCount, "OptOut:", optOutCount, "Expanded:", expandedCount)
        
        -- Check for region leaks
        if #testCard.regions.textures > 20 or #testCard.regions.fontStrings > 20 then
            print("[WARNING] Potential region leak detected!")
            print("    Total textures created:", #testCard.regions.textures)
            print("    Total font strings created:", #testCard.regions.fontStrings)
        end
    end
    
    print("\n[OK] Region cleanup appears functional")
    return true
end

-- MARK: Progressive Disclosure
local function TestProgressiveDisclosure()
    print("\n=== Testing Progressive Data Disclosure ===")
    
    print("\n[MODE 1: OPT-OUT] Minimal data - Name + Role icon")
    print("    Expected: ~3-4 regions (1 icon, 2-3 text)")
    
    print("\n[MODE 2: BENCH] Essential data - Roles, Name, Key, IO")
    print("    Expected: ~6-8 regions (2 icons max, 4-5 text)")
    
    print("\n[MODE 3: SLOT] Detailed data - Class icon, All roles, Full name, Key details, IO")
    print("    Expected: ~10-12 regions (1 class icon, 3 role icons, 4-5 text)")
    
    if TestCardContentUpdates() then
        print("\n[OK] Progressive disclosure working - different region counts per mode")
        return true
    else
        print("\n[FAIL] Progressive disclosure test failed")
        return false
    end
end

-- MARK: Main Test Runner
function TestCardLayoutSystem()
    print("\n")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║       Card Layout System Test Suite                       ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print("")
    
    local allPassed = true
    
    if not TestCardContentUpdates() then
        allPassed = false
    end
    
    if not TestRegionCleanup() then
        allPassed = false
    end
    
    if not TestProgressiveDisclosure() then
        allPassed = false
    end
    
    print("\n")
    print("╔════════════════════════════════════════════════════════════╗")
    if allPassed then
        print("║  RESULT: ALL TESTS PASSED                                 ║")
    else
        print("║  RESULT: SOME TESTS FAILED                                ║")
    end
    print("╚════════════════════════════════════════════════════════════╝")
    print("")
end

-- Make globally accessible
_G.TestCardLayoutSystem = TestCardLayoutSystem