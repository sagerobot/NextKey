-- MARK: Module Definition
-- Auto-Detection System for M+ Group Organizer
-- Detects and builds data for non-addon players in group

local _, NextKey222 = ...

local AutoDetection = {}
NextKey222.OrganizerAutoDetection = AutoDetection

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("OrganizerAutoDetection", AutoDetection)

-- MARK: Private Implementation

-- Class to role mappings for auto-detection
local CLASS_ROLES = {
    WARRIOR = {"Tank", "DPS"},
    PALADIN = {"Tank", "Healer", "DPS"},
    HUNTER = {"DPS"},
    ROGUE = {"DPS"},
    PRIEST = {"Healer", "DPS"},
    DEATHKNIGHT = {"Tank", "DPS"},
    SHAMAN = {"Healer", "DPS"},
    MAGE = {"DPS"},
    WARLOCK = {"DPS"},
    MONK = {"Tank", "Healer", "DPS"},
    DRUID = {"Tank", "Healer", "DPS"},
    DEMONHUNTER = {"Tank", "DPS"},
    EVOKER = {"Healer", "DPS"}
}

-- Class utility mappings
local CLASS_UTILITIES = {
    MAGE = {"Lust"},
    SHAMAN = {"Lust", "Brez"},
    HUNTER = {"Brez"},
    WARLOCK = {"Brez"},
    EVOKER = {"Brez"},
    DEATHKNIGHT = {"Brez"},
    PALADIN = {"Brez"},
    PRIEST = {"Brez"},
    DRUID = {"Brez"},
    MONK = {"Brez"},
    WARRIOR = {"Brez"},
    ROGUE = {} -- No combat res
}

-- MARK: Public Interface

--- Initialize Auto Detection module
-- @return boolean True if initialization successful
function AutoDetection:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("autodetect", "OrganizerAutoDetection initialized")
        return true
    end, "AutoDetection:Initialize")
end

