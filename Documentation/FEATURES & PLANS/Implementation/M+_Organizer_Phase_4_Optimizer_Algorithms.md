# M+ Group Organizer - Phase 4: Optimizer Algorithms

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0, 0.5, 1, 2, 3  
**Estimated Complexity:** VERY HIGH  
**Implementation Priority:** MEDIUM - Automation feature, requires working manual mode first

---

## Overview

This phase implements the three optimization algorithms for automated group formation. This is the most complex technical component of the Organizer, requiring careful implementation of combinatorial algorithms, performance management, and a pausable wizard UI to prevent "script ran too long" errors.

**Key Deliverables:**
1. Core mathematical functions (V(d,l), Gain(p,k))
2. Mode 1: Max Power (Greedy Maximization)
3. Mode 2: Balanced (Fair Distribution)
4. Mode 3: Vault Completion (Preference Maximization)
5. Optimizer Wizard UI with progress tracking
6. Partial group strategy system
7. PUG preference configuration

---

## 1. Core Mathematical Functions

### 1.1 Base Value Function V(d,l)

**File:** `core/organizer/scoring.lua` (NEW)

```lua
-- MARK: Module Definition
local OrganizerScoring = {}
NextKey222.OrganizerScoring = OrganizerScoring
NextKey222.RegisterModule("OrganizerScoring", OrganizerScoring)

function OrganizerScoring:Initialize()
    return NextKey222.SafeRun(function()
        -- Build dungeon matrix for levels 2-20
        self:BuildDungeonMatrix()
        return true
    end, "OrganizerScoring:Initialize")
end

function OrganizerScoring:GetBaseValue(dungeonID, level)
    -- V(d, l) function from Algorithm Spec
    return NextKey222.SafeRun(function()
        if level >= 2 and level <= 20 then
            -- Use lookup table
            return self:GetBaseValueFromTable(dungeonID, level)
        elseif level >= 21 then
            -- Use formula: base_score = 145 + (level * 15) + 40
            return 145 + (level * 15) + 40
        else
            error("Invalid keystone level: " .. tostring(level))
        end
    end, "OrganizerScoring:GetBaseValue")
end

function OrganizerScoring:BuildDungeonMatrix()
    -- This should match the existing dungeonMatrix from IOCalculator
    -- (Simplified here - actual implementation uses existing matrix)
    self.dungeonMatrix = {}
    
    for level = 2, 20 do
        self.dungeonMatrix[level] = {
            baseScore = 145 + (level * 15),
            minScore = 145 + (level * 15) - 15,
            maxScore = 145 + (level * 15) + 15
        }
    end
end

function OrganizerScoring:GetBaseValueFromTable(dungeonID, level)
    -- For levels 2-20, use matrix
    if self.dungeonMatrix[level] then
        return self.dungeonMatrix[level].baseScore
    end
    
    -- Fallback to formula
    return 145 + (level * 15) + 40
end

function OrganizerScoring:CalculatePlayerGain(player, keystone)
    -- Gain(p, k) function from Algorithm Spec
    return NextKey222.SafeRun(function()
        local dungeonID = keystone.dungeonID
        local keystoneLevel = keystone.level
        
        -- Get player's current score for this dungeon
        local currentScore = player.scores[dungeonID] or 0
        
        -- Get base value for this keystone
        local baseValue = self:GetBaseValue(dungeonID, keystoneLevel)
        
        -- Calculate gain (never negative)
        local gain = math.max(0, baseValue - currentScore)
        
        return gain
        
    end, "OrganizerScoring:CalculatePlayerGain")
end
```

---

## 2. Mode 1: Max Power (Greedy Maximization)

### 2.1 Main Algorithm

**File:** `core/organizer/optimizer_mode1.lua` (NEW)

