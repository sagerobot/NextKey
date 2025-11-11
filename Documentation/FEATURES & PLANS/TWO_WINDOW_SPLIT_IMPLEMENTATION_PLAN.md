# Two-Window Split Implementation Plan

## Executive Summary

**Goal**: Split the single `/nk` main window into two truly separate windows:
- **Keystone Window**: Shows available keystones (current main view)
- **Dungeon Window**: Shows all season dungeons with scores/preferences

**Behavior**: Only ONE window can be open at a time (mutual exclusivity), but the architecture supports both being open simultaneously for future flexibility.

**Current Status**: HALF-IMPLEMENTED
- ✅ Two separate AceGUI frames exist (`main_frame`, `dungeon_frame`)
- ✅ Separate creation/show/toggle methods exist
- ❌ Both windows share the SAME `resultsFrame` scroll container
- ❌ Content rendering still uses mutable `viewMode` logic
- ❌ View toggle button mutates content instead of switching windows

---

## Problem Analysis

### Critical Issues

1. **Shared Results Container**
   - Both windows use `UI.resultsFrame` from the facade
   - When dungeon window opens, it tries to render into the keystone window's scroll frame
   - Content gets confused and mixed between windows

2. **ViewMode Mutation Logic**
   - `UI.viewMode` is toggled between "keystones" and "dungeons"
   - Rendering functions check `viewMode` to decide what to render
   - This breaks the two-window separation model

3. **View Toggle Button Confusion**
   - Current button tries to mutate content in place
   - Should instead CLOSE current window and OPEN the other window

4. **Controls Rebuilding on View Change**
   - `UIControls:AttachHeaderControls` rebuilds controls based on `viewMode`
   - This is appropriate for mutating content, NOT for separate windows

---

## Architecture Design

### Window Ownership Model

```
┌─────────────────────────────────────────────────────────┐
│ MainWindow Module (ui/mainWindow.lua)                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  main_frame (Keystone Window)                           │
│  ├── keystoneResultsFrame (NEW - dedicated scroll)     │
│  ├── keystone-specific controls                        │
│  └── "Open Dungeon View" button                        │
│                                                          │
│  dungeon_frame (Dungeon Window)                         │
│  ├── dungeonResultsFrame (NEW - dedicated scroll)      │
│  ├── dungeon-specific controls                         │
│  └── "Back to Keystones" button (NEW)                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### State Separation

**UI Facade State (ui/main.lua)**
```lua
-- REMOVE: viewMode (no longer needed for mutations)
-- REMOVE: resultsFrame (each window has its own)

-- ADD:
keystoneWindow = {
    frame = nil,           -- AceGUI Frame
    resultsFrame = nil,    -- ScrollFrame widget
    controls = nil,        -- Control container
}

dungeonWindow = {
    frame = nil,           -- AceGUI Frame
    resultsFrame = nil,    -- ScrollFrame widget
    controls = nil,        -- Control container
}
```

### Mutual Exclusivity Behavior

**Button Behavior:**
- **In Keystone Window**: "Open Dungeon View" button
  - Closes keystone window
  - Opens dungeon window
  
- **In Dungeon Window**: "Back to Keystones" button
  - Closes dungeon window
  - Opens keystone window

**Slash Commands:**
- `/nk` or `/nk show` - Opens keystone window (closes dungeon if open)
- `/nk dungeon` - Opens dungeon window (closes keystone if open)

---

## Implementation Steps

### Phase 1: Create Dedicated Results Frames

#### File: `ui/mainWindow.lua`

**Changes:**

1. **CreateMainFrame** (keystone window)
```lua
-- BEFORE: Uses shared UI.resultsFrame
-- AFTER: Creates and stores keystoneResultsFrame

function MainWindow:CreateMainFrame(ui)
    -- ... existing frame creation ...
    
    -- Create dedicated results frame for keystones
    local keystoneResults = NextKey222.UIComponents:CreateScrollFrame("primary", nil, {
        fullWidth = true,
        fullHeight = false,
        layout = "List",
    })
    keystoneResults:SetHeight(NextKey222.UIConfig.WINDOW.SCROLL_FRAME_HEIGHT_KEYSTONE)
    
    frame:AddChild(keystoneResults)
    
    -- Store in dedicated structure
    ui.keystoneWindow = ui.keystoneWindow or {}
    ui.keystoneWindow.frame = frame
    ui.keystoneWindow.resultsFrame = keystoneResults
    ui.keystoneWindow.controls = nil  -- Will be set by UIControls
    
    -- REMOVE: ui.resultsFrame = ... (no shared frame)
end
```

2. **CreateDungeonWindow** (dungeon window)
```lua
function MainWindow:CreateDungeonWindow(ui)
    -- ... existing frame creation ...
    
    -- Create dedicated results frame for dungeons
    local dungeonResults = NextKey222.UIComponents:CreateScrollFrame("primary", nil, {
        fullWidth = true,
        fullHeight = false,
        layout = "List",
    })
    dungeonResults:SetHeight(NextKey222.UIConfig.WINDOW.SCROLL_FRAME_HEIGHT_KEYSTONE)
    
    frame:AddChild(dungeonResults)
    
    -- Store in dedicated structure
    ui.dungeonWindow = ui.dungeonWindow or {}
    ui.dungeonWindow.frame = frame
    ui.dungeonWindow.resultsFrame = dungeonResults
    ui.dungeonWindow.controls = nil  -- Will be set by UIControls
