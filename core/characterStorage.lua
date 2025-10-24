-- MARK: Module Definition
-- Character Storage for M+ Group Organizer
-- Handles account-wide character data storage with AceDB profile integration

local _, NextKey222 = ...

local CharacterStorage = {}
NextKey222.CharacterStorage = CharacterStorage

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("CharacterStorage", CharacterStorage)

-- MARK: Private Implementation
local DATA_VERSION = 1

-- Server reset times by region (UTC hour:minute)
local SERVER_RESET_TIMES = {
    US = { day = 3, hour = 15, minute = 0 },    -- Tuesday 15:00 UTC
    EU = { day = 4, hour = 7, minute = 0 },     -- Wednesday 07:00 UTC
    KR = { day = 4, hour = 7, minute = 0 },     -- Wednesday 07:00 UTC
    TW = { day = 4, hour = 7, minute = 0 },     -- Wednesday 07:00 UTC
    CN = { day = 4, hour = 7, minute = 0 }      -- Wednesday 07:00 UTC
}

-- MARK: Public Interface

--- Initialize Character Storage module
-- @return boolean True if initialization successful
function CharacterStorage:Initialize()
    return NextKey222.SafeRun(function()
        -- Initialize profile namespace if missing
        if not self.db.profile.characters then
            self.db.profile.characters = {}
            Debug:Dev("storage", "Initialized character storage")
        end
        
        -- Initialize data version tracking
        if not self.db.profile.characterDataVersion then
            self.db.profile.characterDataVersion = DATA_VERSION
        end
        
        -- Migrate existing character data if needed
        self:MigrateExistingData()
        
        Debug:Dev("storage", "CharacterStorage initialized successfully")
        return true
    end, "CharacterStorage:Initialize")
end

--- Get character data by ID
-- @param characterID string Character name in format "Name-Realm"
-- @return table|nil Character data or nil if not found
function CharacterStorage:GetCharacter(characterID)
    return NextKey222.SafeRun(function()
        if not characterID then return nil end
        return self.db.profile.characters[characterID]
    end, "CharacterStorage:GetCharacter")
end

--- Save or update character data
-- @param characterID string Character name in format "Name-Realm"
-- @param characterData table Character data to save
-- @return boolean True if save successful
function CharacterStorage:SaveCharacter(characterID, characterData)
    return NextKey222.SafeRun(function()
        if not characterID or not characterData then
            Debug:Error("CharacterStorage:SaveCharacter - Invalid parameters")
            return false
        end
        
        -- Validate required fields
        if not characterData.name or not characterData.realm or not characterData.class then
            Debug:Error("CharacterStorage:SaveCharacter - Missing required fields")
            return false
        end
        
        -- Update timestamp
        characterData.lastSeen = time()
        characterData.dataVersion = DATA_VERSION
        
        -- Save to database
        self.db.profile.characters[characterID] = characterData
        
        Debug:Dev("storage", "Saved character data for:", characterID)
        return true
    end, "CharacterStorage:SaveCharacter")
end

--- Get all characters in storage
-- @return table All character data indexed by characterID
function CharacterStorage:GetAllCharacters()
    return NextKey222.SafeRun(function()
        return self.db.profile.characters or {}
    end, "CharacterStorage:GetAllCharacters")
end

--- Remove character from storage
-- @param characterID string Character name in format "Name-Realm"
-- @return boolean True if removal successful
function CharacterStorage:RemoveCharacter(characterID)
    return NextKey222.SafeRun(function()
        if not characterID then return false end
        
        if self.db.profile.characters[characterID] then
            self.db.profile.characters[characterID] = nil
            Debug:Dev("storage", "Removed character:", characterID)
            return true
        end
        
        return false
    end, "CharacterStorage:RemoveCharacter")
end

--- Set character role availability
-- @param characterID string Character name in format "Name-Realm"
-- @param role string Role name ("Tank", "Healer", "DPS")
-- @param available boolean Whether role is available
-- @return boolean True if update successful
function CharacterStorage:SetRole(characterID, role, available)
    return NextKey222.SafeRun(function()
        if not characterID or not role then return false end
        
        local character = self:GetCharacter(characterID)
        if not character then
            Debug:Error("CharacterStorage:SetRole - Character not found:", characterID)
            return false
        end
        
        -- Initialize roles if needed
        character.availableRoles = character.availableRoles or {}
        
        -- Update role availability
        character.availableRoles[role] = available
        character.lastSeen = time()
        
        Debug:Dev("storage", "Updated role for", characterID, ":", role, "=", available)
        return true
    end, "CharacterStorage:SetRole")
