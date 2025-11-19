-- MARK: Module Definition
local _, NextKey222 = ...

--- FrameRegistry Module
--- Centralized frame tracking and cleanup system
--- Replaces the trackAuxFrame(self, frame) pattern used throughout UI code
local FrameRegistry = {}
NextKey222.FrameRegistry = FrameRegistry

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("FrameRegistry", FrameRegistry)

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Module-local State
local _auxFrames = {}

-- MARK: Public Interface

--- Tracks a frame for later cleanup
--- @param frame table Frame to track
function FrameRegistry:Track(frame)
    if not frame then 
        Debug:Dev("frameregistry", "Attempted to track nil frame, ignoring")
        return 
    end
    
    table.insert(_auxFrames, frame)
    Debug:Trace("frameregistry", "Tracked frame:", frame:GetName() or "unnamed", "Total tracked:", #_auxFrames)
end

--- Clears all tracked frames
--- Hides and unparents all tracked frames, then clears the tracking list
function FrameRegistry:ClearAll()
    local clearedCount = 0
    
    for _, frame in ipairs(_auxFrames) do
        if frame and frame.Hide then
            frame:Hide()
            frame:SetParent(nil)
            clearedCount = clearedCount + 1
        end
    end
    
    wipe(_auxFrames)
    Debug:Dev("frameregistry", "Cleared", clearedCount, "tracked frames")
end

--- Gets the count of currently tracked frames
--- @return number Count of tracked frames
function FrameRegistry:GetTrackedCount()
    return #_auxFrames
end

-- MARK: Initialization

--- Initializes the FrameRegistry module
--- @return boolean true if initialization succeeded
function FrameRegistry:Initialize()
    Debug:Dev("frameregistry", "FrameRegistry initialized")
    return true
end

return FrameRegistry