end
```

3. **Add Mutual Exclusivity Logic**
```lua
function MainWindow:ShowMainFrame(ui)
    -- Close dungeon window if open
    if ui.dungeonWindow and ui.dungeonWindow.frame then
        ui.dungeonWindow.frame:Hide()
    end
    
    -- ... existing show logic ...
end

function MainWindow:ShowDungeonWindow(ui)
    -- Close keystone window if open
    if ui.keystoneWindow and ui.keystoneWindow.frame then
        ui.keystoneWindow.frame:Hide()
    end
    
    -- ... existing show logic ...
end
```

### Phase 2: Update Control Creation

#### File: `ui/controls.lua`

**Changes:**

1. **Remove ViewMode-Based Control Switching**
```lua
-- REMOVE: CreateKeystoneControls (view-specific)
-- REMOVE: CreateDungeonControls (view-specific)
-- REMOVE: CreateDebugKeystoneControls (view-specific)

-- REPLACE WITH: Window-specific control builders
```

2. **Add AttachKeystoneControls**
```lua
--- Creates controls for the keystone window (static, no view mutations)
function UIControls:AttachKeystoneControls(ui, frame)
    ui.keystoneWindow.controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })
    
    local controls = ui.keystoneWindow.controls
    
    -- Add keystone-specific controls
    _create_sort_dropdown(ui, controls)
    _create_guild_toggle(ui, controls)
    _create_teleport_button(ui, controls)
    _create_organizer_button(ui, controls)
    
    frame:AddChild(controls)
end
```

3. **Add AttachDungeonControls**
```lua
--- Creates controls for the dungeon window (static, no view mutations)
function UIControls:AttachDungeonControls(ui, frame)
    ui.dungeonWindow.controls = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })
    
    local controls = ui.dungeonWindow.controls
    
    -- Add dungeon-specific controls
    _create_sort_dropdown(ui, controls)
    _create_total_score_label(ui, controls)
    
    frame:AddChild(controls)
end
```

4. **Update Button Creation**
```lua
-- MODIFY: _create_view_toggle_button
-- BEFORE: Toggles viewMode in place
-- AFTER: Closes current window, opens other window

local function _create_dungeon_view_button(ui, parent)
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Open Dungeon View",
        onClick = function()
            -- Close keystone window
            if ui.keystoneWindow and ui.keystoneWindow.frame then
                ui.keystoneWindow.frame:Hide()
            end
            
            -- Open dungeon window
            if ui.ShowDungeonWindow then
                ui:ShowDungeonWindow()
            end
        end,
    })
    
    parent:AddChild(btn)
    return btn
end

local function _create_keystone_view_button(ui, parent)
    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Back to Keystones",
        onClick = function()
            -- Close dungeon window
            if ui.dungeonWindow and ui.dungeonWindow.frame then
                ui.dungeonWindow.frame:Hide()
            end
            
            -- Open keystone window
            if ui.ShowMainFrame then
                ui:ShowMainFrame()
            end
        end,
    })
    
    parent:AddChild(btn)
    return btn
end
```

### Phase 3: Remove ViewMode Mutation Logic

#### File: `ui/main.lua`

**Delete/Replace:**

1. **Remove viewMode Property**
```lua
-- DELETE:
viewMode = "keystones",

-- DELETE:
function UI:ToggleViewMode()
```

2. **Update RenderResults** (keystone-only)
```lua
function UI:RenderResults()
    -- REMOVE: if self.viewMode == "dungeons" check
    -- This function ONLY renders keystones now
    
    if not self.keystoneWindow or not self.keystoneWindow.resultsFrame then
        return
    end
    
    local resultsFrame = self.keystoneWindow.resultsFrame
    -- ... rest of rendering logic using resultsFrame ...
end
```

3. **Update RenderDungeonCards** (dungeon-only)
```lua
function UI:RenderDungeonCards()
    -- REMOVE: if self.viewMode checks
    -- This function ONLY renders dungeons now
    
    if not self.dungeonWindow or not self.dungeonWindow.resultsFrame then
        return
    end
    
    local resultsFrame = self.dungeonWindow.resultsFrame
    -- ... rest of rendering logic using resultsFrame ...
end
```

4. **Remove ViewMode Dependencies**
```lua
-- DELETE: UpdateSortDropdownOptions viewMode checks
-- DELETE: ShouldShowKeystoneControls viewMode checks
-- DELETE: All other viewMode conditional logic
```

### Phase 4: Update Slash Commands

#### File: `core/slashCommands.lua`

**Changes:**

1. **ShowMainWindow** (ensure mutual exclusivity)
```lua
function SlashCommands:ShowMainWindow()
    if NextKey222.UI and NextKey222.UI.ShowMainFrame then
        -- This will handle closing dungeon window internally
        NextKey222.UI:ShowMainFrame()
    end