end

--- Get character role availability
-- @param characterID string Character name in format "Name-Realm"
-- @return table Available roles for character
function CharacterStorage:GetAvailableRoles(characterID)
    return NextKey222.SafeRun(function()
        local character = self:GetCharacter(characterID)
        if not character then return {} end
        
        return character.availableRoles or {}
    end, "CharacterStorage:GetAvailableRoles")
end

--- Check if keystone data is stale (expired after Tuesday reset)
-- @param characterID string Character name in format "Name-Realm"
-- @return boolean True if keystone data is stale
function CharacterStorage:IsKeystoneDataStale(characterID)
    return NextKey222.SafeRun(function()
        local character = self:GetCharacter(characterID)
        if not character or not character.currentKeystone then
            return true -- No data = stale
        end
        
        local lastReset = self:GetLastServerReset()
        return (character.currentKeystone.lastUpdated or 0) < lastReset
    end, "CharacterStorage:IsKeystoneDataStale")
end

--- Get last server reset time for current region
-- @return number Unix timestamp of last server reset
function CharacterStorage:GetLastServerReset()
    return NextKey222.SafeRun(function()
        local currentTime = time()
        local region = self:GetCurrentRegion()
        local resetTime = SERVER_RESET_TIMES[region] or SERVER_RESET_TIMES.US
        
        -- Calculate last reset day
        local lastResetTime = currentTime
        local currentDay = date("*t", currentTime).wday -- 1=Sunday, 3=Tuesday
        
        -- Convert to our day format (3=Tuesday)
        local resetDay = resetTime.day
        
        -- Calculate days since last reset
        local daysSinceReset = (currentDay - resetDay + 7) % 7
        
        -- Subtract days since reset to get last reset time
        lastResetTime = currentTime - (daysSinceReset * 24 * 60 * 60)
        
        -- Set the reset time (hour/minute)
        local resetDate = date("*t", lastResetTime)
        resetDate.hour = resetTime.hour
        resetDate.min = resetTime.minute
        resetDate.sec = 0
        
        return time(resetDate)
    end, "CharacterStorage:GetLastServerReset")
end

--- Get current server region
-- @return string Region code (US, EU, KR, TW, CN)
function CharacterStorage:GetCurrentRegion()
    return NextKey222.SafeRun(function()
        -- Use Blizzard API to get region
        local region = GetCurrentRegion()
        
        -- Map region constants to our codes
        local regionMap = {
            [1] = "US",
            [2] = "KR", 
            [3] = "EU",
            [4] = "TW",
            [5] = "CN"
        }
        
        return regionMap[region] or "US"
    end, "CharacterStorage:GetCurrentRegion")
end

--- Create temporary player card for alt character
-- @param altCharacterID string Alt character name in format "Name-Realm"
-- @param sourceCharacterID string Source character who selected the alt
-- @return table Temporary player object
function CharacterStorage:CreateTemporaryPlayerCard(altCharacterID, sourceCharacterID)
    return NextKey222.SafeRun(function()
        local altData = self:GetCharacter(altCharacterID)
        if not altData then
            error("Alt character data not found: " .. altCharacterID)
        end
        
        -- Clone alt's data
        local tempPlayer = {
            id = altCharacterID .. "_TEMP", -- Unique temporary ID
            name = altData.name,
            realm = altData.realm,
            class = altData.class,
            level = altData.level or 80,
            roles = self:DeriveRoles(altData),
            utils = altData.utilities or {},
            keystone = altData.currentKeystone,
            scores = altData.dungeonScores or {},
            overallScore = altData.overallScore or 0,
            preferences = {}, -- Use source character's preferences
            
            -- Temporary flags
            isTemporary = true,
            sourceCharacter = sourceCharacterID,
            dataSource = "temporary",
            dataFreshness = self:CheckDataFreshness(altData)
        }
        
        Debug:Dev("organizer", "Created temporary player card for", altCharacterID)
        return tempPlayer
    end, "CharacterStorage:CreateTemporaryPlayerCard")
