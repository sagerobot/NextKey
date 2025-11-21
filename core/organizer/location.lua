-- MARK: Module Definition
local _, NextKey222 = ...

local Location = {}
NextKey222.Location = Location
NextKey222.RegisterModule("Location", Location)

local Debug = NextKey222.Debug

-- MARK: Location Type Definition
-- Location type can be:
-- 1. "bench" (string) - Player is on the bench
-- 2. "opt_out" (string) - Player has opted out
-- 3. {zone="slot", group=N, slot=N} (table) - Player is in a group slot

-- MARK: Public API

--- Converts a location to a human-readable string for debugging
-- @param location Location - The location to convert
-- @return string - Human-readable location string
function Location.ToString(location)
    return NextKey222.SafeRun(function()
        if not location then
            return "nil"
        end
        
        if type(location) == "string" then
            return location
        end
        
        if type(location) == "table" then
            if location.zone == "slot" then
                return string.format("slot(group=%d, slot=%d)", 
                    location.group or 0, location.slot or 0)
            end
            -- Fallback for unknown table format
            return "table(unknown)"
        end
        
        return "unknown(" .. type(location) .. ")"
    end, "Location.ToString")
end

--- Compares two locations for equality
-- @param loc1 Location - First location
-- @param loc2 Location - Second location
-- @return boolean - True if locations are equal
function Location.IsEqual(loc1, loc2)
    return NextKey222.SafeRun(function()
        -- Both nil
        if not loc1 and not loc2 then
            return true
        end
        
        -- One nil, one not
        if not loc1 or not loc2 then
            return false
        end
        
        -- Both strings
        if type(loc1) == "string" and type(loc2) == "string" then
            return loc1 == loc2
        end
        
        -- Both tables (slot locations)
        if type(loc1) == "table" and type(loc2) == "table" then
            return loc1.zone == loc2.zone and
                   loc1.group == loc2.group and
                   loc1.slot == loc2.slot
        end
        
        -- Different types
        return false
    end, "Location.IsEqual")
end

--- Converts from legacy format (bench set, optOut set, groups table) to new Location format
-- @param benchSet table - {[playerID] = true} set for bench players
-- @param optOutSet table - {[playerID] = true} set for opt-out players
-- @param groups table - {[groupIndex][slotIndex] = playerID} for slot assignments
-- @param playerID string - The player to find location for
-- @return Location|nil - The player's location in new format, or nil if not found
function Location.FromLegacy(benchSet, optOutSet, groups, playerID)
    return NextKey222.SafeRun(function()
        if not playerID then
            return nil
        end
        
        -- Check bench
        if benchSet and benchSet[playerID] then
            return "bench"
        end
        
        -- Check opt-out
        if optOutSet and optOutSet[playerID] then
            return "opt_out"
        end
        
        -- Check group slots
        if groups then
            for groupIndex, slots in pairs(groups) do
                for slotIndex, assignedPlayerID in pairs(slots) do
                    if assignedPlayerID == playerID then
                        return {
                            zone = "slot",
                            group = groupIndex,
                            slot = slotIndex
                        }
                    end
                end
            end
        end
        
        return nil
    end, "Location.FromLegacy")
end

--- Converts from new Location format to legacy format (updates legacy data structures)
-- @param location Location - The location in new format
-- @param benchSet table - {[playerID] = true} set to update
-- @param optOutSet table - {[playerID] = true} set to update
-- @param groups table - {[groupIndex][slotIndex] = playerID} to update
-- @param playerID string - The player to place
function Location.ToLegacy(location, benchSet, optOutSet, groups, playerID)
    return NextKey222.SafeRun(function()
        if not location or not playerID then
            return false
        end
        
        -- Clear player from all legacy locations first
        if benchSet then
            benchSet[playerID] = nil
        end
        if optOutSet then
            optOutSet[playerID] = nil
        end
        if groups then
            for groupIndex, slots in pairs(groups) do
                for slotIndex, assignedPlayerID in pairs(slots) do
                    if assignedPlayerID == playerID then
                        groups[groupIndex][slotIndex] = nil
                    end
                end
            end
        end
        
        -- Place in new location
        if type(location) == "string" then
            if location == "bench" and benchSet then
                benchSet[playerID] = true
            elseif location == "opt_out" and optOutSet then
                optOutSet[playerID] = true
            end
        elseif type(location) == "table" and location.zone == "slot" then
            if groups then
                -- Initialize group if needed
                if not groups[location.group] then
                    groups[location.group] = {}
                end
                groups[location.group][location.slot] = playerID
            end
        end
        
        return true
    end, "Location.ToLegacy")
end

-- MARK: Initialization
function Location:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Location module initialized")
        return true
    end, "Location:Initialize")
end

Debug:Dev("organizer", "Location module loaded")