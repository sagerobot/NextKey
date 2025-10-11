-- MARK: Debug Initialization & Setup
local _, NextKey222 = ...

-- MARK: Migration Wrappers for FakePlayerService
-- These functions maintain backward compatibility while delegating to the new service

--- Wrapper: AddRandomFakePlayers - delegates to FakePlayerService
function NextKey222.Addon:AddRandomFakePlayers(count, addonMix)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        print("NextKey Error: FakePlayerService not available. Check addon load order.")
        return 0
    end
    return NextKey222.FakePlayerService:GenerateRandomPlayers(count, addonMix)
end

--- Wrapper: ClearFakePlayers - delegates to FakePlayerService
function NextKey222.Addon:ClearFakePlayers()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        print("NextKey Error: FakePlayerService not available. Check addon load order.")
        return 0
    end
    return NextKey222.FakePlayerService:ClearAllPlayers()
end

--- Wrapper: GeneratePresetTeam - delegates to FakePlayerService
function NextKey222.Addon:GeneratePresetTeam(presetType)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        print("NextKey Error: FakePlayerService not available. Check addon load order.")
        return 0
    end
    return NextKey222.FakePlayerService:GeneratePreset(presetType)
end

-- MARK: Core Debug Functions
-- Ensure we have a list of active season dungeon IDs cached; returns array (possibly fallback)
function NextKey222.Addon:EnsureDungeonIDs()
    if self.currentSeasonDungeons and #self.currentSeasonDungeons > 0 then
        return self.currentSeasonDungeons
    end
    if self.GetActiveSeasonDungeonIDs then
        local ids = self:GetActiveSeasonDungeonIDs()
        if ids and #ids > 0 then
            self.currentSeasonDungeons = ids
            return ids
        end
    end
    return {}
end
function NextKey222.Addon:EnsureDebug()
    if not self.db or not self.db.global then
        return nil
    end
    local dbg = self.db.global.debug
    dbg.players = dbg.players or {}
    dbg.addForm = dbg.addForm or { best = {} }
    return dbg
end

