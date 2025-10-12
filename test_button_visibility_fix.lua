-- Test script to verify the button visibility fix
-- This script helps test that Suggest Groups and Auto Mode buttons are properly hidden
-- when there are fewer than 6 players in the list

-- Run this test after opening the UI to check button visibility states
local function testButtonVisibility()
    if not NextKey222.UI or not NextKey222.UI.mainFrame then
        print("NextKey UI not open - please open the UI first")
        return
    end
    
    local UI = NextKey222.UI
    local cachedCount = UI.cachedItemsCount or 0
    local viewMode = UI.viewMode or "keystones"
    local isDebug = UI:IsDebugMode()
    
    print("=== Button Visibility Test ===")
    print("View Mode:", viewMode)
    print("Cached Items Count:", cachedCount)
    print("Debug Mode:", isDebug and "ON" or "OFF")
    print("")
    
    -- Check button states
    local suggestBtnVisible = UI.suggestGroupsBtn and UI.suggestGroupsBtn.frame and UI.suggestGroupsBtn.frame:IsShown()
    local autoModeBtnVisible = UI.suggestionModeBtn and UI.suggestionModeBtn.frame and UI.suggestionModeBtn.frame:IsShown()
    local guildBtnVisible = UI.guildToggleBtn and UI.guildToggleBtn.frame and UI.guildToggleBtn.frame:IsShown()
    
    print("Button States:")
    print("  Suggest Groups:", suggestBtnVisible and "VISIBLE" or "HIDDEN")
    print("  Auto Mode:", autoModeBtnVisible and "VISIBLE" or "HIDDEN") 
    print("  Guild/Party Toggle:", guildBtnVisible and "VISIBLE" or "HIDDEN")
    print("")
    
    -- Expected states based on current conditions
    local expectSuggestVisible = (viewMode ~= "dungeons") and (cachedCount >= 6)
    local expectAutoModeVisible = (viewMode ~= "dungeons") and (cachedCount >= 6)
    local expectGuildVisible = (viewMode ~= "dungeons")
    
    print("Expected States:")
    print("  Suggest Groups:", expectSuggestVisible and "SHOULD BE VISIBLE" or "SHOULD BE HIDDEN")
    print("  Auto Mode:", expectAutoModeVisible and "SHOULD BE VISIBLE" or "SHOULD BE HIDDEN")
    print("  Guild/Party Toggle:", expectGuildVisible and "SHOULD BE VISIBLE" or "SHOULD BE HIDDEN")
    print("")
    
    -- Check for mismatches
    local issues = {}
    if suggestBtnVisible ~= expectSuggestVisible then
        table.insert(issues, "Suggest Groups button visibility mismatch")
    end
    if autoModeBtnVisible ~= expectAutoModeVisible then
        table.insert(issues, "Auto Mode button visibility mismatch")
    end
    if guildBtnVisible ~= expectGuildVisible then
        table.insert(issues, "Guild/Party button visibility mismatch")
    end
    
    if #issues > 0 then
        print("ISSUES FOUND:")
        for _, issue in ipairs(issues) do
            print("  -", issue)
        end
    else
        print("✓ All button visibility states are correct!")
    end
    
    print("=== End Test ===")
end

-- Create slash command for easy testing
SLASH_NEXTKEYTESTBUTTONS1 = "/nextkeytestbuttons"
SlashCmdList["NEXTKEYTESTBUTTONS"] = function(msg)
    testButtonVisibility()
end

print("Button visibility test loaded. Use /nextkeytestbuttons to run test.")