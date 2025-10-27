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
    local allPlayers = {}
    local seenPlayers = {}  -- Track which players we've already added
    
    -- Add fake players (normalize format to match expected structure)
    if NextKey222.FakePlayerService then
        local fakePlayers = NextKey222.FakePlayerService:GetAllPlayers()
        if fakePlayers then
            Debug:Dev("organizer_ui", "Found", #fakePlayers, "fake players")
            for _, fakeData in ipairs(fakePlayers) do
                -- Convert fake player format to expected card format
                local playerData = {
                    id = fakeData.name,  -- Use full name with realm as ID
                    name = fakeData.name:match("^([^%-]+)") or fakeData.name,  -- Short name
                    class = fakeData.class,
                    roles = {fakeData.role or "DAMAGER"},  -- Convert string to array
                    keystone = fakeData.keystone,
                    overallScore = fakeData.io or 0,  -- Rename io -> overallScore
                    specName = fakeData.specName,  -- Preserve spec name
                    utilities = {}
                }
                
                -- Add utilities based on capabilities
                if fakeData.heroismCaster then
                    table.insert(playerData.utilities, "heroism")
                end
                if fakeData.battleResCaster then
                    table.insert(playerData.utilities, "battleRes")
                end
                
                table.insert(allPlayers, playerData)
                seenPlayers[fakeData.name] = true  -- Mark as seen
            end
        end
    end
    
    -- Add real party members (skip if already added as fake players)
    if NextKey222.Addon and NextKey222.Addon.GetPartyMemberNames then
        local partyMembers = NextKey222.Addon:GetPartyMemberNames()
        Debug:Dev("organizer_ui", "Found", #partyMembers, "party members")
        
        for _, memberName in ipairs(partyMembers) do
            -- Skip if already added as fake player
            if seenPlayers[memberName] then
                Debug:Dev("organizer_ui", "Skipping", memberName, "- already added as fake player")
            else
                -- Use BASE profile to get CURRENT spec's role
                local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(memberName)
                if profile then
                    local playerData = {
                        id = memberName,
                        name = memberName:match("^([^%-]+)") or memberName,
                        class = profile.class,
                        -- CRITICAL: Use current spec's role, not multi-role array from CharacterStorage
                        roles = {profile.role or "DAMAGER"},
                        keystone = nil,  -- Will be populated below
                        overallScore = profile.io or 0,
                        specName = profile.specName,
                        specID = profile.specID,
                        utilities = {}
                    }
                    
                    -- Get keystone from organizer profile
                    local organizerProfile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetOrganizerProfile(memberName)
                    if organizerProfile and organizerProfile.keystone then
                        playerData.keystone = organizerProfile.keystone
                    end
                    
                    -- Use capabilities from base profile for utilities
                    if profile.capabilities then
                        if profile.capabilities.heroism then
                            table.insert(playerData.utilities, "heroism")
                        end
                        if profile.capabilities.battleRes then
                            table.insert(playerData.utilities, "battleRes")
                        end
                    end
                    
                    Debug:Dev("organizer_ui", "Created player data for", memberName, "with current spec role:", profile.role, "specName:", profile.specName)
                    
                    table.insert(allPlayers, playerData)
                    seenPlayers[memberName] = true  -- Mark as seen
                end
            end
        end
    end
    
    Debug:Dev("organizer_ui", "GetBenchPlayers returning", #allPlayers, "total players")
    return allPlayers
end

function RosterBoard:GetGroupedPlayers()
    local result = NextKey222.SafeRun(function()
        return {}
    end, "RosterBoard:GetGroupedPlayers")
    
    return result or {}
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
        
        self:PopulateOptOut({})
        
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
    local buttonWidth = 90
    local checkboxWidth = 60
    local dropdownWidth = 110
    
    -- Poll Group Button (always visible)
    local pollButton = AceGUI:Create("Button")
    pollButton:SetText("Poll")
    pollButton:SetWidth(buttonWidth)
    pollButton:SetCallback("OnClick", function()
        self:OnPollGroupClicked()
    end)
    pollButton.frame:SetParent(headerContainer)
    pollButton.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", xOffset, 0)
    pollButton.frame:Show()
    self.pollButton = pollButton
    self.headerWidgets.pollButton = pollButton
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
            
            -- Trigger instant simulation
            if NextKey222.PollSimulator and NextKey222.PollSimulator:IsInitialized() then
                NextKey222.PollSimulator:SimulatePoll("instant", pollID)
                Debug:Dev("organizer", "Started instant poll simulation with ID:", pollID)
            else
                Debug:Error("PollSimulator not available")
            end
            
            -- Show organizer's own survey
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
            
            -- Also show survey to organizer
            local pollRequest = {
                pollID = pollID,
                timeout = 60,
                organizerName = UnitName("player") .. "-" .. GetRealmName()
            }
            NextKey222.ParticipantSurvey:OnPollRequestReceived(pollRequest, pollRequest.organizerName)
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
        local total = GetNumGroupMembers()
        self.pollButton:SetText("Polling... (0/" .. total .. ")")
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
        self.pollButton:SetText("Poll Group")
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
end

function RosterBoard:OnOptimizeClicked()
    Debug:Dev("organizer_ui", "Optimize clicked with mode:", self.selectedOptimizerMode)
    Debug:User("Optimizer algorithms will be implemented in Phase 4")
end

function RosterBoard:OnAnnounceClicked()
    Debug:Dev("organizer_ui", "Announce clicked")
    Debug:User("Announcement system will be implemented in Phase 5")
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

-- MARK: Active Pool Section (FLAT ARCHITECTURE - All Siblings)
function RosterBoard:CreateActivePoolSection(nativeParent)
    print("[ORGANIZER DIAGNOSTIC] CreateActivePoolSection (FLAT) called")
    print("[ORGANIZER DIAGNOSTIC] Parent frame strata:", nativeParent:GetFrameStrata(), "level:", nativeParent:GetFrameLevel())
    
    -- Create a pure native container frame
    local poolContainer = CreateFrame("Frame", nil, nativeParent)
    poolContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -90)  -- Below header
    poolContainer:SetPoint("BOTTOMRIGHT", nativeParent, "BOTTOMRIGHT", -10, 120)  -- Above opt-out
    poolContainer:Show()
    print("[ORGANIZER DIAGNOSTIC] Pool container created - Strata:", poolContainer:GetFrameStrata(), "Level:", poolContainer:GetFrameLevel())
    
    Debug:Dev("organizer_ui", "Created pool container with flat architecture")
    
    local layout = self:CalculateOptimalLayout()
    print("[ORGANIZER DIAGNOSTIC] Layout - groups:", layout.groupColumns)
    
    -- Initialize arrays
    self.groupBackgrounds = {}
    self.groupSlots = {}
    self.groupTitles = {}
    self.groupKeystones = {}
    self.allInteractiveFrames = {}
    
    -- Create visual backgrounds and interactive slots (all as siblings)
    local columnWidth = 170
    local columnSpacing = 10
    
    for groupIndex = 1, layout.groupColumns do
        local groupXOffset = (groupIndex - 1) * (columnWidth + columnSpacing)
        
        print("[ORGANIZER DIAGNOSTIC] Creating group", groupIndex, "at xOffset:", groupXOffset)
        
        -- Create visual background texture (non-interactive)
        local bgTexture = poolContainer:CreateTexture(nil, "BACKGROUND")
        bgTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        bgTexture:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", groupXOffset, 0)
        bgTexture:SetSize(columnWidth, 550)
        bgTexture:SetDrawLayer("BACKGROUND", -5)  -- Way back
        self.groupBackgrounds[groupIndex] = bgTexture
        
        -- Create title label (sibling of slots)
        local titleLabel = poolContainer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        titleLabel:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", groupXOffset + (columnWidth / 2), -10)
        titleLabel:SetJustifyH("CENTER")
        titleLabel:SetText("M+ Grp. " .. groupIndex)
        titleLabel:SetDrawLayer("ARTWORK", 5)  -- Above backgrounds, below slots
        self.groupTitles[groupIndex] = titleLabel  -- Store for later updates
        
        -- Initialize keystone data
        self.groupKeystones[groupIndex] = {keystone = nil, playerID = nil}
        
        -- Create role slots as direct children of poolContainer (NOT nested)
        self.groupSlots[groupIndex] = {}
        local roles = {"TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER"}
        local roleLabels = {"Tank", "Healer", "DPS", "DPS", "DPS"}
        
        for slotIndex, role in ipairs(roles) do
            local slotYOffset = 35 + ((slotIndex - 1) * 98)  -- Title space + (slot height + spacing)
            
            local slot = self:CreateFlatRoleSlot(
                poolContainer,
                groupIndex,
                role,
                roleLabels[slotIndex],
                slotIndex,
                groupXOffset + 10,  -- X: column offset + padding
                -slotYOffset         -- Y: negative for downward positioning
            )
            
            self.groupSlots[groupIndex][slotIndex] = slot
            table.insert(self.allInteractiveFrames, slot)  -- Strong reference
            
            print("[ORGANIZER DIAGNOSTIC] Created slot", groupIndex, slotIndex, roleLabels[slotIndex], "at:", groupXOffset + 10, -slotYOffset)
        end
    end
    
    print("[ORGANIZER DIAGNOSTIC] Created", #self.groupSlots, "groups with", #self.allInteractiveFrames, "total slots")
    
    -- Create bench (also as sibling)
    local benchXOffset = layout.groupColumns * (columnWidth + columnSpacing)
    local benchColumn = self:CreateNativeBenchColumn(layout.benchWidth, poolContainer)
    benchColumn:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", benchXOffset, 0)
    
    self.activePoolSection = poolContainer
    
    Debug:Dev("organizer_ui", "Active pool section created with flat architecture")
end

-- MARK: Flat Role Slot Creation (Sibling Architecture)
function RosterBoard:CreateFlatRoleSlot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
    -- Create slot frame as direct child of poolContainer (NOT nested in column)
    local slot = CreateFrame("Frame", nil, parentContainer, "BackdropTemplate")
    slot:SetSize(150, 95)
    slot:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", xPos, yPos)
    slot:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slot:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    
    -- Role-colored border
    local borderColor = {r=0.5, g=0.5, b=0.5}
    if role == "TANK" then
        borderColor = {r=0.2, g=0.5, b=1.0}
    elseif role == "HEALER" then
        borderColor = {r=0.1, g=0.9, b=0.1}
    elseif role == "DAMAGER" then
        borderColor = {r=0.9, g=0.1, b=0.1}
    end
    slot:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1.0)
    
    -- Empty label
    local emptyLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyLabel:SetPoint("CENTER")
    emptyLabel:SetText(roleLabel)
    emptyLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Enable mouse for drop detection (CRITICAL)
    slot:EnableMouse(true)
    slot:SetFrameLevel(parentContainer:GetFrameLevel() + 50)  -- WAY above parent
    slot:Show()
    
    print("[SLOT DIAGNOSTIC]", roleLabel, "Level:", slot:GetFrameLevel(), "Parent level:", parentContainer:GetFrameLevel())
    Debug:Dev("organizer_ui", "Created FLAT slot:", groupIndex, slotIndex, roleLabel, "Strata:", slot:GetFrameStrata(), "Level:", slot:GetFrameLevel())
    
    -- Store metadata
    slot.groupIndex = groupIndex
    slot.role = role
    slot.roleLabel = roleLabel
    slot.slotIndex = slotIndex
    slot.playerCard = nil
    slot.emptyLabel = emptyLabel
    slot.isEmpty = true
    slot.frame = slot  -- For compatibility
    
    return slot
end

-- MARK: Native Bench Column (FULLY NATIVE - Based on drag_test_simple.lua)
function RosterBoard:CreateNativeBenchColumn(width, parentFrame)
    -- Create pure native bench frame
    local bench = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    bench:SetSize(width, 540)
    bench:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    bench:Show()
    
    -- Title label
    local titleLabel = bench:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", 0, -10)
    titleLabel:SetText("Roster")
    
    -- Create native scroll frame inside
    local scrollFrame = CreateFrame("ScrollFrame", nil, bench, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    scrollFrame:Show()
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(180, 1)  -- Compact width
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:Show()
    
    -- Store references
    bench.scrollFrame = scrollFrame
    bench.scrollChild = scrollChild
    bench.frame = bench  -- For compatibility
    self.benchContainer = scrollChild
    self.benchScrollFrame = scrollFrame
    self.benchCards = {}
    
    Debug:Dev("organizer_ui", "Created FULLY NATIVE bench column")
    
    return bench
end
-- MARK: Add Player to Bench (Individual)
function RosterBoard:AddPlayerToBench(playerData)
    return NextKey222.SafeRun(function()
        if not self.benchContainer then
            Debug:Error("Bench container not initialized")
            return
        end
        
        -- Create native card
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            self.benchContainer,
            "bench",
            "compact"
        )
        
        if card then
            table.insert(self.benchCards, card)
            
            -- Add visual indicator if auto-detected
            if playerData.dataSource == "auto-detected" then
                self:AddAutoDetectedIndicator(card)
            end
            
            -- Re-layout bench
            self:LayoutBench()
            
            -- Check if window needs to resize for more groups
            self:CheckAndResizeWindow()
            
            Debug:Dev("organizer", "Added player to bench:", playerData.name)
        else
            Debug:Error("Failed to create card for:", playerData.name)
        end
        
    end, "RosterBoard:AddPlayerToBench")
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
    return NextKey222.SafeRun(function()
        if not self.benchCards then
            return
        end
        
        -- Find and remove the player card
        for i = #self.benchCards, 1, -1 do
            local card = self.benchCards[i]
            if card.playerData and card.playerData.id == playerID then
                -- Hide and remove card
                card:Hide()
                card:SetParent(nil)
                table.remove(self.benchCards, i)
                
                Debug:Dev("organizer", "Removed player from bench:", playerID)
                
                -- Re-layout bench
                self:LayoutBench()
                return true
            end
        end
        
        Debug:Dev("organizer", "Player not found in bench:", playerID)
        return false
        
    end, "RosterBoard:RemovePlayerFromBench")
end

function RosterBoard:AddAutoDetectedIndicator(playerCard)
    -- Add small icon overlay to card indicating no addon
    -- For now, just log it - can add visual indicator later
    Debug:Dev("organizer", "Player auto-detected (no addon):", playerCard.playerData.name)
end

-- MARK: Populate Bench (Batch)
function RosterBoard:PopulateBench(players)
    if not self.benchContainer then
        Debug:Error("Bench container not initialized")
        return
    end
    
    -- Clear existing cards
    for _, card in ipairs(self.benchCards) do
        if card then
            card:Hide()
            card:SetParent(nil)
        end
    end
    self.benchCards = {}
    
    Debug:Dev("organizer_ui", "Populating bench with", #players, "players")
    
    -- Create native cards
    for i, playerData in ipairs(players) do
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            self.benchContainer,
            "bench",
            "compact"
        )
        
        if card then
            table.insert(self.benchCards, card)
            Debug:Dev("organizer_ui", "Created bench card", i, "for:", playerData.name)
        else
            Debug:Error("Failed to create card for:", playerData.name)
        end
    end
    
    -- Layout bench
    self:LayoutBench()
    
    Debug:Dev("organizer_ui", "Bench populated with", #self.benchCards, "cards")
end

-- MARK: Window Resize Check
function RosterBoard:CheckAndResizeWindow()
    if not self.mainFrame then
        return
    end
    
    -- Calculate what the layout should be
    local newLayout = self:CalculateOptimalLayout()
    
    -- Get current number of groups
    local currentGroupCount = #self.groupSlots or 0
    
    -- If we need more groups, rebuild the entire window
    if newLayout.groupColumns > currentGroupCount then
        Debug:Dev("organizer_ui", "Player count increased - need more groups. Rebuilding window...")
        
        -- Store visibility state
        local wasVisible = self.mainFrame:IsVisible()
        
        -- Close and recreate
        self:OnMainFrameClosed(self.mainFrame)
        
        if wasVisible then
            self:CreateMainFrame()
        end
    end
end

-- MARK: Layout Bench (NEW - Manual Layout System)
function RosterBoard:LayoutBench()
    if not self.benchContainer or not self.benchCards then
        return
    end
    
    local yOffset = 0
    local spacing = 3
    
    Debug:Dev("organizer_ui", "Laying out", #self.benchCards, "bench cards")
    
    for i, card in ipairs(self.benchCards) do
        card:ClearAllPoints()
        card:SetPoint("TOP", self.benchContainer, "TOP", 0, -yOffset)
        card:SetSize(180, 20)  -- Compact: 180px wide, 20px tall
        card:SetParent(self.benchContainer)  -- Ensure correct parent
        card:Show()
        yOffset = yOffset + 20 + spacing
    end
    
    -- Update scroll child height
    self.benchContainer:SetHeight(math.max(yOffset, 1))
    
    Debug:Dev("organizer_ui", "Bench layout complete")
end

-- MARK: Opt-Out Section (FULLY NATIVE - Fixed Horizontal Scrolling)
function RosterBoard:CreateOptOutSection(nativeParent)
    -- Create pure native opt-out frame
    local optOut = CreateFrame("Frame", nil, nativeParent, "BackdropTemplate")
    optOut:SetPoint("BOTTOMLEFT", nativeParent, "BOTTOMLEFT", 10, 15)
    optOut:SetPoint("BOTTOMRIGHT", nativeParent, "BOTTOMRIGHT", -10, 15)
    optOut:SetHeight(95)
    optOut:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    optOut:Show()
    
    -- Title label
    local titleLabel = optOut:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", 0, -10)
    titleLabel:SetText("Not Playing")
    
    -- Create native scroll frame inside (HORIZONTAL scrolling)
    local scrollFrame = CreateFrame("ScrollFrame", nil, optOut, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    scrollFrame:Show()
    
    -- Enable mouse wheel for horizontal scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetHorizontalScroll()
        local maxScroll = self:GetHorizontalScrollRange()
        local newScroll = math.max(0, math.min(current - (delta * 40), maxScroll))
        self:SetHorizontalScroll(newScroll)
    end)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 30)  -- Start with minimal width, height for single row
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:Show()
    
    -- Store references
    optOut.scrollFrame = scrollFrame
    optOut.scrollChild = scrollChild
    optOut.playerCards = {}
    optOut.frame = optOut  -- For compatibility
    
    self.optOutSection = optOut
    
    Debug:Dev("organizer_ui", "Created FULLY NATIVE opt-out section with horizontal scrolling")
end

function RosterBoard:PopulateOptOut(players)
    if not self.optOutSection or not self.optOutSection.scrollChild then
        return
    end
    
    -- Clear existing cards
    for _, card in ipairs(self.optOutSection.playerCards) do
        if card then
            card:Hide()
            card:SetParent(nil)
        end
    end
    self.optOutSection.playerCards = {}
    
    -- Create native cards for opted-out players
    for i, playerData in ipairs(players) do
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            self.optOutSection.scrollChild,
            "opt_out",
            "compact"  -- Use compact mode (same as bench)
        )
        
        if card then
            table.insert(self.optOutSection.playerCards, card)
        end
    end
    
    -- Layout horizontally
    self:LayoutOptOut()
    
    Debug:Dev("organizer_ui", "Populated opt-out with", #players, "players")
end

-- MARK: Place Card in Opt-Out
function RosterBoard:PlaceCardInOptOut(card)
    Debug:Dev("organizer_ui", "Placing card in opt-out")
    
    if not self.optOutSection or not self.optOutSection.scrollChild then
        Debug:Error("Opt-out section not initialized")
        return
    end
    
    -- Use opt_out mode (2-line square layout)
    card:SetSize(90, 40)  -- Opt-out size (square-ish for 2-line)
    card:SetParent(self.optOutSection.scrollChild)
    
    -- Update metadata
    card.location = "opt_out"
    
    -- Update card content to opt_out mode
    NextKey222.PlayerCard:UpdateCardContent(card, "opt_out")
    
    -- Add to opt-out array
    table.insert(self.optOutSection.playerCards, card)
    
    -- Reset colors
    card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
    card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    
    -- Re-layout opt-out section horizontally
    self:LayoutOptOut()
    
    Debug:Dev("organizer_ui", "Card placed in opt-out successfully")
end

-- MARK: Layout Opt-Out (Horizontal)
function RosterBoard:LayoutOptOut()
    if not self.optOutSection or not self.optOutSection.scrollChild or not self.optOutSection.playerCards then
        return
    end
    
    local xOffset = 0
    local spacing = 5
    local cardWidth = 90  -- Opt-out width (square-ish)
    local cardHeight = 40  -- Opt-out height (2-line)
    
    Debug:Dev("organizer_ui", "Laying out", #self.optOutSection.playerCards, "opt-out cards horizontally")
    
    for i, card in ipairs(self.optOutSection.playerCards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", self.optOutSection.scrollChild, "TOPLEFT", xOffset, 0)
        card:SetSize(cardWidth, cardHeight)
        card:SetParent(self.optOutSection.scrollChild)
        card:Show()
        xOffset = xOffset + cardWidth + spacing
    end
    
    -- Update scroll child width for horizontal scrolling
    self.optOutSection.scrollChild:SetWidth(math.max(xOffset, 1))
    self.optOutSection.scrollChild:SetHeight(cardHeight + 10)
    
    Debug:Dev("organizer_ui", "Opt-out layout complete, total width:", xOffset)
end

-- MARK: Drop Target Detection (NEW - IsMouseOver based)
function RosterBoard:DetectDropTarget()
    -- Check role slots first (highest priority)
    if self.groupSlots then
        for groupIndex, slots in pairs(self.groupSlots) do
            for slotIndex, slot in pairs(slots) do
                if slot and slot.frame and slot.frame:IsMouseOver() then
                    Debug:Dev("organizer_ui", "Mouse over slot:", groupIndex, slotIndex, slot.roleLabel)
                    return {
                        type = "role_slot",
                        slot = slot,
                        groupIndex = groupIndex,
                        slotIndex = slotIndex,
                        role = slot.role
                    }
                end
            end
        end
    end
    
    -- Check bench scroll frame (entire area including empty space)
    if self.benchScrollFrame and self.benchScrollFrame:IsMouseOver() then
        Debug:Dev("organizer_ui", "Mouse over bench")
        return {type = "bench"}
    end
    
    -- Check opt-out scroll frame (entire area including empty space)
    if self.optOutSection and self.optOutSection.scrollFrame and self.optOutSection.scrollFrame:IsMouseOver() then
        Debug:Dev("organizer_ui", "Mouse over opt-out")
        return {type = "opt_out"}
    end
    
    return nil
end

-- MARK: Card Drop Handler (NEW - Two-Phase Removal)
function RosterBoard:HandleCardDrop(card, dropTarget)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "HandleCardDrop - type:", dropTarget.type)
        
        -- Phase 1: Mark for removal (non-destructive)
        self:MarkCardForRemoval(card)
        
        if dropTarget.type == "role_slot" then
            -- Validate role
            local canFill = self:CanPlayerFillRole(card.playerData.roles, dropTarget.role)
            
            if not canFill then
                -- Try to find compatible slot in same group
                local compatibleSlot = self:FindCompatibleSlotInGroup(card, dropTarget.groupIndex)
                if compatibleSlot then
                    Debug:Dev("organizer_ui", "Found compatible slot:", compatibleSlot.roleLabel)
                    dropTarget = {
                        type = "role_slot",
                        slot = compatibleSlot,
                        groupIndex = dropTarget.groupIndex,
                        slotIndex = compatibleSlot.slotIndex,
                        role = compatibleSlot.role
                    }
                else
                    Debug:Dev("organizer_ui", "No compatible slot - rejecting")
                    self:AnimateRejection(card)
                    return
                end
            end
            
            -- Check if slot is occupied
            if not dropTarget.slot.isEmpty then
                Debug:Dev("organizer_ui", "Slot occupied - rejecting")
                self:AnimateRejection(card)
                return
            end
            
            -- SUCCESS - Phase 2: Actually remove from source
            self:CompleteCardRemoval(card)
            
            -- Place in slot
            self:PlaceCardInSlot(card, dropTarget.slot)
            
        elseif dropTarget.type == "bench" then
            -- SUCCESS - Phase 2: Actually remove from source
            self:CompleteCardRemoval(card)
            
            -- Bench always accepts - no rejection animation
            self:PlaceCardInBench(card)
            
        elseif dropTarget.type == "opt_out" then
            -- SUCCESS - Phase 2: Actually remove from source
            self:CompleteCardRemoval(card)
            
            -- Opt-out accepts all
            self:PlaceCardInOptOut(card)
        end
        
    end, "RosterBoard:HandleCardDrop")
end

-- MARK: Mark Card For Removal (Phase 1 - Non-Destructive)
function RosterBoard:MarkCardForRemoval(card)
    local location = card.location
    
    -- Mark card as pending removal (non-destructive)
    card.pendingRemoval = true
    card.originalLocation = location
    card.originalIndex = nil
    card.originalList = nil
    card.originalSlot = nil
    
    if location == "bench" then
        -- Store metadata only - DO NOT remove from array
        for i, benchCard in ipairs(self.benchCards) do
            if benchCard == card then
                card.originalIndex = i
                card.originalList = self.benchCards
                Debug:Dev("organizer_ui", "Marked bench card for removal at index", i)
                break
            end
        end
    elseif location == "opt_out" then
        -- Store opt-out list reference
        if self.optOutSection and self.optOutSection.playerCards then
            for i, optOutCard in ipairs(self.optOutSection.playerCards) do
                if optOutCard == card then
                    card.originalIndex = i
                    card.originalList = self.optOutSection.playerCards
                    Debug:Dev("organizer_ui", "Marked opt-out card for removal at index", i)
                    break
                end
            end
        end
    elseif type(location) == "table" and location.type == "role_slot" then
        -- Store slot reference - DO NOT clear slot.playerCard
        local slot = self.groupSlots[location.groupIndex] and
                     self.groupSlots[location.groupIndex][location.slotIndex]
        
        if slot and slot.playerCard == card then
            card.originalSlot = slot
            Debug:Dev("organizer_ui", "Marked slot card for removal")
        end
    end
end

-- MARK: Complete Card Removal (Phase 2 - Destructive)
function RosterBoard:CompleteCardRemoval(card)
    -- Actually remove from arrays (called ONLY on successful drop)
    
    if card.originalList then
        for i, c in ipairs(card.originalList) do
            if c == card then
                table.remove(card.originalList, i)
                Debug:Dev("organizer_ui", "Completed removal at index", i)
                break
            end
        end
        -- Refresh layout based on original location
        if card.originalLocation == "bench" then
            self:LayoutBench()
        elseif card.originalLocation == "opt_out" then
            self:LayoutOptOut()
        end
    elseif card.originalSlot then
        card.originalSlot.playerCard = nil
        card.originalSlot.isEmpty = true
        
        -- Restore empty label
        if card.originalSlot.emptyLabel then
            card.originalSlot.emptyLabel:Show()
        end
        
        Debug:Dev("organizer_ui", "Completed removal from slot")
    end
    
    -- Clear temporary data
    card.originalIndex = nil
    card.originalList = nil
    card.originalSlot = nil
    card.pendingRemoval = false
end

-- MARK: Place Card in Slot
function RosterBoard:PlaceCardInSlot(card, slot)
    Debug:Dev("organizer_ui", "Placing card in slot:", slot.groupIndex, slot.roleLabel)
    
    -- Hide empty label
    if slot.emptyLabel then
        slot.emptyLabel:Hide()
    end
    
    -- Update card size and position for expanded mode
    card:SetSize(145, 90)  -- Expanded
    card:SetParent(slot)
    card:ClearAllPoints()
    card:SetPoint("CENTER", slot, "CENTER", 0, 0)
    
    -- Update card metadata
    card.location = {
        type = "role_slot",
        groupIndex = slot.groupIndex,
        slotIndex = slot.slotIndex,
        role = slot.role
    }
    
    -- Update card content to expanded mode
    NextKey222.PlayerCard:UpdateCardContent(card, "expanded")
    
    -- Store in slot
    slot.playerCard = card
    slot.isEmpty = false
    
    -- Reset colors
    card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
    card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    
    card:Show()
    
    Debug:Dev("organizer_ui", "Card placed in slot successfully")
end

-- MARK: Place Card in Bench
function RosterBoard:PlaceCardInBench(card)
    Debug:Dev("organizer_ui", "Placing card in bench")
    
    -- Update card size for compact mode
    card:SetSize(180, 20)  -- Compact size
    card:SetParent(self.benchContainer)
    
    -- Update metadata
    card.location = "bench"
    
    -- Update card content to compact mode
    NextKey222.PlayerCard:UpdateCardContent(card, "compact")
    
    -- Add to bench array
    table.insert(self.benchCards, card)
    
    -- Reset colors
    card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
    card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    
    -- Re-layout bench
    self:LayoutBench()
    
    Debug:Dev("organizer_ui", "Card placed in bench successfully")
end

-- MARK: Rejection Animation (NEW - Two-Phase Compatible)
function RosterBoard:AnimateRejection(card)
    Debug:Dev("organizer_ui", "Animating rejection for:", card.playerData.name)
    
    -- Clear pending removal flag (card was never removed from arrays)
    card.pendingRemoval = false
    
    -- Use stored original data
    local originalLocation = card.originalLocation or card.location
    local originalSlot = card.originalSlot
    
    -- Flash red
    card:SetBackdropColor(1.0, 0.2, 0.2, 1.0)
    card:SetBackdropBorderColor(1.0, 1.0, 0.0, 1.0)
    
    local startX, startY = card:GetCenter()
    local targetX, targetY = card.originalX, card.originalY
    
    local duration = 0.3
    local steps = 15
    local stepDelay = duration / steps
    local currentStep = 0
    
    card:SetParent(UIParent)
    card:SetFrameStrata("TOOLTIP")
    
    local function AnimateStep()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        local easedProgress = 1 - (1 - progress) * (1 - progress)
        
        local newX = startX + (targetX - startX) * easedProgress
        local newY = startY + (targetY - startY) * easedProgress
        
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
        
        if currentStep >= steps then
            -- Animation complete - card already in correct list, just refresh layout
            if originalLocation == "bench" or not originalLocation then
                -- Card already in bench array - just refresh layout
                card:SetParent(self.benchContainer)
                card:SetSize(180, 20)  -- Compact size
                card.location = "bench"
                
                -- Refresh layout to show card in correct position
                self:LayoutBench()
                
            elseif originalLocation == "opt_out" then
                -- Card already in opt-out array - just refresh layout
                card:SetParent(self.optOutSection.scrollChild)
                card:SetSize(180, 20)  -- Compact size (same as bench)
                card.location = "opt_out"
                
                -- Refresh layout to show card in correct position
                self:LayoutOptOut()
                
            elseif type(originalLocation) == "table" and originalLocation.type == "role_slot" then
                -- Card already assigned to slot - just ensure it's visible
                if originalSlot then
                    card:SetParent(originalSlot)
                    card:SetSize(145, 90)  -- Expanded size
                    card:ClearAllPoints()
                    card:SetPoint("CENTER", originalSlot, "CENTER")
                    card.location = originalLocation
                    
                    -- Ensure slot metadata is correct
                    originalSlot.isEmpty = false
                    if originalSlot.emptyLabel then
                        originalSlot.emptyLabel:Hide()
                    end
                else
                    -- Fallback to bench
                    card:SetParent(self.benchContainer)
                    card:SetSize(180, 20)
                    card.location = "bench"
                    self:LayoutBench()
                end
            end
            
            -- Clear temporary restoration data
            card.originalIndex = nil
            card.originalList = nil
            card.originalSlot = nil
            card.originalLocation = nil
            
            -- CRITICAL: Restore frame properties using stored originals
            card:SetFrameStrata(card.originalFrameStrata or "MEDIUM")
            card:SetFrameLevel(card.originalFrameLevel or (card:GetParent():GetFrameLevel() + 1))
            card:EnableMouse(true)
            card:SetMovable(true)
            
            -- Reset colors
            card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
            card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
            
            Debug:Dev("organizer_ui", "Rejection animation complete - card restored and clickable")
        else
            C_Timer.After(stepDelay, AnimateStep)
        end
    end
    
    C_Timer.After(stepDelay, AnimateStep)
end

-- MARK: Role Validation
function RosterBoard:CanPlayerFillRole(playerRoles, slotRole)
    if not playerRoles then
        return false
    end
    
    local normalizedSlotRole = slotRole
    if slotRole == "DAMAGER" then
        normalizedSlotRole = "DPS"
    end
    
    for _, role in ipairs(playerRoles) do
        local normalizedPlayerRole = role:upper()
        if normalizedPlayerRole == "DAMAGER" then
            normalizedPlayerRole = "DPS"
        end
        
        if normalizedPlayerRole == normalizedSlotRole or 
           normalizedPlayerRole == slotRole:upper() or
           normalizedPlayerRole == normalizedSlotRole:upper() then
            return true
        end
    end
    
    return false
end

function RosterBoard:FindCompatibleSlotInGroup(card, groupIndex)
    if not self.groupSlots[groupIndex] then
        return nil
    end
    
    for _, slot in ipairs(self.groupSlots[groupIndex]) do
        if slot.isEmpty and self:CanPlayerFillRole(card.playerData.roles, slot.role) then
            return slot
        end
    end
    
    return nil
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

-- MARK: Keystone Designation
function RosterBoard:DesignateGroupKeystone(groupIndex, keystone, playerID)
    return NextKey222.SafeRun(function()
        local groupColumn = self.groupColumns[groupIndex]
        if not groupColumn then
            return
        end
        
        self:ClearPreviousDesignation(groupIndex)
        
        groupColumn.selectedKeystone = keystone
        groupColumn.keystoneOwnerID = playerID
        
        self:BroadcastRosterUpdate({
            action = "KEYSTONE_DESIGNATED",
            groupIndex = groupIndex,
            keystoneOwner = playerID,
            keystone = keystone
        })
        
    end, "RosterBoard:DesignateGroupKeystone")
end

function RosterBoard:ClearPreviousDesignation(groupIndex)
    local groupColumn = self.groupColumns[groupIndex]
    if not groupColumn then
        return
    end
    
    groupColumn.selectedKeystone = nil
    groupColumn.keystoneOwnerID = nil
end

function RosterBoard:UpdateGroupHeader(groupIndex, keystone)
    local groupColumn = self.groupColumns[groupIndex]
    if not groupColumn or not groupColumn.titleLabel then
        return
    end
    
    if keystone then
        local dungeonAbbrev = "???"
        if NextKey222.Utils and NextKey222.Utils.GetDungeonAbbreviation then
            dungeonAbbrev = NextKey222.Utils:GetDungeonAbbreviation(keystone.dungeonID)
        end
        local headerText = dungeonAbbrev .. ": +" .. keystone.level
        groupColumn.titleLabel:SetText(headerText)
    else
        groupColumn.titleLabel:SetText("M+ Grp. " .. groupIndex)
    end
end

-- MARK: Helper Functions
function RosterBoard:FindCardByPlayerID(playerID)
    -- Search bench
    if self.benchCards then
        for _, card in ipairs(self.benchCards) do
            if card.playerData and card.playerData.id == playerID then
                return card
            end
        end
    end
    
    -- Search slots
    if self.groupSlots then
        for _, slots in pairs(self.groupSlots) do
            for _, slot in pairs(slots) do
                if slot.playerCard and slot.playerCard.playerData and 
                   slot.playerCard.playerData.id == playerID then
                    return slot.playerCard
                end
            end
        end
    end
    
    return nil
end

-- MARK: Card Refresh System
--- Refreshes all player cards to reflect updated profile data (e.g., after spec changes)
-- This method updates both bench cards and slot cards with fresh profile information
function RosterBoard:RefreshAllCards()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "RefreshAllCards called - updating all player cards")
        
        -- Refresh bench cards
        if self.benchCards then
            for _, card in ipairs(self.benchCards) do
                if card and card.playerData and card.playerData.id then
                    local playerID = card.playerData.id
                    
                    -- Get fresh BASE profile data (has current spec's role)
                    local profile = NextKey222.ProfilesService and
                                   NextKey222.ProfilesService:GetProfile(playerID)
                    
                    if profile then
                        -- Update card's player data with fresh profile info
                        card.playerData.class = profile.class
                        -- CRITICAL: Use current spec's role from base profile, not multi-role array
                        card.playerData.roles = {profile.role or "DAMAGER"}
                        card.playerData.specName = profile.specName
                        card.playerData.specID = profile.specID
                        card.playerData.overallScore = profile.io or 0
                        
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
                        NextKey222.PlayerCard:UpdateCardContent(card, "compact")
                        
                        Debug:Dev("organizer_ui", "Refreshed bench card for:", playerID, "- role:", profile.role, "spec:", profile.specName)
                    end
                end
            end
        end
        
        -- Refresh slot cards
        if self.groupSlots then
            for groupIndex, slots in pairs(self.groupSlots) do
                for slotIndex, slot in pairs(slots) do
                    if slot.playerCard and slot.playerCard.playerData and slot.playerCard.playerData.id then
                        local card = slot.playerCard
                        local playerID = card.playerData.id
                        
                        -- Get fresh BASE profile data (has current spec's role)
                        local profile = NextKey222.ProfilesService and
                                       NextKey222.ProfilesService:GetProfile(playerID)
                        
                        if profile then
                            -- Update card's player data with fresh profile info
                            card.playerData.class = profile.class
                            -- CRITICAL: Use current spec's role from base profile, not multi-role array
                            card.playerData.roles = {profile.role or "DAMAGER"}
                            card.playerData.specName = profile.specName
                            card.playerData.specID = profile.specID
                            card.playerData.overallScore = profile.io or 0
                            
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
                            NextKey222.PlayerCard:UpdateCardContent(card, "expanded")
                            
                            Debug:Dev("organizer_ui", "Refreshed slot card for:", playerID, "in group", groupIndex, "slot", slotIndex, "- role:", profile.role, "spec:", profile.specName)
                        end
                    end
                end
            end
        end
        
        -- Refresh opt-out cards
        if self.optOutSection and self.optOutSection.playerCards then
            for _, card in ipairs(self.optOutSection.playerCards) do
                if card and card.playerData and card.playerData.id then
                    local playerID = card.playerData.id
                    
                    -- Get fresh BASE profile data (has current spec's role)
                    local profile = NextKey222.ProfilesService and
                                   NextKey222.ProfilesService:GetProfile(playerID)
                    
                    if profile then
                        -- Update card's player data with fresh profile info
                        card.playerData.class = profile.class
                        -- CRITICAL: Use current spec's role from base profile, not multi-role array
                        card.playerData.roles = {profile.role or "DAMAGER"}
                        card.playerData.specName = profile.specName
                        card.playerData.specID = profile.specID
                        card.playerData.overallScore = profile.io or 0
                        
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
                        NextKey222.PlayerCard:UpdateCardContent(card, "opt_out")
                        
                        Debug:Dev("organizer_ui", "Refreshed opt-out card for:", playerID, "- role:", profile.role, "spec:", profile.specName)
                    end
                end
            end
        end
        
        Debug:Dev("organizer_ui", "RefreshAllCards completed successfully")
        
    end, "RosterBoard:RefreshAllCards")
end