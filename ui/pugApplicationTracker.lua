--[[
NextKey PUG Application Tracker
Shows a small window with active LFG applications

This UI component displays active LFG applications with:
- Dungeon alias name
- Key level
- Group leader name
- Application status (pending/invited/declined)
- Time applied

Author: NextKey Team
Version: 0.2.0.1
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGApplicationTracker = {}
NextKey222.PUGApplicationTracker = PUGApplicationTracker

-- MARK: Dependencies
local Debug = NextKey222.Debug
local Constants = NextKey222.Constants
local Utils = NextKey222.Utils

-- MARK: Constants
PUGApplicationTracker.TRACKER_CONFIG = {
    width = 320,
    height = 180,
    max_entries = 8,
    auto_hide_delay = 2, -- seconds after last application resolved
    refresh_interval = 1, -- seconds
    row_height = 20,
    header_height = 25,
    footer_height = 25
}

-- Application status colors
local STATUS_COLORS = {
    pending = { r = 1.0, g = 0.8, b = 0.0 },  -- Yellow
    invited = { r = 0.0, g = 1.0, b = 0.4 },  -- Green
    declined = { r = 1.0, g = 0.2, b = 0.2 },  -- Red
    cancelled = { r = 0.7, g = 0.7, b = 0.7 }, -- Gray
    failed = { r = 0.8, g = 0.4, b = 0.0 }    -- Orange
}

-- MARK: Private Variables
local frame = nil
local applicationEntries = {}
local lastUpdate = 0
local autoHideTimer = nil
local isVisible = false
local trackerConfig = {
    enabled = false,
    autoShow = true,
    position = "center"
}

-- MARK: Module Registration
NextKey222.RegisterModule("PUGApplicationTracker", PUGApplicationTracker)

-- MARK: Public Interface

-- Initialize the application tracker module
function PUGApplicationTracker:Initialize()
    Debug:Dev("pughelper", "PUGApplicationTracker:Initialize() called")
    
    -- Create the UI frame
    self:CreateFrame()
    
    -- Load configuration
    self:LoadConfig()
    
    -- DEBUG: Log initialization status
    Debug:User("PUG Application Tracker initialized - Enabled: " .. (trackerConfig.enabled and "YES" or "NO"))
    Debug:User("PUG Application Tracker config - Auto Show: " .. (trackerConfig.autoShow and "YES" or "NO"))
    Debug:User("PUG Application Tracker frame created: " .. (frame and "YES" or "NO"))
    
    return true
end

-- Show the application tracker
function PUGApplicationTracker:Show()
    Debug:User("PUG Application Tracker: Show() called")
    
    if not frame then
        Debug:Error("PUG Application Tracker: Cannot show tracker: frame not created")
        return
    end
    
    if not trackerConfig.enabled then
        Debug:User("PUG Application Tracker: Cannot show - tracker is disabled")
        return
    end
    
    Debug:User("PUG Application Tracker: Showing tracker window")
    
    isVisible = true
    frame.frame:Show()
    
    -- Update the display
    self:UpdateDisplay()
    
    -- Start refresh timer
    self:StartRefreshTimer()
end

-- Hide the application tracker
function PUGApplicationTracker:Hide()
    if frame then
        frame.frame:Hide()
    end
    
    isVisible = false
    
    -- Stop refresh timer
    self:StopRefreshTimer()
    
    -- Clear auto-hide timer
    if autoHideTimer then
        autoHideTimer:Cancel()
        autoHideTimer = nil
    end
    
    Debug:Dev("pughelper", "Application tracker hidden")
end

-- Toggle the application tracker
function PUGApplicationTracker:Toggle()
    if isVisible then
        self:Hide()
    else
        self:Show()
    end
end

-- Check if tracker is enabled
function PUGApplicationTracker:IsEnabled()
    return trackerConfig.enabled
end

-- Enable/disable the tracker
function PUGApplicationTracker:SetEnabled(enabled)
    trackerConfig.enabled = enabled
    
    if not enabled then
        self:Hide()
    end
    
    Debug:Dev("pughelper", "Application tracker " .. (enabled and "enabled" or "disabled"))
end

-- Configure tracker settings
function PUGApplicationTracker:Configure(settings)
    for key, value in pairs(settings) do
        if trackerConfig[key] ~= nil then
            trackerConfig[key] = value
            Debug:Dev("pughelper", "Tracker config updated: " .. key .. " = " .. tostring(value))
        end
    end
end

-- Get current configuration
function PUGApplicationTracker:GetConfig()
    local configCopy = {}
    for key, value in pairs(trackerConfig) do
        configCopy[key] = value
    end
    return configCopy
end

-- Auto-show tracker if there are active applications
function PUGApplicationTracker:AutoShowIfNeeded()
    Debug:User("PUG Application Tracker: AutoShowIfNeeded called")
    Debug:User("PUG Application Tracker: Enabled: " .. (trackerConfig.enabled and "YES" or "NO"))
    Debug:User("PUG Application Tracker: Auto Show: " .. (trackerConfig.autoShow and "YES" or "NO"))
    Debug:User("PUG Application Tracker: Currently visible: " .. (isVisible and "YES" or "NO"))
    
    if not trackerConfig.enabled then
        Debug:User("PUG Application Tracker: Not enabled - skipping auto-show")
        return
    end
    
    if not trackerConfig.autoShow then
        Debug:User("PUG Application Tracker: Auto-show disabled - skipping")
        return
    end
    
    local activeApplications = self:GetActiveApplications()
    Debug:User("PUG Application Tracker: Found " .. #activeApplications .. " active applications")
    
    if #activeApplications > 0 and not isVisible then
        Debug:User("PUG Application Tracker: Auto-showing tracker with " .. #activeApplications .. " active applications")
        self:Show()
    elseif #activeApplications == 0 and isVisible then
        Debug:User("PUG Application Tracker: Starting auto-hide timer (no active applications)")
        -- Start auto-hide timer
        self:StartAutoHideTimer()
    else
        Debug:User("PUG Application Tracker: No action needed - Apps: " .. #activeApplications .. ", Visible: " .. (isVisible and "YES" or "NO"))
    end
end

-- MARK: Private Implementation

-- Load configuration from saved variables
function PUGApplicationTracker:LoadConfig()
    local db = NextKey222.Addon and NextKey222.Addon.db
    if not db then
        Debug:Dev("pughelper", "Database not available, using default tracker config")
        return
    end
    
    local savedConfig = db.global and db.global.pugApplicationTracker
    
    if savedConfig then
        for key, value in pairs(savedConfig) do
            if trackerConfig[key] ~= nil then
                trackerConfig[key] = value
                Debug:Dev("pughelper", "Loaded tracker config - " .. key .. " = " .. tostring(value))
            end
        end
    end
    
    -- DEBUG: Force enable for testing if disabled
    if not trackerConfig.enabled then
        Debug:User("PUG Application Tracker: Force-enabling for testing (was disabled)")
        trackerConfig.enabled = true
    end
    
    Debug:User("PUG Application Tracker: Final config - Enabled: " .. (trackerConfig.enabled and "YES" or "NO") ..
               ", Auto Show: " .. (trackerConfig.autoShow and "YES" or "NO"))
    Debug:Dev("pughelper", "Application tracker configuration loaded")
end

-- Save configuration to saved variables
function PUGApplicationTracker:SaveConfig()
    local db = NextKey222.Addon and NextKey222.Addon.db
    if not db then
        Debug:Dev("pughelper", "Database not available, cannot save tracker config")
        return
    end
    
    if not db.global.pugApplicationTracker then
        db.global.pugApplicationTracker = {}
    end
    
    for key, value in pairs(trackerConfig) do
        db.global.pugApplicationTracker[key] = value
    end
    
    Debug:Dev("pughelper", "Application tracker configuration saved")
end

-- Create the UI frame using AceGUI and configuration wrappers
function PUGApplicationTracker:CreateFrame()
    if frame then
        return
    end
    
    local config = self.TRACKER_CONFIG
    
    -- Use UIComponents factory to create standardized dialog frame
    frame = NextKey222.UIComponents:CreateFrame("dialog", UIParent, {
        width = config.width,
        height = config.height,
        backdropType = "dark_dialog",
        colorScheme = "dark"
    })
    
    -- Set frame properties for proper layering
    frame.frame:SetFrameStrata("DIALOG")
    frame.frame:SetFrameLevel(90)
    
    -- Position based on configuration
    self:PositionFrame()
    
    -- Make it movable using AceGUI frame
    frame.frame:SetMovable(true)
    frame.frame:RegisterForDrag("LeftButton")
    frame.frame:SetScript("OnDragStart", frame.frame.StartMoving)
    frame.frame:SetScript("OnDragStop", frame.frame.StopMovingOrSizing)
    
    Debug:Dev("pughelper", "PUG application tracker frame created with AceGUI and configuration wrappers")
    
    -- Create title using UIComponents factory
    local title = NextKey222.UIComponents:CreateText("header", nil, {
        text = "NextKey - Applications (0)",
        width = config.width - 16
    })
    title.frame:SetPoint("TOP", frame.frame, "TOP", 0, -8)
    frame.title = title
    
    -- Create scroll frame using UIComponents factory
    Debug:Dev("pughelper", "Creating PUG Application Tracker scroll frame")
    local scrollFrame = NextKey222.UIComponents:CreateScrollFrame("primary", nil, {
        width = config.width - 36,
        height = config.height - 65, -- Account for title and margins
        layout = "List"
    })
    
    -- CRITICAL: Ensure scroll frame is hidden during initialization
    if scrollFrame and scrollFrame.frame then
        Debug:Dev("pughelper", "PUG Tracker scrollFrame created - forcing HIDDEN during init")
        scrollFrame.frame:Hide()
    end
    
    scrollFrame.frame:SetPoint("TOP", title.frame, "BOTTOM", 0, -8)
    scrollFrame.frame:SetPoint("LEFT", frame.frame, "LEFT", 8, 0)
    scrollFrame.frame:SetPoint("RIGHT", frame.frame, "RIGHT", -28, 0)
    scrollFrame.frame:SetPoint("BOTTOM", frame.frame, "BOTTOM", 0, 8)
    frame.scrollFrame = scrollFrame
    
    -- Create content container for scrollable content
    local content = NextKey222.UIComponents:CreateFrame("container", scrollFrame.frame, {
        width = config.width - 36,
        layout = "List"
    })
    scrollFrame:AddChild(content)
    frame.content = content
    
    -- Initialize application entries array (will be created dynamically)
    applicationEntries = {}
    
    -- Create close button using native close button (still needed for X button)
    local closeButton = CreateFrame("Button", nil, frame.frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame.frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        self:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Hide initially
    frame.frame:Hide()
    
    Debug:Dev("pughelper", "Application tracker frame created with pure AceGUI components")
end

-- Position the frame based on configuration
function PUGApplicationTracker:PositionFrame()
    if not frame then
        return
    end
    
    local positions = {
        center = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
        topright = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -50, y = -50 },
        topleft = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 50, y = -50 },
        bottomright = { point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -50, y = 50 },
        bottomleft = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 50, y = 50 }
    }
    
    local pos = positions[trackerConfig.position] or positions.center
    frame.frame:ClearAllPoints()
    frame.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
end

-- Create an application entry row using AceGUI widgets
function PUGApplicationTracker:CreateApplicationEntry(parent, index)
    -- Create container for the entry
    local entry = NextKey222.UIComponents:CreateFrame("container", parent.frame, {
        width = parent.frame:GetWidth(),
        height = self.TRACKER_CONFIG.row_height,
        layout = "Flow"
    })
    
    -- Configure backdrop for hover effects
    NextKey222.UIComponents:ConfigureBackdrop(entry, "compact", {
        colorScheme = "transparent"
    })
    
    -- Dungeon alias (left)
    local dungeonText = NextKey222.UIComponents:CreateText("small", nil, {
        width = 80,
        justifyH = "LEFT"
    })
    entry:AddChild(dungeonText)
    entry.dungeonText = dungeonText
    
    -- Key level
    local keyLevelText = NextKey222.UIComponents:CreateText("small", nil, {
        width = 40,
        justifyH = "CENTER"
    })
    entry:AddChild(keyLevelText)
    entry.keyLevelText = keyLevelText
    
    -- Leader name
    local leaderText = NextKey222.UIComponents:CreateText("small", nil, {
        width = 80,
        justifyH = "LEFT"
    })
    entry:AddChild(leaderText)
    entry.leaderText = leaderText
    
    -- Status
    local statusText = NextKey222.UIComponents:CreateText("small", nil, {
        width = 60,
        justifyH = "CENTER"
    })
    entry:AddChild(statusText)
    entry.statusText = statusText
    
    -- Time applied
    local timeText = NextKey222.UIComponents:CreateText("small", nil, {
        width = 50,
        justifyH = "RIGHT"
    })
    entry:AddChild(timeText)
    entry.timeText = timeText
    
    -- Entry background hover effect
    entry.frame:SetScript("OnEnter", function()
        NextKey222.UIComponents:ConfigureBackdrop(entry, "compact", {
            colorScheme = "light"
        })
    end)
    
    entry.frame:SetScript("OnLeave", function()
        NextKey222.UIComponents:ConfigureBackdrop(entry, "compact", {
            colorScheme = "transparent"
        })
    end)
    
    return entry
end

-- Get active applications from PUG Helper
function PUGApplicationTracker:GetActiveApplications()
    if not NextKey222.PUGHelper then
        return {}
    end
    
    -- Use the new method from PUG Helper to get applications as array
    return NextKey222.PUGHelper:GetApplicationsAsArray() or {}
end

-- Update the display with current applications
function PUGApplicationTracker:UpdateDisplay()
    if not frame or not isVisible then
        return
    end
    
    local applications = self:GetActiveApplications()
    local config = self.TRACKER_CONFIG
    
    -- Update title
    frame.title:SetText("NextKey - Applications (" .. #applications .. ")")
    
    -- Clear existing content children
    frame.content:ReleaseChildren()
    
    -- Update content frame height
    local contentHeight = math.max(#applications * config.row_height, config.row_height)
    frame.content.frame:SetHeight(contentHeight)
    
    -- Update application entries (create new ones as needed)
    for i = 1, #applications do
        local app = applications[i]
        local entry
        
        -- Create new entry if needed
        if i > #applicationEntries then
            entry = self:CreateApplicationEntry(frame.content, i)
            table.insert(applicationEntries, entry)
            frame.content:AddChild(entry)
        else
            entry = applicationEntries[i]
        end
        
        -- Update entry with application data
        self:UpdateApplicationEntry(entry, app)
        entry.frame:Show()
    end
    
    -- Hide excess entries
    for i = #applications + 1, #applicationEntries do
        applicationEntries[i].frame:Hide()
    end
    
    -- Update scroll range (AceGUI handles this automatically)
    -- frame.scrollFrame:UpdateScrollChildRect() -- Not needed with AceGUI
    
    Debug:Dev("pughelper", "Application tracker updated with " .. #applications .. " entries")
end

-- Update a single application entry
function PUGApplicationTracker:UpdateApplicationEntry(entry, app)
    if not entry or not app then
        return
    end
    
    -- Get dungeon information
    local dungeonInfo = NextKey222.PUGHelper:GetDungeonInfo(app.dungeonID)
    local dungeonAlias = dungeonInfo and dungeonInfo.alias or "Unknown"
    
    -- Update dungeon text
    entry.dungeonText:SetText(dungeonAlias)
    
    -- Update key level text
    local keyText = "+"
    if app.keyLevel and app.keyLevel > 0 then
        keyText = keyText .. app.keyLevel
    else
        keyText = keyText .. "?"
    end
    entry.keyLevelText:SetText(keyText)
    
    -- Update leader text (truncate if too long)
    local leaderName = app.leader or "Unknown"
    if string.len(leaderName) > 12 then
        leaderName = string.sub(leaderName, 1, 10) .. ".."
    end
    entry.leaderText:SetText(leaderName)
    
    -- Update status text
    local status = app.status or "pending"
    local statusDisplay = self:FormatStatus(status)
    entry.statusText:SetText(statusDisplay)
    
    -- Set status color
    local color = STATUS_COLORS[status] or STATUS_COLORS.pending
    entry.statusText:SetTextColor(color.r, color.g, color.b)
    
    -- Update time text
    local timeText = self:FormatTimeApplied(app.appliedAt or time())
    entry.timeText:SetText(timeText)
end

-- Format status for display
function PUGApplicationTracker:FormatStatus(status)
    local statusMap = {
        pending = "Pending",
        invited = "Invited",
        declined = "Declined",
        cancelled = "Cancelled",
        failed = "Failed"
    }
    return statusMap[status] or "Unknown"
end

-- Format time applied for display
function PUGApplicationTracker:FormatTimeApplied(appliedAt)
    local now = time()
    local elapsed = now - appliedAt
    
    if elapsed < 60 then
        return tostring(elapsed) .. "s"
    elseif elapsed < 3600 then
        return tostring(math.floor(elapsed / 60)) .. "m"
    else
        return tostring(math.floor(elapsed / 3600)) .. "h"
    end
end

-- Start the refresh timer
function PUGApplicationTracker:StartRefreshTimer()
    self:StopRefreshTimer()
    
    local config = self.TRACKER_CONFIG
    C_Timer.NewTimer(config.refresh_interval, function()
        if isVisible then
            self:UpdateDisplay()
            self:StartRefreshTimer() -- Restart timer
        end
    end)
end

-- Stop the refresh timer
function PUGApplicationTracker:StopRefreshTimer()
    -- Timer is handled by C_Timer.NewTimer, so we don't need to store it
    -- The timer will automatically stop when isVisible is false
end

-- Start the auto-hide timer
function PUGApplicationTracker:StartAutoHideTimer()
    if autoHideTimer then
        autoHideTimer:Cancel()
    end
    
    autoHideTimer = C_Timer.NewTimer(self.TRACKER_CONFIG.auto_hide_delay, function()
        local applications = self:GetActiveApplications()
        if #applications == 0 then
            Debug:Dev("pughelper", "Auto-hiding tracker (no active applications)")
            self:Hide()
        end
        autoHideTimer = nil
    end)
end

-- MARK: Cleanup
function PUGApplicationTracker:Cleanup()
    Debug:Dev("pughelper", "PUGApplicationTracker cleanup called")
    
    -- Save configuration
    self:SaveConfig()
    
    -- Hide the frame
    self:Hide()
    
    -- Clear timers
    if autoHideTimer then
        autoHideTimer:Cancel()
        autoHideTimer = nil
    end
end

return PUGApplicationTracker