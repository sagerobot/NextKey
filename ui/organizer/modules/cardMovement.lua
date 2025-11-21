-- MARK: Module Definition
local _, NextKey222 = ...

local CardMovement = {}
NextKey222.CardMovement = CardMovement
NextKey222.RegisterModule("CardMovement", CardMovement)

local Debug = NextKey222.Debug

-- MARK: Initialization
function CardMovement:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "CardMovement module initialized")
        return true
    end, "CardMovement:Initialize")
end

-- MARK: Role Validation
-- Static helpers with no RosterBoard dependency
--- Check if player can fill a role
-- @param playerRoles Player's roles (array or spec preferences table)
-- @param slotRole Slot's required role
-- @return boolean True if player can fill role
function CardMovement:can_player_fill_role(playerRoles, slotRole)
    if not playerRoles then
        return false
    end
    
    local normalizedSlotRole = slotRole
    if slotRole == "DAMAGER" then
        normalizedSlotRole = "DPS"
    end
    
    -- ENHANCED: Support both array and table formats
    -- Array format: {"TANK", "HEALER"} (legacy)
    -- Table format: {Tank = "play", Healer = "fill", DPS = "none"} (new spec preferences)
    
    -- Check if it's a spec preferences table (key-value pairs)
    local isSpecPreferencesTable = false
    for k, v in pairs(playerRoles) do
        if type(k) == "string" and type(v) == "string" then
            isSpecPreferencesTable = true
            break
        end
    end
    
    if isSpecPreferencesTable then
        -- New format: check spec preferences
        for role, preference in pairs(playerRoles) do
            -- Skip "none" preferences
            if preference ~= "none" then
                local normalizedRole = role:upper()
                if normalizedRole == "DAMAGER" then
                    normalizedRole = "DPS"
                end
                
                if normalizedRole == normalizedSlotRole:upper() or
                   normalizedRole == slotRole:upper() then
                    return true
                end
            end
        end
    else
        -- Legacy format: array of role strings
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
    end
    
    return false
end

--- Remove card from bench array
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
-- @return boolean True if removed successfully
function CardMovement:remove_card_from_bench_array(rosterBoard, card)
    if not rosterBoard.benchCards then return false end
    
    for i = #rosterBoard.benchCards, 1, -1 do
        if rosterBoard.benchCards[i] == card then
            table.remove(rosterBoard.benchCards, i)
            Debug:Dev("organizer_ui", "Removed card from benchCards array at index", i)
            return true
        end
    end
    
    Debug:Dev("organizer_ui", "Card not found in benchCards array")
    return false
end

-- MARK: Drop Detection
--- Detect which target the mouse is over during drop
-- @param rosterBoard RosterBoard instance
-- @return table|nil Drop target information
function CardMovement:detect_drop_target(rosterBoard)
    -- Check role slots first (highest priority)
    if rosterBoard.groupSlots then
        for groupIndex, slots in pairs(rosterBoard.groupSlots) do
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
    if rosterBoard.benchScrollFrame and rosterBoard.benchScrollFrame:IsMouseOver() then
        Debug:Dev("organizer_ui", "Mouse over bench")
        return {type = "bench"}
    end
    
    -- Check opt-out scroll frame (entire area including empty space)
    if rosterBoard.optOutSection and rosterBoard.optOutSection.scrollFrame and rosterBoard.optOutSection.scrollFrame:IsMouseOver() then
        Debug:Dev("organizer_ui", "Mouse over opt-out")
        return {type = "opt_out"}
    end
    
    return nil
end

--- Find a compatible slot in a group for a card
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
-- @param groupIndex Group number
-- @return table|nil Compatible slot if found
function CardMovement:find_compatible_slot_in_group(rosterBoard, card, groupIndex)
    if not rosterBoard.groupSlots[groupIndex] then
        return nil
    end
    
    -- Fetch player data from state
    local playerData = card.playerID and NextKey222.OrganizerState:GetPlayer(card.playerID)
    if not playerData then return nil end
    
    -- ENHANCED: Check spec preferences if available, otherwise fall back to roles array
    local rolesToCheck = playerData.specPreferences or playerData.roles
    
    for _, slot in ipairs(rosterBoard.groupSlots[groupIndex]) do
        if slot.isEmpty and self:can_player_fill_role(rolesToCheck, slot.role) then
            return slot
        end
    end
    
    return nil
end