```lua
-- MARK: Module Definition
local OptimizerMode1 = {}
NextKey222.OptimizerMode1 = OptimizerMode1
NextKey222.RegisterModule("OptimizerMode1", OptimizerMode1)

function OptimizerMode1:FindAllGroups(playerPool, constraints)
    return NextKey222.SafeRun(function()
        local finalGroups = {}
        local leftoverPlayers = self:ClonePlayerPool(playerPool)
        
        while true do
            -- Find the single best group from remaining players
            local bestGroup = self:FindBestPossibleGroup(leftoverPlayers, constraints)
            
            if not bestGroup then
                -- No more valid groups can be formed
                break
            else
                -- Add the best group to our list
                table.insert(finalGroups, bestGroup)
                
                -- Remove those 5 players from the pool for the next iteration
                leftoverPlayers = self:RemovePlayers(leftoverPlayers, bestGroup.players)
                
                Debug:Dev("optimizer", "Mode 1: Formed group", #finalGroups, "with score", bestGroup.totalScore)
            end
        end
        
        return finalGroups, leftoverPlayers
        
    end, "OptimizerMode1:FindAllGroups")
end

function OptimizerMode1:FindBestPossibleGroup(playerPool, constraints)
    -- Core combinatorial search
    return NextKey222.SafeRun(function()
        local bestOverallGroup = nil
        local maxFinalScore = -math.huge -- Use -infinity to handle large penalties
        
        -- Get all available keystones from the pool
        local allKeystones = self:GetAllKeystones(playerPool)
        
        if #allKeystones == 0 then
            return nil -- No keystones available
        end
        
        -- Iterate through every available keystone as the potential run
        for _, keystone in ipairs(allKeystones) do
            -- Generate all valid 5-player combinations for this key
            local validGroups = self:GenerateValidCombinations(playerPool, constraints)
            
            -- For each valid group, calculate its Final Score
            for _, group in ipairs(validGroups) do
                local currentGain = 0
                local preferenceScore = 0
                
                for _, player in ipairs(group) do
                    currentGain = currentGain + NextKey222.OrganizerScoring:CalculatePlayerGain(player, keystone)
                    
                    local pref = player.preferences[keystone.dungeonID] or 0
                    if pref == 1 then
                        preferenceScore = preferenceScore + constraints.LikeBonus
                    elseif pref == -1 then
                        preferenceScore = preferenceScore - constraints.DislikePenalty
                    end
                end
                
                -- Calculate the weighted Final Score
                local finalScore = currentGain + preferenceScore
                
                -- Check if this is the best group found so far
                if finalScore > maxFinalScore then
                    maxFinalScore = finalScore
                    bestOverallGroup = {
                        players = group,
                        chosenKeystone = keystone,
                        totalGain = currentGain,
                        totalScore = finalScore
                    }
                end
            end
        end
        
        return bestOverallGroup
        
    end, "OptimizerMode1:FindBestPossibleGroup")
end

function OptimizerMode1:GenerateValidCombinations(playerPool, constraints)
    -- Recursive backtracking to generate all valid 1T/1H/3D combinations
    return NextKey222.SafeRun(function()
        -- Separate players by role
        local tankList = {}
        local healerList = {}
        local dpsList = {}
        
        for _, player in ipairs(playerPool) do
            for _, role in ipairs(player.roles) do
                if role == "Tank" then
                    table.insert(tankList, player)
                end
                if role == "Healer" then
                    table.insert(healerList, player)
                end
                if role == "DPS" then
                    table.insert(dpsList, player)
                end
            end
        end
        
        local allCombinations = {}
        
        -- Generate combinations using recursive helper
        self:GenerateCombinationsRecursive(
            tankList, healerList, dpsList,
            {}, -- Current group being built
            allCombinations,
            {}, -- Used player IDs
            constraints
        )
        
        return allCombinations
        
    end, "OptimizerMode1:GenerateValidCombinations")
end

function OptimizerMode1:GenerateCombinationsRecursive(tankList, healerList, dpsList, currentGroup, results, usedPlayers, constraints)
    -- Recursive backtracking algorithm
    
    -- Base case: group is complete (1T + 1H + 3D = 5)
    if #currentGroup == 5 then
        -- Validate utility requirements
        if self:CheckUtility(currentGroup, constraints) then
            -- Clone group and add to results
            local groupCopy = {}
            for _, player in ipairs(currentGroup) do
                table.insert(groupCopy, player)
            end
            table.insert(results, groupCopy)
        end
        return
    end
    
    -- Determine next slot to fill
    local tankCount = 0
    local healerCount = 0
    local dpsCount = 0
    
    for _, player in ipairs(currentGroup) do
        -- Count how many of each role we've placed
        -- (Simplified - actual implementation tracks slot assignments)
    end
    
    -- Fill Tank slot
    if tankCount == 0 then
        for _, tank in ipairs(tankList) do
            if not usedPlayers[tank.id] then
                -- Try this tank
                table.insert(currentGroup, tank)
                usedPlayers[tank.id] = true
                
                -- Recurse
                self:GenerateCombinationsRecursive(tankList, healerList, dpsList, currentGroup, results, usedPlayers, constraints)
                
                -- Backtrack
                table.remove(currentGroup)
                usedPlayers[tank.id] = nil
            end
        end
    -- Fill Healer slot
    elseif healerCount == 0 then
        for _, healer in ipairs(healerList) do
            if not usedPlayers[healer.id] then
                table.insert(currentGroup, healer)
                usedPlayers[healer.id] = true
                
                self:GenerateCombinationsRecursive(tankList, healerList, dpsList, currentGroup, results, usedPlayers, constraints)
                
                table.remove(currentGroup)
                usedPlayers[healer.id] = nil
            end
        end
    -- Fill DPS slots
    elseif dpsCount < 3 then
        for _, dps in ipairs(dpsList) do
            if not usedPlayers[dps.id] then
                table.insert(currentGroup, dps)
                usedPlayers[dps.id] = true
                
                self:GenerateCombinationsRecursive(tankList, healerList, dpsList, currentGroup, results, usedPlayers, constraints)
                
                table.remove(currentGroup)
                usedPlayers[dps.id] = nil
            end
        end
    end
end

function OptimizerMode1:CheckUtility(group, constraints)
    if constraints.RequireLust then
        local hasLust = false
        for _, player in ipairs(group) do
            if player.utils and tContains(player.utils, "Lust") then
                hasLust = true
                break
            end
        end
        if not hasLust then
            return false
        end
    end
    
    if constraints.RequireBrez then
        local hasBrez = false
        for _, player in ipairs(group) do
            if player.utils and tContains(player.utils, "Brez") then
                hasBrez = true
                break
            end
        end
        if not hasBrez then
            return false
        end
    end
    
    return true
end
```

