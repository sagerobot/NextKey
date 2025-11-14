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
        width = NextKey222.UIConfig and NextKey222.UIConfig.CONTROLS and NextKey222.UIConfig.CONTROLS.SORT_DROPDOWN_WIDTH or 200,
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

            -- Refresh the appropriate window based on which one is visible
            if ui.keystoneWindow and ui.keystoneWindow.frame and ui.keystoneWindow.frame:IsShown() then
                if ui.RenderResults then
                    local previous_results = ui.resultsFrame
                    ui.resultsFrame = ui.keystoneWindow.resultsFrame
                    ui:RenderResults()
                    ui.resultsFrame = previous_results
                end
            end
            
            if ui.dungeonWindow and ui.dungeonWindow.frame and ui.dungeonWindow.frame:IsShown() then
                if ui.RenderDungeonCards then
                    local previous_results = ui.resultsFrame
                    ui.resultsFrame = ui.dungeonWindow.resultsFrame
                    ui:RenderDungeonCards()
                    ui.resultsFrame = previous_results
                end
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

local function _create_refresh_icon_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateIcon then
        log_error("UIControls: UIComponents.CreateIcon not available")
        return
    end

    -- FUNDAMENTAL FIX: Use AceGUI Icon widget instead of Button + manual texture
    -- This prevents texture leakage because AceGUI properly manages Icon lifecycle
    local icon = NextKey222.UIComponents:CreateIcon("small", nil, {
        imagePath = "Interface\\Icons\\Ability_Repair",
        size = { 28, 28 },
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

            -- Refresh both windows if they're open
            if ui.keystoneWindow and ui.keystoneWindow.frame and ui.keystoneWindow.frame:IsShown() then
                if ui.RefreshResults then
                    local previous_results = ui.resultsFrame
                    ui.resultsFrame = ui.keystoneWindow.resultsFrame
                    ui:RefreshResults()
                    ui.resultsFrame = previous_results
                elseif ui.RenderResults then
                    local previous_results = ui.resultsFrame
                    ui.resultsFrame = ui.keystoneWindow.resultsFrame
                    ui:RenderResults()
                    ui.resultsFrame = previous_results
                end
            end
            
            if ui.dungeonWindow and ui.dungeonWindow.frame and ui.dungeonWindow.frame:IsShown() then
                if ui.RenderDungeonCards then
                    local previous_results = ui.resultsFrame
                    ui.resultsFrame = ui.dungeonWindow.resultsFrame
                    ui:RenderDungeonCards()
                    ui.resultsFrame = previous_results
                end
            end
        end,
        onEnter = function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText("Refresh Data", 1, 1, 1)
            GameTooltip:AddLine("Update keystone and IO data from party/guild", nil, nil, nil, true)
            GameTooltip:Show()
        end,
        onLeave = function()
            GameTooltip:Hide()
        end,
    })

    parent:AddChild(icon)
    ui.headerWidgets.refreshDataBtn = icon
    return icon
end

local function _create_guild_toggle(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for guild toggle")
        return
    end

    local config = NextKey222.UIConfig and NextKey222.UIConfig.CONTROLS or {}
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = ui.showGuildKeys
            and (config.GUILD_KEYS_TEXT or "Guild Keys")
            or (config.PARTY_KEYS_TEXT or "Party Keys"),
        width = config.GUILD_TOGGLE_WIDTH or 95,
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
    
    -- Clean up any stray textures from AceGUI frame reuse
    if btn and btn.frame then
        for _, region in ipairs({btn.frame:GetRegions()}) do
            if region and region.GetTexture and region:GetTexture() == "Interface\\Icons\\Ability_Repair" then
                region:Hide()
                region:SetTexture(nil)
            end
        end
    end

    parent:AddChild(btn)
    ui.guildToggleBtn = btn
    ui.headerWidgets.guildToggleBtn = btn
end

local function _create_teleport_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for teleport")
        return
    end

    local config = NextKey222.UIConfig and NextKey222.UIConfig.CONTROLS or {}
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = config.TELEPORT_TEXT or "Open Teleport",
        width = config.TELEPORT_BUTTON_WIDTH or 110,
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

local function _get_effective_player_count(ui)
    -- 1) OrganizerState: canonical source when present (Organizer / poll flows)
    if NextKey222.OrganizerState and NextKey222.OrganizerState.GetAllPlayers then
        local ok, players = pcall(function()
            return NextKey222.OrganizerState:GetAllPlayers()
        end)
        if ok and type(players) == "table" and #players > 0 then
            return #players
        end
    end

    -- 2) FakePlayerService: used by /nk opt presets and debug tools
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService.IsEnabled
        and NextKey222.FakePlayerService.GetAllPlayerNames
        and NextKey222.FakePlayerService:IsEnabled()
    then
        local ok, fake_names = pcall(function()
            return NextKey222.FakePlayerService:GetAllPlayerNames()
        end)
        if ok and type(fake_names) == "table" and #fake_names > 0 then
            -- +1 for the organizer (current player)
            return #fake_names + 1
        end
    end

    -- 3) UI cached items (keystone rows)
    if ui and ui.cachedItemsCount and ui.cachedItemsCount > 0 then
        return ui.cachedItemsCount
    end

    -- 4) Actual group size
    if GetNumGroupMembers then
        local group_count = GetNumGroupMembers() or 0
        if group_count > 0 then
            return group_count
        end
    end

    return 0
