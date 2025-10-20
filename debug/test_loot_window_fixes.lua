-- Test script for loot window fixes
-- Tests Phase 1-3 fixes and validates Phase 4 persistence

local _, NextKey222 = ...

-- Test function to validate loot window functionality
local function TestLootWindowFixes()
    NextKey222.Debug:Dev("test", "=== Starting Loot Window Fix Tests ===")
    
    -- Test 1: Verify component system is working
    NextKey222.Debug:Dev("test", "Test 1: Verifying UI Components system")
    if NextKey222.UIComponents then
        NextKey222.Debug:Dev("test", "✅ UI Components system available")
    else
        NextKey222.Debug:Error("❌ UI Components system not available")
        return false
    end
    
    -- Test 2: Verify loot data structure
    NextKey222.Debug:Dev("test", "Test 2: Verifying loot data structure")
    if NextKey.LootData and NextKey.LootData.dungeons then
        local dungeonCount = 0
        for dungeonID, data in pairs(NextKey.LootData.dungeons) do
            dungeonCount = dungeonCount + 1
            NextKey222.Debug:Dev("test", "✅ Dungeon", dungeonID, "has", #(data.defaultItems or {}), "default items")
        end
        NextKey222.Debug:Dev("test", "✅ Found", dungeonCount, "dungeons in loot data")
    else
        NextKey222.Debug:Error("❌ Loot data structure not available")
        return false
    end
    
    -- Test 3: Verify dungeon cards system
    NextKey222.Debug:Dev("test", "Test 3: Verifying dungeon cards system")
    if NextKey.DungeonCards then
        -- Test getting a card for Eco-Dome Al'dani (dungeonID 526)
        local testDungeonID = 526
        local card = NextKey.DungeonCards:GetCard(testDungeonID, "Eco-Dome Al'dani")
        if card then
            NextKey222.Debug:Dev("test", "✅ Successfully created/retrieved dungeon card for Eco-Dome Al'dani")
            
            -- Test item tracking
            local testItemID = 225578 -- Eco-Dome Energy Cell
            NextKey.DungeonCards:TrackItem(testDungeonID, testItemID, false, "Test")
            NextKey222.Debug:Dev("test", "✅ Successfully tracked default item:", testItemID)
            
            -- Test custom item tracking
            local customItemID = 207167 -- Test custom item
            NextKey.DungeonCards:TrackItem(testDungeonID, customItemID, true, "Test")
            NextKey222.Debug:Dev("test", "✅ Successfully tracked custom item:", customItemID)
            
            -- Test save/load
            NextKey.DungeonCards:SaveLootTracking()
            NextKey222.Debug:Dev("test", "✅ Successfully saved loot tracking data")
            
        else
            NextKey222.Debug:Error("❌ Failed to create dungeon card")
            return false
        end
    else
        NextKey222.Debug:Error("❌ Dungeon Cards system not available")
        return false
    end
    
    -- Test 4: Verify loot window can be shown
    NextKey222.Debug:Dev("test", "Test 4: Testing loot window creation")
    if NextKey.LootWindow then
        local testDungeonID = 526
        NextKey.LootWindow:Show(testDungeonID)
        NextKey222.Debug:Dev("test", "✅ Loot window shown successfully for dungeonID:", testDungeonID)
        
        -- Wait a moment then hide for clean testing
        C_Timer.After(2.0, function()
            NextKey.LootWindow:Hide()
            NextKey222.Debug:Dev("test", "✅ Loot window hidden successfully")
        end)
    else
        NextKey222.Debug:Error("❌ Loot Window not available")
        return false
    end
    
    NextKey222.Debug:Dev("test", "=== Loot Window Fix Tests Completed ===")
    return true
end

-- Test function to validate persistence
local function TestPersistence()
    NextKey222.Debug:Dev("test", "=== Testing Persistence ===")
    
    local testDungeonID = 526
    local customItemID = 999999 -- Unique test item ID
    
    -- Add a custom item
    NextKey.DungeonCards:TrackItem(testDungeonID, customItemID, true, "Test")
    NextKey222.Debug:Dev("test", "Added test custom item:", customItemID)
    
    -- Save the data
    NextKey.DungeonCards:SaveLootTracking()
    NextKey222.Debug:Dev("test", "Saved loot tracking data")
    
    -- Check if it's in the database
    if NextKey.db and NextKey.db.char and NextKey.db.char.lootTracking then
        local savedData = NextKey.db.char.lootTracking[testDungeonID]
        if savedData and savedData.customItems and savedData.customItems[customItemID] then
            NextKey222.Debug:Dev("test", "✅ Custom item found in saved database")
        else
            NextKey222.Debug:Error("❌ Custom item not found in saved database")
            return false
        end
    else
        NextKey222.Debug:Error("❌ Database structure not available")
        return false
    end
    
    -- Clear the item from memory
    NextKey.DungeonCards:UntrackItem(testDungeonID, customItemID, true)
    NextKey222.Debug:Dev("test", "Cleared test item from memory")
    
    -- Reload from database
    NextKey.DungeonCards:LoadLootTracking()
    NextKey222.Debug:Dev("test", "Reloaded loot tracking data from database")
    
    -- Check if it's back
    local card = NextKey.DungeonCards:GetCard(testDungeonID)
    if card and card.customTrackedItems[customItemID] then
        NextKey222.Debug:Dev("test", "✅ Persistence test passed - item restored from database")
        
        -- Clean up test data
        NextKey.DungeonCards:UntrackItem(testDungeonID, customItemID, true)
        NextKey.DungeonCards:SaveLootTracking()
        NextKey222.Debug:Dev("test", "✅ Cleaned up test data")
        
        return true
    else
        NextKey222.Debug:Error("❌ Persistence test failed - item not restored")
        return false
    end
end

-- Quick validation function for immediate testing
local function QuickValidation()
    NextKey222.Debug:Dev("test", "=== Quick Validation ===")
    
    -- Check if all required systems are available
    local systems = {
        "UIComponents",
        "LootData", 
        "DungeonCards",
        "LootWindow"
    }
    
    for _, systemName in ipairs(systems) do
        local system = NextKey[systemName]
        if system then
            NextKey222.Debug:Dev("test", "✅", systemName, "system available")
        else
            NextKey222.Debug:Error("❌", systemName, "system missing")
            return false
        end
    end
    
    -- Test a simple loot window open
    if NextKey.LootWindow then
        local testDungeonID = 526 -- Eco-Dome Al'dani
        NextKey.LootWindow:Show(testDungeonID)
        NextKey222.Debug:Dev("test", "✅ Quick validation - loot window opened")
        
        -- Auto-close after 1 second
        C_Timer.After(1.0, function()
            NextKey.LootWindow:Hide()
            NextKey222.Debug:Dev("test", "✅ Quick validation - loot window closed")
        end)
        
        return true
    end
    
    return false
end

-- Export test functions
NextKey.TestLootWindowFixes = TestLootWindowFixes
NextKey.TestLootWindowPersistence = TestPersistence
NextKey.QuickLootValidation = QuickValidation

-- Auto-run quick validation when loaded
C_Timer.After(1.0, function()
    QuickValidation()
end)

NextKey222.Debug:Dev("test", "Loot Window Fix Tests loaded")