---

## 3. Mode 2: Balanced (Fair Distribution)

### 3.1 Main Algorithm

**File:** `core/organizer/optimizer_mode2.lua` (NEW)

```lua
-- MARK: Module Definition
local OptimizerMode2 = {}
NextKey222.OptimizerMode2 = OptimizerMode2
NextKey222.RegisterModule("OptimizerMode2", OptimizerMode2)

function OptimizerMode2:FindAllGroups(playerPool, constraints)
    return NextKey222.SafeRun(function()
        -- Phase 1: Rank every player
        local rankedPlayers = self:CalculatePlayerRankScores(playerPool, constraints)
        
        -- Phase 2: Draft players into balanced teams
        local numGroups = math.floor(#playerPool / 5)
        local teams = self:ExecuteRoleConstrainedSnakeDraft(rankedPlayers, numGroups)
        
        -- Phase 3: Optimize keystones within each team
        local finalGroups = {}
        for _, team in ipairs(teams) do
            local finalizedGroup = self:OptimizeTeamKeystone(team, constraints)
            if finalizedGroup then
                table.insert(finalGroups, finalizedGroup)
            end
        end
        
        local leftoverPlayers = self:GetUndraftedPlayers(playerPool, finalGroups)
        
        return finalGroups, leftoverPlayers
        
    end, "OptimizerMode2:FindAllGroups")
end

function OptimizerMode2:CalculatePlayerRankScores(playerPool, constraints)
    local allKeystones = self:GetAllKeystones(playerPool)
    local rankedPlayerList = {}
    
    for _, player in ipairs(playerPool) do
        local totalScore = 0
        
        -- Calculate this player's score against EVERY key
        for _, keystone in ipairs(allKeystones) do
            local gainScore = NextKey222.OrganizerScoring:CalculatePlayerGain(player, keystone)
            
            local preferenceScore = 0
            local pref = player.preferences[keystone.dungeonID] or 0
            if pref == 1 then
                preferenceScore = constraints.LikeBonus
            elseif pref == -1 then
                preferenceScore = -constraints.DislikePenalty
            end
            
            totalScore = totalScore + (gainScore + preferenceScore)
        end
        
        player.rankScore = totalScore
        table.insert(rankedPlayerList, player)
    end
    
    -- Sort players from highest rank score to lowest
    table.sort(rankedPlayerList, function(a, b)
        return a.rankScore > b.rankScore
    end)
    
    return rankedPlayerList
end

function OptimizerMode2:ExecuteRoleConstrainedSnakeDraft(rankedPlayers, numGroups)
    -- Separate players into lists by role
    local tanks = {}
    local healers = {}
    local dps = {}
    
    for _, player in ipairs(rankedPlayers) do
        for _, role in ipairs(player.roles) do
            if role == "Tank" then
                table.insert(tanks, player)
            end
            if role == "Healer" then
                table.insert(healers, player)
            end
            if role == "DPS" then
                table.insert(dps, player)
            end
        end
    end
    
    -- Sort each role list by rank score
    table.sort(tanks, function(a, b) return a.rankScore > b.rankScore end)
    table.sort(healers, function(a, b) return a.rankScore > b.rankScore end)
    table.sort(dps, function(a, b) return a.rankScore > b.rankScore end)
    
    -- Create teams
    local teams = {}
    for i = 1, numGroups do
        teams[i] = {}
    end
    
    local usedPlayerIDs = {}
    
    -- Draft Tanks (1 per team)
    self:DraftRole(teams, tanks, 1, usedPlayerIDs)
    
    -- Draft Healers (1 per team)
    self:DraftRole(teams, healers, 1, usedPlayerIDs)
    
    -- Draft DPS (3 per team)
    self:DraftRole(teams, dps, 3, usedPlayerIDs)
    
    return teams
end

function OptimizerMode2:DraftRole(teams, rolePool, countPerTeam, usedPlayerIDs)
    local numTeams = #teams
    local forward = true
    
    for round = 1, countPerTeam do
        if forward then
            -- Draft forwards: Team 1 → Team N
            for teamIndex = 1, numTeams do
                local player = self:GetNextAvailablePlayer(rolePool, usedPlayerIDs)
                if player then
                    table.insert(teams[teamIndex], player)
                    usedPlayerIDs[player.id] = true
                end
            end
        else
            -- Draft backwards: Team N → Team 1 (snake draft)
            for teamIndex = numTeams, 1, -1 do
                local player = self:GetNextAvailablePlayer(rolePool, usedPlayerIDs)
                if player then
                    table.insert(teams[teamIndex], player)
                    usedPlayerIDs[player.id] = true
                end
            end
        end
        
        -- Alternate direction
        forward = not forward
    end
end

function OptimizerMode2:GetNextAvailablePlayer(rolePool, usedPlayerIDs)
    for _, player in ipairs(rolePool) do
        if not usedPlayerIDs[player.id] then
            return player
        end
    end
    return nil
end

function OptimizerMode2:OptimizeTeamKeystone(team, constraints)
    -- Find the best key for this valid team
    local teamKeystones = {}
    for _, player in ipairs(team) do
        if player.keystone then
            table.insert(teamKeystones, player.keystone)
        end
    end
    
    if #teamKeystones == 0 then
        return nil -- Team has no keystones
    end
    
    local bestTeamScore = -math.huge
    local bestKeystone = nil
    local bestGain = 0
    
    for _, keystone in ipairs(teamKeystones) do
        local currentGain = 0
        local preferenceScore = 0
        
        for _, player in ipairs(team) do
            currentGain = currentGain + NextKey222.OrganizerScoring:CalculatePlayerGain(player, keystone)
            
            local pref = player.preferences[keystone.dungeonID] or 0
            if pref == 1 then
                preferenceScore = preferenceScore + constraints.LikeBonus
            elseif pref == -1 then
                preferenceScore = preferenceScore - constraints.DislikePenalty
            end
        end
        
        local finalScore = currentGain + preferenceScore
        
        if finalScore > bestTeamScore then
            bestTeamScore = finalScore
            bestGain = currentGain
            bestKeystone = keystone
        end
    end
    
    return {
        players = team,
        chosenKeystone = bestKeystone,
        totalGain = bestGain,
        totalScore = bestTeamScore
    }
end
```

