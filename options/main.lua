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
    if not seasonData then
        addon:Print("Error: Could not access season data.")
        return
    end
    
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
                order = 10,
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
            appearance = {
                type = "group",
                name = "Appearance & Themes",
                order = 20,
                args = {
                    themeHeader = {
                        type = "header",
                        name = "Theme Selection",
                        order = 1
                    },
                    currentTheme = {
                        type = "select",
                        name = "UI Theme",
                        desc = "Choose the visual theme for NextKey interface",
                        values = {
                            ["default"] = "Default (Balanced)",
                            ["dark"] = "Dark (Enhanced Contrast)",
                            ["light"] = "Light (Bright Backgrounds)",
                            ["colorblind"] = "Colorblind Friendly",
                            ["high_contrast"] = "High Contrast (Accessibility)"
                        },
                        get = function()
                            if NextKey222.Theme then
                                return NextKey222.Theme:GetCurrentTheme()
                            end
                            return "default"
                        end,
                        set = function(_, value)
                            if NextKey222.Theme then
                                NextKey222.Theme:SetCurrentTheme(value)
                                NextKey222.Theme:SaveTheme()
                                refreshUI()
                            end
                        end,
                        order = 2
                    },
                    themePreview = {
                        type = "description",
                        name = function()
                            if NextKey222.Theme then
                                local theme = NextKey222.Theme:GetCurrentTheme()
                                local themeData = NextKey222.Theme.themes[theme]
                                return themeData and themeData.description or "No theme selected"
                            end
                            return "Theme system not available"
                        end,
                        fontSize = "medium",
                        order = 3
                    },
                    uiScaleHeader = {
                        type = "header",
                        name = "UI Scaling",
                        order = 10
                    },
                    scaleMode = {
                        type = "select",
                        name = "Scale Mode",
                        desc = "Choose how UI scaling is applied",
                        values = {
                            ["manual"] = "Manual Scale",
                            ["auto"] = "Auto Scale (Screen Resolution)"
                        },
                        get = function()
                            if NextKey222.UIScale then
                                return NextKey222.UIScale:IsAutoScaleEnabled() and "auto" or "manual"
                            end
                            return "manual"
                        end,
                        set = function(_, value)
                            if NextKey222.UIScale then
                                if value == "auto" then
                                    NextKey222.UIScale:EnableAutoScale()
                                else
                                    NextKey222.UIScale:DisableAutoScale()
                                end
                                refreshUI()
                            end
                        end,
                        order = 11
                    },
                    manualScale = {
                        type = "range",
                        name = "UI Scale",
                        desc = "Adjust the size of the NextKey interface",
                        min = 0.5,
                        max = 2.0,
                        step = 0.1,
                        isPercent = true,
                        disabled = function()
                            return NextKey222.UIScale and NextKey222.UIScale:IsAutoScaleEnabled()
                        end,
                        get = function()
                            if NextKey222.UIScale then
                                return NextKey222.UIScale:GetCurrentScale()
                            end
                            return 1.0
                        end,
                        set = function(_, value)
                            if NextKey222.UIScale then
                                NextKey222.UIScale:SetScale(value)
                                refreshUI()
                            end
                        end,
                        order = 12
                    },
                    scalePreset = {
                        type = "select",
                        name = "Scale Preset",
                        desc = "Quick select common scale values",
                        values = {
                            ["0.6"] = "Tiny (60%)",
                            ["0.8"] = "Small (80%)",
                            ["1.0"] = "Normal (100%)",
                            ["1.2"] = "Large (120%)",
                            ["1.5"] = "Huge (150%)",
                            ["1.8"] = "Massive (180%)"
                        },
                        disabled = function()
                            return NextKey222.UIScale and NextKey222.UIScale:IsAutoScaleEnabled()
                        end,
                        get = function()
                            if NextKey222.UIScale then
                                return tostring(NextKey222.UIScale:GetCurrentScale())
                            end
                            return "1.0"
                        end,
                        set = function(_, value)
                            if NextKey222.UIScale then
                                NextKey222.UIScale:SetScale(tonumber(value))
                                refreshUI()
                            end
                        end,
                        order = 13
                    },
                    animateScaleChanges = {
                        type = "toggle",
                        name = "Animate Scale Changes",
                        desc = "Smoothly animate between different scale values",
                        width = "full",
                        get = function() return addon.db.char.animateScaleChanges ~= false end,
                        set = function(_, value)
                            addon.db.char.animateScaleChanges = value
                            refreshUI()
                        end,
                        order = 14
                    },
                    responsiveHeader = {
                        type = "header",
                        name = "Responsive Layout",
                        order = 20
                    },
                    layoutMode = {
                        type = "select",
                        name = "Layout Mode",
                        desc = "Choose how the interface adapts to different screen sizes",
                        values = {
                            ["auto"] = "Auto (Detect Screen Size)",
                            ["compact"] = "Compact (Small Screens)",
                            ["standard"] = "Standard (Medium Screens)",
                            ["expanded"] = "Expanded (Large Screens)"
                        },
                        get = function()
                            if NextKey222.Responsive then
                                return NextKey222.Responsive:GetCurrentLayoutMode():lower()
                            end
                            return "auto"
                        end,
                        set = function(_, value)
                            if NextKey222.Responsive then
                                NextKey222.Responsive:SetLayoutMode(value)
                                refreshUI()
                            end
                        end,
                        order = 21
                    },
                    currentBreakpoint = {
                        type = "description",
                        name = function()
                            if NextKey222.Responsive then
                                local breakpoint = NextKey222.Responsive:GetCurrentBreakpoint()
                                local mode = NextKey222.Responsive:GetLayoutMode()
                                return string.format("Current: %s screen, %s layout",
                                    breakpoint:sub(1,1):upper() .. breakpoint:sub(2),
                                    mode:sub(1,1):upper() .. mode:sub(2))
                            end
                            return "Responsive system not available"
                        end,
                        fontSize = "small",
                        order = 22
                    }
                }
            },
            interface = {
                type = "group",
                name = "Interface",
                order = 30,
                args = {
                    tooltipHeader = {
                        type = "header",
                        name = "Tooltip Configuration",
                        order = 1
                    },
                    smartPositioning = {
                        type = "toggle",
                        name = "Smart Tooltip Positioning",
                        desc = "Automatically adjust tooltip position to avoid screen edges",
                        width = "full",
                        get = function() return addon.db.char.tooltipSmartPositioning ~= false end,
                        set = function(_, value)
                            addon.db.char.tooltipSmartPositioning = value
                            refreshUI()
                        end,
                        order = 2
                    },
                    tooltipDelay = {
                        type = "range",
                        name = "Tooltip Delay",
                        desc = "Delay before tooltips appear when hovering over elements",
                        min = 0,
                        max = 2.0,
                        step = 0.1,
                        get = function() return addon.db.char.tooltipDelay or 0.2 end,
                        set = function(_, value)
                            addon.db.char.tooltipDelay = value
                            refreshUI()
                        end,
                        order = 3
                    },
                    tooltipScale = {
                        type = "range",
                        name = "Tooltip Scale",
                        desc = "Adjust the size of tooltips relative to UI scale",
                        min = 0.5,
                        max = 1.5,
                        step = 0.1,
                        isPercent = true,
                        get = function() return addon.db.char.tooltipScale or 1.0 end,
                        set = function(_, value)
                            addon.db.char.tooltipScale = value
                            refreshUI()
                        end,
                        order = 4
                    },
                    animationHeader = {
                        type = "header",
                        name = "Animations & Transitions",
                        order = 10
                    },
                    enableAnimations = {
                        type = "toggle",
                        name = "Enable UI Animations",
                        desc = "Show smooth transitions and animations throughout the interface",
                        width = "full",
                        get = function() return addon.db.char.enableUIAnimations ~= false end,
                        set = function(_, value)
                            addon.db.char.enableUIAnimations = value
                            refreshUI()
                        end,
                        order = 11
                    },
                    animationSpeed = {
                        type = "range",
                        name = "Animation Speed",
                        desc = "Control the speed of UI animations",
                        min = 0.1,
                        max = 2.0,
                        step = 0.1,
                        isPercent = true,
                        disabled = function() return addon.db.char.enableUIAnimations == false end,
                        get = function() return addon.db.char.animationSpeed or 1.0 end,
                        set = function(_, value)
                            addon.db.char.animationSpeed = value
                            refreshUI()
                        end,
                        order = 12
                    },
                    dynamicHeader = {
                        type = "header",
                        name = "Dynamic Configuration",
                        order = 20
                    },
                    enableDynamicConfig = {
                        type = "toggle",
                        name = "Enable Dynamic UI",
                        desc = "Automatically show/hide UI elements based on context (debug mode, party size, etc.)",
                        width = "full",
                        get = function() return addon.db.char.enableDynamicConfig ~= false end,
                        set = function(_, value)
                            addon.db.char.enableDynamicConfig = value
                            if NextKey222.ConfigurationContext then
                                NextKey222.ConfigurationContext:InvalidateCache()
                            end
                            refreshUI()
                        end,
                        order = 21
                    },
                    debugModeIntegration = {
                        type = "toggle",
                        name = "Debug Mode Integration",
                        desc = "When debug mode is enabled, automatically show debug controls and enhanced features",
                        width = "full",
                        disabled = function() return addon.db.char.enableDynamicConfig == false end,
                        get = function() return addon.db.char.debugModeIntegration ~= false end,
                        set = function(_, value)
                            addon.db.char.debugModeIntegration = value
                            if NextKey222.ConfigurationContext then
                                NextKey222.ConfigurationContext:InvalidateCache()
                            end
                            refreshUI()
                        end,
                        order = 22
                    }
                }
            },
            performance = {
                type = "group",
                name = "Performance",
                order = 40,
                args = {
                    cachingHeader = {
                        type = "header",
                        name = "Caching & Optimization",
                        order = 1
                    },
                    enableCaching = {
                        type = "toggle",
                        name = "Enable UI Caching",
                        desc = "Cache UI calculations to improve performance",
                        width = "full",
                        get = function() return addon.db.char.enableUICaching ~= false end,
                        set = function(_, value)
                            addon.db.char.enableUICaching = value
                            refreshUI()
                        end,
                        order = 2
                    },
                    cacheTimeout = {
                        type = "range",
                        name = "Cache Timeout",
                        desc = "How long to cache UI calculations before refreshing (in seconds)",
                        min = 30,
                        max = 600,
                        step = 30,
                        disabled = function() return addon.db.char.enableUICaching == false end,
                        get = function() return addon.db.char.cacheTimeout or 300 end,
                        set = function(_, value)
                            addon.db.char.cacheTimeout = value
                            refreshUI()
                        end,
                        order = 3
                    },
                    batchUpdates = {
                        type = "toggle",
                        name = "Batch UI Updates",
                        desc = "Group UI updates together for better performance",
                        width = "full",
                        get = function() return addon.db.char.batchUIUpdates ~= false end,
                        set = function(_, value)
                            addon.db.char.batchUIUpdates = value
                            refreshUI()
                        end,
                        order = 4
                    },
                    advancedHeader = {
                        type = "header",
                        name = "Advanced Performance",
                        order = 10
                    },
                    throttleInterval = {
                        type = "range",
                        name = "Update Throttling",
                        desc = "Minimum time between UI updates (lower = more responsive, higher = better performance)",
                        min = 0.01,
                        max = 1.0,
                        step = 0.01,
                        get = function() return addon.db.char.updateThrottleInterval or 0.1 end,
                        set = function(_, value)
                            addon.db.char.updateThrottleInterval = value
                            refreshUI()
                        end,
                        order = 11
                    },
                    enableProfiling = {
                        type = "toggle",
                        name = "Enable Performance Profiling",
                        desc = "Track performance metrics for optimization (development use only)",
                        width = "full",
                        get = function() return addon.db.char.enablePerformanceProfiling or false end,
                        set = function(_, value)
                            addon.db.char.enablePerformanceProfiling = value
                            if NextKey222.Performance then
                                NextKey222.Performance.enabled = value
                            end
                            refreshUI()
                        end,
                        order = 12
                    }
                }
            },
            teleport = {
                type = "group",
                name = "Teleport Window",
                order = 50,
                args = {
                    compactMode = {
                        type = "toggle",
                        name = "Compact Mode",
                        desc = "Show only icons instead of full cards. Makes the window much smaller and shows just the teleport icons.",
                        width = "full",
                        get = function() return addon.db.global.teleport.compactMode end,
                        set = function(_, value)
                            addon.db.global.teleport.compactMode = value
                            -- Refresh teleport window if it's open
                            if addon.RefreshTeleportWindow then
                                addon:RefreshTeleportWindow()
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        order = 1,
                    },
                    selectHearthstone = {
                        type = "execute",
                        name = "Select Hearthstone",
                        desc = "Choose which hearthstone toy, item, or spell to use in the teleport window from your collection.",
                        func = function()
                            if addon.ShowHearthstoneSelector then
                                addon:ShowHearthstoneSelector()
                            else
                                addon:Print("Hearthstone selector not available")
                            end
                        end,
                        order = 1.5,
                    },
                    currentHearthstone = {
                        type = "description",
                        name = function()
                            local selectedID = addon.db.global.teleport.selectedHearthstoneID or 6948
                            local hearthstone = NextKey222 and NextKey222.HearthstoneData and NextKey222.HearthstoneData.GetHearthstoneByID(selectedID)
                            if hearthstone then
                                local isAvailable = NextKey222.HearthstoneData.HasHearthstone(hearthstone.id, hearthstone.type)
                                local status = isAvailable and "|cff00ff00(Available)|r" or "|cffff0000(Not Available)|r"
                                return "Current: " .. hearthstone.name .. " " .. status
                            else
                                return "Current: Standard Hearthstone"
                            end
                        end,
                        fontSize = "small",
                        order = 1.6,
                    },
                    showHearthstone = {
                        type = "toggle",
                        name = "Show Hearthstone",
                        desc = "Show hearthstone locations in the teleport window.",
                        width = "full",
                        get = function() return addon.db.global.teleport.showHearthstone end,
                        set = function(_, value)
                            addon.db.global.teleport.showHearthstone = value
                            -- Refresh teleport window if it's open
                            if addon.RefreshTeleportWindow then
                                addon:RefreshTeleportWindow()
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        order = 2,
                    },
                },
            },
            pugHelper = {
                type = "group",
                name = "PUG Helper",
                desc = "Settings for the PUG (Pick Up Group) Helper that assists with LFG workflow",
                order = 60,
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
                    applicationTrackerHeader = {
                        type = "header",
                        name = "Application Tracker",
                        order = 23,
                    },
                    applicationTracker = {
                        type = "toggle",
                        name = "Show Application Tracker",
                        desc = "Display a window showing active LFG applications with dungeon, key level, leader, and status",
                        get = function()
                            if NextKey222.PUGApplicationTracker then
                                return NextKey222.PUGApplicationTracker:IsEnabled()
                            else
                                return addon.db.global.pugApplicationTracker and addon.db.global.pugApplicationTracker.enabled or false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGApplicationTracker then
                                NextKey222.PUGApplicationTracker:SetEnabled(value)
                            else
                                if not addon.db.global.pugApplicationTracker then
                                    addon.db.global.pugApplicationTracker = {}
                                end
                                addon.db.global.pugApplicationTracker.enabled = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 24,
                    },
                    autoShowTracker = {
                        type = "toggle",
                        name = "Auto-Show Tracker",
                        desc = "Automatically show the application tracker when you have active applications",
                        get = function()
                            if NextKey222.PUGApplicationTracker then
                                local config = NextKey222.PUGApplicationTracker:GetConfig()
                                return config.autoShow
                            else
                                return addon.db.global.pugApplicationTracker and addon.db.global.pugApplicationTracker.autoShow ~= false
                            end
                        end,
                        set = function(_, value)
                            if NextKey222.PUGApplicationTracker then
                                NextKey222.PUGApplicationTracker:Configure({autoShow = value})
                            else
                                if not addon.db.global.pugApplicationTracker then
                                    addon.db.global.pugApplicationTracker = {}
                                end
                                addon.db.global.pugApplicationTracker.autoShow = value
                            end
                            local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
                            if reg then reg:NotifyChange("NextKey") end
                        end,
                        width = "full",
                        order = 25,
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
            mythicPlus = {
                type = "group",
                name = "M+ Data",
                order = 70,
                args = {
                    currentScore = {
                        type = "description",
                        name = function()
                            local seasonData = addon:EnsureSeasonData()
                            if not seasonData then
                                return "Current M+ Score: Not available"
                            end
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
                                    if addon.CollectPartyKeys then
                                        addon:CollectPartyKeys()
                                        print("NextKey: Refreshed keystone data")
                                    end
                                    refreshUI()
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
                                    
                                    local seasonData = addon:EnsureSeasonData()
                                    if not seasonData then
                                        addon:Print("Could not initialize season data.")
                                        return
                                    end
                                    
                                    seasonData.currentScore = profile.mythicKeystoneProfile.currentScore or 0
                                    refreshUI()
                                    addon:Print("Successfully imported RaiderIO score: " .. seasonData.currentScore)
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
                        args = (function()
                            local args = {}
                            local dungeons = {}
                            
                            -- Get active season dungeons with error handling
                            if addon.GetActiveSeasonDungeonIDs then
                                local success, dungeonIDs = pcall(addon.GetActiveSeasonDungeonIDs, addon)
                                if success and dungeonIDs then
                                    for _, mapID in ipairs(dungeonIDs) do
                                        local success, name = pcall(addon.GetDungeonName, addon, mapID)
                                        if success and name then
                                            dungeons[tostring(mapID)] = name
                                        end
                                    end
                                end
                            end
                            
                            -- If no dungeons found, show message
                            if next(dungeons) == nil then
                                args.noDungeons = {
                                    type = "description",
                                    name = "No dungeon data available. Please try refreshing data first.",
                                    fontSize = "medium",
                                    order = 1
                                }
                                return args
                            end
                            
                            -- Add dungeon score inputs for each dungeon
                            for mapID, name in pairs(dungeons) do
                                local mid = tonumber(mapID)
                                local mythicData = getMythicPlusData()
                                local bestEntry = mythicData and mythicData[mid]
                                
                                args[mapID .. "_header"] = {
                                    type = "header",
                                    name = name,
                                    order = mid * 10
                                }
                                
                                args[mapID .. "_level"] = {
                                    type = "range",
                                    name = "Level",
                                    min = 0,
                                    max = 30,
                                    step = 1,
                                    get = function()
                                        return bestEntry and bestEntry.level or 0
                                    end,
                                    set = function(_, value)
                                        updateDungeonScore(mid, value, bestEntry and bestEntry.timed or false)
                                    end,
                                    order = mid * 10 + 1
                                }
                                
                                args[mapID .. "_timed"] = {
                                    type = "toggle",
                                    name = "Timed",
                                    get = function()
                                        return bestEntry and bestEntry.timed or false
                                    end,
                                    set = function(_, value)
                                        updateDungeonScore(mid, bestEntry and bestEntry.level or 0, value)
                                    end,
                                    order = mid * 10 + 2
                                }
                            end
                            
                            return args
                        end)()
                    }
                }
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
