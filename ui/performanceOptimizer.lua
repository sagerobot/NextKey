-- MARK: UI Performance Optimizer
-- Addresses critical performance issues causing FPS drops when main window is open

local _, NextKey222 = ...

local PerformanceOptimizer = {}
NextKey222.PerformanceOptimizer = PerformanceOptimizer
NextKey222.RegisterModule("PerformanceOptimizer", PerformanceOptimizer)

-- Performance tracking
PerformanceOptimizer.metrics = {
    frameTimeHistory = {},
    lastFrameTime = 0,
    averageFrameTime = 0,
    slowFrames = 0,
    totalFrames = 0
}

-- Throttling and batching
PerformanceOptimizer.throttleTimers = {}
PerformanceOptimizer.batchQueue = {}
PerformanceOptimizer.isProcessing = false

-- MARK: Critical Issue #1 - Excessive Tooltip Updates
-- Tooltips are being created/updated every frame when mouse moves

function PerformanceOptimizer:OptimizeTooltipSystem()
    if not NextKey222.UI or not GameTooltip then
        return
    end
    
    -- Hook GameTooltip to prevent excessive updates
    local originalSetOwner = GameTooltip.SetOwner
    local lastTooltipUpdate = 0
    local TOOLTIP_THROTTLE = 0.1 -- 100ms minimum between tooltip updates
    
    GameTooltip.SetOwner = function(self, owner, anchor, ...)
        local now = GetTime()
        if now - lastTooltipUpdate < TOOLTIP_THROTTLE then
            return -- Throttle tooltip updates
        end
        lastTooltipUpdate = now
        
        return originalSetOwner(self, owner, anchor, ...)
    end
    
    Debug:Dev("performance", "Tooltip system optimized with throttling")
end

-- MARK: Critical Issue #2 - Unbounded Event Handler Cascades
-- GROUP_ROSTER_UPDATE triggers UI refresh which triggers more events

function PerformanceOptimizer:OptimizeEventCascades()
    if not NextKey222.Events then
        return
    end
    
    -- Hook event handlers to prevent cascading updates
    local originalOnGroupRosterUpdate = NextKey222.Events.OnGroupRosterUpdate
    local lastRosterUpdate = 0
    local ROSTER_THROTTLE = 1.0 -- 1 second minimum between roster updates
    
    NextKey222.Events.OnGroupRosterUpdate = function(self, ...)
        local now = GetTime()
        if now - lastRosterUpdate < ROSTER_THROTTLE then
            Debug:Dev("performance", "Throttling GROUP_ROSTER_UPDATE cascade")
            return
        end
        lastRosterUpdate = now
        
        return originalOnGroupRosterUpdate(self, ...)
    end
    
    Debug:Dev("performance", "Event cascade system optimized")
end

-- MARK: Critical Issue #3 - Memory Leaks in Frame Creation
-- Frames are not being properly cleaned up when window closes

function PerformanceOptimizer:OptimizeFrameManagement()
    if not NextKey222.UI then
        return
    end
    
    -- Track created frames for proper cleanup
    local trackedFrames = {}
    
    -- Hook frame creation to track all UI frames
    local originalCreateFrame = CreateFrame
    _G.CreateFrame = function(frameType, name, parent, template, ...)
        local frame = originalCreateFrame(frameType, name, parent, template, ...)
        
        -- Track frames with NextKey in the name or parent hierarchy
        if (name and name:find("NextKey")) or 
           (parent and self:IsNextKeyFrame(parent)) then
            trackedFrames[frame] = {
                created = GetTime(),
                type = frameType,
                name = name
            }
        end
        
        return frame
    end
    
    -- Enhanced cleanup function
    function PerformanceOptimizer:CleanupAllFrames()
        local cleaned = 0
        for frame, info in pairs(trackedFrames) do
            if frame and frame.Hide then
                frame:Hide()
                frame:SetParent(nil)
                cleaned = cleaned + 1
            end
            trackedFrames[frame] = nil
        end
        
        Debug:Dev("performance", string.format("Cleaned up %d tracked frames", cleaned))
        return cleaned
    end
    
    Debug:Dev("performance", "Frame management system optimized")
end

-- MARK: Critical Issue #4 - Inefficient Profile Caching
-- Profiles are being rebuilt repeatedly instead of cached

function PerformanceOptimizer:OptimizeProfileCaching()
    if not NextKey222.ProfilesService then
        return
    end
    
    -- Enhance profile cache with better invalidation
    local originalGetProfile = NextKey222.ProfilesService.GetProfile
    local profileCache = {}
    local cacheHits = 0
    local cacheMisses = 0
    
    NextKey222.ProfilesService.GetProfile = function(self, playerName)
        if not playerName then return nil end
        
        local cacheKey = playerName
        local cached = profileCache[cacheKey]
        
        if cached and (GetTime() - cached.timestamp) < 300 then -- 5 minute cache
            cacheHits = cacheHits + 1
            return cached.profile
        end
        
        cacheMisses = cacheMisses + 1
        local profile = originalGetProfile(self, playerName)
        
        if profile then
            profileCache[cacheKey] = {
                profile = profile,
                timestamp = GetTime()
            }
        end
        
        return profile
    end
    
    -- Periodic cache stats reporting
    C_Timer.NewTicker(30, function()
        if cacheHits + cacheMisses > 0 then
            local hitRate = cacheHits / (cacheHits + cacheMisses) * 100
            Debug:Dev("performance", string.format("Profile cache: %.1f%% hit rate (%d hits, %d misses)", 
                hitRate, cacheHits, cacheMisses))
        end
    end)
    
    Debug:Dev("performance", "Profile caching system optimized")
