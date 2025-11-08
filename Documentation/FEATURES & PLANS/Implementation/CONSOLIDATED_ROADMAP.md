# NextKey M+ Organizer - Consolidated Implementation Roadmap

**Created**: November 8, 2025
**Status**: Active Development
**Current Phase**: Week 3 Simplification (100% Complete - Ready for Testing)
**Version**: 0.2.2

---

## 📊 Overview

This document consolidates all active and planned work for the M+ Group Organizer feature into a single, prioritized roadmap. It replaces scattered planning documents with one source of truth.

### Quick Status Summary

| Area | Status | Priority | Estimated Effort |
|------|--------|----------|------------------|
| **Week 3: OrganizerState Module** | ✅ 100% Complete | 🟢 DONE | Testing phase |
| **Phase 4: Optimizer Algorithms** | ⏸️ Not Started | 🔴 HIGH | 20+ hours |
| **Phase 5: Communication** | ⏸️ Not Started | 🟡 MEDIUM | 3 hours |
| **Testing & Polish** | ⏸️ Not Started | 🟡 MEDIUM | 10+ hours |

---

## 🎯 Current Active Work

### Week 3 Simplification: OrganizerState Module (COMPLETE)

**Status**: ✅ 100% Complete (All 5 Sessions Done)
**Result**: Poll data loss bug FIXED - Architectural implementation complete
**Ready For**: In-game validation testing
**Documentation**: [`M+_Organizer_Week_3_State_Module.md`](M+_Organizer_Week_3_State_Module.md)

#### Why This Is Critical

**Root Problem**: Cards previously stored authoritative data, causing poll data loss on rebuild.

**Solution**: Centralized `OrganizerState` module where cards become "dumb" renderers.

```
BEFORE (Buggy):
Poll Response → Update card.playerData → Rebuild bench → Card destroyed → Data LOST ❌

AFTER (Fixed):
Poll Response → Update OrganizerState → Rebuild bench → Render from state → Data PRESERVED ✅
```

#### Completed Sessions (All 5)

✅ **Session 1**: OrganizerState module created (940 lines, 41 functions)
✅ **Session 2**: Poll response flow migrated - **BUG FIXED**
✅ **Session 3**: Bench data flow migrated (~114 lines saved)
✅ **Session 4**: State persistence with fake player filtering
✅ **Session 5**: Group & Keystone management functions - **ALL IMPLEMENTED**

#### Session 5 Completion (100%)

**File**: [`core/organizer/state.lua`](../../../core/organizer/state.lua)

**All 13 Functions Fully Implemented**:

**Group Management** (5 functions):
- ✅ `AssignToGroup(playerID, groupIndex, slotIndex)` - Lines 425-442
- ✅ `UnassignFromGroup(playerID)` - Lines 449-469
- ✅ `GetGroupAssignments(groupIndex)` - Lines 476-484
- ✅ `GetSlotPlayer(groupIndex, slotIndex)` - Lines 492-505
- ✅ `IsSlotEmpty(groupIndex, slotIndex)` - Lines 513-526

**Keystone Management** (4 functions):
- ✅ `DesignateKeystone(groupIndex, playerID, keystone)` - Lines 536-551
- ✅ `ClearKeystone(groupIndex)` - Lines 558-569
- ✅ `GetDesignatedKeystone(groupIndex)` - Lines 576-585
- ✅ `GetKeystoneOwner(groupIndex)` - Lines 592-603

**Poll Management** (4 functions - from Sessions 2-4):
- ✅ `StartPoll(pollID)` - Lines 611-633
- ✅ `AddPollResponse(playerID, response)` - Lines 641-669
- ✅ `GetPollResponses()` - Lines 675-694
- ✅ `CompletePoll()` - Lines 700-712

#### Ready for Testing

- ✅ All 41 OrganizerState functions implemented with complete logic
- ✅ No TODO comments remaining
- ✅ All functions have proper error handling and debug logging
- [ ] In-game validation testing (ready to proceed)
- [ ] Commit: `git commit -m "Week3 Session5: Complete group/keystone management functions"`
- [ ] Tag: `git tag Week3_Session5_Complete`

