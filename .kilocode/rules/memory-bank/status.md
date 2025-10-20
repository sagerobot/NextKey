# NextKey Current Status & Requirements

## Project Status: Post-UI Refactor Bugfixing Phase
**Date**: October 20, 2025
**Version**: 0.2.1

## ✅ Blocker Resolved: GetCard() Lua Error

The persistent Lua error in the `GetCard()` function has been fixed. The Loot Window is no longer blocked.

**Original Error**: `NextKey/core/dungeonCards.lua:58: Name required when creating new dungeon card`

See `context.md` for a full debugging summary.

## 🎯 Implementation Status

### 1. Loot Window (`ui/lootWindow.lua`)
**Current State**: Unblocked. Ready for functional testing.
**Status**: 🟠 READY FOR TESTING

**Architectural Work Completed**:
- ✅ Window architecture refactored to use native frames
- ✅ Three-tier item system designed (Featured, Dropdown, Manual)
- ✅ Run counter and drop chance system implemented
- ✅ Database persistence for tracking is in place

**To Be Tested**:
- ❗ **FATAL**: `GetCard()` error is resolved. The window should now render items correctly.
- ❗ Item icons, lists, and input fields can now be tested.
- ❗ Tooltip Hero track ilvl display remains to be fixed.

### 2. PUG Mode Components Status
**Status**: Unchanged. Work is blocked until Phase 3 (Loot System) is complete.

## 📋 Implementation Priority

With the blocker removed, development can now proceed on the Loot System.

### Phase 3 (Current - Loot System) 🟠 READY FOR TESTING (0% Functionally Complete)
1. ✅ **Fix `GetCard()` Lua Error (HIGHEST PRIORITY)**
2. 🟠 **Test loot window rendering**
3. 🟡 Validate/correct item IDs for Season 3 dungeons
4. 🟡 Fix custom item input functionality
5. 🟡 Add run counter tracking features
6. 🟡 Test persistence system

### Phase 4 (Next - PUG Mode)
- Blocked until Phase 3 is complete.

## 🔧 Technical Notes
- The immediate focus is to test the Loot Window thoroughly to ensure all features are working as expected now that the `GetCard` error is resolved.
- After functional validation, the next step is to fix the Hero track ilvl display issue in the tooltip.