end

local function _create_organizer_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for organizer")
        return
    end

    if not ui or not ui.headerWidgets then
        log_error("UIControls: _create_organizer_button missing ui/headerWidgets")
        return
    end

    -- Prevent duplicate buttons across rebuilds
    if ui.headerWidgets.organizerBtn and ui.headerWidgets.organizerBtn.frame then
        log_dev("UIControls: Organizer button already exists; skipping duplicate creation")
        return
    end

    -- Always create the button, but initially hidden
    local config = NextKey222.UIConfig and NextKey222.UIConfig.CONTROLS or {}
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = config.ORGANIZER_TEXT or "Open Organizer",
        size = {
            config.ORGANIZER_BUTTON_WIDTH or 160,
            config.ORGANIZER_BUTTON_HEIGHT or 25
        },
        onClick = function()
            if NextKey222.RosterBoard and NextKey222.RosterBoard.Show then
                NextKey222.RosterBoard:Show()
            else
                if Debug and Debug.Error then
                    Debug:Error("RosterBoard module not available")
                end
            end
        end,
    })

    -- Always add into the same container used for other header controls
    if parent and parent.AddChild then
        parent:AddChild(btn)
    elseif ui.mainFrame and ui.mainFrame.AddChild then
        ui.mainFrame:AddChild(btn)
    end

    ui.headerWidgets.organizerBtn = btn
    
    -- Initial visibility based on current player count
    local player_count = _get_effective_player_count(ui)
    if player_count >= 6 then
        btn.frame:Show()
        log_dev("UIControls: Organizer button created and shown (player_count =", player_count, ")")
    else
        btn.frame:Hide()
        log_dev("UIControls: Organizer button created but hidden (player_count =", player_count, ")")
    end
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

-- REMOVED: _create_debug_controls function
-- Fake player controls are now exclusively in the Fake Player Tools tab
-- of the options menu. Main UI no longer shows debug controls.

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
    
    -- CRITICAL: Also set keystoneWindow.resultsFrame for independent window architecture
    if ui.keystoneWindow then
        ui.keystoneWindow.resultsFrame = scroll
        log_dev("UIControls: keystoneWindow.resultsFrame reference set")
    end
end

local function _create_view_toggle_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for view toggle")
        return
    end

    -- KEYSTONE WINDOW: Button to open dungeon window and close keystone window
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Open Dungeon View",
        fullWidth = true,
        size = {
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.WIDTH or 580),
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.BOTTOM_BUTTON_HEIGHT or 24),
        },
        onClick = function()
            -- Close keystone window first
            if ui.mainFrame and ui.mainFrame.Hide then
                ui.mainFrame:Hide()
            end
            
            -- Then open dungeon window
            if ui.ShowDungeonWindow then
                ui:ShowDungeonWindow()
            elseif NextKey222.Debug and NextKey222.Debug.Error then
                NextKey222.Debug:Error("UIControls: Dungeon window API not available")
            end
        end,
    })

    parent:AddChild(btn)
    ui.viewToggleBtn = btn
    ui.headerWidgets.viewToggleBtn = btn
end

