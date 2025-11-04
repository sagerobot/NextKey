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
        
        -- Note: Spec change events are handled by ProfilesService which automatically
        -- triggers UI refresh. No need for duplicate event handlers here.
        Debug:Dev("organizer_ui", "Roster Board initialized (spec changes handled by ProfilesService)")
        
        Debug:Dev("organizer_ui", "Roster Board initialized successfully")
        return true
    end, "RosterBoard:Initialize")
end

-- MARK: Event Registration & Card Refresh
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

-- MARK: Main Frame Creation (FULLY NATIVE INTERIOR)
function RosterBoard:CreateMainFrame()
    print("[ORGANIZER DIAGNOSTIC] CreateMainFrame called")
    
    return NextKey222.SafeRun(function()
        print("[ORGANIZER DIAGNOSTIC] Inside SafeRun")
        
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
            print("[ORGANIZER DIAGNOSTIC] Releasing existing frame")
            AceGUI:Release(self.mainFrame)
            self.mainFrame = nil
        end
        
        -- Calculate dynamic sizing
        print("[ORGANIZER DIAGNOSTIC] Calculating layout")
        local layout = self:CalculateOptimalLayout()
        print("[ORGANIZER DIAGNOSTIC] Layout calculated - groups:", layout.groupColumns)
        
        -- Create main window container with dynamic size (AceGUI for window chrome only)
        print("[ORGANIZER DIAGNOSTIC] Creating AceGUI Frame")
        local frame = AceGUI:Create("Frame")
        frame:SetTitle("M+ Group Organizer")
        frame:SetWidth(layout.totalWidth)
        frame:SetHeight(layout.totalHeight)
        frame:SetLayout("Fill")  -- Unused, but required by AceGUI
        frame:EnableResize(true)
        
        frame:SetStatusText("M+ Group Organizer - Drag players between bench and groups")
        
        -- Set callback for close button
        frame:SetCallback("OnClose", function(widget)
            self:OnMainFrameClosed(widget)
        end)
        
        -- Store reference
        self.mainFrame = frame
        print("[ORGANIZER DIAGNOSTIC] Main frame created and stored")
        
        -- Get the native frame for direct content parenting
        -- AceGUI Frames have frame.content for interior content
        local nativeFrame = frame.content or frame.frame
        print("[ORGANIZER DIAGNOSTIC] Native frame obtained:", nativeFrame and "YES" or "NO")
        print("[ORGANIZER DIAGNOSTIC] Using frame.content:", frame.content and "YES" or "NO")
        
        -- If there's an InsetFrame, we need to work around it
        if frame.frame.InsetBg then
            print("[ORGANIZER DIAGNOSTIC] InsetBg found - adjusting setup")
        end
        
        -- Create all sections as NATIVE frames with manual positioning
        print("[ORGANIZER DIAGNOSTIC] Creating header section...")
        Debug:Dev("organizer_ui", "Creating header section...")
        self:CreateHeaderSection(nativeFrame)
        print("[ORGANIZER DIAGNOSTIC] Header section created")
        
        print("[ORGANIZER DIAGNOSTIC] Creating active pool section...")
        Debug:Dev("organizer_ui", "Creating active pool section...")
        self:CreateActivePoolSection(nativeFrame)
        print("[ORGANIZER DIAGNOSTIC] Active pool section created")
        
        print("[ORGANIZER DIAGNOSTIC] Creating opt-out section...")
        Debug:Dev("organizer_ui", "Creating opt-out section...")
        self:CreateOptOutSection(nativeFrame)
        print("[ORGANIZER DIAGNOSTIC] Opt-out section created")
        
        -- Populate with actual data
        print("[ORGANIZER DIAGNOSTIC] Populating sections...")
        Debug:Dev("organizer_ui", "Populating sections...")
        self:PopulateAllSections()
        print("[ORGANIZER DIAGNOSTIC] Sections populated")
        
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
    Debug:Dev("ui_contamination", "[ORGANIZER] CleanupNativeFrames called - starting comprehensive cleanup")
    
    -- Hide and nil all bench cards
    local benchCardCount = 0
    for _, card in ipairs(self.benchCards) do
        if card then
            card:Hide()
            card:SetParent(nil)
            card:ClearAllPoints()
            -- Clear all scripts to prevent event handlers from firing
            card:SetScript("OnDragStart", nil)
            card:SetScript("OnDragStop", nil)
            benchCardCount = benchCardCount + 1
        end
    end
    self.benchCards = {}
    Debug:Dev("ui_contamination", "[ORGANIZER] Cleaned up", benchCardCount, "bench cards")
    
    -- Hide and nil all slot cards
    local slotCount = 0
    for groupIndex, slots in pairs(self.groupSlots) do
        for slotIndex, slot in pairs(slots) do
            if slot.playerCard then
                slot.playerCard:Hide()
                slot.playerCard:SetParent(nil)
                slot.playerCard:ClearAllPoints()
                -- Clear all scripts to prevent event handlers from firing
                if slot.playerCard.SetScript then
                    slot.playerCard:SetScript("OnDragStart", nil)
                    slot.playerCard:SetScript("OnDragStop", nil)
                end
            end
            if slot.frame then
                slot.frame:Hide()
                slot.frame:SetParent(nil)
                slot.frame:ClearAllPoints()
            end
            slotCount = slotCount + 1
        end
    end
    self.groupSlots = {}
    Debug:Dev("ui_contamination", "[ORGANIZER] Cleaned up", slotCount, "slot frames")
    
    -- CRITICAL: Clean up all other frame references
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
    
    -- Clear all interactive frame references
    if self.allInteractiveFrames then
        for _, frame in ipairs(self.allInteractiveFrames) do
            if frame then
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
    
    Debug:Dev("ui_contamination", "[ORGANIZER] CleanupNativeFrames completed - all references cleared")
end

-- MARK: Layout Calculation
function RosterBoard:CalculateOptimalLayout()
    local benchPlayers = self:GetBenchPlayers() or {}
    local groupedPlayers = self:GetGroupedPlayers() or {}
    local playerCount = #benchPlayers + #groupedPlayers
    
    -- Calculate needed groups (1-4 groups typically)
    local neededGroups = math.max(1, math.min(math.ceil(playerCount / 5), 4))
    
    -- Dynamic sizing - COMPACT
    local columnWidth = 180
    local benchWidth = 200  -- Compact bench
    local padding = 20
    local headerHeight = 100
    local groupHeight = 550
    
    local totalWidth = (columnWidth * neededGroups) + benchWidth + (padding * 3)
    local totalHeight = headerHeight + groupHeight + 150  -- 150 for opt-out section
    
    Debug:Dev("organizer_ui", "Layout - Players:", playerCount, "Groups:", neededGroups, "Window:", totalWidth, "x", totalHeight)
    
    return {
        groupColumns = neededGroups,
        columnWidth = columnWidth,
        benchWidth = benchWidth,
        totalWidth = totalWidth,
        totalHeight = totalHeight
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

-- MARK: Header Section (Native Container + AceGUI Widgets - Compact Flow)
function RosterBoard:CreateHeaderSection(nativeParent)
    -- Create native container for header
    local headerContainer = CreateFrame("Frame", nil, nativeParent)
    headerContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
    headerContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
    headerContainer:SetHeight(60)
    headerContainer:Show()
    
    -- Calculate available width
    local layout = self:CalculateOptimalLayout()
    
    -- Create AceGUI widgets with compact horizontal flow (no gaps)
    local xOffset = 0
    local buttonWidth = 120
    local checkboxWidth = 60
    local dropdownWidth = 110
    
    -- Poll Group Button (always visible) - WIDER to accommodate "Polling... (15/20)"
    local pollButton = AceGUI:Create("Button")
    pollButton:SetText("Poll")
    pollButton:SetWidth(150)  -- Increased from 120 to 150 for double-digit counts
    pollButton:SetCallback("OnClick", function()
        self:OnPollGroupClicked()
    end)
    pollButton.frame:SetParent(headerContainer)
    pollButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
    pollButton.frame:Show()
    self.pollButton = pollButton
    self.headerWidgets.pollButton = pollButton
    xOffset = xOffset + 150 + 5  -- Use actual button width
    
    -- SESSION 4: Clear Poll Button (next to Poll button)
    local clearPollButton = AceGUI:Create("Button")
    clearPollButton:SetText("Clear Poll")
    clearPollButton:SetWidth(buttonWidth)
    clearPollButton:SetCallback("OnClick", function()
        self:OnClearPollClicked()
    end)
    clearPollButton.frame:SetParent(headerContainer)
    clearPollButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
    clearPollButton.frame:Show()
    self.clearPollButton = clearPollButton
    self.headerWidgets.clearPollButton = clearPollButton
    xOffset = xOffset + buttonWidth + 5
    
    -- Add Fake Raid Button (debug only - next to Poll button)
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService:IsEnabled() then
        local fakeRaidButton = AceGUI:Create("Button")
        fakeRaidButton:SetText("Add Raid")
        fakeRaidButton:SetWidth(buttonWidth)
        fakeRaidButton:SetCallback("OnClick", function()
            self:OnAddFakeRaidClicked()
        end)
        fakeRaidButton.frame:SetParent(headerContainer)
        fakeRaidButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
        fakeRaidButton.frame:Show()
        self.fakeRaidButton = fakeRaidButton
        self.headerWidgets.fakeRaidButton = fakeRaidButton
        xOffset = xOffset + buttonWidth + 5
    end
    
    -- Sort Button (organizer only)
    local sortButton = AceGUI:Create("Button")
    sortButton:SetText("Sort")
    sortButton:SetWidth(buttonWidth)
    sortButton:SetCallback("OnClick", function()
        self:OnSortClicked()
    end)
    sortButton.frame:SetParent(headerContainer)
    sortButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
    sortButton.frame:Show()
    self.sortButton = sortButton
    self.headerWidgets.sortButton = sortButton
    xOffset = xOffset + buttonWidth + 5
    
    -- Announce Button (always visible)
    local announceButton = AceGUI:Create("Button")
    announceButton:SetText("Announce")
    announceButton:SetWidth(buttonWidth)
    announceButton:SetCallback("OnClick", function()
        self:OnAnnounceClicked()
    end)
    announceButton.frame:SetParent(headerContainer)
    announceButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
    announceButton.frame:Show()
    self.announceButton = announceButton
    self.headerWidgets.announceButton = announceButton
    xOffset = xOffset + buttonWidth + 5
    
    -- Raid checkbox (always visible for compact layout)
    local raidCheckbox = AceGUI:Create("CheckBox")
    raidCheckbox:SetLabel("Raid")
    raidCheckbox:SetValue(true)
    raidCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        self.announceToRaid = value
    end)
    raidCheckbox.frame:SetParent(headerContainer)
    raidCheckbox.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, -5)
    raidCheckbox.frame:Show()
    self.headerWidgets.raidCheckbox = raidCheckbox
    xOffset = xOffset + checkboxWidth + 5
    
    -- Guild checkbox (always visible for compact layout)
    local guildCheckbox = AceGUI:Create("CheckBox")
    guildCheckbox:SetLabel("Guild")
    guildCheckbox:SetValue(false)
    guildCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        self.announceToGuild = value
    end)
    guildCheckbox.frame:SetParent(headerContainer)
    guildCheckbox.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, -5)
    guildCheckbox.frame:Show()
    self.headerWidgets.guildCheckbox = guildCheckbox
    xOffset = xOffset + checkboxWidth + 5
    
    -- Only show optimizer controls if window is wide enough (3+ groups)
    if layout.groupColumns >= 3 then
        -- Optimizer Dropdown
        local optimizerDropdown = AceGUI:Create("Dropdown")
        optimizerDropdown:SetLabel("Opt:")
        optimizerDropdown:SetList({
            mode1 = "Max Power",
            mode2 = "Balanced",
            mode3 = "Vault"
        })
        optimizerDropdown:SetValue("mode2")
        optimizerDropdown:SetWidth(dropdownWidth)
        optimizerDropdown:SetCallback("OnValueChanged", function(widget, event, value)
            self.selectedOptimizerMode = value
        end)
        optimizerDropdown.frame:SetParent(headerContainer)
        optimizerDropdown.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
        optimizerDropdown.frame:Show()
        self.optimizerDropdown = optimizerDropdown
        self.headerWidgets.optimizerDropdown = optimizerDropdown
        xOffset = xOffset + dropdownWidth + 5
        
        -- Optimize Button
        local optimizeButton = AceGUI:Create("Button")
        optimizeButton:SetText("Run")
        optimizeButton:SetWidth(60)
        optimizeButton:SetCallback("OnClick", function()
            self:OnOptimizeClicked()
        end)
        optimizeButton.frame:SetParent(headerContainer)
        optimizeButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
        optimizeButton.frame:Show()
        self.optimizeButton = optimizeButton
        self.headerWidgets.optimizeButton = optimizeButton
    end
    
    self.headerSection = headerContainer
