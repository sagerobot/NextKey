local _, NextKey222 = ...

-- Get addon reference (available after boot)
local function GetNextKey()
    return NextKey222.Addon
end

local function GetUtils()
    return NextKey222.Utils
end

---@class DungeonCard
---@field dungeonID number Dungeon identifier
---@field name string Localized dungeon name
---@field shortName string Short dungeon name for display
---@field fortifiedScore number Best fortified score
---@field tyrannicalScore number Best tyrannical score
---@field totalScore number Total score from both affixes
---@field bestLevel number Highest completed key level
---@field bestLevelAffix string Affix when highest key was completed
---@field likes table<string, boolean> Map of players who like this dungeon
---@field dislikes table<string, boolean> Map of players who dislike this dungeon
---@field trackedItems table<number, boolean> Map of item IDs being tracked
---@field customTrackedItems table<number, boolean> Map of custom item IDs added by players

---@class DungeonCards
local DungeonCards = {
    ---@type table<number, DungeonCard>
    dungeons = {},
    sortMethod = "alphabetical", -- "alphabetical", "highest", "lowest", "smart", "manual"
    scoreUpdated = false,
    preloadedTrinkets = {
        -- Pre-defined trinkets per dungeon
        -- Format: [dungeonID] = {itemID1, itemID2, ...}
    },
}

-- MARK: Card Management

---Create or update a dungeon card
---@param dungeonID number Dungeon identifier
---@param name? string Optional name for new cards
---@param shortName? string Optional short name for new cards
---@return DungeonCard
function DungeonCards:GetCard(dungeonID, name, shortName)
    -- Return existing card if found
    if self.dungeons[dungeonID] then
        -- Update names if provided
        if name then
            self.dungeons[dungeonID].name = name
            self.dungeons[dungeonID].shortName = shortName or name
        end
        return self.dungeons[dungeonID]
    end
    
    -- Require name for new cards
    if not name then
        error("Name required when creating new dungeon card")
    end
    
    -- Create new card
    self.dungeons[dungeonID] = {
        dungeonID = dungeonID,
        name = name,
        shortName = shortName or name,
        fortifiedScore = 0,
        tyrannicalScore = 0,
        totalScore = 0,
        bestLevel = 0,
        bestLevelAffix = "",
        likes = {},
        dislikes = {},
        trackedItems = {},
        customTrackedItems = {}
    }
    return self.dungeons[dungeonID]
end

---Update scores for a dungeon card
---@param dungeonID number
---@param fortifiedScore number
---@param tyrannicalScore number
---@param bestLevel number
---@param bestLevelAffix string
function DungeonCards:UpdateScores(dungeonID, fortifiedScore, tyrannicalScore, bestLevel, bestLevelAffix)
    -- Get existing card or create with fallback name
    local card = self.dungeons[dungeonID]
    if not card then
        -- Try to get name from portal data
        local dungeonName = nil
        if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[dungeonID] then
            dungeonName = NextKey.PortalData.dungeons[dungeonID].name
        end
        if not dungeonName then
            dungeonName = "Dungeon " .. dungeonID
        end
        card = self:GetCard(dungeonID, dungeonName, dungeonName)
    end
    
    card.fortifiedScore = fortifiedScore or 0
    card.tyrannicalScore = tyrannicalScore or 0
    card.totalScore = (fortifiedScore or 0) + (tyrannicalScore or 0)
    if bestLevel and bestLevel > card.bestLevel then
        card.bestLevel = bestLevel
        card.bestLevelAffix = bestLevelAffix
    end
    self.scoreUpdated = true
end

-- MARK: Preference Management

---Toggle like status for a dungeon
---@param dungeonID number
---@param playerName string
---@return boolean liked Current like status
function DungeonCards:ToggleLike(dungeonID, playerName)
    -- Functionality disabled
    return false
end

---Toggle dislike status for a dungeon
---@param dungeonID number
---@param playerName string
---@return boolean disliked Current dislike status
function DungeonCards:ToggleDislike(dungeonID, playerName)
    -- Functionality disabled
    return false
end

---Get formatted list of players who like/dislike a dungeon
---@param dungeonID number
---@return string likes, string dislikes
function DungeonCards:GetPreferenceTooltip(dungeonID)
    -- Get existing card or create with fallback name
    local card = self.dungeons[dungeonID]
    if not card then
        local dungeonName = "Dungeon " .. dungeonID
        card = self:GetCard(dungeonID, dungeonName, dungeonName)
    end
    
    local likes = {}
    for name in pairs(card.likes) do
        table.insert(likes, GetUtils().getShortName(name))
    end
    
    local dislikes = {}
    for name in pairs(card.dislikes) do
        table.insert(dislikes, GetUtils().getShortName(name))
    end
    
    return table.concat(likes, ", "), table.concat(dislikes, ", ")