-- Return a random playable class token
function NextKey222.Addon:GetRandomClassToken()
    local classes = {
        "WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","DEATHKNIGHT",
        "SHAMAN","MAGE","WARLOCK","MONK","DRUID","DEMONHUNTER","EVOKER"
    }
    local idx = math.random(1, #classes)
    return classes[idx]
end

-- Notify AceConfig that options changed (safe no-op if not available)
function NextKey222.Addon:NotifyOptionsChanged()
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

function NextKey222.Addon:GetFakePlayerBest(playerIndex, mapID)
    local dbg = self:EnsureDebug()
    if not dbg or not dbg.players[playerIndex] or not dbg.players[playerIndex].best then
        return nil
    end
    
    local best = dbg.players[playerIndex].best[mapID]
    if best then
        return {
            level = best.level or 0,
            chests = best.chests or 0
        }
    end
    return nil
end

function NextKey222.Addon:SetFakePlayerBest(playerIndex, mapID, level, chests)
    local dbg = self:EnsureDebug()
    if not dbg then return end
    
    -- Initialize player structure
    if not dbg.players[playerIndex] then
        dbg.players[playerIndex] = {
            name = "FakePlayer" .. playerIndex,
            best = {},
            keystone = nil,
            addonStatus = { nextkey = false, raiderio = false }
        }
    end
    
    -- Set the best run - also calculate and store the score
    local runData = {
        level = level or 0,
        chests = chests or 0
    }
    
    -- Calculate the score for this run using IOCalculator
    if NextKey222.IOCalculator and NextKey222.IOCalculator.EstimateRunScore then
        local timed = (chests or 0) > 0
        local fractionalTime = 0.9 - ((chests or 0) * 0.1)
        runData.score = NextKey222.IOCalculator:EstimateRunScore(level or 0, timed, fractionalTime)
    else
        -- Fallback calculation
        runData.score = math.max(0, ((level or 0) - 1) * 10) + ((chests or 0) * 5)
    end
    
    dbg.players[playerIndex].best[mapID] = runData
    
    -- Special handling for Tazavesh: So'leah's Gambit ID variants (392 and 2441 are the same dungeon)
    if mapID == 392 or mapID == 2441 then
        -- Create equivalent data for So'leah's Gambit ID variants only
        local soLeahIDs = { 392, 2441 }
        for _, soLeahID in ipairs(soLeahIDs) do
            if soLeahID ~= mapID then
                dbg.players[playerIndex].best[soLeahID] = {
                    level = runData.level,
                    chests = runData.chests,
                    score = runData.score
                }
            end
        end
        if self.db.global.debug.enabled then
            print("NextKey: [FAKE PLAYER] So'leah's Gambit detected - created data for IDs 392 and 2441")
        end
    end
    
    -- Streets of Wonder (ID 391) is a separate dungeon - no cross-mapping needed
    
    if self.db.global.debug.enabled then
        print("NextKey: [FAKE PLAYER] Set best for Player" .. playerIndex .. " mapID " .. mapID .. " level " .. (level or 0) .. " chests " .. (chests or 0) .. " score " .. runData.score)
    end
    
    -- Recalculate total score
    self:RecalculateFakePlayerScore(playerIndex)
    -- Refresh options UI if open
    self:NotifyOptionsChanged()
    -- Invalidate profiles cache for fake player
    if NextKey222.ProfilesService then
        local playerName = "FakePlayer" .. playerIndex
        NextKey222.ProfilesService:InvalidateCache(playerName)
    end
end

function NextKey222.Addon:RecalculateFakePlayerScore(playerIndex)
    local dbg = self:EnsureDebug()
    if not dbg or not dbg.players[playerIndex] then return end
    
    local player = dbg.players[playerIndex]
    local totalScore = 0
    
    -- Create standardized IO package for fake player
    local playerName = player.name or ("FakePlayer" .. playerIndex)
    local ioPackage = NextKey222.PlayerIODataStructure:CreatePlayerIOPackage(playerName, true)
    
    if player.best then
        for mapID, best in pairs(player.best) do
            if best.level and best.level > 0 then
                local score = 0
                local level = best.level or 0
                local chests = best.chests or 0
                local isInTime = chests > 0
                
                -- Use IOCalculator if available
                if NextKey222.IOCalculator and NextKey222.IOCalculator.EstimateRunScore then
                    -- Convert chests to fractional time (0=untimed, 1+=timed with varying performance)
                    local timed = chests > 0
                    local fractionalTime = 0.9 - (chests * 0.1) -- Better chests = better fractional time
                    score = NextKey222.IOCalculator:EstimateRunScore(level, timed, fractionalTime)
                    
                    if NextKey222.Addon.db.global.debug.enabled then
                        print("NextKey: [FAKE PLAYER] Player" .. playerIndex .. " dungeon " .. mapID .. " level " .. level .. " chests " .. chests .. " = " .. score .. " IO")
                    end
                else
                    -- Fallback calculation
                    local baseScore = math.max(0, (level - 1) * 10)
                    local bonus = chests * 5
                    score = baseScore + bonus
                end
                
                -- Update the best data with calculated score
                best.score = score
                totalScore = totalScore + score
                
                -- Add to standardized IO package
                NextKey222.PlayerIODataStructure:AddDungeonScore(ioPackage, mapID, score, level, chests, isInTime)
            end
        end
    end
    
    player.score = totalScore
    player.io = totalScore -- expose as 'io' so keystones.lua can display it
    
    -- Store the standardized IO package in communications cache
    if NextKey222.Communications then
        NextKey222.Communications.playerIOCache[playerName] = ioPackage
        NextKey222.Debug:Print("debug", "Generated IO package for fake player", playerName, "with total IO:", totalScore)
    end
    
    if NextKey222.Addon.db.global.debug.enabled then
        print("NextKey: [FAKE PLAYER] Player" .. playerIndex .. " (" .. playerName .. ") recalculated total IO: " .. totalScore)
    end
end

function NextKey222.Addon:SetFakePlayerAllBests(playerIndex, level, timed)
    -- Use active season dungeon list from addon API
    local dungeonIDs = self:EnsureDungeonIDs()
    if not dungeonIDs or #dungeonIDs == 0 then return end
    
    -- Clear existing bests
    self:ClearFakePlayerBests(playerIndex)
    
    -- Set all dungeons to the specified level
    for _, mapID in ipairs(dungeonIDs) do
        local chests = 0
        if timed then
            chests = math.random(0, 3) -- Random chest count for timed runs
        end
        self:SetFakePlayerBest(playerIndex, mapID, level, chests)
    end
    self:NotifyOptionsChanged()
end

function NextKey222.Addon:ClearFakePlayerBests(playerIndex)
    local dbg = self:EnsureDebug()
    if not dbg or not dbg.players[playerIndex] then return end
    
    dbg.players[playerIndex].best = {}
    dbg.players[playerIndex].score = 0
    self:NotifyOptionsChanged()
end

-- MARK: Deprecated - All legacy fake player functions removed (286 lines deleted)
-- Use FakePlayerService directly for all fake player operations
-- See Documentation/FAKE_PLAYER_QUICK_REFERENCE.md for API
-- 
-- Removed functions:
--   - LegacyAddRandomFakePlayers
--   - GenerateRealisticFakePlayer
--   - GenerateRealisticIOTier
--   - GetBaseLevelFromIOTier
--   - GenerateRealisticDungeonScore
--   - GetTimingChanceForLevel
--   - DetermineAddonStatus
--   - SelectRealisticKeystone
--   - LegacyGeneratePresetTeam
--   - GeneratePresetPlayer
--   - LegacyClearFakePlayers
--   - RemoveFakePlayer
--
-- Note: If you see errors about missing functions, the FakePlayerService
-- failed to load. Check your TOC file and ensure core\fakePlayerService.lua
-- is loaded before debug\init.lua