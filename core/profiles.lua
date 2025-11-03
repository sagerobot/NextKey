-- MARK: Centralized Profiles Service
-- This module provides a unified interface for building player profiles from multiple data sources
-- All UI and calculation systems should use this service instead of building profiles locally

local _, NextKey222 = ...

local CLASS_CAPABILITIES = {
    SHAMAN = { heroism = true },
    MAGE = { heroism = true },
    EVOKER = { heroism = true },
    DRUID = { battleRes = true },
    WARLOCK = { battleRes = true },
    DEATHKNIGHT = { battleRes = true }
}

local SPEC_CAPABILITIES = {
    [62] = { heroism = true },
    [63] = { heroism = true },
    [64] = { heroism = true },
    [262] = { heroism = true },
    [263] = { heroism = true },
    [264] = { heroism = true },
    [1467] = { heroism = true },
    [1468] = { heroism = true },
    [1473] = { heroism = true },
    [253] = { heroism = true },

    [102] = { battleRes = true },
    [103] = { battleRes = true },
    [104] = { battleRes = true },
    [105] = { battleRes = true },
    [250] = { battleRes = true },
    [251] = { battleRes = true },
    [252] = { battleRes = true },
    [265] = { battleRes = true },
    [266] = { battleRes = true },
    [267] = { battleRes = true }
}

local DEFAULT_CLASS_ROLE = {
    MAGE = "DAMAGER",
    ROGUE = "DAMAGER",
    HUNTER = "DAMAGER",
    WARLOCK = "DAMAGER",
    DEMONHUNTER = "DAMAGER",
    SHAMAN = "DAMAGER",
    PRIEST = "HEALER",
    EVOKER = "DAMAGER"
}

-- MARK: PlayerProfile Contract
-- Standardized format for all player profile data
--[[
PlayerProfile = {
    name = "PlayerName-Realm",
    class = "WARRIOR", -- or nil if unknown
    io = 1234, -- total IO score or 0 if unknown
    dataSource = "combined", -- "blizzard", "raiderio", "libopenraid", "debug", "combined"
    dungeonScores = {
        [dungeonID] = {
            bestScore = 123,
            bestLevel = 15,
            timeLimit = 1800000, -- in milliseconds
            dataSource = "io_score", -- "io_score", "key_level", "fake_debug", etc.
            timed = true, -- optional
            chests = 2 -- optional
        }
    },
    addonStatus = { -- optional metadata about addon presence
        nextkey = false,
        raiderio = false
    }
}
--]]

-- MARK: Profiles Service
local ProfilesService = {}
NextKey222.ProfilesService = ProfilesService
NextKey222.RegisterModule("ProfilesService", ProfilesService)

-- Cache for built profiles (cleared on invalidation events)
ProfilesService.cache = {}
ProfilesService.cacheStats = { hits = 0, misses = 0, builds = 0, invalidations = 0 }
ProfilesService.cacheTimeout = 300 -- 5 minutes default timeout

-- Performance metrics
ProfilesService.perfStats = {
    totalBuildTime = 0,
    totalBuilds = 0,
    slowestBuild = 0,
    slowestPlayer = nil,
    lastLogTime = 0
}

-- Feature flag for rollout safety (checked dynamically)

-- MARK: Cache Management
function ProfilesService:GetCacheKey(playerName, season)
    local currentSeason = season or (NextKey222.Addon and NextKey222.Addon.CurrentSeasonKey) or "TWW_S3"
    return string.format("%s:%s", playerName, currentSeason)
end

function ProfilesService:InvalidateCache(playerName)
    local invalidatedCount = 0
    
    if playerName then
        -- Selective invalidation: Only invalidate specific player
        -- CRITICAL: Escape pattern-special characters in playerName (especially the dash in Name-Realm)
        local escapedName = playerName:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
        for cacheKey in pairs(self.cache) do
            if cacheKey:match("^" .. escapedName .. ":") then
                self.cache[cacheKey] = nil
                invalidatedCount = invalidatedCount + 1
            end
        end
        
        if NextKey222.Debug and invalidatedCount > 0 then
            NextKey222.Debug:Dev("profiles", string.format("Selectively invalidated %d profile(s) for %s",
                invalidatedCount, playerName))
        end
    else
        -- Full invalidation only when absolutely necessary
        -- This should be rare - only on major events like season changes
        invalidatedCount = self:CountTable(self.cache)
        self.cache = {}
        
        if NextKey222.Debug and invalidatedCount > 0 then
            NextKey222.Debug:Dev("profiles", string.format("Full cache invalidation: %d profiles cleared",
                invalidatedCount))
        end
    end
    
    self.cacheStats.invalidations = self.cacheStats.invalidations + 1