--- Scan for non-addon players in current group
-- @return table List of detected non-addon player data
function AutoDetection:ScanForNonAddonPlayers()
    return NextKey222.SafeRun(function()
        local raidSize = GetNumGroupMembers()
        local detectedPlayers = {}
        
        if raidSize == 0 then
            Debug:Dev("autodetect", "Not in a group, no players to scan")
            return detectedPlayers
        end
        
        Debug:Dev("autodetect", "Scanning", raidSize, "players for non-addon users")
        
        for i = 1, raidSize do
            local unit = "raid" .. i
            local name, realm = UnitName(unit)
            if name then
                local fullName = name .. "-" .. (realm or GetRealmName())
                
                -- Check if they have the addon
                if not self:HasAddon(fullName) then
                    local playerData = self:BuildPlayerDataFromAPIs(unit, fullName)
                    if playerData then
                        table.insert(detectedPlayers, playerData)
                        Debug:Dev("autodetect", "Detected non-addon player:", fullName)
                    end
                else
                    Debug:Dev("autodetect", "Player has addon:", fullName)
                end
            end
        end
        
        Debug:Dev("autodetect", "Scan complete. Found", #detectedPlayers, "non-addon players")
        return detectedPlayers
    end, "AutoDetection:ScanForNonAddonPlayers")
end

--- Check if player has NextKey addon
-- @param playerID string Player name in format "Name-Realm"
-- @return boolean True if player has addon
function AutoDetection:HasAddon(playerID)
    return NextKey222.SafeRun(function()
        -- Use existing addon detection from Communications module
        if NextKey222.Communications and NextKey222.Communications.IsPlayerOnline then
            return NextKey222.Communications:IsPlayerOnline(playerID)
        end
        
        -- Fallback: check if we have recent communication from them
        return false
    end, "AutoDetection:HasAddon")
end

--- Build player data from available APIs
-- @param unit string Unit ID (e.g., "raid1")
-- @param fullName string Full player name "Name-Realm"
-- @return table|nil Player data or nil if failed
function AutoDetection:BuildPlayerDataFromAPIs(unit, fullName)
    return NextKey222.SafeRun(function()
        local name, realm = UnitName(unit)
        if not name then return nil end
        
        local class, classFile = UnitClass(unit)
        local level = UnitLevel(unit)
        local specID = GetSpecializationInfo(GetSpecialization() or 1)
        
        -- Build basic player data
        local playerData = {
            id = fullName,
            name = name,
            realm = realm or GetRealmName(),
            class = classFile or "UNKNOWN",
            level = level or 80,
            roles = self:DeriveRoles(classFile, specID),
            utils = self:DeriveUtilities(classFile),
            keystone = self:GetKeystoneFromLibOpenRaid(fullName),
            scores = self:GetScoresFromAPIs(fullName),
            overallScore = self:GetOverallScoreFromAPIs(fullName),
            preferences = {}, -- Cannot know preferences for non-addon users
            
            -- Auto-detected flags
            dataSource = "auto-detected",
            hasAddon = false,
            dataFreshness = "current"
        }
        
        return playerData
    end, "AutoDetection:BuildPlayerDataFromAPIs")
end

--- Derive roles from class and spec
-- @param classFile string Class file token (e.g., "WARRIOR")
-- @param specID number Specialization ID
-- @return table List of available roles
function AutoDetection:DeriveRoles(classFile, specID)
    return NextKey222.SafeRun(function()
        local roles = CLASS_ROLES[classFile] or {"DPS"}
        
        -- If we have spec info, try to be more specific
        if specID and specID > 0 then
            local specRole = GetSpecializationRoleByID(specID)
            if specRole then
                -- Convert to our role format
                if specRole == "TANK" then
                    return {"Tank"}
                elseif specRole == "HEALER" then
                    return {"Healer"}
                elseif specRole == "DAMAGER" then
                    return {"DPS"}
                end
            end
        end
        
        return roles
    end, "AutoDetection:DeriveRoles")
end

--- Derive utilities from class
-- @param classFile string Class file token (e.g., "WARRIOR")
-- @return table List of provided utilities
function AutoDetection:DeriveUtilities(classFile)
    return NextKey222.SafeRun(function()
        return CLASS_UTILITIES[classFile] or {}
    end, "AutoDetection:DeriveUtilities")
end

--- Get keystone data from LibOpenRaid
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Keystone data or nil
function AutoDetection:GetKeystoneFromLibOpenRaid(playerID)
    return NextKey222.SafeRun(function()
        -- Try LibOpenRaid first
        if LibOpenRaid and LibOpenRaid.GetKeystoneInfo then
            local keystoneInfo = LibOpenRaid.GetKeystoneInfo(playerID)
            if keystoneInfo and keystoneInfo.challengeMapId then
                return {
                    dungeonID = keystoneInfo.challengeMapId,
                    level = keystoneInfo.level or 0,
                    ownerID = playerID
                }
            end
        end
        
        return nil
    end, "AutoDetection:GetKeystoneFromLibOpenRaid")
end

--- Get scores from available APIs
-- @param playerID string Player name in format "Name-Realm"
-- @return table Dungeon scores
function AutoDetection:GetScoresFromAPIs(playerID)
    return NextKey222.SafeRun(function()
        local scores = {}
        
        -- Try ProfilesService first (it handles multiple sources)
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            local profile = NextKey222.ProfilesService:GetProfile(playerID)
            if profile and profile.dungeonScores then
                scores = profile.dungeonScores
            end
        end
        
        -- Fallback: try direct RaiderIO if available
        if not next(scores) and RaiderIO then
            local name, realm = strsplit("-", playerID)
            if RaiderIO.GetProfile then
                local rioProfile = RaiderIO.GetProfile(name, realm)
                if rioProfile and rioProfile.mythicKeystoneProfile then
                    local dungeonScores = rioProfile.mythicKeystoneProfile.dungeonScores
                    if dungeonScores then
                        -- Convert RaiderIO format to our format
                        for _, scoreData in ipairs(dungeonScores) do
                            if scoreData.mapChallengeModeID and scoreData.score then
                                scores[scoreData.mapChallengeModeID] = scoreData.score
                            end
                        end
                    end
                end
            end
        end
        
        return scores
    end, "AutoDetection:GetScoresFromAPIs")
end

--- Get overall score from available APIs
-- @param playerID string Player name in format "Name-Realm"
-- @return number Overall score
function AutoDetection:GetOverallScoreFromAPIs(playerID)
    return NextKey222.SafeRun(function()
        -- Try ProfilesService first
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            local profile = NextKey222.ProfilesService:GetProfile(playerID)
            if profile and profile.io then
                return profile.io
            end
        end
        
        -- Fallback: try direct RaiderIO
        local name, realm = strsplit("-", playerID)
        if RaiderIO and RaiderIO.GetProfile then
            local rioProfile = RaiderIO.GetProfile(name, realm)
            if rioProfile and rioProfile.mythicKeystoneProfile then
                return rioProfile.mythicKeystoneProfile.currentScore or 0
            end
        end
        
        -- Fallback: try Blizzard API
        if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
            local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(name)
            if summary and summary.currentSeasonScore then
                return summary.currentSeasonScore
            end
        end
        
        return 0
    end, "AutoDetection:GetOverallScoreFromAPIs")
end

--- Test auto-detection functionality
function AutoDetection:TestScan()
    return NextKey222.SafeRun(function()
        Debug:User("=== Auto-Detection Test ===")
        
        local detectedPlayers = self:ScanForNonAddonPlayers()
        
        Debug:User("Found", #detectedPlayers, "non-addon players:")
        
        for i, player in ipairs(detectedPlayers) do
            Debug:User(string.format("[%d] %s - %s (Level %d)", 
                i, 
                player.name, 
                player.class,
                player.level or 0
            ))
            Debug:User("  Roles:", table.concat(player.roles or {}, ", "))
            Debug:User("  Utilities:", table.concat(player.utils or {}, ", "))
            
            if player.keystone then
                Debug:User("  Keystone:", player.keystone.level, "DungeonID:", player.keystone.dungeonID)
            else
                Debug:User("  Keystone: None detected")
            end
            
            Debug:User("  Overall Score:", player.overallScore)
            Debug:User("  Data Source:", player.dataSource)
            Debug:User("")
        end
        
        Debug:User("=== Test Complete ===")
        return detectedPlayers
    end, "AutoDetection:TestScan")
end

--- Get class information for a unit
-- @param unit string Unit ID
-- @return table Class information
function AutoDetection:GetClassInfo(unit)
    return NextKey222.SafeRun(function()
        local class, classFile = UnitClass(unit)
        return {
            name = class,
            file = classFile,
            roles = CLASS_ROLES[classFile] or {"DPS"},
            utilities = CLASS_UTILITIES[classFile] or {}
        }
    end, "AutoDetection:GetClassInfo")
end

--- Update auto-detection data for all players in group
-- @return table Updated player data
function AutoDetection:UpdateGroupData()
    return NextKey222.SafeRun(function()
        local groupData = {}
        local raidSize = GetNumGroupMembers()
        
        if raidSize == 0 then
            Debug:Dev("autodetect", "Not in a group")
            return groupData
        end
        
        for i = 1, raidSize do
            local unit = "raid" .. i
            local name, realm = UnitName(unit)
            if name then
                local fullName = name .. "-" .. (realm or GetRealmName())
                local playerData
                
                if self:HasAddon(fullName) then
                    -- Get data from addon user
                    playerData = self:GetAddonPlayerData(fullName)
                else
                    -- Build data from APIs
                    playerData = self:BuildPlayerDataFromAPIs(unit, fullName)
                end
                
                if playerData then
                    table.insert(groupData, playerData)
                end
            end
        end
        
        Debug:Dev("autodetect", "Updated group data for", #groupData, "players")
        return groupData
    end, "AutoDetection:UpdateGroupData")
end

--- Get player data for addon user
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Player data or nil
function AutoDetection:GetAddonPlayerData(playerID)
    return NextKey222.SafeRun(function()
        -- Try to get data from ProfilesService for addon users
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            local profile = NextKey222.ProfilesService:GetProfile(playerID)
            if profile then
                return {
                    id = playerID,
                    name = profile.name,
                    realm = profile.realm or GetRealmName(),
                    class = profile.class,
                    level = profile.level or 80,
                    roles = self:GetPlayerRoles(playerID),
                    utils = profile.capabilities or {},
                    keystone = self:GetPlayerKeystone(playerID),
                    scores = profile.dungeonScores or {},
                    overallScore = profile.io or 0,
                    preferences = self:GetPlayerPreferences(playerID),
                    
                    -- Addon user flags
                    dataSource = "addon",
                    hasAddon = true,
                    dataFreshness = "current"
                }
            end
        end
        
        return nil
    end, "AutoDetection:GetAddonPlayerData")
end

--- Get player roles from character storage
-- @param playerID string Player name in format "Name-Realm"
-- @return table Available roles
function AutoDetection:GetPlayerRoles(playerID)
    return NextKey222.SafeRun(function()
        if NextKey222.CharacterStorage and NextKey222.CharacterStorage.GetAvailableRoles then
            return NextKey222.CharacterStorage:GetAvailableRoles(playerID)
        end
        
        return {}
    end, "AutoDetection:GetPlayerRoles")
end

--- Get player keystone data
-- @param playerID string Player name in format "Name-Realm"
-- @return table|nil Keystone data
function AutoDetection:GetPlayerKeystone(playerID)
    return NextKey222.SafeRun(function()
        -- Try multiple sources for keystone data
        return self:GetKeystoneFromLibOpenRaid(playerID)
    end, "AutoDetection:GetPlayerKeystone")
end

--- Get player preferences
-- @param playerID string Player name in format "Name-Realm"
-- @return table Player preferences
function AutoDetection:GetPlayerPreferences(playerID)
    return NextKey222.SafeRun(function()
        -- Try to get preferences from config
        if NextKey222.Config and NextKey222.Config.GetPreferences then
            return NextKey222.Config:GetPreferences(playerID)
        end
        
        return {}
    end, "AutoDetection:GetPlayerPreferences")
end

-- MARK: Event Handlers
function AutoDetection:OnEnable()
    -- Register for events if needed
end

function AutoDetection:OnDisable()
    -- Cleanup if needed
end

return AutoDetection