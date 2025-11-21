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
        -- Event-Driven Architecture - Register listeners for OrganizerModel events
        if NextKey222.OrganizerModel then
            NextKey222.OrganizerModel:RegisterCallback(function(event, payload)
                self:OnModelUpdate(event, payload)
            end)
            Debug:Dev("organizer_events", "Registered OrganizerModel callback")
        end

        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            -- Register listener for poll response received events
            NextKey222.Addon:RegisterMessage("ORGANIZER_POLL_RESPONSE_RECEIVED", function(event, payload)
                self:OnPollResponseReceived(payload)
            end)
            
            -- Register listener for profile updates (spec changes, role changes)
            NextKey222.Addon:RegisterMessage("NEXTKEY_PROFILE_UPDATED", function(event, payload)
                self:OnProfileUpdated(payload)
            end)
            
            Debug:Dev("organizer_events", "Registered event listeners")
        else
            Debug:Error("Cannot register event listeners - AceEvent system not available")
        end
        
        Debug:Dev("organizer_ui", "Roster Board initialized successfully")
        return true
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "SyncBenchAndOptOutOnly - rebuilding bench and opt-out only")
        
            local child = select(i, UIParent:GetChildren())
            -- FIXED: Only destroy cards that are DIRECTLY parented to UIParent
            -- Cards in slots/bench/opt-out have benchContainer or scrollChild as parent
            if child and child.playerData and child.playerID then
                local parent = child:GetParent()
                if parent == UIParent then
                    -- This is a truly orphaned card floating in UIParent - mark for cleanup
                    table.insert(orphanedCards, child)
                    Debug:Dev("organizer_ui", "Found orphaned card (direct UIParent child):", child.playerID)
                end
            end
        end
        
        -- Destroy orphaned cards
        for _, card in ipairs(orphanedCards) do
            Debug:Dev("organizer_ui", "Destroying orphaned card:", card.playerID)
            card:Hide()
            card:SetParent(nil)
            card:ClearAllPoints()
        end
        
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
        
        -- NEW: Rebuild bench from state using CardView
        for _, playerID in ipairs(benchPlayerIDs) do
            local card = NextKey222.CardView:Create(playerID, self.benchContainer, "bench")
            if card then
                NextKey222.CardView:Update(card)
                table.insert(self.benchCards, card)
            end
        end
        
        -- NEW: Rebuild opt-out from state using CardView
        for _, playerID in ipairs(optOutPlayerIDs) do
            local card = NextKey222.CardView:Create(playerID, self.optOutSection.scrollChild, "opt_out")
            if card then
                NextKey222.CardView:Update(card)
                table.insert(self.optOutSection.playerCards, card)
            end
        end
        
        -- Re-layout sections
        self:LayoutBench()
        self:LayoutOptOut()
        
        Debug:Dev("organizer_ui", "Synced bench and opt-out only -", #self.benchCards, "bench,",
                 #self.optOutSection.playerCards, "opt-out")
        
    end, "RosterBoard:SyncBenchAndOptOutOnly")
end

-- MARK: Event Handlers
-- Old event handlers (OnPlayerAdded, OnPlayerMoved) removed.
-- All updates are now handled by OnModelUpdate.

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

-- MARK: Drag State Reset
-- Reset visual drag state on a card
function RosterBoard:ResetDragState(card)
    if not card then return end
    
    -- Reset drag flag
    card.isDragging = false
    
    -- Reset backdrop colors to normal (class color background, dark border)
    if card.classColor then
        card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    end
    
    -- Reset frame strata if it was stored
    if card.originalFrameStrata then
        card:SetFrameStrata(card.originalFrameStrata)
        card.originalFrameStrata = nil
    end
    
    -- Reset frame level if it was stored
    if card.originalFrameLevel and card:GetParent() then
        card:SetFrameLevel(card.originalFrameLevel)
        card.originalFrameLevel = nil
    end
    
    Debug:Dev("organizer_ui", "Reset drag state for card:", card.playerID)
end

