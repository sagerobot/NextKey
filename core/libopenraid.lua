-- MARK: LibOpenRaid Integration Module
local _, NextKey222 = ...

-- LibOpenRaid Integration module
local LibOpenRaidIntegration = {}
NextKey222.LibOpenRaidIntegration = LibOpenRaidIntegration

-- Register with module system
NextKey222.RegisterModule("LibOpenRaidIntegration", LibOpenRaidIntegration)

-- Get the LibOpenRaid library
local openRaidLib = nil

-- MARK: Initialization
function LibOpenRaidIntegration:Initialize()
    -- Get LibOpenRaid library
    if LibStub then
        local success, lib = pcall(LibStub.GetLibrary, LibStub, "LibOpenRaid-1.0")
        if success and lib then
            openRaidLib = lib
            NextKey222.Debug:Dev("libopenraid", "LibOpenRaid-1.0 loaded successfully")
            
            -- Register callbacks
            self:RegisterCallbacks()
            
            return true
        else
            NextKey222.Debug:Dev("libopenraid", "Failed to load LibOpenRaid-1.0:", lib)
        end
    end
    
    NextKey222.Debug:Dev("libopenraid", "LibOpenRaid-1.0 not available")
    return false
end

-- MARK: Callback Registration
function LibOpenRaidIntegration:RegisterCallbacks()
    if not openRaidLib then return end
    
    -- Register keystone update callback
    openRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
    openRaidLib.RegisterCallback(self, "KeystoneWipe", "OnKeystoneWipe")
    
    NextKey222.Debug:Dev("libopenraid", "Callbacks registered")
end

-- MARK: Keystone Data Access
function LibOpenRaidIntegration:GetAllKeystones()
    NextKey222.Debug:Dev("libopenraid", "=== GetAllKeystones() called ===")
    if not openRaidLib then 
        NextKey222.Debug:Dev("libopenraid", "openRaidLib is nil, returning empty table")
        return {} 
    end
    
    NextKey222.Debug:Dev("libopenraid", "openRaidLib available, calling GetAllKeystonesInfo()")
    local allKeystones = openRaidLib.GetAllKeystonesInfo()
    local nextKeyFormat = {}
    NextKey222.Debug:Dev("libopenraid", "GetAllKeystonesInfo() returned:", allKeystones and "data" or "nil")
    
    NextKey222.Debug:Dev("libopenraid", "Raw LibOpenRaid data:")
    if allKeystones then
        for playerName, keystoneInfo in pairs(allKeystones) do
            NextKey222.Debug:Dev("libopenraid", "  Player:", playerName)
            NextKey222.Debug:Dev("libopenraid", "    mythicPlusMapID:", keystoneInfo.mythicPlusMapID or "NIL")
            NextKey222.Debug:Dev("libopenraid", "    level:", keystoneInfo.level or "NIL")
            NextKey222.Debug:Dev("libopenraid", "    mapID:", keystoneInfo.mapID or "NIL")
            NextKey222.Debug:Dev("libopenraid", "    challengeMapID:", keystoneInfo.challengeMapID or "NIL")
            NextKey222.Debug:Dev("libopenraid", "    All fields:", tostring(keystoneInfo))
            
            -- Debug: Print all available fields
            for k, v in pairs(keystoneInfo) do
                NextKey222.Debug:Dev("libopenraid", "      " .. tostring(k) .. ":", tostring(v))
            end
        end
    else
        NextKey222.Debug:Dev("libopenraid", "  allKeystones is nil!")
    end
    
    if allKeystones then
        for playerName, keystoneInfo in pairs(allKeystones) do
            NextKey222.Debug:Dev("libopenraid", "Processing player:", playerName)
            
            if keystoneInfo then
                NextKey222.Debug:Dev("libopenraid", "  Has keystoneInfo")
                NextKey222.Debug:Dev("libopenraid", "  mythicPlusMapID check:", keystoneInfo.mythicPlusMapID, type(keystoneInfo.mythicPlusMapID))
                NextKey222.Debug:Dev("libopenraid", "  level check:", keystoneInfo.level, type(keystoneInfo.level))
                
                if keystoneInfo.level then
                    NextKey222.Debug:Dev("libopenraid", "  ✓ Valid keystone data found")
                    
                    -- Choose the best dungeonID from available fields
                    -- Priority: challengeMapID > mythicPlusMapID > mapID
                    local dungeonID = 0
                    if keystoneInfo.challengeMapID and keystoneInfo.challengeMapID > 0 then
                        dungeonID = keystoneInfo.challengeMapID
                        NextKey222.Debug:Dev("libopenraid", "  Using challengeMapID:", dungeonID)
                    elseif keystoneInfo.mythicPlusMapID and keystoneInfo.mythicPlusMapID > 0 then
                        dungeonID = keystoneInfo.mythicPlusMapID
                        NextKey222.Debug:Dev("libopenraid", "  Using mythicPlusMapID:", dungeonID)
                    elseif keystoneInfo.mapID and keystoneInfo.mapID > 0 then
                        dungeonID = keystoneInfo.mapID
                        NextKey222.Debug:Dev("libopenraid", "  Using mapID:", dungeonID)
                    else
                        NextKey222.Debug:Dev("libopenraid", "  No valid ID found, using 0")
                    end
                    
                    -- Convert LibOpenRaid format to NextKey format
                    local shortName = playerName:match("^([^%-]+)") or playerName
                    local keyData = {
                        dungeonID = dungeonID,
                        level = keystoneInfo.level,
                        mapID = keystoneInfo.mapID,
                        challengeMapID = keystoneInfo.challengeMapID,
                        mythicPlusMapID = keystoneInfo.mythicPlusMapID,
                        ownerName = playerName,
                        ownerShort = shortName,
                        classID = keystoneInfo.classID,
                        class = keystoneInfo.classID and select(2, GetClassInfo(keystoneInfo.classID)) or "WARRIOR",
                        rating = keystoneInfo.rating or 0,
                        source = "libopenraid",
                        timestamp = GetTime()
                    }
                    NextKey222.Debug:Dev("libopenraid", "  Created keyData with dungeonID:", keyData.dungeonID)
                    -- Use short name as key to prevent duplicates
                    nextKeyFormat[shortName] = keyData
                else
                    NextKey222.Debug:Dev("libopenraid", "  ✗ Missing level or keystone data")
                end
            else
                NextKey222.Debug:Dev("libopenraid", "  ✗ No keystoneInfo")
            end
        end
    end
    
    NextKey222.Debug:Dev("libopenraid", "Retrieved", self:CountTable(nextKeyFormat), "keystones")
    return nextKeyFormat
