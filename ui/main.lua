local _, NextKey222 = ...
local NextKey = NextKey222.Addon

-- MARK: Module Definition

-- Central UI facade: thin coordinator delegating to dedicated modules.
local UI = {
    -- Core state
    showGuildKeys = false,

    -- Frame/control references (owned by MainWindow/UIControls)
    mainFrame = nil,
    resultsFrame = nil,
    viewToggleBtn = nil,
    guildToggleBtn = nil,
    headerWidgets = {},
    
    -- Window structures for independent windows
    keystoneWindow = nil,
    dungeonWindow = nil,

    -- Debug / fake player state
    debugFakeTierSelection = "random",

    -- Character capture tracking
    hasTriggeredCharacterCapture = false,

    -- Dynamic Configuration Context Reference
    configContext = nil,

    -- Organizer: UI mode state
    currentUIMode = nil,   -- "KEYSTONE_OPTIMIZER" or "ROSTER_BOARD"
    organizerState = nil,  -- Preserved state for mode switches

    -- PERFORMANCE: Debounced render timer
    pendingRenderTimer = nil,
    renderDebounceDelay = 0.3,

    -- PERFORMANCE / CACHE: IO + render caches (delegated to UICalculations/UIRendering)
    ioGainCache = {},
    partyCompositionHash = nil,
    lastRenderedKeystoneHash = nil,
    lastRenderedSortMode = nil,
}

NextKey222.UI = UI
NextKey222.RegisterModule("UI", UI)

-- MARK: Module References

local MainWindow      = NextKey222.MainWindow
local UIControls      = NextKey222.UIControls
local ViewManager     = NextKey222.ViewManager
local UIRendering     = NextKey222.UIRendering
local UICalculations  = NextKey222.UICalculations
local UIPerformance   = NextKey222.UIPerformance

-- MARK: Public Interface

-- Main frame lifecycle (facade only; implementation in MainWindow/UIControls)
function UI:CreateMainFrame()
    if not MainWindow or not MainWindow.CreateMainFrame then
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("UI: MainWindow module not available")
        end
        return
    end

    -- Create base frame once
    -- MainWindow handles all UI construction including header controls
    local frame = MainWindow:CreateMainFrame(self)

    return frame
end

-- Two-window system:
-- - Keystone window: primary NextKey view (/nk)
-- - Dungeon window: dedicated dungeon view (opened explicitly)
-- No more mutable single window toggling.

-- Keystone window: show/hide

function UI:ShowMainFrame()
    if not MainWindow or not MainWindow.ShowMainFrame then
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("UI: MainWindow module not available for keystone window")
        end
        return
    end

    MainWindow:ShowMainFrame(self)
end

function UI:ToggleMainFrame()
    if not MainWindow or not MainWindow.ToggleMainFrame then
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("UI: MainWindow module not available for keystone window toggle")
        end
        return
    end

    -- Ensure frame exists when toggling.
    if not self.mainFrame then
        self:CreateMainFrame()
    end

    MainWindow:ToggleMainFrame(self)
end

function UI:IsMainFrameVisible()
    if MainWindow and MainWindow.IsMainFrameVisible then
        return MainWindow:IsMainFrameVisible()
    end
    return self.mainFrame and self.mainFrame.IsShown and self.mainFrame:IsShown() or false
end

-- Dungeon window: dedicated, separate frame

--- Show the dedicated dungeon window (separate from keystone window).
function UI:ShowDungeonWindow()
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:Show()
    else
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("UI: DungeonWindow module not available")
        end
    end
end

--- Toggle the dedicated dungeon window.
function UI:ToggleDungeonWindow()
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:Toggle()
    else
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("UI: DungeonWindow module not available")
        end
    end
end

function UI:IsDungeonWindowVisible()
    if NextKey222.DungeonWindow then
        return NextKey222.DungeonWindow:IsVisible()
    end
    return false
end

-- View / mode switching (legacy toggle) is deprecated under two-window system.
-- Keep stub for compatibility; internally we route to open the relevant window.

function UI:ToggleViewMode()
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "ToggleViewMode called (deprecated) - opening dungeon window instead")
    end
    self:ShowDungeonWindow()
end

function UI:OnGroupRosterUpdate()
    if ViewManager and ViewManager.on_group_roster_update then
        return ViewManager:on_group_roster_update(self)
    end
end

function UI:RefreshKeystoneList()
    -- Refresh keystone window if open
    if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
        if self.RenderResults then
            self:RenderResults()
        end
    end
    
    -- Refresh dungeon window if open
    if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
        NextKey222.DungeonWindow:Render()
    end
end

-- Rendering (facade)

