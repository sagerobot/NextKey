-- MARK: Module Definition
-- Player Data Builder for M+ Group Organizer
-- Centralized data acquisition and player object assembly

local _, NextKey222 = ...

local PlayerDataBuilder = {}
NextKey222.OrganizerPlayerDataBuilder = PlayerDataBuilder

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("OrganizerPlayerDataBuilder", PlayerDataBuilder)

-- CRITICAL: Get Debug reference (was missing, causing crash on line 30)
local Debug = NextKey222.Debug
-- Debug reference loaded

-- MARK: Private Implementation

-- Data source priority order
local DATA_SOURCE_PRIORITY = {
    "addon",        -- Survey responses from addon users
    "auto-detected", -- API data for non-addon users
    "temporary"      -- Alt character data from character storage
}

-- MARK: Public Interface

--- Generate spec preferences for player
-- Unified function supporting both deterministic (pre-poll) and randomized (poll simulation) modes
-- @param playerID string Player name in format "Name-Realm"
-- @param options table Optional configuration: {randomize = boolean}
--   - randomize=false (default): Current spec="play", others="none" (PRE-POLL)
--   - randomize=true: Weighted random preferences (POST-POLL simulation)
-- @return table, table specPreferences and specDetails tables
function PlayerDataBuilder:GenerateSpecPreferences(playerID, options)
    return NextKey222.SafeRun(function()
        options = options or {}
        local randomize = options.randomize or false
        
        local mode = randomize and "RANDOMIZED (POST-POLL)" or "DETERMINISTIC (PRE-POLL)"
        Debug:Dev("organizer", "=== GenerateSpecPreferences", mode, "for:", playerID)
        
        local specPreferences = {}
        local specDetails = {}
        local availableSpecs = {}
        
        -- Get player profile
        local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(playerID)
        if not profile or not profile.class then
            Debug:Error("No profile found for:", playerID)
            return specPreferences, specDetails
        end
        
        local currentSpecID = profile.specID
        Debug:Dev("organizer", "Player", playerID, "current specID:", currentSpecID, "specName:", profile.specName)
        
        -- Get class ID for API call
        local classID = nil
        local numClasses = GetNumClasses()
        for i = 1, numClasses do
            local className, classToken = GetClassInfo(i)
            if classToken == profile.class then
                classID = i
                break
            end
        end
        
        if not classID then
            Debug:Error("Could not find classID for class:", profile.class)
            return specPreferences, specDetails
        end
        
        -- Query ALL specializations for this class
        local numSpecs = GetNumSpecializationsForClassID(classID)
        for i = 1, numSpecs do
            local specID, specName, _, iconTexture, role = GetSpecializationInfoForClassID(classID, i)
            if specID then
                table.insert(availableSpecs, {
                    specID = specID,
                    specName = specName,
                    role = role,
                    iconTexture = iconTexture
                })
            end
        end
        
        -- Generate preferences based on mode
        local priorityMap = { play = 3, fill = 2, none = 1 }
        
        for _, specInfo in ipairs(availableSpecs) do
            local normalizedRole = specInfo.role and specInfo.role:upper() or "DAMAGER"
            local isCurrentSpec = currentSpecID and specInfo.specID == currentSpecID
            
            local preference
            if randomize then
                -- RANDOMIZED MODE: Weighted probabilities
                if isCurrentSpec then
                    -- Current spec: 70% play, 20% fill, 10% none
                    local rand = math.random()
                    if rand < 0.70 then
                        preference = "play"
                    elseif rand < 0.90 then
                        preference = "fill"
                    else
                        preference = "none"
                    end
                else
                    -- Off-spec: 30% play, 40% fill, 30% none
                    local rand = math.random()
                    if rand < 0.30 then
                        preference = "play"
                    elseif rand < 0.70 then
                        preference = "fill"
                    else
                        preference = "none"
                    end
                end
                Debug:Dev("organizer", (isCurrentSpec and "Current spec" or "Off-spec"), specInfo.specName, "->", preference)
            else
                -- DETERMINISTIC MODE: Current spec="play", others="none"
                if isCurrentSpec then
                    preference = "play"
                    Debug:Dev("organizer", "Marking CURRENT spec", specInfo.specName, "as 'play' for", playerID)
                else
                    preference = "none"
                end
            end
            
            -- Track spec details for tooltips (ALWAYS use uppercase keys)
            if not specDetails[normalizedRole] then
                specDetails[normalizedRole] = {}
            end
            table.insert(specDetails[normalizedRole], {
                specName = specInfo.specName,
                preference = preference
            })
            
            -- Store by role with priority (highest priority wins)
            local currentPriority = priorityMap[specPreferences[normalizedRole]] or 0
            local newPriority = priorityMap[preference] or 0
            
            if newPriority > currentPriority then
                specPreferences[normalizedRole] = preference
            end
        end
        
        Debug:Dev("organizer", "Generated spec preferences for", playerID, ":",
                  "specPrefs has data:", next(specPreferences) ~= nil,
                  "specDetails has data:", next(specDetails) ~= nil)
        
        return specPreferences, specDetails
    end, "PlayerDataBuilder:GenerateSpecPreferences")