end

function ProfilesService:InvalidateOnEvents()
    -- Set up event-driven cache invalidation
    if NextKey222.Addon then
        -- Create event handler function if it doesn't exist
        if not NextKey222.Addon.OnProfilesInvalidation then
            NextKey222.Addon.OnProfilesInvalidation = function(self, event, unit, ...)
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("profiles", "EVENT FIRED:", event or "unknown", "unit:", unit or "none")
                end

                if NextKey222.ProfilesService then
                    -- Selective cache invalidation based on event type
                    local shouldInvalidate = false
                    local targetPlayer = nil
                    
                    if event == "PLAYER_SPECIALIZATION_CHANGED" then
                            -- Only invalidate current player
                            local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
                            targetPlayer = currentPlayer
                            shouldInvalidate = true
                            NextKey222.Debug:Dev("profiles", "PLAYER_SPECIALIZATION_CHANGED detected for:", currentPlayer)
                        elseif event == "UNIT_SPECIALIZATION" and unit then
                            -- Invalidate specific unit that changed spec
                            local name, realm = UnitName(unit)
                            if name then
                                targetPlayer = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
                                shouldInvalidate = true
                                NextKey222.Debug:Dev("profiles", "UNIT_SPECIALIZATION detected for:", targetPlayer, "unit:", unit)
                            end
                    elseif event == "GROUP_ROSTER_UPDATE" then
                        -- Only invalidate cache if someone actually joined/left
                        -- Don't invalidate on minor roster changes
                        local currentSize = GetNumGroupMembers() or 0
                        self.lastRosterSize = self.lastRosterSize or 0
                        
                        if currentSize ~= self.lastRosterSize then
                            shouldInvalidate = true
                            self.lastRosterSize = currentSize
                            NextKey222.Debug:Dev("profiles", string.format("Roster size changed: %d -> %d",
                                self.lastRosterSize, currentSize))
                        else
                            NextKey222.Debug:Dev("profiles", "Roster update but no size change - skipping invalidation")
                        end
                    else
                        -- Other events: invalidate entire cache (rare)
                        shouldInvalidate = true
                    end
                    
                    if shouldInvalidate then
                        NextKey222.ProfilesService:InvalidateCache(targetPlayer)
                        if NextKey222.Debug then
                            local eventName = type(event) == "string" and event or tostring(event or "unknown")
                            NextKey222.Debug:Dev("profiles", string.format("Cache invalidated due to %s%s",
                                eventName, targetPlayer and (" for " .. targetPlayer) or ""))
                        end
                    end

                    -- Trigger UI refresh for spec changes and roster updates
                    if event == "PLAYER_SPECIALIZATION_CHANGED" or
                       event == "UNIT_SPECIALIZATION" or
                       event == "GROUP_ROSTER_UPDATE" then
                        
                        -- Use longer delay for spec changes to ensure Blizzard API has updated
                        local delay = 0.1
                        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "UNIT_SPECIALIZATION" then
                            delay = 0.5  -- 500ms for spec changes to allow API to update
                        end
                        
                        C_Timer.After(delay, function()
                            NextKey222.Debug:Dev("profiles", "About to call RefreshUIComponents for spec change event")
                            ProfilesService:RefreshUIComponents(event)
                            NextKey222.Debug:Dev("profiles", "RefreshUIComponents call completed")
                        end)
                    end
                end
            end
        end
        
        -- Register events that should invalidate profiles cache
        local events = {
            "CHALLENGE_MODE_KEYSTONE_SLOTTED",
            "CHALLENGE_MODE_COMPLETED",
            "CHALLENGE_MODE_RESET",
            "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE",
            "GROUP_ROSTER_UPDATE",
            "PARTY_MEMBER_ENABLE",
            "PARTY_MEMBER_DISABLE",
            "PLAYER_SPECIALIZATION_CHANGED",  -- Current player changes spec
            "UNIT_SPECIALIZATION"              -- Any unit (including party members) changes spec
        }
        
        for _, eventName in ipairs(events) do
            -- Always try to register - the IsEventRegistered check might not work
            local success = pcall(function()
                NextKey222.Addon:RegisterEvent(eventName, "OnProfilesInvalidation")
            end)
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", string.format("Event registration for %s: %s",
                    eventName, success and "SUCCESS" or "FAILED"))
            end

            -- Also register with the global frame as a backup
            if not success and _G.NextKeyMainFrame then
                pcall(function()
                    _G.NextKeyMainFrame:RegisterEvent(eventName)
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("profiles", string.format("Backup event registration for %s on main frame", eventName))
                    end
                end)
            end
        end
        
        -- Register for FakePlayerService custom messages
        if NextKey222.Addon.RegisterMessage then
            NextKey222.Addon:RegisterMessage("NEXTKEY_FAKE_PLAYER_UPDATED", function(event, playerName)
                if NextKey222.ProfilesService then
                    NextKey222.ProfilesService:InvalidateCache(playerName)
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("profiles", "Cache invalidated for fake player: " .. (playerName or "unknown"))
                    end
                end
            end)
            
            NextKey222.Addon:RegisterMessage("NEXTKEY_FAKE_PLAYER_REMOVED", function(event, playerName)
                if NextKey222.ProfilesService then
                    NextKey222.ProfilesService:InvalidateCache(playerName)
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("profiles", "Cache invalidated for removed fake player: " .. (playerName or "unknown"))
                    end
                end
            end)
            
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "Registered for FakePlayerService message events")
            end
        end
        
        -- LibOpenRaid callback registration (if available)
        if LibStub then
            local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true)
            if openRaidLib and openRaidLib.RegisterCallback then
                pcall(function()
                    openRaidLib:RegisterCallback(self, "DataUpdate", function()
                        self:InvalidateCache()
                        if NextKey222.Debug then
                            NextKey222.Debug:Dev("profiles", "Cache invalidated due to LibOpenRaid update")
                        end
                    end)
                end)
            end
        end
        
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", "Event-driven cache invalidation registered for " .. #events .. " events + backup frame")
        end
    end
