-- Options.lua - AceConfig options registration for NextKey

local _, NextKey222 = ...
local addon = NextKey222.Addon
local NextKey = NextKey222.Addon  -- Add NextKey alias for debug functions
if not addon then return end

local function refreshUI()
    -- Refresh main UI if it exists and is visible
    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame then
        NextKey222.UI:RenderResults()
    end
    -- Refresh teleport window if it exists  
    if addon.RefreshTeleportWindow then
        addon:RefreshTeleportWindow()
    end
    -- Notify AceConfig that options changed
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

local function getDungeonValues()
    if not addon.GetActiveSeasonDungeonIDs then
        return {}
    end
    local list = {}
    for _, mapID in ipairs(addon:GetActiveSeasonDungeonIDs()) do
        list[tostring(mapID)] = addon:GetDungeonName(mapID)
    end
    return list
end

local function ensureForm()
    if addon.EnsureDebugAddForm then
        return NextKey:EnsureDebugAddForm()
    end
    NextKey:EnsureDebug()
    addon.db.global.debug.addForm = addon.db.global.debug.addForm or { best = {} }
    return addon.db.global.debug.addForm
end

local function getSelectedIndex()
    local dbg = NextKey:EnsureDebug()
    return dbg.selectedPlayerIndex
end

local function setSelectedIndex(value)
    local dbg = NextKey:EnsureDebug()
    if value == nil or value == "" then
        dbg.selectedPlayerIndex = nil
    else
        dbg.selectedPlayerIndex = tonumber(value)
    end
end

local function getMythicPlusData()
    local seasonData = addon:EnsureSeasonData()
    return seasonData and seasonData.bestLevels or {}
end

local function updateDungeonScore(mapID, level, timed)
    local seasonData = addon:EnsureSeasonData()
    if not seasonData.bestLevels then
        seasonData.bestLevels = {}
    end
    
    if level and level > 0 then
        seasonData.bestLevels[mapID] = {
            level = level,
            timed = timed,
            chests = timed and 1 or 0,
            fractionalTime = timed and (NextKey222.IOCalculator and NextKey222.IOCalculator:ApproximateFractionalFromChests(1) or 0.9) or nil
        }
    else
        seasonData.bestLevels[mapID] = nil
    end
    refreshUI()
end

local function fetchBlizzardData()
    -- SyncWithBlizzardAPI function doesn't exist, use CollectPartyKeys instead
    if addon.CollectPartyKeys then
        addon:CollectPartyKeys()
        print("NextKey: Refreshed keystone data")
    else
        print("NextKey: Keystone refresh function not available")
    end
end

local function fetchRaiderIOData()
    -- Check if RaiderIO addon exists
    if not RaiderIO then
        print("NextKey: RaiderIO addon is not installed or enabled.")
        return
    end
    
    local profile = RaiderIO.GetProfile("player")
    if not profile or not profile.mythicKeystoneProfile then
        print("NextKey: Could not fetch RaiderIO data for player.")
        return
    end
    
    local seasonData = addon:EnsureSeasonData()
    if seasonData then
        seasonData.currentScore = profile.mythicKeystoneProfile.currentScore or 0
    else
        print("NextKey: Could not initialize season data")
        return
    end
    
    -- Update UI
    refreshUI()
    print("NextKey: Successfully imported RaiderIO data.")
end

