local _, NextKey222 = ...

-- MARK: Module Definition

local Sorting = {
    -- Algorithm registry
    algorithms = {},
    
    -- Context-based filtering metadata
    contexts = {
        KEYSTONES = "keystones",
        DUNGEONS = "dungeons",
        ORGANIZER = "organizer",
    },
}

NextKey222.Sorting = Sorting
NextKey222.RegisterModule("Sorting", Sorting)

-- MARK: Public Interface

--- Registers a sorting algorithm with metadata
-- @param name string Unique algorithm identifier (e.g., "HighestKeyLevel")
-- @param metadata table Algorithm metadata including:
--   - displayName: string User-facing name
--   - contexts: table Array of valid contexts (KEYSTONES, DUNGEONS, ORGANIZER)
--   - description: string Optional description
--   - priority: number Optional priority for default selection (higher = higher priority)
-- @param sortFunction function Comparator function(a, b) returning boolean
function Sorting:RegisterAlgorithm(name, metadata, sortFunction)
    if not name or not metadata or not sortFunction then
        if NextKey222.Debug then
            NextKey222.Debug:Error("Sorting: Invalid algorithm registration - missing required parameters")
        end
        return false
    end
    
    if self.algorithms[name] then
        if NextKey222.Debug then
            NextKey222.Debug:Dev("sorting", "Sorting: Algorithm already registered, replacing:", name)
        end
    end
    
    self.algorithms[name] = {
        name = name,
        displayName = metadata.displayName or name,
        contexts = metadata.contexts or {},
        description = metadata.description or "",
        priority = metadata.priority or 0,
        sortFunction = sortFunction,
    }
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("sorting", string.format(
            "Registered algorithm: %s (contexts: %s)",
            name,
            table.concat(metadata.contexts or {}, ", ")
        ))
    end
    
    return true
end

--- Gets all algorithms valid for a specific context
-- @param context string Context identifier (KEYSTONES, DUNGEONS, ORGANIZER)
-- @return table Array of algorithm metadata sorted by priority
function Sorting:GetAlgorithmsForContext(context)
    if not context then
        if NextKey222.Debug then
            NextKey222.Debug:Error("Sorting: GetAlgorithmsForContext called without context")
        end
        return {}
    end
    
    local results = {}
    
    for name, algo in pairs(self.algorithms) do
        -- Check if algorithm supports this context
        local validForContext = false
        for _, ctx in ipairs(algo.contexts) do
            if ctx == context then
                validForContext = true
                break
            end
        end
        
        if validForContext then
            table.insert(results, {
                name = algo.name,
                displayName = algo.displayName,
                description = algo.description,
                priority = algo.priority,
            })
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(results, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    
    return results
end

--- Sorts data using the specified algorithm
-- @param data table Array of items to sort
-- @param algorithmName string Name of the registered algorithm
-- @return table Sorted array (new table, original unchanged)
function Sorting:SortData(data, algorithmName)
    if not data or type(data) ~= "table" then
        if NextKey222.Debug then
            NextKey222.Debug:Error("Sorting: SortData called with invalid data")
        end
        return {}
    end
    
    if not algorithmName then
        if NextKey222.Debug then
            NextKey222.Debug:Dev("sorting", "Sorting: No algorithm specified, returning unsorted data")
        end
        return data
    end
    
    local algorithm = self.algorithms[algorithmName]
    if not algorithm then
        if NextKey222.Debug then
            NextKey222.Debug:Error("Sorting: Unknown algorithm:", algorithmName)
        end
        return data
    end
    
    -- Create a copy of the data to avoid mutating the original
    local sorted = {}
    for i, item in ipairs(data) do
        sorted[i] = item
    end
    
    -- Apply the sort function with error protection
    local success, err = pcall(function()
        table.sort(sorted, algorithm.sortFunction)
    end)
    
    if not success then
        if NextKey222.Debug then
            NextKey222.Debug:Error("Sorting: Sort function failed for", algorithmName, "error:", err)
        end
        return data -- Return original data on failure
    end
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("sorting", string.format(
            "Sorted %d items using algorithm: %s",
            #sorted,
            algorithmName
        ))
    end
    
    return sorted
end

--- Gets algorithm metadata by name
-- @param algorithmName string Name of the algorithm
-- @return table|nil Algorithm metadata or nil if not found
function Sorting:GetAlgorithm(algorithmName)
    return self.algorithms[algorithmName]
end

--- Checks if an algorithm is registered
-- @param algorithmName string Name of the algorithm
-- @return boolean true if algorithm exists
function Sorting:HasAlgorithm(algorithmName)
    return self.algorithms[algorithmName] ~= nil
end

--- Gets a list of all registered algorithms
-- @return table Map of algorithmName -> metadata
function Sorting:GetAllAlgorithms()
    local results = {}
    for name, algo in pairs(self.algorithms) do
        results[name] = {
            name = algo.name,
            displayName = algo.displayName,
            contexts = algo.contexts,
            description = algo.description,
            priority = algo.priority,
        }
    end
    return results
end

-- MARK: Initialization

function Sorting:Initialize()
    if NextKey222.Debug then
        NextKey222.Debug:Dev("sorting", "Sorting service initialized")
    end
    return true
end

return Sorting