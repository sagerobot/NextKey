local _, NextKey222 = ...

-- MARK: Lowest Key
-- Sorts keystones by level in ascending order (lowest first)

local Sorting = NextKey222.Sorting

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "LowestKeyLevel",
    {
        displayName = "Lowest Key Level",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Sort by lowest key level for easier completions. Useful for vault filling or newer players. May overlap with other sorts in balanced groups.",
        priority = 70, -- Lower priority than HighestKeyLevel (75)
        showIOTooltips = false -- Pure level-based sort, no IO tooltips
    },
    function(a, b)
        -- Extract key data
        local aLevel = (a.key and a.key.level) or 0
        local bLevel = (b.key and b.key.level) or 0
        
        -- Sort ascending (lowest level first)
        return aLevel < bLevel
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: LowestKeyLevel")
end