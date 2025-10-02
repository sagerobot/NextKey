-- Test script to validate NextKey integration 
-- This file is for testing purposes and should be removed before release

local _, NextKey222 = ...

-- Test function to validate our new features
local function TestIntegration()
    local NextKey = NextKey222.Addon
    if not NextKey then
        print("NextKey addon not found!")
        return false
    end
    
    print("=== NextKey Integration Test ===")
    
    -- Test 1: Check LibOpenRaid integration
    if NextKey.LibOpenRaid then
        print("✓ LibOpenRaid integration loaded")
        if NextKey.LibOpenRaid:IsAvailable() then
            print("✓ LibOpenRaid library available")
        else
            print("⚠ LibOpenRaid library not available (may need to reload)")
        end
    else
        print("✗ LibOpenRaid integration not loaded")
        return false
    end
    
    -- Test 2: Check keystone detection enhancements
    if NextKey.CollectPartyKeys then
        print("✓ Enhanced keystone collection available")
        local keys = NextKey:CollectPartyKeys()
        print("  Detected", keys and #keys or 0, "keystones")
    else
        print("✗ Keystone collection function missing")
        return false
    end
    
    -- Test 3: Check Blizzard API integration
    if NextKey.ScanPlayerKeystone then
        print("✓ Player keystone scanning available")
        local playerKey = NextKey:ScanPlayerKeystone()
        if playerKey then
            print("  Player keystone: Dungeon", playerKey.dungeonID or 0, "Level", playerKey.level or 0)
        else
            print("  No player keystone detected")
        end
    else
        print("✗ Player keystone scanning missing")
        return false
    end
    
    -- Test 4: Check LibOpenRaid keystone functions
    if NextKey.LibOpenRaid and NextKey.LibOpenRaid:IsAvailable() then
        print("✓ LibOpenRaid keystone functions available")
        local allKeystones = NextKey.LibOpenRaid:GetAllKeystones()
        print("  Found", NextKey.LibOpenRaid:CountTable(allKeystones), "keystones via LibOpenRaid")
        
        local playerKeystone = NextKey.LibOpenRaid:GetPlayerKeystone()
        if playerKeystone then
            print("  Player keystone:", playerKeystone.dungeonID, "level", playerKeystone.level)
        else
            print("  No player keystone detected")
        end
    else
        print("⚠ LibOpenRaid not available for keystone testing")
    end
    
    print("=== All tests passed! NextKey is ready. ===")
    return true
end

-- Register test command
SLASH_NKTEST1 = "/nktest"
SlashCmdList.NKTEST = function()
    TestIntegration()
end

return TestIntegration