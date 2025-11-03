# M+ Group Organizer Simplification Plan

**Status**: Planning Phase  
**Created**: November 2, 2025  
**Goal**: Reduce organizer codebase from 8,752 lines to ~6,000 lines (31% reduction) while improving maintainability and preventing bugs like the poll data reset issue.

---

## Progress Tracker

### Overall Status
- [x] **Phase 0**: Architecture Audit Complete
- [-] **Week 1**: Quick Wins (LOW RISK) - IN PROGRESS
- [ ] **Week 2**: Structural Improvements (MEDIUM RISK)
- [ ] **Week 3-4**: Architectural Evolution (HIGH RISK, OPTIONAL)

### Current Metrics
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Total Lines** | 8,653 (-99) | ~6,000 | 🟡 Week 1 Started |
| **Largest File** | 2,396 (-99) | ~500 | 🟡 Week 1 Started |
| **Duplicate Logic** | ~301 lines (-99) | ~50 lines | 🟡 Task 1.1 Complete |
| **Data Ownership** | Unclear (5+ formats) | Single source | 🔴 Not Started |

---

## Executive Summary

### Root Cause of Poll Data Bug

The poll data reset bug occurred because **cards were treated as the source of truth** instead of **displays of the truth**. When `RebuildBenchAfterPoll()` cleared cards to "refresh" them, poll data was lost.

**Design Principle Violation**:
```
❌ WRONG: card.playerData is authoritative
         └─> Rebuild functions preserve card data
         └─> Complex preservation logic fails
         └─> Data loss bugs

✅ RIGHT: Central state is authoritative
         └─> Cards render from state
         └─> Simple re-render
         └─> Can't lose data
```

### Key Complexity Findings

1. **Massive Functions**: 7 functions over 100 lines
2. **Code Duplication**: RefreshAllCards() has identical 40-line blocks repeated 3x
3. **Data Redundancy**: Poll responses stored in 4 different locations
4. **Unclear Ownership**: Player data exists in 5+ formats across modules
5. **Over-Engineering**: Animation queue module for single use case

---

## Week 1: Quick Wins (LOW RISK)

**Timeline**: 5 days  
**Expected Savings**: ~400 lines  
**Risk Level**: 🟢 Very Low

### Tasks

#### Task 1.1: Extract RefreshCard() Helper ✅ COMPLETE
- **File**: `ui/organizer/rosterBoard.lua`
- **Lines Affected**: 2365-2449 (85 lines after refactoring)
- **Savings**: 99 lines (127 → 28 for RefreshAllCards)
- **Difficulty**: Easy
- **Testing**: Verify card refresh after spec changes
- **Completed**: November 2, 2025

**Before** (114 duplicate lines):
```lua
-- Block 1: Bench cards (37 lines)
for _, card in ipairs(self.benchCards) do
    local profile = GetProfile(card.playerData.id)
    card.playerData.class = profile.class
    card.playerData.roles = {profile.role}
    -- ... 30 more identical lines
end

-- Block 2: Slot cards (39 lines) - SAME LOGIC
-- Block 3: Opt-out cards (38 lines) - SAME LOGIC
```

**After** (15 lines):
```lua
function RosterBoard:RefreshCard(card, displayMode)
    local profile = NextKey222.ProfilesService:GetProfile(card.playerData.id)
    if not profile then return end
    
    -- Update card data (30 lines)
    card.playerData.class = profile.class
    card.playerData.roles = {profile.role}
    card.playerData.specName = profile.specName
    -- ... rest of update logic
    
    NextKey222.PlayerCard:UpdateCardContent(card, displayMode)
end

-- Use helper (3 lines each location)
for _, card in ipairs(self.benchCards) do
    self:RefreshCard(card, "compact")
end
```

**Checklist**:
- [x] Extract RefreshSingleCard() helper function
- [x] Replace bench card refresh logic
- [x] Replace slot card refresh logic
- [x] Replace opt-out card refresh logic
- [x] Test spec change detection
- [x] Test card visual updates
- [x] In-game validation complete (November 2, 2025)

---

#### Task 1.2: Merge Spec Generation Functions ⏳ Not Started
- **File**: `core/organizer/playerDataBuilder.lua`
- **Lines Affected**: 32-261 (224 lines total)
- **Savings**: ~100 lines
- **Difficulty**: Easy
- **Testing**: Verify tooltips and poll simulation

