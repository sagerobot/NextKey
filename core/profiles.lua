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
        -- Invalidate specific player
        for cacheKey in pairs(self.cache) do
            if cacheKey:match("^" .. playerName .. ":") then
                self.cache[cacheKey] = nil
                invalidatedCount = invalidatedCount + 1
            end
        end
    else
        -- Invalidate entire cache
        invalidatedCount = self:CountTable(self.cache)
        self.cache = {}
    end
    
    self.cacheStats.invalidations = self.cacheStats.invalidations + 1
    
    if NextKey222.Debug and invalidatedCount > 0 then
        NextKey222.Debug:Dev("profiles", string.format("Invalidated %d profile%s from cache", 
            invalidatedCount, invalidatedCount == 1 and "" or "s"))
    end
end

function ProfilesService:InvalidateOnEvents()
    -- Set up event-driven cache invalidation
    if NextKey222.Addon then
        -- Create event handler function if it doesn't exist
        if not NextKey222.Addon.OnProfilesInvalidation then
            NextKey222.Addon.OnProfilesInvalidation = function(event, ...)
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("profiles", "EVENT FIRED: " .. (event or "unknown"))
                end

                if NextKey222.ProfilesService then
                    NextKey222.ProfilesService:InvalidateCache()
                    if NextKey222.Debug then
                        NextKey222.Debug:Dev("profiles", "Cache invalidated due to event: " .. (event or "unknown"))
                    end

                    -- Trigger UI refresh for spec changes and roster updates
                    if event == "PLAYER_SPECIALIZATION_CHANGED" or
                       event == "UNIT_SPECIALIZATION" or
                       event == "GROUP_ROSTER_UPDATE" then
                        if NextKey222.UI and NextKey222.UI.RefreshResults then
                            if NextKey222.UI:IsMainFrameVisible() then
                                if NextKey222.Debug then
                                    NextKey222.Debug:Dev("profiles", "Triggering UI refresh due to " .. event .. " (UI visible)")
                                end
                            else
                                if NextKey222.Debug then
                                    NextKey222.Debug:Dev("profiles", "Triggering UI refresh due to " .. event .. " (UI not visible, but refreshing anyway)")
                                end
                            end

                            -- Small delay to allow profile data to update
                            C_Timer.After(0.1, function()
                                if NextKey222.UI and NextKey222.UI.RefreshResults then
                                    NextKey222.UI:RefreshResults()
                                    if NextKey222.Debug then
                                        NextKey222.Debug:Dev("profiles", "UI refresh completed for " .. event)
                                    end
                                else
                                    if NextKey222.Debug then
                                        NextKey222.Debug:Dev("profiles", "UI refresh FAILED - UI not available for " .. event)
                                    end
                                end
                            end)
                        else
                            if NextKey222.Debug then
                                NextKey222.Debug:Dev("profiles", "UI refresh SKIPPED - UI not available for " .. event)
                            end
                        end
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
        
        -- Also register events directly on a frame as backup
        local eventFrame = CreateFrame("Frame")
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "FRAME EVENT FIRED: " .. (event or "unknown"))
            end

            -- Call the same handler
            if NextKey222.ProfilesService then
                NextKey222.ProfilesService:InvalidateCache()
                if NextKey222.Debug then
                    NextKey222.Debug:Dev("profiles", "Cache invalidated due to frame event: " .. (event or "unknown"))
                end

                -- Trigger UI refresh for spec changes and roster updates
                if event == "PLAYER_SPECIALIZATION_CHANGED" or
                   event == "UNIT_SPECIALIZATION" or
                   event == "GROUP_ROSTER_UPDATE" then
                    if NextKey222.UI and NextKey222.UI.RefreshResults then
                        if NextKey222.Debug then
                            NextKey222.Debug:Dev("profiles", "Triggering UI refresh due to frame event " .. event)
                        end
                        C_Timer.After(0.1, function()
                            if NextKey222.UI and NextKey222.UI.RefreshResults then
                                NextKey222.UI:RefreshResults()
                                if NextKey222.Debug then
                                    NextKey222.Debug:Dev("profiles", "UI refresh completed for frame event " .. event)
                                end
                            end
                        end)
                    end
                end
            end
        end)

        -- Register the key events on the backup frame
        for _, eventName in ipairs({"PLAYER_SPECIALIZATION_CHANGED", "GROUP_ROSTER_UPDATE"}) do
            eventFrame:RegisterEvent(eventName)
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", "Backup frame registered for event: " .. eventName)
            end
        end

        if NextKey222.Debug then
            NextKey222.Debug:Dev("profiles", "Event-driven cache invalidation registered for " .. #events .. " events + backup frame")
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

    if source.role and not target.role then
        target.role = source.role
    end

    if source.specID and not target.specID then
        target.specID = source.specID
    end

    if source.specName and not target.specName then
        target.specName = source.specName
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

    if profile.class then
        profile.class = string.upper(profile.class)
    end

    profile.capabilities = profile.capabilities or {}

    if profile.specID and GetSpecializationInfoByID then
        local _, specName, _, _, _, role = GetSpecializationInfoByID(profile.specID)
        if specName and not profile.specName then
            profile.specName = specName
        end
        if role and not profile.role then
            profile.role = role
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

    if not profile.role and profile.class then
        profile.role = DEFAULT_CLASS_ROLE[profile.class] or "DAMAGER"
        
        -- Debug fallback logic
        if profile.class == "EVOKER" then
            local fallbackRole = DEFAULT_CLASS_ROLE[profile.class] or "DAMAGER"
            if NextKey222.Debug then
                NextKey222.Debug:Dev("profiles", string.format("Evoker Fallback: Using default role=%s for class=%s", fallbackRole, profile.class))
            end
        end
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
