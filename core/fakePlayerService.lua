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

--- Validates a WoW character name against Blizzard's official rules
-- @param name string The name to validate (without realm)
-- @return boolean, string Success status and error message if invalid
--
-- Blizzard's Official Rules:
-- 1. Must be 2-12 characters long
-- 2. Accented characters are supported
-- 3. Numbers and symbols are not supported
-- 4. Mixed capitals and spaces are not supported
local function validateWoWName(name)
    if not name or name == "" then
        return false, "Name cannot be empty"
    end
    
    -- Remove realm suffix if present for validation
    local baseName = name:match("^([^%-]+)") or name
    
    -- Rule 1: Length check (2-12 characters)
    if #baseName < 2 then
        return false, "Name must be at least 2 characters"
    end
    if #baseName > 12 then
        return false, "Name must be 12 characters or less"
    end
    
    -- Rule 2 & 3: Letters only (including accented), no numbers or symbols
    -- Lua pattern: %a matches all letters including accented characters
    if not baseName:match("^%a+$") then
        return false, "Name can only contain letters (no spaces, numbers, or symbols)"
    end
    
    -- Rule 4: No mixed capitals (e.g., "TaNk" is invalid)
    -- All lowercase OR proper case are both valid
    -- Check if it's mixed case by seeing if it's NOT all one case
    local isAllLower = baseName == baseName:lower()
    local isAllUpper = baseName == baseName:upper()
    local isProperCase = baseName:sub(1, 1) == baseName:sub(1, 1):upper() and baseName:sub(2) == baseName:sub(2):lower()
    
    if not (isAllLower or isAllUpper or isProperCase) then
        return false, "Name cannot have mixed capitals (use 'Tank', 'TANK', or 'tank', not 'TaNk')"
    end
    
    return true, nil
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

local function findSpecByID(specID)
    for className, specs in pairs(CLASS_SPEC_DATA) do
        for _, spec in ipairs(specs) do
            if spec.specID == specID then
                return spec
            end
        end
    end
    return nil
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
        -- Handle custom name with realm
        local playerID = generatePlayerID()
        local playerName = config.name
        
        if playerName then
            -- User provided custom name
            playerName = normalizePlayerName(playerName)
            -- Validate uniqueness
            if fakePlayerStorage[playerName] then
                NextKey222.Debug:Error("Player already exists:", playerName)
                return nil
            end
        else
            -- Auto-generate numbered name
            playerName = string.format("%02dFP", playerID)
            playerName = normalizePlayerName(playerName)
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
        
        -- Handle spec selection - custom specID takes precedence
        local specInfo = nil
        if config.specID then
            -- Find spec by ID
            specInfo = findSpecByID(config.specID)
            if not specInfo then
                NextKey222.Debug:Error("Invalid spec ID:", config.specID)
                return nil
            end
            -- Validate spec matches class if both provided
            if config.class and specInfo.class and specInfo.class ~= classToken then
                NextKey222.Debug:Error("Spec doesn't match class:", config.specID, "vs", classToken)
                return nil
            end
        else
            -- Random spec for class (existing behavior)
            specInfo = pickSpecForClass(classToken)
        end
        
        -- Handle capabilities - custom override or auto-detect
        local capabilities = config.capabilities or determineCapabilities(classToken, specInfo and specInfo.specID)
      
        -- NEW: Get ALL specs for this class for spec preference generation
        local allClassSpecs = CLASS_SPEC_DATA[classToken] or {}
        local specializationData = {}
        for _, spec in ipairs(allClassSpecs) do
        	table.insert(specializationData, {
        		specID = spec.specID,
        		specName = spec.specName,
        		role = spec.role,
        		iconTexture = nil  -- Could add icon paths if needed for debugging
        	})
        end
      
        -- Create player data structure
        local playerData = {
        	id = playerID,
        	name = playerName,
        	class = classToken,
        	tier = tier,
        	dungeonScores = dungeonScores,
        	keystone = keystone,
        	addonStatus = config.addonStatus or { nextkey = false, raiderio = false },
        	io = config.io or (config.tier and calculateTotalIO(dungeonScores) or 0),
        	createdAt = GetTime(),
        	dataSource = "fake_player_service",
        	role = specInfo and specInfo.role or "DAMAGER",
        	specID = specInfo and specInfo.specID or nil,
        	specName = specInfo and specInfo.specName or nil,
        	specializations = specializationData,  -- NEW: Store all specs for GenerateSpecPreferences
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
        
        -- MEMORY LEAK FIX: Deep cleanup of nested data structures
        local playerData = fakePlayerStorage[playerName]
        if playerData then
            -- Nil out deeply nested tables explicitly
            if playerData.dungeonScores then
                for dungeonID, scoreData in pairs(playerData.dungeonScores) do
                    playerData.dungeonScores[dungeonID] = nil
                end
                playerData.dungeonScores = nil
            end
            
            if playerData.keystoneData then
                playerData.keystoneData = nil
            end
            
            if playerData.specPreferences then
                for role in pairs(playerData.specPreferences) do
                    playerData.specPreferences[role] = nil
                end
                playerData.specPreferences = nil
            end
            
            if playerData.specDetails then
                playerData.specDetails = nil
            end
            
            if playerData.specializations then
                for i in ipairs(playerData.specializations) do
                    playerData.specializations[i] = nil
                end
                playerData.specializations = nil
            end
        end
        
        removeFromStorage(playerName)
        
        -- Invalidate profile cache for this player
        if NextKey222.ProfilesService then
            NextKey222.ProfilesService:InvalidateCache(playerName)
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", "Removed fake player with deep cleanup:", playerName)
        return true
    end, "FakePlayerService:RemovePlayer")
