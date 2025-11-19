-- MARK: Module Definition
local _, NextKey222 = ...

local TimeUtils = {}
NextKey222.TimeUtils = TimeUtils
NextKey222.RegisterModule("TimeUtils", TimeUtils)

-- MARK: Time Utils

--- Gets current server time with fallbacks
-- @return number Current server timestamp or local time
function TimeUtils.currentTime()
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

-- MARK: Module Interface

function TimeUtils:Initialize()
    return true
end

function TimeUtils:GetTime()
    return self.currentTime()
end

return TimeUtils