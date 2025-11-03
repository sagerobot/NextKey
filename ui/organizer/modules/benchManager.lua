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
--- Get all players for bench (fake + real party members)
-- @param rosterBoard RosterBoard instance
-- @return table Array of playerData objects
function BenchManager:get_bench_players(rosterBoard)
    local allPlayers = {}
    local seenPlayers = {}  -- Track which players we've already added
    
    -- STEP 1: Preserve existing bench cards with poll response data (CRITICAL FIX)
    -- This prevents poll responses (specPreferences, surveyResponse) from being lost
    if rosterBoard.benchCards then
        Debug:Dev("organizer_ui", "Preserving", #rosterBoard.benchCards, "existing bench cards with poll data")
        for _, card in ipairs(rosterBoard.benchCards) do
            if card.playerData then
                table.insert(allPlayers, card.playerData)  -- Reuse existing data
                seenPlayers[card.playerData.id] = true  -- CRITICAL: Mark as seen to prevent duplicate processing
                Debug:Dev("organizer_ui", "Preserved player data for:", card.playerData.id,
                         "- has specPreferences:", card.playerData.specPreferences ~= nil,
                         "- has specDetails:", card.playerData.specDetails ~= nil)
            end
        end
    end
    
    -- STEP 2: Add NEW fake players not already in bench
    if NextKey222.FakePlayerService then
        local fakePlayers = NextKey222.FakePlayerService:GetAllPlayers()
        if fakePlayers then
            Debug:Dev("organizer_ui", "Found", #fakePlayers, "fake players")
            for _, fakeData in ipairs(fakePlayers) do
                -- Skip if already preserved from bench
                if seenPlayers[fakeData.name] then
                    Debug:Dev("organizer_ui", "Skipping", fakeData.name, "- already preserved from bench")
                else
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
                    
                    -- CRITICAL FIX: Only generate defaults if player doesn't already have spec preferences
                    -- (preserves poll response data if it exists)
                    if not playerData.specPreferences or not next(playerData.specPreferences) then
                    	if NextKey222.OrganizerPlayerDataBuilder and
                    	   NextKey222.OrganizerPlayerDataBuilder.GenerateDefaultSpecPreferences then
                    		-- SafeRun returns the function's direct outputs: (specPreferences, specDetails)
                    		local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(fakeData.name)
                    		
                    		if success and specPrefs then
                    			playerData.specPreferences = specPrefs
                    			playerData.specDetails = specDetails
                    			
                    			Debug:Dev("organizer_ui", "Generated default spec preferences for fake player:", fakeData.name,
                    			         "- has specPreferences:", specPrefs ~= nil,
                    			         "- has specDetails:", specDetails ~= nil)
                    		else
                    			Debug:Error("Failed to generate default spec preferences for fake player:", fakeData.name)
                    		end
                    	end
                    else
                    	Debug:Dev("organizer_ui", "Player", fakeData.name, "already has spec preferences - preserving")
                    end
                    
                    table.insert(allPlayers, playerData)
                    seenPlayers[fakeData.name] = true  -- Mark as seen
                end
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
                    
                    -- CRITICAL FIX: Only generate defaults if player doesn't already have spec preferences
                    -- (preserves poll response data if it exists)
                    if not playerData.specPreferences or not next(playerData.specPreferences) then
                    	if NextKey222.OrganizerPlayerDataBuilder and
                    	   NextKey222.OrganizerPlayerDataBuilder.GenerateDefaultSpecPreferences then
                    		-- SafeRun returns the function's direct outputs: (specPreferences, specDetails)
                    		local success, specPrefs, specDetails = NextKey222.OrganizerPlayerDataBuilder:GenerateDefaultSpecPreferences(memberName)
                    		
                    		if success and specPrefs then
                    			playerData.specPreferences = specPrefs
                    			playerData.specDetails = specDetails
                    			
                    			Debug:Dev("organizer_ui", "Generated default spec preferences for real player:", memberName,
                    			         "- has specPreferences:", specPrefs ~= nil,
                    			         "- has specDetails:", specDetails ~= nil)
                    		else
                    			Debug:Error("Failed to generate default spec preferences for real player:", memberName)
                    		end
                    	end
                    else
                    	Debug:Dev("organizer_ui", "Player", memberName, "already has spec preferences - preserving")
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
    
    local yOffset = 0
    local spacing = 3
    
    Debug:Dev("organizer_ui", "Laying out", #rosterBoard.benchCards, "bench cards")
    
    for i, card in ipairs(rosterBoard.benchCards) do
        card:ClearAllPoints()
        card:SetPoint("TOP", rosterBoard.benchContainer, "TOP", 0, -yOffset)
        card:SetSize(180, 20)  -- Compact: 180px wide, 20px tall
        card:SetParent(rosterBoard.benchContainer)  -- Ensure correct parent
        card:Show()
        yOffset = yOffset + 20 + spacing
    end
    
    -- Update scroll child height
    rosterBoard.benchContainer:SetHeight(math.max(yOffset, 1))
    
    Debug:Dev("organizer_ui", "Bench layout complete")
end

-- MARK: UI Creation
--- Create native bench column with scroll frame
-- @param rosterBoard RosterBoard instance
-- @param width Column width
-- @param parentFrame Parent frame
-- @return frame Bench column frame
function BenchManager:create_native_bench_column(rosterBoard, width, parentFrame)
    return NextKey222.SafeRun(function()
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
        rosterBoard.benchContainer = scrollChild
        rosterBoard.benchScrollFrame = scrollFrame
        rosterBoard.benchCards = {}
        
        Debug:Dev("organizer_ui", "Created FULLY NATIVE bench column")
        
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