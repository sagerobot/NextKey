-- MARK: Module Definition
local _, NextKey222 = ...

local AnimationQueue = {}
NextKey222.AnimationQueue = AnimationQueue
NextKey222.RegisterModule("AnimationQueue", AnimationQueue)

local Debug = NextKey222.Debug

-- MARK: Animation Configuration
AnimationQueue.config = {
    highlightDuration = 0.3,     -- Green flash duration (seconds)
    flashCount = 2,               -- Number of flashes
    flyDuration = 0.4,            -- Flying animation duration
    stepDelay = 0.02,             -- Frame delay for smooth animation
    interCardDelay = 0.1,         -- Pause between cards
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