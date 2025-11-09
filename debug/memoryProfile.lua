-- Memory Profiling Tool for NextKey
-- Helps identify memory leaks during development

local _, NextKey222 = ...

local MemoryProfile = {}
NextKey222.MemoryProfile = MemoryProfile

-- Track memory snapshots
local snapshots = {}
local snapshotIndex = 0

--- Takes a memory snapshot
function MemoryProfile:TakeSnapshot(label)
    collectgarbage("collect")
    collectgarbage("collect") -- Call twice for thorough collection
    
    snapshotIndex = snapshotIndex + 1
    local kb = collectgarbage("count")
    
    snapshots[snapshotIndex] = {
        index = snapshotIndex,
        label = label or ("Snapshot " .. snapshotIndex),
        kb = kb,
        timestamp = GetTime()
    }
    
    print(string.format("[Memory] %s: %.2f MB", snapshots[snapshotIndex].label, kb / 1024))
    
    return snapshotIndex
end

--- Compares two snapshots
function MemoryProfile:Compare(index1, index2)
    local snap1 = snapshots[index1 or (snapshotIndex - 1)]
    local snap2 = snapshots[index2 or snapshotIndex]
    
    if not snap1 or not snap2 then
        print("[Memory] Invalid snapshot indices")
        return
    end
    
    local diff = snap2.kb - snap1.kb
    local timeDiff = snap2.timestamp - snap1.timestamp
    
    print(string.format("[Memory] %s -> %s:", snap1.label, snap2.label))
    print(string.format("  Memory: %.2f MB -> %.2f MB", snap1.kb / 1024, snap2.kb / 1024))
    print(string.format("  Diff: %s%.2f MB (%.2f KB)", diff > 0 and "+" or "", diff / 1024, diff))
    print(string.format("  Time: %.2fs", timeDiff))
end

--- Shows all snapshots
function MemoryProfile:ShowAll()
    print("[Memory] All Snapshots:")
    for i, snap in ipairs(snapshots) do
        print(string.format("  [%d] %s: %.2f MB", snap.index, snap.label, snap.kb / 1024))
    end
end

--- Clears all snapshots
function MemoryProfile:Clear()
    snapshots = {}
    snapshotIndex = 0
    print("[Memory] Snapshots cleared")
end

-- Slash command
SLASH_NKMEMORY1 = "/nkmem"
SlashCmdList["NKMEMORY"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    
    if cmd == "snap" or cmd == "" then
        MemoryProfile:TakeSnapshot(arg ~= "" and arg or nil)
    elseif cmd == "compare" then
        local idx1, idx2 = arg:match("(%d+)%s*(%d*)")
        MemoryProfile:Compare(tonumber(idx1), tonumber(idx2))
    elseif cmd == "show" then
        MemoryProfile:ShowAll()
    elseif cmd == "clear" then
        MemoryProfile:Clear()
    else
        print("NextKey Memory Profiler")
        print("  /nkmem snap [label] - Take snapshot")
        print("  /nkmem compare [idx1] [idx2] - Compare snapshots")
        print("  /nkmem show - Show all snapshots")
        print("  /nkmem clear - Clear snapshots")
    end
end

return MemoryProfile