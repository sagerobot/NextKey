-- MARK: Module Definition
local _, NextKey222 = ...

local ScoringUtils = {}
NextKey222.ScoringUtils = ScoringUtils
NextKey222.RegisterModule("ScoringUtils", ScoringUtils)

-- MARK: IO Score Color Helper

--- Gets universal IO score color used consistently across the addon
--- Uses Blizzard API as primary, RaiderIO as fallback (same as main UI)
---@param score number The IO score to get color for
---@return number, number, number RGB color values (0-1)
function ScoringUtils:GetIOScoreColor(score)
    local r, g, b = 1, 1, 1
    
    -- Prefer Blizzard's official score color if available (same as main UI)
    if C_ChallengeMode and C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor then
        local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(score or 0)
        if color then
            r, g, b = color.r or r, color.g or g, color.b or b
        end
    end
    
    -- Fallback to RaiderIO gradient if Blizzard color unavailable (same as main UI)
    if (r == 1 and g == 1 and b == 1) and NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
        local rioR, rioG, rioB = NextKey222.RaiderIO:GetScoreColor(score or 0)
        if rioR and rioG and rioB then
            r, g, b = rioR, rioG, rioB
        end
    end
    
    return r, g, b
end

-- MARK: Module Interface

function ScoringUtils:Initialize()
    return true
end

return ScoringUtils