---

## 4. Mode 3: Vault Completion

### 4.1 Main Algorithm

**File:** `core/organizer/optimizer_mode3.lua` (NEW)

```lua
-- MARK: Module Definition
local OptimizerMode3 = {}
NextKey222.OptimizerMode3 = OptimizerMode3
NextKey222.RegisterModule("OptimizerMode3", OptimizerMode3)

function OptimizerMode3:FindAllGroups(playerPool, constraints)
    return NextKey222.SafeRun(function()
        local finalGroups = {}
        local leftoverPlayers = self:ClonePlayerPool(playerPool)
        
        -- Filter keystones ONCE at the start (level 10+)
        local validKeystones = {}
        for _, player in ipairs(playerPool) do
            if player.keystone and player.keystone.level >= 10 then
                table.insert(validKeystones, player.keystone)
            end
        end
        
        if #validKeystones == 0 then
            Debug:User("No keystones level 10 or higher available")
            return finalGroups, leftoverPlayers
        end
        
        while true do
            -- Find the group with the highest preference score
            local bestGroup = self:FindHappiestValidGroup(leftoverPlayers, validKeystones, constraints)
            
            if not bestGroup then
                -- No more valid groups can be formed
                break
            else
                table.insert(finalGroups, bestGroup)
                
                -- Remove players and the used keystone
                leftoverPlayers = self:RemovePlayers(leftoverPlayers, bestGroup.players)
                validKeystones = self:RemoveKeystone(validKeystones, bestGroup.chosenKeystone)
            end
        end
        
        return finalGroups, leftoverPlayers
        
    end, "OptimizerMode3:FindAllGroups")
end

function OptimizerMode3:FindHappiestValidGroup(playerPool, validKeystones, constraints)
    local bestOverallGroup = nil
    local maxPreferenceScore = -math.huge
    
    -- Generate all possible 1T/1H/3D combinations
    local allCombinations = self:GenerateAllRoleCombinations(playerPool)
    
    -- Iterate through keystones first
    for _, keystone in ipairs(validKeystones) do
        -- Then iterate through groups
        for _, group in ipairs(allCombinations) do
            -- Check if this group can use this key
            local keystoneOwnerInGroup = false
            for _, player in ipairs(group) do
                if player.keystone and player.keystone.dungeonID == keystone.dungeonID and
                   player.keystone.level == keystone.level then
                    keystoneOwnerInGroup = true
                    break
                end
            end
            
            if not keystoneOwnerInGroup then
                -- This group can't use this key
                goto continue
            end
            
            -- Check utilities
            if self:CheckUtility(group, constraints) then
                -- This group is valid, now calculate its preference score
                local currentPreference = 0
                for _, player in ipairs(group) do
                    -- Use the raw -1, 0, or +1
                    currentPreference = currentPreference + (player.preferences[keystone.dungeonID] or 0)
                end
                
                if currentPreference > maxPreferenceScore then
                    maxPreferenceScore = currentPreference
                    bestOverallGroup = {
                        players = group,
                        chosenKeystone = keystone,
                        totalGain = 0, -- IO is not tracked
                        totalScore = currentPreference
                    }
                end
            end
            
            ::continue::
        end
    end
    
    return bestOverallGroup
end

function OptimizerMode3:GenerateAllRoleCombinations(playerPool)
    -- Same as Mode 1's combination generation
    -- (Implementation identical)
    return NextKey222.OptimizerMode1:GenerateValidCombinations(playerPool, {})
end

function OptimizerMode3:CheckUtility(group, constraints)
    -- Same as Mode 1
    return NextKey222.OptimizerMode1:CheckUtility(group, constraints)
end

function OptimizerMode3:RemoveKeystone(keystones, usedKeystone)
    local result = {}
    for _, keystone in ipairs(keystones) do
        if keystone ~= usedKeystone then
            table.insert(result, keystone)
        end
    end
    return result
end
```

