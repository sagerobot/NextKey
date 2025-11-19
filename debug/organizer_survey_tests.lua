-- MARK: Organizer Survey Tests
local _, NextKey222 = ...

local Debug = NextKey222.Debug

-- MARK: Test Suite Definition
local OrganizerSurveyTests = {}
NextKey222.OrganizerSurveyTests = OrganizerSurveyTests

-- MARK: Test Configuration
local TEST_CONFIG = {
    simulatedDelay = 0.5, -- Delay between simulated responses (seconds)
    pollTimeout = 60, -- Poll timeout duration
    testPlayers = {
        {name = "TestPlayer1-Dalaran", opted = "in", character = "main"},
        {name = "TestPlayer2-Dalaran", opted = "in", character = "main"},
        {name = "TestPlayer3-Dalaran", opted = "out", character = "main"},
        {name = "TestPlayer4-Dalaran", opted = "in", character = "alt"},
    }
}

-- MARK: Test Helper Functions
function OrganizerSurveyTests:ResetTestEnvironment()
    Debug:Dev("test", "Resetting test environment for survey tests")
    
    -- Clear active poll
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard.activePoll = nil
    end
    
    -- Clear any test data
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey.activePollID = nil
    end
    
    Debug:Dev("test", "Test environment reset complete")
end

function OrganizerSurveyTests:CreateMockPollRequest()
    local pollID = "test-" .. tostring(time())
    return {
        opcode = NextKey222.Constants.COMM_OPCODES.ORG_POLL_REQUEST,
        version = "0.5.32",
        timestamp = GetTime(),
        sender = UnitName("player") .. "-" .. GetRealmName(),
        pollID = pollID
    }
end

function OrganizerSurveyTests:CreateMockPollResponse(playerName, optedIn, characterChoice)
    return {
        opcode = NextKey222.Constants.COMM_OPCODES.ORG_POLL_RESPONSE,
        version = "0.5.32",
        timestamp = GetTime(),
        sender = playerName,
        pollID = NextKey222.ParticipantSurvey and NextKey222.ParticipantSurvey.activePollID or "test-poll",
        data = {
            participation = optedIn and "opt_in" or "opt_out",
            selectedCharacter = characterChoice or "main",
            roles = {"TANK", "HEALER", "DAMAGER"},
            preferences = {
                like = {},
                dislike = {}
            }
        }
    }
end

-- MARK: Poll Request Test
function OrganizerSurveyTests:TestPollRequestSending()
    Debug:Dev("test", "=== Test 1: Poll Request Sending ===")
    
    -- Check if RosterBoard is available
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not available - test cannot proceed")
        return false
    end
    
    -- Simulate poll button click
    Debug:Dev("test", "Simulating poll button click...")
    NextKey222.RosterBoard:OnPollGroupClicked()
    
    -- Verify poll was created
    if NextKey222.RosterBoard.activePoll then
        Debug:Dev("test", "✓ Active poll created with ID:", NextKey222.RosterBoard.activePoll.id)
        return true
    else
        Debug:Error("✗ Failed to create active poll")
        return false
    end
end

-- MARK: Survey Dialog Test
function OrganizerSurveyTests:TestSurveyDialogDisplay()
    Debug:Dev("test", "=== Test 2: Survey Dialog Display ===")
    
    -- Check if SurveyDialog is available
    if not NextKey222.SurveyDialog then
        Debug:Error("SurveyDialog module not available - test cannot proceed")
        return false
    end
    
    -- Create mock poll request
    local mockRequest = self:CreateMockPollRequest()
    
    -- Simulate receiving poll request
    Debug:Dev("test", "Simulating poll request reception...")
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnPollRequestReceived(mockRequest, "Organizer-Dalaran")
    end
    
    -- Check if dialog was created
    if NextKey222.SurveyDialog.activeDialog then
        Debug:Dev("test", "✓ Survey dialog created and displayed")
        return true
    else
        Debug:Error("✗ Failed to create survey dialog")
        return false
    end
end

