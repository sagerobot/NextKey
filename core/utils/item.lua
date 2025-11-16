-- MARK: Module Definition
local _, NextKey222 = ...

local ItemUtils = {}
NextKey222.ItemUtils = ItemUtils
NextKey222.RegisterModule("ItemUtils", ItemUtils)

-- MARK: Item Utilities

--- Builds an enhanced item link with bonus IDs for M+ difficulty display
--- Following AtlasLoot's exact assembly pattern from Core/ItemInfo.lua
--- @param itemID number The base item ID
--- @param difficultyKey string Optional difficulty key (default: "HERO_TRACK")
--- @return string itemString The enhanced item string with bonus IDs
function ItemUtils:BuildEnhancedItemLink(itemID, difficultyKey)
    difficultyKey = difficultyKey or "HERO_TRACK"
    
    -- Step 1: Get bonus ID string from constants (AtlasLoot pattern)
    local bonusString = NextKey222.Constants.KEYSTONES.ITEM_BONUS_IDS[difficultyKey]
    
    if not bonusString then
        NextKey222.Debug:Dev("item", "No bonus IDs for difficulty:", difficultyKey, "- using base item ID")
        return "item:" .. tostring(itemID)
    end
    
    -- Step 2: Calculate number of bonus IDs (count colons + 1)
    -- This is required by WoW's item string format
    local _, colonCount = string.gsub(bonusString, ":", "")
    local numBonuses = colonCount + 1
    
    -- Step 3: Assemble the full item string
    -- Format: "item:itemID::::::::::::context:numBonuses:bonusID1:bonusID2:..."
    -- Context 14 = Raid/Dungeon loot (standard for M+ items)
    local itemString = string.format("item:%d::::::::::::14:%d:%s",
        itemID,
        numBonuses,
        bonusString
    )
    
    NextKey222.Debug:Dev("item", "Enhanced item link:", itemID, "->", itemString)
    return itemString
end

--- Gets the Epic (purple) quality color for items.
--- Used to display M+ dungeon items as Epic quality in the loot window.
--- This is purely visual - it doesn't change the item itself.
---@return table color The Epic quality color {r, g, b}
function ItemUtils:GetEpicQualityColor()
    -- Quality 4 = Epic (purple)
    local epicQuality = 4
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[epicQuality] then
        return ITEM_QUALITY_COLORS[epicQuality]
    end
    -- Fallback to purple if color table not available
    return { r = 0.64, g = 0.21, b = 0.93 }
end

-- MARK: Module Interface

function ItemUtils:Initialize()
    NextKey222.Debug:Dev("item", "ItemUtils initialized")
    return true
end

return ItemUtils