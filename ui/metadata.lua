local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug

-- MARK: Module Definition

-- MetadataEnricher module provides metadata enrichment for keystone entries.
-- Centralizes profile integration, role resolution, capability detection,
-- and dungeon name resolution for consistent UI rendering.

local MetadataEnricher = {}

NextKey222.MetadataEnricher = MetadataEnricher
NextKey222.RegisterModule("MetadataEnricher", MetadataEnricher)

-- MARK: Private Helpers

local function safe_debug_dev(category, ...)
    if Debug and Debug.Dev then
        Debug:Dev(category, ...)
    end
end

local function safe_debug_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

-- MARK: Role Resolution

--- Resolve player role from profile and specID
-- Uses spec-to-role mapping for reliable role detection, falling back to profile.role
-- @param profile table Player profile from ProfilesService
-- @param specID number Specialization ID
-- @return string Role ("TANK", "HEALER", "DAMAGER")
function MetadataEnricher:resolve_player_role(profile, specID)
    -- Priority 1: Use spec-to-role mapping when specID available
    if specID and NextKey222.UIComponents and NextKey222.UIComponents.GetRoleFromSpecID then
        local role = NextKey222.UIComponents:GetRoleFromSpecID(specID, "DAMAGER")
        return role
    end

    -- Priority 2: Use profile.role (already normalized by ProfilesService)
    if profile and profile.role then
        return string.upper(profile.role)
    end

    -- Fallback: Default to DAMAGER
    return "DAMAGER"
end

-- MARK: Capability Detection

--- Get player capabilities (heroism, battle res)
-- @param ui table UI facade reference (for capability methods)
-- @param profile table Player profile
-- @param classToken string Class token (e.g., "EVOKER")
-- @param specID number Specialization ID
-- @return table { hasHeroism: boolean, hasBattleRes: boolean }
function MetadataEnricher:get_player_capabilities(ui, profile, classToken, specID)
    local capabilities = {
        hasHeroism = false,
        hasBattleRes = false,
    }

    if not ui then
        return capabilities
    end

    -- Use UI's capability methods (delegate to PlayerCapabilities)
    if ui.PlayerProvidesHeroism then
        capabilities.hasHeroism = ui:PlayerProvidesHeroism(profile, classToken, specID)
    end

    if ui.PlayerProvidesBattleRes then
        capabilities.hasBattleRes = ui:PlayerProvidesBattleRes(profile, classToken, specID)
    end

    -- Also check profile.capabilities if available
    if profile and profile.capabilities then
        if profile.capabilities.heroism then
            capabilities.hasHeroism = true
        end
        if profile.capabilities.battleRes then
            capabilities.hasBattleRes = true
        end
    end

    return capabilities
end

-- MARK: Public Interface

--- Enrich a keystone entry with metadata
-- This is the main entry point for metadata enrichment, extracting logic
-- from ui/main.lua:EnrichEntryMetadata for better separation of concerns.
-- @param ui table UI facade reference
-- @param entry table Keystone entry to enrich
function MetadataEnricher:enrich_entry_metadata(ui, entry)
    if not entry or not entry.key then
        return
    end

    local owner_name = entry.key.ownerName or "Unknown"
    entry.ownerName = owner_name

    -- Normalize player name
    local normalized_name = NextKey222.UIComponents
        and NextKey222.UIComponents:NormalizePlayerName(owner_name)
        or owner_name
    entry.normalizedOwnerName = normalized_name

    -- Get cached profile
    local profile = nil
    if NextKey222.ProfileCache and NextKey222.ProfileCache.get_cached_profile then
        profile = NextKey222.ProfileCache:get_cached_profile(normalized_name)
    elseif ui and ui.GetPlayerProfileCached then
        -- Fallback to UI method for backward compatibility
        profile = ui:GetPlayerProfileCached(normalized_name)
    end

    -- Debug logging for Evoker role issue (legacy tracking)
    if owner_name:find("Ryuza") or (profile and profile.class == "EVOKER") then
        safe_debug_dev("metadata", string.format(
            "EnrichEntryMetadata Debug: ownerName=%s, normalizedName=%s, profile=%s",
            owner_name, normalized_name, profile and "exists" or "nil"
        ))
        if profile then
            safe_debug_dev("metadata", string.format(
                "Profile Data: class=%s, role=%s, specName=%s, specID=%s",
                profile.class or "nil",
                profile.role or "nil",
                profile.specName or "nil",
                profile.specID or "nil"
            ))
        end
    end

    entry.profile = profile
    entry.specName = profile and profile.specName or nil
    entry.specID = profile and profile.specID or nil

    -- PHASE 1: Diagnostic logging - track role determination
    if Debug and (owner_name:find("Ryuza") or (profile and profile.class == "EVOKER")) then
        safe_debug_dev("metadata", string.format(
            "EnrichEntryMetadata BEFORE role detection: ownerName=%s, specID=%s, profile.role=%s",
            owner_name, entry.specID or "nil", profile and profile.role or "nil"
        ))
    end

    -- Resolve role using dedicated method
    entry.role = self:resolve_player_role(profile, entry.specID)

    -- PHASE 1: Diagnostic logging - track role resolution result
    if Debug and (owner_name:find("Ryuza") or (profile and profile.class == "EVOKER")) then
        safe_debug_dev("metadata", string.format(
            "Role resolved to: %s (specID=%s, profile.role=%s)",
            entry.role or "nil",
            entry.specID or "nil",
            profile and profile.role or "nil"
        ))
    end

    -- Get capabilities
    local class_token = entry.key.class or (profile and profile.class)
    local spec_id = profile and profile.specID

    local capabilities = self:get_player_capabilities(ui, profile, class_token, spec_id)
    entry.hasHeroism = capabilities.hasHeroism
    entry.hasBattleRes = capabilities.hasBattleRes

    -- Dungeon name
    if entry.key.dungeonID then
        entry.dungeonName = NextKey222.Addon:GetDungeonName(entry.key.dungeonID)
            or ("Dungeon " .. entry.key.dungeonID)
    else
        entry.dungeonName = "No Dungeon"
    end

    entry.keyLevel = entry.key.level or 0

    -- Expected IO gain
    local expected = entry.ioGainRange
        and entry.ioGainRange.expected
        or entry.ioGainPotential
        or 0
    entry.expectedGain = expected or 0

    -- Current dungeon IO from breakdown or calculators
    if entry.ioGainRange and entry.ioGainRange.playerBreakdown then
        local breakdown = entry.ioGainRange.playerBreakdown[normalized_name]
        if breakdown then
            entry.currentDungeonIO = breakdown.current or 0
        end
    end

    if not entry.currentDungeonIO then
        if NextKey222.IOCalculator and entry.key.dungeonID then
            entry.currentDungeonIO = NextKey222.IOCalculator:GetPlayerDungeonScore(
                normalized_name,
                entry.key.dungeonID
            ) or 0
        else
            entry.currentDungeonIO = 0
        end
    end

    -- Final diagnostic logging
    if Debug and (owner_name:find("Ryuza") or (profile and profile.class == "EVOKER")) then
        safe_debug_dev("metadata", string.format(
            "EnrichEntryMetadata COMPLETE: final entry.role = %s (will be used for icon display)",
            entry.role or "nil"
        ))
    end
end

-- MARK: Initialize

function MetadataEnricher:Initialize()
    safe_debug_dev("metadata", "MetadataEnricher module initialized")
    return true
end

return MetadataEnricher