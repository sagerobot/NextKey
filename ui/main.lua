local _, NextKey222 = ...
local HEROISM_CLASSES = {
    SHAMAN = true,
    MAGE = true,
    EVOKER = true
}

local BATTLE_RES_CLASSES = {
    DRUID = true,
    WARLOCK = true,
    DEATHKNIGHT = true
}

local SPEC_CAPABILITIES_UI = {
    [62] = { heroism = true },
    [63] = { heroism = true },
    [64] = { heroism = true },
    [262] = { heroism = true },
    [263] = { heroism = true },
    [264] = { heroism = true },
    [1467] = { heroism = true },
    [1468] = { heroism = true },
    [1473] = { heroism = true },
    [253] = { heroism = true },

    [102] = { battleRes = true },
    [103] = { battleRes = true },
    [104] = { battleRes = true },
    [105] = { battleRes = true },
    [250] = { battleRes = true },
    [251] = { battleRes = true },
    [252] = { battleRes = true },
    [265] = { battleRes = true },
    [266] = { battleRes = true },
    [267] = { battleRes = true }
}

local NextKey = NextKey222.Addon
local AceGUI = LibStub("AceGUI-3.0")
-- Debug is available as global variable from debugService.lua

-- UI module with view mode state
local UI = {
    viewMode = "keystones", -- "keystones" or "dungeons" - controls what cards are displayed
    showGuildKeys = false, -- false = party only, true = guild keys (start with party only)
    mainFrame = nil,      -- Main AceGUI window frame
    resultsFrame = nil,   -- Container for player/dungeon cards
    viewToggleBtn = nil,  -- Button to switch between views
    guildToggleBtn = nil, -- Button to toggle guild/party filter
    debugFakeTierSelection = "random",
    suggestionMode = "auto" -- "auto", "best_key", or "best_groups"
}
NextKey222.UI = UI
NextKey222.RegisterModule("UI", UI)

--- Determines whether debug mode is currently enabled
-- @return boolean true if global debug flag is enabled
function UI:IsDebugMode()
    if not NextKey then
        Debug:Trace("ui", "IsDebugMode: NextKey is nil")
        return false
    end

    if NextKey.EnsureDebug then
        local dbg = NextKey:EnsureDebug()
        Debug:Trace("ui", "IsDebugMode: NextKey.EnsureDebug exists, dbg.enabled =", dbg and dbg.enabled)
        return dbg and dbg.enabled == true
    end

    local debugEnabled = NextKey222.Debug and NextKey222.Debug.enabled == true
    Debug:Trace("ui", "IsDebugMode: NextKey222.Debug.enabled =", NextKey222.Debug and NextKey222.Debug.enabled, "result =", debugEnabled)
    return debugEnabled
end

--- Determines if debug-only controls should be visible
-- @return boolean true when debug mode is active and the fake player service exists and not in dungeon view
function UI:ShouldShowDebugControls()
    local isDebug = self:IsDebugMode()
    local hasFakeService = NextKey222.FakePlayerService ~= nil
    local isNotDungeonView = self.viewMode ~= "dungeons"
    local result = isDebug and hasFakeService and isNotDungeonView
    Debug:Dev("ui", "ShouldShowDebugControls: isDebug =", isDebug, "hasFakeService =", hasFakeService, "isNotDungeonView =", isNotDungeonView, "result =", result)
    return result
end

--- Determines if keystone-specific controls should be visible
-- @return boolean true when in keystone view (not dungeon view)
function UI:ShouldShowKeystoneControls()
    local isNotDungeonView = self.viewMode ~= "dungeons"
    Debug:Dev("ui", "ShouldShowKeystoneControls: isNotDungeonView =", isNotDungeonView)
    return isNotDungeonView
end

--- Applies the appropriate window height based on the current view and debug state
function UI:ApplyWindowHeight()
    if not self.mainFrame or not NextKey222.UIConfig then
        return
    end

    local height = NextKey222.UIConfig:GetWindowHeight(self.viewMode or "keystones", {
        isDebugMode = self:ShouldShowDebugControls()
    })

    self.mainFrame:SetHeight(height)
end

--- Applies configurable spacing between controls and the results list
function UI:ApplyResultsTopPadding()
    if not self.resultsSpacer or not self.resultsSpacer.SetHeight then
        return
    end

    local padding = 0
    if NextKey222.UIConfig and NextKey222.UIConfig.LAYOUT then
        local cfgPadding = NextKey222.UIConfig.LAYOUT.RESULTS_TOP_PADDING
        if type(cfgPadding) == "number" then
            padding = math.max(cfgPadding, 0)
        end
    end

    self.resultsSpacer:SetHeight(padding)
    if self.resultsSpacer.frame then
        self.resultsSpacer.frame:SetHeight(padding)
    end
end

--- Shows or hides debug-specific widgets and reapplies layout
-- Dynamically adds or removes debug container based on debug mode state
function UI:UpdateDebugControlsVisibility()
    if not self.controlsContainer or not self.debugControlsContainer then
        Debug:Dev("ui", "UpdateDebugControlsVisibility: Missing containers")
        return
    end
    
    local showDebug = self:ShouldShowDebugControls()
    
    -- Check if debug container is currently in the layout
    local isInLayout = false
    if self.controlsContainer.children then
        for _, child in ipairs(self.controlsContainer.children) do
            if child == self.debugControlsContainer then
                isInLayout = true
                break
            end
        end
    end
    
    Debug:Dev("ui", "UpdateDebugControlsVisibility: showDebug =", showDebug, "isInLayout =", isInLayout)
    
    if showDebug and not isInLayout then
        -- Add debug container to layout
        Debug:Dev("ui", "Adding debug controls to layout")
        self.controlsContainer:AddChild(self.debugControlsContainer)
        
    elseif not showDebug and isInLayout then
        -- Remove debug container from layout
        Debug:Dev("ui", "Removing debug controls from layout")
        
        -- Find the position of debug container in children
        local debugIndex = nil
        for i, child in ipairs(self.controlsContainer.children) do
            if child == self.debugControlsContainer then
                debugIndex = i
                break
            end
        end
        
        if debugIndex then
            -- Remove from children array
            table.remove(self.controlsContainer.children, debugIndex)
            
            -- Hide the container's frame
            if self.debugControlsContainer.frame then
                self.debugControlsContainer.frame:Hide()
                self.debugControlsContainer.frame:SetParent(nil)
            end
        end
    end
    
    -- Update layouts
    if self.controlsContainer.DoLayout then
        self.controlsContainer:DoLayout()
        Debug:Dev("ui", "Controls container layout updated")
    end
    
    if self.mainFrame then
        self:ApplyWindowHeight()
        if self.mainFrame.DoLayout then
            self.mainFrame:DoLayout()
        end
        Debug:Dev("ui", "Main frame layout updated")
    end
end

--- Shows or hides keystone-specific controls based on view mode
-- Handles visibility of Suggest Groups, Auto Mode, and Guild/Party toggle buttons
function UI:UpdateKeystoneControlsVisibility()
    if not self.mainFrame then
        Debug:Dev("ui", "UpdateKeystoneControlsVisibility: Main frame not available")
        return
    end
    
    if not self.controlsContainer then
        Debug:Dev("ui", "UpdateKeystoneControlsVisibility: Controls container not available")
        return
    end
    
    local showKeystoneControls = self:ShouldShowKeystoneControls()
    Debug:Dev("ui", "UpdateKeystoneControlsVisibility: showKeystoneControls =", showKeystoneControls, "cachedItemsCount =", self.cachedItemsCount)
    
    -- Handle Suggest Groups button (add/remove from layout like debug controls)
    if self.suggestGroupsBtn then
        local shouldShow = showKeystoneControls and self.cachedItemsCount and self.cachedItemsCount >= 6
        
        -- Check if button is currently in the layout
        local isInLayout = false
        if self.controlsContainer.children then
            for _, child in ipairs(self.controlsContainer.children) do
                if child == self.suggestGroupsBtn then
                    isInLayout = true
                    break
                end
            end
        end
        
        Debug:Dev("ui", "Suggest Groups button: shouldShow =", shouldShow, "isInLayout =", isInLayout)
        
        if shouldShow and not isInLayout then
            -- Add button to layout at the correct position (after guild toggle button)
            Debug:Dev("ui", "Adding Suggest Groups button to layout")
            
            -- Re-parent the button to the controls container
            if self.suggestGroupsBtn.frame then
                self.suggestGroupsBtn.frame:SetParent(self.controlsContainer.frame)
                self.suggestGroupsBtn.frame:Show()
            end
            
            -- Find the position to insert (after guild toggle button)
            local insertPosition = 1
            if self.controlsContainer.children then
                for i, child in ipairs(self.controlsContainer.children) do
                    if child == self.guildToggleBtn then
                        insertPosition = i + 1
                        break
                    end
                end
            end
            
            table.insert(self.controlsContainer.children, insertPosition, self.suggestGroupsBtn)
        elseif not shouldShow and isInLayout then
            -- Remove button from layout
            Debug:Dev("ui", "Removing Suggest Groups button from layout")
            local buttonIndex = nil
            for i, child in ipairs(self.controlsContainer.children) do
                if child == self.suggestGroupsBtn then
                    buttonIndex = i
                    break
                end
            end
            
            if buttonIndex then
                table.remove(self.controlsContainer.children, buttonIndex)
                if self.suggestGroupsBtn.frame then
                    self.suggestGroupsBtn.frame:Hide()
                    self.suggestGroupsBtn.frame:SetParent(nil)
                end
            end
        end
    end
    
    -- Handle Suggestion Mode button (add/remove from layout like debug controls)
    if self.suggestionModeBtn then
        local shouldShow = showKeystoneControls and self.cachedItemsCount and self.cachedItemsCount >= 6
        
        -- Check if button is currently in the layout
        local isInLayout = false
        if self.controlsContainer.children then
            for _, child in ipairs(self.controlsContainer.children) do
                if child == self.suggestionModeBtn then
                    isInLayout = true
                    break
                end
            end
        end
        
        Debug:Dev("ui", "Suggestion Mode button: shouldShow =", shouldShow, "isInLayout =", isInLayout)
        
        if shouldShow and not isInLayout then
            -- Add button to layout at the correct position (after suggest groups button)
            Debug:Dev("ui", "Adding Suggestion Mode button to layout")
            
            -- Re-parent the button to the controls container
            if self.suggestionModeBtn.frame then
                self.suggestionModeBtn.frame:SetParent(self.controlsContainer.frame)
                self.suggestionModeBtn.frame:Show()
            end
            
            -- Find the position to insert (after suggest groups button, or after guild toggle if suggest groups not present)
            local insertPosition = 1
            if self.controlsContainer.children then
                for i, child in ipairs(self.controlsContainer.children) do
                    if child == self.suggestGroupsBtn then
                        insertPosition = i + 1
                        break
                    elseif child == self.guildToggleBtn then
                        insertPosition = i + 1
                    end
                end
            end
            
            table.insert(self.controlsContainer.children, insertPosition, self.suggestionModeBtn)
        elseif not shouldShow and isInLayout then
            -- Remove button from layout
            Debug:Dev("ui", "Removing Suggestion Mode button from layout")
            local buttonIndex = nil
            for i, child in ipairs(self.controlsContainer.children) do
                if child == self.suggestionModeBtn then
                    buttonIndex = i
                    break
                end
            end
            
            if buttonIndex then
                table.remove(self.controlsContainer.children, buttonIndex)
                if self.suggestionModeBtn.frame then
                    self.suggestionModeBtn.frame:Hide()
                    self.suggestionModeBtn.frame:SetParent(nil)
                end
            end
        end
    end
    
    -- Update Guild/Party toggle button visibility (this one can stay in layout, just show/hide)
    if self.guildToggleBtn and self.guildToggleBtn.frame then
        if showKeystoneControls then
            self.guildToggleBtn.frame:Show()
        else
            self.guildToggleBtn.frame:Hide()
        end
    end
    
    -- Update layouts
    if self.controlsContainer.DoLayout then
        self.controlsContainer:DoLayout()
        Debug:Dev("ui", "Controls container layout updated")
    end
    
    Debug:Dev("ui", "Keystone controls visibility updated")
end

--- Manual refresh function for debug controls (for testing and fallback)
function UI:RefreshDebugControls()
    Debug:Dev("ui", "Manual debug controls refresh triggered")
    if self.mainFrame then
        self:UpdateDebugControlsVisibility()
    else
        Debug:Dev("ui", "Cannot refresh debug controls - no main frame")
    end
