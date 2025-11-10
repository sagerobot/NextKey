local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

local UIControls = {}

NextKey222.UIControls = UIControls
NextKey222.RegisterModule("UIControls", UIControls)

-- MARK: Private Helpers

local function log_dev(...)
    if Debug and Debug.Dev then
        Debug:Dev("ui", ...)
    end
end

local function log_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

local function _create_sort_dropdown(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateDropdown then
        log_error("UIControls: UIComponents.CreateDropdown not available")
        return
    end

    local dropdown = NextKey222.UIComponents:CreateDropdown("primary", nil, {
        label = "Sort Mode",
        width = 200,
        onValueChanged = function(_, _, key)
            if not ui or not ui.SetCurrentSortMode then
                return
            end

            ui:SetCurrentSortMode(key)

            if ui.ioDisplayModeBtn and ui.ioDisplayModeBtn.frame then
                if key == "IOGainPotential" then
                    ui.ioDisplayModeBtn.frame:Show()
                else
                    ui.ioDisplayModeBtn.frame:Hide()
                end
            end

            if ui.viewMode == "dungeons" and ui.RenderDungeonCards then
                ui:RenderDungeonCards()
            elseif ui.RenderResults then
                ui:RenderResults()
            end
        end,
    })

    ui.sortDropdown = dropdown
    ui.headerWidgets.sortDropdown = dropdown

    if ui.viewMode == "dungeons" and ui.UpdateSortDropdownOptions then
        ui:UpdateSortDropdownOptions()
    elseif ui.UpdateSortDropdownOptions then
        ui.viewMode = ui.viewMode or "keystones"
        ui:UpdateSortDropdownOptions()
    end

    if ui.GetCurrentSortMode then
        dropdown:SetValue(ui:GetCurrentSortMode())
    end

    parent:AddChild(dropdown)
end

local function _create_refresh_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available")
        return
    end

    local btn = NextKey222.UIComponents:CreateButton("secondary_action", nil, {
        text = "Refresh Data",
        size = { 120, 25 },
        onClick = function()
            if NextKey222.Communications then
                if NextKey222.Communications.EnsureCurrentPlayerIOData then
                    NextKey222.Communications:EnsureCurrentPlayerIOData()
                end
                if NextKey222.Communications.SendSync then
                    NextKey222.Communications:SendSync()
                end
                if NextKey222.Communications.RequestPartyIOData then
                    NextKey222.Communications:RequestPartyIOData()
                end
            end

            if not ui then
                return
            end

            if ui.viewMode == "dungeons" and ui.RenderDungeonCards then
                ui:RenderDungeonCards()
            elseif ui.RefreshResults then
                ui:RefreshResults()
            elseif ui.RenderResults then
                ui:RenderResults()
            end
        end,
    })

    parent:AddChild(btn)
    ui.headerWidgets.refreshDataBtn = btn
end

local function _create_guild_toggle(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for guild toggle")
        return
    end

    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = ui.showGuildKeys and "Guild Keys" or "Party Keys",
        onClick = function()
            if not ui then
                return
            end

            if not ui.showGuildKeys and IsInGuild and IsInGuild() then
                Debug:User("Requesting guild keystones... (requires LibOpenRaid-compatible addons)")

                if LibStub then
                    local lib = LibStub:GetLibrary("LibOpenRaid-1.0", true)
                    if lib and lib.RequestKeystoneDataFromGuild then
                        lib.RequestKeystoneDataFromGuild()
                    end
                end
            elseif not ui.showGuildKeys and (not IsInGuild or not IsInGuild()) then
                Debug:User("Not in a guild - cannot show guild keystones")
            end

            if ui.ToggleGuildFilter then
                ui:ToggleGuildFilter()
            end
        end,
    })

    parent:AddChild(btn)
    ui.guildToggleBtn = btn
    ui.headerWidgets.guildToggleBtn = btn
end

local function _create_teleport_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for teleport")
        return
    end

    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Open Teleport",
        onClick = function()
            if NextKey222.Addon and NextKey222.Addon.ToggleTeleportWindow then
                NextKey222.Addon:ToggleTeleportWindow()
            else
                Debug:Error("Teleport window function not available")
            end
        end,
    })

    parent:AddChild(btn)
    ui.headerWidgets.teleportWindowBtn = btn
end

local function _create_organizer_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for organizer")
        return
    end

    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Open Organizer",
        size = { 160, 25 },
        onClick = function()
            if NextKey222.RosterBoard and NextKey222.RosterBoard.Show then
                NextKey222.RosterBoard:Show()
            else
                Debug:Error("RosterBoard module not available")
            end
        end,
    })

    if parent.AddChild then
        parent:AddChild(btn)
    end

    ui.headerWidgets.organizerBtn = btn
end

