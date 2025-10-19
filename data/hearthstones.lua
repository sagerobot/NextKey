-- MARK: Hearthstone Data
-- Hearthstone toy, item, and spell data for NextKey teleport window
-- Based on HearthstoneToys addon with comprehensive hearthstone collection

local _, NextKey222 = ...

-- MARK: Hearthstone Database
-- Complete list of hearthstone toys, items, and spells
-- Format: {id = itemID, type = "toy"|"item"|"spell", name = "Display Name"}
NextKey222.HearthstoneData = {
    -- Standard Hearthstone Items
    {id = 6948, type = "item", name = "Hearthstone"},
    {id = 37118, type = "item", name = "Scroll of Recall"},
    {id = 44314, type = "item", name = "Scroll of Recall II"},
    {id = 44315, type = "item", name = "Scroll of Recall III"},
    
    -- Shaman Spell
    {id = 556, type = "spell", name = "Astral Recall"},
    
    -- Hearthstone Toys (Cataclysm - Mists of Pandaria)
    {id = 54452, type = "toy", name = "Ethereal Portal"},
    {id = 64488, type = "toy", name = "The Innkeeper's Daughter"},
    {id = 93672, type = "toy", name = "Dark Portal"},
    
    -- Legion
    {id = 140192, type = "toy", name = "Dalaran Hearthstone"},
    {id = 142542, type = "toy", name = "Tome of Town Portal"},
    
    -- Battle for Azeroth Event Toys
    {id = 162973, type = "toy", name = "Greatfather Winter's Hearthstone"},
    {id = 163045, type = "toy", name = "Headless Horseman's Hearthstone"},
    {id = 163206, type = "toy", name = "Weary Spirit Binding"},
    {id = 165669, type = "toy", name = "Lunar Elder's Hearthstone"},
    {id = 165670, type = "toy", name = "Peddlefeet's Lovely Hearthstone"},
    {id = 165802, type = "toy", name = "Noble Gardener's Hearthstone"},
    {id = 166746, type = "toy", name = "Fire Eater's Hearthstone"},
    {id = 166747, type = "toy", name = "Brewfest Reveler's Hearthstone"},
    
    -- Battle for Azeroth Engineering
    {id = 168907, type = "toy", name = "Holographic Digitalization Hearthstone"},
    
    -- Shadowlands
    {id = 172179, type = "toy", name = "Eternal Traveler's Hearthstone"},
    {id = 180290, type = "toy", name = "Night Fae Hearthstone"},
    {id = 182773, type = "toy", name = "Necrolord Hearthstone"},
    {id = 183716, type = "toy", name = "Venthyr Sinstone"},
    {id = 184353, type = "toy", name = "Kyrian Hearthstone"},
    {id = 188952, type = "toy", name = "Dominated Hearthstone"},
    
    -- Dragonflight
    {id = 190196, type = "toy", name = "Enlightened Hearthstone"},
    {id = 190237, type = "toy", name = "Broker Translocation Matrix"},
    {id = 193588, type = "toy", name = "Timewalker's Hearthstone"},
    {id = 200630, type = "toy", name = "Ohnir Windsage's Hearthstone"},
    {id = 206195, type = "toy", name = "Path of the Naaru"},
    
    -- The War Within
    {id = 208704, type = "toy", name = "Deepdweller's Earthen Hearthstone"},
    {id = 209035, type = "toy", name = "Hearthstone of the Flame"},
    {id = 210455, type = "toy", name = "Draenic Hologem"},
    {id = 212337, type = "toy", name = "Stone of the Hearth"},
    {id = 228940, type = "toy", name = "Notorious Thread's Hearthstone"},
    {id = 236687, type = "toy", name = "Explosive Hearthstone"},
    {id = 246565, type = "toy", name = "Cosmic Hearthstone"},
    {id = 245970, type = "toy", name = "P.O.S.T. Master's Express Hearthstone"},
    {id = 235016, type = "toy", name = "Redeployment Module"},
}

-- MARK: Helper Functions
-- Functions to work with hearthstone data

--- Check if player has a specific hearthstone
-- @param itemID number The item/toy/spell ID to check
-- @param itemType string The type ("toy", "item", or "spell")
-- @return boolean True if player has the hearthstone
function NextKey222.HearthstoneData.HasHearthstone(itemID, itemType)
    if itemType == "toy" then
        return PlayerHasToy(itemID)
    elseif itemType == "spell" then
        return IsSpellKnown(itemID) or IsPlayerSpell(itemID)
    elseif itemType == "item" then
        return GetItemCount(itemID) > 0
    end
    return false
end

--- Get all hearthstones the player has learned
-- @return table List of hearthstone data the player owns
function NextKey222.HearthstoneData.GetLearnedHearthstones()
    local learned = {}
    
    for _, hearthstone in ipairs(NextKey222.HearthstoneData) do
        if NextKey222.HearthstoneData.HasHearthstone(hearthstone.id, hearthstone.type) then
            table.insert(learned, hearthstone)
        end
    end
    
    return learned
end

--- Get hearthstone data by ID
-- @param itemID number The hearthstone ID to find
-- @return table|nil The hearthstone data or nil if not found
function NextKey222.HearthstoneData.GetHearthstoneByID(itemID)
    for _, hearthstone in ipairs(NextKey222.HearthstoneData) do
        if hearthstone.id == itemID then
            return hearthstone
        end
    end
    return nil
end

--- Get hearthstone icon texture
-- @param itemID number The hearthstone ID
-- @param itemType string The type ("toy", "item", or "spell")
-- @return string|nil The texture path or nil if not found
function NextKey222.HearthstoneData.GetHearthstoneTexture(itemID, itemType)
    local texture = nil
    
    if itemType == "toy" then
        local _, _, toyTexture = C_ToyBox.GetToyInfo(itemID)
        texture = toyTexture
    elseif itemType == "spell" then
        texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(itemID)
        if not texture then
            local _, _, spellTexture = GetSpellInfo(itemID)
            texture = spellTexture
        end
    elseif itemType == "item" then
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        texture = itemTexture
    end
    
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

--- Get hearthstone display name
-- @param itemID number The hearthstone ID
-- @param itemType string The type ("toy", "item", or "spell")
-- @return string The display name
function NextKey222.HearthstoneData.GetHearthstoneName(itemID, itemType)
    local name = "Unknown Hearthstone"
    
    if itemType == "toy" then
        local _, toyName = C_ToyBox.GetToyInfo(itemID)
        name = toyName or name
    elseif itemType == "spell" then
        name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(itemID)
        if not name then
            name = GetSpellInfo(itemID) or name
        end
    elseif itemType == "item" then
        name = GetItemInfo(itemID) or name
    end
    
    return name
end

-- MARK: Constants
-- UI layout constants for hearthstone selector

NextKey222.HearthstoneData.UI = {
    ICON_SIZE = 48,
    ICON_SPACING = 4,
    COLUMNS = 6,
    WINDOW_PADDING = 10,
    SELECTED_BORDER_COLOR = {1, 0.82, 0}, -- Gold color
    BACKDROP_COLOR = {0, 0, 0, 0.85},
    BACKDROP_BORDER_COLOR = {0.4, 0.4, 0.4, 1},
}

return NextKey222.HearthstoneData