end

--- Helper function to refresh all UI components after profile update
-- @param event string The event that triggered the refresh
function ProfilesService:RefreshUIComponents(event)
    -- Refresh Main UI if visible
    if NextKey222.UI and NextKey222.UI.RefreshResults then
        if NextKey222.UI:IsMainFrameVisible() then
            -- CRITICAL: Clear render tracking for spec changes so UI actually re-renders
            -- Keystones don't change when specs change, but player roles do!
            NextKey222.UI.lastRenderedKeystoneHash = nil
            NextKey222.UI.lastRenderedSortMode = nil
            
            NextKey222.UI:RefreshResults()
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "Main UI refresh completed for " .. event)
            end
        else
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "Main UI not visible, skipping refresh for " .. event)
            end
        end
    end
    
    -- Refresh RosterBoard if visible
    if NextKey222.RosterBoard and NextKey222.RosterBoard.IsVisible and NextKey222.RosterBoard:IsVisible() then
        if NextKey222.RosterBoard.RefreshAllCards then
            -- CRITICAL: Clear any render caches before refreshing (same as main UI does)
            -- This ensures spec changes actually trigger a re-render
            if NextKey222.RosterBoard.lastRenderedState then
                NextKey222.RosterBoard.lastRenderedState = nil
            end
            
            NextKey222.RosterBoard:RefreshAllCards(true)  -- Pass true to indicate this is a spec change
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "RosterBoard refresh completed for " .. event .. " (SPEC CHANGE)")
            end
        else
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "RosterBoard refresh method not available for " .. event)
            end
        end
    else
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", "RosterBoard not visible, skipping refresh for " .. event)
        end
    end
end

-- MARK: Core Profile Building
function ProfilesService:BuildProfileForPlayer(playerName)
    -- Check feature flag
    local enabled = true
    if NextKey222.Addon and NextKey222.Addon.IsFeatureEnabled then
        enabled = NextKey222.Addon:IsFeatureEnabled("profilesService")
    end
    
    if not enabled then
        return nil
    end
    
    -- Check cache first
    local cacheKey = self:GetCacheKey(playerName)
    local cached = self.cache[cacheKey]
    if cached then
        -- Check if cache entry has expired
        if cached.timestamp and (GetTime() - cached.timestamp) < self.cacheTimeout then
            self.cacheStats.hits = self.cacheStats.hits + 1
            return cached.profile
        else
            -- Cache expired, remove it
            self.cache[cacheKey] = nil
        end
    end
    
    self.cacheStats.misses = self.cacheStats.misses + 1
    self.cacheStats.builds = self.cacheStats.builds + 1
    
    -- Start performance timing
    local startTime = GetTime()
    
    -- Build new profile by combining data from all available sources
    local profile = {
        name = playerName,
        class = nil,
        io = 0,
        dataSource = "combined",
        dungeonScores = {},
        addonStatus = { nextkey = false, raiderio = false }
    }
    
    -- 1. Check for debug/fake player data first (highest priority for testing)
    local debugProfile = self:GetDebugProfile(playerName)
    if debugProfile then
        self:MergeProfileData(profile, debugProfile)
        profile.dataSource = "debug"
    else
        -- 2. Get data from real sources and merge in priority order
        
        -- Try LibOpenRaid first (most comprehensive real-time data)
        local lorProfile = self:GetLibOpenRaidProfile(playerName)
        if lorProfile then
            self:MergeProfileData(profile, lorProfile)
        end
        
        -- Try RaiderIO (external API data)
        local rioProfile = self:GetRaiderIOProfile(playerName)
        if rioProfile then
            self:MergeProfileData(profile, rioProfile)
        end
        
        -- Try Blizzard APIs (local client data)
        local blizzardProfile = self:GetBlizzardProfile(playerName)
        if blizzardProfile then
            self:MergeProfileData(profile, blizzardProfile)
        end
    end
    
    -- End performance timing and record metrics
    local buildTime = GetTime() - startTime
    self.perfStats.totalBuildTime = self.perfStats.totalBuildTime + buildTime
    self.perfStats.totalBuilds = self.perfStats.totalBuilds + 1
    
    if buildTime > self.perfStats.slowestBuild then
        self.perfStats.slowestBuild = buildTime
        self.perfStats.slowestPlayer = playerName
    end
    
    -- Log performance summary periodically
    self:LogPerformanceMetrics()

    self:FinalizeProfile(profile)

    -- Cache the result with timestamp
    self.cache[cacheKey] = {
        profile = profile,
        timestamp = GetTime()
    }
    
    return profile
