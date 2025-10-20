# NextKey Development Plan - Post-UI Refactor Bugfixing Phase

**Date**: October 20, 2025
**Current Version**: 0.2.1
**Project Status**: Post-UI Refactor Bugfixing Phase - Loot System Implementation

---

## 🎯 Executive Summary

NextKey has completed major UI refactoring (Phases 1-6) and critical core functionality restoration (Phases 1-2). Currently in Phase 3: implementing the loot targeting system with a focus on fixing rendering issues and completing feature integration.

---

## ✅ Completed Phases

### Phase 1: Critical Core Functionality (COMPLETED) ✅
- ✅ Fixed IO tooltips in both regular and compact views
- ✅ Fixed dungeon view IO color consistency with keystone cards
- ✅ Fixed hearthstone selector icon loading (no more question marks on first open)

### Phase 2: Quick UI Wins (COMPLETED) ✅
- ✅ Enhanced card button layouts with proper vertical centering
- ✅ Expanded fake player varieties from 4 to 9 skill tiers (title → beginner)

---

## 🔄 Phase 3: Loot Targeting System (IN PROGRESS - 25% Complete)

### Current Status
The loot window architecture is complete with component factory integration, but rendering is broken. Focus is on fixing display issues and validating item data.

### 3.1 Fix Loot Window Rendering Issues (HIGHEST PRIORITY) ⭐⭐⭐

**Problem**: Items not displaying in loot window despite architecture being in place
**Location**: `ui/lootWindow.lua` (lines 252-401)
**Files Involved**:
- `ui/lootWindow.lua` - Main loot window logic
- `data/loot.lua` - Seasonal item data
- `core/dungeonCards.lua` - Tracking methods
- `core/config.lua` - Database persistence

**Known Issues**:
1. Item icons not displaying (blank, not question marks)
2. Item list appears empty in scroll frame
3. Custom item input field overhangs window boundary
4. Items not appearing after adding via input

**Root Causes (Suspected)**:
- Scroll frame not properly rendering child components
- Component factory integration issue with scroll frame children
- Icon preloading not completing before render
- Incorrect positioning or parenting of item frames

**Approach**:
1. Enable debug output for loot window rendering
2. Verify scroll frame is properly initialized and visible
3. Check component factory CreateFrame returns valid objects
4. Validate item data is being retrieved correctly
5. Test icon preloading sequence
6. Fix input field positioning and width constraints

**Expected Time**: 2-3 hours
**Success Criteria**: 
- All items display with proper icons (no blanks/question marks)
- Custom items can be added via input field
- Input field fits properly within window boundaries
- Items persist after `/reload`

---

### 3.2 Validate and Fix Item IDs (BLOCKER) ⭐⭐⭐

**Problem**: Item IDs in `data/loot.lua` are placeholders and may be incorrect for TWW S3
**Location**: `data/loot.lua` (lines 18-80)
**Impact**: Users will track wrong items or get empty item names

**Approach**:
1. Receive Wowhead link from user for each dungeon
2. Extract correct item IDs for each dungeon
3. Update `data/loot.lua` with accurate data
4. Cross-reference with Blizzard API to ensure IDs are valid
5. Test item name loading and quality colors

**Dependencies**: Waiting for user to provide Wowhead links with item data

**Expected Time**: 30-60 minutes once item data provided

---

### 3.3 Implement Run Counter Integration (FUTURE ENHANCEMENT)

**Features to Add** (Part of loot window, not separate):
- Track number of dungeon completions while item is targeted
- Per-item run counter (multiple items track independently)
- Display total dungeon runs for context
- "Fun drop rate message" when targeted item finally drops
- Optional integration with RaiderIO/WoW API for historical run counts
- Show calculations with/without RaiderIO data

**Database Structure**: Already prepared in `core/config.lua` (lootTracking table)
**Visual**: Indicator on dungeon card showing tracked items with tooltip

**Expected Implementation**: After rendering issues fixed
**Complexity**: Medium - requires run tracking and messaging system

---

## 📋 Phase 4: PUG Mode Fixes (Next After Loot)

### Priority Issues:
1. Fix PUG invite notifications (never worked)
2. Implement application tracker
3. Enhance getaway UI
4. Audit and streamline options panel

