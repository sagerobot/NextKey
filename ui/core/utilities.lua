local _, NextKey222 = ...

-- MARK: Module Definition
local Utilities = {}
NextKey222.Utilities = Utilities
NextKey222.RegisterModule("Utilities", Utilities)

--- Tracks auxiliary frames for cleanup (delegates to FrameRegistry)
--- This is a compatibility wrapper - new code should use FrameRegistry directly
--- @param frame table Frame to track
function Utilities:TrackAuxFrame(frame)
    if NextKey222.FrameRegistry then
        NextKey222.FrameRegistry:Track(frame)
    else
        -- Fallback to old behavior if FrameRegistry not loaded
        Debug:Error("FrameRegistry not available - frame tracking may fail")
    end
end

--- Add dark background overlay to frame content
--- @param frame table Frame to darken
function Utilities:DarkenContent(frame)
    if not frame or frame._nkDarkened then return end
    local bg = frame.content:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.55)
    bg:SetAllPoints(frame.content)
    frame._nkDarkened = true
end

--- Determines if compact mode should be used based on player count
--- @param playerCount number The total number of players/entries
--- @return boolean true if compact mode should be enabled
function Utilities:ShouldUseCompactMode(playerCount)
    return playerCount > 5
end

--- Gets the dungeon alias for compact display
--- @param dungeonID number The dungeon ID
--- @return string The short alias for the dungeon
function Utilities:GetDungeonAlias(dungeonID)
    local NextKey = NextKey222.Addon
    if NextKey and NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[dungeonID] then
        return NextKey.PortalData.dungeons[dungeonID].alias
    end
    return "UNK"
end

--- Helper to count table entries
--- @param t table The table to count
--- @return number Entry count
function Utilities:CountTable(t)
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

--- Module initialization
--- @return boolean true if initialization succeeded
function Utilities:Initialize()
    Debug:Dev("utilities", "Utilities module initialized")
    return true
end

return Utilities