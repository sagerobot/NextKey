local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

local UICalculations = {
    -- Cache keyed by "dungeonID:level:partyHash"
    io_gain_cache = {},
}

NextKey222.UICalculations = UICalculations
NextKey222.RegisterModule("UICalculations", UICalculations)

-- MARK: Private Helpers

local function safe_debug_dev(category, ...)
    if Debug and Debug.Dev then
        Debug:Dev(category, ...)
    end
end

local function safe_debug_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

local function _ensure_party_profiles()
    local profiles = {}
    local addon = NextKey222.Addon
    local profiles_service = NextKey222.ProfilesService

    if not addon then
        return profiles
    end

    local party_members = addon.GetPartyMemberNames and addon:GetPartyMemberNames() or {}
    for _, member_name in pairs(party_members) do
        if profiles_service and profiles_service.GetProfile then
            profiles[member_name] = profiles_service:GetProfile(member_name)
        else
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
        return "empty"
    end

    table.sort(names)
    return table.concat(names, "|")
end

-- Generate a hash of keystone list for render skipping
-- Keys: { { ownerName, dungeonID, level }, ... }
function UICalculations:get_keystone_list_hash(keys)
    if not keys or #keys == 0 then
        return "empty"
    end

    local parts = {}
    for _, key in ipairs(keys) do
        table.insert(parts, string.format(
            "%s:%d:%d",
            key.ownerName or "unknown",
            key.dungeonID or 0,
            key.level or 0
        ))
    end

    table.sort(parts)
    return table.concat(parts, "|")
end

-- Clear all IO gain cache entries (e.g. when party or season changes)
function UICalculations:clear_io_gain_cache()
    for k in pairs(self.io_gain_cache) do
        self.io_gain_cache[k] = nil
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
        return { min = 0, max = 0, expected = 0 }
    end

    local dungeon_id = keystone_data.dungeonID or 0
    local level = keystone_data.level or 0
    local party_hash = opts.party_hash or self:get_party_composition_hash()

    local cache_key = string.format("%d:%d:%s", dungeon_id, level, party_hash or "")
    local cached = self.io_gain_cache[cache_key]
    if cached then
        return cached
    end

    local party_profiles = opts.party_profiles or _ensure_party_profiles()
    local range = nil

    NextKey222.SafeRun(function()
        range = NextKey222.IOCalculator:CalculateGroupIORange(keystone_data, party_profiles)
    end, "UICalculations:CalculateGroupIORange")

    local result = {
        min = 0,
        max = 0,
        expected = 0,
    }

    if range then
        result.min = range.min or 0
        result.max = range.max or 0
        result.expected = range.expected or 0
        result.playerBreakdown = range.playerBreakdown
    end

    self.io_gain_cache[cache_key] = result

    return result
end

-- Calculate aggregated breakpoint ranges for untimed/timed/+2/+3 from a player breakdown
-- Mirrors existing UI:CalculateBreakpointRanges behavior for compatibility.
-- key_info: { level = number, ... }
-- player_breakdown: map of playerName -> { range = { min, expected, max }, ... }
function UICalculations:calculate_breakpoint_ranges(key_info, player_breakdown)
    if not key_info or not player_breakdown then
        return nil
    end

    local level = tonumber(key_info.level) or 0
    if level <= 0 then
        return nil
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
        local min_gain = tonumber(pr.min) or 0
        local expected_gain = tonumber(pr.expected) or 0
        local max_gain = tonumber(pr.max) or 0

        count = count + 1

        totals.untimed = totals.untimed + math.max(0, min_gain)
        totals.timed = totals.timed + math.max(0, expected_gain)
        totals.plus3 = totals.plus3 + math.max(0, max_gain)

        local timed_clamped = math.max(0, expected_gain)
        local max_clamped = math.max(timed_clamped, max_gain)
        local gain_plus2 = timed_clamped + (max_clamped - timed_clamped) * 0.5
        totals.plus2 = totals.plus2 + gain_plus2
    end

    if count == 0 then
        return nil
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
    }
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
    safe_debug_dev("ui", "UICalculations module initialized")
    return true
end

return UICalculations