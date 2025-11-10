local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug
local AceGUI = LibStub and LibStub("AceGUI-3.0")

-- MARK: Module Definition

local MainWindow = {
    main_frame = nil,
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

    NextKey222.UIComponents:ConfigureBackdrop(frame, "dialog", { colorScheme = "dark" })
end

local function _select_footer_message()
    local messages = {
        "UI skeleton - M0.6",
        "Pick your hearthstone in /nk opt",
    }

    if #messages == 0 then
        return "NextKey"
    end

    local index = 1
    if GetTime then
        index = (math.floor(GetTime()) % #messages) + 1
    end

    return messages[index]
end

local function _on_close(ui, widget)
    if not ui then
        return
    end

    -- Cancel pending debounced render
    if ui.pendingRenderTimer then
        ui.pendingRenderTimer:Cancel()
        ui.pendingRenderTimer = nil
    end

    -- Clear header widgets references
    if ui.headerWidgets then
        wipe(ui.headerWidgets)
    end

    -- Clear render tracking variables
    ui.lastRenderedKeystoneHash = nil
    ui.lastRenderedSortMode = nil
    ui.partyCompositionHash = nil

    -- Clear caches
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

    -- Clear aux frames via FrameRegistry + legacy cleanup
    if ui.ClearAuxFrames then
        ui:ClearAuxFrames()
    end

    log_dev("[MAIN UI] OnClose - cleared all tracking variables and caches")

    if AceGUI and widget then
        AceGUI:Release(widget)
    end

    ui.mainFrame = nil
    ui.resultsFrame = nil
    ui.controlsContainer = nil
    ui.debugControlsContainer = nil
    ui.debugFakeTierDropdown = nil
    ui.debugAddFakeBtn = nil
    ui.debugClearFakeBtn = nil
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

    log_dev("MainWindow: creating AceGUI Frame")

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey")
    frame:SetLayout("Flow")
    frame:SetStatusText(_select_footer_message())

    if NextKey222.UIConfig and NextKey222.UIConfig.WINDOW then
        local width = NextKey222.UIConfig.WINDOW.WIDTH or 600
        frame:SetWidth(width)

        local initial_height = NextKey222.UIConfig:GetWindowHeight("keystones", {
            isDebugMode = ui.ShouldShowDebugControls and ui:ShouldShowDebugControls() or false,
        }) or NextKey222.UIConfig.WINDOW.BASE_HEIGHT or 640

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

    ui.mainFrame = frame

    -- Attach header controls and layout via UIControls when available (Phase 5 wiring)
    if NextKey222.UIControls and NextKey222.UIControls.AttachHeaderControls then
        NextKey222.UIControls:AttachHeaderControls(ui, frame)
    else
        log_dev("MainWindow: UIControls.AttachHeaderControls not available; main UI will be bare")
    end

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

--- Show the main frame, creating it if necessary.
-- @param ui table NextKey222.UI facade
function MainWindow:ShowMainFrame(ui)
    if not ui then
        return
    end

    if not ui.mainFrame then
        self:CreateMainFrame(ui)
    end

    if ui.mainFrame then
        ui.mainFrame:Show()
        log_dev("MainWindow: main frame shown")
    else
        log_error("MainWindow: failed to create main frame")
    end
end

--- Toggle the main frame; hides and releases on close, or shows if not visible.
-- Cleanup semantics mirror existing UI:ToggleMainFrame behavior.
-- @param ui table NextKey222.UI facade
function MainWindow:ToggleMainFrame(ui)
    if not ui then
        return
    end

    local frame = ui.mainFrame

    if frame and frame.IsShown and frame:IsShown() then
        log_dev("MainWindow: hiding existing main frame")

        -- Clear key caches proactively (in addition to OnClose)
        if ui.ioGainCache then wipe(ui.ioGainCache) end
        if ui.cachedItems then wipe(ui.cachedItems) end
        if ui.profileCache then wipe(ui.profileCache) end
        if ui.cachedPartyProfiles then wipe(ui.cachedPartyProfiles) end

        frame:Hide()

        if AceGUI then
            AceGUI:Release(frame)
        end

        ui.mainFrame = nil
        ui.resultsFrame = nil
        ui.controlsContainer = nil
        ui.debugControlsContainer = nil

        if collectgarbage then
            collectgarbage("step", 1000)
        end

        log_dev("MainWindow: frame hidden, caches cleared, GC hinted")
    else
        log_dev("MainWindow: showing or creating main frame")
        self:ShowMainFrame(ui)
    end
end

-- MARK: Initialization

function MainWindow:Initialize()
    log_dev("MainWindow module initialized")
    return true
end

return MainWindow