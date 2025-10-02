local _, NextKey222 = ...

-- MARK: Utility Functions
local Utils = {}
NextKey222.Utils = Utils
NextKey222.RegisterModule("Utils", Utils)

function Utils.currentTime()
    if type(GetServerTime) == "function" then
        local ok, value = pcall(GetServerTime)
        if ok and type(value) == "number" then
            return value
        end
    end
    if type(time) == "function" then
        return time()
    end
    return 0
end

function Utils.normalizeMapID(mapID)
    local asNumber = tonumber(mapID)
    return asNumber or mapID
end

function Utils.safeGetClass(unit)
    if type(UnitClass) ~= "function" then
        return ""
    end
    local _, class = UnitClass(unit)
    return class or ""
end

function Utils.safeGetName(unit)
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

function Utils.encodeTuple(parts)
    for index, value in ipairs(parts) do
        parts[index] = tostring(value or "")
    end
    return table.concat(parts, "|")
end

function Utils.decodeTuple(message)
    if type(message) ~= "string" or message == "" then
        return {}
    end
    local fields, index = {}, 1
    for field in message:gmatch("([^|]*)") do
        fields[index] = field
        index = index + 1
    end
    return fields
end

function Utils.chooseCommChannel()
    if type(IsInGroup) == "function" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        if type(IsInRaid) == "function" and IsInRaid() then
            return "RAID"
        end
        if IsInGroup() then
            return "PARTY"
        end
    end
    return nil
end

function Utils.getShortName(fullName)
    if not fullName or fullName == "" then
        return "Unknown"
    end
    return fullName:match("^([^%-]+)") or fullName
end

function Utils.tableCount(tbl)
    if not tbl or type(tbl) ~= "table" then
        return 0
    end
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Module interface
function Utils:Initialize()
    return true
end

function Utils:GetTime()
    return self.currentTime()
end

return Utils