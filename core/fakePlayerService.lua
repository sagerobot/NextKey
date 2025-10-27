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

-- Spec definitions with associated roles (uses specialization IDs from Blizzard API)
local CLASS_SPEC_DATA = {
    WARRIOR = {
        { specID = 71, specName = "Arms", role = "DAMAGER" },
        { specID = 72, specName = "Fury", role = "DAMAGER" },
        { specID = 73, specName = "Protection", role = "TANK" }
    },
    PALADIN = {
        { specID = 65, specName = "Holy", role = "HEALER" },
        { specID = 66, specName = "Protection", role = "TANK" },
        { specID = 70, specName = "Retribution", role = "DAMAGER" }
    },
    HUNTER = {
        { specID = 253, specName = "Beast Mastery", role = "DAMAGER" },
        { specID = 254, specName = "Marksmanship", role = "DAMAGER" },
        { specID = 255, specName = "Survival", role = "DAMAGER" }
    },
    ROGUE = {
        { specID = 259, specName = "Assassination", role = "DAMAGER" },
        { specID = 260, specName = "Outlaw", role = "DAMAGER" },
        { specID = 261, specName = "Subtlety", role = "DAMAGER" }
    },
    PRIEST = {
        { specID = 256, specName = "Discipline", role = "HEALER" },
        { specID = 257, specName = "Holy", role = "HEALER" },
        { specID = 258, specName = "Shadow", role = "DAMAGER" }
    },
    DEATHKNIGHT = {
        { specID = 250, specName = "Blood", role = "TANK" },
        { specID = 251, specName = "Frost", role = "DAMAGER" },
        { specID = 252, specName = "Unholy", role = "DAMAGER" }
    },
    SHAMAN = {
        { specID = 262, specName = "Elemental", role = "DAMAGER" },
        { specID = 263, specName = "Enhancement", role = "DAMAGER" },
        { specID = 264, specName = "Restoration", role = "HEALER" }
    },
    MAGE = {
        { specID = 62, specName = "Arcane", role = "DAMAGER" },
        { specID = 63, specName = "Fire", role = "DAMAGER" },
        { specID = 64, specName = "Frost", role = "DAMAGER" }
    },
    WARLOCK = {
        { specID = 265, specName = "Affliction", role = "DAMAGER" },
        { specID = 266, specName = "Demonology", role = "DAMAGER" },
        { specID = 267, specName = "Destruction", role = "DAMAGER" }
    },
    MONK = {
        { specID = 268, specName = "Brewmaster", role = "TANK" },
        { specID = 269, specName = "Windwalker", role = "DAMAGER" },
        { specID = 270, specName = "Mistweaver", role = "HEALER" }
    },
    DRUID = {
        { specID = 102, specName = "Balance", role = "DAMAGER" },
        { specID = 103, specName = "Feral", role = "DAMAGER" },
        { specID = 104, specName = "Guardian", role = "TANK" },
        { specID = 105, specName = "Restoration", role = "HEALER" }
    },
    DEMONHUNTER = {
        { specID = 577, specName = "Havoc", role = "DAMAGER" },
        { specID = 581, specName = "Vengeance", role = "TANK" }
    },
    EVOKER = {
        { specID = 1467, specName = "Devastation", role = "DAMAGER" },
        { specID = 1468, specName = "Preservation", role = "HEALER" },
        { specID = 1473, specName = "Augmentation", role = "DAMAGER" }
    }
}

local CLASS_CAPABILITIES = {
    SHAMAN = { heroism = true },
    MAGE = { heroism = true },
    EVOKER = { heroism = true },
    DRUID = { battleRes = true },
    WARLOCK = { battleRes = true },
    DEATHKNIGHT = { battleRes = true }
}

local SPEC_CAPABILITIES = {
    [262] = { heroism = true },
    [263] = { heroism = true },
    [264] = { heroism = true },
    [62]  = { heroism = true },
    [63]  = { heroism = true },
    [64]  = { heroism = true },
    [1467] = { heroism = true },
    [1468] = { heroism = true },
    [1473] = { heroism = true },
    [253] = { heroism = true },

    [102] = { battleRes = true },
    [103] = { battleRes = true },
    [104] = { battleRes = true },
    [105] = { battleRes = true },
    [250] = { battleRes = true },
    [251] = { battleRes = true },
    [252] = { battleRes = true },
    [265] = { battleRes = true },
    [266] = { battleRes = true },
    [267] = { battleRes = true }
}

-- Realistic IO distribution based on TWW Season 3 US cutoffs
-- Target IO ranges derived from raider.io/mythic-plus/cutoffs/season-tww-3/us
local SKILL_TIERS = {
    -- Top 0.1% - Title holders, all 20s+
    title = { 
        baseLevel = {20, 22}, 
        timingChance = 0.98, 
        targetIO = {3600, 3800},
        description = "Top 0.1% - All 20s+" 
    },
    -- Top 1% - Elite pushers, 18-19s
    elite = { 
        baseLevel = {18, 20}, 
        timingChance = 0.95, 
        targetIO = {3300, 3600},
        description = "Top 1% - 18-19s" 
    },
    -- Top 5% - Expert players, 15-17s
    expert = { 
        baseLevel = {15, 18}, 
        timingChance = 0.88, 
        targetIO = {3100, 3400},
        description = "Top 5% - 15-17s" 
    },
    -- Top 10% - Skilled players, 13-14s (KSL territory)
    skilled = { 
        baseLevel = {13, 15}, 
        timingChance = 0.75, 
        targetIO = {2900, 3100},
        description = "Top 10% - KSL 13-14s" 
    },
    -- Top 25% - Competent players, 11-12s (KSH territory)
    competent = { 
        baseLevel = {11, 13}, 
        timingChance = 0.65, 
        targetIO = {2500, 2900},
        description = "Top 25% - KSH 11-12s" 
    },
    -- Top 50% - Average players, 7-10s (KSM territory)
    average = { 
        baseLevel = {7, 11}, 
        timingChance = 0.50, 
        targetIO = {2000, 2600},
        description = "Top 50% - KSM 7-10s" 
    },
    -- Top 60% - Casual players, 4-6s (KSC territory)
    casual = { 
        baseLevel = {4, 7}, 
        timingChance = 0.35, 
        targetIO = {1500, 2000},
        description = "Top 60% - KSC 4-6s" 
    },
    -- Top 70% - New players, 2-3s
    beginner = { 
        baseLevel = {2, 4}, 
        timingChance = 0.20, 
        targetIO = {1000, 1500},
        description = "Top 70% - 2-3s" 
    }
}

