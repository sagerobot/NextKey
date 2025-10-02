-- MARK: UI Main Module
-- =====================================================
-- Main UI module for NextKey addon
-- Handles player keystone cards, dungeon information display,
-- and view toggling between players and dungeons & loot
-- =====================================================
--
-- MARK: UI SIZE CONFIGURATION GUIDE
-- =================================
-- ALL UI DIMENSIONS ARE NOW CENTRALIZED BELOW!
-- Simply edit the values in the "UI SIZE CONFIGURATION VARIABLES" 
-- section (lines 44-70) to customize all dimensions at once.
--
-- No need to search through the entire file - everything is
-- in one convenient location for easy editing!
--
-- =====================================================
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceGUI = LibStub("AceGUI-3.0")

-- MARK: UI SIZE CONFIGURATION VARIABLES
-- =====================================================
-- Edit these values to customize all UI dimensions in one place
-- All sizes are in pixels unless otherwise noted
-- =====================================================

-- Main Window Dimensions
local WINDOW_WIDTH = 550               -- Overall window width
local WINDOW_HEIGHT = 625               -- Base window height (changes dynamically)

-- Dynamic View Heights  
local DUNGEON_VIEW_HEIGHT = 775         -- Height when showing dungeon cards
local PLAYER_VIEW_HEIGHT = 625        -- Height when showing player keystones

-- Dungeon Card Layout
local DUNGEON_CARD_HEIGHT = 45          -- Height of each individual dungeon card
local CARD_HEIGHT_CALC = 45             -- Used for height calculations (should match above)
local HEADER_PADDING = 20               -- Extra space for headers and padding

-- Icon Configuration
local ICON_SIZE = 32                    -- Dungeon icon image size (32x32px)
local ICON_WIDTH = 40                   -- Icon container width

-- Text Element Widths
local NAME_LABEL_WIDTH = 180            -- Dungeon name display width
local SCORE_LABEL_WIDTH = 90            -- IO score display width

-- Button Dimensions
local BUTTON_HEIGHT = 28                -- Standard height for all buttons
local TELEPORT_WIDTH = 100               -- Teleport button width
local LOOT_WIDTH = 75                  -- Loot button width  
local PREFERENCE_WIDTH = 50             -- Like/Dislike button width

-- Card Spacing & Layout
local CARD_VERTICAL_SPACING = 0         -- Vertical space between dungeon cards (0 = no gap)
local CARD_MARGIN = 0                   -- Margin around each card
local CONTAINER_PADDING = 0             -- Padding inside the main results container
local USE_TIGHT_LAYOUT = true           -- Use SimpleGroup for minimal padding (true = tight, false = styled)
local USE_ULTRA_TIGHT = false            -- Use raw frames for absolute minimal padding (requires USE_TIGHT_LAYOUT = true)

-- Button Configuration
local CLOSE_BUTTON_WIDTH = 80            -- Width of the close button
local CLOSE_BUTTON_HEIGHT = 25           -- Height of the close button
local TOGGLE_BUTTON_WIDTH = 120          -- Width of the toggle button (wider for longer text)
local TOGGLE_BUTTON_HEIGHT = 25          -- Height of the toggle button

-- =====================================================
-- END CONFIGURATION SECTION
-- =====================================================

-- UI module with view mode state
local UI = {
    viewMode = "keystones", -- "keystones" or "dungeons" - controls what cards are displayed
    showGuildKeys = false, -- false = party only, true = guild keys (start with party only)
    mainFrame = nil,      -- Main AceGUI window frame
    resultsFrame = nil,   -- Container for player/dungeon cards
    viewToggleBtn = nil,  -- Button to switch between views
    guildToggleBtn = nil  -- Button to toggle guild/party filter
}
NextKey222.UI = UI
NextKey222.RegisterModule("UI", UI)

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
    NextKey222.Addon:Print("CreateMainFrame called")
    
    if self.mainFrame then 
        NextKey222.Addon:Print("Main frame already exists, skipping creation")
        return 
    end

    NextKey222.Addon:Print("Creating AceGUI Frame...")
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey")
    frame:SetStatusText("UI skeleton - M0.6")
    frame:SetLayout("Flow")
    frame:SetWidth(WINDOW_WIDTH)  -- Use centralized width variable
    frame:SetHeight(WINDOW_HEIGHT) -- Use centralized height variable  
    frame:EnableResize(true)

    -- Standard close button behavior
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        self.mainFrame = nil
        self.resultsFrame = nil
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

    local sortDrop = AceGUI:Create("Dropdown")
    sortDrop:SetLabel("Sort Mode")
    sortDrop:SetList({ 
        HighestKeyLevel = "Highest Key Level", 
        LowestKeyLevel = "Lowest Key Level",
        IOGainPotential = "IO Gain Potential"
    })
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
        NextKey222.Addon:SendSync()
    end)
    controls:AddChild(syncBtn)

    -- Guild/Party Filter Toggle Button
    local guildToggleBtn = AceGUI:Create("Button")
    guildToggleBtn:SetText(self.showGuildKeys and "Guild Keys" or "Party Keys")
    guildToggleBtn:SetAutoWidth(true)
    guildToggleBtn:SetCallback("OnClick", function()
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
    
    -- Add total IO score display
    local totalScoreLabel = AceGUI:Create("Label")
    totalScoreLabel:SetText("")
    totalScoreLabel:SetWidth(120)
    totalScoreLabel:SetFontObject(GameFontNormalLarge)
    totalScoreLabel:SetColor(1, 0.8, 0) -- Gold color
    controls:AddChild(totalScoreLabel)
    self.totalScoreLabel = totalScoreLabel

    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)

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
    self:RenderResults()  -- Show keystones by default
    
    -- Show the frame
    NextKey222.Addon:Print("Showing main frame...")
    frame:Show()
end

-- MARK: Frame Visibility Management
--
-- Functions responsible for showing, hiding, and managing the visibility
-- state of the main UI frame and related components.

