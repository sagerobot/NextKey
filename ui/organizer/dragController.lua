-- MARK: Module Definition
local _, NextKey222 = ...

local DragController = {}
NextKey222.DragController = DragController
NextKey222.RegisterModule("DragController", DragController)

local Debug = NextKey222.Debug

-- MARK: State
DragController.activeDrag = nil  -- {card, playerID, fromLocation}

-- MARK: Initialization
function DragController:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "DragController module initialized")
        self.activeDrag = nil
        return true
    end, "DragController:Initialize")
end

-- MARK: Enable Drag
--- Register drag handlers on a card
-- @param card The card frame to enable dragging on
function DragController:EnableDrag(card)
    if not card then return end
    
    card:SetMovable(true)
    card:RegisterForDrag("LeftButton")
    
    card:SetScript("OnDragStart", function(self)
        DragController:StartDrag(self)
    end)
    
    card:SetScript("OnDragStop", function(self)
        DragController:CompleteDrag(self)
    end)
end

-- MARK: Start Drag
--- Initialize drag operation
-- @param card The card being dragged
function DragController:StartDrag(card)
    return NextKey222.SafeRun(function()
        if not card or not card.playerID then
            Debug:Error("StartDrag called with invalid card")
            return
        end
        
        Debug:Dev("organizer_ui", "StartDrag:", card.playerID)
        
        -- CRITICAL FIX: Save original parent and strata for restoration
        card.originalParent = card:GetParent()
        card.originalFrameStrata = card:GetFrameStrata()
        
        -- CRITICAL FIX: Reparent to UIParent so card is not clipped by container boundaries
        card:SetParent(UIParent)
        
        -- CRITICAL FIX: Elevate to TOOLTIP strata to render above all other UI
        card:SetFrameStrata("TOOLTIP")
        
        -- Visual feedback
        card:StartMoving()
        card:SetBackdropBorderColor(1.0, 1.0, 0, 1.0)  -- Yellow border
        
        -- Store transaction data
        self.activeDrag = {
            card = card,
            playerID = card.playerID,
            fromLocation = NextKey222.OrganizerState:GetLocation(card.playerID)
        }
        
        Debug:Dev("organizer_ui", "Drag transaction started - playerID:", card.playerID,
                 "fromLocation:", self.activeDrag.fromLocation)
        
    end, "DragController:StartDrag")
end

-- MARK: Detect Drop Target
--- Detect what the card is being dropped on
-- @return table Drop target with zone info
function DragController:DetectDropTarget()
    local RosterBoard = NextKey222.RosterBoard
    
    -- Check slots first (priority)
    if RosterBoard.groupSlots then
        for groupIndex, slots in pairs(RosterBoard.groupSlots) do
            for slotIndex, slot in pairs(slots) do
                if slot and slot.frame and slot.frame:IsMouseOver() then
                    Debug:Dev("organizer_ui", "Drop target: slot", groupIndex, slotIndex)
                    return {
                        type = "slot",
                        zone = "slot",
                        group = groupIndex,
                        slot = slotIndex,
                        frame = slot.frame,
                        role = slot.role
                    }
                end
            end
        end
    end
    
    -- Check opt-out
    if RosterBoard.optOutSection and RosterBoard.optOutSection.scrollFrame and 
       RosterBoard.optOutSection.scrollFrame:IsMouseOver() then
        Debug:Dev("organizer_ui", "Drop target: opt-out")
        return {
            type = "opt_out",
            zone = "opt_out",
            frame = RosterBoard.optOutSection.scrollFrame
        }
    end
    
    -- Default: bench
    Debug:Dev("organizer_ui", "Drop target: bench (default)")
    return {
        type = "bench",
        zone = "bench",
        frame = RosterBoard.benchContainer
    }
end

