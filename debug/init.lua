-- MARK: Debug Initialization & Setup
local _, NextKey222 = ...

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

-- MARK: Enhanced Fake Player Generation
function NextKey222.Addon:AddRandomFakePlayers(count, addonMix)
    -- Obtain dungeon IDs via the core season API
    local dungeonIDs = self:EnsureDungeonIDs()
    if not dungeonIDs then
        print("NextKey: No dungeon IDs available")
        return
    end
    
    count = count or 4
    addonMix = addonMix or { nextkey = 2, raiderio = 1, none = 1 }
    
    -- Clear existing fake players first
    self:ClearFakePlayers()
    
    print("NextKey: Generating " .. count .. " fake players...")
    
    for i = 1, count do
        self:GenerateRealisticFakePlayer(i, dungeonIDs, addonMix)
    end
    
    print("NextKey: Generated " .. count .. " fake players successfully!")
    self:NotifyOptionsChanged()
end

function NextKey222.Addon:GenerateRealisticFakePlayer(index, dungeonIDs, addonMix)
    -- Generate player tier (skill level)
    local tier = self:GenerateRealisticIOTier()
    local baseLevel = self:GetBaseLevelFromIOTier(tier)
    
    -- Initialize player
    local dbg = self:EnsureDebug()
    if not dbg then return end
    
    dbg.players[index] = {
        name = "FakePlayer" .. index,
        best = {},
        keystone = nil,
        score = 0,
        addonStatus = self:DetermineAddonStatus(index, addonMix),
        class = self:GetRandomClassToken(),
    }
    
    -- Generate scores for all dungeons
    for _, mapID in ipairs(dungeonIDs) do
        local level, chests = self:GenerateRealisticDungeonScore(baseLevel, tier)
        if level > 0 then
            self:SetFakePlayerBest(index, mapID, level, chests)
        end
    end
    
    -- Generate keystone
    local keystone = self:SelectRealisticKeystone(dungeonIDs, dbg.players[index].bests, baseLevel)
    -- Store in both legacy and current shapes for compatibility
    dbg.players[index].keystone = keystone
    dbg.players[index].key = {
        dungeonID = keystone and keystone.dungeonID or nil,
        level = keystone and keystone.level or nil,
    }
    -- Ensure total IO score is populated
    self:RecalculateFakePlayerScore(index)
end

function NextKey222.Addon:GenerateRealisticIOTier()
    -- Bell curve distribution of player skill
    local rand = math.random()
    
    if rand < 0.05 then return "elite"      -- Top 5%
    elseif rand < 0.15 then return "expert" -- Next 10%
    elseif rand < 0.35 then return "skilled" -- Next 20%
    elseif rand < 0.70 then return "average" -- 35% average
    elseif rand < 0.90 then return "casual"  -- 20% casual
    else return "beginner" end              -- Bottom 10%
end

function NextKey222.Addon:GetBaseLevelFromIOTier(tier)
    local tierLevels = {
        elite = math.random(28, 30),
        expert = math.random(22, 27),
        skilled = math.random(16, 21),
        average = math.random(10, 15),
        casual = math.random(6, 9),
        beginner = math.random(2, 5)
    }
    return tierLevels[tier] or 10
end

function NextKey222.Addon:GenerateRealisticDungeonScore(baseLevel, tier)
    -- Add some variation around the base level
    local variation = math.random(-3, 3)
    local level = math.max(2, baseLevel + variation)
    
    -- Determine if this run was timed based on skill and difficulty
    local timingChance = self:GetTimingChanceForLevel(level, tier)
    local timed = math.random() < timingChance
    
    local chests = 0
    if timed then
        -- Higher skill players more likely to get multiple chests
        local skillBonus = 0
        if tier == "elite" then skillBonus = 0.4
        elseif tier == "expert" then skillBonus = 0.3
        elseif tier == "skilled" then skillBonus = 0.2
        elseif tier == "average" then skillBonus = 0.1
        end
        
        local chestRand = math.random()
        if chestRand < 0.1 + skillBonus then chests = 3
        elseif chestRand < 0.3 + skillBonus then chests = 2
        elseif chestRand < 0.6 + skillBonus then chests = 1
        end
    end
    
    return level, chests
end