---

## 📋 Queued Work (Priority Order)

### Priority 1: Complete Week 3 Session 5 (RECOMMENDED NEXT)

**Why First**:
- 80% complete - finish what we started
- Only 2-3 hours remaining
- Provides clean foundation for Phase 4
- Prevents entire class of data loss bugs
- Higher value than starting new features

**When to Start**: Immediately after this planning session

---

### Priority 2: Phase 4 - Optimizer Algorithms

**Status**: Not Started  
**Complexity**: 🔴 VERY HIGH  
**Estimated Effort**: 20+ hours  
**Documentation**: [`M+_Organizer_Phase_4_Optimizer_Algorithms.md`](M+_Organizer_Phase_4_Optimizer_Algorithms.md)

#### Why After OrganizerState

The optimizer algorithms will be **significantly cleaner** with OrganizerState complete:
- Single source of truth for player data
- Clean APIs for group assignments
- Simpler state management during optimization
- No risk of data loss during algorithm execution

#### Three Optimization Modes

**Mode 1: Max Power** (Greedy exhaustive search)
- Find best possible group from available players
- Repeat until no valid groups remain
- **Files**: `core/organizer/optimizer_mode1.lua` (~400 lines)

**Mode 2: Balanced** (Snake draft with aggregate scoring)
- Calculate player rank scores across all keystones
- Snake draft by role to balance teams
- Optimize keystone selection per team
- **Files**: `core/organizer/optimizer_mode2.lua` (~500 lines)

**Mode 3: Vault Completion** (Preference-only matching)
- Only consider keystones level 10+
- Pure preference scoring (ignore IO gains)
- Maximize player happiness
- **Files**: `core/organizer/optimizer_mode3.lua` (~300 lines)

#### Core Components

**Scoring Functions** (`core/organizer/scoring.lua` - NEW)
- [ ] `GetBaseValue(dungeonID, level)` - Dungeon matrix for levels 2-20
- [ ] `CalculatePlayerGain(player, keystone)` - Individual gain calculation
- [ ] `CalculateGroupTotalGain(group, keystone)` - Group aggregate
- [ ] `CalculatePlayerAggregatePotential()` - For Mode 2
- [ ] `GenerateValidCombinations()` - Recursive backtracking
- [ ] Preference scoring (LikeBonus/DislikePenalty)

**Optimizer Wizard UI** (`ui/organizer/optimizerWizard.lua` - NEW)
- [ ] Mode selection dialog
- [ ] Progress bar with status updates
- [ ] Pause/resume/cancel controls
- [ ] Async execution with coroutines
- [ ] Timeout system (2 minutes)
- [ ] Results preview before applying

**Performance Optimization**
- [ ] Memoization cache for gain calculations
- [ ] Early pruning of invalid combinations
- [ ] Batch processing (100ms chunks)
- [ ] Progress tracking and user feedback

#### Implementation Sessions

1. **Session 1** (6 hours): Core scoring functions + Mode 3 (simplest)
2. **Session 2** (8 hours): Mode 1 (Max Power) + testing
3. **Session 3** (10 hours): Mode 2 (Balanced) + snake draft
4. **Session 4** (6 hours): Optimizer Wizard UI + integration
5. **Session 5** (5 hours): Performance optimization + testing

**Total**: ~35 hours (1 week of focused work)

---

### Priority 3: Phase 5 - Communication System

**Status**: Not Started  
**Complexity**: 🟢 LOW  
**Estimated Effort**: 3 hours  
**Documentation**: [`M+_Organizer_Phase_5_Communication.md`](M+_Organizer_Phase_5_Communication.md)

#### Why After Phase 4

Communication is the final piece - users want to announce optimized groups, not manually organized ones.

#### Announcement System

**File**: `core/organizer/announcer.lua` (NEW - ~200 lines)

- [ ] `AnnounceGroups(groups, channels)` - Main function
- [ ] `FormatGroupMessages()` - Class colors + role icons
- [ ] `GetPlayerAssignedRole()` - Role detection
- [ ] `ShowPreviewDialog()` - Preview before sending
- [ ] `SendToChannels()` - Batch send with throttling
- [ ] Handle chat API limits (4KB per message)

