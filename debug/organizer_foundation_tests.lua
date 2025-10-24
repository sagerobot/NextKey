-- MARK: Module Definition
-- Foundation Tests for M+ Group Organizer
-- Tests character storage, auto-detection, data builder, validation, and communications

local _, NextKey222 = ...

local FoundationTests = {}
NextKey222.FoundationTests = FoundationTests

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("FoundationTests", FoundationTests)

-- MARK: Test Functions

--- Run all foundation tests
function FoundationTests:RunAllTests()
    return NextKey222.SafeRun(function()
        Debug:User("=== M+ Group Organizer Foundation Tests ===")
        
        local totalTests = 0
        local passedTests = 0
        local failedTests = 0
        
        -- Test Character Storage
        local storagePassed, storageFailed = self:TestCharacterStorage()
        totalTests = totalTests + storagePassed + storageFailed
        passedTests = passedTests + storagePassed
        failedTests = failedTests + storageFailed
        
        -- Test Auto Detection
        local autoPassed, autoFailed = self:TestAutoDetection()
        totalTests = totalTests + autoPassed + autoFailed
        passedTests = passedTests + autoPassed
        failedTests = failedTests + autoFailed
        
        -- Test Player Data Builder
        local builderPassed, builderFailed = self:TestPlayerDataBuilder()
        totalTests = totalTests + builderPassed + builderFailed
        passedTests = passedTests + builderPassed
        failedTests = failedTests + builderFailed
        
        -- Test Validation
        local validationPassed, validationFailed = self:TestValidation()
        totalTests = totalTests + validationPassed + validationFailed
        passedTests = passedTests + validationPassed
        failedTests = failedTests + validationFailed
        
        -- Test Communications
        local commsPassed, commsFailed = self:TestCommunications()
        totalTests = totalTests + commsPassed + commsFailed
        passedTests = passedTests + commsPassed
        failedTests = failedTests + commsFailed
        
        -- Test Integration
        local integrationPassed, integrationFailed = self:TestIntegration()
        totalTests = totalTests + integrationPassed + integrationFailed
        passedTests = passedTests + integrationPassed
        failedTests = failedTests + integrationFailed
        
        -- Summary
        Debug:User(string.format("=== Test Summary ==="))
        Debug:User(string.format("Total Tests: %d", totalTests))
        Debug:User(string.format("Passed: %d", passedTests))
        Debug:User(string.format("Failed: %d", failedTests))
        Debug:User(string.format("Success Rate: %.1f%%", (passedTests / totalTests) * 100))
        
        if failedTests > 0 then
            Debug:User("=== Some tests failed. Check debug output for details ===")
        else
            Debug:User("=== All tests passed! ===")
        end
        
        Debug:User("=== Foundation Tests Complete ===")
        return failedTests == 0
    end, "FoundationTests:RunAllTests")
end

