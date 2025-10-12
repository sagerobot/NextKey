# Intelligent Grouping System - Design Document

## Overview
The Intelligent Grouping System is an advanced feature for NextKey that analyzes available keystones and party composition to suggest optimal group formations. It operates in two distinct modes to serve different player needs.

---

## System Architecture

### Two Primary Modes

#### 1. **Best Key Mode** 
*Single-Group Optimization*

**Goal**: Find the one keystone that maximizes total group IO gain and build the optimal 5-player team around it.

**Use Case**: 
- When you have 5-8 players available
- When you want to run the highest-value key first
- When you're optimizing for a single push

**Algorithm**:
```
FOR EACH available keystone:
    Calculate total IO gain for the 5-player party
    Consider each player's individual gain from that dungeon
    
SELECT keystone with highest total group gain

BUILD optimal group FROM available players:
    - Ensure role balance (1 tank, 1 healer, 3 DPS)
    - Apply group preference filters:
        * prioritizeHeroism: Include Mage/Shaman/Evoker if enabled
        * prioritizeBattleRes: Include Druid/Warlock/DK if enabled
    - Maximize combined IO gain
    - Key owner is always included

OUTPUT suggestion WITH:
    - Selected keystone details
    - 5-player roster with roles
    - Individual and total IO gain projections
    - Utility indicators (Heroism/BattleRes status)
```

**Example Output**:
```
🎯 Best Key Suggestion
━━━━━━━━━━━━━━━━━━━
Run: Eve's Necrotic Wake +13
Total Group IO Gain: 320 points

Suggested Group:
🛡️ Alice (Tank, Shaman) +40 IO ✓ Heroism
💚 Carol (Healer, Druid) +60 IO ✓ Battle Res
⚔️ Bob (DPS, Mage) +50 IO ✓ Heroism
⚔️ Eve (DPS, Warlock - Key Owner) +90 IO ✓ Battle Res
⚔️ Henry (DPS, Rogue) +80 IO

✅ Has Heroism (Alice, Bob)
✅ Has Battle Res (Carol, Eve)
```

---

#### 2. **Best Groups Mode**
*Multi-Group Key Rotation*

**Goal**: When you have more than 5 players, intelligently split them into multiple groups where members will run EACH OTHER'S keystones for mutual IO benefit.

**Use Case**:
- When you have 8-15 players available
- When you want to maximize efficiency across multiple runs
- When you're organizing a guild M+ night

**Algorithm**:
```
STEP 1: Analyze Synergy Matrix
FOR EACH pair of players (A, B):
    Calculate mutual IO benefit if they run each other's keys
    synergy[A][B] = gainA(B.key) + gainB(A.key)

STEP 2: Cluster Players into Groups
USE clustering algorithm TO:
    - Form groups of 5 players
    - Maximize total synergy within each group
    - Ensure role balance in each group
    - Apply preference constraints (Heroism/BattleRes)

STEP 3: Generate Key Rotation Schedule
FOR EACH group:
    LIST all keystones owned by group members
    SORT by IO gain potential for the group
    CREATE rotation order

STEP 4: Validate and Warn
FOR EACH group:
    CHECK role composition
    CHECK utility requirements
    FLAG issues (missing tank, missing Heroism, etc.)
    SUGGEST recruits from guild/LFG if needed

OUTPUT multiple group suggestions WITH:
    - Group rosters with roles
    - Key rotation schedule per group
    - Total IO gain per group
    - Utility status and warnings
```

**Example Output**:
```
👥 Best Groups Suggestion
━━━━━━━━━━━━━━━━━━━━━━
8 players → 2 groups with key rotation

━━ Group 1 ━━ (870 IO Total Potential)
🛡️ Alice (Tank, Shaman) ✓ Heroism
💚 Carol (Healer, Druid) ✓ Battle Res
⚔️ Bob (DPS, Mage) ✓ Heroism
⚔️ Eve (DPS, Warlock) ✓ Battle Res
⚔️ Dave (DPS, Hunter)

Key Rotation (3 keys):
1. Eve's Necrotic Wake +13 → +320 group IO
   Alice: +40, Carol: +60, Bob: +50, Eve: +90, Dave: +80

2. Bob's Stonevault +12 → +280 group IO
   Alice: +45, Carol: +50, Bob: +95, Eve: +50, Dave: +40

3. Carol's Mists +11 → +270 group IO
   Alice: +50, Carol: +100, Bob: +40, Eve: +45, Dave: +35

✅ Has Heroism (Alice, Bob)
✅ Has Battle Res (Carol, Eve)
✅ Complete group - Ready to start!

━━ Group 2 ━━ (690 IO Total Potential)
🛡️ Frank (Tank, Warrior)
💚 Grace (Healer, Priest)
⚔️ Henry (DPS, Rogue)
⚔️ [Need 1 more DPS]
⚔️ [Need 1 more DPS]

Key Rotation (3 keys):
1. Henry's Grim Batol +12 → +270 group IO (when full)
2. Grace's Siege +11 → +240 group IO (when full)
3. Frank's City of Threads +10 → +180 group IO (when full)

⚠️ Missing Heroism - Recruit Mage/Shaman/Evoker
⚠️ Missing Battle Res - Recruit Druid/Warlock/DK
⚠️ Need 2 more DPS to complete group

💡 Suggestion: Check guild roster or use LFG for:
   - 1x DPS with Heroism (Mage/Evoker)
   - 1x DPS with Battle Res (Warlock)
```

