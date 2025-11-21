-- MARK: Module Definition
local _, NextKey222 = ...

local BenchManager = {}
NextKey222.BenchManager = BenchManager
NextKey222.RegisterModule("BenchManager", BenchManager)

local Debug = NextKey222.Debug

-- MARK: Initialization
function BenchManager:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "BenchManager module initialized")
        return true
    end, "BenchManager:Initialize")
end

-- MARK: Data Retrieval
--- Get all players for bench (STATE-DRIVEN - Session 3 Refactor)
-- @param rosterBoard RosterBoard instance
-- @return table Array of playerData objects
function BenchManager:get_bench_players(rosterBoard)
    local allPlayers = {}
    local seenPlayers = {}
    
    -- STEP 1: Get bench players from OrganizerModel (SINGLE SOURCE OF TRUTH)
    local benchPlayerIDs = NextKey222.OrganizerModel:GetBench()
    
    Debug:Dev("organizer_ui", "OrganizerState reports", #benchPlayerIDs, "bench players")
    
    -- STEP 2: Fetch full data for each player from state
    for _, playerID in ipairs(benchPlayerIDs) do
        local playerData = NextKey222.OrganizerModel:GetPlayer(playerID)
        
        if playerData then
            table.insert(allPlayers, playerData)
            seenPlayers[playerID] = true
            Debug:Dev("organizer_ui", "Fetched bench player from state:", playerID)
        else
            Debug:Error("Player in bench but no data in state:", playerID)
        end
    end
    
    -- STEP 3: Add NEW players not yet in state (fake + real party)
    -- This handles initial population before poll
    
    -- Add fake players not in state yet
    if NextKey222.FakePlayerService then
        local fakePlayers = NextKey222.FakePlayerService:GetAllPlayers()
        if fakePlayers then
            for _, fakeData in ipairs(fakePlayers) do
                if not seenPlayers[fakeData.name] then
                    -- Check if player exists in state
                    local exists = (NextKey222.OrganizerModel:GetPlayer(fakeData.name) ~= nil)
                    
                    if not exists then
                        -- Player is NEW (not in state at all) - check if should add
                        local location = NextKey222.OrganizerModel:GetAssignment(fakeData.name)
                        
                        if location == "opt_out" then
                            Debug:Dev("organizer_ui", "Skipping opted-out player:", fakeData.name)
                        else
                            -- Add new player to bench
                            local playerData = self:BuildPlayerDataFromFake(fakeData)
                            NextKey222.OrganizerModel:AddPlayer(playerData)
                            NextKey222.OrganizerModel:SetAssignment(fakeData.name, "bench")
                            
                            table.insert(allPlayers, playerData)
                            seenPlayers[fakeData.name] = true
                        end
                    else
                        -- Player exists - don't move them!
                        Debug:Dev("organizer_ui", "Player already in state, not moving:", fakeData.name)
                    end
                end
            end
        end
    end
    
    -- Add real party members not in state yet
    if NextKey222.Addon and NextKey222.Addon.GetPartyMemberNames then
        local partyMembers = NextKey222.Addon:GetPartyMemberNames()
        for _, memberName in ipairs(partyMembers) do
            if not seenPlayers[memberName] then
                -- Check if player exists in state
                local exists = (NextKey222.OrganizerModel:GetPlayer(memberName) ~= nil)
                
                if not exists then
                    -- Player is NEW (not in state at all) - check if should add
                    local location = NextKey222.OrganizerModel:GetAssignment(memberName)
                    
                    if location == "opt_out" then
                        Debug:Dev("organizer_ui", "Skipping opted-out player:", memberName)
                    else
                        -- Add new player to bench
                        local playerData = self:BuildPlayerDataFromParty(memberName)
                        if playerData then
                            NextKey222.OrganizerModel:AddPlayer(playerData)
                            NextKey222.OrganizerModel:SetAssignment(memberName, "bench")
                            
                            table.insert(allPlayers, playerData)
                            seenPlayers[memberName] = true
                        end
                    end
                else
                    -- Player exists - don't move them!
                    Debug:Dev("organizer_ui", "Player already in state, not moving:", memberName)
                end
            end
        end
    end
    
    Debug:Dev("organizer_ui", "Returning", #allPlayers, "bench players (state-driven)")
    return allPlayers
end

-- MARK: Player Data Builders
--- Build player data from fake player service data
-- @param fakeData Fake player service data
-- @return table PlayerData object
function BenchManager:BuildPlayerDataFromFake(fakeData)
    -- CRITICAL: Get profile from ProfilesService for accurate spec/role data
    local profile = NextKey222.ProfilesService and
                   NextKey222.ProfilesService:GetProfile(fakeData.name)
    
    if profile then
        Debug:Dev("organizer", "BuildPlayerDataFromFake: Got profile for", fakeData.name, "role:", profile.role, "specID:", profile.specID)
    else
        Debug:Error("BuildPlayerDataFromFake: NO PROFILE for", fakeData.name)
    end
    
    local playerData = {
        id = fakeData.name,
        name = fakeData.name:match("^([^%-]+)") or fakeData.name,
        class = fakeData.class,
        -- CRITICAL FIX: Use profile role if available, fallback to fakeData
        roles = {(profile and profile.role) or fakeData.role or "DAMAGER"},
        keystone = fakeData.keystone,
        overallScore = fakeData.io or 0,
        specName = (profile and profile.specName) or fakeData.specName,
        specID = profile and profile.specID,
        utilities = {}
    }
    
    -- Add utilities
    if fakeData.heroismCaster then
        table.insert(playerData.utilities, "heroism")
    end
    if fakeData.battleResCaster then
        table.insert(playerData.utilities, "battleRes")
    end
    
    -- CRITICAL FIX: ALWAYS generate spec preferences for sorting to work
    if NextKey222.OrganizerPlayerDataBuilder then
        Debug:Dev("organizer", "BuildPlayerDataFromFake: Calling GenerateSpecPreferences for", fakeData.name)
        local success, specPrefs, specDetails =
            NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(fakeData.name, {randomize = false})
        if success and specPrefs then
            playerData.specPreferences = specPrefs
            playerData.specDetails = specDetails
            Debug:Dev("organizer", "BuildPlayerDataFromFake: Generated specPreferences for", fakeData.name,
                     "- TANK:", specPrefs.TANK or "none",
                     "HEALER:", specPrefs.HEALER or "none",
                     "DAMAGER:", specPrefs.DAMAGER or "none")
        else
            Debug:Error("BuildPlayerDataFromFake: Failed to generate specPreferences for", fakeData.name)
        end
    else
        Debug:Error("BuildPlayerDataFromFake: OrganizerPlayerDataBuilder NOT AVAILABLE")
    end
    
    Debug:Dev("organizer", "BuildPlayerDataFromFake: Returning playerData for", fakeData.name,
             "with roles:", playerData.roles and table.concat(playerData.roles, ",") or "NONE",
             "hasSpecPrefs:", playerData.specPreferences ~= nil)
    
    return playerData
end

--- Build player data from party member profile
-- @param memberName Player name-realm
-- @return table|nil PlayerData object or nil if profile unavailable
function BenchManager:BuildPlayerDataFromParty(memberName)
    local profile = NextKey222.ProfilesService and
                   NextKey222.ProfilesService:GetProfile(memberName)
    
    if not profile then
        return nil
    end
    
    local playerData = {
        id = memberName,
        name = memberName:match("^([^%-]+)") or memberName,
        class = profile.class,
        roles = {profile.role or "DAMAGER"},
        keystone = nil,
        overallScore = profile.io or 0,
        specName = profile.specName,
        specID = profile.specID,
        utilities = {}
    }
    
    -- Get keystone
    local orgProfile = NextKey222.ProfilesService and
                      NextKey222.ProfilesService:GetOrganizerProfile(memberName)
    if orgProfile and orgProfile.keystone then
        playerData.keystone = orgProfile.keystone
    end
    
    -- Add utilities
    if profile.capabilities then
        if profile.capabilities.heroism then
            table.insert(playerData.utilities, "heroism")
        end
        if profile.capabilities.battleRes then
            table.insert(playerData.utilities, "battleRes")
        end
    end
    
    -- Generate default spec preferences
    if NextKey222.OrganizerPlayerDataBuilder then
        local success, specPrefs, specDetails =
            NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(memberName, {randomize = false})
        if success and specPrefs then
            playerData.specPreferences = specPrefs
            playerData.specDetails = specDetails
        end
    end
    
    return playerData
end

-- MARK: Single Operations
--- Add a single player to the bench
-- @param rosterBoard RosterBoard instance
-- @param playerData Player data object
function BenchManager:add_player_to_bench(rosterBoard, playerData)
    return NextKey222.SafeRun(function()
        if not rosterBoard.benchContainer then
            Debug:Error("Bench container not initialized")
            return
        end
        
        -- NEW: Create card using CardView
        local playerID = playerData.id
        local card = NextKey222.CardView:Create(playerID, rosterBoard.benchContainer, "bench")
        
        if card then
            NextKey222.CardView:Update(card)
            table.insert(rosterBoard.benchCards, card)
            
            -- Add visual indicator if auto-detected
            if playerData.dataSource == "auto-detected" then
                self:add_auto_detected_indicator(card)
            end
            
            -- Re-layout bench
            self:layout_bench(rosterBoard)
            
            -- Check if window needs to resize for more groups
            self:check_and_resize_window(rosterBoard)
            
            Debug:Dev("organizer", "Added player to bench:", playerData.name)
        else
            Debug:Error("Failed to create card for:", playerData.name)
        end
        
    end, "BenchManager:add_player_to_bench")
end

--- Remove a player from the bench by ID
-- @param rosterBoard RosterBoard instance
-- @param playerID Player identifier
function BenchManager:remove_player_from_bench(rosterBoard, playerID)
    return NextKey222.SafeRun(function()
        if not rosterBoard.benchCards then
            return
        end
        
        -- Find and remove the player card
        for i = #rosterBoard.benchCards, 1, -1 do
            local card = rosterBoard.benchCards[i]
            if card.playerID and card.playerID == playerID then
                -- Hide and remove card
                card:Hide()
                card:SetParent(nil)
                table.remove(rosterBoard.benchCards, i)
                
                Debug:Dev("organizer", "Removed player from bench:", playerID)
                
                -- Re-layout bench
                self:layout_bench(rosterBoard)
                return true
            end
        end
        
        Debug:Dev("organizer", "Player not found in bench:", playerID)
        return false
        
    end, "BenchManager:remove_player_from_bench")
end

-- MARK: Batch Operations
--- Populate bench with multiple players
-- @param rosterBoard RosterBoard instance
-- @param players Array of playerData objects
function BenchManager:populate_bench(rosterBoard, players)
    if not rosterBoard.benchContainer then
        Debug:Error("Bench container not initialized")
        return
    end
    
    -- Clear existing cards
    for _, card in ipairs(rosterBoard.benchCards) do
        if card then
            card:Hide()
            card:SetParent(nil)
        end
    end
    rosterBoard.benchCards = {}
    
    Debug:Dev("organizer_ui", "Populating bench with", #players, "players")
    
    -- NEW: Create cards using CardView
    for i, playerData in ipairs(players) do
        local playerID = playerData.id
        local card = NextKey222.CardView:Create(playerID, rosterBoard.benchContainer, "bench")
        
        if card then
            NextKey222.CardView:Update(card)
            table.insert(rosterBoard.benchCards, card)
            Debug:Dev("organizer_ui", "Created bench card", i, "for:", playerData.name)
        else
            Debug:Error("Failed to create CardView for:", playerData.name)
        end
    end
    
    -- Layout bench
    self:layout_bench(rosterBoard)
    
    Debug:Dev("organizer_ui", "Bench populated with", #rosterBoard.benchCards, "cards")
end

-- MARK: Layout Management
--- Layout bench cards vertically
-- @param rosterBoard RosterBoard instance
function BenchManager:layout_bench(rosterBoard)
    if not rosterBoard.benchContainer or not rosterBoard.benchCards then
        return
    end
    
    local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
    local spacing = config.BENCH_CARD_SPACING or 3
    local cardHeight = config.BENCH_CARD_HEIGHT or 20
    local horizontalPadding = config.BENCH_HORIZONTAL_PADDING or 10
    local scrollbarPadding = config.BENCH_SCROLLBAR_PADDING or 18
    local cardWidth = rosterBoard.benchCardWidth or ((config.BENCH_WIDTH or 260) - (horizontalPadding * 2) - scrollbarPadding)
    local innerPadding = rosterBoard.benchContainerPadding or (config.BENCH_SCROLL_GAP or 8)
    local yOffset = innerPadding
    
    Debug:Dev("organizer_ui", "Laying out", #rosterBoard.benchCards, "bench cards")
    
    for i, card in ipairs(rosterBoard.benchCards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", rosterBoard.benchContainer, "TOPLEFT", 0, -yOffset)
        card:SetSize(cardWidth, cardHeight)
        card:SetParent(rosterBoard.benchContainer)
        card:Show()
        yOffset = yOffset + cardHeight + spacing
    end
    
    local totalCards = #rosterBoard.benchCards
    local totalHeight
    if totalCards > 0 then
        totalHeight = innerPadding + (totalCards * cardHeight) + ((totalCards - 1) * spacing) + innerPadding
    else
        totalHeight = innerPadding * 2
    end

    rosterBoard.benchContainer:SetHeight(math.max(totalHeight, 1))
    rosterBoard.benchContainer:SetWidth(cardWidth)
    
    Debug:Dev("organizer_ui", "Bench layout complete")
end

-- MARK: UI Creation
--- Create native bench column with scroll frame and inline controls
-- @param rosterBoard RosterBoard instance
-- @param width Column width
-- @param parentFrame Parent frame
-- @return frame Bench column frame
function BenchManager:create_native_bench_column(rosterBoard, width, parentFrame)
    return NextKey222.SafeRun(function()
        local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
        local groupHeight = config.GROUP_HEIGHT or 550
        local innerPadding = config.BENCH_SCROLL_GAP or 8
        local titleHeight = config.BENCH_TITLE_HEIGHT or 20
        local horizontalPadding = config.BENCH_HORIZONTAL_PADDING or 10
        local scrollbarPadding = config.BENCH_SCROLLBAR_PADDING or 18

        -- Create pure native bench frame
        local bench = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        bench:SetSize(width, groupHeight)
        bench:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        bench:Show()
        
        -- PHASE 2 FIX: Simplified title bar with Recall All button
        -- Create title bar container
        local titleBar = CreateFrame("Frame", nil, bench)
        titleBar:SetPoint("TOPLEFT", horizontalPadding, -horizontalPadding)
        titleBar:SetPoint("TOPRIGHT", -horizontalPadding, -horizontalPadding)
        titleBar:SetHeight(titleHeight)
        titleBar:Show()
        
        -- Title label (vertically centered - anchor to parent center, not edge)
        local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleLabel:SetPoint("LEFT", titleBar, "LEFT", 0, 0)
        titleLabel:SetJustifyV("MIDDLE")  -- Explicitly set vertical justification
        titleLabel:SetText("BENCH")
        
        -- Recall All button (vertically centered)
        local recallButton = CreateFrame("Button", nil, titleBar, "UIPanelButtonTemplate")
        recallButton:SetSize(60, 16)
        recallButton:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)  -- RIGHT anchor for vertical centering
        recallButton:SetText("Recall All")
        recallButton:SetNormalFontObject("GameFontNormalSmall")
        recallButton:SetEnabled(false)  -- Start disabled
        recallButton:SetScript("OnClick", function()
            self:recall_all_cards(rosterBoard)
        end)
        recallButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Recall All Players", 1, 1, 1)
            GameTooltip:AddLine("Move all players from M+ groups back to the bench", nil, nil, nil, true)
            GameTooltip:Show()
        end)
        recallButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Store reference for enable/disable control
        bench.recallButton = recallButton
        rosterBoard.benchRecallButton = recallButton
        
        -- PHASE 2 FIX: Anchor scroll frame to title bar bottom (not hardcoded offset)
        local scrollFrame = CreateFrame("ScrollFrame", nil, bench, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -innerPadding)
        scrollFrame:SetPoint("BOTTOMRIGHT", bench, "BOTTOMRIGHT", -(horizontalPadding + scrollbarPadding), horizontalPadding)
        scrollFrame:Show()
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(width - (horizontalPadding * 2) - scrollbarPadding, 1)
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:Show()
        
        -- Store references
        bench.scrollFrame = scrollFrame
        bench.scrollChild = scrollChild
        bench.frame = bench  -- For compatibility
        rosterBoard.benchContainer = scrollChild
        rosterBoard.benchScrollFrame = scrollFrame
        rosterBoard.benchCards = {}
        rosterBoard.benchCardWidth = width - (horizontalPadding * 2) - scrollbarPadding
        rosterBoard.benchContainerPadding = innerPadding
        
        Debug:Dev("organizer_ui", "Created FULLY NATIVE bench column with inline controls")
        
        return bench
    end, "BenchManager:create_native_bench_column")
end

-- MARK: Utilities
--- Add visual indicator for auto-detected players
-- @param playerCard Player card frame
function BenchManager:add_auto_detected_indicator(playerCard)
    -- Add small icon overlay to card indicating no addon
    -- For now, just log it - can add visual indicator later
    Debug:Dev("organizer", "Player auto-detected (no addon):", playerCard.playerData.name)
end

--- Check if window needs resize for more groups
-- @param rosterBoard RosterBoard instance
function BenchManager:check_and_resize_window(rosterBoard)
    if not rosterBoard.mainFrame then
        return
    end
    
    -- Calculate what the layout should be
    local newLayout = rosterBoard:CalculateOptimalLayout()
    
    -- Get current number of groups
    local currentGroupCount = #rosterBoard.groupSlots or 0
    
    -- If we need more groups, rebuild the entire window
    if newLayout.groupColumns > currentGroupCount then
        Debug:Dev("organizer_ui", "Player count increased - need more groups. Rebuilding window...")
        
        -- Store visibility state
        local wasVisible = rosterBoard.mainFrame:IsVisible()
        
        -- Close and recreate
        rosterBoard:OnMainFrameClosed(rosterBoard.mainFrame)
        
        if wasVisible then
            rosterBoard:CreateMainFrame()
        end
    end
end

-- MARK: Button State
--- Update the enabled/disabled state of the Recall All button
-- @param rosterBoard RosterBoard instance
function BenchManager:update_recall_button_state(rosterBoard)
    if not rosterBoard.benchRecallButton then return end
    
    local hasSlottedCards = false
    
    if rosterBoard.groupSlots then
        for _, slots in pairs(rosterBoard.groupSlots) do
            for _, slot in pairs(slots) do
                if not slot.isEmpty then
                    hasSlottedCards = true
                    break
                end
            end
            if hasSlottedCards then break end
        end
    end
    
    rosterBoard.benchRecallButton:SetEnabled(hasSlottedCards)
    Debug:Dev("organizer_ui", "Recall button state:", hasSlottedCards and "ENABLED" or "DISABLED")
end

-- MARK: Recall All
--- Recalls all player cards from M+ group slots back to the bench with animation (EVENT-DRIVEN)
-- @param rosterBoard RosterBoard instance
function BenchManager:recall_all_cards(rosterBoard)
    return NextKey222.SafeRun(function()
        if not rosterBoard.groupSlots then return end
        
        -- Disable button during animation
        if rosterBoard.benchRecallButton then
            rosterBoard.benchRecallButton:SetEnabled(false)
        end
        
        -- Collect cards by group AND their player IDs
        local cardsByGroup = {}
        local playerIDs = {}
        local totalCards = 0
        
        for groupIndex, slots in pairs(rosterBoard.groupSlots) do
            cardsByGroup[groupIndex] = {}
            
            for slotIndex, slot in pairs(slots) do
                if not slot.isEmpty and slot.playerCard then
                    local card = slot.playerCard
                    -- CRITICAL FIX: CardView stores playerID directly, not playerData
                    local playerID = card.playerID
                    
                    table.insert(cardsByGroup[groupIndex], card)
                    table.insert(playerIDs, playerID)
                    totalCards = totalCards + 1
                    
                    -- Clear keystone if designated
                    if NextKey222.KeystoneManager:is_keystone_designated(
                        rosterBoard, groupIndex, playerID) then
                        NextKey222.KeystoneManager:clear_group_keystone(
                            rosterBoard, groupIndex)
                        Debug:Dev("organizer", "Cleared keystone for:", playerID)
                    end
                end
            end
        end
        
        if totalCards == 0 then
            Debug:User("No cards to recall")
            if rosterBoard.benchRecallButton then
                rosterBoard.benchRecallButton:SetEnabled(false)
            end
            return
        end
        
        Debug:User("Recalling " .. totalCards .. " players to bench...")
        
        -- Execute animated recall sequence
        -- CRITICAL: Animation completes, THEN we update state, THEN rebuild
        NextKey222.AnimationQueue:ExecuteRecallSequence(cardsByGroup, function()
            -- FINAL STEP (same as manual drag): Update state, event rebuilds UI
            Debug:Dev("organizer", "Animation complete - updating state for", #playerIDs, "players")
            for _, playerID in ipairs(playerIDs) do
                NextKey222.OrganizerModel:SetAssignment(playerID, "bench")
            end
            -- ORGANIZER_PLAYER_MOVED events will fire and rebuild UI automatically
            
            -- Re-enable button after rebuild
            if rosterBoard.benchRecallButton then
                C_Timer.After(0.1, function()
                    self:update_recall_button_state(rosterBoard)
                end)
            end
            
            Debug:User("Recall complete!")
        end)
        
    end, "BenchManager:recall_all_cards")
end

-- MARK: Rebuild (Legacy)
-- DEPRECATED: Will be removed in Week 3
--- Rebuild bench after poll completion (LEGACY)
-- @param rosterBoard RosterBoard instance
function BenchManager:rebuild_bench_after_poll(rosterBoard)
    return NextKey222.SafeRun(function()
        if not rosterBoard.benchContainer then
            Debug:Error("Cannot rebuild bench - container not initialized")
            return
        end
        
        Debug:Dev("organizer_ui", "RebuildBenchAfterPoll - clearing all existing bench cards")
        
        -- Clear ALL existing bench cards completely
        for _, card in ipairs(rosterBoard.benchCards) do
            if card then
                card:Hide()
                card:SetParent(nil)
                card:ClearAllPoints()
            end
        end
        rosterBoard.benchCards = {}
        
        -- Get fresh player list (will preserve poll response data from existing cards)
        local benchPlayers = self:get_bench_players(rosterBoard)
        
        Debug:Dev("organizer_ui", "Creating fresh cards for", #benchPlayers, "bench players")
        
        -- NEW: Create brand new cards using CardView
        for i, playerData in ipairs(benchPlayers) do
            local playerID = playerData.id
            local card = NextKey222.CardView:Create(playerID, rosterBoard.benchContainer, "bench")
            
            if card then
                NextKey222.CardView:Update(card)
                table.insert(rosterBoard.benchCards, card)
                Debug:Dev("organizer_ui", "Recreated bench card", i, "for:", playerData.name,
                         "- has specPreferences:", playerData.specPreferences ~= nil)
            else
                Debug:Error("Failed to recreate CardView for:", playerData.name)
            end
        end
        
        -- Re-layout bench
        self:layout_bench(rosterBoard)
        
        Debug:Dev("organizer_ui", "Bench rebuild complete -", #rosterBoard.benchCards, "cards created")
        
    end, "BenchManager:rebuild_bench_after_poll")
end