end

--- Handles debug mode toggles while the UI is open
function UI:OnDebugModeChanged()
    Debug:Dev("ui", "OnDebugModeChanged called - mainFrame exists:", self.mainFrame ~= nil)
    
    if not self.mainFrame then
        Debug:Dev("ui", "No main frame, skipping visibility update")
        return
    end

    -- Update visibility of debug controls
    self:UpdateDebugControlsVisibility()

    -- Refresh results if in keystone view to update any debug-related displays
    if self.viewMode == "keystones" then
        self:RenderResults()
    end
    
    Debug:Dev("ui", "Debug mode change completed")
end

local function normalizeClassToken(classToken)
    if not classToken then return nil end
    return string.upper(classToken)
end

function UI:PlayerProvidesHeroism(profile, classToken, specID)
    if profile and profile.capabilities and profile.capabilities.heroism ~= nil then
        return profile.capabilities.heroism
    end

    classToken = normalizeClassToken(classToken) or (profile and normalizeClassToken(profile.class))
    specID = specID or (profile and profile.specID)

    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].heroism then
        return true
    end

    if classToken and HEROISM_CLASSES[classToken] then
        return true
    end

    return false
end

function UI:PlayerProvidesBattleRes(profile, classToken, specID)
    if profile and profile.capabilities and profile.capabilities.battleRes ~= nil then
        return profile.capabilities.battleRes
    end

    classToken = normalizeClassToken(classToken) or (profile and normalizeClassToken(profile.class))
    specID = specID or (profile and profile.specID)

    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].battleRes then
        return true
    end

    if classToken and BATTLE_RES_CLASSES[classToken] then
        return true
    end

    return false
end

local function normalizeClassToken(classToken)
    if not classToken then return nil end
    return string.upper(classToken)
end

function UI:PlayerProvidesHeroism(profile, classToken, specID)
    if profile and profile.capabilities and profile.capabilities.heroism ~= nil then
        return profile.capabilities.heroism
    end
    classToken = normalizeClassToken(classToken) or (profile and profile.class) or nil
    specID = specID or (profile and profile.specID)
    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].heroism then
        return true
    end
    if classToken and HEROISM_CLASSES[classToken] then
        return true
    end
    return false
end

function UI:PlayerProvidesBattleRes(profile, classToken, specID)
    if profile and profile.capabilities and profile.capabilities.battleRes ~= nil then
        return profile.capabilities.battleRes
    end
    classToken = normalizeClassToken(classToken) or (profile and profile.class) or nil
    specID = specID or (profile and profile.specID)
    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].battleRes then
        return true
    end
    if classToken and BATTLE_RES_CLASSES[classToken] then
        return true
    end
    return false
end


-- MARK: Private Helper Functions
-- =====================================================
-- Utility functions for frame management and UI effects
-- =====================================================

---Track auxiliary frames for cleanup
---@param self table UI module instance
---@param frame table Frame to track
local function trackAuxFrame(self, frame)
    if not frame then return end
    self._auxFrames = self._auxFrames or {}
    table.insert(self._auxFrames, frame)
end

---Add dark background overlay to frame content
---@param frame table Frame to darken
local function darkenContent(frame)
    if not frame or frame._nkDarkened then return end
    local bg = frame.content:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.55)
    bg:SetAllPoints(frame.content)
    frame._nkDarkened = true
end

--- Determines if compact mode should be used based on player count
-- @param playerCount number The total number of players/entries
-- @return boolean true if compact mode should be enabled
local function shouldUseCompactMode(playerCount)
    return playerCount > 5
end

--- Gets the dungeon alias for compact display
-- @param dungeonID number The dungeon ID
-- @return string The short alias for the dungeon
local function getDungeonAlias(dungeonID)
    if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[dungeonID] then
        return NextKey.PortalData.dungeons[dungeonID].alias
    end
    return "UNK"
end

-- MARK: Main Frame Creation
-- =====================================================
-- Creates the primary NextKey window with controls and layout
-- =====================================================

---Create the main NextKey window frame
---Sets up the window layout, controls, and results area
function UI:CreateMainFrame()
    Debug:Trace("ui", "CreateMainFrame called")
    
    if self.mainFrame then 
        Debug:Dev("ui", "Main frame already exists, skipping creation")
        return 
    end

    Debug:Dev("ui", "Creating AceGUI Frame...")
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey")
    frame:SetStatusText("UI skeleton - M0.6")
    frame:SetLayout("Flow")
    frame:SetWidth(NextKey222.UIConfig.WINDOW.WIDTH)
    local initialHeight = NextKey222.UIConfig:GetWindowHeight("keystones", {
        isDebugMode = self:ShouldShowDebugControls()
    }) or NextKey222.UIConfig.WINDOW.BASE_HEIGHT
    frame:SetHeight(initialHeight)
    frame:EnableResize(true)

    -- Standard close button behavior
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        self.mainFrame = nil
        self.resultsFrame = nil
        self.controlsContainer = nil
        self.debugControlsContainer = nil
        self.debugFakeTierDropdown = nil
        self.debugAddFakeBtn = nil
        self.debugClearFakeBtn = nil
        self.resultsSpacer = nil
        self:ClearAuxFrames()
    end)

    darkenContent(frame)

    local header = AceGUI:Create("Label")
    header:SetText("Choose a sort mode; results area below.")
    header:SetFullWidth(true)
    frame:AddChild(header)

    local controls = AceGUI:Create("SimpleGroup")
    controls:SetFullWidth(true)
    controls:SetLayout("Flow")
    frame:AddChild(controls)
    self.controlsContainer = controls

    local sortDrop = AceGUI:Create("Dropdown")
    sortDrop:SetLabel("Sort Mode")
    
    -- Store reference to dropdown for updates
    self.sortDropdown = sortDrop
    
    -- Set initial dropdown options based on current view (defaults to keystone view)
    self.viewMode = self.viewMode or "keystones"
    self:UpdateSortDropdownOptions()
    
    sortDrop:SetValue(self:GetCurrentSortMode())
    sortDrop:SetCallback("OnValueChanged", function(_, _, key)
        self:SetCurrentSortMode(key)
        -- Show/hide IO display mode button based on sort mode
        if self.ioDisplayModeBtn then
            if key == "IOGainPotential" then
                self.ioDisplayModeBtn.frame:Show()
            else
                self.ioDisplayModeBtn.frame:Hide()
            end
        end
        if self.viewMode == "dungeons" then
            self:RenderDungeonCards()
        else
            self:RenderResults()
        end
    end)
    controls:AddChild(sortDrop)

    local refreshBtn = AceGUI:Create("Button")
    refreshBtn:SetText("Refresh")
    refreshBtn:SetAutoWidth(true)
    refreshBtn:SetCallback("OnClick", function()
        if self.viewMode == "dungeons" then
            self:RenderDungeonCards()
        else
            -- Use enhanced refresh that re-scans keystones
            self:RefreshResults()
        end
    end)
    controls:AddChild(refreshBtn)

    local syncBtn = AceGUI:Create("Button")
    syncBtn:SetText("Sync")
    syncBtn:SetAutoWidth(true)
    syncBtn:SetCallback("OnClick", function()
        if NextKey222.Communications then
            -- Ensure current player's IO data is refreshed
            NextKey222.Communications:EnsureCurrentPlayerIOData()
            
            -- Send sync to request data from others
            if NextKey222.Communications.SendSync then
                NextKey222.Communications:SendSync()
            end
            
            -- Request IO data from party members  
            if NextKey222.Communications.RequestPartyIOData then
                NextKey222.Communications:RequestPartyIOData()
            end
        else
            Debug:Error("Communications not available")
        end
    end)
    controls:AddChild(syncBtn)

    -- Guild/Party Filter Toggle Button
    local guildToggleBtn = AceGUI:Create("Button")
    guildToggleBtn:SetText(self.showGuildKeys and "Guild Keys" or "Party Keys")
    guildToggleBtn:SetAutoWidth(true)
    guildToggleBtn:SetCallback("OnClick", function()
        -- Enhanced guild toggle with immediate feedback
        if not self.showGuildKeys and IsInGuild() then
            -- Switching to guild mode - show immediate feedback
            Debug:User("Requesting guild keystones... (requires LibOpenRaid-compatible addons)")
            
            -- Try direct LibOpenRaid request as well as our integration
            if LibStub then
                local lib = LibStub:GetLibrary("LibOpenRaid-1.0", true)
                if lib then
                    lib.RequestKeystoneDataFromGuild()
                end
            end
        elseif not self.showGuildKeys and not IsInGuild() then
            Debug:User("Not in a guild - cannot show guild keystones")
        end
        
        self:ToggleGuildFilter()
    end)
    controls:AddChild(guildToggleBtn)
    self.guildToggleBtn = guildToggleBtn

    local teleportWindowBtn = AceGUI:Create("Button")
    teleportWindowBtn:SetText("Open Teleport")
    teleportWindowBtn:SetAutoWidth(true)
    teleportWindowBtn:SetCallback("OnClick", function()
        NextKey222.Addon:ToggleTeleportWindow()
    end)
    controls:AddChild(teleportWindowBtn)

    -- Add view toggle button to controls (this approach works reliably)
    local toggleBtn = AceGUI:Create("Button")
    toggleBtn:SetText("Switch to Dungeons View")  -- Initial text - starts in Keystone View
    toggleBtn:SetAutoWidth(true)
    toggleBtn:SetCallback("OnClick", function()
        self:ToggleViewMode()
    end)
    controls:AddChild(toggleBtn)

    -- Store reference for text updates
    self.viewToggleBtn = toggleBtn

    -- Group suggestion buttons (conditionally added when 6+ players)
    -- Create buttons but don't add to layout yet
    local suggestBtn = AceGUI:Create("Button")
    suggestBtn:SetText("Suggest Groups")
    suggestBtn:SetAutoWidth(true)
    suggestBtn:SetCallback("OnClick", function()
        self:SuggestGroups()
    end)
    self.suggestGroupsBtn = suggestBtn
    Debug:Dev("ui", "Suggest Groups button created (not added to layout yet)")

    local modeBtn = AceGUI:Create("Button")
    modeBtn:SetText("Auto Mode")
    modeBtn:SetAutoWidth(true)
    modeBtn:SetCallback("OnClick", function()
        self:ToggleSuggestionMode()
    end)
    self.suggestionModeBtn = modeBtn
    Debug:Dev("ui", "Suggestion Mode button created (not added to layout yet)")

    -- Debug-only controls for managing fake players
    -- Always create widgets, but only add to layout when debug is enabled
    if NextKey222.FakePlayerService then
        Debug:Dev("ui", "Creating debug controls")

        -- Create a simple group container for all debug widgets
        local debugContainer = AceGUI:Create("SimpleGroup")
        debugContainer:SetFullWidth(true)
        debugContainer:SetLayout("Flow")
        self.debugControlsContainer = debugContainer

        -- Create fake player tier dropdown
        local tierDropdown = AceGUI:Create("Dropdown")
        tierDropdown:SetLabel("Fake Player Tier")
        tierDropdown:SetWidth(200)
        tierDropdown:SetList({
            random = "Random (Expert/Skilled/Competent)",
            expert = "Expert",
            skilled = "Skilled",
            competent = "Competent"
        })
        tierDropdown:SetValue(self.debugFakeTierSelection or "random")
        tierDropdown:SetCallback("OnValueChanged", function(widget, event, value)
            self.debugFakeTierSelection = value or "random"
        end)
        debugContainer:AddChild(tierDropdown)
        self.debugFakeTierDropdown = tierDropdown

        -- Create add fake player button
        local addFakeBtn = AceGUI:Create("Button")
        addFakeBtn:SetText("Add Fake Player")
        addFakeBtn:SetAutoWidth(true)
        addFakeBtn:SetCallback("OnClick", function()
            self:HandleAddDebugFakePlayer()
        end)
        debugContainer:AddChild(addFakeBtn)
        self.debugAddFakeBtn = addFakeBtn

        -- Create clear fake players button
        local clearFakeBtn = AceGUI:Create("Button")
        clearFakeBtn:SetText("Delete All Fakes")
        clearFakeBtn:SetAutoWidth(true)
        clearFakeBtn:SetCallback("OnClick", function()
            self:HandleDeleteAllFakePlayers()
        end)
        debugContainer:AddChild(clearFakeBtn)
        self.debugClearFakeBtn = clearFakeBtn

        -- Add to controls if debug is currently enabled
        local showDebug = self:ShouldShowDebugControls()
        if showDebug then
            controls:AddChild(debugContainer)
            Debug:Dev("ui", "Debug controls added to layout (debug ON)")
        else
            Debug:Dev("ui", "Debug controls created but not added to layout (debug OFF)")
        end
    else
        Debug:Dev("ui", "FakePlayerService not available - debug controls disabled")
    end

    -- Add total IO score display
    local totalScoreLabel = AceGUI:Create("Label")
    totalScoreLabel:SetText("")
    totalScoreLabel:SetWidth(120)
    totalScoreLabel:SetFontObject(GameFontNormalLarge)
    totalScoreLabel:SetColor(1, 0.8, 0) -- Gold color
    controls:AddChild(totalScoreLabel)
    self.totalScoreLabel = totalScoreLabel

    local spacer = AceGUI:Create("Label")
    spacer:SetText("")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)
    self.resultsSpacer = spacer
    self:ApplyResultsTopPadding()

    local results = AceGUI:Create("ScrollFrame")
    results:SetFullWidth(true)
    results:SetFullHeight(true)
    results:SetLayout("List")
    frame:AddChild(results)

    self.resultsFrame = results
    self.mainFrame = frame

    -- Toggle button is now in the top controls area where it works reliably

    -- Initialize with keystone view (default)
    -- Set up initial button text and render keystones
    if self.viewToggleBtn then
        self.viewToggleBtn:SetText("Switch to Dungeons View")
    end
    Debug:Dev("ui", "CreateMainFrame: About to call initial RenderResults")
    self:RenderResults()  -- Show keystones by default
    
    -- Update keystone controls visibility after initial render
    Debug:Dev("ui", "CreateMainFrame: About to call initial UpdateKeystoneControlsVisibility")
    self:UpdateKeystoneControlsVisibility()
    Debug:Dev("ui", "CreateMainFrame: Initial setup complete")
    
    -- Show the frame
    Debug:Dev("ui", "Showing main frame...")
    frame:Show()
    
    -- Double-check button visibility after frame is shown
    Debug:Dev("ui", "CreateMainFrame: Final button visibility check")
    if self.suggestGroupsBtn and self.suggestGroupsBtn.frame then
        Debug:Dev("ui", "Suggest Groups button visible after frame show:", self.suggestGroupsBtn.frame:IsShown() and "YES" or "NO")
    end
    if self.suggestionModeBtn and self.suggestionModeBtn.frame then
        Debug:Dev("ui", "Suggestion Mode button visible after frame show:", self.suggestionModeBtn.frame:IsShown() and "YES" or "NO")
    end