end

-- MARK: Header Button Handlers
function RosterBoard:OnPollGroupClicked()
    return NextKey222.SafeRun(function()
        -- DEBUG MODE: If fake players exist, trigger poll simulation instead
        local hasFakePlayers = NextKey222.FakePlayerService and
                               NextKey222.FakePlayerService:IsEnabled() and
                               #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
        
        if hasFakePlayers then
        	Debug:User("DEBUG MODE: Triggering poll simulation with fake players")
        	
        	-- Generate unique poll ID
        	local pollID = self:GeneratePollID()
        	
        	-- Store poll state
        	self.activePoll = {
        		id = pollID,
        		startTime = GetTime(),
        		responses = {},
        		timeout = 60
        	}
        	
        	-- Update UI to show polling
        	self:ShowPollInProgress()
        	
        	-- CRITICAL FIX: Start timeout timer for debug mode too!
        	self:StartPollTimeout()
        	
        	-- Trigger instant simulation
        	if NextKey222.PollSimulator and NextKey222.PollSimulator:IsInitialized() then
        		NextKey222.PollSimulator:SimulatePoll("instant", pollID)
        		Debug:Dev("organizer", "Started instant poll simulation with ID:", pollID)
        	else
        		Debug:Error("PollSimulator not available")
        	end
        	
        	-- Show organizer's own survey (ONLY in debug mode)
        	if NextKey222.ParticipantSurvey then
        		local pollRequest = {
        			pollID = pollID,
        			timeout = 60,
        			organizerName = UnitName("player") .. "-" .. GetRealmName()
        		}
        		NextKey222.ParticipantSurvey:OnPollRequestReceived(pollRequest, pollRequest.organizerName)
        	end
        	
        	return
        end
        
        -- PRODUCTION MODE: Normal group polling
        
        -- Validate we're in a group
        local groupSize = GetNumGroupMembers()
        if groupSize < 2 then
            Debug:User("You must be in a group to poll members")
            return
        end
        
        -- Generate unique poll ID
        local pollID = self:GeneratePollID()
        
        -- Store poll state
        self.activePoll = {
            id = pollID,
            startTime = GetTime(),
            responses = {},
            timeout = 60
        }
        
        -- Send poll request to all members (including self)
        if NextKey222.ParticipantSurvey then
        	NextKey222.ParticipantSurvey:SendPollRequest(pollID)
        	
        	-- REMOVED: Duplicate organizer survey call (SendPollRequest already includes organizer)
        	-- The organizer receives the poll via the RAID broadcast in SendPollRequest
        end
        
        -- Simultaneously trigger auto-detection
        self:RunAutoDetection()
        
        -- Start timeout timer
        self:StartPollTimeout()
        
        -- Update UI
        self:ShowPollInProgress()
        
        Debug:Dev("organizer", "Started poll with ID:", pollID)
        
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
	-- Disable poll button
	if self.pollButton then
		self.pollButton:SetDisabled(true)
		
		-- Calculate total expected responses FIRST (before using it)
		local totalMembers = GetNumGroupMembers()
		
		-- In debug mode with fake players, count fake players
		local hasFakePlayers = NextKey222.FakePlayerService and
		                       NextKey222.FakePlayerService:IsEnabled() and
		                       #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
		
		if hasFakePlayers then
			totalMembers = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1  -- +1 for organizer
		end
		
		self.pollButton:SetText("Polling... (0/" .. totalMembers .. ")")
	end
end

function RosterBoard:UpdatePollProgress()
    if not self.activePoll or not self.pollButton then
        return
    end
    
    -- Calculate total expected responses
    local totalMembers = GetNumGroupMembers()
    
    -- In debug mode with fake players, count fake players
    local hasFakePlayers = NextKey222.FakePlayerService and
                           NextKey222.FakePlayerService:IsEnabled() and
                           #NextKey222.FakePlayerService:GetAllPlayerNames() > 0
    
    if hasFakePlayers then
        totalMembers = #NextKey222.FakePlayerService:GetAllPlayerNames() + 1  -- +1 for organizer
    end
    
    local responses = #self.activePoll.responses
    
    -- Update button text
    self.pollButton:SetText("Polling... (" .. responses .. "/" .. totalMembers .. ")")
    
    -- Check if complete (all members responded, including organizer)
    if responses >= totalMembers then
        self:CompletePoll()
    end
end

function RosterBoard:CompletePoll()
    if not self.activePoll then return end
    
    -- Cancel timeout timer
    if self.pollTimeoutTimer then
        self.pollTimeoutTimer:Cancel()
        self.pollTimeoutTimer = nil
    end
    
    -- Re-enable poll button
    if self.pollButton then
        self.pollButton:SetDisabled(false)
        self.pollButton:SetText("Poll")
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

function RosterBoard:OnOptimizeClicked()
    Debug:Dev("organizer_ui", "Optimize clicked with mode:", self.selectedOptimizerMode)
    Debug:User("Optimizer algorithms will be implemented in Phase 4")
end

function RosterBoard:OnAnnounceClicked()
    Debug:Dev("organizer_ui", "Announce clicked")
    Debug:User("Announcement system will be implemented in Phase 5")
end

-- MARK: Clear Poll Handler (SESSION 4)
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
        
        -- Reset poll button
        if self.pollButton then
            self.pollButton:SetDisabled(false)
            self.pollButton:SetText("Poll")
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

-- MARK: Sorting Orchestrator
function RosterBoard:OnSortClicked()
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
        
        -- Disable sort button during execution
        if self.sortButton then
            self.sortButton:SetDisabled(true)
            self.sortButton:SetText("Sorting...")
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
            self:ResetSortButton()
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
            self:ResetSortButton()
            return
        end
        
        Debug:User("Starting sort animation for", #validAssignments, "players")
        
        -- Execute animation sequence with simplified API
        NextKey222.AnimationQueue:ExecuteSequence(validAssignments, function()
            self:OnSortComplete()
        end)
        
    end, "RosterBoard:OnSortClicked")
end

function RosterBoard:OnSortComplete()
    Debug:Dev("organizer", "Sort animation sequence completed")
    
    -- Re-enable sort button
    self:ResetSortButton()
    
    -- Refresh layout
    self:LayoutBench()
    
    Debug:User("Sorting complete!")
end

function RosterBoard:ResetSortButton()
    if self.sortButton then
        self.sortButton:SetDisabled(false)
        self.sortButton:SetText("Sort")
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

-- MARK: Active Pool Section (Delegates to SlotManager)
function RosterBoard:CreateActivePoolSection(nativeParent)
    return NextKey222.SlotManager:create_active_pool_section(self, nativeParent)
end

-- MARK: Flat Role Slot Creation (Delegates to SlotManager)
function RosterBoard:CreateFlatRoleSlot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
    return NextKey222.SlotManager:create_flat_role_slot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
end

-- MARK: Native Bench Column (Delegates to BenchManager)
function RosterBoard:CreateNativeBenchColumn(width, parentFrame)
    return NextKey222.BenchManager:create_native_bench_column(self, width, parentFrame)
end
-- MARK: Add Player to Bench (Delegates to BenchManager)
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
            "compact"
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

-- MARK: Populate Bench (Delegates to BenchManager)
function RosterBoard:PopulateBench(players)
    return NextKey222.BenchManager:populate_bench(self, players)
end

-- MARK: Window Resize Check (Delegates to BenchManager)
function RosterBoard:CheckAndResizeWindow()
    return NextKey222.BenchManager:check_and_resize_window(self)
end

-- MARK: Layout Bench (Delegates to BenchManager)
function RosterBoard:LayoutBench()
    return NextKey222.BenchManager:layout_bench(self)
end

-- MARK: Opt-Out Section (Delegates to SlotManager)
function RosterBoard:CreateOptOutSection(nativeParent)
    return NextKey222.SlotManager:create_opt_out_section(self, nativeParent)
end

function RosterBoard:PopulateOptOut(players)
    return NextKey222.SlotManager:populate_opt_out(self, players)
end

-- MARK: Place Card in Opt-Out (Delegates to SlotManager)
function RosterBoard:PlaceCardInOptOut(card)
    return NextKey222.SlotManager:place_card_in_opt_out(self, card)
end

-- MARK: Layout Opt-Out (Delegates to SlotManager)
function RosterBoard:LayoutOptOut()
    return NextKey222.SlotManager:layout_opt_out(self)
end

-- MARK: Drop Target Detection (Delegates to CardMovement)
function RosterBoard:DetectDropTarget()
    return NextKey222.CardMovement:detect_drop_target(self)
end

-- MARK: Card Drop Handler (Delegates to CardMovement)
function RosterBoard:HandleCardDrop(card, dropTarget)
    return NextKey222.CardMovement:handle_card_drop(self, card, dropTarget)
end

-- MARK: Mark Card For Removal (Delegates to CardMovement)
function RosterBoard:MarkCardForRemoval(card)
    return NextKey222.CardMovement:mark_card_for_removal(self, card)
end

-- MARK: Complete Card Removal (Delegates to CardMovement)
function RosterBoard:CompleteCardRemoval(card)
    return NextKey222.CardMovement:complete_card_removal(self, card)
end

-- MARK: Place Card in Slot (Delegates to SlotManager)
function RosterBoard:PlaceCardInSlot(card, slot)
    return NextKey222.SlotManager:place_card_in_slot(card, slot)
end

-- MARK: Place Card in Bench (Delegates to CardMovement)
function RosterBoard:PlaceCardInBench(card)
    return NextKey222.CardMovement:place_card_in_bench(self, card)
end

-- MARK: Remove Card From Bench Array (Delegates to CardMovement)
function RosterBoard:RemoveCardFromBenchArray(card)
    return NextKey222.CardMovement:remove_card_from_bench_array(self, card)
end

-- MARK: Rejection Animation (Delegates to CardMovement)
function RosterBoard:AnimateRejection(card)
    return NextKey222.CardMovement:animate_rejection(self, card)
end

-- MARK: Role Validation (Delegates to CardMovement)
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

-- MARK: Keystone Designation (Delegates to KeystoneManager)
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

-- MARK: Helper Functions (Delegates to KeystoneManager)
function RosterBoard:FindCardByPlayerID(playerID)
    return NextKey222.KeystoneManager:find_card_by_player_id(self, playerID)
end

-- MARK: Bench Rebuild After Poll (NEW - Forces UI Refresh)
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
            
            for role, preference in pairs(card.playerData.specPreferences) do
                if role:upper() == newSpecRole:upper() and preference ~= "none" then
                    pollHasThisRole = true
                    break
                end
            end
            
            if not pollHasThisRole then
                -- They switched to a spec they didn't sign up for - invalidate poll
                Debug:Dev("organizer_ui", "New spec NOT in poll preferences - invalidating poll response")
                
                if NextKey222.OrganizerPlayerDataBuilder and
                   NextKey222.OrganizerPlayerDataBuilder.GenerateDefaultSpecPreferences then
                    local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(playerID)
                    
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
               NextKey222.OrganizerPlayerDataBuilder.GenerateDefaultSpecPreferences then
                local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(playerID)
                
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

-- MARK: Refresh Bench Cards From State (SESSION 3: Poll Data Visual Update)
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

-- MARK: Refresh Single Card By PlayerID (SESSION 3: Real-time Poll Updates)
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

-- MARK: Sync UI to State (SESSION 3: Handle Opt-Out/Alt Movement)
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
        
        Debug:Dev("organizer_ui", "Synced UI to state -", #self.benchCards, "bench,",
                 #self.optOutSection.playerCards, "opt-out")
        
    end, "RosterBoard:SyncUIToState")
end