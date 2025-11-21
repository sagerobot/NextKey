-- MARK: Module Definition
local _, NextKey222 = ...

local RosterBoard = {}
NextKey222.RosterBoard = RosterBoard
NextKey222.RegisterModule("RosterBoard", RosterBoard)

local AceGUI = LibStub("AceGUI-3.0")
local Debug = NextKey222.Debug

-- MARK: Module State
RosterBoard.mainFrame = nil
RosterBoard.headerSection = nil
RosterBoard.activePoolSection = nil
RosterBoard.optOutSection = nil
RosterBoard.viewMode = nil -- "ORGANIZER" or "PARTICIPANT"
RosterBoard.manualGroupCount = nil  -- nil = auto, number = manual override

-- Poll state
RosterBoard.activePoll = nil

-- Native frame arrays (NEW - replaces AceGUI widget storage)
RosterBoard.benchCards = {}  -- Array of native card frames
RosterBoard.benchContainer = nil  -- Native scrollable container
RosterBoard.benchScrollFrame = nil
RosterBoard.groupSlots = {}  -- [groupIndex][slotIndex] = {frame, card, role, etc}
RosterBoard.groupBackgrounds = {}  -- Array of background textures (visual only)
RosterBoard.groupTitles = {}  -- Array of title label FontStrings
RosterBoard.groupKeystones = {}  -- [groupIndex] = {keystone, playerID}
RosterBoard.allInteractiveFrames = {}  -- Strong references to prevent garbage collection

-- Header controls
RosterBoard.pollButton = nil
RosterBoard.optimizerDropdown = nil
RosterBoard.optimizeButton = nil
RosterBoard.announceButton = nil

-- AceGUI Widget Cleanup: Track all header widgets for proper release
RosterBoard.headerWidgets = {}  -- Store references to all AceGUI widgets created in header

-- Settings
RosterBoard.selectedOptimizerMode = "mode2" -- Default to Balanced
RosterBoard.announceToRaid = true
RosterBoard.announceToGuild = false

-- MARK: Initialization
function RosterBoard:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Initializing Roster Board module (Native Frame Version)")
        
        -- Determine view mode
        self.viewMode = self:DetermineViewMode()
        
        -- Initialize arrays
        self.benchCards = {}
        self.groupSlots = {}
        self.groupBackgrounds = {}
        self.groupTitles = {}
        self.groupKeystones = {}
        self.allInteractiveFrames = {}
        
        -- MARK: Event Registration
        -- Event-Driven Architecture - Register listeners for OrganizerState events
        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            -- Register listener for player added events
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_ADDED", function(event, payload)
                self:OnPlayerAdded(payload)
            end)
            
            -- Register listener for player moved events
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_MOVED", function(event, payload)
                self:OnPlayerMoved(payload)
            end)
            
            -- Register listener for player updated events
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_UPDATED", function(event, payload)
                self:OnPlayerUpdated(payload)
            end)
            
            -- Register listener for poll response received events
            NextKey222.Addon:RegisterMessage("ORGANIZER_POLL_RESPONSE_RECEIVED", function(event, payload)
                self:OnPollResponseReceived(payload)
            end)
            
            -- Register listener for state cleared events
            NextKey222.Addon:RegisterMessage("ORGANIZER_STATE_CLEARED", function(event, payload)
                self:OnStateCleared(payload)
            end)
            
            -- Register listener for profile updates (spec changes, role changes)
            NextKey222.Addon:RegisterMessage("NEXTKEY_PROFILE_UPDATED", function(event, payload)
                self:OnProfileUpdated(payload)
            end)
            
            Debug:Dev("organizer_events", "Registered 6 event listeners (5 organizer + 1 profile)")
        else
            Debug:Error("Cannot register event listeners - AceEvent system not available")
        end
        
        Debug:Dev("organizer_ui", "Roster Board initialized successfully")
        return true
    end, "RosterBoard:Initialize")
end

-- MARK: Event & Refresh
-- Note: Spec change events are handled by ProfilesService (core/profiles.lua:132-302)
-- ProfilesService automatically invalidates cache and triggers UI refresh when specs change
-- This prevents duplicate event handlers and ensures consistent behavior across all UI components

-- MARK: View Mode Detection
function RosterBoard:DetermineViewMode()
    local isLeader = UnitIsGroupLeader("player")
    local isAssistant = UnitIsGroupAssistant("player")
    
    -- If not in a group, consider solo player as organizer
    if not IsInGroup() then
        return "ORGANIZER"
    end
    
    if isLeader or isAssistant then
        return "ORGANIZER"
    else
        return "PARTICIPANT"
    end
end

function RosterBoard:IsOrganizer()
    return self.viewMode == "ORGANIZER"
end

function RosterBoard:IsParticipant()
    return self.viewMode == "PARTICIPANT"
end

-- MARK: Main Frame
-- FULLY NATIVE INTERIOR
function RosterBoard:CreateMainFrame()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "CreateMainFrame called - clearing caches")
        
        -- CRITICAL: Clear ALL caches FIRST, before any profile calls
        if NextKey222.ProfilesService then
            local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
            NextKey222.ProfilesService:InvalidateCache(currentPlayer)
            Debug:Dev("organizer_ui", "Invalidated ProfilesService cache at START of CreateMainFrame")
        end
        if NextKey222.UI then
            NextKey222.UI.profileCache = {}
            Debug:Dev("organizer_ui", "Cleared UI profile cache at START of CreateMainFrame")
        end
        
        -- Release existing frame if present
        if self.mainFrame then
            Debug:Dev("organizer_ui", "Releasing existing frame")
            AceGUI:Release(self.mainFrame)
            self.mainFrame = nil
        end
        
        -- Calculate dynamic sizing
        Debug:Dev("organizer_ui", "Calculating layout")
        local layout = self:CalculateOptimalLayout()
        Debug:Dev("organizer_ui", "Layout calculated - groups:", layout.groupColumns)
        
        -- Create main window container with dynamic size (AceGUI for window chrome only)
        Debug:Dev("organizer_ui", "Creating AceGUI Frame")
        local frame = AceGUI:Create("Frame")
        frame:SetTitle("M+ Group Organizer")
        frame:SetWidth(layout.totalWidth)
        frame:SetHeight(layout.totalHeight)
        frame:SetLayout("Fill")  -- Unused, but required by AceGUI
        frame:EnableResize(false)
        
        -- Set status text using centralized UIConfig system
        local UIConfig = NextKey222 and NextKey222.UIConfig
        if UIConfig and UIConfig.GetStatusMessage then
            frame:SetStatusText(UIConfig:GetStatusMessage("ORGANIZER_WINDOW"))
        else
            -- Fallback if UIConfig not available
            local version = "v0.5.32"
            if NextKey and NextKey.version_full then
                version = NextKey.version_full
            elseif NextKey and NextKey.version then
                version = "v" .. NextKey.version
            end
            frame:SetStatusText(version .. " - M+ Group Organizer - Drag players between bench and groups")
        end
        
        -- Set callback for close button
        frame:SetCallback("OnClose", function(widget)
            self:OnMainFrameClosed(widget)
        end)
        
        -- Store reference
        self.mainFrame = frame
        Debug:Dev("organizer_ui", "Main frame created and stored")
        
        -- Get the native frame for direct content parenting
        -- AceGUI Frames have frame.content for interior content
        local nativeFrame = frame.content or frame.frame
        Debug:Dev("organizer_ui", "Native frame obtained:", nativeFrame and "YES" or "NO")
        
        -- Create all sections as NATIVE frames with manual positioning
        Debug:Dev("organizer_ui", "Creating header section (minimal spacer)...")
        self:CreateHeaderSection(nativeFrame)
        Debug:Dev("organizer_ui", "Header section created")
        
        Debug:Dev("organizer_ui", "Creating active pool section...")
        self:CreateActivePoolSection(nativeFrame)
        Debug:Dev("organizer_ui", "Active pool section created")
        
        -- ACTION BAR REMOVED: All controls now in header (row 2)
        
        Debug:Dev("organizer_ui", "Creating opt-out section...")
        self:CreateOptOutSection(nativeFrame)
        Debug:Dev("organizer_ui", "Opt-out section created")
        
        -- Populate with actual data
        Debug:Dev("organizer_ui", "Populating sections...")
        self:PopulateAllSections()
        Debug:Dev("organizer_ui", "Sections populated")
        
        -- Apply view-specific restrictions
        if self:IsParticipant() then
            self:DisableOrganizerControls()
            self:RequestRosterState()
        end
        
        Debug:Dev("organizer_ui", "Created Roster Board main frame in", self.viewMode, "mode")
        return frame
        
    end, "RosterBoard:CreateMainFrame")
end

function RosterBoard:OnMainFrameClosed(widget)
    Debug:Dev("organizer_ui", "Roster Board closed")
    
    -- DIAGNOSTIC: Track widget cleanup for contamination debugging
    Debug:Dev("ui_contamination", "[ORGANIZER] OnMainFrameClosed called - starting cleanup")
    
    -- CRITICAL: Clear header widgets references
    -- NOTE: Do NOT manually release - AceGUI:Release(widget) automatically releases children
    -- But we need to clear the references to prevent stale widget reuse
    self.headerWidgets = {}
    
    -- DIAGNOSTIC: Count widgets before release
    local widgetCount = 0
    for _ in pairs(self.headerWidgets) do
        widgetCount = widgetCount + 1
    end
    Debug:Dev("ui_contamination", "[ORGANIZER] Header widgets count before cleanup:", widgetCount)
    
    AceGUI:Release(widget)
    self.mainFrame = nil
    
    -- DIAGNOSTIC: Verify cleanup completeness
    Debug:Dev("ui_contamination", "[ORGANIZER] AceGUI:Release completed")
    Debug:Dev("ui_contamination", "[ORGANIZER] mainFrame set to nil:", self.mainFrame == nil)
    
    -- Clean up native frames
    self:CleanupNativeFrames()
    
    -- DIAGNOSTIC: Verify native frame cleanup
    local totalFrames = 0
    if self.benchCards then totalFrames = totalFrames + #self.benchCards end
    if self.groupSlots then
        for _, slots in pairs(self.groupSlots) do
            for _, slot in pairs(slots) do
                totalFrames = totalFrames + 1
            end
        end
    end
    Debug:Dev("ui_contamination", "[ORGANIZER] Native frames remaining after cleanup:", totalFrames)
    
    Debug:Dev("ui_contamination", "[ORGANIZER] Cleanup completed - should be fully isolated")
end