**Current**:
- `GenerateDefaultSpecPreferences()` - 121 lines (32-152) - Pre-poll tooltips
- `GenerateRealisticPollResponse()` - 103 lines (159-261) - Poll simulation

**Proposed**:
```lua
function PlayerDataBuilder:GenerateSpecPreferences(playerName, options)
    options = options or {}
    local randomize = options.randomize or false
    local currentSpecOnly = options.currentSpecOnly or false
    
    -- Unified logic (~120 lines instead of 224)
    -- Get specs
    -- Map to roles
    -- Apply randomization if requested
    -- Format output
end
```

**Checklist**:
- [ ] Create unified GenerateSpecPreferences() function
- [ ] Add options parameter for randomization
- [ ] Update calls in rosterBoard.lua (lines 412-430, 481-502)
- [ ] Update calls in pollSimulator.lua
- [ ] Test tooltip spec display
- [ ] Test poll simulation responses
- [ ] Remove old functions after verification

---

#### Task 1.3: Remove Animation Queue Module ⏳ Not Started
- **File**: `core/organizer/animationQueue.lua`
- **Lines Affected**: Entire module (~150 lines)
- **Savings**: ~150 lines
- **Difficulty**: Medium
- **Testing**: Verify Sort button still animates correctly

**Current**: Dedicated module with queue system

**Proposed**: Inline into `core/organizer/sorting.lua`:
```lua
function Sorting:ExecuteAssignmentPlan(plan, onComplete)
    local currentIndex = 1
    
    local function ProcessNext()
        if currentIndex > #plan then
            onComplete()
            return
        end
        
        local assignment = plan[currentIndex]
        MoveCardWithAnimation(assignment.card, assignment.slot, function()
            currentIndex = currentIndex + 1
            C_Timer.After(0.1, ProcessNext)
        end)
    end
    
    ProcessNext()
end
```

**Checklist**:
- [ ] Inline animation logic into sorting.lua
- [ ] Update OnSortClicked() in rosterBoard.lua (lines 995-1037)
- [ ] Test Sort button visual feedback
- [ ] Test completion callback
- [ ] Remove animationQueue.lua file
- [ ] Update NextKey.toc to remove file reference

---

#### Task 1.4: Extract Card Rendering Helpers ⏳ Not Started
- **File**: `ui/organizer/playerCard.lua`
- **Lines Affected**: Multiple render functions
- **Savings**: ~50 lines
- **Difficulty**: Easy
- **Testing**: Verify all 3 display modes render correctly

**Proposed**:
```lua
-- Common rendering helpers
local function RenderPlayerName(card, playerData, config)
    -- Shared name rendering logic
end

local function RenderClassIndicator(card, playerData, config)
    -- Shared class rendering logic
end

-- Reduce duplication across CreateCompactContent, CreateExpandedContent, CreateOptOutContent
```

**Checklist**:
- [ ] Identify common rendering patterns
- [ ] Extract helper functions
- [ ] Update CreateCompactContent()
- [ ] Update CreateExpandedContent()
- [ ] Update CreateOptOutContent()
- [ ] Test compact mode (bench)
- [ ] Test expanded mode (slots)
- [ ] Test opt_out mode

---

### Week 1 Completion Criteria
- [ ] All 4 tasks completed
- [ ] ~400 lines of code removed
- [ ] All tests passing
- [ ] No behavior changes
- [ ] Code review approved

---

## Week 2: Structural Improvements (MEDIUM RISK)

**Timeline**: 5 days  
**Expected Savings**: ~600 lines  
**Risk Level**: 🟡 Medium

### Tasks

#### Task 2.1: Split rosterBoard.lua ⏳ Not Started
- **Current**: 2,495 lines in one file
- **Target**: 5 files of ~300-500 lines each
- **Savings**: ~500 lines through better organization
- **Difficulty**: Hard
- **Testing**: Full integration testing required

**Proposed Structure**:
```
ui/organizer/
    rosterBoard.lua             (Main orchestration - 400 lines)
    modules/
        benchManager.lua        (Bench operations - 300 lines)
        slotManager.lua         (Slot operations - 350 lines)
        cardMovement.lua        (Drag/drop, animations - 400 lines)
        keystoneManager.lua     (Keystone designation - 200 lines)
```

**Functions to Move**:

**benchManager.lua**:
- GetBenchPlayers()
- PopulateBench()
- AddPlayerToBench()
- RemovePlayerFromBench()
- LayoutBench()
- CreateNativeBenchColumn()