end

-- MARK: Critical Issue #5 - Excessive Debug Logging
-- Debug calls are happening even when debug is disabled

function PerformanceOptimizer:OptimizeDebugLogging()
    -- Cache debug state to avoid repeated checks
    local debugEnabled = NextKey222.Debug and NextKey222.Debug.enabled or false
    local lastDebugCheck = 0
    
    -- Hook debug functions to check state less frequently
    if NextKey222.Debug then
        local originalDev = NextKey222.Debug.Dev
        NextKey222.Debug.Dev = function(self, category, ...)
            if not debugEnabled then return end
            
            local now = GetTime()
            if now - lastDebugCheck > 0.5 then -- Check debug state every 500ms
                debugEnabled = NextKey222.Debug.enabled or false
                lastDebugCheck = now
            end
            
            if debugEnabled and originalDev then
                return originalDev(self, category, ...)
            end
        end
    end
    
    Debug:Dev("performance", "Debug logging system optimized")
end

-- MARK: Performance Monitoring
function PerformanceOptimizer:StartPerformanceMonitoring()
    if self.monitoringFrame then
        return
    end
    
    self.monitoringFrame = CreateFrame("Frame")
    self.monitoringFrame:SetScript("OnUpdate", function()
        self:MonitorFramePerformance()
    end)
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("performance", "Performance monitoring started")
    end
end

function PerformanceOptimizer:MonitorFramePerformance()
    local now = GetTime()
    local frameDelta = now - self.metrics.lastFrameTime
    self.metrics.lastFrameTime = now
    
    -- Track frame time history
    table.insert(self.metrics.frameTimeHistory, frameDelta)
    if #self.metrics.frameTimeHistory > 60 then -- Keep last 60 frames
        table.remove(self.metrics.frameTimeHistory, 1)
    end
    
    self.metrics.totalFrames = self.metrics.totalFrames + 1
    
    -- Calculate average frame time
    local totalTime = 0
    for _, time in ipairs(self.metrics.frameTimeHistory) do
        totalTime = totalTime + time
    end
    self.metrics.averageFrameTime = totalTime / #self.metrics.frameTimeHistory
    
    -- Detect slow frames (> 33ms = < 30 FPS)
    if frameDelta > 0.033 then
        self.metrics.slowFrames = self.metrics.slowFrames + 1
        
        -- Log every 10th slow frame to avoid spam
        if self.metrics.slowFrames % 10 == 0 then
            if NextKey222.Debug then
                NextKey222.Debug:Dev("performance", string.format("Slow frame detected: %.1fms (%.0f FPS)",
                    frameDelta * 1000, 1 / frameDelta))
            end
        end
    end
    
    -- Report performance every 30 seconds
    if self.metrics.totalFrames % 1800 == 0 then -- 30 seconds at 60 FPS
        self:ReportPerformanceMetrics()
    end
end

function PerformanceOptimizer:ReportPerformanceMetrics()
    local avgFPS = 1 / self.metrics.averageFrameTime
    local slowFramePercent = (self.metrics.slowFrames / self.metrics.totalFrames) * 100
    
    Debug:Dev("performance", string.format("Performance Report: %.1f FPS avg, %.1f%% slow frames", 
        avgFPS, slowFramePercent))
    
    -- Reset counters
    self.metrics.slowFrames = 0
    self.metrics.totalFrames = 0
end

-- MARK: Helper Functions
function PerformanceOptimizer:IsNextKeyFrame(frame)
    if not frame then return false end
    
    -- Check frame name
    if frame.GetName and frame:GetName() and frame:GetName():find("NextKey") then
        return true
    end
    
    -- Check parent hierarchy
    local parent = frame.GetParent and frame:GetParent()
    if parent then
        return self:IsNextKeyFrame(parent)
    end
    
    return false
end

function PerformanceOptimizer:ForceGarbageCollection()
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after = collectgarbage("count")
    local freed = (before - after) / 1024
    
    Debug:Dev("performance", string.format("Forced GC: freed %.2f MB", freed))
    return freed
end

-- MARK: Module Initialization
function PerformanceOptimizer:Initialize()
    Debug:Dev("performance", "Initializing Performance Optimizer")
    
    -- Apply all optimizations
    self:OptimizeTooltipSystem()
    self:OptimizeEventCascades()
    self:OptimizeFrameManagement()
    self:OptimizeProfileCaching()
    self:OptimizeDebugLogging()
    
    -- Start performance monitoring
    self:StartPerformanceMonitoring()
    
    -- Periodic garbage collection
    C_Timer.NewTicker(60, function()
        self:ForceGarbageCollection()
    end)
    
    Debug:Dev("performance", "Performance Optimizer initialized with all optimizations")
    return true
end

return PerformanceOptimizer