# NextKey Project Audit - November 4, 2025

## Executive Summary

**Current Version**: 0.2.2 (CHANGELOG shows tooltip fixes on Nov 2)
**Memory Bank Status**: UPDATED (Nov 4 - all corrections applied)
**Current Phase**: Phase 3 Manual Mode COMPLETE ✅
**Total Progress**: M+ Organizer 100% complete for manual mode

---

## 1. CORE ADDON STATUS (5-Player Mode)

### ✅ COMPLETE FEATURES
- [x] Keystone detection & ranking (Smart Sort, Max Group IO, etc.)
- [x] RaiderIO integration with score calculations
- [x] Dungeon preferences system (like/dislike)
- [x] Loot targeting system (v0.2.1 - seasonal items, run tracking)
- [x] Travel assistant with teleport integration
- [x] IO tooltips with gain calculations
- [x] Guild keystone sharing via LibOpenRaid
- [x] AceGUI-based main UI with dual views

### 🎯 ACTIVE DEVELOPMENT
**None** - Core 5-player mode is feature-complete and stable

---

## 2. M+ GROUP ORGANIZER STATUS (6+ Player Mode)

### ORIGINAL VISION (from PRD)
Multi-group M+ organizer replacing 6+ player compact mode with:
1. Interactive Roster Board (drag-and-drop)
2. 3-phase participant survey (participation → character → spec preferences)
3. Manual mode with keystone designation
4. 3 optimizer algorithms (Max Power, Balanced, Vault Completion)
5. Announcement system (Raid/Guild chat)

### IMPLEMENTATION REALITY

#### ✅ PHASE 0: Foundation (COMPLETE)
- Character storage with account-wide data
- Auto-detection for non-addon players
- Player data builder with multiple source routing
- Organizer-specific communications (8 opcodes)
- Character Roles options panel

#### ✅ PHASE 0.5: Integration (COMPLETE)
- UI fork system (1-5 vs 6+ players)
- ProfilesService extensions for organizer profiles
- IOCalculator extensions for group gain calculations
- Event-driven cache invalidation

#### ✅ PHASE 1: UI Framework (COMPLETE)
**MAJOR ARCHITECTURE SHIFT**: Replaced AceGUI widgets with native frames
- **`ui/organizer/rosterBoard.lua`** (1,340 lines) - Main orchestrator
- **`ui/organizer/playerCard.lua`** (649 lines) - Native card factory
- **`ui/organizer/dragManager.lua`** - Drag system (inline in playerCard)
- Bench (vertical scroll), Groups (5-slot columns), Opt-Out (horizontal scroll)
- Role validation, drop detection, rejection animations
- View mode detection (Organizer vs Participant)

#### ✅ PHASE 2: Participant Survey (COMPLETE)
- **`core/organizer/survey.lua`** (451 lines) - Poll orchestration
- **`ui/organizer/surveyDialog.lua`** (884 lines) - 3-phase progressive UI
- **`debug/pollSimulator.lua`** (346 lines) - Testing tool
- Phase 1: Yes/Yes on Alt/No participation cards
- Phase 2: Character selection with scrolling
- Phase 3: Spec selection with 3-state preferences (Want to Play/Will Fill/Not Playing)
- Smart defaults based on current spec
- Full specialization metadata capture
- Poll progress tracking with timeout (60s)

#### ✅ PHASE 2.5: Code Simplification (COMPLETE)
**Week 1 Simplification** (Nov 2-3):
- Extracted `RefreshCard()` helper (99 lines saved)
- Merged spec generation functions (96 lines saved)
- Simplified AnimationQueue API (65 lines saved)
- Extracted card rendering helpers (117 lines saved)
- **Total**: 377 lines saved (94% of 400-line goal)

