local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug
local AceGUI = LibStub and LibStub("AceGUI-3.0")

-- MARK: Module Definition

local MainWindow = {
    -- Keystone window (primary)
    main_frame = nil,

    -- Dungeon window (separate, dedicated)
    dungeon_frame = nil,
}

NextKey222.MainWindow = MainWindow
NextKey222.RegisterModule("MainWindow", MainWindow)

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

local function _track_main_frame(frame)
    if not NextKey222 or not NextKey222.FrameRegistry or not frame then
        return
    end
    -- Main frame is managed by AceGUI; FrameRegistry is used for aux frames.
    -- No-op here, reserved for future hooks if needed.
end

local function _apply_backdrop(frame)
    if not NextKey222 or not NextKey222.UIComponents or not frame then
        return
    end

    -- Get configurable backdrop opacity
    local opacity = NextKey222.UIConfig and NextKey222.UIConfig.WINDOW
        and NextKey222.UIConfig.WINDOW.BACKDROP_OPACITY or 0.95

    NextKey222.UIComponents:ConfigureBackdrop(frame, "dialog", {
        colorScheme = "dark",
        customBgColor = {0, 0, 0, opacity}
    })
end

local function _wire_on_close(ui, widget, kind)
    if not ui then
        return
    end

    -- Shared cleanup for any primary window (keystone/dungeon)
    if ui.pendingRenderTimer then
        ui.pendingRenderTimer:Cancel()
        ui.pendingRenderTimer = nil
    end

    if ui.headerWidgets then
        wipe(ui.headerWidgets)
    end
    
    -- Clear all widget and container references so they get recreated on next open
    ui.headerContainer = nil
    ui.controlsContainer = nil
    ui.sortDropdown = nil
    ui.guildToggleBtn = nil
    ui.viewToggleBtn = nil

    ui.lastRenderedKeystoneHash = nil
    ui.lastRenderedSortMode = nil
    ui.partyCompositionHash = nil
    
    -- CRITICAL: Clear UIRendering module cache ONLY for keystone window
    -- Dungeon window doesn't use UIRendering, so only clear when keystone window closes
    if kind == "keystone" and NextKey222.UIRendering then
        NextKey222.UIRendering.last_rendered_keystone_hash = nil
        NextKey222.UIRendering.last_rendered_sort_mode = nil
        NextKey222.UIRendering.cached_items = nil
        NextKey222.UIRendering.cached_use_compact_mode = nil
        NextKey222.UIRendering.cached_items_count = 0
    end

    if ui.ioGainCache then
        wipe(ui.ioGainCache)
    end
    if ui.cachedItems then
        wipe(ui.cachedItems)
    end
    if ui.profileCache then
        wipe(ui.profileCache)
    end
    if ui.cachedPartyProfiles then
        wipe(ui.cachedPartyProfiles)
    end

    if ui.ClearAuxFrames then
        ui:ClearAuxFrames()
    end

    if AceGUI and widget then
        AceGUI:Release(widget)
    end

    if kind == "keystone" then
        ui.mainFrame = nil
        MainWindow.main_frame = nil
        
        -- If BOTH windows are now closed, clean up the shared FrameRegistry
        local dungeonWindowClosed = not NextKey222.DungeonWindow or not NextKey222.DungeonWindow:IsVisible()
        if dungeonWindowClosed and NextKey222.FrameRegistry and NextKey222.FrameRegistry.ClearAll then
            log_dev("Both windows closed - clearing shared FrameRegistry")
            NextKey222.FrameRegistry:ClearAll()
        end
    elseif kind == "dungeon" then
        ui.dungeonFrame = nil
        MainWindow.dungeon_frame = nil
    end

    log_dev(string.format("[MAIN UI] OnClose (%s) - cleared state and released widget", kind or "unknown"))
end

local function _select_footer_message()
    -- Use centralized UIConfig status message system
    local UIConfig = NextKey222 and NextKey222.UIConfig
    if UIConfig and UIConfig.GetStatusMessage then
        return UIConfig:GetStatusMessage("MAIN_WINDOW")
    end
    
    -- Fallback if UIConfig not available
    local version = "v0.5.32"
    if NextKey and NextKey.version_full then
        version = NextKey.version_full
    elseif NextKey and NextKey.version then
        version = "v" .. NextKey.version
    end
    return version
end

-- Legacy close handler (keystone window only) retained for compatibility.
local function _on_close(ui, widget)
    _wire_on_close(ui, widget, "keystone")
end

-- MARK: Public Interface

