local _, NextKey222 = ...

-- MARK: Player Coverage Algorithm
-- Maximizes the number of players who benefit from IO gains

local Sorting = NextKey222.Sorting
local UI = NextKey222.UI

if not Sorting then
    error("Sorting service not available - check load order")
end

-- Register algorithm
Sorting:RegisterAlgorithm(
    "MaxPlayerCoverage",
    {
        displayName = "Max Player Coverage",
        contexts = { Sorting.contexts.KEYSTONES },
        description = "Ensure most players benefit from IO gains (fairness-focused). Differs from Max Group IO when choosing between 'many small gains' vs 'few large gains'.",
        priority = 85,
        icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
        showIOTooltips = true -- Show IO gain tooltips for this algorithm
    },
    function(a, b)
        -- Max Player Coverage prioritizes keystones that benefit the most players
        -- Even if total IO is lower, we want more people to get upgrades
        
        local function calculateCoverageScore(entry)
            if not entry.ioGainRange or not entry.ioGainRange.playerBreakdown then
                return 0, 0, 0  -- Return score, playerCount, totalGain for debugging
            end
            
            local playerCount = 0
            local totalGain = 0
            local fairnessBonus = 0
            
            -- Count players benefiting and calculate fairness metric
            for playerName, playerData in pairs(entry.ioGainRange.playerBreakdown) do
                local expectedGain = playerData.expected or 0
                if expectedGain > 0 then
                    playerCount = playerCount + 1
                    totalGain = totalGain + expectedGain
                    
                    -- Award fairness bonus for balanced gains (10-30 IO per player is ideal)
                    if expectedGain >= 10 and expectedGain <= 30 then
                        fairnessBonus = fairnessBonus + 20
                    end
                end
            end
            
            -- Score formula: Player count is most important, then total gain, then fairness
            -- This ensures keys that benefit more players rank higher
            local score = (playerCount * 1000) + totalGain + fairnessBonus
            
            return score, playerCount, totalGain
        end
        
        local aScore, aPlayers, aTotalIO = calculateCoverageScore(a)
        local bScore, bPlayers, bTotalIO = calculateCoverageScore(b)
        
        -- Debug logging (only in dev mode)
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("sorting", string.format(
                "[PlayerCoverage] %s +%d vs %s +%d -> Score: %.1f (%d players, %.1f IO) vs %.1f (%d players, %.1f IO)",
                (a.key and a.key.ownerName) or "?",
                (a.key and a.key.level) or 0,
                (b.key and b.key.ownerName) or "?",
                (b.key and b.key.level) or 0,
                aScore, aPlayers, aTotalIO,
                bScore, bPlayers, bTotalIO
            ))
        end
        
        -- Sort descending (higher coverage score first)
        return aScore > bScore
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: MaxPlayerCoverage")
end