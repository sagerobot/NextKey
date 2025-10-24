# M+ Group Organizer - Phase 0.5: Integration Strategy

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0 (Foundation)  
**Estimated Complexity:** High  
**Implementation Priority:** CRITICAL - Must complete before UI development

---

## Overview

This document addresses the **critical integration challenges** between the new M+ Group Organizer feature and NextKey's existing systems. The Organizer is not a standalone feature—it must seamlessly coexist with, extend, and sometimes replace existing functionality.

**Key Integration Points:**
1. UI fork mechanism (5-player vs 6+ player modes)
2. Existing module integration (ProfilesService, IOCalculator, Communications)
3. GroupSuggestions deprecation strategy
4. Compact mode migration
5. Backward compatibility handling

---

## 1. UI Fork Architecture

### 1.1 Current UI Structure

NextKey currently has a single main UI in [`ui/main.lua`](../../../ui/main.lua:1):
- **Keystone View:** Ranked list of party keystones (default for 1-5 players)
- **Dungeon View:** Personal scores and preferences
- **Compact Mode:** Simplified view for 6+ players (basic, non-interactive)

### 1.2 New Dual-Mode System

**Architecture:**
```
Group Size Detection
    ├─ 1-5 Players → Existing UI (Keystone/Dungeon View)
    └─ 6+ Players → NEW Roster Board
                   ├─ Organizer View (Leader/Assistant)
                   └─ Participant View (Read-only)
```

### 1.3 Implementation Strategy

**File:** Modify [`ui/main.lua`](../../../ui/main.lua:1)

```lua
-- MARK: UI Mode Detection

function NextKeyUI:DetermineUIMode()
    local groupSize = GetNumGroupMembers()
    
    if groupSize <= 5 then
        return "KEYSTONE_OPTIMIZER" -- Existing 5-man UI
    else
        return "ROSTER_BOARD" -- New Organizer UI
    end
end

function NextKeyUI:ShowMainWindow()
    return NextKey222.SafeRun(function()
        local mode = self:DetermineUIMode()
        
        if mode == "KEYSTONE_OPTIMIZER" then
            self:ShowKeystoneOptimizerUI()
        elseif mode == "ROSTER_BOARD" then
            self:ShowRosterBoardUI()
        end
        
        Debug:Dev("ui", "Main window opened in mode:", mode)
    end, "NextKeyUI:ShowMainWindow")
end
```

### 1.4 Dynamic Mode Switching

**Challenge:** User opens UI with 5 players, 6th joins mid-session

**Solution:**
```lua
-- Register roster change event
function NextKeyUI:Initialize()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRosterChange")
end

function NextKeyUI:OnRosterChange()
    if not self.mainFrame or not self.mainFrame:IsVisible() then
        return
    end
    
    local currentMode = self.currentUIMode
    local newMode = self:DetermineUIMode()
    
    if currentMode ~= newMode then
        Debug:User("Group size changed, switching UI mode...")
        self:ShowMainWindow() -- Rebuild UI in new mode
    end
end
```

### 1.5 Compact Mode Deprecation

**Current Compact Mode Location:** [`ui/main.lua`](../../../ui/main.lua:1) (inline conditional)

**Migration Strategy:**
1. **v0.3.0 (Organizer Release):** Compact mode code remains but is never triggered (6+ always routes to Organizer)
2. **v0.3.1 (Next Release):** Remove compact mode code entirely
3. **Documentation:** Update user guide to explain new Organizer feature

**Code Cleanup Checklist:**
- [ ] Remove `CreateCompactModeUI()` function from `ui/main.lua`
- [ ] Remove compact mode configuration options from `options/main.lua`
- [ ] Remove compact mode references from debug system
- [ ] Update user guide with Organizer documentation

---

## 2. ProfilesService Integration

### 2.1 Current ProfilesService Usage

[`core/profiles.lua`](../../../core/profiles.lua:1) provides centralized player profile building:
- Aggregates data from RaiderIO, LibOpenRaid, Blizzard API
- 5-minute cache with event-driven invalidation
- Used by UI tooltips, keystone ranking, group suggestions

### 2.2 Organizer Requirements

The Organizer needs **enhanced profile data** beyond current scope:
- ✅ Already provided: Class, spec, role, IO score, dungeon scores
- ❌ Missing: Account-wide alt data
- ❌ Missing: Role flexibility configuration
- ❌ Missing: Utility capabilities (Lust/Brez)