**Week 2 Simplification** (Nov 3-4):
- Split `rosterBoard.lua` into 5 modules (445 lines removed from main, -26%)
  - **`ui/organizer/modules/benchManager.lua`** (462 lines)
  - **`ui/organizer/modules/slotManager.lua`** (411 lines)
  - **`ui/organizer/modules/cardMovement.lua`** (422 lines)
  - **`ui/organizer/modules/keystoneManager.lua`** (215 lines) - FULL IMPLEMENTATION ✅
- Simplified two-phase card removal (95 lines saved)
- Standardized card location tracking (consistency improved)
- **Total**: 540 lines saved (90% of 600-line goal)

**Simplification Achievements**:
- 917 total lines saved across 2 weeks
- `rosterBoard.lua` reduced from 1,726 → 1,340 lines (26% reduction)
- Modular architecture prevents future data loss bugs

#### ✅ PHASE 3: Manual Mode (100% COMPLETE)
**All Features Complete**:
- [x] Drag-and-drop with role validation
- [x] Drop target detection using `IsMouseOver()`
- [x] Auto-slot finding for compatible roles
- [x] Rejection animation for invalid drops
- [x] Two-phase removal system (mark → complete)
- [x] Sequential sorting with animated visualization
  - **`core/organizer/sorting.lua`** (185 lines) - Round-robin algorithm
  - **`core/organizer/animationQueue.lua`** (162 lines) - Flash + flight animation
  - Sort button with orchestration in rosterBoard.lua
- [x] Keystone Designation System (FULLY IMPLEMENTED)
  - `ui/organizer/modules/keystoneManager.lua` - All 7 functions implemented
  - `playerCard.lua:CreateKeystoneButton()` - Star icon button (lines 500-586)
  - Group header updates with dungeon abbreviation + level
  - Visual feedback: Gold border (designated) / Gray border (undesignated)
  - Toggle functionality (click to designate/undesignate)
  - Auto-clear on card movement between groups
  - Auto-clear when card removed from slot
  - DungeonNameService integration for abbreviations
  - Color-coded by key level (15+ orange, 10+ light blue, <10 white)
  - Tooltip shows designation status
  - Sync to participants via organizer communications

#### ❌ PHASE 4: Optimizer Algorithms (NOT STARTED)
**Scope**: Most complex phase, 20+ hours estimated
- [ ] `core/organizer/scoring.lua` (~300 lines) - IO gain calculations
- [ ] `core/organizer/optimizer_mode1.lua` (~400 lines) - Max Power (greedy)
- [ ] `core/organizer/optimizer_mode2.lua` (~500 lines) - Balanced (snake draft)
- [ ] `core/organizer/optimizer_mode3.lua` (~200 lines) - Vault Completion
- [ ] `ui/organizer/optimizerWizard.lua` (~400 lines) - Progress UI with pause/resume
- [ ] Partial group strategies (7 players, 13 players, etc.)
- [ ] Memoization, pruning, batching optimizations

#### ❌ PHASE 5: Communication (NOT STARTED)
- [ ] `core/organizer/announcer.lua` - Announce groups to Raid/Guild chat
- [ ] Format group messages with class colors
- [ ] Preview dialog before sending
- [ ] Channel throttling (4KB message limits)

#### ❌ TESTING & POLISH (NOT STARTED)
- [ ] Functional tests (5-40 player scenarios)
- [ ] Edge case tests (from Edge Cases doc)
- [ ] Performance regression suite
- [ ] User guide updates
- [ ] Visual polish (icons, colors, sounds)

---

## 3. TOOLTIP BUG STATUS

### ✅ FIXED (Nov 2, CHANGELOG v0.2.2)

**What was fixed**:
- Poll simulator double-appending realm names
- Role icons vanishing for fake players after poll
- Spec-level tooltip breakdowns not displaying
- SafeRun return value capture in `rosterBoard.lua`
- Role name normalization (DAMAGER → DPS)

**Files Modified**:
- `debug/pollSimulator.lua` - Uses `OrganizerPlayerDataBuilder` for consistency
- `ui/organizer/playerCard.lua` - Fixed tooltip formatting
- `ui/organizer/modules/benchManager.lua` - SafeRun capture fixed (lines 77-88, 149-160)