-- MARK: Validate Move
--- Check if the move is valid
-- @param playerID Player identifier
-- @param fromLocation Source location
-- @param toLocation Destination location
-- @return boolean True if valid
function DragController:ValidateMove(playerID, fromLocation, toLocation)
    -- Same location check
    if NextKey222.Location and NextKey222.Location.IsEqual then
        if NextKey222.Location.IsEqual(fromLocation, toLocation) then
            Debug:Dev("organizer_ui", "ValidateMove: Same location - valid")
            return true
        end
    end
    
    -- Role validation for slot targets
    if toLocation.zone == "slot" then
        local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
        if not playerData then
            Debug:Error("ValidateMove: No player data for", playerID)
            return false
        end
        
        local RosterBoard = NextKey222.RosterBoard
        local slot = RosterBoard.groupSlots[toLocation.group] and 
                     RosterBoard.groupSlots[toLocation.group][toLocation.slot]
        
        if not slot then
            Debug:Error("ValidateMove: Slot not found")
            return false
        end
        
        -- Check if slot is occupied
        if not slot.isEmpty then
            Debug:Dev("organizer_ui", "ValidateMove: Slot occupied - invalid")
            return false
        end
        
        -- Check role compatibility
        local canFill = self:CanFillRole(playerData.roles, slot.role)
        Debug:Dev("organizer_ui", "ValidateMove: Role check -", canFill)
        return canFill
    end
    
    -- Bench/opt-out always valid
    return true
end

-- MARK: Role Validation
--- Check if player can fill a role
-- @param playerRoles Player's roles (array or spec preferences table)
-- @param slotRole Slot's required role
-- @return boolean True if player can fill role
function DragController:CanFillRole(playerRoles, slotRole)
    if not playerRoles then
        return false
    end
    
    local normalizedSlotRole = slotRole
    if slotRole == "DAMAGER" then
        normalizedSlotRole = "DPS"
    end
    
    -- Support both array and table formats
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

-- MARK: Complete Drag
--- Finalize drag operation
-- @param card The card being dragged
function DragController:CompleteDrag(card)
    return NextKey222.SafeRun(function()
        card:StopMovingOrSizing()
        
        -- CRITICAL FIX: Restore original parent first
        if card.originalParent then
            card:SetParent(card.originalParent)
            card.originalParent = nil
        end
        
        -- CRITICAL FIX: Restore original frame strata
        if card.originalFrameStrata then
            card:SetFrameStrata(card.originalFrameStrata)
            card.originalFrameStrata = nil
        end
        
        local drag = self.activeDrag
        if not drag then
            Debug:Dev("organizer_ui", "CompleteDrag: No active drag")
            return
        end
        
        Debug:Dev("organizer_ui", "CompleteDrag:", drag.playerID)
        
        -- Detect drop target
        local dropTarget = self:DetectDropTarget()
        local toLocation = dropTarget
        
        -- Convert dropTarget format to Location format
        if dropTarget.zone == "slot" then
            toLocation = {
                zone = "slot",
                group = dropTarget.group,
                slot = dropTarget.slot
            }
        elseif dropTarget.zone == "opt_out" then
            toLocation = "opt_out"
        else
            toLocation = "bench"
        end
        
        Debug:Dev("organizer_ui", "Drop target detected:", toLocation)
        
        -- Validate move
        if not self:ValidateMove(drag.playerID, drag.fromLocation, toLocation) then
            Debug:Dev("organizer_ui", "Move validation failed - rejecting")
            self:AnimateReject(card, drag.fromLocation)
            self.activeDrag = nil
            return
        end
        
        -- Update state FIRST (will trigger ORGANIZER_PLAYER_MOVED event)
        Debug:Dev("organizer_ui", "Updating state - playerID:", drag.playerID, "to:", toLocation)
        NextKey222.OrganizerState:SetLocation(drag.playerID, toLocation)
        
        -- CRITICAL: Card will be hidden and destroyed by the event-driven rebuild
        -- The OnPlayerMoved event handler will call RebuildSlots/RebuildBench which
        -- properly cleans up old cards and creates new ones from state
        
        -- Clear active drag
        self.activeDrag = nil
        
        Debug:Dev("organizer_ui", "CompleteDrag finished - state updated, card hidden")
        
    end, "DragController:CompleteDrag")
end

