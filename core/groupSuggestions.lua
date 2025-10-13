local _, NextKey222 = ...

-- MARK: Group Suggestions Module
-- Intelligent grouping system for NextKey
-- Provides Best Key and Best Groups mode suggestions

local GroupSuggestions = {}
NextKey222.GroupSuggestions = GroupSuggestions

local NextKey = NextKey222.Addon
local Debug = NextKey222.Debug

-- MARK: Core Data Structures

--- Enhanced player profile for group suggestions
---@class PlayerProfile
---@field name string Player name with realm
---@field class string Player class (WARRIOR, MAGE, etc.)
---@field specID number Specialization ID
---@field role string Role (TANK, HEALER, DAMAGER)
---@field io number Current IO score
---@field keystones table List of owned keystones
---@field capabilities table Utility capabilities (heroism, battleRes, etc.)
---@field dungeonGains table IO gain potential per dungeon

--- Group suggestion result
---@class GroupSuggestion
---@field mode string "best_key" or "best_groups"
---@field selectedKey table|nil For best_key mode
---@field roster table List of 5 players
---@field ioGain table Total and per-player IO gains
---@field utilities table Utility status (hasHeroism, hasBattleRes, etc.)
---@field isValid boolean Whether suggestion is complete
---@field warnings table List of warnings
---@field errors table List of errors

--- Multi-group suggestion result
---@class MultiGroupSuggestion
---@field mode string "best_groups"
---@field groups table Array of GroupSuggestion objects
---@field totalPlayers number Total players processed

-- MARK: Utility Functions

--- Gets the group preferences from the saved variables.
--- These preferences determine the desired group composition, such as prioritizing heroism and battle resurrection.
---@return table A table containing the group preferences.
function GroupSuggestions:GetGroupPreferences()
    local prefs = NextKey.db and NextKey.db.global and NextKey.db.global.groupPreferences
    if not prefs then
        -- Fallback to defaults
        return {
            prioritizeHeroism = true,
            prioritizeBattleRes = true
        }
    end
    return prefs
end

--- Checks if a player's class or spec provides the Heroism/Bloodlust buff.
---@param player PlayerProfile The player profile to check.
---@return boolean True if the player provides Heroism, false otherwise.
function GroupSuggestions:PlayerProvidesHeroism(player)
    if not player then return false end

    -- Check capabilities override
    if player.capabilities and player.capabilities.heroism ~= nil then
        return player.capabilities.heroism
    end

    -- Check class/spec combinations
    local HEROISM_CLASSES = {
        SHAMAN = true,
        MAGE = true,
        EVOKER = true
    }

    local HEROISM_SPECS = {
        [62] = true,  -- Arcane Mage
        [63] = true,  -- Fire Mage
        [64] = true,  -- Frost Mage
        [262] = true, -- Elemental Shaman
        [263] = true, -- Enhancement Shaman
        [264] = true, -- Restoration Shaman
        [1467] = true, -- Devastation Evoker
        [1468] = true, -- Preservation Evoker
        [1473] = true  -- Augmentation Evoker
    }

    if player.specID and HEROISM_SPECS[player.specID] then
        return true
    end

    if player.class and HEROISM_CLASSES[player.class] then
        return true
    end

    return false
end

--- Checks if a player's class or spec provides a battle resurrection.
---@param player PlayerProfile The player profile to check.
---@return boolean True if the player provides a battle resurrection, false otherwise.
function GroupSuggestions:PlayerProvidesBattleRes(player)
    if not player then return false end

    -- Check capabilities override
    if player.capabilities and player.capabilities.battleRes ~= nil then
        return player.capabilities.battleRes
    end

    -- Check class/spec combinations
    local BATTLE_RES_CLASSES = {
        DRUID = true,
        WARLOCK = true,
        DEATHKNIGHT = true
    }

    local BATTLE_RES_SPECS = {
        [102] = true, -- Balance Druid
        [103] = true, -- Feral Druid
        [104] = true, -- Guardian Druid
        [105] = true, -- Restoration Druid
        [250] = true, -- Blood DK
        [251] = true, -- Frost DK
        [252] = true, -- Unholy DK
        [265] = true, -- Affliction Warlock
        [266] = true, -- Demonology Warlock
        [267] = true  -- Destruction Warlock
    }

    if player.specID and BATTLE_RES_SPECS[player.specID] then
        return true
    end

    if player.class and BATTLE_RES_CLASSES[player.class] then
        return true
    end

    return false
end

