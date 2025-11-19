-- MARK: Module Definition
local _, NextKey222 = ...

local AnimationQueue = {}
NextKey222.AnimationQueue = AnimationQueue
NextKey222.RegisterModule("AnimationQueue", AnimationQueue)

local Debug = NextKey222.Debug

-- MARK: Animation Config
AnimationQueue.config = {
    highlightDuration = 0.3,     -- Green flash duration (seconds)
    flashCount = 2,               -- Number of flashes
    flyDuration = 0.4,            -- Flying animation duration
    stepDelay = 0.02,             -- Frame delay for smooth animation
    interCardDelay = 0.1,         -- Pause between cards
    
    -- Recall animation configuration
    recallWaveDelay = 0.15,           -- Delay between group waves
    recallFlashDuration = 0.2,        -- Flash duration per group
    simultaneousFlyDuration = 0.6,    -- All cards fly together
    recallFlashColor = {r=1.0, g=0.8, b=0.2},  -- Gold flash
    recallArcHeight = 40,             -- Parabolic arc height in pixels
    
    -- Simple Sort (Role Wave) animation configuration
    simpleSortWaveDelay = 0.3,        -- Delay between role waves
    simpleSortFlashDuration = 0.2,    -- Flash duration per role
    simpleSortFlyDuration = 0.5,      -- Flight duration
    simpleSortArcHeights = {
        TANK = 20,      -- Tanks: low arc (grounded)
        HEALER = 30,    -- Healers: medium arc
        DAMAGER = 40    -- DPS: high arc (agile)
    },
    roleFlashColors = {
        TANK = {r=0.0, g=0.67, b=1.0},     -- Blue (protection)
        HEALER = {r=0.0, g=1.0, b=0.0},    -- Green (health)
        DAMAGER = {r=1.0, g=0.27, b=0.27}  -- Red (damage)
    }
}

-- MARK: Initialization
function AnimationQueue:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Initialized AnimationQueue")
        return true
    end, "AnimationQueue:Initialize")
end