end

-- MARK: Profile Data Sources
function ProfilesService:GetDebugProfile(playerName)
    return NextKey222.DebugAdapter and NextKey222.DebugAdapter:GetProfile(playerName) or nil
end

function ProfilesService:GetLibOpenRaidProfile(playerName)
    return NextKey222.LibOpenRaidAdapter and NextKey222.LibOpenRaidAdapter:GetProfile(playerName) or nil
end

function ProfilesService:GetRaiderIOProfile(playerName)
    return NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter:GetProfile(playerName) or nil
end

function ProfilesService:GetBlizzardProfile(playerName)
    return NextKey222.BlizzardAdapter and NextKey222.BlizzardAdapter:GetProfile(playerName) or nil
end

-- MARK: Profile Data Merging
function ProfilesService:MergeProfileData(target, source)
    -- Merge profile data with intelligent precedence rules
    if not source then return end
    
    -- Basic fields - take non-nil values
    target.class = target.class or source.class
    target.io = math.max(target.io or 0, source.io or 0)
    
    -- Merge addon status
    if source.addonStatus then
        target.addonStatus = target.addonStatus or {}
        for addon, status in pairs(source.addonStatus) do
            target.addonStatus[addon] = target.addonStatus[addon] or status
        end
    end

    -- CRITICAL: Blizzard adapter provides real-time spec data
    -- If source is from Blizzard adapter, ALWAYS override spec-related fields
    -- This ensures spec changes are detected immediately
    local isBlizzardData = source.dataSource == "blizzard"
    
    if source.role then
        if isBlizzardData or not target.role then
            target.role = source.role
        end
    end

    if source.specID then
        if isBlizzardData or not target.specID then
            target.specID = source.specID
        end
    end

    if source.specName then
        if isBlizzardData or not target.specName then
            target.specName = source.specName
        end
    end

    if source.capabilities then
        target.capabilities = target.capabilities or {}
        if target.capabilities.heroism == nil then
            target.capabilities.heroism = source.capabilities.heroism or false
        end
        if target.capabilities.battleRes == nil then
            target.capabilities.battleRes = source.capabilities.battleRes or false
        end
    end
    
    -- Merge dungeon scores - keep best scores per dungeon
    if source.dungeonScores then
        for dungeonID, scoreData in pairs(source.dungeonScores) do
            local existing = target.dungeonScores[dungeonID]
            if not existing or (scoreData.bestScore or 0) > (existing.bestScore or 0) then
                target.dungeonScores[dungeonID] = scoreData
            end
        end
    end
end

-- MARK: High-Level Interface Methods
function ProfilesService:GetPartyProfiles(mode, customMembers)
    mode = mode or "mythicplus"
    local profiles = {}
    
    -- Get party members (use provided list or auto-detect)
    local partyMembers = customMembers or self:GetPartyMembers()
    
    -- Build profile for each member
    for _, memberName in ipairs(partyMembers) do
        local profile = self:BuildProfileForPlayer(memberName)
        if profile then
            profiles[memberName] = profile
        end
    end
    
    return profiles
end

function ProfilesService:GetGuildProfiles()
    -- Future implementation for guild-wide profiles
    return {}
end

