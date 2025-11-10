local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

local ViewManager = {
    -- Default view mode
    view_mode = "keystones",
}

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

local function _update_controls(ui)
    if not ui then
        return
    end

    if ui.UpdateKeystoneControlsVisibility then
        ui:UpdateKeystoneControlsVisibility()
    end

    if ui.UpdateDebugControlsVisibility then
        ui:UpdateDebugControlsVisibility()
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

--- Get current view mode.
-- @return string "keystones" or "dungeons"
function ViewManager:get_view_mode()
    return self.view_mode or "keystones"
end

--- Initialize view mode state from existing UI state (backwards compatibility).
-- @param ui table NextKey222.UI
function ViewManager:initialize_view_mode(ui)
    if ui and ui.viewMode then
        self.view_mode = ui.viewMode
    else
        self.view_mode = "keystones"
    end
    log_dev("ViewManager initialized with mode:", self.view_mode)
end

--- Toggle between keystone and dungeon views.
-- Mirrors existing UI:ToggleViewMode behavior but centralized.
-- @param ui table NextKey222.UI facade
function ViewManager:toggle_view_mode(ui)
    if not ui then
        return
    end

    local current = self:get_view_mode()
    log_dev("ToggleViewMode (ViewManager) called, current mode:", current)

    if current == "keystones" then
        self.view_mode = "dungeons"

        if ui.viewToggleBtn and ui.viewToggleBtn.SetText then
            ui.viewToggleBtn:SetText("Switch to Keystone View")
        end

        _apply_scroll_height(ui)
        if ui.UpdateSortDropdownOptions then
            ui:UpdateSortDropdownOptions()
        end

        _sync_config_context(ui)
        _update_controls(ui)

        if ui.lastRenderedKeystoneHash ~= nil then
            ui.lastRenderedKeystoneHash = nil
        end
        if ui.lastRenderedSortMode ~= nil then
            ui.lastRenderedSortMode = nil
        end

        if ui.RenderDungeonCards then
            ui:RenderDungeonCards()
        end

        _update_total_score_label(ui)
        if ui.ApplyWindowHeight then
            ui:ApplyWindowHeight()
        end
    else
        self.view_mode = "keystones"

        if ui.viewToggleBtn and ui.viewToggleBtn.SetText then
            ui.viewToggleBtn:SetText("Switch to Dungeons View")
        end

        _apply_scroll_height(ui)
        if ui.UpdateSortDropdownOptions then
            ui:UpdateSortDropdownOptions()
        end

        _sync_config_context(ui)
        _update_controls(ui)

        if ui.lastRenderedKeystoneHash ~= nil then
            ui.lastRenderedKeystoneHash = nil
        end
        if ui.lastRenderedSortMode ~= nil then
            ui.lastRenderedSortMode = nil
        end

        if ui.RenderResults then
            ui:RenderResults()
        end

        _update_total_score_label(ui)
        if ui.ApplyWindowHeight then
            ui:ApplyWindowHeight()
        end
    end

    ui.viewMode = self.view_mode
    log_dev("ToggleViewMode (ViewManager) completed, new mode:", self.view_mode)
end

--- Ensure current view is rendered (used by UI facade).
-- @param ui table NextKey222.UI
function ViewManager:render_current_view(ui)
    _render_view(ui)
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
    log_dev("ui", "ViewManager module initialized")
    return true
end

return ViewManager