end


--- Initialize Player Data Builder module
-- @return boolean True if initialization successful
function PlayerDataBuilder:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "OrganizerPlayerDataBuilder initialized")
        return true
    end, "PlayerDataBuilder:Initialize")
end

--- Build player object from specified data source
-- @param playerID string Player name in format "Name-Realm"
-- @param dataSource string Data source type ("addon", "auto-detected", "temporary")
-- @return table|nil Player object or nil if failed
function PlayerDataBuilder:BuildPlayerObject(playerID, dataSource)
    return NextKey222.SafeRun(function()
        if not playerID then
            Debug:Error("PlayerDataBuilder:BuildPlayerObject - Missing playerID")
            return nil
        end
        
        dataSource = dataSource or "auto-detected"
        
        Debug:Dev("organizer", "Building player object for", playerID, "from", dataSource)
        
        local playerData = {
            id = playerID,
            dataSource = dataSource
        }
        
        -- Route to appropriate builder
        if dataSource == "addon" then
            return self:BuildFromSurveyResponse(playerID)
        elseif dataSource == "auto-detected" then
            return self:BuildFromAutoDetection(playerID)
        elseif dataSource == "temporary" then
            return self:BuildFromCharacterStorage(playerID)
        else
            Debug:Error("PlayerDataBuilder:BuildPlayerObject - Unknown data source:", dataSource)
            return nil
        end
    end, "PlayerDataBuilder:BuildPlayerObject")
end

--- Build player object from survey response (addon user)
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Player object or nil if failed
function PlayerDataBuilder:BuildFromSurveyResponse(playerID)
    return NextKey222.SafeRun(function()
        -- Get profile data from ProfilesService
        local profile = NextKey222.ProfilesService:GetProfile(playerID)
        if not profile then
            Debug:Error("PlayerDataBuilder:BuildFromSurveyResponse - No profile found for", playerID)
            return nil
        end
        
        -- Get preferences from config
        local preferences = self:GetPlayerPreferences(playerID)
        
        -- Get roles from character storage
        local roles = self:GetPlayerRoles(playerID)
        
        -- Get keystone data
        local keystone = self:GetPlayerKeystone(playerID)
        
        -- Assemble player object
        local playerData = self:AssemblePlayerObject(profile, preferences, roles, keystone, "addon")
        
        Debug:Dev("organizer", "Built player object from survey response for", playerID)
        return playerData
    end, "PlayerDataBuilder:BuildFromSurveyResponse")
end