function ProfilesService:GetPartyMembers()
    -- Helper to get current party member names
    local members = {}
    
    -- Add player
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    if playerName and realmName then
        table.insert(members, playerName .. "-" .. realmName)
    end
    
    -- Add party members
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() do
            local unit = IsInRaid() and "raid" .. i or "party" .. i
            local name, realm = UnitName(unit)
            if name and name ~= playerName then
                local fullName = realm and (name .. "-" .. realm) or (name .. "-" .. realmName)
                table.insert(members, fullName)
            end
        end
    end
    
    return members
end

-- MARK: Diagnostics and Debugging  
function ProfilesService:GetCacheStats()
    return {
        enabled = self.enabled,
        cacheSize = self:CountTable(self.cache),
        hits = self.cacheStats.hits,
        misses = self.cacheStats.misses,
        builds = self.cacheStats.builds,
        hitRate = self.cacheStats.hits > 0 and (self.cacheStats.hits / (self.cacheStats.hits + self.cacheStats.misses)) or 0
    }
end

function ProfilesService:CountTable(t)
    local count = 0
    for _ in pairs(t or {}) do count = count + 1 end
    return count
end

function ProfilesService:LogStats()
    local stats = self:GetCacheStats()
    if NextKey222.Debug then
        NextKey222.Debug:Dev("profiles", string.format("Cache stats: %d entries, %.1f%% hit rate, %d builds", 
            stats.cacheSize, stats.hitRate * 100, stats.builds))
    end
end

function ProfilesService:LogPerformanceMetrics()
    local currentTime = GetTime()
    
    -- Only log every 30 seconds to avoid spam
    if currentTime - self.perfStats.lastLogTime < 30 then
        return
    end
    
    if self.perfStats.totalBuilds > 0 then
        local avgBuildTime = self.perfStats.totalBuildTime / self.perfStats.totalBuilds
        
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", string.format(
                "Performance: %d builds, avg %.3fms, slowest %.3fms (%s)",
                self.perfStats.totalBuilds,
                avgBuildTime * 1000,
                self.perfStats.slowestBuild * 1000,
                self.perfStats.slowestPlayer or "unknown"
            ))
        end
        
        self.perfStats.lastLogTime = currentTime
    end
end

-- MARK: Initialization
function ProfilesService:Initialize()
    -- Check if service should be enabled
    local enabled = true
    if NextKey222.Addon and NextKey222.Addon.IsFeatureEnabled then
        enabled = NextKey222.Addon:IsFeatureEnabled("profilesService")
    end
    
    if not enabled then
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", "Profiles service disabled by feature flag")
        end
        return
    end
    
    self:InvalidateOnEvents()
    
    -- Initialize adapters
    if NextKey222.LibOpenRaidAdapter then
        NextKey222.LibOpenRaidAdapter:Initialize()
    end
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("profiles", "Profiles service initialized with adapters and performance monitoring")
    end
end

-- MARK: Dungeon Preference Management
-- Functions for managing user dungeon preferences (liked/disliked dungeons)

--- Gets the current preference for a specific dungeon
-- @param dungeonID number The dungeon ID
-- @return table|nil Preference table with liked/disliked flags
function ProfilesService:GetDungeonPreference(dungeonID)
    local NextKey = NextKey222.Addon
    if not NextKey or not NextKey.db or not NextKey.db.char or not NextKey.db.char.preferences then
        return nil
    end
    return NextKey.db.char.preferences[dungeonID]
end

--- Toggles dungeon preference (like/dislike)
-- @param dungeonID number The dungeon ID
-- @param isLike boolean True for like, false for dislike
function ProfilesService:ToggleDungeonPreference(dungeonID, isLike)
    local NextKey = NextKey222.Addon
    if not NextKey or not NextKey.db or not NextKey.db.char then
        return
    end
    
    -- Initialize preferences table if needed
    if not NextKey.db.char.preferences then
        NextKey.db.char.preferences = {}
    end
    
    local current = NextKey.db.char.preferences[dungeonID] or {}
    
    if isLike then
        -- Toggle like preference
        if current.liked then
            current.liked = nil -- Remove like if already liked
        else
            current.liked = true
            current.disliked = nil -- Clear dislike if setting like
        end
    else
        -- Toggle dislike preference
        if current.disliked then
            current.disliked = nil -- Remove dislike if already disliked
        else
            current.disliked = true
            current.liked = nil -- Clear like if setting dislike
        end
    end
    
    -- Update timestamp
    current.lastUpdated = time()
    
    -- Save preference (remove empty tables)
    if not current.liked and not current.disliked then
        NextKey.db.char.preferences[dungeonID] = nil
    else
        NextKey.db.char.preferences[dungeonID] = current
    end
    
    if NextKey222.Debug then
        NextKey222.Debug:Dev("profiles", string.format("Dungeon preference updated: %s", 
            current.liked and "Liked" or (current.disliked and "Disliked" or "Neutral")))
    end
