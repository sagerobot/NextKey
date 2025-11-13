-- MARK: Module Definition

local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- UICalculations module provides functions for calculating IO gain ranges and breakpoints.
-- It caches computed values to improve performance when dealing with frequently requested party compositions.
-- The module is registered under the "UICalculations" name within the addon system.

local UICalculations = {
    -- Cache keyed by "dungeonID:level:partyHash"
    io_gain_cache = {},  -- Stores calculated IO gain ranges for performance optimization
}

NextKey222.UICalculations = UICalculations   -- Exposes module publicly within addon system.
NextKey222.RegisterModule("UICalculations", UICalculations)   -- Registers the module with the addon framework.

-- MARK: Private Helpers

local function safe_debug_dev(category, ...)
    if Debug and Debug.Dev then
        Debug:Dev(category, ...)  -- Safely logs debug messages only when Dev flag is enabled.
    end
end

local function safe_debug_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)   -- Safely logs error messages.
    end
end

-- Internal utility to ensure that party profiles are available. If ProfilesService is present,
-- it retrieves the current profile for each party member; otherwise, a placeholder profile is created.

local function _ensure_party_profiles()
    local profiles = {}
    local addon = NextKey222.Addon
    local profiles_service = NextKey222.ProfilesService

    if not addon then
        return profiles  -- Returns empty table if Addon isn't available.
    end

    local party_members = addon.GetPartyMemberNames and addon:GetPartyMemberNames() or {}
    for _, member_name in pairs(party_members) do
        if profiles_service and profiles_service.GetProfile then
            profiles[member_name] = profiles_service:GetProfile(member_name)
        else
            -- Fallback placeholder profile when ProfilesService is unavailable.
            profiles[member_name] = { player_name = member_name }
        end
    end

    return profiles
end

-- MARK: Public Interface

-- Generate a stable hash for current party composition
-- Accepts an optional explicit list (for testability); falls back to Addon if omitted.
function UICalculations:get_party_composition_hash(party_members)
    local addon = NextKey222.Addon
    local names = {}

    if type(party_members) == "table" then
        for _, name in pairs(party_members) do
            if name and name ~= "" then
                table.insert(names, name)
            end
        end
    elseif addon and addon.GetPartyMemberNames then
        local auto = addon:GetPartyMemberNames() or {}
        for _, name in pairs(auto) do
            if name and name ~= "" then
                table.insert(names, name)
            end
        end
    end

    if #names == 0 then
        return "empty"   -- Indicates an empty party composition.
    end

    table.sort(names)  -- Sorts the names alphabetically to ensure consistent hashes.
    return table.concat(names, "|")   -- Concatenates names with a delimiter for hashing purposes.
end

-- Generate a hash of keystone list for render skipping
-- Keys: { { ownerName, dungeonID, level }, ... }
function UICalculations:get_keystone_list_hash(keys)
    if not keys or #keys == 0 then
        return "empty"   -- Returns empty hash when no keys are provided.
    end

    local parts = {}
    for _, key in ipairs(keys) do
        table.insert(parts, string.format(
            "%s:%d:%d",
            key.ownerName or "unknown",   -- Owner name; uses 'unknown' if not available.
            key.dungeonID or 0,           -- Dungeon ID; defaults to 0 if missing.
            key.level or 0                -- Level; defaults to 0 if missing.
        ))
    end

    table.sort(parts)  -- Sorts the parts alphabetically for consistency in hashing.

    return table.concat(parts, "|")   -- Concatenates sorted parts with a delimiter.
end

-- Clear all IO gain cache entries (e.g. when party or season changes)
function UICalculations:clear_io_gain_cache()
    for k in pairs(self.io_gain_cache) do
        self.io_gain_cache[k] = nil   -- Removes each cached entry to free memory and avoid stale data.
    end
end