---

## Configuration Settings

Located in **General Settings** tab of the addon options menu:

### Group Composition Preferences

#### `prioritizeHeroism` (boolean, default: true)
- **Description**: When suggesting groups, prioritize including players with Heroism/Bloodlust
- **Applies To**: Mage, Shaman, Evoker (and their Heroism-capable specs)
- **Effect**: 
  - Groups without Heroism will be flagged with warnings
  - Algorithm will try to include at least one Heroism class per group
  - If impossible, provides clear notification

#### `prioritizeBattleRes` (boolean, default: true)
- **Description**: When suggesting groups, prioritize including players with Battle Resurrection
- **Applies To**: Druid, Warlock, Death Knight
- **Effect**:
  - Groups without Battle Res will be flagged with warnings
  - Algorithm will try to include at least one Battle Res class per group
  - If impossible, provides clear notification

### Storage Location
```lua
addon.db.global.groupPreferences = {
    prioritizeHeroism = true,
    prioritizeBattleRes = true
}
```

---

## Technical Implementation Details

### Data Structures

#### Player Profile (Enhanced)
```lua
PlayerProfile = {
    name = "PlayerName-Realm",
    class = "MAGE",
    spec = "Frost",
    specID = 64,
    role = "DAMAGER",  -- "TANK", "HEALER", "DAMAGER"
    io = 3100,
    
    -- Keystones
    keystones = {
        { dungeonID = 1, level = 10, ... }
    },
    
    -- Capabilities
    capabilities = {
        heroism = true,
        battleRes = false,
        immunities = true,  -- Potential future expansion
        -- Add more utilities as needed
    },
    
    -- IO Potential per dungeon
    dungeonGains = {
        [1] = { min = 20, expected = 35, max = 50 },  -- Ara-Kara
        [2] = { min = 15, expected = 30, max = 45 },  -- City of Threads
        -- ... per dungeon
    }
}
```

#### Group Suggestion
```lua
GroupSuggestion = {
    mode = "best_key",  -- or "best_groups"
    
    -- For Best Key Mode
    selectedKey = {
        dungeonID = 6,
        level = 13,
        owner = "Eve-Realm"
    },
    
    -- Group composition
    roster = {
        { name = "Alice-Realm", role = "TANK", ... },
        { name = "Carol-Realm", role = "HEALER", ... },
        { name = "Bob-Realm", role = "DAMAGER", ... },
        { name = "Eve-Realm", role = "DAMAGER", ... },
        { name = "Henry-Realm", role = "DAMAGER", ... }
    },
    
    -- IO Analysis
    ioGain = {
        total = 320,
        perPlayer = {
            ["Alice-Realm"] = 40,
            ["Carol-Realm"] = 60,
            ["Bob-Realm"] = 50,
            ["Eve-Realm"] = 90,
            ["Henry-Realm"] = 80
        }
    },
    
    -- Utility Status
    utilities = {
        hasHeroism = true,
        heroismProviders = { "Alice-Realm", "Bob-Realm" },
        hasBattleRes = true,
        battleResProviders = { "Carol-Realm", "Eve-Realm" }
    },
    
    -- Validation
    isValid = true,
    warnings = {},
    errors = {}
}
```