local function _create_total_score_label(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateText then
        log_error("UIControls: UIComponents.CreateText not available")
        return
    end

    local label = NextKey222.UIComponents:CreateText("large", nil, {
        text = "",
        width = 120,
        fontObject = GameFontNormalLarge,
        color = { 1, 0.8, 0 },
    })

    parent:AddChild(label)
    ui.totalScoreLabel = label
    ui.headerWidgets.totalScoreLabel = label
end

local function _create_debug_controls(ui, parent)
    if not NextKey222.FakePlayerService then
        log_dev("UIControls: FakePlayerService not available - debug controls disabled")
        return
    end

    if not NextKey222.UIComponents then
        log_error("UIControls: UIComponents not available for debug controls")
        return
    end

    local container = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    ui.debugControlsContainer = container

    local tier_dropdown = NextKey222.UIComponents:CreateDropdown("compact", nil, {
        label = "Fake Player Tier",
        width = 200,
        list = {
            random = "Random (All Skill Levels)",
            title = "Title (3600-3800 IO, 20s+)",
            elite = "Elite (3300-3600 IO, 18-19s)",
            expert = "Expert (3100-3400 IO, 15-17s)",
            skilled = "Skilled (2900-3100 IO, 13-14s)",
            competent = "Competent (2500-2900 IO, 11-12s)",
            average = "Average (2000-2600 IO, 7-10s)",
            casual = "Casual (1500-2000 IO, 4-6s)",
            beginner = "Beginner (1000-1500 IO, 2-3s)",
        },
        value = ui.debugFakeTierSelection or "random",
        onValueChanged = function(_, _, value)
            ui.debugFakeTierSelection = value or "random"
        end,
    })
    container:AddChild(tier_dropdown)
    ui.debugFakeTierDropdown = tier_dropdown
    ui.headerWidgets.debugFakeTierDropdown = tier_dropdown

    local add_btn = NextKey222.UIComponents:CreateButton("compact_list", nil, {
        text = "Add Fake Player",
        onClick = function()
            if ui.HandleAddDebugFakePlayer then
                ui:HandleAddDebugFakePlayer()
            end
        end,
    })
    container:AddChild(add_btn)
    ui.debugAddFakeBtn = add_btn
    ui.headerWidgets.debugAddFakeBtn = add_btn

    local clear_btn = NextKey222.UIComponents:CreateButton("compact_list", nil, {
        text = "Delete All Fakes",
        onClick = function()
            if ui.HandleDeleteAllFakePlayers then
                ui:HandleDeleteAllFakePlayers()
            end
        end,
    })
    container:AddChild(clear_btn)
    ui.debugClearFakeBtn = clear_btn
    ui.headerWidgets.debugClearFakeBtn = clear_btn

    local show_debug = ui.ShouldShowDebugControls and ui:ShouldShowDebugControls()
    if show_debug and parent.AddChild then
        parent:AddChild(container)
        log_dev("UIControls: debug controls added to layout (debug ON)")
    else
        log_dev("UIControls: debug controls created but not added (debug OFF)")
    end
end

local function _create_results_scroll(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateScrollFrame then
        log_error("UIControls: UIComponents.CreateScrollFrame not available")
        return
    end

    local scroll = NextKey222.UIComponents:CreateScrollFrame("primary", nil, {
        fullWidth = true,
        fullHeight = false,
        layout = "List",
    })

    if NextKey222.UIConfig and NextKey222.UIConfig.WINDOW then
        local height = NextKey222.UIConfig.WINDOW.SCROLL_FRAME_HEIGHT_KEYSTONE
        scroll:SetHeight(height)
    end

    parent:AddChild(scroll)
    ui.resultsFrame = scroll
end

local function _create_view_toggle_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for view toggle")
        return
    end

    local text = "Switch to Dungeons View"
    if ui.viewMode == "dungeons" then
        text = "Switch to Keystone View"
    end

    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = text,
        fullWidth = true,
        size = {
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.WIDTH or 580),
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.BOTTOM_BUTTON_HEIGHT or 24),
        },
        onClick = function()
            if ui.ToggleViewMode then
                ui:ToggleViewMode()
            end
        end,
    })

    parent:AddChild(btn)
    ui.viewToggleBtn = btn
    ui.headerWidgets.viewToggleBtn = btn
end

-- MARK: Public Interface

--- Attach header controls and primary layout to the given UI facade.
-- This function is intended to be called from ui/main.lua's frame creation path.
-- @param ui table NextKey222.UI facade
-- @param frame table AceGUI frame
function UIControls:AttachHeaderControls(ui, frame)
    if not ui or not frame then
        log_error("UIControls:AttachHeaderControls requires ui and frame")
        return
    end

    ui.headerWidgets = ui.headerWidgets or {}

    local header = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Choose a sort mode; results area below.",
        width = 580,
    })
    frame:AddChild(header)

    local controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    frame:AddChild(controls)
    ui.controlsContainer = controls

    _create_sort_dropdown(ui, controls)
    _create_refresh_button(ui, controls)
    _create_guild_toggle(ui, controls)
    _create_teleport_button(ui, controls)
    _create_organizer_button(ui, controls)
    _create_debug_controls(ui, controls)
    _create_total_score_label(ui, controls)
    _create_results_scroll(ui, frame)
    _create_view_toggle_button(ui, frame)

    log_dev("UIControls: header controls attached")
end

function UIControls:Initialize()
    log_dev("UIControls module initialized")
    return true
end

return UIControls