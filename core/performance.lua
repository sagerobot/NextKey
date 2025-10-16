-- MARK: Performance Optimization System
-- Centralized performance monitoring and optimization for UI systems
-- Phase 7: Performance Optimization System

local _, NextKey222 = ...

local Performance = {}
NextKey222.Performance = Performance

-- Register with module system
NextKey222.RegisterModule("Performance", Performance)

-- MARK: Performance Constants
-- Standardized performance settings and thresholds

Performance.THROTTLE_INTERVAL = 0.1 -- Default throttle interval in seconds
Performance.BATCH_SIZE = 10 -- Default batch size for operations
Performance.CACHE_TIMEOUT = 300 -- Default cache timeout in seconds (5 minutes)
Performance.LAZY_LOAD_DELAY = 0.2 -- Default delay for lazy loading in seconds

Performance.METRICS = {
    RENDER_TIME = "render_time",
    UPDATE_TIME = "update_time",
    CACHE_HIT_RATE = "cache_hit_rate",
    MEMORY_USAGE = "memory_usage",
    FRAME_RATE = "frame_rate"
}

Performance.THRESHOLDS = {
    RENDER_TIME_WARNING = 16.67, -- ~60fps (ms)
    RENDER_TIME_CRITICAL = 33.33, -- ~30fps (ms)
    UPDATE_TIME_WARNING = 10, -- Warning threshold for updates (ms)
    UPDATE_TIME_CRITICAL = 25, -- Critical threshold for updates (ms)
    MEMORY_WARNING = 50, -- Memory usage warning (MB)
    MEMORY_CRITICAL = 100 -- Memory usage critical (MB)
}

-- MARK: Performance State
-- Current performance state and metrics

Performance.enabled = false
Performance.metrics = {}
Performance.profiles = {}
Performance.cache = {}
Performance.throttledFunctions = {}
Performance.batchQueue = {}
Performance.lazyLoadQueue = {}

-- MARK: Performance Profiling
-- Functions to profile and measure performance

--- Starts profiling a function
-- @param functionName string The name of the function to profile
-- @return table Profile context
function Performance:StartProfile(functionName)
    if not self.enabled then return {} end
    
    local profile = {
        name = functionName,
        startTime = debugprofilestop(),
        startMemory = collectgarbage("count"),
        calls = 0,
        totalTime = 0,
        minTime = math.huge,
        maxTime = 0,
        memoryUsed = 0
    }
    
    self.profiles[functionName] = profile
    return profile
end

--- Stops profiling a function
-- @param functionName string The name of the function to stop profiling
-- @return table Profile results
function Performance:StopProfile(functionName)
    if not self.enabled then return {} end
    
    local profile = self.profiles[functionName]
    if not profile then return {} end
    
    local endTime = debugprofilestop()
    local endMemory = collectgarbage("count")
    local elapsed = endTime - profile.startTime
    local memoryUsed = endMemory - profile.startMemory
    
    profile.calls = profile.calls + 1
    profile.totalTime = profile.totalTime + elapsed
    profile.minTime = math.min(profile.minTime, elapsed)
    profile.maxTime = math.max(profile.maxTime, elapsed)
    profile.memoryUsed = profile.memoryUsed + memoryUsed
    profile.averageTime = profile.totalTime / profile.calls
    
    -- Check thresholds
    if elapsed > self.THRESHOLDS.RENDER_TIME_CRITICAL then
        Debug:Error("Performance: Critical render time for", functionName, ":", elapsed, "ms")
    elseif elapsed > self.THRESHOLDS.RENDER_TIME_WARNING then
        Debug:Warn("Performance: Slow render time for", functionName, ":", elapsed, "ms")
    end
    
    return profile
end

--- Profiles a function call
-- @param func function The function to profile
-- @param functionName string The name of the function
-- @param ... any Arguments to pass to the function
-- @return any Function return values
function Performance:ProfileFunction(func, functionName, ...)
    if not self.enabled then return func(...) end
    
    self:StartProfile(functionName)
    local results = {pcall(func, ...)}
    local success = table.remove(results, 1)
    self:StopProfile(functionName)
    
    if not success then
        Debug:Error("Performance: Function error in", functionName, ":", unpack(results))
        error(results[1])
    end
    
    return unpack(results)