--- Build player object from auto-detection (non-addon user)
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Player object or nil if failed
function PlayerDataBuilder:BuildFromAutoDetection(playerID)
    return NextKey222.SafeRun(function()
        -- Use AutoDetection module to build data
        if NextKey222.OrganizerAutoDetection and NextKey222.OrganizerAutoDetection.UpdateGroupData then
            local groupData = NextKey222.OrganizerAutoDetection:UpdateGroupData()
            
            -- Find the player in the group data
            for _, player in ipairs(groupData) do
                if player.id == playerID then
                    Debug:Dev("organizer", "Built player object from auto-detection for", playerID)
                    return player
                end
            end
        end
        
        -- Fallback: build manually
        local name, realm = strsplit("-", playerID)
        local unit = self:FindUnitForPlayer(playerID)
        
        if unit then
            return NextKey222.OrganizerAutoDetection:BuildPlayerDataFromAPIs(unit, playerID)
        end
        
        Debug:Error("PlayerDataBuilder:BuildFromAutoDetection - Could not find unit for", playerID)
        return nil
    end, "PlayerDataBuilder:BuildFromAutoDetection")
end

--- Build player object from character storage (temporary/alt)
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Player object or nil if failed
function PlayerDataBuilder:BuildFromCharacterStorage(playerID)
    return NextKey222.SafeRun(function()
        if not NextKey222.CharacterStorage then
            Debug:Error("PlayerDataBuilder:BuildFromCharacterStorage - CharacterStorage not available")
            return nil
        end
        
        local characterData = NextKey222.CharacterStorage:GetCharacter(playerID)
        if not characterData then
            Debug:Error("PlayerDataBuilder:BuildFromCharacterStorage - No character data found for", playerID)
            return nil
        end
        
        -- Convert character storage format to player object
        local playerData = {
            id = playerID,
            name = characterData.name,
            realm = characterData.realm,
            class = characterData.class,
            level = characterData.level or 80,
            roles = NextKey222.CharacterStorage:DeriveRoles(characterData),
            utils = characterData.utilities or {},
            keystone = characterData.currentKeystone,
            scores = characterData.dungeonScores or {},
            overallScore = characterData.overallScore or 0,
            preferences = self:GetPlayerPreferences(playerID),
            
            -- Temporary flags
            isTemporary = true,
            sourceCharacter = playerID,
            dataSource = "temporary",
            dataFreshness = NextKey222.CharacterStorage:CheckDataFreshness(characterData)
        }
        
        Debug:Dev("organizer", "Built player object from character storage for", playerID)
        return playerData
    end, "PlayerDataBuilder:BuildFromCharacterStorage")
end

--- Assemble player object from component data
-- @param profile table Profile data from ProfilesService
-- @param preferences table Player preferences
-- @param roles table Available roles
-- @param keystone table Keystone data
-- @param source string Data source
-- @return table Assembled player object
function PlayerDataBuilder:AssemblePlayerObject(profile, preferences, roles, keystone, source)
    return NextKey222.SafeRun(function()
        local playerID = profile.name .. "-" .. (profile.realm or GetRealmName())
        
        local playerData = {
            -- Basic Info
            id = playerID,
            name = profile.name,
            realm = profile.realm or GetRealmName(),
            class = profile.class,
            level = profile.level or 80,
            
            -- Role & Utility
            roles = roles or {},
            utils = profile.capabilities or {},
            
            -- Keystone
            keystone = keystone,
            
            -- Scoring Data
            scores = profile.dungeonScores or {},
            overallScore = profile.io or 0,
            
            -- Preferences
            preferences = preferences or {},
            
            -- Organizer-Specific Fields
            rankScore = 0, -- Will be calculated by optimizer
            isTemporary = false,
            sourceCharacter = nil,
            
            -- Data Source Metadata
            dataSource = source,
            hasAddon = (source == "addon"),
            dataFreshness = "current"
        }
        
        -- Generate default spec preferences if not already set (no poll response yet)
        if not playerData.specPreferences or next(playerData.specPreferences) == nil then
            local defaultSpecPrefs, defaultSpecDetails = self:GenerateSpecPreferences(playerID, {randomize = false})
            playerData.specPreferences = defaultSpecPrefs
            playerData.specDetails = defaultSpecDetails
            
            Debug:Dev("organizer", "Added default spec preferences for", playerID)
        end
        
        -- Validate the assembled object
        local isValid, errors = NextKey222.PlayerTypes.ValidatePlayerObject(playerData)
        if not isValid then
            Debug:Error("PlayerDataBuilder:AssemblePlayerObject - Validation failed:", table.concat(errors, ", "))
            return nil
        end
        
        return playerData
    end, "PlayerDataBuilder:AssemblePlayerObject")