-- MARK: Card Removal
--- Remove card from its current location
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
function CardMovement:remove_card_from_source(rosterBoard, card)
    local location = card.location
    
    -- Handle location (support both string and table formats for backward compatibility)
    local locationType = type(location) == "table" and location.type or location
    
    if locationType == "bench" then
        -- Remove from bench array
        for i = #rosterBoard.benchCards, 1, -1 do
            if rosterBoard.benchCards[i] == card then
                table.remove(rosterBoard.benchCards, i)
                Debug:Dev("organizer_ui", "Removed card from bench at index", i)
                NextKey222.BenchManager:layout_bench(rosterBoard)
                return
            end
        end
        
    elseif locationType == "opt_out" then
        -- Remove from opt-out array
        if rosterBoard.optOutSection and rosterBoard.optOutSection.playerCards then
            for i = #rosterBoard.optOutSection.playerCards, 1, -1 do
                if rosterBoard.optOutSection.playerCards[i] == card then
                    table.remove(rosterBoard.optOutSection.playerCards, i)
                    Debug:Dev("organizer_ui", "Removed card from opt-out at index", i)
                    NextKey222.SlotManager:layout_opt_out(rosterBoard)
                    return
                end
            end
        end
        
    elseif type(location) == "table" and location.type == "role_slot" then
        -- Remove from slot
        local slot = rosterBoard.groupSlots[location.groupIndex] and
                     rosterBoard.groupSlots[location.groupIndex][location.slotIndex]
        
        if slot and slot.playerCard == card then
            slot.playerCard = nil
            slot.isEmpty = true
            
            -- Restore empty label
            if slot.emptyLabel then
                slot.emptyLabel:Show()
            end
            
            Debug:Dev("organizer_ui", "Removed card from slot")
        end
    end
end

-- MARK: Placement
-- NOTE: Placement logic removed - now handled entirely by event-driven architecture
-- Drag-drop updates state only, event handlers update UI

-- MARK: Rejection
--- Animate card rejection (bounce back to original position)
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
function CardMovement:animate_rejection(rosterBoard, card)
    return NextKey222.SafeRun(function()
        local playerData = card.playerID and NextKey222.OrganizerState:GetPlayer(card.playerID)
        Debug:Dev("organizer_ui", "Animating rejection for:", playerData and playerData.name or card.playerID)
        
        -- Flash red to indicate rejection
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
                -- Animation complete - restore card to original location
                local location = card.location
                
                -- Handle location (support both string and table formats)
                local locationType = type(location) == "table" and location.type or location
                
                if locationType == "role_slot" then
                    -- Card is in a slot - restore it there
                    local slot = rosterBoard.groupSlots[location.groupIndex] and
                                 rosterBoard.groupSlots[location.groupIndex][location.slotIndex]
                    
                    if slot then
                        card:SetParent(slot)
                        card:SetSize(145, 90)  -- Expanded size for slots
                        card:ClearAllPoints()
                        card:SetPoint("CENTER", slot, "CENTER")
                        
                        -- Ensure slot metadata is correct (card was never removed)
                        slot.isEmpty = false
                        if slot.emptyLabel then
                            slot.emptyLabel:Hide()
                        end
                    end
                    
                elseif locationType == "bench" then
                    -- Card is in bench - re-layout
                    card:SetParent(rosterBoard.benchContainer)
                    NextKey222.BenchManager:layout_bench(rosterBoard)
                    
                elseif locationType == "opt_out" then
                    -- Card is in opt-out - re-layout
                    card:SetParent(rosterBoard.optOutSection.scrollChild)
                    NextKey222.SlotManager:layout_opt_out(rosterBoard)
                end
                
                -- Restore frame properties
                card:SetFrameStrata(card.originalFrameStrata or "MEDIUM")
                card:SetFrameLevel(card.originalFrameLevel or (card:GetParent():GetFrameLevel() + 1))
                card:EnableMouse(true)
                card:SetMovable(true)
                
                -- Reset colors
                card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
                card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
                
                Debug:Dev("organizer_ui", "Rejection animation complete - card restored to:", type(location) == "table" and location.type or location)
            else
                C_Timer.After(stepDelay, AnimateStep)
            end
        end
        
        C_Timer.After(stepDelay, AnimateStep)
        
    end, "CardMovement:animate_rejection")
end

