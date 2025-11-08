--[[
NextKey PUG Application Tracker (Debug UI)

GOAL:
- Debug-only native-frame UI to visualize tracked Mythic+ LFG applications.
- Tracking is ALWAYS handled by PUGHelper (core/pugHelper_applications.lua).
- This module is a thin, optional view over that data.

RULES:
- Only shows when:
  - NextKey debug is enabled (db.global.debug.enabled == true)
  - PUG Helper is enabled
  - There is at least one Mythic+ application
- No AceGUI usage. Pure native frames.
- No chat spam: only Dev-level logging in "pughelper" category.

This file DOES NOT own tracking. It only renders what PUGHelper provides.
]]

local _, NextKey222 = ...

-- MARK: Module Definition
local PUGApplicationTracker = {}
NextKey222.PUGApplicationTracker = PUGApplicationTracker

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Constants
local TRACKER_CONFIG = {
    width = 260,
    max_entries = 6,
    row_height = 16,
    anchor_point = "TOPRIGHT",
    anchor_x = -40,
    anchor_y = -200,
}

local STATUS_COLORS = {
    pending = { r = 1.0, g = 0.82, b = 0.0 },   -- Yellow
    invited = { r = 0.0, g = 1.0,  b = 0.4 },   -- Green
    accepted = { r = 0.0, g = 1.0,  b = 0.4 },  -- Green
    declined = { r = 1.0, g = 0.2,  b = 0.2 },  -- Red
    cancelled = { r = 0.7, g = 0.7, b = 0.7 },  -- Gray
    failed = { r = 0.8, g = 0.4,  b = 0.0 },    -- Orange
}

-- MARK: Private State
local frame = nil
local rows = {}
local is_visible = false

-- MARK: Module Registration
NextKey222.RegisterModule("PUGApplicationTracker", PUGApplicationTracker)

-- MARK: Helpers

local function is_debug_enabled()
    -- Check if debug is enabled via the debug service directly
    -- This is more reliable than checking the database
    if NextKey222.Debug then
        return NextKey222.Debug.enabled == true or NextKey222.Debug.level >= 3
    end
    
    -- Fallback to database check
    local addon = NextKey222.Addon
    local db = addon and addon.db
    return db and db.global and db.global.debug and db.global.debug.enabled == true
end

local function is_pug_helper_enabled()
    return NextKey222.PUGHelper and NextKey222.PUGHelper:IsEnabled()
end

local function is_mplus_application(app)
    -- Debug UI: Show ALL applications by default
    -- In production, this could be filtered by activity category or dungeon name patterns
    -- For now, we show everything to help with debugging
    if not app then
        return false
    end
    
    -- If we have an activityID, check if it's valid (non-zero)
    -- Otherwise, accept any application as potentially M+ for debugging
    return true
end

local function ensure_frame()
    if frame then
        return frame
    end

    local f = CreateFrame("Frame", "NextKey_MPlusApplications_Debug", UIParent, "BackdropTemplate")
    f:SetSize(
        TRACKER_CONFIG.width,
        (TRACKER_CONFIG.row_height * (TRACKER_CONFIG.max_entries + 1)) + 20
    )
    f:SetPoint(
        TRACKER_CONFIG.anchor_point,
        UIParent,
        TRACKER_CONFIG.anchor_point,
        TRACKER_CONFIG.anchor_x,
        TRACKER_CONFIG.anchor_y
    )
    f:SetFrameStrata("TOOLTIP")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    title:SetText("NextKey - M+ Applications (debug)")
    f.title = title

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function()
        f:Hide()
        is_visible = false
    end)

    for i = 1, TRACKER_CONFIG.max_entries do
        local row = {}
        local y = -10 - (i * TRACKER_CONFIG.row_height)

        row.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
        row.text:SetWidth(TRACKER_CONFIG.width - 16)
        row.text:SetJustifyH("LEFT")

        rows[i] = row
    end

    f:Hide()
    frame = f

    Debug:Dev("pughelper", "PUGApplicationTracker: native debug frame created")
    return frame
end

local function hide_frame()
    if frame then
        frame:Hide()
    end
    is_visible = false
end

local function update_rows(applications)
    local f = ensure_frame()

    for i = 1, TRACKER_CONFIG.max_entries do
        local row = rows[i]
        local app = applications[i]

        if app then
            local status = app.status or "pending"
            local color = STATUS_COLORS[status] or STATUS_COLORS.pending

            local key = (app.keyLevel and app.keyLevel > 0) and ("+" .. app.keyLevel) or "+?"
            local leader = app.leader or "Unknown"
            if #leader > 12 then
                leader = string.sub(leader, 1, 10) .. ".."
            end

            local dungeon = app.name or "Unknown"
            if #dungeon > 18 then
                dungeon = string.sub(dungeon, 1, 16) .. ".."
            end

            local text = string.format("%s  %s  %s  [%s]", key, dungeon, leader, status)
            row.text:SetText(text)
            row.text:SetTextColor(color.r, color.g, color.b)
            row.text:Show()
        else
            row.text:SetText("")
            row.text:Hide()
        end
    end

    if #applications > 0 then
        f:Show()
        is_visible = true
    else
        f:Hide()
        is_visible = false
    end
end

-- MARK: Public Interface

function PUGApplicationTracker:Initialize()
    Debug:Dev("pughelper", "PUGApplicationTracker:Initialize() - debug-only UI")
    -- Frame is lazy-created on first update; nothing else required here.
    return true
end

-- Called by PUGHelper_applications.lua after each processed update
-- applicationsArray = PUGHelper:GetApplicationsAsArray()
function PUGApplicationTracker:OnApplicationsUpdated(applicationsArray)
    -- Always respect tracking; only gate the UI.
    
    Debug:Dev("pughelper", "PUGApplicationTracker:OnApplicationsUpdated called with " .. (applicationsArray and #applicationsArray or 0) .. " apps")

    local debugEnabled = is_debug_enabled()
    local pugEnabled = is_pug_helper_enabled()
    Debug:Dev("pughelper", "  Debug enabled: " .. tostring(debugEnabled) .. ", PUG Helper enabled: " .. tostring(pugEnabled))

    if not debugEnabled or not pugEnabled then
        if is_visible then
            Debug:Dev("pughelper", "PUGApplicationTracker: Hiding (debug disabled or PUGHelper disabled)")
        end
        hide_frame()
        return
    end

    if type(applicationsArray) ~= "table" then
        Debug:Dev("pughelper", "PUGApplicationTracker: Invalid applicationsArray type")
        hide_frame()
        return
    end

    local mplus_apps = {}
    for i, app in ipairs(applicationsArray) do
        Debug:Dev("pughelper", "  App " .. i .. ": activityID=" .. tostring(app.activityID) .. ", name=" .. tostring(app.name))
        if is_mplus_application(app) then
            table.insert(mplus_apps, app)
        else
            Debug:Dev("pughelper", "    App " .. i .. " filtered out (not M+)")
        end
    end

    Debug:Dev("pughelper", "PUGApplicationTracker: Filtered " .. #applicationsArray .. " apps down to " .. #mplus_apps .. " M+ apps")

    if #mplus_apps == 0 then
        if is_visible then
            Debug:Dev("pughelper", "PUGApplicationTracker: Hiding (no M+ applications)")
        end
        hide_frame()
        return
    end

    Debug:Dev("pughelper", "PUGApplicationTracker: Updating debug UI with " .. #mplus_apps .. " M+ applications")
    update_rows(mplus_apps)
end

function PUGApplicationTracker:Hide()
    hide_frame()
end

return PUGApplicationTracker