### 2.3 Integration Strategy: Extend ProfilesService

**File:** Extend [`core/profiles.lua`](../../../core/profiles.lua:1)

```lua
-- MARK: Organizer Extensions

function ProfilesService:GetOrganizerProfile(playerID)
    return NextKey222.SafeRun(function()
        -- Get base profile
        local baseProfile = self:GetProfile(playerID)
        
        -- Enhance with Organizer-specific data
        local enhancedProfile = {
            -- Base profile data
            name = baseProfile.name,
            realm = baseProfile.realm,
            class = baseProfile.class,
            specID = baseProfile.specID,
            role = baseProfile.role,
            io = baseProfile.io,
            dungeonScores = baseProfile.dungeonScores,
            capabilities = baseProfile.capabilities,
            
            -- Organizer enhancements
            availableRoles = self:GetAvailableRoles(playerID),
            utilities = self:GetUtilities(playerID),
            preferences = self:GetPreferences(playerID),
            alts = self:GetAlts(playerID),
            dataSource = baseProfile.dataSource,
            
            -- Metadata
            hasAddon = self:CheckAddonPresence(playerID),
            dataFreshness = self:CheckDataFreshness(baseProfile)
        }
        
        return enhancedProfile
    end, "ProfilesService:GetOrganizerProfile")
end

function ProfilesService:GetAvailableRoles(playerID)
    -- Fetch from CharacterStorage (Phase 0)
    local charData = NextKey222.CharacterStorage:GetCharacter(playerID)
    if charData and charData.availableRoles then
        local roles = {}
        for role, enabled in pairs(charData.availableRoles) do
            if enabled then
                table.insert(roles, role)
            end
        end
        return roles
    end
    
    -- Fallback: derive from current spec
    return self:DeriveRolesFromSpec(playerID)
end

function ProfilesService:GetUtilities(playerID)
    -- Use existing capability detection
    local profile = self:GetProfile(playerID)
    return profile.capabilities or {}
end

function ProfilesService:GetPreferences(playerID)
    -- Fetch from Config module
    return NextKey222.Config:GetPreferences() or {}
end

function ProfilesService:GetAlts(playerID)
    -- Fetch from CharacterStorage
    return NextKey222.CharacterStorage:GetAltCharacters(playerID)
end
```

### 2.4 Cache Strategy for Organizer Profiles

**Challenge:** Organizer needs data for 20+ players simultaneously

**Solution:** Batch profile loading with dedicated cache
```lua
function ProfilesService:GetOrganizerProfilesBatch(playerIDs)
    local profiles = {}
    
    for _, playerID in ipairs(playerIDs) do
        -- Use cache if available and fresh
        if self.organizerProfileCache[playerID] then
            local cached = self.organizerProfileCache[playerID]
            if (GetTime() - cached.timestamp) < 300 then -- 5 min TTL
                profiles[playerID] = cached.profile
            else
                profiles[playerID] = self:GetOrganizerProfile(playerID)
                self.organizerProfileCache[playerID] = {
                    profile = profiles[playerID],
                    timestamp = GetTime()
                }
            end
        else
            profiles[playerID] = self:GetOrganizerProfile(playerID)
            self.organizerProfileCache[playerID] = {
                profile = profiles[playerID],
                timestamp = GetTime()
            }
        end
    end
    
    return profiles
end
```

---

## 3. IOCalculator Integration

### 3.1 Current IOCalculator Usage

[`core/ioCalculator.lua`](../../../core/ioCalculator.lua:1) implements MythicPlanner.com algorithm:
- `CalculateDungeonScore()`: Score for specific run
- `CalculateIORange()`: Min/max/expected gains for single player
- `CalculateGroupIORange()`: Total party gains

### 3.2 Organizer Requirements

**Algorithms need these calculations:**
- **Mode 1 (Max Power):** Per-group total IO gain
- **Mode 2 (Balanced):** Per-player aggregate potential across all keys
- **Mode 3 (Vault):** No IO calculations (preference-only)

### 3.3 Integration Strategy: Extend IOCalculator

**File:** Extend [`core/ioCalculator.lua`](../../../core/ioCalculator.lua:1)

