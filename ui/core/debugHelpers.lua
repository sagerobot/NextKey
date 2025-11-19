local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module

local UIDebugHelpers = {}

NextKey222.UIDebugHelpers = UIDebugHelpers
NextKey222.RegisterModule("UIDebugHelpers", UIDebugHelpers)

-- MARK: Private

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

local function _ensure_ui()
    local ui = NextKey222 and NextKey222.UI
    if not ui then
        log_error("UIDebugHelpers: UI facade not available")
        return nil
    end
    return ui
end

-- MARK: Fake Players

--- Add a fake player using the current UI debug tier selection.
function UIDebugHelpers:AddFakePlayer()
    local ui = _ensure_ui()
    if not ui then
        return
    end

    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.CreatePlayer then
        log_dev("UIDebugHelpers: FakePlayerService unavailable - cannot add player")
        return
    end

    local tier_selection = ui.debugFakeTierSelection or "random"
    local tiers = {
        "title",
        "elite",
        "expert",
        "skilled",
        "competent",
        "average",
        "casual",
        "beginner",
    }

    local chosen_tier = tier_selection
    if tier_selection == "random" then
        local index = math.random(#tiers)
        chosen_tier = tiers[index]
    end

    local name = NextKey222.FakePlayerService:CreatePlayer({ tier = chosen_tier })
    if name then
        log_dev("UIDebugHelpers: created fake player", name, "tier", chosen_tier)
        if ui.ScheduleRender then
            ui:ScheduleRender()
        elseif ui.RefreshResults then
            ui:RefreshResults()
        end
    else
        log_dev("UIDebugHelpers: failed to create fake player for tier", chosen_tier)
    end
end

--- Remove all fake players.
function UIDebugHelpers:ClearAllFakePlayers()
    local ui = _ensure_ui()
    if not ui then
        return
    end

    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.ClearAllPlayers then
        log_dev("UIDebugHelpers: FakePlayerService unavailable - cannot clear players")
        return
    end

    local removed = NextKey222.FakePlayerService:ClearAllPlayers() or 0
    log_dev("UIDebugHelpers: cleared fake players", removed)

    if ui.ScheduleRender then
        ui:ScheduleRender()
    elseif ui.RefreshResults then
        ui:RefreshResults()
    end
end

--- Remove a single fake player by name.
-- @param player_name string
function UIDebugHelpers:RemoveFakePlayer(player_name)
    local ui = _ensure_ui()
    if not ui then
        return
    end

    if not player_name or not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RemovePlayer then
        return
    end

    NextKey222.FakePlayerService:RemovePlayer(player_name)
    log_dev("UIDebugHelpers: removed fake player", player_name)

    if ui.ScheduleRender then
        ui:ScheduleRender()
    elseif ui.RefreshResults then
        ui:RefreshResults()
    end
end

-- MARK: Debug Controls

--- Attach debug controls into an existing controls container.
-- The actual widgets are created by UIControls; this helper wires behavior.
-- @param ui table NextKey222.UI
-- @param container table AceGUI container holding debug controls
function UIDebugHelpers:AttachDebugControls(ui, container)
    if not ui or not container then
        return
    end

    ui.debugControlsContainer = container

    -- If UIComponents built widgets directly, they should already call back into UI:
    -- HandleAddDebugFakePlayer / HandleDeleteAllFakePlayers / HandleDeleteFakePlayer.
    -- This module keeps helpers centralized; no extra behavior needed here currently.
    log_dev("UIDebugHelpers: debug controls attached")
end

--- Update debug controls layout/visibility based on current debug mode and view.
-- This is called from UI:UpdateDebugControlsVisibility when needed.
-- @param ui table
function UIDebugHelpers:OnDebugModeChanged(ui)
    ui = ui or _ensure_ui()
    if not ui then
        return
    end

    if ui.UpdateDebugControlsVisibility then
        ui:UpdateDebugControlsVisibility()
    end

    if ui.viewMode == "keystones" and ui.RenderResults then
        ui:RenderResults()
    end

    log_dev("UIDebugHelpers: debug mode change applied")
end

-- MARK: Public API
-- Invoked by core/slashCommands.lua

--- Manual debug controls refresh (called from /nextkeyrefreshdebug).
function UIDebugHelpers:RefreshDebugControls()
    local ui = _ensure_ui()
    if not ui then
        return
    end

    if Debug and Debug.User then
        Debug:User("Manual debug controls refresh triggered")
    end

    if ui.RefreshDebugControls then
        ui:RefreshDebugControls()
    elseif ui.UpdateDebugControlsVisibility then
        ui:UpdateDebugControlsVisibility()
    end
end

--- Manual UI refresh (called from /nextkeyrefresh).
function UIDebugHelpers:RefreshUI()
    local ui = _ensure_ui()
    if not ui then
        return
    end

    if Debug and Debug.User then
        Debug:User("Manual UI refresh triggered")
    end

    if ui.RefreshResults then
        ui:RefreshResults()
        if Debug and Debug.User then
            Debug:User("UI refresh completed")
        end
    elseif ui.RenderResults then
        ui:RenderResults()
        if Debug and Debug.User then
            Debug:User("UI render triggered")
        end
    end
end

--- Simulate spec change event (called from /nextkeytestspec).
function UIDebugHelpers:SimulateSpecChange()
    if Debug and Debug.User then
        Debug:User("Simulating spec change event")
    end

    if NextKey222.ProfilesService and NextKey222.ProfilesService.InvalidateCache then
        NextKey222.ProfilesService:InvalidateCache()
        if Debug and Debug.User then
            Debug:User("Profile cache invalidated")
        end
    end

    local ui = _ensure_ui()
    if ui and ui.RefreshResults then
        ui:RefreshResults()
        if Debug and Debug.User then
            Debug:User("UI refresh triggered after simulated spec change")
        end
    end
end

--- Open Roster Board for testing (called from /nkroster).
function UIDebugHelpers:OpenRosterBoard()
    if Debug and Debug.User then
        Debug:User("Manually showing Roster Board for testing")
    end

    if NextKey222.RosterBoard and NextKey222.RosterBoard.Show then
        local ui = NextKey222.UI
        if ui and ui.mainFrame and ui.mainFrame.IsShown and ui.mainFrame:IsShown() then
            ui.mainFrame:Hide()
        end

        NextKey222.RosterBoard:Show()

        if Debug and Debug.User then
            Debug:User("Roster Board opened for testing")
        end
    else
        if Debug and Debug.Error then
            Debug:Error("RosterBoard module not available")
        end
    end
end

-- MARK: Initialization

function UIDebugHelpers:Initialize()
    log_dev("UIDebugHelpers module initialized")
    return true
end

return UIDebugHelpers