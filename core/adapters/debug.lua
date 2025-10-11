-- MARK: Debug Profile Adapter
-- Adapter for converting fake/debug player data into standard PlayerProfile format

local _, NextKey222 = ...

local DebugAdapter = {}

-- MARK: Debug Player Profile Building
function DebugAdapter:GetProfile(playerName)
    -- Check if this is a fake/debug player
    if not NextKey222.Addon or not NextKey222.Addon.UI or not NextKey222.Addon.UI.GetFakePlayerData then
        return nil
    end
    
    local fakeData = NextKey222.Addon.UI:GetFakePlayerData(playerName)
    if not fakeData then
        return nil
    end
    
    local profile = {
        name = playerName,
        class = fakeData.class,
        io = fakeData.io or 0,
        dataSource = "debug",
        dungeonScores = {},
        addonStatus = fakeData.addonStatus or { nextkey = false, raiderio = false }
    }
    
    -- Convert fake player bests data to standard format
    local bests = fakeData.best or fakeData.bests -- Support both formats during transition
    if bests then
        for mapID, bestData in pairs(bests) do
            if bestData and bestData.level and bestData.level > 0 then
                -- Convert to NextKey canonical ID using IDMapper
                local dungeonID = mapID
                if NextKey222.IDMapper then
                    dungeonID = NextKey222.IDMapper:ToDungeonID(mapID) or mapID
                end
                
                -- Calculate score from level if not provided
                local score = bestData.score
                if not score and NextKey222.IOCalculator then
                    local timed = (bestData.timed ~= nil) and bestData.timed or ((bestData.chests or 0) > 0)
                    score = NextKey222.IOCalculator:EstimateRunScore(bestData.level, timed, bestData.chests or 0)
                end
                
                profile.dungeonScores[dungeonID] = {
                    bestScore = score or 0,
                    bestLevel = bestData.level,
                    timeLimit = 1800000, -- Default 30 minutes in milliseconds
                    dataSource = "fake_debug",
                    timed = bestData.timed,
                    chests = bestData.chests,
                    originalMapID = mapID -- Keep original for debugging
                }
            end
        end
    end
    
    return profile
end

-- MARK: Debug Player Detection
function DebugAdapter:IsDebugPlayer(playerName)
    return NextKey222.Addon and 
           NextKey222.Addon.UI and
           NextKey222.Addon.UI.GetFakePlayerData and 
           NextKey222.Addon.UI:GetFakePlayerData(playerName) ~= nil
end

-- MARK: Debug Player Management
function DebugAdapter:GetAllDebugPlayers()
    if not NextKey222.Addon or not NextKey222.Addon.EnsureDebug then
        return {}
    end
    
    local debug = NextKey222.Addon:EnsureDebug()
    if not debug or not debug.players then
        return {}
    end
    
    local players = {}
    for index, playerData in pairs(debug.players) do
        if playerData.name then
            table.insert(players, playerData.name)
        end
    end
    
    return players
end

-- MARK: Export
NextKey222.DebugAdapter = DebugAdapter