```lua
-- MARK: Organizer Extensions

function IOCalculator:CalculatePlayerGain(player, keystone)
    -- This is the core Gain(p, k) function from Algorithm Spec
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
    end, "IOCalculator:CalculatePlayerGain")
end

function IOCalculator:GetBaseValue(dungeonID, level)
    -- V(d, l) function from Algorithm Spec
    if level >= 2 and level <= 20 then
        -- Use static lookup table (dungeonMatrix)
        return self:GetBaseValueFromTable(dungeonID, level)
    elseif level >= 21 then
        -- Use formula for 21+
        return 145 + (level * 15) + 40
    else
        error("Invalid keystone level: " .. tostring(level))
    end
end

function IOCalculator:CalculateGroupTotalGain(group, keystone)
    -- Sum of all player gains for a specific keystone
    local totalGain = 0
    
    for _, player in ipairs(group.players) do
        totalGain = totalGain + self:CalculatePlayerGain(player, keystone)
    end
    
    return totalGain
end

function IOCalculator:CalculatePlayerAggregatePotential(player, allKeystones, constraints)
    -- Used by Mode 2 (Balanced) ranking algorithm
    local totalPotential = 0
    
    for _, keystone in ipairs(allKeystones) do
        local gain = self:CalculatePlayerGain(player, keystone)
        local prefValue = player.preferences[keystone.dungeonID] or 0
        
        -- Apply preference weights
        local preferenceScore = 0
        if prefValue == 1 then
            preferenceScore = constraints.LikeBonus
        elseif prefValue == -1 then
            preferenceScore = -constraints.DislikePenalty
        end
        
        totalPotential = totalPotential + gain + preferenceScore
    end
    
    return totalPotential
end
```

### 3.4 Performance Optimization: Memoization

**Challenge:** Mode 1 calculates gain for every (player, keystone) pair thousands of times

**Solution:** Memoize gain calculations
```lua
function IOCalculator:CalculatePlayerGainCached(player, keystone)
    -- Create cache key
    local cacheKey = player.id .. ":" .. keystone.dungeonID .. ":" .. keystone.level
    
    if not self.gainCache then
        self.gainCache = {}
    end
    
    if self.gainCache[cacheKey] then
        return self.gainCache[cacheKey]
    end
    
    local gain = self:CalculatePlayerGain(player, keystone)
    self.gainCache[cacheKey] = gain
    
    return gain
end

function IOCalculator:ClearGainCache()
    self.gainCache = {}
end
```

---

## 4. Communications Integration

### 4.1 Current Communications Module

[`core/comms.lua`](../../../core/comms.lua:1) handles:
- Party/Raid keystone syncing
- IO score updates
- Preference sharing
- Uses AceComm-3.0 with `NKEY1` prefix

### 4.2 Organizer Communication Needs

**New message types** (defined in Phase 0):
- Poll requests/responses
- Roster state synchronization
- Optimizer status updates

### 4.3 Integration Strategy: Extend Communications

**File:** Extend [`core/comms.lua`](../../../core/comms.lua:1)

```lua
-- MARK: Organizer Communication Extensions

Communications.OrganizerOpcodes = {
    POLL_REQUEST = "ORG_POLL_REQUEST",
    POLL_RESPONSE = "ORG_POLL_RESPONSE",
    ROSTER_STATE_FULL = "ORG_ROSTER_FULL",
    ROSTER_STATE_DELTA = "ORG_ROSTER_DELTA",
    PLAYER_CARD_MOVED = "ORG_CARD_MOVED",
    KEYSTONE_DESIGNATED = "ORG_KEY_SET",
    OPTIMIZER_STARTED = "ORG_OPT_START",
    OPTIMIZER_PROGRESS = "ORG_OPT_PROGRESS",
    OPTIMIZER_COMPLETE = "ORG_OPT_COMPLETE"
}

function Communications:SendOrganizerMessage(opcode, data, channel)
    return NextKey222.SafeRun(function()
        local message = {
            opcode = opcode,
            version = self.version,
            timestamp = GetTime(),
            sender = self:GetPlayerFullName(),
            data = data
        }
        
        self:SendAddonMessage(message, channel or "RAID")
        
        Debug:Dev("org_comms", "Sent organizer message:", opcode)
    end, "Communications:SendOrganizerMessage")
end

function Communications:RegisterOrganizerHandlers()
    -- Register handlers for all organizer opcodes
    for name, opcode in pairs(self.OrganizerOpcodes) do
        self:RegisterHandler(opcode, function(message, sender)
            self:HandleOrganizerMessage(opcode, message, sender)
        end)
    end
end

function Communications:HandleOrganizerMessage(opcode, message, sender)
    -- Route to appropriate Organizer module
    if NextKey222.Organizer then
        NextKey222.Organizer:OnMessageReceived(opcode, message, sender)
    end
end
```

