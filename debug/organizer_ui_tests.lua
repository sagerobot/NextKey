-- MARK: Module Definition
local _, NextKey222 = ...

local Debug = NextKey222.Debug

-- MARK: Test Suite
local OrganizerUITests = {}

function OrganizerUITests:TestRosterBoardCreation()
    Debug:User("Testing Roster Board creation...")
    
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not found!")
        return false
    end
    
    local success, result = pcall(function()
        return NextKey222.RosterBoard:CreateMainFrame()
    end)
    
    if success and result then
        Debug:User("[OK] Roster Board main frame created successfully")
        return true
    else
        Debug:Error("[FAIL] Roster Board creation failed:", result)
        return false
    end
end

function OrganizerUITests:TestPlayerCardRendering()
    Debug:User("Testing Player Card rendering...")
    
    if not NextKey222.PlayerCard then
        Debug:Error("PlayerCard module not found!")
        return false
    end
    
    -- Test data
    local testPlayerData = {
        id = "TestPlayer-Realm",
        name = "TestPlayer",
        class = "WARRIOR",
        roles = {"Tank", "DPS"},
        keystone = {
            dungeonID = 503,
            level = 15
        },
        overallScore = 2500,
        utilities = {"Lust"}
    }
    
    local success, result = pcall(function()
        return NextKey222.PlayerCard:Create(testPlayerData, "bench")
    end)
    
    if success and result then
        Debug:User("[OK] Player Card created successfully")
        return true
    else
        Debug:Error("[FAIL] Player Card creation failed:", result)
        return false
    end
end

function OrganizerUITests:TestViewModeDetection()
    Debug:User("Testing view mode detection...")
    
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not found!")
        return false
    end
    
    local viewMode = NextKey222.RosterBoard:DetermineViewMode()
    Debug:User("Current view mode:", viewMode)
    
    if viewMode == "ORGANIZER" or viewMode == "PARTICIPANT" then
        Debug:User("[OK] View mode detected correctly")
        return true
    else
        Debug:Error("[FAIL] Invalid view mode:", viewMode)
        return false
    end
end

function OrganizerUITests:TestComponentPooling()
    Debug:User("Testing component pooling...")
    
    if not NextKey222.PlayerCard then
        Debug:Error("PlayerCard module not found!")
        return false
    end
    
    -- Test data
    local testPlayerData = {
        id = "TestPlayer-Realm",
        name = "TestPlayer",
        class = "MAGE",
        roles = {"DPS"},
        overallScore = 2000
    }
    
    -- Create and release cards
    local cards = {}
    for i = 1, 5 do
        local card = NextKey222.PlayerCard:AcquireCard(testPlayerData, "bench")
        if not card then
            Debug:Error("[FAIL] Failed to acquire card", i)
            return false
        end
        table.insert(cards, card)
    end
    
    -- Release cards back to pool
    for _, card in ipairs(cards) do
        NextKey222.PlayerCard:ReleaseCard(card)
    end
    
    -- Verify pool has cards
    local poolSize = #NextKey222.PlayerCard.cardPool
    if poolSize == 5 then
        Debug:User("[OK] Component pooling working correctly (pool size:", poolSize, ")")
        return true
    else
        Debug:Error("[FAIL] Component pooling failed (pool size:", poolSize, "expected 5)")
        return false
    end
end

function OrganizerUITests:TestLayoutCalculation()
    Debug:User("Testing layout calculation...")
    
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not found!")
        return false
    end
    
    local layout = NextKey222.RosterBoard:CalculateOptimalLayout()
    
    if layout and layout.groupColumns and layout.columnWidth and layout.benchWidth then
        Debug:User("[OK] Layout calculated:", layout.groupColumns, "columns")
        return true
    else
        Debug:Error("[FAIL] Layout calculation failed")
        return false
    end
end

-- MARK: Run All Tests
function OrganizerUITests:RunAll()
    Debug:User("=== Starting Organizer UI Tests ===")
    
    local results = {
        rosterBoard = self:TestRosterBoardCreation(),
        playerCard = self:TestPlayerCardRendering(),
        viewMode = self:TestViewModeDetection(),
        pooling = self:TestComponentPooling(),
        layout = self:TestLayoutCalculation()
    }
    
    local passed = 0
    local failed = 0
    for name, result in pairs(results) do
        if result then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end
    
    Debug:User("=== Test Results ===")
    Debug:User("Passed:", passed)
    Debug:User("Failed:", failed)
    Debug:User("Total:", passed + failed)
    
    return passed, failed
end

-- MARK: Global Test Function
function TestOrganizerUI()
    return OrganizerUITests:RunAll()
end

-- Add global reference for easier access
NextKey222.TestOrganizerUI = TestOrganizerUI

Debug:Dev("organizer_ui", "Organizer UI test suite loaded")

-- Add slash command for easy testing
SLASH_NEXTKEYORGANIZERTEST1 = "/nkorgtest"
SlashCmdList["NEXTKEYORGANIZERTEST"] = function(msg)
    Debug:User("Running Organizer UI tests...")
    local passed, failed = TestOrganizerUI()
    Debug:User(string.format("Test Results: %d passed, %d failed", passed, failed))
    if failed == 0 then
        Debug:User("[SUCCESS] All Organizer UI tests passed!")
    else
        Debug:User("[WARNING] Some tests failed - check debug output")
    end
end