function RosterBoard:CleanupNativeFrames()
    Debug:Dev("ui_contamination", "[ORGANIZER] CleanupNativeFrames called - ENHANCED MEMORY LEAK FIXES")
    
    -- CRITICAL FIX: Enhanced bench card cleanup with script handler nil-ing
    local benchCardCount = 0
    for _, card in ipairs(self.benchCards) do
        if card then
            -- Nil ALL script handlers to break circular references
            card:SetScript("OnDragStart", nil)
            card:SetScript("OnDragStop", nil)
            card:SetScript("OnMouseDown", nil)
            card:SetScript("OnMouseUp", nil)
            card:SetScript("OnEnter", nil)
            card:SetScript("OnLeave", nil)
            card:SetScript("OnClick", nil)
            
            -- Clear all child frames and textures
            for _, child in ipairs({card:GetChildren()}) do
                child:Hide()
                child:SetParent(nil)
            end
            
            for _, region in ipairs({card:GetRegions()}) do
                if region:GetObjectType() == "Texture" then
                    region:SetTexture(nil)
                elseif region:GetObjectType() == "FontString" then
                    region:SetText("")
                end
            end
            
            card:Hide()
            card:SetParent(nil)
            card:ClearAllPoints()
            benchCardCount = benchCardCount + 1
        end
    end
    self.benchCards = {}
    Debug:Dev("ui_contamination", "[ORGANIZER] Enhanced cleanup:", benchCardCount, "bench cards")
    
    -- CRITICAL FIX: Enhanced slot card cleanup
    local slotCount = 0
    for groupIndex, slots in pairs(self.groupSlots) do
        for slotIndex, slot in pairs(slots) do
            if slot.playerCard then
                -- Nil all script handlers
                slot.playerCard:SetScript("OnDragStart", nil)
                slot.playerCard:SetScript("OnDragStop", nil)
                slot.playerCard:SetScript("OnMouseDown", nil)
                slot.playerCard:SetScript("OnMouseUp", nil)
                slot.playerCard:SetScript("OnEnter", nil)
                slot.playerCard:SetScript("OnLeave", nil)
                slot.playerCard:SetScript("OnClick", nil)
                
                slot.playerCard:Hide()
                slot.playerCard:SetParent(nil)
                slot.playerCard:ClearAllPoints()
                slot.playerCard = nil
            end
            
            if slot.frame then
                slot.frame:SetScript("OnEnter", nil)
                slot.frame:SetScript("OnLeave", nil)
                slot.frame:Hide()
                slot.frame:SetParent(nil)
                slot.frame:ClearAllPoints()
            end
            slotCount = slotCount + 1
        end
    end
    self.groupSlots = {}
    Debug:Dev("ui_contamination", "[ORGANIZER] Enhanced cleanup:", slotCount, "slot frames")
    
    -- Clean up header, active pool, and opt-out sections
    if self.headerSection then
        self.headerSection:Hide()
        self.headerSection:SetParent(nil)
        self.headerSection = nil
    end
    
    if self.activePoolSection then
        self.activePoolSection:Hide()
        self.activePoolSection:SetParent(nil)
        self.activePoolSection = nil
    end
    
    if self.optOutSection then
        if self.optOutSection.playerCards then
            for _, card in ipairs(self.optOutSection.playerCards) do
                if card then
                    card:SetScript("OnDragStart", nil)
                    card:SetScript("OnDragStop", nil)
                    card:SetScript("OnMouseDown", nil)
                    card:SetScript("OnMouseUp", nil)
                    card:Hide()
                    card:SetParent(nil)
                    card:ClearAllPoints()
                end
            end
        end
        self.optOutSection:Hide()
        self.optOutSection:SetParent(nil)
        self.optOutSection = nil
    end
    
    -- CRITICAL FIX: Remove strong references and nil script handlers
    if self.allInteractiveFrames then
        for _, frame in ipairs(self.allInteractiveFrames) do
            if frame then
                -- Nil all possible script handlers (use pcall to avoid errors on non-existent handlers)
                pcall(function() frame:SetScript("OnMouseDown", nil) end)
                pcall(function() frame:SetScript("OnMouseUp", nil) end)
                pcall(function() frame:SetScript("OnDragStart", nil) end)
                pcall(function() frame:SetScript("OnDragStop", nil) end)
                pcall(function() frame:SetScript("OnEnter", nil) end)
                pcall(function() frame:SetScript("OnLeave", nil) end)
                pcall(function() frame:SetScript("OnClick", nil) end)
                
                frame:Hide()
                frame:SetParent(nil)
                frame:ClearAllPoints()
            end
        end
    end
    self.allInteractiveFrames = {}
    
    -- Clear all group-related arrays
    self.groupBackgrounds = {}
    self.groupTitles = {}
    self.groupKeystones = {}
    
    Debug:Dev("ui_contamination", "[ORGANIZER] CleanupNativeFrames COMPLETE - memory leak fixes applied")
end

-- MARK: Layout Calculation
-- Uses UIConfig constants
function RosterBoard:CalculateOptimalLayout()
    local benchPlayers = self:GetBenchPlayers() or {}
    local groupedPlayers = self:GetGroupedPlayers() or {}
    local playerCount = #benchPlayers + #groupedPlayers
    
    -- USE MANUAL COUNT IF SET, otherwise auto-calculate
    local neededGroups
    if self.manualGroupCount then
        neededGroups = self.manualGroupCount
    else
        -- ROUND DOWN to only create groups when there are enough players to fill them
        -- 1-5 players = 1 group, 6-10 = 1 group, 11-15 = 2 groups, etc.
        -- Exception: always have at least 1 group, never more than 8
        neededGroups = math.max(1, math.min(math.floor(playerCount / 5), 8))
    end
    
    -- Use centralized UIConfig constants
    local config = NextKey222.UIConfig.ORGANIZER
    local columnWidth = config.COLUMN_WIDTH
    local benchWidth = config.BENCH_WIDTH
    local padding = config.PADDING
    local benchLeftGap = config.BENCH_LEFT_GAP or 30
    local benchRightGap = config.BENCH_RIGHT_GAP or 30
    local headerHeight = config.HEADER_HEIGHT
    local groupHeight = config.GROUP_HEIGHT
    local optOutHeight = config.OPT_OUT_HEIGHT
    local statusBarHeight = config.STATUS_BAR_HEIGHT
    local headerToGroupsGap = config.HEADER_TO_GROUPS_GAP or 20
    
    -- Calculate total width: Left padding + Groups + Bench left gap + Bench + Bench right gap
    -- Calculate total height: Header + Gap + Groups + Gap + OptOut + Gap + Status
    -- ACTION BAR REMOVED: All controls now in header
    local totalWidth = padding + (columnWidth * neededGroups) + benchLeftGap + benchWidth + benchRightGap
    local totalHeight = headerHeight + headerToGroupsGap + groupHeight +
                       config.GROUP_TO_OPTOUT_GAP + optOutHeight +
                       config.OPTOUT_TO_BOTTOM_GAP + statusBarHeight
    
    Debug:Dev("organizer_ui", "Layout - Players:", playerCount, "Groups:", neededGroups, "Window:", totalWidth, "x", totalHeight)
    
    return {
        groupColumns = neededGroups,
        columnWidth = columnWidth,
        benchWidth = benchWidth,
        totalWidth = totalWidth,
        totalHeight = totalHeight,
        headerHeight = headerHeight,
        padding = padding,
        slotHeight = config.SLOT_HEIGHT,
        slotSpacing = config.SLOT_SPACING,
        groupToOptOutGap = config.GROUP_TO_OPTOUT_GAP,
        optOutHeight = optOutHeight,
        statusBarHeight = statusBarHeight
    }
end

function RosterBoard:GetBenchPlayers()
    return NextKey222.BenchManager:get_bench_players(self)
end

function RosterBoard:GetGroupedPlayers()
    return NextKey222.SlotManager:get_grouped_players(self)
end