function UI:RenderResults()
    if not self.resultsFrame then
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("ui", "RenderResults: no results frame")
        end
        return
    end

    local addon = NextKey222.Addon
    local keys = addon and addon.GetAvailableKeys and addon:GetAvailableKeys() or {}
    local mode = self.GetCurrentSortMode and self:GetCurrentSortMode() or "HighestKeyLevel"

    if UIRendering and UIRendering.render_keystones then
        UIRendering:render_keystones(self, keys, mode)
        if self.configContext and self.configContext.SynchronizeWithUI then
            self.configContext:SynchronizeWithUI(self)
        end
        return
    end

    -- Fallback to legacy inline path when orchestrator is unavailable.
    -- This ensures a single render path (no duplicate cards).
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "UIRendering missing; using inline fallback RenderResults")
    end

    -- Reuse the inline implementation that used to live below.
    -- It will honor cachedItemsCount and visibility helpers.
    -- (Defined immediately after as part of UI:RenderResults body.)
    if not keys or #keys == 0 then
        if NextKey222.UIComponents and self.resultsFrame.AddChild then
            local none = NextKey222.UIComponents:CreateText("body", nil, {
                text = "No keys detected. Enable Debug in options or acquire a keystone.",
                width = nil,
            })
            self.resultsFrame:AddChild(none)
        end

        self.cachedItemsCount = 0
        if self.UpdateKeystoneControlsVisibility then
            self:UpdateKeystoneControlsVisibility()
        end
        if self.configContext and self.configContext.SynchronizeWithUI then
            self.configContext:SynchronizeWithUI(self)
        end
        return
    end

    local current_hash = self.GetKeystoneListHash and self:GetKeystoneListHash(keys) or nil
    if current_hash
        and self.lastRenderedKeystoneHash == current_hash
        and self.lastRenderedSortMode == mode
    then
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("keystones", "Skipping fallback render - no keystone or sort changes detected")
        end
        return
    end

    self.lastRenderedKeystoneHash = current_hash
    self.lastRenderedSortMode = mode

    if self.ClearAuxFrames then
        self:ClearAuxFrames()
    end
    if self.resultsFrame.ReleaseChildren then
        self.resultsFrame:ReleaseChildren()
    end

    self.cachedItems = {}
    local items = self.SortKeys and self:SortKeys(keys, mode) or {}

    local use_compact = shouldUseCompactMode(#items)
    self.cachedUseCompactMode = use_compact
    self.cachedItemsCount = #items

    for _, it in ipairs(items) do
        if self.EnrichEntryMetadata then
            self:EnrichEntryMetadata(it)
        end
        table.insert(self.cachedItems, it)

        local render_fn = use_compact and self.AddKeyRowCompact or self.AddKeyRow
        if render_fn and NextKey222.SafeRun then
            local ok = NextKey222.SafeRun(render_fn, "Render keystone card (fallback)", self, it)
            if not ok and NextKey222.Debug and NextKey222.Debug.Error then
                NextKey222.Debug:Error("UI fallback: failed to render card for", it.key and it.key.ownerName or "nil")
            end
        end
    end

    if self.UpdateKeystoneControlsVisibility then
        self:UpdateKeystoneControlsVisibility()
    end
    if self.configContext and self.configContext.SynchronizeWithUI then
        self.configContext:SynchronizeWithUI(self)
    end
end

-- IO / calculations (facade)

function UI:CalculateIOGainRange(keystone_data)
    if UICalculations and UICalculations.calculate_io_gain_range then
        return UICalculations:calculate_io_gain_range(keystone_data, {
            party_hash = self.partyCompositionHash,
        })
    end
    return { min = 0, max = 0, expected = 0 }
end

function UI:GetPartyCompositionHash()
    if UICalculations and UICalculations.get_party_composition_hash then
        return UICalculations:get_party_composition_hash()
    end
    return "empty"
end

function UI:GetKeystoneListHash(keys)
    if UICalculations and UICalculations.get_keystone_list_hash then
        return UICalculations:get_keystone_list_hash(keys)
    end
    return "empty"
end

-- Frame pacing (facade)

function UI:QueueFramePacedRender()
    if UIPerformance and UIPerformance.QueueFramePacedRender then
        return UIPerformance:QueueFramePacedRender(self)
    end

    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "UIPerformance missing; falling back to immediate render")
    end

    -- Default to keystone rendering if called directly
    if self.RenderResults then
        self:RenderResults()
    end
end

-- Initialization (facade)

function UI:Initialize()
    if NextKey222.Debug then
        NextKey222.Debug:Dev("ui", "UI module initialized (facade)")
    end

    if NextKey222.ConfigurationContext then
        self.configContext = NextKey222.ConfigurationContext
    end

    if UIPerformance and UIPerformance.Initialize_for_ui then
        UIPerformance:Initialize_for_ui(self)
    end

    -- ViewManager no longer needed for two-window system
    -- Each window is independent

    if NextKey222.UIInitialization and NextKey222.UIInitialization.InitializeUI then
        NextKey222.UIInitialization:InitializeUI(self)
    end

    return true
end

--- Determines whether debug mode is currently enabled
-- @return boolean true if global debug flag is enabled
function UI:IsDebugMode()
    if not NextKey222 or not NextKey222.Debug then
        return false
    end

    return NextKey222.Debug.enabled == true
end

--- Determines if debug-only controls should be visible.
-- Delegates to configurationContext when available.
function UI:ShouldShowDebugControls()
    if self.configContext and self.configContext.ShouldShowDebugControls then
        return self.configContext:ShouldShowDebugControls()
    end

    local is_debug = self:IsDebugMode()
    local has_fake_service = NextKey222.FakePlayerService ~= nil
    -- Debug controls only appear in keystone window
    return is_debug and has_fake_service
end

--- Determines if keystone-specific controls should be visible.
function UI:ShouldShowKeystoneControls()
    if self.configContext and self.configContext.ShouldShowKeystoneControls then
        return self.configContext:ShouldShowKeystoneControls()
    end

    -- Keystone controls should show in keystone window (always true for keystone window)
    return true
end

--- Applies the appropriate window height based on current view and debug state.
function UI:ApplyWindowHeight()
    if not self.mainFrame then
        return
    end

    local height = 645

    if self.configContext and self.configContext.GetResolvedConfig then
        local window_config = self.configContext:GetResolvedConfig("window") or {}
        height = window_config.height or height
    elseif NextKey222.UIConfig and NextKey222.UIConfig.GetWindowHeight then
        height = NextKey222.UIConfig:GetWindowHeight("keystones", {
            isDebugMode = self:ShouldShowDebugControls(),
        }) or height
    end

    if NextKey222.UIScale and NextKey222.UIScale.ScaleValue then
        height = NextKey222.UIScale:ScaleValue(height, true)
    end

    self.mainFrame:SetHeight(height)
end

-- Removed: ApplyResultsTopPadding() - spacer no longer needed

--- Shows or hides debug-specific widgets and reapplies layout.
-- DEPRECATED: Controls are now rebuilt per-view via ViewManager:_rebuild_controls()
-- Kept as a stub for backward compatibility.
function UI:UpdateDebugControlsVisibility()
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "UpdateDebugControlsVisibility: deprecated stub called (controls now rebuilt per-view)")
    end
    -- No-op: controls are now managed by ViewManager:_rebuild_controls()
end

--- Shows or hides keystone-specific controls based on view mode.
-- DEPRECATED: Controls are now rebuilt per-view via ViewManager:_rebuild_controls()
-- Kept as a stub for backward compatibility.
function UI:UpdateKeystoneControlsVisibility()
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "UpdateKeystoneControlsVisibility: deprecated stub called (controls now rebuilt per-view)")
    end
    -- No-op: controls are now managed by ViewManager:_rebuild_controls()
end

--- Manual refresh function for debug controls (for testing and fallback).
function UI:RefreshDebugControls()
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "Manual debug controls refresh triggered")
    end

    if self.mainFrame then
        self:UpdateDebugControlsVisibility()
    else
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("ui", "Cannot refresh debug controls - no main frame")
        end
    end