local function _create_back_to_keystones_button(ui, parent)
    if not NextKey222.UIComponents or not NextKey222.UIComponents.CreateButton then
        log_error("UIControls: UIComponents.CreateButton not available for back button")
        return
    end

    -- DUNGEON WINDOW: Button to return to keystone window
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Back to Keystones",
        fullWidth = true,
        size = {
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.WIDTH or 580),
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.BOTTOM_BUTTON_HEIGHT or 24),
        },
        onClick = function()
            -- Just open keystone window (no mutual exclusivity)
            if ui.ShowMainFrame then
                ui:ShowMainFrame()
            elseif NextKey222.Debug and NextKey222.Debug.Error then
                NextKey222.Debug:Error("UIControls: Keystone window API not available")
            end
        end,
    })

    parent:AddChild(btn)
    ui.backToKeystonesBtn = btn
    ui.headerWidgets.backToKeystonesBtn = btn
    
    return btn
end

-- MARK: Public Interface

--- Public wrapper for creating back to keystones button
function UIControls:CreateBackToKeystonesButton(ui, parent)
    return _create_back_to_keystones_button(ui, parent)
end

--- Creates header with text and refresh icon button
-- @param ui table NextKey222.UI facade
-- @param parent table Parent frame to add header to
local function _create_header_with_refresh(ui, parent)
    if not NextKey222.UIComponents then
        return
    end
    
    local headerContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })
    
    local headerText = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Choose a sort mode; results area below.",
        width = 520,
    })
    headerContainer:AddChild(headerText)
    
    _create_refresh_icon_button(ui, headerContainer)
    
    parent:AddChild(headerContainer)
    
    -- Store reference so it can be removed during view toggle
    ui.headerContainer = headerContainer
    
    return headerContainer
end

--- Creates keystone view controls (normal mode, BELOW persistent header)
-- Expects headerContainer to have been created once via AttachHeaderControls.
-- @param ui table NextKey222.UI facade
-- @param parent table Parent container; will host controls just under header
function UIControls:CreateKeystoneControls(ui, parent)
    if not ui or not parent then
        log_error("UIControls:CreateKeystoneControls requires ui and parent")
        return
    end

    ui.headerWidgets = ui.headerWidgets or {}

    local controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    _create_sort_dropdown(ui, controls)
    _create_guild_toggle(ui, controls)
    _create_teleport_button(ui, controls)
    _create_organizer_button(ui, controls)

    -- Add to mainFrame so ViewManager can control ordering explicitly
    if ui.mainFrame and ui.mainFrame.AddChild then
        ui.mainFrame:AddChild(controls)
    else
        parent:AddChild(controls)
    end

    ui.controlsContainer = controls

    log_dev("UIControls: keystone controls created")
    return controls
end

--- Creates dungeon view controls (BELOW persistent header)
-- Expects headerContainer to have been created once via AttachHeaderControls.
-- @param ui table NextKey222.UI facade
-- @param parent table Parent container; will host controls just under header
function UIControls:CreateDungeonControls(ui, parent)
    if not ui or not parent then
        log_error("UIControls:CreateDungeonControls requires ui and parent")
        return
    end

    ui.headerWidgets = ui.headerWidgets or {}

    local controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    _create_sort_dropdown(ui, controls)
    _create_total_score_label(ui, controls)

    if ui.mainFrame and ui.mainFrame.AddChild then
        ui.mainFrame:AddChild(controls)
    else
        parent:AddChild(controls)
    end

    ui.controlsContainer = controls

    log_dev("UIControls: dungeon controls created")
    return controls
end

--- Creates keystone view controls with debug tools (BELOW persistent header)
-- Expects headerContainer to have been created once via AttachHeaderControls.
-- @param ui table NextKey222.UI facade
-- @param parent table Parent container; will host controls just under header
function UIControls:CreateDebugKeystoneControls(ui, parent)
    if not ui or not parent then
        log_error("UIControls:CreateDebugKeystoneControls requires ui and parent")
        return
    end

    ui.headerWidgets = ui.headerWidgets or {}

    local controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    _create_sort_dropdown(ui, controls)
    _create_guild_toggle(ui, controls)
    _create_teleport_button(ui, controls)
    _create_organizer_button(ui, controls)
    if _create_debug_controls then
        _create_debug_controls(ui, controls)
    end

    if ui.mainFrame and ui.mainFrame.AddChild then
        ui.mainFrame:AddChild(controls)
    else
        parent:AddChild(controls)
    end

    ui.controlsContainer = controls

    log_dev("UIControls: debug keystone controls created")
    return controls
end

