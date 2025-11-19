-- MARK: Module Definition
local _, NextKey222 = ...

--- PlayerCapabilities Module
--- Contains data tables and functions for detecting player capabilities (Heroism, Battle Res)
--- Extracted from ui/main.lua lines 2-36, 387-428
local PlayerCapabilities = {}
NextKey222.PlayerCapabilities = PlayerCapabilities

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("PlayerCapabilities", PlayerCapabilities)

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Capability Data Tables

--- Classes that can provide Heroism/Bloodlust
local HEROISM_CLASSES = {
    SHAMAN = true,
    MAGE = true,
    EVOKER = true
}

--- Classes that can provide Battle Resurrection
local BATTLE_RES_CLASSES = {
    DRUID = true,
    WARLOCK = true,
    DEATHKNIGHT = true
}

--- Spec-specific capabilities (spec ID -> capabilities table)
local SPEC_CAPABILITIES_UI = {
    [62] = { heroism = true },   -- Arcane Mage
    [63] = { heroism = true },   -- Fire Mage
    [64] = { heroism = true },   -- Frost Mage
    [262] = { heroism = true },  -- Elemental Shaman
    [263] = { heroism = true },  -- Enhancement Shaman
    [264] = { heroism = true },  -- Restoration Shaman
    [1467] = { heroism = true }, -- Devastation Evoker
    [1468] = { heroism = true }, -- Preservation Evoker
    [1473] = { heroism = true }, -- Augmentation Evoker
    [253] = { heroism = true },  -- Beast Mastery Hunter

    [102] = { battleRes = true }, -- Balance Druid
    [103] = { battleRes = true }, -- Feral Druid
    [104] = { battleRes = true }, -- Guardian Druid
    [105] = { battleRes = true }, -- Restoration Druid
    [250] = { battleRes = true }, -- Blood Death Knight
    [251] = { battleRes = true }, -- Frost Death Knight
    [252] = { battleRes = true }, -- Unholy Death Knight
    [265] = { battleRes = true }, -- Affliction Warlock
    [266] = { battleRes = true }, -- Demonology Warlock
    [267] = { battleRes = true }  -- Destruction Warlock
}

-- MARK: Private Helper Functions

--- Normalizes class token to uppercase
--- @param classToken string The class token to normalize
--- @return string|nil Normalized class token or nil
local function normalizeClassToken(classToken)
    if not classToken then return nil end
    return string.upper(classToken)
end

-- MARK: Public Interface

--- Checks if a player can provide Heroism/Bloodlust
--- @param profile table|nil Player profile data
--- @param classToken string|nil Player class token
--- @param specID number|nil Player spec ID
--- @return boolean true if player can provide heroism
function PlayerCapabilities:PlayerProvidesHeroism(profile, classToken, specID)
    -- Check profile capabilities first (most specific)
    if profile and profile.capabilities and profile.capabilities.heroism ~= nil then
        return profile.capabilities.heroism
    end

    -- Normalize class token from parameter or profile
    classToken = normalizeClassToken(classToken) or (profile and normalizeClassToken(profile.class))
    specID = specID or (profile and profile.specID)

    -- Check spec-specific capabilities
    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].heroism then
        return true
    end

    -- Check class-wide capabilities
    if classToken and HEROISM_CLASSES[classToken] then
        return true
    end

    return false
end

--- Checks if a player can provide Battle Resurrection
--- @param profile table|nil Player profile data
--- @param classToken string|nil Player class token
--- @param specID number|nil Player spec ID
--- @return boolean true if player can provide battle res
function PlayerCapabilities:PlayerProvidesBattleRes(profile, classToken, specID)
    -- Check profile capabilities first (most specific)
    if profile and profile.capabilities and profile.capabilities.battleRes ~= nil then
        return profile.capabilities.battleRes
    end

    -- Normalize class token from parameter or profile
    classToken = normalizeClassToken(classToken) or (profile and normalizeClassToken(profile.class))
    specID = specID or (profile and profile.specID)

    -- Check spec-specific capabilities
    if specID and SPEC_CAPABILITIES_UI[specID] and SPEC_CAPABILITIES_UI[specID].battleRes then
        return true
    end

    -- Check class-wide capabilities
    if classToken and BATTLE_RES_CLASSES[classToken] then
        return true
    end

    return false
end

-- MARK: Initialization

--- Initializes the PlayerCapabilities module
--- @return boolean true if initialization succeeded
function PlayerCapabilities:Initialize()
    Debug:Dev("playercapabilities", "PlayerCapabilities initialized")
    return true
end

return PlayerCapabilities