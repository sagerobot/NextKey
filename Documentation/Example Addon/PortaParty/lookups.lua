local _, ns = ...

ns.lookups = {}
ns.lookups[0] = {
    spellName = "",
    spellID = -1,
    dungeonName = "No dungeon found",
    zone = "",
    zoneID = 1,
    expansion = 0,
}

-- Algeth'ar Academy
ns.lookups[2526] = {
        -- Dragonflight season 4 (12)
        spellName = "Path of the Draconic Diploma",
        spellID = 393273,
        dungeonName = "Algeth'ar Academy",
        zone = "Thaldraszus",
        zoneID = 2025,
        expansion = 9, -- Dragonflight
}

-- Atal'Dazar
ns.lookups[1763] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of the Golden Tomb",
    spellID = 424187,
    dungeonName = "Atal'Dazar",
    zone = "Zuldazar",
    zoneID = 862,
    expansion = 7, -- Battle for Azeroth
}

-- The Azure Vault
ns.lookups[2515] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of Arcane Secrets",
    spellID = 393279,
    dungeonName = "The Azure Vault",
    zone = "The Azure Span",
    zoneID = 2024,
    expansion = 9, -- Dragonflight
}

-- Black Rook Hold
ns.lookups[1501] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of Ancient Horrors",
    spellID = 424153,
    dungeonName = "Black Rook Hold",
    zone = "Val'sharah",
    zoneID = 641,
    expansion = 6, -- Legion
}

-- Brackenhide Hollow
ns.lookups[2520] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Rotting Woods",
    spellID = 393267,
    dungeonName = "Brackenhide Hollow",
    zone = "The Azure Span",
    zoneID = 2024,
    expansion = 9, -- Dragonflight
}

-- Darkheart Thicket
ns.lookups[1466] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of the Nightmare Lord",
    spellID = 424163,
    dungeonName = "Darkheart Thicket",
    zone = "Val'sharah",
    zoneID = 641,
    expansion = 6, -- Legion
}

-- Dawn of the Infinites: Galakrond's Fall
-- Dawn of the Infinites: Murozond's Rise
ns.lookups[2579] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of Twisted Time",
    spellID = 424197,
    dungeonName = "Dawn of the Infinites",
    zone = "Thaldraszus",
    zoneID = 2025,
    expansion = 9, -- Dragonflight
}

-- Everbloom
ns.lookups[1279] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of the Verdant",
    spellID = 159901,
    dungeonName = "Everbloom",
    zone = "Gorgrond",
    zoneID = 543,
    expansion = 5, -- Warlords of Draenor
}

-- Halls of Infusion
ns.lookups[2527] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Titanic Reservoir",
    spellID = 393283,
    dungeonName = "Halls of Infusion",
    zone = "Thaldraszus",
    zoneID = 2025,
    expansion = 9, -- Dragonflight
}

-- Neltharus
ns.lookups[2519] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Obsidian Hoard",
    spellID = 393276,
    dungeonName = "Neltharus",
    zone = "The Waking Shores",
    zoneID = 2022,
    expansion = 9, -- Dragonflight
}

-- The Nokhud Offensive
ns.lookups[2516] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Windswept Plains",
    spellID = 393262,
    dungeonName = "The Nokhud Offensive",
    zone = "Ohn'ahran Plains",
    zoneID = 2023,
    expansion = 9, -- Dragonflight
}

-- Ruby Life Pools
ns.lookups[2521] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Clutch Defender",
    spellID = 393256,
    dungeonName = "Ruby Life Pools",
    zone = "The Waking Shores",
    zoneID = 2022,
    expansion = 9, -- Dragonflight
}

-- Throne of the Tides
ns.lookups[643] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of the Tidehunter",
    spellID = 424142,
    dungeonName = "Throne of the Tides",
    zone = "Vashj'ir",
    zoneID = 203,
    expansion = 3, -- Cataclyism
}

-- Uldaman: Legacy of Tyr
ns.lookups[2451] = {
    -- Dragonflight season 4 (12)
    spellName = "Path of the Watcher's Legacy",
    spellID = 393222,
    dungeonName = "Uldaman: Legacy of Tyr",
    zone = "Badlands",
    zoneID = 15,
    expansion = 9, -- Dragonflight
}

-- Waycrest Manor
ns.lookups[1862] = {
    -- Dragonflight season 3 (11)
    spellName = "Path of Heart's Bane",
    spellID = 424167,
    dungeonName = "Waycrest Manor",
    zone = "Drustvar",
    zoneID = 896,
    expansion = 7, -- Battle for Azeroth
}


ns.classColors                 = {}
ns.classColors["Death Knight"] = { red = 0.77, blue = 0.12, green = 0.23 }
ns.classColors["Demon Hunter"] = { red = 0.64, blue = 0.19, green = 0.79 }
ns.classColors["Druid"]        = { red = 1.00, blue = 0.49, green = 0.04 }
ns.classColors["Evoker"]       = { red = 0.20, blue = 0.58, green = 0.50 }
ns.classColors["Hunter"]       = { red = 0.67, blue = 0.83, green = 0.45 }
ns.classColors["Mage"]         = { red = 0.25, blue = 0.78, green = 0.92 }
ns.classColors["Monk"]         = { red = 0.00, blue = 1.00, green = 0.60 }
ns.classColors["Paladin"]      = { red = 0.96, blue = 0.55, green = 0.73 }
ns.classColors["Priest"]       = { red = 1.00, blue = 1.00, green = 1.00 }
ns.classColors["Rogue"]        = { red = 1.00, blue = 0.96, green = 0.41 }
ns.classColors["Shaman"]       = { red = 0.00, blue = 0.44, green = 0.87 }
ns.classColors["Warlock"]      = { red = 0.53, blue = 0.53, green = 0.93 }
ns.classColors["Warrior"]      = { red = 0.78, blue = 0.61, green = 0.43 }

ns.seasons = {}
ns.seasons[-1] = {}
ns.seasons[0] = {}

ns.seasons[11] = {1763, 1501, 1466, 2579, 1279, 643, 1862}
ns.seasons[12] = {2526, 2515, 2520, 2527, 2519, 2516, 2521, 2451}

ns.seasonNames = {}
ns.seasonNames[1] = "Battle for Azeroth Season 1"
ns.seasonNames[2] = "Battle for Azeroth Season 2"
ns.seasonNames[3] = "Battle for Azeroth Season 3"
ns.seasonNames[4] = "Battle for Azeroth Season 4"

ns.seasonNames[5] = "Shadowlands Season 1"
ns.seasonNames[6] = "Shadowlands Season 2"
ns.seasonNames[7] = "Shadowlands Season 3"
ns.seasonNames[8] = "Shadowlands Season 4"

ns.seasonNames[9] = "Dragonflight Season 1"
ns.seasonNames[10] = "Dragonflight Season 2"
ns.seasonNames[11] = "Dragonflight Season 3"
ns.seasonNames[12] = "Dragonflight Season 4"