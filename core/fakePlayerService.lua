-- MARK: Fake Player Service
-- Centralized service for all fake/test player operations
-- Provides a clean API that returns standard PlayerProfile objects
-- Following NextKey222 architectural patterns

local _, NextKey222 = ...

-- MARK: Module Definition
local FakePlayerService = {}
NextKey222.FakePlayerService = FakePlayerService

-- Register with module system
NextKey222.RegisterModule("FakePlayerService", FakePlayerService)

-- MARK: Module State
local isInitialized = false
local fakePlayerStorage = {}  -- In-memory storage, indexed by player name
local playerIDCounter = 0
local defaultRealm = "TestRealm"

-- MARK: Constants
local VALID_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT",
    "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER"
}

local SKILL_TIERS = {
    elite = { baseLevel = {28, 30}, timingChance = 0.95 },
    expert = { baseLevel = {22, 27}, timingChance = 0.85 },
    skilled = { baseLevel = {16, 21}, timingChance = 0.70 },
    average = { baseLevel = {10, 15}, timingChance = 0.50 },
    casual = { baseLevel = {6, 9}, timingChance = 0.30 },
    beginner = { baseLevel = {2, 5}, timingChance = 0.15 }
}

local PRESET_CONFIGS = {
    mixed_skill = {
        { tier = "expert", addon = { nextkey = true, raiderio = true } },
        { tier = "skilled", addon = { nextkey = true, raiderio = true } },
        { tier = "average", addon = { nextkey = false, raiderio = true } },
        { tier = "casual", addon = { nextkey = false, raiderio = false } }
    },
    beginner = {
        { tier = "beginner", addon = { nextkey = false, raiderio = false } },
        { tier = "casual", addon = { nextkey = false, raiderio = false } },
        { tier = "casual", addon = { nextkey = false, raiderio = true } },
        { tier = "average", addon = { nextkey = true, raiderio = true } }
    },
    expert = {
        { tier = "elite", addon = { nextkey = true, raiderio = true } },
        { tier = "expert", addon = { nextkey = true, raiderio = true } },
        { tier = "expert", addon = { nextkey = true, raiderio = true } },
        { tier = "skilled", addon = { nextkey = true, raiderio = true } }
    },
    high_keys = {
        { tier = "elite", addon = { nextkey = true, raiderio = true } },
        { tier = "elite", addon = { nextkey = true, raiderio = true } },
        { tier = "expert", addon = { nextkey = true, raiderio = true } },
        { tier = "expert", addon = { nextkey = true, raiderio = true } }
    }
}

-- MARK: Utility Functions
local function generatePlayerID()
    playerIDCounter = playerIDCounter + 1
    return playerIDCounter
end

local function normalizePlayerName(name)
    if not name then return nil end
    -- Ensure realm is present
    if not name:match("%-") then
        return name .. "-" .. defaultRealm
    end
    return name
end