-- MARK: Data Population
function RosterBoard:PopulateAllSections()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "PopulateAllSections called")
        
        local allPlayers = self:GetBenchPlayers()
        Debug:Dev("organizer_ui", "Got", allPlayers and #allPlayers or 0, "players")
        
        local benchPlayers = allPlayers or {}
        
        if #benchPlayers > 0 then
            Debug:Dev("organizer_ui", "Populating bench with", #benchPlayers, "players")
            self:PopulateBench(benchPlayers)
        end
        
        -- CRITICAL FIX: Restore group slot assignments from OrganizerState
        Debug:Dev("organizer_ui", "Restoring group slot assignments from state")
        
        -- DEBUG: Check if OrganizerState has any group data
        local totalGroupSlots = 0
        if NextKey222.OrganizerState and NextKey222.OrganizerState.groups then
            for gIdx, slots in pairs(NextKey222.OrganizerState.groups) do
                for sIdx, pID in pairs(slots) do
                    totalGroupSlots = totalGroupSlots + 1
                    Debug:Dev("organizer_ui", "State has player in group", gIdx, "slot", sIdx, ":", pID)
                end
            end
        end
        Debug:Dev("organizer_ui", "OrganizerState has", totalGroupSlots, "total players in group slots")
        
        if self.groupSlots then
            local restoredCount = 0
            for groupIndex, slots in pairs(self.groupSlots) do
                for slotIndex, slot in pairs(slots) do
                    -- Get playerID from state (SafeRun returns the value directly, not (success, result))
                    local playerID = NextKey222.OrganizerState:GetSlotPlayer(groupIndex, slotIndex)
                    
                    -- CRITICAL: Check playerID is valid before using it
                    -- SafeRun may return true/false for success, or the actual value
                    -- We only want string playerIDs
                    if type(playerID) == "string" and playerID ~= "" then
                        Debug:Dev("organizer_ui", "Found player in group", groupIndex, "slot", slotIndex, "- playerID:", playerID)
                        -- Fetch full player data object using the playerID
                        local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
                        
                        if playerData and type(playerData) == "table" then
                            -- Create card for this slot using the FULL player data object
                            local card = NextKey222.PlayerCard:CreateNativeCard(
                                playerData,
                                slot,
                                "role_slot",
                                "compact"  -- Start compact, will expand on placement
                            )
                            
                            if card then
                                -- Place card in slot using SlotManager
                                NextKey222.SlotManager:place_card_in_slot(card, slot)
                                restoredCount = restoredCount + 1
                                Debug:Dev("organizer_ui", "Restored player to group", groupIndex, "slot", slotIndex, ":", playerID)
                            else
                                Debug:Error("Failed to create card for slot player:", playerID)
                            end
                        else
                            Debug:Error("GetPlayer returned invalid data for playerID:", playerID, "- type:", type(playerData))
                        end
                    end
                end
            end
            Debug:Dev("organizer_ui", "Restored", restoredCount, "players to group slots")
        end
        
        -- SESSION 4 FIX: Fetch and populate opt-out players from state
        local optOutPlayerIDs = NextKey222.OrganizerState:GetOptOutPlayers()
        local optOutPlayers = {}
        for _, playerID in ipairs(optOutPlayerIDs) do
            local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
            if playerData then
                table.insert(optOutPlayers, playerData)
            end
        end
        
        Debug:Dev("organizer_ui", "Populating opt-out with", #optOutPlayers, "players")
        self:PopulateOptOut(optOutPlayers)
        
    end, "RosterBoard:PopulateAllSections")
end

-- MARK: Header Section
-- Uses UIConfig constants
function RosterBoard:CreateHeaderSection(nativeParent)
    return NextKey222.SafeRun(function()
        -- Use centralized button size constants
        local HEADER_BUTTON_SIZES = NextKey222.UIConfig.ORGANIZER.BUTTON_SIZES
        
        local layout = self:CalculateOptimalLayout()
        local availableWidth = layout.totalWidth - 40
        local hasFakePlayers = NextKey222.FakePlayerService and NextKey222.FakePlayerService:IsEnabled()
        
        -- Create header container (90px height for 2 rows)
        local headerContainer = CreateFrame("Frame", nil, nativeParent)
        headerContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
        headerContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
        headerContainer:SetHeight(90)  -- 2 rows: Poll controls + Organize/Announce
        headerContainer:Show()
        
        -- Row 1: Poll Controls with dynamic progress text
        local pollLabel = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pollLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, 0)
        pollLabel:SetText("POLL CONTROLS")
        pollLabel:SetTextColor(0.6, 0.6, 0.6, 1.0)
        self.pollLabel = pollLabel  -- Store reference for dynamic updates
        
        local row1 = AceGUI:Create("SimpleGroup")
        row1:SetLayout("Flow")
        row1:SetFullWidth(true)
        row1.frame:SetParent(headerContainer)
        row1.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -18)
        row1.frame:SetWidth(availableWidth)
        row1.frame:SetHeight(30)
        row1.frame:Show()
        
        -- Poll button
        local pollButton = AceGUI:Create("Button")
        pollButton:SetText("Poll Group")
        pollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
        pollButton:SetCallback("OnClick", function() self:OnPollGroupClicked() end)
        row1:AddChild(pollButton)
        self.pollButton = pollButton
        
        -- End Poll button
        local endPollButton = AceGUI:Create("Button")
        endPollButton:SetText("End Poll")
        endPollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
        endPollButton:SetCallback("OnClick", function() self:OnEndPollClicked() end)
        row1:AddChild(endPollButton)
        self.endPollButton = endPollButton
        
        -- Clear Poll button
        local clearPollButton = AceGUI:Create("Button")
        clearPollButton:SetText("Clear Poll")
        clearPollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
        clearPollButton:SetCallback("OnClick", function() self:OnClearPollClicked() end)
        row1:AddChild(clearPollButton)
        self.clearPollButton = clearPollButton
        
        -- Debug button (only in DEV_MODE)
        if NextKey222.Debug and NextKey222.Debug.DEV_MODE then
            local fakeRaidButton = AceGUI:Create("Button")
            fakeRaidButton:SetText("Add Raid")
            fakeRaidButton:SetWidth(HEADER_BUTTON_SIZES.DEBUG)
            fakeRaidButton:SetCallback("OnClick", function() self:OnAddFakeRaidClicked() end)
            row1:AddChild(fakeRaidButton)
            self.fakeRaidButton = fakeRaidButton
        end
        
        -- Row 2: Organize/Announce Controls
        local organizeLabel = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        organizeLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -48)
        organizeLabel:SetText("GROUP CONTROLS")
        organizeLabel:SetTextColor(0.6, 0.6, 0.6, 1.0)
        
        local row2 = AceGUI:Create("SimpleGroup")
        row2:SetLayout("Flow")
        row2:SetFullWidth(true)
        row2.frame:SetParent(headerContainer)
        row2.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -66)
        row2.frame:SetWidth(availableWidth)
        row2.frame:SetHeight(30)
        row2.frame:Show()
        
        -- Organize dropdown
        local organizeDropdown = AceGUI:Create("Dropdown")
        organizeDropdown:SetLabel("")
        organizeDropdown:SetList({
            simple_sort = "Simple Sort",
            max_power = "(NYI)Max Power",
            balanced = "(NYI)Balanced",
            vault = "(NYI)Vault Focused"
        })
        organizeDropdown:SetValue("simple_sort")
        organizeDropdown:SetWidth(HEADER_BUTTON_SIZES.DROPDOWN)
        organizeDropdown:SetCallback("OnValueChanged", function(widget, event, value)
            self.selectedOrganizeMode = value
        end)
        row2:AddChild(organizeDropdown)
        self.organizeDropdown = organizeDropdown
        self.selectedOrganizeMode = "simple_sort"
        
        -- Organize button
        local organizeButton = AceGUI:Create("Button")
        organizeButton:SetText("Organize")
        organizeButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
        organizeButton:SetCallback("OnClick", function()
            self:OnOrganizeClicked()
        end)
        row2:AddChild(organizeButton)
        self.organizeButton = organizeButton
        
        -- Announce button
        local announceButton = AceGUI:Create("Button")
        announceButton:SetText("Announce")
        announceButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
        announceButton:SetCallback("OnClick", function()
            self:OnAnnounceClicked()
        end)
        row2:AddChild(announceButton)
        self.announceButton = announceButton
        
        -- Raid checkbox
        local raidCheckbox = AceGUI:Create("CheckBox")
        raidCheckbox:SetLabel("Raid")
        raidCheckbox:SetValue(true)
        raidCheckbox:SetWidth(HEADER_BUTTON_SIZES.CHECKBOX)
        raidCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
            self.announceToRaid = value
        end)
        row2:AddChild(raidCheckbox)
        
        -- Guild checkbox
        local guildCheckbox = AceGUI:Create("CheckBox")
        guildCheckbox:SetLabel("Guild")
        guildCheckbox:SetValue(false)
        guildCheckbox:SetWidth(HEADER_BUTTON_SIZES.CHECKBOX)
        guildCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
            self.announceToGuild = value
        end)
        row2:AddChild(guildCheckbox)
        
        self.headerSection = headerContainer
        self.headerWidgets = {pollButton, endPollButton, clearPollButton, row1, organizeDropdown, organizeButton, announceButton, raidCheckbox, guildCheckbox, row2}
        if NextKey222.Debug and NextKey222.Debug.DEV_MODE and self.fakeRaidButton then
            table.insert(self.headerWidgets, self.fakeRaidButton)
        end
        
        Debug:Dev("organizer_ui", "Created header section (90px, 2 rows)")
        
    end, "RosterBoard:CreateHeaderSection")
end

-- MARK: Obsolete Helpers
-- Header Button Helpers (REMOVED)
-- These functions are no longer needed as buttons are now contextual:
-- - Poll/End/Clear buttons: Inline with bench title (created in benchManager)
-- - Organize button: In bottom bar (created in CreateBottomBar)
-- - Announce/checkboxes: In bottom bar (created in CreateBottomBar)
-- - Debug buttons: In bottom bar (created in CreateBottomBar)