function NextKey222.Addon:GetTimingChanceForLevel(level, tier)
    -- Base timing chances by tier
    local baseChances = {
        elite = 0.95,
        expert = 0.85,
        skilled = 0.70,
        average = 0.50,
        casual = 0.30,
        beginner = 0.15
    }
    
    local baseChance = baseChances[tier] or 0.50
    
    -- Reduce chance for higher levels
    local levelPenalty = math.max(0, (level - 15) * 0.02)
    return math.max(0.05, baseChance - levelPenalty)
end

function NextKey222.Addon:DetermineAddonStatus(index, addonMix)
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
        if rand < 0.3 then return { nextkey = true, raiderio = true }   -- 30% have NextKey
        elseif rand < 0.8 then return { nextkey = false, raiderio = true } -- 50% have RaiderIO only
        else return { nextkey = false, raiderio = false }              -- 20% have neither
    end
    end
end

function NextKey222.Addon:SelectRealisticKeystone(dungeonIDs, dungeonScores, baseLevel)
    if not dungeonIDs or #dungeonIDs == 0 then return nil end
    
    -- Select random dungeon
    local selectedDungeon = dungeonIDs[math.random(#dungeonIDs)]
    
    -- Key level based on player's performance in that dungeon
    local keyLevel = baseLevel
    if dungeonScores[selectedDungeon] then
        local playerLevel = dungeonScores[selectedDungeon].level or baseLevel
        keyLevel = math.max(2, playerLevel + math.random(-2, 1))
    end
    
    return {
        dungeonID = selectedDungeon,
        level = keyLevel,
        ownerName = "FakePlayer" .. math.random(1, 4)
    }
end

-- MARK: Preset Team Generation
function NextKey222.Addon:GeneratePresetTeam(presetType)
    -- Fetch active season dungeon IDs from the addon API
    local dungeonIDs = self:EnsureDungeonIDs()
    if not dungeonIDs or #dungeonIDs == 0 then
        print("NextKey: No dungeon IDs available for preset generation")
        return
    end
    
    local presets = {
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
        }
    }
    
    local preset = presets[presetType]
    if not preset then
        print("NextKey: Unknown preset type: " .. tostring(presetType))
        return
    end
    
    -- Clear existing fake players
    self:ClearFakePlayers()
    
    -- Generate players according to preset
    for i, spec in ipairs(preset) do
        self:GeneratePresetPlayer(i, dungeonIDs, spec)
    end
    
    print("NextKey: Generated " .. presetType .. " preset team successfully!")
    self:NotifyOptionsChanged()
    -- Invalidate entire profiles cache since we generated new fake players
    if NextKey222.ProfilesService then
        NextKey222.ProfilesService:InvalidateCache()
    end
end

function NextKey222.Addon:GeneratePresetPlayer(index, dungeonIDs, spec)
    local baseLevel = self:GetBaseLevelFromIOTier(spec.tier)
    
    -- Initialize player
    local dbg = self:EnsureDebug()
    if not dbg then return end
    
    dbg.players[index] = {
        name = "FakePlayer" .. index,
        best = {},
        keystone = nil,
        score = 0,
        addonStatus = spec.addon,
        class = self:GetRandomClassToken(),
    }
    
    -- Generate scores
    for _, mapID in ipairs(dungeonIDs) do
        local level, chests = self:GenerateRealisticDungeonScore(baseLevel, spec.tier)
        if level > 0 then
            self:SetFakePlayerBest(index, mapID, level, chests)
        end
    end
    
    -- Generate keystone
    local keystone = self:SelectRealisticKeystone(dungeonIDs, dbg.players[index].best, baseLevel)
    -- Store in both legacy and current shapes for compatibility
    dbg.players[index].keystone = keystone
    dbg.players[index].key = {
        dungeonID = keystone and keystone.dungeonID or nil,
        level = keystone and keystone.level or nil,
    }
    -- Ensure total IO score is populated
    self:RecalculateFakePlayerScore(index)
end

-- MARK: Utility Functions
function NextKey222.Addon:ClearFakePlayers()
    local dbg = self:EnsureDebug()
    if dbg and dbg.players then
        wipe(dbg.players)
        print("NextKey: Cleared all fake players")
    end
    self:NotifyOptionsChanged()
end

function NextKey222.Addon:RemoveFakePlayer(index)
    local dbg = self:EnsureDebug()
    if dbg and dbg.players and dbg.players[index] then
        table.remove(dbg.players, index)
    end
    self:NotifyOptionsChanged()
end