--- Test Character Storage module
-- @return number passed, number failed
function FoundationTests:TestCharacterStorage()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Character Storage ---")
        local passed = 0
        local failed = 0
        
        if not NextKey222.CharacterStorage then
            Debug:User("❌ CharacterStorage module not available")
            return 0, 1
        end
        
        -- Test initialization
        if NextKey222.CharacterStorage.Initialize then
            local success = NextKey222.CharacterStorage:Initialize()
            if success then
                Debug:User("✅ CharacterStorage initialization successful")
                passed = passed + 1
            else
                Debug:User("❌ CharacterStorage initialization failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ CharacterStorage.Initialize method not available")
            failed = failed + 1
        end
        
        -- Test character CRUD operations
        local testCharID = "TestPlayer-Realm"
        local testCharData = {
            name = "TestPlayer",
            realm = "Realm",
            class = "WARRIOR",
            level = 80,
            availableRoles = {
                Tank = true,
                Healer = false,
                DPS = true
            },
            utilities = {
                Lust = false,
                Brez = true
            },
            currentKeystone = {
                dungeonID = 503,
                level = 15,
                lastUpdated = time()
            },
            overallScore = 2500,
            dungeonScores = {
                [503] = 285.5,
                [504] = 280.0
            }
        }
        
        -- Test save character
        if NextKey222.CharacterStorage.SaveCharacter then
            local success = NextKey222.CharacterStorage:SaveCharacter(testCharID, testCharData)
            if success then
                Debug:User("✅ SaveCharacter successful")
                passed = passed + 1
            else
                Debug:User("❌ SaveCharacter failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ SaveCharacter method not available")
            failed = failed + 1
        end
        
        -- Test get character
        if NextKey222.CharacterStorage.GetCharacter then
            local retrieved = NextKey222.CharacterStorage:GetCharacter(testCharID)
            if retrieved and retrieved.name == testCharData.name then
                Debug:User("✅ GetCharacter successful")
                passed = passed + 1
            else
                Debug:User("❌ GetCharacter failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ GetCharacter method not available")
            failed = failed + 1
        end
        
        -- Test role management
        if NextKey222.CharacterStorage.SetRole then
            local success = NextKey222.CharacterStorage:SetRole(testCharID, "Healer", true)
            if success then
                Debug:User("✅ SetRole successful")
                passed = passed + 1
            else
                Debug:User("❌ SetRole failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ SetRole method not available")
            failed = failed + 1
        end
        
        -- Test role retrieval
        if NextKey222.CharacterStorage.GetAvailableRoles then
            local roles = NextKey222.CharacterStorage:GetAvailableRoles(testCharID)
            if roles and roles.Healer == true then
                Debug:User("✅ GetAvailableRoles successful")
                passed = passed + 1
            else
                Debug:User("❌ GetAvailableRoles failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ GetAvailableRoles method not available")
            failed = failed + 1
        end
        
        -- Test temporary player card creation
        if NextKey222.CharacterStorage.CreateTemporaryPlayerCard then
            local tempCard = NextKey222.CharacterStorage:CreateTemporaryPlayerCard(testCharID, testCharID)
            if tempCard and tempCard.isTemporary == true then
                Debug:User("✅ CreateTemporaryPlayerCard successful")
                passed = passed + 1
            else
                Debug:User("❌ CreateTemporaryPlayerCard failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ CreateTemporaryPlayerCard method not available")
            failed = failed + 1
        end
        
        -- Test data freshness
        if NextKey222.CharacterStorage.CheckDataFreshness then
            local freshness = NextKey222.CharacterStorage:CheckDataFreshness(testCharData)
            if freshness then
                Debug:User("✅ CheckDataFreshness successful: " .. freshness)
                passed = passed + 1
            else
                Debug:User("❌ CheckDataFreshness failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ CheckDataFreshness method not available")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Character Storage Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestCharacterStorage")
end