-- MARK: Animate Reject
--- Animate rejection with smooth fly-back to original position
-- @param card The card being rejected
-- @param originalLocation Original location to restore visual state
function DragController:AnimateReject(card, originalLocation)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "AnimateReject:", card.playerID)
        
        -- Store current position (where the invalid drop happened)
        local startX, startY = card:GetCenter()
        
        -- Stop any ongoing movement
        card:StopMovingOrSizing()
        
        -- Keep card on UIParent and TOOLTIP strata for animation visibility
        -- (Don't restore parent yet - we need to animate freely)
        
        -- Red flash border
        card:SetBackdropBorderColor(1.0, 0, 0, 1.0)
        
        -- Get target position by temporarily rebuilding and capturing position
        local RosterBoard = NextKey222.RosterBoard
        local targetX, targetY
        
        -- Rebuild the section to get the target position
        if originalLocation == "bench" and RosterBoard then
            RosterBoard:RebuildBench()
            -- Find the rebuilt card to get its target position
            for _, benchCard in ipairs(RosterBoard.benchCards or {}) do
                if benchCard.playerID == card.playerID then
                    targetX, targetY = benchCard:GetCenter()
                    benchCard:Hide() -- Hide the rebuilt card, we'll animate the original
                    break
                end
            end
        elseif originalLocation == "opt_out" and RosterBoard and RosterBoard.optOutSection then
            RosterBoard:RebuildOptOut()
            for _, optOutCard in ipairs(RosterBoard.optOutSection.playerCards or {}) do
                if optOutCard.playerID == card.playerID then
                    targetX, targetY = optOutCard:GetCenter()
                    optOutCard:Hide()
                    break
                end
            end
        elseif type(originalLocation) == "table" and originalLocation.zone == "slot" and RosterBoard then
            RosterBoard:RebuildSlots()
            local slot = RosterBoard.groupSlots[originalLocation.group] and
                        RosterBoard.groupSlots[originalLocation.group][originalLocation.slot]
            if slot and slot.playerCard and slot.playerCard.playerID == card.playerID then
                targetX, targetY = slot.playerCard:GetCenter()
                slot.playerCard:Hide()
            end
        end
        
        -- Fallback if we couldn't get target position
        if not targetX or not targetY then
            Debug:Error("AnimateReject: Could not determine target position")
            card:Hide()
            return
        end
        
        -- Animate fly-back (fast - 0.15 seconds total)
        local duration = 0.15
        local steps = 8
        local stepDelay = duration / steps
        local currentStep = 0
        
        -- Keep card on UIParent for animation
        card:SetParent(UIParent)
        card:SetFrameStrata("TOOLTIP")
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", startX, startY)
        
        local function animateStep()
            currentStep = currentStep + 1
            local progress = currentStep / steps
            
            -- Ease-out cubic for smooth deceleration
            local easedProgress = 1 - math.pow(1 - progress, 3)
            
            -- Interpolate position
            local newX = startX + (targetX - startX) * easedProgress
            local newY = startY + (targetY - startY) * easedProgress
            
            card:ClearAllPoints()
            card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
            
            if currentStep >= steps then
                -- Animation complete - restore original state
                if card.originalParent then
                    card:SetParent(card.originalParent)
                    card.originalParent = nil
                end
                if card.originalFrameStrata then
                    card:SetFrameStrata(card.originalFrameStrata)
                    card.originalFrameStrata = nil
                end
                
                -- Reset border color
                if card.classColor then
                    card:SetBackdropBorderColor(
                        card.classColor.r * 0.8,
                        card.classColor.g * 0.8,
                        card.classColor.b * 0.8,
                        1.0
                    )
                else
                    card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
                end
                
                -- Hide animated card, final rebuild will create proper card
                card:Hide()
                
                -- Final rebuild to ensure clean state
                if originalLocation == "bench" then
                    RosterBoard:RebuildBench()
                elseif originalLocation == "opt_out" then
                    RosterBoard:RebuildOptOut()
                elseif type(originalLocation) == "table" and originalLocation.zone == "slot" then
                    RosterBoard:RebuildSlots()
                end
            else
                C_Timer.After(stepDelay, animateStep)
            end
        end
        
        -- Start animation
        animateStep()
        
    end, "DragController:AnimateReject")
end

return DragController