local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

-- ProfileCache module provides UI-level caching for player profiles.
-- This is separate from ProfilesService's internal cache and serves as a
-- lightweight cache for UI rendering operations.

local ProfileCache = {
    cache = {},  -- Player profile cache keyed by normalized player name
}

NextKey222.ProfileCache = ProfileCache
NextKey222.RegisterModule("ProfileCache", ProfileCache)

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

-- MARK: Public Interface

--- Get a player's profile with caching
-- @param playerName string The player name to get profile for
-- @return table|nil The player's profile or nil
function ProfileCache:get_cached_profile(playerName)
    if not playerName then
        return nil
    end

    -- CRITICAL FIX: Don't use cache - always fetch fresh profile
    -- ProfileCache is being deprecated in favor of ProfilesService's internal cache
    -- The UI-level cache was causing stale data on spec changes
    
    -- Debug logging for specific players (legacy Ryuza tracking)
    if playerName:find("Ryuza") then
        safe_debug_dev("profiles", string.format(
            "ProfileCache:get_cached_profile called for: %s (bypassing cache, using ProfilesService)",
            playerName
        ))
    end

    -- Get from ProfilesService (which has its own LRU cache with event-driven invalidation)
    if not NextKey222.ProfilesService or not NextKey222.ProfilesService.GetProfile then
        safe_debug_error("ProfileCache: ProfilesService not available")
        return nil
    end

    local profile = NextKey222.ProfilesService:GetProfile(playerName)

    -- Debug logging for specific players
    if playerName:find("Ryuza") then
        safe_debug_dev("profiles", string.format(
            "Profile retrieved for %s: class=%s, role=%s, specName=%s, specID=%s",
            playerName,
            profile and profile.class or "nil",
            profile and profile.role or "nil",
            profile and profile.specName or "nil",
            profile and profile.specID or "nil"
        ))
    end

    -- Don't cache - ProfilesService handles caching with event-driven invalidation
    return profile
end

--- Invalidate cache for a specific player
-- @param playerName string The player name to invalidate
function ProfileCache:invalidate_cache(playerName)
    if not playerName then
        return
    end

    if self.cache[playerName] then
        self.cache[playerName] = nil
        safe_debug_dev("profiles", "Invalidated UI profile cache for:", playerName)
    end
end

--- Clear entire profile cache
-- Used when party composition changes significantly
function ProfileCache:clear_cache()
    local count = 0
    for k in pairs(self.cache) do
        self.cache[k] = nil
        count = count + 1
    end

    if count > 0 then
        safe_debug_dev("profiles", string.format("Cleared %d entries from UI profile cache", count))
    end
end

--- Get cache statistics (for debugging)
-- @return table { size: number, keys: table }
function ProfileCache:get_cache_stats()
    local keys = {}
    local size = 0

    for k in pairs(self.cache) do
        table.insert(keys, k)
        size = size + 1
    end

    return {
        size = size,
        keys = keys,
    }
end

-- MARK: Initialize

function ProfileCache:Initialize()
    self.cache = {}
    safe_debug_dev("profiles", "ProfileCache module initialized")
    return true
end

return ProfileCache