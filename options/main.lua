-- MARK: Options Registration

local _, NextKey222 = ...
local addon = NextKey222.Addon
if not addon then return end

local Debug = NextKey222.Debug

-- MARK: Local Helpers

local function notify_options_changed()
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

local function refresh_ui()
    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame then
        NextKey222.UI:RenderResults()
    end

    if addon.RefreshTeleportWindow then
        addon:RefreshTeleportWindow()
    end

    notify_options_changed()
end

local function get_active_season_dungeons()
    local values = {}

    if not addon.GetActiveSeasonDungeonIDs or not addon.GetDungeonName then
        return values
    end

    local ok, dungeon_ids = pcall(addon.GetActiveSeasonDungeonIDs, addon)
    if not ok or not dungeon_ids then
        return values
    end

    for _, map_id in ipairs(dungeon_ids) do
        local success, name = pcall(addon.GetDungeonName, addon, map_id)
        if success and name then
            values[tostring(map_id)] = name
        end
    end

    return values
end

-- MARK: Dev Tools Helpers

local function ensure_debug()
    if not addon.EnsureDebug then
        return nil
    end
    return addon:EnsureDebug()
end

local function ensure_debug_add_form()
    if addon.EnsureDebugAddForm then
        return addon:EnsureDebugAddForm()
    end
    local dbg = ensure_debug()
    if not dbg then
        return { best = {} }
    end
    dbg.addForm = dbg.addForm or { best = {} }
    return dbg.addForm
end

local function get_selected_fake_index()
    local dbg = ensure_debug()
    return dbg and dbg.selectedPlayerIndex or nil
end

local function set_selected_fake_index(value)
    local dbg = ensure_debug()
    if not dbg then return end

    if not value or value == "" then
        dbg.selectedPlayerIndex = nil
    else
        dbg.selectedPlayerIndex = tonumber(value)
    end
end