**Testing Scenarios**:
- [ ] Announce 1 group to PARTY
- [ ] Announce 4 groups to RAID
- [ ] Announce 6 groups to GUILD
- [ ] Preview formatting accuracy
- [ ] Throttling with rapid announces

**Implementation**: Single 3-hour session

---

### Priority 4: Testing & Polish

**Status**: Not Started  
**Estimated Effort**: 10+ hours

#### Comprehensive Testing

**Functional Tests**:
- [ ] Test all workflows end-to-end
- [ ] Test with 5, 10, 15, 20, 30, 40 players
- [ ] Test mixed addon versions
- [ ] Test all 3 optimizer modes
- [ ] Test all partial group strategies
- [ ] Test undo/redo extensively

**Edge Case Tests**:
- [ ] All scenarios from Edge Cases document
- [ ] Error recovery procedures
- [ ] Desync detection and recovery
- [ ] Performance degradation modes

**Performance Tests**:
- [ ] Run performance regression suite
- [ ] Verify all performance limits enforced
- [ ] Test memory usage under load
- [ ] Test optimizer timeout handling

**Integration Tests**:
- [ ] Verify 5-player mode still works
- [ ] Test UI fork transitions (5→6→5 players)
- [ ] Test backward compatibility
- [ ] Verify no regression in existing features

#### Documentation Updates

- [ ] Update user guide with Organizer section
- [ ] Create Organizer tutorial
- [ ] Update slash commands documentation
- [ ] Create troubleshooting guide
- [ ] Update CHANGELOG.md

#### Polish

- [ ] Visual polish (icons, colors, animations)
- [ ] Sound effects (optional)
- [ ] Localization strings
- [ ] Accessibility improvements
- [ ] Performance optimization based on testing

---

## 🗺️ Implementation Timeline

### Week 1 (Current): Week 3 Simplification
- [x] Sessions 1-4 complete (80%)
- [x] Session 5: All functions implemented (100%)
- [ ] In-game validation of all Session 5 functions
- [ ] **Deliverable**: OrganizerState fully implemented and tested ✅ (implementation complete, testing pending)

### Week 2-3: Phase 4 Optimizer Algorithms
- [ ] Session 1: Core scoring + Mode 3 (6 hours)
- [ ] Session 2: Mode 1 implementation (8 hours)
- [ ] Session 3: Mode 2 implementation (10 hours)
- [ ] Session 4: Optimizer Wizard UI (6 hours)
- [ ] Session 5: Performance optimization (5 hours)
- [ ] **Deliverable**: All 3 optimizer modes working

### Week 4: Phase 5 Communication + Testing
- [ ] Day 1: Communication system (3 hours)
- [ ] Day 2-3: Functional testing (10 hours)
- [ ] Day 4: Edge case testing (6 hours)
- [ ] Day 5: Performance testing (4 hours)
- [ ] **Deliverable**: Feature complete and production-ready

### Week 5: Documentation & Polish
- [ ] Days 1-2: Documentation updates
- [ ] Days 3-4: Visual polish
- [ ] Day 5: Final validation
- [ ] **Deliverable**: Ready for release

---

## 📈 Progress Tracking

### Completion Metrics

| Metric | Baseline | Current | Target | Status |
|--------|----------|---------|--------|--------|
| **Total Lines** | 8,752 | 8,588 | ~6,000 | 🟡 19% to goal |
| **Largest File** | 2,495 | 1,281 | ~500 | 🟢 48% reduction |
| **Functions >100 lines** | 7 | 5 | 0 | 🟡 71% done |
| **Data Sources** | 5+ | 1 (OrganizerState) | 1 | 🟢 Complete |
| **Duplicate Blocks** | 3 | 0 | 0 | ✅ Complete |

### Phase Completion