end
```

2. **ShowDungeonCards** (ensure mutual exclusivity)
```lua
function SlashCommands:ShowDungeonCards()
    if NextKey222.UI and NextKey222.UI.ShowDungeonWindow then
        -- This will handle closing keystone window internally
        NextKey222.UI:ShowDungeonWindow()
    end
end
```

### Phase 5: Clean Up Legacy Code

**Files to Clean:**

1. **ui/main.lua**
   - Remove all `if viewMode == "keystones"` checks
   - Remove all `if viewMode == "dungeons"` checks
   - Remove `viewToggleBtn` references
   - Remove `UpdateDebugControlsVisibility` (no longer needed for view switching)
   - Remove `UpdateKeystoneControlsVisibility` (no longer needed for view switching)

2. **ui/controls.lua**
   - Remove `CreateKeystoneControls`
   - Remove `CreateDungeonControls`
   - Remove `CreateDebugKeystoneControls`
   - Remove viewMode checks in `AttachHeaderControls`

3. **ui/viewManager.lua** (if it exists)
   - Delete entirely OR repurpose for other view logic
   - Remove all toggle_view_mode logic

---

## Testing Checklist

### Manual Testing

- [ ] Open keystone window via `/nk`
  - [ ] Verify keystone-specific controls appear
  - [ ] Verify keystones render correctly
  - [ ] Verify "Open Dungeon View" button is present

- [ ] Click "Open Dungeon View" button
  - [ ] Keystone window closes
  - [ ] Dungeon window opens
  - [ ] Dungeon-specific controls appear
  - [ ] Dungeons render correctly

- [ ] Click "Back to Keystones" button in dungeon window
  - [ ] Dungeon window closes
  - [ ] Keystone window opens
  - [ ] Back to keystones view

- [ ] Test slash commands
  - [ ] `/nk` opens keystone window (closes dungeon if open)
  - [ ] `/nk dungeon` opens dungeon window (closes keystone if open)

- [ ] Test mutual exclusivity
  - [ ] Opening keystone window closes dungeon window
  - [ ] Opening dungeon window closes keystone window
  - [ ] No way to have both windows open simultaneously

### Code Verification

- [ ] No references to `UI.viewMode` remain (except for removal)
- [ ] No references to shared `UI.resultsFrame` remain
- [ ] All rendering functions use window-specific results frames
- [ ] All control creation is window-specific (no view mutations)
- [ ] Button callbacks properly close/open windows

---

## Migration Notes

### Backward Compatibility

**Breaking Changes:**
- Users who had custom keybindings to "toggle view" will need to update
- Any external addons that accessed `NextKey222.UI.viewMode` will break

**Preserved Behavior:**
- `/nk` still opens the main (keystone) view
- `/nk dungeon` still opens the dungeon view
- Visual appearance remains identical
- Only one window open at a time (same as before, but cleaner)

### Future Enhancements

If we want to allow BOTH windows open simultaneously in the future:
1. Remove mutual exclusivity logic from `ShowMainFrame` and `ShowDungeonWindow`
2. Change button behavior to NOT close the other window
3. Update button text to "Open Dungeon View (New Window)"

---

## File Modification Summary

| File | Changes | Lines Affected |
|------|---------|----------------|
| `ui/mainWindow.lua` | Add dedicated results frames, mutual exclusivity | ~100 |
| `ui/controls.lua` | Remove view-based control switching, add window-specific builders | ~200 |
| `ui/main.lua` | Remove viewMode, update rendering functions | ~300 |
| `core/slashCommands.lua` | Ensure slash commands respect mutual exclusivity | ~20 |
| `ui/viewManager.lua` | Delete or repurpose | ALL |

**Total Estimated Changes:** ~620 lines across 5 files

---

## Implementation Order

1. **Phase 1** - Create dedicated results frames (foundation)
2. **Phase 2** - Update control creation (UI structure)
3. **Phase 5** - Clean up legacy code (remove viewMode)
4. **Phase 3** - Remove viewMode mutation logic (core behavior)
5. **Phase 4** - Update slash commands (entry points)
6. **Testing** - Verify all scenarios work correctly

---

## Risk Assessment

**Low Risk:**
- Creating dedicated results frames (additive change)
- Updating button callbacks (isolated change)

**Medium Risk:**
- Removing viewMode logic (touches many files)
- Control creation refactor (affects initialization)

**High Risk:**
- None identified (all changes are architectural cleanup)

**Mitigation:**
- Test each phase independently
- Keep git commits granular for easy rollback
- Verify no regressions in keystone rendering
- Verify no regressions in dungeon rendering

---

## Success Criteria

✅ **Complete when:**
1. Keystone window shows ONLY keystones
2. Dungeon window shows ONLY dungeons
3. Only one window can be open at a time
4. Buttons switch between windows (close current, open other)
5. No viewMode references remain in codebase
6. No shared resultsFrame references remain
7. All tests pass

🎯 **Bonus Goals:**
- Code is cleaner and easier to understand
- Future two-window-simultaneous support is trivial to add
- Memory usage is the same or better (no shared state confusion)