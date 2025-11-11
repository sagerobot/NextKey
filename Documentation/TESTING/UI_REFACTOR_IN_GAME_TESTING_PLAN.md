# UI Main Refactoring - In-Game Testing Plan

**Date**: 2025-11-10  
**Status**: Active - Addressing Double Render Issues  
**Current Issues**: 
- Buttons rendering twice in controls area
- Player cards appearing below main window (suggesting duplicate scroll frames)

---

## 🔍 Root Cause Analysis

Based on code review, I've identified **THE PRIMARY ISSUE**:

### **CRITICAL: Double AttachHeaderControls() Call**

**Location**: [`ui/main.lua:66-73`](ui/main.lua:66)

```lua
function UI:CreateMainFrame()
    -- Line 67: Creates frame via MainWindow
    local frame = MainWindow:CreateMainFrame(self)
    
    -- Line 70-73: DUPLICATE ATTACHMENT
    -- This runs EVERY TIME CreateMainFrame is called!
    if frame and (not self._headerInitialized) and UIControls then
        UIControls:AttachHeaderControls(self, frame)
        self._headerInitialized = true
    end
    
    return frame
end
```

**BUT ALSO** in [`ui/mainWindow.lua:184-189`](ui/mainWindow.lua:184):

```lua
function MainWindow:CreateMainFrame(ui)
    -- ... frame creation ...
    
    -- Line 185-187: FIRST ATTACHMENT
    if NextKey222.UIControls and NextKey222.UIControls.AttachHeaderControls then
        NextKey222.UIControls:AttachHeaderControls(ui, frame)
    end
    
    return frame
end
```

**Result**: `AttachHeaderControls()` is called **TWICE** on first window open:
1. Once in `MainWindow:CreateMainFrame()` (line 186)
2. Again in `UI:CreateMainFrame()` (line 71)

This creates duplicate:
- Sort dropdowns
- Refresh buttons
- Guild/Party toggles
- Teleport buttons
- Organizer buttons
- Debug controls
- **Results scroll frame** ← This causes the "two scroll frames" appearance
- View toggle button

---

## 🎯 Immediate Fix Required

**Choose ONE of these patterns:**

### Option A: Remove from ui/main.lua (Recommended)
```lua
function UI:CreateMainFrame()
    if not MainWindow or not MainWindow.CreateMainFrame then
        -- error handling
        return
    end

    -- Simply delegate - MainWindow handles everything
    local frame = MainWindow:CreateMainFrame(self)
    
    -- REMOVE lines 70-73 completely
    -- _headerInitialized flag no longer needed
    
    return frame
end
```

### Option B: Remove from ui/mainWindow.lua
```lua
function MainWindow:CreateMainFrame(ui)
    -- ... frame creation ...
    
    -- REMOVE lines 184-189
    -- Let ui/main.lua handle control attachment
    
    return frame
end
```

**Recommendation**: Use **Option A** - keeps all UI construction in MainWindow/UIControls modules, making ui/main.lua truly a facade.

---

## 📋 Testing Checklist

### Pre-Fix Verification (Confirm the Bug)

```lua
-- 1. Open window
/nk

-- 2. Count controls container children
/script print("Controls children:", select("#", NextKey222.UI.controlsContainer:GetChildren()))

-- 3. Expected if bug exists: ~14-16 children (doubled from ~7-8 expected)
-- Expected after fix: ~7-8 children

-- 4. List all buttons to see duplicates
/script for i=1, NextKey222.UI.controlsContainer:GetNumChildren() do local c=select(i,NextKey222.UI.controlsContainer:GetChildren()); print(i, c:GetObjectType(), c:GetName() or "unnamed") end

-- 5. Check for duplicate scroll frames
/script local found=0; for i=1,100 do if _G["NextKeyScrollFrame"..i] then found=found+1 end end; print("Scroll frames found:", found)
```

### Post-Fix Verification

