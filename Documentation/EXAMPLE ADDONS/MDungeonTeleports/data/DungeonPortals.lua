local L = LibStub("AceLocale-3.0"):GetLocale("MDungeonTeleports")
local factionGroup = UnitFactionGroup("player")

local siegeID = nil
local motherID = nil

if factionGroup == "Horde" then
    siegeID = 464256
    motherID = 467555
elseif factionGroup == "Alliance" then
    siegeID = 445418
    motherID = 467553
else
    print("Warning: Unknown faction detected! Tell The Addon Author: M+ Dungeon Teleports.")
end

-- MARK: Season 3 Portals
MDT_Season3Row1 = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara", spellID = 445417, name = L["ARAK"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker", spellID = 445414, name = L["DAWN"]},
    {icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome", spellID = 1237215, name = L["EDA"]},
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement", spellID = 354465, name = L["HOA"]} 
}
MDT_Season3Row2 = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks", spellID = 1216786, name = L["FLOOD"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame", spellID = 445444, name = L["PSF"]},
    {icon = "Interface\\Addons\\MDungeonTeleports\\media\\icons\\gambit", spellID = 367416, name = L["GMBT"]}, -- "Interface\\Icons\\achievement_dungeon_brokerdungeon"
    {icon = "Interface\\Addons\\MDungeonTeleports\\media\\icons\\streets", spellID = 367416, name = L["STRT"]} -- "Interface\\Icons\\Achievement_dungeon_theotherside_dealergexa"
}
-- MARK: Season 2 Portals
MDT_Season2Row1 = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_cinderbrewmeadery", spellID = 445440, name = L["BREW"]}, 
    {icon = "Interface\\Icons\\inv_achievement_dungeon_darkflamecleft", spellID = 445441, name = L["DFC"]}, 
    {icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame", spellID = 445444, name = L["PSF"]}, 
    {icon = "Interface\\Icons\\inv_achievement_dungeon_rookery", spellID = 445443, name = L["ROOK"]} 
}
MDT_Season2Row2 = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks", spellID = 1216786, name = L["FLOOD"]},
    {icon = "Interface\\Icons\\achievement_dungeon_kezan", spellID = motherID, name = L["ML"]},
    {icon = "Interface\\Icons\\achievement_dungeon_theatreofpain", spellID = 354467, name = L["TOP"]},
    {icon = "Interface\\Icons\\achievement_boss_mechagon", spellID = 373274, name = L["MECHA"]}
}
-- MARK: Season 1 Portals
MDT_Season1Row1 = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara", spellID = 445417, name = L["ARAK"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_cityofthreads", spellID = 445416, name = L["COT"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker", spellID = 445414, name = L["DAWN"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_stonevault", spellID = 445269, name = L["SV"]}
}
MDT_Season1Row2 = {
    {icon = "Interface\\Icons\\achievement_dungeon_mistsoftirnascithe", spellID = 354464, name = L["MISTS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_theneroticwake", spellID = 354462, name = L["NW"]},
    {icon = "Interface\\Icons\\achievement_dungeon_siegeofboralus", spellID = siegeID, name = L["SIEGE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_grimbatol", spellID = 445424, name = L["GB"]}
}
-- MARK: Portal Library
-- The War Within
MDT_PL_TWW = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara", spellID = 445417, name = L["ARAK"], fullname = L["ARA-KARA"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_cinderbrewmeadery", spellID = 445440, name = L["BREW"], fullname = L["CINDERBREW"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_cityofthreads", spellID = 445416, name = L["COT"], fullname = L["CITY_OF_THREADS"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_darkflamecleft", spellID = 445441, name = L["DFC"], fullname = L["DARKFLAME"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker", spellID = 445414, name = L["DAWN"], fullname = L["DAWNBREAKER"]},
    {icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome", spellID = 1237215, name = L["EDA"], fullname = L["ECO_DOME"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks", spellID = 1216786, name = L["FLOOD"], fullname = L["FLOODGATE"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame", spellID = 445444, name = L["PSF"], fullname = L["PRIORY"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_rookery", spellID = 445443, name = L["ROOK"], fullname = L["ROOKERY"]},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_stonevault", spellID = 445269, name = L["SV"], fullname = L["STONEVAULT"]}
}
-- Dragonflight
MDT_PL_DF = {
    {icon = "Interface\\Icons\\achievement_dungeon_dragonacademy", spellID = 393273, name = L["AA"], fullname = L["ALGETHAR"]},
    {icon = "Interface\\Icons\\achievement_dungeon_arcanevaults", spellID = 393279, name = L["AV"], fullname = L["AZURE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_brackenhidehollow", spellID = 393267, name = L["BH"], fullname = L["BRACKENHIDE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_dawnoftheinfinite", spellID = 424197, name = L["DOTI"], fullname = L["INFINITE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofinfusion", spellID = 393283, name = L["HOI"], fullname = L["INFUSION"]},
    {icon = "Interface\\Icons\\achievement_dungeon_neltharus", spellID = 393276, name = L["NELTH"], fullname = L["NELTHARUS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_centaurplains", spellID = 393262, name = L["NO"], fullname = L["PLAINS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_lifepools", spellID = 393256, name = L["RLP"], fullname = L["POOLS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_uldaman", spellID = 393222, name = L["ULD"], fullname = L["ULDAMAN_TYR"]}

}
-- Shadowlands
MDT_PL_SL = {
    {icon = "Interface\\Icons\\achievement_dungeon_theotherside", spellID = 354468, name = L["DOS"], fullname = L["DE_OTHER_SIDE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement", spellID = 354465, name = L["HOA"], fullname = L["ATTONEMENT"]},
    {icon = "Interface\\Icons\\achievement_dungeon_mistsoftirnascithe", spellID = 354464, name = L["MISTS"], fullname = L["MISTS_OF"]},
    {icon = "Interface\\Icons\\achievement_dungeon_theneroticwake", spellID = 354462, name = L["NW"], fullname = L["NECROTIC"]},
    {icon = "Interface\\Icons\\achievement_dungeon_plaguefall", spellID = 354463, name = L["PF"], fullname = L["PLAUGEFALL"]},
    {icon = "Interface\\Icons\\achievement_dungeon_sanguinedepths", spellID = 354469, name = L["SD"], fullname = L["SANGUINE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_spireofascension", spellID = 354466, name = L["SOA"], fullname = L["SPIRES"]},
    {icon = "Interface\\Icons\\achievement_dungeon_brokerdungeon", spellID = 367416, name = L["TAZ"], fullname = L["TAZAVESH"]},
    {icon = "Interface\\Icons\\achievement_dungeon_theatreofpain", spellID = 354467, name = L["TOP"], fullname = L["THEATRE"]}

}
-- Battle for Azeroth
MDT_PL_BFA = {
    {icon = "Interface\\Icons\\achievement_dungeon_ataldazar", spellID = 424187, name = L["AD"], fullname = L["ATAL_DAZAR"]},
    {icon = "Interface\\Icons\\achievement_dungeon_freehold", spellID = 410071, name = L["FH"], fullname = L["FREEHOLD"]},
    {icon = "Interface\\Icons\\achievement_boss_mechagon", spellID = 373274, name = L["MECHA"], fullname = L["MECHAGON"]},
    {icon = "Interface\\Icons\\achievement_dungeon_kezan", spellID = motherID, name = L["ML"], fullname = L["MOTHERLODE"]},
    {icon = "Interface\\Icons\\achievement_dungeon_siegeofboralus", spellID = siegeID, name = L["SIEGE"], fullname = L["SIEGE_OF_BORALUS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_underrot", spellID = 410074, name = L["UNDR"], fullname = L["UNDERROT"]},
    {icon = "Interface\\Icons\\achievement_dungeon_waycrestmannor", spellID = 424167, name = L["WM"], fullname = L["WAYCREST_MANOR"]}
}
-- Legion
MDT_PL_Legion = {
    {icon = "Interface\\Icons\\achievement_dungeon_blackrookhold", spellID = 424153, name = L["BRH"], fullname = L["BLACKROOK_HOLD"]},
    {icon = "Interface\\Icons\\achievement_dungeon_courtofstars", spellID = 393766, name = L["COS"], fullname = L["COURT_OF_STARS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_darkheartthicket", spellID = 424163, name = L["DT"], fullname = L["DARKHEART_THICKET"]},
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofvalor", spellID = 393764, name = L["HOV"], fullname = L["HALLS_OF_VALOR"]},
    {icon = "Interface\\Icons\\achievement_raid_karazhan", spellID = 373262, name = L["KARA"], fullname = L["KARAZHAN"]},
    {icon = "Interface\\Icons\\achievement_dungeon_neltharionslair", spellID = 410078, name = L["NL"], fullname = L["NELTHARIONS_LAIR"]}
}
-- Warlords of Draenor
MDT_PL_WOD = {
    {icon = "Interface\\Icons\\achievement_dungeon_auchindoun", spellID = 159897, name = L["AUCH"], fullname = L["AUCHINDOUN"]},
    {icon = "Interface\\Icons\\achievement_dungeon_ogreslagmines", spellID = 159895, name = L["BSM"], fullname = L["BLOODMAUL_SLAGMINES"]},
    {icon = "Interface\\Icons\\achievement_dungeon_everbloom", spellID = 159901, name = L["EB"], fullname = L["EVERBLOOM"]},
    {icon = "Interface\\Icons\\achievement_dungeon_blackrockdepot", spellID = 159900, name = L["GD"], fullname = L["GRIMRAIL_DEPOT"]},
    {icon = "Interface\\Icons\\achievement_dungeon_blackrockdocks", spellID = 159896, name = L["ID"], fullname = L["IRON_DOCKS"]},
    {icon = "Interface\\Icons\\achievement_dungeon_shadowmoonhideout", spellID = 159899, name = L["SBG"], fullname = L["SHADOWMOON_VALLEY"]},
    {icon = "Interface\\Icons\\achievement_dungeon_arakkoaspires", spellID = 159898, name = L["SR"], fullname = L["SPIRES_OF_ARAK"]},
    {icon = "Interface\\Icons\\achievement_dungeon_upperblackrockspire", spellID = 159902, name = L["UBRS"], fullname = L["UPPER_BLACKROCK_SPIRE"]}
}
-- Mists of Pandaria
MDT_PL_MOP = {
    {icon = "Interface\\Icons\\achievement_greatwall", spellID = 131225, name = L["GOTSS"], fullname = L["GATE_OF_SUN"]},
    {icon = "Interface\\Icons\\achievement_dungeon_mogupalace", spellID = 131222, name = L["MSP"], fullname = L["MOGU_PALACE"]},
    {icon = "Interface\\Icons\\spell_holy_senseundead", spellID = 131232, name = L["SCHOLO"], fullname = L["SCHOLOMANCE"]},
    {icon = "Interface\\Icons\\inv_helmet_52", spellID = 131231, name = L["SH"], fullname = L["SCARLET_HALLS"]},
    {icon = "Interface\\Icons\\spell_holy_resurrection", spellID = 131229, name = L["SM"], fullname = L["MONASTARY"]},
    {icon = "Interface\\Icons\\achievement_dungeon_siegeofniuzaotemple", spellID = 131228, name = L["SNT"], fullname = L["NIUZAO_TEMPLE"]},
    {icon = "Interface\\Icons\\achievement_shadowpan_hideout", spellID = 131206, name = L["SPM"], fullname = L["SHADO_MONASTARY"]},
    {icon = "Interface\\Icons\\achievement_brewery", spellID = 131205, name = L["SSB"], fullname = L["STORMSTOUT"]},
    {icon = "Interface\\Icons\\achievement_jadeserpent", spellID = 131204, name = L["TJS"], fullname = L["TEMPLE_JADE"]}
}
-- Cataclysm
MDT_PL_CATA = {
    {icon = "Interface\\Icons\\achievement_dungeon_grimbatol", spellID = 445424, name = L["GB"], fullname = L["GRIM_BATOL"]},
    {icon = "Interface\\Icons\\achievement_dungeon_throne of the tides", spellID = 424142, name = L["TOTT"], fullname = L["THRONE_OF_TIDES"]},
    {icon = "Interface\\Icons\\achievement_dungeon_skywall", spellID = 410080, name = L["VP"], fullname = L["VORTEX"]}
}

-- MARK: Portal Library Raid
MDT_PLR_SL = {
    {icon = "Interface\\Icons\\achievement_raid_revendrethraid_castlenathria", spellID = 373190, name = L["CN"], fullname = L["NATHRIA"]},
    {icon = "Interface\\Icons\\achievement_raid_torghastraid", spellID = 373191, name = L["SOD"], fullname = L["SANCTUM"]},
    {icon = "Interface\\Icons\\inv_achievement_raid_progenitorraid", spellID = 373192, name = L["STFO"], fullname = L["SEPULCHER"]}
}
MDT_PLR_DF = {
    {icon = "Interface\\Icons\\achievement_raidprimalist_raid", spellID = 432254, name = L["VOTI"], fullname = L["VAULT_INCARNATES"]},
    {icon = "Interface\\Icons\\inv_achievement_raiddragon_raid", spellID = 432257, name = L["ATSC"], fullname = L["ABBERUS"]},
    {icon = "Interface\\Icons\\inv_achievement_raidemeralddream_raid", spellID = 432258, name = L["ATDH"], fullname = L["AMIRDRASSIL"]}
}
MDT_PLR_TWW = {
    {icon = "Interface\\Icons\\inv_achievement_zone_undermine", spellID = 1226482, name = L["LOU"], fullname = L["UNDERMINE"]},
    {icon = "Interface\\Icons\\inv_achievement_raid_manaforgeomega", spellID = 1239155, name = L["MFO"], fullname = L["MANAFORGE"]}
}

-- MARK: Lock Icons

AltLocks = {
    {icon = "Interface\\Icons\\inv_babycosmicflyer_purple", spellID = 1237215}, -- Eco-Dome Al'dani
    {icon = "Interface\\Icons\\achievement_dungeon_mogulrazdunk", spellID = motherID}, -- The MOTHERLODE!!
    {icon = "Interface\\Icons\\achievement_zone_theringingdeeps", spellID = 1216786}, -- Operation: Floodgate
    {icon = "Interface\\Icons\\INV_Shield_1H_Maldraxxus_D_01", spellID = 354467}, -- Theatre of Pain
    {icon = "Interface\\Icons\\Achievement_AlliedRace_Mechagnome", spellID = 373274}, -- Operation: Mechagon
    {icon = "Interface\\Icons\\Achievement_Zone_IsleOfDorn", spellID = 445440},  -- Cinderbrew Meadery
    {icon = "Interface\\Icons\\INV_Misc_CandleKobold_Color3", spellID = 445441},  -- Darkflame Cleft
    {icon = "Interface\\Icons\\Achievement_Zone_Hallowfall", spellID = 445444},  -- Priory of the Sacred Flame
    {icon = "Interface\\Icons\\INV_Gryphon_Air_Mount_Dark", spellID = 445443}, -- The Rookery
    {icon = "Interface\\Icons\\achievement_zone_azjkahet", spellID = 445417}, -- Ara-Kara, City of Echoes
    {icon = "Interface\\Icons\\inv_achievement_raidnerubian_queenansurek", spellID = 445416}, -- City of Threads
    {icon = "Interface\\Icons\\inv_achievement_raidnerubian_flyingnerubianevolved", spellID = 445414}, -- The Dawnbreaker
    {icon = "Interface\\Icons\\inv_achievement_alliedrace_earthen", spellID = 445269}, -- The Stonevault
    {icon = "Interface\\Icons\\inv_ardenweald", spellID = 354464}, -- Mists of Tirne Scithe
    {icon = "Interface\\Icons\\inv_bastion", spellID = 354462}, -- The Necrotic Wake
    {icon = "Interface\\Icons\\inv_tiragardesound", spellID = siegeID}, -- Siege of Boralus
    {icon = "Interface\\Icons\\achievement_zone_twilighthighlands", spellID = 445424}, -- Grim Batol
    {icon = "Interface\\Icons\\achievement_zone_thaldraszus", spellID = 393273}, -- Algethar Acadmey
    {icon = "Interface\\Icons\\achievement_zone_azurespan", spellID = 393279}, -- The Azure Vault
    {icon = "Interface\\Icons\\inv_10_dungeonjewelry_titan_trinket_2_color1", spellID = 393283}, -- Galls of Atonement
    {icon = "Interface\\Icons\\achievement_zone_wakingshores", spellID = 393276}, -- Neltharus
    {icon = "Interface\\Icons\\achievement_zone_ohnahranplains", spellID = 393262}, -- The Nokud Offensive
    {icon = "Interface\\Icons\\inv_item_dragonegg_redbroken01", spellID = 393256}, -- Ruby Life Pools
    {icon = "Interface\\Icons\\achievement_zone_badlands_01", spellID = 393222}, -- Uldman: Legacy of Tyr
    {icon = "Interface\\Icons\\achievement_boss_infinitecorruptor", spellID = 424197}, -- Dawn of the Infinite
    {icon = "Interface\\Icons\\achievement_dungeon_theotherside_hakkar", spellID = 354468}, -- De Other Side
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement_halkias", spellID = 354465}, -- Halls of Attonement
    {icon = "Interface\\Icons\\inv_maldraxxus", spellID = 354463}, -- Plaugefall
    {icon = "Interface\\Icons\\achievement_raid_revendrethraid_generalkaalgrashaal", spellID = 354469}, -- Sanguine Depths
    {icon = "Interface\\Icons\\achievement_dungeon_spireofascension_ventunax", spellID = 354466}, -- Spires of Ascension
    {icon = "Interface\\Icons\\inv_misc_paperpackage01b", spellID = 367416}, -- Tazavesh
    {icon = "Interface\\Icons\\inv_zuldazar", spellID = 424187}, -- Atal'dazar
    {icon = "Interface\\Icons\\inv_tourofdutytiragardesound", spellID = 410071}, -- Freehold
    {icon = "Interface\\Icons\\achievement_nazmir_boss_ghuun", spellID = 410074}, -- Underrot
    {icon = "Interface\\Icons\\achievement_dungeon_lordandladywaycrest", spellID = 424167}, -- Waycrest Manor
    {icon = "Interface\\Icons\\achievements_zone_valsharah", spellID = 424153}, -- Black Rook Hold
    {icon = "Interface\\Icons\\achievements_zone_suramar", spellID = 393766}, -- Court of Stars
    {icon = "Interface\\Icons\\achievement_emeraldnightmare_xavius", spellID = 424163}, -- Darkheart Thicket
    {icon = "Interface\\Icons\\achievements_zone_stormheim", spellID = 393764}, -- Halls of Valor
    {icon = "Interface\\Icons\\achievements_zone_highmountain", spellID = 410078}, -- Neltharions Lair
    {icon = "Interface\\Icons\\achievement_zone_deadwindpass", spellID = 373262}, -- Karazhan
    {icon = "Interface\\Icons\\achievement_zone_talador", spellID = 159897}, -- Auchindoun
    {icon = "Interface\\Icons\\achievement_zone_frostfire", spellID = 159895}, -- Bloodmaul Slag Mines
    {icon = "Interface\\Icons\\achievement_zone_gorgrond", spellID = 159901}, -- The Everbloom
    {icon = "Interface\\Icons\\inv_offhand_1h_draenorraid_d_04", spellID = 159900}, -- Grim Batol
    {icon = "Interface\\Icons\\achievement_boss_ironjuggernaut", spellID = 159896}, -- Iron Docks
    {icon = "Interface\\Icons\\achievement_zone_newshadowmoonvalley", spellID = 159899}, -- Shadowmoon Burial Grounds
    {icon = "Interface\\Icons\\achievement_zone_spiresofarak", spellID = 159898}, -- Spires of Arak
    {icon = "Interface\\Icons\\achievement_dungeon_blackrockcaverns", spellID = 159902}, -- Upper Black Rock Spire
    {icon = "Interface\\Icons\\achievement_raid_soo_ruined_vale", spellID = 131225}, -- Gate of the Setting Sun
    {icon = "Interface\\Icons\\achievement_zone_valeofeternalblossoms", spellID = 131222}, -- Mogu'shan Palace
    {icon = "Interface\\Icons\\achievement_zone_westernplaguelands_01", spellID = 131232}, -- Scholomance
    {icon = "Interface\\Icons\\achievement_zone_tirisfalglades_01", spellID = 131231}, -- Scarlet Halls
    {icon = "Interface\\Icons\\inv_misc_token_scarletcrusade", spellID = 131229}, -- Scarlet Monastary
    {icon = "Interface\\Icons\\achievement_zone_townlongsteppes", spellID = 131228}, -- Siege of Niuzao Temple
    {icon = "Interface\\Icons\\achievement_zone_kunlaisummit", spellID = 131206}, -- Shado-Pan Monastary
    {icon = "Interface\\Icons\\achievement_zone_valleyoffourwinds", spellID = 131205}, -- Stormstour Brewery
    {icon = "Interface\\Icons\\achievement_zone_jadeforest", spellID = 131204}, -- Temple of the Jade Serpent
    {icon = "Interface\\Icons\\achievement_zone_vashjir", spellID = 424142}, -- Throne of the Tides
    {icon = "Interface\\Icons\\achievement_zone_uldum", spellID = 410080}, -- Vortex Pinnacle
    -- raid portals
    {icon = "Interface\\Icons\\achievement_raidprimalist_raszageth", spellID = 432254}, -- Vault of the Incarnates
    {icon = "Interface\\Icons\\spell_sarkareth", spellID = 432257}, -- Abberus the Shadowed Crucible
    {icon = "Interface\\Icons\\inv_achievement_raidemeralddream_fyrakk", spellID = 432258}, -- Amirdrasill, The Dreams Hope
    {icon = "Interface\\Icons\\achievement_raid_revendrethraid_siredenathrius", spellID = 373190}, -- Castle Nathria
    {icon = "Interface\\Icons\\achievement_raid_torghast_sylvanaswindrunner", spellID = 373191}, -- Sanctum of Domination
    {icon = "Interface\\Icons\\inv_achievement_raid_progenitorraid_jailer", spellID = 373192}, -- Sepulcher of the First Ones
    {icon = "Interface\\Icons\\inv_111_raid_achievement_chromekinggallywix", spellID = 1226482}, -- Liberation of Undermine
    {icon = "Interface\\Icons\\inv_112_achievement_raid_dimensius", spellID = 1239155} -- Manaforge Omega
}
-- Key Tracker Data
KeyTrackerIcons = {
    {icon = "Interface\\Icons\\inv_achievement_dungeon_arak-ara", spellID = 445417, short = L["ARAK_SHORT"] , name = "", mapID = 503},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_dawnbreaker", spellID = 445414, short = L["DAWN_SHORT"], name = "", mapID = 505},
    {icon = "Interface\\Icons\\inv_112_achievement_dungeon_ecodome", spellID = 1237215, short = L["ECO_DOME_SHORT"], name = "", mapID = 542},
    {icon = "Interface\\Icons\\achievement_dungeon_hallsofattonement", spellID = 354465, short = L["HALLS_SHORT"], name = "", mapID = 378},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_waterworks", spellID = 1216786, short = L["FLOODGATE_SHORT"], name = "", mapID = 525},
    {icon = "Interface\\Icons\\inv_achievement_dungeon_prioryofthesacredflame", spellID = 445444, short = L["PRIORY_SHORT"], name = "", mapID = 499},
    {icon = "Interface\\Addons\\MDungeonTeleports\\media\\icons\\gambit", spellID = 367416, short = L["GAMBIT_SHORT"], name = "", mapID = 392},
    {icon = "Interface\\Addons\\MDungeonTeleports\\media\\icons\\streets", spellID = 367416, short = L["STREETS_SHORT"], name = "", mapID = 391}
}