--- Toggles the visibility of the main NextKey UI window
-- Creates the main frame if it doesn't exist, then destroys/recreates it on hide
-- Properly releases AceGUI resources and clears auxiliary frames
function UI:ToggleMainFrame()
    NextKey222.Addon:Print("ToggleMainFrame called")
    
    if self.mainFrame then
        NextKey222.Addon:Print("Hiding existing main frame")
        self.mainFrame:Hide()
        AceGUI:Release(self.mainFrame)
        self.mainFrame = nil
        self.resultsFrame = nil
        self:ClearAuxFrames()
    else
        NextKey222.Addon:Print("Creating new main frame")
        self:CreateMainFrame()
    end
end

-- MARK: Individual Player Analysis
--
-- Functions for analyzing and displaying individual player IO improvement potential

-- Individual Player Recommendations function removed - no longer needed
-- Now focusing on group-based keystone ranking by IO gain potential

-- MARK: Data Management & Sorting
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
        NextKey222.Addon:Print("Debug: No results frame found")
        return 
    end

    -- Clearing previous content
    -- Clear existing content
    self:ClearAuxFrames()
    self.resultsFrame:ReleaseChildren()

    -- Get available keys
    local keys = NextKey222.Addon:GetAvailableKeys()
    NextKey222.Addon:Print("[KEY DEBUG] GetAvailableKeys returned", keys and #keys or 0, "keys")
    
    -- Debug: Print all collected keys for troubleshooting
    if keys then
        for i, key in ipairs(keys) do
            NextKey222.Addon:Print(string.format("[KEY DEBUG] Key %d: %s (ID:%s, Level:%s, Source:%s)", 
                i, key.ownerName or "nil", tostring(key.dungeonID), tostring(key.level), key.source or "unknown"))
        end
    end

    -- Update status text
    local mode = self:GetCurrentSortMode()
    if self.mainFrame and self.mainFrame.SetStatusText then
        local count = keys and #keys or 0
        local statusText = string.format("Mode: %s | Keys: %d | M0.6", tostring(mode), count)
        
        -- Add extra info for IO Gain mode
        if mode == "IOGainPotential" then
            local partySize = #(NextKey:GetPartyMemberNames() or {})
            statusText = statusText .. string.format(" | Party: %d", partySize)
        end
        
        self.mainFrame:SetStatusText(statusText)
    end

    if not keys or #keys == 0 then
        local none = AceGUI:Create("Label")
        none:SetText("No keys detected. Enable Debug in options or acquire a keystone.")
        none:SetFullWidth(true)
        self.resultsFrame:AddChild(none)
        return
    end

    -- No longer showing individual recommendations - just rank keystones by group IO gain

    local items = self:SortKeys(keys, mode)
    NextKey222.Addon:Print(string.format("[SORT DEBUG] SortKeys returned %d items for mode %s", 
        items and #items or 0, tostring(mode)))
    
    if items and #items > 0 then
        for i, item in ipairs(items) do
            NextKey222.Addon:Print(string.format("[SORT DEBUG] Item %d: %s, ioGainPotential=%s", 
                i, item.key and item.key.ownerName or "nil", tostring(item.ioGainPotential)))
        end
    end
    
    local useCompactMode = shouldUseCompactMode(#items)
    
    for i, it in ipairs(items) do
        NextKey222.Addon:Print(string.format("[RENDER DEBUG] Attempting to render card %d for %s", 
            i, it.key and it.key.ownerName or "nil"))
        local renderFunc = useCompactMode and self.AddKeyRowCompact or self.AddKeyRow
        local success = NextKey222.SafeRun(renderFunc, "Render keystone card", self, it)
        if not success then
            NextKey222.Addon:Print("Failed to render card for", it.key and it.key.ownerName or "nil")
        else
            NextKey222.Addon:Print(string.format("[RENDER DEBUG] Successfully rendered card for %s", 
                it.key and it.key.ownerName or "nil"))
        end
    end
end

-- MARK: Keystone Card Rendering
--
-- Functions responsible for creating and displaying individual keystone cards
-- with player information, scores, and interactive elements.

--- Creates and renders a keystone card for a single player entry
-- @param entry table The keystone data containing player info, key details, and scores
-- Handles both real player keystones and fake player data for testing
function UI:AddKeyRow(entry)
    -- AddKeyRow processing
    local keyInfo = entry.key
    local dungeonName
    -- Enhanced dungeon name debugging
    NextKey222.Addon:Print(string.format("[DUNGEON DEBUG] %s: dungeonID=%s, level=%s", 
        keyInfo.ownerName or "Unknown", tostring(keyInfo.dungeonID), tostring(keyInfo.level)))
    
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG] GetDungeonName(%d) returned: %s", 
            keyInfo.dungeonID, tostring(dungeonName)))
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    else
        dungeonName = "No Keystone"
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG] %s has dungeonID=%s (showing 'No Keystone')", 
            keyInfo.ownerName or "Unknown", tostring(keyInfo.dungeonID)))
    end
    -- Always use full name with realm (ownerName) for display
    local ownerName = keyInfo.ownerName or "Unknown"
    -- If ownerName doesn't have realm, try to add current realm for same-server players
    if ownerName and not string.find(ownerName, "-") then
        local currentRealm = GetRealmName()
        if currentRealm and currentRealm ~= "" then
            ownerName = ownerName .. "-" .. currentRealm
        end
    end
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Get player IO score (enhanced retrieval)
    local score = 0
    -- Try multiple sources for IO score (LibOpenRaid uses 'rating' field)
    score = keyInfo.rating or keyInfo.rioScore or keyInfo.io or keyInfo.score or 0
    
    -- IO score retrieval (debug logging removed for performance)
    
    -- For the actual player, also try getting current RaiderIO data
    if NextKey222.Addon.IsPlayerOwner and NextKey222.Addon:IsPlayerOwner(ownerName) then
        if self.GetTotalIOScore then
            local playerScore = self:GetTotalIOScore()
            if playerScore and playerScore > score then
                score = playerScore
            end
        end
    end
    
    -- Final score calculated (debug logging removed for performance)
    
    -- Check for RaiderIO data specifically using the proper API
    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(ownerName)
        if profile and profile.mythicKeystoneProfile then
            local rioScore = profile.mythicKeystoneProfile.currentScore
            -- Update score if RaiderIO has a better value
            if rioScore and rioScore > score then
                score = rioScore
            end
        end
    end
    
    -- KeyInfo properties available for debugging if needed
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local ownerColor = classColor and classColor.colorStr or "ffffffff"

    local container = AceGUI:Create("SimpleGroup")
    container:SetFullWidth(true)
    container:SetLayout("Fill")
    container:SetAutoAdjustHeight(false)
    container:SetHeight(88)
    self.resultsFrame:AddChild(container)

    local frame = CreateFrame("Frame", nil, container.frame, "BackdropTemplate")
    frame:SetAllPoints(container.frame)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.55)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    trackAuxFrame(self, frame)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if coords then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end

    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    
    -- Score was calculated above, now display it
    
    local nameDisplay = string.format("|c%s%s|r", ownerColor, ownerName)
    if score > 0 then
        nameDisplay = string.format("%s |cffFFD700(%d)|r", nameDisplay, score)
    end
    nameText:SetText(nameDisplay)
    nameText:SetJustifyH("LEFT")

    -- Add prominent IO gain display for IOGainPotential sort mode
    local ioGainText = nil
    local currentSortMode = self:GetCurrentSortMode()
    if currentSortMode == "IOGainPotential" then
        -- Use pre-calculated range data if available, otherwise calculate
        local ioRange = entry.ioGainRange or self:CalculateIOGainRange(keyInfo)
        if ioRange.expected > 0 then
            ioGainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            ioGainText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -8)
            
            -- Use dynamic formatting based on display mode
            local displayText = self:FormatIOGainDisplay(ioRange)
            ioGainText:SetText(string.format("|cff00ff00%s|r", displayText))
            ioGainText:SetJustifyH("RIGHT")
            
            -- Make it clickable for tooltip
            local ioGainButton = CreateFrame("Button", nil, frame)
            ioGainButton:SetAllPoints(ioGainText)
            ioGainButton:SetScript("OnEnter", function(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:SetText("Group IO Gain Breakdown")
                GameTooltip:AddLine(string.format("Expected: +%d IO", math.floor(ioRange.expected)), 0, 1, 0)
                GameTooltip:AddLine(string.format("Range: +%d to +%d IO", math.floor(ioRange.min), math.floor(ioRange.max)), 1, 1, 1)
                GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                
                -- Add player breakdown
                if ioRange.playerBreakdown then
                    for playerName, breakdown in pairs(ioRange.playerBreakdown) do
                        local shortName = playerName:match("^([^%-]+)") or playerName
                        local gainText = string.format("%s: %s", shortName, breakdown.gainText)
                        GameTooltip:AddLine(gainText, 0.8, 0.8, 0.8)
                    end
                end
                
                GameTooltip:Show()
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

    local selectBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectBtn:SetSize(80, 22)
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    selectBtn:SetText("Select")
    selectBtn:SetMotionScriptsWhileDisabled(true)
    trackAuxFrame(self, selectBtn)

    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)

    if isSelected then
        selectBtn:SetText("Selected")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetAlpha(1)
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
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)
end