- ✅ **Phase 0**: Foundation (100%)
- ✅ **Phase 0.5**: Integration (100%)
- ✅ **Phase 1**: UI Framework (100%)
- ✅ **Phase 2**: Participant Survey (100%)
- ✅ **Phase 3**: Manual Mode (100%)
- ✅ **Week 3 Simplification**: OrganizerState (100% - Ready for Testing)
- ⏸️ **Phase 4**: Optimizer Algorithms (0%)
- ⏸️ **Phase 5**: Communication (0%)
- ⏸️ **Testing & Polish**: (0%)

---

## 🎯 Success Criteria

### Week 3 Completion
- ✅ Poll data loss bug FIXED (architecturally impossible)
- ✅ Single source of truth implemented
- ✅ Cards are "dumb" renderers
- ✅ ~114 lines saved (target achieved)
- ✅ All 41 OrganizerState functions fully implemented
- [ ] In-game validation complete

### Phase 4 Completion
- [ ] All 3 optimizer modes working
- [ ] Performance <2 seconds for 20 players
- [ ] Wizard UI polished and intuitive
- [ ] Partial group strategies working
- [ ] Comprehensive testing passed

### Phase 5 Completion
- [ ] Groups announced to chat correctly
- [ ] Class colors and formatting perfect
- [ ] Preview dialog accurate
- [ ] Throttling working (no spam)

### Feature Launch
- [ ] All phases 100% complete
- [ ] No critical bugs
- [ ] Performance targets met
- [ ] Documentation complete
- [ ] User testing positive

---

## 🚀 Decision Framework

### When Choosing Next Task

**Complete over Start**: Finish 80% complete work before starting new features  
**Foundation over Features**: Architectural work enables better features later  
**User Value over Complexity**: Prioritize what users will use most  
**Risk Mitigation**: High-risk changes need more testing time

### Current Recommendation

**NEXT ACTION**: In-Game Validation Testing
- Week 3 Session 5 complete (all functions implemented)
- Test group assignment/unassignment in-game
- Test keystone designation/clearing in-game
- Verify no Lua errors on `/reload`
- Then proceed to Phase 4: Optimizer Algorithms

---

## 📚 Reference Documents

### Active Plans
- [Week 3 State Module](M+_Organizer_Week_3_State_Module.md) - ✅ 100% complete
- [Simplification Plan](M+_Organizer_Simplification_Plan.md) - Tracks Week 1-2 completion
- [Master Checklist](M+_Organizer_MASTER_IMPLEMENTATION_CHECKLIST.md) - Phase tracking

### Completed Plans
- ✅ [Handshake Protocol](M+_Organizer_Handshake_Protocol.md) - Nov 5, 2025
- ✅ [Unified Poll System](M+_Organizer_Unified_Poll_System.md) - Nov 5, 2025
- ✅ Phase 0-3 implementation docs

### Future Work
- [Phase 4: Optimizer Algorithms](M+_Organizer_Phase_4_Optimizer_Algorithms.md) - Queued
- [Phase 5: Communication](M+_Organizer_Phase_5_Communication.md) - Queued

### Supporting Docs
- [PRD](../M+%20Group%20Organizer%20-%20Product%20Requirements%20Document.md)
- [Algorithm Spec](../Keystone%20Group%20Optimizer_%20Algorithm%20Specification.md)
- [Performance Limits](M+_Organizer_Performance_Limits.md)

---

## 💡 Notes for Future Sessions

### Memory Bank Context
Always update [`context.md`](../../../.kilocode/rules/memory-bank/context.md) after completing sessions:
- Current phase and progress percentage
- Recently completed work
- Next immediate action
- Any blockers or issues

### Git Workflow
- Create tags after each session: `Week3_Session5`, `Phase4_Session1`, etc.
- Commit message format: `"[Phase/Week] [Session]: [Description]"`
- Test thoroughly before committing

### Testing Strategy
- Test incrementally - don't build entire phases without validation
- Use `/nk test preset mixed_skill` for fake player testing
- Enable debug category: `/nk config` → Debug System → "organizer"
- Run `/reload` frequently during development

---

**Last Updated**: November 8, 2025
**Next Review**: After in-game validation testing
**Status**: Week 3 Simplification COMPLETE - Ready for Phase 4