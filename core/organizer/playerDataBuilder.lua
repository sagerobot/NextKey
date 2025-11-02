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
print("[TEMP DEBUG] NextKey222.Debug exists:", NextKey222.Debug ~= nil)

-- MARK: Private Implementation

-- Data source priority order
local DATA_SOURCE_PRIORITY = {
    "addon",        -- Survey responses from addon users
    "auto-detected", -- API data for non-addon users
    "temporary"      -- Alt character data from character storage
}

-- MARK: Public Interface

--- Generate default spec preferences based on player's current spec
-- Used for players who haven't responded to a poll yet
-- @param playerID string Player name in format "Name-Realm"
-- @return table, table specPreferences and specDetails tables
function PlayerDataBuilder:GenerateDefaultSpecPreferences(playerID)
    return NextKey222.SafeRun(function()
        print("[TRACE 1] GenerateDefaultSpecPreferences START for:", playerID)
        Debug:Dev("organizer", "=== GenerateDefaultSpecPreferences called for:", playerID)
        
        print("[TRACE 2] About to create empty tables")
        local specPreferences = {}
        local specDetails = {}
        print("[TRACE 3] Empty tables created successfully")
        
        -- ALWAYS use WoW API to get ALL specs for player's class
        -- CharacterStorage may not have fake players, so skip it entirely
        print("[TRACE 4] About to create availableSpecs table")
        local availableSpecs = {}
        
        print("[TRACE 5] About to call GetProfile for:", playerID)
        local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(playerID)
        print("[TRACE 6] GetProfile returned, profile exists:", profile ~= nil)
        if profile and profile.class then
            print("[TRACE 7] Profile has class:", profile.class)
            Debug:Dev("organizer", "Got profile for", playerID, "- class:", profile.class)
                
  -- Get class ID for API call
  print("[TRACE 8] About to call GetNumClasses()")
  local numClasses = GetNumClasses()
  print("[TRACE 9] GetNumClasses() returned:", numClasses)
  
  local classID = nil
  for i = 1, numClasses do
   print("[TRACE 10] Loop iteration:", i)
   local className, classToken = GetClassInfo(i)
   print("[TRACE 11] GetClassInfo returned:", className, classToken)
        			if classToken == profile.class then
        				classID = i
        				print("[TRACE 12] Found matching class! classID:", classID)
        			                      Debug:Dev("organizer", "Found classID:", classID, "for", profile.class)
        				break
        			  end
        			  end
        			
        		print("[TRACE 13] Loop complete. classID:", classID)
        			  	
        			  if classID then
        			  	print("[TRACE 14] classID exists, about to call GetNumSpecializationsForClassID")
        			  	-- Query ALL specializations for this class
        			  	print("[TRACE 15] Calling GetNumSpecializationsForClassID with classID:", classID)
        			  	local numSpecs = GetNumSpecializationsForClassID(classID)
        			  	print("[TRACE 16] GetNumSpecializationsForClassID returned:", numSpecs)
        			      Debug:Dev("organizer", "Class has", numSpecs, "specializations")
        			      
        			   print("[TRACE 17] About to start specs loop, numSpecs:", numSpecs)
        			   for i = 1, numSpecs do
        			    print("[TRACE 18] Specs loop iteration:", i)
        			    local specID, specName, _, iconTexture, role = GetSpecializationInfoForClassID(classID, i)
        			    print("[TRACE 19] GetSpecializationInfoForClassID returned:", specID, specName, role)
        			    if specID then
        			  			table.insert(availableSpecs, {
        			  				specID = specID,
        			  				specName = specName,
        			  				role = role,
        			  				iconTexture = iconTexture
        			  			})
        			  			
        			  			Debug:Dev("organizer", "Found spec via WoW API:", specName, "role:", role, "for", playerID)
        			  		end
        			  	end
        			  else
        			      Debug:Error("Could not find classID for class:", profile.class)
        			  end
        	else
        			  Debug:Error("No profile found for:", playerID)
        	end
        
        -- Get player's current role to identify primary spec
        local currentRole = nil
        local profileForRole = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(playerID)
        if profileForRole then
            currentRole = profileForRole.role
            Debug:Dev("organizer", "Player", playerID, "current role:", currentRole)
        end
        
        -- Generate preferences: current spec = "play", others = "none"
        -- Use priority mapping to handle multiple specs per role
        local priorityMap = { play = 3, fill = 2, none = 1 }
        
        for _, specInfo in ipairs(availableSpecs) do
            local preference = "none"
            
            -- CRITICAL: Normalize role to uppercase for consistent keying
            local normalizedRole = specInfo.role and specInfo.role:upper() or "DAMAGER"
            local normalizedCurrentRole = currentRole and currentRole:upper() or "DAMAGER"
            
            -- If this spec matches the player's current role, mark as "play"
            if normalizedRole == normalizedCurrentRole then
                preference = "play"
                Debug:Dev("organizer", "Marking", specInfo.specName, "as 'play' for", playerID)
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
            if preference ~= "none" then
                local currentPriority = priorityMap[specPreferences[normalizedRole]] or 0
                local newPriority = priorityMap[preference] or 0
                
                if newPriority > currentPriority then
                    specPreferences[normalizedRole] = preference
                end
            end
        end
        
        print("[TRACE 20] About to call Debug:Dev for summary")
        Debug:Dev("organizer", "Generated spec preferences for", playerID, ":",
                  "specPrefs has data:", next(specPreferences) ~= nil,
                  "specDetails has data:", next(specDetails) ~= nil)
        
        print("[TRACE 21] About to check if specDetails has data")
        -- Log the actual contents for debugging
        if next(specDetails) then
            print("[TRACE 22] specDetails has data, about to iterate")
            for role, specs in pairs(specDetails) do
                print("[TRACE 23] Role:", role, "has", #specs, "specs")
                Debug:Dev("organizer", "  Role", role, "has", #specs, "specs")
            end
            print("[TRACE 24] Finished iterating specDetails")
        else
            print("[TRACE 25] specDetails is EMPTY!")
            Debug:Error("specDetails is EMPTY for", playerID)
        end
        
        print("[TRACE 26] About to return specPreferences and specDetails")
        print("[TRACE 27] specPreferences contents:", specPreferences and "EXISTS" or "NIL")
        if specPreferences then
            for k, v in pairs(specPreferences) do
                print("[TRACE 28] specPreferences[" .. tostring(k) .. "] =", tostring(v))
            end
        end
        print("[TRACE 29] specDetails contents:", specDetails and "EXISTS" or "NIL")
        if specDetails then
            for k, v in pairs(specDetails) do
                print("[TRACE 30] specDetails[" .. tostring(k) .. "] = table with", #v, "specs")
            end
        end
        print("[TRACE 31] RETURNING NOW")
        local returnVal1, returnVal2 = specPreferences, specDetails
        print("[TRACE 32] returnVal1 type:", type(returnVal1), "returnVal2 type:", type(returnVal2))
        return returnVal1, returnVal2
    end, "PlayerDataBuilder:GenerateDefaultSpecPreferences")
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
            local defaultSpecPrefs, defaultSpecDetails = self:GenerateDefaultSpecPreferences(playerID)
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