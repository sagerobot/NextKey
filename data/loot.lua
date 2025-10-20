-- MARK: Initialization
-- This file defines all seasonal loot data for the addon.

local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then return end

-- MARK: Loot Data
-- Define all loot data in one place.
-- The addon will select the active season's data at runtime.
local lootData = {
    ["TWW_S3"] = {
        name = "The War Within Season 3",
        dungeons = {
            -- MARK: Halls of Atonement
            [377] = {
                name = "Halls of Atonement",
                items = {
                    [246344] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Cursed Stone Idol",
                    },
                    [178825] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Pulsating Stoneheart",
                    },
                    [178826] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Sunblood Amethyst",
                    },
                    [178829] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Nathrian Ferula",
                    },
                    [246284] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Nathrian Reliquary",
                    },
                    [178828] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Nathrian Tabernacle",
                    },
                    [178834] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Stoneguardian's Morningstar",
                    },
                    [178824] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Signet of the False Accuser",
                    },
                    [178827] = {
                        featured = false,
                        inDropdown = true,
                        slot = "NECK",
                        name = "Sin Stained Pendant",
                    },
                    [178817] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Hood of Refracted Shadows",
                    },
                    [178816] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Nathrian Usurper's Mask",
                    },
                    [178812] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Wing Commander's Helmet",
                    },
                    [178821] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Mantle of Ephemeral Visages",
                    },
                    [178820] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Pauldrons of Unleashed Pride",
                    },
                    [246276] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Sinlight Shoulderpads",
                    },
                    [246286] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Spaulders of Unleashed Pride",
                    },
                    [178814] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Breastplate of Otherworldly Influence",
                    },
                    [178813] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Sinlight Shroud",
                    },
                    [178815] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Soaring Decimator's Hauberk",
                    },
                    [246273] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Vest of Refracted Shadows",
                    },
                    [178832] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Gloves of Haunting Fixation",
                    },
                    [178833] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Stonefiend Shaper's Mitts",
                    },
                    [178822] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Cord of the Dark Word",
                    },
                    [178823] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Waistcord of Dark Devotion",
                    },
                    [178818] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Halkias's Towering Pillars",
                    },
                    [178819] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Skyterror's Stonehide Leggings",
                    },
                    [178830] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Shardskin Sabatons",
                    },
                    [178831] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Slippers of Leavened Station",
                    },
                }
            },
            -- MARK: Priory of the Sacred Flame
            [523] = {
                name = "Priory of the Sacred Flame",
                items = {
                    [219310] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Bursting Lightshard",
                    },
                    [219308] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Signet of the Priory",
                    },
                    [219309] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Tome of Light's Devotion",
                    },
                    [221127] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Emberbrand Zweihander",
                    },
                    [221116] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Glorious Defender's Poleaxe",
                    },
                    [221122] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Hand of Beledar",
                    },
                    [221117] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Sanctified Priory Wall",
                    },
                    [221128] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Starforged Seraph's Mace",
                    },
                    [221200] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Radiant Necromancer's Band",
                    },
                    [252009] = {
                        featured = false,
                        inDropdown = true,
                        slot = "NECK",
                        name = "Bloodstained Memento",
                    },
                    [221131] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Elysian Flame Crown",
                    },
                    [221125] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Helm of the Righteous Crusade",
                    },
                    [221203] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Reanimator's Pyreforged Shoulders",
                    },
                    [221130] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Seraphic Wraps of the Ordained",
                    },
                    [221126] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Zealous Warden's Raiment",
                    },
                    [221124] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Consecrated Baron's Bindings",
                    },
                    [221118] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Flameforged Armguard",
                    },
                    [221119] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Holybound Grips",
                    },
                    [221121] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Honorbound Retainer's Sash",
                    },
                    [221129] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Divine Pyrewalkers",
                    },
                    [221123] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Devoted Plate Walkers",
                    },
                    [221120] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Stalwart Guardian's Boots",
                    },
                }
            },
            -- MARK: Operation: Floodgate
            [525] = {
                name = "Operation: Floodgate",
                items = {
                    [232542] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Darkfuse Medichopper",
                    },
                    [232545] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Gigazap's Zap-Cap",
                    },
                    [232541] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Improvised Seaforium Pacemaker",
                    },
                    [232543] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Ringing Ritual Mud",
                    },
                    [234490] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Circuit Breaker",
                    },
                    [234494] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Gallytech Turbo-Tiller",
                    },
                    [234493] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Geezle's Coercive Volt-Ohmmeter",
                    },
                    [234492] = {
                        featured = false,
                        inDropdown = false,
                        slot = "RANGED",
                        name = "Keeza's 'B.' B.B.B.F.G",
                    },
                    [234491] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Sonic Ka-BOOM!-erang",
                    },
                    [251880] = {
                        featured = false,
                        inDropdown = true,
                        slot = "NECK",
                        name = "Momma's Mega Medallion",
                    },
                    [234498] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Waterworks Filtration Mask",
                    },
                    [234500] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Mechanized Junkpads",
                    },
                    [234503] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Skystreak's Hidden Missiles",
                    },
                    [234507] = {
                        featured = false,
                        inDropdown = false,
                        slot = "BACK",
                        name = "Electrician's Siphoning Filter",
                    },
                    [234502] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Bront's Singed Blastcoat",
                    },
                    [234506] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Muckdiver's Wading Plate",
                    },
                    [234496] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Saboteur's Rubber Jacket",
                    },
                    [234499] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Disturbed Kelp Wraps",
                    },
                    [246279] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Fizzlefuse Cuffs",
                    },
                    [234504] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Jumpstarter's Scaffold-Scrapers",
                    },
                    [234501] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Portable Power Generator",
                    },
                    [234505] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Venture Contractor's Floodlight",
                    },
                    [246278] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Overpressure Platelegs",
                    },
                    [234495] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Razorchoke Slacks",
                    },
                    [246277] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Swampface's Oozewalkers",
                    },
                    [246274] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Geezle's Zapstep Boots",
                    },
                    [234497] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Nonconductive Kill-o-Socks",
                    },
                }
            },
            -- MARK: The Dawnbreaker
            [524] = {
                name = "The Dawnbreaker",
                items = {
                    [219312] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Empowering Crystal of Anub'ikkaj",
                    },
                    [219311] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Void Pactstone",
                    },
                    [221137] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Black Shepherd's Guisarme",
                    },
                    [221132] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Overflowing Umbral Pail",
                    },
                    [221138] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Parson's Ornamented Blade",
                    },
                    [221136] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Devout Zealot's Ring",
                    },
                    [221141] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "High Nerubian Signet",
                    },
                    [221135] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Fanatic's Blackened Shoulderwraps",
                    },
                    [221140] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Shadowblight Mantle",
                    },
                    [221139] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Dark Priest's Carapace",
                    },
                    [221142] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Scheming Assailer's Bands",
                    },
                    [221133] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Girdle of Somber Ploys",
                    },
                    [221134] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Shadow Congregant's Belt",
                    },
                    [221202] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Defiance Crusher's Sabatons",
                    },
                }
            },
            -- MARK: Ara-Kara, City of Echoes
            [503] = {
                name = "Ara-Kara, City of Echoes",
                items = {
                    [219314] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Ara-Kara Sacbrood",
                    },
                    [219316] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Ceaseless Swarmgland",
                    },
                    [219317] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Harvester's Edict",
                    },
                    [221150] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Arachnoid Soulcleaver",
                    },
                    [221160] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Blight Hunter's Scalpelglaive",
                    },
                    [221159] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Harvester's Interdiction",
                    },
                    [221165] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Unceremonious Bloodletter",
                    },
                    [221156] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Cryptbound Headpiece",
                    },
                    [221163] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Whispering Mask",
                    },
                    [221155] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Swarm Monarch's Spaulders",
                    },
                    [221154] = {
                        featured = false,
                        inDropdown = false,
                        slot = "BACK",
                        name = "Swarmcaller's Shroud",
                    },
                    [221161] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Experimental Goresilk Chestguard",
                    },
                    [221157] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Unbreakable Beetlebane Bindings",
                    },
                    [221162] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Claws of Tainted Ichor",
                    },
                    [221151] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Devourer's Gauntlets",
                    },
                    [221158] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Burrower's Cinch",
                    },
                    [221164] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Archaic Venomancer's Legwraps",
                    },
                    [221153] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Gauzewoven Legguards",
                    },
                    [221152] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Silksteel Striders",
                    },
                }
            },
            -- MARK: Eco-Dome Al'dani
            [526] = {
                name = "Eco-Dome Al'dani",
                items = {
                    [242497] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Azhiccaran Parapodia",
                    },
                    [242495] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Incorporeal Warpclaw",
                    },
                    [242494] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Lily of the Eternal Weave",
                    },
                    [242487] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Fatebound Crusader",
                    },
                    [242470] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Mandibular Bonewhacker",
                    },
                    [242484] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Soul-Scribe's Tabiqa Dagger",
                    },
                    [242481] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Spellstrike Warplance",
                    },
                    [242493] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Starlit Safeguard",
                    },
                    [242464] = {
                        featured = false,
                        inDropdown = false,
                        slot = "RANGED",
                        name = "Swarmite's Frenzied Pedicel",
                    },
                    [242476] = {
                        featured = false,
                        inDropdown = false,
                        slot = "RANGED",
                        name = "Taah'bat's Desert Carbine",
                    },
                    [242491] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Whispers of K'aresh",
                    },
                    [242477] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Wasteland Devotee's Wrappings",
                    },
                    [242472] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Consumed Wastelander's Epaulets",
                    },
                    [242486] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Mantle of Wounded Fate",
                    },
                    [242482] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Reinforced Stalkerhide Vest",
                    },
                    [242488] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Tunic of Sworn Revenge",
                    },
                    [242468] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Al'dani Attendant's Gauze",
                    },
                    [242475] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Eco-Dome Access Bands",
                    },
                    [242490] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Ancient Oracle's Caress",
                    },
                    [242479] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Girdle of Absolute Faith",
                    },
                    [242473] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Spittle-Stained Trousers",
                    },
                    [242483] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Greaves of the Wild Pair",
                    },
                }
            },
            -- MARK: Tazavesh: Streets of Wonder
            [401] = {
                name = "Tazavesh: Streets of Wonder",
                items = {
                    [185777] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Fang of Alcruux",
                    },
                    [185821] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Gluttonous Rondel",
                    },
                    [185811] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Package Protector",
                    },
                    [185840] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Seal of the Panoply",
                    },
                    [185782] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Robes of Midnight Bargains",
                    },
                    [185786] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "So'azmi's Fractal Vest",
                    },
                    [185792] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Achillite's Unbreakable Grip",
                    },
                    [185793] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Cyphered Gloves",
                    },
                    [185794] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Gavel Pounders",
                    },
                    [185791] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HANDS",
                        name = "Knuckle-Dusting Handwraps",
                    },
                    [185808] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Discount Mail-Order Belt",
                    },
                    [185806] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Improvisational Cinch",
                    },
                    [185807] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Pan-Dimensional Packing Cord",
                    },
                    [185809] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WAIST",
                        name = "Venza's Powderbelt",
                    },
                    [185800] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Orbitwarp Culottes",
                    },
                    [185798] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Quantum Leapers",
                    },
                    [185787] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Implacable Weatherproof Treads",
                    },
                    [185789] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Sabatons of Measured Time",
                    },
                    [185812] = {
                        featured = false,
                        inDropdown = false,
                        slot = "OFF_HAND",
                        name = "Acoustically Alluring Censer",
                    },
                    [185814] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Auctioneer's Counting Bracers",
                    },
                    [185824] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Blade of Grievous Harm",
                    },
                    [185817] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Bracers of Autonomous Classification",
                    },
                    [185802] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Breakbeat Shoulderguards",
                    },
                    [185836] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Codex of the First Technique",
                    },
                    [185816] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Confiscated Bracers of Concealment",
                    },
                    [185845] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "First Class Healing Distributor",
                    },
                    [185778] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "First Fist of the So Cartel",
                    },
                    [185804] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Harmonious Spaulders",
                    },
                    [185780] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Interrogator's Flensing Blade",
                    },
                    [185846] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Miniscule Mailemental in an Envelope",
                    },
                    [185842] = {
                        featured = false,
                        inDropdown = true,
                        slot = "NECK",
                        name = "Ornately Engraved Amplifier",
                    },
                    [190652] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "Ticking Sack of Terror",
                    },
                    [185815] = {
                        featured = false,
                        inDropdown = false,
                        slot = "WRIST",
                        name = "Vambraces of Verification",
                    },
                    [185783] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Yasahm the Riftbreaker",
                    },
                }
            },
            -- MARK: Tazavesh: So'leah's Gambit
            [402] = {
                name = "Tazavesh: So'leah's Gambit",
                items = {
                    [185819] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Event Horizon's Edge",
                    },
                    [185779] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Spire of Expurgation",
                    },
                    [185822] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Staff of Fractured Spacetime",
                    },
                    [185813] = {
                        featured = false,
                        inDropdown = true,
                        slot = "RING",
                        name = "Signet of Collapsing Stars",
                    },
                    [185785] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Embrace of the Relicbinder",
                    },
                    [185784] = {
                        featured = false,
                        inDropdown = false,
                        slot = "CHEST",
                        name = "Novaburst Warplate",
                    },
                    [185801] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Anomalous Starlit Breeches",
                    },
                    [185799] = {
                        featured = false,
                        inDropdown = false,
                        slot = "LEGS",
                        name = "Hyperlight Leggings",
                    },
                    [185788] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Codebreaker's Cunning Sandals",
                    },
                    [185790] = {
                        featured = false,
                        inDropdown = false,
                        slot = "FEET",
                        name = "Treads of Titanic Deconversion",
                    },
                    [185820] = {
                        featured = false,
                        inDropdown = true,
                        slot = "NECK",
                        name = "Cabochon of the Infinite Flight",
                    },
                    [185795] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Cowl of Branching Fate",
                    },
                    [185796] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Dragonbane Diadem",
                    },
                    [185823] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Fatebreaker, Destroyer of Futures",
                    },
                    [185776] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Hooktail's Commanding Gaze",
                    },
                    [185805] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Hylbrande's Retrofitted Shoulderguards",
                    },
                    [185797] = {
                        featured = false,
                        inDropdown = false,
                        slot = "HEAD",
                        name = "Rakishly Tipped Tricorne",
                    },
                    [185810] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Skyreaver, Greataxe of the Keepers",
                    },
                    [185818] = {
                        featured = true,
                        inDropdown = false,
                        slot = "TRINKET",
                        name = "So'leah's Secret Technique",
                    },
                    [185803] = {
                        featured = false,
                        inDropdown = false,
                        slot = "SHOULDER",
                        name = "Stoneflesh Spaulders",
                    },
                    [185841] = {
                        featured = false,
                        inDropdown = true,
                        slot = "WEAPON",
                        name = "Timetwister Tulwar",
                    },
                }
            }
        }
    },
    -- To add a new season:
    -- 1. Copy the TWW_S3 block.
    -- 2. Change the key e.g., "TWW_S4".
    -- 3. Update the dungeon loot data within.
    -- 4. Change "activeSeasonKey" below to the new key.
}