-- MARK: Surgical Card Movement
-- Move a single card without rebuilding all cards
function RosterBoard:MoveSingleCard(playerID, fromLocation, toLocation)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "MoveSingleCard:", playerID, "from:", fromLocation, "to:", toLocation)
        
        -- Check if source and destination are the same (dropped back in same location)
        local fromLoc = type(fromLocation) == "table" and fromLocation.type or fromLocation
        local toLoc = type(toLocation) == "table" and toLocation.type or toLocation
        
        local isSameLocation = false
        if type(fromLocation) == "table" and type(toLocation) == "table" then
            -- Both are role slots - check if same slot
            isSameLocation = (fromLocation.type == toLocation.type and
                            fromLocation.groupIndex == toLocation.groupIndex and
                            fromLocation.slotIndex == toLocation.slotIndex)
        else
            -- Simple string comparison for bench/opt_out
            isSameLocation = (fromLoc == toLoc)
        end
        
        if isSameLocation then
            Debug:Dev("organizer_ui", "Same location drop - just resetting drag state")
            -- Find the card without removing it
            local card = nil
            if fromLoc == "bench" then
                for _, benchCard in ipairs(self.benchCards) do
                    if benchCard.playerID == playerID then
                        card = benchCard
                        break
                    end
                end
            elseif fromLoc == "opt_out" then
                if self.optOutSection and self.optOutSection.playerCards then
                    for _, optCard in ipairs(self.optOutSection.playerCards) do
                        if optCard.playerID == playerID then
                            card = optCard
                            break
                        end
                    end
                end
            elseif fromLoc == "role_slot" then
                local slot = self.groupSlots[fromLocation.groupIndex] and
                            self.groupSlots[fromLocation.groupIndex][fromLocation.slotIndex]
                if slot and slot.playerCard and slot.playerCard.playerID == playerID then
                    card = slot.playerCard
                end
            end
            
            if card then
                self:ResetDragState(card)
                -- Re-layout to fix positioning after drag
                if fromLoc == "bench" then
                    NextKey222.BenchManager:layout_bench(self)
                elseif fromLoc == "opt_out" then
                    NextKey222.SlotManager:layout_opt_out(self)
                end
            end
            return
        end
        
        -- Different location - find and remove card from source
        local card = nil
        
        if fromLoc == "bench" then
            for i, benchCard in ipairs(self.benchCards) do
                if benchCard.playerID == playerID then
                    card = benchCard
                    table.remove(self.benchCards, i)
                    Debug:Dev("organizer_ui", "Found card in bench at index", i)
                    break
                end
            end
        elseif fromLoc == "opt_out" then
            if self.optOutSection and self.optOutSection.playerCards then
                for i, optCard in ipairs(self.optOutSection.playerCards) do
                    if optCard.playerID == playerID then
                        card = optCard
                        table.remove(self.optOutSection.playerCards, i)
                        Debug:Dev("organizer_ui", "Found card in opt-out at index", i)
                        break
                    end
                end
            end
        elseif fromLoc == "role_slot" then
            local slot = self.groupSlots[fromLocation.groupIndex] and
                        self.groupSlots[fromLocation.groupIndex][fromLocation.slotIndex]
            if slot and slot.playerCard and slot.playerCard.playerID == playerID then
                card = slot.playerCard
                slot.playerCard = nil
                slot.isEmpty = true
                if slot.emptyLabel then
                    slot.emptyLabel:Show()
                end
                Debug:Dev("organizer_ui", "Found card in slot", fromLocation.groupIndex, fromLocation.slotIndex)
            end
        end
        
        if not card then
            Debug:Error("MoveSingleCard: Card not found for", playerID)
            return
        end
        
        -- CRITICAL: Reset drag state before moving to clear yellow border
        self:ResetDragState(card)
        
        -- Move card to destination
        if toLoc == "bench" then
            -- Add to bench
            card:SetParent(self.benchContainer)
            card.location = "bench"
            card.displayMode = "compact"
            table.insert(self.benchCards, card)
            NextKey222.CardView:Update(card)
            NextKey222.BenchManager:layout_bench(self)
            Debug:Dev("organizer_ui", "Moved card to bench")
        elseif toLoc == "opt_out" then
            -- Add to opt-out
            card:SetParent(self.optOutSection.scrollChild)
            card.location = "opt_out"
            card.displayMode = "opt_out"
            table.insert(self.optOutSection.playerCards, card)
            NextKey222.CardView:Update(card)
            NextKey222.SlotManager:layout_opt_out(self)
            Debug:Dev("organizer_ui", "Moved card to opt-out")
        elseif toLoc == "role_slot" then
            -- Add to slot
            local slot = self.groupSlots[toLocation.groupIndex] and
                        self.groupSlots[toLocation.groupIndex][toLocation.slotIndex]
            if slot then
                card:SetParent(slot.frame)
                card.location = toLocation
                card.displayMode = "expanded"
                NextKey222.CardView:Update(card)
                NextKey222.SlotManager:place_card_in_slot(card, slot, true)
                Debug:Dev("organizer_ui", "Moved card to slot", toLocation.groupIndex, toLocation.slotIndex)
            end
        end
        
    end, "RosterBoard:MoveSingleCard")
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