### 4.4 Throttling Strategy for Roster Sync

**Challenge:** Frequent roster updates (drag-and-drop) = message spam

**Solution:** Batch updates (implemented in Phase 0, integrated here)
```lua
function Communications:QueueOrganizerUpdate(updateData)
    if not self.organizerUpdateQueue then
        self.organizerUpdateQueue = {}
    end
    
    table.insert(self.organizerUpdateQueue, updateData)
    
    -- Start flush timer if not already running
    if not self.organizerFlushTimer then
        self.organizerFlushTimer = C_Timer.NewTicker(0.5, function()
            self:FlushOrganizerUpdateQueue()
        end)
    end
end

function Communications:FlushOrganizerUpdateQueue()
    if #self.organizerUpdateQueue == 0 then return end
    
    -- Combine multiple updates into batch message
    local batchMessage = {
        updates = self.organizerUpdateQueue
    }
    
    self:SendOrganizerMessage(
        self.OrganizerOpcodes.ROSTER_STATE_DELTA,
        batchMessage,
        "RAID"
    )
    
    self.organizerUpdateQueue = {}
end
```

---

## 5. GroupSuggestions Deprecation

### 5.1 Current GroupSuggestions Module

[`core/groupSuggestions.lua`](../../../core/groupSuggestions.lua:1) provides:
- "Smart Sort" algorithm (Borda Count)
- Keystone ranking for 5-player groups
- IO gain calculations

### 5.2 Conflict Analysis

**Overlap with Organizer:**
- Both rank keystones
- Both calculate IO gains
- Both consider preferences

**Key Difference:**
- GroupSuggestions: Rank **keystones** for a single 5-player group
- Organizer: Form **multiple groups** from a large player pool

### 5.3 Deprecation Strategy

**Option 1: Keep Both (Recommended)**
- GroupSuggestions remains for 5-player groups (existing UI)
- Organizer used for 6+ players only
- No conflict, clear separation

**Option 2: Merge into Organizer**
- Deprecate GroupSuggestions entirely
- Make Organizer handle single-group optimization (5-player mode)
- Higher implementation complexity

**Decision:** **Keep Both** - Clean separation, lower risk

**Code Changes:**
```lua
-- In ui/main.lua
function NextKeyUI:ShowKeystoneOptimizerUI()
    -- Continue using GroupSuggestions for 5-player mode
    local suggestions = NextKey222.GroupSuggestions:GetSuggestions()
    self:RenderKeystoneCards(suggestions)
end

function NextKeyUI:ShowRosterBoardUI()
    -- Use new Organizer for 6+ players
    NextKey222.Organizer:ShowRosterBoard()
end
```

**No deprecation needed** - modules serve different purposes.

---

## 6. Backward Compatibility

### 6.1 Version Compatibility Matrix

**Scenario:** Mixed addon versions in same raid

| Organizer Version | Member Version | Behavior |
|-------------------|----------------|----------|
| 0.3.0 (Organizer) | 0.3.0 | ✅ Full functionality |
| 0.3.0 (Organizer) | 0.2.1 (Pre-Organizer) | ⚠️ Auto-detected as non-addon user |
| 0.2.1 (Pre-Organizer) | 0.3.0 | ❌ Cannot see Organizer (no 6+ UI) |

### 6.2 Detection Strategy

**File:** Extend [`core/comms.lua`](../../../core/comms.lua:1)

```lua
function Communications:CheckOrganizerSupport(playerID)
    -- Send version check message
    local versionCheck = {
        opcode = "VERSION_CHECK",
        features = {"ORGANIZER"}
    }
    
    self:SendWhisper(versionCheck, playerID)
    
    -- Response handled in version check handler
    -- Sets self.organizerCapablePlayers[playerID] = true/false
end

function Communications:OnVersionCheckResponse(message, sender)
    local hasOrganizer = false
    
    if message.data.features then
        for _, feature in ipairs(message.data.features) do
            if feature == "ORGANIZER" then
                hasOrganizer = true
                break
            end
        end
    end
    
    self.organizerCapablePlayers[sender] = hasOrganizer
end
```

### 6.3 Graceful Degradation