end

function LibOpenRaidIntegration:GetPlayerKeystone(unitId)
    if not openRaidLib then return nil end
    
    local keystoneInfo = openRaidLib.GetKeystoneInfo(unitId or "player")
    if not keystoneInfo or not keystoneInfo.level then
        return nil
    end
    
    -- Choose the best dungeonID from available fields
    local dungeonID = 0
    if keystoneInfo.challengeMapID and keystoneInfo.challengeMapID > 0 then
        dungeonID = keystoneInfo.challengeMapID
    elseif keystoneInfo.mythicPlusMapID and keystoneInfo.mythicPlusMapID > 0 then
        dungeonID = keystoneInfo.mythicPlusMapID
    elseif keystoneInfo.mapID and keystoneInfo.mapID > 0 then
        dungeonID = keystoneInfo.mapID
    end
    
    local playerName = UnitName(unitId or "player")
    local fullName = NextKey222.Utils.safeGetName(unitId or "player")
    
    return {
        dungeonID = dungeonID,
        level = keystoneInfo.level,
        mapID = keystoneInfo.mapID,
        challengeMapID = keystoneInfo.challengeMapID,
        mythicPlusMapID = keystoneInfo.mythicPlusMapID,
        ownerName = fullName,
        ownerShort = playerName,
        classID = keystoneInfo.classID,
        class = keystoneInfo.classID and select(2, GetClassInfo(keystoneInfo.classID)) or NextKey222.Utils.safeGetClass(unitId or "player"),
        rating = keystoneInfo.rating or 0,
        source = "libopenraid",
        timestamp = GetTime()
    }
end

