local _, NS = ...
local NextKey = NS.Addon
local Utils = NS.Utils
local Keystones = NS.Keystones

local Comms = {}

-- MARK: Message Serialization
local function serializeSyncPayload(key)
    if not key then
        return Utils.encodeTuple({ NS.COMM_OPCODE.SYNC })
    end
    return Utils.encodeTuple({
        NS.COMM_OPCODE.SYNC,
        key.dungeonID or "",
        key.level or "",
        key.ownerName or "",
        key.class or "",
        key.io or "",
    })
end

local function parseSyncPayload(parts)
    local mapID = tonumber(parts[2])
    local level = tonumber(parts[3])
    local owner = parts[4] ~= "" and parts[4] or nil
    local class = parts[5] ~= "" and parts[5] or nil
    local ioScore = tonumber(parts[6])
    if not mapID or not level then
        return nil
    end
    return {
        dungeonID = mapID,
        level = level,
        ownerName = owner,
        ownerShort = owner and owner:match("^[^%-]+") or owner,
        class = class,
        io = ioScore,
        source = "comm",
        timestamp = Utils.currentTime(),
    }
end

-- MARK: Communication Functions
function NextKey:BroadcastTeleportSelection(target)
    local data = target or self.teleportTargetKey
    if not data then
        return
    end

    local channel = Utils.chooseCommChannel()
    if not channel then
        return
    end

    local payload = Utils.encodeTuple({
        NS.COMM_OPCODE.SELECT,
        data.dungeonID or "",
        data.level or "",
        data.ownerName or "",
        data.class or "",
    })

    self:SendCommMessage(NS.COMM_PREFIX, payload, channel)
end

function NextKey:BuildSyncPayload()
    return self:ScanPlayerKeystone()
end

function NextKey:SendSync()
    local channel = Utils.chooseCommChannel()
    if not channel then
        self:Print("No group channel available for sync.")
        return
    end
    local key = self:BuildSyncPayload()
    local payload = serializeSyncPayload(key)
    self:SendCommMessage(NS.COMM_PREFIX, payload, channel)
    self:Print("Sync broadcast sent.")
end

-- MARK: Message Handling
function NextKey:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= NS.COMM_PREFIX then
        return
    end

    local parts = Utils.decodeTuple(message)
    local opcode = parts[1]

    if opcode == NS.COMM_OPCODE.SELECT then
        local mapID = tonumber(parts[2])
        local level = tonumber(parts[3])
        local owner = parts[4]
        local class = parts[5]
        if mapID and level then
            self:SetTeleportTargetKey({
                dungeonID = mapID,
                level = level,
                ownerName = owner,
                ownerShort = owner and owner:match("^[^%-]+") or owner,
                class = class,
                source = "comm",
            }, {
                broadcast = false,
                source = "comm",
                receivedFrom = sender,
            })
        end
    elseif opcode == NS.COMM_OPCODE.SYNC then
        local entry = parseSyncPayload(parts)
        if entry then
            entry.receivedFrom = sender
            self.receivedKeys = self.receivedKeys or {}
            self.receivedKeys[sender] = entry
            if type(self.RenderResults) == "function" then
                self:RenderResults()
            end
        end
    end
end

NS.Comms = Comms
return Comms