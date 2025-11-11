local _, NextKey222 = ...

-- Keystones module
local Keystones = {}
NextKey222.Keystones = Keystones

-- Register with module system
NextKey222.RegisterModule("Keystones", Keystones)

-- Get addon reference (available after boot)
local function GetNextKey()
    return NextKey222.Addon
end

local function GetUtils()
    return NextKey222.Utils
end

---@class KeystoneEntry
---@field dungeonID number Dungeon identifier
---@field level number Keystone level
---@field ownerName string Full player name with realm
---@field ownerShort string Short player name without realm
---@field class string Player class
---@field source string Source of the keystone info
---@field timestamp number When the data was recorded
---@field rioScore number? Player's RaiderIO score
---@field dungeonBest DungeonBest? Player's best run in this dungeon
---@field runCounts RunCounts? Player's M+ run counts

---@class DungeonBest
---@field fortified DungeonRunInfo? Best fortified run
---@field tyrannical DungeonRunInfo? Best tyrannical run
---@field currentAffixScore number Score for current week's affix

---Gets a player's Mythic+ score using Blizzard API
---@param playerName string The player name to get score for 
---@return number? score The player's current M+ rating or nil if unavailable
local function getBlizzardMythicPlusScore(playerName)
        -- For the current player, use direct API calls
        if not playerName or playerName == UnitName("player") or playerName == NextKey222.Addon.playerFullName then
            if C_MythicPlus and C_MythicPlus.GetOverallDungeonScore then
                local score = C_MythicPlus.GetOverallDungeonScore()
                NextKey222.Debug:Dev("keystones", "Blizzard API score for current player:", score)
                return score
            end
            
            -- Alternative API for player rating summary
            if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
                if summary and summary.currentSeasonScore then
                    NextKey222.Debug:Dev("keystones", "Blizzard API rating summary for current player:", summary.currentSeasonScore)
                    return summary.currentSeasonScore
                end
            end
        else
            -- For party members, try to get their rating summary
            if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                -- Try to find the unit ID for this player name
                local unitID = nil
                for i = 1, 4 do
                    local unit = "party" .. i
                    if UnitExists(unit) and UnitName(unit) == playerName then
                        unitID = unit
                        break
                    end
                end
                
                if unitID then
                    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unitID)
                    if summary and summary.currentSeasonScore then
                        NextKey222.Debug:Dev("keystones", "Blizzard API score for", playerName, ":", summary.currentSeasonScore)
                        return summary.currentSeasonScore
                    end
                end
            end
        end
        
        NextKey222.Debug:Dev("keystones", "No Blizzard API score available for", playerName)
        return nil
end

---@type table<string, function>
local Keystones = {
    ---Create a new keystone entry with optional RaiderIO data
    ---@param dungeonID number
    ---@param level number
    ---@param ownerName string
    ---@param ownerShort string?
    ---@param class string?
    ---@param source string?
    ---@return KeystoneEntry
    createKeyEntry = function(dungeonID, level, ownerName, ownerShort, class, source)
        local entry = {
            dungeonID = dungeonID,
            level = level or 2,
            ownerName = ownerName or "Unknown",
            ownerShort = ownerShort or ownerName or "Unknown",
            class = class or "WARRIOR",
            source = source or "other",
            timestamp = GetUtils().currentTime()
        }
        
        -- Try to get score from Blizzard API first (most up-to-date)
        local blizzardScore = getBlizzardMythicPlusScore(ownerName)
        if blizzardScore and blizzardScore > 0 then
            entry.rioScore = blizzardScore
            NextKey222.Debug:Dev("keystones", "Got Blizzard API score for", ownerName, ":", blizzardScore)
        else
            -- Fallback to RaiderIO data if Blizzard API unavailable
            if NextKey222.RaiderIO then
                local profile = NextKey222.RaiderIO:GetProfile(ownerName)
                NextKey222.Debug:Dev("keystones", "RaiderIO profile for", ownerName, ":", profile and "found" or "not found")
                if profile and profile.mythicKeystoneProfile then
                    local p = profile.mythicKeystoneProfile
                    entry.rioScore = p.currentScore
                    NextKey222.Debug:Dev("keystones", "Set RaiderIO score for", ownerName, "to", entry.rioScore)
                    
                    -- Get best runs for this dungeon
                    if p.fortifiedDungeonScores and p.tyrannicalDungeonScores then
                        entry.dungeonBest = {
                            fortified = p.fortifiedDungeonScores[dungeonID],
                            tyrannical = p.tyrannicalDungeonScores[dungeonID]
                        }
                        
                        -- Get score for current week's affix
                        local currentAffixID = C_MythicPlus.GetCurrentAffixes()
                        if currentAffixID and currentAffixID[1] then
                            local isFortified = currentAffixID[1] == 10 -- 10 is Fortified
                            entry.dungeonBest.currentAffixScore = isFortified 
                                and (entry.dungeonBest.fortified and entry.dungeonBest.fortified.score or 0)
                                or (entry.dungeonBest.tyrannical and entry.dungeonBest.tyrannical.score or 0)
                        end
                    end
                    
                    -- Get run counts
                    entry.runCounts = NextKey222.RaiderIO:GetRunCounts(profile)
                end
            end
        end
        
        return entry
    end,
    
    ---Deep copy a keystone entry
    ---@param key KeystoneEntry|number|table
    ---@return KeystoneEntry?
    copyKey = function(self, key)
        if not key then return nil end
        
        -- Handle case where key is just a dungeon ID number
        if type(key) == "number" then
            return Keystones.createKeyEntry(key, 2, "Unknown")
        end
        
        -- Handle case where key is just dungeonID and level
        if type(key) == "table" and not key.ownerName then
            return Keystones.createKeyEntry(
                key.dungeonID or 0,
                key.level or 2,
                "Unknown",
                nil,
                nil,
                key.source
            )
        end
        
        -- Copy full key entry
        return Keystones.createKeyEntry(
            key.dungeonID,
            key.level,
            key.ownerName,
            key.ownerShort,
            key.class,
            key.source
        )
    end
}

-- MARK: Keystone Scanning & Discovery

