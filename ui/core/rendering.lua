local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

local UIRendering = {
    -- Cached state used to avoid redundant renders
    last_rendered_keystone_hash = nil,
    last_rendered_sort_mode = nil,
    cached_items = nil,
    cached_use_compact_mode = nil,
    cached_items_count = 0,
}

NextKey222.UIRendering = UIRendering
NextKey222.RegisterModule("UIRendering", UIRendering)

-- MARK: Private Helpers

local function safe_dev(category, ...)
    if Debug and Debug.Dev then
        Debug:Dev(category, ...)
    end
end

local function safe_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

local function _get_uicalc()
    return NextKey222.UICalculations
end

local function _ensure_cached_tables(self_ref)
    if not self_ref.cached_items then
        self_ref.cached_items = {}
    end
end

local function _reset_render_cache(self_ref)
    self_ref.last_rendered_keystone_hash = nil
    self_ref.last_rendered_sort_mode = nil
    self_ref.cached_items = {}
    self_ref.cached_use_compact_mode = nil
    self_ref.cached_items_count = 0
end

-- MARK: Sorting & Metadata

-- Sorts incoming keystone data into a list of entries suitable for rendering.
-- Uses the pluggable sorting system to apply the selected algorithm.
-- keys: array of keystone objects from Addon
-- mode: current sort mode
-- ui: reference to NextKey222.UI (for helper calls)
function UIRendering:build_sorted_entries(keys, mode, ui)
    local entries = {}

    if not keys or #keys == 0 then
        return entries
    end

    for _, key in ipairs(keys) do
        table.insert(entries, { key = key })
    end

    -- Get the algorithm from the sorting system
    local algorithm = nil
    if NextKey222.Sorting and NextKey222.Sorting.GetAlgorithm then
        algorithm = NextKey222.Sorting:GetAlgorithm(mode)
    end

    -- If algorithm needs IO tooltips, calculate IO gain data for all entries
    -- NOTE: We calculate ioGainRange (detailed player breakdown) but NOT ioGainPotential
    -- Each algorithm will calculate its own score from the breakdown data
    if algorithm and algorithm.showIOTooltips then
        -- CRITICAL: Ensure party profiles are cached for all players before calculating IO ranges
        -- This ensures Smart Sort and other algorithms have complete player data
        local NextKey = NextKey222.Addon
        if NextKey and NextKey.GetPartyMemberNames then
            local partyMembers = NextKey:GetPartyMemberNames()
            local partyProfiles = {}
            
            for _, memberName in pairs(partyMembers) do
                if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
                    local profile = NextKey222.ProfilesService:GetProfile(memberName)
                    if profile then
                        partyProfiles[memberName] = profile
                        safe_dev("sorting", "Loaded profile for", memberName, "class:", profile.class or "nil", "role:", profile.role or "nil")
                    else
                        safe_dev("sorting", "WARNING: No profile found for", memberName)
                    end
                else
                    safe_dev("sorting", "WARNING: ProfilesService not available")
                end
            end
            
            -- Cache party profiles on UI for use by CalculateIOGainRange
            if ui then
                ui.cachedPartyProfiles = partyProfiles
                safe_dev("sorting", "Cached", ui:CountTable(partyProfiles), "party profiles for IO calculations")
            end
        end
        
        for _, entry in ipairs(entries) do
            entry.ioGainRange = ui:CalculateIOGainRange(entry.key)
            -- Do NOT pre-calculate ioGainPotential - let algorithms compute their own scores
        end
    end

    -- Apply the sorting algorithm from the registry
    if algorithm and algorithm.sortFunction then
        table.sort(entries, algorithm.sortFunction)
        safe_dev("sorting", "Applied algorithm:", mode, "showIOTooltips:", algorithm.showIOTooltips)
    else
        -- Fallback: no sorting if algorithm not found
        safe_dev("sorting", "No algorithm found for mode:", mode)
    end

    return entries
end

-- Enriches a single entry with profile/role/heroism/res info and dungeon labels.
-- Delegates to MetadataEnricher module for consistent enrichment logic.
function UIRendering:enrich_entry_metadata(ui, entry)
    if not entry or not entry.key then
        return
    end

    -- Delegate to MetadataEnricher module
    if NextKey222.MetadataEnricher and NextKey222.MetadataEnricher.enrich_entry_metadata then
        NextKey222.MetadataEnricher:enrich_entry_metadata(ui, entry)
    else
        -- Fallback if module not loaded
        safe_error("UIRendering: MetadataEnricher module not available")
    end
end

-- MARK: Render Orchestration