end

--- Handles debug mode toggles while the UI is open.
function UI:OnDebugModeChanged()
    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "OnDebugModeChanged called - mainFrame exists:", self.mainFrame ~= nil)
    end

    if not self.mainFrame then
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("ui", "No main frame, skipping visibility update")
        end
        return
    end

    self:UpdateDebugControlsVisibility()

    -- Refresh keystone window if it's open
    if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
        if self.RenderResults then
            self:RenderResults()
        end
    end

    if NextKey222.Debug and NextKey222.Debug.Dev then
        NextKey222.Debug:Dev("ui", "Debug mode change completed")
    end
end

--- Determines if a player provides Heroism/Bloodlust (delegates to PlayerCapabilities module)
-- @param profile table Optional player profile with capabilities
-- @param classToken string Optional class token
-- @param specID number Optional specialization ID
-- @return boolean true if player can provide heroism
function UI:PlayerProvidesHeroism(profile, classToken, specID)
    if NextKey222.PlayerCapabilities then
        return NextKey222.PlayerCapabilities:PlayerProvidesHeroism(profile, classToken, specID)
    end
    if NextKey222.Debug and NextKey222.Debug.Error then
        NextKey222.Debug:Error("PlayerCapabilities module not available")
    end
    return false
end

--- Determines if a player provides Battle Resurrection (delegates to PlayerCapabilities module)
-- @param profile table Optional player profile with capabilities
-- @param classToken string Optional class token
-- @param specID number Optional specialization ID
-- @return boolean true if player can provide battle res
function UI:PlayerProvidesBattleRes(profile, classToken, specID)
    if NextKey222.PlayerCapabilities then
        return NextKey222.PlayerCapabilities:PlayerProvidesBattleRes(profile, classToken, specID)
    end
    if NextKey222.Debug and NextKey222.Debug.Error then
        NextKey222.Debug:Error("PlayerCapabilities module not available")
    end
    return false
end


-- MARK: Private Helper Functions
-- =====================================================
-- Utility functions for frame management and UI effects
-- NOTE: These are now delegated to the Utilities module
-- =====================================================

---Track auxiliary frames for cleanup (delegates to Utilities module)
---@param self table UI module instance (unused, kept for compatibility)
---@param frame table Frame to track
local function trackAuxFrame(self, frame)
    if NextKey222.Utilities then
        NextKey222.Utilities:TrackAuxFrame(frame)
    else
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("Utilities module not available - frame tracking may fail")
        end
    end
end

---Add dark background overlay to frame content (delegates to Utilities module)
---@param frame table Frame to darken
local function darkenContent(frame)
    if NextKey222.Utilities then
        NextKey222.Utilities:DarkenContent(frame)
    else
        if NextKey222.Debug and NextKey222.Debug.Error then
            NextKey222.Debug:Error("Utilities module not available - darkenContent may fail")
        end
    end
end

--- Determines if compact mode should be used based on player count (delegates to Utilities module)
-- @param playerCount number The total number of players/entries
-- @return boolean true if compact mode should be enabled
local function shouldUseCompactMode(playerCount)
    if NextKey222.Utilities then
        return NextKey222.Utilities:ShouldUseCompactMode(playerCount)
    end
    -- Fallback if module not loaded
    return playerCount > 5
end

--- Gets the dungeon alias for compact display (delegates to Utilities module)
-- @param dungeonID number The dungeon ID
-- @return string The short alias for the dungeon
local function getDungeonAlias(dungeonID)
    if NextKey222.Utilities then
        return NextKey222.Utilities:GetDungeonAlias(dungeonID)
    end
    -- Fallback if module not loaded
    return "UNK"
end

-- MARK: Main Frame Creation (delegated to MainWindow/UIControls)
-- ui/main.lua no longer owns frame construction; see:
-- - NextKey222.MainWindow:CreateMainFrame(ui)
-- - NextKey222.UIControls:AttachHeaderControls(ui, frame)

-- MARK: Frame Visibility Management
--
-- Functions responsible for showing, hiding, and managing the visibility
-- state of the main UI frame and related components.

-- NOTE: Legacy ShowMainFrame implementation superseded by facade at top of file.

--- Determines which UI mode should be displayed based on current group size
-- NOTE: UI mode detection and switching are handled by ViewManager
-- via ViewManager:detect_ui_mode() and ViewManager:on_group_roster_update(ui).
-- Legacy DetectUIMode / SwitchToUIMode implementations have been removed
-- to avoid divergence; UI facade delegates to ViewManager instead.

-- NOTE: Legacy OnGroupRosterUpdate implementation superseded by ViewManager:on_group_roster_update.

-- NOTE: Legacy ToggleMainFrame implementation superseded by facade at top of file.

-- Get fake player data (addon status, profiles) from DebugAdapter
function UI:GetFakePlayerData(playerName)
    if not playerName or not NextKey222.ProfilesService then
        return nil
    end

    -- Check if this is a fake player by getting their debug profile
    local debugProfile = NextKey222.ProfilesService:GetDebugProfile(playerName)
    if debugProfile and debugProfile.addonStatus then
        return debugProfile
    end

    return nil
end

function UI:GetPlayerProfileCached(playerName)
    if not playerName then return nil end
    self.profileCache = self.profileCache or {}
    if self.profileCache[playerName] then
        return self.profileCache[playerName]
    end

    -- Debug logging to track profile system calls
    if playerName:find("Ryuza") then
        if NextKey222.Debug then
            NextKey222.Debug:Dev("ui", string.format("GetPlayerProfileCached called for: %s, ProfilesService exists: %s",
                playerName,
                NextKey222.ProfilesService and "YES" or "NO"))
        end
    end

    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
        local profile = NextKey222.ProfilesService:GetProfile(playerName)
        
        -- Debug logging to track profile data
        if playerName:find("Ryuza") then
            if NextKey222.Debug then
                NextKey222.Debug:Dev("ui", string.format("Profile retrieved for %s: class=%s, role=%s, specName=%s, specID=%s",
                    playerName,
                    profile and profile.class or "nil",
                    profile and profile.role or "nil",
                    profile and profile.specName or "nil",
                    profile and profile.specID or "nil"))
            end
        end
        
        self.profileCache[playerName] = profile
        return profile
    end

    return nil
