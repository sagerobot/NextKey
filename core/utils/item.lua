-- MARK: Module Definition
local _, NextKey222 = ...

local ItemUtils = {}
NextKey222.ItemUtils = ItemUtils
NextKey222.RegisterModule("ItemUtils", ItemUtils)

-- MARK: Item Utilities

--- Generates a hyperlink for an item with a specific item level.
--- This is used to display the correct Hero track item level in tooltips.
---@param itemID number The base item ID.
---@return string itemLink The formatted item hyperlink.
function ItemUtils:GetHeroTrackItemLink(itemID)
    -- As of TWW S3, Hero track items from M+ are ilvl 710.
    -- Try different approaches for Hero track display
    local itemLevel = 710
    
    -- Method 1: Try with a single bonus ID that might work for Hero track
    -- Method 2: Try with just the item level (no bonus IDs)
    -- Method 3: Try with different bonus ID combinations
    
    -- Let's try a simpler approach first - just set the level
    -- The hyperlink format is: "item:itemID:enchantID:gemID1:gemID2:gemID3:gemID4:suffixID:uniqueID:level:specializationID:rarityID:..."
    -- Format: item:itemID::::::level
    return string.format("item:%d::::::%d", itemID, itemLevel)
end

-- MARK: Module Interface

function ItemUtils:Initialize()
    return true
end

return ItemUtils