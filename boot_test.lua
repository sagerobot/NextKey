-- NextKey Boot Architecture Test
-- Quick test to validate consolidated boot system

local function TestBootArchitecture()
    print("=== NextKey Boot Architecture Test ===")
    
    -- Test 1: Check global namespace
    if _G.NextKey222 then
        print("✓ NextKey222 namespace available")
    else
        print("✗ NextKey222 namespace missing")
        return false
    end
    
    -- Test 2: Check addon instance
    if NextKey222.Addon then
        print("✓ Addon instance available")
    else
        print("✗ Addon instance missing")
        return false
    end
    
    -- Test 3: Check module registry
    if NextKey222.RegisterModule then
        print("✓ Module registration system available")
    else
        print("✗ Module registration system missing")
        return false
    end
    
    -- Test 4: Check startup system
    if NextKey222.StartUp and NextKey222.StartUp.RegisterPhaseHandler then
        print("✓ Startup system available")
    else
        print("✗ Startup system missing")
        return false
    end
    
    -- Test 5: Check utils
    if NextKey222.Utils and NextKey222.Utils.GetSafePlayerName then
        print("✓ Utility functions available")
    else
        print("✗ Utility functions missing")
        return false
    end
    
    -- Test 6: Check debug system
    if NextKey222.Debug and NextKey222.Debug.Print then
        print("✓ Debug system available")
    else
        print("✗ Debug system missing")
        return false
    end
    
    -- Test 7: Check performance monitoring
    if NextKey222.Performance and NextKey222.Performance.StartProfile then
        print("✓ Performance monitoring available")
    else
        print("✗ Performance monitoring missing")
        return false
    end
    
    print("✓ All boot architecture tests passed!")
    print("=== Test Complete ===")
    return true
end

-- Register a test command
SLASH_NKTEST1 = "/nktest"
SlashCmdList["NKTEST"] = function()
    TestBootArchitecture()
end

print("NextKey: Boot architecture test registered - use /nktest to validate")