#### Test 1: Single Control Creation
```lua
/reload
/nk

-- Should see exactly ONE of each:
/script local types={}; for i=1,NextKey222.UI.controlsContainer:GetNumChildren() do local c=select(i,NextKey222.UI.controlsContainer:GetChildren()); local t=c:GetObjectType(); types[t]=(types[t] or 0)+1 end; for k,v in pairs(types) do print(k,v) end

-- Expected output (approximate):
-- Dropdown: 1 (sort dropdown)
-- Button: 5-6 (refresh, guild, teleport, organizer, view toggle, maybe debug)
-- Frame: 1-2 (debug controls container, maybe total score label container)
-- ScrollFrame: 1 (results frame)
```

#### Test 2: No _headerInitialized Flag Issues
```lua
-- Close and reopen
/nk
/nk
/nk

-- Check flag state
/script print("Header initialized flag:", NextKey222.UI._headerInitialized)

-- If Option A chosen, this should be nil/false
-- Controls should still render correctly
```

#### Test 3: Open/Close Stability
```lua
-- Rapid cycling
/nk
/nk
/nk
/nk

-- Final check - count should stay consistent
/script print("Final count:", select("#", NextKey222.UI.controlsContainer:GetChildren()))
```

#### Test 4: Visual Inspection
- ✅ Single sort dropdown
- ✅ Single "Refresh Data" button
- ✅ Single "Party Keys"/"Guild Keys" button
- ✅ Single "Open Teleport" button
- ✅ Single "Open Organizer" button (if 6+ players)
- ✅ Single view toggle button at bottom
- ✅ Player cards appear IN the results area, not below window

#### Test 5: Functional Testing
```lua
-- Test each control works
-- 1. Sort dropdown - change sort mode
-- 2. Refresh button - triggers refresh
-- 3. Guild/Party toggle - switches modes
-- 4. Teleport button - opens teleport window
-- 5. View toggle - switches between keystones/dungeons
```

---

## 🔧 Additional Issues Found

### Issue #2: Potential Double Initialization Guard
**Location**: [`ui/mainWindow.lua:128-131`](ui/mainWindow.lua:128)

```lua
if ui.mainFrame then
    log_dev("MainWindow: main frame already exists, skipping creation")
    return
end
```

**This guard prevents re-creation**, but the `_headerInitialized` flag in ui/main.lua can still cause issues if:
- User closes window (releases frame, sets `ui.mainFrame = nil`)
- User reopens window
- Flag is still `true`, so controls aren't attached
- Result: blank window

**Fix**: Remove `_headerInitialized` flag entirely when using Option A.

### Issue #3: ShowMainFrame Creates If Missing
**Location**: [`ui/mainWindow.lua:214-216`](ui/mainWindow.lua:214)

```lua
if not ui.mainFrame then
    self:CreateMainFrame(ui)
end
```

This is fine, but make sure it doesn't bypass the double-attachment fix.

---

## 🧪 Comprehensive Test Suite

### Phase 1: Basic Functionality
```lua
-- T1.1: Fresh start
/reload
/script print("Pre-open:", NextKey222.UI.mainFrame and "EXISTS" or "NIL")
/nk
/script print("Post-open:", NextKey222.UI.mainFrame and "EXISTS" or "NIL")

-- T1.2: Control count
/script print("Controls:", select("#", NextKey222.UI.controlsContainer:GetChildren()))

-- T1.3: Results frame exists
/script print("Results frame:", NextKey222.UI.resultsFrame and "EXISTS" or "NIL")
```

### Phase 2: Duplicate Detection
```lua
-- T2.1: Check for duplicate buttons by name
/script local seen={}; for i=1,NextKey222.UI.controlsContainer:GetNumChildren() do local c=select(i,NextKey222.UI.controlsContainer:GetChildren()); if c.GetText then local t=c:GetText(); if seen[t] then print("DUPE:",t) else seen[t]=true end end end

-- T2.2: Check widget references
/script local w=NextKey222.UI.headerWidgets; print("sortDropdown:", w.sortDropdown and "1" or "0", "refreshDataBtn:", w.refreshDataBtn and "1" or "0", "teleportWindowBtn:", w.teleportWindowBtn and "1" or "0")

-- T2.3: Verify single scroll frame
/script local count=0; local f=NextKey222.UI.mainFrame.frame; while f do for i=1,f:GetNumChildren() do local c=select(i,f:GetChildren()); if c:GetObjectType()=="ScrollFrame" then count=count+1 end end; break; end; print("ScrollFrames:",count)
```

