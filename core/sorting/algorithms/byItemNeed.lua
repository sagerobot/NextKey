local _, NextKey222 = ...

-- MARK: Item Need Algorithm
-- Prioritizes dungeons with tracked loot items

local Sorting = NextKey222.Sorting

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "MaxItemNeed",
    {
        displayName = "Max Item Need",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Prioritize dungeons with tracked loot items",
        priority = 80,
        icon = "Interface\\Icons\\INV_Misc_Note_01"
    },
    function(a, b)
        -- Max Item Need prioritizes keystones for dungeons with tracked loot
        -- Perfect for loot farming focused groups
        
        local function getLootScore(entry)
            local score = 0
            
            -- Primary: Check if dungeon has tracked loot
            if entry.hasTrackedLoot then
                score = score + 1000 -- High base score for tracked loot
                
                -- Bonus for number of tracked items (if available)
                if entry.trackedItemCount then
                    score = score + (entry.trackedItemCount * 100)
                end
            end
            
            -- Secondary: Add IO gain as tiebreaker
            if entry.ioGainPotential then
                score = score + entry.ioGainPotential
            elseif entry.ioGainRange and entry.ioGainRange.expected then
                score = score + entry.ioGainRange.expected
            end
            
            return score
        end
        
        local aScore = getLootScore(a)
        local bScore = getLootScore(b)
        
        -- Sort descending (highest loot priority first)
        return aScore > bScore
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: MaxItemNeed")
end