---Scan RaiderIO data for all party members
---@return KeystoneEntry[] keys Array of keystone entries with RaiderIO data
function NextKey:ScanPartyRaiderIO()
    NextKey222.Debug:Dev("keystones", "Enhanced party scan started")
    
    local keys = {}
    local memberType = IsInRaid() and "raid" or "party"
    local maxMembers = IsInRaid() and 40 or 5
    
    -- Track seen players to avoid duplicates
    local seen = {}
    
    for i = 1, maxMembers do
        local unit = i == 1 and "player" or memberType .. i
        local name = GetUtils().safeGetName(unit)
        NextKey222.Debug:Dev("keystones", "Checking party member", i, "unit:", unit, "name:", name or "nil")
        
        if name and not seen[name] and UnitExists(unit) then
            seen[name] = true
            
            -- Method 1: Try Blizzard API for owned keystone (current player only)
            local keystoneLevel, keystoneMapID = 0, 0
            if unit == "player" then
                keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
                -- FIXED: Use GetOwnedKeystoneChallengeMapID() instead of GetOwnedKeystoneMapID()
                keystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID() or 0
                NextKey222.Debug:Dev("keystones", "Blizzard API keystone for player:", keystoneLevel, keystoneMapID)
            end
            
            -- Method 2: Try active challenge mode detection
            if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo and unit == "player" then
                local level, affixes, wasEnergized = C_ChallengeMode.GetActiveKeystoneInfo()
                if level and level > 0 then
                    local activeMapID = C_ChallengeMode.GetActiveChallengeMapID()
                    NextKey222.Debug:Dev("keystones", "Active keystone detected:", level, activeMapID)
                    keystoneLevel = level
                    keystoneMapID = activeMapID
                end
            end
            
            -- Method 3: Get RaiderIO profile for additional data
            local profile = nil
            if NextKey222.RaiderIO then
                profile = NextKey222.RaiderIO:GetProfile(name)
                NextKey222.Debug:Dev("keystones", "RaiderIO profile for", name, ":", profile and "found" or "not found")
            end
            
            -- Create entry with detected or default keystone info
            local entry = Keystones.createKeyEntry(
                keystoneMapID, -- Use detected mapID or 0
                keystoneLevel, -- Use detected level or 0
                name,
                GetUtils().getShortName(name),
                GetUtils().safeGetClass(unit),
                keystoneLevel > 0 and "blizzard" or (profile and "rio" or "party")
            )
                
            if entry then
                NextKey222.Debug:Dev("keystones", "Created entry for", name, "with keystone level", keystoneLevel)
                table.insert(keys, entry)
            end
        end
    end
    
    NextKey222.Debug:Dev("keystones", "Enhanced party scan completed, found", #keys, "members")
    return keys
end

function NextKey:ScanPlayerKeystone()
    NextKey222.Debug:Dev("keystones", "Enhanced player keystone scan started")
    
    -- Method 1: Try LibOpenRaid Integration first (most comprehensive)
    if NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration:IsAvailable() then
        local libKeystone = NextKey222.LibOpenRaidIntegration:GetPlayerKeystone("player")
        if libKeystone then
            NextKey222.Debug:Dev("keystones", "Found keystone via LibOpenRaid Integration:", libKeystone.dungeonID, libKeystone.level)
            return libKeystone
        end
    end
    
    -- Method 2: Fallback to Blizzard APIs
    local mapID, level
    if C_MythicPlus then
        NextKey222.Debug:Dev("keystones", "Trying Blizzard API methods")
        
        -- FIXED: Use GetOwnedKeystoneChallengeMapID() instead of GetOwnedKeystoneMapID()
        -- GetOwnedKeystoneMapID() returns map IDs like 2773 (incorrect)
        -- GetOwnedKeystoneChallengeMapID() returns challenge mode IDs like 525 (correct)
        mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        level = C_MythicPlus.GetOwnedKeystoneLevel()
        
        NextKey222.Debug:Dev("keystones", "Blizzard API returned challenge mapID:", mapID or "nil", "level:", level or "nil")
        
        if mapID and mapID ~= 0 and level and level > 0 then
            -- No conversion needed - GetOwnedKeystoneChallengeMapID() returns the correct ID
            NextKey222.Debug:Dev("keystones", "Found keystone via Blizzard API - dungeonID:", mapID, "level:", level)
            -- Fall back to runtime name/short if boot hasn't populated playerFullName yet
            local runtimeName = GetUtils().safeGetName("player")
            local runtimeShort = GetUtils().getShortName(runtimeName)
            return {
                dungeonID = mapID,  -- Use challenge mode ID directly (matches portal data)
                level = level,
                ownerName = self.playerFullName or runtimeName,
                ownerShort = self.playerShortName or runtimeShort,
                class = self.playerClass,
                source = "blizzard-api",
                timestamp = GetUtils().currentTime()
            }
        else
            print("NextKey DEBUG: Modern API failed - mapID or level invalid")
        end
    else
        print("NextKey DEBUG: C_MythicPlus not available")
    end

    -- If the modern API fails, fall back to scanning bags manually
    print("NextKey DEBUG: Modern API failed, scanning bags.")
    
    if C_Container and C_MythicPlus and C_MythicPlus.IsMythicPlusKeystone then
        print("NextKey DEBUG: All bag scan APIs available")
        local itemsFound = 0
        for bag = 0, NUM_BAG_SLOTS do
            local slots = C_Container.GetContainerNumSlots(bag)
            print("NextKey DEBUG: Scanning bag", bag, "with", slots or 0, "slots")
            for slot = 1, slots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    itemsFound = itemsFound + 1
                    print("NextKey DEBUG: Found item", info.itemID, "checking if keystone")
                    if C_MythicPlus.IsMythicPlusKeystone(info.itemID) then
                        print("NextKey DEBUG: Found potential keystone in bags, itemID:", info.itemID)
                        if info.hyperlink then
                            print("NextKey DEBUG: Keystone has hyperlink, getting info")
                            -- Try to get keystone info from the item
                            local keystoneMapID, keystoneLevel = C_ChallengeMode.GetKeystoneInfo(info.hyperlink)
                            print("NextKey DEBUG: GetKeystoneInfo returned mapID:", keystoneMapID or "nil", "level:", keystoneLevel or "nil")
                            if keystoneMapID and keystoneMapID ~= 0 and keystoneLevel and keystoneLevel > 0 then
                                print("NextKey DEBUG: Keystone confirmed from bags")
                                mapID = keystoneMapID
                                level = keystoneLevel
                                break
                            end
                        else
                            print("NextKey DEBUG: Keystone has no hyperlink")
                        end
                    end
                end
            end
            if mapID and mapID ~= 0 then
                break
            end
        end
        print("NextKey DEBUG: Bag scan complete, found", itemsFound, "items total")
    else
        print("NextKey DEBUG: Missing bag scan APIs - C_Container:", C_Container and "yes" or "no", 
              "C_MythicPlus:", C_MythicPlus and "yes" or "no", 
              "IsMythicPlusKeystone:", C_MythicPlus and C_MythicPlus.IsMythicPlusKeystone and "yes" or "no")
    end

    if not mapID or mapID == 0 then
        print("NextKey DEBUG: No key found after all checks.")
        return nil
    end

    print(string.format("NextKey DEBUG: Found key %s, Level %d", self:GetDungeonName(mapID), level or 0))

    local owner = self.playerFullName or GetUtils().safeGetName("player")
    local class = self.playerClass ~= "" and self.playerClass or GetUtils().safeGetClass("player") or ""

    return {
        dungeonID = mapID,
        level = level or 0,
        ownerName = owner,
        ownerShort = self.playerShortName,
        class = class ~= "" and class or "EVOKER",
        source = "player",
        timestamp = GetUtils().currentTime(),
    }
end

-- MARK: Guild Keystone Collection
local guildKeystones = {} -- Cache for guild member keystones

-- Store a guild member's keystone data
function NextKey:StoreGuildKeystone(playerName, dungeonID, level, source)
    if not playerName or not dungeonID or not level then return end
    
    local shortName = playerName:match("^([^%-]+)") or playerName
    guildKeystones[shortName] = {
        dungeonID = dungeonID,
        level = level,
        ownerName = playerName,
        ownerShort = shortName,
        source = source or "guild-comm",
        timestamp = GetTime()
    }
    
    print("NextKey GUILD STORE: Stored keystone for", shortName, "- Level", level, "dungeon", dungeonID)
end

-- Get stored guild keystones
function NextKey:GetGuildKeystones()
    local keys = {}
    local currentTime = GetTime()
    
    -- Clean up old entries (older than 5 minutes)
    for playerName, keyData in pairs(guildKeystones) do
        if currentTime - keyData.timestamp > 300 then
            guildKeystones[playerName] = nil
        else
            table.insert(keys, keyData)
        end
    end
    
    return keys
end

-- Request keystones from guild members
function NextKey:RequestGuildKeystones()
    if not IsInGuild() then return false end
    
    NextKey222.Debug:Dev("keystones", "Requesting keystones from guild...")
    
    -- Send guild-wide request
    if NextKey222.Communications and NextKey222.Communications.SendGuildMessage then
        NextKey222.Communications:SendGuildMessage("KEYSTONE_REQUEST", "")
    end
    
    -- Also try LibOpenRaid as backup
    if NextKey222.LibOpenRaidIntegration then
        NextKey222.LibOpenRaidIntegration:RequestGuildKeystones()
    end
    
    return true
end



-- MARK: Keystone Collection & Management
function NextKey:CollectPartyKeys()
    local keys = {}
    local seen = {}

    local function addKey(entry)
        if not entry then return end
        -- Handle case where entry is just a dungeon ID number
        if type(entry) == "number" then
            entry = {
                dungeonID = entry,
                level = 2,  -- Default to +2 if unknown
                ownerName = "Unknown",
                class = "WARRIOR",
                ownerShort = "Unknown",
                source = "other",
                timestamp = GetUtils().currentTime()
            }
        elseif not entry.dungeonID then
            return  -- Still reject completely invalid entries
        end
        -- Allow dungeonID = 0 for party members without keystones
        entry.ownerName = entry.ownerName or "Unknown"
        entry.class = entry.class or "WARRIOR"
        entry.ownerShort = entry.ownerShort or entry.ownerName
        
        -- Normalize player name for deduplication (use short name as key)
        local normalizedOwner = entry.ownerShort or entry.ownerName:match("^([^%-]+)") or entry.ownerName
        
        -- Enhanced deduplication: check for player+level combination first
        local playerFingerprint = string.format("%s:%s", normalizedOwner, entry.level or 0)
        
        -- Check if we already have a keystone for this player at this level
        local existingIndex = nil
        for i, existingKey in ipairs(keys) do
            local existingNormalized = existingKey.ownerShort or existingKey.ownerName:match("^([^%-]+)") or existingKey.ownerName
            if existingNormalized == normalizedOwner and existingKey.level == entry.level then
                existingIndex = i
                break
            end
        end
        
        if existingIndex then
            local existingKey = keys[existingIndex]
            NextKey222.Debug:Dev("keystones", "Found duplicate keystone for", normalizedOwner, "level", entry.level)
            NextKey222.Debug:Dev("keystones", "  Existing: source=" .. (existingKey.source or "unknown") .. ", dungeonID=" .. (existingKey.dungeonID or 0))
            NextKey222.Debug:Dev("keystones", "  New: source=" .. (entry.source or "unknown") .. ", dungeonID=" .. (entry.dungeonID or 0))
            
            -- Define source priority (higher number = higher priority)
            local sourcePriority = {
                blizzard = 3,
                libopenraid = 2,
                rio = 1
            }
            
            local existingPriority = sourcePriority[existingKey.source] or 0
            local newPriority = sourcePriority[entry.source] or 0
            
            if newPriority > existingPriority then
                NextKey222.Debug:Dev("keystones", "  Replacing with higher priority source:", entry.source)
                keys[existingIndex] = Keystones.copyKey(entry)
            elseif newPriority == existingPriority and (entry.dungeonID or 0) > (existingKey.dungeonID or 0) then
                NextKey222.Debug:Dev("keystones", "  Replacing with better dungeonID:", entry.dungeonID, ">", existingKey.dungeonID)
                keys[existingIndex] = Keystones.copyKey(entry)
            else
                NextKey222.Debug:Dev("keystones", "  Keeping existing keystone")
            end
            return
        end
        
        NextKey222.Debug:Dev("keystones", "Added new keystone:", entry.ownerName, "->", normalizedOwner, "level:", entry.level, "source:", entry.source)
        table.insert(keys, Keystones.copyKey(entry))
    end

    local playerKey = self:ScanPlayerKeystone()
    if playerKey then
        if type(playerKey) == "number" then
            playerKey = Keystones.createKeyEntry(playerKey, 2, self.playerFullName)
        end
        addKey(playerKey)
        self.playerKeystone = Keystones.copyKey(playerKey)
        NextKey222.Debug:Dev("keystones", "Player keystone detected:", playerKey.dungeonID, "level", playerKey.level)
    else
        self.playerKeystone = nil
    end

    -- Add keystones from LibOpenRaid Integration (primary source)
    local openRaidKeys = 0
    NextKey222.Debug:Dev("keystones", "Checking LibOpenRaid integration availability...")
    NextKey222.Debug:Dev("keystones", "  NextKey222.LibOpenRaidIntegration:", NextKey222.LibOpenRaidIntegration and "exists" or "nil")
    
    if NextKey222.LibOpenRaidIntegration then
        NextKey222.Debug:Dev("keystones", "  NextKey222.LibOpenRaidIntegration:IsAvailable():", NextKey222.LibOpenRaidIntegration:IsAvailable() and "true" or "false")
        if NextKey222.LibOpenRaidIntegration:IsAvailable() then
            NextKey222.Debug:Dev("keystones", "Calling LibOpenRaidIntegration:GetAllKeystones()...")
            local libKeystones = NextKey222.LibOpenRaidIntegration:GetAllKeystones()
            NextKey222.Debug:Dev("keystones", "LibOpenRaid integration returned keystones:", libKeystones and "data" or "nil")
            
            if libKeystones then
                for playerName, keyData in pairs(libKeystones) do
                    NextKey222.Debug:Dev("keystones", "Processing LibOpenRaid keystone for:", playerName)
                    NextKey222.Debug:Dev("keystones", "  keyData.dungeonID:", keyData.dungeonID)
                    NextKey222.Debug:Dev("keystones", "  keyData.level:", keyData.level)
                    addKey(keyData)
                    openRaidKeys = openRaidKeys + 1
                    NextKey222.Debug:Dev("keystones", "Added LibOpenRaid keystone:", playerName, keyData.dungeonID, keyData.level)
                end
            else
                NextKey222.Debug:Dev("keystones", "LibOpenRaid integration returned no keystones (empty or nil)")
            end
        else
            NextKey222.Debug:Dev("keystones", "LibOpenRaid integration is not available")
        end
    else
        NextKey222.Debug:Dev("keystones", "LibOpenRaid integration reference not set")
    end
    NextKey222.Debug:Dev("keystones", "LibOpenRaid integration keys added:", openRaidKeys)
    
    -- Add stored guild keystones if available
    local guildKeys = self:GetGuildKeystones()
    if guildKeys and #guildKeys > 0 then
        NextKey222.Debug:Dev("keystones", "Adding stored guild keystones:", #guildKeys)
        for _, guildKey in ipairs(guildKeys) do
            NextKey222.Debug:Dev("keystones", "Adding guild keystone:", guildKey.ownerName, guildKey.dungeonID, guildKey.level)
            addKey(guildKey)
        end
    else
        NextKey222.Debug:Dev("keystones", "No stored guild keystones available")
    end
    
    -- Legacy support: Add from old receivedKeys if still present
    if type(self.receivedKeys) == "table" then
        for _, entry in pairs(self.receivedKeys) do
            addKey(entry)
        end
    end

    -- Request keystones via LibOpenRaid Integration
    if IsInGroup() and NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration:IsAvailable() then
        NextKey222.Debug:Dev("keystones", "Requesting keystones via LibOpenRaid integration")
        NextKey222.LibOpenRaidIntegration:RequestKeystones()
    end

    -- Scan RaiderIO for party members who haven't sent keys
    local rioEntries = self:ScanPartyRaiderIO()
    for _, entry in ipairs(rioEntries) do
        -- Only add entry if we don't already have a key for this player
        local fingerprint = entry.ownerName .. ":"
        if not seen[fingerprint] then
            addKey(entry)
        end
    end

    -- Debug keys handled by FakePlayerService (when debug mode OR basic tools enabled)
    local debugEnabled = self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled
    local basicToolsEnabled = self.db and self.db.global and self.db.global.debug and self.db.global.debug.basicToolsEnabled
    
    if (debugEnabled or basicToolsEnabled) and NextKey222.FakePlayerService then
        local fakePlayers = NextKey222.FakePlayerService:GetAllPlayers()
        NextKey222.Debug:Dev("keystones", "Checking fake players from FakePlayerService, count:", fakePlayers and #fakePlayers or "nil")
        if fakePlayers and type(fakePlayers) == "table" then
            for i, player in ipairs(fakePlayers) do
                -- FakePlayerService stores keystone in 'keystone' field, not 'key'
                local keystone = player.keystone or player.key
                if keystone and keystone.dungeonID then
                    addKey({
                        dungeonID = keystone.dungeonID,
                        level = keystone.level,
                        ownerName = player.name,
                        ownerShort = player.name,
                        class = player.class,
                        io = player.io or 0,
                        source = "debug",
                        timestamp = GetUtils().currentTime(),
                        dungeonScores = player.dungeonScores,  -- Include dungeon scores for detailed IO data
                        addonStatus = player.addonStatus,      -- Include addon status
                    })
                    NextKey222.Debug:Dev("keystones", "Fake player key added:", player.name, "class:", player.class, "-", keystone.dungeonID, "level", keystone.level, "IO:", player.io or 0)
                else
                    -- Even players without keystones should appear in the list
                    addKey({
                        dungeonID = 0,  -- No keystone
                        level = 0,
                        ownerName = player.name,
                        ownerShort = player.name,
                        class = player.class,
                        io = player.io or 0,
                        source = "debug",
                        timestamp = GetUtils().currentTime(),
                        dungeonScores = player.dungeonScores,
                        addonStatus = player.addonStatus,
                    })
                    NextKey222.Debug:Dev("keystones", "Fake player (no key) added:", player.name, "class:", player.class, "IO:", player.io or 0)
                end
            end
            
            -- Trigger UI refresh if fake players were added and UI is visible
            if #fakePlayers > 0 then
                if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
                    NextKey222.Debug:Dev("keystones", "Fake players detected - triggering UI refresh")
                    C_Timer.After(0.1, function()
                        if NextKey222.UI.RefreshResults then
                            NextKey222.UI:RefreshResults()
                        end
                    end)
                end
            end
        else
            NextKey222.Debug:Dev("keystones", "FakePlayerService returned no players or invalid data")
        end
    end

    table.sort(keys, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

    -- Debug summary of collected keystones
    NextKey222.Debug:Dev("keystones", "Collected", #keys, "total keystones")
    local sourceCounts = {}
    for i, key in ipairs(keys) do
        local source = key.source or "unknown"
        sourceCounts[source] = (sourceCounts[source] or 0) + 1
        NextKey222.Debug:Dev("keystones", string.format("Key %d: %s - %s +%d (source: %s)", i, key.ownerName or "nil", key.dungeonID or "nil", key.level or 0, source))
    end
    
    NextKey222.Debug:Dev("keystones", "Keys by source:")
    for source, count in pairs(sourceCounts) do
        NextKey222.Debug:Dev("keystones", string.format("  %s: %d", source, count))
    end

    -- If in guild mode or no party members, also collect guild keystones
    if (NextKey222.UI and NextKey222.UI.showGuildKeys) or #keys <= 1 then
        -- NOTE: Don't request keystones here - that's triggered by UI toggle
        -- This function is called during rendering and would create infinite loops
        
        -- Get keystones from both NextKey cache and LibOpenRaid
        local guildKeys = self:GetGuildKeystones()
        NextKey222.Debug:Dev("keystones", "Found", #guildKeys, "cached guild keystones from NextKey")
        
        -- Also get keystones directly from LibOpenRaid
        local libOpenRaidKeys = {}
        if NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration.GetLibOpenRaid then
            local openRaidLib = NextKey222.LibOpenRaidIntegration:GetLibOpenRaid()
            if openRaidLib.GetAllKeystonesInfo then
                local allKeystones = openRaidLib.GetAllKeystonesInfo()
                NextKey222.Debug:Dev("keystones", "Checking LibOpenRaid keystones...")
                for playerName, keystoneInfo in pairs(allKeystones) do
                    if keystoneInfo.level and keystoneInfo.level > 0 then
                        NextKey222.Debug:Dev("keystones", "Found LibOpenRaid keystone:", playerName, "Level", keystoneInfo.level)
                        NextKey222.Debug:Dev("keystones", "Raw keystone data - mapID:", keystoneInfo.mapID, "mythicPlusMapID:", keystoneInfo.mythicPlusMapID, "challengeMapID:", keystoneInfo.challengeMapID)
                        
                        -- Convert to NextKey format using mythicPlusMapID first (like Details! does)
                        local dungeonID = keystoneInfo.mythicPlusMapID or keystoneInfo.challengeMapID or keystoneInfo.mapID or 0
                        local shortName = playerName:match("^([^%-]+)") or playerName
                        
                        -- Map mythicPlusMapID to NextKey's dungeon system if needed
                        local mappedDungeonID = dungeonID
                        local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
                        if next(dungeons) then
                            -- Try to find a mapping for the mythicPlusMapID
                            for nkDungeonID, dungeonData in pairs(dungeons) do
                                if (dungeonData.mythicPlusMapID and dungeonData.mythicPlusMapID == dungeonID) or 
                                   (dungeonData.mapID and dungeonData.mapID == dungeonID) or
                                   (dungeonData.challengeMapID and dungeonData.challengeMapID == dungeonID) then
                                    mappedDungeonID = nkDungeonID
                                    NextKey222.Debug:Dev("keystones", "Mapped mythicPlusMapID", dungeonID, "to NextKey dungeonID", nkDungeonID, "(", dungeonData.name or "Unknown", ")")
                                    break
                                end
                            end
                            
                            -- If no mapping found, keep the original ID but log it
                            if mappedDungeonID == dungeonID and dungeonID > 0 then
                                NextKey222.Debug:Dev("keystones", "No mapping found for mythicPlusMapID", dungeonID, "- using as-is")
                            end
                        end
                        
                        local libKey = {
                            dungeonID = mappedDungeonID,
                            level = keystoneInfo.level,
                            ownerName = playerName,
                            ownerShort = shortName,
                            classID = keystoneInfo.classID,
                            class = keystoneInfo.classID and select(2, GetClassInfo(keystoneInfo.classID)) or "WARRIOR",
                            rating = keystoneInfo.rating or 0,
                            source = "libopenraid-direct",
                            timestamp = GetTime()
                        }
                        table.insert(libOpenRaidKeys, libKey)
                    end
                end
            end
        end
        NextKey222.Debug:Dev("keystones", "Found", #libOpenRaidKeys, "LibOpenRaid keystones")
        
        -- Combine both sources
        local allGuildKeys = {}
        for _, key in ipairs(guildKeys) do
            table.insert(allGuildKeys, key)
        end
        for _, key in ipairs(libOpenRaidKeys) do
            table.insert(allGuildKeys, key)
        end
        
        NextKey222.Debug:Dev("keystones", "Total guild keystones to process:", #allGuildKeys)
        
        for _, guildKey in ipairs(allGuildKeys) do
            local normalizedOwner = guildKey.ownerShort or guildKey.ownerName:match("^([^%-]+)") or guildKey.ownerName
            NextKey222.Debug:Dev("keystones", "Processing keystone from", guildKey.ownerName, "normalized:", normalizedOwner, "level:", guildKey.level)
            
            -- Check if we already have this player's keystone
            local alreadyExists = false
            for _, existingKey in ipairs(keys) do
                local existingNormalized = existingKey.ownerShort or existingKey.ownerName:match("^([^%-]+)") or existingKey.ownerName
                NextKey222.Debug:Dev("keystones", "Comparing with existing key:", existingKey.ownerName, "normalized:", existingNormalized)
                if existingNormalized == normalizedOwner then
                    alreadyExists = true
                    NextKey222.Debug:Dev("keystones", "Duplicate found, skipping")
                    break
                end
            end
            
            if not alreadyExists then
                NextKey222.Debug:Dev("keystones", "Attempting to copy keystone:", guildKey.ownerName, "Level", guildKey.level, "DungeonID", guildKey.dungeonID)
                local copied = Keystones.copyKey(guildKey)
                if copied then
                    table.insert(keys, copied)
                    NextKey222.Debug:Dev("keystones", "Successfully added guild keystone from", guildKey.ownerName, "Level", copied.level, "Dungeon", copied.dungeonID)
                    NextKey222.Debug:Dev("keystones", "Copied keystone data:", "ownerName=", copied.ownerName, "level=", copied.level, "dungeonID=", copied.dungeonID, "source=", copied.source)
                else
                    NextKey222.Debug:Dev("keystones", "Failed to copy keystone from", guildKey.ownerName, "- copyKey returned nil")
                end
            else
                NextKey222.Debug:Dev("keystones", "Skipped duplicate keystone from", guildKey.ownerName)
            end
        end
    end

    self.cachedKeys = keys
    return keys
end

function NextKey:GetAvailableKeys()
    NextKey222.Debug:Dev("keystones", "GetAvailableKeys called")

    local keys = self:CollectPartyKeys()
    if not keys then 
        NextKey222.Debug:Dev("keystones", "No keys returned from CollectPartyKeys")
        return {} 
    end
    
    NextKey222.Debug:Dev("keystones", "Initial keys collected:", #keys)
    for i, key in ipairs(keys) do
        NextKey222.Debug:Dev("keystones", "Initial key", i .. ":", key.ownerName or "Unknown", "source:", key.source or "Unknown")
    end
    
    local copy = {}
    if type(keys) == "table" then
        for i, entry in ipairs(keys) do
            if entry then

                
                local copied = Keystones.copyKey(entry)
                if copied then
                    table.insert(copy, copied)

                end
            end
        end
    end
    
    -- If Guild view is enabled, restrict to online guild members and exclude the player
    if NextKey222.UI and NextKey222.UI.showGuildKeys then
        NextKey222.Debug:Dev("keystones", "Guild view enabled, filtering keys")
        local onlineGuild = self:GetOnlineGuildMemberNames(false) -- include player in the set
        local myShort = self.playerShortName or (GetUtils().getShortName(GetUtils().safeGetName("player")))
        
        NextKey222.Debug:Dev("keystones", "Online guild members:")
        local guildCount = 0
        for member, _ in pairs(onlineGuild) do
            guildCount = guildCount + 1
            NextKey222.Debug:Dev("keystones", "  ", member)
        end
        NextKey222.Debug:Dev("keystones", "Total online guild members:", guildCount)
        NextKey222.Debug:Dev("keystones", "My short name:", myShort)
        NextKey222.Debug:Dev("keystones", "Keys to filter (before):", #copy)
        
        local guildFiltered = {}
        for _, key in ipairs(copy) do
            local owner = key and key.ownerName
            local short = owner and owner:match("^([^%-]+)") or owner or ""
            local isGuildMember = onlineGuild[short]
            local isMe = short == myShort
            
            NextKey222.Debug:Dev("keystones", "Key owner:", owner, "Short:", short, "IsGuildMember:", isGuildMember, "IsMe:", isMe)
            
            if owner and owner ~= "Unknown" and (isGuildMember or isMe) then
                table.insert(guildFiltered, key)
                NextKey222.Debug:Dev("keystones", "Including key from", owner)
            else
                NextKey222.Debug:Dev("keystones", "Filtering out in guild view:", owner or "nil", key and (key.source or "?") or "?")
                NextKey222.Debug:Dev("keystones", "Filtering out key from", owner or "nil")
            end
        end
        NextKey222.Debug:Dev("keystones", "Keys after guild filtering:", #guildFiltered)
        copy = guildFiltered
    end

    -- Apply guild/party filtering if UI is available
    if NextKey222.UI and not NextKey222.UI.showGuildKeys then
        NextKey222.Debug:Dev("keystones", "Filtering to party members only")
        local filteredCopy = {}
        local partyMembers = self:GetPartyMemberNames()
        local seenPlayers = {}  -- Track seen players to avoid duplicates
        
        for i, key in ipairs(copy) do
                local playerName = key.ownerName or ""
                local isPartyMember = false
                
                NextKey222.Debug:Dev("keystones", "Checking keystone from:", playerName)
                
                -- Check against all party members (both short and full names)
                for _, partyMember in pairs(partyMembers) do
                    local partyShort = partyMember:match("^([^%-]+)") or partyMember
                    local playerShort = playerName:match("^([^%-]+)") or playerName
                    
                    -- Match by full name or short name
                    if playerName == partyMember or playerShort == partyShort then
                        isPartyMember = true
                        NextKey222.Debug:Dev("keystones", "  Matched party member:", partyMember)
                        break
                    end
                end
                
                if isPartyMember then
                    -- Additional deduplication: only keep the best keystone per player
                    local playerShort = playerName:match("^([^%-]+)") or playerName
                    local existingKey = seenPlayers[playerShort]
                    
                    if not existingKey then
                        -- First keystone for this player
                        seenPlayers[playerShort] = key
                        table.insert(filteredCopy, key)
                        NextKey222.Debug:Dev("keystones", "  Added first keystone for:", playerShort)
                    else
                        -- Compare keystones and keep the better one
                        local shouldReplace = false
                        
                        -- Priority 1: Higher level keystone
                        if (key.level or 0) > (existingKey.level or 0) then
                            shouldReplace = true
                            NextKey222.Debug:Dev("keystones", "  Replacing with higher level:", key.level, ">", existingKey.level)
                        elseif (key.level or 0) == (existingKey.level or 0) then
                            -- Priority 2: Better dungeonID (non-zero preferred)
                            if (key.dungeonID or 0) > (existingKey.dungeonID or 0) then
                                shouldReplace = true
                                NextKey222.Debug:Dev("keystones", "  Replacing with better dungeonID:", key.dungeonID, ">", existingKey.dungeonID)
                            end
                        end
                        
                        if shouldReplace then
                            -- Replace the existing keystone
                            for j, existingEntry in ipairs(filteredCopy) do
                                if existingEntry == existingKey then
                                    filteredCopy[j] = key
                                    seenPlayers[playerShort] = key
                                    break
                                end
                            end
                        end
                        NextKey222.Debug:Dev("keystones", "  Duplicate keystone", shouldReplace and "replaced" or "ignored", "for:", playerShort)
                    end
                else
                    NextKey222.Debug:Dev("keystones", "  Filtered out non-party member:", playerName)
                end
            end
            
        copy = filteredCopy
        NextKey222.Debug:Dev("keystones", "After filtering: " .. #copy .. " keys remaining")
    end
    
    -- Available keys processed (debug output removed for performance)
    
    -- Include party members without keystones as "No Keystone" entries
    -- Note: Only inject these placeholders when we're showing party-only view.
    -- In Guild view, we should not add party placeholders as it can be misleading.
    local skipPlaceholders = NextKey222.UI and NextKey222.UI.showGuildKeys
    -- Build a quick lookup of players already present
    local presentShort = {}
    for _, key in ipairs(copy or {}) do
        local playerName = key.ownerName or ""
        local playerShort = playerName:match("^([^%-]+)") or playerName
        presentShort[playerShort] = true
    end

    -- Build a lookup for debug player metadata (class/io) if available
    local dbgMeta = {}
    if self.db and self.db.global and self.db.global.debug and type(self.db.global.debug.players) == "table" then
        for _, p in ipairs(self.db.global.debug.players) do
            if p and p.name then
                dbgMeta[p.name] = { class = p.class, io = p.io }
            end
        end
    end

    if not skipPlaceholders then
        local partyMembers = self:GetPartyMemberNames() or {}
        for _, memberName in ipairs(partyMembers) do
            local short = memberName:match("^([^%-]+)") or memberName
            if not presentShort[short] then
                -- Create a placeholder entry for UI; no dungeonID/level
                local classToken
                local meta = dbgMeta[memberName] or dbgMeta[short]
                if meta and meta.class then
                    classToken = meta.class
                end
                table.insert(copy, {
                    ownerName = memberName,
                    ownerShort = short,
                    dungeonID = nil,
                    level = 0,
                    class = classToken,
                    io = meta and meta.io or 0,
                    source = "party-nokey",
                    timestamp = GetUtils().currentTime(),
                })
            end
        end
    end

    -- As a final guard: when in Guild view, drop any entries with missing/unknown owner
    -- (These can come from legacy caches or malformed data.)
    if NextKey222.UI and NextKey222.UI.showGuildKeys then
        local cleaned = {}
        for _, key in ipairs(copy or {}) do
            local owner = key and key.ownerName
            if owner and owner ~= "Unknown" and owner ~= "" then
                table.insert(cleaned, key)
            else
                NextKey222.Debug:Dev("keystones", "Dropping entry with unknown owner in guild view:", tostring(key and key.dungeonID), tostring(key and key.level), key and (key.source or "?"))
            end
        end
        copy = cleaned
    end

    return copy
end

-- MARK: Party Member Detection
function NextKey:GetPartyMemberNames()
    local partyMembers = {}
    local currentRealm = GetRealmName()
    
    -- Add the current player (with full name)
    local playerName = UnitName("player")
    if playerName then
        local playerFullName = playerName
        if not string.find(playerName, "-") and currentRealm then
            playerFullName = playerName .. "-" .. currentRealm
        end
        table.insert(partyMembers, playerFullName)
        NextKey222.Debug:Dev("keystones", "Added current player:", playerFullName)
    end
    
    -- Add party members
    if IsInGroup() then
        local numMembers = GetNumGroupMembers()
        for i = 1, numMembers do
            local unitId = IsInRaid() and "raid" .. i or "party" .. i
            if UnitExists(unitId) then
                local memberName = GetUnitName(unitId, true) -- Include realm
                if memberName then
                    -- Ensure full name with realm
                    if not string.find(memberName, "-") and currentRealm then
                        memberName = memberName .. "-" .. currentRealm
                    end
                    
                    -- Avoid duplicating the player
                    local isPlayer = false
                    for _, existingMember in pairs(partyMembers) do
                        if memberName == existingMember then
                            isPlayer = true
                            break
                        end
                    end
                    
                    if not isPlayer then
                        table.insert(partyMembers, memberName)
                        NextKey222.Debug:Dev("keystones", "Added party member:", memberName)
                    end
                end
            end
        end
    end
    
    -- In debug mode OR basic tools mode, add fake players as if they were party members
    local debugEnabled = self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled
    local basicToolsEnabled = self.db and self.db.global and self.db.global.debug and self.db.global.debug.basicToolsEnabled
    
    if (debugEnabled or basicToolsEnabled) then
        if NextKey222.FakePlayerService then
            local fakePlayers = NextKey222.FakePlayerService:GetAllPlayers()
            if fakePlayers and type(fakePlayers) == "table" then
                for i, player in ipairs(fakePlayers) do
                    if player and player.name then
                        -- Add fake player name to party members list
                        table.insert(partyMembers, player.name)
                        NextKey222.Debug:Dev("keystones", "Added fake player as party member:", player.name)
                    end
                end
            end
        end
    end
    
    NextKey222.Debug:Dev("keystones", "Final party members (" .. #partyMembers .. "):", table.concat(partyMembers, ", "))
    return partyMembers
end

---Get a set of short names for online guild members
---@param excludePlayer boolean? if true, the current player will be excluded
---@return table<string, boolean> set map of shortName => true
function NextKey:GetOnlineGuildMemberNames(excludePlayer)
    local set = {}
    if not IsInGuild or not IsInGuild() then
        return set
    end
    -- Ask the client to refresh roster data (non-blocking)
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        pcall(C_GuildInfo.GuildRoster)
    end
    local num = GetNumGuildMembers and GetNumGuildMembers() or 0
    local myShort = self.playerShortName or (GetUtils().getShortName(GetUtils().safeGetName("player")))
    for i = 1, num do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and online then
            local short = name:match("^([^%-]+)") or name
            if not (excludePlayer and short == myShort) then
                set[short] = true
            end
        end
    end
    return set
end

-- MARK: Keystone Selection
function NextKey:GetSelectedTeleportKey()
    return self.teleportTargetKey
end

function NextKey:IsKeySelected(key)
    if not self.teleportTargetKey or not key then
        return false
    end
    return self.teleportTargetKey.dungeonID == key.dungeonID
        and self.teleportTargetKey.level == key.level
        and self.teleportTargetKey.ownerName == key.ownerName
end

function NextKey:GetTeleportTargetKey()
    if self.teleportTargetKey then
        return self.teleportTargetKey
    end
    return self:ScanPlayerKeystone()
end

function NextKey:SetTeleportTargetKey(key, opts)
    opts = opts or {}
    local same = self:IsKeySelected(key)

    if key and key.dungeonID then
        self.teleportTargetKey = Keystones.copyKey({
            dungeonID = key.dungeonID,
            level = key.level,
            ownerName = key.ownerName,
            ownerShort = key.ownerShort,
            class = key.class,
            io = key.io,
            source = opts.source or key.source,
            receivedFrom = opts.receivedFrom,
            timestamp = GetUtils().currentTime(),
        })
        
        -- DEBUG: Log teleport target setting
        NextKey222.Debug:User("SetTeleportTargetKey: " .. (key.ownerName or "Unknown") .. " - " ..
                              (self:GetDungeonName(key.dungeonID) or "Unknown") ..
                              " +" .. (key.level or 0) .. " (source: " .. (key.source or "unknown") .. ")")
    else
        self.teleportTargetKey = nil
        NextKey222.Debug:User("SetTeleportTargetKey: Cleared teleport target")
    end

    -- When leader (or solo) chooses a key and broadcast=true, share the selection via addon comms
    if opts.broadcast and self:IsLeaderOrSolo() and key and key.dungeonID and key.level then
        if NextKey222.Communications and NextKey222.Communications.BroadcastTeleportSelection then
            NextKey222.Communications:BroadcastTeleportSelection(self.teleportTargetKey)
        else
            NextKey222.Debug:Dev("keystones", "BroadcastTeleportSelection not available; teleport selection not synced")
        end
    end

    -- Always update the local teleport window with the latest selection
    if type(self.RefreshTeleportWindow) == "function" then
        self:RefreshTeleportWindow()
    end

    -- Don't trigger UI refresh for dungeon portal fake keystones to prevent view switching
    local isDungeonPortal = key and key.source == "dungeon_portal"
    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame and not same and not isDungeonPortal then
        NextKey222.UI:RenderResults()
    end
end

function NextKey:SetTeleportWindowContext(context)
    Debug:Dev("teleport", "SetTeleportWindowContext called with mode:", context and context.mode or "nil")
    self.teleportWindowContext = context
    
    -- Refresh the teleport window if it's open to apply the new context
    if self.RefreshTeleportWindow then
        self:RefreshTeleportWindow()
    end
end

function NextKey:GetTeleportWindowContext()
    return self.teleportWindowContext
end

function NextKey:ClearTeleportWindowContext()
    self.teleportWindowContext = nil
    Debug:Dev("teleport", "Teleport window context cleared.")
    
    -- Refresh the teleport window if it's open to remove contextual elements
    if self.RefreshTeleportWindow then
        self:RefreshTeleportWindow()
    end
end

-- MARK: Utility Functions
function NextKey:IsPlayerOwner(owner)
    if not owner then
        return false
    end
    if owner == self.playerFullName then
        return true
    end
    if owner == self.playerShortName then
        return true
    end
    return owner == UnitName("player")
end

function NextKey:IsLeaderOrSolo()
    local dbg = self.db and self.db.global and self.db.global.debug
    if dbg and dbg.enabled and dbg.simNotLeader then
        return false
    end

    if not IsInGroup or not IsInGroup() then
        return true
    end

    if UnitIsGroupLeader then
        return UnitIsGroupLeader("player")
    end

    if UnitIsGroupAssistant and UnitIsGroupAssistant("player") then
        return true
    end

    return false
end

function Keystones.copyKey(entry)
    return {
        dungeonID = entry.dungeonID,
        level = entry.level,
        ownerName = entry.ownerName,
        ownerShort = entry.ownerShort,
        class = entry.class,
        io = entry.io,
        source = entry.source,
        receivedFrom = entry.receivedFrom,
        timestamp = entry.timestamp,
    }
end

-- MARK: Dungeon Teleport Handler
function NextKey:HandleTeleportClick(dungeonID, dungeonData)
    NextKey222.Debug:Dev("keystones", "Teleport requested for dungeon:", dungeonData.name)
    
    -- Direct spell cast if spell ID available
    local spellID = dungeonData.spellID
    if spellID then
        -- Try spell casting with error handling
        local success, errorMsg = pcall(function()
            if C_Spell and C_Spell.GetSpellInfo then
                -- Modern API
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                if spellInfo and spellInfo.name then
                    self:Print(string.format("Casting %s to %s", spellInfo.name, dungeonData.name))
                    if CastSpellByName then
                        CastSpellByName(spellInfo.name)
                        return true
                    end
                end
            end
            
            -- Fallback: Use spell name if we know it
            if dungeonData.spellName and CastSpellByName then
                self:Print(string.format("Casting %s to %s", dungeonData.spellName, dungeonData.name))
                CastSpellByName(dungeonData.spellName)
                return true
            end
            
            return false
        end)
        
        if not success then
            self:Print(string.format("Teleport spell not available for %s", dungeonData.name))
            -- Show teleport window as fallback
            if NextKey222.TeleportWindow then
                NextKey222.TeleportWindow:Show()
            end
        end
    else
        self:Print("No teleport spell ID configured for " .. dungeonData.name)
    end
end

-- MARK: Dungeon Loot Handler
function NextKey:HandleLootClick(dungeonID, dungeonData)
    NextKey222.Debug:Dev("keystones", "Loot window requested for dungeon:", dungeonData.name)
    
    -- Placeholder for future loot window integration
    self:Print(string.format("Loot tracking for %s - Coming Soon!", dungeonData.name))
    
    -- TODO: Integrate with loot tracking system
    -- if NextKey222.LootWindow then
    --     NextKey222.LootWindow:Show(dungeonID)
    -- end
end

-- Scan player's current keystone (NextKey222 namespace version)
function Keystones:ScanPlayerKeystone()
    -- Delegate to the global NextKey function for compatibility
    local NextKey = NextKey222.Addon
    if NextKey and NextKey.ScanPlayerKeystone then
        NextKey222.Debug:Dev("keystones", "Delegating ScanPlayerKeystone to NextKey.Addon")
        return NextKey:ScanPlayerKeystone()
    end
    
    NextKey222.Debug:Error("ScanPlayerKeystone: NextKey.Addon not available")
    return nil
end

-- Request keystones from guild members (Details!-style implementation)
function Keystones:RequestGuildKeystones()
    if not IsInGuild() then
        NextKey222.Debug:Dev("keystones", "Not in guild - cannot request keystones")
        return false
    end
    
    -- Throttle: Don't send requests more than once every 10 seconds
    local currentTime = GetTime()
    if self.lastGuildKeystoneRequest and (currentTime - self.lastGuildKeystoneRequest) < 10 then
        local cooldown = 10 - (currentTime - self.lastGuildKeystoneRequest)
        NextKey222.Debug:Dev("keystones", string.format("Guild keystone request throttled (%.1fs remaining)", cooldown))
        return false
    end
    
    self.lastGuildKeystoneRequest = currentTime
    NextKey222.Debug:Dev("keystones", "Requesting keystones from guild members...")
    
    -- Update guild roster first (like Details! does)
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
        NextKey222.Debug:Dev("keystones", "Updated guild roster")
    end
    
    -- Primary method: Use LibOpenRaid integration
    if NextKey222.LibOpenRaidIntegration and NextKey222.LibOpenRaidIntegration.RequestGuildKeystones then
        local success = NextKey222.LibOpenRaidIntegration:RequestGuildKeystones()
        if success then
            NextKey222.Debug:Dev("keystones", "LibOpenRaid guild request sent")
        else
            NextKey222.Debug:Dev("keystones", "LibOpenRaid guild request failed")
        end
    else
        NextKey222.Debug:Dev("keystones", "LibOpenRaid integration not available")
    end
    
    -- Backup method: Use our custom communication system
    if NextKey222.Communications and NextKey222.Communications.RequestGuildKeystones then
        local commSuccess = NextKey222.Communications:RequestGuildKeystones()
        NextKey222.Debug:Dev("keystones", "NextKey communication request:", commSuccess and "sent" or "throttled")
    end
    
    return true
end

-- MARK: Visual Testing Functions

---Visual test for keystone detection and management
---Follows "In-Game First" testing protocol
function Keystones:TestVisualDetection()
    NextKey222.Debug:Dev("keystones", "Starting visual keystone detection test")
    
    -- Create visual test frame for user interaction
    local testFrame = CreateFrame("Frame", "NextKeyKeystoneTestFrame", UIParent, "BackdropTemplate")
    testFrame:SetSize(400, 300)
    testFrame:SetPoint("CENTER")
    testFrame:SetFrameStrata("DIALOG")
    testFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title
    local title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Visual Keystone Detection Test")
    
    -- Instructions
    local instructions = testFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", title, "BOTTOM", 0, -15)
    instructions:SetWidth(380)
    instructions:SetText("This test validates keystone detection through visual confirmation:\n\n" ..
                       "1. Check your bags for a keystone\n" ..
                       "2. Open the main NextKey window (/nk)\n" ..
                       "3. Verify your keystone appears in the list\n" ..
                       "4. Hover over the keystone to see tooltip details\n\n" ..
                       "Expected visual results:\n" ..
                       "• Your keystone should be detected and displayed\n" ..
                       "• Dungeon name and level should be correct\n" ..
                       "• Tooltip should show detailed information\n" ..
                       "• IO score should be calculated if available")
    
    -- Test buttons
    local scanButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    scanButton:SetSize(120, 25)
    scanButton:SetPoint("BOTTOMLEFT", 20, 20)
    scanButton:SetText("Scan Now")
    scanButton:SetScript("OnClick", function()
        NextKey222.Debug:Dev("keystones", "Manual keystone scan triggered")
        
        -- Trigger keystone scan
        local NextKey = NextKey222.Addon
        if NextKey and NextKey.CollectPartyKeys then
            local keys = NextKey:CollectPartyKeys()
            NextKey222.Debug:Dev("keystones", "Scan found", #keys, "keystones")
            
            -- Show visual feedback
            for i, key in ipairs(keys) do
                if NextKey:IsPlayerOwner(key.ownerName) then
                    NextKey:User("Found your keystone: " .. (NextKey:GetDungeonName(key.dungeonID) or "Unknown") .. " +" .. (key.level or 0))
                end
            end
        end
    end)
    
    local openMainButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    openMainButton:SetSize(120, 25)
    openMainButton:SetPoint("BOTTOMRIGHT", -20, 20)
    openMainButton:SetText("Open NextKey")
    openMainButton:SetScript("OnClick", function()
        -- Open main NextKey window
        if NextKey222.UI and NextKey222.UI.ToggleMainFrame then
            NextKey222.UI:ToggleMainFrame()
        else
            NextKey222.Debug:Error("Main UI not available")
        end
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, testFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        testFrame:Hide()
    end)
    
    testFrame:Show()
    
    -- Auto-refresh timer
    local timer = 0
    testFrame:SetScript("OnUpdate", function(self, elapsed)
        timer = timer + elapsed
        if timer >= 5 then
            timer = 0
            -- Periodically check for keystore changes
            local NextKey = NextKey222.Addon
            if NextKey and NextKey.CollectPartyKeys then
                local keys = NextKey:CollectPartyKeys()
                local hasPlayerKey = false
                for _, key in ipairs(keys) do
                    if NextKey:IsPlayerOwner(key.ownerName) and key.dungeonID and key.dungeonID > 0 then
                        hasPlayerKey = true
                        break
                    end
                end
                
                if hasPlayerKey then
                    instructions:SetText("✓ Keystone detected! Check the main NextKey window.\n\n" ..
                                       "Visual validation steps:\n" ..
                                       "1. Open /nk and find your keystone\n" ..
                                       "2. Verify dungeon name and level\n" ..
                                       "3. Hover to see detailed tooltip\n" ..
                                       "4. Check IO score calculation")
                end
            end
        end
    end)
    
    NextKey222.Debug:Dev("keystones", "Visual keystone detection test frame created")
end

-- Module interface
function Keystones:Initialize()
    -- Set up LibOpenRaid reference
    self.LibOpenRaid = NextKey222.LibOpenRaidIntegration
    NextKey222.Debug:Dev("keystones", "LibOpenRaid reference set:", self.LibOpenRaid and "available" or "nil")
    return true
end

return Keystones