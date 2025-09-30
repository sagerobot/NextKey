local _, NS = ...
local NextKey = NS.Addon
local Utils = NS.Utils

local Keystones = {
    createKeyEntry = function(dungeonID, level, ownerName, ownerShort, class, source)
        return {
            dungeonID = dungeonID,
            level = level or 2,
            ownerName = ownerName or "Unknown",
            ownerShort = ownerShort or ownerName or "Unknown",
            class = class or "WARRIOR",
            io = 0,
            source = source or "other",
            timestamp = Utils.currentTime()
        }
    end,
    
    -- Deep copy a keystone entry
    copyKey = function(key)
        if not key then return nil end
        
        -- Handle case where key is just a dungeon ID number
        if type(key) == "number" then
            return Keystones.createKeyEntry(key)
        end
        
        -- Handle case where key is just dungeonID and level
        if type(key) == "table" and not key.ownerName then
            return Keystones.createKeyEntry(
                key.dungeonID or 0,
                key.level,
                key.ownerName,
                key.ownerShort,
                key.class,
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
function NextKey:ScanPlayerKeystone()
    print("NextKey DEBUG: ScanPlayerKeystone called")
    local mapID, level

    -- Try the modern split API first (Dragonflight+)
    if C_MythicPlus then
        mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        level = C_MythicPlus.GetOwnedKeystoneLevel()
        if mapID and mapID ~= 0 and level and level > 0 then
            print("NextKey DEBUG: Found key through modern API")
            return {
                dungeonID = mapID,
                level = level,
                ownerName = self.playerFullName,
                ownerShort = self.playerShortName,
                class = self.playerClass,
                source = "player",
                timestamp = Utils.currentTime()
            }
        end
    end

    -- If the modern API fails, fall back to scanning bags manually
    print("NextKey DEBUG: Modern API failed, scanning bags.")
    
    if C_Container and C_MythicPlus and C_MythicPlus.IsMythicPlusKeystone then
        for bag = 0, NUM_BAG_SLOTS do
            local slots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, slots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID then
                    if C_MythicPlus.IsMythicPlusKeystone(info.itemID) then
                        print("NextKey DEBUG: Found potential keystone in bags")
                        if info.hyperlink then
                            -- Try to get keystone info from the item
                            local keystoneMapID, keystoneLevel = C_ChallengeMode.GetKeystoneInfo(info.hyperlink)
                            if keystoneMapID and keystoneMapID ~= 0 and keystoneLevel and keystoneLevel > 0 then
                                print("NextKey DEBUG: Keystone confirmed from bags")
                                mapID = keystoneMapID
                                level = keystoneLevel
                                break
                            end
                        end
                    end
                end
            end
            if mapID and mapID ~= 0 then
                break
            end
        end
    end

    if not mapID or mapID == 0 then
        print("NextKey DEBUG: No key found after all checks.")
        return nil
    end

    print(string.format("NextKey DEBUG: Found key %s, Level %d", self:GetDungeonName(mapID), level or 0))

    local owner = self.playerFullName or Utils.safeGetName("player")
    local class = self.playerClass ~= "" and self.playerClass or Utils.safeGetClass("player") or ""

    return {
        dungeonID = mapID,
        level = level or 0,
        ownerName = owner,
        ownerShort = self.playerShortName,
        class = class ~= "" and class or "EVOKER",
        source = "player",
        timestamp = Utils.currentTime(),
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
                timestamp = Utils.currentTime()
            }
        elseif not entry.dungeonID or entry.dungeonID == 0 then
            return
        end
        entry.ownerName = entry.ownerName or "Unknown"
        entry.class = entry.class or "WARRIOR"
        entry.ownerShort = entry.ownerShort or entry.ownerName
        local fingerprint = string.format("%s:%s:%s", entry.ownerName, entry.dungeonID, entry.level or 0)
        if seen[fingerprint] then
            return
        end
        seen[fingerprint] = true
        table.insert(keys, Keystones.copyKey(entry))
    end

    local playerKey = self:ScanPlayerKeystone()
    if playerKey then
        if type(playerKey) == "number" then
            playerKey = Keystones.createKeyEntry(playerKey)
        end
        addKey(playerKey)
        self.playerKeystone = Keystones.copyKey(playerKey)
        if self.db.global.debug and self.db.global.debug.enabled then
            self:Print("Player keystone detected: ", playerKey.dungeonID, " level ", playerKey.level)
        end
    else
        self.playerKeystone = nil
    end

    if type(self.receivedKeys) == "table" then
        for _, entry in pairs(self.receivedKeys) do
            addKey(entry)
        end
    end

    -- Debug keys handled by debug module
    if self.db and self.db.global and self.db.global.debug then
        local dbg = self.db.global.debug
        if type(dbg.players) == "table" then
            for _, player in ipairs(dbg.players) do
                if player.key then
                    addKey({
                        dungeonID = player.key.dungeonID,
                        level = player.key.level,
                        ownerName = player.name,
                        ownerShort = player.name,
                        class = player.class,
                        io = player.io or 0,
                        source = "debug",
                        timestamp = Utils.currentTime(),
                    })
                    if self.db.global.debug.enabled then
                        self:Print("Debug player key added: ", player.name, " - ", player.key.dungeonID, " level ", player.key.level)
                    end
                end
            end
        end
    end

    table.sort(keys, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)

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
                if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
                    self:Print(string.format("Processing key %d: %s", i, type(entry) == "number" and entry or (entry.dungeonID or "nil")))
                end
                
                local copied = Keystones.copyKey(entry)
                if copied then
                    table.insert(copy, copied)
                    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
                        self:Print(string.format("Added key: %s (Level %d) from %s", 
                            self:GetDungeonName(copied.dungeonID) or copied.dungeonID,
                            copied.level or 0,
                            copied.ownerName or "Unknown"
                        ))
                    end
                end
            end
        end
    end
    
    -- Add debug output
    if self.db and self.db.global and self.db.global.debug and self.db.global.debug.enabled then
        self:Print("Available keys found: " .. #copy)
        for i, key in ipairs(copy) do
            self:Print(string.format("Key %d: %s - Level %d (%s)", 
                i, 
                key.ownerName or "Unknown",
                key.level or 0,
                key.source or "unknown"
            ))
        end
    end
    
    return copy
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
            timestamp = Utils.currentTime(),
        })
    else
        self.teleportTargetKey = nil
    end

    if opts.broadcast and self:IsLeaderOrSolo() then
        self:BroadcastTeleportSelection(self.teleportTargetKey)
    end

    if type(self.RefreshTeleportWindow) == "function" then
        self:RefreshTeleportWindow()
    end

    if type(self.RenderResults) == "function" and not same then
        self:RenderResults()
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

NS.Keystones = Keystones
return Keystones