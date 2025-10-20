-- MARK: Loot System Test Suite
-- Simple test script to verify loot targeting system functionality

local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then return end

-- Test function to verify loot system components
local function TestLootSystem()
    NextKey222.Debug:User("=== Testing Loot Targeting System ===")
    
    -- Test 1: Verify loot data is loaded
    if NextKey.LootData then
        NextKey222.Debug:User("✅ Loot data loaded successfully")
        NextKey222.Debug:Dev("test", "Active season:", NextKey.LootData.name)
        
        -- Check if dungeon data exists
        local dungeonCount = 0
        for dungeonID, data in pairs(NextKey.LootData.dungeons or {}) do
            dungeonCount = dungeonCount + 1
            NextKey222.Debug:Dev("test", "Dungeon", dungeonID, "has", #data.defaultItems, "default items")
        end
        NextKey222.Debug:User("✅ Found", dungeonCount, "dungeons with loot data")
    else
        NextKey222.Debug:Error("❌ Loot data not loaded")
    end
    
    -- Test 2: Verify GetDefaultLootItems function
    if NextKey.GetDefaultLootItems then
        local testDungeonID = 503 -- Ara-Kara
        local defaultItems = NextKey:GetDefaultLootItems(testDungeonID)
        if defaultItems and #defaultItems > 0 then
            NextKey222.Debug:User("✅ GetDefaultLootItems works - found", #defaultItems, "items for dungeon", testDungeonID)
            for i, itemID in ipairs(defaultItems) do
                NextKey222.Debug:Dev("test", "  Item", i, "ID:", itemID)
            end
        else
            NextKey222.Debug:Error("❌ GetDefaultLootItems returned no items for dungeon", testDungeonID)
        end
    else
        NextKey222.Debug:Error("❌ GetDefaultLootItems function not available")
    end
    
    -- Test 3: Verify DungeonCards loot tracking methods
    if NextKey.DungeonCards then
        NextKey222.Debug:User("✅ DungeonCards module available")
        
        -- Test tracking methods
        if NextKey.DungeonCards.TrackItem and NextKey.DungeonCards.UntrackItem then
            NextKey222.Debug:User("✅ TrackItem/UntrackItem methods available")
            
            -- Test tracking a sample item
            local testDungeonID = 503
            local testItemID = 221023
            NextKey.DungeonCards:TrackItem(testDungeonID, testItemID, false, "Test")
            NextKey222.Debug:User("✅ Successfully tracked test item")
            
            -- Test untracking
            NextKey.DungeonCards:UntrackItem(testDungeonID, testItemID, false)
            NextKey222.Debug:User("✅ Successfully untracked test item")
        else
            NextKey222.Debug:Error("❌ TrackItem/UntrackItem methods not available")
        end
        
        -- Test persistence methods
        if NextKey.DungeonCards.SaveLootTracking and NextKey.DungeonCards.LoadLootTracking then
            NextKey222.Debug:User("✅ SaveLootTracking/LoadLootTracking methods available")
        else
            NextKey222.Debug:Error("❌ SaveLootTracking/LoadLootTracking methods not available")
        end
    else
        NextKey222.Debug:Error("❌ DungeonCards module not available")
    end
    
    -- Test 4: Verify LootWindow module
    if NextKey.LootWindow then
        NextKey222.Debug:User("✅ LootWindow module available")
        
        if NextKey.LootWindow.Show then
            NextKey222.Debug:User("✅ LootWindow.Show method available")
        else
            NextKey222.Debug:Error("❌ LootWindow.Show method not available")
        end
    else
        NextKey222.Debug:Error("❌ LootWindow module not available")
    end
    
    -- Test 5: Verify HandleLootClick function
    if NextKey.HandleLootClick then
        NextKey222.Debug:User("✅ HandleLootClick function available")
    else
        NextKey222.Debug:Error("❌ HandleLootClick function not available")
    end
    
    -- Test 6: Verify database structure
    if NextKey.db and NextKey.db.char then
        if NextKey.db.char.lootTracking then
            NextKey222.Debug:User("✅ lootTracking database structure available")
        else
            NextKey222.Debug:User("⚠️ lootTracking database structure not yet initialized (normal for first run)")
        end
    else
        NextKey222.Debug:Error("❌ Database not available")
    end
    
    NextKey222.Debug:User("=== Loot System Test Complete ===")
end

-- Register test command
SLASH_NEXTKEYTESTLOOT1 = "/nktestloot"
SlashCmdList["NEXTKEYTESTLOOT"] = function(msg)
    TestLootSystem()
end

-- Auto-run test if debug mode is enabled
if NextKey222.Debug and NextKey222.Debug.enabled then
    -- Delay test to ensure all modules are loaded
    C_Timer.After(2.0, TestLootSystem)
end

-- Export test function for other modules
NextKey.TestLootSystem = TestLootSystem