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
    local card = self:GetCard(dungeonID)
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
    local card = self:GetCard(dungeonID)
    if card.likes[playerName] then
        card.likes[playerName] = nil
        self:SavePreferences()
        if playerName == NextKey.playerFullName then
            NextKey:BroadcastPreferences()
        end
        return false
    else
        card.likes[playerName] = true
        card.dislikes[playerName] = nil -- Remove dislike if present
        self:SavePreferences()
        if playerName == NextKey.playerFullName then
            NextKey:BroadcastPreferences()
        end
        return true
    end
end

---Toggle dislike status for a dungeon
---@param dungeonID number
---@param playerName string
---@return boolean disliked Current dislike status
function DungeonCards:ToggleDislike(dungeonID, playerName)
    local card = self:GetCard(dungeonID)
    if card.dislikes[playerName] then
        card.dislikes[playerName] = nil
        self:SavePreferences()
        if playerName == NextKey.playerFullName then
            NextKey:BroadcastPreferences()
        end
        return false
    else
        card.dislikes[playerName] = true
        card.likes[playerName] = nil -- Remove like if present
        self:SavePreferences()
        if playerName == NextKey.playerFullName then
            NextKey:BroadcastPreferences()
        end
        return true
    end
end

---Get formatted list of players who like/dislike a dungeon
---@param dungeonID number
---@return string likes, string dislikes
function DungeonCards:GetPreferenceTooltip(dungeonID)
    local card = self:GetCard(dungeonID)
    
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
function DungeonCards:TrackItem(dungeonID, itemID, isCustom)
    local card = self:GetCard(dungeonID)
    if isCustom then
        card.customTrackedItems[itemID] = true
    else
        card.trackedItems[itemID] = true
    end
end

---Untrack an item for a dungeon
---@param dungeonID number
---@param itemID number
---@param isCustom boolean
function DungeonCards:UntrackItem(dungeonID, itemID, isCustom)
    local card = self:GetCard(dungeonID)
    if isCustom then
        card.customTrackedItems[itemID] = nil
    else
        card.trackedItems[itemID] = nil
    end
end

-- MARK: Sorting

---Calculate a preference score for a dungeon card
---@param card DungeonCard The dungeon card to score
---@param partySize number Current party size
---@return number score, number likes, number dislikes
function DungeonCards:GetPreferenceScore(card, partySize)
    local likes = GetUtils().tableCount(card.likes)
    local dislikes = GetUtils().tableCount(card.dislikes)
    
    -- Weight factors
    local LIKE_WEIGHT = 2.0
    local DISLIKE_WEIGHT = -1.5
    local UNANIMOUS_BONUS = 1.5
    local MAJORITY_BONUS = 1.2
    
    -- Calculate base score
    local score = (likes * LIKE_WEIGHT) + (dislikes * DISLIKE_WEIGHT)
    
    -- Apply unanimous/majority bonuses
    if likes > 0 and dislikes == 0 then
        if likes == partySize then
            score = score * UNANIMOUS_BONUS -- Everyone likes it
        elseif likes >= math.ceil(partySize / 2) then
            score = score * MAJORITY_BONUS -- Majority likes it
        end
    end
    
    -- Heavily penalize unanimous dislikes
    if dislikes == partySize and likes == 0 then
        score = score * 2 -- Double the negative score
    end
    
    return score, likes, dislikes
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
    
    if self.sortMethod == "highest" then
        table.sort(cards, function(a, b)
            return a.totalScore > b.totalScore
        end)
    elseif self.sortMethod == "lowest" then
        table.sort(cards, function(a, b)
            return a.totalScore < b.totalScore
        end)
    elseif self.sortMethod == "smart" then
        table.sort(cards, function(a, b)
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
            
            -- Fall back to dungeon score for equal preferences
            if a.totalScore ~= b.totalScore then
                return a.totalScore > b.totalScore
            end
            
            -- Finally sort alphabetically
            return a.name < b.name
        end)
    else -- alphabetical (default)
        table.sort(cards, function(a, b)
            return a.name < b.name
        end)
    end
    
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
    local prefs = {}
    for dungeonID, card in pairs(self.dungeons) do
        if next(card.likes) or next(card.dislikes) then
            prefs[dungeonID] = {
                likes = card.likes,
                dislikes = card.dislikes
            }
        end
    end
    NextKey.db.char.dungeonPrefs = prefs
end

---Load dungeon preferences from character DB
function DungeonCards:LoadPreferences()
    local prefs = NextKey.db.char.dungeonPrefs
    if prefs then
        for dungeonID, data in pairs(prefs) do
            local card = self:GetCard(dungeonID)
            if data.likes then
                for player in pairs(data.likes) do
                    card.likes[player] = true
                end
            end
            if data.dislikes then
                for player in pairs(data.dislikes) do
                    card.dislikes[player] = true
                end
            end
        end
    end
end

function DungeonCards:Init()
    -- Load sort preference
    self.sortMethod = NextKey.db.char.dungeonSort or "alphabetical"
    
    -- Initialize dungeon data from current season
    local season = C_MythicPlus.GetCurrentSeason()
    if season then
        local seasonDungeons = C_MythicPlus.GetSeasonDungeonInfo(season)
        if seasonDungeons then
            for _, info in ipairs(seasonDungeons) do
                self:GetCard(info.id, info.name, info.shortName)
            end
        end
    end
    
    -- Update scores from RaiderIO data
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