-- MARK: Public API
--- Executes a sequence of card animations (highlight + flight) in order
-- @param assignments Array of {card, targetSlot, player} objects
-- @param onComplete Callback function to execute when all animations finish
function AnimationQueue:ExecuteSequence(assignments, onComplete)
    return NextKey222.SafeRun(function()
        if not assignments or #assignments == 0 then
            Debug:Dev("organizer", "ExecuteSequence: No assignments to animate")
            if onComplete then onComplete() end
            return
        end
        
        Debug:Dev("organizer", "ExecuteSequence: Starting animation sequence for", #assignments, "assignments")
        
        local currentIndex = 1
        
        local function ProcessNext()
            if currentIndex > #assignments then
                Debug:Dev("organizer", "ExecuteSequence: All animations completed")
                if onComplete then onComplete() end
                return
            end
            
            local assignment = assignments[currentIndex]
            Debug:Dev("organizer", "ExecuteSequence: Animating card", currentIndex, "/", #assignments)
            
            -- Execute two-stage animation (highlight → flight)
            self:AnimateHighlight(assignment.card, function()
                self:AnimateFlight(assignment.card, assignment.targetSlot, function()
                    -- Move to next card after delay
                    currentIndex = currentIndex + 1
                    C_Timer.After(self.config.interCardDelay, ProcessNext)
                end)
            end)
        end
        
        -- Start the sequence
        ProcessNext()
        
    end, "AnimationQueue:ExecuteSequence")
end

-- MARK: Animation Functions
--- Stage 1: Highlight Animation (green flash)
function AnimationQueue:AnimateHighlight(card, onComplete)
    local flashCount = 0
    local maxFlashes = self.config.flashCount * 2 -- On/off cycle
    local flashInterval = self.config.highlightDuration / maxFlashes
    
    local function flash()
        flashCount = flashCount + 1
        
        if flashCount % 2 == 1 then
            -- Flash ON - green highlight
            card:SetBackdropColor(0.2, 0.9, 0.2, 1.0)
            card:SetBackdropBorderColor(0.2, 0.9, 0.2, 1.0)
        else
            -- Flash OFF - restore class color
            card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
            card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        end
        
        if flashCount >= maxFlashes then
            -- Highlight complete
            if onComplete then
                onComplete()
            end
        else
            -- Continue flashing
            C_Timer.After(flashInterval, flash)
        end
    end
    
    -- Start flashing
    flash()
end

--- Stage 2: Flight Animation (card flying to slot)
function AnimationQueue:AnimateFlight(card, targetSlot, onComplete)
    -- Store original position
    local startX, startY = card:GetCenter()
    local targetX, targetY = targetSlot:GetCenter()
    
    -- Calculate animation parameters
    local duration = self.config.flyDuration
    local steps = math.floor(duration / self.config.stepDelay)
    local currentStep = 0
    
    -- CRITICAL: Store original frame properties
    card.originalFrameStrata = card:GetFrameStrata()
    card.originalFrameLevel = card:GetFrameLevel()
    
    -- Reparent to UIParent for unrestricted movement
    card:SetParent(UIParent)
    card:SetFrameStrata("TOOLTIP")
    card:ClearAllPoints()
    card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", startX, startY)
    
    -- Animation step function
    local function animateStep()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        
        -- Eased progress (ease-in-out)
        local easedProgress = progress < 0.5
            and 2 * progress * progress
            or 1 - math.pow(-2 * progress + 2, 2) / 2
        
        -- Calculate current position
        local newX = startX + (targetX - startX) * easedProgress
        local newY = startY + (targetY - startY) * easedProgress
        
        -- Update card position
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
        
        if currentStep >= steps then
            -- Animation complete - remove from bench FIRST, then place in slot
            -- Remove card from bench array (prevent LayoutBench from repositioning it)
            NextKey222.RosterBoard:RemoveCardFromBenchArray(card)
            
            -- Now place in slot
            NextKey222.RosterBoard:PlaceCardInSlot(card, targetSlot)
            
            if onComplete then
                onComplete()
            end
        else
            -- Continue animation
            C_Timer.After(self.config.stepDelay, animateStep)
        end
    end
    
    -- Start animation
    animateStep()
end

-- MARK: Recall Animation
--- Executes recall animation sequence with cascading wave highlight and simultaneous flight
-- @param cardsByGroup Table of {[groupIndex] = {card1, card2, ...}}
-- @param onComplete Callback function to execute when all animations finish
function AnimationQueue:ExecuteRecallSequence(cardsByGroup, onComplete)
    return NextKey222.SafeRun(function()
        local allCards = {}
        local groupIndices = {}
        
        -- Collect all cards and sort groups
        for groupIndex, cards in pairs(cardsByGroup) do
            table.insert(groupIndices, groupIndex)
            for _, card in ipairs(cards) do
                table.insert(allCards, card)
            end
        end
        table.sort(groupIndices)
        
        Debug:Dev("organizer", "RecallSequence: Animating", #allCards,
                 "cards from", #groupIndices, "groups")
        
        if #allCards == 0 then
            if onComplete then onComplete() end
            return
        end
        
        -- PHASE 1: Cascading highlight wave
        local currentGroupIndex = 1
        local function highlightNextGroup()
            if currentGroupIndex > #groupIndices then
                -- Wave complete - start simultaneous flight
                C_Timer.After(0.1, function()
                    self:ExecuteSimultaneousFlight(allCards, onComplete)
                end)
                return
            end
            
            local groupIndex = groupIndices[currentGroupIndex]
            local groupCards = cardsByGroup[groupIndex]
            
            -- Flash all cards in this group simultaneously
            for _, card in ipairs(groupCards) do
                self:AnimateRecallFlash(card)
            end
            
            Debug:Dev("organizer", "RecallSequence: Flashed group", groupIndex,
                     "with", #groupCards, "cards")
            
            currentGroupIndex = currentGroupIndex + 1
            C_Timer.After(self.config.recallWaveDelay, highlightNextGroup)
        end
        
        -- Start the wave
        highlightNextGroup()
        
    end, "AnimationQueue:ExecuteRecallSequence")
end

--- Single gold flash animation for recall
-- @param card Player card frame
function AnimationQueue:AnimateRecallFlash(card)
    if not card then return end
    
    local flashColor = self.config.recallFlashColor
    
    -- Flash ON
    card:SetBackdropColor(flashColor.r, flashColor.g, flashColor.b, 1.0)
    card:SetBackdropBorderColor(flashColor.r, flashColor.g, flashColor.b, 1.0)
    
    -- Flash OFF after duration
    C_Timer.After(self.config.recallFlashDuration, function()
        if card and card.classColor then
            card:SetBackdropColor(card.classColor.r, card.classColor.g,
                                 card.classColor.b, 0.8)
            card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        end
    end)
end

--- Execute simultaneous flight for all cards
-- @param allCards Array of card frames
-- @param onComplete Callback when all cards have landed
function AnimationQueue:ExecuteSimultaneousFlight(allCards, onComplete)
    local completedCount = 0
    local totalCards = #allCards
    
    Debug:Dev("organizer", "SimultaneousFlight: Launching", totalCards, "cards")
    
    -- All cards start flying at the SAME TIME
    for _, card in ipairs(allCards) do
        self:AnimateRecallFlight(card, function()
            completedCount = completedCount + 1
            
            -- Only call onComplete when ALL cards have landed
            if completedCount >= totalCards then
                Debug:Dev("organizer", "SimultaneousFlight: All", totalCards, "cards landed")
                if onComplete then onComplete() end
            end
        end)
    end
end

--- Animate single card flight with parabolic arc
-- @param card Player card frame
-- @param onComplete Callback when card lands
function AnimationQueue:AnimateRecallFlight(card, onComplete)
    if not card then
        if onComplete then onComplete() end
        return
    end
    
    -- Store original position
    local startX, startY = card:GetCenter()
    
    -- Calculate target position on bench
    local rosterBoard = NextKey222.RosterBoard
    if not rosterBoard or not rosterBoard.benchContainer then
        Debug:Error("RecallFlight: benchContainer not available")
        if onComplete then onComplete() end
        return
    end
    
    local targetX, targetY = rosterBoard.benchContainer:GetCenter()
    
    -- Animation parameters
    local duration = self.config.simultaneousFlyDuration
    local steps = math.floor(duration / self.config.stepDelay)
    local currentStep = 0
    
    -- Store frame properties
    card.originalFrameStrata = card:GetFrameStrata()
    card.originalFrameLevel = card:GetFrameLevel()
    
    -- Elevate to UIParent for unrestricted flight
    card:SetParent(UIParent)
    card:SetFrameStrata("TOOLTIP")
    card:ClearAllPoints()
    card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", startX, startY)
    
    -- Animation step with PARABOLIC ARC
    local function animateStep()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        
        -- Ease-in-out for smooth motion
        local easedProgress = progress < 0.5
            and 2 * progress * progress
            or 1 - math.pow(-2 * progress + 2, 2) / 2
        
        -- Linear interpolation
        local newX = startX + (targetX - startX) * easedProgress
        local baseY = startY + (targetY - startY) * easedProgress
        
        -- Add parabolic arc (peaks at 50% progress)
        local arcHeight = self.config.recallArcHeight
        local arcOffset = arcHeight * math.sin(progress * math.pi)
        local newY = baseY + arcOffset
        
        -- Update position
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
        
        if currentStep >= steps then
            -- Flight complete - place in bench
            if NextKey222.CardMovement and NextKey222.CardMovement.place_card_in_bench then
                NextKey222.CardMovement:place_card_in_bench(rosterBoard, card)
            end
            
            Debug:Dev("organizer", "RecallFlight: Card landed")
            
            if onComplete then
                onComplete()
            end
        else
            C_Timer.After(self.config.stepDelay, animateStep)
        end
    end
    
    -- Start flight
    animateStep()
end

-- MARK: Simple Sort Animation
--- Executes role-based wave animation with simultaneous flight per role
--- Much faster than sequential animation - completes in ~1.2s for any group size
-- @param assignments Array of {card, targetSlot, player} objects
-- @param onComplete Callback function to execute when all animations finish
function AnimationQueue:ExecuteRoleWaveSequence(assignments, onComplete)
    return NextKey222.SafeRun(function()
        if not assignments or #assignments == 0 then
            Debug:Dev("organizer", "RoleWaveSequence: No assignments to animate")
            if onComplete then onComplete() end
            return
        end
        
        Debug:Dev("organizer", "RoleWaveSequence: Starting role wave animation for", #assignments, "assignments")
        
        -- Group assignments by role
        local roleGroups = {
            TANK = {},
            HEALER = {},
            DAMAGER = {}
        }
        
        for _, assignment in ipairs(assignments) do
            local role = assignment.targetSlot.role or "DAMAGER"
            table.insert(roleGroups[role], assignment)
        end
        
        Debug:Dev("organizer", string.format("RoleWaveSequence: Grouped - %d tanks, %d healers, %d dps",
                 #roleGroups.TANK, #roleGroups.HEALER, #roleGroups.DAMAGER))
        
        -- Execute waves in priority order: TANK → HEALER → DAMAGER
        local roleOrder = {"TANK", "HEALER", "DAMAGER"}
        local currentRoleIndex = 1
        
        local function ExecuteNextWave()
            if currentRoleIndex > #roleOrder then
                Debug:Dev("organizer", "RoleWaveSequence: All waves completed")
                if onComplete then onComplete() end
                return
            end
            
            local role = roleOrder[currentRoleIndex]
            local roleAssignments = roleGroups[role]
            
            if #roleAssignments > 0 then
                Debug:Dev("organizer", "RoleWaveSequence: Launching", role, "wave with", #roleAssignments, "cards")
                
                self:ExecuteRoleWave(role, roleAssignments, function()
                    currentRoleIndex = currentRoleIndex + 1
                    C_Timer.After(self.config.simpleSortWaveDelay, ExecuteNextWave)
                end)
            else
                -- Skip empty role
                Debug:Dev("organizer", "RoleWaveSequence: Skipping empty", role, "wave")
                currentRoleIndex = currentRoleIndex + 1
                ExecuteNextWave()
            end
        end
        
        -- Start the wave sequence
        ExecuteNextWave()
        
    end, "AnimationQueue:ExecuteRoleWaveSequence")
end

--- Execute a single role wave (flash + simultaneous flight)
-- @param role string Role name ("TANK", "HEALER", "DAMAGER")
-- @param assignments Array of {card, targetSlot, player} objects for this role
-- @param onComplete Callback when all cards in this wave have landed
function AnimationQueue:ExecuteRoleWave(role, assignments, onComplete)
    local flashColor = self.config.roleFlashColors[role]
    local arcHeight = self.config.simpleSortArcHeights[role]
    
    if not flashColor then
        Debug:Error("No flash color defined for role:", role)
        flashColor = {r=1.0, g=1.0, b=1.0}  -- Fallback to white
    end
    
    -- PHASE 1: Flash all cards in this role simultaneously
    for _, assignment in ipairs(assignments) do
        self:AnimateRoleFlash(assignment.card, flashColor)
    end
    
    Debug:Dev("organizer", "RoleWave: Flashed", #assignments, role, "cards")
    
    -- PHASE 2: After flash, launch all cards simultaneously
    C_Timer.After(self.config.simpleSortFlashDuration, function()
        local completedCount = 0
        local totalCards = #assignments
        
        for _, assignment in ipairs(assignments) do
            self:AnimateRoleWaveFlight(assignment.card, assignment.targetSlot, arcHeight, function()
                completedCount = completedCount + 1
                
                -- Only call onComplete when ALL cards in this wave have landed
                if completedCount >= totalCards then
                    Debug:Dev("organizer", "RoleWave:", role, "wave complete -", totalCards, "cards landed")
                    if onComplete then onComplete() end
                end
            end)
        end
    end)
end

--- Single role-colored flash animation
-- @param card Player card frame
-- @param flashColor Table with {r, g, b} values
function AnimationQueue:AnimateRoleFlash(card, flashColor)
    if not card then return end
    
    -- Flash ON with role color
    card:SetBackdropColor(flashColor.r, flashColor.g, flashColor.b, 1.0)
    card:SetBackdropBorderColor(flashColor.r, flashColor.g, flashColor.b, 1.0)
    
    -- Flash OFF after duration - restore class color
    C_Timer.After(self.config.simpleSortFlashDuration, function()
        if card and card.classColor then
            card:SetBackdropColor(card.classColor.r, card.classColor.g,
                                 card.classColor.b, 0.8)
            card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        end
    end)
end

--- Animate single card flight with role-specific arc height
-- @param card Player card frame
-- @param targetSlot Target slot frame
-- @param arcHeight Parabolic arc height in pixels (varies by role)
-- @param onComplete Callback when card lands
function AnimationQueue:AnimateRoleWaveFlight(card, targetSlot, arcHeight, onComplete)
    if not card or not targetSlot then
        Debug:Error("RoleWaveFlight: Invalid card or targetSlot")
        if onComplete then onComplete() end
        return
    end
    
    -- Store original position
    local startX, startY = card:GetCenter()
    local targetX, targetY = targetSlot:GetCenter()
    
    -- Animation parameters
    local duration = self.config.simpleSortFlyDuration
    local steps = math.floor(duration / self.config.stepDelay)
    local currentStep = 0
    
    -- CRITICAL: Store original frame properties
    card.originalFrameStrata = card:GetFrameStrata()
    card.originalFrameLevel = card:GetFrameLevel()
    
    -- Reparent to UIParent for unrestricted movement
    card:SetParent(UIParent)
    card:SetFrameStrata("TOOLTIP")
    card:ClearAllPoints()
    card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", startX, startY)
    
    -- Animation step function with parabolic arc
    local function animateStep()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        
        -- Ease-in-out for smooth acceleration/deceleration
        local easedProgress = progress < 0.5
            and 2 * progress * progress
            or 1 - math.pow(-2 * progress + 2, 2) / 2
        
        -- Linear interpolation
        local newX = startX + (targetX - startX) * easedProgress
        local baseY = startY + (targetY - startY) * easedProgress
        
        -- Add parabolic arc (peaks at 50% progress)
        local arcOffset = arcHeight * math.sin(progress * math.pi)
        local newY = baseY + arcOffset
        
        -- Update card position
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
        
        if currentStep >= steps then
            -- Animation complete - remove from bench FIRST, then place in slot
            NextKey222.RosterBoard:RemoveCardFromBenchArray(card)
            NextKey222.RosterBoard:PlaceCardInSlot(card, targetSlot)
            
            if onComplete then
                onComplete()
            end
        else
            -- Continue animation
            C_Timer.After(self.config.stepDelay, animateStep)
        end
    end
    
    -- Start animation
    animateStep()
end