local function create_developer_tools_group()
    local dungeons = get_active_season_dungeons()

    local function get_players()
        return NextKey222.FakePlayerService and NextKey222.FakePlayerService:GetAllPlayers() or {}
    end

    local dev_args = {}

    -- Gate: this whole group is intended for authors/testers; keep label clear.
    dev_args.header = {
        type = "description",
        name = "Developer and testing utilities. Not required for normal gameplay use.",
        order = 0,
        fontSize = "medium",
    }

    -- Debug master toggle
    dev_args.enable_debug_mode = {
        type = "toggle",
        name = "Enable Debug Mode",
        desc = "Enable NextKey internal debug/test features.",
        width = "full",
        order = 1,
        get = function()
            local dbg = ensure_debug()
            return dbg and dbg.enabled or false
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.enabled = v and true or false
            
            -- When enabling Debug Mode, disable Basic Tools
            if v then
                dbg.basicToolsEnabled = false
            end

            if NextKey222.UI and NextKey222.UI.OnDebugModeChanged then
                NextKey222.UI:OnDebugModeChanged()
            end

            if NextKey222.Debug and NextKey222.Debug.SetEnabled then
                NextKey222.Debug:SetEnabled(dbg.enabled)
            end
            
            -- Refresh options UI to update checkbox states
            notify_options_changed()
        end,
    }
    
    -- Basic Fake Player Testing Tools toggle
    dev_args.enable_basic_tools = {
        type = "toggle",
        name = "Enable Basic Fake Player Testing Tools",
        desc = "Enable simplified fake player generation tools (team builders and custom player creator). This provides a subset of debug features without full debug mode overhead.",
        width = "full",
        order = 2,
        disabled = function()
            local dbg = ensure_debug()
            return dbg and dbg.enabled or false
        end,
        get = function()
            local dbg = ensure_debug()
            return dbg and dbg.basicToolsEnabled or false
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            
            -- Prevent enabling if Debug Mode is active
            if dbg.enabled then
                if Debug then
                    Debug:User("Cannot enable Basic Tools while Debug Mode is active")
                end
                return
            end
            
            dbg.basicToolsEnabled = v and true or false
            notify_options_changed()
        end,
    }
    
    -- Tooltip widget that shows when Basic Tools is disabled due to Debug Mode
    dev_args.basic_tools_disabled_info = {
        type = "description",
        name = function()
            local dbg = ensure_debug()
            if dbg and dbg.enabled then
                return "|cFFFFAA00Basic Tools are disabled while Debug Mode is active. Disable Debug Mode to use Basic Tools.|r"
            end
            return ""
        end,
        order = 2.5,
        fontSize = "small",
        hidden = function()
            local dbg = ensure_debug()
            return not (dbg and dbg.enabled)
        end,
    }
    
    -- MARK: Section 1 - Teams
    dev_args.quickteams_header = {
        type = "header",
        name = "Quick Teams",
        order = 5,
    }
    
    dev_args.quickteams_description = {
        type = "description",
        name = "Preset team compositions for quick testing",
        order = 6,
        fontSize = "small",
    }
    
    -- Addon config toggles
    dev_args.addon_nextkey = {
        type = "toggle",
        name = "Preset: Players Have NextKey",
        desc = "Fake players are considered to have NextKey installed.",
        order = 7,
        width = "full",
        get = function()
            local dbg = ensure_debug()
            if not dbg then return false end
            dbg.presetAddonConfig = dbg.presetAddonConfig or { nextkey = true, raiderio = true }
            return dbg.presetAddonConfig.nextkey
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.presetAddonConfig = dbg.presetAddonConfig or {}
            dbg.presetAddonConfig.nextkey = v and true or false
        end,
    }
    
    dev_args.addon_raiderio = {
        type = "toggle",
        name = "Preset: Players Have RaiderIO",
        desc = "Fake players are considered to have RaiderIO data.",
        order = 8,
        width = "full",
        get = function()
            local dbg = ensure_debug()
            if not dbg then return false end
            dbg.presetAddonConfig = dbg.presetAddonConfig or { nextkey = true, raiderio = true }
            return dbg.presetAddonConfig.raiderio
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.presetAddonConfig = dbg.presetAddonConfig or {}
            dbg.presetAddonConfig.raiderio = v and true or false
        end,
    }
    
    dev_args.spacer1 = {
        type = "header",
        name = "",
        order = 9,
    }
    
    -- Quick team buttons
    dev_args.gen_mixed = {
        type = "execute",
        name = "Mixed Skill (4 players)",
        desc = "4 players with varied IO for realistic testing.",
        order = 10,
        func = function()
            if not ensure_debug() or not NextKey222.Addon or not NextKey222.Addon.GeneratePresetTeam then
                if Debug then Debug:User("devtools", "Preset generator not available.") end
                return
            end
            NextKey222.Addon:ClearFakePlayers()
            local count = NextKey222.Addon:GeneratePresetTeam("mixed_skill")
            if Debug then Debug:User("devtools", ("Generated %d fake players (mixed_skill)"):format(count or 0)) end
            refresh_ui()
        end,
    }
    
    dev_args.gen_beginner = {
        type = "execute",
        name = "Beginner Team",
        desc = "Lower IO players for fallback/path testing.",
        order = 11,
        func = function()
            if not ensure_debug() or not NextKey222.Addon or not NextKey222.Addon.GeneratePresetTeam then
                if Debug then Debug:User("devtools", "Preset generator not available.") end
                return
            end
            NextKey222.Addon:ClearFakePlayers()
            local count = NextKey222.Addon:GeneratePresetTeam("beginner")
            if Debug then Debug:User("devtools", ("Generated %d fake players (beginner)"):format(count or 0)) end
            refresh_ui()
        end,
    }
    
    dev_args.gen_expert = {
        type = "execute",
        name = "Expert Team",
        desc = "High IO players for pushing scenarios.",
        order = 12,
        func = function()
            if not ensure_debug() or not NextKey222.Addon or not NextKey222.Addon.GeneratePresetTeam then
                if Debug then Debug:User("devtools", "Preset generator not available.") end
                return
            end
            NextKey222.Addon:ClearFakePlayers()
            local count = NextKey222.Addon:GeneratePresetTeam("expert")
            if Debug then Debug:User("devtools", ("Generated %d fake players (expert)"):format(count or 0)) end
            refresh_ui()
        end,
    }
    
    dev_args.gen_boosting_team = {
        type = "execute",
        name = "Boosting Team (3 boosters + 1 carry)",
        desc = "Tests Max Group IO vs Player Coverage - 3 expert players + 1 beginner to showcase algorithm differences.",
        order = 13,
        func = function()
            if not ensure_debug() or not NextKey222.Addon or not NextKey222.Addon.GeneratePresetTeam then
                if Debug then Debug:User("devtools", "Preset generator not available.") end
                return
            end
            NextKey222.Addon:ClearFakePlayers()
            
            -- Use GeneratePreset to ensure proper addon config and score generation
            -- Create 3 experts
            for i = 1, 3 do
                if NextKey222.FakePlayerService and NextKey222.FakePlayerService.CreatePlayer then
                    -- Get addon configuration from debug state (same as other presets)
                    local addonConfig = { nextkey = true, raiderio = true }
                    if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
                        local dbg = NextKey222.Addon.db.global.debug
                        if dbg.presetAddonConfig then
                            addonConfig = dbg.presetAddonConfig
                        end
                    end
                    
                    NextKey222.FakePlayerService:CreatePlayer({
                        tier = "expert",
                        class = ({"WARRIOR", "PALADIN", "PRIEST"})[i],
                        addonStatus = addonConfig,
                    })
                end
            end
            
            -- Create 1 beginner
            if NextKey222.FakePlayerService and NextKey222.FakePlayerService.CreatePlayer then
                local addonConfig = { nextkey = true, raiderio = true }
                if NextKey222.Addon and NextKey222.Addon.db and NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug then
                    local dbg = NextKey222.Addon.db.global.debug
                    if dbg.presetAddonConfig then
                        addonConfig = dbg.presetAddonConfig
                    end
                end
                
                NextKey222.FakePlayerService:CreatePlayer({
                    tier = "beginner",
                    class = "HUNTER",
                    addonStatus = addonConfig,
                })
            end
            
            if Debug then Debug:User("devtools", "Generated boosting team (3 experts + 1 beginner)") end
            refresh_ui()
        end,
    }
    
    dev_args.gen_high_keys = {
        type = "execute",
        name = "High Keys Team",
        desc = "Team with high-level keystones for challenge testing.",
        order = 14,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateLevelRange then
                if Debug then Debug:User("devtools", "High keys generator not available.") end
                return
            end
            NextKey222.Addon:ClearFakePlayers()
            local count = NextKey222.FakePlayerService:GenerateLevelRange(15, 18, 4)
            if Debug then Debug:User("devtools", ("Generated %d players with high keys"):format(count or 0)) end
            refresh_ui()
        end,
    }
    
    dev_args.spacer2 = {
        type = "header",
        name = "",
        order = 15,
    }
    
    dev_args.clear_fake = {
        type = "execute",
        name = "Clear All Fake Players",
        desc = "Remove all fake players from the system.",
        confirm = true,
        order = 16,
        func = function()
            if NextKey222.Addon and NextKey222.Addon.ClearFakePlayers then
                NextKey222.Addon:ClearFakePlayers()
                refresh_ui()
            end
        end,
    }
    
    -- MARK: Section 2 - Algo Tests
    dev_args.algorithmtests_header = {
        type = "header",
        name = "Algorithm Test Scenarios",
        order = 20,
    }
    
    dev_args.algorithmtests_description = {
        type = "description",
        name = "Edge case generators that differentiate sorting algorithms",
        order = 21,
        fontSize = "small",
    }
    
    dev_args.iogap = {
        type = "execute",
        name = "IO Gap Test",
        desc = "MaxGroupIO vs SmartSort differentiation - creates team where algorithms produce different rankings",
        order = 22,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RunScenario then
                if Debug then Debug:User("devtools", "Scenario system not available.") end
                return
            end
            NextKey222.FakePlayerService:RunScenario("io_gap")
            if NextKey222.FakePlayerService.ShowAlgorithmComparison then
                NextKey222.FakePlayerService:ShowAlgorithmComparison()
            end
            refresh_ui()
        end,
    }
    
    dev_args.lootpriority = {
        type = "execute",
        name = "Loot Priority Test",
        desc = "ItemNeed vs other algorithms - tests loot-based sorting",
        order = 23,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RunScenario then
                if Debug then Debug:User("devtools", "Scenario system not available.") end
                return
            end
            NextKey222.FakePlayerService:RunScenario("loot_priority")
            if NextKey222.FakePlayerService.ShowAlgorithmComparison then
                NextKey222.FakePlayerService:ShowAlgorithmComparison()
            end
            refresh_ui()
        end,
    }
    
    dev_args.coverage = {
        type = "execute",
        name = "Coverage Test",
        desc = "PlayerCoverage edge case - uneven benefit distribution",
        order = 24,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RunScenario then
                if Debug then Debug:User("devtools", "Scenario system not available.") end
                return
            end
            NextKey222.FakePlayerService:RunScenario("coverage_test")
            if NextKey222.FakePlayerService.ShowAlgorithmComparison then
                NextKey222.FakePlayerService:ShowAlgorithmComparison()
            end
            refresh_ui()
        end,
    }
    
    dev_args.comprehensive = {
        type = "execute",
        name = "Comprehensive Suite",
        desc = "All 7 algorithms should produce different results - maximum variance",
        order = 25,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RunScenario then
                if Debug then Debug:User("devtools", "Scenario system not available.") end
                return
            end
            NextKey222.FakePlayerService:RunScenario("comprehensive")
            if NextKey222.FakePlayerService.ShowAlgorithmComparison then
                NextKey222.FakePlayerService:ShowAlgorithmComparison()
            end
            refresh_ui()
        end,
    }
    
    dev_args.spacer_algo = {
        type = "header",
        name = "",
        order = 26,
    }
    
    dev_args.showcomparison = {
        type = "execute",
        name = "Show Algorithm Comparison",
        desc = "Compare how all 7 algorithms rank current keys",
        order = 27,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.ShowAlgorithmComparison then
                if Debug then Debug:User("devtools", "Algorithm comparison not available.") end
                return
            end
            NextKey222.FakePlayerService:ShowAlgorithmComparison()
        end,
    }
    
    -- MARK: Section 3 - Builder
    dev_args.custombuilder_header = {
        type = "header",
        name = "Custom Player Builder",
        order = 30,
    }
    
    dev_args.custombuilder_description = {
        type = "description",
        name = "Create fully customized fake players with precise control over all attributes",
        order = 31,
        fontSize = "small",
    }
    
    -- Basic Info
    dev_args.builder_name = {
        type = "input",
        name = "Player Name",
        desc = "Blizzard Rules: 2-12 letters, no mixed capitals (use 'Tank', 'TANK', or 'tank', not 'TaNk')",
        order = 27,
        width = "normal",
        get = function()
            local form = ensure_debug_add_form()
            return form.name or ""
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.name = value
            notify_options_changed()  -- Force refresh to update counter
        end,
    }
    
    -- Character counter (live update)
    dev_args.builder_name_counter = {
        type = "description",
        name = function()
            local form = ensure_debug_add_form()
            local name = form.name or ""
            local baseName = name:match("^([^%-]+)") or name
            local length = #baseName
            
            -- Build status message
            local lengthStatus = string.format("%d/12 characters", length)
            local validationMsg = ""
            
            -- Validate and show errors
            if length > 0 then
                if length < 2 then
                    validationMsg = " |cFFFF0000- Too short (min 2)|r"
                elseif length > 12 then
                    validationMsg = " |cFFFF0000- Too long (max 12)|r"
                elseif not baseName:match("^%a+$") then
                    validationMsg = " |cFFFF0000- Invalid characters (letters only)|r"
                else
                    -- Check for mixed capitals (e.g., "TaNk")
                    local isAllLower = baseName == baseName:lower()
                    local isAllUpper = baseName == baseName:upper()
                    local isProperCase = baseName:sub(1, 1) == baseName:sub(1, 1):upper() and baseName:sub(2) == baseName:sub(2):lower()
                    
                    if not (isAllLower or isAllUpper or isProperCase) then
                        validationMsg = " |cFFFF0000- No mixed capitals (use 'Tank', 'TANK', or 'tank', not 'TaNk')|r"
                    else
                        validationMsg = " |cFF00FF00- Valid|r"
                    end
                end
            end
            
            return lengthStatus .. validationMsg
        end,
        order = 27.5,
        fontSize = "small",
    }
    
    dev_args.builder_class = {
        type = "select",
        name = "Class",
        desc = "Select player class",
        order = 28,
        values = {
            WARRIOR = "Warrior",
            PALADIN = "Paladin",
            HUNTER = "Hunter",
            ROGUE = "Rogue",
            PRIEST = "Priest",
            DEATHKNIGHT = "Death Knight",
            SHAMAN = "Shaman",
            MAGE = "Mage",
            WARLOCK = "Warlock",
            MONK = "Monk",
            DRUID = "Druid",
            DEMONHUNTER = "Demon Hunter",
            EVOKER = "Evoker",
        },
        get = function()
            local form = ensure_debug_add_form()
            return form.class or "WARRIOR"
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.class = value
            -- Reset spec when class changes
            form.specID = nil
            notify_options_changed()
        end,
    }
    
    dev_args.builder_spec = {
        type = "select",
        name = "Specialization",
        desc = "Select specific spec (auto-filtered by class)",
        order = 29,
        values = function()
            local form = ensure_debug_add_form()
            local class = form.class or "WARRIOR"
            
            -- Get specs from FakePlayerService
            if NextKey222.FakePlayerService and NextKey222.FakePlayerService.GetClassSpecs then
                local specs = NextKey222.FakePlayerService:GetClassSpecs(class)
                local values = { [0] = "Random" }
                for _, spec in ipairs(specs) do
                    values[spec.specID] = string.format("%s (%s)", spec.specName, spec.role)
                end
                return values
            end
            
            return { [0] = "Random" }
        end,
        get = function()
            local form = ensure_debug_add_form()
            return form.specID or 0
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.specID = (value ~= 0) and value or nil
        end,
    }
    
    -- Scoring
    dev_args.builder_tier = {
        type = "select",
        name = "Skill Tier Preset",
        desc = "Use preset skill tier for automatic score generation",
        order = 30,
        values = {
            [""] = "Manual IO Score",
            title = "Title (3600-3800 IO)",
            elite = "Elite (3300-3600 IO)",
            expert = "Expert (3100-3400 IO)",
            skilled = "Skilled (2900-3100 IO)",
            competent = "Competent (2500-2900 IO)",
            average = "Average (2000-2600 IO)",
            casual = "Casual (1500-2000 IO)",
            beginner = "Beginner (1000-1500 IO)",
        },
        get = function()
            local form = ensure_debug_add_form()
            return form.tier or ""
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.tier = (value ~= "") and value or nil
        end,
    }
    
    dev_args.builder_io = {
        type = "range",
        name = "Manual IO Score",
        desc = "Specific IO score (only used if no tier preset selected)",
        order = 31,
        min = 0,
        max = 4000,
        step = 10,
        disabled = function()
            local form = ensure_debug_add_form()
            return form.tier ~= nil and form.tier ~= ""
        end,
        get = function()
            local form = ensure_debug_add_form()
            return form.io or 2500
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.io = value
        end,
    }
    
    -- Keystone
    dev_args.builder_keystone_dungeon = {
        type = "select",
        name = "Keystone Dungeon",
        desc = "Select dungeon for player's keystone (optional)",
        order = 32,
        values = function()
            local dungeons = get_active_season_dungeons()
            dungeons[""] = "No Keystone"
            return dungeons
        end,
        get = function()
            local form = ensure_debug_add_form()
            return tostring(form.keystoneDungeon or "")
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.keystoneDungeon = (value ~= "" and tonumber(value)) or nil
        end,
    }
    
    dev_args.builder_keystone_level = {
        type = "range",
        name = "Keystone Level",
        desc = "Level for player's keystone",
        order = 33,
        min = 2,
        max = 30,
        step = 1,
        disabled = function()
            local form = ensure_debug_add_form()
            return not form.keystoneDungeon
        end,
        get = function()
            local form = ensure_debug_add_form()
            return form.keystoneLevel or 10
        end,
        set = function(_, value)
            local form = ensure_debug_add_form()
            form.keystoneLevel = value
        end,
    }
    
    -- MARK: Per-Dungeon Tuning
    dev_args.perdungeontuning = {
        type = "group",
        name = "Per-Dungeon Tuning",
        inline = false,
        order = 31.5,
        args = {
            header = {
                type = "description",
                name = "Adjust performance per dungeon relative to base skill tier. Use modifiers from -4 (much weaker) to +4 (much stronger) for precise control over each dungeon's score.",
                order = 0,
                fontSize = "small",
            },
        }
    }
    
    -- Dynamically add sliders for each dungeon
    do
        local dungeons = get_active_season_dungeons()
        local order = 1
        
        for dungeonIDStr, dungeonName in pairs(dungeons) do
            local dungeonID = tonumber(dungeonIDStr)
            if dungeonID then
                dev_args.perdungeontuning.args["dungeon_" .. dungeonID] = {
                    type = "range",
                    name = dungeonName,
                    desc = string.format("Modifier: -4 (much weaker) to +4 (much stronger) for %s", dungeonName),
                    min = -4,
                    max = 4,
                    step = 1,
                    get = function()
                        local form = ensure_debug_add_form()
                        form.dungeonOverrides = form.dungeonOverrides or {}
                        local override = form.dungeonOverrides[dungeonID]
                        if override and override.modifier then
                            return override.modifier
                        end
                        return 0
                    end,
                    set = function(_, val)
                        local form = ensure_debug_add_form()
                        form.dungeonOverrides = form.dungeonOverrides or {}
                        if val == 0 then
                            -- Remove override when set to 0 (neutral)
                            form.dungeonOverrides[dungeonID] = nil
                        else
                            form.dungeonOverrides[dungeonID] = { modifier = val }
                        end
                        notify_options_changed()
                    end,
                    order = order
                }
                order = order + 1
            end
        end
        
        -- Reset button
        dev_args.perdungeontuning.args.reset = {
            type = "execute",
            name = "Reset All to Tier Default",
            desc = "Clear all per-dungeon modifiers",
            func = function()
                local form = ensure_debug_add_form()
                form.dungeonOverrides = {}
                notify_options_changed()
            end,
            order = 99
        }
    end
    
    -- MARK: Loot Targeting
    dev_args.loottargeting = {
        type = "group",
        name = "Loot Targeting",
        inline = false,
        order = 31.7,
        args = {
            description = {
                type = "description",
                name = "Assign loot targets to test the 'Max Item Need' sorting algorithm. Select dungeons this player needs loot from.",
                order = 0,
                fontSize = "small",
            },
            targetdungeons = {
                type = "multiselect",
                name = "Target Dungeons",
                desc = "Select dungeons this player needs loot from",
                values = function()
                    return get_active_season_dungeons()
                end,
                get = function(_, dungeonID)
                    local form = ensure_debug_add_form()
                    form.lootDungeons = form.lootDungeons or {}
                    return form.lootDungeons[tonumber(dungeonID)] == true
                end,
                set = function(_, dungeonID, value)
                    local form = ensure_debug_add_form()
                    form.lootDungeons = form.lootDungeons or {}
                    local id = tonumber(dungeonID)
                    form.lootDungeons[id] = value or nil
                    notify_options_changed()
                end,
                order = 1
            },
            itempreview = {
                type = "description",
                name = function()
                    local form = ensure_debug_add_form()
                    local lootDungeons = form.lootDungeons or {}
                    
                    local selectedCount = 0
                    for _ in pairs(lootDungeons) do
                        selectedCount = selectedCount + 1
                    end
                    
                    if selectedCount == 0 then
                        return "|cffaaaaaa(No dungeons selected)|r"
                    end
                    
                    local text = "|cff00ff00Featured items from selected dungeons:|r\n"
                    for dungeonID in pairs(lootDungeons) do
                        local dungeons = get_active_season_dungeons()
                        local dungeonName = dungeons[tostring(dungeonID)] or ("Dungeon " .. dungeonID)
                        
                        if addon and addon.GetFeaturedItems then
                            local items = addon:GetFeaturedItems(dungeonID) or {}
                            if #items > 0 then
                                text = text .. string.format("\n|cffffd700%s:|r", dungeonName)
                                for _, itemID in ipairs(items) do
                                    local itemName = GetItemInfo(itemID)
                                    if itemName then
                                        text = text .. string.format("\n  • %s", itemName)
                                    else
                                        text = text .. string.format("\n  • Item %d (loading...)", itemID)
                                    end
                                end
                            end
                        end
                    end
                    return text
                end,
                order = 2,
                fontSize = "small",
            },
            randomloot = {
                type = "execute",
                name = "Assign Random Loot (1-3 Dungeons)",
                desc = "Automatically assign 1-3 featured items as loot targets",
                func = function()
                    local form = ensure_debug_add_form()
                    form.lootDungeons = {}
                    
                    local dungeons = get_active_season_dungeons()
                    local dungeonIDs = {}
                    for idStr in pairs(dungeons) do
                        table.insert(dungeonIDs, tonumber(idStr))
                    end
                    
                    if #dungeonIDs == 0 then
                        if Debug then
                            Debug:User("No dungeons available for loot targeting")
                        end
                        return
                    end
                    
                    -- Shuffle dungeon IDs
                    for i = #dungeonIDs, 2, -1 do
                        local j = math.random(i)
                        dungeonIDs[i], dungeonIDs[j] = dungeonIDs[j], dungeonIDs[i]
                    end
                    
                    -- Select 1-3 random dungeons
                    local numDungeons = math.random(1, math.min(3, #dungeonIDs))
                    for i = 1, numDungeons do
                        form.lootDungeons[dungeonIDs[i]] = true
                    end
                    
                    if Debug then
                        Debug:User("devtools", string.format("Assigned %d random loot target dungeon(s)", numDungeons))
                    end
                    notify_options_changed()
                end,
                order = 3
            },
            clearloot = {
                type = "execute",
                name = "Clear All Loot Targets",
                desc = "Remove all selected loot target dungeons",
                func = function()
                    local form = ensure_debug_add_form()
                    form.lootDungeons = {}
                    if Debug then
                        Debug:User("devtools", "Cleared all loot targets")
                    end
                    notify_options_changed()
                end,
                order = 4
            }
        }
    }
    
    -- Preview
    dev_args.builder_preview = {
        type = "description",
        name = function()
            local form = ensure_debug_add_form()
            if not form.name or form.name == "" then
                return "|cFFFF0000Please enter a player name|r"
            end
            
            local class = form.class or "Unknown"
            local spec = "Random"
            if form.specID and NextKey222.FakePlayerService then
                local specs = NextKey222.FakePlayerService:GetClassSpecs(class)
                for _, s in ipairs(specs or {}) do
                    if s.specID == form.specID then
                        spec = s.specName
                        break
                    end
                end
            end
            
            local io = form.tier and ("Tier: " .. form.tier) or ("IO: " .. (form.io or 2500))
            local key = ""
            if form.keystoneDungeon then
                local dungeons = get_active_season_dungeons()
                local dungeonName = dungeons[tostring(form.keystoneDungeon)] or "Unknown"
                key = string.format("\nKeystone: %s +%d", dungeonName, form.keystoneLevel or 10)
            end
            
            return string.format(
                "|cFF00FF00Preview:|r\nName: %s\nClass: %s\nSpec: %s\n%s%s",
                form.name,
                class,
                spec,
                io,
                key
            )
        end,
        order = 34,
        fontSize = "medium",
    }
    
    -- Actions
    dev_args.builder_create = {
        type = "execute",
        name = "Create Player",
        desc = "Create the custom fake player with specified attributes",
        order = 35,
        func = function()
            local form = ensure_debug_add_form()
            
            -- Validation
            if not form.name or form.name == "" then
                if Debug then
                    Debug:Error("Please enter a player name")
                end
                return
            end
            
            -- Validate name against Blizzard's official WoW character naming rules
            local baseName = form.name:match("^([^%-]+)") or form.name
            
            -- Rule 1: Length (2-12 characters)
            if #baseName < 2 or #baseName > 12 then
                if Debug then
                    Debug:Error("Player name must be 2-12 characters")
                end
                return
            end
            
            -- Rule 2 & 3: Letters only (accented supported), no numbers/symbols
            if not baseName:match("^%a+$") then
                if Debug then
                    Debug:Error("Player name can only contain letters (no spaces, numbers, or symbols)")
                end
                return
            end
            
            -- Rule 4: No mixed capitals (e.g., "TaNk")
            local isAllLower = baseName == baseName:lower()
            local isAllUpper = baseName == baseName:upper()
            local isProperCase = baseName:sub(1, 1) == baseName:sub(1, 1):upper() and baseName:sub(2) == baseName:sub(2):lower()
            
            if not (isAllLower or isAllUpper or isProperCase) then
                if Debug then
                    Debug:Error("Name cannot have mixed capitals (use 'Tank', 'TANK', or 'tank', not 'TaNk')")
                end
                return
            end
            
            if not form.class then
                if Debug then
                    Debug:Error("Please select a class")
                end
                return
            end
            
            -- Build loot targets from selected dungeons (Phase 2.2)
            local lootTargets = nil
            local hasLootDungeons = form.lootDungeons and next(form.lootDungeons) ~= nil
            
            if hasLootDungeons and addon and addon.GetFeaturedItems then
                lootTargets = {}
                for dungeonID in pairs(form.lootDungeons) do
                    local featuredItems = addon:GetFeaturedItems(dungeonID) or {}
                    if #featuredItems > 0 then
                        -- Take 1-2 random items from featured
                        local itemCount = math.random(1, math.min(2, #featuredItems))
                        local selectedItems = {}
                        
                        -- Shuffle and select
                        local shuffled = {}
                        for i, itemID in ipairs(featuredItems) do
                            shuffled[i] = itemID
                        end
                        for i = #shuffled, 2, -1 do
                            local j = math.random(i)
                            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
                        end
                        
                        for i = 1, itemCount do
                            table.insert(selectedItems, shuffled[i])
                        end
                        
                        lootTargets[dungeonID] = {
                            itemIDs = selectedItems,
                            priority = "high"
                        }
                    end
                end
            end
            
            -- Build config
            local config = {
                name = form.name,
                class = form.class,
                specID = form.specID,
                tier = form.tier,
                io = (form.tier or form.tier == "") and nil or form.io,
                keystoneDungeon = form.keystoneDungeon,
                keystoneLevel = form.keystoneLevel,
                dungeonOverrides = form.dungeonOverrides,  -- Phase 2.1
                lootTargets = lootTargets  -- Phase 2.2
            }
            
            -- Create player
            if not NextKey222.FakePlayerService then
                if Debug then
                    Debug:Error("FakePlayerService not available")
                end
                return
            end
            
            local playerName = NextKey222.FakePlayerService:CreatePlayer(config)
            
            if playerName then
                if Debug then
                    Debug:User("devtools", string.format("Created custom player: %s", playerName))
                end
                
                -- Reset form (preserve best table structure)
                local dbg = ensure_debug()
                if dbg then
                    dbg.addForm = {
                        best = {},
                        dungeonOverrides = {},
                        lootDungeons = {}
                    }
                end
                
                notify_options_changed()
                refresh_ui()
            else
                if Debug then
                    Debug:Error("Failed to create player - name may already exist")
                end
            end
        end,
    }
    
    dev_args.builder_reset = {
        type = "execute",
        name = "Reset Form",
        desc = "Clear all fields and start over",
        order = 36,
        func = function()
            local dbg = ensure_debug()
            if dbg then
                dbg.addForm = {
                    best = {},
                    dungeonOverrides = {},
                    lootDungeons = {}
                }
            end
            notify_options_changed()
        end,
    }
    
    -- MARK: Section 4 - Keys
    dev_args.keystonescenarios = {
        type = "group",
        name = "Keystone Scenarios",
        inline = true,
        order = 30,
        args = {
            description = {
                type = "description",
                name = "Keystone configuration generators for testing different scenarios",
                order = 0,
                fontSize = "small",
            },
            
            diverse_keys = {
                type = "execute",
                name = "Diverse Keys",
                desc = "All different dungeons at same level - tests dungeon variety",
                order = 1,
                func = function()
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateDiverseKeys then
                        if Debug then Debug:User("devtools", "Diverse Keys generator not available.") end
                        return
                    end
                    local count = NextKey222.FakePlayerService:GenerateDiverseKeys(10, 4)
                    if Debug then Debug:User("devtools", ("Generated %d players with diverse keys"):format(count or 0)) end
                    refresh_ui()
                end,
            },
            
            level_spread = {
                type = "execute",
                name = "Level Spread",
                desc = "Wide key level range (+7 to +15) - tests level-based sorting",
                order = 2,
                func = function()
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateLevelRange then
                        if Debug then Debug:User("devtools", "Level Spread generator not available.") end
                        return
                    end
                    local count = NextKey222.FakePlayerService:GenerateLevelRange(7, 15, 4)
                    if Debug then Debug:User("devtools", ("Generated %d players with level spread"):format(count or 0)) end
                    refresh_ui()
                end,
            },
        },
    }
    
    -- MARK: Section 5 - Advanced
    dev_args.advancedops = {
        type = "group",
        name = "Advanced Operations",
        inline = false,
        order = 40,
        args = {
            description = {
                type = "description",
                name = "Save/load team configurations and bulk operations for advanced testing",
                order = 0,
                fontSize = "small",
            },
            
            -- Save/Load Teams
            saveload_header = {
                type = "header",
                name = "Save/Load Teams",
                order = 1,
            },
            
            team_name = {
                type = "input",
                name = "Team Name",
                desc = "Name for saving/loading team configurations",
                order = 2,
                width = "full",
                get = function()
                    local dbg = ensure_debug()
                    if not dbg then return "" end
                    dbg.teamName = dbg.teamName or ""
                    return dbg.teamName
                end,
                set = function(_, value)
                    local dbg = ensure_debug()
                    if not dbg then return end
                    dbg.teamName = value
                end,
            },
            
            team_description = {
                type = "input",
                name = "Description",
                desc = "Optional description for this team configuration",
                order = 3,
                width = "full",
                multiline = 3,
                get = function()
                    local dbg = ensure_debug()
                    if not dbg then return "" end
                    dbg.teamDescription = dbg.teamDescription or ""
                    return dbg.teamDescription
                end,
                set = function(_, value)
                    local dbg = ensure_debug()
                    if not dbg then return end
                    dbg.teamDescription = value
                end,
            },
            
            save_team = {
                type = "execute",
                name = "Save Current Team",
                desc = "Save current fake players as a named configuration",
                order = 4,
                func = function()
                    local dbg = ensure_debug()
                    if not dbg or not dbg.teamName or dbg.teamName == "" then
                        if Debug then Debug:Error("Please enter a team name") end
                        return
                    end
                    
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.SaveCurrentTeam then
                        if Debug then Debug:Error("Save team feature not available") end
                        return
                    end
                    
                    local success = NextKey222.FakePlayerService:SaveCurrentTeam(dbg.teamName, dbg.teamDescription)
                    if success then
                        if Debug then Debug:User("devtools", string.format("Saved team '%s'", dbg.teamName)) end
                        notify_options_changed()
                    end
                end,
            },
            
            load_team = {
        type = "select",
        name = "Load Team",
        desc = "Select a saved team to load",
        order = 96,
                values = function()
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GetSavedTeams then
                        return {}
                    end
                    
                    local teams = NextKey222.FakePlayerService:GetSavedTeams()
                    local values = {}
                    for name, data in pairs(teams) do
                        local desc = data.description and data.description ~= "" and data.description or "No description"
                        values[name] = string.format("%s (%d players)", name, #(data.players or {}))
                    end
                    return values
                end,
                get = function()
                    return nil
                end,
                set = function(_, value)
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.LoadTeam then
                        if Debug then Debug:Error("Load team feature not available") end
                        return
                    end
                    
                    local success = NextKey222.FakePlayerService:LoadTeam(value)
                    if success then
                        if Debug then Debug:User("devtools", string.format("Loaded team '%s'", value)) end
                        refresh_ui()
                    end
                end,
            },
            
            delete_team = {
                type = "execute",
                name = "Delete Selected Team",
                desc = "Delete the team specified in the Team Name field",
                confirm = true,
                order = 6,
                func = function()
                    local dbg = ensure_debug()
                    if not dbg or not dbg.teamName or dbg.teamName == "" then
                        if Debug then Debug:Error("Please enter a team name to delete") end
                        return
                    end
                    
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.DeleteTeam then
                        if Debug then Debug:Error("Delete team feature not available") end
                        return
                    end
                    
                    local success = NextKey222.FakePlayerService:DeleteTeam(dbg.teamName)
                    if success then
                        if Debug then Debug:User("devtools", string.format("Deleted team '%s'", dbg.teamName)) end
                        dbg.teamName = ""
                        dbg.teamDescription = ""
                        notify_options_changed()
                    else
                        if Debug then Debug:Error(string.format("Team '%s' not found", dbg.teamName)) end
                    end
                end,
            },
            
            -- Bulk Operations
            bulk_header = {
                type = "header",
                name = "Bulk Operations",
                order = 10,
            },
            
            bulk_add_loot = {
                type = "execute",
                name = "Add Random Loot to All Players",
                desc = "Assign random loot targets to all fake players (1-3 dungeons each)",
                order = 11,
                func = function()
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.BulkAddLoot then
                        if Debug then Debug:Error("Bulk loot feature not available") end
                        return
                    end
                    
                    NextKey222.FakePlayerService:BulkAddLoot()
                    refresh_ui()
                end,
            },
            
            bulk_randomize_keys = {
                type = "execute",
                name = "Randomize All Keystones",
                desc = "Assign random keystones to all fake players",
                order = 12,
                func = function()
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.BulkRandomizeKeys then
                        if Debug then Debug:Error("Bulk randomize feature not available") end
                        return
                    end
                    
                    NextKey222.FakePlayerService:BulkRandomizeKeys()
                    refresh_ui()
                end,
            },
            
            bulk_io_adjustment = {
                type = "range",
                name = "IO Adjustment",
                desc = "Amount to add/subtract from all player IO scores",
                order = 13,
                min = -1000,
                max = 1000,
                step = 50,
                get = function()
                    local dbg = ensure_debug()
                    if not dbg then return 0 end
                    dbg.bulkIOAdjustment = dbg.bulkIOAdjustment or 0
                    return dbg.bulkIOAdjustment
                end,
                set = function(_, value)
                    local dbg = ensure_debug()
                    if not dbg then return end
                    dbg.bulkIOAdjustment = value
                end,
            },
            
            bulk_apply_io = {
                type = "execute",
                name = "Apply IO Adjustment",
                desc = "Add/subtract IO from all fake players",
                order = 14,
                func = function()
                    local dbg = ensure_debug()
                    if not dbg or not dbg.bulkIOAdjustment then
                        if Debug then Debug:Error("No IO adjustment value set") end
                        return
                    end
                    
                    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.BulkAdjustIO then
                        if Debug then Debug:Error("Bulk IO adjustment feature not available") end
                        return
                    end
                    
                    NextKey222.FakePlayerService:BulkAdjustIO(dbg.bulkIOAdjustment)
                    refresh_ui()
                end,
            },
        },
    }
    
    -- MARK: Section 6 - Debug
    dev_args.debugvalidation = {
        type = "group",
        name = "Debug & Validation",
        inline = false,
        order = 50,
        args = {
            description = {
                type = "description",
                name = "Status display and debugging tools",
                order = 0,
                fontSize = "small",
            },
            
            status = {
                type = "description",
                name = function()
                    local players = get_players()
                    local total = #players
                    if total == 0 then
                        return "|cFF808080No fake players currently generated.|r"
                    end
                    
                    -- Count by role
                    local tanks, healers, dps = 0, 0, 0
                    for _, player in ipairs(players) do
                        if player.role == "TANK" then
                            tanks = tanks + 1
                        elseif player.role == "HEALER" then
                            healers = healers + 1
                        else
                            dps = dps + 1
                        end
                    end
                    
                    return string.format(
                        "|cFF00FF00Active Players: %d|r\n  • Tanks: %d\n  • Healers: %d\n  • DPS: %d",
                        total, tanks, healers, dps
                    )
                end,
                order = 1,
                fontSize = "medium",
            },
        },
    }

    return {
        type = "group",
        name = "Developer Tools",
        order = 90,
        args = dev_args,
    }
end

-- Expose create_developer_tools_group for DebugUI rebuild
if NextKey222.Addon then
    NextKey222.Addon.CreateDeveloperToolsGroup = create_developer_tools_group
end

-- MARK: SetupOptions

function NextKey222.SetupOptions()
    local Debug = NextKey222.Debug
    
    if Debug then
        Debug:Dev("startup", "SetupOptions called")
    end
    
    local AceConfig = LibStub("AceConfig-3.0", true)
    if not AceConfig then
        if Debug then
            Debug:Error("AceConfig-3.0 not available!")
        end
        return
    end
    
    if Debug then
        Debug:Dev("startup", "AceConfig-3.0 found, building options table")
    end

    local options = {
        name = "NextKey",
        type = "group",
        args = {
            -- 1. General
            general = {
                type = "group",
                name = "General",
                order = 10,
                args = {
                    autoSuggest = {
                        type = "toggle",
                        name = "Auto Suggest",
                        desc = "Automatically suggest the best key when the window opens.",
                        get = function()
                            return addon.db.global.leaderSettings.autoSuggestEnabled
                        end,
                        set = function(_, value)
                            addon.db.global.leaderSettings.autoSuggestEnabled = value and true or false
                            notify_options_changed()
                        end,
                    },
                    sortMode = {
                        type = "select",
                        name = "Default Sort Mode",
                        desc = "Choose how keystones are sorted by default.",
                        values = {
                            HighestKeyLevel = "Highest Key Level",
                            LowestKeyLevel = "Lowest Key Level",
                        },
                        get = function()
                            return addon.db.global.leaderSettings.defaultSortMode
                        end,
                        set = function(_, value)
                            addon.db.global.leaderSettings.defaultSortMode = value
                            notify_options_changed()
                        end,
                    },
                    group_header = {
                        type = "header",
                        name = "Group Composition Preferences",
                        order = 20,
                    },
                    prioritizeHeroism = {
                        type = "toggle",
                        name = "Prefer Heroism Support",
                        desc = "Prefer including Heroism/Bloodlust (Mage, Shaman, Evoker).",
                        width = "full",
                        order = 21,
                        get = function()
                            local prefs = addon.db.global.groupPreferences or {}
                            return prefs.prioritizeHeroism
                        end,
                        set = function(_, value)
                            addon.db.global.groupPreferences = addon.db.global.groupPreferences or {}
                            addon.db.global.groupPreferences.prioritizeHeroism = value and true or false
                            notify_options_changed()
                        end,
                    },
                    prioritizeBattleRes = {
                        type = "toggle",
                        name = "Prefer Battle Res Support",
                        desc = "Prefer including Battle Resurrection (Druid, Warlock, Death Knight).",
                        width = "full",
                        order = 22,
                        get = function()
                            local prefs = addon.db.global.groupPreferences or {}
                            return prefs.prioritizeBattleRes
                        end,
                        set = function(_, value)
                            addon.db.global.groupPreferences = addon.db.global.groupPreferences or {}
                            addon.db.global.groupPreferences.prioritizeBattleRes = value and true or false
                            notify_options_changed()
                        end,
                    },
                },
            },

            -- 2. Teleport Window
            teleportWindow = {
                type = "group",
                name = "Teleport Window",
                order = 20,
                args = {
                    description = {
                        type = "description",
                        name = "Configure teleport window behavior and appearance.",
                        fontSize = "medium",
                        order = 1,
                    },
                    compactMode = {
                        type = "toggle",
                        name = "Compact Mode",
                        desc = "Use a more compact layout for the teleport window.",
                        width = "full",
                        order = 10,
                        get = function()
                            return addon.db.global.teleport.compactMode
                        end,
                        set = function(_, value)
                            addon.db.global.teleport.compactMode = value and true or false
                            notify_options_changed()
                        end,
                    },
                    showHearthstone = {
                        type = "toggle",
                        name = "Show Hearthstone Options",
                        desc = "Display hearthstone selection in the teleport window.",
                        width = "full",
                        order = 20,
                        get = function()
                            return addon.db.global.teleport.showHearthstone
                        end,
                        set = function(_, value)
                            addon.db.global.teleport.showHearthstone = value and true or false
                            notify_options_changed()
                        end,
                    },
                    autoShowAfterCompletion = {
                        type = "toggle",
                        name = "Auto-Show After M+ Completion",
                        desc = "Automatically open the teleport window when a Mythic+ dungeon is completed.",
                        width = "full",
                        order = 30,
                        get = function()
                            return addon.db.global.teleport.autoShowAfterCompletion
                        end,
                        set = function(_, value)
                            addon.db.global.teleport.autoShowAfterCompletion = value and true or false
                            notify_options_changed()
                        end,
                    },
                    selectHearthstone = {
                        type = "execute",
                        name = "Select Hearthstone",
                        desc = "Open the hearthstone selector window to choose your preferred hearthstone.",
                        order = 40,
                        func = function()
                            if addon and addon.ShowHearthstoneSelector then
                                addon:ShowHearthstoneSelector()
                            elseif Debug then
                                Debug:Error("Hearthstone selector not available")
                            end
                        end,
                    },
                },
            },

            -- 3. PUG Helper
            pugHelper = {
                type = "group",
                name = "PUG Helper",
                order = 30,
                args = {
                    description = {
                        type = "description",
                        name = "Configure PUG Helper features for LFG/group finder runs.",
                        fontSize = "medium",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable PUG Helper",
                        desc = "Enable PUG detection and assistance features.",
                        width = "full",
                        order = 10,
                        get = function()
                            return addon.db.global.pugHelper.enabled
                        end,
                        set = function(_, value)
                            addon.db.global.pugHelper.enabled = value and true or false
                            notify_options_changed()
                        end,
                    },
                    showNotifications = {
                        type = "toggle",
                        name = "Show Invite Notifications",
                        desc = "Display enhanced notifications when receiving group invites.",
                        width = "full",
                        order = 20,
                        disabled = function()
                            return not addon.db.global.pugHelper.enabled
                        end,
                        get = function()
                            return addon.db.global.pugHelper.showNotifications
                        end,
                        set = function(_, value)
                            addon.db.global.pugHelper.showNotifications = value and true or false
                            notify_options_changed()
                        end,
                    },
                    autoAcceptInvites = {
                        type = "toggle",
                        name = "Auto-Accept Invites (Use With Caution)",
                        desc = "|cFFFF0000Warning:|r Automatically accepts the first group invite received. Use carefully!",
                        width = "full",
                        order = 30,
                        disabled = function()
                            return not addon.db.global.pugHelper.enabled
                        end,
                        get = function()
                            return addon.db.global.pugHelper.autoAcceptInvites
                        end,
                        set = function(_, value)
                            addon.db.global.pugHelper.autoAcceptInvites = value and true or false
                            notify_options_changed()
                        end,
                    },
                    travelAssistant = {
                        type = "toggle",
                        name = "Travel Assistant",
                        desc = "Show travel assistance UI for PUG groups.",
                        width = "full",
                        order = 40,
                        disabled = function()
                            return not addon.db.global.pugHelper.enabled
                        end,
                        get = function()
                            return addon.db.global.pugHelper.travelAssistant
                        end,
                        set = function(_, value)
                            addon.db.global.pugHelper.travelAssistant = value and true or false
                            notify_options_changed()
                        end,
                    },
                    getawayUI = {
                        type = "toggle",
                        name = "Post-Run Getaway UI",
                        desc = "Show leave group option after completing a PUG run.",
                        width = "full",
                        order = 50,
                        disabled = function()
                            return not addon.db.global.pugHelper.enabled
                        end,
                        get = function()
                            return addon.db.global.pugHelper.getawayUI
                        end,
                        set = function(_, value)
                            addon.db.global.pugHelper.getawayUI = value and true or false
                            notify_options_changed()
                        end,
                    },
                },
            },

            -- 4. Organizer & Roles
            organizerRoles = {
                type = "group",
                name = "Organizer & Roles",
                order = 40,
                args = {
                    description = {
                        type = "description",
                        name = "Character role preferences are automatically detected based on your current specialization. Use '/nk organizer' to access the M+ Group Organizer for multi-group management.",
                        fontSize = "medium",
                        order = 1,
                    },
                    info = {
                        type = "description",
                        name = "\nRole information is stored per-character and shared via the organizer communication system when participating in organized groups.\n\nYour current role is determined by:\n• Tank/Healer/DPS spec\n• Class capabilities\n• Group composition needs",
                        fontSize = "small",
                        order = 2,
                    },
                },
            },

            -- 5. M+ Data
            mythicPlusData = addon.GetMythicPlusDataOptions and addon:GetMythicPlusDataOptions() or {
                type = "group",
                name = "M+ Data",
                order = 50,
                args = {
                    placeholder = {
                        type = "description",
                        name = "M+ Data options not available",
                    },
                },
            },

            -- 6. Debug System
            debugSystem = NextKey222.DebugUI and NextKey222.DebugUI.CreateDebugOptions and NextKey222.DebugUI:CreateDebugOptions() or {
                type = "group",
                name = "Debug System",
                order = 80,
                args = {
                    description = {
                        type = "description",
                        name = "Debug UI not available. Please ensure core/debugUI.lua is loaded.",
                        fontSize = "medium",
                    },
                },
            },

            -- 7. Fake Player Tools (top-level scrollable section)
            fakePlayerTools = (function()
                local devTools = create_developer_tools_group()
                
                return {
                    type = "group",
                    name = "Fake Player Tools",
                    order = 90,
                    hidden = function()
                        local DebugService = NextKey222.Debug
                        local dbg = ensure_debug()
                        -- Show if either full debug OR basic tools are enabled
                        return not ((DebugService and DebugService.enabled) or (dbg and dbg.basicToolsEnabled))
                    end,
                    args = devTools.args or {},
                }
            end)(),
        },
    }

    if Debug then
        Debug:Dev("startup", "Registering options table with AceConfig")
    end
    
    local success, err = pcall(function()
        AceConfig:RegisterOptionsTable("NextKey", options)
    end)
    
    if success then
        if Debug then
            Debug:Dev("startup", "Options table registered successfully")
        end
        
        -- Note: Live updates for debug statistics have been disabled to prevent
        -- interrupting user input in text fields. Statistics will update when
        -- the user interacts with debug controls (toggles, buttons, etc.)
    else
        if Debug then
            Debug:Error("Failed to register options table:", err)
        end
    end
end