#### Multi-Group Suggestion (Best Groups Mode)
```lua
MultiGroupSuggestion = {
    mode = "best_groups",
    groups = {
        [1] = {
            roster = { ... },  -- 5 players
            keyRotation = {
                { key = {...}, totalGain = 320, perPlayer = {...} },
                { key = {...}, totalGain = 280, perPlayer = {...} },
                { key = {...}, totalGain = 270, perPlayer = {...} }
            },
            totalPotential = 870,
            utilities = { hasHeroism = true, hasBattleRes = true },
            isComplete = true
        },
        [2] = {
            roster = { ... },  -- 3 players (incomplete)
            keyRotation = { ... },
            totalPotential = 690,
            utilities = { hasHeroism = false, hasBattleRes = false },
            isComplete = false,
            warnings = {
                "Missing Heroism",
                "Missing Battle Res", 
                "Need 2 more DPS"
            },
            recruitSuggestions = {
                { role = "DAMAGER", preferredClass = "MAGE", reason = "Provides Heroism" },
                { role = "DAMAGER", preferredClass = "WARLOCK", reason = "Provides Battle Res" }
            }
        }
    }
}
```

---

## Algorithm Details

### Best Key Mode Algorithm

```lua
function UI:SuggestBestKey()
    local availablePlayers = self:GetAvailablePlayers()
    local availableKeys = self:GetAllKeystones()
    
    -- Calculate IO gain for each potential key/group combination
    local bestScore = 0
    local bestKey = nil
    local bestRoster = nil
    
    for _, keystone in ipairs(availableKeys) do
        -- Try all possible 5-player combinations
        local combinations = self:GenerateRosterCombinations(
            availablePlayers,
            5,  -- group size
            { keyOwner = keystone.owner }  -- owner must be included
        )
        
        for _, roster in ipairs(combinations) do
            -- Validate role composition
            if not self:ValidateRoleComposition(roster) then
                continue
            end
            
            -- Apply preference filters
            if not self:MeetsGroupPreferences(roster) then
                continue
            end
            
            -- Calculate total IO gain
            local totalGain = 0
            for _, player in ipairs(roster) do
                local gain = self:CalculatePlayerIOGain(player, keystone)
                totalGain = totalGain + gain
            end
            
            -- Track best option
            if totalGain > bestScore then
                bestScore = totalGain
                bestKey = keystone
                bestRoster = roster
            end
        end
    end
    
    return self:FormatBestKeySuggestion(bestKey, bestRoster, bestScore)
end
```

### Best Groups Mode Algorithm

```lua
function UI:SuggestBestGroups()
    local availablePlayers = self:GetAvailablePlayers()
    
    if #availablePlayers < 5 then
        return "Need at least 5 players for group suggestions"
    end
    
    -- Step 1: Calculate synergy matrix
    local synergy = self:CalculateSynergyMatrix(availablePlayers)
    
    -- Step 2: Cluster into groups (greedy approach with role constraints)
    local groups = {}
    local remaining = self:CopyTable(availablePlayers)
    
    while #remaining >= 3 do  -- Need at least 3 for a partial group
        local group = self:FormOptimalGroup(remaining, synergy)
        table.insert(groups, group)
        
        -- Remove assigned players
        for _, player in ipairs(group.roster) do
            self:RemovePlayer(remaining, player)
        end
    end
    
    -- Step 3: Generate key rotation for each group
    for _, group in ipairs(groups) do
        group.keyRotation = self:GenerateKeyRotation(group.roster)
        group.totalPotential = self:CalculateTotalPotential(group.keyRotation)
    end
    
    -- Step 4: Validate and generate warnings
    for _, group in ipairs(groups) do
        self:ValidateGroup(group)
        self:GenerateRecruitSuggestions(group)
    end
    
    return self:FormatMultiGroupSuggestion(groups)
end

function UI:CalculateSynergyMatrix(players)
    local matrix = {}
    
    for i, playerA in ipairs(players) do
        matrix[i] = {}
        for j, playerB in ipairs(players) do
            if i ~= j then
                -- Calculate mutual benefit if A and B group together
                local gainA = 0
                local gainB = 0
                
                -- If B has a key, how much does A gain?
                if playerB.keystones then
                    for _, key in ipairs(playerB.keystones) do
                        gainA = gainA + self:CalculatePlayerIOGain(playerA, key)
                    end
                end
                
                -- If A has a key, how much does B gain?
                if playerA.keystones then
                    for _, key in ipairs(playerA.keystones) do
                        gainB = gainB + self:CalculatePlayerIOGain(playerB, key)
                    end
                end
                
                matrix[i][j] = gainA + gainB
            end
        end
    end
    
    return matrix
end
```

### Group Preference Validation

