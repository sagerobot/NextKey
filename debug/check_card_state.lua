-- Debug script to check card visual state
-- Usage: /script CheckCardState()

function CheckCardState()
    if not NextKey222.RosterBoard or not NextKey222.RosterBoard.benchCards then
        print("RosterBoard not initialized")
        return
    end
    
    print("=== BENCH CARD STATE CHECK ===")
    print("Total bench cards:", #NextKey222.RosterBoard.benchCards)
    print("")
    
    for i, card in ipairs(NextKey222.RosterBoard.benchCards) do
        if card and card.playerData then
            local name = card.playerData.name or "Unknown"
            local hasSpecPrefs = card.playerData.specPreferences ~= nil
            local hasSpecDetails = card.playerData.specDetails ~= nil
            local roleButtonCount = card.roleButtons and #card.roleButtons or 0
            
            print(string.format("Card %d: %s", i, name))
            print("  - has specPreferences:", hasSpecPrefs)
            print("  - has specDetails:", hasSpecDetails)
            print("  - roleButtons count:", roleButtonCount)
            
            if hasSpecPrefs and card.playerData.specPreferences then
                local prefCount = 0
                for role, pref in pairs(card.playerData.specPreferences) do
                    prefCount = prefCount + 1
                    print(string.format("    - %s: %s", role, pref))
                end
                print("  - total preferences:", prefCount)
            end
            
            if hasSpecDetails and card.playerData.specDetails then
                print("  - specDetails breakdown:")
                for role, specs in pairs(card.playerData.specDetails) do
                    print(string.format("    - %s: %d specs", role, #specs))
                    for _, specInfo in ipairs(specs) do
                        print(string.format("      - %s: %s", specInfo.specName, specInfo.preference))
                    end
                end
            end
            
            if card.roleButtons then
                print("  - roleButtons visible:")
                for j, btn in ipairs(card.roleButtons) do
                    local isVisible = btn:IsShown() and "YES" or "NO"
                    print(string.format("    - Button %d: %s", j, isVisible))
                end
            end
            print("")
        end
    end
    
    print("=== END CHECK ===")
end

print("CheckCardState() function loaded. Use /script CheckCardState() to run.")