local function getRandomClass()
    return VALID_CLASSES[math.random(1, #VALID_CLASSES)]
end

local function getRandomTier()
    local rand = math.random()
    if rand < 0.05 then return "elite"
    elseif rand < 0.15 then return "expert"
    elseif rand < 0.35 then return "skilled"
    elseif rand < 0.70 then return "average"
    elseif rand < 0.90 then return "casual"
    else return "beginner" end
end

local function calculateScoreForRun(level, timed, chests)
    if NextKey222.IOCalculator and NextKey222.IOCalculator.EstimateRunScore then
        local fractionalTime = timed and (0.9 - (chests * 0.1)) or nil
        return NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
    else
        -- Fallback calculation
        local baseScore = math.max(0, (level - 1) * 10)
        local bonus = timed and (chests * 5) or 0
        return baseScore + bonus
    end
end

-- MARK: Core Storage Access
local function getStorage()
    -- Return in-memory storage for now
    -- Future: Could load from SavedVariables or JSON
    return fakePlayerStorage
end

local function saveToStorage(playerName, playerData)
    fakePlayerStorage[playerName] = playerData
    
    -- Fire custom event for cache invalidation
    NextKey222.SafeRun(function()
        if NextKey222.Addon then
            NextKey222.Addon:SendMessage("NEXTKEY_FAKE_PLAYER_UPDATED", playerName)
        end
    end, "FakePlayerService:SaveToStorage:SendMessage")
end

local function removeFromStorage(playerName)
    fakePlayerStorage[playerName] = nil
    
    -- Fire custom event
    NextKey222.SafeRun(function()
        if NextKey222.Addon then
            NextKey222.Addon:SendMessage("NEXTKEY_FAKE_PLAYER_REMOVED", playerName)
        end
    end, "FakePlayerService:RemoveFromStorage:SendMessage")
end

-- MARK: Player Generation Logic
local function generateDungeonScores(tier, dungeonIDs)
    local scores = {}
    local tierConfig = SKILL_TIERS[tier] or SKILL_TIERS.average
    local baseLevel = math.random(tierConfig.baseLevel[1], tierConfig.baseLevel[2])
    
    for _, dungeonID in ipairs(dungeonIDs) do
        -- Add variation per dungeon
        local variation = math.random(-3, 3)
        local level = math.max(2, baseLevel + variation)
        
        -- Determine if timed
        local timingChance = tierConfig.timingChance
        local levelPenalty = math.max(0, (level - 15) * 0.02)
        local timed = math.random() < (timingChance - levelPenalty)
        
        -- Determine chests for timed runs
        local chests = 0
        if timed then
            local skillBonus = (tierConfig.timingChance - 0.15) * 2  -- Scale skill bonus
            local chestRand = math.random()
            if chestRand < 0.1 + skillBonus then chests = 3
            elseif chestRand < 0.3 + skillBonus then chests = 2
            elseif chestRand < 0.6 + skillBonus then chests = 1
            end
        end
        
        -- Calculate score
        local score = calculateScoreForRun(level, timed, chests)
        
        scores[dungeonID] = {
            level = level,
            chests = chests,
            timed = timed,
            score = score,
            dataSource = "fake_generated"
        }
    end
    
    return scores
end

local function generateKeystone(dungeonIDs, dungeonScores, baseLevel)
    if not dungeonIDs or #dungeonIDs == 0 then
        return nil
    end
    
    -- Select random dungeon
    local dungeonID = dungeonIDs[math.random(#dungeonIDs)]
    
    -- Key level based on player's performance
    local keyLevel = baseLevel
    if dungeonScores[dungeonID] then
        keyLevel = math.max(2, dungeonScores[dungeonID].level + math.random(-2, 1))
    end
    
    return {
        dungeonID = dungeonID,
        level = keyLevel
    }
end

local function determineAddonStatus(index, addonMix)
    if addonMix then
        -- Use provided configuration
        local total = (addonMix.nextkey or 0) + (addonMix.raiderio or 0) + (addonMix.none or 0)
        if index <= (addonMix.nextkey or 0) then
            return { nextkey = true, raiderio = true }
        elseif index <= (addonMix.nextkey or 0) + (addonMix.raiderio or 0) then
            return { nextkey = false, raiderio = true }
        else
            return { nextkey = false, raiderio = false }
        end
    else
        -- Default realistic distribution
        local rand = math.random()
        if rand < 0.3 then return { nextkey = true, raiderio = true }
        elseif rand < 0.8 then return { nextkey = false, raiderio = true }
        else return { nextkey = false, raiderio = false }
        end
    end
end

local function calculateTotalIO(dungeonScores)
    local total = 0
    for _, scoreData in pairs(dungeonScores) do
        total = total + (scoreData.score or 0)
    end
    return total
end

-- MARK: Public API - Player Management

--- Initializes the fake player service
-- @return boolean Success status
function FakePlayerService:Initialize()
    if isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Already initialized")
        return true
    end
    
    NextKey222.Debug:Dev("startup", "FakePlayerService initializing...")
    
    local success = NextKey222.SafeRun(function()
        -- Initialize storage
        fakePlayerStorage = {}
        playerIDCounter = 0
        
        -- Get realm name for generating player names
        if GetRealmName then
            defaultRealm = GetRealmName() or "TestRealm"
        end
        
        -- Set up event listeners for cache invalidation
        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            -- Register for our custom messages
            NextKey222.Addon:RegisterMessage("NEXTKEY_FAKE_PLAYER_UPDATED", function(event, playerName)
                if NextKey222.ProfilesService then
                    NextKey222.ProfilesService:InvalidateCache(playerName)
                end
            end)
            
            NextKey222.Addon:RegisterMessage("NEXTKEY_FAKE_PLAYER_REMOVED", function(event, playerName)
                if NextKey222.ProfilesService then
                    NextKey222.ProfilesService:InvalidateCache(playerName)
                end
            end)
        end
        
        isInitialized = true
        return true
    end, "FakePlayerService:Initialize")
    
    NextKey222.Debug:Dev("startup", "FakePlayerService initialization", success and "successful" or "failed")
    return success
end

--- Creates a new fake player with the specified configuration
-- @param config table Configuration for the player
--   - name: string (optional) Player name, auto-generated if not provided
--   - class: string (optional) Player class token, random if not provided
--   - tier: string (optional) Skill tier (elite, expert, skilled, average, casual, beginner)
--   - io: number (optional) Total IO score, calculated if not provided
--   - addonStatus: table (optional) { nextkey = bool, raiderio = bool }
--   - keystoneLevel: number (optional) Level of keystone to generate
--   - keystoneDungeon: number (optional) Specific dungeon ID for keystone
-- @return string|nil Player name if created, nil on failure
function FakePlayerService:CreatePlayer(config)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return nil
    end
    
    config = config or {}
    
    return NextKey222.SafeRun(function()
        -- Generate player name with realm
        local playerID = generatePlayerID()
        local playerName = config.name or ("FakePlayer" .. playerID)
        playerName = normalizePlayerName(playerName)
        
        -- Validate no duplicate
        if fakePlayerStorage[playerName] then
            NextKey222.Debug:Dev("fakeplayerservice", "Player already exists:", playerName)
            return nil
        end
        
        -- Get active season dungeons
        local dungeonIDs = {}
        if NextKey222.Addon and NextKey222.Addon.GetActiveSeasonDungeonIDs then
            dungeonIDs = NextKey222.Addon:GetActiveSeasonDungeonIDs() or {}
        end
        
        if #dungeonIDs == 0 then
            NextKey222.Debug:Dev("fakeplayerservice", "Warning: No dungeon IDs available for fake player generation")
        end
        
        -- Determine tier
        local tier = config.tier or getRandomTier()
        local tierConfig = SKILL_TIERS[tier] or SKILL_TIERS.average
        local baseLevel = math.random(tierConfig.baseLevel[1], tierConfig.baseLevel[2])
        
        -- Generate dungeon scores
        local dungeonScores = {}
        if #dungeonIDs > 0 then
            dungeonScores = generateDungeonScores(tier, dungeonIDs)
        end
        
        -- Generate or use provided keystone
        local keystone = nil
        if config.keystoneDungeon and config.keystoneLevel then
            keystone = {
                dungeonID = config.keystoneDungeon,
                level = config.keystoneLevel
            }
        elseif #dungeonIDs > 0 then
            keystone = generateKeystone(dungeonIDs, dungeonScores, baseLevel)
        end
        
        -- Create player data structure
        local playerData = {
            id = playerID,
            name = playerName,
            class = config.class or getRandomClass(),
            tier = tier,
            dungeonScores = dungeonScores,
            keystone = keystone,
            addonStatus = config.addonStatus or { nextkey = false, raiderio = false },
            io = config.io or calculateTotalIO(dungeonScores),
            createdAt = GetTime(),
            dataSource = "fake_player_service"
        }
        
        -- Save to storage
        saveToStorage(playerName, playerData)
        
        NextKey222.Debug:Dev("fakeplayerservice", "Created fake player:", playerName, "class:", playerData.class, "tier:", tier, "IO:", playerData.io)
        
        return playerName
    end, "FakePlayerService:CreatePlayer")
end

--- Removes a fake player
-- @param playerName string The player name to remove
-- @return boolean Success status
function FakePlayerService:RemovePlayer(playerName)
    if not isInitialized then return false end
    
    playerName = normalizePlayerName(playerName)
    
    return NextKey222.SafeRun(function()
        if not fakePlayerStorage[playerName] then
            NextKey222.Debug:Dev("fakeplayerservice", "Player not found:", playerName)
            return false
        end
        
        removeFromStorage(playerName)
        NextKey222.Debug:Dev("fakeplayerservice", "Removed fake player:", playerName)
        return true
    end, "FakePlayerService:RemovePlayer")
end

--- Clears all fake players
-- @return number Count of players removed
function FakePlayerService:ClearAllPlayers()
    if not isInitialized then return 0 end
    
    return NextKey222.SafeRun(function()
        local count = 0
        for playerName in pairs(fakePlayerStorage) do
            count = count + 1
        end
        
        fakePlayerStorage = {}
        
        -- Invalidate entire profile cache
        if NextKey222.ProfilesService then
            NextKey222.ProfilesService:InvalidateCache()
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Cleared all fake players, removed:", count)
        return count
    end, "FakePlayerService:ClearAllPlayers") or 0
end

--- Gets a fake player's raw data (internal use)
-- @param playerName string The player name
-- @return table|nil The player data or nil if not found
function FakePlayerService:GetPlayer(playerName)
    if not isInitialized then return nil end
    
    playerName = normalizePlayerName(playerName)
    return fakePlayerStorage[playerName]
end

--- Gets all fake player names
-- @return table Array of player names
function FakePlayerService:GetAllPlayerNames()
    if not isInitialized then return {} end
    
    local names = {}
    for playerName in pairs(fakePlayerStorage) do
        table.insert(names, playerName)
    end
    return names
end

--- Gets all fake players (raw data)
-- @return table Array of player data
function FakePlayerService:GetAllPlayers()
    if not isInitialized then return {} end
    
    local players = {}
    for _, playerData in pairs(fakePlayerStorage) do
        table.insert(players, playerData)
    end
    return players
end

--- Checks if a player is a fake player
-- @param playerName string The player name to check
-- @return boolean True if fake player
function FakePlayerService:IsFakePlayer(playerName)
    if not isInitialized then return false end
    
    playerName = normalizePlayerName(playerName)
    return fakePlayerStorage[playerName] ~= nil
end

-- MARK: Public API - Profile Generation

--- Gets a standard PlayerProfile for a fake player
-- @param playerName string The player name
-- @return PlayerProfile|nil Standard profile or nil if not found
function FakePlayerService:GetProfile(playerName)
    if not isInitialized then return nil end
    
    playerName = normalizePlayerName(playerName)
    local playerData = fakePlayerStorage[playerName]
    
    if not playerData then
        return nil
    end
    
    return NextKey222.SafeRun(function()
        -- Convert internal format to standard PlayerProfile
        local profile = {
            name = playerData.name,
            class = playerData.class,
            io = playerData.io or 0,
            dataSource = "fake_player_service",
            dungeonScores = {},
            addonStatus = playerData.addonStatus or { nextkey = false, raiderio = false }
        }
        
        -- Convert dungeon scores to standard format
        if playerData.dungeonScores then
            for dungeonID, scoreData in pairs(playerData.dungeonScores) do
                profile.dungeonScores[dungeonID] = {
                    bestScore = scoreData.score or 0,
                    bestLevel = scoreData.level or 0,
                    timeLimit = 1800000,  -- Default 30 minutes
                    dataSource = "fake_player_service",
                    timed = scoreData.timed,
                    chests = scoreData.chests
                }
            end
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Generated profile for:", playerName, "IO:", profile.io)
        return profile
    end, "FakePlayerService:GetProfile")
end

--- Gets a fake player's keystone
-- @param playerName string The player name
-- @return table|nil Keystone data { dungeonID, level } or nil
function FakePlayerService:GetKeystone(playerName)
    if not isInitialized then return nil end
    
    playerName = normalizePlayerName(playerName)
    local playerData = fakePlayerStorage[playerName]
    
    if not playerData or not playerData.keystone then
        return nil
    end
    
    return playerData.keystone
end

-- MARK: Public API - Preset Generation

--- Generates a preset team of fake players
-- @param presetType string Type of preset (mixed_skill, beginner, expert, high_keys)
-- @param count number (optional) Number of players to generate, uses preset default if not provided
-- @return number Count of players created
function FakePlayerService:GeneratePreset(presetType, count)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        local preset = PRESET_CONFIGS[presetType]
        if not preset then
            NextKey222.Debug:Dev("fakeplayerservice", "Unknown preset type:", presetType)
            return 0
        end
        
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Determine player count
        local playerCount = count or #preset
        
        NextKey222.Debug:Dev("fakeplayerservice", "Generating preset:", presetType, "with", playerCount, "players")
        
        local created = 0
        for i = 1, playerCount do
            local spec = preset[((i - 1) % #preset) + 1]  -- Cycle through preset specs
            local playerName = self:CreatePlayer({
                tier = spec.tier,
                addonStatus = spec.addon
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Created", created, "fake players for preset:", presetType)
        return created
    end, "FakePlayerService:GeneratePreset") or 0
end

--- Generates random fake players
-- @param count number Number of players to generate
-- @param addonMix table (optional) Distribution of addon status { nextkey = n, raiderio = n, none = n }
-- @return number Count of players created
function FakePlayerService:GenerateRandomPlayers(count, addonMix)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    count = count or 4
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        NextKey222.Debug:Dev("fakeplayerservice", "Generating", count, "random fake players")
        
        local created = 0
        for i = 1, count do
            local playerName = self:CreatePlayer({
                addonStatus = determineAddonStatus(i, addonMix)
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Created", created, "random fake players")
        return created
    end, "FakePlayerService:GenerateRandomPlayers") or 0
end

-- MARK: Public API - Data Modification

--- Sets a fake player's best run for a dungeon
-- @param playerName string The player name
-- @param dungeonID number The dungeon ID
-- @param level number The key level
-- @param timed boolean Whether the run was timed
-- @param chests number (optional) Number of chests, 0-3
-- @return boolean Success status
function FakePlayerService:SetDungeonBest(playerName, dungeonID, level, timed, chests)
    if not isInitialized then return false end
    
    playerName = normalizePlayerName(playerName)
    
    return NextKey222.SafeRun(function()
        local playerData = fakePlayerStorage[playerName]
        if not playerData then
            NextKey222.Debug:Dev("fakeplayerservice", "Player not found:", playerName)
            return false
        end
        
        chests = chests or (timed and 1 or 0)
        local score = calculateScoreForRun(level, timed, chests)
        
        playerData.dungeonScores = playerData.dungeonScores or {}
        playerData.dungeonScores[dungeonID] = {
            level = level,
            chests = chests,
            timed = timed,
            score = score,
            dataSource = "fake_manual"
        }
        
        -- Recalculate total IO
        playerData.io = calculateTotalIO(playerData.dungeonScores)
        
        saveToStorage(playerName, playerData)
        
        NextKey222.Debug:Dev("fakeplayerservice", "Set dungeon best for", playerName, "dungeon", dungeonID, "level", level, "score", score)
        return true
    end, "FakePlayerService:SetDungeonBest")
end

--- Sets a fake player's keystone
-- @param playerName string The player name
-- @param dungeonID number The dungeon ID
-- @param level number The key level
-- @return boolean Success status
function FakePlayerService:SetKeystone(playerName, dungeonID, level)
    if not isInitialized then return false end
    
    playerName = normalizePlayerName(playerName)
    
    return NextKey222.SafeRun(function()
        local playerData = fakePlayerStorage[playerName]
        if not playerData then
            NextKey222.Debug:Dev("fakeplayerservice", "Player not found:", playerName)
            return false
        end
        
        playerData.keystone = {
            dungeonID = dungeonID,
            level = level
        }
        
        saveToStorage(playerName, playerData)
        
        NextKey222.Debug:Dev("fakeplayerservice", "Set keystone for", playerName, "dungeon", dungeonID, "level", level)
        return true
    end, "FakePlayerService:SetKeystone")
end

--- Sets a fake player's addon status
-- @param playerName string The player name
-- @param addonStatus table { nextkey = bool, raiderio = bool }
-- @return boolean Success status
function FakePlayerService:SetAddonStatus(playerName, addonStatus)
    if not isInitialized then return false end
    
    playerName = normalizePlayerName(playerName)
    
    return NextKey222.SafeRun(function()
        local playerData = fakePlayerStorage[playerName]
        if not playerData then
            NextKey222.Debug:Dev("fakeplayerservice", "Player not found:", playerName)
            return false
        end
        
        playerData.addonStatus = addonStatus or { nextkey = false, raiderio = false }
        
        saveToStorage(playerName, playerData)
        
        NextKey222.Debug:Dev("fakeplayerservice", "Set addon status for", playerName)
        return true
    end, "FakePlayerService:SetAddonStatus")
end

-- MARK: Public API - Status and Diagnostics

--- Gets service status and statistics
-- @return table Status information
function FakePlayerService:GetStatus()
    return {
        initialized = isInitialized,
        playerCount = self:CountTable(fakePlayerStorage),
        playerIDCounter = playerIDCounter,
        defaultRealm = defaultRealm,
        storageType = "in-memory"
    }
end

--- Checks if the service is enabled
-- @return boolean True if initialized and enabled
function FakePlayerService:IsEnabled()
    return isInitialized
end

--- Counts entries in a table
-- @param t table The table to count
-- @return number The count
function FakePlayerService:CountTable(t)
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

--- Logs current statistics
function FakePlayerService:LogStats()
    local status = self:GetStatus()
    NextKey222.Debug:Dev("fakeplayerservice", string.format(
        "Status: %s | Players: %d | Storage: %s | Realm: %s",
        status.initialized and "Initialized" or "Not initialized",
        status.playerCount,
        status.storageType,
        status.defaultRealm
    ))
end

-- MARK: Module Initialization Check
function FakePlayerService:IsInitialized()
    return isInitialized
end

-- MARK: Export
return FakePlayerService