end

--- Derive roles from character data
-- @param characterData table Character data
-- @return table List of available roles
function CharacterStorage:DeriveRoles(characterData)
    return NextKey222.SafeRun(function()
        local roles = {}
        
        -- Use configured roles if available
        if characterData.availableRoles then
            for role, available in pairs(characterData.availableRoles) do
                if available then
                    table.insert(roles, role)
                end
            end
        end
        
        -- Fallback to class-based role derivation
        if #roles == 0 and characterData.class then
            local classRoles = self:GetClassRoles(characterData.class)
            roles = classRoles
        end
        
        return roles
    end, "CharacterStorage:DeriveRoles")
end

--- Get default roles for a class
-- @param class string WoW class token
-- @return table List of default roles for class
function CharacterStorage:GetClassRoles(class)
    return NextKey222.SafeRun(function()
        local classRoles = {
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
        
        return classRoles[class] or {"DPS"}
    end, "CharacterStorage:GetClassRoles")
end

--- Check data freshness for character
-- @param characterData table Character data
-- @return string Freshness status ("current", "stale", "unknown")
function CharacterStorage:CheckDataFreshness(characterData)
    return NextKey222.SafeRun(function()
        if not characterData then return "unknown" end
        
        local lastSeen = characterData.lastSeen or 0
        local currentTime = time()
        local hoursSinceSeen = (currentTime - lastSeen) / 3600
        
        if hoursSinceSeen < 24 then
            return "current"
        elseif hoursSinceSeen < 168 then -- 7 days
            return "stale"
        else
            return "unknown"
        end
    end, "CharacterStorage:CheckDataFreshness")
end

--- Migrate existing character data from older versions
function CharacterStorage:MigrateExistingData()
    return NextKey222.SafeRun(function()
        local currentVersion = self.db.profile.characterDataVersion or 0
        
        if currentVersion < DATA_VERSION then
            Debug:Dev("storage", "Migrating character data from version", currentVersion, "to", DATA_VERSION)
            
            -- Add migration logic here as needed
            -- For now, just update the version
            self.db.profile.characterDataVersion = DATA_VERSION
            
            Debug:Dev("storage", "Character data migration completed")
        end
    end, "CharacterStorage:MigrateExistingData")
end

--- Debug print all characters
function CharacterStorage:DebugPrintAllCharacters()
    return NextKey222.SafeRun(function()
        local characters = self:GetAllCharacters()
        local count = 0
        
        Debug:User("=== Character Storage Debug ===")
        
        for characterID, characterData in pairs(characters) do
            count = count + 1
            Debug:User(string.format("[%d] %s - %s (%s)", 
                count, 
                characterData.name, 
                characterData.class,
                characterData.realm or "Unknown"
            ))
            
            if characterData.availableRoles then
                local roles = {}
                for role, available in pairs(characterData.availableRoles) do
                    if available then
                        table.insert(roles, role)
                    end
                end
                Debug:User("  Roles:", table.concat(roles, ", "))
            end
            
            if characterData.currentKeystone then
                Debug:User("  Keystone:", characterData.currentKeystone.level, 
                    "DungeonID:", characterData.currentKeystone.dungeonID)
            end
            
            if characterData.overallScore then
                Debug:User("  Overall Score:", characterData.overallScore)
            end
            
            Debug:User("  Data Freshness:", self:CheckDataFreshness(characterData))
            Debug:User("  Keystone Stale:", self:IsKeystoneDataStale(characterID) and "Yes" or "No")
            Debug:User("")
        end
        
        Debug:User("=== Total Characters:", count, "===")
    end, "CharacterStorage:DebugPrintAllCharacters")
end

-- MARK: Module Database Reference
-- This will be set during initialization
CharacterStorage.db = nil

-- MARK: Event Handlers
function CharacterStorage:OnEnable()
    -- Register for events if needed
end

function CharacterStorage:OnDisable()
    -- Cleanup if needed
end

return CharacterStorage