**If some members don't have Organizer support:**
- Auto-detect them as non-addon users
- Include them in roster board manually
- Organizer functionality still works for those who have it
- Participants without Organizer see nothing (no 6+ UI in old version)

**User Communication:**
```lua
function Organizer:CheckMemberVersions()
    local outdatedMembers = {}
    
    for _, playerID in ipairs(self:GetRaidMembers()) do
        if not Communications.organizerCapablePlayers[playerID] then
            table.insert(outdatedMembers, playerID)
        end
    end
    
    if #outdatedMembers > 0 then
        Debug:User("Some raid members don't have the Group Organizer addon. They will need to be managed manually.")
    end
end
```

---

## 7. Data Migration

### 7.1 SavedVariables Migration

**File:** `core/characterStorage.lua` (Phase 0)

```lua
function CharacterStorage:MigrateFromVersion(oldVersion)
    return NextKey222.SafeRun(function()
        if oldVersion < "0.3.0" then
            Debug:User("Migrating character data to new storage format...")
            
            -- Initialize new profile.characters structure
            if not self.db.profile.characters then
                self.db.profile.characters = {}
            end
            
            -- Migrate current character data
            local currentChar = self:GetCurrentCharacterID()
            if not self.db.profile.characters[currentChar] then
                self:AddCurrentCharacter()
            end
            
            Debug:User("Migration complete. Please log in to your alts to update their data.")
        end
        
        return true
    end, "CharacterStorage:MigrateFromVersion")
end
```

### 7.2 First-Time Setup

**On first login with v0.3.0:**
1. Detect no character storage exists
2. Create storage for current character
3. Show tutorial prompt about Organizer feature
4. Prompt user to configure roles in Options

```lua
function Organizer:CheckFirstTimeSetup()
    if not self.db.profile.characters or not next(self.db.profile.characters) then
        self:ShowFirstTimeSetupDialog()
    end
end

function Organizer:ShowFirstTimeSetupDialog()
    -- Create popup dialog
    StaticPopupDialogs["NEXTKEY_ORGANIZER_FIRST_TIME"] = {
        text = "Welcome to the new Group Organizer! Configure your character roles in /nk config → Character Roles.",
        button1 = "Open Config",
        button2 = "Later",
        OnAccept = function()
            NextKey222.Options:OpenToPanel("Character Roles")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopup_Show("NEXTKEY_ORGANIZER_FIRST_TIME")
end
```

---

## 8. Module Load Order

### 8.1 Updated Load Order

Update [`NextKey.toc`](../../../NextKey.toc:1):

```
# Core Systems (existing)
core/config.lua
core/debugService.lua
core/debugUI.lua
boot.lua
core/slashCommands.lua

# Character Storage (NEW - must load before ProfilesService)
core/characterStorage.lua
core/types/player.lua

# Existing Core Modules
core/utils.lua
core/constants.lua
core/keystones.lua
core/profiles.lua          # Will use CharacterStorage
core/ioCalculator.lua
core/comms.lua

# Organizer Modules (NEW)
core/organizer/autoDetection.lua
core/organizer/playerDataBuilder.lua
core/organizer/validation.lua
core/organizer/comms.lua   # Extends core/comms.lua

# UI Modules (existing)
ui/components.lua
ui/main.lua                # Modified for UI fork

# Organizer UI (NEW - in Phase 1)
ui/organizer/rosterBoard.lua
ui/organizer/playerCard.lua
ui/organizer/surveyDialog.lua
```

### 8.2 Dependency Graph

```
boot.lua
    ├─ config.lua
    ├─ debugService.lua
    └─ characterStorage.lua (NEW)
            └─ profiles.lua (enhanced)
                    ├─ ioCalculator.lua (enhanced)
                    ├─ organizer/playerDataBuilder.lua (NEW)
                    └─ organizer/autoDetection.lua (NEW)
                            └─ organizer/validation.lua (NEW)
```

---

## 9. Event Handling Integration

### 9.1 Existing Event System

NextKey uses [`events/handlers.lua`](../../../events/handlers.lua:1) for event registration.

### 9.2 Organizer Event Needs

**New events to handle:**
- `GROUP_ROSTER_UPDATE` - Detect 5→6 player transition
- `PLAYER_SPECIALIZATION_CHANGED` - Role changes
- `CHALLENGE_MODE_COMPLETED` - Keystone completions (update scores)
- Custom events from Communications module

### 9.3 Integration Strategy

**File:** Extend [`events/handlers.lua`](../../../events/handlers.lua:1)

