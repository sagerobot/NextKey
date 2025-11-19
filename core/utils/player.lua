-- MARK: Module Definition
local _, NextKey222 = ...

local PlayerUtils = {}
NextKey222.PlayerUtils = PlayerUtils
NextKey222.RegisterModule("PlayerUtils", PlayerUtils)

-- MARK: Player Utils

--- Safely gets class token for a unit
-- @param unit string Unit identifier (e.g., "player", "party1")
-- @return string Class token or empty string
function PlayerUtils.safeGetClass(unit)
    if type(UnitClass) ~= "function" then
        return ""
    end
    local _, class = UnitClass(unit)
    return class or ""
end

--- Safely gets player name with realm
-- @param unit string Unit identifier
-- @return string Player name-realm or "Unknown"
function PlayerUtils.safeGetName(unit)
    if type(UnitFullName) == "function" then
        local name, realm = UnitFullName(unit)
        if name and name ~= "" then
            if realm and realm ~= "" then
                return string.format("%s-%s", name, realm)
            end
            return name
        end
    end
    if type(UnitName) == "function" then
        local name = UnitName(unit)
        if name and name ~= "" then
            return name
        end
    end
    return unit or "Unknown"
end

--- Gets short name without realm suffix
-- @param fullName string Full player name with realm
-- @return string Short name without realm
function PlayerUtils.getShortName(fullName)
    if not fullName or fullName == "" then
        return "Unknown"
    end
    return fullName:match("^([^%-]+)") or fullName
end

-- MARK: Module Interface

function PlayerUtils:Initialize()
    return true
end

return PlayerUtils