---

## 5. Optimizer Wizard UI

### 5.1 Wizard Frame

**File:** `ui/organizer/optimizerWizard.lua` (NEW)

```lua
-- MARK: Module Definition
local OptimizerWizard = {}
NextKey222.OptimizerWizard = OptimizerWizard
NextKey222.RegisterModule("OptimizerWizard", OptimizerWizard)

local AceGUI = LibStub("AceGUI-3.0")

function OptimizerWizard:Show(mode, constraints)
    return NextKey222.SafeRun(function()
        -- Create wizard frame
        local wizard = AceGUI:Create("Frame")
        wizard:SetTitle("Group Optimizer - " .. mode)
        wizard:SetWidth(600)
        wizard:SetHeight(400)
        wizard:SetLayout("Flow")
        
        -- Store state
        wizard.optimizerMode = mode
        wizard.constraints = constraints
        wizard.state = "READY" -- READY, RUNNING, PAUSED, COMPLETE
        wizard.progress = 0
        wizard.totalWork = 0
        wizard.currentWorkDone = 0
        
        -- Build UI
        self:BuildWizardUI(wizard)
        
        self.activeWizard = wizard
        
    end, "OptimizerWizard:Show")
end

function OptimizerWizard:BuildWizardUI(wizard)
    -- Progress bar
    local progressBar = AceGUI:Create("Slider")
    progressBar:SetLabel("Progress:")
    progressBar:SetSliderValues(0, 100, 1)
    progressBar:SetValue(0)
    progressBar:SetDisabled(true)
    progressBar:SetFullWidth(true)
    wizard:AddChild(progressBar)
    wizard.progressBar = progressBar
    
    -- Status label
    local statusLabel = AceGUI:Create("Label")
    statusLabel:SetText("Ready to start optimizer")
    statusLabel:SetFullWidth(true)
    statusLabel:SetFont(GameFontNormal)
    wizard:AddChild(statusLabel)
    wizard.statusLabel = statusLabel
    
    -- Start/Pause/Resume button
    local actionButton = AceGUI:Create("Button")
    actionButton:SetText("Start Optimizer")
    actionButton:SetWidth(150)
    actionButton:SetCallback("OnClick", function()
        self:OnActionButtonClicked(wizard)
    end)
    wizard:AddChild(actionButton)
    wizard.actionButton = actionButton
    
    -- Cancel button
    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(100)
    cancelButton:SetCallback("OnClick", function()
        self:OnCancelClicked(wizard)
    end)
    wizard:AddChild(cancelButton)
end

function OptimizerWizard:OnActionButtonClicked(wizard)
    if wizard.state == "READY" then
        self:StartOptimizer(wizard)
    elseif wizard.state == "RUNNING" then
        self:PauseOptimizer(wizard)
    elseif wizard.state == "PAUSED" then
        self:ResumeOptimizer(wizard)
    end
end

function OptimizerWizard:StartOptimizer(wizard)
    wizard.state = "RUNNING"
    wizard.actionButton:SetText("Pause")
    wizard.statusLabel:SetText("Running optimizer...")
    
    -- Get player pool from bench
    local playerPool = NextKey222.RosterBoard:GetBenchPlayers()
    
    -- Start async execution
    self:RunOptimizerAsync(wizard, playerPool)
end

function OptimizerWizard:RunOptimizerAsync(wizard, playerPool)
    -- Run in coroutine to allow yielding
    local co = coroutine.create(function()
        local optimizer = self:GetOptimizer(wizard.optimizerMode)
        local finalGroups, leftoverPlayers = optimizer:FindAllGroups(playerPool, wizard.constraints)
        
        -- Apply results
        NextKey222.RosterBoard:ApplyOptimizerResults(finalGroups)
        
        -- Complete
        wizard.state = "COMPLETE"
        wizard.statusLabel:SetText("Optimizer complete!")
        wizard.actionButton:SetText("Done")
        wizard.actionButton:SetDisabled(true)
    end)
    
    -- Tick function to resume coroutine
    local function tick()
        if wizard.state ~= "RUNNING" then
            return
        end
        
        local success, result = coroutine.resume(co)
        
        if not success then
            Debug:Error("Optimizer error:", result)
            wizard.state = "ERROR"
            wizard.statusLabel:SetText("Error: " .. tostring(result))
            return
        end
        
        -- Update progress
        wizard.currentWorkDone = wizard.currentWorkDone + 1
        wizard.progress = (wizard.currentWorkDone / wizard.totalWork) * 100
        wizard.progressBar:SetValue(wizard.progress)
        
        -- Continue if not complete
        if coroutine.status(co) ~= "dead" then
            C_Timer.After(0.05, tick) -- Yield for 50ms
        end
    end
    
    -- Start ticking
    tick()
end
```

