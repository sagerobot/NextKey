-- MARK: Module Definition
local _, NextKey222 = ...

local OrganizerSorting = {}
NextKey222.OrganizerSorting = OrganizerSorting
NextKey222.RegisterModule("OrganizerSorting", OrganizerSorting)

local Debug = NextKey222.Debug

-- MARK: Initialization
function OrganizerSorting:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Initialized OrganizerSorting module")
        return true
    end, "OrganizerSorting:Initialize")
end

-- MARK: Helper Functions

--- Collect players who can play a specific role (play OR fill preference)
-- @param players Array of player data objects
-- @param role string Role name ("Tank", "Healer", "DPS")
-- @param allowDPSOnlyFlex boolean If true, include DPS-only players for this role
-- @return Array of candidates sorted by preference priority
local function collect_players_by_role_preference(players, role, allowDPSOnlyFlex)
    local result = {}
    
    for _, player in ipairs(players) do
        local preference = nil
        local canPlayRole = nil  -- nil means "not determined yet"
        
        -- Check if player has spec preferences from poll
        -- CRITICAL: Empty table {} is NOT the same as no poll response
        local hasAnsweredPoll = false
        if player.specPreferences then
            -- Check if the table has any actual preferences
            for _ in pairs(player.specPreferences) do
                hasAnsweredPoll = true
                break
            end
        end
        
        if hasAnsweredPoll then
            -- Player answered poll - check their preference for this specific role
            -- CRITICAL: Handle both "DAMAGER" and "DPS" naming (WoW API inconsistency)
            preference = player.specPreferences[role]
            
            -- Fallback for DPS/DAMAGER synonym
            if not preference and role == "DAMAGER" then
                preference = player.specPreferences["DPS"]
            elseif not preference and role == "DPS" then
                preference = player.specPreferences["DAMAGER"]
            end
            
            if preference == "play" or preference == "fill" then
                -- Player wants to play this role
                canPlayRole = true
                Debug:Dev("organizer", "Poll data for", player.name, "role", role, "preference:", preference)
            elseif preference == "none" then
                -- Player explicitly does NOT want this role
                canPlayRole = false
                Debug:Dev("organizer", "Poll data for", player.name, "role", role, "preference: none - excluding")
            else
                -- preference is nil - player didn't select anything for this role in poll
                -- Check if ALL their preferences are nil (didn't answer poll properly)
                local hasAnyPreference = false
                for _, pref in pairs(player.specPreferences) do
                    if pref == "play" or pref == "fill" or pref == "none" then
                        hasAnyPreference = true
                        break
                    end
                end
                
                if hasAnyPreference then
                    -- They answered poll but skipped this role - treat as "none"
                    canPlayRole = false
                    Debug:Dev("organizer", "Poll data for", player.name, "role", role, "not selected in poll - excluding")
                else
                    -- Poll data exists but is empty - fall back to roles array
                    Debug:Dev("organizer", "Poll data for", player.name, "role", role, "empty poll - checking roles")
                end
            end
        end
        
        -- Fallback: Check if player's roles array includes this role
        -- (only used when player didn't answer poll OR poll data was completely empty)
        if canPlayRole == nil and player.roles then
            -- Check if player is DPS-only (for flex filtering)
            local isDPSOnly = false
            if not allowDPSOnlyFlex then
                -- Check if player only has DPS role
                local hasNonDPSRole = false
                for _, playerRole in ipairs(player.roles) do
                    local normalized = playerRole:upper()
                    if normalized == "TANK" or normalized == "HEALER" then
                        hasNonDPSRole = true
                        break
                    end
                end
                isDPSOnly = not hasNonDPSRole
            end
            
            -- Check if this is a DPS-only player being evaluated for Tank/Healer
            if isDPSOnly and (role:upper() == "TANK" or role:upper() == "HEALER") then
                -- DPS-only players cannot fill Tank/Healer roles, skip role matching
                Debug:Dev("organizer", "Skipping DPS-only player", player.name, "for", role, "role (not eligible)")
                canPlayRole = false
            else
                -- Check if player has the requested role
                for _, playerRole in ipairs(player.roles) do
                    local normalizedRole = playerRole:upper()
                    local normalizedTargetRole = role:upper()
                    
                    -- Match TANK, HEALER, or DAMAGER/DPS
                    if normalizedRole == normalizedTargetRole or
                       (normalizedTargetRole == "DPS" and normalizedRole == "DAMAGER") or
                       (normalizedTargetRole == "DAMAGER" and normalizedRole == "DPS") then
                        canPlayRole = true
                        preference = "play" -- Default to "play" when using roles array
                        Debug:Dev("organizer", "Fallback roles for", player.name, "role", role, "matched")
                        break
                    end
                end
            end
        end
        
        -- Include players who can play this role
        if canPlayRole then
            table.insert(result, {
                player = player,
                preference = preference,
                priority = (preference == "play") and 10 or 5
            })
        end
    end
    
    -- Sort by priority (play > fill)
    table.sort(result, function(a, b)
        return a.priority > b.priority
    end)
    
    return result
end

-- MARK: Main Sorting Function
--- Calculates sequential assignment plan using global priority sorting
--- Ensures "want to play" is prioritized over "fill" across ALL roles
-- @param benchPlayers Array of player data objects from bench
-- @param numGroups Number of groups to distribute players into
-- @return Array of assignment objects: {player, groupIndex, slotIndex, role, assignedFromPreference}
function OrganizerSorting:CalculateSequentialAssignment(benchPlayers, numGroups)
    return NextKey222.SafeRun(function()
        if not benchPlayers or #benchPlayers == 0 then
            Debug:Error("No players to sort")
            return {}
        end
        
        if numGroups < 1 then
            Debug:Error("Invalid number of groups:", numGroups)
            return {}
        end
        
        Debug:Dev("organizer", "Calculating sequential assignment for", #benchPlayers, "players into", numGroups, "groups")
        
        -- Build role candidate lists (sorted by priority within role)
        -- allowDPSOnlyFlex = false: Don't assign DPS-only players to Tank/Healer
        local tankCandidates = collect_players_by_role_preference(benchPlayers, "TANK", false)
        local healerCandidates = collect_players_by_role_preference(benchPlayers, "HEALER", false)
        local dpsCandidates = collect_players_by_role_preference(benchPlayers, "DAMAGER", true)
        
        Debug:Dev("organizer", "Role candidates - Tank:", #tankCandidates, "Healer:", #healerCandidates, "DPS:", #dpsCandidates)
        Debug:Dev("organizer", "Enhanced priority: DPS-only players excluded from Tank/Healer flex")
        
        -- Track assigned players AND slots to prevent double assignment
        local assignedPlayers = {}
        local assignedSlots = {}  -- {[groupIndex][slotIndex] = true}
        local assignmentPlan = {}
        
        -- Helper function to assign next available player for a role
        local function assign_next_for_role(candidates, candidateIndex, role, groupIndex, slotIndex)
            -- Check if slot is already filled
            if assignedSlots[groupIndex] and assignedSlots[groupIndex][slotIndex] then
                return candidateIndex  -- Slot occupied, skip assignment
            end
            
            -- Skip already assigned players
            while candidateIndex <= #candidates and
                  assignedPlayers[candidates[candidateIndex].player.id] do
                candidateIndex = candidateIndex + 1
            end
            
            if candidateIndex <= #candidates then
                local candidate = candidates[candidateIndex]
                
                table.insert(assignmentPlan, {
                    player = candidate.player,
                    groupIndex = groupIndex,
                    slotIndex = slotIndex,
                    role = role,
                    assignedFromPreference = candidate.preference
                })
                
                assignedPlayers[candidate.player.id] = true
                
                -- Mark slot as occupied
                if not assignedSlots[groupIndex] then
                    assignedSlots[groupIndex] = {}
                end
                assignedSlots[groupIndex][slotIndex] = true
                
                Debug:Dev("organizer", "  - Assigned", candidate.player.name, "to", role, "(preference:", candidate.preference, ")")
                
                return candidateIndex + 1
            end
            
            return candidateIndex
        end
        
        -- Role-by-role assignment strategy
        -- Fill each role completely (play → fill) before moving to next role
        -- This ensures flex players fill high-priority roles first
        
        Debug:Dev("organizer", "Role-by-role assignment: Tank → Healer → DPS")
        
        -- Phase 1: Fill ALL Tank slots (play preferences first, then fill)
        Debug:Dev("organizer", "Phase 1: Assigning all Tank slots")
        local tankIdx = 1
        for groupIndex = 1, numGroups do
            tankIdx = assign_next_for_role(tankCandidates, tankIdx, "TANK", groupIndex, 1)
        end
        
        -- Phase 2: Fill ALL Healer slots (play preferences first, then fill)
        Debug:Dev("organizer", "Phase 2: Assigning all Healer slots")
        local healerIdx = 1
        for groupIndex = 1, numGroups do
            healerIdx = assign_next_for_role(healerCandidates, healerIdx, "HEALER", groupIndex, 2)
        end
        
        -- Phase 3: Fill ALL DPS slots (play preferences first, then fill)
        Debug:Dev("organizer", "Phase 3: Assigning all DPS slots")
        local dpsIdx = 1
        for dpsSlotNumber = 1, 3 do
            for groupIndex = 1, numGroups do
                dpsIdx = assign_next_for_role(dpsCandidates, dpsIdx, "DAMAGER", groupIndex, 2 + dpsSlotNumber)
            end
        end
        
        Debug:Dev("organizer", "Generated assignment plan with", #assignmentPlan, "assignments")
        
        return assignmentPlan
        
    end, "OrganizerSorting:CalculateSequentialAssignment")
end