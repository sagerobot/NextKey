local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition
-- NOTE: ViewManager is now deprecated with the two-window system.
-- Keeping stub for backward compatibility only.

local ViewManager = {}

NextKey222.ViewManager = ViewManager
NextKey222.RegisterModule("ViewManager", ViewManager)

-- MARK: Private Helpers

local function log_dev(...)
    if Debug and Debug.Dev then
        Debug:Dev("ui", ...)
    end
end

local function _apply_scroll_height(ui)
    if not ui or not ui.resultsFrame or not NextKey222 or not NextKey222.UIConfig then
        return
    end

    local config = NextKey222.UIConfig
    local height

    if ViewManager.view_mode == "dungeons" then
        height = config.WINDOW and config.WINDOW.SCROLL_FRAME_HEIGHT_DUNGEON
    else
        height = config.WINDOW and config.WINDOW.SCROLL_FRAME_HEIGHT_KEYSTONE
    end

    if height and ui.resultsFrame.SetHeight then
        ui.resultsFrame:SetHeight(height)
    end
end

local function _sync_config_context(ui)
    if not ui or not ui.configContext then
        return
    end

    ui.configContext:SynchronizeWithUI(ui)
end

local function _rebuild_controls(ui, view_mode)
    if not ui or not ui.mainFrame then
        return
    end

    if not NextKey222.UIControls then
        log_dev("ViewManager: UIControls module not available")
        return
    end

    -- IMPORTANT:
    -- The headerContainer ("Choose a sort mode; results area below.") is created once
    -- by UIControls:AttachHeaderControls() during main frame creation and MUST remain
    -- fixed at the top of the window. We only rebuild the controlsContainer below it.
    --
    -- This prevents the header line from jumping to the bottom when toggling views.

    -- Remove existing controls container (but keep headerContainer intact)
    if ui.controlsContainer then
        local parent_frame = ui.mainFrame
        if parent_frame and parent_frame.children then
            for i, child in ipairs(parent_frame.children) do
                if child == ui.controlsContainer then
                    table.remove(parent_frame.children, i)
                    if ui.controlsContainer.frame then
                        ui.controlsContainer.frame:Hide()
                        ui.controlsContainer.frame:SetParent(nil)
                    end
                    break
                end
            end
        end
        ui.controlsContainer = nil
    end

    -- Rebuild headerWidgets mapping from persistent headerContainer so controls code
    -- can still attach references safely without recreating the header.
    if not ui.headerWidgets then
        ui.headerWidgets = {}
    else
        -- Only clear non-header entries. For simplicity and safety in this refactor,
        -- we allow controls code to overwrite keys it owns; headerContainer itself
        -- stays referenced via ui.headerContainer.
        for k in pairs(ui.headerWidgets) do
            ui.headerWidgets[k] = nil
        end
    end

    -- Determine which control set to create under the header based on view/debug state
    local should_show_debug = ui.ShouldShowDebugControls and ui:ShouldShowDebugControls()

    -- Compute insertion index so controlsContainer is always:
    -- [ headerContainer ] [ controlsContainer ] [ resultsFrame ] ...
    local insert_at = 1
    local children = ui.mainFrame.children or {}

    -- Find header position if it exists; otherwise default to top.
    if ui.headerContainer then
        for i, child in ipairs(children) do
            if child == ui.headerContainer then
                insert_at = i + 1
                break
            end
        end
    end

    -- Fallback: if no explicit headerContainer found, assume first slot is header
    if insert_at == 1 and #children > 0 then
        insert_at = 2
    end

    -- Build appropriate controls into mainFrame; UIControls will set ui.controlsContainer.
    if view_mode == "dungeons" then
        NextKey222.UIControls:CreateDungeonControls(ui, ui.mainFrame)
        log_dev("ViewManager: rebuilt controls for dungeon view")
    elseif should_show_debug then
        NextKey222.UIControls:CreateDebugKeystoneControls(ui, ui.mainFrame)
        log_dev("ViewManager: rebuilt controls for debug keystone view")
    else
        NextKey222.UIControls:CreateKeystoneControls(ui, ui.mainFrame)
        log_dev("ViewManager: rebuilt controls for keystone view")
    end

    -- Ensure the new controlsContainer is placed directly under headerContainer.
    if ui.controlsContainer and ui.mainFrame.children then
        local controls = ui.controlsContainer

        -- Remove from current position
        for i = #ui.mainFrame.children, 1, -1 do
            if ui.mainFrame.children[i] == controls then
                table.remove(ui.mainFrame.children, i)
                break
            end
        end

        -- Clamp insert_at within valid range
        if insert_at < 1 then
            insert_at = 1
        end
        if insert_at > (#ui.mainFrame.children + 1) then
            insert_at = #ui.mainFrame.children + 1
        end

        table.insert(ui.mainFrame.children, insert_at, controls)
    end
end

local function _update_total_score_label(ui)
    if not ui or not ui.totalScoreLabel or not NextKey222 or not NextKey222.Addon then
        return
    end

    if ViewManager.view_mode == "dungeons" then
        local total = NextKey222.Addon:GetRaiderIOTotalScore()
        if ui.FormatColoredTotalScore then
            ui.totalScoreLabel:SetText(ui:FormatColoredTotalScore(total))
        else
            ui.totalScoreLabel:SetText(tostring(total or 0))
        end
    else
        ui.totalScoreLabel:SetText("")
    end
end

local function _render_view(ui)
    if not ui then
        return
    end

    if ViewManager.view_mode == "dungeons" then
        if ui.RenderDungeonCards then
            ui:RenderDungeonCards()
        end
    else
        if ui.RenderResults then
            ui:RenderResults()
        end
    end
end

local function _get_group_size()
    return (GetNumGroupMembers and GetNumGroupMembers()) or 1
end

-- MARK: Public Interface

--- Deprecated: Get current view mode stub
function ViewManager:get_view_mode()
    return "keystones" -- Always return keystones for compatibility
end

--- Deprecated: Initialize view mode stub
function ViewManager:initialize_view_mode(ui)
    -- No-op: two-window system doesn't use view modes
end

--- Deprecated: Toggle view mode stub
function ViewManager:toggle_view_mode(ui)
    -- No-op: use separate ShowDungeonWindow/ShowMainFrame instead
    if Debug and Debug.Dev then
        Debug:Dev("ui", "ViewManager:toggle_view_mode is deprecated - use ShowDungeonWindow/ShowMainFrame")
    end
end

--- Deprecated: Render current view stub
function ViewManager:render_current_view(ui)
    -- No-op: windows render themselves independently
end

--- Detect which high-level UI mode should be used based on group size.
-- @return string "KEYSTONE_OPTIMIZER" or "ROSTER_BOARD"
function ViewManager:detect_ui_mode()
    local size = _get_group_size()
    if size >= 6 then
        return "ROSTER_BOARD"
    end
    return "KEYSTONE_OPTIMIZER"
end

--- Handle GROUP_ROSTER_UPDATE for UI mode changes.
-- Delegates to NextKey222.UI facade methods when available.
-- @param ui table NextKey222.UI
function ViewManager:on_group_roster_update(ui)
    if not ui or not ui.SwitchToUIMode then
        return
    end

    local new_mode = self:detect_ui_mode()
    if new_mode ~= ui.currentUIMode then
        log_dev("ui", "ViewManager: group size changed, switching UI mode from",
            ui.currentUIMode or "NONE", "to", new_mode)
        ui:SwitchToUIMode(new_mode)
    end

    _sync_config_context(ui)
end

-- MARK: Initialization

function ViewManager:Initialize()
    if Debug and Debug.Dev then
        Debug:Dev("ui", "ViewManager module initialized (deprecated stub)")
    end
    return true
end

return ViewManager