---

## 6. Partial Group Strategy

### 6.1 Configuration UI

```lua
-- In RosterBoard header section
function RosterBoard:CreateOptimizerControls(header)
    -- Partial Group Strategy dropdown
    local partialStrategyDropdown = AceGUI:Create("Dropdown")
    partialStrategyDropdown:SetLabel("Partial Groups:") 
    partialStrategyDropdown:SetList({
        maximize_full = "Maximize Full Groups",
        distribute_evenly = "Distribute Evenly"
    })
    partialStrategyDropdown:SetValue("maximize_full")
    partialStrategyDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.partialGroupStrategy = value
        
        -- Show/hide PUG preferences
        if value == "distribute_evenly" then
            self:ShowPUGPreferences()
        else
            self:HidePUGPreferences()
        end
    end)
    header:AddChild(partialStrategyDropdown)
    
    -- PUG Preferences (hidden by default)
    local pugPreferences = AceGUI:Create("InlineGroup")
    pugPreferences:SetTitle("PUG Preferences")
    pugPreferences:SetLayout("Flow")
    pugPreferences:SetVisible(false)
    
    local pugTankCheckbox = AceGUI:Create("CheckBox")
    pugTankCheckbox:SetLabel("Allow PUG Tanks")
    pugTankCheckbox:SetValue(false)
    pugPreferences:AddChild(pugTankCheckbox)
    
    local pugHealerCheckbox = AceGUI:Create("CheckBox")
    pugHealerCheckbox:SetLabel("Allow PUG Healers")
    pugHealerCheckbox:SetValue(false)
    pugPreferences:AddChild(pugHealerCheckbox)
    
    header:AddChild(pugPreferences)
    self.pugPreferences = pugPreferences
end
```