end

--- Create temporary player card for alt character
-- @param altCharacterID string Alt character name in format "Name-Realm"
-- @param sourceCharacterID string Source character who selected the alt
-- @return table|nil Temporary player object
function PlayerDataBuilder:CreateTemporaryPlayerCard(altCharacterID, sourceCharacterID)
    return NextKey222.SafeRun(function()
        if not NextKey222.CharacterStorage then
            Debug:Error("PlayerDataBuilder:CreateTemporaryPlayerCard - CharacterStorage not available")
            return nil
        end
        
        return NextKey222.CharacterStorage:CreateTemporaryPlayerCard(altCharacterID, sourceCharacterID)
    end, "PlayerDataBuilder:CreateTemporaryPlayerCard")
end

--- Get player preferences from config
-- @param playerID string Player name in format "Name-Realm"
-- @return table Player preferences
function PlayerDataBuilder:GetPlayerPreferences(playerID)
    return NextKey222.SafeRun(function()
        -- Try to get preferences from config
        if NextKey222.Config and NextKey222.Config.GetPreferences then
            return NextKey222.Config:GetPreferences(playerID)
        end
        
        -- Fallback: try character storage
        if NextKey222.CharacterStorage then
            local character = NextKey222.CharacterStorage:GetCharacter(playerID)
            if character and character.preferences then
                return character.preferences
            end
        end
        
        return {}
    end, "PlayerDataBuilder:GetPlayerPreferences")
end

--- Get player roles from character storage
-- @param playerID string Player name in format "Name-Realm"
-- @return table Available roles
function PlayerDataBuilder:GetPlayerRoles(playerID)
    return NextKey222.SafeRun(function()
        if NextKey222.CharacterStorage and NextKey222.CharacterStorage.GetAvailableRoles then
            return NextKey222.CharacterStorage:GetAvailableRoles(playerID)
        end
        
        return {}
    end, "PlayerDataBuilder:GetPlayerRoles")
end

--- Get player keystone data
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Keystone data
function PlayerDataBuilder:GetPlayerKeystone(playerID)
    return NextKey222.SafeRun(function()
        -- Try multiple sources for keystone data
        if NextKey222.OrganizerAutoDetection then
            return NextKey222.OrganizerAutoDetection:GetPlayerKeystone(playerID)
        end
        
        return nil
    end, "PlayerDataBuilder:GetPlayerKeystone")
end

--- Find unit ID for player in group
-- @param playerID string Player name in format "Name-Realm"
-- @return string|nil Unit ID or nil if not found
function PlayerDataBuilder:FindUnitForPlayer(playerID)
    return NextKey222.SafeRun(function()
        local raidSize = GetNumGroupMembers()
        if raidSize == 0 then return nil end
        
        local name, realm = strsplit("-", playerID)
        
        for i = 1, raidSize do
            local unit = "raid" .. i
            local unitName, unitRealm = UnitName(unit)
            
            if unitName == name and (unitRealm or GetRealmName()) == (realm or GetRealmName()) then
                return unit
            end
        end
        
        return nil
    end, "PlayerDataBuilder:FindUnitForPlayer")
end

