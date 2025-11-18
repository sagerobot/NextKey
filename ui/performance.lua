local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug
local SafeRun = NextKey222 and NextKey222.SafeRun

-- MARK: Module Definition
-- Centralized frame pacing and batch rendering helpers for the main UI.
-- This module owns the pacing loop and queues; ui/main.lua becomes a thin delegate.

local UIPerformance = {
    -- Default per-frame budget in milliseconds (tuned for 60 FPS target)
    DEFAULT_FRAME_BUDGET_MS = 16,
    -- Max work items processed per frame tick
    DEFAULT_MAX_WORK_PER_FRAME = 3,

    -- Internal state (per-UI, keyed by UI table)
    state = {}
}

NextKey222.UIPerformance = UIPerformance
NextKey222.RegisterModule("UIPerformance", UIPerformance)

-- MARK: Private Helpers

local function log_dev(category, ...)
    if Debug and Debug.Dev then
        Debug:Dev(category, ...)
    end
end

local function log_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

local function _get_ui_state(self)
    if not self then
        return nil
    end
    local st = UIPerformance.state[self]
    if not st then
        st = {
            work_queue = {},
            render_queue = {},
            update_frame = nil,
            is_processing = false,
            last_frame_time = 0,
            frame_budget_ms = UIPerformance.DEFAULT_FRAME_BUDGET_MS,
            max_work_per_frame = UIPerformance.DEFAULT_MAX_WORK_PER_FRAME,
        }
        UIPerformance.state[self] = st
    end
    return st
end

local function _clear_queues(st)
    st.work_queue = {}
    st.render_queue = {}
end

-- MARK: Public Interface

--- Initialize performance settings for a specific UI instance.
-- Should be called once from UI:Initialize().
-- @param ui table UI module instance
function UIPerformance:Initialize_for_ui(ui)
    if not ui then
        return
    end
    local st = _get_ui_state(ui)
    st.frame_budget_ms = UIPerformance.DEFAULT_FRAME_BUDGET_MS
    st.max_work_per_frame = UIPerformance.DEFAULT_MAX_WORK_PER_FRAME
    _clear_queues(st)
    st.is_processing = false

    log_dev("ui", "UIPerformance: initialized for UI instance")
end

--- Queue a frame-paced render for the given UI.
-- Decides what to render based on ui.viewMode and group size.
-- @param ui table UI module instance (NextKey222.UI)
function UIPerformance:QueueFramePacedRender(ui)
    if not ui or not ui.resultsFrame then
        return
    end

    local st = _get_ui_state(ui)
    _clear_queues(st)

    local group_size = GetNumGroupMembers() or 1
    local effective_size = group_size

    -- Optional integration with Events helper for offline players
    if NextKey222.Events
        and NextKey222.Events.HasSignificantOfflinePlayers
        and NextKey222.Events:HasSignificantOfflinePlayers()
        and NextKey222.Events.GetOnlineGroupMembers
    then
        local online = NextKey222.Events:GetOnlineGroupMembers()
        if type(online) == "number" and online > 0 then
            effective_size = online
        end
    end

    -- Queue data preparation work
    -- This task is responsible for populating the render queue with individual items
    table.insert(st.work_queue, {
        type = "prepare_data",
        ui = ui,
        priority = 1,
    })

    if not st.is_processing then
        self:StartFramePacing(ui)
    end

    log_dev("ui", string.format(
        "UIPerformance: queued frame-paced render (group=%d, effective=%d, view=%s)",
        group_size, effective_size, ui.viewMode or "keystones"
    ))
end