local PRESET_CONFIGS = {
    mixed_skill = {
        { tier = "expert" },
        { tier = "skilled" },
        { tier = "competent" },
        { tier = "average" }
    },
    beginner = {
        { tier = "beginner" },
        { tier = "casual" },
        { tier = "casual" },
        { tier = "average" }
    },
    expert = {
        { tier = "title" },
        { tier = "elite" },
        { tier = "expert" },
        { tier = "skilled" }
    },
    high_keys = {
        { tier = "title" },
        { tier = "title" },
        { tier = "elite" },
        { tier = "expert" }
    },
    raid_group = {
        -- 20 players for M+ Group Organizer testing
        -- 2 expert, 4 skilled, 8 competent, 6 average
        { tier = "expert" },
        { tier = "expert" },
        { tier = "skilled" },
        { tier = "skilled" },
        { tier = "skilled" },
        { tier = "skilled" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "competent" },
        { tier = "average" },
        { tier = "average" },
        { tier = "average" },
        { tier = "average" },
        { tier = "average" },
        { tier = "average" }
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
        
        -- Also refresh RosterBoard if visible
        if NextKey222.RosterBoard and NextKey222.RosterBoard.IsVisible and NextKey222.RosterBoard:IsVisible() then
            NextKey222.RosterBoard:PopulateAllSections()
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

local function pickSpecForClass(classToken)
    local specs = CLASS_SPEC_DATA[classToken]
    if not specs or #specs == 0 then
        return nil
    end
    return specs[math.random(#specs)]
end

local function determineCapabilities(classToken, specID)
    local specCaps = SPEC_CAPABILITIES[specID] or {}
    local classCaps = CLASS_CAPABILITIES[classToken] or {}
    return {
        heroism = specCaps.heroism or classCaps.heroism or false,
        battleRes = specCaps.battleRes or classCaps.battleRes or false
    }
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
        
        local classToken = config.class and string.upper(config.class) or getRandomClass()
        local specInfo = pickSpecForClass(classToken)
        local capabilities = determineCapabilities(classToken, specInfo and specInfo.specID)

        -- Create player data structure
        local playerData = {
            id = playerID,
            name = playerName,
            class = classToken,
            tier = tier,
            dungeonScores = dungeonScores,
            keystone = keystone,
            addonStatus = config.addonStatus or { nextkey = false, raiderio = false },
            io = config.io or calculateTotalIO(dungeonScores),
            createdAt = GetTime(),
            dataSource = "fake_player_service",
            role = specInfo and specInfo.role or "DAMAGER",
            specID = specInfo and specInfo.specID or nil,
            specName = specInfo and specInfo.specName or nil,
            heroismCaster = capabilities.heroism,
            battleResCaster = capabilities.battleRes
        }

        -- Save to storage
        saveToStorage(playerName, playerData)

        NextKey222.Debug:Dev("fakeplayerservice", "Created fake player:", playerName, "class:", playerData.class, "spec:", playerData.specName or "Unknown", "tier:", tier, "IO:", playerData.io)
        
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
            addonStatus = playerData.addonStatus or { nextkey = false, raiderio = false },
            role = playerData.role or "DAMAGER",
            specID = playerData.specID,
            specName = playerData.specName,
            capabilities = {
                heroism = playerData.heroismCaster or false,
                battleRes = playerData.battleResCaster or false
            }
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
        
        -- Get addon configuration from debug state (set by options UI)
        local addonConfig = { nextkey = true, raiderio = true }  -- Default
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Determine player count
        local playerCount = count or #preset
        
        NextKey222.Debug:Dev("fakeplayerservice", "Generating preset:", presetType, "with", playerCount, "players", 
            "NextKey:", addonConfig.nextkey and "YES" or "NO", 
            "RaiderIO:", addonConfig.raiderio and "YES" or "NO")
        
        local created = 0
        for i = 1, playerCount do
            local spec = preset[((i - 1) % #preset) + 1]  -- Cycle through preset specs
            local playerName = self:CreatePlayer({
                tier = spec.tier,
                addonStatus = addonConfig  -- Use global addon config instead of per-player
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
-- @param addonMix table (optional) DEPRECATED - uses global addon config from options
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
        
        -- Get addon configuration from debug state (set by options UI)
        local addonConfig = { nextkey = true, raiderio = true }  -- Default
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Generating", count, "random fake players",
            "NextKey:", addonConfig.nextkey and "YES" or "NO", 
            "RaiderIO:", addonConfig.raiderio and "YES" or "NO")
        
        local created = 0
        for i = 1, count do
            local playerName = self:CreatePlayer({
                addonStatus = addonConfig  -- Use global addon config
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