-- MARK: Keystone Requests
function LibOpenRaidIntegration:RequestKeystones()
    if not openRaidLib then 
        NextKey222.Debug:Dev("libopenraid", "Cannot request keystones - LibOpenRaid not available")
        return false 
    end
    
    local success = false
    
    -- Try party request first
    if IsInGroup() and not IsInRaid() then
        success = openRaidLib.RequestKeystoneDataFromParty()
        NextKey222.Debug:Dev("libopenraid", "Requested keystones from party, success:", success)
    elseif IsInRaid() then
        success = openRaidLib.RequestKeystoneDataFromRaid()
        NextKey222.Debug:Dev("libopenraid", "Requested keystones from raid, success:", success)
    else
        NextKey222.Debug:Dev("libopenraid", "Not in group, cannot request keystones")
    end
    
    return success
end

function LibOpenRaidIntegration:RequestGuildKeystones()
    if not openRaidLib then return false end
    
    local success = openRaidLib.RequestKeystoneDataFromGuild()
    NextKey222.Debug:Dev("libopenraid", "Requested keystones from guild, success:", success)
    return success
end

-- Expose LibOpenRaid instance for direct access
function LibOpenRaidIntegration:GetLibOpenRaid()
    return openRaidLib
end

-- MARK: Callback Handlers
function LibOpenRaidIntegration:OnKeystoneUpdate(unitName, keystoneInfo, allKeystoneInfo)
    NextKey222.Debug:Dev("libopenraid", "Keystone update received from", unitName)
    
    if keystoneInfo and keystoneInfo.level and keystoneInfo.level > 0 then
        local mapName = ""
        if keystoneInfo.mythicPlusMapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            mapName = C_ChallengeMode.GetMapUIInfo(keystoneInfo.mythicPlusMapID) or "Unknown"
        end
        NextKey222.Debug:Dev("libopenraid", unitName, "has", keystoneInfo.level, mapName, "keystone")
        
        -- Store guild keystone in NextKey's guild cache (like Details! does)
        local NextKey = NextKey222.Addon
        if NextKey and NextKey.StoreGuildKeystone then
            local dungeonID = keystoneInfo.mythicPlusMapID or keystoneInfo.mapID or 0
            NextKey:StoreGuildKeystone(unitName, dungeonID, keystoneInfo.level, "libopenraid")
            print("NextKey LIBOPENRAID: Stored guild keystone from", unitName, "- Level", keystoneInfo.level)
            
            -- Clear cached keys to force refresh
            NextKey.cachedKeys = nil
        end
    end
    
    -- Trigger UI update if main window is open
    local NextKey = NextKey222.Addon
    if NextKey then
        -- Clear cached keys to force refresh
        NextKey.cachedKeys = nil
        
        -- Update UI if it's visible
        if NextKey222.UI and NextKey222.UI.mainFrame and NextKey222.UI.mainFrame:IsShown() then
            NextKey222.Debug:Dev("libopenraid", "Refreshing UI due to keystone update")
            if NextKey222.UI.viewMode == "dungeons" then
                NextKey222.UI:RenderDungeonCards()
            else
                NextKey222.UI:RenderResults()
            end
        end
    end
end

function LibOpenRaidIntegration:OnKeystoneWipe(allKeystoneInfo)
    NextKey222.Debug:Dev("libopenraid", "Keystone data wiped")
    
    -- Trigger UI update if main window is open
    local NextKey = NextKey222.Addon
    if NextKey then
        -- Clear cached keys to force refresh
        NextKey.cachedKeys = nil
        
        -- Update UI if it's visible
        if NextKey222.UI and NextKey222.UI.mainFrame and NextKey222.UI.mainFrame:IsShown() then
            print("NextKey LIBOPENRAID: Refreshing UI due to keystone wipe")
            if NextKey222.UI.viewMode == "dungeons" then
                NextKey222.UI:RenderDungeonCards()
            else
                NextKey222.UI:RenderResults()
            end
        end
    end
end

-- MARK: Utility Functions
function LibOpenRaidIntegration:IsAvailable()
    return openRaidLib ~= nil
end

function LibOpenRaidIntegration:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- MARK: Public Interface
function LibOpenRaidIntegration:GetLibrary()
    return openRaidLib
end

return LibOpenRaidIntegration