end

-- MARK: Item Tracking

---Track an item for a dungeon
---@param dungeonID number
---@param itemID number
---@param isCustom boolean
function DungeonCards:TrackItem(dungeonID, itemID, isCustom, dungeonName)
    local card = self:GetCard(dungeonID, dungeonName, nil) -- Internal calls don't need names
    
    -- Initialize loot tracking data if needed
    if not card.lootData then
        card.lootData = {}
    end
    
    if isCustom then
        card.customTrackedItems[itemID] = true
    else
        card.trackedItems[itemID] = true
    end
    
    -- Initialize run counter for this item
    if not card.lootData[itemID] then
        card.lootData[itemID] = {
            runsSinceTracking = 0,
            historicalRuns = 0
        }
    end
end

---Untrack an item for a dungeon
---@param dungeonID number
---@param itemID number
---@param isCustom boolean
function DungeonCards:UntrackItem(dungeonID, itemID, isCustom)
    -- Get existing card or create with fallback name
    local card = self.dungeons[dungeonID]
    if not card then
        local dungeonName = "Dungeon " .. dungeonID
        card = self:GetCard(dungeonID, dungeonName, dungeonName)
    end
    
    if isCustom then
        card.customTrackedItems[itemID] = nil
    else
        card.trackedItems[itemID] = nil
    end
    
    -- Clean up loot data if item is no longer tracked
    if card.lootData and card.lootData[itemID] then
        -- Only remove if not featured and not custom tracked
        if not card.trackedItems[itemID] and not card.customTrackedItems[itemID] then
            card.lootData[itemID] = nil
        end
    end
end

---Increment run counter for tracked items
---@param dungeonID number
---@param itemID number
function DungeonCards:IncrementRunCounter(dungeonID, itemID)
    -- Get existing card or create with fallback name
    local card = self.dungeons[dungeonID]
    if not card then
        local dungeonName = "Dungeon " .. dungeonID
        card = self:GetCard(dungeonID, dungeonName, dungeonName)
    end
    
    if not card.lootData then
        card.lootData = {}
    end
    
    if not card.lootData[itemID] then
        card.lootData[itemID] = {
            runsSinceTracking = 0,
            historicalRuns = 0
        }
    end
    
    card.lootData[itemID].runsSinceTracking = card.lootData[itemID].runsSinceTracking + 1
    NextKey222.Debug:Dev("lootwindow", "Incremented run counter for item", itemID, "in dungeon", dungeonID, "new count:", card.lootData[itemID].runsSinceTracking)
end

---Get run counter for an item
---@param dungeonID number
---@param itemID number
---@return number runsSinceTracking
function DungeonCards:GetRunCount(dungeonID, itemID)
    -- Get existing card or create with fallback name
    local card = self.dungeons[dungeonID]
    if not card then
        local dungeonName = "Dungeon " .. dungeonID
        card = self:GetCard(dungeonID, dungeonName, dungeonName)
    end
    
    if card.lootData and card.lootData[itemID] then
        return card.lootData[itemID].runsSinceTracking or 0
    end
    return 0
end

---Calculate drop chance based on run count
---@param runs number Number of runs completed
---@return number dropChance Percentage
function DungeonCards:CalculateDropChance(runs)
    if runs <= 0 then
        return 100.0 -- Next run is guaranteed!
    end
    return 100.0 / (runs + 1)
end

-- MARK: Sorting

---Calculate a preference score for a dungeon card
---@param card DungeonCard The dungeon card to score
---@param partySize number Current party size
---@return number score, number likes, number dislikes
function DungeonCards:GetPreferenceScore(card, partySize)
    -- Functionality disabled, returning neutral score
    return 0, 0, 0
end

---Get all dungeon cards sorted by the current method
---@return DungeonCard[]
function DungeonCards:GetSortedCards()
    local cards = {}
    for _, card in pairs(self.dungeons) do
        table.insert(cards, card)
    end
    
    -- Get current party size for preference weighting
    local partySize = IsInRaid() and GetNumGroupMembers() or (IsInGroup() and GetNumGroupMembers() or 1)
    
    local sortFunctions = {
        highest = function(a, b)
            return a.totalScore > b.totalScore
        end,
        lowest = function(a, b)
            return a.totalScore < b.totalScore
        end,
        smart = function(a, b)
            -- Get weighted preference scores
            local aScore, aLikes, aDislikes = self:GetPreferenceScore(a, partySize)
            local bScore, bLikes, bDislikes = self:GetPreferenceScore(b, partySize)
            
            -- First compare strong preferences
            if aLikes == partySize and bLikes < partySize then return true end
            if bLikes == partySize and aLikes < partySize then return false end
            if aDislikes == partySize and bDislikes < partySize then return false end
            if bDislikes == partySize and aDislikes < partySize then return true end
            
            -- Then compare weighted scores
            if aScore ~= bScore then
                return aScore > bScore
            end
            
            -- Fall back to dungeon score
            if a.totalScore ~= b.totalScore then
                return a.totalScore > b.totalScore
            end
            
            -- Finally sort alphabetically
            return a.name < b.name
        end,
        alphabetical = function(a, b)
            return a.name < b.name
        end
    }

    local sortFunc = sortFunctions[self.sortMethod] or sortFunctions.alphabetical
    table.sort(cards, sortFunc)
    
    return cards