--- Validates the role composition of a given roster.
--- A valid roster must have exactly 1 tank, 1 healer, and 3 DPS.
---@param roster table An array of PlayerProfile objects.
---@return boolean, string True if the composition is valid, otherwise false and an error message.
function GroupSuggestions:ValidateRoleComposition(roster)
    if not roster or #roster ~= 5 then
        return false, "Roster must have exactly 5 players"
    end

    local roleCount = {
        TANK = 0,
        HEALER = 0,
        DAMAGER = 0
    }

    for _, player in ipairs(roster) do
        if player.role and roleCount[player.role] then
            roleCount[player.role] = roleCount[player.role] + 1
        else
            return false, string.format("Invalid role '%s' for player %s", player.role or "nil", player.name or "Unknown")
        end
    end

    -- Standard composition: 1 tank, 1 healer, 3 DPS
    if roleCount.TANK ~= 1 then
        return false, string.format("Need exactly 1 tank, have %d", roleCount.TANK)
    end

    if roleCount.HEALER ~= 1 then
        return false, string.format("Need exactly 1 healer, have %d", roleCount.HEALER)
    end

    if roleCount.DAMAGER ~= 3 then
        return false, string.format("Need exactly 3 DPS, have %d", roleCount.DAMAGER)
    end

    return true
end

--- Checks if a roster meets the configured group preferences (e.g., has Heroism and Battle Res).
---@param roster table An array of PlayerProfile objects.
---@return boolean, table True if the roster meets the preferences, otherwise false and a table of warnings.
function GroupSuggestions:MeetsGroupPreferences(roster)
    local prefs = self:GetGroupPreferences()
    local warnings = {}

    -- Check Heroism requirement
    if prefs.prioritizeHeroism then
        local hasHeroism = false
        local heroismProviders = {}

        for _, player in ipairs(roster) do
            if self:PlayerProvidesHeroism(player) then
                hasHeroism = true
                table.insert(heroismProviders, player.name)
            end
        end

        if not hasHeroism then
            table.insert(warnings, "No Heroism provider in group (Mage/Shaman/Evoker)")
        end
    end

    -- Check Battle Res requirement
    if prefs.prioritizeBattleRes then
        local hasBattleRes = false
        local battleResProviders = {}

        for _, player in ipairs(roster) do
            if self:PlayerProvidesBattleRes(player) then
                hasBattleRes = true
                table.insert(battleResProviders, player.name)
            end
        end

        if not hasBattleRes then
            table.insert(warnings, "No Battle Res provider in group (Druid/Warlock/DK)")
        end
    end

    return #warnings == 0, warnings
end

--- Calculates the potential IO gain for a player from completing a specific keystone.
--- This function delegates to the IOCalculator module if available, otherwise uses a fallback estimation.
---@param player PlayerProfile The player's profile.
---@param keystone table The keystone data.
---@return number The estimated IO gain.
function GroupSuggestions:CalculatePlayerIOGain(player, keystone)
    if not player or not keystone then return 0 end

    -- Use existing IOCalculator if available
    if NextKey222.IOCalculator and NextKey222.IOCalculator.CalculatePlayerIOGain then
        return NextKey222.IOCalculator:CalculatePlayerIOGain(player, keystone)
    end

    -- Fallback calculation
    local baseGain = 0

    -- Simple estimation based on key level and player IO
    if keystone.level and player.io then
        -- Higher level keys give more IO, but players with higher IO gain less
        local levelMultiplier = keystone.level * 2
        local ioMultiplier = math.max(0, (4000 - player.io) / 4000) -- Less gain for higher IO players
        baseGain = levelMultiplier * ioMultiplier * 10
    end

    return math.floor(baseGain)
end

--- Gathers a list of all available players, including the current player, party members, and fake players for debugging.
---@return table An array of enhanced PlayerProfile objects for all available players.
function GroupSuggestions:GetAvailablePlayers()
    local players = {}

    -- Get party members
    local partyMembers = NextKey:GetPartyMemberNames() or {}

    -- Also include current player if not in party
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local hasCurrentPlayer = false
    for _, name in ipairs(partyMembers) do
        if name == currentPlayer then
            hasCurrentPlayer = true
            break
        end
    end
    if not hasCurrentPlayer then
        table.insert(partyMembers, currentPlayer)
    end

    -- Add fake players if debug mode is enabled
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService.IsEnabled and NextKey222.FakePlayerService:IsEnabled() then
        local fakeNames = NextKey222.FakePlayerService:GetAllPlayerNames()
        for _, fakeName in ipairs(fakeNames) do
            local alreadyInList = false
            for _, existingName in ipairs(partyMembers) do
                if existingName == fakeName then
                    alreadyInList = true
                    break
                end
            end
            if not alreadyInList then
                table.insert(partyMembers, fakeName)
            end
        end
    end

for _, playerName in ipairs(partyMembers) do
local profile = NextKey222.ProfilesService:GetProfile(playerName)
if not profile then
    -- Try fake player service as fallback
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService.GetProfile then
        profile = NextKey222.FakePlayerService:GetProfile(playerName)
    end
end

