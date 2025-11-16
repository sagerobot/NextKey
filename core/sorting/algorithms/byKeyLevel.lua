local _, NextKey222 = ...

-- MARK: Highest Key Level Algorithm
-- Sorts keystones by level in descending order (highest first)

local Sorting = NextKey222.Sorting

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "HighestKeyLevel",
    {
        displayName = "Highest Key Level",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Sort by highest key level for challenging content. Differs from IO-based sorts when highest keys don't provide optimal IO gains.",
        priority = 75, -- High priority but lower than SmartSort (100)
        showIOTooltips = false -- Pure level-based sort, no IO tooltips
    },
    function(a, b)
        -- Extract key data
        local aLevel = (a.key and a.key.level) or 0
        local bLevel = (b.key and b.key.level) or 0
        
        -- Sort descending (highest level first)
        return aLevel > bLevel
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: HighestKeyLevel")
end