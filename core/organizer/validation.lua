-- MARK: Module Definition
-- Validation System for M+ Group Organizer
-- Provides data validation and error reporting for organizer components

local _, NextKey222 = ...

local Validation = {}
NextKey222.OrganizerValidation = Validation

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("OrganizerValidation", Validation)

-- MARK: Private Implementation

-- Validation error levels
local ERROR_LEVELS = {
    ERROR = "ERROR",     -- Critical errors that prevent functionality
    WARNING = "WARNING", -- Issues that should be addressed but don't block
    INFO = "INFO"        -- Informational messages
}

-- MARK: Public Interface

--- Initialize Validation module
-- @return boolean True if initialization successful
function Validation:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("org_validation", "OrganizerValidation initialized")
        return true
    end, "Validation:Initialize")
end

--- Validate player object structure and data
-- @param player table Player object to validate
-- @return boolean isValid, table errors
function Validation:ValidatePlayerObject(player)
    return NextKey222.SafeRun(function()
        local errors = {}
        local warnings = {}
        
        -- Use type definitions validation if available
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.ValidatePlayerObject then
            local isValid, typeErrors = NextKey222.PlayerTypes.ValidatePlayerObject(player)
            if not isValid then
                for _, error in ipairs(typeErrors) do
                    table.insert(errors, { level = ERROR_LEVELS.ERROR, message = error })
                end
            end
        end
        
        -- Additional organizer-specific validation
        if player then
            -- Validate roles
            if player.roles then
                local validRoles = {"Tank", "Healer", "DPS"}
                for _, role in ipairs(player.roles) do
                    if not tContains(validRoles, role) then
                        table.insert(errors, { 
                            level = ERROR_LEVELS.ERROR, 
                            message = "Invalid role: " .. tostring(role) 
                        })
                    end
                end
            end
            
            -- Validate utilities
            if player.utils then
                local validUtils = {"Lust", "Brez"}
                for _, util in ipairs(player.utils) do
                    if not tContains(validUtils, util) then
                        table.insert(warnings, { 
                            level = ERROR_LEVELS.WARNING, 
                            message = "Unknown utility: " .. tostring(util) 
                        })
                    end
                end
            end
            
            -- Validate data source
            local validSources = {"addon", "auto-detected", "temporary"}
            if not tContains(validSources, player.dataSource) then
                table.insert(errors, { 
                    level = ERROR_LEVELS.ERROR, 
                    message = "Invalid data source: " .. tostring(player.dataSource) 
                })
            end
            
            -- Validate data freshness
            local validFreshness = {"current", "stale", "unknown"}
            if not tContains(validFreshness, player.dataFreshness) then
                table.insert(warnings, { 
                    level = ERROR_LEVELS.WARNING, 
                    message = "Invalid data freshness: " .. tostring(player.dataFreshness) 
                })
            end
            
            -- Check for missing but expected data
            if player.dataSource == "addon" and not player.hasAddon then
                table.insert(warnings, { 
                    level = ERROR_LEVELS.WARNING, 
                    message = "Addon user marked as not having addon" 
                })
            end
            
            if player.dataSource == "temporary" and not player.isTemporary then
                table.insert(warnings, { 
                    level = ERROR_LEVELS.WARNING, 
                    message = "Temporary player not marked as temporary" 
                })
            end
        end
        
        -- Combine errors and warnings
        local allIssues = {}
        for _, error in ipairs(errors) do
            table.insert(allIssues, error)
        end
        for _, warning in ipairs(warnings) do
            table.insert(allIssues, warning)
        end
        
        return #errors == 0, allIssues
    end, "Validation:ValidatePlayerObject")
end