end

--- Gets performance metrics for a function
-- @param functionName string The name of the function
-- @return table Performance metrics
function Performance:GetMetrics(functionName)
    return self.profiles[functionName] or {}
end

--- Gets all performance metrics
-- @return table All performance metrics
function Performance:GetAllMetrics()
    return self.profiles
end

--- Resets performance metrics
-- @param functionName string Optional function name to reset (resets all if not provided)
function Performance:ResetMetrics(functionName)
    if functionName then
        self.profiles[functionName] = nil
    else
        self.profiles = {}
    end
    Debug:Dev("performance", "Performance metrics reset for:", functionName or "all")
end

-- MARK: Function Throttling
-- Functions to throttle expensive operations

--- Creates a throttled version of a function
-- @param func function The function to throttle
-- @param delay number Throttle delay in seconds
-- @param functionName string Optional function name for profiling
-- @return function Throttled function
function Performance:Throttle(func, delay, functionName)
    delay = delay or self.THROTTLE_INTERVAL
    local lastCall = 0
    
    local function throttledFunc(...)
        local currentTime = GetTime()
        
        if currentTime - lastCall >= delay then
            lastCall = currentTime
            
            if functionName then
                return self:ProfileFunction(func, functionName, ...)
            else
                return func(...)
            end
        end
    end
    
    -- Store reference for cleanup
    if functionName then
        self.throttledFunctions[functionName] = throttledFunc
    end
    
    return throttledFunc
end

--- Removes a throttled function
-- @param functionName string The function name to remove
function Performance:RemoveThrottledFunction(functionName)
    self.throttledFunctions[functionName] = nil
end

--- Clears all throttled functions
function Performance:ClearThrottledFunctions()
    self.throttledFunctions = {}
end

-- MARK: Batch Processing
-- Functions to batch operations for better performance

--- Adds a function to the batch queue
-- @param func function The function to batch
-- @param context table Optional context for the function
-- @param priority number Optional priority (higher = earlier)
function Performance:BatchAdd(func, context, priority)
    priority = priority or 0
    
    table.insert(self.batchQueue, {
        func = func,
        context = context or {},
        priority = priority,
        timestamp = GetTime()
    })
    
    -- Sort by priority (higher first)
    table.sort(self.batchQueue, function(a, b) return a.priority > b.priority end)
end

--- Processes the batch queue
-- @param batchSize number Optional batch size
function Performance:BatchProcess(batchSize)
    batchSize = batchSize or self.BATCH_SIZE
    
    if #self.batchQueue == 0 then return end
    
    local processed = 0
    
    self:StartProfile("batch_process")
    
    for i = #self.batchQueue, 1, -1 do
        if processed >= batchSize then break end
        
        local item = table.remove(self.batchQueue, i)
        
        if item and item.func then
            local success, result = pcall(item.func, item.context)
            if not success then
                Debug:Error("Performance: Batch function error:", result)
            end
            processed = processed + 1
        end
    end
    
    self:StopProfile("batch_process")
    
    Debug:Dev("performance", "Batch processed", processed, "items")
end

--- Clears the batch queue
function Performance:BatchClear()
    self.batchQueue = {}
    Debug:Dev("performance", "Batch queue cleared")
end

-- MARK: Caching System
-- Functions to cache expensive computations

--- Gets a value from cache
-- @param key string The cache key
-- @return any The cached value or nil
function Performance:CacheGet(key)
    local cached = self.cache[key]
    
    if cached then
        local currentTime = GetTime()
        
        -- Check if cache is still valid
        if currentTime - cached.timestamp < self.CACHE_TIMEOUT then
            cached.hits = (cached.hits or 0) + 1
            return cached.value
        else
            -- Remove expired cache
            self.cache[key] = nil
        end
    end
    
    return nil
end

--- Sets a value in cache
-- @param key string The cache key
-- @param value any The value to cache
function Performance:CacheSet(key, value)
    self.cache[key] = {
        value = value,
        timestamp = GetTime(),
        hits = 0
    }
