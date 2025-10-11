local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local AceGUI = LibStub("AceGUI-3.0")

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
    frame:SetWidth(NextKey222.UIConfig.WINDOW.WIDTH)
    frame:SetHeight(NextKey222.UIConfig.WINDOW.BASE_HEIGHT)  
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
            NextKey222.Addon:Print("Communications not available")
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
            NextKey222.Addon:Print("Requesting guild keystones... (requires LibOpenRaid-compatible addons)")
            
            -- Try direct LibOpenRaid request as well as our integration
            if LibStub then
                local lib = LibStub:GetLibrary("LibOpenRaid-1.0", true)
                if lib then
                    lib.RequestKeystoneDataFromGuild()
                end
            end
        elseif not self.showGuildKeys and not IsInGuild() then
            NextKey222.Addon:Print("Not in a guild - cannot show guild keystones")
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
        NextKey222.Debug:Print("ui", "Creating IO score rankings for current player:", playerName)
        
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
        NextKey222.Debug:Print("ui", "Creating key level rankings for party member:", playerName)
        
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
            NextKey222.Debug:Print("ui", "Trying NextKey communication for", playerName)
            
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
        
        NextKey222.Debug:Print("ui", string.format("Player %s dungeon %s: rank %d (value: %d %s)",
            playerName, data.name, rank, data.value, isCurrentPlayer and "IO" or "level"))
    end
    
    NextKey222.Debug:Print("ui", string.format("Created rankings for %s: %d dungeons ranked", 
        playerName, #dungeonData))
    
    return rankings
end

-- Compare two players by their dungeon rankings
function UI:CompareDungeonRankings(playerA, playerB, dungeonID)
    local rankingsA = self:GetDungeonRankings(playerA)
    local rankingsB = self:GetDungeonRankings(playerB)
    
    local rankA = rankingsA[dungeonID] and rankingsA[dungeonID].rank or 0
    local rankB = rankingsB[dungeonID] and rankingsB[dungeonID].rank or 0
    
    NextKey222.Debug:Print("ui", string.format("Dungeon comparison - %s: rank %d, %s: rank %d", 
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
        NextKey222.Debug:Print("ui", "Unknown RaiderIO dungeon name:", dungeonData.name)
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
    local count = keys and #keys or 0
    local statusText = string.format("Mode: %s | Keys: %d | M0.6", tostring(mode), count)
    
    -- Add extra info for IO Gain mode
    if mode == "IOGainPotential" then
        local partySize = #(NextKey:GetPartyMemberNames() or {})
        statusText = statusText .. string.format(" | Party: %d", partySize)
    end
    
    NextKey222.Addon:Print(statusText)

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
        NextKey222.Addon:Print("ERROR: UIComponents not loaded! Check load order.")
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
    
    -- Create class icon using component factory
    local icon = NextKey222.UIComponents:CreateClassIcon(frame, classToken, 32)
    icon:SetPoint("LEFT", 12, 0)
    
    -- Create formatted player name text
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    nameText:SetText(NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score))
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
            
            -- Format IO gain display (simple range format)
            local displayText = string.format("+%d IO", math.floor(ioRange.expected))
            ioGainText:SetText(string.format("|cff00ff00%s|r", displayText))
            ioGainText:SetJustifyH("RIGHT")
            
            -- Make it clickable for tooltip
            local ioGainButton = CreateFrame("Button", nil, frame)
            ioGainButton:SetAllPoints(ioGainText)
            ioGainButton:SetScript("OnEnter", function(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                
                -- Debug: Check where ioRange comes from
                local usedPreCalculated = entry.ioGainRange ~= nil
                print("NextKey TOOLTIP DEBUG: Using", usedPreCalculated and "pre-calculated" or "recalculated", "ioRange")
                if ioRange.playerBreakdown then
                    -- Count players in breakdown
                    local playerCount = 0
                    for _ in pairs(ioRange.playerBreakdown) do
                        playerCount = playerCount + 1
                    end
                    print("NextKey TOOLTIP DEBUG: Player breakdown has", playerCount, "players")
                    for playerName, _ in pairs(ioRange.playerBreakdown) do
                        print("NextKey TOOLTIP DEBUG: Breakdown includes player:", playerName)
                    end
                else
                    print("NextKey TOOLTIP DEBUG: No player breakdown available")
                end
                
                -- Get dungeon name and owner info for enhanced header
                local dungeonName = "Unknown Dungeon"
                local ownerName = keyInfo and keyInfo.ownerName or "Unknown"
                if keyInfo and keyInfo.dungeonID and keyInfo.dungeonID > 0 then
                    dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID) or ("Dungeon " .. keyInfo.dungeonID)
                end
                
                -- Enhanced header with dungeon, level, and owner information
                local keystoneLevel = keyInfo and keyInfo.level or 0
                local headerText = string.format("%s (+%d) - %s's Key", dungeonName, keystoneLevel, ownerName:match("^([^%-]+)") or ownerName)
                GameTooltip:SetText(headerText, 1, 1, 1, 1, true)
                GameTooltip:AddLine("Group IO Gain Potential", 0.9, 0.9, 1)
                
                -- Show simple group IO summary
                GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                GameTooltip:AddLine(string.format("Group IO Gain: +%d", math.floor(ioRange.expected)), 0, 1, 0)
                GameTooltip:AddLine(string.format("Range: +%d to +%d", math.floor(ioRange.min), math.floor(ioRange.max)), 0.8, 0.8, 0.8)
                GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                GameTooltip:AddLine("Individual Player Breakdown:", 0.9, 0.9, 0.9)
                
                -- Add enhanced player breakdown with improved format
                if ioRange.playerBreakdown then
                    for playerName, breakdown in pairs(ioRange.playerBreakdown) do
                        local shortName = playerName:match("^([^%-]+)") or playerName
                        
                        -- Check if this player has valid NextKey data
                        local minGain = breakdown.min or 0
                        local maxGain = breakdown.max or 0
                        
                        -- Get current dungeon-specific IO score using IOCalculator (handles all player types)
                        local currentDungeonIO = 0
                        local dungeonID = keyInfo and keyInfo.dungeonID
                        
                        if dungeonID and NextKey222.IOCalculator then
                            -- IOCalculator handles fake players, communications, and real players properly
                            currentDungeonIO = NextKey222.IOCalculator:GetPlayerDungeonScore(playerName, dungeonID) or 0
                            NextKey222.Debug:Print("tooltip", "Current dungeon IO for", playerName, "dungeon", dungeonID .. ":", currentDungeonIO)
                        end
                        
                        -- Check for fake player addon status first
                        local fakePlayerData = self:GetFakePlayerData(playerName)
                        local hasNextKey = false
                        
                        if fakePlayerData and fakePlayerData.addonStatus then
                            hasNextKey = fakePlayerData.addonStatus.nextkey or false
                        else
                            -- Determine if player has NextKey (valid score data)
                            hasNextKey = (minGain > 0 or maxGain > 0 or currentDungeonIO > 0)
                        end
                        
                        if hasNextKey then
                            -- NextKey user: Single line format with colors
                            local potentialColor = "|cff00ff00" -- Green by default
                            if math.floor(minGain) == 0 and math.floor(maxGain) == 0 then
                                potentialColor = "|cff999999" -- Grey when no potential gain
                            end
                            
                            -- Get highest key level completed for this dungeon
                            local bestLevel = 0
                            local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
                            local isCurrentPlayer = (playerName == currentPlayer) or 
                                                  (playerName:match("^([^%-]+)") == UnitName("player"))
                            
                            if isCurrentPlayer and dungeonID then
                                -- For current player, use GetBestLevel method
                                bestLevel = self:GetBestLevel(dungeonID) or 0
                            elseif fakePlayerData and fakePlayerData.best and dungeonID then
                                -- For fake players, find their highest completed level for this dungeon
                                local bestRun = fakePlayerData.best[dungeonID]
                                if bestRun and bestRun.level then
                                    bestLevel = bestRun.level
                                end
                            end
                            
                            -- Build the player line with best level info
                            local bestLevelText = bestLevel > 0 and string.format(" |cff4aa3ff+%d|r", bestLevel) or ""
                            local playerLine = string.format("%s: %s(+%d-%d Potential IO)|r |cffffff00(Current IO: %d)|r%s", 
                                shortName, 
                                potentialColor,
                                math.floor(minGain), 
                                math.floor(maxGain), 
                                math.floor(currentDungeonIO),
                                bestLevelText)
                            GameTooltip:AddLine(playerLine, 1, 1, 1) -- White text for name
                        else
                            -- Non-NextKey user: Grey "NextKey Not Installed" message
                            local playerLine = string.format("%s: NextKey Not Installed", shortName)
                            GameTooltip:AddLine(playerLine, 0.6, 0.6, 0.6) -- Grey text
                        end
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
        NextKey222.Addon:Print("ERROR: UIComponents not loaded! Check load order.")
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
    
    -- Create smaller class icon
    local icon = NextKey222.UIComponents:CreateClassIcon(frame, classToken, 20)
    icon:SetPoint("LEFT", 8, 0)
    
    -- Create compact single-line text
    local mainText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    
    -- Format combined display text
    local nameDisplay = NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score)
    local keyDisplay = NextKey222.UIComponents:FormatKeystoneDisplay(dungeonName, keyInfo.level)
    
    -- Add IO gain if in IO gain mode
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
    NextKey222.Addon:Print("ToggleViewMode called, current mode:", self.viewMode or "nil")
    if self.viewMode == "keystones" then
        self.viewMode = "dungeons"
        NextKey222.Addon:Print("Switching to dungeon view")
        if self.viewToggleBtn then
            self.viewToggleBtn:SetText("Switch to Keystone View")  -- Show what clicking will do
        end
        -- Update sort dropdown options for dungeon view
        self:UpdateSortDropdownOptions()
        -- Show total score in dungeon view
        if self.totalScoreLabel then
            self.totalScoreLabel:SetText(self:FormatColoredTotalScore(NextKey222.Addon:GetRaiderIOTotalScore()))
        end
        -- Use centralized dungeon view height
        if self.mainFrame then
            self.mainFrame:SetHeight(NextKey222.UIConfig.WINDOW.DUNGEON_VIEW_HEIGHT)
        end
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
        -- Use centralized keystone view height
        if self.mainFrame then
            self.mainFrame:SetHeight(NextKey222.UIConfig.WINDOW.PLAYER_VIEW_HEIGHT)
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
    print("NextKey TOGGLE DEBUG: Guild keys mode:", self.showGuildKeys and "ENABLED" or "DISABLED")
    
    -- When switching to guild mode, request guild keystones
    if self.showGuildKeys then
        print("NextKey TOGGLE DEBUG: Switching to guild mode, requesting guild keystones...")
        
        -- Request guild keystones from multiple sources
        local success = false
        if NextKey222.LibOpenRaidIntegration then
            success = NextKey222.LibOpenRaidIntegration:RequestGuildKeystones()
            NextKey222.Debug:Print("ui", "LibOpenRaid guild keystone request sent:", success and "success" or "failed")
            print("NextKey TOGGLE DEBUG: LibOpenRaid request result:", success and "SUCCESS" or "FAILED")
        end
        
        -- Also request via addon's own guild communication system
        local NextKey = NextKey222.Addon
        if NextKey and NextKey.RequestGuildKeystones then
            local commSuccess = NextKey:RequestGuildKeystones()
            NextKey222.Debug:Print("ui", "Communication guild keystone request sent:", commSuccess and "success" or "failed")
            print("NextKey TOGGLE DEBUG: Communication request result:", commSuccess and "SUCCESS" or "FAILED")
            success = success or commSuccess
        end
        
        -- Clear cached keystones to force refresh
        if NextKey then
            NextKey.cachedKeys = nil
        end
        
        -- Add multiple refresh attempts to catch incoming data
        local refreshAttempts = 0
        local maxAttempts = 3
        
        local function refreshUI()
            refreshAttempts = refreshAttempts + 1
            NextKey222.Debug:Print("ui", "Refreshing UI after guild keystone request - attempt", refreshAttempts)
            print("NextKey TOGGLE DEBUG: Refreshing UI - attempt", refreshAttempts)
            
            if self.viewMode == "dungeons" then
                self:RenderDungeonCards()
            else
                self:RenderResults()
            end
            
            -- Schedule next refresh if we have more attempts
            if refreshAttempts < maxAttempts then
                C_Timer.After(1.5, refreshUI)
            end
        end
        
        -- First refresh after a short delay
        C_Timer.After(0.5, refreshUI)
    else
        -- Immediate refresh when switching to party mode
        print("NextKey TOGGLE DEBUG: Switching to party mode")
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
    NextKey222.Addon:Print(string.format("Dungeon Cards: Mode: Dungeons | Count: %d", count))
    
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
    NextKey222.Debug:Print("teleport", "Creating teleport button for dungeonID:", dungeonID)
    teleBtn:SetCallback("OnClick", function()
        NextKey222.Debug:Print("teleport", "Teleport button clicked for dungeonID:", dungeonID)
        
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
        NextKey222.Debug:Print("teleport", "Fake keystone created - dungeonID:", dungeonID, "dungeonName:", dungeonName or "nil")
        
        NextKey222.Debug:Print("teleport", "Setting fake keystone as teleport target:", fakeKeyInfo.dungeonID, fakeKeyInfo.ownerName)
        
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
        NextKey222.Addon:Print("[Score Debug] Getting scores for dungeon " .. dungeonID .. " (mapID: " .. mapID .. ") for " .. playerName)
    end
    
    -- Use official WoW API to get season best scores (MrMythical addon approach)
    -- This is much simpler and more reliable than parsing RaiderIO data structures!
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)
    
    if shouldDebug then
        NextKey222.Addon:Print("[Score Debug] C_MythicPlus.GetSeasonBestForMap(" .. mapID .. ") Results:")
        if intimeInfo then
            NextKey222.Addon:Print("[Score Debug]   intimeInfo: level=" .. (intimeInfo.level or "nil") .. ", score=" .. (intimeInfo.dungeonScore or "nil"))
            if intimeInfo.durationSec then
                NextKey222.Addon:Print("[Score Debug]   intimeInfo: duration=" .. intimeInfo.durationSec .. " seconds")
            end
        else
            NextKey222.Addon:Print("[Score Debug]   intimeInfo: nil")
        end
        if overtimeInfo then
            NextKey222.Addon:Print("[Score Debug]   overtimeInfo: level=" .. (overtimeInfo.level or "nil") .. ", score=" .. (overtimeInfo.dungeonScore or "nil"))
            if overtimeInfo.durationSec then
                NextKey222.Addon:Print("[Score Debug]   overtimeInfo: duration=" .. overtimeInfo.durationSec .. " seconds")
            end
        else
            NextKey222.Addon:Print("[Score Debug]   overtimeInfo: nil")
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
        NextKey222.Addon:Print("[Score Debug] Best score found: " .. bestScore .. " (level +" .. bestLevel .. ", " .. (isInTime and "in-time" or "overtime") .. ")")
    elseif shouldDebug then
        NextKey222.Addon:Print("[Score Debug] No runs found for this dungeon")
    end
    
    -- Store level info for display formatting if we found data
    if bestScore > 0 then
        self.dungeonLevelCache = self.dungeonLevelCache or {}
        -- Estimate chests based on timing: in-time = at least 1 chest, overtime = 0 chests
        local estimatedChests = isInTime and 1 or 0
        self.dungeonLevelCache[dungeonID] = {level = bestLevel, chests = estimatedChests}
        
        if shouldDebug then
            NextKey222.Addon:Print("[Score Debug] Cached level info: +" .. bestLevel .. " (" .. estimatedChests .. " chests)")
        end
        
        return bestScore
    end
    
    if shouldDebug then
        NextKey222.Addon:Print("[Score Debug] No score found via WoW API for dungeon " .. dungeonID)
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
    NextKey222.Debug:Print("ui", "UI module initialized")
    return true
end

return UI

