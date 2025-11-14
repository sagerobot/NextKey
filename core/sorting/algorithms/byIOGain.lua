local _, NextKey222 = ...

-- MARK: IO Gain Potential Algorithm
-- Sorts keystones by expected IO gain (highest first)

local Sorting = NextKey222.Sorting
local UI = NextKey222.UI

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "IOGainPotential",
    {
        displayName = "IO Gain Potential",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Sort keystones by expected IO gain for the group",
        priority = 95, -- Higher priority than LowestKeyLevel
    },
    function(a, b)
        -- IO Gain is calculated and cached on entries during rendering
        -- If not present, calculate it now (lazy calculation)
        
        if not a.ioGainRange and UI and UI.CalculateIOGainRange then
            a.ioGainRange = UI:CalculateIOGainRange(a.key)
            a.ioGainPotential = a.ioGainRange.expected
        end
        
        if not b.ioGainRange and UI and UI.CalculateIOGainRange then
            b.ioGainRange = UI:CalculateIOGainRange(b.key)
            b.ioGainPotential = b.ioGainRange.expected
        end
        
        local aGain = a.ioGainPotential or 0
        local bGain = b.ioGainPotential or 0
        
        -- Sort descending (highest gain first)
        return aGain > bGain
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: IOGainPotential")
end