end

function UI:EnrichEntryMetadata(entry)
    if not entry or not entry.key then return end

    local ownerName = entry.key.ownerName or "Unknown"
    entry.ownerName = ownerName

    local normalizedName = NextKey222.UIComponents and NextKey222.UIComponents:NormalizePlayerName(ownerName) or ownerName
    entry.normalizedOwnerName = normalizedName

    local profile = self:GetPlayerProfileCached(normalizedName)

    -- Debug logging for Evoker role issue
    if ownerName:find("Ryuza") or (profile and profile.class == "EVOKER") then
        NextKey222.Debug:Dev("ui", string.format("EnrichEntryMetadata Debug: ownerName=%s, normalizedName=%s, profile=%s",
            ownerName, normalizedName, profile and "exists" or "nil"))
        if profile then
            NextKey222.Debug:Dev("ui", string.format("Profile Data: class=%s, role=%s, specName=%s, specID=%s",
                profile.class or "nil",
                profile.role or "nil",
                profile.specName or "nil",
                profile.specID or "nil"))
        end
    end

    entry.profile = profile
    entry.specName = profile and profile.specName or nil
    entry.specID = profile and profile.specID or nil
    
    -- PHASE 1: Diagnostic logging - track role determination in UI
    if NextKey222.Debug and (ownerName:find("Ryuza") or (profile and profile.class == "EVOKER")) then
        NextKey222.Debug:Dev("ui", string.format("EnrichEntryMetadata BEFORE role detection: ownerName=%s, specID=%s, profile.role=%s",
            ownerName, entry.specID or "nil", profile and profile.role or "nil"))
    end
    
    -- Use spec-to-role mapping for reliable role detection (same as tooltip)
    if entry.specID and NextKey222.UIComponents and NextKey222.UIComponents.GetRoleFromSpecID then
        entry.role = NextKey222.UIComponents:GetRoleFromSpecID(entry.specID, "DAMAGER")
        
        -- PHASE 1: Diagnostic logging - track GetRoleFromSpecID result
        if NextKey222.Debug and (ownerName:find("Ryuza") or (profile and profile.class == "EVOKER")) then
            NextKey222.Debug:Dev("ui", string.format("GetRoleFromSpecID(%d) returned: %s", entry.specID or -1, entry.role or "nil"))
        end
    else
        -- Fallback to profile role
        entry.role = (profile and profile.role) or "DAMAGER"
        -- Normalize role to uppercase to ensure consistency
        if entry.role then
            entry.role = string.upper(entry.role)
        end
        
        -- PHASE 1: Diagnostic logging - track fallback usage
        if NextKey222.Debug and (ownerName:find("Ryuza") or (profile and profile.class == "EVOKER")) then
            NextKey222.Debug:Dev("ui", string.format("FALLBACK to profile.role: %s (normalized to %s)",
                profile and profile.role or "nil", entry.role))
        end
    end
    
    -- PHASE 1: Diagnostic logging - final role value for UI display
    if NextKey222.Debug and (ownerName:find("Ryuza") or (profile and profile.class == "EVOKER")) then
        NextKey222.Debug:Dev("ui", string.format("EnrichEntryMetadata COMPLETE: final entry.role = %s (will be used for icon display)",
            entry.role or "nil"))
    end

    local classToken = entry.key.class or (profile and profile.class)
    local specID = profile and profile.specID

    entry.hasHeroism = self:PlayerProvidesHeroism(profile, classToken, specID)
    entry.hasBattleRes = self:PlayerProvidesBattleRes(profile, classToken, specID)

    if entry.key.dungeonID then
        entry.dungeonName = NextKey222.Addon:GetDungeonName(entry.key.dungeonID) or ("Dungeon " .. entry.key.dungeonID)
    else
        entry.dungeonName = "No Dungeon"
    end
    entry.keyLevel = entry.key.level or 0

    local expected = entry.ioGainRange and entry.ioGainRange.expected or entry.ioGainPotential or 0
    entry.expectedGain = expected or 0

    if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
        local breakdown = entry.ioGainRange.playerBreakdown[normalizedName]
        if breakdown then
            entry.currentDungeonIO = breakdown.current or 0
        end
    end

    if not entry.currentDungeonIO then
        if NextKey222.IOCalculator and entry.key.dungeonID then
            entry.currentDungeonIO = NextKey222.IOCalculator:GetPlayerDungeonScore(normalizedName, entry.key.dungeonID) or 0
        else
            entry.currentDungeonIO = 0
        end
    end

    if entry.profile and entry.profile.capabilities then
        if entry.profile.capabilities.heroism then
            entry.hasHeroism = true
        end
        if entry.profile.capabilities.battleRes then
            entry.hasBattleRes = true
        end
    end
end

--- Schedules a debounced render to prevent lag from rapid updates
-- Cancels any pending render and schedules a new one after a short delay
-- This prevents multiple rapid changes (like adding 5 fake players) from triggering 5 immediate re-renders
function UI:ScheduleRender()
    -- Cancel any pending render
    if self.pendingRenderTimer then
        self.pendingRenderTimer:Cancel()
        self.pendingRenderTimer = nil
    end
    
    -- Schedule new render after delay
    self.pendingRenderTimer = C_Timer.NewTimer(self.renderDebounceDelay, function()
        self.pendingRenderTimer = nil
        
        -- Refresh keystone window
        if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
            if self.RenderResults then
                self:RenderResults()
            end
        end
        
        -- Refresh dungeon window
        if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
            NextKey222.DungeonWindow:Render()
        end
    end)
end

-- REMOVED: HandleAddDebugFakePlayer, HandleDeleteAllFakePlayers, HandleDeleteFakePlayer
-- Fake player management is now exclusively handled through the options menu
-- Fake Player Tools tab. No fake player controls appear in the main UI.


--- Shared tooltip handler for IO gain displays (delegates to Tooltips module)
-- @param button Frame Button or region triggering the tooltip
-- @param keyInfo table Keystone data for the row
-- @param entry table Row entry containing cached ioRange (optional)
-- @param ioRange table Range data (min/max/expected + playerBreakdown)
function UI:ShowIOGainTooltip(button, keyInfo, entry, ioRange)
    if NextKey222.Tooltips then
        return NextKey222.Tooltips:ShowIOGainTooltip(self, button, keyInfo, entry, ioRange)
    end
    -- Fallback if module not loaded
    Debug:Error("Tooltips module not available")
