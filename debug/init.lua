-- MARK: Debug Initialization & Setup
local NextKey = LibStub("AceAddon-3.0"):GetAddon("NextKey")

-- MARK: Core Debug Functions
function NextKey:EnsureDebug()
    if not self.db or not self.db.global then
        return nil
    end
    local dbg = self.db.global.debug
    dbg.players = dbg.players or {}
    dbg.addForm = dbg.addForm or { best = {} }
    return dbg
end

-- MARK: Debug Test Data
function NextKey:GetFakePlayerBest(playerIndex, mapID)
    local dbg = self:EnsureDebug()
    if not dbg then
        return nil
    end
    local player = dbg.players[playerIndex]
    if not player or type(player.best) ~= "table" then
        return nil
    end
    return player.best[self.utils.normalizeMapID(mapID)]
end

function NextKey:SetFakePlayerBest(playerIndex, mapID, level, chests)
    local dbg = self:EnsureDebug()
    if not dbg then
        return
    end
    dbg.players[playerIndex] = dbg.players[playerIndex] or { best = {} }
    local player = dbg.players[playerIndex]
    player.best = player.best or {}

    if level and level > 0 then
        player.best[mapID] = {
            level = level,
            chests = chests or 0,
            timed = (chests or 0) > 0,
            fractionalTime = self:ApproximateFractionalFromChests(chests),
        }
    else
        player.best[mapID] = nil
    end

    self:RecalculateFakePlayerScore(playerIndex)
end

function NextKey:RecalculateFakePlayerScore(playerIndex)
    local dbg = self:EnsureDebug()
    if not dbg then
        return
    end
    local player = dbg.players[playerIndex]
    if not player then
        return
    end
    player.best = player.best or {}
    local total = 0
    for _, entry in pairs(player.best) do
        total = total + self:EstimateRunScore(entry.level, entry.timed, entry.fractionalTime)
    end
    player.io = total
end

function NextKey:SetFakePlayerAllBests(playerIndex, level, timed)
    local dbg = self:EnsureDebug()
    if not dbg then
        return
    end
    level = level or 10
    dbg.players[playerIndex] = dbg.players[playerIndex] or { best = {} }
    local player = dbg.players[playerIndex]
    player.best = player.best or {}

    for _, mapID in ipairs(self:GetActiveSeasonDungeonIDs()) do
        player.best[mapID] = {
            level = level,
            timed = timed == true,
            chests = timed and 1 or 0,
            fractionalTime = timed and self:ApproximateFractionalFromChests(1) or nil,
        }
    end

    self:RecalculateFakePlayerScore(playerIndex)
end

function NextKey:ClearFakePlayerBests(playerIndex)
    local dbg = self:EnsureDebug()
    if not dbg then
        return
    end
    local player = dbg.players[playerIndex]
    if player then
        player.best = {}
        player.io = 0
    end
end

function NextKey:AddRandomFakePlayers(count)
    if not self.db then self.db = {} end
    if not self.db.global then self.db.global = {} end
    if not self.db.global.debug then self.db.global.debug = { enabled = true } end
    
    local dbg = self:EnsureDebug()
    if not dbg then
        self:Print("Debug: Failed to initialize debug module")
        return
    end
    
    dbg.players = dbg.players or {}
    local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" }
    local dungeonIDs = self:GetActiveSeasonDungeonIDs()
    if #dungeonIDs == 0 then
        dungeonIDs = { 503, 524, 526, 377, 525, 523, 401, 402 }
    end
    
    self:Print("Debug: Adding", count, "fake players. Current count:", #dbg.players)

    local startIndex = #dbg.players
    for i = 1, count do
        local class = classes[math.random(#classes)]
        local playerName = string.format("Fake %d", startIndex + i)
        local dungeonID = dungeonIDs[math.random(#dungeonIDs)]
        local keyLevel = math.random(2, 20)
        
        -- Generate a random score between 1000 and 3000
        local score = math.random(1000, 3000)
        
        local player = {
            name = playerName,
            class = class,
            key = {
                dungeonID = dungeonID,
                level = keyLevel,
                ownerName = playerName,
                ownerShort = playerName,
                class = class,
                source = "debug",
                timestamp = time(),
                io = score
            },
            best = {},
            io = score
        }
        
        if self.db.global.debug.enabled then
            self:Print(string.format("Debug: Created fake player %s with %s +%d", 
                playerName,
                self:GetDungeonName(dungeonID) or dungeonID,
                keyLevel
            ))
        end
        for _, mapID in ipairs(dungeonIDs) do
            if math.random() > 0.3 then
                local level = math.random(2, 20)
                local timed = math.random() > 0.2
                local chests = timed and math.random(1, 3) or 0
                player.best[mapID] = {
                    level = level,
                    timed = timed,
                    chests = chests,
                    fractionalTime = timed and self:ApproximateFractionalFromChests(chests) or nil,
                }
            end
        end
        table.insert(dbg.players, player)
        self:RecalculateFakePlayerScore(#dbg.players)
    end
end

function NextKey:ClearFakePlayers()
    local dbg = self:EnsureDebug()
    dbg.players = {}
end

function NextKey:RemoveFakePlayer(index)
    local dbg = self:EnsureDebug()
    if type(dbg.players) == "table" and index >= 1 and index <= #dbg.players then
        table.remove(dbg.players, index)
    end
end