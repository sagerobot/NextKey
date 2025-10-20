-- Debug test for button widget issues
-- Tests to identify the source of the AceGUI SetParent error

local _, NextKey222 = ...

local function TestButtonCreation()
    NextKey222.Debug:Dev("test", "=== Button Widget Debug Test ===")
    
    -- Test 1: Create a simple button using NextKey components
    NextKey222.Debug:Dev("test", "Test 1: Creating button with NextKey222.UIComponents")
    local testBtn1 = NextKey222.UIComponents:CreateButton("small", nil, {
        text = "Test",
        onClick = function()
            NextKey222.Debug:Dev("test", "Test button 1 clicked successfully")
        end
    })
    
    if testBtn1 and testBtn1.frame then
        NextKey222.Debug:Dev("test", "✅ Test button 1 created successfully")
        NextKey222.Debug:Dev("test", "Button 1 frame:", testBtn1.frame:GetName() or "unnamed")
        NextKey222.Debug:Dev("test", "Button 1 parent:", testBtn1.frame:GetParent() and testBtn1.frame:GetParent():GetName() or "nil")
    else
        NextKey222.Debug:Error("❌ Test button 1 creation failed")
        return false
    end
    
    -- Test 2: Create a container and add button to it
    NextKey222.Debug:Dev("test", "Test 2: Creating container with button")
    local container = NextKey222.UIComponents:CreateFrame("container", nil, {
        width = 200,
        height = 50,
        colorScheme = "light"
    })
    container:SetLayout("Flow")
    
    local testBtn2 = NextKey222.UIComponents:CreateButton("small", nil, {
        text = "Test2",
        onClick = function()
            NextKey222.Debug:Dev("test", "Test button 2 clicked successfully")
        end
    })
    
    if container and testBtn2 then
        NextKey222.Debug:Dev("test", "Adding button to container")
        container:AddChild(testBtn2)
        NextKey222.Debug:Dev("test", "✅ Test button 2 added to container successfully")
    else
        NextKey222.Debug:Error("❌ Test button 2 container test failed")
        return false
    end
    
    -- Test 3: Simulate the exact loot window scenario
    NextKey222.Debug:Dev("test", "Test 3: Simulating loot window scenario")
    
    -- Create item container like in loot window
    local itemContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        width = 300,
        height = 30,
        colorScheme = "light"
    })
    itemContainer:SetLayout("Flow")
    itemContainer:SetFullWidth(true)
    itemContainer:SetHeight(30)
    
    -- Create remove button like in loot window
    local removeBtn = NextKey222.UIComponents:CreateButton("small", nil, {
        text = "×",
        onClick = function()
            NextKey222.Debug:Dev("test", "Remove button clicked in debug test")
            -- Simulate the exact operations from loot window
            if NextKey.DungeonCards then
                NextKey222.Debug:Dev("test", "DungeonCards available in test")
            else
                NextKey222.Debug:Error("DungeonCards not available in test")
            end
        end
    })
    removeBtn:SetWidth(30)
    removeBtn:SetHeight(20)
    
    if removeBtn and removeBtn.frame then
        NextKey222.Debug:Dev("test", "Remove button created, frame:", removeBtn.frame:GetName() or "unnamed")
        NextKey222.Debug:Dev("test", "Remove button parent before AddChild:", removeBtn.frame:GetParent() and removeBtn.frame:GetParent():GetName() or "nil")
        
        itemContainer:AddChild(removeBtn)
        NextKey222.Debug:Dev("test", "Remove button added to container")
        NextKey222.Debug:Dev("test", "Remove button parent after AddChild:", removeBtn.frame:GetParent() and removeBtn.frame:GetParent():GetName() or "nil")
    else
        NextKey222.Debug:Error("Remove button creation failed in test")
        return false
    end
    
    NextKey222.Debug:Dev("test", "✅ All button tests completed successfully")
    return true
end

-- Test the actual loot window button creation
local function TestLootWindowButton()
    NextKey222.Debug:Dev("test", "=== Loot Window Button Test ===")
    
    if not NextKey.LootWindow then
        NextKey222.Debug:Error("LootWindow not available for testing")
        return false
    end
    
    -- Set up a test dungeon
    local testDungeonID = 526
    NextKey.LootWindow.dungeonID = testDungeonID
    
    -- Add a custom item to test remove button
    if NextKey.DungeonCards then
        -- Get dungeon name first
        local dungeonName = "Test Dungeon"
        if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[testDungeonID] then
            dungeonName = NextKey.PortalData.dungeons[testDungeonID].name or dungeonName
        end
        NextKey.DungeonCards:TrackItem(testDungeonID, 999999, true, dungeonName) -- Test custom item
        NextKey222.Debug:Dev("test", "Added test custom item for remove button test")
    end
    
    -- Create a mock item row like the loot window does
    NextKey222.Debug:Dev("test", "Creating mock item row with remove button")
    
    -- Simulate the exact CreateItemRow logic for custom items
    local itemContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        width = 300,
        height = 30,
        colorScheme = "light"
    })
    itemContainer:SetLayout("Flow")
    itemContainer:SetFullWidth(true)
    itemContainer:SetHeight(30)
    
    local itemName = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Test Item",
        relativeWidth = 0.7,
        justifyH = "LEFT",
        color = {1, 1, 1}
    })
    
    local removeBtn = NextKey222.UIComponents:CreateButton("small", nil, {
        text = "×",
        onClick = function()
            NextKey222.Debug:Dev("test", "LOOT WINDOW TEST: Remove button clicked!")
            NextKey222.Debug:Dev("test", "LOOT WINDOW TEST: dungeonID:", NextKey.LootWindow.dungeonID)
            
            -- Validate the exact same conditions as loot window
            if not NextKey.LootWindow.dungeonID then
                NextKey222.Debug:Error("LOOT WINDOW TEST: dungeonID is nil!")
                return
            end
            
            if not NextKey.DungeonCards then
                NextKey222.Debug:Error("LOOT WINDOW TEST: DungeonCards not available!")
                return
            end
            
            NextKey222.Debug:Dev("test", "LOOT WINDOW TEST: All validations passed!")
        end
    })
    removeBtn:SetWidth(30)
    removeBtn:SetHeight(20)
    
    itemContainer:AddChild(itemName)
    itemContainer:AddChild(removeBtn)
    
    NextKey222.Debug:Dev("test", "✅ Loot window button test setup completed")
    NextKey222.Debug:Dev("test", "Try clicking the × button to test the click handler")
    
    return true
end

-- Export test functions
NextKey.TestButtonCreation = TestButtonCreation
NextKey.TestLootWindowButton = TestLootWindowButton

-- Auto-run tests
C_Timer.After(2.0, function()
    TestButtonCreation()
    TestLootWindowButton()
end)

NextKey222.Debug:Dev("test", "Button Debug Tests loaded")