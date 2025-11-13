-- Simple test to verify the persistence fix
local _, NextKey222 = ...

function SimplePersistenceTest()
    NextKey222.Debug:User("=== Simple Persistence Test ===")
    
    -- Enable debug to see detailed output
    NextKey222.Debug:SetLevel(3) -- DEV level
    
    local testDungeonID = 377
    local testItemID = 246344
    
    -- Clear any existing data first
    NextKey.db.char.lootTracking = {}
    NextKey.DungeonCards.dungeons = {}
    
    NextKey222.Debug:User("Step 1: Tracking item")
    NextKey.DungeonCards:TrackItem(testDungeonID, testItemID, false, "Halls of Atonement")
    
    NextKey222.Debug:User("Step 2: Saving tracking data")
    NextKey.DungeonCards:SaveLootTracking()
    
    NextKey222.Debug:User("Step 3: Clearing in-memory data")
    NextKey.DungeonCards.dungeons = {}
    
    NextKey222.Debug:User("Step 4: Loading tracking data")
    NextKey.DungeonCards:LoadLootTracking()
    
    NextKey222.Debug:User("Step 5: Verifying item is still tracked")
    local card = NextKey.DungeonCards.dungeons[testDungeonID]
    if card and card.trackedItems[testItemID] then
        NextKey222.Debug:User("✅ SUCCESS: Item tracking persisted!")
        return true
    else
        NextKey222.Debug:Error("❌ FAILED: Item tracking lost")
        return false
    end
end

_G.SimplePersistenceTest = SimplePersistenceTest
if NextKey222.Debug and NextKey222.Debug.DEV_MODE then
    NextKey222.Debug:User("Simple test loaded. Use /script SimplePersistenceTest() to test.")
end