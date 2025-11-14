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
        description = "Ensure the most players benefit from IO gains (fairness-focused)",
        priority = 85,
        icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend"
    },
    function(a, b)
        -- Max Player Coverage prioritizes keystones that benefit the most players
        -- Even if total IO is lower, we want more people to get upgrades
        
        local function countPlayersBenefiting(entry)
            -- If we have playersBenefiting already calculated, use it
            if entry.playersBenefiting then
                return entry.playersBenefiting
            end
            
            -- Otherwise, count from ioGainRange player breakdown
            if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
                local count = 0
                for _, playerData in pairs(entry.ioGainRange.playerBreakdown) do
                    if playerData.expected and playerData.expected > 0 then
                        count = count + 1
                    end
                end
                return count
            end
            
            return 0
        end
        
        local aPlayers = countPlayersBenefiting(a)
        local bPlayers = countPlayersBenefiting(b)
        
        -- Primary: Sort by player count (more players = better)
        if aPlayers ~= bPlayers then
            return aPlayers > bPlayers
        end
        
        -- Tiebreaker: Use total IO gain
        local aGain = a.ioGainPotential or 0
        local bGain = b.ioGainPotential or 0
        
        return aGain > bGain
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: MaxPlayerCoverage")
end