end

--- Removes a value from cache
-- @param key string The cache key
function Performance:CacheRemove(key)
    self.cache[key] = nil
end

--- Clears the cache
function Performance:CacheClear()
    self.cache = {}
    Debug:Dev("performance", "Cache cleared")
end

--- Gets cache statistics
-- @return table Cache statistics
function Performance:CacheGetStats()
    local stats = {
        size = 0,
        totalHits = 0,
        validEntries = 0
    }
    
    local currentTime = GetTime()
    
    for key, cached in pairs(self.cache) do
        stats.size = stats.size + 1
        
        if currentTime - cached.timestamp < self.CACHE_TIMEOUT then
            stats.validEntries = stats.validEntries + 1
            stats.totalHits = stats.totalHits + (cached.hits or 0)
        end
    end
    
    return stats
end

--- Creates a cached version of a function
-- @param func function The function to cache
-- @param keyGenerator function Optional function to generate cache keys
-- @param functionName string Optional function name for profiling
-- @return function Cached function
function Performance:Cache(func, keyGenerator, functionName)
    local function cachedFunc(...)
        local key
        
        if keyGenerator then
            key = keyGenerator(...)
        else
            -- Generate key from arguments
            key = table.concat({...}, "|")
        end
        
        -- Try to get from cache
        local cached = self:CacheGet(key)
        if cached ~= nil then
            return cached
        end
        
        -- Compute and cache result
        local result
        if functionName then
            result = self:ProfileFunction(func, functionName, ...)
        else
            result = func(...)
        end
        
        self:CacheSet(key, result)
        return result
    end
    
    return cachedFunc
end

-- MARK: Lazy Loading
-- Functions to defer loading of non-critical components

--- Adds a function to the lazy load queue
-- @param func function The function to lazy load
-- @param delay number Optional delay in seconds
-- @param priority number Optional priority (higher = earlier)
function Performance:LazyLoad(func, delay, priority)
    delay = delay or self.LAZY_LOAD_DELAY
    priority = priority or 0
    
    table.insert(self.lazyLoadQueue, {
        func = func,
        delay = delay,
        priority = priority,
        timestamp = GetTime()
    })
    
    -- Sort by priority (higher first)
    table.sort(self.lazyLoadQueue, function(a, b) return a.priority > b.priority end)
end

--- Processes the lazy load queue
function Performance:LazyLoadProcess()
    if #self.lazyLoadQueue == 0 then return end
    
    local currentTime = GetTime()
    local processed = 0
    
    self:StartProfile("lazy_load_process")
    
    for i = #self.lazyLoadQueue, 1, -1 do
        local item = self.lazyLoadQueue[i]
        
        if currentTime - item.timestamp >= item.delay then
            table.remove(self.lazyLoadQueue, i)
            
            if item and item.func then
                local success, result = pcall(item.func)
                if not success then
                    Debug:Error("Performance: Lazy load function error:", result)
                end
                processed = processed + 1
            end
        end
    end
    
    self:StopProfile("lazy_load_process")
    
    Debug:Dev("performance", "Lazy load processed", processed, "items")
end

--- Clears the lazy load queue
function Performance:LazyLoadClear()
    self.lazyLoadQueue = {}
    Debug:Dev("performance", "Lazy load queue cleared")
end

-- MARK: Memory Management
-- Functions to monitor and optimize memory usage

--- Gets current memory usage
-- @return number Memory usage in MB
function Performance:GetMemoryUsage()
    return collectgarbage("count") / 1024
end

--- Forces garbage collection
-- @return number Memory freed in MB
function Performance:ForceGC()
    local beforeGC = collectgarbage("count")
    collectgarbage("collect")
    local afterGC = collectgarbage("count")
    local freed = (beforeGC - afterGC) / 1024
    
    Debug:Dev("performance", "Forced GC, freed", freed, "MB")
    return freed
end

