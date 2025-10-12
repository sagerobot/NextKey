-- Test script to debug button visibility issues
-- Run this in-game with /testbuttonvisibility

function test_button_visibility_debug()
    local UI = NextKey222.UI
    
    if not UI then
        print("NextKey222.UI not available")
        return
    end
    
    print("=== Button Visibility Debug ===")
    print("View Mode:", UI.viewMode or "nil")
    print("Cached Items Count:", UI.cachedItemsCount or "nil")
    print("ShouldShowKeystoneControls:", UI:ShouldShowKeystoneControls() and "true" or "false")
    
    if UI.suggestGroupsBtn then
        print("Suggest Groups Button Exists:", UI.suggestGroupsBtn.frame and "true" or "false")
        if UI.suggestGroupsBtn.frame then
            print("Suggest Groups Button Visible:", UI.suggestGroupsBtn.frame:IsShown() and "true" or "false")
        end
    else
        print("Suggest Groups Button: nil")
    end
    
    if UI.suggestionModeBtn then
        print("Suggestion Mode Button Exists:", UI.suggestionModeBtn.frame and "true" or "false")
        if UI.suggestionModeBtn.frame then
            print("Suggestion Mode Button Visible:", UI.suggestionModeBtn.frame:IsShown() and "true" or "false")
        end
    else
        print("Suggestion Mode Button: nil")
    end
    
    if UI.guildToggleBtn then
        print("Guild Toggle Button Exists:", UI.guildToggleBtn.frame and "true" or "false")
        if UI.guildToggleBtn.frame then
            print("Guild Toggle Button Visible:", UI.guildToggleBtn.frame:IsShown() and "true" or "false")
        end
    else
        print("Guild Toggle Button: nil")
    end
    
    print("=== Force Update Test ===")
    UI:UpdateKeystoneControlsVisibility()
    
    print("=== After Update ===")
    if UI.suggestGroupsBtn and UI.suggestGroupsBtn.frame then
        print("Suggest Groups Button Visible:", UI.suggestGroupsBtn.frame:IsShown() and "true" or "false")
    end
    if UI.suggestionModeBtn and UI.suggestionModeBtn.frame then
        print("Suggestion Mode Button Visible:", UI.suggestionModeBtn.frame:IsShown() and "true" or "false")
    end
    if UI.guildToggleBtn and UI.guildToggleBtn.frame then
        print("Guild Toggle Button Visible:", UI.guildToggleBtn.frame:IsShown() and "true" or "false")
    end
    
    print("=== Debug Complete ===")
end

-- Create slash command
SLASH_TESTBUTTONVISIBILITY1 = "/testbuttonvisibility"
SlashCmdList["TESTBUTTONVISIBILITY"] = test_button_visibility_debug

print("Button visibility test script loaded. Use /testbuttonvisibility to run debug.")