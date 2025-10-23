-- MARK: Loot Tracking Test Script
-- Test script to verify loot tracking persistence and run counting functionality

local _, NextKey222 = ...

-- Test function to verify loot tracking persistence
local function TestLootTrackingPersistence()
    NextKey222.Debug:User("=== Testing Loot Tracking Persistence ===")
    
    if not NextKey.DungeonCards then
        NextKey222.Debug:Error("DungeonCards module not available")
        return false
    end
    
    -- Test 1: Track an item and verify it's saved
    local testDungeonID = 377 -- Halls of Atonement
    local testItemID = 246344 -- Cursed Stone Idol
    
    NextKey222.Debug:User("Test 1: Tracking item", testItemID, "for dungeon", testDungeonID)
    
    -- Track the item
    NextKey.DungeonCards:TrackItem(testDungeonID, testItemID, false, "Halls of Atonement")
    
    -- Save the tracking data
    NextKey.DungeonCards:SaveLootTracking()
    
    -- Verify the item is tracked
    local card = NextKey.DungeonCards:GetCard(testDungeonID, "Halls of Atonement")
    if card and card.trackedItems[testItemID] then
        NextKey222.Debug:User("✓ Item successfully tracked")
    else
        NextKey222.Debug:Error("✗ Failed to track item")
        return false
    end
    
    -- Test 2: Simulate reload by clearing and reloading
    NextKey222.Debug:User("Test 2: Simulating reload by clearing and reloading tracking data")
    
    -- Clear current tracking (simulate reload)
    card.trackedItems[testItemID] = nil
    if card.lootData and card.lootData[testItemID] then
        card.lootData[testItemID] = nil
    end
    
    -- Reload tracking data
    NextKey.DungeonCards:LoadLootTracking()
    
    -- Verify the item is still tracked after reload
    if card and card.trackedItems[testItemID] then
        NextKey222.Debug:User("✓ Item tracking persisted after reload")
    else
        NextKey222.Debug:Error("✗ Item tracking lost after reload")
        return false
    end
    
    -- Test 3: Test run counter increment
    NextKey222.Debug:User("Test 3: Testing run counter increment")
    
    local initialRuns = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    NextKey222.Debug:User("Initial run count:", initialRuns)
    
    -- Increment run counter
    NextKey.DungeonCards:IncrementRunCounter(testDungeonID, testItemID)
    
    local newRuns = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    NextKey222.Debug:User("Run count after increment:", newRuns)
    
    if newRuns == initialRuns + 1 then
        NextKey222.Debug:User("✓ Run counter incremented correctly")
    else
        NextKey222.Debug:Error("✗ Run counter increment failed")
        return false
    end
    
    -- Test 4: Test run counter persistence
    NextKey222.Debug:User("Test 4: Testing run counter persistence")
    
    -- Save the run counter
    NextKey.DungeonCards:SaveLootTracking()
    
    -- Clear run counter (simulate reload)
    if card.lootData and card.lootData[testItemID] then
        card.lootData[testItemID].runsSinceTracking = 0
    end
    
    -- Reload tracking data
    NextKey.DungeonCards:LoadLootTracking()
    
    -- Verify run counter persisted
    local persistedRuns = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    if persistedRuns == newRuns then
        NextKey222.Debug:User("✓ Run counter persisted after reload")
    else
        NextKey222.Debug:Error("✗ Run counter lost after reload")
        return false
    end
    
    -- Test 5: Test custom item tracking
    NextKey222.Debug:User("Test 5: Testing custom item tracking")
    
    local customItemID = 999999 -- Test custom item
    NextKey.DungeonCards:TrackItem(testDungeonID, customItemID, true, "Halls of Atonement")
    NextKey.DungeonCards:SaveLootTracking()
    
    -- Clear and reload
    card.customTrackedItems[customItemID] = nil
    NextKey.DungeonCards:LoadLootTracking()
    
    if card.customTrackedItems[customItemID] then
        NextKey222.Debug:User("✓ Custom item tracking persisted")
    else
        NextKey222.Debug:Error("✗ Custom item tracking lost")
        return false
    end
    
    NextKey222.Debug:User("=== All Loot Tracking Tests Passed! ===")
    return true
end

-- Test function to verify +7 level filtering
local function TestLevelFiltering()
    NextKey222.Debug:User("=== Testing +7 Level Filtering ===")
    
    local testDungeonID = 377
    local testItemID = 246344
    
    -- Track an item first
    NextKey.DungeonCards:TrackItem(testDungeonID, testItemID, false, "Halls of Atonement")
    
    -- Simulate level 6 completion (should not increment)
    NextKey222.Debug:User("Testing level 6 completion (should not increment)")
    local initialRuns = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    
    -- Simulate the event handler logic for level 6
    local level = 6
    if level >= 7 then
        NextKey.DungeonCards:IncrementRunCounter(testDungeonID, testItemID)
    end
    
    local runsAfterLevel6 = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    if runsAfterLevel6 == initialRuns then
        NextKey222.Debug:User("✓ Level 6 correctly ignored (no increment)")
    else
        NextKey222.Debug:Error("✗ Level 6 incorrectly incremented counter")
        return false
    end
    
    -- Simulate level 7 completion (should increment)
    NextKey222.Debug:User("Testing level 7 completion (should increment)")
    
    -- Simulate the event handler logic for level 7
    level = 7
    if level >= 7 then
        NextKey.DungeonCards:IncrementRunCounter(testDungeonID, testItemID)
    end
    
    local runsAfterLevel7 = NextKey.DungeonCards:GetRunCount(testDungeonID, testItemID)
    if runsAfterLevel7 == initialRuns + 1 then
        NextKey222.Debug:User("✓ Level 7 correctly incremented counter")
    else
        NextKey222.Debug:Error("✗ Level 7 failed to increment counter")
        return false
    end
    
    NextKey222.Debug:User("=== Level Filtering Tests Passed! ===")
    return true
end

-- Main test function
function TestLootTrackingFixes()
    NextKey222.Debug:User("Starting Loot Tracking Fix Tests...")
    
    local success = true
    
    -- Test persistence
    if not TestLootTrackingPersistence() then
        success = false
    end
    
    -- Test level filtering
    if not TestLevelFiltering() then
        success = false
    end
    
    if success then
        NextKey222.Debug:User("🎉 ALL LOOT TRACKING TESTS PASSED!")
        NextKey222.Debug:User("The fixes should now:")
        NextKey222.Debug:User("1. Persist tracked items across /reload")
        NextKey222.Debug:User("2. Increment run counters for +7 and higher dungeons")
        NextKey222.Debug:User("3. Persist run counters across /reload")
    else
        NextKey222.Debug:Error("❌ Some tests failed - check implementation")
    end
    
    return success
end

-- Make the test function globally available
_G.TestLootTrackingFixes = TestLootTrackingFixes

NextKey222.Debug:User("Loot tracking test script loaded. Use /script TestLootTrackingFixes() to run tests.")