--- Monitors memory usage and warns if thresholds are exceeded
function Performance:MonitorMemory()
    local memoryUsage = self:GetMemoryUsage()
    
    if memoryUsage > self.THRESHOLDS.MEMORY_CRITICAL then
        Debug:Error("Performance: Critical memory usage:", memoryUsage, "MB")
        self:ForceGC()
    elseif memoryUsage > self.THRESHOLDS.MEMORY_WARNING then
        Debug:Warn("Performance: High memory usage:", memoryUsage, "MB")
    end
    
    return memoryUsage
end

-- MARK: Performance Monitoring
-- Functions to monitor overall performance

--- Starts performance monitoring
function Performance:StartMonitoring()
    self.enabled = true
    
    -- Create monitoring frame
    local monitorFrame = CreateFrame("Frame")
    monitorFrame:SetScript("OnUpdate", function()
        self:MonitorMemory()
        self:BatchProcess()
        self:LazyLoadProcess()
    end)
    
    self.monitorFrame = monitorFrame
    
    Debug:Dev("performance", "Performance monitoring started")
end

--- Stops performance monitoring
function Performance:StopMonitoring()
    self.enabled = false
    
    if self.monitorFrame then
        self.monitorFrame:SetScript("OnUpdate", nil)
        self.monitorFrame = nil
    end
    
    Debug:Dev("performance", "Performance monitoring stopped")
end

--- Gets performance report
-- @return table Performance report
function Performance:GetReport()
    local report = {
        enabled = self.enabled,
        timestamp = GetTime(),
        memoryUsage = self:GetMemoryUsage(),
        cacheStats = self:CacheGetStats(),
        profiles = {},
        summary = {
            totalFunctions = 0,
            totalCalls = 0,
            averageTime = 0,
            slowestFunction = nil,
            slowestTime = 0
        }
    }
    
    -- Process profiles
    local totalTime = 0
    local totalCalls = 0
    local slowestTime = 0
    local slowestFunction = nil
    
    for functionName, profile in pairs(self.profiles) do
        report.profiles[functionName] = {
            calls = profile.calls,
            totalTime = profile.totalTime,
            averageTime = profile.averageTime,
            minTime = profile.minTime,
            maxTime = profile.maxTime,
            memoryUsed = profile.memoryUsed
        }
        
        report.summary.totalFunctions = report.summary.totalFunctions + 1
        report.summary.totalCalls = report.summary.totalCalls + profile.calls
        totalTime = totalTime + profile.totalTime
        totalCalls = totalCalls + profile.calls
        
        if profile.maxTime > slowestTime then
            slowestTime = profile.maxTime
            slowestFunction = functionName
        end
    end
    
    -- Calculate summary
    if report.summary.totalFunctions > 0 then
        report.summary.averageTime = totalTime / report.summary.totalFunctions
        report.summary.slowestFunction = slowestFunction
        report.summary.slowestTime = slowestTime
    end
    
    return report
end

--- Prints performance report to chat
function Performance:PrintReport()
    local report = self:GetReport()
    
    Debug:User("=== Performance Report ===")
    Debug:User("Monitoring:", report.enabled and "Enabled" or "Disabled")
    Debug:User("Memory Usage:", string.format("%.2f MB", report.memoryUsage))
    Debug:User("Cache Size:", report.cacheStats.size, "entries")
    Debug:User("Cache Hits:", report.cacheStats.totalHits)
    Debug:User("Total Functions:", report.summary.totalFunctions)
    Debug:User("Total Calls:", report.summary.totalCalls)
    Debug:User("Average Time:", string.format("%.2f ms", report.summary.averageTime))
    
    if report.summary.slowestFunction then
        Debug:User("Slowest Function:", report.summary.slowestFunction, 
                  string.format("(%.2f ms)", report.summary.slowestTime))
    end
    
    Debug:User("=== End Report ===")
end

-- MARK: Module Initialization
function Performance:Initialize()
    Debug:Dev("performance", "Performance module initialized")
    
    -- Start monitoring if enabled in settings
    if NextKey and NextKey.db and NextKey.db.global and NextKey.db.global.performance then
        if NextKey.db.global.performance.enabled then
            self:StartMonitoring()
        end
    end
    
    return true
end

return Performance