-- MARK: Header Button Handlers
function RosterBoard:OnPollGroupClicked()
    return NextKey222.SafeRun(function()
        -- Check if fake players are enabled (allows solo testing)
        local hasFakePlayers = NextKey222.FakePlayerService and
                               NextKey222.FakePlayerService:IsEnabled() and
                               #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
        
        -- Validate we're in a group (or have fake players for testing)
        local groupSize = GetNumGroupMembers()
        if groupSize < 2 and not hasFakePlayers then
            Debug:User("You must be in a group to poll members")
            return
        end
        
        -- Override groupSize when using fake players
        if hasFakePlayers then
            groupSize = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1  -- +1 for organizer
        end
        
        -- LAZY INITIALIZATION: Enable fake player protocol FIRST if fake players exist
        local hasFakePlayers = NextKey222.FakePlayerService and
                               NextKey222.FakePlayerService:IsEnabled() and
                               #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
        
        if hasFakePlayers then
            -- Initialize fake player auto-response systems (lazy - only on first poll)
            if NextKey222.FakePlayerService.EnablePollProtocol and
               not NextKey222.FakePlayerService.pollProtocolInitialized then
                NextKey222.FakePlayerService:EnablePollProtocol()
                Debug:Dev("organizer", "Enabled FakePlayerService poll protocol")
            end
            
            if NextKey222.PollSimulator and NextKey222.PollSimulator.EnablePollProtocol and
               not NextKey222.PollSimulator.pollProtocolInitialized then
                NextKey222.PollSimulator:EnablePollProtocol()
                Debug:Dev("organizer", "Enabled PollSimulator poll protocol")
            end
        end
        
        -- Generate unique poll ID
        local pollID = self:GeneratePollID()
        
        -- Initialize poll state
        self.activePoll = {
            id = pollID,
            startTime = GetTime(),
            responses = {},
            addonUsers = {},
            nonAddonUsers = {},
            addonUserCount = 0,
            totalMembers = groupSize,
            timeout = 60,
            discoveryComplete = false
        }
        
        Debug:Dev("organizer", string.format("Starting poll %s for %d members", pollID, groupSize))
        
        -- PHASE 1: Discovery Protocol
        -- Send ADDON_PING to discover who has addon installed
        Debug:Dev("organizer", "Starting addon discovery phase...")
        NextKey222.ParticipantSurvey:SendAddonPing(pollID)
        
        -- FakePlayerService will automatically respond with PONGs (if protocol enabled)
        -- Real players will respond via OnAddonPing handler
        
        -- Early completion system for discovery phase
        local discoveryStartTime = GetTime()
        local expectedPongs = self.activePoll.totalMembers - 1  -- Organizer doesn't PONG themselves
        local discoveryTicker  -- Declare before NewTicker so it's accessible in callback
        
        Debug:Dev("organizer", string.format(
        	"Discovery phase started - expecting %d PONGs from %d total members",
        	expectedPongs, self.activePoll.totalMembers
        ))
        
        -- Periodic check for early completion (every 0.1 seconds)
        discoveryTicker = C_Timer.NewTicker(0.1, function()
        	-- Validate poll still active
        	if not self.activePoll or self.activePoll.id ~= pollID then
        		discoveryTicker:Cancel()
        		Debug:Dev("organizer", "Discovery cancelled - poll no longer active")
        		return
        	end
        	
        	-- Count current PONGs received
        	local pongCount = 0
        	if self.activePoll.addonUsers then
        		for _ in pairs(self.activePoll.addonUsers) do
        			pongCount = pongCount + 1
        		end
        	end
        	
        	-- Calculate elapsed time
        	local elapsed = GetTime() - discoveryStartTime
        	
        	-- Check completion conditions
        	local allPongsReceived = (pongCount >= expectedPongs)
        	local timeoutReached = (elapsed >= 3)
        	
        	-- Complete if all PONGs received OR timeout reached
        	if allPongsReceived or timeoutReached then
        		discoveryTicker:Cancel()
        		
        		Debug:Dev("organizer", string.format(
        			"Discovery %s: %d/%d PONGs received in %.2fs",
        			allPongsReceived and "COMPLETE" or "TIMEOUT",
        			pongCount, expectedPongs, elapsed
        		))
        		
        		-- PHASE 2: Complete Discovery
        		local success, addonUsers, nonAddonUsers = NextKey222.ParticipantSurvey:CompleteDiscovery()
        		
        		if not success then
        			Debug:Error("Discovery failed - aborting poll")
        			return
        		end
        		
        		self.activePoll.addonUsers = addonUsers
        		self.activePoll.nonAddonUsers = nonAddonUsers
        		self.activePoll.addonUserCount = #addonUsers
        		self.activePoll.discoveryComplete = true
        		
        		Debug:Dev("organizer", string.format("Discovery complete: %d addon users, %d non-addon users",
        			#addonUsers, #nonAddonUsers))
        		
        		-- PHASE 3: Send Poll Request (to addon users only)
        		if #addonUsers > 0 then
        			NextKey222.ParticipantSurvey:SendPollRequest(pollID)
        			-- PollSimulator will automatically respond for fake players
        			-- Real players will show survey dialog
        			
        			-- CRITICAL: Organizer must manually show themselves the survey dialog
        			-- (they don't receive their own RAID messages)
        			local organizerID = UnitName("player") .. "-" .. GetRealmName()
        			Debug:Dev("organizer", "Showing survey dialog for organizer (self)")
        			local pollMessage = {
        				pollID = pollID,
        				timeout = 60,
        				organizerName = organizerID
        			}
        			NextKey222.ParticipantSurvey:ShowSurveyDialog(pollMessage)
        		else
        			Debug:User("No addon users found - cannot send poll")
        		end
        		
        		-- PHASE 4: Non-addon players already on bench (no poll needed for them)
        		-- They will use their current spec as default role preference
        		Debug:Dev("organizer", "Non-addon players detected:", #nonAddonUsers, "- using default roles")
        		
        		-- Start timeout timer
        		self:StartPollTimeout()
        		
        		-- Update UI
        		self:ShowPollInProgress()
        		self:UpdatePollProgress()
        	end
        end)
        
        Debug:Dev("organizer", "Started poll with unified protocol - ID:", pollID)
        
    end, "RosterBoard:OnPollGroupClicked")
end

function RosterBoard:GeneratePollID()
    -- Create unique ID: Timestamp + Random
    return tostring(time()) .. "-" .. tostring(math.random(1000, 9999))
end

function RosterBoard:RunAutoDetection()
    -- Use auto-detection from Phase 0
    if not NextKey222.OrganizerAutoDetection then
        Debug:Dev("organizer", "Auto-detection not available")
        return
    end
    
    local nonAddonPlayers = NextKey222.OrganizerAutoDetection:ScanForNonAddonPlayers()
    
    if nonAddonPlayers then
        -- Add to bench immediately with indicator
        for _, playerData in ipairs(nonAddonPlayers) do
            playerData.dataSource = "auto-detected"
            self:AddPlayerToBench(playerData)
        end
        
        Debug:Dev("organizer", "Auto-detected", #nonAddonPlayers, "non-addon players")
    end
end

function RosterBoard:StartPollTimeout()
    self.pollTimeoutTimer = C_Timer.NewTimer(60, function()
        self:OnPollTimeout()
    end)
end

function RosterBoard:OnPollTimeout()
    Debug:User("Poll timeout reached. Processing responses...")
    self:CompletePoll()
end

function RosterBoard:ShowPollInProgress()
	-- Disable poll button and set to grey "Polling" state
	if self.pollButton then
		self.pollButton:SetDisabled(true)
		self.pollButton:SetText("Polling")
	end
	
	-- Disable organize button during poll
	if self.organizeButton then
		self.organizeButton:SetDisabled(true)
		-- Set tooltip explaining why it's disabled
		self.organizeButton.frame:SetScript("OnEnter", function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_TOP")
			GameTooltip:SetText("Organize Disabled", 1, 1, 1)
			GameTooltip:AddLine("Wait for the spec preference poll to complete or end it early with 'End Poll'.", nil, nil, nil, true)
			GameTooltip:Show()
		end)
		self.organizeButton.frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	-- Update poll label with descriptive progress
	if self.pollLabel then
		local hasFakePlayers = NextKey222.FakePlayerService and
		                       NextKey222.FakePlayerService:IsEnabled() and
		                       #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
		
		if hasFakePlayers then
			-- Debug mode: descriptive format
			local totalMembers = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1
			self.pollLabel:SetText("POLL CONTROLS - Waiting for responses: 0/" .. totalMembers .. " members")
		else
			-- Production mode: descriptive format with handshake data
			if self.activePoll and self.activePoll.addonUserCount then
				local addonUsers = self.activePoll.addonUserCount
				local totalMembers = self.activePoll.totalMembers
				self.pollLabel:SetText("POLL CONTROLS - Waiting for responses: 0/" .. addonUsers .. " addon users (" .. totalMembers .. " total members)")
			else
				-- Fallback during handshake phase
				local totalMembers = GetNumGroupMembers()
				self.pollLabel:SetText("POLL CONTROLS - Discovering addon users: 0/" .. totalMembers .. " members checked")
			end
		end
	end
end

function RosterBoard:UpdatePollProgress()
    if not self.activePoll then
        return
    end
    
    -- Update poll label with descriptive progress (button stays grey "Polling")
    if self.pollLabel then
        local hasFakePlayers = NextKey222.FakePlayerService and
                               NextKey222.FakePlayerService:IsEnabled() and
                               #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
        
        local responses = #self.activePoll.responses
        
        if hasFakePlayers then
            -- Debug mode: descriptive format
            local totalMembers = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1
            local remaining = totalMembers - responses
            if remaining > 0 then
                self.pollLabel:SetText("POLL CONTROLS - Responses received: " .. responses .. "/" .. totalMembers .. " (" .. remaining .. " waiting)")
            else
                self.pollLabel:SetText("POLL CONTROLS - All responses received: " .. responses .. "/" .. totalMembers)
            end
            
            -- Check if complete
            if responses >= totalMembers then
                self:CompletePoll()
            end
        else
            -- Production mode: descriptive format with handshake data
            if self.activePoll.addonUserCount then
                local addonUsers = self.activePoll.addonUserCount
                local totalMembers = self.activePoll.totalMembers
                local remaining = addonUsers - responses
                
                if remaining > 0 then
                    self.pollLabel:SetText("POLL CONTROLS - Responses received: " .. responses .. "/" .. addonUsers .. " addon users (" .. remaining .. " waiting, " .. totalMembers .. " total members)")
                else
                    self.pollLabel:SetText("POLL CONTROLS - All responses received: " .. responses .. "/" .. addonUsers .. " addon users (" .. totalMembers .. " total members)")
                end
                
                -- Check if complete (all ADDON users responded)
                if responses >= addonUsers then
                    self:CompletePoll()
                end
            else
                -- Fallback (shouldn't happen in production)
                local totalMembers = GetNumGroupMembers()
                local remaining = totalMembers - responses
                if remaining > 0 then
                    self.pollLabel:SetText("POLL CONTROLS - Responses received: " .. responses .. "/" .. totalMembers .. " (" .. remaining .. " waiting)")
                else
                    self.pollLabel:SetText("POLL CONTROLS - All responses received: " .. responses .. "/" .. totalMembers)
                end
                
                if responses >= totalMembers then
                    self:CompletePoll()
                end
            end
        end
    end
    
    -- REAL-TIME VISUAL FEEDBACK: Refresh all bench cards to update "Polling..." states
    -- This makes cards grey out when waiting and return to normal when they respond
    self:RefreshBenchCardsFromState()
end

function RosterBoard:CompletePoll()
    if not self.activePoll then return end
    
    -- Cancel timeout timer
    if self.pollTimeoutTimer then
        self.pollTimeoutTimer:Cancel()
        self.pollTimeoutTimer = nil
    end
    
    -- Re-enable poll button and reset label
    if self.pollButton then
        self.pollButton:SetDisabled(false)
        self.pollButton:SetText("Poll Group")
    end
    
    if self.pollLabel then
        self.pollLabel:SetText("POLL CONTROLS")
    end
    
    -- Re-enable organize button and clear tooltip
    if self.organizeButton then
        self.organizeButton:SetDisabled(false)
        self.organizeButton.frame:SetScript("OnEnter", nil)
        self.organizeButton.frame:SetScript("OnLeave", nil)
    end
    
    -- Show completion message
    local totalResponses = #self.activePoll.responses
    
    -- Calculate expected total (include organizer)
    local totalMembers = GetNumGroupMembers()
    local hasFakePlayers = NextKey222.FakePlayerService and
                           NextKey222.FakePlayerService:IsEnabled() and
                           #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
    
    if hasFakePlayers then
        totalMembers = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1  -- +1 for organizer
    end
    
    Debug:User("Poll complete: " .. totalResponses .. "/" .. totalMembers .. " members responded")
    
    -- Clear active poll
    self.activePoll = nil
    
    -- SESSION 3 FIX: Refresh cards to fetch poll data from OrganizerState
    -- Cards now fetch from state, so we need to trigger UpdateCardContent() to show visual changes
    Debug:Dev("organizer_ui", "Poll complete - refreshing cards to fetch poll data from state")
    self:RefreshBenchCardsFromState()
end

function RosterBoard:OnAddFakeRaidClicked()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Add Fake Raid button clicked")
        
        if not NextKey222.FakePlayerService then
            Debug:Error("FakePlayerService not available")
            return
        end
        
        -- Generate the raid team
        local count = NextKey222.FakePlayerService:GenerateRaidTeam()
        
        if count > 0 then
            Debug:User("Created " .. count .. "-player raid team + you (20 total)")
            
            -- Close and recreate the window to rebuild with correct number of groups
            if self.mainFrame then
                local wasVisible = self.mainFrame:IsVisible()
                self:OnMainFrameClosed(self.mainFrame)
                
                if wasVisible then
                    -- Small delay to ensure cleanup is complete
                    C_Timer.After(0.1, function()
                        self:CreateMainFrame()
                    end)
                end
            end
        else
            Debug:Error("Failed to create raid team")
        end
        
    end, "RosterBoard:OnAddFakeRaidClicked")
end

-- MARK: OnOptimizeClicked
-- REMOVED - replaced by OnOrganizeClicked
-- This function is obsolete - organize mode is now selected via dropdown
-- and executed via unified OnOrganizeClicked handler

-- MARK: Announcement System
--- Gets the role label for a slot index
-- @param slotIndex number - Slot index (1-5)
-- @return string - Role label ("TANK", "HEALER", "DPS")
function RosterBoard:GetRoleLabel(slotIndex)
    local ROLE_SLOTS = {
        [1] = "TANK",
        [2] = "HEALER",
        [3] = "DPS",
        [4] = "DPS",
        [5] = "DPS"
    }
    return ROLE_SLOTS[slotIndex] or "DPS"
end

--- Formats a single player line for announcement
-- @param playerData table - Player data from OrganizerState
-- @param slotIndex number - Slot index for role label
-- @return string - Formatted player line
function RosterBoard:FormatPlayerLine(playerData, slotIndex)
    local roleLabel = self:GetRoleLabel(slotIndex)
    local name = playerData.name or "Unknown"
    local class = playerData.class or "Unknown"
    local io = playerData.overallScore or 0
    
    return string.format("  [%s] %s (%s, %d IO)", roleLabel, name, class, io)
end

--- Formats the group header with keystone info
-- @param groupIndex number - Group number
-- @param keystoneData table|nil - Keystone data from OrganizerState
-- @return string - Formatted group header
function RosterBoard:FormatGroupHeader(groupIndex, keystoneData)
    local header = "Group " .. groupIndex .. ": "
    
    if keystoneData and type(keystoneData) == "table" and keystoneData.keystone then
        local keystone = keystoneData.keystone
        local dungeonName = "Unknown"
        
        -- Get dungeon name
        if NextKey222.Utils and keystone.dungeonID then
            local success, name = pcall(function()
                return NextKey222.Utils:GetDungeonAbbreviation(keystone.dungeonID)
            end)
            if success and name then
                dungeonName = name
            end
        end
        
        local level = keystone.level or 0
        local owner = keystoneData.playerID or "Unknown"
        
        -- Extract short name (remove realm)
        local ownerShort = owner:match("^([^%-]+)") or owner
        
        header = header .. string.format("[%s +%d] (Owner: %s)", dungeonName, level, ownerShort)
    else
        header = header .. "No keystone assigned"
    end
    
    return header
end

--- Identifies PUG needs for a group (empty slots)
-- @param groupIndex number - Group number
-- @return table - Array of empty slot descriptions
function RosterBoard:IdentifyPUGNeeds(groupIndex)
    local pugNeeds = {}
    
    if not self.groupSlots or not self.groupSlots[groupIndex] then
        return pugNeeds
    end
    
    for slotIndex = 1, 5 do
        local slot = self.groupSlots[groupIndex][slotIndex]
        if slot and slot.isEmpty then
            local roleLabel = self:GetRoleLabel(slotIndex)
            table.insert(pugNeeds, string.format("  [%s] **NEED PUG**", roleLabel))
        end
    end
    
    return pugNeeds
end

--- Formats a complete group announcement
-- @param groupIndex number - Group number
-- @return string|nil - Formatted group announcement or nil if empty
function RosterBoard:FormatSingleGroupAnnouncement(groupIndex)
    if not NextKey222.OrganizerState then
        Debug:Error("OrganizerState not available")
        return nil
    end
    
    -- Get group assignments (unwrap SafeRun tuple)
    local success, assignments = NextKey222.OrganizerState:GetGroupAssignments(groupIndex)
    if not success or not assignments or not next(assignments) then
        -- Check if there are any slots at all
        if not self.groupSlots or not self.groupSlots[groupIndex] then
            return nil -- Skip completely empty groups
        end
        assignments = {}
    end
    
    -- Get keystone data (unwrap SafeRun tuple)
    local success2, keystoneData = NextKey222.OrganizerState:GetDesignatedKeystone(groupIndex)
    if not success2 then
        keystoneData = nil
    end
    
    -- Build announcement lines
    local lines = {}
    
    -- Add group header
    local header = self:FormatGroupHeader(groupIndex, keystoneData)
    if header then
        table.insert(lines, header)
    end
    
    -- Add player lines
    local playerCount = 0
    for slotIndex = 1, 5 do
        local playerID = assignments and assignments[slotIndex]
        
        if playerID then
            local pSuccess, playerData = NextKey222.OrganizerState:GetPlayer(playerID)
            if pSuccess and playerData and type(playerData) == "table" then
                local playerLine = self:FormatPlayerLine(playerData, slotIndex)
                if playerLine then
                    table.insert(lines, playerLine)
                    playerCount = playerCount + 1
                end
            end
        end
    end
    
    -- Add PUG needs if there are any players
    if playerCount > 0 then
        local pugNeeds = self:IdentifyPUGNeeds(groupIndex)
        if pugNeeds then
            for _, need in ipairs(pugNeeds) do
                table.insert(lines, need)
            end
        end
    else
        -- Empty group
        table.insert(lines, "  No players assigned")
    end
    
    return table.concat(lines, "\n")
end

--- Formats the complete announcement for all groups
-- @return string - Complete formatted announcement
function RosterBoard:FormatGroupAnnouncement()
    local lines = {}
    
    -- Add header
    table.insert(lines, "=== NextKey M+ Groups ===")
    
    -- Get number of groups
    local groupCount = 0
    if self.groupSlots then
        for _ in pairs(self.groupSlots) do
            groupCount = groupCount + 1
        end
    end
    
    if groupCount == 0 then
        return "No groups configured"
    end
    
    -- Format each group
    for groupIndex = 1, groupCount do
        local groupAnnouncement = self:FormatSingleGroupAnnouncement(groupIndex)
        if groupAnnouncement then
            table.insert(lines, groupAnnouncement)
        end
    end
    
    return table.concat(lines, "\n")
end

--- Handles the Announce button click
function RosterBoard:OnAnnounceClicked()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Announce button clicked")
        
        -- Validate groups exist
        local groupCount = 0
        if self.groupSlots then
            for _ in pairs(self.groupSlots) do
                groupCount = groupCount + 1
            end
        end
        
        if groupCount == 0 then
            Debug:User("No groups configured to announce")
            return
        end
        
        -- Generate announcement
        Debug:Dev("organizer_ui", "Generating announcement for", groupCount, "groups")
        local announcement = self:FormatGroupAnnouncement()
        
        if not announcement or announcement == "" then
            Debug:Error("Failed to generate announcement")
            Debug:User("Failed to generate announcement")
            return
        end
        
        Debug:Dev("organizer_ui", "Announcement generated - length:", #announcement)
        
        -- Track success for user feedback
        local sentToRaid = false
        local sentToGuild = false
        
        -- Check if we're in debug mode with fake players
        local hasFakePlayers = NextKey222.FakePlayerService and
                               NextKey222.FakePlayerService:IsEnabled() and
                               #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
        
        -- Send to Raid channel if selected
        if self.announceToRaid then
            if IsInRaid() or hasFakePlayers then
                local channel = IsInRaid() and "RAID" or "SAY"
                Debug:Dev("organizer_ui", "Sending announcement to", channel, "channel")
                -- Split into multiple messages if needed (WoW has 255 char limit per message)
                local maxLength = 250 -- Leave some buffer
                local currentMessage = ""
                
                for line in announcement:gmatch("[^\n]+") do
                    local testMessage = currentMessage == "" and line or (currentMessage .. "\n" .. line)
                    
                    if #testMessage > maxLength then
                        -- Send current message
                        if currentMessage ~= "" then
                            ChatFrame_SendTell(currentMessage, channel)
                            Debug:Dev("organizer_ui", "Sent", channel, "message chunk:", #currentMessage, "chars")
                        end
                        currentMessage = line
                    else
                        currentMessage = testMessage
                    end
                end
                
                -- Send remaining message
                if currentMessage ~= "" then
                    ChatFrame_SendTell(currentMessage, channel)
                    Debug:Dev("organizer_ui", "Sent final", channel, "message chunk:", #currentMessage, "chars")
                end
                
                sentToRaid = true
                Debug:Dev("organizer_ui", "Announcement sent to", channel, "channel")
            else
                Debug:Dev("organizer_ui", "Raid checkbox selected but player not in raid and no fake players")
            end
        end
        
        -- Send to Guild channel if selected
        if self.announceToGuild then
            if IsInGuild() or hasFakePlayers then
                local channel = IsInGuild() and "GUILD" or "SAY"
                Debug:Dev("organizer_ui", "Sending announcement to", channel, "channel")
                -- Split into multiple messages if needed
                local maxLength = 250
                local currentMessage = ""
                
                for line in announcement:gmatch("[^\n]+") do
                    local testMessage = currentMessage == "" and line or (currentMessage .. "\n" .. line)
                    
                    if #testMessage > maxLength then
                        -- Send current message
                        if currentMessage ~= "" then
                            ChatFrame_SendTell(currentMessage, channel)
                            Debug:Dev("organizer_ui", "Sent", channel, "message chunk:", #currentMessage, "chars")
                        end
                        currentMessage = line
                    else
                        currentMessage = testMessage
                    end
                end
                
                -- Send remaining message
                if currentMessage ~= "" then
                    ChatFrame_SendTell(currentMessage, channel)
                    Debug:Dev("organizer_ui", "Sent final", channel, "message chunk:", #currentMessage, "chars")
                end
                
                sentToGuild = true
                Debug:Dev("organizer_ui", "Announcement sent to", channel, "channel")
            else
                Debug:Dev("organizer_ui", "Guild checkbox selected but player not in guild and no fake players")
            end
        end
        
        -- Show user feedback
        if sentToRaid or sentToGuild then
            local channels = {}
            if sentToRaid then table.insert(channels, "Raid") end
            if sentToGuild then table.insert(channels, "Guild") end
            
            Debug:User("Announced to " .. table.concat(channels, " and ") .. " chat")
        else
            Debug:User("No announcements sent - check channel selections and group membership")
        end
        
    end, "RosterBoard:OnAnnounceClicked")
end

-- MARK: Clear Poll Handler
-- MARK: End Poll Handler
-- Immediately Complete Active Poll
function RosterBoard:OnEndPollClicked()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "End Poll button clicked")
        
        if not self.activePoll then
            Debug:User("No active poll to end")
            return
        end
        
        -- Immediately complete the poll (even if not all responses received)
        local totalResponses = #self.activePoll.responses
        local totalMembers = self.activePoll.totalMembers or GetNumGroupMembers()
        
        Debug:User("Poll ended manually: " .. totalResponses .. "/" .. totalMembers .. " members responded")
        
        -- CRITICAL FIX: Ensure all non-respondents have sortable spec preferences
        -- When poll ends early, players who didn't respond still need their current spec
        -- preferences to be sortable by the organize algorithm
        if NextKey222.OrganizerState then
            -- Get all players from OrganizerState
            local allPlayers = NextKey222.OrganizerState:GetAllPlayers()
            local respondedPlayerIDs = {}
            
            -- Build set of players who already responded
            for _, response in ipairs(self.activePoll.responses) do
                respondedPlayerIDs[response.sender] = true
            end
            
            -- For each non-respondent, ensure they have sortable spec preferences
            for _, playerData in ipairs(allPlayers) do
                local playerID = playerData.id
                
                if playerID and not respondedPlayerIDs[playerID] then
                    -- Check if they need spec preferences generated
                    local needsGeneration = false
                    
                    if not playerData.specPreferences then
                        -- No spec preferences at all
                        needsGeneration = true
                        Debug:Dev("organizer", "Non-respondent has no specPreferences:", playerID)
                    else
                        -- Check if all preferences are "none"
                        local hasNonNonePreference = false
                        for role, preference in pairs(playerData.specPreferences) do
                            if preference ~= "none" then
                                hasNonNonePreference = true
                                break
                            end
                        end
                        
                        if not hasNonNonePreference then
                            needsGeneration = true
                            Debug:Dev("organizer", "Non-respondent has all 'none' preferences:", playerID)
                        else
                            Debug:Dev("organizer", "Non-respondent already has valid spec preferences:", playerID)
                        end
                    end
                    
                    if needsGeneration then
                        Debug:Dev("organizer", "Generating default spec preferences for non-respondent:", playerID)
                        
                        -- Generate default spec preferences (current spec only)
                        if NextKey222.OrganizerPlayerDataBuilder and
                           NextKey222.OrganizerPlayerDataBuilder.GenerateSpecPreferences then
                            local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(playerID, {randomize = false})
                            
                            if success and specPrefs then
                                -- Update player data in OrganizerState
                                NextKey222.OrganizerState:UpdatePlayer(playerID, {
                                    specPreferences = specPrefs,
                                    specDetails = specDetails
                                })
                                Debug:Dev("organizer", "Added default spec preferences for non-respondent:", playerID)
                            else
                                Debug:Error("Failed to generate spec preferences for non-respondent:", playerID)
                            end
                        end
                    end
                end
            end
        end
        
        -- Call CompletePoll to handle cleanup
        self:CompletePoll()
        
    end, "RosterBoard:OnEndPollClicked")
end

function RosterBoard:OnClearPollClicked()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Clear Poll button clicked")
        
        -- Clear OrganizerState (both in-memory and persisted)
        if NextKey222.OrganizerState and NextKey222.OrganizerState.ClearPersistedData then
            NextKey222.OrganizerState:ClearPersistedData()
        else
            Debug:Error("OrganizerState not available - cannot clear poll data")
            return
        end
        
        -- Clear active poll
        self.activePoll = nil
        
        -- Reset poll button and label
        if self.pollButton then
            self.pollButton:SetDisabled(false)
            self.pollButton:SetText("Poll Group")
        end
        
        if self.pollLabel then
            self.pollLabel:SetText("POLL CONTROLS")
        end
        
        -- Re-enable organize button and clear tooltip
        if self.organizeButton then
            self.organizeButton:SetDisabled(false)
            self.organizeButton.frame:SetScript("OnEnter", nil)
            self.organizeButton.frame:SetScript("OnLeave", nil)
        end
        
        -- Close and reopen the window to rebuild from scratch
        -- This is the cleanest way to reset the entire UI
        Debug:User("Poll data cleared - reopening organizer window")
        
        -- Store visibility state
        local wasVisible = self:IsVisible()
        
        -- Close window
        self:Hide()
        
        -- Small delay to ensure cleanup is complete
        if wasVisible then
            C_Timer.After(0.1, function()
                self:Show()
                Debug:User("Organizer reset complete - ready for new poll")
            end)
        end
        
    end, "RosterBoard:OnClearPollClicked")
end

-- MARK: Action Bar
-- REMOVED - moved to header
-- All organize/announce controls are now in the header section (row 2)

-- MARK: Organize Handler
-- Unified handler (replaces separate Sort and Optimize)
function RosterBoard:OnOrganizeClicked()
    return NextKey222.SafeRun(function()
        local mode = self.selectedOrganizeMode or "simple_sort"
        
        Debug:Dev("organizer", "Organize clicked with mode:", mode)
        
        if mode == "simple_sort" then
            -- Execute current sequential sort algorithm
            self:ExecuteSimpleSort()
        else
            -- Phase 4: Execute optimizer algorithms
            Debug:User("Optimizer mode '" .. mode .. "' will be implemented in Phase 4")
        end
        
    end, "RosterBoard:OnOrganizeClicked")
end

-- MARK: Simple Sort
-- Execution (renamed from OnSortClicked)
function RosterBoard:ExecuteSimpleSort()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Sort button clicked - starting sequential sort")
        
        -- Validate we have players and groups
        if not self.benchCards or #self.benchCards == 0 then
            Debug:User("No players on bench to sort")
            return
        end
        
        if not self.groupSlots or #self.groupSlots == 0 then
            Debug:User("No groups available for sorting")
            return
        end
        
        -- Set animation flag to prevent event handling during animation
        self.isAnimating = true
        
        -- Disable organize button during execution
        if self.organizeButton then
            self.organizeButton:SetDisabled(true)
            self.organizeButton:SetText("Organizing...")
        end
        
        -- Get bench players
        local benchPlayers = {}
        for _, card in ipairs(self.benchCards) do
            if card.playerData then
                table.insert(benchPlayers, card.playerData)
            end
        end
        
        -- Calculate assignment plan
        local numGroups = #self.groupSlots
        local assignmentPlan = NextKey222.OrganizerSorting:CalculateSequentialAssignment(
            benchPlayers,
            numGroups
        )
        
        if not assignmentPlan or #assignmentPlan == 0 then
            Debug:Error("Failed to generate assignment plan")
            self:ResetOrganizeButton()
            return
        end
        
        Debug:Dev("organizer", "Generated", #assignmentPlan, "assignments - preparing animation sequence")
        
        -- Build valid assignment list (filter out occupied slots)
        local validAssignments = {}
        for _, assignment in ipairs(assignmentPlan) do
            local card = self:FindCardByPlayerID(assignment.player.id)
            local targetSlot = self.groupSlots[assignment.groupIndex] and
                              self.groupSlots[assignment.groupIndex][assignment.slotIndex]
            
            if card and targetSlot then
                -- Check if slot is empty
                if targetSlot.isEmpty then
                    table.insert(validAssignments, {
                        card = card,
                        targetSlot = targetSlot,
                        player = assignment.player
                    })
                else
                    Debug:Dev("organizer", "Skipping assignment - slot occupied:",
                        assignment.groupIndex, assignment.slotIndex)
                end
            else
                Debug:Error("Failed to find card or slot for assignment:",
                    assignment.player.id, assignment.groupIndex, assignment.slotIndex)
            end
        end
        
        if #validAssignments == 0 then
            Debug:User("No valid assignments available - all slots may be occupied")
            self:ResetOrganizeButton()
            return
        end
        
        Debug:User("Starting sort animation for", #validAssignments, "players")
        
        -- Execute ROLE WAVE animation sequence (fast thematic animation)
        NextKey222.AnimationQueue:ExecuteRoleWaveSequence(validAssignments, function()
            self:OnSortComplete()
        end)
        
    end, "RosterBoard:OnSortClicked")
end

function RosterBoard:OnSortComplete()
    Debug:Dev("organizer", "Sort animation sequence completed")
    
    -- Clear animation flag
    self.isAnimating = false
    
    -- Re-enable organize button
    self:ResetOrganizeButton()
    
    -- Refresh layout
    self:LayoutBench()
    
    Debug:User("Sorting complete!")
end

function RosterBoard:ResetOrganizeButton()
    if self.organizeButton then
        self.organizeButton:SetDisabled(false)
        self.organizeButton:SetText("Organize")
    end
end

-- MARK: Access Control
function RosterBoard:DisableOrganizerControls()
    if self.pollButton then
        self.pollButton:SetDisabled(true)
    end
    if self.optimizeButton then
        self.optimizeButton:SetDisabled(true)
    end
    if self.announceButton then
        self.announceButton:SetDisabled(true)
    end
    if self.optimizerDropdown then
        self.optimizerDropdown:SetDisabled(true)
    end
    
    Debug:Dev("organizer_ui", "Disabled organizer controls (participant view)")
end

-- MARK: Active Pool
-- Delegates to SlotManager
function RosterBoard:CreateActivePoolSection(nativeParent)
    return NextKey222.SlotManager:create_active_pool_section(self, nativeParent)
end

-- MARK: Flat Role Slot
-- Delegates to SlotManager
function RosterBoard:CreateFlatRoleSlot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
    return NextKey222.SlotManager:create_flat_role_slot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
end

-- MARK: Bench Column
-- Delegates to BenchManager
function RosterBoard:CreateNativeBenchColumn(width, parentFrame)
    return NextKey222.BenchManager:create_native_bench_column(self, width, parentFrame)
end
-- MARK: Add to Bench
-- Delegates to BenchManager
function RosterBoard:AddPlayerToBench(playerData)
    return NextKey222.BenchManager:add_player_to_bench(self, playerData)
end

function RosterBoard:AddPlayerToOptOut(playerData)
    return NextKey222.SafeRun(function()
        if not self.optOutSection or not self.optOutSection.scrollChild then
            Debug:Error("Opt-out section not initialized")
            return
        end
        
        -- Create native card for opt-out
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            self.optOutSection.scrollChild,
            "opt_out",
            "opt_out"
        )
        
        if card then
            table.insert(self.optOutSection.playerCards, card)
            
            -- Re-layout opt-out section
            self:LayoutOptOut()
            
            Debug:Dev("organizer", "Added player to opt-out:", playerData.name)
        else
            Debug:Error("Failed to create card for:", playerData.name)
        end
        
    end, "RosterBoard:AddPlayerToOptOut")
end

function RosterBoard:RemovePlayerFromBench(playerID)
    return NextKey222.BenchManager:remove_player_from_bench(self, playerID)
end

function RosterBoard:AddAutoDetectedIndicator(playerCard)
    return NextKey222.BenchManager:add_auto_detected_indicator(playerCard)
end

-- MARK: Populate Bench
-- Delegates to BenchManager
function RosterBoard:PopulateBench(players)
    return NextKey222.BenchManager:populate_bench(self, players)
end

-- MARK: Window Resize
-- Delegates to BenchManager
function RosterBoard:CheckAndResizeWindow()
    return NextKey222.BenchManager:check_and_resize_window(self)
end

-- MARK: Layout Bench
-- Delegates to BenchManager
function RosterBoard:LayoutBench()
    return NextKey222.BenchManager:layout_bench(self)
end

-- MARK: Opt-Out Section
-- Delegates to SlotManager
function RosterBoard:CreateOptOutSection(nativeParent)
    return NextKey222.SlotManager:create_opt_out_section(self, nativeParent)
end

function RosterBoard:PopulateOptOut(players)
    return NextKey222.SlotManager:populate_opt_out(self, players)
end

-- MARK: Place in Opt-Out
-- Delegates to SlotManager
function RosterBoard:PlaceCardInOptOut(card)
    return NextKey222.SlotManager:place_card_in_opt_out(self, card)
end

-- MARK: Layout Opt-Out
-- Delegates to SlotManager
function RosterBoard:LayoutOptOut()
    return NextKey222.SlotManager:layout_opt_out(self)
end

-- MARK: Drop Detection
-- Delegates to CardMovement
function RosterBoard:DetectDropTarget()
    return NextKey222.CardMovement:detect_drop_target(self)
end

-- MARK: Card Drop Handler
-- Delegates to CardMovement
function RosterBoard:HandleCardDrop(card, dropTarget)
    return NextKey222.CardMovement:handle_card_drop(self, card, dropTarget)
end

-- MARK: Mark For Removal
-- Delegates to CardMovement
function RosterBoard:MarkCardForRemoval(card)
    return NextKey222.CardMovement:mark_card_for_removal(self, card)
end

-- MARK: Complete Removal
-- Delegates to CardMovement
function RosterBoard:CompleteCardRemoval(card)
    return NextKey222.CardMovement:complete_card_removal(self, card)
end

-- MARK: Place in Slot
-- Delegates to SlotManager
function RosterBoard:PlaceCardInSlot(card, slot)
    return NextKey222.SlotManager:place_card_in_slot(card, slot)
end

-- MARK: Place in Bench
-- Delegates to CardMovement
function RosterBoard:PlaceCardInBench(card)
    return NextKey222.CardMovement:place_card_in_bench(self, card)
end

-- MARK: Remove From Bench
-- Delegates to CardMovement
function RosterBoard:RemoveCardFromBenchArray(card)
    return NextKey222.CardMovement:remove_card_from_bench_array(self, card)
end

-- MARK: Rejection Animation
-- Delegates to CardMovement
function RosterBoard:AnimateRejection(card)
    return NextKey222.CardMovement:animate_rejection(self, card)
end

-- MARK: Role Validation
-- Delegates to CardMovement
function RosterBoard:CanPlayerFillRole(playerRoles, slotRole)
    return NextKey222.CardMovement:can_player_fill_role(playerRoles, slotRole)
end

function RosterBoard:FindCompatibleSlotInGroup(card, groupIndex)
    return NextKey222.CardMovement:find_compatible_slot_in_group(self, card, groupIndex)
end

-- MARK: State Synchronization
function RosterBoard:BroadcastRosterUpdate(updateData)
    if NextKey222.Communications and NextKey222.Communications.QueueOrganizerUpdate then
        NextKey222.Communications:QueueOrganizerUpdate(updateData)
    end
end

function RosterBoard:RequestRosterState()
    Debug:Dev("org_sync", "Requesting full roster state from organizer")
end

function RosterBoard:OnRosterUpdateReceived(message, sender)
    return NextKey222.SafeRun(function()
        if self:IsOrganizer() then
            return
        end
        
        local updateData = message.data
        
        if updateData.action == "CARD_MOVED" then
            Debug:Dev("org_sync", "Received CARD_MOVED update")
        elseif updateData.action == "KEYSTONE_DESIGNATED" then
            Debug:Dev("org_sync", "Received KEYSTONE_DESIGNATED update")
        elseif updateData.action == "ROSTER_STATE_FULL" then
            Debug:Dev("org_sync", "Received ROSTER_STATE_FULL update")
        end
        
    end, "RosterBoard:OnRosterUpdateReceived")
end

-- MARK: Public Interface
function RosterBoard:Show()
    Debug:Dev("organizer_ui", "RosterBoard:Show() called")
    
    local success, result = NextKey222.SafeRun(function()
        if not self.mainFrame then
            local frame = self:CreateMainFrame()
        else
            self.mainFrame:Show()
        end
        
        return true
    end, "RosterBoard:Show")
    
    if not success then
        Debug:Error("RosterBoard:Show failed!")
    end
end

function RosterBoard:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function RosterBoard:IsVisible()
    return self.mainFrame and self.mainFrame:IsVisible()
end

-- MARK: Rebuild Frame
-- Preserve Players
function RosterBoard:RebuildMainFrame()
    return NextKey222.SafeRun(function()
        -- Store visibility state
        local wasVisible = self:IsVisible()
        
        -- Close current window (triggers cleanup)
        self:Hide()
        
        -- Small delay to ensure cleanup completes
        C_Timer.After(0.1, function()
            if wasVisible then
                self:Show()  -- Recreates with new manualGroupCount
            end
        end)
        
    end, "RosterBoard:RebuildMainFrame")
end

-- MARK: Keystone Manager
-- Delegates to KeystoneManager
function RosterBoard:DesignateGroupKeystone(groupIndex, keystone, playerID)
    return NextKey222.KeystoneManager:designate_group_keystone(self, groupIndex, keystone, playerID)
end

function RosterBoard:ClearGroupKeystone(groupIndex)
    return NextKey222.KeystoneManager:clear_group_keystone(self, groupIndex)
end

function RosterBoard:HighlightKeystoneButton(playerID)
    return NextKey222.KeystoneManager:highlight_keystone_button(self, playerID)
end

function RosterBoard:UnhighlightKeystoneButton(playerID)
    return NextKey222.KeystoneManager:unhighlight_keystone_button(self, playerID)
end

function RosterBoard:IsKeystoneDesignated(groupIndex, playerID)
    return NextKey222.KeystoneManager:is_keystone_designated(self, groupIndex, playerID)
end

function RosterBoard:UpdateGroupHeader(groupIndex, keystone)
    return NextKey222.KeystoneManager:update_group_header(self, groupIndex, keystone)
end

-- MARK: Helper Functions
-- Delegates to KeystoneManager
function RosterBoard:FindCardByPlayerID(playerID)
    return NextKey222.KeystoneManager:find_card_by_player_id(self, playerID)
end

-- MARK: Rebuild After Poll
-- Forces UI Refresh
function RosterBoard:RebuildBenchAfterPoll()
    return NextKey222.SafeRun(function()
        if not self.benchContainer then
            Debug:Error("Cannot rebuild bench - container not initialized")
            return
        end
        
        Debug:Dev("organizer_ui", "RebuildBenchAfterPoll - clearing all existing bench cards")
        
        -- Clear ALL existing bench cards completely
        for _, card in ipairs(self.benchCards) do
            if card then
                card:Hide()
                card:SetParent(nil)
                card:ClearAllPoints()
            end
        end
        self.benchCards = {}
        
        -- Get fresh player list (will preserve poll response data from existing cards)
        local benchPlayers = self:GetBenchPlayers()
        
        Debug:Dev("organizer_ui", "Creating fresh cards for", #benchPlayers, "bench players")
        
        -- Create brand new cards with updated data
        for i, playerData in ipairs(benchPlayers) do
            local card = NextKey222.PlayerCard:CreateNativeCard(
                playerData,
                self.benchContainer,
                "bench",
                "compact"
            )
            
            if card then
                table.insert(self.benchCards, card)
                Debug:Dev("organizer_ui", "Recreated bench card", i, "for:", playerData.name,
                         "- has specPreferences:", playerData.specPreferences ~= nil)
            else
                Debug:Error("Failed to recreate card for:", playerData.name)
            end
        end
        
        -- Re-layout bench
        self:LayoutBench()
        
        Debug:Dev("organizer_ui", "Bench rebuild complete -", #self.benchCards, "cards created")
        
    end, "RosterBoard:RebuildBenchAfterPoll")
end

-- MARK: Card Refresh System
--- Refreshes a single card with fresh profile data
-- @param card The card frame to refresh
-- @param displayMode The display mode for the card ("compact", "expanded", "opt_out")
-- @param locationContext Optional string for debug logging (e.g., "bench", "group 1 slot 2")
-- @param isSpecChange Optional boolean indicating if this refresh is due to a spec change
local function RefreshSingleCard(card, displayMode, locationContext, isSpecChange)
    if not (card and card.playerData and card.playerData.id) then
        return false
    end
    
    local playerID = card.playerData.id
    
    -- Get fresh BASE profile data (has current spec's role)
    local profile = NextKey222.ProfilesService and
                   NextKey222.ProfilesService:GetProfile(playerID)
    
    if not profile then
        return false
    end
    
    -- Update card's player data with fresh profile info
    card.playerData.class = profile.class
    -- CRITICAL: Use current spec's role from base profile, not multi-role array
    card.playerData.roles = {profile.role or "DAMAGER"}
    card.playerData.specName = profile.specName
    card.playerData.specID = profile.specID
    card.playerData.overallScore = profile.io or 0
    
    -- CRITICAL FIX: Smart invalidation - only regenerate if new spec wasn't in poll response
    if isSpecChange then
        Debug:Dev("organizer_ui", "Spec change detected for:", playerID, "- new role:", profile.role)
        
        -- Check if player has poll data
        if card.playerData.specPreferences then
            -- Check if new spec's role is in their poll preferences
            local newSpecRole = profile.role
            local pollHasThisRole = false
            
            -- Only check if we have a valid role
            if newSpecRole then
                for role, preference in pairs(card.playerData.specPreferences) do
                    if role:upper() == newSpecRole:upper() and preference ~= "none" then
                        pollHasThisRole = true
                        break
                    end
                end
            end
            
            if not pollHasThisRole then
                -- They switched to a spec they didn't sign up for - invalidate poll
                Debug:Dev("organizer_ui", "New spec NOT in poll preferences - invalidating poll response")
                
                if NextKey222.OrganizerPlayerDataBuilder and
                   NextKey222.OrganizerPlayerDataBuilder.GenerateSpecPreferences then
                    local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(playerID, {randomize = false})
                    
                    if success and specPrefs then
                        card.playerData.specPreferences = specPrefs
                        card.playerData.specDetails = specDetails
                        Debug:Dev("organizer_ui", "Poll invalidated - regenerated defaults for:", playerID)
                    else
                        Debug:Error("Failed to regenerate specPreferences for:", playerID)
                        card.playerData.specPreferences = nil
                        card.playerData.specDetails = nil
                    end
                end
            else
                -- New spec IS in their poll preferences - keep poll data, just update specDetails
                Debug:Dev("organizer_ui", "Spec change within poll preferences - preserving poll data")
            end
        else
            -- No poll data - just regenerate defaults for new spec
            Debug:Dev("organizer_ui", "No poll data - generating defaults for new spec")
            
            if NextKey222.OrganizerPlayerDataBuilder and
               NextKey222.OrganizerPlayerDataBuilder.GenerateSpecPreferences then
                local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(playerID, {randomize = false})
                
                if success and specPrefs then
                    card.playerData.specPreferences = specPrefs
                    card.playerData.specDetails = specDetails
                end
            end
        end
    else
        Debug:Dev("organizer_ui", "General refresh - preserving specPreferences for:", playerID)
    end
    
    -- Update utilities from capabilities
    card.playerData.utilities = {}
    if profile.capabilities then
        if profile.capabilities.heroism then
            table.insert(card.playerData.utilities, "heroism")
        end
        if profile.capabilities.battleRes then
            table.insert(card.playerData.utilities, "battleRes")
        end
    end
    
    -- Update card content to reflect new data
    NextKey222.PlayerCard:UpdateCardContent(card, displayMode)
    
    Debug:Dev("organizer_ui", "Refreshed card for:", playerID,
             locationContext and ("(" .. locationContext .. ")") or "",
             "- role:", profile.role, "spec:", profile.specName,
             "- CLEARED specPreferences to force role icon update")
    
    return true
end

--- Refreshes all player cards to reflect updated profile data (e.g., after spec changes)
-- This method updates both bench cards and slot cards with fresh profile information
function RosterBoard:RefreshAllCards(isSpecChange)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "RefreshAllCards called - updating all player cards",
                 isSpecChange and "(SPEC CHANGE)" or "(general refresh)")
        Debug:Dev("organizer_ui", "RefreshAllCards isSpecChange parameter:", isSpecChange)
        
        -- CRITICAL: Clear ProfilesService cache FIRST to ensure we get fresh spec data
        if NextKey222.ProfilesService then
            NextKey222.ProfilesService:InvalidateCache()
            Debug:Dev("organizer_ui", "Invalidated ProfilesService cache before refresh")
        end
        
        -- Refresh bench cards
        if self.benchCards then
            for _, card in ipairs(self.benchCards) do
                RefreshSingleCard(card, "compact", "bench", isSpecChange)
            end
        end
        
        -- Refresh slot cards
        if self.groupSlots then
            for groupIndex, slots in pairs(self.groupSlots) do
                for slotIndex, slot in pairs(slots) do
                    if slot.playerCard then
                        local locationContext = "group " .. groupIndex .. " slot " .. slotIndex
                        RefreshSingleCard(slot.playerCard, "expanded", locationContext, isSpecChange)
                    end
                end
            end
        end
        
        -- Refresh opt-out cards
        if self.optOutSection and self.optOutSection.playerCards then
            for _, card in ipairs(self.optOutSection.playerCards) do
                RefreshSingleCard(card, "opt_out", "opt-out", isSpecChange)
            end
        end
        
        Debug:Dev("organizer_ui", "RefreshAllCards completed successfully")
        
    end, "RosterBoard:RefreshAllCards")
end

-- MARK: Refresh From State
-- SESSION 3: Poll Data Visual Update
--- Lightweight refresh that makes bench cards fetch fresh data from OrganizerState
-- This is called after poll completion to update visual appearance (role icon colors)
-- without rebuilding the entire bench
function RosterBoard:RefreshBenchCardsFromState()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "RefreshBenchCardsFromState - updating all bench cards from state")
        
        if not self.benchCards then
            Debug:Error("Cannot refresh bench cards - benchCards array not initialized")
            return
        end
        
        local refreshedCount = 0
        for _, card in ipairs(self.benchCards) do
            if card and NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                NextKey222.PlayerCard:UpdateCardContent(card, "compact")
                refreshedCount = refreshedCount + 1
            end
        end
        
        Debug:Dev("organizer_ui", "Refreshed", refreshedCount, "bench cards from state")
        
    end, "RosterBoard:RefreshBenchCardsFromState")
end

-- MARK: Refresh By PlayerID
-- SESSION 3: Real-time Poll Updates
--- Refreshes a specific player's card after poll response received
-- Searches bench, slots, and opt-out for the player's card and refreshes it
function RosterBoard:RefreshSingleCardByPlayerID(playerID)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "RefreshSingleCardByPlayerID - searching for:", playerID)
        
        local cardFound = false
        
        -- Search bench cards
        if self.benchCards then
            for _, card in ipairs(self.benchCards) do
                if card and card.playerID == playerID then
                    NextKey222.PlayerCard:UpdateCardContent(card, "compact")
                    Debug:Dev("organizer_ui", "Refreshed bench card for:", playerID)
                    cardFound = true
                    break
                end
            end
        end
        
        -- Search slot cards if not found on bench
        if not cardFound and self.groupSlots then
            for groupIndex, slots in pairs(self.groupSlots) do
                for slotIndex, slot in pairs(slots) do
                    if slot.playerCard and slot.playerCard.playerID == playerID then
                        NextKey222.PlayerCard:UpdateCardContent(slot.playerCard, "expanded")
                        Debug:Dev("organizer_ui", "Refreshed slot card for:", playerID, "in group", groupIndex)
                        cardFound = true
                        break
                    end
                end
                if cardFound then break end
            end
        end
        
        -- Search opt-out cards if not found yet
        if not cardFound and self.optOutSection and self.optOutSection.playerCards then
            for _, card in ipairs(self.optOutSection.playerCards) do
                if card and card.playerID == playerID then
                    NextKey222.PlayerCard:UpdateCardContent(card, "opt_out")
                    Debug:Dev("organizer_ui", "Refreshed opt-out card for:", playerID)
                    cardFound = true
                    break
                end
            end
        end
        
        if not cardFound then
            Debug:Dev("organizer_ui", "Card not found for player:", playerID, "- may need rebuild")
        end
        
    end, "RosterBoard:RefreshSingleCardByPlayerID")
end

-- MARK: Sync UI to State
-- SESSION 3: Handle Opt-Out/Alt Movement
--- Rebuilds bench and opt-out sections to match OrganizerState
-- Called after poll responses that change player locations (opt-out, alt selection)
function RosterBoard:SyncUIToState()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "SyncUIToState - rebuilding bench and opt-out from state")
        
        if not self.benchContainer or not self.optOutSection then
            Debug:Error("Cannot sync UI - containers not initialized")
            return
        end
        
        -- Get current state
        local benchPlayerIDs = NextKey222.OrganizerState:GetBenchPlayers()
        local optOutPlayerIDs = NextKey222.OrganizerState:GetOptOutPlayers()
        
        -- Clear existing bench cards
        for _, card in ipairs(self.benchCards) do
            if card then
                card:Hide()
                card:SetParent(nil)
                card:ClearAllPoints()
            end
        end
        self.benchCards = {}
        
        -- Clear existing opt-out cards
        if self.optOutSection.playerCards then
            for _, card in ipairs(self.optOutSection.playerCards) do
                if card then
                    card:Hide()
                    card:SetParent(nil)
                    card:ClearAllPoints()
                end
            end
        end
        self.optOutSection.playerCards = {}
        
        -- Rebuild bench from state
        for _, playerID in ipairs(benchPlayerIDs) do
            local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
            if playerData then
                local card = NextKey222.PlayerCard:CreateNativeCard(
                    playerData,
                    self.benchContainer,
                    "bench",
                    "compact"
                )
                if card then
                    table.insert(self.benchCards, card)
                end
            end
        end
        
        -- Rebuild opt-out from state
        for _, playerID in ipairs(optOutPlayerIDs) do
            local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
            if playerData then
                local card = NextKey222.PlayerCard:CreateNativeCard(
                    playerData,
                    self.optOutSection.scrollChild,
                    "opt_out",
                    "opt_out"
                )
                if card then
                    table.insert(self.optOutSection.playerCards, card)
                end
            end
        end
        
        -- Re-layout sections
        self:LayoutBench()
        self:LayoutOptOut()
        
        -- Update Return All button state
        if NextKey222.SlotManager and NextKey222.SlotManager.update_return_button_state then
            NextKey222.SlotManager:update_return_button_state(self)
        end
        
        Debug:Dev("organizer_ui", "Synced UI to state -", #self.benchCards, "bench,",
                 #self.optOutSection.playerCards, "opt-out")
        
    end, "RosterBoard:SyncUIToState")
end

-- MARK: Event Handlers
-- Event-Driven Architecture
--- Handler for ORGANIZER_PLAYER_ADDED event
-- @param payload table - Event payload {playerID, playerData, location, source, timestamp}
function RosterBoard:OnPlayerAdded(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnPlayerAdded:", payload.playerID, "location:", payload.location)
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- Add player to appropriate location
        if payload.location == "bench" then
            self:AddPlayerToBench(payload.playerData)
        elseif payload.location == "opt_out" then
            self:AddPlayerToOptOut(payload.playerData)
        elseif type(payload.location) == "table" and payload.location.type == "role_slot" then
            -- Player added directly to slot (rare case)
            local groupIndex = payload.location.groupIndex
            local slotIndex = payload.location.slotIndex
            if self.groupSlots and self.groupSlots[groupIndex] and self.groupSlots[groupIndex][slotIndex] then
                local slot = self.groupSlots[groupIndex][slotIndex]
                local card = NextKey222.PlayerCard:CreateNativeCard(
                    payload.playerData,
                    slot,
                    "role_slot",
                    "compact"
                )
                if card then
                    NextKey222.SlotManager:place_card_in_slot(card, slot)
                end
            end
        end
        
    end, "RosterBoard:OnPlayerAdded")
end

--- Handler for ORGANIZER_PLAYER_MOVED event
-- @param payload table - Event payload {playerID, fromLocation, toLocation, playerData, reason, timestamp}
function RosterBoard:OnPlayerMoved(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnPlayerMoved:", payload.playerID,
                 "from:", payload.fromLocation, "to:", payload.toLocation)
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- CRITICAL: Don't sync UI during animations - it destroys cards being animated
        if self.isAnimating then
            Debug:Dev("organizer_events", "OnPlayerMoved - skipping sync (animation in progress)")
            return
        end
        
        -- CRITICAL: Event handlers should ONLY update UI, not call state mutations
        -- The state has already changed - we just need to refresh the visual representation
        Debug:Dev("organizer_events", "OnPlayerMoved - triggering full UI sync (state already updated)")
        
        -- Instead of trying to move individual cards (which causes recursion),
        -- just rebuild the UI from the current state
        self:SyncUIToState()
        
    end, "RosterBoard:OnPlayerMoved")
end

--- Handler for ORGANIZER_PLAYER_UPDATED event
-- @param payload table - Event payload {playerID, updates, playerData, updateType, timestamp}
function RosterBoard:OnPlayerUpdated(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnPlayerUpdated:", payload.playerID,
                 "type:", payload.updateType)
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- Refresh the specific player's card
        self:RefreshSingleCardByPlayerID(payload.playerID)
        
    end, "RosterBoard:OnPlayerUpdated")