--- Validate keystone object structure and data
-- @param keystone table Keystone object to validate
-- @return boolean isValid, table errors
function Validation:ValidateKeystoneData(keystone)
    return NextKey222.SafeRun(function()
        local errors = {}
        
        -- Use type definitions validation if available
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.ValidateKeystoneObject then
            local isValid, typeErrors = NextKey222.PlayerTypes.ValidateKeystoneObject(keystone)
            if not isValid then
                for _, error in ipairs(typeErrors) do
                    table.insert(errors, { level = ERROR_LEVELS.ERROR, message = error })
                end
            end
        end
        
        -- Additional validation
        if keystone then
            -- Validate dungeon ID against current season
            if keystone.dungeonID then
                if not self:IsValidDungeonID(keystone.dungeonID) then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Invalid dungeon ID for current season: " .. keystone.dungeonID 
                    })
                end
            end
            
            -- Validate keystone level
            if keystone.level then
                if keystone.level < 2 then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Keystone level too low: " .. keystone.level 
                    })
                elseif keystone.level > 40 then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.WARNING, 
                        message = "Keystone level unusually high: " .. keystone.level 
                    })
                end
            end
        end
        
        return #errors == 0, errors
    end, "Validation:ValidateKeystoneData")
end

--- Validate group object structure and composition
-- @param group table Group object to validate
-- @return boolean isValid, table errors
function Validation:ValidateGroupObject(group)
    return NextKey222.SafeRun(function()
        local errors = {}
        
        -- Use type definitions validation if available
        if NextKey222.PlayerTypes and NextKey222.PlayerTypes.ValidateGroupObject then
            local isValid, typeErrors = NextKey222.PlayerTypes.ValidateGroupObject(group)
            if not isValid then
                for _, error in ipairs(typeErrors) do
                    table.insert(errors, { level = ERROR_LEVELS.ERROR, message = error })
                end
            end
        end
        
        -- Additional group-specific validation
        if group and group.players then
            -- Validate role composition
            local roleCount = self:CountRoles(group.players)
            if roleCount.Tank ~= 1 then
                table.insert(errors, { 
                    level = ERROR_LEVELS.ERROR, 
                    message = "Group must have exactly 1 tank, has " .. (roleCount.Tank or 0) 
                })
            end
            
            if roleCount.Healer ~= 1 then
                table.insert(errors, { 
                    level = ERROR_LEVELS.ERROR, 
                    message = "Group must have exactly 1 healer, has " .. (roleCount.Healer or 0) 
                })
            end
            
            if roleCount.DPS ~= 3 then
                table.insert(errors, { 
                    level = ERROR_LEVELS.ERROR, 
                    message = "Group must have exactly 3 DPS, has " .. (roleCount.DPS or 0) 
                })
            end
            
            -- Validate no duplicate players
            local playerIDs = {}
            for _, player in ipairs(group.players) do
                if playerIDs[player.id] then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Duplicate player in group: " .. player.id 
                    })
                else
                    playerIDs[player.id] = true
                end
            end
            
            -- Validate keystone if present
            if group.chosenKeystone then
                local isValid, keystoneErrors = self:ValidateKeystoneData(group.chosenKeystone)
                if not isValid then
                    for _, error in ipairs(keystoneErrors) do
                        table.insert(errors, error)
                    end
                end
            end
        end
        
        return #errors == 0, errors
    end, "Validation:ValidateGroupObject")
end

--- Validate survey response data
-- @param survey table Survey response to validate
-- @return boolean isValid, table errors
function Validation:ValidateSurveyResponse(survey)
    return NextKey222.SafeRun(function()
        local errors = {}
        
        if not survey then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = "Survey response is nil" 
            })
            return false, errors
        end
        
        -- Required fields
        if not survey.pollID or type(survey.pollID) ~= "string" then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = "Missing or invalid poll ID" 
            })
        end
        
        if not survey.playerID or type(survey.playerID) ~= "string" then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = "Missing or invalid player ID" 
            })
        end
        
        if survey.optedIn ~= true and survey.optedIn ~= false then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = "Missing or invalid optedIn flag" 
            })
        end
        
        -- Validate role preferences if present
        if survey.rolePreferences then
            local validPreferences = {"Will Play", "Fill", "Won't Play"}
            for role, preference in pairs(survey.rolePreferences) do
                if not tContains({"Tank", "Healer", "DPS"}, role) then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Invalid role in preferences: " .. tostring(role) 
                    })
                end
                
                if not tContains(validPreferences, preference) then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Invalid role preference: " .. tostring(preference) 
                    })
                end
            end
        end
        
        -- Validate character data if present
        if survey.characterData then
            local isValid, charErrors = self:ValidatePlayerObject(survey.characterData)
            if not isValid then
                for _, error in ipairs(charErrors) do
                    table.insert(errors, { 
                        level = ERROR_LEVELS.ERROR, 
                        message = "Character data error: " .. error.message 
                    })
                end
            end
        end
        
        return #errors == 0, errors
    end, "Validation:ValidateSurveyResponse")