end

-- MARK: Frame Visibility Management
--
-- Functions responsible for showing, hiding, and managing the visibility
-- state of the main UI frame and related components.

--- Toggles the visibility of the main NextKey UI window
-- Creates the main frame if it doesn't exist, then destroys/recreates it on hide
-- Properly releases AceGUI resources and clears auxiliary frames
function UI:ToggleMainFrame()
    Debug:Trace("ui", "ToggleMainFrame called")
    
    if self.mainFrame then
        Debug:Dev("ui", "Hiding existing main frame")
        self.mainFrame:Hide()
        AceGUI:Release(self.mainFrame)
        self.mainFrame = nil
        self.resultsFrame = nil
        self.controlsContainer = nil
        self.debugControlsContainer = nil
        self.debugFakeTierDropdown = nil
        self.debugAddFakeBtn = nil
        self.debugClearFakeBtn = nil
        self.suggestionModeBtn = nil
        self.suggestGroupsBtn = nil
        self.resultsSpacer = nil
        self:ClearAuxFrames()
    else
        Debug:Dev("ui", "Creating new main frame")
        self:CreateMainFrame()
    end
end

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

    -- Debug logging to track function calls
    Debug:Dev("ui", string.format("EnrichEntryMetadata Called: ownerName=%s", ownerName))

    local profile = self:GetPlayerProfileCached(normalizedName)

    -- Debug logging for Evoker role issue
    if ownerName:find("Ryuza") or (profile and profile.class == "EVOKER") then
        Debug:Dev("ui", string.format("EnrichEntryMetadata Debug: ownerName=%s, normalizedName=%s, profile=%s",
            ownerName, normalizedName, profile and "exists" or "nil"))
        if profile then
            Debug:Dev("ui", string.format("Profile Data: class=%s, role=%s, specName=%s, specID=%s",
                profile.class or "nil",
                profile.role or "nil",
                profile.specName or "nil",
                profile.specID or "nil"))
        end
    end

    entry.profile = profile
    entry.specName = profile and profile.specName or nil
    entry.specID = profile and profile.specID or nil
    
    -- Use spec-to-role mapping for reliable role detection (same as tooltip)
    if entry.specID and NextKey222.UIComponents and NextKey222.UIComponents.GetRoleFromSpecID then
        entry.role = NextKey222.UIComponents:GetRoleFromSpecID(entry.specID, "DAMAGER")
        Debug:Dev("ui", string.format("EnrichEntryMetadata: Using spec-to-role mapping for %s: specID=%d, role=%s",
            ownerName, entry.specID, entry.role))
    else
        -- Fallback to profile role
        entry.role = (profile and profile.role) or "DAMAGER"
        -- Normalize role to uppercase to ensure consistency
        if entry.role then
            entry.role = string.upper(entry.role)
        end
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