end

---Set manual sort order for a dungeon
---Set the current sort method
---@param method string "alphabetical"|"highest"|"lowest"|"smart"
function DungeonCards:SetSortMethod(method)
    self.sortMethod = method
    -- Save to DB
    NextKey.db.char.dungeonSort = method
end

-- MARK: Initialization
-- MARK: Preference Management

---Save dungeon preferences to character DB
function DungeonCards:SavePreferences()
    -- Functionality disabled
end

---Load dungeon preferences from character DB
function DungeonCards:LoadPreferences()
    -- Functionality disabled
end

-- MARK: Loot Tracking Persistence

function DungeonCards:SaveLootTracking()
    if not NextKey.db or not NextKey.db.char then
        NextKey222.Debug:Error("lootwindow", "Cannot save loot tracking - database not available")
        return
    end
    
    local lootData = {}
    local totalDungeons = 0
    local savedDungeons = 0
    
    for dungeonID, card in pairs(self.dungeons) do
        totalDungeons = totalDungeons + 1
        
        -- Debug: Check what's in this card
        local hasTrackedItems = next(card.trackedItems) ~= nil
        local hasCustomItems = next(card.customTrackedItems) ~= nil
        local hasLootData = (card.lootData and next(card.lootData)) ~= nil
        
        NextKey222.Debug:Dev("lootwindow", "Checking dungeon", dungeonID, "tracked:", hasTrackedItems, "custom:", hasCustomItems, "lootData:", hasLootData)
        
        -- Save tracking data and run counters
        if hasTrackedItems or hasCustomItems or hasLootData then
            savedDungeons = savedDungeons + 1
            lootData[dungeonID] = {
                name = card.name,           -- Store dungeon name for persistence
                shortName = card.shortName, -- Store short name for persistence
                defaultItems = {},
                customItems = {},
                lootData = {}
            }
            
            -- Save tracked items
            for itemID, tracked in pairs(card.trackedItems) do
                lootData[dungeonID].defaultItems[itemID] = tracked
                NextKey222.Debug:Dev("lootwindow", "Saving tracked item", itemID, "for dungeon", dungeonID)
            end
            
            -- Save custom tracked items
            for itemID in pairs(card.customTrackedItems) do
                lootData[dungeonID].customItems[itemID] = true
                NextKey222.Debug:Dev("lootwindow", "Saving custom item", itemID, "for dungeon", dungeonID)
            end
            
            -- Save run counter data
            if card.lootData then
                for itemID, data in pairs(card.lootData) do
                    lootData[dungeonID].lootData[itemID] = {
                        runsSinceTracking = data.runsSinceTracking,
                        historicalRuns = data.historicalRuns
                    }
                    NextKey222.Debug:Dev("lootwindow", "Saving loot data for item", itemID, "runs:", data.runsSinceTracking)
                end
            end
        end
    end
    
    NextKey.db.char.lootTracking = lootData
    NextKey222.Debug:Dev("lootwindow", "Saved loot tracking data for", savedDungeons, "of", totalDungeons, "dungeons")
    
    -- Debug: Show the actual saved data structure
    NextKey222.Debug:Dev("lootwindow", "Final saved data structure:")
    for dungeonID, data in pairs(lootData) do
        NextKey222.Debug:Dev("lootwindow", "  Dungeon", dungeonID, ":", data.name)
        for itemID in pairs(data.defaultItems) do
            NextKey222.Debug:Dev("lootwindow", "    Tracked item:", itemID)
        end
        for itemID in pairs(data.customItems) do
            NextKey222.Debug:Dev("lootwindow", "    Custom item:", itemID)
        end
        for itemID, lootData in pairs(data.lootData) do
            NextKey222.Debug:Dev("lootwindow", "    Loot data item:", itemID, "runs:", lootData.runsSinceTracking)
        end
    end
    
    -- Debug: Show what we actually saved
    for dungeonID, data in pairs(lootData) do
        local trackedCount = 0
        local customCount = 0
        local lootDataCount = 0
        
        for _ in pairs(data.defaultItems) do trackedCount = trackedCount + 1 end
        for _ in pairs(data.customItems) do customCount = customCount + 1 end
        for _ in pairs(data.lootData) do lootDataCount = lootDataCount + 1 end
        
        NextKey222.Debug:Dev("lootwindow", "Saved dungeon", dungeonID, "name:", data.name, "tracked items:", trackedCount, "custom items:", customCount, "loot data items:", lootDataCount)
    end
