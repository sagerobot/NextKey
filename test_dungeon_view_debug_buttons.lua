-- Test script to verify fake player and keystone-specific buttons are hidden in dungeon view
-- This script can be run in-game to test the implementation

local function TestDungeonViewButtonVisibility()
    print("=== Testing Dungeon View Button Visibility ===")
    
    -- Check if UI module is available
    if not NextKey222.UI then
        print("ERROR: UI module not available")
        return false
    end
    
    local UI = NextKey222.UI
    
    -- Test 1: Check ShouldShowDebugControls in keystone view
    print("\n--- Test 1: Debug Controls in Keystone View ---")
    UI.viewMode = "keystones"
    local keystoneDebugResult = UI:ShouldShowDebugControls()
    print("View mode: keystones")
    print("ShouldShowDebugControls:", keystoneDebugResult)
    print("Expected: true if debug mode is on, false otherwise")
    
    -- Test 2: Check ShouldShowDebugControls in dungeon view
    print("\n--- Test 2: Debug Controls in Dungeon View ---")
    UI.viewMode = "dungeons"
    local dungeonDebugResult = UI:ShouldShowDebugControls()
    print("View mode: dungeons")
    print("ShouldShowDebugControls:", dungeonDebugResult)
    print("Expected: false (should hide fake player buttons)")
    
    -- Test 3: Check ShouldShowKeystoneControls in keystone view
    print("\n--- Test 3: Keystone Controls in Keystone View ---")
    UI.viewMode = "keystones"
    local keystoneControlsResult = UI:ShouldShowKeystoneControls()
    print("View mode: keystones")
    print("ShouldShowKeystoneControls:", keystoneControlsResult)
    print("Expected: true (should show Suggest Groups, Auto Mode, and Guild/Party buttons)")
    
    -- Test 4: Check ShouldShowKeystoneControls in dungeon view
    print("\n--- Test 4: Keystone Controls in Dungeon View ---")
    UI.viewMode = "dungeons"
    local dungeonControlsResult = UI:ShouldShowKeystoneControls()
    print("View mode: dungeons")
    print("ShouldShowKeystoneControls:", dungeonControlsResult)
    print("Expected: false (should hide Suggest Groups, Auto Mode, and Guild/Party buttons)")
    
    -- Test 5: Verify the differences
    print("\n--- Test 5: Verification ---")
    local debugControlsWork = keystoneDebugResult ~= dungeonDebugResult
    local keystoneControlsWork = keystoneControlsResult ~= dungeonControlsResult
    
    if debugControlsWork then
        print("SUCCESS: Debug control visibility changes between view modes")
        if not dungeonDebugResult then
            print("SUCCESS: Fake player buttons are hidden in dungeon view")
        end
    else
        print("WARNING: No difference in debug control visibility between view modes")
    end
    
    if keystoneControlsWork then
        print("SUCCESS: Keystone control visibility changes between view modes")
        if not dungeonControlsResult then
            print("SUCCESS: Keystone-specific buttons are hidden in dungeon view")
        end
    else
        print("WARNING: No difference in keystone control visibility between view modes")
    end
    
    -- Test 6: Check if main frame exists and test visibility updates
    if UI.mainFrame then
        print("\n--- Test 6: Live UI Test ---")
        print("Main frame exists, testing visibility updates...")
        
        -- Switch to keystone view
        UI.viewMode = "keystones"
        UI:UpdateDebugControlsVisibility()
        UI:UpdateKeystoneControlsVisibility()
        print("Switched to keystone view")
        print("  - Debug controls should be visible if debug mode is on")
        print("  - Keystone controls should be visible")
        
        -- Switch to dungeon view
        UI.viewMode = "dungeons"
        UI:UpdateDebugControlsVisibility()
        UI:UpdateKeystoneControlsVisibility()
        print("Switched to dungeon view")
        print("  - Debug controls should be hidden")
        print("  - Keystone controls should be hidden")
        
        print("\nCheck the UI to verify all buttons are properly shown/hidden in each view mode")
    else
        print("\n--- Test 6: Live UI Test ---")
        print("Main frame not found. Open the NextKey UI to test live visibility.")
    end
    
    print("\n=== Test Complete ===")
    return true
end

-- Run the test
TestDungeonViewButtonVisibility()