--- Adds a single fake player using the current debug tier selection
function UI:HandleAddDebugFakePlayer()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.CreatePlayer then
        Debug:Dev("fakeplayerservice", "FakePlayerService unavailable - cannot add player from UI")
        return
    end

    local tierSelection = self.debugFakeTierSelection or "random"
    local highSkillTiers = { "expert", "skilled", "competent" }

    local chosenTier = tierSelection
    if tierSelection == "random" then
        local index = math.random(#highSkillTiers)
        chosenTier = highSkillTiers[index]
    end

    local createdName = NextKey222.FakePlayerService:CreatePlayer({ tier = chosenTier })
    if createdName then
        Debug:Dev("fakeplayerservice", "UI created fake player", createdName, "tier", chosenTier)
        self:RenderResults()
    else
        Debug:Dev("fakeplayerservice", "UI failed to create fake player for tier", chosenTier)
    end
end

--- Removes all fake players (debug helper)
function UI:HandleDeleteAllFakePlayers()
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.ClearAllPlayers then
        Debug:Dev("fakeplayerservice", "FakePlayerService unavailable - cannot clear players")
        return
    end

    local removedCount = NextKey222.FakePlayerService:ClearAllPlayers() or 0
    Debug:Dev("fakeplayerservice", "UI cleared fake players", removedCount)
    self:RenderResults()
end

--- Removes a specific fake player by name
-- @param playerName string Full normalized player name
function UI:HandleDeleteFakePlayer(playerName)
    if not playerName or not NextKey222.FakePlayerService or not NextKey222.FakePlayerService.RemovePlayer then
        return
    end

    NextKey222.FakePlayerService:RemovePlayer(playerName)
    Debug:Dev("fakeplayerservice", "UI removed fake player", playerName)
    self:RenderResults()
end

--- Generate and display intelligent group suggestions
function UI:SuggestGroups()
    Debug:Dev("ui", "SuggestGroups called")

    if not NextKey222.GroupSuggestions then
        Debug:Error("ui", "GroupSuggestions module not available")
        return
    end

    -- Generate suggestions based on current mode
    local suggestion = NextKey222.GroupSuggestions:GenerateSuggestions(self.suggestionMode)

    if not suggestion then
        Debug:User("No group suggestions available. Need at least 5 players with keystones.")
        return
    end

    -- Format for chat output
    local chatMessage = NextKey222.GroupSuggestions:FormatSuggestionForChat(suggestion)

    -- Send to party/raid chat
    local chatType = UnitInRaid("player") and "RAID" or "PARTY"
    if UnitInParty("player") or UnitInRaid("player") then
        SendChatMessage(chatMessage, chatType)
        Debug:User("Group suggestions posted to " .. chatType .. " chat")
    else
        -- Solo player - show in system chat
        print(chatMessage)
        Debug:User("Group suggestions displayed (solo player)")
    end

    -- Also show a brief summary in user chat
    if suggestion.mode == "best_key" then
        Debug:User(string.format("Suggested: %s +%d for %d group IO gain",
            suggestion.selectedKey.dungeonName or "Unknown",
            suggestion.selectedKey.level or 0,
            suggestion.ioGain.total))
    elseif suggestion.mode == "best_groups" then
        Debug:User(string.format("Suggested: %d groups from %d players with key rotation",
            #suggestion.groups, suggestion.totalPlayers))
    end
end

--- Toggle between suggestion modes (Best Key vs Best Groups)
function UI:ToggleSuggestionMode()
    if self.suggestionMode == "auto" then
        self.suggestionMode = "best_key"
        self.suggestionModeBtn:SetText("Best Key Mode")
        Debug:User("Suggestion mode: Best Key (single group optimization)")
    elseif self.suggestionMode == "best_key" then
        self.suggestionMode = "best_groups"
        self.suggestionModeBtn:SetText("Best Groups Mode")
        Debug:User("Suggestion mode: Best Groups (multi-group key rotation)")
    else
        self.suggestionMode = "auto"
        self.suggestionModeBtn:SetText("Auto Mode")
        Debug:User("Suggestion mode: Auto (intelligent selection)")
    end
end

--- Shared tooltip handler for IO gain displays (full and compact rows)
-- @param button Frame Button or region triggering the tooltip
-- @param keyInfo table Keystone data for the row
-- @param entry table Row entry containing cached ioRange (optional)
-- @param ioRange table Range data (min/max/expected + playerBreakdown)
function UI:ShowIOGainTooltip(button, keyInfo, entry, ioRange)
    if not button or not keyInfo or not ioRange then
        return
    end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

    local usedPreCalculated = entry and entry.ioGainRange ~= nil
    Debug:Dev("tooltip", " Using", usedPreCalculated and "pre-calculated" or "recalculated", "ioRange")

    if ioRange.playerBreakdown then
        local playerCount = 0
        for _ in pairs(ioRange.playerBreakdown) do
            playerCount = playerCount + 1
        end
        Debug:Dev("tooltip", " Player breakdown has", playerCount, "players")
        for playerName in pairs(ioRange.playerBreakdown) do
            Debug:Dev("tooltip", " Breakdown includes player:", playerName)
        end
    else
        Debug:Dev("tooltip", " No player breakdown available")
    end

    local dungeonName = "Unknown Dungeon"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID) or ("Dungeon " .. keyInfo.dungeonID)
    end

    local ownerName = keyInfo.ownerName or "Unknown"
    local keystoneLevel = keyInfo.level or 0
    local headerText = string.format("%s (+%d) - %s's Key", dungeonName, keystoneLevel, ownerName:match("^([^%-]+)") or ownerName)
    GameTooltip:SetText(headerText, 1, 1, 1, 1, true)
    GameTooltip:AddLine("Group IO Gain Potential", 0.9, 0.9, 1)

    local showedBreakpoints = false
    if keystoneLevel > 0 and NextKey222.IOCalculator and ioRange.playerBreakdown then
        local breakpointRanges = self:CalculateBreakpointRanges(keyInfo, ioRange.playerBreakdown)
        if breakpointRanges then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(string.format("Untimed: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.untimed.total or 0),
                math.floor(breakpointRanges.untimed.average or 0)), 0.8, 0.4, 0.4)
            GameTooltip:AddLine(string.format("Timed: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.timed.total or 0),
                math.floor(breakpointRanges.timed.average or 0)), 1, 1, 0.4)
            GameTooltip:AddLine(string.format("+2: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.plus2.total or 0),
                math.floor(breakpointRanges.plus2.average or 0)), 0.4, 1, 0.4)
            GameTooltip:AddLine(string.format("+3: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.plus3.total or 0),
                math.floor(breakpointRanges.plus3.average or 0)), 0.2, 1, 0.2)
            showedBreakpoints = true
        end
    end

    if not showedBreakpoints then
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine(string.format("Group IO Gain: +%d", math.floor(ioRange.expected or 0)), 0, 1, 0)
        GameTooltip:AddLine(string.format("Range: +%d to +%d", math.floor(ioRange.min or 0), math.floor(ioRange.max or 0)), 0.8, 0.8, 0.8)
    end

    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Individual Player Breakdown:", 0.9, 0.9, 0.9)

    if ioRange.playerBreakdown then
        local playerEntries = {}
        local dungeonID = keyInfo.dungeonID

        for playerName, breakdown in pairs(ioRange.playerBreakdown) do
            local entryData = {
                name = playerName,
                shortName = playerName:match("^([^%-]+)") or playerName,
                breakdown = breakdown,
                minGain = breakdown.min or 0,
                maxGain = breakdown.max or 0,
                currentIO = 0,
                bestLevel = 0,
                hasNextKey = false,
                fakeProfile = self:GetFakePlayerData(playerName)
            }

            if dungeonID and NextKey222.IOCalculator then
                entryData.currentIO = NextKey222.IOCalculator:GetPlayerDungeonScore(playerName, dungeonID) or 0
                Debug:Dev("tooltip", "Current dungeon IO for", playerName, "dungeon", dungeonID .. ":", entryData.currentIO)
            end

            if entryData.fakeProfile and entryData.fakeProfile.addonStatus then
                entryData.hasNextKey = entryData.fakeProfile.addonStatus.nextkey or false
            else
                entryData.hasNextKey = (entryData.minGain > 0 or entryData.maxGain > 0 or entryData.currentIO > 0)
            end

            local currentPlayerFull = UnitName("player") .. "-" .. GetRealmName()
            local isCurrentPlayer = (playerName == currentPlayerFull) or (playerName:match("^([^%-]+)") == UnitName("player"))
            if entryData.hasNextKey and dungeonID then
                if isCurrentPlayer then
                    entryData.bestLevel = self:GetBestLevel(dungeonID) or 0
                elseif entryData.fakeProfile and entryData.fakeProfile.dungeonScores then
                    local scoreEntry = entryData.fakeProfile.dungeonScores[dungeonID]
                    if scoreEntry then
                        entryData.bestLevel = scoreEntry.bestLevel or scoreEntry.level or 0
                    end
                end
            end

            table.insert(playerEntries, entryData)
        end

        table.sort(playerEntries, function(a, b)
            if a.hasNextKey ~= b.hasNextKey then
                return a.hasNextKey and not b.hasNextKey
            end

            if a.currentIO ~= b.currentIO then
                return a.currentIO < b.currentIO
            end

            return (a.bestLevel or 0) < (b.bestLevel or 0)
        end)

        for _, data in ipairs(playerEntries) do
            if data.hasNextKey then
                local potentialColor = "|cff00ff00"
                if math.floor(data.minGain) == 0 and math.floor(data.maxGain) == 0 then
                    potentialColor = "|cff999999"
                end

                local bestLevelText = data.bestLevel > 0 and string.format(" |cff4aa3ff+%d|r", data.bestLevel) or ""
                local playerLine = string.format("%s: %s(+%d-%d Potential IO)|r |cffffff00(Current IO: %d)|r%s",
                    data.shortName,
                    potentialColor,
                    math.floor(data.minGain),
                    math.floor(data.maxGain),
                    math.floor(data.currentIO),
                    bestLevelText)
                GameTooltip:AddLine(playerLine, 1, 1, 1)
            else
                GameTooltip:AddLine(string.format("%s: NextKey Not Installed", data.shortName), 0.6, 0.6, 0.6)
            end
        end
    end

    GameTooltip:Show()
end

-- MARK: Individual Player Analysis
--
-- Functions for analyzing and displaying individual player IO improvement potential

-- Individual Player Recommendations function removed - no longer needed
-- Now focusing on group-based keystone ranking by IO gain potential

-- MARK: Data Management

-- Create dungeon ranking system (1-8) for cross-addon comparison
-- Lower rank = weaker dungeon, Higher rank = stronger dungeon
function UI:GetDungeonRankings(playerName)
    local rankings = {}
    local dungeonData = {}
    
    -- Get current season dungeons
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    
    -- Check if this is current player (use NextKey/WoW API data)
    local currentPlayerName = UnitName("player")
    local isCurrentPlayer = (playerName == currentPlayerName) or 
                           (playerName:match("^([^%-]+)") == currentPlayerName)
    
    if isCurrentPlayer then
        Debug:Dev("ui", "Creating IO score rankings for current player:", playerName)
        
        -- For current player: rank by IO scores (NextKey method)
        for dungeonID, dungeonInfo in pairs(dungeons) do
            local ioScore = self:GetRaiderIODungeonScore(dungeonID)
            table.insert(dungeonData, {
                dungeonID = dungeonID,
                value = ioScore,
                name = dungeonInfo.name
            })
        end
        
        -- Sort by IO score (lowest to highest for ranking)
        table.sort(dungeonData, function(a, b) return a.value < b.value end)
        
    else
        Debug:Dev("ui", "Creating key level rankings for party member:", playerName)
        
        -- For party members: try RaiderIO key levels as fallback
        if RaiderIO and RaiderIO.GetProfile then
            local profile = RaiderIO.GetProfile(playerName)
            if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.sortedDungeons then
                
                -- Map RaiderIO dungeons to NextKey IDs and get levels
                for i, rioData in ipairs(profile.mythicKeystoneProfile.sortedDungeons) do
                    local nextKeyID = self:FindNextKeyIDFromRaiderIO(rioData)
                    if nextKeyID and dungeons[nextKeyID] then
                        table.insert(dungeonData, {
                            dungeonID = nextKeyID,
                            value = rioData.level or 0,
                            name = dungeons[nextKeyID].name
                        })
                    end
                end
                
                -- Sort by key level (lowest to highest for ranking)
                table.sort(dungeonData, function(a, b) return a.value < b.value end)
            end
        end
        
        -- If no RaiderIO data, check for NextKey communication
        if #dungeonData == 0 and NextKey222.Communications then
            Debug:Dev("ui", "Trying NextKey communication for", playerName)
            
            if NextKey222.Communications:HasScoresForPlayer(playerName) then
                local partyScores = NextKey222.Communications:GetPartyMemberScores(playerName)
                
                for dungeonID, scoreData in pairs(partyScores) do
                    if dungeons[dungeonID] then
                        table.insert(dungeonData, {
                            dungeonID = dungeonID,
                            value = scoreData.score or 0,
                            name = dungeons[dungeonID].name
                        })
                    end
                end
                
                -- Sort by IO score (lowest to highest for ranking)
                table.sort(dungeonData, function(a, b) return a.value < b.value end)
            end
        end
    end
    
    -- Create 1-8 rankings (1 = weakest/lowest, 8 = strongest/highest)
    for rank, data in ipairs(dungeonData) do
        rankings[data.dungeonID] = {
            rank = rank,
            value = data.value,
            dungeonName = data.name,
            dataType = isCurrentPlayer and "io_score" or "key_level"
        }
        
        Debug:Dev("ui", string.format("Player %s dungeon %s: rank %d (value: %d %s)",
            playerName, data.name, rank, data.value, isCurrentPlayer and "IO" or "level"))
    end
    
    Debug:Dev("ui", string.format("Created rankings for %s: %d dungeons ranked", 
        playerName, #dungeonData))
    
    return rankings
end

-- Compare two players by their dungeon rankings
function UI:CompareDungeonRankings(playerA, playerB, dungeonID)
    local rankingsA = self:GetDungeonRankings(playerA)
    local rankingsB = self:GetDungeonRankings(playerB)
    
    local rankA = rankingsA[dungeonID] and rankingsA[dungeonID].rank or 0
    local rankB = rankingsB[dungeonID] and rankingsB[dungeonID].rank or 0
    
    Debug:Dev("ui", string.format("Dungeon comparison - %s: rank %d, %s: rank %d", 
        playerA, rankA, playerB, rankB))
    
    return rankA, rankB
end



-- Get RaiderIO keystone levels as fallback for score estimation


-- Find NextKey dungeon ID from RaiderIO dungeon data
function UI:FindNextKeyIDFromRaiderIO(dungeonData)
    if not dungeonData or not dungeonData.name then
        return nil
    end
    
    -- Map RaiderIO dungeon names to NextKey IDs
    local nameMapping = {
        ["Ara-Kara, City of Echoes"] = 1,
        ["City of Threads"] = 2, 
        ["The Stonevault"] = 3,
        ["The Dawnbreaker"] = 4,
        ["Mists of Tirna Scithe"] = 5,
        ["The Necrotic Wake"] = 6,
        ["Siege of Boralus"] = 7,
        ["Grim Batol"] = 8
    }
    
    local nextKeyID = nameMapping[dungeonData.name]
    if not nextKeyID then
        Debug:Dev("ui", "Unknown RaiderIO dungeon name:", dungeonData.name)
    end
    
    return nextKeyID
end

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

--- Main rendering function that displays keystones based on current view mode
-- Handles both player keystone view and dungeon card view
-- Updates UI content and status messages
function UI:RenderResults()
    -- RenderResults called
    if not self.resultsFrame then 
        Debug:Dev("ui", " No results frame found")
        return 
    end

    -- Clearing previous content
    -- Clear existing content
    self:ClearAuxFrames()
    self.resultsFrame:ReleaseChildren()

    -- Get available keys
    local keys = NextKey222.Addon:GetAvailableKeys()
    Debug:Dev("ui", "[KEY DEBUG] GetAvailableKeys returned", keys and #keys or 0, "keys")
    
    -- Debug: Print all collected keys for troubleshooting
    if keys then
        for i, key in ipairs(keys) do
            Debug:Dev("ui", string.format("[KEY DEBUG] Key %d: %s (ID:%s, Level:%s, Source:%s)", 
                i, key.ownerName or "nil", tostring(key.dungeonID), tostring(key.level), key.source or "unknown"))
        end
    end

    -- Update status text
    local mode = self:GetCurrentSortMode()
    local count = keys and #keys or 0
    local statusText = string.format("Mode: %s | Keys: %d | M0.6", tostring(mode), count)
    
    -- Add extra info for IO Gain mode
    if mode == "IOGainPotential" then
        local partySize = #(NextKey:GetPartyMemberNames() or {})
        statusText = statusText .. string.format(" | Party: %d", partySize)
    end
    
    Debug:Dev("ui", statusText)

    if not keys or #keys == 0 then
        local none = AceGUI:Create("Label")
        none:SetText("No keys detected. Enable Debug in options or acquire a keystone.")
        none:SetFullWidth(true)
        self.resultsFrame:AddChild(none)
        
        -- Set cachedItemsCount to 0 even when no keys exist
        self.cachedItemsCount = 0
        
        -- Update all keystone controls visibility (this handles all button visibility logic)
        self:UpdateKeystoneControlsVisibility()
        return
    end

    -- No longer showing individual recommendations - just rank keystones by group IO gain

    self.profileCache = {}
    self.cachedItems = {}
    self.cachedSortMode = mode

    local items = self:SortKeys(keys, mode)
    Debug:Dev("ui", string.format("[SORT DEBUG] SortKeys returned %d items for mode %s", 
        items and #items or 0, tostring(mode)))
    
    if items and #items > 0 then
        for i, item in ipairs(items) do
            Debug:Dev("ui", string.format("[SORT DEBUG] Item %d: %s, ioGainPotential=%s", 
                i, item.key and item.key.ownerName or "nil", tostring(item.ioGainPotential)))
        end
    end
    
    local useCompactMode = shouldUseCompactMode(#items)
    self.cachedUseCompactMode = useCompactMode
    self.cachedItemsCount = #items
    
    for i, it in ipairs(items) do
        Debug:Dev("ui", string.format("[RENDER DEBUG] Attempting to render card %d for %s", 
            i, it.key and it.key.ownerName or "nil"))
        self:EnrichEntryMetadata(it)
        table.insert(self.cachedItems, it)
        local renderFunc = useCompactMode and self.AddKeyRowCompact or self.AddKeyRow
        local success = NextKey222.SafeRun(renderFunc, "Render keystone card", self, it)
        if not success then
            Debug:Error("Failed to render card for", it.key and it.key.ownerName or "nil")
        else
            Debug:Dev("ui", string.format("[RENDER DEBUG] Successfully rendered card for %s", 
                it.key and it.key.ownerName or "nil"))
        end
    end

    -- Update all keystone controls visibility (this handles all button visibility logic)
    self:UpdateKeystoneControlsVisibility()
end

-- MARK: Keystone Card Rendering
--
-- Functions responsible for creating and displaying individual keystone cards
-- with player information, scores, and interactive elements.

--- Creates and renders a keystone card for a single player entry
-- @param entry table The keystone data containing player info, key details, and scores
-- Handles both real player keystones and fake player data for testing
function UI:AddKeyRow(entry)
    local keyInfo = entry.key
    
    -- Get dungeon name
    local dungeonName = "No Keystone"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    else
        keyInfo.level = 0
    end
    
    -- Normalize player name and get score using components
    if not NextKey222.UIComponents then
        Debug:Error(" UIComponents not loaded! Check load order.")
        return
    end
    
    local ownerName = NextKey222.UIComponents:NormalizePlayerName(keyInfo.ownerName)
    local score = NextKey222.UIComponents:GetPlayerScore(keyInfo)
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Create container using component factory
    local container = NextKey222.UIComponents:CreateCardContainer(88, false)
    self.resultsFrame:AddChild(container)
    
    -- Create backdrop using component factory
    local frame = NextKey222.UIComponents:CreateBackdrop(container.frame, "keystone")
    trackAuxFrame(self, frame)
    
    -- Create class icon using component factory with player data for tooltip
    local playerData = {
        ownerName = ownerName,
        classToken = classToken,
        specName = entry.specName,
        specID = entry.specID,
        role = entry.role,
        hasHeroism = entry.hasHeroism,
        hasBattleRes = entry.hasBattleRes
    }
    local icon = NextKey222.UIComponents:CreateClassIcon(frame, classToken, 32, playerData)
    icon:SetPoint("LEFT", 12, 0)
    
    -- Create role icon using component factory
    local roleIcon = NextKey222.UIComponents:CreateRoleIcon(frame, entry.role, NextKey222.UIConfig.ICON.ROLE_SIZE)
    roleIcon:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    
    -- Create formatted player name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", roleIcon, "TOPRIGHT", 6, -2)
    nameText:SetText(NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score))
    nameText:SetJustifyH("LEFT")

    -- Add prominent IO gain display for IOGainPotential sort mode
    local ioGainText = nil
    local currentSortMode = self:GetCurrentSortMode()
    if currentSortMode == "IOGainPotential" then
        -- Use pre-calculated range data if available, otherwise calculate
        local ioRange = entry.ioGainRange or self:CalculateIOGainRange(keyInfo)
        if ioRange and not entry.ioGainRange then
            entry.ioGainRange = ioRange
        end
        if ioRange.expected > 0 then
            ioGainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            ioGainText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -8)
            
            -- Format IO gain display (simple range format)
            local displayText = string.format("+%d IO", math.floor(ioRange.expected))
            ioGainText:SetText(string.format("|cff00ff00%s|r", displayText))
            ioGainText:SetJustifyH("RIGHT")
            
            -- Make it clickable for tooltip
            local ioGainButton = CreateFrame("Button", nil, frame)
            ioGainButton:SetAllPoints(ioGainText)
            ioGainButton:SetFrameLevel(frame:GetFrameLevel() + 1)
            ioGainButton:SetScript("OnEnter", function(btn)
                self:ShowIOGainTooltip(btn, keyInfo, entry, ioRange)
            end)
            ioGainButton:SetScript("OnLeave", GameTooltip_Hide)
            trackAuxFrame(self, ioGainButton)
        end
    end

    local levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    levelText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2)
    
    -- Simple keystone display (IO gain shown in prominent green number instead)
    local keystoneText = string.format("Keystone: %s |cff4aa3ff+%d|r", dungeonName, keyInfo.level or 0)
    levelText:SetText(keystoneText)
    levelText:SetJustifyH("LEFT")

    local bestLevel = self.GetSeasonBestLevel and self:GetSeasonBestLevel(keyInfo.dungeonID)
    if bestLevel and bestLevel > 0 then
        local bestText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bestText:SetPoint("TOPLEFT", levelText, "BOTTOMLEFT", 0, -4)
        bestText:SetText(string.format("Your best: |cff4aa3ff+%d|r", bestLevel))
        bestText:SetJustifyH("LEFT")
    end

    -- Create select button using component factory
    local selectBtn = NextKey222.UIComponents:CreateButton(frame, "select", nil, nil)
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    trackAuxFrame(self, selectBtn)

    -- Configure button state and behavior
    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)
    
    if isSelected then
        selectBtn:SetText("Selected")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetScript("OnClick", function()
            NextKey222.Addon:SetTeleportTargetKey(keyInfo, { broadcast = true })
        end)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set this keystone as the teleport target.")
            GameTooltip:AddLine("Shares the selection with party members running NextKey.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
    else
        selectBtn:Disable()
        selectBtn:SetAlpha(0.4)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Debug helper: allow removing individual fake players directly from the card
    if self:IsDebugMode() and NextKey222.FakePlayerService and ownerName and NextKey222.FakePlayerService:IsFakePlayer(ownerName) then
        local deleteBtn = NextKey222.UIComponents:CreateButton(frame, "select", nil, nil)
        deleteBtn:SetText("Delete")
        deleteBtn:SetWidth(70)
        deleteBtn:SetPoint("RIGHT", selectBtn, "LEFT", -6, 0)
        deleteBtn:SetScript("OnClick", function()
            self:HandleDeleteFakePlayer(ownerName)
        end)
        deleteBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove this fake player")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
        trackAuxFrame(self, deleteBtn)
    end
end

--- Creates and renders a compact keystone card for high player counts
-- @param entry table The keystone data containing player info, key details, and scores
-- Uses aliases and condensed layout to save vertical space
function UI:AddKeyRowCompact(entry)
    local keyInfo = entry.key
    
    -- Get dungeon name
    local dungeonName = "No Key"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    end
    
    -- Use component system for consistent processing
    if not NextKey222.UIComponents then
        Debug:Error(" UIComponents not loaded! Check load order.")
        return
    end
    
    local ownerName = NextKey222.UIComponents:NormalizePlayerName(keyInfo.ownerName)
    local score = NextKey222.UIComponents:GetPlayerScore(keyInfo)
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Create compact container
    local container = NextKey222.UIComponents:CreateCardContainer(28, true)
    self.resultsFrame:AddChild(container)
    
    -- Create compact backdrop
    local frame = NextKey222.UIComponents:CreateBackdrop(container.frame, "keystone_compact")
    trackAuxFrame(self, frame)
    
    -- Create smaller class icon with player data for tooltip
    local playerData = {
        ownerName = ownerName,
        classToken = classToken,
        specName = entry.specName,
        specID = entry.specID,
        role = entry.role,
        hasHeroism = entry.hasHeroism,
        hasBattleRes = entry.hasBattleRes
    }
    local icon = NextKey222.UIComponents:CreateClassIcon(frame, classToken, 20, playerData)
    icon:SetPoint("LEFT", 8, 0)
    
    -- Create role icon for compact view (smaller size)
    local roleIcon = NextKey222.UIComponents:CreateRoleIcon(frame, entry.role, 12)
    roleIcon:SetPoint("LEFT", icon, "RIGHT", 2, 0)
    
    -- Create compact single-line text
    local mainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainText:SetPoint("LEFT", roleIcon, "RIGHT", 6, 0)
    
    -- Format combined display text
    local nameDisplay = NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score)
    local keyDisplay = NextKey222.UIComponents:FormatKeystoneDisplay(dungeonName, keyInfo.level)
    
    -- Determine IO gain display state for compact view
    local currentSortMode = self:GetCurrentSortMode()
    local compactIORange = nil
    local showCompactIO = false
    if currentSortMode == "IOGainPotential" then
        compactIORange = entry.ioGainRange or self:CalculateIOGainRange(keyInfo)
        if compactIORange and (compactIORange.expected or 0) > 0 then
            showCompactIO = true
            if not entry.ioGainRange then
                entry.ioGainRange = compactIORange
            end
        end
    end

    local fullText
    if showCompactIO then
        fullText = string.format("%s | %s", nameDisplay, keyDisplay)
    elseif currentSortMode == "IOGainPotential" and entry.ioGainPotential then
        local gainDisplay = string.format("|cff00ff00+%.1f IO|r", entry.ioGainPotential)
        fullText = string.format("%s | %s | %s", nameDisplay, keyDisplay, gainDisplay)
    else
        fullText = string.format("%s | %s", nameDisplay, keyDisplay)
    end
    mainText:SetText(fullText)
    mainText:SetJustifyH("LEFT")

    -- Create compact select button
    local selectBtn = NextKey222.UIComponents:CreateButton(frame, "select_compact", nil, nil)
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    trackAuxFrame(self, selectBtn)

    -- Configure compact button state
    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)
    
    if isSelected then
        selectBtn:SetText("✓")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetScript("OnClick", function()
            NextKey222.Addon:SetTeleportTargetKey(keyInfo, { broadcast = true })
        end)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set this keystone as the teleport target.")
            GameTooltip:AddLine("Shares the selection with party members running NextKey.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
    else
        selectBtn:Disable()
        selectBtn:SetAlpha(0.4)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)

    local deleteBtn = nil
    if self:IsDebugMode() and NextKey222.FakePlayerService and ownerName and NextKey222.FakePlayerService:IsFakePlayer(ownerName) then
        deleteBtn = NextKey222.UIComponents:CreateButton(frame, "select_compact", nil, nil)
        deleteBtn:SetText("Del")
        deleteBtn:SetWidth(40)
        deleteBtn:SetPoint("RIGHT", selectBtn, "LEFT", -4, 0)
        deleteBtn:SetScript("OnClick", function()
            self:HandleDeleteFakePlayer(ownerName)
        end)
        deleteBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove this fake player")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
        trackAuxFrame(self, deleteBtn)
    end

    if showCompactIO and compactIORange then
        local anchorButton = deleteBtn or selectBtn
        local ioGainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ioGainText:SetPoint("RIGHT", anchorButton, "LEFT", -6, 0)
        ioGainText:SetText(string.format("|cff00ff00+%d IO|r", math.floor(compactIORange.expected or 0)))
        ioGainText:SetJustifyH("RIGHT")

        local ioGainButton = CreateFrame("Button", nil, frame)
        ioGainButton:SetPoint("TOPLEFT", ioGainText, "TOPLEFT", -2, 2)
        ioGainButton:SetPoint("BOTTOMRIGHT", ioGainText, "BOTTOMRIGHT", 2, -2)
        ioGainButton:SetScript("OnEnter", function(btn)
            self:ShowIOGainTooltip(btn, keyInfo, entry, compactIORange)
        end)
        ioGainButton:SetScript("OnLeave", GameTooltip_Hide)
        ioGainButton:SetFrameLevel(frame:GetFrameLevel() + 1)
        trackAuxFrame(self, ioGainButton)
    end
end

-- MARK: Cleanup & Utility Functions
--
-- Helper functions for frame management, cleanup, and auxiliary operations.

--- Clears all auxiliary frames created for UI elements
-- Properly hides and unparents frame references to prevent memory leaks
function UI:ClearAuxFrames()
    if not self._auxFrames then return end
    for _, frame in ipairs(self._auxFrames) do
        if frame and frame.Hide then
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    wipe(self._auxFrames)
end

-- MARK: Module Interface Functions
function UI:RefreshKeystoneList()
    if self.mainFrame then
        if self.viewMode == "dungeons" then
            self:RenderDungeonCards()
        else
            self:RenderResults()
        end
    end
end

-- MARK: View Mode Management
--
-- Functions for switching between different display modes (players vs dungeons)
-- and managing the related UI state and button text updates.

--- Toggles between keystone view and dungeon information view
-- Updates the toggle button text and triggers appropriate rendering function
function UI:ToggleViewMode()
    Debug:Dev("ui", "ToggleViewMode called, current mode:", self.viewMode or "nil")
    if self.viewMode == "keystones" then
        self.viewMode = "dungeons"
        Debug:Dev("ui", "Switching to dungeon view")
        if self.viewToggleBtn then
            self.viewToggleBtn:SetText("Switch to Keystone View")  -- Show what clicking will do
        end
        -- Update sort dropdown options for dungeon view
        self:UpdateSortDropdownOptions()
        -- Show total score in dungeon view
        if self.totalScoreLabel then
            self.totalScoreLabel:SetText(self:FormatColoredTotalScore(NextKey222.Addon:GetRaiderIOTotalScore()))
        end
        -- Update debug controls visibility (hide fake player buttons in dungeon view)
        self:UpdateDebugControlsVisibility()
        -- Update keystone controls visibility (hide Suggest Groups, Auto Mode, and Guild/Party buttons)
        self:UpdateKeystoneControlsVisibility()
        -- Use centralized dungeon view height
        self:ApplyWindowHeight()
        self:RenderDungeonCards()
    else
        self.viewMode = "keystones"
        if self.viewToggleBtn then
            self.viewToggleBtn:SetText("Switch to Dungeons View")  -- Show what clicking will do
        end
        -- Update sort dropdown options for keystone view
        self:UpdateSortDropdownOptions()
        -- Hide total score in keystone view
        if self.totalScoreLabel then
            self.totalScoreLabel:SetText("")
        end
        -- Update debug controls visibility (show fake player buttons in keystone view if debug is on)
        self:UpdateDebugControlsVisibility()
        -- Update keystone controls visibility (show Suggest Groups, Auto Mode, and Guild/Party buttons if applicable)
        self:UpdateKeystoneControlsVisibility()
        -- Use centralized keystone view height
        self:ApplyWindowHeight()
        self:RenderResults()
    end
end

--- Toggles between party-only and guild-wide keystone filtering
-- Updates the button text and triggers keystone refresh
function UI:ToggleGuildFilter()
    self.showGuildKeys = not self.showGuildKeys
    if self.guildToggleBtn then
        self.guildToggleBtn:SetText(self.showGuildKeys and "Guild Keys" or "Party Keys")
    end
    
    Debug:Dev("ui", "Guild filter toggled:", self.showGuildKeys and "showing guild keys" or "showing party only")
    Debug:Dev("ui", " Guild keys mode:", self.showGuildKeys and "ENABLED" or "DISABLED")
    
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
            
            if self.viewMode == "dungeons" then
                self:RenderDungeonCards()
            else
                self:RenderResults()
            end
        end
        
        -- Refresh after a delay to allow keystones to arrive
        C_Timer.After(2.0, refreshUI)
    else
        -- Immediate refresh when switching to party mode
        Debug:Dev("ui", " Switching to party mode")
        if self.viewMode == "dungeons" then
            self:RenderDungeonCards()
        else
            self:RenderResults()
        end
    end
end

-- MARK: Dungeon Card Rendering
--
-- Functions for rendering dungeon information cards including scores,
-- levels, and seasonal data for each available dungeon.

--- Renders dungeon information cards for the current season
-- Displays dungeon names, best scores, levels, and completion data
function UI:RenderDungeonCards()
    if not self.resultsFrame then
        return
    end

    -- Clear existing content completely
    self:ClearAuxFrames()
    self.resultsFrame:ReleaseChildren()
    
    -- Get current season dungeons
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local seasonName = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.name or "Unknown Season"
    
    -- Update status text (removed season text to save space)
    local count = 0
    for _ in pairs(dungeons) do count = count + 1 end
    Debug:Dev("ui", string.format("Dungeon Cards: Mode: Dungeons | Count: %d", count))
    
    if not next(dungeons) then
        local none = AceGUI:Create("Label")
        none:SetText("No dungeon data available for current season.")
        none:SetFullWidth(true)
        self.resultsFrame:AddChild(none)
        return
    end
    
    -- Sort dungeons based on current sort mode
    local sortedDungeons = {}
    for dungeonID, data in pairs(dungeons) do
        -- Get IO score for each dungeon for sorting
        local ioScore = self:GetRaiderIODungeonScore(dungeonID)
        table.insert(sortedDungeons, {id = dungeonID, data = data, ioScore = ioScore})
    end
    
    -- Apply sorting based on current mode
    local currentSort = self:GetCurrentSortMode()
    if currentSort == "Alphabetical" then
        table.sort(sortedDungeons, function(a, b) return a.data.name < b.data.name end)
    elseif currentSort == "HighestIO" then
        table.sort(sortedDungeons, function(a, b) return (a.ioScore or 0) > (b.ioScore or 0) end)
    elseif currentSort == "LowestIO" then
        table.sort(sortedDungeons, function(a, b) return (a.ioScore or 0) < (b.ioScore or 0) end)
    else
        -- Default to alphabetical if unknown sort mode
        table.sort(sortedDungeons, function(a, b) return a.data.name < b.data.name end)
    end
    
    -- Calculate total IO score from all dungeons
    local totalIOScore = NextKey222.Addon:GetRaiderIOTotalScore()
    
    -- Update total score display
    if self.totalScoreLabel then
        self.totalScoreLabel:SetText(self:FormatColoredTotalScore(totalIOScore))
    end
    
    -- Create enhanced dungeon cards with preferences
    local useCompact = true -- Always use compact for better layout
    -- Use centralized height calculation variables
    local expectedHeight = #sortedDungeons * NextKey222.UIConfig.CARD.HEIGHT + NextKey222.UIConfig.CARD.HEADER_PADDING
    
    Debug:Dev("ui", " Rendering", #sortedDungeons, "enhanced dungeons with preferences")
    Debug:Dev("ui", " Expected total height:", expectedHeight, "px (window height: 640px)")
    Debug:Dev("ui", " Card height: 52px, with icons, IO scores, and preference buttons")
    Debug:Dev("ui", " Total IO Score:", totalIOScore or 0)
    
    for i, dungeon in ipairs(sortedDungeons) do
        if useCompact then
            self:AddDungeonRowCompact(dungeon.id, dungeon.data)
        else
            self:AddDungeonRow(dungeon.id, dungeon.data)
        end
    end
end

-- Enhanced dungeon card with icons and IO scores
function UI:AddDungeonRowCompact(dungeonID, dungeonData)
    -- Use configurable container type for different spacing options
    local containerType = NextKey222.UIConfig.LAYOUT.USE_TIGHT_LAYOUT and "SimpleGroup" or "InlineGroup"
    local container = AceGUI:Create(containerType)
    
    if not NextKey222.UIConfig.LAYOUT.USE_TIGHT_LAYOUT then
        container:SetTitle("") -- Only needed for InlineGroup
    end
    
    container:SetFullWidth(true)
    -- Use centralized dungeon card height
    container:SetHeight(NextKey222.UIConfig.CARD.HEIGHT)
    container:SetLayout("Flow")
    
    -- Apply ultra-tight spacing by modifying frame properties
    if NextKey222.UIConfig.LAYOUT.USE_TIGHT_LAYOUT and NextKey222.UIConfig.LAYOUT.USE_ULTRA_TIGHT and container.content then
        -- Remove extra padding from the container's content frame
        local content = container.content
        if content then
            content:ClearAllPoints()
            content:SetAllPoints(container.frame)
        end
    end
    
    -- Get player's best data and IO score
    local playerScore = self:GetDungeonScore(dungeonID)
    local bestLevel = self:GetBestLevel(dungeonID)
    local ioScore = self:GetDungeonIOScore(dungeonID) -- New function for IO score per dungeon
    
    -- Dungeon icon
    local iconWidget = AceGUI:Create("Icon")
    if dungeonData.mapArtID then
        -- Convert NextKey dungeon ID to proper Challenge Mode map ID for icon lookup
        local challengeModeMapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
        -- Try to get dungeon icon from challenge mode using converted map ID
        local iconTexture = select(4, C_ChallengeMode.GetMapUIInfo(challengeModeMapID)) or "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider"
        iconWidget:SetImage(iconTexture)
    else
        iconWidget:SetImage("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider") -- Default dungeon icon
    end
    -- Use centralized icon size variables
    iconWidget:SetImageSize(NextKey222.UIConfig.ICON.SIZE, NextKey222.UIConfig.ICON.SIZE)
    iconWidget:SetWidth(NextKey222.UIConfig.ICON.WIDTH)
    container:AddChild(iconWidget)
    
    -- Dungeon name (use full name with more space)
    local nameLabel = AceGUI:Create("Label")
    local displayName = dungeonData.name -- Use full name now that we have more width
    nameLabel:SetText(displayName)
    nameLabel:SetFontObject(GameFontNormal)
    -- Use centralized text width variables
    nameLabel:SetWidth(NextKey222.UIConfig.TEXT.NAME_LABEL_WIDTH)
    nameLabel:SetColor(1, 1, 1)
    container:AddChild(nameLabel)
    
    -- IO Score and level display (more compact)
    local infoText = ""
    local infoColor = {0.7, 0.7, 0.7}
    
    local scoreToDisplay = ioScore or playerScore or 0
    
    if scoreToDisplay > 0 then
        -- Get level and chests info for enhanced display
        local level, chests = self:GetDungeonLevelAndChests(dungeonID)
        
        -- Format with chest indicators: + for 1 chest, ++ for 2 chests, +++ for 3+ chests
        local chestIndicator = ""
        if level > 0 then
            if chests >= 3 then
                chestIndicator = " | +++" .. level
            elseif chests >= 2 then
                chestIndicator = " | ++" .. level
            elseif chests >= 1 then
                chestIndicator = " | +" .. level
            else
                chestIndicator = " | " .. level -- No chests (barely timed or untimed)
            end
        end
        
        -- Display IO score with level and chest information
        infoText = string.format("%.0f IO%s", scoreToDisplay, chestIndicator)
        
        -- Use specialized individual dungeon coloring (proportional system)
        infoColor = self:GetDungeonScoreColor(scoreToDisplay)
    else
        -- Show "0 IO" to clearly indicate no IO earned for this dungeon
        infoText = "0 IO"
        infoColor = {0.5, 0.5, 0.5} -- Gray for zero score
    end
    
    local scoreLabel = AceGUI:Create("Label")
    scoreLabel:SetText(infoText)
    scoreLabel:SetFontObject(GameFontNormalSmall)
    -- Use centralized score display width
    scoreLabel:SetWidth(NextKey222.UIConfig.TEXT.SCORE_LABEL_WIDTH)
    scoreLabel:SetColor(infoColor[1], infoColor[2], infoColor[3])
    container:AddChild(scoreLabel)
    
    -- Use centralized button size variables for all buttons
    
    -- Action buttons (teleport and loot)
    local teleBtn = AceGUI:Create("Button")
    teleBtn:SetText("Teleport")
    teleBtn:SetWidth(NextKey222.UIConfig.BUTTON.TELEPORT_WIDTH)
    teleBtn:SetHeight(NextKey222.UIConfig.BUTTON.HEIGHT)
    
    -- Debug: verify button creation
    Debug:Dev("teleport", "Creating teleport button for dungeonID:", dungeonID)
    teleBtn:SetCallback("OnClick", function()
        Debug:Dev("teleport", "Teleport button clicked for dungeonID:", dungeonID)
        
        -- Create a fake keystone that mimics a real keystone for teleport selection
        -- This uses the exact same logic path as working keystone selection
        local fakeKeyInfo = {
            dungeonID = dungeonID,
            level = 0,  -- No level for dungeon portals
            ownerName = "Dungeon Portal",  -- Clear indication this is not a player keystone
            ownerShort = "Portal",
            source = "dungeon_portal",
            class = "MAGE",  -- Neutral class for portals
            io = 0  -- Default IO
        }
        
        -- Debug: check what GetDungeonName returns for this dungeonID
        local dungeonName = NextKey222.Addon:GetDungeonName(dungeonID)
        Debug:Dev("teleport", "Fake keystone created - dungeonID:", dungeonID, "dungeonName:", dungeonName or "nil")
        
        Debug:Dev("teleport", "Setting fake keystone as teleport target:", fakeKeyInfo.dungeonID, fakeKeyInfo.ownerName)
        
        -- Use the exact same method that works for keystone selection
        -- The "dungeon_portal" source prevents automatic UI refresh in SetTeleportTargetKey
        NextKey222.Addon:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
        
        -- Open teleport window which should now show the correct spell
        NextKey222.Addon:ToggleTeleportWindow()
    end)
    container:AddChild(teleBtn)

    local lootBtn = AceGUI:Create("Button")
    lootBtn:SetText("Loot")
    lootBtn:SetWidth(NextKey222.UIConfig.BUTTON.LOOT_WIDTH)
    lootBtn:SetHeight(NextKey222.UIConfig.BUTTON.HEIGHT)
    lootBtn:SetCallback("OnClick", function()
        NextKey222.Addon:HandleLootClick(dungeonID, dungeonData)
    end)
    container:AddChild(lootBtn)
    
    -- Preference buttons after action buttons
    local preference = NextKey222.ProfilesService:GetDungeonPreference(dungeonID)
    
    local likeBtn = AceGUI:Create("Button")
    likeBtn:SetText("+")
    likeBtn:SetWidth(NextKey222.UIConfig.BUTTON.PREFERENCE_WIDTH)
    likeBtn:SetHeight(NextKey222.UIConfig.BUTTON.HEIGHT)
    if preference and preference.liked then
        likeBtn:SetText("|cFF00FF00+|r") -- Green if liked
    end
    likeBtn:SetCallback("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, true)
        self:RenderDungeonCards() -- Refresh to show updated preference
    end)
    container:AddChild(likeBtn)
    
    local dislikeBtn = AceGUI:Create("Button")
    dislikeBtn:SetText("-")
    dislikeBtn:SetWidth(NextKey222.UIConfig.BUTTON.PREFERENCE_WIDTH)
    dislikeBtn:SetHeight(NextKey222.UIConfig.BUTTON.HEIGHT)
    if preference and preference.disliked then
        dislikeBtn:SetText("|cFFFF0000-|r") -- Red if disliked
    end
    dislikeBtn:SetCallback("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, false)
        self:RenderDungeonCards() -- Refresh to show updated preference
    end)
    container:AddChild(dislikeBtn)
    
    -- Add the container to the results frame
    self.resultsFrame:AddChild(container)
    
    -- Add configurable vertical spacing between cards
    if NextKey222.UIConfig.CARD.VERTICAL_SPACING > 0 then
        local spacer = AceGUI:Create("Label")
        spacer:SetText(" ")
        spacer:SetFullWidth(true)
        spacer:SetHeight(NextKey222.UIConfig.CARD.VERTICAL_SPACING)
        self.resultsFrame:AddChild(spacer)
    end
end

function UI:AddDungeonRow(dungeonID, dungeonData)
    local container = AceGUI:Create("SimpleGroup")
    container:SetLayout("Fill")
    container:SetAutoAdjustHeight(false)
    
    local frame = CreateFrame("Frame", nil, container.frame, "BackdropTemplate")
    frame:SetAllPoints(container.frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    
    -- Get player's best scores for this dungeon
    local playerScore = self:GetDungeonScore(dungeonID)
    local bestLevel = self:GetBestLevel(dungeonID)
    
    -- Dungeon name and alias
    local nameText = string.format("%s (%s)", dungeonData.name, dungeonData.alias or "")
    
    -- Score information
    local scoreText = ""
    if playerScore and playerScore > 0 then
        scoreText = string.format("Score: %.0f", playerScore)
        if bestLevel and bestLevel > 0 then
            scoreText = scoreText .. string.format(" | Best: +%d", bestLevel)
        end
    else
        -- Show "Score: 0" instead of "No runs completed" to indicate earned IO
        scoreText = "Score: 0"
    end
    
    -- Loot tracking info (placeholder)
    local lootText = "Loot tracking: Not implemented yet"
    
    local content = AceGUI:Create("SimpleGroup")
    content:SetLayout("List")
    content:SetFullWidth(true)
    content:SetAutoAdjustHeight(true)
    
    -- Dungeon name
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(nameText)
    nameLabel:SetFontObject(GameFontNormalLarge)
    nameLabel:SetFullWidth(true)
    content:AddChild(nameLabel)
    
    -- Score info with proper coloring
    local scoreLabel = AceGUI:Create("Label")
    scoreLabel:SetText(scoreText)
    scoreLabel:SetFullWidth(true)
    
    -- Apply RaiderIO color to the score if available
    if playerScore and playerScore > 0 and NextKey222.RaiderIO then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(playerScore)
        scoreLabel:SetColor(r, g, b)
    elseif playerScore == 0 then
        scoreLabel:SetColor(0.5, 0.5, 0.5) -- Gray for zero score
    end
    
    content:AddChild(scoreLabel)
    
    -- Loot info
    local lootLabel = AceGUI:Create("Label")
    lootLabel:SetText(lootText)
    lootLabel:SetColor(0.7, 0.7, 0.7) -- Gray text
    lootLabel:SetFullWidth(true)
    content:AddChild(lootLabel)
    
    container:AddChild(content)
    self.resultsFrame:AddChild(container)
end

-- MARK: Score & Data Functions Moved
-- Score functions moved to core/scoring.lua
-- ID conversion functions moved to core/utils.lua

--- Gets appropriate color for individual dungeon scores (proportional system)
-- @param score number The individual dungeon IO score
-- @return table RGB color values {r, g, b} (0-1)
function UI:GetDungeonScoreColor(score)
    if not score or score <= 0 then
        return {0.5, 0.5, 0.5} -- Gray for no score
    end
    
    -- Option 1: Try RaiderIO's system but scale appropriately for individual dungeons
    -- RaiderIO expects total scores, so multiply individual score to fit their ranges
    if NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        -- Scale individual score to RaiderIO's total score range
        -- Typical individual: 0-300, typical total: 0-4000
        -- So multiply by ~13 to get proportional coloring
        local scaledScore = score * 13
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(scaledScore)
        return {r, g, b}
    end
    
    -- Option 2: Use WoW's built-in dungeon score color system
    local color = C_ChallengeMode.GetDungeonScoreRarityColor(score * 13) -- Scale for better colors
    if color then
        return {color.r, color.g, color.b}
    end
    
    -- Option 3: Custom gradient system based on typical individual dungeon score ranges
    -- Individual dungeon scores typically range from 0-300+
    if score >= 250 then
        -- Legendary (orange/gold) - very high individual score
        return {1.0, 0.5, 0.0}
    elseif score >= 200 then
        -- Epic (purple) - high score  
        return {0.64, 0.21, 0.93}
    elseif score >= 150 then
        -- Rare (blue) - good score
        return {0.0, 0.44, 0.87}
    elseif score >= 100 then
        -- Uncommon (green) - decent score
        return {0.12, 1.0, 0.0}
    elseif score >= 50 then
        -- Common (white) - low score
        return {1.0, 1.0, 1.0}
    else
        -- Poor (gray) - very low score
        return {0.62, 0.62, 0.62}
    end
end

--- Gets the best level and chests for a dungeon (for display purposes)
-- @param dungeonID number The dungeon ID
-- @return number, number level, chests (0 if not found)
function UI:GetDungeonLevelAndChests(dungeonID)
    -- Check cache first (populated during score calculation)
    if self.dungeonLevelCache and self.dungeonLevelCache[dungeonID] then
        local cached = self.dungeonLevelCache[dungeonID]
        return cached.level or 0, cached.chests or 0
    end
    
    -- Try to get from RaiderIO directly
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            local bestLevel = 0
            local bestChests = 0
            
            -- Use sortedDungeons to find best level and chests
            if mp.sortedDungeons and type(mp.sortedDungeons) == "table" then
                local rioKeystoneID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
                for _, dungeonProfile in ipairs(mp.sortedDungeons) do
                    if dungeonProfile.dungeon then
                        local dungeon = dungeonProfile.dungeon
                        if dungeon.keystone_instance == rioKeystoneID then
                            local level = dungeonProfile.level or 0
                            local chests = dungeonProfile.chests or 0
                            if level > bestLevel then
                                bestLevel = level
                                bestChests = chests
                            end
                        end
                    end
                end
            end
            
            return bestLevel, bestChests
        end
    end
    
    return 0, 0
end

--- Formats total IO score with appropriate coloring (no scaling for total scores)
-- @param totalScore number The total IO score
-- @return string Colored total score text
function UI:FormatColoredTotalScore(totalScore)
    if not totalScore or totalScore <= 0 then
        return "|cFF808080Total IO: 0|r" -- Gray for zero
    end
    
    -- Get color for total score (no scaling needed for total scores)
    local color
    
    -- Try RaiderIO's color system first (designed for total scores)
    if NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(totalScore)
        color = {r, g, b}
    else
        -- Try WoW's built-in system
        local colorObj = C_ChallengeMode.GetDungeonScoreRarityColor(totalScore)
        if colorObj then
            color = {colorObj.r, colorObj.g, colorObj.b}
        else
            -- Fallback to custom ranges for total scores
            if totalScore >= 3000 then
                color = {1.0, 0.5, 0.0} -- Legendary Orange
            elseif totalScore >= 2500 then
                color = {0.64, 0.21, 0.93} -- Epic Purple
            elseif totalScore >= 2000 then
                color = {0.0, 0.44, 0.87} -- Rare Blue
            elseif totalScore >= 1500 then
                color = {0.12, 1.0, 0.0} -- Uncommon Green
            elseif totalScore >= 1000 then
                color = {1.0, 1.0, 1.0} -- Common White
            else
                color = {0.62, 0.62, 0.62} -- Poor Gray
            end
        end
    end
    
    -- Convert to hex color string
    local r, g, b = color[1] * 255, color[2] * 255, color[3] * 255
    local hexColor = string.format("%02x%02x%02x", r, g, b)
    
    return string.format("|cFF%sTotal IO: %.0f|r", hexColor, totalScore)
end

--- Retrieves the player's best score for a specific dungeon
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
--- Helper function to get dungeon score from WoW API (MrMythical approach)
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score for this dungeon from WoW API (0 if none)
function UI:GetRaiderIODungeonScore(dungeonID)
    -- Debug: Only for Ara-Kara to see WoW API data structure  
    local shouldDebug = (dungeonID == 503) -- Only Ara-Kara for cleaner output
    
    -- Convert NextKey dungeon ID to Challenge Mode map ID
    local mapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
    
    if shouldDebug then
        local playerName = UnitName("player")
        Debug:Dev("ui", "[Score Debug] Getting scores for dungeon " .. dungeonID .. " (mapID: " .. mapID .. ") for " .. playerName)
    end
    
    -- Use official WoW API to get season best scores (MrMythical addon approach)
    -- This is much simpler and more reliable than parsing RaiderIO data structures!
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    if shouldDebug then
        Debug:Dev("ui", "[Score Debug] C_MythicPlus.GetSeasonBestForMap(" .. mapID .. ") Results:")
        if intimeInfo then
            Debug:Dev("ui", "[Score Debug]   intimeInfo: level=" .. (intimeInfo.level or "nil") .. ", score=" .. (intimeInfo.dungeonScore or "nil"))
            if intimeInfo.durationSec then
                Debug:Dev("ui", "[Score Debug]   intimeInfo: duration=" .. intimeInfo.durationSec .. " seconds")
            end
        else
            Debug:Dev("ui", "[Score Debug]   intimeInfo: nil")
        end
        if overtimeInfo then
            Debug:Dev("ui", "[Score Debug]   overtimeInfo: level=" .. (overtimeInfo.level or "nil") .. ", score=" .. (overtimeInfo.dungeonScore or "nil"))
            if overtimeInfo.durationSec then
                Debug:Dev("ui", "[Score Debug]   overtimeInfo: duration=" .. overtimeInfo.durationSec .. " seconds")
            end
        else
            Debug:Dev("ui", "[Score Debug]   overtimeInfo: nil")
        end
    end
    
    -- Find the highest score between in-time and overtime runs
    local bestScore = 0
    local bestLevel = 0
    local isInTime = false
    
    if intimeInfo and intimeInfo.dungeonScore then
        bestScore = intimeInfo.dungeonScore
        bestLevel = intimeInfo.level or 0
        isInTime = true
    end
    
    if overtimeInfo and overtimeInfo.dungeonScore and overtimeInfo.dungeonScore > bestScore then
        bestScore = overtimeInfo.dungeonScore
        bestLevel = overtimeInfo.level or 0
        isInTime = false
    end
    
    if shouldDebug and bestScore > 0 then
        Debug:Dev("ui", "[Score Debug] Best score found: " .. bestScore .. " (level +" .. bestLevel .. ", " .. (isInTime and "in-time" or "overtime") .. ")")
    elseif shouldDebug then
        Debug:Dev("ui", "[Score Debug] No runs found for this dungeon")
    end
    
    -- Store level info for display formatting if we found data
    if bestScore > 0 then
        self.dungeonLevelCache = self.dungeonLevelCache or {}
        -- Estimate chests based on timing: in-time = at least 1 chest, overtime = 0 chests
        local estimatedChests = isInTime and 1 or 0
        self.dungeonLevelCache[dungeonID] = {level = bestLevel, chests = estimatedChests}
        
        if shouldDebug then
            Debug:Dev("ui", "[Score Debug] Cached level info: +" .. bestLevel .. " (" .. estimatedChests .. " chests)")
        end
        
        return bestScore
    end
    
    if shouldDebug then
        Debug:Dev("ui", "[Score Debug] No score found via WoW API for dungeon " .. dungeonID)
    end
    
    return 0
end

function UI:GetDungeonScore(dungeonID)
    -- First try to get score from RaiderIO data (most current)
    local raiderIOScore = self:GetRaiderIODungeonScore(dungeonID)
    if raiderIOScore and raiderIOScore > 0 then
        return raiderIOScore
    end
    
    -- Fallback to saved data if RaiderIO data not available
    local addon = NextKey222.Addon
    if not (addon.db and addon.db.char and addon.db.char.mythicPlus) then
        if addon.db and addon.db.global and addon.db.global.debug and addon.db.global.debug.enabled then
            Debug:Dev("ui", " No mythicPlus data for dungeon score")
        end
        return 0
    end
    
    local seasonData = addon.db.char.mythicPlus.seasons
    local activeSeason = addon.db.char.mythicPlus.activeSeason
    
    if seasonData and activeSeason and seasonData[activeSeason] and seasonData[activeSeason].bestLevels then
        local dungeonScores = seasonData[activeSeason].bestLevels[dungeonID]
        if dungeonScores then
            -- Return the higher of fortified/tyrannical scores
            local fort = dungeonScores.fortified and dungeonScores.fortified.score or 0
            local tyr = dungeonScores.tyrannical and dungeonScores.tyrannical.score or 0
            return math.max(fort, tyr)
        end
    end
    return 0
end

--- Helper function to get best key level from RaiderIO profile data
-- @param dungeonID number The dungeon ID to get the level for
-- @return number The best key level for this dungeon from RaiderIO data (0 if none)
function UI:GetRaiderIOBestLevel(dungeonID)
    -- Try direct RaiderIO API access first
    if _G.RaiderIO and _G.RaiderIO.GetProfile then
        local playerName = UnitName("player")
        local realmName = GetRealmName()
        local profile = _G.RaiderIO.GetProfile(playerName, realmName)
        
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            
            -- Method 1: Try sortedDungeons (most reliable)
            if mp.sortedDungeons and type(mp.sortedDungeons) == "table" then
                for _, dungeonProfile in ipairs(mp.sortedDungeons) do
                    if dungeonProfile.dungeon then
                        local dungeon = dungeonProfile.dungeon
                        -- Try multiple ID matching strategies
                        local matches = (
                            dungeon.keystone_instance == dungeonID or
                            dungeon.id == dungeonID or
                            dungeon.instance_map_id == dungeonID
                        )
                        
                        if matches then
                            return dungeonProfile.level or 0
                        end
                    end
                end
            end
            
            -- Method 2: Try dungeon level arrays
            if mp.dungeonTimes and mp.dungeonUpgrades then
                local seasonIndex = NextKey222.Utils:GetSeasonDungeonIndex(dungeonID)
                if seasonIndex then
                    -- Get level from upgrades (which correlates to key level)
                    local upgrades = mp.dungeonUpgrades[seasonIndex] or 0
                    if upgrades > 0 then
                        -- Upgrades typically correspond to key levels in some fashion
                        return upgrades + 1 -- Rough approximation
                    end
                end
            end
        end
    end
    
    -- Fallback to NextKey222 RaiderIO module
    if NextKey222.RaiderIO then
        local profile = NextKey222.RaiderIO:GetProfile(UnitName("player"), GetRealmName())
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            local bestLevel = 0
            
            if mp.fortifiedDungeonScores and mp.fortifiedDungeonScores[dungeonID] then
                bestLevel = math.max(bestLevel, mp.fortifiedDungeonScores[dungeonID].level or 0)
            end
            if mp.tyrannicalDungeonScores and mp.tyrannicalDungeonScores[dungeonID] then
                bestLevel = math.max(bestLevel, mp.tyrannicalDungeonScores[dungeonID].level or 0)
            end
            
            return bestLevel
        end
    end
    
    return 0
end

--- Retrieves the player's best key level for a specific dungeon
-- @param dungeonID number The dungeon ID to get the best level for
-- @return number The highest key level completed for this dungeon (0 if none)
function UI:GetBestLevel(dungeonID)
    -- First try to get level from RaiderIO data (most current)
    local raiderIOLevel = self:GetRaiderIOBestLevel(dungeonID)
    if raiderIOLevel and raiderIOLevel > 0 then
        return raiderIOLevel
    end
    
    -- Fallback to saved data if RaiderIO data not available
    local addon = NextKey222.Addon
    if not (addon.db and addon.db.char and addon.db.char.mythicPlus) then
        return 0
    end
    
    local seasonData = addon.db.char.mythicPlus.seasons
    local activeSeason = addon.db.char.mythicPlus.activeSeason
    
    if seasonData and activeSeason and seasonData[activeSeason] and seasonData[activeSeason].bestLevels then
        local dungeonScores = seasonData[activeSeason].bestLevels[dungeonID]
        if dungeonScores then
            -- Return the higher level of fortified/tyrannical runs
            local fortLevel = dungeonScores.fortified and dungeonScores.fortified.level or 0
            local tyrLevel = dungeonScores.tyrannical and dungeonScores.tyrannical.level or 0
            return math.max(fortLevel, tyrLevel)
        end
    end
    
    return 0
end

--- Retrieves the player's IO score contribution from a specific dungeon
-- @param dungeonID number The dungeon ID to get the IO score for
-- @return number The IO score from this dungeon (0 if none)
function UI:GetDungeonIOScore(dungeonID)
    local currentPlayerName = UnitName("player")
    
    -- Use IOCalculator unified method if available
    if NextKey222.IOCalculator and currentPlayerName then
        local score = NextKey222.IOCalculator:GetPlayerDungeonScore(currentPlayerName, dungeonID)
        if score > 0 then
            return score
        end
    end
    
    -- Fallback to direct RaiderIO integration for current player
    local ioScore = self:GetRaiderIODungeonScore(dungeonID)
    
    if ioScore and ioScore > 0 then
        -- Store in IOCalculator for future use
        if NextKey222.IOCalculator and currentPlayerName then
            NextKey222.IOCalculator:StorePlayerDungeonScore(currentPlayerName, dungeonID, ioScore)
        end
        return ioScore
    end
    
    -- Final fallback to regular dungeon score
    return self:GetDungeonScore(dungeonID) or 0
end

-- MARK: IO Calculation Functions Moved
-- IO calculation logic moved to core/ioCalculator.lua
-- Dungeon preference functions moved to core/profiles.lua

--- Calculate IO gain range for a keystone using existing IOCalculator
-- @param keystoneData table The keystone data (with dungeonID, level, ownerName)
-- @return table IO gain range with min, max, expected values
function UI:CalculateIOGainRange(keystoneData)
    if not keystoneData or not NextKey222.IOCalculator then
        return { min = 0, max = 0, expected = 0 }
    end
    
    -- Get party member names for group calculation
    local partyMembers = NextKey222.Addon:GetPartyMemberNames() or {}
    
    -- Build party profiles using existing profile building logic
    local partyProfiles = {}
    for _, memberName in pairs(partyMembers) do
        if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
            partyProfiles[memberName] = NextKey222.ProfilesService:GetProfile(memberName)
        else
            -- Fallback to simple profile
            partyProfiles[memberName] = { playerName = memberName }
        end
    end
    
    -- Use IOCalculator's existing group range calculation
    local groupRange = NextKey222.IOCalculator:CalculateGroupIORange(keystoneData, partyProfiles)
    
    if groupRange then
        return {
            min = groupRange.min or 0,
            max = groupRange.max or 0,
            expected = groupRange.expected or 0,
            playerBreakdown = groupRange.playerBreakdown
        }
    end
    
    return { min = 0, max = 0, expected = 0 }
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

--- Checks if the main frame is currently visible
-- @return boolean true if the main frame is visible and shown
function UI:IsMainFrameVisible()
    return self.mainFrame and self.mainFrame:IsShown()
end

--- Refreshes the UI results by re-rendering with current data
-- This is useful when party composition changes or data is updated
function UI:RefreshResults()
    -- Always refresh data, even if UI is not visible (for when user opens it later)
    -- Only skip if mainFrame doesn't exist at all
    if not self.mainFrame then
        Debug:Dev("ui", "Skipping refresh - main frame not created yet")
        return
    end

    -- Throttle refreshes to prevent performance issues
    local now = GetTime()
    if self.lastRefreshTime and (now - self.lastRefreshTime) < 1.0 then
        Debug:Dev("ui", "Throttling refresh - too soon since last refresh")
        return
    end
    self.lastRefreshTime = now

    -- Check if we're already refreshing to prevent spam
    if self.refreshing then
        Debug:Dev("ui", "Already refreshing - ignoring duplicate refresh call")
        return
    end

    self.refreshing = true
    Debug:Dev("ui", "Refreshing UI results - clearing cached profile data")

    -- Clear profile cache to force fresh data on refresh
    if NextKey222.UI then
        NextKey222.UI.profileCache = {}
        Debug:Dev("ui", "Cleared profile cache for UI refresh")
    end

    -- Show user notification for IO Gain Potential mode
    if self:IsPartySensitiveSortMode() then
        -- Party composition changed - recalculating IO gain potential
    end

    -- Re-scan keystones first to get latest data
    if NextKey.Keystones and NextKey.Keystones.ScanAllKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanAllKeystones, "Refresh keystone scan")
    end

    -- Only re-render the UI if it's currently visible
    if self:IsMainFrameVisible() then
        Debug:Dev("ui", "UI is visible, re-rendering results")
        NextKey.SafeRun(self.RenderResults, "Refresh render results", self)
    else
        Debug:Dev("ui", "UI not visible, skipping render but data will be fresh when opened")
    end

    self.refreshing = false
    Debug:Dev("ui", "UI refresh completed")
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

--- Initializes the UI module
-- Called during addon startup to set up the UI system
-- @return boolean true if initialization succeeded
function UI:Initialize()
    Debug:Dev("ui", "UI module initialized")

    -- Register for spec change events directly
    local specChangeFrame = CreateFrame("Frame")
    specChangeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    specChangeFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    specChangeFrame:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            Debug:Dev("ui", "PLAYER_SPECIALIZATION_CHANGED event received")
            -- Invalidate profile cache
            if NextKey222.ProfilesService then
                NextKey222.ProfilesService:InvalidateCache()
                Debug:Dev("ui", "Profile cache invalidated due to spec change")
            end
            -- Refresh UI
            C_Timer.After(0.2, function()
                if NextKey222.UI and NextKey222.UI.RefreshResults then
                    NextKey222.UI:RefreshResults()
                    Debug:Dev("ui", "UI refreshed after spec change")
                end
            end)
        elseif event == "GROUP_ROSTER_UPDATE" then
            Debug:Dev("ui", "GROUP_ROSTER_UPDATE event received")
            -- Refresh for group changes
            C_Timer.After(0.2, function()
                if NextKey222.UI and NextKey222.UI.RefreshResults then
                    NextKey222.UI:RefreshResults()
                    Debug:Dev("ui", "UI refreshed after group roster change")
                end
            end)
        end
    end)

    return true
end

-- Slash command for manual debug control refresh (for testing)
SLASH_NEXTKEYREFRESHDEBUG1 = "/nextkeyrefreshdebug"
SlashCmdList["NEXTKEYREFRESHDEBUG"] = function(msg)
    Debug:User("Manual debug controls refresh triggered")
    if NextKey222.UI and NextKey222.UI.RefreshDebugControls then
        NextKey222.UI:RefreshDebugControls()
    else
        Debug:Error("UI module not available for debug refresh")
    end
end

-- Slash command for manual UI refresh (for testing spec change updates)
SLASH_NEXTKEYREFRESH1 = "/nextkeyrefresh"
SlashCmdList["NEXTKEYREFRESH"] = function(msg)
    Debug:User("Manual UI refresh triggered")
    if NextKey222.UI and NextKey222.UI.RefreshResults then
        NextKey222.UI:RefreshResults()
        Debug:User("UI refresh completed")
    else
        Debug:Error("UI module not available for refresh")
    end
end

-- Slash command to simulate spec change (for testing)
SLASH_NEXTKEYTESTSPEC1 = "/nextkeytestspec"
SlashCmdList["NEXTKEYTESTSPEC"] = function(msg)
    Debug:User("Simulating spec change event")
    if NextKey222.ProfilesService then
        -- Invalidate cache as if spec changed
        NextKey222.ProfilesService:InvalidateCache()
        Debug:User("Profile cache invalidated")

        -- Trigger UI refresh
        if NextKey222.UI and NextKey222.UI.RefreshResults then
            NextKey222.UI:RefreshResults()
            Debug:User("UI refresh triggered")
        end
    else
        Debug:Error("ProfilesService not available")
    end
end

return UI