end

--- Shows IO gain tooltip using the centralized tooltip system (delegates to Tooltips module)
-- @param button Frame Button or region triggering the tooltip
-- @param keyInfo table Keystone data for the row
-- @param entry table Row entry containing cached ioRange (optional)
-- @param ioRange table Range data (min/max/expected + playerBreakdown)
function UI:ShowIOGainTooltipCentralized(button, keyInfo, entry, ioRange)
    if NextKey222.Tooltips then
        return NextKey222.Tooltips:ShowIOGainTooltipCentralized(self, button, keyInfo, entry, ioRange)
    end
    -- Fallback if module not loaded
    Debug:Error("Tooltips module not available")
end

--- Builds the title for IO gain tooltip (delegates to Tooltips module)
-- @param keyInfo table Keystone data
-- @param ioRange table IO range data
-- @return string Formatted title
function UI:BuildIOTooltipTitle(keyInfo, ioRange)
    if NextKey222.Tooltips then
        return NextKey222.Tooltips:BuildIOTooltipTitle(keyInfo, ioRange)
    end
    -- Fallback if module not loaded
    Debug:Error("Tooltips module not available")
    return "Unknown Key"
end

--- Builds the player breakdown for IO gain tooltip (delegates to Tooltips module)
-- @param keyInfo table Keystone data
-- @param ioRange table IO range data
-- @return table Formatted breakdown data
function UI:BuildIOTooltipBreakdown(keyInfo, ioRange)
    if NextKey222.Tooltips then
        return NextKey222.Tooltips:BuildIOTooltipBreakdown(self, keyInfo, ioRange)
    end
    -- Fallback if module not loaded
    Debug:Error("Tooltips module not available")
    return {}
end

--- Builds the totals section for IO gain tooltip (delegates to Tooltips module)
-- @param keyInfo table Keystone data
-- @param ioRange table IO range data
-- @return table Formatted totals data
function UI:BuildIOTooltipTotals(keyInfo, ioRange)
    if NextKey222.Tooltips then
        return NextKey222.Tooltips:BuildIOTooltipTotals(self, keyInfo, ioRange)
    end
    -- Fallback if module not loaded
    Debug:Error("Tooltips module not available")
    return nil
end

-- MARK: Individual Player Analysis
--
-- Functions for analyzing and displaying individual player IO improvement potential

-- Individual Player Recommendations function removed - no longer needed
-- Now focusing on group-based keystone ranking by IO gain potential

-- MARK: Data Management

-- Create dungeon ranking system (1-8) for cross-addon comparison
-- NOTE: Legacy experimental dungeon ranking helpers (GetDungeonRankings,
-- CompareDungeonRankings, FindNextKeyIDFromRaiderIO) have been removed
-- from the UI facade. Scoring and ranking responsibilities belong to
-- dedicated scoring/IO modules per the refactor plan.



-- Get RaiderIO keystone levels as fallback for score estimation


-- Find NextKey dungeon ID from RaiderIO dungeon data
-- (see note above regarding removed RaiderIO name-mapping helpers)

-- MARK: Sorting
--
-- Functions responsible for sorting keystone data, managing display modes,
-- and organizing data for presentation in the UI.

--- Sorts keystone entries based on the specified mode
-- @param keys table The keystone data to sort
-- @param mode string The sorting mode ('level', 'score', 'name', etc.)
-- @return table Sorted array of keystone entries
function UI:SortKeys(keys, mode)
    local sorted = {}
    for _, key in ipairs(keys) do
        table.insert(sorted, { key = key })
    end

    if mode == "HighestKeyLevel" then
        table.sort(sorted, function(a, b)
            return (a.key.level or 0) > (b.key.level or 0)
        end)
    elseif mode == "LowestKeyLevel" then
        table.sort(sorted, function(a, b)
            return (a.key.level or 0) < (b.key.level or 0)
        end)
    elseif mode == "IOGainPotential" then
        -- Calculate IO gain range for each key (includes expected value)
        for _, item in ipairs(sorted) do
            item.ioGainRange = self:CalculateIOGainRange(item.key)
            item.ioGainPotential = item.ioGainRange.expected -- For backward compatibility
        end
        table.sort(sorted, function(a, b)
            return (a.ioGainPotential or 0) > (b.ioGainPotential or 0)
        end)
    end

    return sorted
end

--- Updates sort dropdown options based on current view mode
function UI:UpdateSortDropdownOptions()
    if not self.sortDropdown then
        return
    end
    
    if self.viewMode == "dungeons" then
        -- Dungeon view: Alphabetical, Highest IO, Lowest IO
        self.sortDropdown:SetList({
            Alphabetical = "Alphabetical",
            HighestIO = "Highest IO Score", 
            LowestIO = "Lowest IO Score"
        })
        -- Set default sort for dungeons if current sort isn't valid
        local currentSort = self:GetCurrentSortMode()
        if currentSort ~= "Alphabetical" and currentSort ~= "HighestIO" and currentSort ~= "LowestIO" then
            self:SetCurrentSortMode("Alphabetical")
            self.sortDropdown:SetValue("Alphabetical")
        end
    else
        -- Keystone view: original options
        self.sortDropdown:SetList({ 
            HighestKeyLevel = "Highest Key Level", 
            LowestKeyLevel = "Lowest Key Level",
            IOGainPotential = "IO Gain Potential"
        })
        -- Set default sort for keystones if current sort isn't valid
        local currentSort = self:GetCurrentSortMode()
        if currentSort ~= "HighestKeyLevel" and currentSort ~= "LowestKeyLevel" and currentSort ~= "IOGainPotential" then
            self:SetCurrentSortMode("HighestKeyLevel")
            self.sortDropdown:SetValue("HighestKeyLevel")
        end
    end
end

-- MARK: Main Rendering Functions
--
-- Core functions responsible for rendering the primary UI content,
-- including keystone lists, player cards, and dungeon information.

-- Legacy inline RenderResults implementation has been replaced by the
-- facade definition near the top of this file, which delegates to
-- NextKey222.UIRendering with a SafeRun-wrapped fallback path.
-- No additional RenderResults implementation is defined here.