-- Set the currently active season. This is the only line you'll need to
-- update when a new season begins (after adding its data above).
local activeSeasonKey = "TWW_S3"

-- Expose the active season's data to the rest of the addon.
-- This will be a table like: { name = "Season Name", dungeons = { ... } }
NextKey.LootData = lootData[activeSeasonKey]
NextKey.CurrentLootSeasonKey = activeSeasonKey

-- For debugging or other purposes, expose the entire dataset.
NextKey.AllLootData = lootData

-- Helper: Get featured items for a dungeon
function NextKey:GetFeaturedItems(dungeonID)
    if not self.LootData or not self.LootData.dungeons[dungeonID] then
        return {}
    end
    
    local featured = {}
    for itemID, itemData in pairs(self.LootData.dungeons[dungeonID].items) do
        if itemData.featured then
            table.insert(featured, itemID)
        end
    end
    return featured
end

-- Helper: Get dropdown items (with tracking status)
function NextKey:GetDropdownItems(dungeonID)
    if not self.LootData or not self.LootData.dungeons[dungeonID] then
        return {}
    end
    
    -- Get dungeon name for GetCard call
    local dungeonName = nil
    if self.PortalData and self.PortalData.dungeons and self.PortalData.dungeons[dungeonID] then
        dungeonName = self.PortalData.dungeons[dungeonID].name
    end
    if not dungeonName then
        dungeonName = "Dungeon " .. dungeonID
    end
    
    -- Ensure dungeonName is never nil before calling GetCard
    if not dungeonName then
        dungeonName = "Unknown Dungeon"
        NextKey222.Debug:Error("data/loot", "dungeonName is still nil after fallback for dungeonID:", dungeonID)
    end
    
    local card = self.DungeonCards:GetCard(dungeonID, dungeonName)
    local dropdownItems = {}
    
    for itemID, itemData in pairs(self.LootData.dungeons[dungeonID].items) do
        if itemData.inDropdown then
            local isTracked = (card.trackedItems and card.trackedItems[itemID]) or (card.customTrackedItems and card.customTrackedItems[itemID]) or false
            
            table.insert(dropdownItems, {
                itemID = itemID,
                data = itemData,
                isTracked = isTracked,
                trackLabel = isTracked and "(Already Tracked)" or ""
            })
        end
    end
    
    -- Sort by slot: TRINKET → WEAPON → RING
    table.sort(dropdownItems, function(a, b)
        local slotOrder = {TRINKET = 1, WEAPON = 2, RING = 3}
        return (slotOrder[a.data.slot] or 99) < (slotOrder[b.data.slot] or 99)
    end)
    
    return dropdownItems
end

-- Helper: Get default items (for backward compatibility)
function NextKey:GetDefaultLootItems(dungeonID)
    return self:GetFeaturedItems(dungeonID)
end

-- Helper: Check if item is from this dungeon
function NextKey:IsItemFromDungeon(dungeonID, itemID)
    if not self.LootData or not self.LootData.dungeons[dungeonID] then
        return false
    end
    
    return self.LootData.dungeons[dungeonID].items[itemID] ~= nil
end

-- Helper: Get item data for an item
function NextKey:GetItemData(dungeonID, itemID)
    if not self.LootData or not self.LootData.dungeons[dungeonID] then
        return nil
    end
    
    return self.LootData.dungeons[dungeonID].items[itemID]
end

return lootData