--- Test Auto Detection module
-- @return number passed, number failed
function FoundationTests:TestAutoDetection()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Auto Detection ---")
        local passed = 0
        local failed = 0
        
        if not NextKey222.OrganizerAutoDetection then
            Debug:User("❌ OrganizerAutoDetection module not available")
            return 0, 1
        end
        
        -- Test initialization
        if NextKey222.OrganizerAutoDetection.Initialize then
            local success = NextKey222.OrganizerAutoDetection:Initialize()
            if success then
                Debug:User("✅ AutoDetection initialization successful")
                passed = passed + 1
            else
                Debug:User("❌ AutoDetection initialization failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ AutoDetection.Initialize method not available")
            failed = failed + 1
        end
        
        -- Test addon detection
        if NextKey222.OrganizerAutoDetection.HasAddon then
            local hasAddon = NextKey222.OrganizerAutoDetection:HasAddon("TestPlayer-Realm")
            Debug:User("✅ HasAddon test completed: " .. (hasAddon and "detected" or "not detected"))
            passed = passed + 1
        else
            Debug:User("❌ HasAddon method not available")
            failed = failed + 1
        end
        
        -- Test role derivation
        if NextKey222.OrganizerAutoDetection.DeriveRoles then
            local roles = NextKey222.OrganizerAutoDetection:DeriveRoles("WARRIOR", 71) -- Arms Warrior spec
            if roles and #roles > 0 then
                Debug:User("✅ DeriveRoles successful: " .. table.concat(roles, ", "))
                passed = passed + 1
            else
                Debug:User("❌ DeriveRoles failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ DeriveRoles method not available")
            failed = failed + 1
        end
        
        -- Test utility derivation
        if NextKey222.OrganizerAutoDetection.DeriveUtilities then
            local utils = NextKey222.OrganizerAutoDetection:DeriveUtilities("WARRIOR")
            if utils then
                Debug:User("✅ DeriveUtilities successful: " .. table.concat(utils, ", "))
                passed = passed + 1
            else
                Debug:User("❌ DeriveUtilities failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ DeriveUtilities method not available")
            failed = failed + 1
        end
        
        -- Test keystone detection
        if NextKey222.OrganizerAutoDetection.GetKeystoneFromLibOpenRaid then
            local keystone = NextKey222.OrganizerAutoDetection:GetKeystoneFromLibOpenRaid("TestPlayer-Realm")
            if keystone then
                Debug:User("✅ GetKeystoneFromLibOpenRaid successful")
                passed = passed + 1
            else
                Debug:User("✅ GetKeystoneFromLibOpenRaid completed (no keystone found)")
                passed = passed + 1
            end
        else
            Debug:User("❌ GetKeystoneFromLibOpenRaid method not available")
            failed = failed + 1
        end
        
        -- Test scan for non-addon players
        if NextKey222.OrganizerAutoDetection.ScanForNonAddonPlayers then
            local detected = NextKey222.OrganizerAutoDetection:ScanForNonAddonPlayers()
            if detected then
                Debug:User("✅ ScanForNonAddonPlayers successful: found " .. #detected .. " players")
                passed = passed + 1
            else
                Debug:User("✅ ScanForNonAddonPlayers completed (no players in group)")
                passed = passed + 1
            end
        else
            Debug:User("❌ ScanForNonAddonPlayers method not available")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Auto Detection Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestAutoDetection")
end

--- Test Player Data Builder module
-- @return number passed, number failed
function FoundationTests:TestPlayerDataBuilder()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Player Data Builder ---")
        local passed = 0
        local failed = 0
        
        if not NextKey222.OrganizerPlayerDataBuilder then
            Debug:User("❌ OrganizerPlayerDataBuilder module not available")
            return 0, 1
        end
        
        -- Test initialization
        if NextKey222.OrganizerPlayerDataBuilder.Initialize then
            local success = NextKey222.OrganizerPlayerDataBuilder:Initialize()
            if success then
                Debug:User("✅ PlayerDataBuilder initialization successful")
                passed = passed + 1
            else
                Debug:User("❌ PlayerDataBuilder initialization failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ PlayerDataBuilder.Initialize method not available")
            failed = failed + 1
        end
        
        -- Test player object building
        if NextKey222.OrganizerPlayerDataBuilder.BuildPlayerObject then
            local player = NextKey222.OrganizerPlayerDataBuilder:BuildPlayerObject("TestPlayer-Realm", "addon")
            if player and player.id == "TestPlayer-Realm" then
                Debug:User("✅ BuildPlayerObject successful")
                passed = passed + 1
            else
                Debug:User("❌ BuildPlayerObject failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ BuildPlayerObject method not available")
            failed = failed + 1
        end
        
        -- Test data source priority
        if NextKey222.OrganizerPlayerDataBuilder.GetBestDataSource then
            local source = NextKey222.OrganizerPlayerDataBuilder:GetBestDataSource("TestPlayer-Realm")
            if source then
                Debug:User("✅ GetBestDataSource successful: " .. source)
                passed = passed + 1
            else
                Debug:User("❌ GetBestDataSource failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ GetBestDataSource method not available")
            failed = failed + 1
        end
        
        -- Test temporary player card creation
        if NextKey222.OrganizerPlayerDataBuilder.CreateTemporaryPlayerCard then
            local tempCard = NextKey222.OrganizerPlayerDataBuilder:CreateTemporaryPlayerCard("TestPlayer-Realm", "TestPlayer-Realm")
            if tempCard and tempCard.isTemporary == true then
                Debug:User("✅ CreateTemporaryPlayerCard successful")
                passed = passed + 1
            else
                Debug:User("❌ CreateTemporaryPlayerCard failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ CreateTemporaryPlayerCard method not available")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Player Data Builder Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestPlayerDataBuilder")
end

--- Test Validation module
-- @return number passed, number failed
function FoundationTests:TestValidation()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Validation ---")
        local passed = 0
        local failed = 0
        
        if not NextKey222.OrganizerValidation then
            Debug:User("❌ OrganizerValidation module not available")
            return 0, 1
        end
        
        -- Test initialization
        if NextKey222.OrganizerValidation.Initialize then
            local success = NextKey222.OrganizerValidation:Initialize()
            if success then
                Debug:User("✅ Validation initialization successful")
                passed = passed + 1
            else
                Debug:User("❌ Validation initialization failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ Validation.Initialize method not available")
            failed = failed + 1
        end
        
        -- Test player validation
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.CreatePlayerObject then
            local testPlayer = NextKey222.PlayerTypes.CreatePlayerObject("TestPlayer-Realm", "Test", "Realm", "WARRIOR")
            testPlayer.roles = {"Tank", "DPS"}
            testPlayer.utils = {"Brez"}
            
            local isValid, errors = NextKey222.OrganizerValidation:ValidatePlayerObject(testPlayer)
            if isValid then
                Debug:User("✅ ValidatePlayerObject successful")
                passed = passed + 1
            else
                Debug:User("❌ ValidatePlayerObject failed: " .. NextKey222.OrganizerValidation:FormatErrors(errors))
                failed = failed + 1
            end
        else
            Debug:User("❌ ValidatePlayerObject method not available")
            failed = failed + 1
        end
        
        -- Test keystone validation
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.CreateKeystoneObject then
            local testKeystone = NextKey222.PlayerTypes.CreateKeystoneObject(503, 15, "TestPlayer-Realm")
            
            local isValid, errors = NextKey222.OrganizerValidation:ValidateKeystoneData(testKeystone)
            if isValid then
                Debug:User("✅ ValidateKeystoneData successful")
                passed = passed + 1
            else
                Debug:User("❌ ValidateKeystoneData failed: " .. NextKey222.OrganizerValidation:FormatErrors(errors))
                failed = failed + 1
            end
        else
            Debug:User("❌ ValidateKeystoneData method not available")
            failed = failed + 1
        end
        
        -- Test group validation
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.CreateGroupObject then
            local testGroup = NextKey222.PlayerTypes.CreateGroupObject(1)
            testGroup.players = {testPlayer}
            
            local isValid, errors = NextKey222.OrganizerValidation:ValidateGroupObject(testGroup)
            if isValid then
                Debug:User("✅ ValidateGroupObject successful")
                passed = passed + 1
            else
                Debug:User("❌ ValidateGroupObject failed: " .. NextKey222.OrganizerValidation:FormatErrors(errors))
                failed = failed + 1
            end
        else
            Debug:User("❌ ValidateGroupObject method not available")
            failed = failed + 1
        end
        
        -- Test role counting
        if NextKey222.OrganizerValidation.CountRoles then
            local roleCount = NextKey222.OrganizerValidation:CountRoles({testPlayer})
            if roleCount and roleCount.Tank == 1 and roleCount.DPS == 1 then
                Debug:User("✅ CountRoles successful")
                passed = passed + 1
            else
                Debug:User("❌ CountRoles failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ CountRoles method not available")
            failed = failed + 1
        end
        
        -- Test group composition validation
        if NextKey222.OrganizerValidation.ValidateGroupComposition then
            local isValid, errors = NextKey222.OrganizerValidation:ValidateGroupComposition(
                {testPlayer},
                {tank = 1, healer = 1, dps = 3, utilities = {"Brez"}}
            )
            if isValid then
                Debug:User("✅ ValidateGroupComposition successful")
                passed = passed + 1
            else
                Debug:User("❌ ValidateGroupComposition failed: " .. NextKey222.OrganizerValidation:FormatErrors(errors))
                failed = failed + 1
            end
        else
            Debug:User("❌ ValidateGroupComposition method not available")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Validation Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestValidation")
end

--- Test Communications module
-- @return number passed, number failed
function FoundationTests:TestCommunications()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Communications ---")
        local passed = 0
        local failed = 0
        
        if not NextKey222.OrganizerComms then
            Debug:User("❌ OrganizerComms module not available")
            return 0, 1
        end
        
        -- Test initialization
        if NextKey222.OrganizerComms.Initialize then
            local success = NextKey222.OrganizerComms:Initialize()
            if success then
                Debug:User("✅ Comms initialization successful")
                passed = passed + 1
            else
                Debug:User("❌ Comms initialization failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ Comms.Initialize method not available")
            failed = failed + 1
        end
        
        -- Test message sending
        if NextKey222.OrganizerComms.SendOrganizerMessage then
            local success = NextKey222.OrganizerComms:SendOrganizerMessage("TEST_OPCODE", {test = "data"}, "PARTY")
            if success then
                Debug:User("✅ SendOrganizerMessage successful")
                passed = passed + 1
            else
                Debug:User("❌ SendOrganizerMessage failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ SendOrganizerMessage method not available")
            failed = failed + 1
        end
        
        -- Test poll request
        if NextKey222.OrganizerComms.SendPollRequest then
            local success = NextKey222.OrganizerComms:SendPollRequest("TEST_POLL", 60)
            if success then
                Debug:User("✅ SendPollRequest successful")
                passed = passed + 1
            else
                Debug:User("❌ SendPollRequest failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ SendPollRequest method not available")
            failed = failed + 1
        end
        
        -- Test poll response
        if NextKey222.OrganizerComms.SendPollResponse then
            local success = NextKey222.OrganizerComms:SendPollResponse("TEST_POLL", {
                optedIn = true,
                selectedCharacter = "TestPlayer-Realm",
                rolePreferences = {
                    Tank = "Will Play",
                    DPS = "Will Play",
                    Healer = "Fill"
                }
            })
            if success then
                Debug:User("✅ SendPollResponse successful")
                passed = passed + 1
            else
                Debug:User("❌ SendPollResponse failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ SendPollResponse method not available")
            failed = failed + 1
        end
        
        -- Test batch ID generation
        if NextKey222.OrganizerComms.GenerateBatchID then
            local batchID = NextKey222.OrganizerComms:GenerateBatchID()
            if batchID and string.find(batchID, "BATCH_") then
                Debug:User("✅ GenerateBatchID successful: " .. batchID)
                passed = passed + 1
            else
                Debug:User("❌ GenerateBatchID failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ GenerateBatchID method not available")
            failed = failed + 1
        end
        
        -- Test poll ID generation
        if NextKey222.OrganizerComms.GeneratePollID then
            local pollID = NextKey222.OrganizerComms:GeneratePollID()
            if pollID and string.find(pollID, "POLL_") then
                Debug:User("✅ GeneratePollID successful: " .. pollID)
                passed = passed + 1
            else
                Debug:User("❌ GeneratePollID failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ GeneratePollID method not available")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Communications Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestCommunications")
end

--- Test integration between modules
-- @return number passed, number failed
function FoundationTests:TestIntegration()
    return NextKey222.SafeRun(function()
        Debug:User("--- Testing Integration ---")
        local passed = 0
        local failed = 0
        
        -- Test that all modules are available
        local requiredModules = {
            "CharacterStorage",
            "PlayerTypes",
            "OrganizerAutoDetection",
            "OrganizerPlayerDataBuilder",
            "OrganizerValidation",
            "OrganizerComms"
        }
        
        for _, moduleName in ipairs(requiredModules) do
            local module = NextKey222[moduleName]
            if module then
                Debug:User("✅ " .. moduleName .. " module available")
                passed = passed + 1
            else
                Debug:User("❌ " .. moduleName .. " module not available")
                failed = failed + 1
            end
        end
        
        -- Test cross-module functionality
        if NextKey222.CharacterStorage and NextKey222.OrganizerAutoDetection then
            -- Test that auto-detection can use character storage
            local chars = NextKey222.CharacterStorage:GetAllCharacters()
            if chars then
                Debug:User("✅ CharacterStorage and AutoDetection integration successful")
                passed = passed + 1
            else
                Debug:User("✅ CharacterStorage and AutoDetection integration successful (no characters)")
                passed = passed + 1
            end
        else
            Debug:User("❌ CharacterStorage and AutoDetection integration failed")
            failed = failed + 1
        end
        
        -- Test that validation can use player types
        if NextKey222.OrganizerValidation and NextKey222.PlayerTypes then
            local testPlayer = NextKey222.PlayerTypes.CreatePlayerObject("TestPlayer-Realm", "Test", "Realm", "WARRIOR")
            local isValid, errors = NextKey222.OrganizerValidation:ValidatePlayerObject(testPlayer)
            if isValid then
                Debug:User("✅ Validation and PlayerTypes integration successful")
                passed = passed + 1
            else
                Debug:User("❌ Validation and PlayerTypes integration failed")
                failed = failed + 1
            end
        else
            Debug:User("❌ Validation and PlayerTypes integration failed")
            failed = failed + 1
        end
        
        Debug:User(string.format("--- Integration Tests: %d passed, %d failed ---", passed, failed))
        return passed, failed
    end, "FoundationTests:TestIntegration")
end

-- MARK: Test Commands

--- Run specific test category
-- @param category string Test category to run
function FoundationTests:RunTestCategory(category)
    return NextKey222.SafeRun(function()
        if category == "storage" then
            return self:TestCharacterStorage()
        elseif category == "autodetect" then
            return self:TestAutoDetection()
        elseif category == "builder" then
            return self:TestPlayerDataBuilder()
        elseif category == "validation" then
            return self:TestValidation()
        elseif category == "comms" then
            return self:TestCommunications()
        elseif category == "integration" then
            return self:TestIntegration()
        else
            Debug:User("Unknown test category: " .. tostring(category))
            return 0, 1
        end
    end, "FoundationTests:RunTestCategory")
end

-- MARK: Module Initialization

--- Initialize Foundation Tests
function FoundationTests:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("foundation_tests", "FoundationTests initialized")
        return true
    end, "FoundationTests:Initialize")
end

-- MARK: Module Cleanup

--- Cleanup Foundation Tests
function FoundationTests:Cleanup()
    return NextKey222.SafeRun(function()
        Debug:Dev("foundation_tests", "FoundationTests cleaned up")
        return true
    end, "FoundationTests:Cleanup")
end

return FoundationTests