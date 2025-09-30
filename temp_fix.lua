local file = io.open([[c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\NextKey\events\handlers.lua]], "w")
if not file then return end

local content = [[
-- MARK: Initialization
local _, NS = ...
local NextKey = NS.Addon

if not NextKey then return end

-- MARK: RaiderIO Integration

-- Function to sync addon data with Blizzard API
function NextKey:SyncWithBlizzardAPI(options)
    options = options or {}
    
    -- Check if we have a keystone in our bags
    local keystoneMapID, keystoneLevel = C_MythicPlus.GetOwnedKeystoneChallengeMapID(), C_MythicPlus.GetOwnedKeystoneLevel()
    if keystoneMapID and keystoneLevel then
        self:UpdatePlayerKeystone(keystoneMapID, keystoneLevel)
    else
        self:UpdatePlayerKeystone(nil, nil)
    end
    
    if options.announceNoChange then
        self:Print("Synced with Blizzard API")
    end
end

-- Function to import RaiderIO data
function NextKey:ImportRaiderIOData(silent)
    if not RaiderIO then
        if not silent then
            self:Print("RaiderIO addon is not installed or enabled.")
        end
        return false
    end
    
    local profile = RaiderIO.GetProfile("player")
    if not profile or not profile.mythicKeystoneProfile then
        if not silent then
            self:Print("No RaiderIO data found for your character.")
        end
        return false
    end
    
    -- Initialize season data if needed
    local seasonData = self.db.char.seasonData or {}
    self.db.char.seasonData = seasonData
    
    -- Initialize best levels if needed
    seasonData.bestLevels = seasonData.bestLevels or {}
    
    -- Update with fortified scores
    if profile.mythicKeystoneProfile.fortifiedDungeonScores then
        for dungeonId, dungeon in pairs(profile.mythicKeystoneProfile.fortifiedDungeonScores) do
            if not seasonData.bestLevels[dungeonId] or 
               (dungeon.score or 0) > (seasonData.bestLevels[dungeonId].score or 0) then
                seasonData.bestLevels[dungeonId] = seasonData.bestLevels[dungeonId] or {}
                seasonData.bestLevels[dungeonId].level = dungeon.level or 0
                seasonData.bestLevels[dungeonId].timed = dungeon.timed or false
                seasonData.bestLevels[dungeonId].score = dungeon.score or 0
            end
        end
    end
        
    -- Update with tyrannical scores
    if profile.mythicKeystoneProfile.tyrannicalDungeonScores then
        for dungeonId, dungeon in pairs(profile.mythicKeystoneProfile.tyrannicalDungeonScores) do
            if not seasonData.bestLevels[dungeonId] or 
               (dungeon.score or 0) > (seasonData.bestLevels[dungeonId].score or 0) then
                seasonData.bestLevels[dungeonId] = seasonData.bestLevels[dungeonId] or {}
                seasonData.bestLevels[dungeonId].level = dungeon.level or 0
                seasonData.bestLevels[dungeonId].timed = dungeon.timed or false
                seasonData.bestLevels[dungeonId].score = dungeon.score or 0
            end
        end
    end
        
    if not silent then
        self:Print("Successfully imported RaiderIO data.")
    end
        
    -- Update UI
    if self.RenderResults then
        self:RenderResults()
    end
    
    return true
end

-- Event handler registration
function NextKey:RegisterEventHandlers()
    -- Register for login/reload
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    
    -- Register for group changes
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
    
    -- Register for M+ completion
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnEvent")
end

-- Event handler
function NextKey:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Use a longer initial delay and multiple attempts to ensure RaiderIO is loaded
        local attempts = 0
        local function tryImport()
            if RaiderIO and RaiderIO.GetProfile then
                self:ImportRaiderIOData(true)
                self:SyncWithBlizzardAPI()
            elseif attempts < 5 then
                attempts = attempts + 1
                C_Timer.After(2, tryImport)
            end
        end
        
        -- Start first attempt after 3 seconds
        C_Timer.After(3, tryImport)
    elseif event == "GROUP_ROSTER_UPDATE" then
        local wasInGroup = self.lastGroupSize and self.lastGroupSize > 0
        local nowInGroup = IsInGroup()
        if wasInGroup ~= nowInGroup then
            self:ImportRaiderIOData(true)
            self:SyncWithBlizzardAPI()
        end
        self.lastGroupSize = GetNumGroupMembers()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        -- Wait a moment for everything to settle
        C_Timer.After(1, function()
            self:ImportRaiderIOData(true)
            self:SyncWithBlizzardAPI()
        end)
    end
end
]]

file:write(content)
file:close()