**slotManager.lua**:
- CreateActivePoolSection()
- CreateFlatRoleSlot()
- PlaceCardInSlot()
- PopulateOptOut()
- PlaceCardInOptOut()
- LayoutOptOut()

**cardMovement.lua**:
- DetectDropTarget()
- HandleCardDrop()
- MarkCardForRemoval()
- CompleteCardRemoval()
- AnimateRejection()
- CanPlayerFillRole()
- FindCompatibleSlotInGroup()

**keystoneManager.lua**:
- DesignateGroupKeystone()
- ClearGroupKeystone()
- IsKeystoneDesignated()
- UpdateGroupHeader()
- HighlightKeystoneButton()
- UnhighlightKeystoneButton()

**Checklist**:
- [ ] Create module directory structure
- [ ] Create benchManager.lua with stub functions
- [ ] Create slotManager.lua with stub functions
- [ ] Create cardMovement.lua with stub functions
- [ ] Create keystoneManager.lua with stub functions
- [ ] Move functions one module at a time
- [ ] Update rosterBoard.lua to use modules
- [ ] Test bench operations
- [ ] Test slot operations
- [ ] Test drag/drop
- [ ] Test keystone designation
- [ ] Full regression test

---

#### Task 2.2: Simplify Two-Phase Card Removal ⏳ Not Started
- **File**: `ui/organizer/rosterBoard.lua` (cardMovement.lua after split)
- **Lines Affected**: 1653-1808 (155 lines)
- **Savings**: ~60 lines
- **Difficulty**: Medium
- **Testing**: Test rejection animations, valid drops

**Current**: Mark for removal → Validate → Complete or Reject

**Proposed**: Validate → Remove → Place
```lua
function RosterBoard:HandleCardDrop(card, dropTarget)
    -- Validate FIRST
    if not self:IsValidDrop(card, dropTarget) then
        self:AnimateRejection(card)
        return
    end
    
    -- Then execute (no phases needed)
    self:RemoveFromSource(card)
    self:PlaceInTarget(card, dropTarget)
end
```

**Checklist**:
- [ ] Create IsValidDrop() validation function
- [ ] Refactor HandleCardDrop() to validate first
- [ ] Remove MarkCardForRemoval() function
- [ ] Remove CompleteCardRemoval() function
- [ ] Simplify AnimateRejection() (no restoration needed)
- [ ] Test role validation
- [ ] Test slot occupancy validation
- [ ] Test rejection animation
- [ ] Test successful drops

---

#### Task 2.3: Standardize Card Location Tracking ⏳ Not Started
- **Files**: Multiple
- **Savings**: ~40 lines
- **Difficulty**: Easy
- **Testing**: Test card movement between all locations

**Current**: 3 different formats
```lua
card.location = "bench"  -- String
card.location = {type = "role_slot", groupIndex = 1}  -- Table
-- Implicit from array membership
```

**Proposed**: Always use table format
```lua
card.location = {
    type = "bench" | "role_slot" | "opt_out",
    groupIndex = nil | number,
    slotIndex = nil | number
}
```

**Checklist**:
- [ ] Update PlaceCardInBench() to use table format
- [ ] Update PlaceCardInSlot() to use table format
- [ ] Update PlaceCardInOptOut() to use table format
- [ ] Update all location checks to use table format
- [ ] Remove string location checks
- [ ] Test bench placement
- [ ] Test slot placement
- [ ] Test opt-out placement

---

### Week 2 Completion Criteria
- [ ] All 3 tasks completed
- [ ] rosterBoard.lua split into modules
- [ ] Two-phase removal simplified
- [ ] Location tracking standardized
- [ ] ~600 lines of code removed or better organized
- [ ] Full regression test passing
- [ ] Code review approved

---

## Week 3-4: Architectural Evolution (HIGH RISK, OPTIONAL)

**Timeline**: 10 days  
**Expected Savings**: ~800 lines + future bug prevention  
**Risk Level**: 🔴 High

### Tasks

#### Task 3.1: Create OrganizerState Module ⏳ Not Started
- **New File**: `core/organizer/state.lua`
- **Impact**: Entire organizer architecture
- **Savings**: ~200 lines + preventing entire class of bugs
- **Difficulty**: Very Hard
- **Testing**: Comprehensive regression testing

**Purpose**: Single source of truth for all organizer data