```lua
function UI:MeetsGroupPreferences(roster)
    local prefs = NextKey.db.global.groupPreferences
    
    -- Check Heroism requirement
    if prefs.prioritizeHeroism then
        local hasHeroism = false
        for _, player in ipairs(roster) do
            if self:PlayerProvidesHeroism(player.profile, player.class, player.specID) then
                hasHeroism = true
                break
            end
        end
        
        if not hasHeroism then
            return false, "No Heroism provider in group"
        end
    end
    
    -- Check Battle Res requirement
    if prefs.prioritizeBattleRes then
        local hasBattleRes = false
        for _, player in ipairs(roster) do
            if self:PlayerProvidesBattleRes(player.profile, player.class, player.specID) then
                hasBattleRes = true
                break
            end
        end
        
        if not hasBattleRes then
            return false, "No Battle Res provider in group"
        end
    end
    
    return true
end
```

---

## UI Integration

### Trigger Conditions
The group suggestion system becomes available when:
1. More than 5 keystones are detected (compact mode)
2. "Suggest Groups" button is clicked (located in results area when compact mode is active)

### Display Format
- **Chat Output**: Post formatted suggestions to party/raid chat
- **UI Window**: Show detailed breakdown in main window
- **Tooltip**: Hover over suggestions for individual player IO breakdowns

### User Actions
After receiving a suggestion, players can:
1. Accept and auto-invite suggested group members (if leader)
2. Copy suggestion to clipboard for manual invites
3. Request alternative suggestions (re-calculate with different preferences)
4. Save suggestion for later reference

---

## Future Enhancements

### Phase 2 Features
- **Historical Performance**: Weight suggestions by past success rates with certain players
- **Schedule Coordination**: Track when players are available across multiple days
- **Vault Optimization**: Consider Great Vault rewards when suggesting key levels
- **Loot Distribution**: Factor in gear needs when suggesting groups

### Phase 3 Features
- **Cross-Realm Integration**: Pull data from connected realms
- **Community Integration**: Share suggestions with WoW Communities
- **Analytics Dashboard**: Track group performance over time
- **ML Predictions**: Use machine learning to predict key success probability

---

## Testing Strategy

### Unit Tests
- Synergy matrix calculation
- Role composition validation
- Preference filter logic
- IO gain calculations

### Integration Tests
- End-to-end group suggestion flow
- Multi-group splitting logic
- Chat output formatting
- UI rendering

### Scenarios to Test
1. **Perfect Setup**: 10 players, all roles, balanced IO, everyone has keys
2. **Incomplete Groups**: 7 players, missing tank in second group
3. **No Utility**: Players without Heroism/BattleRes with preferences enabled
4. **Edge Cases**: 
   - Solo player (should suggest recruiting)
   - Exactly 5 players (should use Best Key mode)
   - 20+ players (should split into 4 groups)

---

## Performance Considerations

### Optimization Strategies
- **Cache synergy calculations**: Reuse for same player set
- **Limit combination search**: Use heuristics to prune search space
- **Lazy evaluation**: Only calculate full suggestions when requested
- **Throttle recalculations**: Don't recalculate on every UI update

### Expected Performance
- Best Key Mode: < 100ms for 10 players, 40 keystones
- Best Groups Mode: < 500ms for 15 players (with caching)
- Memory: < 1MB additional memory usage

---

## Implementation Priority

### Phase 1: Foundation (Current Task - COMPLETED ✓)
- [x] Move group preferences to General Settings
- [x] Add configuration defaults
- [x] Update UI references

### Phase 2: Best Key Mode (Next)
- [ ] Implement basic roster combination generator
- [ ] Add role composition validator
- [ ] Create IO gain calculator integration
- [ ] Build suggestion formatter
- [ ] Add chat output

### Phase 3: Best Groups Mode
- [ ] Implement synergy matrix calculator
- [ ] Create group clustering algorithm
- [ ] Add key rotation generator
- [ ] Build multi-group formatter
- [ ] Add recruit suggestion logic

### Phase 4: Polish
- [ ] Add tooltips and detailed breakdowns
- [ ] Implement suggestion history
- [ ] Add user preference overrides
- [ ] Create comprehensive testing suite

---

## Notes for Future Implementation

1. **Modularity**: Keep the grouping logic separate from UI code
   - Create `core/groupSuggestions.lua` module
   - Use event-driven architecture for updates

2. **Extensibility**: Design with future enhancements in mind
   - Abstract utility detection (easy to add new utilities)
   - Pluggable scoring algorithms (swap in ML models later)

3. **User Experience**: 
   - Always provide actionable suggestions
   - Clear explanations for why certain groups are suggested
   - Allow users to manually adjust suggestions

4. **Communication**:
   - Be mindful of chat spam with large groups
   - Provide condensed and detailed output options
   - Support whisper-based coordination

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-12  
**Status**: Checkboxes moved to General Settings ✓ | Core system awaiting implementation