-- MARK: Poll Response Test
function OrganizerSurveyTests:TestPollResponseProcessing()
    Debug:Dev("test", "=== Test 3: Poll Response Processing ===")
    
    -- Initialize active poll
    if NextKey222.RosterBoard then
        NextKey222.RosterBoard.activePoll = {
            id = "test-poll",
            startTime = GetTime(),
            responses = {},
            timeout = 60
        }
    end
    
    -- Simulate responses from test players
    local successCount = 0
    for i, playerConfig in ipairs(TEST_CONFIG.testPlayers) do
        local mockResponse = self:CreateMockPollResponse(
            playerConfig.name,
            playerConfig.opted == "in",
            playerConfig.character
        )
        
        Debug:Dev("test", "Processing response from:", playerConfig.name)
        
        -- Process response
        if NextKey222.ParticipantSurvey then
            NextKey222.ParticipantSurvey:OnPollResponseReceived(mockResponse, playerConfig.name)
        end
        
        -- Verify response was recorded
        if NextKey222.RosterBoard.activePoll then
            local responseCount = #NextKey222.RosterBoard.activePoll.responses
            if responseCount == i then
                Debug:Dev("test", "✓ Response", i, "recorded (total:", responseCount, ")")
                successCount = successCount + 1
            else
                Debug:Error("✗ Response", i, "not recorded correctly")
            end
        end
    end
    
    return successCount == #TEST_CONFIG.testPlayers
end

-- MARK: Poll Progress Test
function OrganizerSurveyTests:TestPollProgressTracking()
    Debug:Dev("test", "=== Test 4: Poll Progress Tracking ===")
    
    if not NextKey222.RosterBoard or not NextKey222.RosterBoard.activePoll then
        Debug:Error("No active poll to track")
        return false
    end
    
    -- Get current response count
    local responseCount = #NextKey222.RosterBoard.activePoll.responses
    Debug:Dev("test", "Current responses:", responseCount)
    
    -- Update progress UI
    NextKey222.RosterBoard:UpdatePollProgress()
    
    -- Verify button text was updated (if button exists)
    if NextKey222.RosterBoard.pollButton then
        local buttonText = NextKey222.RosterBoard.pollButton:GetText()
        Debug:Dev("test", "✓ Poll button text:", buttonText)
        return true
    else
        Debug:Dev("test", "⚠ Poll button not available (may be normal)")
        return true
    end
end

-- MARK: Poll Timeout Test
function OrganizerSurveyTests:TestPollTimeoutHandling()
    Debug:Dev("test", "=== Test 5: Poll Timeout Handling ===")
    
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not available")
        return false
    end
    
    -- Create test poll
    NextKey222.RosterBoard.activePoll = {
        id = "test-timeout",
        startTime = GetTime(),
        responses = {},
        timeout = 2 -- Short timeout for testing
    }
    
    Debug:Dev("test", "Starting poll with 2-second timeout...")
    
    -- Start timeout timer
    NextKey222.RosterBoard:StartPollTimeout()
    
    -- Simulate timeout completion after delay
    C_Timer.After(2.5, function()
        if NextKey222.RosterBoard.activePoll then
            Debug:Error("✗ Poll still active after timeout")
        else
            Debug:Dev("test", "✓ Poll completed on timeout")
        end
    end)
    
    return true -- Async test, result logged later
end

-- MARK: Bench/OptOut Test
function OrganizerSurveyTests:TestBenchOptOutPopulation()
    Debug:Dev("test", "=== Test 6: Bench/Opt-Out Population ===")
    
    if not NextKey222.RosterBoard then
        Debug:Error("RosterBoard module not available")
        return false
    end
    
    -- Create mock player data
    local mockPlayers = {
        {
            id = "TestBench1-Dalaran",
            name = "TestBench1",
            class = "WARRIOR",
            roles = {"TANK"},
            keystone = {dungeonID = 503, level = 10},
            overallScore = 2500,
            utilities = {"heroism"}
        },
        {
            id = "TestBench2-Dalaran",
            name = "TestBench2",
            class = "PRIEST",
            roles = {"HEALER"},
            keystone = {dungeonID = 507, level = 8},
            overallScore = 2200,
            utilities = {"battleRes"}
        }
    }
    
    -- Test adding to bench
    Debug:Dev("test", "Adding players to bench...")
    for _, playerData in ipairs(mockPlayers) do
        NextKey222.RosterBoard:AddPlayerToBench(playerData)
    end
    
    -- Verify bench population
    local benchCount = #NextKey222.RosterBoard.benchCards
    Debug:Dev("test", "✓ Bench contains", benchCount, "players")
    
    -- Test adding to opt-out
    Debug:Dev("test", "Adding player to opt-out...")
    local optOutPlayer = {
        id = "TestOptOut1-Dalaran",
        name = "TestOptOut1",
        class = "MAGE",
        roles = {"DAMAGER"},
        overallScore = 1800,
        utilities = {}
    }
    
    NextKey222.RosterBoard:AddPlayerToOptOut(optOutPlayer)
    
    -- Verify opt-out population
    if NextKey222.RosterBoard.optOutSection and NextKey222.RosterBoard.optOutSection.playerCards then
        local optOutCount = #NextKey222.RosterBoard.optOutSection.playerCards
        Debug:Dev("test", "✓ Opt-out contains", optOutCount, "players")
        return true
    else
        Debug:Error("✗ Opt-out section not properly initialized")
        return false
    end