**Proposed API**:
```lua
OrganizerState = {
    -- Data
    players = {},        -- {[playerID] = playerData}
    groups = {},         -- {[groupIndex][slotIndex] = playerID}
    keystones = {},      -- {[groupIndex] = {keystone, playerID}}
    activePoll = nil,    -- Current poll state
    
    -- Player Management
    GetPlayer(playerID),
    UpdatePlayer(playerID, data),
    UpdatePlayerFromPollResponse(playerID, response),
    
    -- Group Management
    AssignToGroup(playerID, groupIndex, slotIndex),
    RemoveFromGroup(groupIndex, slotIndex),
    GetGroupAssignments(groupIndex),
    
    -- Keystone Management
    DesignateKeystone(groupIndex, playerID, keystone),
    ClearKeystone(groupIndex),
    GetDesignatedKeystone(groupIndex),
}
```

**Checklist**:
- [ ] Create state.lua module structure
- [ ] Implement player management functions
- [ ] Implement group management functions
- [ ] Implement keystone management functions
- [ ] Migrate data from scattered locations to OrganizerState
- [ ] Update rosterBoard to use OrganizerState
- [ ] Update survey.lua to use OrganizerState
- [ ] Update playerDataBuilder to use OrganizerState
- [ ] Make cards "dumb" renderers (no authoritative data)
- [ ] Test poll response flow
- [ ] Test group assignment flow
- [ ] Test keystone designation flow
- [ ] Full regression test

---

#### Task 3.2: Redesign Poll Data Flow ⏳ Not Started
- **Files**: survey.lua, rosterBoard.lua, surveyDialog.lua
- **Impact**: Core poll mechanism
- **Savings**: ~200 lines
- **Difficulty**: Very Hard
- **Testing**: Poll simulation with fake players

**Current Flow** (7 touch points):
```
Poll Request → activePoll.responses → ProcessResponse →
FindCard → Update card.playerData → Maybe rebuild → Layout
```

**Proposed Flow** (3 touch points):
```
Poll Request → OrganizerState:UpdatePlayer →
RosterBoard:InvalidateCard → PlayerCard:Render
```

**Key Changes**:
- Poll responses update OrganizerState directly
- Cards render from OrganizerState, not from card.playerData
- No preservation needed
- No rebuild needed
- Data loss impossible

**Checklist**:
- [ ] Refactor ProcessResponse() to update OrganizerState
- [ ] Create InvalidateCard() function
- [ ] Update PlayerCard rendering to use OrganizerState
- [ ] Remove preservation logic from GetBenchPlayers()
- [ ] Remove RebuildBenchAfterPoll() (already removed, verify)
- [ ] Test poll with fake players
- [ ] Test poll with real players
- [ ] Test poll timeout
- [ ] Test partial responses
- [ ] Verify data never lost

---

#### Task 3.3: Evaluate characterStorage vs ProfilesService ⏳ Not Started
- **Files**: core/characterStorage.lua, core/profiles.lua
- **Impact**: Data source consolidation
- **Savings**: TBD (potentially 200+ lines if merged)
- **Difficulty**: Hard
- **Testing**: Character selection, profile data accuracy

**Analysis Needed**:
1. Document exact overlap between systems
2. Identify unique functionality in each
3. Decide: Merge or Document Separation?

**If Merge**:
- Move character storage into ProfilesService
- Update all references to use unified API
- Remove duplicate functionality

**If Separate**:
- Document clear separation of concerns
- Add comments explaining when to use each
- Ensure no duplicate data storage

**Checklist**:
- [ ] Document characterStorage functionality
- [ ] Document ProfilesService functionality
- [ ] Identify 60% overlap areas
- [ ] Make merge/separate decision
- [ ] If merging: Create migration plan
- [ ] If separating: Add documentation
- [ ] Update all callers if needed
- [ ] Test character selection
- [ ] Test profile data retrieval
- [ ] Test spec changes

---

#### Task 3.4: ProcessResponse() Refactor ⏳ Not Started
- **File**: core/organizer/survey.lua
- **Lines Affected**: 132-333 (202 lines)
- **Savings**: ~120 lines
- **Difficulty**: Hard
- **Testing**: Poll flow with all response types

**Current**: Massive 202-line function that does everything

**Proposed**: Break into focused functions
```lua
function Survey:ProcessResponse(response, sender)
    -- Validate (10 lines)
    -- Update state (5 lines)
    -- Invalidate card (5 lines)
    -- Handle alts if needed (10 lines)
end

function Survey:ValidateResponse(response)
    -- Validation logic (20 lines)
end

function Survey:HandleAltCharacterResponse(response)
    -- Alt handling logic (30 lines)
end
```

