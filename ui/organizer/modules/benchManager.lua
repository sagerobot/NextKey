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
    
    -- STEP 1: Get bench players from OrganizerState (SINGLE SOURCE OF TRUTH)
    local benchPlayerIDs = NextKey222.OrganizerState:GetBenchPlayers()
    
    Debug:Dev("organizer_ui", "OrganizerState reports", #benchPlayerIDs, "bench players")
    
    -- STEP 2: Fetch full data for each player from state
    for _, playerID in ipairs(benchPlayerIDs) do
        local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
        
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
                    -- SESSION 4 FIX: Check if player has opted out before adding to bench
                    local location = NextKey222.OrganizerState:GetPlayerLocation(fakeData.name)
                    
                    if location ~= "opt_out" then
                        -- Build playerData and add to state
                        local playerData = self:BuildPlayerDataFromFake(fakeData)
                        NextKey222.OrganizerState:SetPlayer(fakeData.name, playerData)
                        NextKey222.OrganizerState:MoveToBench(fakeData.name)
                        
                        table.insert(allPlayers, playerData)
                        seenPlayers[fakeData.name] = true
                    else
                        Debug:Dev("organizer_ui", "Skipping opted-out player:", fakeData.name)
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
                -- SESSION 4 FIX: Check if player has opted out before adding to bench
                local location = NextKey222.OrganizerState:GetPlayerLocation(memberName)
                
                if location ~= "opt_out" then
                    -- Build playerData and add to state
                    local playerData = self:BuildPlayerDataFromParty(memberName)
                    if playerData then
                        NextKey222.OrganizerState:SetPlayer(memberName, playerData)
                        NextKey222.OrganizerState:MoveToBench(memberName)
                        
                        table.insert(allPlayers, playerData)
                        seenPlayers[memberName] = true
                    end
                else
                    Debug:Dev("organizer_ui", "Skipping opted-out player:", memberName)
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
    local playerData = {
        id = fakeData.name,
        name = fakeData.name:match("^([^%-]+)") or fakeData.name,
        class = fakeData.class,
        roles = {fakeData.role or "DAMAGER"},
        keystone = fakeData.keystone,
        overallScore = fakeData.io or 0,
        specName = fakeData.specName,
        utilities = {}
    }
    
    -- Add utilities
    if fakeData.heroismCaster then
        table.insert(playerData.utilities, "heroism")
    end
    if fakeData.battleResCaster then
        table.insert(playerData.utilities, "battleRes")
    end
    
    -- Generate default spec preferences if none exist
    if NextKey222.OrganizerPlayerDataBuilder then
        local success, specPrefs, specDetails =
            NextKey222.OrganizerPlayerDataBuilder:GenerateSpecPreferences(fakeData.name, {randomize = false})
        if success and specPrefs then
            playerData.specPreferences = specPrefs
            playerData.specDetails = specDetails
        end
    end
    
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

-- MARK: Individual Operations
--- Add a single player to the bench
-- @param rosterBoard RosterBoard instance
-- @param playerData Player data object
function BenchManager:add_player_to_bench(rosterBoard, playerData)
    return NextKey222.SafeRun(function()
        if not rosterBoard.benchContainer then
            Debug:Error("Bench container not initialized")
            return
        end
        
        -- Create native card
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            rosterBoard.benchContainer,
            "bench",
            "compact"
        )
        
        if card then
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
            if card.playerData and card.playerData.id == playerID then
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
    
    -- Create native cards
    for i, playerData in ipairs(players) do
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            rosterBoard.benchContainer,
            "bench",
            "compact"
        )
        
        if card then
            table.insert(rosterBoard.benchCards, card)
            Debug:Dev("organizer_ui", "Created bench card", i, "for:", playerData.name)
        else
            Debug:Error("Failed to create card for:", playerData.name)
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
    local cardWidth = rosterBoard.benchCardWidth or ((config.BENCH_WIDTH or 220) - 24)
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
        local scrollbarPadding = 18

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
        
        -- PHASE 2 FIX: Simplified title bar (NO inline buttons - eliminates empty space)
        -- Create title bar container
        local titleBar = CreateFrame("Frame", nil, bench)
        titleBar:SetPoint("TOPLEFT", 10, -10)
        titleBar:SetPoint("TOPRIGHT", -10, -10)
        titleBar:SetHeight(titleHeight)
        titleBar:Show()
        
        -- Title label (centered for clean look)
        local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleLabel:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
        titleLabel:SetText("BENCH")
        
        -- PHASE 2 FIX: Anchor scroll frame to title bar bottom (not hardcoded offset)
        local scrollFrame = CreateFrame("ScrollFrame", nil, bench, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -innerPadding)
        scrollFrame:SetPoint("BOTTOMRIGHT", bench, "BOTTOMRIGHT", -(innerPadding + scrollbarPadding), innerPadding)
        scrollFrame:Show()
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(width - (innerPadding * 2) - scrollbarPadding, 1)
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:Show()
        
        -- Store references
        bench.scrollFrame = scrollFrame
        bench.scrollChild = scrollChild
        bench.frame = bench  -- For compatibility
        rosterBoard.benchContainer = scrollChild
        rosterBoard.benchScrollFrame = scrollFrame
        rosterBoard.benchCards = {}
        rosterBoard.benchCardWidth = width - (innerPadding * 2) - scrollbarPadding
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

-- MARK: Rebuild (DEPRECATED - Will be removed in Week 3)
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
        
        -- Create brand new cards with updated data
        for i, playerData in ipairs(benchPlayers) do
            local card = NextKey222.PlayerCard:CreateNativeCard(
                playerData,
                rosterBoard.benchContainer,
                "bench",
                "compact"
            )
            
            if card then
                table.insert(rosterBoard.benchCards, card)
                Debug:Dev("organizer_ui", "Recreated bench card", i, "for:", playerData.name,
                         "- has specPreferences:", playerData.specPreferences ~= nil)
            else
                Debug:Error("Failed to recreate card for:", playerData.name)
            end
        end
        
        -- Re-layout bench
        self:layout_bench(rosterBoard)
        
        Debug:Dev("organizer_ui", "Bench rebuild complete -", #rosterBoard.benchCards, "cards created")
        
    end, "BenchManager:rebuild_bench_after_poll")
end