--- Creates and renders a compact keystone card for high player counts
-- @param entry table The keystone data containing player info, key details, and scores
-- Uses aliases and condensed layout to save vertical space
function UI:AddKeyRowCompact(entry)
    -- AddKeyRowCompact processing
    local keyInfo = entry.key
    -- Use FULL dungeon names in compact mode (we have horizontal room)
    local dungeonName = "No Key"
    NextKey222.Addon:Print(string.format("[DUNGEON DEBUG COMPACT] %s: dungeonID=%s, level=%s", 
        keyInfo.ownerName or "Unknown", tostring(keyInfo.dungeonID), tostring(keyInfo.level)))
    
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG COMPACT] Calling GetDungeonName with dungeonID: %d", keyInfo.dungeonID))
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG COMPACT] GetDungeonName(%d) returned: %s (type: %s)", 
            keyInfo.dungeonID, tostring(dungeonName), type(dungeonName)))
        
        -- Also try the Blizzard API directly for comparison
        local blizzardName = C_ChallengeMode.GetMapUIInfo(keyInfo.dungeonID)
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG COMPACT] C_ChallengeMode.GetMapUIInfo(%d) returned: %s", 
            keyInfo.dungeonID, tostring(blizzardName)))
        
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    else
        NextKey222.Addon:Print(string.format("[DUNGEON DEBUG COMPACT] Skipping GetDungeonName - dungeonID is %s", tostring(keyInfo.dungeonID)))
    end
    -- Always use full name with realm (ownerName) for display  
    local ownerName = keyInfo.ownerName or "Unknown"
    -- If ownerName doesn't have realm, try to add current realm for same-server players
    if ownerName and not string.find(ownerName, "-") then
        local currentRealm = GetRealmName()
        if currentRealm and currentRealm ~= "" then
            ownerName = ownerName .. "-" .. currentRealm
        end
    end
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Enhanced IO score retrieval (same as regular mode)
    local score = 0
    -- Try multiple sources for IO score (LibOpenRaid uses 'rating' field)
    score = keyInfo.rating or keyInfo.rioScore or keyInfo.io or keyInfo.score or 0
    
    -- IO score retrieval (debug logging removed for performance)
    
    -- For the actual player, also try getting current RaiderIO data
    if NextKey222.Addon.IsPlayerOwner and NextKey222.Addon:IsPlayerOwner(ownerName) then
        if self.GetTotalIOScore then
            local playerScore = self:GetTotalIOScore()
            if playerScore and playerScore > score then
                score = playerScore
            end
        end
    end
    
    -- Final score calculated for compact view (debug logging removed for performance)
    
    -- Check for RaiderIO data specifically using the proper API (compact view)
    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(ownerName)
        if profile and profile.mythicKeystoneProfile then
            local rioScore = profile.mythicKeystoneProfile.currentScore
            -- Update score if RaiderIO has a better value
            if rioScore and rioScore > score then
                score = rioScore
            end
        end
    end
    
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local ownerColor = classColor and classColor.colorStr or "ffffffff"

    local container = AceGUI:Create("SimpleGroup")
    container:SetFullWidth(true)
    container:SetLayout("Fill")
    container:SetAutoAdjustHeight(false)
    container:SetHeight(28) -- Much smaller height for compact mode
    self.resultsFrame:AddChild(container)

    local frame = CreateFrame("Frame", nil, container.frame, "BackdropTemplate")
    frame:SetAllPoints(container.frame)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8, -- Thinner border
        insets = { left = 2, right = 2, top = 2, bottom = 2 }, -- Smaller insets
    })
    frame:SetBackdropColor(0, 0, 0, 0.45)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    trackAuxFrame(self, frame)

    -- Smaller class icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
    if coords then
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    end

    -- Single line with all info: "PlayerName (1234) | Ara +15" 
    local mainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    
    local nameDisplay = string.format("|c%s%s|r", ownerColor, ownerName)
    if score > 0 then
        nameDisplay = string.format("%s |cffFFD700(%d)|r", nameDisplay, score)
    end
    
    local keyDisplay = string.format("|cff4aa3ff%s +%d|r", dungeonName, keyInfo.level or 0)
    
    -- Add IO gain potential display when using that sort mode
    local currentSortMode = self:GetCurrentSortMode()
    local fullText
    if currentSortMode == "IOGainPotential" and entry.ioGainPotential then
        local gainDisplay = string.format("|cff00ff00+%.1f IO|r", entry.ioGainPotential)
        fullText = string.format("%s | %s | %s", nameDisplay, keyDisplay, gainDisplay)
    else
        fullText = string.format("%s | %s", nameDisplay, keyDisplay)
    end
    mainText:SetText(fullText)
    mainText:SetJustifyH("LEFT")

    -- Smaller select button
    local selectBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectBtn:SetSize(50, 18)
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    selectBtn:SetText("Select")
    selectBtn:SetMotionScriptsWhileDisabled(true)
    trackAuxFrame(self, selectBtn)

    -- Same selection logic as regular mode
    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)

    if isSelected then
        selectBtn:SetText("✓")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetAlpha(1)
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
        selectBtn:SetScript("OnClick", nil)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)
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
    if self.viewMode == "keystones" then
        self.viewMode = "dungeons"
        if self.viewToggleBtn then
            self.viewToggleBtn:SetText("Switch to Keystone View")  -- Show what clicking will do
        end
        -- Show total score in dungeon view
        if self.totalScoreLabel then
            self.totalScoreLabel:SetText("|cFFFFD100Total IO: " .. self:GetTotalIOScore() .. "|r")
        end
        -- Use centralized dungeon view height
        if self.mainFrame then
            self.mainFrame:SetHeight(DUNGEON_VIEW_HEIGHT)
        end
        self:RenderDungeonCards()
    else
        self.viewMode = "keystones"
        if self.viewToggleBtn then
            self.viewToggleBtn:SetText("Switch to Dungeons View")  -- Show what clicking will do
        end
        -- Hide total score in keystone view
        if self.totalScoreLabel then
            self.totalScoreLabel:SetText("")
        end
        -- Use centralized keystone view height
        if self.mainFrame then
            self.mainFrame:SetHeight(PLAYER_VIEW_HEIGHT)
        end
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
    
    NextKey222.Debug:Print("ui", "Guild filter toggled:", self.showGuildKeys and "showing guild keys" or "showing party only")
    
    -- Refresh the current view
    if self.viewMode == "dungeons" then
        self:RenderDungeonCards()
    else
        self:RenderResults()
    end