**Checklist**:
- [ ] Extract ValidateResponse()
- [ ] Extract HandleAltCharacterResponse()
- [ ] Simplify ProcessResponse() to orchestration
- [ ] Remove direct card manipulation
- [ ] Use OrganizerState for data updates
- [ ] Test Phase 1 responses (participation)
- [ ] Test Phase 2 responses (character selection)
- [ ] Test Phase 3 responses (spec preferences)
- [ ] Test alt character responses

---

### Week 3-4 Completion Criteria
- [ ] OrganizerState module created and integrated
- [ ] Poll data flow redesigned
- [ ] characterStorage/ProfilesService evaluated
- [ ] ProcessResponse() refactored
- [ ] ~800 lines saved
- [ ] Poll data loss bug **impossible**
- [ ] Full regression test passing
- [ ] Code review approved
- [ ] Architecture documented

---

## Testing Strategy

### Quick Wins Testing (Week 1)
- Unit tests for extracted helpers
- Visual verification of card rendering
- Spec change detection test
- Poll simulation test

### Structural Testing (Week 2)
- Integration tests for module interactions
- Drag/drop regression test
- Poll flow regression test
- Keystone designation test

### Architectural Testing (Week 3-4)
- Comprehensive poll simulation
- State management unit tests
- Data flow integration tests
- Memory leak checks
- Performance benchmarks

---

## Risk Mitigation

### Version Control Strategy
- Create feature branch for each week
- Commit after each completed task
- Tag working states for easy rollback

### Rollback Plan
- Keep original code commented out initially
- Test thoroughly before deletion
- Maintain backup branch before merge

### Communication
- Update this document after each session
- Note any issues or blockers
- Document deviations from plan

---

## Session Log

### Session 1: November 2, 2025
**Duration**: Architecture Audit
**Status**: ✅ Complete
**Achievements**:
- Analyzed 8,752 lines across 12 files
- Identified root cause of poll data bug
- Created 3-phase refactoring plan
- Documented 9 simplification opportunities

**Next Session**: Begin Week 1, Task 1.1 (RefreshCard helper)

---

### Session 2: November 2, 2025
**Duration**: Task 1.1 Implementation & Testing
**Status**: ✅ Complete
**Achievements**:
- Implemented RefreshCard() helper function
- Reduced RefreshAllCards() from 127 lines to 28 lines (99 line reduction)
- Eliminated 114 lines of duplicate code across bench/slot/opt-out refresh logic
- In-game validation successful after debugging
- All card refresh functionality working correctly

**Issues Resolved**:
- Fixed initial implementation bugs during in-game testing
- Verified spec change detection works properly
- Confirmed visual updates render correctly

**Next Session**: Task 1.2 (Merge Spec Generation Functions)

---

## Notes & Decisions

### Design Decisions
- **Cards are displays, not data**: State lives in OrganizerState, cards render it
- **Validate before mutate**: Check drop validity before removing card from source
- **Data-driven rendering**: Use configs and tables instead of duplicate code
- **Module organization**: Group by feature, not by type

### Open Questions
1. Should characterStorage be merged into ProfilesService? (Decide in Week 3)
2. Is animation queue complexity worth it? (Decision: No, removing in Week 1)
3. How to handle backward compatibility? (Decision: Internal refactor, no breaking changes)

---

## Success Metrics

| Metric | Baseline | Week 1 Target | Week 2 Target | Week 3-4 Target | Status |
|--------|----------|---------------|---------------|-----------------|--------|
| **Total Lines** | 8,752 | 8,352 | 7,752 | 6,000 | 8,752 |
| **Largest File** | 2,495 | 2,395 | 500 | 500 | 2,495 |
| **Functions >100 lines** | 7 | 4 | 2 | 0 | 7 |
| **Data Sources** | 5+ | 5+ | 3 | 1 | 5+ |
| **Duplicate Blocks** | 3 | 0 | 0 | 0 | 3 |

---

## References

### Key Files
- `ui/organizer/rosterBoard.lua` (2,495 lines)
- `core/organizer/survey.lua` (451 lines)
- `core/organizer/playerDataBuilder.lua` (694 lines)
- `ui/organizer/playerCard.lua` (756 lines)

### Related Documentation
- [M+ Organizer Phase 2 Implementation](M+_Organizer_Phase_2_Participant_Survey.md)
- [M+ Organizer State Management](M+_Organizer_State_Management.md)
- [Architecture Update](../../PHASE_6_DOCUMENTATION/Architecture_Update_Ace3_Patterns.md)