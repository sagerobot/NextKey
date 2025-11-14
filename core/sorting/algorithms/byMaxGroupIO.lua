local _, NextKey222 = ...

-- MARK: Max Group IO Algorithm
-- Maximizes total IO gain for the entire party

local Sorting = NextKey222.Sorting
local UI = NextKey222.UI

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "MaxGroupIO",
    {
        displayName = "Max Group IO",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Maximize total IO gain for the entire party",
        priority = 90,
        icon = "Interface\\Icons\\Achievement_Dungeon_Mythic_All"
    },
    function(a, b)
        -- Max Group IO prioritizes keystones that give the highest total IO gain
        -- across all party members (sum of all individual gains)
        
        -- Use pre-calculated IO gain if available
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
        
        -- Sort descending (highest group IO gain first)
        return aGain > bGain
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: MaxGroupIO")
end