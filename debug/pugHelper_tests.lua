local _, NextKey222 = ...
local PUGHelper = NextKey222.PUGHelper
local Debug = NextKey222.Debug

if not PUGHelper then
    Debug:Error("PUG Helper module not found, cannot add test functions.")
    return
end

-- Manually trigger application tracking (for testing)
function PUGHelper:TestApplicationTracking()
    if not self:IsEnabled() then
        Debug:User("PUG Helper is disabled")
        return
    end

    Debug:Dev("pughelper", "Test: Simulating application tracking")

    -- Create fake application data for testing
    local fakeApp = {
        id = "test-" .. time(),
        name = "Test Group - Ara-Kara, City of Echoes",
        leader = "TestLeader-Realm",
        dungeonID = 503,
        keyLevel = 10,
        activityID = 1329,
        comment = "Test group for PUG Helper"
    }

    -- Accessing private variables for testing purposes
    self.trackedApplications[fakeApp.id] = fakeApp
    self:TransitionToState(self.STATE.TRACKING, "test_application_tracking")

    Debug:User("Test application added: " .. fakeApp.name)
end

-- Test function to validate PUG Helper fixes
function PUGHelper:TestPUGHelperFixes()
    Debug:User("=== PUG Helper Fix Validation Test ===")

    -- Test 1: Check if PUG Helper initializes without errors
    Debug:User("Test 1: Checking PUG Helper initialization...")
    local initSuccess = pcall(function()
        return self:Initialize()
    end)

    if initSuccess then
        Debug:User("✓ PUG Helper initialization successful")
    else
        Debug:Error("✗ PUG Helper initialization failed")
        return false
    end

    -- Test 2: Check if event registration works without errors
    Debug:User("Test 2: Checking event registration...")
    local eventSuccess = pcall(function()
        self:RegisterLFGEvents()
    end)

    if eventSuccess then
        Debug:User("✓ Event registration successful")
    else
        Debug:Error("✗ Event registration failed")
        return false
    end

    -- Test 3: Check if hooking setup works without errors
    Debug:User("Test 3: Checking hook setup...")
    local hookSuccess = pcall(function()
        self:SetHookEnabled(true)
    end)

    if hookSuccess then
        Debug:User("✓ Hook setup successful (no errors)")
    else
        Debug:Error("✗ Hook setup failed")
        return false
    end

    -- Test 4: Check state transitions
    Debug:User("Test 4: Checking state transitions...")
    local stateSuccess = pcall(function()
        self:TransitionToState(self.STATE.TRACKING, "test")
        self:TransitionToState(self.STATE.IDLE, "test")
    end)

    if stateSuccess then
        Debug:User("✓ State transitions successful")
    else
        Debug:Error("✗ State transitions failed")
        return false
    end

    -- Test 5: Check application tracking
    Debug:User("Test 5: Checking application tracking...")
    local trackingSuccess = pcall(function()
        self:TestApplicationTracking()
    end)

    if trackingSuccess then
        Debug:User("✓ Application tracking successful")
    else
        Debug:Error("✗ Application tracking failed")
        return false
    end

    Debug:User("=== All PUG Helper tests passed! ===")
    return true
end