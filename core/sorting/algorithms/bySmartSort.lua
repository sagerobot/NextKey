local _, NextKey222 = ...

-- MARK: Smart Sort
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
        description = "Balanced ranking using Borda count: 40% IO gain, 30% player coverage, 20% key level, 10% loot. May produce similar results to other algorithms when party composition is balanced.",
        priority = 100, -- Highest priority (default algorithm)
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Bronze",
        showIOTooltips = true -- Show IO gain tooltips for this algorithm
    },
    function(a, b)
        -- Smart Sort uses a Borda count ranking system
        -- Each keystone is scored across multiple criteria and ranked
        -- The keystone with the highest total score wins
        
        local function calculateSmartScore(entry)
            local score = 0
            local ioComponent = 0
            local coverageComponent = 0
            local levelComponent = 0
            local lootComponent = 0
            
            -- Criterion 1: IO Gain Potential (weight: 40%)
            -- Calculate from player breakdown
            if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
                local totalIO = 0
                for playerName, playerData in pairs(entry.ioGainRange.playerBreakdown) do
                    totalIO = totalIO + (playerData.expected or 0)
                end
                ioComponent = totalIO * 0.4
                score = score + ioComponent
            end
            
            -- Criterion 2: Player Coverage (weight: 30%)
            -- Number of players who benefit from this key
            if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
                local playerCount = 0
                for playerName, playerData in pairs(entry.ioGainRange.playerBreakdown) do
                    if (playerData.expected or 0) > 0 then
                        playerCount = playerCount + 1
                    end
                end
                coverageComponent = playerCount * 10 * 0.3
                score = score + coverageComponent
            end
            
            -- Criterion 3: Key Level (weight: 20%)
            -- Higher keys are slightly preferred for challenge
            if entry.key and entry.key.level then
                levelComponent = entry.key.level * 2 * 0.2
                score = score + levelComponent
            end
            
            -- Criterion 4: Loot Targeting (weight: 10%)
            -- Dungeons with tracked loot items get a bonus
            if entry.hasTrackedLoot then
                lootComponent = 50 * 0.1
                score = score + lootComponent
            end
            
            return score, ioComponent, coverageComponent, levelComponent, lootComponent
        end
        
        -- Calculate scores and sort descending (highest score first)
        local aScore, aIO, aCoverage, aLevel, aLoot = calculateSmartScore(a)
        local bScore, bIO, bCoverage, bLevel, bLoot = calculateSmartScore(b)
        
        -- Debug logging (only in dev mode)
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("sorting", string.format(
                "[SmartSort] %s +%d vs %s +%d -> Score: %.1f (IO:%.1f Cov:%.1f Lvl:%.1f Loot:%.1f) vs %.1f (IO:%.1f Cov:%.1f Lvl:%.1f Loot:%.1f)",
                (a.key and a.key.ownerName) or "?",
                (a.key and a.key.level) or 0,
                (b.key and b.key.ownerName) or "?",
                (b.key and b.key.level) or 0,
                aScore, aIO, aCoverage, aLevel, aLoot,
                bScore, bIO, bCoverage, bLevel, bLoot
            ))
        end
        
        return aScore > bScore
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: SmartSort (Borda count)")
end