-- MARK: Initialization
local addon = LibStub("AceAddon-3.0"):GetAddon("NextKey", true)
if not addon then return end

-- MARK: Options Configuration

-- MARK: Data Management

local function createMythicPlusDataOptions()
    local dungeons = {}
    local seasonData = addon:EnsureSeasonData()
    
    -- Get active dungeons
    if addon.GetActiveSeasonDungeonIDs then
        for _, mapID in ipairs(addon:GetActiveSeasonDungeonIDs()) do
            dungeons[tostring(mapID)] = addon:GetDungeonName(mapID)
        end
    end

    -- Create options table
    local options = {
        type = "group",
        name = "M+ Data",
        order = 25,
        args = {
            currentScore = {
                type = "description",
                name = function()
                    local score = seasonData.currentScore or 0
                    local color = C_ChallengeMode.GetDungeonScoreRarityColor(score)
                    if color then
                        return string.format("Current M+ Score: |cff%02x%02x%02x%d|r", 
                            color.r * 255, color.g * 255, color.b * 255, score)
                    else
                        return string.format("Current M+ Score: %d", score)
                    end
                end,
                fontSize = "large",
                order = 0
            },
            description = {
                type = "description",
                name = "Configure your Mythic+ data and scores",
                order = 1
            },
            fetchGroup = {
                type = "group",
                name = "Data Import",
                inline = true,
                order = 2,
                args = {
                    fetchBlizzard = {
                        type = "execute",
                        name = "Fetch from Blizzard",
                        desc = "Import your Mythic+ data from Blizzard API",
                        func = function()
                            addon:SyncWithBlizzardAPI({announceNoChange = true})
                            if addon.RenderResults then
                                addon:RenderResults()
                            end
                        end,
                        order = 1
                    },
                    fetchRaiderIO = {
                        type = "execute",
                        name = "Fetch from RaiderIO",
                        desc = "Import your Mythic+ data from RaiderIO addon",
                        func = function()
                            if not RaiderIO then
                                addon:Print("RaiderIO addon is not installed or enabled.")
                                return
                            end
                            
                            local profile = RaiderIO.GetProfile("player")
                            if not profile or not profile.mythicKeystoneProfile then
                                addon:Print("Could not fetch RaiderIO data for player.")
                                return
                            end
                            
                            local score = profile.mythicKeystoneProfile.currentScore
                            if score then
                                seasonData.currentScore = score
                                if addon.RenderResults then
                                    addon:RenderResults()
                                end
                                addon:Print("Successfully imported RaiderIO score: " .. score)
                            end
                        end,
                        order = 2
                    }
                }
            },
            dungeonScores = {
                type = "group",
                name = "Dungeon Scores",
                inline = true,
                order = 3,
                args = {}
            }
        }
    }

    -- Add dungeon score inputs
    for mapID, name in pairs(dungeons) do
        local mid = tonumber(mapID)
        local bestEntry = seasonData.bestLevels and seasonData.bestLevels[mid]
        
        options.args.dungeonScores.args[mapID .. "_header"] = {
            type = "header",
            name = name,
            order = mid * 10
        }
        
        options.args.dungeonScores.args[mapID .. "_level"] = {
            type = "range",
            name = "Level",
            min = 0,
            max = 30,
            step = 1,
            get = function() 
                return bestEntry and bestEntry.level or 0
            end,
            set = function(_, value)
                if not seasonData.bestLevels then
                    seasonData.bestLevels = {}
                end
                if value > 0 then
                    seasonData.bestLevels[mid] = seasonData.bestLevels[mid] or {}
                    seasonData.bestLevels[mid].level = value
                else
                    seasonData.bestLevels[mid] = nil
                end
                if addon.RenderResults then
                    addon:RenderResults()
                end
            end,
            order = mid * 10 + 1
        }
        
        options.args.dungeonScores.args[mapID .. "_timed"] = {
            type = "toggle",
            name = "Timed",
            get = function()
                return bestEntry and bestEntry.timed or false
            end,
            set = function(_, value)
                if not seasonData.bestLevels or not seasonData.bestLevels[mid] then
                    return
                end
                seasonData.bestLevels[mid].timed = value
                seasonData.bestLevels[mid].chests = value and 1 or 0
                if addon.RenderResults then
                    addon:RenderResults()
                end
            end,
            order = mid * 10 + 2
        }
    end

    return options
end

function addon:GetMythicPlusDataOptions()
    return createMythicPlusDataOptions()
end