-- MARK: Keystone Card Rendering
--
-- Functions responsible for creating and displaying individual keystone cards
-- with player information, scores, and interactive elements.

--- Creates and renders a keystone card for a single player entry (delegates to KeystoneCards module)
-- @param entry table The keystone data containing player info, key details, and scores
-- Handles both real player keystones and fake player data for testing
function UI:AddKeyRow(entry)
    if NextKey222.KeystoneCards then
        return NextKey222.KeystoneCards:AddKeyRow(self, entry)
    end
    -- Fallback if module not loaded
    Debug:Error("KeystoneCards module not available")
end

--- Creates and renders a compact keystone card for high player counts
-- @param entry table The keystone data containing player info, key details, and scores
-- Uses aliases and condensed layout to save vertical space
function UI:AddKeyRowCompact(entry)
    if NextKey222.KeystoneCards then
        return NextKey222.KeystoneCards:AddKeyRowCompact(self, entry)
    end
    -- Fallback if module not loaded
    Debug:Error("KeystoneCards module not available")
end

-- MARK: Cleanup & Utility Functions
--
-- Helper functions for frame management, cleanup, and auxiliary operations.

-- MARK: Cleanup & Utility Functions

function UI:ClearAuxFrames()
    -- NOTE: Do NOT call FrameRegistry:ClearAll() here - it's shared with the dungeon window
    -- and would clear frames from both windows. FrameRegistry should only be cleared on window close.
    -- The resultsFrame:ReleaseChildren() call in rendering is sufficient for clearing UI content.
    
    if self._auxFrames then
        for _, frame in ipairs(self._auxFrames) do
            if frame and frame.Hide then
                frame:Hide()
                frame:SetParent(nil)
            end
        end
        wipe(self._auxFrames)
    end
end

-- NOTE: RefreshKeystoneList facade is defined near the top of this file.
-- The duplicate legacy implementation has been removed to avoid divergence.

-- MARK: View Mode Management
--
-- Functions for switching between different display modes (players vs dungeons)
-- and managing the related UI state and button text updates.

-- NOTE: View mode switching is handled by NextKey222.ViewManager:toggle_view_mode(ui).

--- Toggles between party-only and guild-wide keystone filtering
-- Updates the button text and triggers keystone refresh
function UI:ToggleGuildFilter()
    self.showGuildKeys = not self.showGuildKeys
    if self.guildToggleBtn then
        self.guildToggleBtn:SetText(self.showGuildKeys and "Guild Keys" or "Party Keys")
    end
    
    Debug:Dev("ui", "Guild filter toggled:", self.showGuildKeys and "showing guild keys" or "showing party only")
    
    -- When switching to guild mode, request guild keystones
    if self.showGuildKeys then
        Debug:Dev("ui", "Switching to guild mode, requesting guild keystones...")
        
        -- Use centralized Keystones module for requests (includes throttling)
        local success = false
        if NextKey222.Keystones and NextKey222.Keystones.RequestGuildKeystones then
            success = NextKey222.Keystones:RequestGuildKeystones()
            Debug:Dev("ui", "Guild keystone request:", success and "sent" or "throttled/failed")
        end
        
        -- Clear cached keystones to force refresh
        local NextKey = NextKey222.Addon
        if NextKey then
            NextKey.cachedKeys = nil
        end
        
        -- Single delayed refresh to catch incoming data
        -- The throttling in Keystones:RequestGuildKeystones prevents spam
        local function refreshUI()
            Debug:Dev("ui", "Refreshing UI after guild keystone request")
            
            -- Refresh keystone window
            if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
                if self.RenderResults then
                    self:RenderResults()
                end
            end
            
            -- Refresh dungeon window
            if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
                NextKey222.DungeonWindow:Render()
            end
        end
        
        -- Refresh after a delay to allow keystones to arrive
        C_Timer.After(2.0, refreshUI)
    else
        -- Immediate refresh when switching to party mode
        Debug:Dev("ui", " Switching to party mode")
        -- Refresh keystone window
        if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
            if self.RenderResults then
                self:RenderResults()
            end
        end
        
        -- Refresh dungeon window
        if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
            NextKey222.DungeonWindow:Render()
        end
    end
end

-- MARK: Dungeon Card Rendering
--
-- Functions for rendering dungeon information cards including scores,
-- levels, and seasonal data for each available dungeon.

--- REMOVED: RenderDungeonCards and AddDungeonRowCompact
-- Dungeon rendering now handled by independent NextKey222.DungeonWindow module
-- See ui/dungeonWindow.lua

function UI:RenderDungeonCards()
    -- Deprecated: delegate to DungeonWindow module
    if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
        NextKey222.DungeonWindow:Render()
    end
end

function UI:AddDungeonRowCompact(dungeonID, dungeonData)
    -- Deprecated: delegate to DungeonWindow module
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:RenderDungeonCard(dungeonID, dungeonData)
    end
end

function UI:AddDungeonRow(dungeonID, dungeonData)
    -- Deprecated: delegate to DungeonWindow module
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:RenderDungeonCard(dungeonID, dungeonData)
    end
end

-- MARK: Score & Data Functions Moved
-- Score functions moved to core/scoring.lua
-- ID conversion functions moved to core/utils.lua

--- Gets appropriate color for individual dungeon scores (delegates to ScoreCalculations module)
-- @param score number The individual dungeon IO score
-- @return table RGB color values {r, g, b} (0-1)
function UI:GetDungeonScoreColor(score)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonScoreColor(score)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return {0.5, 0.5, 0.5}
end

