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

-- MARK: Queue State
AnimationQueue.queue = {}          -- Array of animation tasks
AnimationQueue.isRunning = false   -- Whether queue is actively processing
AnimationQueue.currentTask = nil   -- Currently executing task
AnimationQueue.isPaused = false    -- Pause state
AnimationQueue.totalTasks = 0      -- Total tasks for progress tracking
AnimationQueue.onQueueComplete = nil -- Completion callback

-- MARK: Initialization
function AnimationQueue:Initialize()
    return NextKey222.SafeRun(function()
        self.queue = {}
        self.isRunning = false
        self.currentTask = nil
        self.isPaused = false
        self.totalTasks = 0
        self.onQueueComplete = nil
        Debug:Dev("organizer", "Initialized AnimationQueue")
        return true
    end, "AnimationQueue:Initialize")
end

-- MARK: Queue Management
function AnimationQueue:Enqueue(task)
    table.insert(self.queue, task)
    Debug:Trace("organizer", "Enqueued animation task - Queue size:", #self.queue)
    
    -- Start processing if not already running
    if not self.isRunning and not self.isPaused then
        self:ProcessQueue()
    end
end

function AnimationQueue:ProcessQueue()
    if #self.queue == 0 then
        self.isRunning = false
        Debug:Dev("organizer", "Animation queue completed")
        
        -- Notify completion
        if self.onQueueComplete then
            self:onQueueComplete()
        end
        return
    end
    
    self.isRunning = true
    
    -- Get next task
    local task = table.remove(self.queue, 1)
    self.currentTask = task
    
    Debug:Dev("organizer", "Processing animation task - Remaining:", #self.queue)
    
    -- Execute two-stage animation
    self:ExecuteTwoStageAnimation(task)
end

-- MARK: Two-Stage Animation
function AnimationQueue:ExecuteTwoStageAnimation(task)
    -- Stage 1: Highlight (green flash)
    self:AnimateHighlight(task.card, function()
        -- Stage 2: Fly to target
        self:AnimateFlight(task.card, task.targetSlot, function()
            -- Animation complete, process next
            C_Timer.After(self.config.interCardDelay, function()
                self:ProcessQueue()
            end)
        end)
    end)
end

-- MARK: Stage 1 - Highlight Animation
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

-- MARK: Stage 2 - Flight Animation
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

-- MARK: Control Functions
function AnimationQueue:Pause()
    self.isPaused = true
    Debug:Dev("organizer", "Animation queue paused")
end

function AnimationQueue:Resume()
    self.isPaused = false
    if not self.isRunning and #self.queue > 0 then
        self:ProcessQueue()
    end
    Debug:Dev("organizer", "Animation queue resumed")
end

function AnimationQueue:Clear()
    self.queue = {}
    self.isRunning = false
    self.currentTask = nil
    Debug:Dev("organizer", "Animation queue cleared")
end

function AnimationQueue:GetProgress()
    local remaining = #self.queue + (self.isRunning and 1 or 0)
    local completed = self.totalTasks - remaining
    return completed, self.totalTasks
end