```lua
-- MARK: Organizer Event Handlers

function EventHandlers:RegisterOrganizerEvents()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate_Organizer")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnSpecChange_Organizer")
end

function EventHandlers:OnGroupRosterUpdate_Organizer()
    -- Check if Organizer is active
    if NextKey222.Organizer and NextKey222.Organizer:IsActive() then
        NextKey222.Organizer:OnRosterChange()
    end
    
    -- Check if UI needs to switch modes
    if NextKey222.UI and NextKey222.UI.mainFrame then
        NextKey222.UI:OnRosterChange()
    end
end

function EventHandlers:OnSpecChange_Organizer(unit)
    if unit == "player" then
        -- Update current character's role data
        NextKey222.CharacterStorage:UpdateCurrentCharacterRoles()
    end
end
```

---

## 10. Testing Integration Points

### 10.1 Integration Test Suite

**File:** `debug/organizer_integration_tests.lua` (NEW)

```lua
function TestUIForkMechanism()
    -- Test 5→6 player transition
    -- Test 6→5 player transition
    -- Verify correct UI shown
end

function TestProfileServiceIntegration()
    -- Test GetOrganizerProfile()
    -- Verify enhanced data fields
    -- Test batch loading
    -- Verify cache behavior
end

function TestIOCalculatorIntegration()
    -- Test CalculatePlayerGain()
    -- Test CalculateGroupTotalGain()
    -- Verify memoization
    -- Compare results with existing calculations
end

function TestCommunicationsIntegration()
    -- Test organizer message sending
    -- Test message routing
    -- Verify throttling
    -- Test backward compatibility detection
end

function TestDataMigration()
    -- Test SavedVariables migration
    -- Verify no data loss
    -- Test first-time setup
end
```

### 10.2 Regression Test Checklist

**Before releasing Organizer, verify existing features still work:**

- [ ] 5-player keystone optimizer (existing UI)
- [ ] Dungeon preference management
- [ ] Loot tracking system
- [ ] Travel assistant
- [ ] IO tooltips
- [ ] RaiderIO integration
- [ ] LibOpenRaid integration
- [ ] Guild keystone sharing
- [ ] Slash commands
- [ ] Options panel
- [ ] Debug system

---

## 11. Performance Impact Analysis

### 11.1 Memory Overhead

**New persistent data:**
- Character storage: ~500 bytes per character
- 20 characters (current + alts): ~10KB
- Organizer UI (when active): ~50KB
- **Total new baseline:** ~60KB (acceptable)

**During active Organizer session:**
- 20 players × 8 dungeons × scores: ~5KB
- Temporary player cards: ~2KB each × 10 alts: ~20KB
- Roster state cache: ~10KB
- **Active session peak:** ~100KB (acceptable)

### 11.2 Performance Monitoring

**File:** Extend [`core/performance.lua`](../../../core/performance.lua:1)

```lua
-- Add Organizer profiling points
Performance.PROFILE_POINTS = {
    -- Existing points...
    
    -- New Organizer points
    ORGANIZER_INIT = "Organizer:Initialize",
    ORGANIZER_ROSTER_BUILD = "Organizer:BuildRoster",
    ORGANIZER_UI_RENDER = "Organizer:RenderUI",
    ORGANIZER_POLL_PROCESS = "Organizer:ProcessPoll",
    ORGANIZER_AUTO_DETECT = "Organizer:AutoDetect",
    ORGANIZER_OPTIMIZER_MODE1 = "Optimizer:Mode1",
    ORGANIZER_OPTIMIZER_MODE2 = "Optimizer:Mode2",
    ORGANIZER_OPTIMIZER_MODE3 = "Optimizer:Mode3"
}
```

---

## 12. Documentation Updates Required

### 12.1 User-Facing Documentation

**Files to update:**
- [ ] `README/USER_GUIDE.md` - Add Organizer section
- [ ] `README/SLASH_COMMANDS.md` - Document new commands
- [ ] `CHANGELOG.md` - Add v0.3.0 section

**New documentation to create:**
- [ ] `README/GROUP_ORGANIZER.md` - Complete feature guide
- [ ] `README/ORGANIZER_FAQ.md` - Common questions

### 12.2 Developer Documentation

**Files to update:**
- [ ] `Documentation/AI DOCS/DEVELOPMENT.md` - Add Organizer architecture
- [ ] `.kilocode/rules/memory-bank/architecture.md` - Update data flow
- [ ] `.kilocode/rules/memory-bank/tech.md` - New modules