end

--- Check if dungeon ID is valid for current season
-- @param dungeonID number Dungeon ID to check
-- @return boolean True if valid
function Validation:IsValidDungeonID(dungeonID)
    return NextKey222.SafeRun(function()
        -- Get current season dungeons
        if NextKey222.Season and NextKey222.Season.GetCurrentSeasonDungeons then
            local seasonDungeons = NextKey222.Season:GetCurrentSeasonDungeons()
            for _, dungeon in ipairs(seasonDungeons) do
                if dungeon.id == dungeonID then
                    return true
                end
            end
        end
        
        -- Fallback: check against known dungeon IDs
        local knownDungeons = {
            503, -- Ara-Kara, City of Echoes
            504, -- Cinderbrew Meadery
            505, -- The Stonevault
            506, -- Darkflame Cleft
            507, -- The Rookery
            508, -- Priory of the Sacred Flame
            509, -- The Dawnbreaker
            510, -- City of Threads
        }
        
        return tContains(knownDungeons, dungeonID)
    end, "Validation:IsValidDungeonID")
end

--- Count roles in a group of players
-- @param players table List of player objects
-- @return table Role counts
function Validation:CountRoles(players)
    return NextKey222.SafeRun(function()
        local roleCount = { Tank = 0, Healer = 0, DPS = 0 }
        
        for _, player in ipairs(players) do
            if player.roles then
                for _, role in ipairs(player.roles) do
                    if roleCount[role] then
                        roleCount[role] = roleCount[role] + 1
                    end
                end
            end
        end
        
        return roleCount
    end, "Validation:CountRoles")
end

--- Validate group composition for specific requirements
-- @param players table List of player objects
-- @param requirements table Composition requirements
-- @return boolean isValid, table errors
function Validation:ValidateGroupComposition(players, requirements)
    return NextKey222.SafeRun(function()
        local errors = {}
        local roleCount = self:CountRoles(players)
        
        requirements = requirements or {
            tank = 1,
            healer = 1,
            dps = 3,
            utilities = {}
        }
        
        -- Check role requirements
        if roleCount.Tank ~= requirements.tank then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = string.format("Tank requirement: %d, have %d", requirements.tank, roleCount.Tank) 
            })
        end
        
        if roleCount.Healer ~= requirements.healer then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = string.format("Healer requirement: %d, have %d", requirements.healer, roleCount.Healer) 
            })
        end
        
        if roleCount.DPS ~= requirements.dps then
            table.insert(errors, { 
                level = ERROR_LEVELS.ERROR, 
                message = string.format("DPS requirement: %d, have %d", requirements.dps, roleCount.DPS) 
            })
        end
        
        -- Check utility requirements
        if requirements.utilities then
            local groupUtils = self:GetGroupUtilities(players)
            
            for _, requiredUtil in ipairs(requirements.utilities) do
                if not tContains(groupUtils, requiredUtil) then
                    table.insert(errors, { 
                        level = ERROR_LEVELS.WARNING, 
                        message = "Missing required utility: " .. requiredUtil 
                    })
                end
            end
        end
        
        return #errors == 0, errors
    end, "Validation:ValidateGroupComposition")
end

