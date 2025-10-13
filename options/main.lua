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
            if NextKey222.UI and NextKey222.UI.OnDebugModeChanged then
                NextKey222.UI:OnDebugModeChanged()
            end
            if NextKey222.Debug and NextKey222.Debug.SetEnabled then
                NextKey222.Debug:SetEnabled(dbg.enabled)
            end
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
        addonHeader = {
            type = "header",
            name = "Addon Settings (Applies to All Presets)",
            order = 2.65,
        },
        addonDescription = {
            type = "description",
            name = "Control which addons generated players will have. These settings apply to ALL preset buttons below.",
            fontSize = "small",
            order = 2.66,
        },
        addonNextKey = {
            type = "toggle",
            name = "Players Have NextKey",
            desc = "Generated players will have NextKey addon and broadcast their keystones",
            width = "full",
            get = function()
                local dbg = NextKey:EnsureDebug()
                if dbg.presetAddonConfig == nil then
                    dbg.presetAddonConfig = { nextkey = true, raiderio = true }
                end
                return dbg.presetAddonConfig.nextkey
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                if not dbg.presetAddonConfig then
                    dbg.presetAddonConfig = {}
                end
                dbg.presetAddonConfig.nextkey = val
            end,
            order = 2.67,
        },
        addonRaiderIO = {
            type = "toggle",
            name = "Players Have RaiderIO",
            desc = "Generated players will have RaiderIO addon with IO scores visible",
            width = "full",
            get = function()
                local dbg = NextKey:EnsureDebug()
                if dbg.presetAddonConfig == nil then
                    dbg.presetAddonConfig = { nextkey = true, raiderio = true }
                end
                return dbg.presetAddonConfig.raiderio
            end,
            set = function(_, val)
                local dbg = NextKey:EnsureDebug()
                if not dbg.presetAddonConfig then
                    dbg.presetAddonConfig = {}
                end
                dbg.presetAddonConfig.raiderio = val
            end,
            order = 2.68,
        },
        addonStatusWarning = {
            type = "description",
            name = function()
                local dbg = NextKey:EnsureDebug()
                if not dbg.presetAddonConfig or (not dbg.presetAddonConfig.nextkey and not dbg.presetAddonConfig.raiderio) then
                    return "|cFFFF4444⚠ Both addons disabled - Players will have NO addon data (pure fallback mode)|r"
                end
                local status = {}
                if dbg.presetAddonConfig.nextkey then table.insert(status, "NextKey") end
                if dbg.presetAddonConfig.raiderio then table.insert(status, "RaiderIO") end
                return "|cFF00FF00✓ Players will have: " .. table.concat(status, " + ") .. "|r"
            end,
            fontSize = "small",
            order = 2.69,
        },
        genMixed = {
            type = "execute", 
            name = "Mixed Skill Team (Recommended)",
            desc = "4 players with varied IO: Expert (3100+), Skilled (2900+), Competent (2500+), Average (2000+)",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:GeneratePresetTeam("mixed_skill")
                addon:Print(string.format("Generated %d Mixed Skill players", count or 0))
                refreshUI()
            end,
            order = 3.1,
        },
        genNewbie = {
            type = "execute",
            name = "Beginner Team", 
            desc = "4 lower IO players: Beginner (1000-1500), Casual (1500-2000), Casual, Average (2000+)",
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:GeneratePresetTeam("beginner")
                addon:Print(string.format("Generated %d Beginner Team players", count or 0))
                refreshUI()
            end,
            order = 3.2,
        },
        genExpert = {
            type = "execute",
            name = "Expert Team",
            desc = "4 high IO players: Title (3600+), Elite (3300+), Expert (3100+), Skilled (2900+)", 
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:GeneratePresetTeam("expert")
                addon:Print(string.format("Generated %d Expert Team players", count or 0))
                refreshUI()
            end,
            order = 3.3,
        },
        genHighKeys = {
            type = "execute",
            name = "High Keys Team",
            desc = "4 elite pushers: 2x Title (3600+), Elite (3300+), Expert (3100+) - Top 1% players", 
            func = function()
                NextKey:EnsureDebug()
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:GeneratePresetTeam("high_keys")
                addon:Print(string.format("Generated %d High Keys Team players", count or 0))
                refreshUI()
            end,
            order = 3.4,
        },
        customHeader = {
            type = "header",
            name = "Custom Team Builder",
            order = 3.8,
        },
        customCount = {
            type = "range",
            name = "Team Size",
            desc = "Number of fake players to generate with random IO levels (1-12)",
            min = 1,
            max = 12,
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
        genCustom = {
            type = "execute",
            name = "Generate Custom Team",
            desc = "Create random team using addon settings above",
            func = function()
                NextKey:EnsureDebug()
                local dbg = NextKey:EnsureDebug()
                local size = dbg.customTeamSize or 4
                
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:AddRandomFakePlayers(size)
                addon:Print(string.format("Generated %d custom players", count or 0))
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
                -- Get players from FakePlayerService
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                
                if not players or #players == 0 then
                    return "No fake players currently generated."
                end
                
                local nextkey_count = 0
                local rio_count = 0 
                local none_count = 0
                
                for _, player in ipairs(players) do
                    if player.addonStatus then
                        if player.addonStatus.nextkey and player.addonStatus.raiderio then
                            nextkey_count = nextkey_count + 1
                        elseif player.addonStatus.raiderio then
                            rio_count = rio_count + 1
                        elseif not player.addonStatus.nextkey and not player.addonStatus.raiderio then
                            none_count = none_count + 1
                        end
                    else
                        none_count = none_count + 1
                    end
                end
                
                return string.format("Active: %d players (%d NextKey+RIO, %d RIO only, %d None)", 
                    #players, nextkey_count, rio_count, none_count)
            end,
            fontSize = "medium",
            order = 3.98,
        },
        clear = {
            type = "execute",
            name = "Clear All Fake Players",
            confirm = true,
            func = function()
                NextKey222.Addon:ClearFakePlayers()
                refreshUI()
            end,
            order = 4,
        },
        dataHeader = {
            type = "header",
            name = "Data Management",
            order = 4.5,
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
            order = 4.6,
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
            order = 4.7,
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
            desc = "Create a single fake player with the specified keystone using the addon settings above",
            func = function()
                NextKey:EnsureDebug()
                local form = ensureForm()
                
                -- Validate required fields
                if not form.name or form.name == "" then
                    addon:Print("Debug: Please enter a player name.")
                    return
                end
                
                if not form.mapID then
                    addon:Print("Debug: Please select a dungeon.")
                    return
                end
                
                if not form.level then
                    addon:Print("Debug: Please set a key level.")
                    return
                end
                
                -- Get addon config
                local dbg = NextKey:EnsureDebug()
                local addonConfig = dbg.presetAddonConfig or { nextkey = true, raiderio = true }
                
                -- Create player using FakePlayerService
                local playerName = NextKey222.FakePlayerService:CreatePlayer({
                    name = form.name,
                    class = form.class or "WARRIOR",
                    io = tonumber(form.io),  -- Can be nil, will be calculated
                    keystoneLevel = tonumber(form.level),
                    keystoneDungeon = tonumber(form.mapID),
                    addonStatus = addonConfig
                })
                
                if playerName then
                    addon:Print("Created fake player:", playerName)
                    refreshUI()
                else
                    addon:Print("Debug: Failed to create fake player. Check debug output.")
                end
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
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                local values = {}
                for idx, player in ipairs(players or {}) do
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
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                local player = players[idx]
                return player and player.key and player.key.dungeonID and tostring(player.key.dungeonID) or ""
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                local player = players[idx]
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
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                local player = players[idx]
                return player and player.key and player.key.level or 10
            end,
            set = function(_, v)
                local idx = getSelectedIndex()
                if not idx then return end
                local players = NextKey222.FakePlayerService:GetAllPlayers()
                local player = players[idx]
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
        name = "Debug Tools",
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
                name = "General Settings",
                args = {
                    autoSuggest = {
                        type = "toggle",
                        name = "Auto Suggest",
                        desc = "Automatically suggest the best key to run when the window opens. This analyzes all available keystones and recommends the optimal choice.",
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
                        desc = "Default sorting method for the keystone list. Highest Key Level shows the most challenging keys first, Lowest Key Level shows easier keys first.",
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
                    groupHeader = {
                        type = "header",
                        name = "Group Composition Preferences",
                    },
                    prioritizeHeroism = {
                        type = "toggle",
                        name = "Prefer Heroism Support",
                        desc = "When suggesting groups, prioritize including players with Heroism/Bloodlust (Mage, Shaman, Evoker).",
                        width = "full",
                        get = function()
                            return addon.db.global.groupPreferences and addon.db.global.groupPreferences.prioritizeHeroism
                        end,
                        set = function(_, value)
                            if not addon.db.global.groupPreferences then
                                addon.db.global.groupPreferences = {}
                            end
                            addon.db.global.groupPreferences.prioritizeHeroism = value
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                    },
                    prioritizeBattleRes = {
                        type = "toggle",
                        name = "Prefer Battle Res Support",
                        desc = "When suggesting groups, prioritize including players with Battle Resurrection (Druid, Warlock, Death Knight).",
                        width = "full",
                        get = function()
                            return addon.db.global.groupPreferences and addon.db.global.groupPreferences.prioritizeBattleRes
                        end,
                        set = function(_, value)
                            if not addon.db.global.groupPreferences then
                                addon.db.global.groupPreferences = {}
                            end
                            addon.db.global.groupPreferences.prioritizeBattleRes = value
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
            pugHelper = {
                type = "group",
                name = "PUG Helper",
                desc = "Settings for the PUG (Pick Up Group) Helper that assists with LFG workflow",
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable PUG Helper",
                        desc = "Enable automatic assistance when using the LFG tool for Mythic+ dungeons",
                        get = function()
                            if NextKey222.PUGHelper then
                                return NextKey222.PUGHelper:IsEnabled()
                            else
                                return addon.db.global.pugHelper and addon.db.global.pugHelper.enabled or false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGHelper then
                                NextKey222.PUGHelper:SetEnabled(value)
                            else
                                if not addon.db.global.pugHelper then
                                    addon.db.global.pugHelper = {}
                                end
                                addon.db.global.pugHelper.enabled = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                    },
                    notificationsHeader = {
                        type = "header",
                        name = "Invite Notifications",
                        order = 10,
                    },
                    showNotifications = {
                        type = "toggle",
                        name = "Show Invite Notifications",
                        desc = "Display enhanced invite notifications with dungeon information when receiving invites from tracked LFG applications",
                        get = function()
                            if NextKey222.PUGHelper then
                                local config = NextKey222.PUGHelper:GetConfig()
                                return config.showNotifications
                            else
                                return addon.db.global.pugHelper and addon.db.global.pugHelper.showNotifications ~= false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGHelper then
                                NextKey222.PUGHelper:Configure({showNotifications = value})
                            else
                                if not addon.db.global.pugHelper then
                                    addon.db.global.pugHelper = {}
                                end
                                addon.db.global.pugHelper.showNotifications = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 11,
                    },
                    autoAcceptInvites = {
                        type = "toggle",
                        name = "Auto-Accept Invites",
                        desc = "Automatically accept group invitations from tracked LFG applications (use with caution)",
                        get = function()
                            if NextKey222.PUGHelper then
                                local config = NextKey222.PUGHelper:GetConfig()
                                return config.autoAcceptInvites
                            else
                                return addon.db.global.pugHelper and addon.db.global.pugHelper.autoAcceptInvites or false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGHelper then
                                NextKey222.PUGHelper:Configure({autoAcceptInvites = value})
                            else
                                if not addon.db.global.pugHelper then
                                    addon.db.global.pugHelper = {}
                                end
                                addon.db.global.pugHelper.autoAcceptInvites = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 12,
                    },
                    travelHeader = {
                        type = "header",
                        name = "Travel Assistance",
                        order = 20,
                    },
                    travelAssistant = {
                        type = "toggle",
                        name = "Travel Assistant",
                        desc = "Show travel assistance window when joining a PUG group with teleport, hearthstone, and summon options",
                        get = function()
                            if NextKey222.PUGHelper then
                                local config = NextKey222.PUGHelper:GetConfig()
                                return config.travelAssistant
                            else
                                return addon.db.global.pugHelper and addon.db.global.pugHelper.travelAssistant ~= false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGHelper then
                                NextKey222.PUGHelper:Configure({travelAssistant = value})
                            else
                                if not addon.db.global.pugHelper then
                                    addon.db.global.pugHelper = {}
                                end
                                addon.db.global.pugHelper.travelAssistant = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 21,
                    },
                    getawayUI = {
                        type = "toggle",
                        name = "Post-Run Getaway UI",
                        desc = "Show quick exit options after completing a Mythic+ dungeon with a PUG group",
                        get = function()
                            if NextKey222.PUGHelper then
                                local config = NextKey222.PUGHelper:GetConfig()
                                return config.getawayUI
                            else
                                return addon.db.global.pugHelper and addon.db.global.pugHelper.getawayUI ~= false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGHelper then
                                NextKey222.PUGHelper:Configure({getawayUI = value})
                            else
                                if not addon.db.global.pugHelper then
                                    addon.db.global.pugHelper = {}
                                end
                                addon.db.global.pugHelper.getawayUI = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 22,
                    },
                    testHeader = {
                        type = "header",
                        name = "Testing",
                        order = 30,
                    },
                    testApplication = {
                        type = "execute",
                        name = "Test Application Tracking",
                        desc = "Simulate applying to an LFG group to test the PUG Helper functionality",
                        func = function()
                            if NextKey222.PUGHelper and NextKey222.PUGHelper.TestApplicationTracking then
                                NextKey222.PUGHelper:TestApplicationTracking()
                                addon:Print("PUG Helper: Test application tracking activated")
                            else
                                addon:Print("PUG Helper: Module not available")
                            end
                        end,
                        order = 31,
                    },
                },
            },
        },
    }

    -- Inject enhanced debug options using the new DebugUI module
    if NextKey222.DebugUI and NextKey222.DebugUI.CreateDebugOptions then
        options.args.debugSystem = NextKey222.DebugUI:CreateDebugOptions()
        Debug:Dev("options", "Enhanced debug system loaded successfully")
    elseif self.InjectDebugOptions then
        -- Fallback to old debug options if new system not available
        self:InjectDebugOptions(options)
        Debug:Dev("options", "Using legacy debug options as fallback")
    else
        Debug:Error("No debug options system available")
    end

    local AceConfig = LibStub("AceConfig-3.0")
    AceConfig:RegisterOptionsTable("NextKey", options)

end
