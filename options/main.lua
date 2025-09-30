-- Options.lua - AceConfig options registration for NextKey

local addon = LibStub("AceAddon-3.0"):GetAddon("NextKey", true)
if not addon then return end

local function refreshUI()
    if addon.RenderResults then
        addon:RenderResults()
    end
    if addon.RefreshTeleportWindow then
        addon:RefreshTeleportWindow()
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
        return addon:EnsureDebugAddForm()
    end
    addon:EnsureDebug()
    addon.db.global.debug.addForm = addon.db.global.debug.addForm or { best = {} }
    return addon.db.global.debug.addForm
end

local function getSelectedIndex()
    local dbg = addon:EnsureDebug()
    return dbg.selectedPlayerIndex
end

local function setSelectedIndex(value)
    local dbg = addon:EnsureDebug()
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
            fractionalTime = timed and addon:ApproximateFractionalFromChests(1) or nil
        }
    else
        seasonData.bestLevels[mapID] = nil
    end
    refreshUI()
end

local function fetchBlizzardData()
    addon:SyncWithBlizzardAPI({announceNoChange = true})
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
    seasonData.currentScore = profile.mythicKeystoneProfile.currentScore or 0
    
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
                local dbg = addon:EnsureDebug()
                return dbg.enabled
            end,
            set = function(_, v)
                local dbg = addon:EnsureDebug()
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
                local dbg = addon:EnsureDebug()
                return dbg.simNotLeader == true
            end,
            set = function(_, v)
                local dbg = addon:EnsureDebug()
                dbg.simNotLeader = v and true or false
            end,
            width = "full",
            order = 1.5,
        },
        addRandom = {
            type = "execute",
            name = "Add Random Fake Player",
            func = function()
                addon:EnsureDebug()
                addon:AddRandomFakePlayers(1)
                refreshUI()
            end,
            order = 2,
        },
        genParty = {
            type = "execute",
            name = "Generate Sample Party (3)",
            func = function()
                addon:EnsureDebug()
                addon:AddRandomFakePlayers(3)
                refreshUI()
            end,
            order = 3,
        },
        clear = {
            type = "execute",
            name = "Clear Fake Players",
            confirm = true,
            func = function()
                addon:ClearFakePlayers()
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
                addon:TryLoadRaiderIO({ silent = false })
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
            desc = "Leave blank to auto-calculate from dungeon bests.",
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
        bestHeader = {
            type = "header",
            name = "Dungeon Bests (New Player)",
            order = 14,
        },
        bestAllLevel = {
            type = "range",
            name = "Bulk Level",
            desc = "Level used by the Set All buttons below.",
            min = 0, max = 30, step = 1,
            get = function()
                local form = ensureForm()
                return form.bulkLevel or 10
            end,
            set = function(_, v)
                local form = ensureForm()
                form.bulkLevel = v
            end,
            order = 14.1,
        },
        bestAllTimed = {
            type = "execute",
            name = "Set All Timed",
            func = function()
                local form = ensureForm()
                addon:SetAddFormAllBest(form.bulkLevel or 10, true)
            end,
            order = 14.11,
        },
        bestAllUntimed = {
            type = "execute",
            name = "Set All Untimed",
            func = function()
                local form = ensureForm()
                addon:SetAddFormAllBest(form.bulkLevel or 10, false)
            end,
            order = 14.12,
        },
        bestAllClear = {
            type = "execute",
            name = "Clear All",
            func = function()
                addon:ClearAddFormBest()
            end,
            order = 14.13,
        },
        addSpecific = {
            type = "execute",
            name = "Add Fake Player",
            func = function()
                addon:EnsureDebug()
                local form = ensureForm()
                if not (form.name and form.mapID and form.level) then
                    addon:Print("Debug: Missing name/mapID/level.")
                    return
                end
                local dbg = addon:EnsureDebug()
                dbg.players = dbg.players or {}

                local best = {}
                if addon.GetAddFormBest then
                    local ids = addon:GetActiveSeasonDungeonIDs() or {}
                    for _, mapID in ipairs(ids) do
                        local entry = addon:GetAddFormBest(mapID)
                        if entry and entry.level and entry.level > 0 then
                            best[mapID] = {
                                level = entry.level,
                                timed = entry.timed and true or false,
                                chests = entry.chests or (entry.timed and 1 or 0),
                                fractionalTime = entry.fractionalTime,
                            }
                        end
                    end
                end

                local player = {
                    name = form.name,
                    class = form.class or "WARRIOR",
                    key = { dungeonID = tonumber(form.mapID), level = tonumber(form.level) },
                    best = best,
                }

                local manualIO = tonumber(form.io)
                player.io = manualIO or 0

                table.insert(dbg.players, player)
                local index = #dbg.players
                if not manualIO or manualIO <= 0 then
                    addon:RecalculateFakePlayerScore(index)
                end

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
                local dbg = addon:EnsureDebug()
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
                local dbg = addon:EnsureDebug()
                local player = dbg.players[idx]
                return player and player.key and player.key.dungeonID and tostring(player.key.dungeonID) or ""
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local dbg = addon:EnsureDebug()
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
                local dbg = addon:EnsureDebug()
                local player = dbg.players[idx]
                return player and player.key and player.key.level or 10
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local dbg = addon:EnsureDebug()
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
                    addon:RemoveFakePlayer(idx)
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
                    addon:RecalculateFakePlayerScore(idx)
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
                local dbg = addon:EnsureDebug()
                return dbg.editorBulkLevel or 10
            end,
            set = function(_, v)
                local dbg = addon:EnsureDebug()
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
                    local dbg = addon:EnsureDebug()
                    addon:SetFakePlayerAllBests(idx, dbg.editorBulkLevel or 10, true)
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
                    local dbg = addon:EnsureDebug()
                    addon:SetFakePlayerAllBests(idx, dbg.editorBulkLevel or 10, false)
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

    local dungeonIDs = addon.GetActiveSeasonDungeonIDs and addon:GetActiveSeasonDungeonIDs() or {}
    for i, mapID in ipairs(dungeonIDs) do
        local orderBase = 14.3 + i * 0.01
        debugArgs["newBest_" .. mapID] = {
            type = "group",
            name = addon:GetDungeonName(mapID),
            inline = true,
            order = orderBase,
            args = {
                level = {
                    type = "range",
                    name = "Level",
                    min = 0, max = 30, step = 1,
                    get = function()
                        local entry = addon.GetAddFormBest and addon:GetAddFormBest(mapID)
                        return entry and entry.level or 0
                    end,
                    set = function(_, value)
                        local entry = addon.GetAddFormBest and addon:GetAddFormBest(mapID)
                        addon:SetAddFormBest(mapID, value, entry and entry.timed)
                    end,
                    order = 1,
                },
                chests = {
                    type = "select",
                    name = "Result",
                    values = {
                        [0] = "Untimed",
                        [1] = "Timed (1 Chest)",
                        [2] = "Timed (2 Chests)",
                        [3] = "Timed (3 Chests)",
                    },
                    get = function()
                        local entry = addon.GetAddFormBest and addon:GetAddFormBest(mapID)
                        return entry and entry.chests or 0
                    end,
                    set = function(_, value)
                        local entry = addon.GetAddFormBest and addon:GetAddFormBest(mapID)
                        local level = entry and entry.level or 0
                        if level <= 0 and value > 0 then
                            level = ensureForm().bulkLevel or 10
                        end
                        addon:SetAddFormBest(mapID, level, value)
                    end,
                    order = 2,
                },
            },
        }
    end

    local editDungeonOrderBase = 20.4
    for i, mapID in ipairs(dungeonIDs) do
        debugArgs["editBest_" .. mapID] = {
            type = "group",
            name = addon:GetDungeonName(mapID),
            inline = true,
            order = editDungeonOrderBase + i * 0.01,
            args = {
                level = {
                    type = "range",
                    name = "Level",
                    min = 0, max = 30, step = 1,
                    get = function()
                        local idx = getSelectedIndex()
                        if not idx then return 0 end
                        local entry = addon:GetFakePlayerBest(idx, mapID)
                        return entry and entry.level or 0
                    end,
                    set = function(_, value)
                        local idx = getSelectedIndex()
                        if not idx then return end
                        local entry = addon:GetFakePlayerBest(idx, mapID)
                        addon:SetFakePlayerBest(idx, mapID, value, entry and entry.chests or 0)
                        refreshUI()
                    end,
                    order = 1,
                },
                chests = {
                    type = "select",
                    name = "Result",
                    values = {
                        [0] = "Untimed",
                        [1] = "Timed (1 Chest)",
                        [2] = "Timed (2 Chests)",
                        [3] = "Timed (3 Chests)",
                    },
                    get = function()
                        local idx = getSelectedIndex()
                        if not idx then return 0 end
                        local entry = addon:GetFakePlayerBest(idx, mapID)
                        return entry and entry.chests or 0
                    end,
                    set = function(_, value)
                        local idx = getSelectedIndex()
                        if not idx then return end
                        local entry = addon:GetFakePlayerBest(idx, mapID)
                        local level = entry and entry.level or 0
                        if level <= 0 and value > 0 then
                            local dbg = addon:EnsureDebug()
                            level = dbg.editorBulkLevel or 10
                        end
                        addon:SetFakePlayerBest(idx, mapID, level, value)
                        refreshUI()
                    end,
                    order = 2,
                },
            },
        }
    end
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
                        set = function(_, value) addon.db.global.leaderSettings.autoSuggestEnabled = value end,
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
                        set = function(_, value) addon.db.global.leaderSettings.defaultSortMode = value end,
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
                        set = function(_, value) addon.db.global.teleport.showHearthstone = value end,
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