-- Orchestrates keystone rendering into ui.resultsFrame.
-- Keeps all existing behavior but centralizes logic for clarity.
-- ui: NextKey222.UI instance
-- keys: array from Addon:GetAvailableKeys()
-- mode: current sort mode
-- Prepares keystone data for rendering (sorting, enrichment) and either renders immediately
-- or queues render items if frame pacing is active.
function UIRendering:render_keystones(ui, keys, mode)
    if not ui or not ui.resultsFrame then
        safe_dev("ui", "UIRendering:render_keystones: missing resultsFrame")
        return
    end

    -- Use combined hash that includes BOTH keystones AND profile state (spec/role changes)
    local combined_hash = ui.GetRenderHash and ui:GetRenderHash(keys) or nil
    
    if not combined_hash then
        -- Fallback to keystone-only hash if GetRenderHash unavailable
        local uicalc = _get_uicalc()
        combined_hash = uicalc
            and uicalc:get_keystone_list_hash(keys)
            or ui:GetKeystoneListHash(keys)
    end

    -- Skip if nothing changed (includes spec/role changes via profile state hash)
    if self.last_rendered_keystone_hash
        and self.last_rendered_keystone_hash == combined_hash
        and self.last_rendered_sort_mode == mode
    then
        safe_dev("keystones", "Skipping render - no changes detected (keystones + profiles)")
        return
    end

    self.last_rendered_keystone_hash = combined_hash
    self.last_rendered_sort_mode = mode

    safe_dev("ui_contamination", "[UIRendering] Rendering - hash:",
        combined_hash ~= nil and "present" or "nil",
        "mode:", mode)

    -- Clear existing content and aux frames
    if ui.ClearAuxFrames then
        ui:ClearAuxFrames()
    end
    ui.resultsFrame:ReleaseChildren()

    -- No keys case: render message and update controls
    if not keys or #keys == 0 then
        local none = NextKey222.UIComponents:CreateText("body", nil, {
            text = "No keys detected. Enable Debug in options or acquire a keystone.",
            width = nil,
        })
        ui.resultsFrame:AddChild(none)
        ui.cachedItemsCount = 0
        if ui.UpdateKeystoneControlsVisibility then
            ui:UpdateKeystoneControlsVisibility()
        end
        if ui.configContext then
            ui.configContext:SynchronizeWithUI(ui)
        end
        return
    end

    _ensure_cached_tables(self)

    -- Build sorted entries
    local entries = self:build_sorted_entries(keys, mode, ui)
    self.cached_items = {}
    self.cached_items_count = #entries

    local use_compact = (NextKey222.Utilities
        and NextKey222.Utilities:ShouldUseCompactMode(#entries))
        or (#entries > 5)
    self.cached_use_compact_mode = use_compact

    -- Check if we should use frame pacing
    local use_pacing = false
    if NextKey222.UIPerformance and NextKey222.UIPerformance.state and NextKey222.UIPerformance.state[ui] then
        use_pacing = NextKey222.UIPerformance.state[ui].is_processing
    end

    if use_pacing then
        -- Queue render items
        local render_items = {}
        for _, entry in ipairs(entries) do
            self:enrich_entry_metadata(ui, entry)
            table.insert(self.cached_items, entry)
            
            local render_func = use_compact and ui.AddKeyRowCompact or ui.AddKeyRow
            table.insert(render_items, {
                type = "render_card",
                callback = render_func,
                data = entry,
                priority = 1
            })
        end
        
        NextKey222.UIPerformance:EnqueueRenderItems(ui, render_items)
        safe_dev("ui", "Enqueued", #render_items, "keystone render items")
    else
        -- Render immediately
        for _, entry in ipairs(entries) do
            self:enrich_entry_metadata(ui, entry)
            table.insert(self.cached_items, entry)

            local render_func = use_compact and ui.AddKeyRowCompact or ui.AddKeyRow
            local ok = NextKey222.SafeRun(render_func, "Render keystone card", ui, entry)
            if not ok then
                safe_error("Failed to render keystone card for",
                    entry.key and (entry.key.ownerName or "unknown") or "nil")
            end
        end
    end

    -- Update control visibility after render (or queueing)
    if ui.UpdateKeystoneControlsVisibility then
        ui:UpdateKeystoneControlsVisibility()
    end
    
    -- Update organizer button visibility based on rendered keystone count
    if ui.headerWidgets and ui.headerWidgets.organizerBtn and ui.headerWidgets.organizerBtn.frame then
        if self.cached_items_count >= 6 then
            ui.headerWidgets.organizerBtn.frame:Show()
            safe_dev("ui", "Organizer button shown (keystone count =", self.cached_items_count, ")")
        else
            ui.headerWidgets.organizerBtn.frame:Hide()
            safe_dev("ui", "Organizer button hidden (keystone count =", self.cached_items_count, ")")
        end
    end
end

-- Prepares render data (called by UIPerformance worker)
function UIRendering:prepare_render(ui)
    if not ui then return end
    
    -- Trigger a render pass which will now queue items if pacing is active
    if ui.RenderResults then
        ui:RenderResults()
    end
end

-- MARK: Initialize

function UIRendering:Initialize()
    _reset_render_cache(self)
    safe_dev("ui", "UIRendering module initialized")
    return true
end

return UIRendering