--- Legacy: Attach header controls and primary layout to the given UI facade.
-- This function is kept for backward compatibility but now enforces deterministic ordering
-- while staying purely structural (no data rendering).
-- Contract:
--   - headerContainer is created once and must remain the first visual block.
--   - This function sets up:
--         [headerContainer][controlsContainer][resultsFrame][viewToggleBtn]
--   - Actual content rendering is handled by UI / ViewManager / MainWindow.
-- @param ui table NextKey222.UI facade
-- @param frame table AceGUI frame
function UIControls:AttachHeaderControls(ui, frame)
    if not ui or not frame then
        log_error("UIControls:AttachHeaderControls requires ui and frame")
        return
    end

    ui.headerWidgets = ui.headerWidgets or {}

    -- 1) Ensure persistent header container exists.
    if not ui.headerContainer then
        _create_header_with_refresh(ui, frame)
        log_dev("UIControls: created headerContainer in AttachHeaderControls")
    end

    -- 2) Normalize headerContainer position to be first child.
    if frame.children and ui.headerContainer then
        for i = #frame.children, 1, -1 do
            if frame.children[i] == ui.headerContainer then
                table.remove(frame.children, i)
                break
            end
        end
        table.insert(frame.children, 1, ui.headerContainer)
    end

    -- 3) Clean up any prior controls/results/toggle from a previous life of this frame.
    --    This prevents ghost widgets and guarantees a single canonical set on reopen.
    local function safe_detach(widget)
        if not widget then
            return
        end

        local wframe = widget.frame or widget

        -- Hide and unparent the widget/frame
        if wframe and wframe.Hide then
            wframe:Hide()
        end
        if wframe and wframe.SetParent then
            wframe:SetParent(nil)
        end
    end

    -- Detach and sanitize previous UI elements so reopened windows start clean
    safe_detach(ui.controlsContainer)
    safe_detach(ui.resultsFrame)
    safe_detach(ui.viewToggleBtn)

    -- Reset references so new widgets are built fresh for both keystone and dungeon windows
    ui.controlsContainer = nil
    ui.resultsFrame = nil
    ui.viewToggleBtn = nil
    ui.sortDropdown = nil
    ui.guildToggleBtn = nil
    ui.headerWidgets.teleportWindowBtn = nil

    -- 4) Create controls container for the current view directly under header.
    local is_dungeon_view = ui.viewMode == "dungeons"
    if is_dungeon_view then
        self:CreateDungeonControls(ui, frame)
    elseif ui.ShouldShowDebugControls and ui:ShouldShowDebugControls() then
        self:CreateDebugKeystoneControls(ui, frame)
    else
        self:CreateKeystoneControls(ui, frame)
    end

    -- 5) Create results scroll and appropriate toggle button.
    _create_results_scroll(ui, frame)
    
    -- Add the appropriate window-switching button
    if is_dungeon_view then
        _create_back_to_keystones_button(ui, frame)
    else
        _create_view_toggle_button(ui, frame)
    end

    -- 6) Enforce final ordering:
    --    [headerContainer][controlsContainer][resultsFrame][viewToggleBtn]
    if frame.children then
        local header = ui.headerContainer
        local controls = ui.controlsContainer
        local results = ui.resultsFrame
        local toggle = ui.viewToggleBtn

        local function remove_child(target)
            if not target then return end
            for i = #frame.children, 1, -1 do
                if frame.children[i] == target then
                    table.remove(frame.children, i)
                    break
                end
            end
        end

        -- Strip any existing instances so reinsertion is deterministic.
        remove_child(header)
        remove_child(controls)
        remove_child(results)
        remove_child(toggle)

        -- Insert in canonical order, skipping nils.
        local ordered = {}
        if header then table.insert(ordered, header) end
        if controls then table.insert(ordered, controls) end
        if results then table.insert(ordered, results) end
        if toggle then table.insert(ordered, toggle) end

        for index, child in ipairs(ordered) do
            table.insert(frame.children, index, child)
        end

        log_dev("UIControls:AttachHeaderControls enforced child order",
            "headerContainer=", header and "ok" or "nil",
            "controlsContainer=", controls and "ok" or "nil",
            "resultsFrame=", results and "ok" or "nil",
            "viewToggleBtn=", toggle and "ok" or "nil")
    end

    -- IMPORTANT:
    -- Do NOT trigger RenderResults/RenderDungeonCards here.
    -- First-open and reopen flows both:
    --   - Build structure via MainWindow + UIControls,
    --   - Then render via UI/MainWindow/ViewManager logic.
    log_dev("UIControls: header controls attached with enforced ordering (structural only)")
end

function UIControls:Initialize()
    log_dev("UIControls module initialized")
    return true
end

return UIControls