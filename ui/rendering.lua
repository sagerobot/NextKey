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

-- MARK: Keystone Sorting & Metadata

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
-- This mirrors the logic currently in ui/main.lua:EnrichEntryMetadata.
function UIRendering:enrich_entry_metadata(ui, entry)
    if not entry or not entry.key then
        return
    end

    local owner_name = entry.key.ownerName or "Unknown"
    entry.ownerName = owner_name

    local normalized_name = NextKey222.UIComponents
        and NextKey222.UIComponents:NormalizePlayerName(owner_name)
        or owner_name
    entry.normalizedOwnerName = normalized_name

    local profile = ui:GetPlayerProfileCached(normalized_name)
    entry.profile = profile
    entry.specName = profile and profile.specName or nil
    entry.specID = profile and profile.specID or nil

    -- Role resolution: prioritize profile.role (which comes from Blizzard adapter)
    if profile and profile.role then
        -- Profile already has role from adapter/finalization
        entry.role = string.upper(profile.role)
    elseif entry.specID
        and NextKey222.UIComponents
        and NextKey222.UIComponents.GetRoleFromSpecID
    then
        -- Fallback to spec-to-role mapping
        entry.role = NextKey222.UIComponents:GetRoleFromSpecID(entry.specID, "DAMAGER")
    else
        -- Final fallback
        entry.role = "DAMAGER"
    end

    -- Heroism / Battle Res flags via PlayerCapabilities
    local class_token = entry.key.class or (profile and profile.class)
    local spec_id = profile and profile.specID

    entry.hasHeroism = ui:PlayerProvidesHeroism(profile, class_token, spec_id)
    entry.hasBattleRes = ui:PlayerProvidesBattleRes(profile, class_token, spec_id)

    -- Dungeon name
    if entry.key.dungeonID then
        entry.dungeonName = NextKey222.Addon:GetDungeonName(entry.key.dungeonID)
            or ("Dungeon " .. entry.key.dungeonID)
    else
        entry.dungeonName = "No Dungeon"
    end

    entry.keyLevel = entry.key.level or 0

    -- Expected IO gain
    local expected = entry.ioGainRange
        and entry.ioGainRange.expected
        or entry.ioGainPotential
        or 0
    entry.expectedGain = expected or 0

    -- Current dungeon IO from breakdown or calculators
    if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
        local breakdown = entry.ioGainRange.playerBreakdown[normalized_name]
        if breakdown then
            entry.currentDungeonIO = breakdown.current or 0
        end
    end

    if not entry.currentDungeonIO then
        if NextKey222.IOCalculator and entry.key.dungeonID then
            entry.currentDungeonIO = NextKey222.IOCalculator:GetPlayerDungeonScore(
                normalized_name,
                entry.key.dungeonID
            ) or 0
        else
            entry.currentDungeonIO = 0
        end
    end

    -- Capability flags from profile capabilities (mirrors existing safety)
    if entry.profile and entry.profile.capabilities then
        if entry.profile.capabilities.heroism then
            entry.hasHeroism = true
        end
        if entry.profile.capabilities.battleRes then
            entry.hasBattleRes = true
        end
    end
end

-- MARK: Keystone Render Orchestration

-- Orchestrates keystone rendering into ui.resultsFrame.
-- Keeps all existing behavior but centralizes logic for clarity.
-- ui: NextKey222.UI instance
-- keys: array from Addon:GetAvailableKeys()
-- mode: current sort mode
function UIRendering:render_keystones(ui, keys, mode)
    if not ui or not ui.resultsFrame then
        safe_dev("ui", "UIRendering:render_keystones: missing resultsFrame")
        return
    end

    local uicalc = _get_uicalc()
    local keystone_hash = uicalc
        and uicalc:get_keystone_list_hash(keys)
        or ui:GetKeystoneListHash(keys)

    -- Skip if nothing changed (same behavior as existing code)
    if self.last_rendered_keystone_hash
        and self.last_rendered_keystone_hash == keystone_hash
        and self.last_rendered_sort_mode == mode
    then
        safe_dev("keystones", "Skipping render - no changes detected")
        return
    end

    self.last_rendered_keystone_hash = keystone_hash
    self.last_rendered_sort_mode = mode

    safe_dev("ui_contamination", "[UIRendering] Rendering - hash:",
        keystone_hash ~= nil and "present" or "nil",
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

    -- Enrich & render each entry
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

    -- Update control visibility after render
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

-- MARK: Initialize

function UIRendering:Initialize()
    _reset_render_cache(self)
    safe_dev("ui", "UIRendering module initialized")
    return true
end

return UIRendering