--- Build player objects for multiple players
-- @param playerIDs table List of player IDs
-- @param dataSource string Data source to use for all players
-- @return table List of player objects
function PlayerDataBuilder:BuildMultiplePlayerObjects(playerIDs, dataSource)
    return NextKey222.SafeRun(function()
        local playerObjects = {}
        
        for _, playerID in ipairs(playerIDs) do
            local playerData = self:BuildPlayerObject(playerID, dataSource)
            if playerData then
                table.insert(playerObjects, playerData)
            else
                Debug:Error("PlayerDataBuilder:BuildMultiplePlayerObjects - Failed to build player for", playerID)
            end
        end
        
        Debug:Dev("organizer", "Built", #playerObjects, "player objects from", #playerIDs, "requests")
        return playerObjects
    end, "PlayerDataBuilder:BuildMultiplePlayerObjects")
end

--- Update player object with new data
-- @param playerData table Existing player object
-- @param updates table Updates to apply
-- @return table Updated player object
function PlayerDataBuilder:UpdatePlayerObject(playerData, updates)
    return NextKey222.SafeRun(function()
        if not playerData or not updates then
            return playerData
        end
        
        -- Apply updates
        for key, value in pairs(updates) do
            playerData[key] = value
        end
        
        -- Re-validate if needed
        local isValid, errors = NextKey222.PlayerTypes.ValidatePlayerObject(playerData)
        if not isValid then
            Debug:Error("PlayerDataBuilder:UpdatePlayerObject - Validation failed after update:", table.concat(errors, ", "))
        end
        
        return playerData
    end, "PlayerDataBuilder:UpdatePlayerObject")
end

--- Get data source priority for player
-- @param playerID string Player name in format "Name-Realm"
-- @return string Best available data source
function PlayerDataBuilder:GetBestDataSource(playerID)
    return NextKey222.SafeRun(function()
        -- Check each data source in priority order
        for _, source in ipairs(DATA_SOURCE_PRIORITY) do
            if self:IsDataSourceAvailable(playerID, source) then
                return source
            end
        end
        
        return "auto-detected" -- Fallback
    end, "PlayerDataBuilder:GetBestDataSource")
end

--- Check if data source is available for player
-- @param playerID string Player name in format "Name-Realm"
-- @param dataSource string Data source to check
-- @return boolean True if data source is available
function PlayerDataBuilder:IsDataSourceAvailable(playerID, dataSource)
    return NextKey222.SafeRun(function()
        if dataSource == "addon" then
            -- Check if player has addon and has responded to survey
            return NextKey222.OrganizerAutoDetection and NextKey222.OrganizerAutoDetection:HasAddon(playerID)
            
        elseif dataSource == "auto-detected" then
            -- Always available for players in group
            return self:FindUnitForPlayer(playerID) ~= nil
            
        elseif dataSource == "temporary" then
            -- Check if character exists in storage
            return NextKey222.CharacterStorage and NextKey222.CharacterStorage:GetCharacter(playerID) ~= nil
        end
        
        return false
    end, "PlayerDataBuilder:IsDataSourceAvailable")
end

--- Test player data builder functionality
function PlayerDataBuilder:Test()
    return NextKey222.SafeRun(function()
        Debug:User("=== Player Data Builder Test ===")
        
        -- Test with current player
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local playerID = playerName .. "-" .. realmName
        
        Debug:User("Testing with player:", playerID)
        
        -- Test different data sources
        local sources = {"addon", "auto-detected", "temporary"}
        
        for _, source in ipairs(sources) do
            Debug:User("Testing data source:", source)
            
            if self:IsDataSourceAvailable(playerID, source) then
                local playerData = self:BuildPlayerObject(playerID, source)
                if playerData then
                    Debug:User("  ✅ Successfully built player object")
                    Debug:User("  Name:", playerData.name)
                    Debug:User("  Class:", playerData.class)
                    Debug:User("  Roles:", table.concat(playerData.roles or {}, ", "))
                    Debug:User("  Data Source:", playerData.dataSource)
                else
                    Debug:User("  ❌ Failed to build player object")
                end
            else
                Debug:User("  ⚠️ Data source not available")
            end
            Debug:User("")
        end
        
        Debug:User("=== Test Complete ===")
    end, "PlayerDataBuilder:Test")
end

-- MARK: Event Handlers
function PlayerDataBuilder:OnEnable()
    -- Register for events if needed
end

function PlayerDataBuilder:OnDisable()
    -- Cleanup if needed
end

return PlayerDataBuilder