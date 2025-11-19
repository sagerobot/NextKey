local _, NextKey222 = ...

-- MARK: Max Group IO
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
        description = "Maximize total IO gain for entire party. Differs from Smart Sort when one player can gain significantly more IO than others (e.g., one undergeared player).",
        priority = 90,
        icon = "Interface\\Icons\\Achievement_Dungeon_Mythic_All",
        showIOTooltips = true -- Show IO gain tooltips for this algorithm
    },
    function(a, b)
        -- Max Group IO prioritizes keystones that give the highest total IO gain
        -- across all party members (sum of all individual gains)
        
        local function calculateTotalGroupIO(entry)
            if not entry.ioGainRange or not entry.ioGainRange.playerBreakdown then
                return 0
            end
            
            -- Sum expected IO gain across ALL players
            local total = 0
            for playerName, playerData in pairs(entry.ioGainRange.playerBreakdown) do
                local expectedGain = playerData.expected or 0
                total = total + expectedGain
            end
            
            return total
        end
        
        local aGain = calculateTotalGroupIO(a)
        local bGain = calculateTotalGroupIO(b)
        
        -- Debug logging (only in dev mode)
        if NextKey222.Debug and NextKey222.Debug.Dev then
            NextKey222.Debug:Dev("sorting", string.format(
                "[MaxGroupIO] %s +%d vs %s +%d -> Score: %.1f vs %.1f",
                (a.key and a.key.ownerName) or "?",
                (a.key and a.key.level) or 0,
                (b.key and b.key.ownerName) or "?",
                (b.key and b.key.level) or 0,
                aGain,
                bGain
            ))
        end
        
        -- Sort descending (highest group IO gain first)
        return aGain > bGain
    end
)

if NextKey222.Debug then
    NextKey222.Debug:Dev("sorting", "Registered algorithm: MaxGroupIO")
end