end

--- Clears all fake players
-- @return number Count of players removed
function FakePlayerService:ClearAllPlayers()
    if not isInitialized then return 0 end
    
    return NextKey222.SafeRun(function()
        local count = 0
        
        -- MEMORY LEAK FIX: Deep cleanup each player before clearing storage
        for playerName, playerData in pairs(fakePlayerStorage) do
            count = count + 1
            
            -- Nil out deeply nested tables explicitly
            if playerData then
                if playerData.dungeonScores then
                    for dungeonID, scoreData in pairs(playerData.dungeonScores) do
                        playerData.dungeonScores[dungeonID] = nil
                    end
                    playerData.dungeonScores = nil
                end
                
                if playerData.keystoneData then
                    playerData.keystoneData = nil
                end
                
                if playerData.specPreferences then
                    for role in pairs(playerData.specPreferences) do
                        playerData.specPreferences[role] = nil
                    end
                    playerData.specPreferences = nil
                end
                
                if playerData.specDetails then
                    playerData.specDetails = nil
                end
                
                if playerData.specializations then
                    for i in ipairs(playerData.specializations) do
                        playerData.specializations[i] = nil
                    end
                    playerData.specializations = nil
                end
            end
            
            fakePlayerStorage[playerName] = nil
        end
        
        fakePlayerStorage = {}
        
        -- Invalidate entire profile cache
        if NextKey222.ProfilesService then
            NextKey222.ProfilesService:InvalidateCache()
        end
        
        -- Hint to garbage collector
        collectgarbage("step")
        
        NextKey222.Debug:Dev("fakeplayerservice", "Cleared all fake players with deep cleanup, removed:", count)
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

--- Generates a full 20-player raid team with optimal role distribution
-- Detects real player's roles and fills remaining slots intelligently
-- Distribution: 2 tanks, 5 healers, 13 DPS (standard M+ raid composition)
-- @return number Count of players created
function FakePlayerService:GenerateRaidTeam()
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Define target composition (20 players total including real player)
        local targetTanks = 2
        local targetHealers = 5
        local targetDPS = 13
        
        -- We'll create 19 fake players since real player is #20
        local fakePlayers = 19
        
        -- Create role distribution for fake players
        local roleAssignments = {}
        
        -- TANKS: Create pure tanks (primary role = TANK)
        for i = 1, targetTanks do
            table.insert(roleAssignments, {
                primaryRole = "TANK",
                tier = i == 1 and "expert" or "skilled"
            })
        end
        
        -- HEALERS: Create healers (primary role = HEALER)
        for i = 1, targetHealers do
            table.insert(roleAssignments, {
                primaryRole = "HEALER",
                tier = i <= 2 and "skilled" or "competent"
            })
        end
        
        -- DPS: Create DPS (primary role = DAMAGER)
        for i = 1, targetDPS do
            table.insert(roleAssignments, {
                primaryRole = "DAMAGER",
                tier = i <= 3 and "expert" or (i <= 8 and "competent" or "average")
            })
        end
        
        -- Shuffle to mix skill levels
        for i = #roleAssignments, 2, -1 do
            local j = math.random(i)
            roleAssignments[i], roleAssignments[j] = roleAssignments[j], roleAssignments[i]
        end
        
        -- Create fake players
        local created = 0
        for i = 1, fakePlayers do
            local assignment = roleAssignments[i]
            
            -- Pick a class that can fill the primary role
            local classToken = self:GetRandomClassForRole(assignment.primaryRole)
            
            local playerName = self:CreatePlayer({
                tier = assignment.tier,
                class = classToken,
                addonStatus = addonConfig
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format(
            "Created %d-player raid team (%d tanks, %d healers, %d DPS + you)",
            created + 1,
            targetTanks,
            targetHealers,
            targetDPS
        ))
        
        return created
    end, "FakePlayerService:GenerateRaidTeam") or 0
end

--- Gets a random class that can fill a specific role
-- @param role string "TANK", "HEALER", or "DAMAGER"
-- @return string Class token
function FakePlayerService:GetRandomClassForRole(role)
    local tankClasses = {"WARRIOR", "PALADIN", "DEATHKNIGHT", "MONK", "DRUID", "DEMONHUNTER"}
    local healerClasses = {"PALADIN", "PRIEST", "SHAMAN", "MONK", "DRUID", "EVOKER"}
    local dpsClasses = VALID_CLASSES  -- All classes can DPS
    
    if role == "TANK" then
        return tankClasses[math.random(#tankClasses)]
    elseif role == "HEALER" then
        return healerClasses[math.random(#healerClasses)]
    else  -- DAMAGER/DPS
        return dpsClasses[math.random(#dpsClasses)]
    end
end

-- MARK: Public API - Keystone-Focused Generation

--- Generates players with diverse keystones at the same level
-- @param level number The keystone level for all players
-- @param count number (optional) Number of players to generate (default 4)
-- @return number Count of players created
function FakePlayerService:GenerateDiverseKeys(level, count)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    count = count or 4
    level = level or 10
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Get active season dungeons
        local dungeonIDs = {}
        if NextKey222.Addon and NextKey222.Addon.GetActiveSeasonDungeonIDs then
            dungeonIDs = NextKey222.Addon:GetActiveSeasonDungeonIDs() or {}
        end
        
        if #dungeonIDs == 0 then
            NextKey222.Debug:Error("No dungeon IDs available for diverse key generation")
            return 0
        end
        
        -- Shuffle dungeons to ensure variety
        local shuffled = {}
        for i, id in ipairs(dungeonIDs) do
            shuffled[i] = id
        end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        
        local created = 0
        for i = 1, math.min(count, #shuffled) do
            local playerName = self:CreatePlayer({
                tier = "competent", -- Middle tier for testing
                keystoneDungeon = shuffled[i],
                keystoneLevel = level,
                addonStatus = addonConfig
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format("Generated %d players with diverse +%d keys", created, level))
        return created
    end, "FakePlayerService:GenerateDiverseKeys") or 0
end

--- Generates players with keystones in a specific level range
-- @param minLevel number Minimum keystone level
-- @param maxLevel number Maximum keystone level
-- @param count number (optional) Number of players to generate (default 4)
-- @return number Count of players created
function FakePlayerService:GenerateLevelRange(minLevel, maxLevel, count)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    count = count or 4
    minLevel = minLevel or 7
    maxLevel = maxLevel or 10
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Get active season dungeons
        local dungeonIDs = {}
        if NextKey222.Addon and NextKey222.Addon.GetActiveSeasonDungeonIDs then
            dungeonIDs = NextKey222.Addon:GetActiveSeasonDungeonIDs() or {}
        end
        
        if #dungeonIDs == 0 then
            NextKey222.Debug:Error("No dungeon IDs available for level range generation")
            return 0
        end
        
        local created = 0
        for i = 1, count do
            -- Random dungeon and level within range
            local dungeonID = dungeonIDs[math.random(#dungeonIDs)]
            local level = math.random(minLevel, maxLevel)
            
            local playerName = self:CreatePlayer({
                tier = "competent",
                keystoneDungeon = dungeonID,
                keystoneLevel = level,
                addonStatus = addonConfig
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format("Generated %d players with +%d to +%d keys", created, minLevel, maxLevel))
        return created
    end, "FakePlayerService:GenerateLevelRange") or 0
end

--- Generates players with duplicate keystones (same dungeon, same level)
-- @param dungeonID number The dungeon ID
-- @param level number The keystone level
-- @param count number (optional) Number of players to generate (default 3)
-- @return number Count of players created
function FakePlayerService:GenerateDuplicateKeys(dungeonID, level, count)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    count = count or 3
    level = level or 10
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        local created = 0
        for i = 1, count do
            local playerName = self:CreatePlayer({
                tier = "competent",
                keystoneDungeon = dungeonID,
                keystoneLevel = level,
                addonStatus = addonConfig
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format("Generated %d players with dungeon %d +%d", created, dungeonID, level))
        return created
    end, "FakePlayerService:GenerateDuplicateKeys") or 0
end

-- MARK: Public API - Role Composition Generation

--- Generates players with specific role composition
-- @param tanks number Number of tanks (0-4)
-- @param healers number Number of healers (0-4)
-- @param dps number Number of DPS (0-12)
-- @param options table (optional) { tier = "mixed" | tier name, respectSkillTier = bool, addonStatus = { nextkey, raiderio } }
-- @return number Count of players created
function FakePlayerService:GenerateRoleComposition(tanks, healers, dps, options)
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    tanks = tanks or 0
    healers = healers or 0
    dps = dps or 0
    options = options or {}
    
    local total = tanks + healers + dps
    if total > 20 then
        NextKey222.Debug:Error("Total player count exceeds maximum (20)")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = options.addonStatus or { nextkey = true, raiderio = true }
        if not options.addonStatus and NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        local created = 0
        
        -- Create tanks
        for i = 1, tanks do
            local classToken = self:GetRandomClassForRole("TANK")
            local playerName = self:CreatePlayer({
                class = classToken,
                tier = options.tier or "competent",
                addonStatus = addonConfig
            })
            if playerName then
                created = created + 1
            end
        end
        
        -- Create healers
        for i = 1, healers do
            local classToken = self:GetRandomClassForRole("HEALER")
            local playerName = self:CreatePlayer({
                class = classToken,
                tier = options.tier or "competent",
                addonStatus = addonConfig
            })
            if playerName then
                created = created + 1
            end
        end
        
        -- Create DPS
        for i = 1, dps do
            local classToken = self:GetRandomClassForRole("DAMAGER")
            local playerName = self:CreatePlayer({
                class = classToken,
                tier = options.tier or "competent",
                addonStatus = addonConfig
            })
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format("Generated role composition: %d tanks, %d healers, %d DPS", tanks, healers, dps))
        return created
    end, "FakePlayerService:GenerateRoleComposition") or 0
end

--- Generates standard M+ composition (1 tank, 1 healer, 3 DPS)
-- @return number Count of players created
function FakePlayerService:GenerateStandardComp()
    return self:GenerateRoleComposition(1, 1, 3, { tier = "competent" })
end

--- Generates a 4-player team based on current player's role (1T/1H/3D minus player)
-- Detects your role and fills remaining slots to complete a standard 5-man composition
-- @return number Count of players created
function FakePlayerService:Generate4PlayerTeam()
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Detect current player's role
        local playerRole = "DAMAGER"  -- Default fallback
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            if playerName and realmName then
                local fullName = playerName .. "-" .. realmName
                local profile = NextKey222.ProfilesService:GetProfile(fullName)
                if profile and profile.role then
                    playerRole = profile.role
                    NextKey222.Debug:Dev("fakeplayerservice", "Detected player role:", playerRole)
                end
            end
        end
        
        -- Build 5-man composition: 1 Tank, 1 Healer, 3 DPS (minus player's role)
        local roleAssignments = {}
        
        -- Add tank if player is not tank
        if playerRole ~= "TANK" then
            table.insert(roleAssignments, { role = "TANK", tier = "competent" })
        end
        
        -- Add healer if player is not healer
        if playerRole ~= "HEALER" then
            table.insert(roleAssignments, { role = "HEALER", tier = "competent" })
        end
        
        -- Calculate remaining DPS slots (3 total DPS, minus player if they are DPS)
        local dpsSlots = (playerRole == "DAMAGER") and 2 or 3
        for i = 1, dpsSlots do
            table.insert(roleAssignments, { role = "DAMAGER", tier = "competent" })
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", string.format(
            "Creating 4-player team for player role %s: %d assignments",
            playerRole, #roleAssignments))
        
        -- Create fake players
        local created = 0
        for _, assignment in ipairs(roleAssignments) do
            local classToken = self:GetRandomClassForRole(assignment.role)
            
            local playerName = self:CreatePlayer({
                tier = assignment.tier,
                class = classToken,
                addonStatus = addonConfig
            })
            
            if playerName then
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format(
            "Created %d-player team (you + 4) - Standard M+ composition",
            created + 1))
        
        return created
    end, "FakePlayerService:Generate4PlayerTeam") or 0
end

--- Generates a 19-player team based on current player's role (4T/4H/12D minus player)
-- Detects your role and fills remaining slots for a 20-player raid composition
-- @return number Count of players created
function FakePlayerService:Generate19PlayerTeam()
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Detect current player's role
        local playerRole = "DAMAGER"  -- Default fallback
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            if playerName and realmName then
                local fullName = playerName .. "-" .. realmName
                local profile = NextKey222.ProfilesService:GetProfile(fullName)
                if profile and profile.role then
                    playerRole = profile.role
                    NextKey222.Debug:Dev("fakeplayerservice", "Detected player role:", playerRole)
                end
            end
        end
        
        -- Build 20-player composition: 4 Tanks, 4 Healers, 12 DPS (minus player's role)
        local roleAssignments = {}
        
        -- Add tanks (4 total, minus 1 if player is tank)
        local tankSlots = (playerRole == "TANK") and 3 or 4
        for i = 1, tankSlots do
            table.insert(roleAssignments, {
                role = "TANK",
                tier = i <= 2 and "expert" or "skilled"
            })
        end
        
        -- Add healers (4 total, minus 1 if player is healer)
        local healerSlots = (playerRole == "HEALER") and 3 or 4
        for i = 1, healerSlots do
            table.insert(roleAssignments, {
                role = "HEALER",
                tier = i <= 2 and "expert" or "competent"
            })
        end
        
        -- Add DPS (12 total, minus 1 if player is DPS)
        local dpsSlots = (playerRole == "DAMAGER") and 11 or 12
        for i = 1, dpsSlots do
            table.insert(roleAssignments, {
                role = "DAMAGER",
                tier = i <= 3 and "expert" or (i <= 7 and "skilled" or "competent")
            })
        end
        
        -- Shuffle to mix skill levels
        for i = #roleAssignments, 2, -1 do
            local j = math.random(i)
            roleAssignments[i], roleAssignments[j] = roleAssignments[j], roleAssignments[i]
        end
        
        NextKey222.Debug:Dev("fakeplayerservice", string.format(
            "Creating 19-player team for player role %s: %d assignments",
            playerRole, #roleAssignments))
        
        -- Create fake players
        local created = 0
        for _, assignment in ipairs(roleAssignments) do
            local classToken = self:GetRandomClassForRole(assignment.role)
            
            -- 80% of players get keystones
            local shouldHaveKey = math.random(100) <= 80
            
            local config = {
                tier = assignment.tier,
                class = classToken,
                addonStatus = addonConfig
            }
            
            local playerName = self:CreatePlayer(config)
            
            if playerName then
                -- Remove keystone for 20% of players
                if not shouldHaveKey then
                    local playerData = fakePlayerStorage[playerName]
                    if playerData then
                        playerData.keystone = nil
                    end
                end
                created = created + 1
            end
        end
        
        NextKey222.Debug:User(string.format(
            "Created %d-player raid team (you + 19) - 4T/4H/12D composition, 80%% with keys",
            created + 1))
        
        return created
    end, "FakePlayerService:Generate19PlayerTeam") or 0
end

--- Generates enhanced Organizer team (20 players) with optimal distribution
-- @return number Count of players created
function FakePlayerService:GenerateOrganizerTeam()
    if not isInitialized then
        NextKey222.Debug:Dev("fakeplayerservice", "Service not initialized")
        return 0
    end
    
    return NextKey222.SafeRun(function()
        -- Clear existing fake players
        self:ClearAllPlayers()
        
        -- Get addon configuration
        local addonConfig = { nextkey = true, raiderio = true }
        if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
            local dbg = NextKey222.Addon.db.global.debug
            if dbg.presetAddonConfig then
                addonConfig = dbg.presetAddonConfig
            end
        end
        
        -- Optimized composition for Organizer testing
        -- 4 tanks (one per potential group)
        -- 6 healers (coverage for 4 groups + flexibility)
        -- 10 DPS (remaining slots)
        
        local roleAssignments = {}
        
        -- TANKS: 4 tanks with varied skill
        table.insert(roleAssignments, { role = "TANK", tier = "expert" })
        table.insert(roleAssignments, { role = "TANK", tier = "expert" })
        table.insert(roleAssignments, { role = "TANK", tier = "skilled" })
        table.insert(roleAssignments, { role = "TANK", tier = "skilled" })
        
        -- HEALERS: 6 healers with varied skill
        table.insert(roleAssignments, { role = "HEALER", tier = "expert" })
        table.insert(roleAssignments, { role = "HEALER", tier = "expert" })
        table.insert(roleAssignments, { role = "HEALER", tier = "skilled" })
        table.insert(roleAssignments, { role = "HEALER", tier = "skilled" })
        table.insert(roleAssignments, { role = "HEALER", tier = "competent" })
        table.insert(roleAssignments, { role = "HEALER", tier = "competent" })
        
        -- DPS: 10 DPS with skill distribution
        table.insert(roleAssignments, { role = "DAMAGER", tier = "expert" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "expert" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "expert" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "skilled" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "skilled" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "skilled" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "skilled" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "competent" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "competent" })
        table.insert(roleAssignments, { role = "DAMAGER", tier = "competent" })
        
        -- Shuffle to mix roles
        for i = #roleAssignments, 2, -1 do
            local j = math.random(i)
            roleAssignments[i], roleAssignments[j] = roleAssignments[j], roleAssignments[i]
        end
        
        -- Create players
        local created = 0
        for i, assignment in ipairs(roleAssignments) do
            local classToken = self:GetRandomClassForRole(assignment.role)
            
            -- 80% of players get keystones (realistic)
            local shouldHaveKey = math.random(100) <= 80
            
            local config = {
                tier = assignment.tier,
                class = classToken,
                addonStatus = addonConfig
            }
            
            -- Don't specify keystone if player shouldn't have one
            -- CreatePlayer will auto-generate if not specified and shouldHaveKey logic is built-in
            
            local playerName = self:CreatePlayer(config)
            
            if playerName then
                -- Remove keystone for 20% of players
                if not shouldHaveKey then
                    local playerData = fakePlayerStorage[playerName]
                    if playerData then
                        playerData.keystone = nil
                    end
                end
                created = created + 1
            end
        end
        
        -- Enable poll protocol for all fake players
        if self.EnablePollProtocol then
            self:EnablePollProtocol()
        end
        
        NextKey222.Debug:User(string.format("Generated Organizer team: %d players (4T/6H/10D, 80%% with keys)", created))
        return created
    end, "FakePlayerService:GenerateOrganizerTeam") or 0
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

--- Gets all available specs for a class
-- @param classToken string Class token (e.g., "EVOKER")
-- @return table List of spec info {specID, specName, role}
function FakePlayerService:GetClassSpecs(classToken)
    classToken = classToken and string.upper(classToken)
    return CLASS_SPEC_DATA[classToken] or {}
end

--- Gets all specs across all classes
-- @return table List of all specs with class info
function FakePlayerService:ListAllSpecs()
    local specs = {}
    for className, classSpecs in pairs(CLASS_SPEC_DATA) do
        for _, spec in ipairs(classSpecs) do
            table.insert(specs, {
                class = className,
                specID = spec.specID,
                specName = spec.specName,
                role = spec.role
            })
        end
    end
    return specs
end

-- MARK: Module Initialization Check
function FakePlayerService:IsInitialized()
    return isInitialized
end

-- MARK: Poll Protocol (Unified System - Lazy Initialization)

--- Enable automatic PONG responses for poll protocol
-- Makes fake players respond to ADDON_PING messages automatically
-- Uses lazy initialization to avoid module load order issues
-- @return boolean Success status
function FakePlayerService:EnablePollProtocol()
    if self.pollProtocolInitialized then
        Debug:Dev("fake_players", "Poll protocol already initialized")
        return true  -- Already initialized
    end
    
    if not NextKey222.ParticipantSurvey then
        Debug:Error("FakePlayerService:EnablePollProtocol - ParticipantSurvey not available")
        return false
    end
    
    Debug:Dev("fake_players", "Enabling poll protocol - wrapping SendAddonPing method")
    
    -- Store original SendAddonPing method
    self.originalSendAddonPing = NextKey222.ParticipantSurvey.SendAddonPing
    
    -- Wrap SendAddonPing to intercept and simulate fake player PONGs
    NextKey222.ParticipantSurvey.SendAddonPing = function(survey, pollID)
        -- Call original method (sends PING to real players)
        FakePlayerService.originalSendAddonPing(survey, pollID)
        
        -- Simulate fake players responding with PONGs
        FakePlayerService:SimulatePongResponses(pollID)
    end
    
    self.pollProtocolInitialized = true
    Debug:Dev("fake_players", "Poll protocol enabled - fake players will auto-respond to PINGs")
    return true
end

--- Simulate PONG responses from all fake players
-- @param pollID string Poll identifier
function FakePlayerService:SimulatePongResponses(pollID)
    local fakePlayers = self:GetAllPlayerNames()
    
    if #fakePlayers == 0 then
        Debug:Dev("fake_players", "No fake players - skipping PONG simulation")
        return -- No fake players to simulate
    end
    
    Debug:Dev("fake_players", string.format("Simulating PONGs from %d fake players", #fakePlayers))
    
    for _, playerName in ipairs(fakePlayers) do
        -- Realistic network delay: 0-500ms
        local delay = math.random(0, 500) / 1000
        
        C_Timer.After(delay, function()
            NextKey222.SafeRun(function()
                -- Build PONG message (identical structure to real player)
                local pongMessage = {
                    pollID = pollID,
                    version = "0.5.32-fake"
                }
                
                -- Send directly to ParticipantSurvey as if received over network
                if NextKey222.ParticipantSurvey and NextKey222.ParticipantSurvey.OnAddonPong then
                    NextKey222.ParticipantSurvey:OnAddonPong(pongMessage, playerName)
                    Debug:Dev("fake_players", string.format("Simulated ADDON_PONG from %s (delay: %dms)", 
                        playerName, delay * 1000))
                end
            end, "FakePlayerService:SimulatePongResponses:Timer")
        end)
    end
end

--- Disable poll protocol (restore original methods)
-- @return boolean Success status
function FakePlayerService:DisablePollProtocol()
    if self.originalSendAddonPing and NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey.SendAddonPing = self.originalSendAddonPing
        self.originalSendAddonPing = nil
        self.pollProtocolInitialized = false
        Debug:Dev("fake_players", "Poll protocol disabled - restored original SendAddonPing")
        return true
    end
    return false
end

-- MARK: Export
return FakePlayerService