--- Gets the best level and chests for a dungeon (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID
-- @return number, number level, chests (0 if not found)
function UI:GetDungeonLevelAndChests(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonLevelAndChests(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0, 0
end

--- Formats total IO score with appropriate coloring (delegates to ScoreCalculations module)
-- @param totalScore number The total IO score
-- @return string Colored total score text
function UI:FormatColoredTotalScore(totalScore)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:FormatColoredTotalScore(totalScore)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return "|cFF808080Total IO: 0|r"
end

--- Retrieves the player's best score for a specific dungeon
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
--- Helper function to get dungeon score from WoW API (MrMythical approach)
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score for this dungeon from WoW API (0 if none)
--- Retrieves the player's best score for a specific dungeon (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
function UI:GetRaiderIODungeonScore(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetRaiderIODungeonScore(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

--- Retrieves the player's best score for a specific dungeon (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
function UI:GetDungeonScore(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonScore(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

--- Helper function to get best key level from RaiderIO profile data
-- @param dungeonID number The dungeon ID to get the level for
-- @return number The best key level for this dungeon from RaiderIO data (0 if none)
--- Helper function to get best key level from RaiderIO profile data (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID to get the level for
-- @return number The best key level for this dungeon from RaiderIO data (0 if none)
function UI:GetRaiderIOBestLevel(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetRaiderIOBestLevel(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

--- Retrieves the player's best key level for a specific dungeon
-- @param dungeonID number The dungeon ID to get the best level for
-- @return number The highest key level completed for this dungeon (0 if none)
--- Retrieves the player's best key level for a specific dungeon (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID to get the best level for
-- @return number The highest key level completed for this dungeon (0 if none)
function UI:GetBestLevel(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetBestLevel(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

--- Retrieves the player's IO score contribution from a specific dungeon
-- @param dungeonID number The dungeon ID to get the IO score for
-- @return number The IO score from this dungeon (0 if none)
--- Retrieves the player's IO score contribution from a specific dungeon (delegates to ScoreCalculations module)
-- @param dungeonID number The dungeon ID to get the IO score for
-- @return number The IO score from this dungeon (0 if none)
function UI:GetDungeonIOScore(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonIOScore(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

-- MARK: IO Calculation Functions Moved
-- IO calculation logic moved to core/ioCalculator.lua
-- Dungeon preference functions moved to core/profiles.lua

--- Calculate IO gain range for a keystone (backwards-compatible wrapper)
-- Delegates to NextKey222.UICalculations to keep logic centralized.
-- @param keystoneData table The keystone data (with dungeonID, level, ownerName)
-- @return table IO gain range with min, max, expected values
function UI:CalculateIOGainRange(keystoneData)
    if NextKey222.UICalculations then
        return NextKey222.UICalculations:calculate_io_gain_range(keystoneData, {
            party_hash = self.partyCompositionHash,
            party_profiles = self.cachedPartyProfiles,
        })
    end

    -- Fallback to preserve safety if module missing
    if not keystoneData or not NextKey222.IOCalculator then
        return { min = 0, max = 0, expected = 0 }
    end

    local partyProfiles = self.cachedPartyProfiles
    if not partyProfiles then
        local partyMembers = NextKey222.Addon and NextKey222.Addon:GetPartyMemberNames() or {}
        partyProfiles = {}
        for _, memberName in pairs(partyMembers) do
            if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
                partyProfiles[memberName] = NextKey222.ProfilesService:GetProfile(memberName)
            else
                partyProfiles[memberName] = { playerName = memberName }
            end
        end
    end

    local groupRange = NextKey222.IOCalculator:CalculateGroupIORange(keystoneData, partyProfiles)
    local result = {
        min = 0,
        max = 0,
        expected = 0,
    }
    if groupRange then
        result.min = groupRange.min or 0
        result.max = groupRange.max or 0
        result.expected = groupRange.expected or 0
        result.playerBreakdown = groupRange.playerBreakdown
    end
    return result
end

--- Generates a hash of current party composition for cache invalidation
-- Backwards-compatible wrapper delegating to UICalculations.
-- @return string Hash representing current party members
function UI:GetPartyCompositionHash()
    if NextKey222.UICalculations then
        return NextKey222.UICalculations:get_party_composition_hash()
    end

    local partyMembers = NextKey222.Addon and NextKey222.Addon:GetPartyMemberNames() or {}
    
    local sortedNames = {}
    for _, name in pairs(partyMembers) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)
    
    return table.concat(sortedNames, "|")
end

--- Generates a hash of keystone list for render skipping
-- Backwards-compatible wrapper delegating to UICalculations.
-- @param keys table List of keystones
-- @return string Hash representing keystone state
function UI:GetKeystoneListHash(keys)
    if NextKey222.UICalculations then
        return NextKey222.UICalculations:get_keystone_list_hash(keys)
    end

    if not keys or #keys == 0 then
        return "empty"
    end

    local sortedKeys = {}
    for _, key in ipairs(keys) do
        table.insert(sortedKeys, string.format("%s:%d:%d",
            key.ownerName or "unknown",
            key.dungeonID or 0,
            key.level or 0))
    end
    table.sort(sortedKeys)

    return table.concat(sortedKeys, "|")
end

--- Helper to count table entries (delegates to Utilities module)
-- @param t table The table to count
-- @return number Entry count
function UI:CountTable(t)
    if NextKey222.Utilities then
        return NextKey222.Utilities:CountTable(t)
    end
    -- Fallback if module not loaded
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

--- Calculates group IO gain totals at key breakpoints (untimed/timed/+2/+3)
-- @param keyInfo table Keystone information (expects .level and .dungeonID)
-- @param playerBreakdown table Map of playerName -> { current, range = {min, expected, max} }
-- @return table|nil { untimed={total,average}, timed={...}, plus2={...}, plus3={...} }
function UI:CalculateBreakpointRanges(keyInfo, playerBreakdown)
    if not keyInfo or not playerBreakdown or not NextKey222.IOCalculator then
        return nil
    end

    local level = tonumber(keyInfo.level) or 0
    if level <= 0 then return nil end

    local count = 0
    local totals = { untimed = 0, timed = 0, plus2 = 0, plus3 = 0 }

    for _, pdata in pairs(playerBreakdown) do
        count = count + 1
        local pr = pdata.range or {}

        -- Use per-player range for untimed/timed/+3 directly (consistent with IOCalculator)
        local minGain = tonumber(pr.min) or 0
        local expectedGain = tonumber(pr.expected) or 0
        local maxGain = tonumber(pr.max) or 0

        totals.untimed = totals.untimed + math.max(0, minGain)
        totals.timed   = totals.timed   + math.max(0, expectedGain)
        totals.plus3   = totals.plus3   + math.max(0, maxGain)

        -- For +2, linearly interpolate the gain between timed (20% bonus) and 3-chest (40% bonus)
        local timedGainClamped = math.max(0, expectedGain)
        local maxGainClamped = math.max(timedGainClamped, maxGain)
        local gainPlus2 = timedGainClamped + (maxGainClamped - timedGainClamped) * 0.5
        totals.plus2 = totals.plus2 + gainPlus2
    end

    if count == 0 then return nil end

    return {
        untimed = { total = totals.untimed, average = totals.untimed / count },
        timed   = { total = totals.timed,   average = totals.timed   / count },
        plus2   = { total = totals.plus2,   average = totals.plus2   / count },
        plus3   = { total = totals.plus3,   average = totals.plus3   / count },
    }
end

-- (IsMainFrameVisible facade is defined near the top of the file)

-- NOTE: RefreshResults throttling/scan logic now lives in the facade
-- implementation near the top of this file and delegated modules.
-- This legacy inline implementation has been removed to avoid divergence.

-- MARK: PHASE 3 - Frame Pacing System
-- Thin wrappers delegating frame pacing behavior to NextKey222.UIPerformance.
-- Keeps ui/main.lua free of pacing internals.

--- Queues rendering work to be processed across multiple frames.
-- NOTE: QueueFramePacedRender facade is defined near the top of this file.
-- The duplicate legacy implementation has been removed to avoid divergence.

--- Starts the frame pacing update loop (compatibility wrapper).
function UI:StartFramePacing()
    if NextKey222.UIPerformance then
        NextKey222.UIPerformance:StartFramePacing(self)
    end
end

--- Processes frame-paced work (compatibility wrapper).
function UI:ProcessFramePacing()
    if NextKey222.UIPerformance then
        NextKey222.UIPerformance:ProcessFramePacing(self)
    end
end

--- Executes a work item from the queue (compatibility wrapper).
function UI:ExecuteWorkItem(work)
    if NextKey222.UIPerformance then
        NextKey222.UIPerformance:ExecuteWorkItem(self, work)
    end
end

--- Executes a render item from the queue (compatibility wrapper).
function UI:ExecuteRenderItem(render)
    if NextKey222.UIPerformance then
        NextKey222.UIPerformance:ExecuteRenderItem(self, render)
    end
end

--- Prepares data for rendering without expensive UI operations.
-- This remains UI-specific but is invoked by UIPerformance.
function UI:PrepareRenderData()
    if NextKey222.UI then
        NextKey222.UI.profileCache = {}
    end

    if NextKey and NextKey.Keystones and NextKey.Keystones.ScanAllKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanAllKeystones, "Prepare keystone scan")
    end

    Debug:Dev("ui", "Prepared render data")
end

--- Stops the frame pacing system (compatibility wrapper).
function UI:StopFramePacing()
    if NextKey222.UIPerformance then
        NextKey222.UIPerformance:StopFramePacing(self)
    end
end

--- Checks if the current sort mode is affected by party composition changes
-- @return boolean true if party changes should trigger a refresh
function UI:IsPartySensitiveSortMode()
    local currentMode = self:GetCurrentSortMode()
    return currentMode == "IOGainPotential"
end

-- MARK: Configuration & Settings Management
--
-- Functions for managing UI configuration settings including sort modes,
-- preferences, and initialization state.

--- Gets the current keystone sorting mode from saved variables
-- @return string The current sort mode (default: "HighestKeyLevel")
function UI:GetCurrentSortMode()
    return NextKey.db and NextKey.db.char and NextKey.db.char.sortMode or "HighestKeyLevel"
end

--- Sets the current keystone sorting mode in saved variables
-- @param mode string The sort mode to set
function UI:SetCurrentSortMode(mode)
    if NextKey.db and NextKey.db.char then
        NextKey.db.char.sortMode = mode
    end
end

-- MARK: Fake Keystone Teleport System
--
-- Uses the existing working keystone selection logic for dungeon teleports

-- MARK: Module Initialization
--
-- Initialization function called during addon startup to prepare the UI module.

--- Initializes the UI module (Phase 7: Enhanced with dynamic configuration context)
-- Called during addon startup to set up the UI system
-- @return boolean true if initialization succeeded
-- NOTE: Initialize facade implemented near top of file; legacy inline initialization removed.

--- Handles specialization changes for current player and party members
-- @param unitID string Unit identifier ("player", "party1", "party2", etc.)
function UI:OnSpecChanged(unitID)
    -- Get player name from unit ID
    local playerName
    if not unitID or unitID == "player" then
        playerName = UnitName("player") .. "-" .. GetRealmName()
    else
        local name, realm = UnitName(unitID)
        if name then
            realm = realm or GetRealmName()
            playerName = name .. "-" .. realm
        end
    end
    
    if not playerName then
        Debug:Dev("ui", "OnSpecChanged: Could not determine player name from unitID:", unitID or "nil")
        return
    end
    
    Debug:Dev("ui", "OnSpecChanged: Handling spec change for", playerName)
    
    -- Invalidate cache for this specific player
    if NextKey222.ProfilesService then
        NextKey222.ProfilesService:InvalidatePlayerCache(playerName)
        Debug:Dev("ui", "Invalidated profile cache for", playerName)
    end
    
    -- Clear UI's profile cache for this player
    if self.profileCache then
        self.profileCache[playerName] = nil
        Debug:Dev("ui", "Cleared UI profile cache for", playerName)
    end
    
    -- If main frame is open and visible, refresh the display after a short delay
    -- This gives the profile system time to fetch updated data
    if self.mainFrame and self.mainFrame:IsShown() then
        C_Timer.After(0.15, function()
            -- Refresh whichever windows are open
            if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
                if self.RenderResults then
                    local previous_results = self.resultsFrame
                    self.resultsFrame = self.keystoneWindow.resultsFrame
                    self:RenderResults()
                    self.resultsFrame = previous_results
                end
            end
            
            if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
                NextKey222.DungeonWindow:Render()
            end
            Debug:Dev("ui", "UI refreshed after spec change for", playerName)
        end)
    end
end

-- NOTE:
-- UI-related debug/test slash commands have been moved into NextKey222.UIDebugHelpers
-- via UIDebugHelpers:RegisterSlashCommands(). No SLASH_* handlers are declared here.

-- MARK: Loot Window Integration
-- Handle loot button clicks from dungeon cards

function NextKey:HandleLootClick(dungeonID, dungeonData)
    if not self.LootWindow then
        NextKey222.Debug:Error("LootWindow module not available")
        return
    end
    
    NextKey222.Debug:Dev("ui", "Opening loot window for dungeon:", dungeonID, dungeonData.name)
    self.LootWindow:Show(dungeonID)
end

return UI


