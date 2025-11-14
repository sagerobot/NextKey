local _, NextKey222 = ...

-- MARK: Smart Sort Algorithm (Borda Count)
-- Balances IO gain, player coverage, key level, and loot preferences using ranked voting

local Sorting = NextKey222.Sorting
local UI = NextKey222.UI

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "SmartSort",
    {
        displayName = "Smart Sort",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Balanced ranking using Borda count: considers IO gain, player coverage, key level, and loot targeting",
        priority = 100, -- Highest priority (default algorithm)
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze"
    },
    function(a, b)
        -- Smart Sort uses a Borda count ranking system
        -- Each keystone is scored across multiple criteria and ranked
        -- The keystone with the highest total score wins
        
        local function calculateSmartScore(entry)
            local score = 0
            
            -- Criterion 1: IO Gain Potential (weight: 40%)
            if entry.ioGainPotential then
                score = score + (entry.ioGainPotential * 0.4)
            elseif entry.ioGainRange and entry.ioGainRange.expected then
                score = score + (entry.ioGainRange.expected * 0.4)
            end
            
            -- Criterion 2: Player Coverage (weight: 30%)
            -- Number of players who benefit from this key
            if entry.playersBenefiting then
                score = score + (entry.playersBenefiting * 10 * 0.3)
            end
            
            -- Criterion 3: Key Level (weight: 20%)
            -- Higher keys are slightly preferred for challenge
            if entry.key and entry.key.level then
                score = score + (entry.key.level * 2 * 0.2)
            end
            
            -- Criterion 4: Loot Targeting (weight: 10%)
            -- Dungeons with tracked loot items get a bonus
            if entry.hasTrackedLoot then
                score = score + (50 * 0.1)
            end
            
            return score
        end
        
        -- Calculate scores and sort descending (highest score first)
        local aScore = calculateSmartScore(a)
        local bScore = calculateSmartScore(b)
        
        return aScore > bScore
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: SmartSort (Borda count)")
end