function addon:InjectDebugOptions(options)
    options.args = options.args or {}
    
    -- Add M+ Data tab
    options.args.mythicPlusData = {
        type = "group",
        name = "M+ Data",
        order = 25, -- Position after Leader Settings and Teleport Window
        args = {
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
                        func = fetchBlizzardData,
                        order = 1
                    },
                    fetchRaiderIO = {
                        type = "execute",
                        name = "Fetch from RaiderIO",
                        desc = "Import your Mythic+ data from RaiderIO addon",
                        func = fetchRaiderIOData,
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

    local debugArgs = {
        enabled = {
            type = "toggle",
            name = "Enable Debug Mode",
            desc = "Allows adding fake players with keys and IO for local testing.",
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.enabled
            end,
            set = function(_, v)
                local dbg = NextKey:EnsureDebug()
                dbg.enabled = v and true or false
            end,
            width = "full",
            order = 1,
        },
        simNotLeader = {
            type = "toggle",
            name = "Simulate Not Being Party Leader",
            desc = "If checked, forces the addon to behave as if you are NOT the party leader, even if you are solo.",
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.simNotLeader == true
            end,
            set = function(_, v)
                local dbg = NextKey:EnsureDebug()
                dbg.simNotLeader = v and true or false
            end,
            width = "full",
            order = 1.5,
        },
        teamHeader = {
            type = "header",
            name = "Sample Team Presets",
            order = 2.5,
        },
        teamDesc = {
            type = "description",
            name = "Generate realistic sample teams with different characteristics for comprehensive testing.",
            fontSize = "medium",
            order = 2.6,
        },
        genMixed = {
            type = "execute", 
            name = "Mixed Skill Team (Recommended)",
            desc = "Generates 4 players: 1 high IO, 2 medium IO, 1 low IO with mixed addon status",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                -- Generate mixed skill team with specific tiers
                NextKey222.Addon:GeneratePresetTeam("mixed_skill")
                refreshUI()
            end,
            order = 3.1,
        },
        genNewbie = {
            type = "execute",
            name = "Beginner Team", 
            desc = "4 low-medium IO players (800-1500) for testing progression scenarios",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                NextKey222.Addon:GeneratePresetTeam("beginner")
                refreshUI()
            end,
            order = 3.2,
        },
        genExpert = {
            type = "execute",
            name = "Expert Team",
            desc = "4 high IO players (2200-2800+) for testing high-key scenarios", 
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                NextKey222.Addon:GeneratePresetTeam("expert")
                refreshUI()
            end,
            order = 3.3,
        },
        genAddonMix = {
            type = "execute",
            name = "Addon Testing Team",
            desc = "Mixed addon status: 2 NextKey, 1 RaiderIO only, 1 no addons",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                NextKey222.Addon:AddRandomFakePlayers(4, { nextkey = 2, raiderio = 1, none = 1 })
                refreshUI()
            end,
            order = 3.4,
        },
        genWorstCase = {
            type = "execute",
            name = "No Addon Team",
            desc = "4 players with no NextKey or RaiderIO for testing pure fallback scenarios",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                NextKey222.Addon:AddRandomFakePlayers(4, { nextkey = 0, raiderio = 0, none = 4 })
                refreshUI()
            end,
            order = 3.5,
        },
        customHeader = {
            type = "header",
            name = "Custom Team Builder",
            order = 3.8,
        },
        customCount = {
            type = "range",
            name = "Team Size",
            desc = "Number of fake players to generate (1-8)",
            min = 1,
            max = 8,
            step = 1,
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.customTeamSize or 4
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                dbg.customTeamSize = val
            end,
            order = 3.85,
        },
        customNextKey = {
            type = "range",
            name = "NextKey Users",
            desc = "Players with NextKey addon installed",
            min = 0,
            max = 8,
            step = 1,
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.customNextKey or 2
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                dbg.customNextKey = val
            end,
            order = 3.86,
        },
        customRaiderIO = {
            type = "range",
            name = "RaiderIO Only Users", 
            desc = "Players with RaiderIO but no NextKey",
            min = 0,
            max = 8,
            step = 1,
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.customRaiderIO or 1
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                dbg.customRaiderIO = val
            end,
            order = 3.87,
        },
        customNone = {
            type = "range",
            name = "No Addon Users",
            desc = "Players without NextKey or RaiderIO",
            min = 0,
            max = 8, 
            step = 1,
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.customNone or 1
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                dbg.customNone = val
            end,
            order = 3.88,
        },
        genCustom = {
            type = "execute",
            name = "⚙️ Generate Custom Team",
            desc = "Create team with your specified parameters",
            func = function()
                NextKey:EnsureDebug()
                local dbg = NextKey:EnsureDebug()
                local size = dbg.customTeamSize or 4
                local nextkey = dbg.customNextKey or 2
                local raiderio = dbg.customRaiderIO or 1
                local none = dbg.customNone or 1
                
                NextKey222.Addon:ClearFakePlayers()
                NextKey222.Addon:AddRandomFakePlayers(size, { nextkey = nextkey, raiderio = raiderio, none = none })
                refreshUI()
            end,
            order = 3.89,
        },
        statusHeader = {
            type = "header",
            name = "Current Status",
            order = 3.95,
        },
        statusDisplay = {
            type = "description",
            name = function()
                local dbg = NextKey:EnsureDebug()
                if not dbg or not dbg.players or #dbg.players == 0 then
                    return "No fake players currently generated."
                end
                
                local nextkey_count = 0
                local rio_count = 0 
                local none_count = 0
                
                for _, player in ipairs(dbg.players) do
                    if player.addonStatus then
                        if player.addonStatus.nextkey then
                            nextkey_count = nextkey_count + 1
                        elseif player.addonStatus.raiderio then
                            rio_count = rio_count + 1
                        else
                            none_count = none_count + 1
                        end
                    end
                end
                
                return string.format("Active: %d players (%d NextKey, %d RaiderIO, %d None)", 
                    #dbg.players, nextkey_count, rio_count, none_count)
            end,
            fontSize = "medium",
            order = 3.98,
        },
        clear = {
            type = "execute",
            name = "🗑️ Clear All Fake Players",
            confirm = true,
            func = function()
                NextKey222.Addon:ClearFakePlayers()
                refreshUI()
            end,
            order = 4,
        },
        clearMythicPlus = {
            type = "execute",
            name = "Clear M+ Score Data",
            desc = "Clear all saved Mythic+ score data (for testing)",
            confirm = true,
            confirmText = "Are you sure you want to clear all M+ score data?",
            func = function()
                addon:ClearMythicPlusData()
            end,
            order = 5,
        },
        rio = {
            type = "execute",
            name = "Scan Raider.IO Now",
            desc = "Attempts to detect Raider.IO saved variables and report status.",
            func = function()
                if addon.TryLoadRaiderIO then
                    addon:TryLoadRaiderIO({ silent = false })
                else
                    print("NextKey: TryLoadRaiderIO function not available")
                end
            end,
            order = 5,
        },
        heading = {
            type = "header",
            name = "Add Specific Fake Player",
            order = 10,
        },
        fakeName = {
            type = "input",
            name = "Name",
            get = function()
                local form = ensureForm()
                return form.name or ""
            end,
            set = function(_, v)
                local form = ensureForm()
                form.name = v
            end,
            order = 11,
        },
        fakeMap = {
            type = "select",
            name = "Dungeon",
            desc = "Select a dungeon for the fake player's key.",
            values = getDungeonValues,
            get = function()
                local form = ensureForm()
                return form.mapID and tostring(form.mapID) or ""
            end,
            set = function(_, v)
                local form = ensureForm()
                form.mapID = tonumber(v)
            end,
            order = 12,
        },
        fakeLevel = {
            type = "range",
            name = "Key Level",
            min = 2, max = 30, step = 1,
            get = function()
                local form = ensureForm()
                return form.level or 10
            end,
            set = function(_, v)
                local form = ensureForm()
                form.level = v
            end,
            order = 13,
        },
        fakeClass = {
            type = "select",
            name = "Class",
            values = {
                WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
                PRIEST = "Priest", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage",
                WARLOCK = "Warlock", MONK = "Monk", DRUID = "Druid", DEMONHUNTER = "Demon Hunter", EVOKER = "Evoker",
            },
            get = function()
                local form = ensureForm()
                return form.class or "WARRIOR"
            end,
            set = function(_, v)
                local form = ensureForm()
                form.class = v
            end,
            order = 13.5,
        },
        fakeIO = {
            type = "input",
            name = "IO Score (optional)",
            desc = "Manual IO score for this fake player.",
            get = function()
                local form = ensureForm()
                return form.io and tostring(form.io) or ""
            end,
            set = function(_, v)
                local form = ensureForm()
                form.io = tonumber(v)
            end,
            order = 13.7,
        },
        addSpecific = {
            type = "execute",
            name = "Add Fake Player",
            func = function()
                NextKey:EnsureDebug()
                local form = ensureForm()
                if not (form.name and form.mapID and form.level) then
                    addon:Print("Debug: Missing name/mapID/level.")
                    return
                end
                local dbg = NextKey:EnsureDebug()
                dbg.players = dbg.players or {}

                local player = {
                    name = form.name,
                    class = form.class or "WARRIOR",
                    key = { dungeonID = tonumber(form.mapID), level = tonumber(form.level) },
                    io = tonumber(form.io) or 0,
                }

                table.insert(dbg.players, player)
                refreshUI()
            end,
            order = 15,
        },
        editHeader = {
            type = "header",
            name = "Edit Existing Fake Player",
            order = 20,
        },
        editSelect = {
            type = "select",
            name = "Fake Player",
            values = function()
                local dbg = NextKey:EnsureDebug()
                local values = {}
                for idx, player in ipairs(dbg.players or {}) do
                    local label = player.name or ("Player %d"):format(idx)
                    values[tostring(idx)] = label
                end
                return values
            end,
            get = function()
                local idx = getSelectedIndex()
                return idx and tostring(idx) or ""
            end,
            set = function(_, v)
                setSelectedIndex(v)
                LibStub("AceConfigDialog-3.0"):Open("NextKey")
            end,
            order = 20.1,
        },
        editMap = {
            type = "select",
            name = "Dungeon",
            desc = "Select a dungeon for the fake player's key.",
            values = getDungeonValues,
            get = function()
                local idx = getSelectedIndex()
                if not idx then return "" end
                local dbg = NextKey:EnsureDebug()
                local player = dbg.players[idx]
                return player and player.key and player.key.dungeonID and tostring(player.key.dungeonID) or ""
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local dbg = NextKey:EnsureDebug()
                local player = dbg.players[idx]
                if player and player.key then
                    player.key.dungeonID = tonumber(v)
                    refreshUI()
                end
            end,
            order = 20.11,
        },
        editLevel = {
            type = "range",
            name = "Key Level",
            min = 2, max = 30, step = 1,
            get = function()
                local idx = getSelectedIndex()
                if not idx then return 10 end
                local dbg = NextKey:EnsureDebug()
                local player = dbg.players[idx]
                return player and player.key and player.key.level or 10
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local dbg = NextKey:EnsureDebug()
                local player = dbg.players[idx]
                if player and player.key then
                    player.key.level = v
                    refreshUI()
                end
            end,
            order = 20.12,
        },
        editRemove = {
            type = "execute",
            name = "Remove Selected",
            func = function()
                local idx = getSelectedIndex()
                if idx then
                    NextKey:RemoveFakePlayer(idx)
                    setSelectedIndex(nil)
                    refreshUI()
                end
            end,
            order = 20.15,
        },
        editRecalc = {
            type = "execute",
            name = "Recalculate score",
            func = function()
                local idx = getSelectedIndex()
                if idx then
                    NextKey:RecalculateFakePlayerScore(idx)
                    refreshUI()
                end
            end,
            order = 20.16,
        },
        editBulkLevel = {
            type = "range",
            name = "Bulk Level",
            min = 0, max = 30, step = 1,
            get = function()
                local dbg = NextKey:EnsureDebug()
                return dbg.editorBulkLevel or 10
            end,
            set = function(_, v)
                local dbg = NextKey:EnsureDebug()
                dbg.editorBulkLevel = v
            end,
            order = 20.2,
        },
        editAllTimed = {
            type = "execute",
            name = "Set All Timed",
            func = function()
                local idx = getSelectedIndex()
                if idx then
                    local dbg = NextKey:EnsureDebug()
                    NextKey:SetFakePlayerAllBests(idx, dbg.editorBulkLevel or 10, true)
                    refreshUI()
                end
            end,
            order = 20.21,
        },
        editAllUntimed = {
            type = "execute",
            name = "Set All Untimed",
            func = function()
                local idx = getSelectedIndex()
                if idx then
                    local dbg = NextKey:EnsureDebug()
                    NextKey:SetFakePlayerAllBests(idx, dbg.editorBulkLevel or 10, false)
                    refreshUI()
                end
            end,
            order = 20.22,
        },
        editAllClear = {
            type = "execute",
            name = "Clear All",
            func = function()
                local idx = getSelectedIndex()
                if idx then
                    addon:ClearFakePlayerBests(idx)
                    refreshUI()
                end
            end,
            order = 20.23,
        },
    }

    options.args.debug = {
        type = "group",
        name = "Debug",
        order = 99,
        args = debugArgs,
    }


end

function addon:SetupOptions()
    local options = {
        name = "NextKey",
        type = "group",
        args = {
            leader = {
                type = "group",
                name = "Leader Settings",
                args = {
                    autoSuggest = {
                        type = "toggle",
                        name = "Auto Suggest",
                        desc = "Automatically suggest the best key to use.",
                        get = function() return addon.db.global.leaderSettings.autoSuggestEnabled end,
                        set = function(_, value)
                            addon.db.global.leaderSettings.autoSuggestEnabled = value
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                    },
                    sortMode = {
                        type = "select",
                        name = "Sort Mode",
                        desc = "How to sort the list of keys.",
                        values = {
                            HighestKeyLevel = "Highest Key Level",
                            LowestKeyLevel = "Lowest Key Level",
                        },
                        get = function() return addon.db.global.leaderSettings.defaultSortMode end,
                        set = function(_, value)
                            addon.db.global.leaderSettings.defaultSortMode = value
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                    },
                },
            },
            teleport = {
                type = "group",
                name = "Teleport Window",
                args = {
                    showHearthstone = {
                        type = "toggle",
                        name = "Show Hearthstone",
                        desc = "Show hearthstone locations in the teleport window.",
                        get = function() return addon.db.global.teleport.showHearthstone end,
                        set = function(_, value)
                            addon.db.global.teleport.showHearthstone = value
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                    },
                },
            },
        },
    }

    -- Inject debug options if the function exists
    if self.InjectDebugOptions then
        self:InjectDebugOptions(options)
    end

    local AceConfig = LibStub("AceConfig-3.0")
    AceConfig:RegisterOptionsTable("NextKey", options)

end
