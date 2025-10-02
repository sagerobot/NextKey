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
                NextKey222.Debug:Print("keystones", "Blizzard API score for current player:", score)
                return score
            end
            
            -- Alternative API for player rating summary
            if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
                if summary and summary.currentSeasonScore then
                    NextKey222.Debug:Print("keystones", "Blizzard API rating summary for current player:", summary.currentSeasonScore)
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
                        NextKey222.Debug:Print("keystones", "Blizzard API score for", playerName, ":", summary.currentSeasonScore)
                        return summary.currentSeasonScore
                    end
                end
            end
        end
        
        NextKey222.Debug:Print("keystones", "No Blizzard API score available for", playerName)
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
            NextKey222.Debug:Print("keystones", "Got Blizzard API score for", ownerName, ":", blizzardScore)
        else
            -- Fallback to RaiderIO data if Blizzard API unavailable
            if NextKey222.RaiderIO then
                local profile = NextKey222.RaiderIO:GetProfile(ownerName)
                NextKey222.Debug:Print("keystones", "RaiderIO profile for", ownerName, ":", profile and "found" or "not found")
                if profile and profile.mythicKeystoneProfile then
                    local p = profile.mythicKeystoneProfile
                    entry.rioScore = p.currentScore
                    NextKey222.Debug:Print("keystones", "Set RaiderIO score for", ownerName, "to", entry.rioScore)
                    
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
    NextKey222.Debug:Print("keystones", "Enhanced party scan started")
    
    local keys = {}
    local memberType = IsInRaid() and "raid" or "party"
    local maxMembers = IsInRaid() and 40 or 5
    
    -- Track seen players to avoid duplicates
    local seen = {}
    
    for i = 1, maxMembers do
        local unit = i == 1 and "player" or memberType .. i
        local name = GetUtils().safeGetName(unit)
        NextKey222.Debug:Print("keystones", "Checking party member", i, "unit:", unit, "name:", name or "nil")
        
        if name and not seen[name] and UnitExists(unit) then
            seen[name] = true
            
            -- Method 1: Try Blizzard API for owned keystone (current player only)
            local keystoneLevel, keystoneMapID = 0, 0
            if unit == "player" then
                keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
                keystoneMapID = C_MythicPlus.GetOwnedKeystoneMapID() or 0
                NextKey222.Debug:Print("keystones", "Blizzard API keystone for player:", keystoneLevel, keystoneMapID)
            end
            
            -- Method 2: Try active challenge mode detection
            if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo and unit == "player" then
                local level, affixes, wasEnergized = C_ChallengeMode.GetActiveKeystoneInfo()
                if level and level > 0 then
                    local activeMapID = C_ChallengeMode.GetActiveChallengeMapID()
                    NextKey222.Debug:Print("keystones", "Active keystone detected:", level, activeMapID)
                    keystoneLevel = level
                    keystoneMapID = activeMapID
                end
            end
            
            -- Method 3: Get RaiderIO profile for additional data
            local profile = nil
            if NextKey222.RaiderIO then
                profile = NextKey222.RaiderIO:GetProfile(name)
                NextKey222.Debug:Print("keystones", "RaiderIO profile for", name, ":", profile and "found" or "not found")
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
                NextKey222.Debug:Print("keystones", "Created entry for", name, "with keystone level", keystoneLevel)
                table.insert(keys, entry)
            end
        end
    end
    
    NextKey222.Debug:Print("keystones", "Enhanced party scan completed, found", #keys, "members")
    return keys
end

function NextKey:ScanPlayerKeystone()
    NextKey222.Debug:Print("keystones", "Enhanced player keystone scan started")
    
    -- Method 1: Try LibOpenRaid first (most comprehensive)
    if self.LibOpenRaid and self.LibOpenRaid:IsAvailable() then
        local libKeystone = self.LibOpenRaid:GetPlayerKeystone("player")
        if libKeystone then
            NextKey222.Debug:Print("keystones", "Found keystone via LibOpenRaid:", libKeystone.dungeonID, libKeystone.level)
            return libKeystone
        end
    end
    
    -- Method 2: Fallback to Blizzard APIs
    local mapID, level
    if C_MythicPlus then
        NextKey222.Debug:Print("keystones", "Trying Blizzard API methods")
        
        -- Primary method: GetOwnedKeystone APIs
        mapID = C_MythicPlus.GetOwnedKeystoneMapID() -- This should work for current keystones
        level = C_MythicPlus.GetOwnedKeystoneLevel()
        
        -- Alternative method: Challenge map API
        if not mapID or mapID == 0 then
            mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        end
        
        NextKey222.Debug:Print("keystones", "Blizzard API returned mapID:", mapID or "nil", "level:", level or "nil")
        
        if mapID and mapID ~= 0 and level and level > 0 then
            NextKey222.Debug:Print("keystones", "Found keystone via Blizzard API:", mapID, level)
            return {
                dungeonID = mapID,
                level = level,
                ownerName = self.playerFullName,
                ownerShort = self.playerShortName,
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
            NextKey222.Debug:Print("keystones", "Found duplicate keystone for", normalizedOwner, "level", entry.level)
            NextKey222.Debug:Print("keystones", "  Existing: source=" .. (existingKey.source or "unknown") .. ", dungeonID=" .. (existingKey.dungeonID or 0))
            NextKey222.Debug:Print("keystones", "  New: source=" .. (entry.source or "unknown") .. ", dungeonID=" .. (entry.dungeonID or 0))
            
            -- Define source priority (higher number = higher priority)
            local sourcePriority = {
                blizzard = 3,
                libopenraid = 2,
                rio = 1
            }
            
            local existingPriority = sourcePriority[existingKey.source] or 0
            local newPriority = sourcePriority[entry.source] or 0
            
            if newPriority > existingPriority then
                NextKey222.Debug:Print("keystones", "  Replacing with higher priority source:", entry.source)
                keys[existingIndex] = Keystones.copyKey(entry)
            elseif newPriority == existingPriority and (entry.dungeonID or 0) > (existingKey.dungeonID or 0) then
                NextKey222.Debug:Print("keystones", "  Replacing with better dungeonID:", entry.dungeonID, ">", existingKey.dungeonID)
                keys[existingIndex] = Keystones.copyKey(entry)
            else
                NextKey222.Debug:Print("keystones", "  Keeping existing keystone")
            end
            return
        end
        
        NextKey222.Debug:Print("keystones", "Added new keystone:", entry.ownerName, "->", normalizedOwner, "level:", entry.level, "source:", entry.source)
        table.insert(keys, Keystones.copyKey(entry))
    end

    local playerKey = self:ScanPlayerKeystone()
    if playerKey then
        if type(playerKey) == "number" then
            playerKey = Keystones.createKeyEntry(playerKey, 2, self.playerFullName)
        end
        addKey(playerKey)
        self.playerKeystone = Keystones.copyKey(playerKey)
        if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
            self:Print("Player keystone detected: ", playerKey.dungeonID, " level ", playerKey.level)
        end
    else
        self.playerKeystone = nil
    end

    -- Add keystones from LibOpenRaid (primary source)
    local openRaidKeys = 0
    NextKey222.Debug:Print("keystones", "Checking LibOpenRaid availability...")
    NextKey222.Debug:Print("keystones", "  self.LibOpenRaid:", self.LibOpenRaid and "exists" or "nil")
    
    if self.LibOpenRaid then
        NextKey222.Debug:Print("keystones", "  self.LibOpenRaid:IsAvailable():", self.LibOpenRaid:IsAvailable() and "true" or "false")
        if self.LibOpenRaid:IsAvailable() then
            NextKey222.Debug:Print("keystones", "Calling LibOpenRaid:GetAllKeystones()...")
            local libKeystones = self.LibOpenRaid:GetAllKeystones()
            NextKey222.Debug:Print("keystones", "LibOpenRaid returned keystones:", libKeystones and "data" or "nil")
            
            if libKeystones then
                for playerName, keyData in pairs(libKeystones) do
                    NextKey222.Debug:Print("keystones", "Processing LibOpenRaid keystone for:", playerName)
                    NextKey222.Debug:Print("keystones", "  keyData.dungeonID:", keyData.dungeonID)
                    NextKey222.Debug:Print("keystones", "  keyData.level:", keyData.level)
                    addKey(keyData)
                    openRaidKeys = openRaidKeys + 1
                    NextKey222.Debug:Print("keystones", "Added LibOpenRaid keystone:", playerName, keyData.dungeonID, keyData.level)
                end
            else
                NextKey222.Debug:Print("keystones", "LibOpenRaid returned no keystones (empty or nil)")
            end
        else
            NextKey222.Debug:Print("keystones", "LibOpenRaid is not available")
        end
    else
        NextKey222.Debug:Print("keystones", "LibOpenRaid reference not set")
    end
    NextKey222.Debug:Print("keystones", "LibOpenRaid keys added:", openRaidKeys)
    
    -- Legacy support: Add from old receivedKeys if still present
    if type(self.receivedKeys) == "table" then
        for _, entry in pairs(self.receivedKeys) do
            addKey(entry)
        end
    end

    -- Request keystones via LibOpenRaid
    if IsInGroup() and self.LibOpenRaid and self.LibOpenRaid:IsAvailable() then
        NextKey222.Debug:Print("keystones", "Requesting keystones via LibOpenRaid")
        self.LibOpenRaid:RequestKeystones()
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

    -- Debug keys handled by debug module
    if self.db and self.db.global and self.db.global.debug then
        local dbg = self.db.global.debug
        if self.db.global.debug.enabled then
            self:Print("Debug: Checking debug players, count:", dbg.players and #dbg.players or "nil")
        end
        if type(dbg.players) == "table" then
            for i, player in ipairs(dbg.players) do
                if player.key then
                    addKey({
                        dungeonID = player.key.dungeonID,
                        level = player.key.level,
                        ownerName = player.name,
                        ownerShort = player.name,
                        class = player.class,
                        io = player.io or 0,
                        source = "debug",
                        timestamp = GetUtils().currentTime(),
                    })
                    if self.db.global.debug.enabled then
                        self:Print("Debug player key added: ", player.name, " - ", player.key.dungeonID, " level ", player.key.level, " IO:", player.io or 0)
                    end
                else
                    if self.db.global.debug.enabled then
                        self:Print("Debug: Player", i, "(", player.name or "nil", ") has no key")
                    end
                end
            end
        else
            if self.db.global.debug.enabled then
                self:Print("Debug: dbg.players is not a table:", type(dbg.players))
            end
        end
        
        -- Trigger UI refresh if fake players were added and UI is visible
        if type(dbg.players) == "table" and #dbg.players > 0 then
            if NextKey222.UI and NextKey222.UI.IsMainFrameVisible and NextKey222.UI:IsMainFrameVisible() then
                NextKey222.Debug:Print("keystones", "Fake players detected - triggering UI refresh")
                C_Timer.After(0.1, function()
                    if NextKey222.UI.RefreshResults then
                        NextKey222.UI:RefreshResults()
                    end
                end)
            end
        end
    end

    table.sort(keys, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

    -- Debug summary of collected keystones
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        -- CollectPartyKeys completed
        
        -- Count by source
        local sourceCounts = {}
        for i, key in ipairs(keys) do
            local source = key.source or "unknown"
            sourceCounts[source] = (sourceCounts[source] or 0) + 1
            self:Print(string.format("Key %d: %s - %s +%d (source: %s)", i, key.ownerName or "nil", key.dungeonID or "nil", key.level or 0, source))
        end
        
        self:Print("Keys by source:")
        for source, count in pairs(sourceCounts) do
            self:Print(string.format("  %s: %d", source, count))
        end
    end

    self.cachedKeys = keys
    return keys
end

function NextKey:GetAvailableKeys()
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        self:Print("GetAvailableKeys called")
    end

    local keys = self:CollectPartyKeys()
    if not keys then 
        if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
            self:Print("No keys returned from CollectPartyKeys")
        end
        return {} 
    end
    
    local copy = {}
    if type(keys) == "table" then
        for i, entry in ipairs(keys) do
            if entry then
                -- Processing key (debug output removed for performance)
                
                local copied = Keystones.copyKey(entry)
                if copied then
                    table.insert(copy, copied)
                    -- Key added (debug output removed for performance)
                end
            end
        end
    end
    
    -- Apply guild/party filtering if UI is available
    if NextKey222.UI and not NextKey222.UI.showGuildKeys then
        NextKey222.Debug:Print("keystones", "Filtering to party members only")
        local filteredCopy = {}
        local partyMembers = self:GetPartyMemberNames()
        local seenPlayers = {}  -- Track seen players to avoid duplicates
        
        for i, key in ipairs(copy) do
                local playerName = key.ownerName or ""
                local isPartyMember = false
                
                NextKey222.Debug:Print("keystones", "Checking keystone from:", playerName)
                
                -- Check against all party members (both short and full names)
                for _, partyMember in pairs(partyMembers) do
                    local partyShort = partyMember:match("^([^%-]+)") or partyMember
                    local playerShort = playerName:match("^([^%-]+)") or playerName
                    
                    -- Match by full name or short name
                    if playerName == partyMember or playerShort == partyShort then
                        isPartyMember = true
                        NextKey222.Debug:Print("keystones", "  Matched party member:", partyMember)
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
                        NextKey222.Debug:Print("keystones", "  Added first keystone for:", playerShort)
                    else
                        -- Compare keystones and keep the better one
                        local shouldReplace = false
                        
                        -- Priority 1: Higher level keystone
                        if (key.level or 0) > (existingKey.level or 0) then
                            shouldReplace = true
                            NextKey222.Debug:Print("keystones", "  Replacing with higher level:", key.level, ">", existingKey.level)
                        elseif (key.level or 0) == (existingKey.level or 0) then
                            -- Priority 2: Better dungeonID (non-zero preferred)
                            if (key.dungeonID or 0) > (existingKey.dungeonID or 0) then
                                shouldReplace = true
                                NextKey222.Debug:Print("keystones", "  Replacing with better dungeonID:", key.dungeonID, ">", existingKey.dungeonID)
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
                        NextKey222.Debug:Print("keystones", "  Duplicate keystone", shouldReplace and "replaced" or "ignored", "for:", playerShort)
                    end
                else
                    NextKey222.Debug:Print("keystones", "  Filtered out non-party member:", playerName)
                end
            end
            
        copy = filteredCopy
        NextKey222.Debug:Print("keystones", "After filtering: " .. #copy .. " keys remaining")
    end
    
    -- Available keys processed (debug output removed for performance)
    
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
        NextKey222.Debug:Print("keystones", "Added current player:", playerFullName)
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
                        NextKey222.Debug:Print("keystones", "Added party member:", memberName)
                    end
                end
            end
        end
    end
    
    -- In debug mode, add fake players as if they were party members
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        local dbg = self.db.global.debug
        if type(dbg.players) == "table" then
            for i, player in ipairs(dbg.players) do
                if player.name then
                    -- Add fake player name to party members list
                    table.insert(partyMembers, player.name)
                    NextKey222.Debug:Print("keystones", "Added fake player as party member:", player.name)
                end
            end
        end
    end
    
    NextKey222.Debug:Print("keystones", "Final party members (" .. #partyMembers .. "):", table.concat(partyMembers, ", "))
    return partyMembers
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
    else
        self.teleportTargetKey = nil
    end

    if opts.broadcast and self:IsLeaderOrSolo() then
        -- Broadcast teleport selection to party/raid (placeholder implementation)
        NextKey222.Debug:Print("keystones", "Teleport target selected:", key and (key.ownerName .. " - " .. self:GetDungeonName(key.dungeonID)) or "none")
        -- TODO: Implement actual broadcast via communications module if needed
    end

    if type(self.RefreshTeleportWindow) == "function" then
        self:RefreshTeleportWindow()
    end

    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame and not same then
        NextKey222.UI:RenderResults()
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
    NextKey222.Debug:Print("keystones", "Teleport requested for dungeon:", dungeonData.name)
    
    -- Use existing teleport window toggle method
    if self.ToggleTeleportWindow then
        self:ToggleTeleportWindow()
    end
    
    -- Alternative: Direct spell cast if spell ID available
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
    NextKey222.Debug:Print("keystones", "Loot window requested for dungeon:", dungeonData.name)
    
    -- Placeholder for future loot window integration
    self:Print(string.format("Loot tracking for %s - Coming Soon!", dungeonData.name))
    
    -- TODO: Integrate with loot tracking system
    -- if NextKey222.LootWindow then
    --     NextKey222.LootWindow:Show(dungeonID)
    -- end
end

-- Module interface
function Keystones:Initialize()
    -- Set up LibOpenRaid reference
    self.LibOpenRaid = NextKey222.LibOpenRaidIntegration
    NextKey222.Debug:Print("keystones", "LibOpenRaid reference set:", self.LibOpenRaid and "available" or "nil")
    return true
end

return Keystones