end

-- MARK: Export to NextKey222 namespace
NextKey222.ProfilesService = ProfilesService

-- Initialize when loaded
if NextKey222.Addon then
    NextKey222.Addon.ProfilesService = ProfilesService
end

function ProfilesService:FinalizeProfile(profile)
    if not profile then
        return
    end
    
    -- PHASE 1: Diagnostic logging - track FinalizeProfile entry
    if NextKey222.Debug then
        NextKey222.Debug:Dev("profiles", string.format("FinalizeProfile called for: %s, class: %s, specID: %s, existing role: %s",
            profile.name or "unknown",
            profile.class or "nil",
            profile.specID or "nil",
            profile.role or "nil"))
    end

    if profile.class then
        profile.class = string.upper(profile.class)
    end

    profile.capabilities = profile.capabilities or {}

    -- CRITICAL: Get role from specID using correct Blizzard API
    local role = nil
    local specName = nil
    
    -- For current player, ALWAYS use GetSpecialization() directly (ignore adapter specID)
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local currentPlayer = playerName .. "-" .. realmName
    
    if profile.name == currentPlayer and GetSpecialization then
        -- Current player: ALWAYS use GetSpecialization + GetSpecializationInfo
        -- This is the source of truth for current player's active spec
        local specIndex = GetSpecialization()
        
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", string.format("[SPEC DEBUG] GetSpecialization() returned index: %s, profile.specID from adapter: %s",
                tostring(specIndex), tostring(profile.specID)))
        end
        
        if specIndex then
            -- API returns: specID, name, description, icon, role, primaryStat
            local currentSpecID, name, _, _, specRole = GetSpecializationInfo(specIndex)
            
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", string.format("[SPEC DEBUG] GetSpecializationInfo(%d) returned: specID=%s, specName=%s, specRole=%s",
                    specIndex, tostring(currentSpecID), tostring(name), tostring(specRole)))
            end
            
            -- ALWAYS use current spec data, overwrite what adapters provided
            profile.specID = currentSpecID
            profile.role = specRole  -- CRITICAL: Actually set profile.role, not just local variable
            profile.specName = name
            role = specRole  -- Keep local for later checks
            specName = name
            
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", string.format("Current player spec data SET: specID=%d, specName=%s, profile.role=%s",
                    currentSpecID or 0, name or "nil", specRole or "nil"))
            end
        else
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "[SPEC DEBUG] GetSpecialization() returned nil!")
            end
        end
    elseif profile.specID then
        -- For other players, use GetSpecializationInfoByID with the specID from adapters
        
        if GetSpecializationInfoByID then
            -- GetSpecializationInfoByID returns: id, name, description, icon, role, primaryStat
            local _, name, _, _, specRole = GetSpecializationInfoByID(profile.specID)
            
            -- Validate the role is actually a valid role string
            if specRole and (specRole == "TANK" or specRole == "HEALER" or specRole == "DAMAGER") then
                role = specRole
                specName = name
                
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("profiles", string.format("GetSpecializationInfoByID(%d) returned: specName=%s, role=%s",
                        profile.specID, specName or "nil", role or "nil"))
                end
            else
                -- GetSpecializationInfoByID is returning invalid data, log warning
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("profiles", string.format("GetSpecializationInfoByID(%d) returned INVALID role: %s (expected TANK/HEALER/DAMAGER)",
                        profile.specID, tostring(specRole)))
                end
            end
        end
        
        -- ALWAYS use spec-based role if we got a valid one (overwrite any existing role)
        if role then
            profile.role = role
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", string.format("ROLE SET from specID %d: %s -> profile.role = %s",
                    profile.specID, role, profile.role))
            end
        end
        
        if specName and not profile.specName then
            profile.specName = specName
        end
        
        -- Debug logging for Evoker spec/role detection
        if profile.class == "EVOKER" then
            local debugMsg = string.format("Evoker Spec Debug: specID=%d, specName=%s, role=%s",
                profile.specID or "nil",
                specName or "nil",
                role or "nil")
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", debugMsg)
            end
        end
    end

    -- Fallback ONLY if we still don't have a role after spec detection
    if not profile.role and profile.class then
        profile.role = DEFAULT_CLASS_ROLE[profile.class] or "DAMAGER"
        
        -- PHASE 1: Diagnostic logging - track fallback usage
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", string.format("FALLBACK: No role from spec, using default for class %s: %s",
                profile.class, profile.role))
        end
    end
    
    -- PHASE 1: Diagnostic logging - final role value
    if NextKey222.Debug then
        NextKey222.Debug:Dev("profiles", string.format("FinalizeProfile COMPLETE for %s: final role = %s",
            profile.name or "unknown", profile.role or "nil"))
    end

    local specCaps = profile.specID and SPEC_CAPABILITIES[profile.specID] or nil
    local classCaps = profile.class and CLASS_CAPABILITIES[profile.class] or nil

    if specCaps then
        if specCaps.heroism then
            profile.capabilities.heroism = true
        end
        if specCaps.battleRes then
            profile.capabilities.battleRes = true
        end
    end

    if profile.capabilities.heroism == nil and classCaps then
        profile.capabilities.heroism = classCaps.heroism or false
    elseif profile.capabilities.heroism == nil then
        profile.capabilities.heroism = false
    end

    if profile.capabilities.battleRes == nil and classCaps then
        profile.capabilities.battleRes = classCaps.battleRes or false
    elseif profile.capabilities.battleRes == nil then
        profile.capabilities.battleRes = false
    end
