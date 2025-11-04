# NextKey Current Context

## Current Status
**Date**: November 4, 2025
**Version**: 0.2.2
**Current Phase**: Planning Week 3 Simplification - OrganizerState Module
**Next Action**: Begin Session 1 implementation

## Recent Completions

### Week 2 Simplification (Nov 3-4) ✅
- Split `rosterBoard.lua` into 5 specialized modules (540 lines saved, -26% size)
- **New Modules**:
  - `ui/organizer/modules/benchManager.lua` (462 lines) - Bench operations
  - `ui/organizer/modules/slotManager.lua` (411 lines) - Slot creation/layout
  - `ui/organizer/modules/cardMovement.lua` (422 lines) - Drag/drop validation
  - `ui/organizer/modules/keystoneManager.lua` (215 lines) - **FULL IMPLEMENTATION** ✅
- Modular architecture prevents data loss bugs
- **Total simplification**: 917 lines saved across Week 1+2

### M+ Organizer Progress ✅
- Phase 0: Foundation COMPLETE
- Phase 0.5: Integration COMPLETE
- Phase 1: UI Framework COMPLETE (native frames)
- Phase 2: Participant Survey COMPLETE (3-phase poll with spec preferences)
- **Phase 3: Manual Mode 100% COMPLETE** ✅
  - Drag-and-drop: COMPLETE
  - Sequential sorting: COMPLETE (animationQueue + sorting algorithm)
  - Keystone designation: COMPLETE (keystoneManager.lua fully implemented)

## Active Work

### Week 3 Simplification: OrganizerState Module (PLANNED)

**Decision Made**: November 4, 2025 - Chosen over Phase 5 Communication and Phase 4 Optimizer

**Timeline**: 10 days (5 implementation sessions)  
**Risk Level**: 🔴 HIGH - Architectural refactor  
**Expected Outcome**: ~200 lines saved + poll data loss bug prevention  

**Core Problem Identified**:
- Cards currently store authoritative data (`card.playerData`)
- Rebuild operations can lose poll response data
- Bug: Poll responses → `card.playerData` → rebuild bench → data LOST ❌

**Solution Architecture**:
- Create centralized [`OrganizerState`](core/organizer/state.lua) module
- Cards become "dumb" renderers (only store `playerID`)
- All data lives in `OrganizerState.players[playerID]`
- Rebuild operations cannot lose data (architecturally impossible) ✅

**Implementation Sessions**:
1. **Session 1** (Days 1-2): Create OrganizerState module (~300 lines)
2. **Session 2** (Days 3-4): Migrate poll response flow (**FIXES THE BUG**)
3. **Session 3** (Days 5-6): Migrate bench data flow
4. **Session 4** (Days 7-8): Migrate group/keystone management
5. **Session 5** (Days 9-10): Final cleanup & comprehensive testing

**Documentation**: [`Documentation/FEATURES & PLANS/Implementation/M+_Organizer_Week_3_State_Module.md`](../../../Documentation/FEATURES%20&%20PLANS/Implementation/M+_Organizer_Week_3_State_Module.md)

**Why This Path**:
- Prevents entire class of data loss bugs
- Cleaner architecture for Phase 4 optimizer algorithms
- Foundation for long-term maintainability
- Higher value than quick fixes

## What's Next?

### Immediate: Week 3 Simplification Session 1
**Action**: Create OrganizerState module skeleton
**Files**: Create `core/organizer/state.lua`, modify `NextKey.toc`
**Timeline**: 2 days
**Complexity**: 🟡 MEDIUM (low risk - no integration yet)

### After Week 3 Complete (~10 days)

**Option A**: Phase 5 Communication (~3 hours)
- Announce groups to Raid/Guild chat
- Quick win to complete manual mode

**Option B**: Phase 4 Optimizer Algorithms (~20+ hours)
- NOW MUCH CLEANER thanks to OrganizerState
- Three optimization modes
- Algorithms read/write state directly

**Option C**: Further simplification/polish

## Blockers
**NONE** - Week 3 planning complete, ready to begin Session 1

## Technical Notes

### OrganizerState API (Session 1 Deliverable)
```lua
-- Player Management
OrganizerState:GetPlayer(playerID)
OrganizerState:SetPlayer(playerID, playerData)
OrganizerState:UpdatePlayerFromPollResponse(playerID, response)

-- Location Tracking
OrganizerState:GetPlayerLocation(playerID)
OrganizerState:MoveToBench(playerID)
OrganizerState:MoveToSlot(playerID, groupIndex, slotIndex)

-- Group Management
OrganizerState:GetGroupAssignments(groupIndex)
OrganizerState:GetSlotPlayer(groupIndex, slotIndex)

-- Keystone Management
OrganizerState:DesignateKeystone(groupIndex, playerID, keystone)
OrganizerState:GetDesignatedKeystone(groupIndex)

-- Poll Management
OrganizerState:StartPoll(pollID)
OrganizerState:UpdatePlayerFromPollResponse(playerID, response)
```

### Data Structure
```lua
OrganizerState = {
    players = {},     -- {[playerID] = PlayerData} - SINGLE SOURCE OF TRUTH
    groups = {},      -- {[groupIndex][slotIndex] = playerID}
    keystones = {},   -- {[groupIndex] = {keystone, playerID}}
    activePoll = nil, -- Current poll state
    bench = {},       -- {[playerID] = true} (set for fast lookup)
    optOut = {}       -- {[playerID] = true}
}
```

### Critical Success Metric
**Poll data persists through unlimited rebuilds** ✅

After Session 2, this test MUST pass:
```lua
-- Complete poll → rebuild bench 10 times → verify poll data intact
```

Currently: **FAILS** (data lost on rebuild)  
After Week 3: **PASSES** (data cannot be lost)