-- MARK: Drop Handling
-- Main orchestrator for card drops
--- Handle card drop event (orchestrates validation and placement)
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
-- @param dropTarget Drop target information
function CardMovement:handle_card_drop(rosterBoard, card, dropTarget)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "HandleCardDrop - type:", dropTarget.type)
        
        -- Fetch player data from state
        if not card.playerID then
            Debug:Error("Card has no playerID - cannot handle drop")
            return
        end
        
        local playerData = NextKey222.OrganizerState:GetPlayer(card.playerID)
        if not playerData then
            Debug:Error("Player data not found in state:", card.playerID)
            return
        end
        
        -- VALIDATE FIRST (before any state changes)
        if dropTarget.type == "role_slot" then
            -- Validate role compatibility
            local canFill = self:can_player_fill_role(playerData.roles, dropTarget.role)
            
            if not canFill then
                -- Try to find compatible slot in same group
                local compatibleSlot = self:find_compatible_slot_in_group(rosterBoard, card, dropTarget.groupIndex)
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
                    self:animate_rejection(rosterBoard, card)
                    return
                end
            end
            
            -- Check if slot is occupied
            if not dropTarget.slot.isEmpty then
                Debug:Dev("organizer_ui", "Slot occupied - rejecting")
                self:animate_rejection(rosterBoard, card)
                return
            end
        end
        
        -- VALIDATION PASSED - Now check for same-location drop
        
        -- Get current location from state (most reliable)
        local currentLocation = NextKey222.OrganizerState:GetPlayerLocation(card.playerID)
        
        -- Check if dropping in same location
        local isSameLocation = false
        if type(currentLocation) == "table" and type(dropTarget.type) == "string" and dropTarget.type == "role_slot" then
            -- Both are role slots - compare group and slot indices
            isSameLocation = (currentLocation.type == "role_slot" and
                            currentLocation.groupIndex == dropTarget.groupIndex and
                            currentLocation.slotIndex == dropTarget.slotIndex)
        elseif type(currentLocation) == "string" and type(dropTarget.type) == "string" then
            -- Both are simple locations (bench/opt_out)
            isSameLocation = (currentLocation == dropTarget.type)
        end
        
        if isSameLocation then
            Debug:Dev("organizer_ui", "Same location drop detected - resetting drag state only")
            -- Reset drag state and reparent to correct container
            if currentLocation == "bench" then
                card:SetParent(rosterBoard.benchContainer)
                card:SetFrameStrata("MEDIUM")
                card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
                card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
                NextKey222.BenchManager:layout_bench(rosterBoard)
            elseif currentLocation == "opt_out" then
                card:SetParent(rosterBoard.optOutSection.scrollChild)
                card:SetFrameStrata("MEDIUM")
                card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
                card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
                NextKey222.SlotManager:layout_opt_out(rosterBoard)
            elseif type(currentLocation) == "table" and currentLocation.type == "role_slot" then
                local slot = rosterBoard.groupSlots[currentLocation.groupIndex] and
                            rosterBoard.groupSlots[currentLocation.groupIndex][currentLocation.slotIndex]
                if slot then
                    card:SetParent(slot.frame)
                    card:SetFrameStrata("MEDIUM")
                    card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
                    card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
                    card:ClearAllPoints()
                    card:SetPoint("CENTER", slot.frame, "CENTER")
                end
            end
            return  -- Don't update state - nothing changed
        end
        
        -- Different location - proceed with move
        
        -- Clear keystone if moving from a slot
        if card.location and
           type(card.location) == "table" and
           card.location.type == "role_slot" then
            
            local prevGroupIndex = card.location.groupIndex
            
            if NextKey222.KeystoneManager:is_keystone_designated(rosterBoard, prevGroupIndex, card.playerID) then
                NextKey222.KeystoneManager:clear_group_keystone(rosterBoard, prevGroupIndex)
                Debug:Dev("organizer", "Cleared keystone - card moved to different group")
            end
        end
        
        -- CRITICAL: Do NOT remove card from source arrays here!
        -- SyncUIToState will clean up ALL cards when it rebuilds from state
        -- If we remove it here, SyncUIToState won't find it to destroy it
        
        -- EVENT-DRIVEN PATTERN: Only update state, let event handler do UI work
        if dropTarget.type == "role_slot" then
            NextKey222.OrganizerState:MoveToSlot(card.playerID, dropTarget.groupIndex, dropTarget.slotIndex)
            Debug:Dev("organizer_ui", "State updated - moving to slot", dropTarget.groupIndex, dropTarget.slotIndex)
        elseif dropTarget.type == "bench" then
            NextKey222.OrganizerState:MoveToBench(card.playerID)
            Debug:Dev("organizer_ui", "State updated - moving to bench")
        elseif dropTarget.type == "opt_out" then
            NextKey222.OrganizerState:MoveToOptOut(card.playerID)
            Debug:Dev("organizer_ui", "State updated - moving to opt-out")
        end
        
    end, "CardMovement:handle_card_drop")
end