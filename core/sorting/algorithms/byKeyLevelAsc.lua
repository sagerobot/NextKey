local _, NextKey222 = ...

-- MARK: Lowest Key Level Algorithm
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
        description = "Sort keystones by level (lowest first)",
        priority = 90, -- Lower priority than HighestKeyLevel
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