--- Get all utilities provided by a group
-- @param players table List of player objects
-- @return table List of utilities
function Validation:GetGroupUtilities(players)
    return NextKey222.SafeRun(function()
        local utilities = {}
        
        for _, player in ipairs(players) do
            if player.utils then
                for _, util in ipairs(player.utils) do
                    if not tContains(utilities, util) then
                        table.insert(utilities, util)
                    end
                end
            end
        end
        
        return utilities
    end, "Validation:GetGroupUtilities")
end

--- Validate all players in a list
-- @param players table List of player objects
-- @return table validationResults
function Validation:ValidateAllPlayers(players)
    return NextKey222.SafeRun(function()
        local results = {}
        local totalErrors = 0
        local totalWarnings = 0
        
        for i, player in ipairs(players) do
            local isValid, errors = self:ValidatePlayerObject(player)
            
            local errorCount = 0
            local warningCount = 0
            
            for _, error in ipairs(errors) do
                if error.level == ERROR_LEVELS.ERROR then
                    errorCount = errorCount + 1
                elseif error.level == ERROR_LEVELS.WARNING then
                    warningCount = warningCount + 1
                end
            end
            
            results[i] = {
                playerID = player.id,
                isValid = isValid,
                errors = errorCount,
                warnings = warningCount,
                details = errors
            }
            
            totalErrors = totalErrors + errorCount
            totalWarnings = totalWarnings + warningCount
        end
        
        return {
            totalPlayers = #players,
            validPlayers = #players - totalErrors,
            totalErrors = totalErrors,
            totalWarnings = totalWarnings,
            playerResults = results
        }
    end, "Validation:ValidateAllPlayers")
end

--- Format validation errors for display
-- @param errors table List of error objects
-- @return string Formatted error message
function Validation:FormatErrors(errors)
    return NextKey222.SafeRun(function()
        if not errors or #errors == 0 then
            return "No errors"
        end
        
        local messages = {}
        for _, error in ipairs(errors) do
            local prefix = ""
            if error.level == ERROR_LEVELS.ERROR then
                prefix = "❌ "
            elseif error.level == ERROR_LEVELS.WARNING then
                prefix = "⚠️ "
            else
                prefix = "ℹ️ "
            end
            
            table.insert(messages, prefix .. error.message)
        end
        
        return table.concat(messages, "\n")
    end, "Validation:FormatErrors")
end

--- Test validation functionality
function Validation:Test()
    return NextKey222.SafeRun(function()
        Debug:User("=== Validation Test ===")
        
        -- Test player validation
        local testPlayer = NextKey222.PlayerTypes.CreatePlayerObject("Test-Realm", "Test", "Realm", "WARRIOR")
        testPlayer.roles = {"Tank", "DPS"}
        testPlayer.utils = {"Brez"}
        
        local isValid, errors = self:ValidatePlayerObject(testPlayer)
        Debug:User("Player validation:", isValid and "✅ Passed" or "❌ Failed")
        if not isValid then
            Debug:User(self:FormatErrors(errors))
        end
        
        -- Test keystone validation
        local testKeystone = NextKey222.PlayerTypes.CreateKeystoneObject(503, 15, "Test-Realm")
        local isKeystoneValid, keystoneErrors = self:ValidateKeystoneData(testKeystone)
        Debug:User("Keystone validation:", isKeystoneValid and "✅ Passed" or "❌ Failed")
        if not isKeystoneValid then
            Debug:User(self:FormatErrors(keystoneErrors))
        end
        
        -- Test group validation
        local testGroup = NextKey222.PlayerTypes.CreateGroupObject(1)
        testGroup.players = {testPlayer} -- Incomplete group for testing
        
        local isGroupValid, groupErrors = self:ValidateGroupObject(testGroup)
        Debug:User("Group validation:", isGroupValid and "✅ Passed" or "❌ Failed")
        if not isGroupValid then
            Debug:User(self:FormatErrors(groupErrors))
        end
        
        Debug:User("=== Test Complete ===")
    end, "Validation:Test")
end

-- MARK: Event Handlers
function Validation:OnEnable()
    -- Register for events if needed
end

function Validation:OnDisable()
    -- Cleanup if needed
end

return Validation