---

## 13. Rollout Strategy

### 13.1 Phased Release Plan

**Phase 1: Internal Testing (v0.3.0-alpha)**
- Enable for guild members only
- Gather feedback on UI/UX
- Identify bugs in multi-group scenarios

**Phase 2: Public Beta (v0.3.0-beta)**
- Release to general users
- Monitor performance with large raids
- Collect usage analytics

**Phase 3: Stable Release (v0.3.0)**
- Full public release
- Deprecate compact mode
- Update all documentation

### 13.2 Feature Flag (Optional)

**For cautious rollout:**
```lua
-- In core/config.lua
defaults = {
    global = {
        features = {
            organizerEnabled = true, -- Can disable if issues found
        }
    }
}

-- In ui/main.lua
function NextKeyUI:DetermineUIMode()
    local groupSize = GetNumGroupMembers()
    
    if groupSize <= 5 then
        return "KEYSTONE_OPTIMIZER"
    elseif self.db.global.features.organizerEnabled then
        return "ROSTER_BOARD"
    else
        -- Fallback to compact mode if Organizer disabled
        return "COMPACT_MODE"
    end
end
```

---

## 14. Known Integration Risks

### 14.1 High-Risk Areas

**Risk 1: UI Mode Switching Mid-Session**
- **Impact:** Player drags card, someone leaves, drops to 5 players, UI rebuilds
- **Mitigation:** Save organizer state before switch, restore if returning to 6+

**Risk 2: ProfilesService Cache Invalidation**
- **Impact:** Organizer profiles cached separately from base profiles
- **Mitigation:** Unified cache invalidation system

**Risk 3: Communication Message Conflicts**
- **Impact:** Existing messages + new organizer messages = bandwidth issues
- **Mitigation:** Strict throttling, batch updates, priority system

### 14.2 Mitigation Strategies

**State Preservation:**
```lua
function Organizer:OnUIModeSwitchAway()
    -- Save current roster state
    self.savedState = {
        groups = self:SerializeGroups(),
        bench = self:SerializeBench(),
        optOut = self:SerializeOptOut(),
        timestamp = GetTime()
    }
    
    Debug:Dev("organizer", "Saved organizer state before UI switch")
end

function Organizer:OnUIModeSwitchBack()
    -- Restore roster state if saved recently
    if self.savedState and (GetTime() - self.savedState.timestamp) < 60 then
        self:RestoreGroups(self.savedState.groups)
        self:RestoreBench(self.savedState.bench)
        self:RestoreOptOut(self.savedState.optOut)
        
        Debug:Dev("organizer", "Restored organizer state after UI switch")
    end
end
```

---

## 15. Implementation Checklist

- [ ] Modify `ui/main.lua` for UI fork mechanism
- [ ] Add dynamic mode switching on roster changes
- [ ] Extend `core/profiles.lua` with GetOrganizerProfile()
- [ ] Extend `core/ioCalculator.lua` with Gain() and aggregate functions
- [ ] Implement memoization for IO calculations
- [ ] Extend `core/comms.lua` with organizer message types
- [ ] Add batch update system for roster sync
- [ ] Implement version detection for backward compatibility
- [ ] Add organizer event handlers to `events/handlers.lua`
- [ ] Create data migration logic in CharacterStorage
- [ ] Update `NextKey.toc` load order
- [ ] Add performance profiling points
- [ ] Create integration test suite
- [ ] Run regression tests on existing features
- [ ] Update user and developer documentation
- [ ] Test with 5→6 and 6→5 player transitions
- [ ] Test with mixed addon versions
- [ ] Verify memory footprint within acceptable limits

---

## 16. Dependencies for Next Phases

**Phase 1 (UI Framework) requires:**
- ✅ UI fork mechanism (Section 1)
- ✅ ProfilesService integration (Section 2)
- ✅ Communications integration (Section 4)

**Phase 2 (Survey) requires:**
- ✅ Communications integration (Section 4)
- ✅ Backward compatibility detection (Section 6)

**Phase 3 (Manual Mode) requires:**
- ✅ All integration points

**Phase 4 (Algorithms) requires:**
- ✅ IOCalculator integration (Section 3)
- ✅ ProfilesService integration (Section 2)

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** None (Phase 0 must complete first)  
**Next Document:** Phase 1 - UI Framework