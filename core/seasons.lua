local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local Utils = NextKey222.Utils

local Seasons = {}

-- MARK: Season Data Management
function NextKey:GetCurrentSeasonKey()
    if self.CurrentSeasonKey then
        return self.CurrentSeasonKey
    end
    if self.PortalData and self.PortalData.name then
        return self.PortalData.name
    end
    if type(NextKey_CurrentSeasonKey) == "string" then
        return NextKey_CurrentSeasonKey
    end
    return "UNKNOWN_SEASON"
end

function NextKey:EnsureSeasonData(targetSeasonKey)
    if not (self.db and self.db.char) then
        return nil
    end

    local mp = self.db.char.mythicPlus
    if type(mp) ~= "table" then
        mp = { activeSeason = nil, seasons = {} }
        self.db.char.mythicPlus = mp
    end

    mp.seasons = mp.seasons or {}

    local seasonKey = targetSeasonKey or mp.activeSeason or self:GetCurrentSeasonKey()
    if seasonKey and mp.activeSeason ~= seasonKey then
        mp.activeSeason = seasonKey
    end

    if not mp.activeSeason then
        return nil
    end

    if not mp.seasons[mp.activeSeason] then
        mp.seasons[mp.activeSeason] = {
            bestLevels = {},
            lastSyncSource = nil,
            lastSyncTime = 0,
            currentScore = 0,
        }
    end

    local seasonData = mp.seasons[mp.activeSeason]
    seasonData.bestLevels = seasonData.bestLevels or {}
    return seasonData, mp.activeSeason
end

function NextKey:GetCurrentSeasonData()
    return self:EnsureSeasonData()
end

local function isBetterRun(existing, candidate)
    if not candidate or (candidate.level or 0) <= 0 then
        return false
    end
    if not existing then
        return true
    end

    local candidateLevel = candidate.level or 0
    local existingLevel = existing.level or 0
    if candidateLevel ~= existingLevel then
        return candidateLevel > existingLevel
    end

    local candidateChests = candidate.chests or 0
    local existingChests = existing.chests or 0
    if candidateChests ~= existingChests then
        return candidateChests > existingChests
    end

    local candidateFraction = candidate.fractionalTime or math.huge
    local existingFraction = existing.fractionalTime or math.huge
    if candidateFraction ~= existingFraction then
        return candidateFraction < existingFraction
    end

    return (candidate.updatedAt or 0) > (existing.updatedAt or 0)
end

function NextKey:UpdateSeasonBest(mapID, data)
    local seasonData = self:EnsureSeasonData()
    if not seasonData then
        return false, nil
    end

    local normalizedMapID = Utils.normalizeMapID(mapID)
    if not normalizedMapID then
        return false, seasonData
    end

    if type(data) ~= "table" then
        return false, seasonData
    end

    local payload = {
        level = tonumber(data.level) or 0,
        chests = tonumber(data.chests) or 0,
        fractionalTime = tonumber(data.fractionalTime),
        timed = data.timed == true,
        source = data.source,
        updatedAt = data.updatedAt or Utils.currentTime(),
        io = data.io and tonumber(data.io) or nil,
    }

    if payload.level <= 0 then
        seasonData.bestLevels[normalizedMapID] = nil
        return true, seasonData
    end

    local existing = seasonData.bestLevels[normalizedMapID]
    if isBetterRun(existing, payload) then
        seasonData.bestLevels[normalizedMapID] = payload
        return true, seasonData
    end

    return false, seasonData
end

function NextKey:GetSeasonBestEntry(mapID, seasonKey)
    local seasonData = self:EnsureSeasonData(seasonKey)
    if not seasonData then
        return nil
    end
    return seasonData.bestLevels and seasonData.bestLevels[Utils.normalizeMapID(mapID)] or nil
end

function NextKey:GetSeasonBestLevel(mapID, seasonKey)
    local entry = self:GetSeasonBestEntry(mapID, seasonKey)
    return entry and entry.level or 0
end

function NextKey:GetSeasonBestLevels(seasonKey)
    local seasonData = self:EnsureSeasonData(seasonKey)
    if not seasonData then
        return {}
    end
    return seasonData.bestLevels
end

-- MARK: Deprecated - Removed duplicate EstimateRunScore function
-- Use NextKey222.IOCalculator:EstimateRunScore() or NextKey:EstimateRunScore() instead
-- The duplicate implementation has been consolidated to avoid drift

NextKey222.Seasons = Seasons
NextKey222.RegisterModule("Seasons", Seasons)

-- Module interface
function Seasons:Initialize()
    return true
end

return Seasons