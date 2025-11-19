-- MARK: Module
-- RaiderIO Integration Module - interfaces with RaiderIO addon
local _, NextKey222 = ...
local NextKey = NextKey222.Addon

---@class RaiderIOAddon
---@field GetProfile fun(name: string, realm?: string): RaiderIOProfile?
---@field GetScoreColor fun(score: number): number, number, number
_G.RaiderIO = _G.RaiderIO

---@class RaiderIOProfile
---@field mythicKeystoneProfile RaiderIOMythicKeystoneProfile
---@field name string
---@field realm string
---@field class string

---@class RaiderIOMythicKeystoneProfile
---@field currentScore number
---@field previousScore number
---@field fortifiedDungeonScores table<number, RaiderIODungeonScore>
---@field tyrannicalDungeonScores table<number, RaiderIODungeonScore>
---@field keystoneFivePlus number
---@field keystoneTenPlus number
---@field keystoneFifteenPlus number
---@field keystoneTwentyPlus number
---@field mplusCurrent RaiderIOSeasonRoles

---@class RaiderIODungeonScore
---@field score number
---@field level number
---@field chests number
---@field fractionalTime number?

---@class RaiderIOSeasonRoles
---@field roles RaiderIORole[]
---@field score number

---@alias RaiderIORole { [1]: string, [2]: string }

-- MARK: Module Setup
local RaiderIO = {}

-- Register RaiderIO module
NextKey222.RaiderIO = RaiderIO
NextKey222.RegisterModule("RaiderIO", RaiderIO)

-- MARK: Profile Cache
local profileCache = {}
local cacheTimeout = 300 -- 5 minutes

-- MARK: Core Functions

--- Retrieves a player's Raider.IO profile, using a cache to avoid redundant API calls.
---@param target string The player's unit token (e.g., "player", "target") or a "Name-Realm" string.
---@param skipCache boolean? If true, the cache will be bypassed and fresh data will be fetched.
---@return table|nil, string|nil The player's Raider.IO profile, or nil and an error message if not found.
function RaiderIO:GetProfile(target, skipCache)
    -- Make sure we can access the function safely
    if not self or not target then
        return nil, "Invalid parameters"
    end
    -- Validate RaiderIO addon
    if not _G.RaiderIO then
        return nil, "RaiderIO addon not installed"
    end

    -- Get player info
    local name, realm
    if target:find("-") then
        name, realm = target:match("(.+)-(.+)")
    else
        name = UnitName(target)
        realm = GetNormalizedRealmName()
    end
    if not name then return nil, "Invalid target" end

    -- Check cache
    local cacheKey = name .. "-" .. realm
    local cached = profileCache[cacheKey]
    if not skipCache and cached and cached.timestamp + cacheTimeout > GetTime() then
        return cached.data
    end

    -- Get fresh data
    local profile = _G.RaiderIO.GetProfile(name, realm)
    if profile and profile.mythicKeystoneProfile then
        profileCache[cacheKey] = {
            timestamp = GetTime(),
            data = profile
        }
        return profile
    end
    
    return nil, "No RaiderIO data found"
end

--- Formats the dungeon scores from a Raider.IO profile into a structured table.
---@param profile table The Raider.IO profile of the player.
---@return table|nil A table of formatted dungeon scores, or nil if the profile is invalid.
function RaiderIO:FormatDungeonScores(profile)
    if not profile or not profile.mythicKeystoneProfile then
        return nil
    end

    local scores = {}
    local p = profile.mythicKeystoneProfile

    -- Handle both affixes
    for _, affix in ipairs({"fortified", "tyrannical"}) do
        local dungeonScores = p[affix .. "DungeonScores"]
        if dungeonScores then
            for dungeonId, data in pairs(dungeonScores) do
                scores[dungeonId] = scores[dungeonId] or {}
                scores[dungeonId][affix] = {
                    score = data.score or 0,
                    level = data.level or 0,
                    chests = data.chests or 0,
                    fractionalTime = data.fractionalTime
                }
            end
        end
    end

    return scores
end

--- Extracts the number of runs completed at various keystone levels from a Raider.IO profile.
---@param profile table The Raider.IO profile of the player.
---@return table|nil A table with the counts of +5, +10, +15, and +20 keys completed, or nil if the profile is invalid.
function RaiderIO:GetRunCounts(profile)
    if not profile or not profile.mythicKeystoneProfile then
        return nil
    end

    local p = profile.mythicKeystoneProfile
    return {
        plus5 = p.keystoneFivePlus or 0,
        plus10 = p.keystoneTenPlus or 0,
        plus15 = p.keystoneFifteenPlus or 0,
        plus20 = p.keystoneTwentyPlus or 0
    }
end

--- Retrieves role-specific performance data, such as scores for tanking, healing, and DPS, from a Raider.IO profile.
---@param profile table The Raider.IO profile of the player.
---@return table|nil A table of role-specific data, or nil if the profile is invalid.
function RaiderIO:GetRoleData(profile)
    if not profile or not profile.mythicKeystoneProfile then
        return nil
    end

    local p = profile.mythicKeystoneProfile
    local roleData = {}

    -- Current season roles
    if p.mplusCurrent and p.mplusCurrent.roles then
        for _, role in ipairs(p.mplusCurrent.roles) do
            if role[1] and role[2] then -- role type and completion status
                roleData[role[1]] = {
                    status = role[2],
                    score = p.mplusCurrent.score or 0
                }
            end
        end
    end

    return roleData
end

--- Creates a complete data payload for syncing a player's Raider.IO data with other addons or services.
---@param target string The player's unit token or "Name-Realm" string.
---@return table|nil, string|nil The formatted data payload, or nil and an error message if the profile cannot be retrieved.
function RaiderIO:FormatSyncPayload(target)
    local profile, err = self:GetProfile(target)
    if not profile then
        return nil, err
    end

    return {
        version = 1, -- Protocol version
        timestamp = GetTime(),
        scores = {
            current = profile.mythicKeystoneProfile.currentScore or 0,
            previous = profile.mythicKeystoneProfile.previousScore or 0,
            dungeons = self:FormatDungeonScores(profile)
        },
        runCounts = self:GetRunCounts(profile),
        roles = self:GetRoleData(profile)
    }
end

-- MARK: Score Colors
-- Score color formatting functions

--- Retrieves the appropriate color for a given Mythic+ score, using the Raider.IO addon's color scale if available.
---@param score number The Mythic+ score.
---@return number, number, number The R, G, and B components of the color, ranging from 0 to 1.
function RaiderIO:GetScoreColor(score)
    if _G.RaiderIO and _G.RaiderIO.GetScoreColor then
        return _G.RaiderIO.GetScoreColor(score)
    end
    -- Fallback to game API if RaiderIO isn't available
    local color = C_ChallengeMode.GetDungeonScoreRarityColor(score)
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1 -- White as final fallback
end

--- Formats a Mythic+ score as a color-coded string for display in the game UI.
---@param score number The Mythic+ score.
---@return string The color-coded score string.
function RaiderIO:FormatScore(score)
    local r, g, b = self:GetScoreColor(score)
    return string.format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, score)
end