end

function DungeonCards:LoadLootTracking()
    if not NextKey.db or not NextKey.db.char then
        NextKey222.Debug:Error("lootwindow", "Cannot load loot tracking - database not available")
        return
    end
    
    local lootData = NextKey.db.char.lootTracking
    if not lootData then
        NextKey222.Debug:Dev("lootwindow", "No saved loot tracking data found")
        return
    end
    
    local foundDungeonCount = 0
    for _ in pairs(lootData) do foundDungeonCount = foundDungeonCount + 1 end
    NextKey222.Debug:Dev("lootwindow", "Found loot tracking data for", foundDungeonCount, "dungeons")
    
    for dungeonID, tracking in pairs(lootData) do
        NextKey222.Debug:Dev("lootwindow", "Loading tracking for dungeon", dungeonID, "name:", tracking.name)
        
        -- Use stored name as fallback, or generate a fallback name
        local dungeonName = tracking.name or ("Dungeon " .. dungeonID)
        local dungeonShortName = tracking.shortName or dungeonName
        
        -- Ensure dungeonName is never nil before calling GetCard
        if not dungeonName then
            dungeonName = "Unknown Dungeon"
            NextKey222.Debug:Error("dungeonCards", "dungeonName is still nil after fallback for dungeonID:", dungeonID)
        end
        
        local card = self:GetCard(dungeonID, dungeonName, dungeonShortName)
        
        if tracking.defaultItems then
            NextKey222.Debug:Dev("lootwindow", "Loading", table.getn(tracking.defaultItems), "default items for dungeon", dungeonID)
            for itemID, tracked in pairs(tracking.defaultItems) do
                card.trackedItems[itemID] = tracked
                NextKey222.Debug:Dev("lootwindow", "Loaded tracked item", itemID, "for dungeon", dungeonID)
            end
        end
        
        if tracking.customItems then
            NextKey222.Debug:Dev("lootwindow", "Loading", table.getn(tracking.customItems), "custom items for dungeon", dungeonID)
            for itemID in pairs(tracking.customItems) do
                card.customTrackedItems[itemID] = true
                NextKey222.Debug:Dev("lootwindow", "Loaded custom item", itemID, "for dungeon", dungeonID)
            end
        end
        
        -- Load run counter data
        if tracking.lootData then
            NextKey222.Debug:Dev("lootwindow", "Loading loot data for", table.getn(tracking.lootData), "items for dungeon", dungeonID)
            if not card.lootData then
                card.lootData = {}
            end
            for itemID, data in pairs(tracking.lootData) do
                card.lootData[itemID] = {
                    runsSinceTracking = data.runsSinceTracking or 0,
                    historicalRuns = data.historicalRuns or 0
                }
                NextKey222.Debug:Dev("lootwindow", "Loaded loot data for item", itemID, "runs:", data.runsSinceTracking)
            end
        end
    end
    
    NextKey222.Debug:Dev("lootwindow", "Loaded loot tracking data for", table.getn(lootData), "dungeons")
end

function DungeonCards:Init()
    -- Load sort preference
    self.sortMethod = NextKey.db.char.dungeonSort or "alphabetical"
    
    -- Initialize dungeon data from current season FIRST
    local season = C_MythicPlus.GetCurrentSeason()
    if season then
        local seasonDungeons = C_MythicPlus.GetSeasonDungeonInfo(season)
        if seasonDungeons then
            for _, info in ipairs(seasonDungeons) do
                self:GetCard(info.id, info.name, info.shortName)
            end
        end
    end
    
    -- Load saved loot tracking data AFTER dungeon cards exist
    self:LoadLootTracking()
    
    -- Update scores from RaiderIO data LAST
    if NextKey222.RaiderIO then
        local profile = NextKey222.RaiderIO:GetProfile(NextKey.playerFullName)
        if profile and profile.mythicKeystoneProfile then
            local mp = profile.mythicKeystoneProfile
            for dungeonID, card in pairs(self.dungeons) do
                if mp.fortifiedDungeonScores and mp.fortifiedDungeonScores[dungeonID] then
                    local fort = mp.fortifiedDungeonScores[dungeonID]
                    local tyr = mp.tyrannicalDungeonScores and mp.tyrannicalDungeonScores[dungeonID]
                    self:UpdateScores(
                        dungeonID,
                        fort.score,
                        tyr and tyr.score or 0,
                        fort.level > (tyr and tyr.level or 0) and fort.level or (tyr and tyr.level or 0),
                        fort.level > (tyr and tyr.level or 0) and "fortified" or "tyrannical"
                    )
                end
            end
        end
    end
end

NextKey.DungeonCards = DungeonCards
return DungeonCards