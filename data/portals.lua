-- MARK: Initialization
-- This file defines all seasonal dungeon and teleport data for the addon.

local _, NS = ...
local NextKey = NS.Addon

if not NextKey then return end

-- MARK: Portal Data
-- Define all portal data in one place.
-- The addon will select the active season's data at runtime.
local portalData = {
    ["TWW_S3"] = {
        name = "The War Within Season 3",
        dungeons = {
            -- mapID = { name, alias, spellID, mapArtID }
            [503] = { name = "Ara-Kara, City of Echoes", alias = "Ara", spellID = 445417, mapArtID = 2588 }, -- Real ID for Ara-Kara
            [524] = { name = "The Dawnbreaker", alias = "Dawn", spellID = 445414, mapArtID = 2582 },
            [526] = { name = "Eco-Dome Al'dani", alias = "Eco", spellID = 1237215, mapArtID = 2598 },
            [377] = { name = "Halls of Atonement", alias = "Halls", spellID = 354465, mapArtID = 1672 },
            [525] = { name = "Operation: Floodgate", alias = "Flood", spellID = 1216786, mapArtID = 2596 },
            [523] = { name = "Priory of the Sacred Flame", alias = "Priory", spellID = 445444, mapArtID = 2595 },
            [401] = { name = "Tazavesh: Streets of Wonder", alias = "Streets", spellID = 367416, mapArtID = 2481 },
            [402] = { name = "Tazavesh: So'leah's Gambit", alias = "Gambit", spellID = 367416, mapArtID = 2481 },
        }
    },
    -- To add a new season:
    -- 1. Copy the TWW_S3 block.
    -- 2. Change the key e.g., "TWW_S4".
    -- 3. Update the dungeon data within.
    -- 4. Change "activeSeasonKey" below to the new key.
}

-- Set the currently active season. This is the only line you'll need to
-- update when a new season begins (after adding its data above).
local activeSeasonKey = "TWW_S3"

-- Expose the active season's data to the rest of the addon.
-- This will be a table like: { name = "Season Name", dungeons = { ... } }
NextKey.PortalData = portalData[activeSeasonKey]
NextKey.CurrentSeasonKey = activeSeasonKey
NextKey_CurrentSeasonKey = activeSeasonKey

-- For debugging or other purposes, expose the entire dataset.
NextKey.AllPortalData = portalData

-- For backward compatibility with other files that have not been updated yet.
NextKey_PortalDB = {}
NextKey_MapArtDB = {}
NextKey_DungeonNames = {}
NextKey_DungeonAliases = {}

if NextKey.PortalData and NextKey.PortalData.dungeons then
    for id, data in pairs(NextKey.PortalData.dungeons) do
        NextKey_PortalDB[id] = data.spellID
        NextKey_MapArtDB[id] = data.mapArtID
        NextKey_DungeonNames[id] = data.name
        NextKey_DungeonAliases[id] = data.alias
    end
end


