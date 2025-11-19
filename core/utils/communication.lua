-- MARK: Module Definition
local _, NextKey222 = ...

local CommunicationUtils = {}
NextKey222.CommunicationUtils = CommunicationUtils
NextKey222.RegisterModule("CommunicationUtils", CommunicationUtils)

-- MARK: Comm Utils

--- Encodes array of values into pipe-delimited string
-- @param parts table Array of values to encode
-- @return string Encoded tuple string
function CommunicationUtils.encodeTuple(parts)
    for index, value in ipairs(parts) do
        parts[index] = tostring(value or "")
    end
    return table.concat(parts, "|")
end

--- Decodes pipe-delimited string into array
-- @param message string Encoded tuple string
-- @return table Array of decoded values
function CommunicationUtils.decodeTuple(message)
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

--- Determines appropriate communication channel based on group type
-- @return string|nil Communication channel ("INSTANCE_CHAT", "RAID", "PARTY", or nil)
function CommunicationUtils.chooseCommChannel()
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

-- MARK: Module Interface

function CommunicationUtils:Initialize()
    return true
end

return CommunicationUtils