end

--- Handler for ORGANIZER_POLL_RESPONSE_RECEIVED event
-- @param payload table - Event payload {playerID, response, playerData, timestamp, totalResponses, expectedResponses}
function RosterBoard:OnPollResponseReceived(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnPollResponseReceived:", payload.playerID,
                 "progress:", payload.totalResponses, "/", payload.expectedResponses)
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- Update poll progress UI
        self:UpdatePollProgress()
        
        -- Refresh the specific player's card to show poll response
        self:RefreshSingleCardByPlayerID(payload.playerID)
        
    end, "RosterBoard:OnPollResponseReceived")
end

--- Handler for NEXTKEY_PROFILE_UPDATED event (spec changes, role changes)
-- @param payload table - Event payload {triggerEvent, playerName, specID, role, etc.}
function RosterBoard:OnProfileUpdated(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnProfileUpdated:", payload.triggerEvent or "unknown")
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- Refresh all cards to show updated spec/role information
        Debug:Dev("organizer_events", "Refreshing all organizer cards after profile update")
        self:RefreshAllCards(true)  -- Pass true to indicate spec change
        
    end, "RosterBoard:OnProfileUpdated")
end

--- Handler for ORGANIZER_STATE_CLEARED event
-- @param payload table - Event payload {reason, clearedData, timestamp}
function RosterBoard:OnStateCleared(payload)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_events", "OnStateCleared:", payload.reason,
                 "players:", payload.clearedData.playerCount)
        
        -- Only update UI if window is visible
        if not self:IsVisible() then
            return
        end
        
        -- Rebuild the entire UI from scratch
        local wasVisible = self:IsVisible()
        self:Hide()
        
        if wasVisible then
            C_Timer.After(0.1, function()
                self:Show()
            end)
        end
        
    end, "RosterBoard:OnStateCleared")
end