end

-- MARK: Dungeon Card Rendering
--
-- Functions for rendering dungeon information cards including scores,
-- levels, and seasonal data for each available dungeon.

--- Renders dungeon information cards for the current season
-- Displays dungeon names, best scores, levels, and completion data
function UI:RenderDungeonCards()
    NextKey222.Addon:Print("Debug: RenderDungeonCards called")
    if not self.resultsFrame then
        return
    end

    -- Clear existing content completely
    NextKey222.Addon:Print("Debug: Clearing results frame for dungeon view")
    self:ClearAuxFrames()
    self.resultsFrame:ReleaseChildren()
    
    -- Get current season dungeons
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local seasonName = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.name or "Unknown Season"
    
    -- Update status text (removed season text to save space)
    if self.mainFrame and self.mainFrame.SetStatusText then
        local count = 0
        for _ in pairs(dungeons) do count = count + 1 end
        self.mainFrame:SetStatusText(string.format("Mode: Dungeons | Count: %d", count))
    end
    
    if not next(dungeons) then
        local none = AceGUI:Create("Label")
        none:SetText("No dungeon data available for current season.")
        none:SetFullWidth(true)
        self.resultsFrame:AddChild(none)
        return
    end
    
    -- Sort dungeons by name for consistent display
    local sortedDungeons = {}
    for dungeonID, data in pairs(dungeons) do
        table.insert(sortedDungeons, {id = dungeonID, data = data})
    end
    table.sort(sortedDungeons, function(a, b) return a.data.name < b.data.name end)
    
    -- Calculate total IO score from all dungeons
    local totalIOScore = self:GetTotalIOScore(sortedDungeons)
    
    -- Update total score display
    if self.totalScoreLabel then
        self.totalScoreLabel:SetText(string.format("Total IO: %.0f", totalIOScore or 0))
    end
    
    -- Create enhanced dungeon cards with preferences
    local useCompact = true -- Always use compact for better layout
    -- Use centralized height calculation variables
    local expectedHeight = #sortedDungeons * CARD_HEIGHT_CALC + HEADER_PADDING
    
    NextKey222.Addon:Print("Debug: Rendering", #sortedDungeons, "enhanced dungeons with preferences")
    NextKey222.Addon:Print("Debug: Expected total height:", expectedHeight, "px (window height: 640px)")
    NextKey222.Addon:Print("Debug: Card height: 52px, with icons, IO scores, and preference buttons")
    NextKey222.Addon:Print("Debug: Total IO Score:", totalIOScore or 0)
    
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
    local containerType = USE_TIGHT_LAYOUT and "SimpleGroup" or "InlineGroup"
    local container = AceGUI:Create(containerType)
    
    if not USE_TIGHT_LAYOUT then
        container:SetTitle("") -- Only needed for InlineGroup
    end
    
    container:SetFullWidth(true)
    -- Use centralized dungeon card height
    container:SetHeight(DUNGEON_CARD_HEIGHT)
    container:SetLayout("Flow")
    
    -- Apply ultra-tight spacing by modifying frame properties
    if USE_TIGHT_LAYOUT and USE_ULTRA_TIGHT and container.content then
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
        -- Try to get dungeon icon from map art or challenge mode
        local iconTexture = select(4, C_ChallengeMode.GetMapUIInfo(dungeonID)) or "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider"
        iconWidget:SetImage(iconTexture)
    else
        iconWidget:SetImage("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider") -- Default dungeon icon
    end
    -- Use centralized icon size variables
    iconWidget:SetImageSize(ICON_SIZE, ICON_SIZE)
    iconWidget:SetWidth(ICON_WIDTH)
    container:AddChild(iconWidget)
    
    -- Dungeon name (use full name with more space)
    local nameLabel = AceGUI:Create("Label")
    local displayName = dungeonData.name -- Use full name now that we have more width
    nameLabel:SetText(displayName)
    nameLabel:SetFontObject(GameFontNormal)
    -- Use centralized text width variables
    nameLabel:SetWidth(NAME_LABEL_WIDTH)
    nameLabel:SetColor(1, 1, 1)
    container:AddChild(nameLabel)
    
    -- IO Score and level display (more compact)
    local infoText = ""
    local infoColor = {0.7, 0.7, 0.7}
    
    if ioScore and ioScore > 0 then
        if bestLevel and bestLevel > 0 then
            infoText = string.format("%.0f | +%d", ioScore, bestLevel)
        else
            infoText = string.format("%.0f", ioScore)
        end
        infoColor = {0, 1, 0}
    elseif playerScore and playerScore > 0 then
        if bestLevel and bestLevel > 0 then
            infoText = string.format("%.0f | +%d", playerScore, bestLevel)
        else
            infoText = string.format("%.0f", playerScore)
        end
        infoColor = {0, 1, 0}
    else
        infoText = "No runs"
    end
    
    local scoreLabel = AceGUI:Create("Label")
    scoreLabel:SetText(infoText)
    scoreLabel:SetFontObject(GameFontNormalSmall)
    -- Use centralized score display width
    scoreLabel:SetWidth(SCORE_LABEL_WIDTH)
    scoreLabel:SetColor(infoColor[1], infoColor[2], infoColor[3])
    container:AddChild(scoreLabel)
    
    -- Use centralized button size variables for all buttons
    
    -- Action buttons first (teleport and loot)
    local teleBtn = AceGUI:Create("Button")
    teleBtn:SetText("Teleport")
    teleBtn:SetWidth(TELEPORT_WIDTH)
    teleBtn:SetHeight(BUTTON_HEIGHT)
    teleBtn:SetCallback("OnClick", function()
        NextKey222.Addon:HandleTeleportClick(dungeonID, dungeonData)
    end)
    container:AddChild(teleBtn)
    
    local lootBtn = AceGUI:Create("Button")
    lootBtn:SetText("Loot")
    lootBtn:SetWidth(LOOT_WIDTH)
    lootBtn:SetHeight(BUTTON_HEIGHT)
    lootBtn:SetCallback("OnClick", function()
        NextKey222.Addon:HandleLootClick(dungeonID, dungeonData)
    end)
    container:AddChild(lootBtn)
    
    -- Preference buttons after action buttons
    local preference = self:GetDungeonPreference(dungeonID)
    
    local likeBtn = AceGUI:Create("Button")
    likeBtn:SetText("+")
    likeBtn:SetWidth(PREFERENCE_WIDTH)
    likeBtn:SetHeight(BUTTON_HEIGHT)
    if preference and preference.liked then
        likeBtn:SetText("|cFF00FF00+|r") -- Green if liked
    end
    likeBtn:SetCallback("OnClick", function()
        self:ToggleDungeonPreference(dungeonID, true)
        self:RenderDungeonCards() -- Refresh to show updated preference
    end)
    container:AddChild(likeBtn)
    
    local dislikeBtn = AceGUI:Create("Button")
    dislikeBtn:SetText("-")
    dislikeBtn:SetWidth(PREFERENCE_WIDTH)
    dislikeBtn:SetHeight(BUTTON_HEIGHT)
    if preference and preference.disliked then
        dislikeBtn:SetText("|cFFFF0000-|r") -- Red if disliked
    end
    dislikeBtn:SetCallback("OnClick", function()
        self:ToggleDungeonPreference(dungeonID, false)
        self:RenderDungeonCards() -- Refresh to show updated preference
    end)
    container:AddChild(dislikeBtn)
    
    -- Add the container to the results frame
    self.resultsFrame:AddChild(container)
    
    -- Add configurable vertical spacing between cards
    if CARD_VERTICAL_SPACING > 0 then
        local spacer = AceGUI:Create("Label")
        spacer:SetText(" ")
        spacer:SetFullWidth(true)
        spacer:SetHeight(CARD_VERTICAL_SPACING)
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
        scoreText = "No runs completed"
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
    
    -- Score info  
    local scoreLabel = AceGUI:Create("Label")
    scoreLabel:SetText(scoreText)
    scoreLabel:SetFullWidth(true)
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

-- MARK: Score & Data Retrieval
--
-- Utility functions for retrieving player scores, dungeon levels,
-- and other data from saved variables and RaiderIO.

--- Retrieves the player's best score for a specific dungeon
-- @param dungeonID number The dungeon ID to get the score for
-- @return number The best score achieved for this dungeon (0 if none)
function UI:GetDungeonScore(dungeonID)
    -- Get player's best score for this dungeon from saved data
    local addon = NextKey222.Addon
    if not (addon.db and addon.db.char and addon.db.char.mythicPlus) then
        if addon.db and addon.db.global and addon.db.global.debug and addon.db.global.debug.enabled then
            addon:Print("Debug: No mythicPlus data for dungeon score")
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

--- Retrieves the player's best key level for a specific dungeon
-- @param dungeonID number The dungeon ID to get the best level for
-- @return number The highest key level completed for this dungeon (0 if none)
function UI:GetBestLevel(dungeonID)
    -- Get player's best key level for this dungeon
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
    -- Try to get IO score from RaiderIO if available
    local addon = NextKey222.Addon
    if NextKey222.RaiderIO then
        local profile = NextKey222.RaiderIO:GetProfile(addon.playerFullName)
        if profile and profile.mythicKeystoneProfile then
            local keystoneProfile = profile.mythicKeystoneProfile
            
            -- Check for dungeon-specific scores
            if keystoneProfile.fortifiedDungeonScores and keystoneProfile.fortifiedDungeonScores[dungeonID] then
                local fortScore = keystoneProfile.fortifiedDungeonScores[dungeonID].score or 0
                local tyrScore = 0
                if keystoneProfile.tyrannicalDungeonScores and keystoneProfile.tyrannicalDungeonScores[dungeonID] then
                    tyrScore = keystoneProfile.tyrannicalDungeonScores[dungeonID].score or 0
                end
                -- Return higher of the two scores (IO uses best score)
                return math.max(fortScore, tyrScore)
            end
        end
    end
    
    -- Fallback to regular dungeon score if IO not available
    return self:GetDungeonScore(dungeonID)
end

--- Calculates total IO score from all dungeons
-- @param sortedDungeons table Optional array of dungeon data (if nil, gets current season dungeons)
-- @return number Total IO score across all dungeons
function UI:GetTotalIOScore(sortedDungeons)
    local total = 0
    
    if sortedDungeons then
        -- Use provided sorted dungeons
        for _, dungeon in ipairs(sortedDungeons) do
            total = total + self:GetDungeonIOScore(dungeon.id)
        end
    else
        -- Get dungeons for current season directly from PortalData
        local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
        for dungeonID, _ in pairs(dungeons) do
            total = total + self:GetDungeonIOScore(dungeonID)
        end
    end
    
    return total
end

-- MARK: Dungeon Preference Management
--
-- Functions for managing user dungeon preferences (liked/disliked dungeons)

--- Gets the current preference for a specific dungeon
-- @param dungeonID number The dungeon ID
-- @return table|nil Preference table with liked/disliked flags
function UI:GetDungeonPreference(dungeonID)
    if not NextKey.db or not NextKey.db.char or not NextKey.db.char.preferences then
        return nil
    end
    return NextKey.db.char.preferences[dungeonID]
end

--- Toggles dungeon preference (like/dislike)
-- @param dungeonID number The dungeon ID
-- @param isLike boolean True for like, false for dislike
function UI:ToggleDungeonPreference(dungeonID, isLike)
    if not NextKey.db or not NextKey.db.char then
        return
    end
    
    -- Initialize preferences table if needed
    if not NextKey.db.char.preferences then
        NextKey.db.char.preferences = {}
    end
    
    local current = NextKey.db.char.preferences[dungeonID] or {}
    
    if isLike then
        -- Toggle like preference
        if current.liked then
            current.liked = nil -- Remove like if already liked
        else
            current.liked = true
            current.disliked = nil -- Clear dislike if setting like
        end
    else
        -- Toggle dislike preference
        if current.disliked then
            current.disliked = nil -- Remove dislike if already disliked
        else
            current.disliked = true
            current.liked = nil -- Clear like if setting dislike
        end
    end
    
    -- Update timestamp
    current.lastUpdated = time()
    
    -- Save preference (remove empty tables)
    if not current.liked and not current.disliked then
        NextKey.db.char.preferences[dungeonID] = nil
    else
        NextKey.db.char.preferences[dungeonID] = current
    end
    
    NextKey222.Addon:Print(string.format("Dungeon preference updated: %s", 
        current.liked and "Liked" or (current.disliked and "Disliked" or "Neutral")))
end

-- MARK: IO Display Mode Management
--
-- Functions for managing the IO gain display mode (Range/Expected/Min/Max)

--- Gets the current IO display mode
-- @return string The current display mode
function UI:GetIODisplayMode()
    return self.ioDisplayMode or "Range"
end

--- Sets the IO display mode and updates UI
-- @param mode string The new display mode ("Range", "Expected", "Min", "Max")
function UI:SetIODisplayMode(mode)
    self.ioDisplayMode = mode
    
    -- Update button text
    if self.ioDisplayModeBtn then
        self.ioDisplayModeBtn:SetText(mode)
    end
    
    -- Refresh results to update IO displays
    if self:GetCurrentSortMode() == "IOGainPotential" then
        self:RenderResults()
    end
end

--- Cycles through IO display modes
function UI:CycleIODisplayMode()
    local modes = {"Range", "Expected", "Min", "Max"}
    local current = self:GetIODisplayMode()
    
    -- Find current mode index
    local currentIndex = 1
    for i, mode in ipairs(modes) do
        if mode == current then
            currentIndex = i
            break
        end
    end
    
    -- Cycle to next mode
    local nextIndex = (currentIndex % #modes) + 1
    self:SetIODisplayMode(modes[nextIndex])
end

--- Formats IO gain display based on current mode
-- @param ioRange table The IO range data {min, max, expected}
-- @return string Formatted display text
function UI:FormatIOGainDisplay(ioRange)
    local mode = self:GetIODisplayMode()
    
    if mode == "Range" then
        return string.format("+%d-%d IO", math.floor(ioRange.min), math.floor(ioRange.max))
    elseif mode == "Min" then
        return string.format("+%d IO", math.floor(ioRange.min))
    elseif mode == "Max" then
        return string.format("+%d IO", math.floor(ioRange.max))
    else -- Expected
        return string.format("+%d IO", math.floor(ioRange.expected))
    end
end

-- MARK: IO Gain Potential Calculation
--
-- Functions for calculating IO gain potential for group optimization.

--- Calculates the IO gain potential range using MythicPlanner.com logic
-- @param keystone table The keystone data to analyze
-- @return table Range data with min/max/expected and player breakdown
function UI:CalculateIOGainRange(keystone)
    if not keystone or not keystone.dungeonID or not keystone.level then
        return { min = 0, max = 0, expected = 0, playerBreakdown = {} }
    end

    -- Cache key for performance (cache for 1 minute)
    local cacheKey = string.format("range_%d-%d-%d", keystone.dungeonID, keystone.level, math.floor(GetTime() / 60))
    if self.ioRangeCache and self.ioRangeCache[cacheKey] then
        return self.ioRangeCache[cacheKey]
    end

    local groupRange = { min = 0, max = 0, expected = 0, playerBreakdown = {} }
    
    -- Use IOCalculator for accurate range calculation
    if NextKey222.IOCalculator then
        NextKey222.Addon:Print(string.format("[IO DEBUG] IOCalculator available for keystone %s +%d", 
            tostring(keystone.dungeonID), keystone.level or 0))
        
        local partyMembers = NextKey:GetPartyMemberNames()
        NextKey222.Addon:Print(string.format("[IO DEBUG] Party members: %d", #partyMembers))
        
        -- Add keystone owner if not in party (for cross-realm keys)
        if keystone.ownerName then
            local ownerInParty = false
            for _, member in pairs(partyMembers) do
                local memberShort = member:match("^([^%-]+)") or member
                local ownerShort = keystone.ownerName:match("^([^%-]+)") or keystone.ownerName
                if member == keystone.ownerName or memberShort == ownerShort then
                    ownerInParty = true
                    break
                end
            end
            if not ownerInParty then
                table.insert(partyMembers, keystone.ownerName)
            end
        end

        -- Build party profiles for IOCalculator
        local partyProfiles = {}
        for _, memberName in pairs(partyMembers) do
            partyProfiles[memberName] = self:GetPlayerProfileForIOCalculation(memberName)
        end
        
        -- Calculate group range
        local success, result = pcall(NextKey222.IOCalculator.CalculateGroupIORange, NextKey222.IOCalculator, keystone, partyProfiles)
        if success and result then
            groupRange = result
            NextKey222.Addon:Print(string.format("[IO DEBUG] IOCalculator returned: expected=%s", tostring(groupRange.expected)))
        else
            NextKey222.Addon:Print("[IO DEBUG] IOCalculator failed, using fallback")
            groupRange.expected = keystone.level * 15 -- Simple fallback
            groupRange.min = keystone.level * 10
            groupRange.max = keystone.level * 25
        end
    else
        NextKey222.Addon:Print("[IO DEBUG] IOCalculator not available, using fallback")
        -- Fallback to simple calculation if IOCalculator not available
        groupRange.expected = keystone.level * 15 -- Simple fallback
        groupRange.min = keystone.level * 10
        groupRange.max = keystone.level * 25
    end

    -- Cache the result
    if not self.ioRangeCache then
        self.ioRangeCache = {}
    end
    self.ioRangeCache[cacheKey] = groupRange

    return groupRange
end

--- Legacy function for backward compatibility - returns expected value
-- @param keystone table The keystone data to analyze
-- @return number The expected IO gain potential
function UI:CalculateIOGainPotential(keystone)
    local range = self:CalculateIOGainRange(keystone)
    return range.expected
end

--- Gets player profile data formatted for IOCalculator
-- @param playerName string The player name
-- @return table Player profile data for IO calculations
function UI:GetPlayerProfileForIOCalculation(playerName)
    if not NextKey222.RaiderIO then
        NextKey222.Debug:Print("ui", "RaiderIO module not available for", playerName)
        return { dungeonScores = {} }
    end

    -- Try multiple methods to get player profile
    local profile, err
    
    -- First try RaiderIO module
    if NextKey222.RaiderIO then
        profile, err = NextKey222.RaiderIO:GetProfile(playerName)
    end
    
    -- If that fails, try the global RaiderIO addon
    if not profile and RaiderIO and RaiderIO.GetProfile then
        profile = RaiderIO.GetProfile(playerName)
    end
    
    -- Check if this is a fake player
    local fakePlayerData = self:GetFakePlayerData(playerName)
    if fakePlayerData then
        NextKey222.Debug:Print("ui", "Using fake player data for", playerName)
        return self:ConvertFakePlayerDataToProfile(fakePlayerData)
    end
    
    NextKey222.Debug:Print("ui", "Profile for", playerName, ":", profile and "found" or "not found")
    
    if not profile or not profile.mythicKeystoneProfile then
        NextKey222.Debug:Print("ui", "No mythic keystone profile for", playerName)
        return { dungeonScores = {} }
    end

    local keystoneProfile = profile.mythicKeystoneProfile
    local dungeonScores = keystoneProfile.fortifiedDungeonScores or {}
    local tyrannicalScores = keystoneProfile.tyrannicalDungeonScores or {}
    
    local fortCount = 0
    for _ in pairs(dungeonScores) do fortCount = fortCount + 1 end
    local tyrCount = 0  
    for _ in pairs(tyrannicalScores) do tyrCount = tyrCount + 1 end
    NextKey222.Debug:Print("ui", "Fort dungeons for", playerName, ":", fortCount)
    NextKey222.Debug:Print("ui", "Tyr dungeons for", playerName, ":", tyrCount)
    
    -- Combine fort and tyr scores, taking the best of each dungeon
    local combinedScores = {}
    
    -- Process fortified scores
    for dungeonId, scoreData in pairs(dungeonScores) do
        if not combinedScores[dungeonId] then
            combinedScores[dungeonId] = {
                bestScore = scoreData.score or 0,
                bestLevel = scoreData.level or 0,
                timeLimit = scoreData.timeLimit or 1800000 -- Default 30 min in ms
            }
        else
            if (scoreData.score or 0) > combinedScores[dungeonId].bestScore then
                combinedScores[dungeonId].bestScore = scoreData.score or 0
                combinedScores[dungeonId].bestLevel = scoreData.level or 0
            end
        end
    end
    
    -- Process tyrannical scores
    for dungeonId, scoreData in pairs(tyrannicalScores) do
        if not combinedScores[dungeonId] then
            combinedScores[dungeonId] = {
                bestScore = scoreData.score or 0,
                bestLevel = scoreData.level or 0,
                timeLimit = scoreData.timeLimit or 1800000 -- Default 30 min in ms
            }
        else
            if (scoreData.score or 0) > combinedScores[dungeonId].bestScore then
                combinedScores[dungeonId].bestScore = scoreData.score or 0
                combinedScores[dungeonId].bestLevel = scoreData.level or 0
            end
        end
    end

    return {
        dungeonScores = combinedScores
    }
end

--- Gets fake player data if the player is a fake player
-- @param playerName string The player name to check
-- @return table|nil Fake player data or nil if not a fake player
function UI:GetFakePlayerData(playerName)
    if not NextKey222.Addon.db then return nil end
    local dbg = NextKey222.Addon.db.global and NextKey222.Addon.db.global.debug
    if not dbg or not dbg.players then return nil end
    
    for _, player in ipairs(dbg.players) do
        if player.name == playerName then
            return player
        end
    end
    return nil
end

--- Converts fake player data to IOCalculator-compatible format
-- @param fakePlayerData table The fake player data
-- @return table Profile data formatted for IOCalculator
function UI:ConvertFakePlayerDataToProfile(fakePlayerData)
    local dungeonScores = {}
    
    -- Convert fake player 'best' data to IOCalculator format
    if fakePlayerData.best then
        for dungeonId, bestData in pairs(fakePlayerData.best) do
            if bestData.level and bestData.level > 0 then
                -- Estimate score based on level and timing
                local baseScore = self:EstimateScoreFromLevel(bestData.level, bestData.timed, bestData.chests or 0)
                
                dungeonScores[dungeonId] = {
                    bestScore = baseScore,
                    bestLevel = bestData.level,
                    timeLimit = 1800000 -- Default 30 min
                }
            end
        end
    end
    
    return {
        dungeonScores = dungeonScores
    }
end

--- Estimates IO score from key level and completion quality
-- @param level number The key level
-- @param timed boolean Whether the key was timed
-- @param chests number Number of chests (0-3)
-- @return number Estimated IO score
function UI:EstimateScoreFromLevel(level, timed, chests)
    -- Use our IOCalculator to get proper base scores
    if NextKey222.IOCalculator then
        local metrics = NextKey222.IOCalculator:GetDungeonMetrics(level)
        if metrics then
            if not timed then
                return metrics.min -- Untimed
            elseif chests >= 3 then
                return metrics.max -- 3-chest
            elseif chests >= 1 then
                return metrics.base + ((chests - 1) * 5) -- 1-2 chest progression
            else
                return metrics.base -- Barely timed
            end
        end
    end
    
    -- Fallback calculation if IOCalculator not available
    local baseScore = level * 15 + 100
    if not timed then
        return baseScore * 0.8
    elseif chests >= 3 then
        return baseScore * 1.1
    else
        return baseScore
    end
end

--- Legacy function kept for compatibility - now uses IOCalculator internally
-- @param playerName string The player name  
-- @param dungeonID number The dungeon ID
-- @param keyLevel number The keystone level
-- @return number The potential IO gain for this player
function UI:CalculatePlayerIOGain(playerName, dungeonID, keyLevel)
    if NextKey222.IOCalculator then
        local playerProfile = self:GetPlayerProfileForIOCalculation(playerName)
        local keystone = {
            dungeonID = dungeonID,
            level = keyLevel
        }
        return NextKey222.IOCalculator:CalculateKeystoneValue(keystone, playerProfile)
    else
        -- Simple fallback if IOCalculator not available
        return keyLevel * 5
    end
end

--- Test function for IO gain potential calculation using new IOCalculator
-- Creates mock data to test the MythicPlanner.com algorithm
function UI:TestIOGainPotential()
    NextKey222.Addon:Print("=== MythicPlanner.com IO Algorithm Test ===")
    
    if not NextKey222.IOCalculator then
        NextKey222.Addon:Print("ERROR: IOCalculator module not loaded")
        return
    end
    
    -- Test the base calculation formulas
    NextKey222.Addon:Print("Testing base score calculations:")
    local testCases = {
        { level = 10, runTime = 1800000, timeLimit = 1980000, expected = "~334" }, -- Under time
        { level = 7, runTime = 1667000, timeLimit = 1980000, expected = "~271" },  -- MythicPlanner example
        { level = 12, runTime = 2100000, timeLimit = 1800000, expected = "~321" }  -- Overtime
    }
    
    for _, test in ipairs(testCases) do
        local score = NextKey222.IOCalculator:CalculateDungeonScore(test.runTime, test.timeLimit, test.level)
        NextKey222.Addon:Print(string.format("Level %d: %.1f score (expected %s)", test.level, score, test.expected))
    end
    
    -- Test keystone value calculation with mock party data
    local mockKeystones = {
        { dungeonID = 2526, level = 10, ownerName = "TestPlayer1-Stormrage" },
        { dungeonID = 2515, level = 12, ownerName = "TestPlayer2-Stormrage" }, 
        { dungeonID = 2527, level = 8, ownerName = "TestPlayer3-Stormrage" }
    }
    
    NextKey222.Addon:Print("\nTesting keystone values:")
    for i, keystone in ipairs(mockKeystones) do
        local value = self:CalculateIOGainPotential(keystone)
        NextKey222.Addon:Print(string.format("Key %d: +%d dungeon -> %.1f value", 
            i, keystone.level, value))
    end
    
    NextKey222.Addon:Print("=== Test Complete ===")
end

-- MARK: UI State Management
--
-- Functions for managing UI visibility and refresh state.

--- Checks if the main frame is currently visible
-- @return boolean true if the main frame is visible and shown
function UI:IsMainFrameVisible()
    return self.mainFrame and self.mainFrame:IsShown()
end

--- Refreshes the UI results by re-rendering with current data
-- This is useful when party composition changes or data is updated
function UI:RefreshResults()
    if not self:IsMainFrameVisible() then
        NextKey222.Debug:Print("ui", "Skipping refresh - main frame not visible")
        return
    end
    
    -- Throttle refreshes to prevent performance issues
    local now = GetTime()
    if self.lastRefreshTime and (now - self.lastRefreshTime) < 1.0 then
        NextKey222.Debug:Print("ui", "Throttling refresh - too soon since last refresh")
        return
    end
    self.lastRefreshTime = now
    
    -- Check if we're already refreshing to prevent spam
    if self.refreshing then
        NextKey222.Debug:Print("ui", "Already refreshing - ignoring duplicate refresh call")
        return
    end
    
    self.refreshing = true
    NextKey222.Debug:Print("ui", "Refreshing UI results")
    
    -- Show user notification for IO Gain Potential mode
    if self:IsPartySensitiveSortMode() then
        -- Party composition changed - recalculating IO gain potential
    end
    
    -- Re-scan keystones first to get latest data
    if NextKey.Keystones and NextKey.Keystones.ScanAllKeystones then
        NextKey.SafeRun(NextKey.Keystones.ScanAllKeystones, "Refresh keystone scan")
    end
    
    -- Re-render the results
    NextKey.SafeRun(self.RenderResults, "Refresh render results", self)
    
    self.refreshing = false
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

-- MARK: Module Initialization
--
-- Initialization function called during addon startup to prepare the UI module.

--- Initializes the UI module
-- Called during addon startup to set up the UI system
-- @return boolean true if initialization succeeded
function UI:Initialize()
    NextKey222.Debug:Print("ui", "UI module initialized")
    return true
end

return UI