### Phase 3: Lifecycle Testing
```lua
-- T3.1: Open/close cycle
/nk
/script local c1=select("#", NextKey222.UI.controlsContainer and NextKey222.UI.controlsContainer:GetChildren() or 0); print("Open #1:",c1)
/nk
/nk
/script local c2=select("#", NextKey222.UI.controlsContainer and NextKey222.UI.controlsContainer:GetChildren() or 0); print("Open #2:",c2)

-- T3.2: Add fake players
/nk test
/script print("With fakes:", select("#", NextKey222.UI.resultsFrame:GetChildren()))

-- T3.3: Clear and check
/nk test clear
/script print("After clear:", select("#", NextKey222.UI.resultsFrame:GetChildren()))
```

### Phase 4: Integration Testing
```lua
-- T4.1: Sort mode changes
-- Use UI to change sort dropdown
-- Verify results update

-- T4.2: View toggle
-- Click "Switch to Dungeons View"
-- Verify dungeon cards appear
-- Click "Switch to Keystone View"
-- Verify keystone cards appear

-- T4.3: Guild/Party toggle
-- Click toggle
-- Verify button text changes
-- Verify appropriate keys shown
```

---

## 📊 Success Criteria

### Must Pass (P0)
- ✅ Control count: 7-9 children in controlsContainer (not 14-18)
- ✅ No duplicate button text when listing all controls
- ✅ Exactly 1 ScrollFrame in main frame hierarchy
- ✅ Player cards appear within resultsFrame scroll area
- ✅ No visual overlap of controls
- ✅ Open/close cycle maintains consistent control count

### Should Pass (P1)
- ✅ All controls functional (sort, refresh, toggles work)
- ✅ No Lua errors on open/close
- ✅ Memory stable across cycles (no accumulation)
- ✅ View toggle works correctly

### Nice to Have (P2)
- ✅ Debug controls appear/disappear correctly with debug mode
- ✅ Organizer button shows/hides based on group size
- ✅ Frame pacing works for large groups

---

## 🚀 Implementation Steps

1. **Apply Fix** (choose Option A or B above)
2. **Remove Flag** (if Option A: remove `_headerInitialized` and related logic)
3. **Test Basic** (Phase 1 tests)
4. **Test Duplicates** (Phase 2 tests)
5. **Test Lifecycle** (Phase 3 tests)
6. **Test Integration** (Phase 4 tests)
7. **Visual Verification** (manual UI inspection)
8. **Update Docs** (mark issue resolved in refactoring plan)

---

## 📝 Quick Diagnostic Commands

```lua
-- One-liner: Check for double attachment
/script print("Controls:", select("#", NextKey222.UI.controlsContainer:GetChildren()), "Expected: 7-9, Bug if: 14-18")

-- One-liner: List control types
/script local t={}; for i=1,NextKey222.UI.controlsContainer:GetNumChildren() do local c=select(i,NextKey222.UI.controlsContainer:GetChildren()); t[c:GetObjectType()]=(t[c:GetObjectType()] or 0)+1 end; for k,v in pairs(t) do print(k,v) end

-- One-liner: Check scroll frames
/script local s=0; for i=1,NextKey222.UI.mainFrame.frame:GetNumChildren() do if select(i,NextKey222.UI.mainFrame.frame:GetChildren()):GetObjectType()=="ScrollFrame" then s=s+1 end end; print("ScrollFrames:",s,"Expected: 0-1")
```

---

## 🎯 Root Cause Summary

**The bug is caused by**:
- `UIControls:AttachHeaderControls()` being called **twice**
- Once in `MainWindow:CreateMainFrame()` (line 186)
- Again in `UI:CreateMainFrame()` (line 71)

**This creates**:
- Duplicate controls in `controlsContainer`
- Duplicate `resultsFrame` scroll frame (appears as "second scroll frame below window")
- Visual chaos in the UI

**The fix is simple**:
- Remove **ONE** of the two calls to `AttachHeaderControls()`
- Recommended: Remove from `ui/main.lua` (Option A)
- Keep MainWindow as the single source of UI construction

---

**Estimated Fix Time**: 5 minutes  
**Estimated Test Time**: 15 minutes  
**Confidence Level**: 95% - This is the root cause