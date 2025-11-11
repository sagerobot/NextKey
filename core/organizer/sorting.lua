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
-- @return Array of candidates sorted by preference priority
local function collect_players_by_role_preference(players, role)
    local result = {}
    
    for _, player in ipairs(players) do
        local preference = nil
        local canPlayRole = false
        
        -- Check if player has spec preferences from poll
        if player.specPreferences then
            -- Player answered poll - use their explicit preferences
            preference = player.specPreferences[role]
            canPlayRole = (preference == "play" or preference == "fill")
            
            Debug:Dev("organizer", "Poll data for", player.name, "role", role, "preference:", preference or "none")
        else
            -- Fallback: Check if player's roles array includes this role
            -- (used for players who haven't answered poll yet)
            if player.roles then
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