--- Enqueue a batch of render items
-- @param ui table UI module instance
-- @param items table Array of render items
function UIPerformance:EnqueueRenderItems(ui, items)
    local st = _get_ui_state(ui)
    if not st or not items then return end
    
    for _, item in ipairs(items) do
        table.insert(st.render_queue, item)
    end
    
    log_dev("ui", string.format("UIPerformance: enqueued %d render items", #items))
end

--- Start the frame pacing update loop for a UI if not already running.
-- @param ui table UI module instance
function UIPerformance:StartFramePacing(ui)
    local st = _get_ui_state(ui)
    if st.is_processing then
        return
    end

    st.is_processing = true
    st.last_frame_time = GetTime()

    local update_frame = CreateFrame("Frame", nil, UIParent)
    update_frame:SetScript("OnUpdate", function()
        UIPerformance:ProcessFramePacing(ui)
    end)
    st.update_frame = update_frame

    log_dev("ui", "UIPerformance: started frame pacing loop")
end

--- Process queued work/render items within the configured frame budget.
-- This is called every OnUpdate while pacing is active.
-- @param ui table UI module instance
function UIPerformance:ProcessFramePacing(ui)
    local st = _get_ui_state(ui)
    if not st or not st.is_processing then
        return
    end

    local now = GetTime()
    local frame_delta = now - st.last_frame_time

    -- Only process when we have passed the budget interval.
    if frame_delta < (st.frame_budget_ms / 1000) then
        return
    end

    st.last_frame_time = now
    local work_start = GetTime()
    local processed = 0

    -- Process work queue first
    while #st.work_queue > 0
        and processed < st.max_work_per_frame
        and (GetTime() - work_start) < (st.frame_budget_ms / 1000)
    do
        local work = table.remove(st.work_queue, 1)
        self:ExecuteWorkItem(ui, work)
        processed = processed + 1
    end

    -- Then process render queue
    if #st.work_queue == 0 and #st.render_queue > 0 then
        while #st.render_queue > 0
            and processed < st.max_work_per_frame
            and (GetTime() - work_start) < (st.frame_budget_ms / 1000)
        do
            local render = table.remove(st.render_queue, 1)
            self:ExecuteRenderItem(ui, render)
            processed = processed + 1
        end
    end

    -- Stop when all queues are empty
    if #st.work_queue == 0 and #st.render_queue == 0 then
        self:StopFramePacing(ui)
    end

    if processed > 0 then
        log_dev("ui", string.format(
            "UIPerformance: processed %d items in %.2fms",
            processed,
            (GetTime() - work_start) * 1000
        ))
    end
end

--- Execute a single work item (non-UI heavy).
-- @param ui table
-- @param work table
function UIPerformance:ExecuteWorkItem(ui, work)
    if not work or not work.type then
        return
    end

    if work.type == "prepare_data" then
        -- Delegate to existing PrepareRenderData if present on UI
        if ui.PrepareRenderData then
            if SafeRun then
                SafeRun(function() ui:PrepareRenderData() end, "UIPerformance:PrepareRenderData")
            else
                ui:PrepareRenderData()
            end
        end
    end
end

--- Execute a single render item (UI heavy; SafeRun-wrapped).
-- @param ui table
-- @param render table
function UIPerformance:ExecuteRenderItem(ui, render)
    if not render or not render.type then
        return
    end

    if render.type == "render_card" then
        if render.callback then
            if SafeRun then
                SafeRun(render.callback, "UIPerformance:RenderCard", ui, render.data)
            else
                render.callback(ui, render.data)
            end
        end
    elseif render.type == "render_dungeons" then
        if ui.RenderDungeonCards then
            if SafeRun then
                SafeRun(ui.RenderDungeonCards, "UIPerformance:RenderDungeonCards", ui)
            else
                ui:RenderDungeonCards()
            end
        end
    elseif render.type == "render_keystones" then
        if ui.RenderResults then
            if SafeRun then
                SafeRun(ui.RenderResults, "UIPerformance:RenderResults", ui)
            else
                ui:RenderResults()
            end
        end
    end
end

--- Stop pacing for the given UI and clean up the OnUpdate frame.
-- @param ui table UI module instance
function UIPerformance:StopFramePacing(ui)
    local st = _get_ui_state(ui)
    if not st then
        return
    end

    if st.update_frame then
        st.update_frame:SetScript("OnUpdate", nil)
        st.update_frame = nil
    end

    st.is_processing = false
    _clear_queues(st)

    log_dev("ui", "UIPerformance: stopped frame pacing loop")
end

--- Optional helper to adjust pacing parameters for tuning.
-- @param ui table
-- @param frame_budget_ms number|nil
-- @param max_work_per_frame number|nil
function UIPerformance:Configure(ui, frame_budget_ms, max_work_per_frame)
    local st = _get_ui_state(ui)
    if not st then
        return
    end

    if type(frame_budget_ms) == "number" and frame_budget_ms > 0 then
        st.frame_budget_ms = frame_budget_ms
    end

    if type(max_work_per_frame) == "number" and max_work_per_frame > 0 then
        st.max_work_per_frame = max_work_per_frame
    end

    log_dev("ui", string.format(
        "UIPerformance: configured for UI (budget=%dms, maxWork=%d)",
        st.frame_budget_ms,
        st.max_work_per_frame
    ))
end

-- MARK: Module Initialization

function UIPerformance:Initialize()
    -- Global init is trivial; per-UI init happens via Initialize_for_ui.
    log_dev("ui", "UIPerformance module initialized")
    return true
end

return UIPerformance