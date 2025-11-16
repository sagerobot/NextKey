-- This is a draft of the complete new structure following the FAKE_PLAYER_SYSTEM_OVERHAUL plan
-- Will be integrated into options/main.lua after review

local function create_developer_tools_group()
    local dungeons = get_active_season_dungeons()

    local function get_players()
        return NextKey222.FakePlayerService and NextKey222.FakePlayerService:GetAllPlayers() or {}
    end

    local dev_args = {}

    -- Header and mode toggles (unchanged)
    dev_args.header = {
        type = "description",
        name = "Developer and testing utilities. Not required for normal gameplay use.",
        order = 0,
        fontSize = "medium",
    }

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
            
            if v then
                dbg.basicToolsEnabled = false
            end

            if NextKey222.UI and NextKey222.UI.OnDebugModeChanged then
                NextKey222.UI:OnDebugModeChanged()
            end

            if NextKey222.Debug and NextKey222.Debug.SetEnabled then
                NextKey222.Debug:SetEnabled(dbg.enabled)
            end
            
            notify_options_changed()
        end,
    }
    
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
    
    -- MARK: Section 1 - Quick Teams
    dev_args.quickteams = {
        type = "group",
        name = "Quick Teams",
        inline = true,
        order = 5,
        args = {
            description = {
                type = "description",
                name = "Preset team compositions for quick testing",
                order = 0,
                fontSize = "small",
            },
            
            -- Addon config toggles
            addon_nextkey = {
                type = "toggle",
                name = "Preset: Players Have NextKey",
                desc = "Fake players are considered to have NextKey installed.",
                order = 1,
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
            },
            
            addon_raiderio = {
                type = "toggle",
                name = "Preset: Players Have RaiderIO",
                desc = "Fake players are considered to have RaiderIO data.",
                order = 2,
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
            },
            
            spacer1 = {
                type = "header",
                name = "",
                order = 3,
            },
            
            -- Quick team buttons
            gen_mixed = {
                type = "execute",
                name = "Mixed Skill (4 players)",
                desc = "4 players with varied IO for realistic testing.",
                order = 4,
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
            },
            
            gen_beginner = {
                type = "execute",
                name = "Beginner Team",
                desc = "Lower IO players for fallback/path testing.",
                order = 5,
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
            },
            
            gen_expert = {
                type = "execute",
                name = "Expert Team",
                desc = "High IO players for pushing scenarios.",
                order = 6,
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
            },
            
            gen_high_keys = {
                type = "execute",
                name = "High Keys Team",
                desc = "Team with high-level keystones for challenge testing.",
                order = 7,
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
            },
            
            spacer2 = {
                type = "header",
                name = "",
                order = 8,
            },
            
            clear_fake = {
                type = "execute",
                name = "Clear All Fake Players",
                desc = "Remove all fake players from the system.",
                confirm = true,
                order = 9,
                func = function()
                    if NextKey222.Addon and NextKey222.Addon.ClearFakePlayers then
                        NextKey222.Addon:ClearFakePlayers()
                        refresh_ui()
                    end
                end,
            },
        },
    }
    
    -- TODO: Add remaining sections following plan structure
    -- Section 2: Algorithm Test Scenarios
    -- Section 3: Custom Player Builder  
    -- Section 4: Keystone Scenarios
    -- Section 5: Advanced Operations
    -- Section 6: Debug & Validation
    
    -- For now, keep status display
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

    return {
        type = "group",
        name = "Developer Tools",
        order = 90,
        args = dev_args,
    }
end