**Evidence**: CHANGELOG.md v0.2.2 (2025-11-02) explicitly lists these as FIXED.

---

## 4. WEEK 3 SIMPLIFICATION (QUEUED, HIGH RISK)

**From**: `M+_Organizer_Simplification_Plan.md` Task 3.1

**Goal**: Create `core/organizer/state.lua` - Single source of truth for all organizer data

**Scope**:
- Create ~200-line centralized state module
- Redesign poll data flow to update OrganizerState directly
- Make cards "dumb" renderers (no authoritative data in card.playerData)
- Prevents poll data loss bugs permanently

**Risk**: HIGH - Touches entire organizer architecture, 10-day effort estimate

**Benefit**: Makes data loss impossible, architectural evolution

---

## 5. ARCHITECTURE EVOLUTION

### BEFORE (Phase 1 Original)
- Monolithic `rosterBoard.lua` (1,726 lines)
- Cards as data sources (poll data loss bug)
- Complex animation queue with manual management

### AFTER (Week 2 Simplification)
- **Orchestrator**: `rosterBoard.lua` (1,340 lines, -26%)
- **Specialized Modules** (stateless workers):
  - `benchManager.lua` (462 lines) - Bench operations
  - `slotManager.lua` (411 lines) - Slot creation/layout
  - `cardMovement.lua` (422 lines) - Drag/drop validation
  - `keystoneManager.lua` (215 lines) - Keystone designation (FULL IMPLEMENTATION)
- **Centralized State**: All data in RosterBoard namespace
- **Parameter Pattern**: `ModuleName:FunctionName(rosterBoard, ...args)`
- **Simplified Animation**: `ExecuteSequence(assignments, onComplete)` - single method

### FUTURE (Week 3 - IF IMPLEMENTED)
- **OrganizerState Module**: Single source of truth
- **Cards as Displays**: Render from state, no authoritative data
- **Data Loss Impossible**: State survives UI rebuilds

---

## 6. PRIORITY RECOMMENDATIONS

### OPTION A: Phase 5 Communication (~3 hours, QUICK WIN)
**Time**: ~3 hours
**Risk**: LOW
**Benefit**: Announce groups to Raid/Guild chat with class colors
**Result**: Users can share group compositions easily

### OPTION B: Phase 4 Optimizer Algorithms (~20+ hours, BIGGEST FEATURE)
**Time**: 20+ hours
**Risk**: VERY HIGH (most complex phase)
**Complexity**: Requires memoization, pruning, batching, partial group strategies
**Benefit**: Automatic group optimization using three different strategies

### OPTION C: Week 3 Simplification (~10 days, ARCHITECTURAL)
**Time**: 10 days
**Risk**: HIGH (architectural refactor)
**Benefit**: Prevents future data loss bugs, cleaner architecture
**Consideration**: Major refactor, should only do if planning long-term maintenance

### RECOMMENDED PATH
1. **QUICK WIN**: Start with Phase 5 Communication (~3 hours)
2. **THEN**: In-game validation of all manual mode features
3. **FINALLY**: Decide between Phase 4 optimizer vs Week 3 simplification based on priority

---

## 7. TOKEN-EFFICIENT SUMMARY

**What's Actually Done**:
- Core 5-player mode: 100% complete
- M+ Organizer Phases 0-2: 100% complete
- M+ Organizer Phase 3: 100% complete (keystone designation IMPLEMENTED)
- Code simplification: 917 lines saved, modular architecture

**What's Left for Full Feature Set**:
- Phase 4: Optimizer algorithms (~1,500 lines, 20+ hours)
- Phase 5: Announcement system (~200 lines, 3 hours)
- Testing & polish (TBD)

**Current Blocker**: None - Phase 3 complete, ready for Phase 4 or 5

**Recommended Next Step**: Phase 5 Communication (quick win) then decide on Phase 4 vs Week 3