---

## 🚀 Immediate Next Steps

1. **Debug Loot Window Rendering**
   - Enable debug: `/nk config` → Debug System → Set to DEV
   - Enable "lootwindow" and "components" categories
   - Open loot window and check debug output
   - Look for rendering, positioning, or component factory errors

2. **Verify Component Factory Integration**
   - Test individual component creation (CreateFrame, CreateIcon, CreateText)
   - Use `/nk components test` to validate component system
   - Check if scroll frame children are rendering

3. **Prepare for Item ID Update**
   - Ready to accept Wowhead links from user
   - Have data/loot.lua structure prepared for updates
   - Test item validation when IDs are updated

---

## 🔧 Development Environment

### Debug Commands:
```bash
# Enable comprehensive debugging
/nk config → Debug System → Set level to DEV
# Enable categories: lootwindow, components, ui

# Test component rendering
/nk components test

# Generate test data
/nk test preset mixed_skill

# Run validation
/script NextKeyRunTests()
```

### Key Files to Monitor:
- `ui/lootWindow.lua` - Main rendering logic
- `core/components.lua` - Component factory (via UIComponents)
- `data/loot.lua` - Item data
- `core/debugService.lua` - Debug output categories

---

## 📊 Success Metrics for Phase 3

### Rendering Fixes:
- ✅ All default items display with proper icons
- ✅ Custom items appear in list after adding
- ✅ Input field fits within window
- ✅ No blank or question mark icons
- ✅ Proper persistence across sessions

### Item Validation:
- ✅ All item IDs valid for Season 3 dungeons
- ✅ Item names load correctly
- ✅ Quality colors display properly
- ✅ No "Loading..." messages remain visible

### Integration:
- ✅ Loot button on dungeon cards opens window correctly
- ✅ Window title shows dungeon name
- ✅ Data flows between window and cards properly

---

## 🔄 Testing Strategy

### Basic Rendering Tests:
1. Open `/nk` → select dungeon → click "Loot" button
2. Verify window opens with title showing dungeon name
3. Check that default items display with icons
4. Verify protected indicator shows on default items
5. Test input field - add custom item ID (e.g., 207167)
6. Check custom item appears in list
7. Test remove button on custom items

### Persistence Tests:
1. Add custom items to multiple dungeons
2. Type `/reload` to save and reload
3. Verify all tracked items still there
4. Check per-dungeon tracking is separate

### Integration Tests:
1. Open main window with fake players
2. Find dungeon with keystones
3. Click "Loot" button on that dungeon card
4. Verify correct items display

---

## 📝 Documentation Updates

### Files Updated:
- ✅ `boot.lua` - Version 0.2.1
- ✅ `NextKey.toc` - Version 0.2.1
- ✅ `.kilocode/rules/memory-bank/context.md` - Current work status
- ✅ `.kilocode/rules/memory-bank/status.md` - Detailed implementation status

### Cleanup Completed:
- ❌ Removed outdated phase documentation
- ❌ Removed completed fix plan documents
- ❌ Consolidated all current work into this single plan

---

## 🎯 Timeline & Priority

| Phase | Task | Status | Time | Next |
|-------|------|--------|------|------|
| 3.1 | Fix loot rendering | 🔄 IN PROGRESS | 2-3h | Debug session |
| 3.2 | Validate item IDs | ⏳ BLOCKED | 30-60m | User provides Wowhead |
| 3.3 | Run counter integration | 📋 PLANNED | 2-3h | After 3.1 complete |
| 4.0 | PUG mode fixes | 📋 PLANNED | 3-4h | After Phase 3 |

---

## 💡 Key Architectural Decisions

1. **Modular Item Data**: Seasonal structure allows easy updates without code changes
2. **Component Factory**: All UI uses established factory patterns for consistency
3. **Per-Dungeon Tracking**: Database structure allows independent tracking per dungeon/character
4. **Persistence First**: Loot tracking integrated into character database from start
5. **Enhancement-Ready**: Run counter architecture planned but not blocking core loot window

---

**Prepared by**: NextKey Development Team
**Last Updated**: October 20, 2025
**Current Focus**: Fixing loot window rendering issues
**Next Review**: After Phase 3.1 debugging session