if profile then
    -- Enhance profile with additional data
    local enhancedProfile = {
        name = playerName,
        class = profile.class,
        specID = profile.specID,
        role = profile.role,
        io = profile.io or 0,
        keystones = profile.keystones or {},
        capabilities = profile.capabilities or {},
        dungeonGains = profile.dungeonGains or {}
    }

    -- Add utility capabilities if not present
    if enhancedProfile.capabilities.heroism == nil then
        enhancedProfile.capabilities.heroism = self:PlayerProvidesHeroism(enhancedProfile)
    end
    if enhancedProfile.capabilities.battleRes == nil then
        enhancedProfile.capabilities.battleRes = self:PlayerProvidesBattleRes(enhancedProfile)
    end

    -- Add keystones from fake player service if available
    if not enhancedProfile.keystones or #enhancedProfile.keystones == 0 then
        if NextKey222.FakePlayerService and NextKey222.FakePlayerService.GetKeystone then
            local fakeKey = NextKey222.FakePlayerService:GetKeystone(playerName)
            if fakeKey then
                enhancedProfile.keystones = {fakeKey}
            end
        end
    end

    table.insert(players, enhancedProfile)
end
end

    Debug:Dev("groupSuggestions", string.format("Found %d available players", #players))
    return players
end

--- Gathers all available keystones from the party and fake players.
---@return table An array of keystone data tables.
function GroupSuggestions:GetAllKeystones()
    local keystones = NextKey:GetAvailableKeys() or {}
    
    -- Add fake player keystones if debug mode is enabled
    if NextKey222.FakePlayerService and NextKey222.FakePlayerService.IsEnabled and NextKey222.FakePlayerService:IsEnabled() then
        local fakeNames = NextKey222.FakePlayerService:GetAllPlayerNames()
        for _, fakeName in ipairs(fakeNames) do
            local fakeKey = NextKey222.FakePlayerService:GetKeystone(fakeName)
            if fakeKey then
                table.insert(keystones, {
                    dungeonID = fakeKey.dungeonID,
                    level = fakeKey.level,
                    ownerName = fakeName,
                    dungeonName = NextKey.PortalData and NextKey.PortalData.dungeons and
                                 NextKey.PortalData.dungeons[fakeKey.dungeonID] and
                                 NextKey.PortalData.dungeons[fakeKey.dungeonID].name or "Unknown Dungeon"
                })
            end
        end
    end
    
    Debug:Dev("groupSuggestions", string.format("Found %d available keystones", #keystones))
    return keystones
end

-- MARK: Best Key Mode Implementation

--- Generates all possible roster combinations of a specified size from a list of players.
--- This is a simplified implementation and does not generate all permutations for performance reasons.
---@param players table An array of PlayerProfile objects.
---@param size number The desired size of the group (typically 5).
---@param requiredPlayers table|nil An array of players who must be included in the roster.
---@return table An array of possible roster combinations.
function GroupSuggestions:GenerateRosterCombinations(players, size, requiredPlayers)
    local combinations = {}
    
    -- Limit the number of combinations to prevent performance issues
    local maxCombinations = 50
    local combinationCount = 0

    -- For now, use a simple approach - generate combinations including required players
    -- TODO: Implement more efficient combination generation

    if requiredPlayers and #requiredPlayers > 0 then
        -- Must include required players
        local available = {}
        for _, player in ipairs(players) do
            local isRequired = false
            for _, req in ipairs(requiredPlayers) do
                if req.name == player.name then
                    isRequired = true
                    break
                end
            end
            if not isRequired then
                table.insert(available, player)
            end
        end

        -- Need to pick (size - #requiredPlayers) from available
        local need = size - #requiredPlayers
        if need <= 0 then
            -- Too many required players
            return {}
        elseif need > #available then
            -- Not enough available players
            return {}
        end

        -- Simple combination: take first N available (TODO: generate all combinations)
        local roster = {}
        for _, req in ipairs(requiredPlayers) do
            table.insert(roster, req)
        end
        for i = 1, math.min(need, #available) do
            table.insert(roster, available[i])
        end

        if #roster == size then
            table.insert(combinations, roster)
            combinationCount = combinationCount + 1
        end
    else
        -- No required players - generate limited combinations
        if #players >= size then
            -- Generate a few different starting combinations
            local startIndices = {1, 2, 3, 4, 5}
            for _, startIndex in ipairs(startIndices) do
                if startIndex <= #players - size + 1 and combinationCount < maxCombinations then
                    local roster = {}
                    for i = 0, size - 1 do
                        table.insert(roster, players[startIndex + i])
                    end
                    table.insert(combinations, roster)
                    combinationCount = combinationCount + 1
                end
            end
        end
    end

    Debug:Dev("groupSuggestions", string.format("Generated %d roster combinations", #combinations))
    return combinations
end

--- Analyzes all available players and keystones to suggest the single best key to run and the optimal group for it.
--- The "best" key is determined by the highest potential total IO gain for the group.
---@return GroupSuggestion|nil A GroupSuggestion object, or nil if no valid suggestion could be made.
function GroupSuggestions:SuggestBestKey()
    Debug:Dev("groupSuggestions", "Starting Best Key mode suggestion")

    local availablePlayers = self:GetAvailablePlayers()
    local availableKeys = self:GetAllKeystones()

    if #availablePlayers < 5 then
        Debug:Dev("groupSuggestions", "Not enough players for group suggestion")
        return nil
    end

    if #availableKeys == 0 then
        Debug:Dev("groupSuggestions", "No keystones available")
        return nil
    end

    -- Limit processing to prevent timeouts
    local maxKeysToEvaluate = math.min(10, #availableKeys)
    local maxCombinationsPerKey = 20
    
    local bestScore = 0
    local bestKey = nil
    local bestRoster = nil
    local bestWarnings = {}

    -- Try each keystone as the target key (limited number)
    for i = 1, maxKeysToEvaluate do
        local keystone = availableKeys[i]
        Debug:Dev("groupSuggestions", string.format("Evaluating key %d/%d: %s +%d",
            i, maxKeysToEvaluate, keystone.dungeonName or "Unknown", keystone.level or 0))

        -- Find the key owner
        local keyOwner = nil
        for _, player in ipairs(availablePlayers) do
            if player.name == keystone.ownerName then
                keyOwner = player
                break
            end
        end

        if not keyOwner then
            Debug:Dev("groupSuggestions", "Key owner not found in available players")
            -- Skip this keystone
        else
            -- Generate limited roster combinations that include the key owner
            local combinations = self:GenerateRosterCombinations(availablePlayers, 5, {keyOwner})
            
            -- Limit combinations per key to prevent timeouts
            local combinationsToProcess = math.min(#combinations, maxCombinationsPerKey)

            for j = 1, combinationsToProcess do
                local roster = combinations[j]
                
                -- Validate role composition
                local isValid, roleError = self:ValidateRoleComposition(roster)
                if not isValid then
                    Debug:Dev("groupSuggestions", string.format("Invalid roster: %s", roleError))
                    -- Skip this roster
                else
                    -- Check group preferences
                    local meetsPrefs, warnings = self:MeetsGroupPreferences(roster)
                    if not meetsPrefs then
                        Debug:Dev("groupSuggestions", string.format("Roster doesn't meet preferences: %s",
                            table.concat(warnings, ", ")))
                        -- Allow but track warnings
                    end

                    -- Calculate total IO gain
                    local totalGain = 0
                    local perPlayerGain = {}

                    for _, player in ipairs(roster) do
                        local gain = self:CalculatePlayerIOGain(player, keystone)
                        totalGain = totalGain + gain
                        perPlayerGain[player.name] = gain
                    end

                    Debug:Dev("groupSuggestions", string.format("Roster total gain: %d", totalGain))

                    -- Track best option
                    if totalGain > bestScore then
                        bestScore = totalGain
                        bestKey = keystone
                        bestRoster = roster
                        bestWarnings = warnings
                    end
                end
                
                -- Yield periodically to prevent timeouts
                if j % 5 == 0 then
                    -- Small yield to allow other processing
                end
            end
        end
        
        -- Yield between keys to prevent timeouts
        if i % 3 == 0 then
            -- Small yield to allow other processing
        end
    end

    if not bestKey or not bestRoster then
        Debug:Dev("groupSuggestions", "No valid group found")
        return nil
    end

    -- Build result
    local result = {
        mode = "best_key",
        selectedKey = {
            dungeonID = bestKey.dungeonID,
            level = bestKey.level,
            owner = bestKey.ownerName,
            dungeonName = bestKey.dungeonName
        },
        roster = bestRoster,
        ioGain = {
            total = bestScore,
            perPlayer = {}
        },
        utilities = {
            hasHeroism = false,
            heroismProviders = {},
            hasBattleRes = false,
            battleResProviders = {}
        },
        isValid = true,
        warnings = bestWarnings,
        errors = {}
    }

    -- Calculate per-player gains and utilities
    for _, player in ipairs(bestRoster) do
        result.ioGain.perPlayer[player.name] = self:CalculatePlayerIOGain(player, bestKey)

        if self:PlayerProvidesHeroism(player) then
            result.utilities.hasHeroism = true
            table.insert(result.utilities.heroismProviders, player.name)
        end

        if self:PlayerProvidesBattleRes(player) then
            result.utilities.hasBattleRes = true
            table.insert(result.utilities.battleResProviders, player.name)
        end
    end

    Debug:Dev("groupSuggestions", string.format("Best Key suggestion complete: %s +%d, %d IO gain",
        result.selectedKey.dungeonName, result.selectedKey.level, result.ioGain.total))

    return result
end

-- MARK: Best Groups Mode Implementation

--- Calculates a synergy matrix between all players.
--- Synergy is defined as the mutual IO gain between two players from running each other's keystones.
---@param players table An array of PlayerProfile objects.
---@return table A 2D matrix of synergy scores.
function GroupSuggestions:CalculateSynergyMatrix(players)
    local matrix = {}

    for i, playerA in ipairs(players) do
        matrix[i] = {}
        for j, playerB in ipairs(players) do
            if i == j then
                matrix[i][j] = 0 -- No synergy with self
            else
                -- Calculate mutual benefit
                local synergy = 0

                -- If player B has keys, how much does A gain?
                if playerB.keystones then
                    for _, key in ipairs(playerB.keystones) do
                        synergy = synergy + self:CalculatePlayerIOGain(playerA, key)
                    end
                end

                -- If player A has keys, how much does B gain?
                if playerA.keystones then
                    for _, key in ipairs(playerA.keystones) do
                        synergy = synergy + self:CalculatePlayerIOGain(playerB, key)
                    end
                end

                matrix[i][j] = synergy
            end
        end
    end

    Debug:Dev("groupSuggestions", "Calculated synergy matrix for " .. #players .. " players")
    return matrix
end

--- Forms an optimal group from a list of players using a greedy approach based on the synergy matrix.
---@param players table An array of PlayerProfile objects.
---@param synergyMatrix table A 2D synergy matrix for the players.
---@return table|nil A table representing the formed group, or nil if not enough players.
function GroupSuggestions:FormOptimalGroup(players, synergyMatrix)
    if #players < 3 then
        return nil
    end

    local groupSize = math.min(5, #players)
    local roster = {}
    local usedIndices = {}

    -- Simple greedy approach: pick players with highest total synergy
    -- TODO: Implement more sophisticated clustering

    -- Start with player who has highest total synergy with others
    local bestStartIndex = 1
    local bestTotalSynergy = 0

    for i, synergies in ipairs(synergyMatrix) do
        if not usedIndices[i] then
            local totalSynergy = 0
            for j, synergy in ipairs(synergies) do
                if i ~= j then
                    totalSynergy = totalSynergy + synergy
                end
            end

            if totalSynergy > bestTotalSynergy then
                bestTotalSynergy = totalSynergy
                bestStartIndex = i
            end
        end
    end

    -- Build roster starting from best player
    table.insert(roster, players[bestStartIndex])
    usedIndices[bestStartIndex] = true

    -- Add remaining players with highest synergy to existing roster
    while #roster < groupSize and #roster < #players do
        local bestIndex = nil
        local bestSynergy = 0

        for i, player in ipairs(players) do
            if not usedIndices[i] then
                -- Calculate synergy with current roster
                local totalSynergy = 0
                for _, rosterPlayer in ipairs(roster) do
                    local rosterIndex = nil
                    for j, p in ipairs(players) do
                        if p.name == rosterPlayer.name then
                            rosterIndex = j
                            break
                        end
                    end

                    if rosterIndex then
                        totalSynergy = totalSynergy + synergyMatrix[i][rosterIndex]
                    end
                end

                if totalSynergy > bestSynergy then
                    bestSynergy = totalSynergy
                    bestIndex = i
                end
            end
        end

        if bestIndex then
            table.insert(roster, players[bestIndex])
            usedIndices[bestIndex] = true
        else
            break
        end
    end

    -- Generate key rotation for this group
    local keyRotation = self:GenerateKeyRotation(roster)

    return {
        roster = roster,
        keyRotation = keyRotation,
        totalPotential = self:CalculateTotalPotential(keyRotation)
    }
end

--- Generates a prioritized rotation of all keystones owned by players in a roster.
--- The rotation is sorted by the highest potential IO gain for the group.
---@param roster table An array of PlayerProfile objects.
---@return table An array of rotation steps, each containing key data and IO gain information.
function GroupSuggestions:GenerateKeyRotation(roster)
    local rotation = {}
    local processedKeys = {}

    -- Collect all unique keystones from the roster
    local allKeys = {}
    for _, player in ipairs(roster) do
        if player.keystones then
            for _, key in ipairs(player.keystones) do
                local keyId = string.format("%d-%d-%s", key.dungeonID or 0, key.level or 0, key.ownerName or "Unknown")
                if not processedKeys[keyId] then
                    table.insert(allKeys, key)
                    processedKeys[keyId] = true
                end
            end
        end
    end

    -- Sort keys by potential group IO gain (descending)
    table.sort(allKeys, function(a, b)
        local gainA = 0
        local gainB = 0

        for _, player in ipairs(roster) do
            gainA = gainA + self:CalculatePlayerIOGain(player, a)
            gainB = gainB + self:CalculatePlayerIOGain(player, b)
        end

        return gainA > gainB
    end)

    -- Create rotation steps
    for _, key in ipairs(allKeys) do
        local step = {
            key = {
                dungeonID = key.dungeonID,
                level = key.level,
                owner = key.ownerName,
                dungeonName = key.dungeonName
            },
            totalGain = 0,
            perPlayer = {}
        }

        for _, player in ipairs(roster) do
            local gain = self:CalculatePlayerIOGain(player, key)
            step.totalGain = step.totalGain + gain
            step.perPlayer[player.name] = gain
        end

        table.insert(rotation, step)
    end

    return rotation
end

--- Calculates the total potential IO gain from a key rotation schedule.
---@param keyRotation table An array of rotation steps from GenerateKeyRotation.
---@return number The total potential IO gain.
function GroupSuggestions:CalculateTotalPotential(keyRotation)
    local total = 0
    for _, step in ipairs(keyRotation) do
        total = total + step.totalGain
    end
    return total
end

--- Suggests multiple groups from a larger pool of players, including key rotations for each group.
--- This mode is ideal for guild groups or communities.
---@return MultiGroupSuggestion|nil A MultiGroupSuggestion object, or nil if no valid groups could be formed.
function GroupSuggestions:SuggestBestGroups()
    Debug:Dev("groupSuggestions", "Starting Best Groups mode suggestion")

    local availablePlayers = self:GetAvailablePlayers()

    if #availablePlayers < 5 then
        Debug:Dev("groupSuggestions", "Not enough players for multi-group suggestion")
        return nil
    end

    -- Limit players to prevent timeouts
    local maxPlayers = math.min(15, #availablePlayers)
    local limitedPlayers = {}
    for i = 1, maxPlayers do
        table.insert(limitedPlayers, availablePlayers[i])
    end

    -- Calculate synergy matrix with limited players
    local synergyMatrix = self:CalculateSynergyMatrix(limitedPlayers)

    -- Form groups
    local groups = {}
    local remainingPlayers = {}
    for _, player in ipairs(limitedPlayers) do
        table.insert(remainingPlayers, player)
    end

    local maxGroups = 3  -- Limit number of groups to form
    local groupCount = 0

    while #remainingPlayers >= 3 and groupCount < maxGroups do
        local group = self:FormOptimalGroup(remainingPlayers, synergyMatrix)
        if not group then break end

        -- Validate and add warnings
        self:ValidateGroup(group)
        self:GenerateRecruitSuggestions(group)

        table.insert(groups, group)
        groupCount = groupCount + 1

        -- Remove assigned players
        for _, player in ipairs(group.roster) do
            for i, remaining in ipairs(remainingPlayers) do
                if remaining.name == player.name then
                    table.remove(remainingPlayers, i)
                    break
                end
            end
        end
        
        -- Small yield to prevent timeouts
        if groupCount % 2 == 0 then
            -- Allow other processing
        end
    end

    if #groups == 0 then
        Debug:Dev("groupSuggestions", "No valid groups formed")
        return nil
    end

    local result = {
        mode = "best_groups",
        groups = groups,
        totalPlayers = #limitedPlayers
    }

    Debug:Dev("groupSuggestions", string.format("Best Groups suggestion complete: %d groups from %d players",
        #groups, #limitedPlayers))

    return result
end

--- Validates a group's composition and preferences, adding warnings and errors to the group object.
---@param group table The group data to validate.
function GroupSuggestions:ValidateGroup(group)
    group.isValid = true
    group.warnings = {}
    group.errors = {}

    -- Validate role composition
    local isValid, errorMsg = self:ValidateRoleComposition(group.roster)
    if not isValid then
        table.insert(group.errors, errorMsg)
        group.isValid = false
    end

    -- Check preferences
    local meetsPrefs, warnings = self:MeetsGroupPreferences(group.roster)
    for _, warning in ipairs(warnings) do
        table.insert(group.warnings, warning)
    end

    -- Check if group is complete (5 players)
    if #group.roster < 5 then
        table.insert(group.warnings, string.format("Incomplete group: %d/%d players", #group.roster, 5))
        group.isValid = false
    end
end

--- Generates recruitment suggestions for incomplete groups, recommending roles and classes to fill the gaps.
---@param group table The group data, which may be incomplete.
function GroupSuggestions:GenerateRecruitSuggestions(group)
    group.recruitSuggestions = {}

    if #group.roster >= 5 then return end

    local currentRoles = {}
    for _, player in ipairs(group.roster) do
        currentRoles[player.role] = (currentRoles[player.role] or 0) + 1
    end

    -- Determine what roles are needed
    local neededRoles = {}
    if (currentRoles.TANK or 0) < 1 then table.insert(neededRoles, "TANK") end
    if (currentRoles.HEALER or 0) < 1 then table.insert(neededRoles, "HEALER") end
    if (currentRoles.DAMAGER or 0) < 3 then
        for i = 1, 3 - (currentRoles.DAMAGER or 0) do
            table.insert(neededRoles, "DAMAGER")
        end
    end

    -- Check if utilities are missing
    local prefs = self:GetGroupPreferences()
    local hasHeroism = false
    local hasBattleRes = false

    for _, player in ipairs(group.roster) do
        if self:PlayerProvidesHeroism(player) then hasHeroism = true end
        if self:PlayerProvidesBattleRes(player) then hasBattleRes = true end
    end

    -- Generate suggestions
    for _, neededRole in ipairs(neededRoles) do
        local suggestion = {
            role = neededRole,
            preferredClass = nil,
            reason = nil
        }

        -- Suggest utility classes if needed
        if neededRole == "DAMAGER" then
            if prefs.prioritizeHeroism and not hasHeroism then
                suggestion.preferredClass = "MAGE"
                suggestion.reason = "Provides Heroism"
                hasHeroism = true -- Only suggest once
            elseif prefs.prioritizeBattleRes and not hasBattleRes then
                suggestion.preferredClass = "WARLOCK"
                suggestion.reason = "Provides Battle Res"
                hasBattleRes = true -- Only suggest once
            end
        elseif neededRole == "HEALER" then
            if prefs.prioritizeBattleRes and not hasBattleRes then
                suggestion.preferredClass = "DRUID"
                suggestion.reason = "Provides Battle Res"
                hasBattleRes = true
            end
        elseif neededRole == "TANK" then
            if prefs.prioritizeHeroism and not hasHeroism then
                suggestion.preferredClass = "SHAMAN"
                suggestion.reason = "Provides Heroism"
                hasHeroism = true
            end
        end

        table.insert(group.recruitSuggestions, suggestion)
    end
end

-- MARK: Main Interface Functions

--- The main entry point for generating group suggestions.
--- It auto-detects the best mode ("best_key" or "best_groups") based on the number of available players.
---@param mode string|nil The desired mode ("best_key" or "best_groups"). If nil, the mode is auto-detected.
---@return GroupSuggestion|MultiGroupSuggestion|nil The generated suggestion object, or nil if no suggestion could be made.
function GroupSuggestions:GenerateSuggestions(mode)
    local availablePlayers = self:GetAvailablePlayers()
    local availableKeys = self:GetAllKeystones()

    Debug:Dev("groupSuggestions", string.format("Generating suggestions: %d players, %d keys, mode: %s",
        #availablePlayers, #availableKeys, mode or "auto"))

    -- Auto-detect mode based on player count
    if not mode or mode == "auto" then
        if #availablePlayers <= 7 then
            mode = "best_key"
        else
            mode = "best_groups"
        end
    end

    if mode == "best_key" then
        return self:SuggestBestKey()
    elseif mode == "best_groups" then
        return self:SuggestBestGroups()
    else
        Debug:Error("groupSuggestions", "Unknown suggestion mode: " .. tostring(mode))
        return nil
    end
end

--- Formats a group suggestion into a human-readable string for chat output.
---@param suggestion GroupSuggestion|MultiGroupSuggestion The suggestion object to format.
---@return string The formatted chat message.
function GroupSuggestions:FormatSuggestionForChat(suggestion)
    if not suggestion then return "No suggestion available" end

    local lines = {}

    if suggestion.mode == "best_key" then
        table.insert(lines, "[Key] Best Key Suggestion")
        table.insert(lines, "━━━━━━━━━━━━━━━━━━━")

        local key = suggestion.selectedKey
        table.insert(lines, string.format("Run: %s (+%d)",
            key.dungeonName or "Unknown Dungeon", key.level or 0))

        table.insert(lines, string.format("Group IO Gain: +%d points", suggestion.ioGain.total))

        table.insert(lines, "")
        table.insert(lines, "Suggested Group:")

        for _, player in ipairs(suggestion.roster) do
            local gain = suggestion.ioGain.perPlayer[player.name] or 0
            local utility = ""
            if self:PlayerProvidesHeroism(player) then utility = utility .. " ✓ Heroism" end
            if self:PlayerProvidesBattleRes(player) then utility = utility .. " ✓ Battle Res" end

            local roleIcon = ""
            if player.role == "TANK" then roleIcon = "[Tank]"
            elseif player.role == "HEALER" then roleIcon = "[Healer]"
            elseif player.role == "DAMAGER" then roleIcon = "[DPS]" end

            table.insert(lines, string.format("%s %s +%d IO%s",
                roleIcon, player.name:gsub("-.*", ""), gain, utility))
        end

        -- Add utility summary
        local utilLines = {}
        if suggestion.utilities.hasHeroism then
            table.insert(utilLines, "[OK] Has Heroism")
        else
            table.insert(utilLines, "[X] Missing Heroism")
        end
        if suggestion.utilities.hasBattleRes then
            table.insert(utilLines, "[OK] Has Battle Res")
        else
            table.insert(utilLines, "[X] Missing Battle Res")
        end
        table.insert(lines, "")
        table.insert(lines, table.concat(utilLines, " | "))

        -- Add warnings
        if suggestion.warnings and #suggestion.warnings > 0 then
            table.insert(lines, "")
            for _, warning in ipairs(suggestion.warnings) do
                table.insert(lines, "[!] " .. warning)
            end
        end

    elseif suggestion.mode == "best_groups" then
        table.insert(lines, "👥 Best Groups Suggestion")
        table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━")

        table.insert(lines, string.format("%d players → %d groups with key rotation",
            suggestion.totalPlayers, #suggestion.groups))

        for i, group in ipairs(suggestion.groups) do
            table.insert(lines, "")
            table.insert(lines, string.format("━━ Group %d ━━ (Potential: +%d IO)", i, group.totalPotential))

            -- Roster
            for _, player in ipairs(group.roster) do
                local roleIcon = ""
                if player.role == "TANK" then roleIcon = "[Tank]"
                elseif player.role == "HEALER" then roleIcon = "[Healer]"
                elseif player.role == "DAMAGER" then roleIcon = "[DPS]" end
                
                local utilityText = ""
                local utilityIcons = ""
                if self:PlayerProvidesHeroism(player) then
                    utilityText = "Heroism"
                    utilityIcons = utilityIcons .. " ✓"
                end
                if self:PlayerProvidesBattleRes(player) then
                    if utilityText ~= "" then utilityText = utilityText .. ", " end
                    utilityText = utilityText .. "Battle Res"
                    utilityIcons = utilityIcons .. " ✓"
                end
                
                local className = player.class or "Unknown"
                local playerName = player.name:gsub("-.*", "") -- Remove realm suffix for display
                
                table.insert(lines, string.format("%s %s - %s%s%s",
                    roleIcon,
                    playerName,
                    className,
                    utilityText ~= "" and " (" .. utilityText .. ")" or "",
                    utilityIcons))
            end

            -- Key rotation summary
            if group.keyRotation and #group.keyRotation > 0 then
                table.insert(lines, "")
                table.insert(lines, "Key Rotation:")
                for j, rotation in ipairs(group.keyRotation) do
                    if j <= 3 then -- Limit to first 3 rotations in chat
                        local key = rotation.key
                        table.insert(lines, string.format("%d. %s +%d → +%d group IO",
                            j, key.dungeonName or "Unknown", key.level or 0, rotation.totalGain))
                    end
                end
                if #group.keyRotation > 3 then
                    table.insert(lines, string.format("... and %d more keys", #group.keyRotation - 3))
                end
            end

            -- Status
            local statusLines = {}
            if group.isValid then
                table.insert(statusLines, "[OK] Complete group")
            else
                table.insert(statusLines, "[X] Incomplete group")
            end

            local utilCount = 0
            if group.utilities and group.utilities.hasHeroism then utilCount = utilCount + 1 end
            if group.utilities and group.utilities.hasBattleRes then utilCount = utilCount + 1 end

            if utilCount == 2 then
                table.insert(statusLines, "[OK] Full utilities")
            elseif utilCount == 1 then
                table.insert(statusLines, "[!] Partial utilities")
            else
                table.insert(statusLines, "[X] Missing utilities")
            end

            table.insert(lines, table.concat(statusLines, " | "))

            -- Warnings
            if group.warnings and #group.warnings > 0 then
                for _, warning in ipairs(group.warnings) do
                    table.insert(lines, "[!] " .. warning)
                end
            end

            -- Recruit suggestions
            if group.recruitSuggestions and #group.recruitSuggestions > 0 then
                table.insert(lines, "")
                table.insert(lines, "[Info] Recruit suggestions:")
                for _, recruit in ipairs(group.recruitSuggestions) do
                    local suggestion = recruit.role
                    if recruit.preferredClass then
                        suggestion = suggestion .. " (" .. recruit.preferredClass
                        if recruit.reason then
                            suggestion = suggestion .. " - " .. recruit.reason
                        end
                        suggestion = suggestion .. ")"
                    end
                    table.insert(lines, "   • " .. suggestion)
                end
            end
        end
    end

    return table.concat(lines, "\n")
end

-- MARK: Module Initialization

--- Initializes the GroupSuggestions module.
function GroupSuggestions:Initialize()
    Debug:Dev("groupSuggestions", "GroupSuggestions module initialized")
    return true
end

return GroupSuggestions