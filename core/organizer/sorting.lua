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
        if player.specPreferences and player.specPreferences[role] then
            preference = player.specPreferences[role]
            canPlayRole = (preference == "play" or preference == "fill")
        else
            -- Fallback: Check if player's roles array includes this role
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
--- Calculates sequential assignment plan using role-priority round-robin distribution
--- Enhanced with flexible role assignment based on spec preferences
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
        
        -- Track assigned players to prevent double assignment
        local assignedPlayers = {}
        
        -- Build assignment plan (sequential order with flexible role assignment)
        local assignmentPlan = {}
        
        -- Phase 1: Assign tanks (1 per group, round-robin with flexibility)
        local tankCandidates = collect_players_by_role_preference(benchPlayers, "TANK")
        local tankIndex = 1
        
        Debug:Dev("organizer", "Tank assignment - Found", #tankCandidates, "candidates (play + fill)")
        
        for groupIndex = 1, numGroups do
            if tankIndex <= #tankCandidates then
                local candidate = tankCandidates[tankIndex]
                
                table.insert(assignmentPlan, {
                    player = candidate.player,
                    groupIndex = groupIndex,
                    slotIndex = 1, -- Tank slot
                    role = "TANK",
                    assignedFromPreference = candidate.preference -- Track if "fill" or "play"
                })
                
                assignedPlayers[candidate.player.id] = true
                Debug:Dev("organizer", "  - Assigned", candidate.player.name, "to Tank (preference:", candidate.preference, ")")
                tankIndex = tankIndex + 1
            end
        end
        
        -- Phase 2: Assign healers (1 per group, round-robin with flexibility, excluding assigned tanks)
        local healerCandidates = collect_players_by_role_preference(benchPlayers, "HEALER")
        local healerIndex = 1
        
        Debug:Dev("organizer", "Healer assignment - Found", #healerCandidates, "candidates (play + fill)")
        
        for groupIndex = 1, numGroups do
            -- Skip already assigned players (tanks)
            while healerIndex <= #healerCandidates and
                  assignedPlayers[healerCandidates[healerIndex].player.id] do
                Debug:Dev("organizer", "  - Skipping", healerCandidates[healerIndex].player.name, "(already assigned to tank)")
                healerIndex = healerIndex + 1
            end
            
            if healerIndex <= #healerCandidates then
                local candidate = healerCandidates[healerIndex]
                
                table.insert(assignmentPlan, {
                    player = candidate.player,
                    groupIndex = groupIndex,
                    slotIndex = 2, -- Healer slot
                    role = "HEALER",
                    assignedFromPreference = candidate.preference
                })
                
                assignedPlayers[candidate.player.id] = true
                Debug:Dev("organizer", "  - Assigned", candidate.player.name, "to Healer (preference:", candidate.preference, ")")
                healerIndex = healerIndex + 1
            end
        end
        
        -- Phase 3: Assign DPS (3 per group, round-robin - all unassigned players)
        local dpsPlayers = {}
        for _, player in ipairs(benchPlayers) do
            if not assignedPlayers[player.id] then
                table.insert(dpsPlayers, player)
            end
        end
        
        Debug:Dev("organizer", "DPS assignment - Found", #dpsPlayers, "unassigned players")
        
        local dpsIndex = 1
        for dpsSlotNumber = 1, 3 do -- For each DPS slot (3, 4, 5)
            for groupIndex = 1, numGroups do
                if dpsIndex <= #dpsPlayers then
                    table.insert(assignmentPlan, {
                        player = dpsPlayers[dpsIndex],
                        groupIndex = groupIndex,
                        slotIndex = 2 + dpsSlotNumber, -- DPS slots 3, 4, 5
                        role = "DAMAGER",
                        assignedFromPreference = "play" -- Default for DPS
                    })
                    Debug:Dev("organizer", "  - Assigned", dpsPlayers[dpsIndex].name, "to DPS slot", dpsSlotNumber)
                    dpsIndex = dpsIndex + 1
                end
            end
        end
        
        Debug:Dev("organizer", "Generated assignment plan with", #assignmentPlan, "assignments")
        
        return assignmentPlan
        
    end, "OrganizerSorting:CalculateSequentialAssignment")
end