-- Calculate IO gain range for a keystone (UI-facing helper)
-- Uses IOCalculator under the hood and caches by dungeon/level/partyHash.
-- keystone_data: { dungeonID, level, ... }
-- opts:
--   - party_profiles (optional override)
--   - party_hash (optional override)
function UICalculations:calculate_io_gain_range(keystone_data, opts)
    opts = opts or {}

    if not keystone_data or not NextKey222.IOCalculator then
        return { min = 0, max = 0, expected = 0 }   -- Returns default values if calculator isn't present.
    end

    local dungeon_id = keystone_data.dungeonID or 0
    local level = keystone_data.level or 0
    local party_hash = opts.party_hash or self:get_party_composition_hash()

    local cache_key = string.format("%d:%d:%s", dungeon_id, level, party_hash or "")
    local cached = self.io_gain_cache[cache_key]
    if cached then
        return cached   -- Returns cached data if available for this combination.
    end

    local party_profiles = opts.party_profiles or _ensure_party_profiles()
    local range = nil

    NextKey222.SafeRun(function()  -- Executes the IO range calculation in a safe context.
        range = NextKey222.IOCalculator:CalculateGroupIORange(keystone_data, party_profiles)
    end, "UICalculations:CalculateGroupIORange")

    local result = {
        min = 0,
        max = 0,
        expected = 0,
    }

    if range then
        result.min = range.min or 0   -- Fallbacks to 0 if minimum value is missing.
        result.max = range.max or 0   -- Fallbacks to 0 if maximum value is missing.
        result.expected = range.expected or 0  -- Fallbacks to 0 for expected value.
        result.playerBreakdown = range.playerBreakdown
    end

    self.io_gain_cache[cache_key] = result   -- Caches the calculated range with its key.

    return result
end

-- Calculate aggregated breakpoint ranges for untimed/timed/+2/+3 from a player breakdown
-- Mirrors existing UI:CalculateBreakpointRanges behavior for compatibility.
-- key_info: { level = number, ... }
-- player_breakdown: map of playerName -> { range = { min, expected, max }, ... }
function UICalculations:calculate_breakpoint_ranges(key_info, player_breakdown)
    if not key_info or not player_breakdown then
        return nil   -- Returns nil when input data is missing or invalid.
    end

    local level = tonumber(key_info.level) or 0
    if level <= 0 then
        return nil   -- Invalid level; prevents calculation of breakpoints.
    end

    local totals = {
        untimed = 0,
        timed = 0,
        plus2 = 0,
        plus3 = 0,
    }

    local count = 0

    for _, pdata in pairs(player_breakdown) do
        local pr = pdata.range or {}
        local min_gain = tonumber(pr.min) or 0   -- Minimum gain, defaulting to 0 if unavailable.
        local expected_gain = tonumber(pr.expected) or 0   -- Expected gain; defaults to 0.
        local max_gain = tonumber(pr.max) or 0    -- Maximum gain.

        count = count + 1

        totals.untimed = totals.untimed + math.max(0, min_gain)  -- Adds only positive gains.
        totals.timed = totals.timed + math.max(0, expected_gain)   -- Adds only positive expected values.
        totals.plus3 = totals.plus3 + math.max(0, max_gain)       -- Adds maximum gain regardless of sign.

        local timed_clamped = math.max(0, expected_gain)  -- Clamps negative or zero expected gains to 0.
        local max_clamped = math.max(timed_clamped, max_gain)
        local gain_plus2 = timed_clamped + (max_clamped - timed_clamped) * 0.5   -- Calculates midpoint for +2 range.

        totals.plus2 = totals.plus2 + gain_plus2
    end

    if count == 0 then
        return nil   -- No data to calculate; returns empty result.
    end

    return {
        untimed = {
            total = totals.untimed,
            average = totals.untimed / count,
        },
        timed = {
            total = totals.timed,
            average = totals.timed / count,
        },
        plus2 = {
            total = totals.plus2,
            average = totals.plus2 / count,
        },
        plus3 = {
            total = totals.plus3,
            average = totals.plus3 / count,
        },
    }   -- Returns a table with totals and averages for each range type.
end

-- MARK: Event / State Hooks

-- Hint for callers when party might have changed significantly.
-- Does NOT auto-clear; lets orchestrators decide when to invalidate.
function UICalculations:on_party_changed()
    -- Intentionally minimal for now; hook point for future behavior.
    safe_debug_dev("ui", "UICalculations:on_party_changed invoked")
end

-- MARK: Initialize

function UICalculations:Initialize()
    safe_debug_dev("ui", "UICalculations module initialized")   -- Confirms successful initialization of the module.
    return true
end

return UICalculations  -- Exports the module for use by other parts of the addon system.