### 6.2 Partial Group Logic

```lua
function OptimizerMode1:HandlePartialGroups(leftoverPlayers, constraints)
    if #leftoverPlayers == 0 then
        return {}
    end
    
    if constraints.partialGroupStrategy == "maximize_full" then
        -- Put all leftover in single partial group
        return {{players = leftoverPlayers}}
    elseif constraints.partialGroupStrategy == "distribute_evenly" then
        -- Form viable partial groups based on PUG preferences
        return self:FormViablePartialGroups(leftoverPlayers, constraints)
    end
end

function OptimizerMode1:FormViablePartialGroups(leftoverPlayers, constraints)
    -- Check roles available
    local roles = {Tank = 0, Healer = 0, DPS = 0}
    for _, player in ipairs(leftoverPlayers) do
        for _, role in ipairs(player.roles) do
            roles[role] = roles[role] + 1
        end
    end
    
    -- Determine viable partial groups
    local partialGroups = {}
    
    -- Can we form 4-player groups? (PUG 1 role)
    if constraints.allowPUGTanks or constraints.allowPUGHealers then
        -- Try to form 4-player groups
        -- (Implementation details...)
    end
    
    return partialGroups
end
```

---

## 7. Implementation Checklist

- [ ] Create `core/organizer/scoring.lua` with V(d,l) and Gain(p,k)
- [ ] Create `core/organizer/optimizer_mode1.lua`
- [ ] Implement recursive combination generation
- [ ] Create `core/organizer/optimizer_mode2.lua`
- [ ] Implement snake draft algorithm
- [ ] Create `core/organizer/optimizer_mode3.lua`
- [ ] Create `ui/organizer/optimizerWizard.lua`
- [ ] Implement coroutine-based async execution
- [ ] Add progress tracking system
- [ ] Implement partial group strategies
- [ ] Add PUG preference configuration
- [ ] Write comprehensive test suite
- [ ] Performance test with 20 players
- [ ] Test all 3 modes extensively
- [ ] Test partial group logic
- [ ] Update `NextKey.toc`

---

**Document Status:** Complete  
**Ready for Implementation:** Yes (with caution - very complex)  
**Blockers:** Phases 0-3 must be complete and stable  
**Next Document:** Phase 5 - Communication