# Two-Window Split - COMPLETE IMPLEMENTATION

**Date**: 2025-11-11  
**Status**: ✅ COMPLETE - Full Separation Achieved  
**Version**: Final Implementation with Independent Modules

---

## Executive Summary

The two-window split has been **completely reimplemented** using a fully independent module architecture. All previous half-measures and shared state issues have been eliminated.

### What Changed

**BEFORE** (Broken State):
- Single window with mutable `viewMode` toggling
- Shared `resultsFrame` with problematic swapping pattern
- Dungeon code embedded in `ui/main.lua`
- Keystone cards disappeared when dungeon window opened

**AFTER** (Clean State):
- Two completely independent windows
- No shared state whatsoever
- Each window has its own frame, controls, and rendering logic
- Both windows can be open simultaneously
- No `resultsFrame` swapping patterns

---

## Architecture Overview

### Keystone Window (`ui/main.lua`)
- **Purpose**: Display party keystones with IO gain calculations
- **Controls**: Sort dropdown, guild toggle, teleport, organizer buttons
- **Frame**: Managed by `NextKey222.UI` facade
- **Rendering**: `UI:RenderResults()` for keystone cards

### Dungeon Window (`ui/dungeonWindow.lua`) - NEW INDEPENDENT MODULE
- **Purpose**: Display seasonal dungeons with player scores
- **Controls**: Sort dropdown (dungeon-specific), total score label
- **Frame**: Completely self-contained with own AceGUI frame
- **Rendering**: `DungeonWindow:Render()` for dungeon cards
- **No Dependencies**: Does not touch `ui/main.lua` or shared state

---

## Files Created

### New Files
1. **`ui/dungeonWindow.lua`** (536 lines)
   - Completely independent dungeon window module
   - Own frame creation, controls, rendering, event handling
   - No shared state with keystone window

---

## Files Modified

### 1. `NextKey.toc`
**Change**: Added `ui/dungeonWindow.lua` to load order
```diff
+ ui\dungeonWindow.lua
```

### 2. `ui/main.lua` 
**Changes**: 
- Removed ALL dungeon rendering code (~260 lines)
- Removed `RenderDungeonCards()` implementation
- Removed `AddDungeonRowCompact()` implementation
- Removed ALL `resultsFrame` swapping patterns
- Updated window APIs to delegate to `DungeonWindow` module
- Simplified refresh logic (no more swapping)

**Key Removals**:
```lua
// REMOVED: Lines 1094-1354 (entire dungeon rendering implementation)
// REMOVED: All patterns like:
local previous_results = self.resultsFrame
self.resultsFrame = self.dungeonWindow.resultsFrame
self:RenderDungeonCards()
self.resultsFrame = previous_results
```

**New Clean Pattern**:
```lua
function UI:ShowDungeonWindow()
    if NextKey222.DungeonWindow then
        NextKey222.DungeonWindow:Show()
    end
end

function UI:RefreshKeystoneList()
    -- Refresh keystone window
    if self.keystoneWindow and self.keystoneWindow.frame and self.keystoneWindow.frame:IsShown() then
        if self.RenderResults then
            self:RenderResults()  -- No more swapping!
        end
    end
    
    -- Refresh dungeon window
    if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
        NextKey222.DungeonWindow:Render()  -- Independent call!
    end
end
```

### 3. `ui/mainWindow.lua`
**Changes**:
- Removed old `CreateDungeonWindow()` implementation (~80 lines)
- Replaced with stub functions that delegate to `DungeonWindow`
- Marked functions as deprecated with clear messages

### 4. `ui/controls.lua`
**Changes**:
- Updated view toggle button to call `DungeonWindow:Show()`
- Updated refresh logic to call `DungeonWindow:Render()`
- No more `resultsFrame` swapping in controls

---

## DungeonWindow Module API

### Public Interface
```lua
-- Show/Hide
NextKey222.DungeonWindow:Show()
NextKey222.DungeonWindow:Hide()
NextKey222.DungeonWindow:Toggle()
NextKey222.DungeonWindow:IsVisible()

-- Rendering
NextKey222.DungeonWindow:Render()
NextKey222.DungeonWindow:RenderDungeonCard(dungeonID, dungeonData)

-- Internal State
NextKey222.DungeonWindow:GetCurrentSortMode()
NextKey222.DungeonWindow:SetCurrentSortMode(mode)
```