end

--- Public wrapper for profile retrieval used by UI/calculators
-- Ensures callers have a stable API and centralized caching behaviour
-- @param playerName string Full player name (Name-Realm)
-- @return PlayerProfile|nil
function ProfilesService:GetProfile(playerName)
    if not playerName or playerName == "" then
        return nil
    end
    
    -- Debug logging to track profile system calls
    if playerName:find("Ryuza") then
        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", string.format("GetProfile called for: %s", playerName))
        end
    end

    return self:BuildProfileForPlayer(playerName)
end

--- Gets enhanced profile data specifically for Organizer features
-- Includes roles, utilities, preferences, and alts from CharacterStorage
-- @param playerName string Full player name (Name-Realm)
-- @return table|nil Enhanced organizer profile with additional fields
function ProfilesService:GetOrganizerProfile(playerName)
    if not playerName or playerName == "" then
        return nil
    end
    
    Debug:Dev("profiles", "GetOrganizerProfile called for:", playerName)
    
    -- Get base profile first
    local baseProfile = self:BuildProfileForPlayer(playerName)
    if not baseProfile then
        Debug:Dev("profiles", "No base profile found for:", playerName)
        return nil
    end
    
    -- Create enhanced organizer profile
    local organizerProfile = {
        -- Copy all base profile fields
        name = baseProfile.name,
        class = baseProfile.class,
        io = baseProfile.io,
        dataSource = baseProfile.dataSource,
        dungeonScores = baseProfile.dungeonScores,
        addonStatus = baseProfile.addonStatus,
        specID = baseProfile.specID,
        specName = baseProfile.specName,
        role = baseProfile.role,
        capabilities = baseProfile.capabilities,
        
        -- Organizer-specific fields
        roles = self:GetAvailableRoles(playerName),
        utilities = self:GetUtilities(playerName),
        preferences = self:GetPreferences(playerName),
        alts = self:GetAlts(playerName),
        
        -- Keystone data (CRITICAL for organizer UI)
        keystone = self:GetPlayerKeystone(playerName)
    }
    
    Debug:Dev("profiles", "Enhanced organizer profile created for:", playerName,
              "with", organizerProfile.roles and #organizerProfile.roles or 0, "roles")
    
    return organizerProfile
end

--- Gets available roles for a player from CharacterStorage or spec detection
-- @param playerName string Full player name (Name-Realm)
-- @return table List of available roles {TANK, HEALER, DAMAGER}
function ProfilesService:GetAvailableRoles(playerName)
    local roles = {}
    
    -- Try CharacterStorage first (if player has configured multi-role)
    if NextKey222.CharacterStorage then
        local characterData = NextKey222.CharacterStorage:GetCharacter(playerName)
        
        -- BUGFIX: Check if characterData is actually a table (SafeRun returns false on error)
        if type(characterData) == "table" and characterData.roles then
            -- Convert character storage roles to organizer format
            for role, isEnabled in pairs(characterData.roles) do
                if isEnabled then
                    table.insert(roles, role)
                end
            end
            
            -- If we got roles from storage, return them
            if #roles > 0 then
                Debug:Dev("profiles", "Available roles for", playerName, "from storage:", table.concat(roles, ", "))
                return roles
            end
        end
    end
    
    -- Fallback: Get role from spec detection (base profile)
    -- This ensures we get the CURRENT spec's role, not a default
    local baseProfile = self:BuildProfileForPlayer(playerName)
    if baseProfile and baseProfile.role then
        table.insert(roles, baseProfile.role)
        Debug:Dev("profiles", "Available roles for", playerName, "from spec:", baseProfile.role)
    else
        Debug:Dev("profiles", "No roles found for", playerName, "- returning empty array")
    end
    
    return roles
end

--- Gets utility capabilities for a player
-- @param playerName string Full player name (Name-Realm)
-- @return table Utility capabilities {heroism, battleRes}
function ProfilesService:GetUtilities(playerName)
    if not NextKey222.CharacterStorage then
        Debug:Dev("profiles", "CharacterStorage not available for utilities lookup")
        return { heroism = false, battleRes = false }
    end
    
    local utilities = { heroism = false, battleRes = false }
    local characterData = NextKey222.CharacterStorage:GetCharacter(playerName)
    
    -- BUGFIX: Check if characterData is actually a table (SafeRun returns false on error)
    if type(characterData) == "table" and characterData.utilities then
        utilities = characterData.utilities
    else
        -- Fallback to capabilities from base profile
        local baseProfile = self:BuildProfileForPlayer(playerName)
        if baseProfile and baseProfile.capabilities then
            utilities.heroism = baseProfile.capabilities.heroism or false
            utilities.battleRes = baseProfile.capabilities.battleRes or false
        end
    end
    
    Debug:Dev("profiles", "Utilities for", playerName, ":",
              "heroism=", utilities.heroism, "battleRes=", utilities.battleRes)
    return utilities
end

--- Gets dungeon preferences for a player
-- @param playerName string Full player name (Name-Realm)
-- @return table Dungeon preferences {liked, disliked}
function ProfilesService:GetPreferences(playerName)
    -- For now, return empty preferences
    -- This will be expanded when survey system is implemented
    return {
        liked = {},
        disliked = {}
    }
end

--- Gets alt characters for a player
-- @param playerName string Full player name (Name-Realm)
-- @return table List of alt characters
function ProfilesService:GetAlts(playerName)
    if not NextKey222.CharacterStorage then
        Debug:Dev("profiles", "CharacterStorage not available for alts lookup")
        return {}
    end
    
    local alts = {}
    local characterData = NextKey222.CharacterStorage:GetCharacter(playerName)
    
    -- BUGFIX: Check if characterData is actually a table (SafeRun returns false on error)
    if type(characterData) == "table" and characterData.alts then
        alts = characterData.alts
    end
    
    Debug:Dev("profiles", "Alts for", playerName, ":", #alts, "characters")
    return alts
end

--- Gets keystone data for a player
-- @param playerName string Full player name (Name-Realm)
-- @return table|nil Keystone data with dungeonID and level
function ProfilesService:GetPlayerKeystone(playerName)
    if not NextKey222.Addon or not NextKey222.Addon.GetAvailableKeys then
        Debug:Dev("profiles", "GetAvailableKeys not available for keystone lookup")
        return nil
    end
    
    -- Get all available keys and find this player's keystone
    local allKeys = NextKey222.Addon:GetAvailableKeys()
    if not allKeys then
        Debug:Dev("profiles", "No keys available")
        return nil
    end
    
    -- Normalize player name for comparison
    local shortName = playerName:match("^([^%-]+)") or playerName
    
    for _, keyData in ipairs(allKeys) do
        local keyShortName = keyData.ownerName and (keyData.ownerName:match("^([^%-]+)") or keyData.ownerName)
        
        -- Match by short name or full name
        if keyData.ownerName == playerName or keyShortName == shortName then
            -- Return keystone in organizer-expected format
            local keystone = {
                dungeonID = keyData.dungeonID,
                level = keyData.level
            }
            
            Debug:Dev("profiles", "Found keystone for", playerName, ":", keystone.dungeonID, "+", keystone.level)
            return keystone
        end
    end
    
    Debug:Dev("profiles", "No keystone found for", playerName)
    return nil
end

--- Gets organizer profiles for multiple players (batch processing)
-- Optimized for large groups with caching and performance monitoring
-- @param playerNames table List of player names to get profiles for
-- @return table Map of playerName -> organizer profile
function ProfilesService:GetOrganizerProfilesBatch(playerNames)
    if not playerNames or type(playerNames) ~= "table" then
        Debug:Dev("profiles", "GetOrganizerProfilesBatch: Invalid playerNames parameter")
        return {}
    end
    
    Debug:Dev("profiles", "GetOrganizerProfilesBatch called for", #playerNames, "players")
    
    local profiles = {}
    local startTime = GetTime()
    
    -- Process each player
    for _, playerName in ipairs(playerNames) do
        profiles[playerName] = self:GetOrganizerProfile(playerName)
    end
    
    local endTime = GetTime()
    local processingTime = endTime - startTime
    
    Debug:Dev("profiles", string.format("Batch processed %d profiles in %.3fms",
              #playerNames, processingTime * 1000))
    
    return profiles
end
