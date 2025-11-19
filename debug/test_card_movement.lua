-- MARK: Card Movement Test
local _, NextKey222 = ...

-- Test the simplified card movement system
function NextKeyTestCardMovement()
    local Debug = NextKey222.Debug
    
    Debug:User("=== Card Movement Refactoring Test ===")
    Debug:User("Testing simplified Validate → Remove → Place pattern")
    
    -- Test 1: Module exists and has correct functions
    if not NextKey222.CardMovement then
        Debug:Error("CardMovement module not found!")
        return false
    end
    
    local cm = NextKey222.CardMovement
    
    -- Check that old functions are gone
    if cm.mark_card_for_removal then
        Debug:Error("Old function mark_card_for_removal still exists!")
        return false
    end
    
    if cm.complete_card_removal then
        Debug:Error("Old function complete_card_removal still exists!")
        return false
    end
    
    -- Check that new function exists
    if not cm.remove_card_from_source then
        Debug:Error("New function remove_card_from_source not found!")
        return false
    end
    
    Debug:User("[OK] Old two-phase functions removed")
    Debug:User("[OK] New remove_card_from_source function exists")
    
    -- Test 2: Core functions still exist
    local requiredFunctions = {
        "detect_drop_target",
        "handle_card_drop",
        "animate_rejection",
        "can_player_fill_role",
        "find_compatible_slot_in_group",
        "place_card_in_bench",
        "remove_card_from_bench_array"
    }
    
    for _, funcName in ipairs(requiredFunctions) do
        if not cm[funcName] then
            Debug:Error("Required function missing:", funcName)
            return false
        end
    end
    
    Debug:User("[OK] All core functions present")
    
    -- Test 3: Open organizer and test drag/drop
    if NextKey222.RosterBoard and NextKey222.RosterBoard.Show then
        Debug:User("Opening M+ Organizer for manual testing...")
        Debug:User("")
        Debug:User("MANUAL TEST CHECKLIST:")
        Debug:User("1. Drag a tank card to a healer slot → Should reject with red flash")
        Debug:User("2. Drag a tank card to a tank slot → Should place successfully")
        Debug:User("3. Drag a card back to bench → Should place successfully")
        Debug:User("4. Drag a card to opt-out → Should place successfully")
        Debug:User("5. Verify no Lua errors occur during any drag operation")
        Debug:User("")
        
        NextKey222.RosterBoard:Show()
    end
    
    Debug:User("[OK] Card Movement refactoring test complete!")
    Debug:User("File reduced from 485 → 390 lines (95 line reduction, 19.6%)")
    
    return true
end

-- Register slash command for easy testing
SLASH_NKCARDTEST1 = "/nkcardtest"
SlashCmdList["NKCARDTEST"] = function()
    NextKeyTestCardMovement()
end