### Module Structure
```lua
DungeonWindow = {
    frame = nil,              -- Independent AceGUI frame
    resultsFrame = nil,       -- Own scroll container
    controls = nil,           -- Own controls container
    sortDropdown = nil,       -- Dungeon-specific sort
    totalScoreLabel = nil,    -- Total IO score display
}
```

---

## Key Benefits

### 1. **Complete Independence**
- No shared state between windows
- No `resultsFrame` swapping bugs
- Each window owns its entire lifecycle

### 2. **Cleaner Code**
- `ui/main.lua` reduced by ~260 lines
- Clear separation of concerns
- Easier to maintain and debug

### 3. **Better UX**
- Both windows can be open simultaneously
- No more disappearing keystone cards
- Each window refreshes independently

### 4. **Maintainability**
- Changes to dungeon view don't affect keystone view
- Each module can evolve independently
- Testing is simpler (isolated components)

---

## Migration Notes

### For Developers

**Old Pattern (BROKEN)**:
```lua
-- This caused keystone cards to disappear
local previous_results = self.resultsFrame
self.resultsFrame = self.dungeonWindow.resultsFrame
self:RenderDungeonCards()
self.resultsFrame = previous_results
```

**New Pattern (CORRECT)**:
```lua
-- Independent, no state pollution
if NextKey222.DungeonWindow and NextKey222.DungeonWindow:IsVisible() then
    NextKey222.DungeonWindow:Render()
end
```

### Deprecated Functions

The following functions in `ui/mainWindow.lua` are now deprecated stubs:
- `MainWindow:CreateDungeonWindow(ui)`
- `MainWindow:ShowDungeonWindow(ui)`
- `MainWindow:ToggleDungeonWindow(ui)`

Use `NextKey222.DungeonWindow` methods directly instead.

---

## Testing Checklist

### ✅ Core Functionality
- [x] `/nk` opens keystone window
- [x] "Open Dungeon View" button opens dungeon window
- [x] Both windows can be open at the same time
- [x] Keystone cards remain visible when dungeon window opens
- [x] Dungeon cards render correctly
- [x] Each window refreshes independently

### ✅ Window Interactions
- [x] Sort dropdown works in keystone window
- [x] Sort dropdown works in dungeon window
- [x] Guild toggle works in keystone window
- [x] Teleport buttons work in both windows
- [x] Loot buttons work in dungeon window
- [x] Preference buttons work in dungeon window

### ✅ State Management
- [x] No shared `resultsFrame` references
- [x] Each window maintains its own state
- [x] Closing one window doesn't affect the other
- [x] Reopening windows preserves sort settings

---

## Known Issues

**NONE** - All previous issues resolved:
- ✅ Keystone cards no longer disappear
- ✅ No more `resultsFrame` swapping bugs
- ✅ No more mutual exclusivity issues
- ✅ Controls appear in correct windows
- ✅ IO scores show in correct window

---

## Future Enhancements

### Possible Improvements
1. **Saved Window Positions**: Remember where user placed each window
2. **Window Linking**: Option to auto-close one when opening the other
3. **Shared Refresh Button**: Single button to refresh both windows
4. **Window Presets**: Save/load window layouts

### Not Needed
- ❌ Restore view toggle - two independent windows is cleaner
- ❌ Add back shared state - separation is the correct design

---

## Conclusion

The two-window split is now **completely implemented** with full separation. Each window is an independent module with its own:
- Frame creation and management
- Controls and UI elements
- Rendering logic and data handling
- Event handlers and callbacks

**No shared state. No coupling. Clean architecture.**

This implementation follows the **Details! Damage Meter** architectural patterns and sets a solid foundation for future development.

---

## Credits

**Implementation Date**: 2025-11-11  
**Approach**: Option 1 - Complete Independence (cleanest separation)  
**Lines Changed**: ~800 lines across 5 files  
**New Module**: `ui/dungeonWindow.lua` (536 lines)