--- Create and configure the main AceGUI frame.
-- Does not show the frame; visibility is controlled by UI facade.
-- @param ui table NextKey222.UI facade
function MainWindow:CreateMainFrame(ui)
    if not ui then
        log_error("MainWindow:CreateMainFrame called without UI facade")
        return
    end

    if ui.mainFrame then
        log_dev("MainWindow: main frame already exists, skipping creation")
        return
    end

    if not AceGUI then
        log_error("MainWindow: AceGUI-3.0 not available")
        return
    end

    -- Invalidate current player's profile cache on open
    if NextKey222.ProfilesService and UnitName and GetRealmName then
        local current = UnitName("player")
        local realm = GetRealmName()
        if current and realm then
            local player_key = current .. "-" .. realm
            NextKey222.ProfilesService:InvalidateCache(player_key)
            log_dev("MainWindow: invalidated profile cache for", player_key)
        end
    end

    log_dev("MainWindow: creating AceGUI Frame for keystone window")

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey")
    frame:SetLayout("Flow")
    frame:SetStatusText(_select_footer_message())

    if NextKey222.UIConfig and NextKey222.UIConfig.WINDOW then
        local width = NextKey222.UIConfig.WINDOW.WIDTH or 600
        frame:SetWidth(width)

        local initial_height = NextKey222.UIConfig:GetWindowHeight("keystones", {
            isDebugMode = ui.ShouldShowDebugControls and ui:ShouldShowDebugControls() or false,
        }) or NextKey222.UIConfig.WINDOW.KEYSTONE_HEIGHT or 630

        frame:SetHeight(initial_height)
    end

    frame:EnableResize(false)

    -- Hide immediately; shown explicitly via UI:ToggleMainFrame/ShowMainFrame
    frame:Hide()
    log_dev("MainWindow: frame created and hidden")

    -- Apply visual style
    _apply_backdrop(frame)
    _track_main_frame(frame)

    -- Close behavior
    frame:SetCallback("OnClose", function(widget)
        _on_close(ui, widget)
    end)

    -- Store frame reference (backward compatibility)
    ui.mainFrame = frame
    self.main_frame = frame
    
    -- Initialize keystoneWindow structure
    ui.keystoneWindow = ui.keystoneWindow or {}
    ui.keystoneWindow.frame = frame
    ui.keystoneWindow.controls = nil  -- Will be set by UIControls
    
    -- Set context for sorting system
    if NextKey222.Sorting and NextKey222.Sorting.contexts then
        ui.keystoneWindow.context = NextKey222.Sorting.contexts.KEYSTONES
        log_dev("MainWindow: keystoneWindow context set to:", ui.keystoneWindow.context)
    else
        log_dev("WARNING: Sorting service not available during MainWindow initialization")
    end

    -- Attach header controls and layout via UIControls when available (Phase 5 wiring)
    if NextKey222.UIControls and NextKey222.UIControls.AttachHeaderControls then
        NextKey222.UIControls:AttachHeaderControls(ui, frame)
    else
        log_dev("MainWindow: UIControls.AttachHeaderControls not available; main UI will be bare")
    end

    log_dev("MainWindow: keystone window frame creation complete")
    return frame
end

--- Get the current main frame instance (if any).
-- @return table|nil
function MainWindow:GetMainFrame()
    return (NextKey222.UI and NextKey222.UI.mainFrame) or self.main_frame
end

--- Check if main frame is visible.
-- @return boolean
function MainWindow:IsMainFrameVisible()
    local frame = self:GetMainFrame()
    return frame and frame.IsShown and frame:IsShown() or false
end

--- Show the KEYS main frame, creating it if necessary.
-- @param ui table NextKey222.UI facade
function MainWindow:ShowMainFrame(ui)
    if not ui then
        return
    end
    
    if not self.main_frame or not ui.mainFrame then
        self:CreateMainFrame(ui)
    end

    local frame = self.main_frame or ui.mainFrame
    if not frame then
        log_error("MainWindow:ShowMainFrame - main (keystone) frame missing after CreateMainFrame")
        return
    end

    frame:Show()
    log_dev("MainWindow: main (keystone) frame shown")

    -- Render keystone results into this window's resultsFrame
    if ui.keystoneWindow and ui.keystoneWindow.resultsFrame and ui.RenderResults then
        local previous_results = ui.resultsFrame
        ui.resultsFrame = ui.keystoneWindow.resultsFrame
        ui:RenderResults()
        ui.resultsFrame = previous_results
    elseif ui.RenderResults then
        ui:RenderResults()
    end
end

--- Toggle the main (keystone) frame; uses the same close semantics as OnClose.
-- @param ui table NextKey222.UI facade
function MainWindow:ToggleMainFrame(ui)
    if not ui then
        return
    end

    local frame = ui.mainFrame or self.main_frame

    if frame and frame.IsShown and frame:IsShown() then
        log_dev("MainWindow: toggling OFF main (keystone) frame")
        -- Reuse unified close handler to avoid double-release bugs
        _wire_on_close(ui, frame, "keystone")
    else
        log_dev("MainWindow: toggling ON main (keystone) frame")
        self:ShowMainFrame(ui)
    end
end

-- MARK: Initialization

function MainWindow:Initialize()
    log_dev("MainWindow module initialized")
    return true
end

-- MARK: Dungeon Window (REMOVED - now in independent ui/dungeonWindow.lua)

--- Deprecated: Dungeon window is now managed by NextKey222.DungeonWindow module
-- These functions are kept for backward compatibility only
function MainWindow:CreateDungeonWindow(ui)
    log_dev("MainWindow:CreateDungeonWindow - deprecated, use NextKey222.DungeonWindow instead")
end

function MainWindow:ShowDungeonWindow(ui)
    log_dev("MainWindow:ShowDungeonWindow - deprecated, use NextKey222.DungeonWindow:Show() instead")
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:Show()
    end
end

function MainWindow:ToggleDungeonWindow(ui)
    log_dev("MainWindow:ToggleDungeonWindow - deprecated, use NextKey222.DungeonWindow:Toggle() instead")
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:Toggle()
    end
end

function MainWindow:IsDungeonWindowVisible()
    if NextKey222.DungeonWindow then
        return NextKey222.DungeonWindow:IsVisible()
    end
    return false
end

return MainWindow