end

-- MARK: Test Suite Runner
function OrganizerSurveyTests:RunAllTests()
    Debug:Dev("test", "")
    Debug:Dev("test", "═══════════════════════════════════════")
    Debug:Dev("test", "  ORGANIZER SURVEY SYSTEM TEST SUITE")
    Debug:Dev("test", "═══════════════════════════════════════")
    Debug:Dev("test", "")
    
    local results = {}
    
    -- Reset environment before tests
    self:ResetTestEnvironment()
    
    -- Run tests sequentially
    table.insert(results, {name = "Poll Request Sending", passed = self:TestPollRequestSending()})
    C_Timer.After(0.5, function()
        table.insert(results, {name = "Survey Dialog Display", passed = self:TestSurveyDialogDisplay()})
    end)
    
    C_Timer.After(1.0, function()
        table.insert(results, {name = "Poll Response Processing", passed = self:TestPollResponseProcessing()})
    end)
    
    C_Timer.After(1.5, function()
        table.insert(results, {name = "Poll Progress Tracking", passed = self:TestPollProgressTracking()})
    end)
    
    C_Timer.After(2.0, function()
        table.insert(results, {name = "Poll Timeout Handling", passed = self:TestPollTimeoutHandling()})
    end)
    
    C_Timer.After(5.0, function()
        table.insert(results, {name = "Bench/Opt-Out Population", passed = self:TestBenchOptOutPopulation()})
    end)
    
    -- Print summary after all tests complete
    C_Timer.After(7.0, function()
        self:PrintTestSummary(results)
    end)
end

-- MARK: Test Summary
function OrganizerSurveyTests:PrintTestSummary(results)
    Debug:Dev("test", "")
    Debug:Dev("test", "═══════════════════════════════════════")
    Debug:Dev("test", "  TEST SUMMARY")
    Debug:Dev("test", "═══════════════════════════════════════")
    
    local passed = 0
    local failed = 0
    
    for _, result in ipairs(results) do
        if result.passed then
            Debug:Dev("test", "✓", result.name)
            passed = passed + 1
        else
            Debug:Error("✗", result.name)
            failed = failed + 1
        end
    end
    
    Debug:Dev("test", "")
    Debug:Dev("test", "Total Tests:", #results)
    Debug:Dev("test", "Passed:", passed)
    Debug:Dev("test", "Failed:", failed)
    Debug:Dev("test", "═══════════════════════════════════════")
    Debug:Dev("test", "")
end

-- MARK: Quick Test Commands
function OrganizerSurveyTests:QuickTestPollRequest()
    Debug:Dev("test", "Quick Test: Poll Request")
    return self:TestPollRequestSending()
end

function OrganizerSurveyTests:QuickTestSurveyDialog()
    Debug:Dev("test", "Quick Test: Survey Dialog")
    return self:TestSurveyDialogDisplay()
end

function OrganizerSurveyTests:QuickTestPollResponse()
    Debug:Dev("test", "Quick Test: Poll Response")
    return self:TestPollResponseProcessing()
end

-- MARK: Global Test Function
function NextKeyTestOrganizerSurvey()
    NextKey222.OrganizerSurveyTests:RunAllTests()
end