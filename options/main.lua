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

-- MARK: Developer Tools Helpers (Fake Players etc.)

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

    -- Fake player presets / addon matrix
    dev_args.team_header = {
        type = "header",
        name = "Fake Player Generation",
        order = 5,
    }

    dev_args.preset_addons = {
        type = "description",
        name = "Configure and generate fake players for testing suggestions and UI flows.",
        order = 6,
        fontSize = "small",
    }

    dev_args.addon_nextkey = {
        type = "toggle",
        name = "Preset: Players Have NextKey",
        desc = "Fake players are considered to have NextKey installed.",
        order = 7,
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
        width = "full",
    }

    dev_args.addon_raiderio = {
        type = "toggle",
        name = "Preset: Players Have RaiderIO",
        desc = "Fake players are considered to have RaiderIO data.",
        order = 8,
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
        width = "full",
    }

    -- Preset teams (using existing FakePlayerService helpers)
    local function make_preset_button(key, name, desc, order)
        return {
            type = "execute",
            name = name,
            desc = desc,
            order = order,
            func = function()
                if not ensure_debug() or not NextKey222.Addon or not NextKey222.Addon.GeneratePresetTeam then
                    if Debug then
                        Debug:User("devtools", "Preset generator not available.")
                    end
                    return
                end
                NextKey222.Addon:ClearFakePlayers()
                local count = NextKey222.Addon:GeneratePresetTeam(key)
                if Debug then
                    Debug:User("devtools", ("Generated %d fake players (%s)"):format(count or 0, key))
                end
                refresh_ui()
            end,
        }
    end

    dev_args.gen_mixed = make_preset_button(
        "mixed_skill",
        "Mixed Skill Team",
        "4 players with varied IO for realistic testing.",
        10
    )

    dev_args.gen_beginner = make_preset_button(
        "beginner",
        "Beginner Team",
        "Lower IO players for fallback/path testing.",
        11
    )

    dev_args.gen_expert = make_preset_button(
        "expert",
        "Expert Team",
        "High IO players for pushing scenarios.",
        12
    )
    
    -- NEW: 19-player role-aware team (replaces Organizer team for simplicity)
    dev_args.gen_organizer = {
        type = "execute",
        name = "19-Player Team (Fills Your Role)",
        desc = "Detects your current role and generates 19 players for a 20-player raid (4T/4H/12D). Varied skill tiers, 80% have keystones.",
        order = 13,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.Generate19PlayerTeam then
                if Debug then
                    Debug:User("devtools", "19-player team generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:Generate19PlayerTeam()
            if Debug then
                Debug:User("devtools", ("Generated %d players for raid team"):format(count or 0))
            end
            refresh_ui()
        end,
    }

    -- NEW: Keystone Scenarios header
    dev_args.keystone_header = {
        type = "header",
        name = "Keystone Scenarios",
        order = 15,
    }
    
    dev_args.keystone_desc = {
        type = "description",
        name = "Test keystone selection logic with specific key configurations.",
        order = 16,
        fontSize = "small",
    }
    
    -- NEW: Diverse Keys (with level selector)
    dev_args.diverse_keys_level = {
        type = "select",
        name = "Diverse Keys Level",
        desc = "Select keystone level for diverse key generation.",
        order = 17,
        values = {
            [7] = "+7 (KSM)",
            [10] = "+10 (Hero Track)",
            [12] = "+12 (KSH)",
            [15] = "+15 (Myth Track)",
            [18] = "+18 (Expert)",
            [20] = "+20 (Title Push)",
        },
        get = function()
            local dbg = ensure_debug()
            return (dbg and dbg.diverseKeysLevel) or 10
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.diverseKeysLevel = v
        end,
    }
    
    dev_args.gen_diverse_keys = {
        type = "execute",
        name = "Generate: Diverse Keys",
        desc = "4 players, each with different dungeon at selected level.",
        order = 18,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateDiverseKeys then
                if Debug then
                    Debug:User("devtools", "Diverse keys generator not available.")
                end
                return
            end
            local dbg = ensure_debug()
            local level = (dbg and dbg.diverseKeysLevel) or 10
            local count = NextKey222.FakePlayerService:GenerateDiverseKeys(level, 4)
            if Debug then
                Debug:User("devtools", ("Generated %d players with diverse +%d keys"):format(count or 0, level))
            end
            refresh_ui()
        end,
    }
    
    -- NEW: Level Range buttons
    dev_args.gen_ksm_range = {
        type = "execute",
        name = "KSM Range (7-10)",
        desc = "4 players with keys in KSM range (7-10).",
        order = 19,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateLevelRange then
                if Debug then
                    Debug:User("devtools", "Level range generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:GenerateLevelRange(7, 10, 4)
            if Debug then
                Debug:User("devtools", ("Generated %d players with KSM range keys"):format(count or 0))
            end
            refresh_ui()
        end,
    }
    
    dev_args.gen_ksh_range = {
        type = "execute",
        name = "KSH Range (11-12)",
        desc = "4 players with keys in KSH range (11-12).",
        order = 20,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateLevelRange then
                if Debug then
                    Debug:User("devtools", "Level range generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:GenerateLevelRange(11, 12, 4)
            if Debug then
                Debug:User("devtools", ("Generated %d players with KSH range keys"):format(count or 0))
            end
            refresh_ui()
        end,
    }
    
    dev_args.gen_expert_range = {
        type = "execute",
        name = "Expert Range (15-18)",
        desc = "4 players with keys in expert range (15-18).",
        order = 21,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.GenerateLevelRange then
                if Debug then
                    Debug:User("devtools", "Level range generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:GenerateLevelRange(15, 18, 4)
            if Debug then
                Debug:User("devtools", ("Generated %d players with expert range keys"):format(count or 0))
            end
            refresh_ui()
        end,
    }
    
    -- NEW: Role Composition header
    dev_args.add_single_header = {
        type = "header",
        name = "Single Fake Player",
        order = 22,
    }

    dev_args.add_single_tier = {
        type = "select",
        name = "Single Player Skill Tier",
        desc = "Select the skill tier for the next fake player, or Random.",
        order = 23,
        values = {
            random = "Random Tier",
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
            local dbg = ensure_debug()
            dbg.singlePlayerTier = dbg.singlePlayerTier or "random"
            return dbg.singlePlayerTier
        end,
        set = function(_, value)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.singlePlayerTier = value or "random"
        end,
    }

    dev_args.add_single_player = {
        type = "execute",
        name = "Add Single Fake Player",
        desc = "Add one fake player using the selected skill tier. Does not clear existing fake players.",
        order = 24,
        func = function()
            local dbg = ensure_debug()
            if not dbg then return end

            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.CreatePlayer then
                if Debug then
                    Debug:User("devtools", "FakePlayerService not available.")
                end
                return
            end

            local tier = dbg.singlePlayerTier or "random"
            if tier == "random" then
                -- Use FakePlayerService default tier distribution
                local name = NextKey222.FakePlayerService:CreatePlayer({})
                if name and Debug then
                    Debug:User("devtools", ("Added fake player %s with random tier"):format(name))
                end
            else
                local name = NextKey222.FakePlayerService:CreatePlayer({ tier = tier })
                if name and Debug then
                    Debug:User("devtools", ("Added fake player %s (tier: %s)"):format(name, tier))
                end
            end

            refresh_ui()
        end,
    }

    dev_args.role_header = {
        type = "header",
        name = "Role Composition",
        order = 30,
    }
    
    dev_args.role_desc = {
        type = "description",
        name = "Generate specific role layouts for testing group formation.",
        order = 23,
        fontSize = "small",
    }
    
    -- NEW: Role-aware 4-player team button
    dev_args.gen_standard_comp = {
        type = "execute",
        name = "4-Player Team (Fills Your Role)",
        desc = "Detects your current role and generates 4 players to complete a 5-man team (1T/1H/3D). Uses 'competent' tier for balanced testing.",
        order = 24,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.Generate4PlayerTeam then
                if Debug then
                    Debug:User("devtools", "4-player team generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:Generate4PlayerTeam()
            if Debug then
                Debug:User("devtools", ("Generated %d players to complete your team"):format(count or 0))
            end
            refresh_ui()
        end,
    }
    
    -- NEW: Role-aware 19-player team button
    dev_args.gen_19_player_team = {
        type = "execute",
        name = "19-Player Team (Fills Your Role)",
        desc = "Detects your current role and generates 19 players for a 20-player raid (4T/4H/12D). Varied skill tiers, 80% have keystones.",
        order = 24.5,
        func = function()
            if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.Generate19PlayerTeam then
                if Debug then
                    Debug:User("devtools", "19-player team generator not available.")
                end
                return
            end
            local count = NextKey222.FakePlayerService:Generate19PlayerTeam()
            if Debug then
                Debug:User("devtools", ("Generated %d players for raid team"):format(count or 0))
            end
            refresh_ui()
        end,
    }

    -- MARK: Custom Player Builder
    dev_args.custom_builder_header = {
        type = "header",
        name = "Custom Player Builder",
        order = 25,
    }
    
    dev_args.custom_builder_desc = {
        type = "description",
        name = "Create fully customized fake players with precise control over all attributes.",
        order = 26,
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
            
            -- Build config
            local config = {
                name = form.name,
                class = form.class,
                specID = form.specID,
                tier = form.tier,
                io = (form.tier or form.tier == "") and nil or form.io,
                keystoneDungeon = form.keystoneDungeon,
                keystoneLevel = form.keystoneLevel,
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
                
                -- Reset form
                ensure_debug().addForm = { best = {} }
                
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
            ensure_debug().addForm = { best = {} }
            notify_options_changed()
        end,
    }

    -- Custom team
    dev_args.custom_header = {
        type = "header",
        name = "Custom Team",
        order = 40,
    }

    dev_args.custom_count = {
        type = "range",
        name = "Team Size",
        desc = "Generate N random fake players.",
        min = 1,
        max = 12,
        step = 1,
        order = 41,
        get = function()
            local dbg = ensure_debug()
            return (dbg and dbg.customTeamSize) or 4
        end,
        set = function(_, v)
            local dbg = ensure_debug()
            if not dbg then return end
            dbg.customTeamSize = v
        end,
    }

    dev_args.gen_custom = {
        type = "execute",
        name = "Generate Custom Team",
        desc = "Generate random fake players using current preset settings.",
        order = 42,
        func = function()
            local dbg = ensure_debug()
            if not dbg or not NextKey222.Addon or not NextKey222.Addon.AddRandomFakePlayers then
                if Debug then
                    Debug:User("devtools", "Custom generator not available.")
                end
                return
            end
            local size = dbg.customTeamSize or 4
            NextKey222.Addon:ClearFakePlayers()
            local count = NextKey222.Addon:AddRandomFakePlayers(size)
            if Debug then
                Debug:User("devtools", ("Generated %d custom fake players"):format(count or 0))
            end
            refresh_ui()
        end,
    }

    -- Status + clear
    dev_args.status = {
        type = "description",
        name = function()
            local players = get_players()
            local total = #players
            if total == 0 then
                return "No fake players currently generated."
            end
            return ("Active fake players: %d"):format(total)
        end,
        order = 50,
        fontSize = "medium",
    }

    dev_args.clear_fake = {
        type = "execute",
        name = "Clear All Fake Players",
        confirm = true,
        order = 51,
        func = function()
            if NextKey222.Addon and NextKey222.Addon.ClearFakePlayers then
                NextKey222.Addon:ClearFakePlayers()
                refresh_ui()
            end
        end,
    }

    -- Existing targeted test hooks (e.g., PUG Helper test) are kept but scoped here.
    dev_args.test_pug_helper = {
        type = "execute",
        name = "Test PUG Application Tracking",
        desc = "Run PUG Helper application tracking test (if available).",
        order = 60,
        func = function()
            if NextKey222.PUGHelper and NextKey222.PUGHelper.TestApplicationTracking then
                NextKey222.PUGHelper:TestApplicationTracking()
                if Debug then
                    Debug:User("devtools", "PUG Helper: TestApplicationTracking invoked.")
                end
            elseif Debug then
                Debug:User("devtools", "PUG Helper test API not available.")
            end
        end,
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

-- MARK: SetupOptions (Single Canonical Entry)

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

            -- 6. Debug System (with Fake Player Tools as final tab)
            debugSystem = (function()
                local debugOptions = NextKey222.DebugUI and NextKey222.DebugUI.CreateDebugOptions and NextKey222.DebugUI:CreateDebugOptions() or {
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
                }
                
                
                -- Add Fake Player Tools as a final tab
                if debugOptions.args then
                    debugOptions.args.fakePlayerTools = {
                        type = "group",
                        name = "Fake Player Tools",
                        desc = "Developer tools for generating and managing fake players for testing",
                        order = 300,
                        hidden = function()
                            local DebugService = NextKey222.Debug
                            local dbg = ensure_debug()
                            -- Show if either full debug OR basic tools are enabled
                            return not ((DebugService and DebugService.enabled) or (dbg and dbg.basicToolsEnabled))
                        end,
                        args = (function()
                            local devTools = create_developer_tools_group()
                            local generationArgs = {}
                            
                            if devTools and devTools.args then
                                -- Widgets to show in Basic Tools mode (filtered subset)
                                local basicToolsWhitelist = {
                                    gen_standard_comp = true,
                                    gen_organizer = true,
                                    custom_builder_header = true,
                                    custom_builder_desc = true,
                                    builder_name = true,
                                    builder_name_counter = true,
                                    builder_class = true,
                                    builder_spec = true,
                                    builder_tier = true,
                                    builder_io = true,
                                    builder_keystone_dungeon = true,
                                    builder_keystone_level = true,
                                    builder_preview = true,
                                    builder_create = true,
                                    builder_reset = true,
                                    status = true,
                                    clear_fake = true,
                                }
                                
                                -- Copy developer tool items with filtering
                                for k, v in pairs(devTools.args) do
                                    if k ~= "header" and k ~= "enable_debug_mode" and k ~= "enable_basic_tools" and k ~= "basic_tools_disabled_info" then
                                        -- Clone the widget config
                                        local widgetCopy = {}
                                        for key, val in pairs(v) do
                                            widgetCopy[key] = val
                                        end
                                        
                                        -- Add hidden function to filter in Basic mode
                                        local originalHidden = widgetCopy.hidden
                                        widgetCopy.hidden = function(...)
                                            -- Check if original widget was hidden
                                            if originalHidden and originalHidden(...) then
                                                return true
                                            end
                                            
                                            -- Filter based on mode
                                            local dbg = ensure_debug()
                                            local isDebugMode = dbg and dbg.enabled
                                            local isBasicMode = dbg and dbg.basicToolsEnabled and not isDebugMode
                                            
                                            -- In Basic mode, hide widgets not in whitelist
                                            if isBasicMode and not basicToolsWhitelist[k] then
                                                return true
                                            end
                                            
                                            return false
                                        end
                                        
                                        generationArgs[k] = widgetCopy
                                    end
                                end
                            end
                            
                            return generationArgs
                        end)()
                    }
                end
                
                return debugOptions
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
