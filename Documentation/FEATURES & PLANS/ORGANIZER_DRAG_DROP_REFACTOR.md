# NextKey Organizer: Drag & Drop System Refactor Plan

**Date**: November 20, 2025  
**Status**: Proposed Architecture  
**Backward Compatibility**: Not Required (no users yet)

---

## Executive Summary

The current drag-and-drop system suffers from architectural fragmentation across 7+ files, dual drag systems, complex state synchronization, and numerous hacky fixes. This plan proposes a complete rewrite based on a **Single Source of Truth** model with **clear separation of concerns**.

**Key Metrics**:
- **Current Complexity**: ~3,500 lines across 7 files
- **Proposed Complexity**: ~2,000 lines across 5 files (43% reduction)
- **Bug Categories Eliminated**: 8 major architectural issues

---

## Current System Problems

### 1. **Dual Drag Systems** ⚠️ CRITICAL
**Files**: `dragManager.lua` (270 lines), `playerCard.lua` (OnDragStart/OnDragStop handlers)

**Problem**: Two competing drag implementations:
- **DragManager**: Creates visual drag cursors, manages validDropTargets highlighting
- **Native Handlers**: OnDragStart/OnDragStop on cards with direct drop detection

**Symptoms**:
- Unclear which system handles what
- Duplicate role validation logic
- Conflicting state tracking (`isDragging` flags in multiple places)
- Yellow border stuck on cards after drag (lines 2826-2827 in rosterBoard.lua)

### 2. **Complex Location Tracking** ⚠️ HIGH
**Files**: `state.lua`, `cardMovement.lua`, `playerCard.lua`

**Problem**: Multiple location format representations:
- Simple strings: `"bench"`, `"opt_out"`
- Table format: `{type="role_slot", groupIndex=1, slotIndex=2}`
- Cards store: `location`, `displayMode`, `playerData`, `playerID`, `originalX`, `originalY`

**Symptoms**:
- Same-location detection requires 60+ lines (cardMovement.lua:351-396)
- Backward compatibility cruft for old string formats
- Cards bloated with redundant metadata

### 3. **State Synchronization Conflicts** ⚠️ HIGH
**Files**: `rosterBoard.lua` (OnPlayerMoved event handler), `slotManager.lua`, `cardMovement.lua`

**Problem**: Event-driven SyncUIToState can conflict with manual card movements:
- `isBulkOperating` flag to prevent sync during operations
- `isAnimating` flag to prevent sync during animations
- `isDragging` flag to prevent sync during drag (lines 2587-2590)
- Guards stacked on guards creating brittle system

**Symptoms**:
- Circular event loops (C stack overflow - line 2587 fix)
- Cards disappearing mid-drag
- Duplicate cards appearing
- Text missing from cards after placement (skipStateUpdate parameter fix)

### 4. **Scattered Validation Logic** ⚠️ MEDIUM
**Files**: `dragManager.lua`, `cardMovement.lua`

**Problem**: Role compatibility checking duplicated:
- DragManager validates on highlight
- CardMovement validates on drop
- Different validation formats (array vs spec preferences table)

**Symptoms**:
- Lines 24-80 in cardMovement.lua handle multiple role formats
- Bounce-back animation triggered after invalid drop already happened
- Inconsistent validation rules

### 5. **Metadata Bloat on Cards** ⚠️ MEDIUM
**Files**: `playerCard.lua`

**Problem**: Cards store excessive metadata:
```lua
card.playerData      -- Full player object
card.playerID        -- Redundant with playerData.id
card.location        -- "bench" / {type, groupIndex, slotIndex}
card.displayMode     -- "compact" / "expanded" / "opt_out"
card.classColor      -- Redundant with playerData.class
card.originalX       -- For animations
card.originalY       -- For animations
card.isDragging      -- Drag state
```

**Symptoms**:
- Cards should be lightweight views
- State duplication between card and OrganizerState
- Hard to keep in sync

### 6. **Animation Coordination Complexity** ⚠️ MEDIUM
**Files**: `animationQueue.lua`, `rosterBoard.lua`, `cardMovement.lua`

**Problem**: Complex callback chains for animations:
- Recall: highlight wave → simultaneous flight → state update → rebuild UI
- Sort: role wave → flight → remove from bench → place in slot
- Cards hidden after animation, then rebuilt from state

**Symptoms**:
- Animation completion callbacks trigger state updates which trigger UI rebuilds
- Cards reparented to UIParent during animation, then back
- Frame strata/level stored and restored
- Animation callbacks directly call RosterBoard methods (tight coupling)

### 7. **Same-Location Detection Hackiness** ⚠️ LOW
**Files**: `cardMovement.lua` (lines 351-396), `rosterBoard.lua` (MoveSingleCard lines 2729-2782)

**Problem**: 60+ lines to detect if card dropped in same location:
```lua
-- Check if source and destination are the same (dropped back in same location)
local fromLoc = type(fromLocation) == "table" and fromLocation.type or fromLocation
local toLoc = type(toLocation) == "table" and toLocation.type or toLocation

local isSameLocation = false
if type(fromLocation) == "table" and type(toLocation) == "table" then
    -- Both are role slots - check if same slot
    isSameLocation = (fromLocation.type == toLocation.type and
                    fromLocation.groupIndex == toLocation.groupIndex and
                    fromLocation.slotIndex == toLocation.slotIndex)
else
    -- Simple string comparison for bench/opt_out
    isSameLocation = (fromLoc == toLoc)
end
```

**Symptoms**:
- Should be a simple equality check
- Duplicated across multiple files

### 8. **Multiple Reparenting** ⚠️ LOW
**Files**: All animation and drag code

**Problem**: Cards change parents frequently:
- Start: parented to bench/slot/opt-out
- Drag: reparented to UIParent
- Animation: reparented to UIParent
- Drop: reparented to target slot/bench/opt-out

**Symptoms**:
- Frame strata and level constantly changing
- Orphaned cards floating in UIParent
- Cleanup code finds and destroys orphaned cards (lines 2432-2455)

---

## Proposed Architecture: "Card-as-View" Model

### Core Principles

1. **Single Source of Truth**: OrganizerState owns ALL data and locations
2. **Cards Are Views**: Cards display state, never own it
3. **Single Drag System**: Native WoW drag handlers only
4. **Unified Location Format**: Single consistent representation
5. **State-First Updates**: All changes go through OrganizerState first
6. **Event-Driven UI**: UI reacts to state changes only

---

## New Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     OrganizerState                          │
│  (Single Source of Truth - No UI Knowledge)                 │
│                                                              │
│  • players: {[playerID] = {id, name, class, roles, ...}}   │
│  • locations: {[playerID] = Location}                       │
│  • groups: {[groupIndex][slotIndex] = playerID}            │
│                                                              │
│  Location = "bench" | "opt_out" |                          │
│             {zone="slot", group=N, slot=N}                  │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ Events
                            │
┌───────────────────────────┴─────────────────────────────────┐
│                     RosterBoard                              │
│  (UI Orchestrator - Event Listener)                         │
│                                                              │
│  • Listens to OrganizerState events                         │
│  • Rebuilds UI sections as needed                           │
│  • No business logic                                        │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        ▼                   ▼                   ▼
   ┌─────────┐        ┌──────────┐       ┌──────────┐
   │  Bench  │        │  Slots   │       │ Opt-Out  │
   └─────────┘        └──────────┘       └──────────┘
        │                   │                   │
        └───────────────────┴───────────────────┘
                            ▼
                    ┌──────────────┐
                    │  Card (View) │
                    │              │
                    │ playerID     │ ← Only stores ID reference
                    │ OnDragStart  │ ← Initiates drag transaction
                    │ OnDragStop   │ ← Completes drag transaction
                    └──────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  DragController  │
                  │ (Single System)  │
                  │                  │
                  │ • Validates drop │
                  │ • Updates state  │
                  │ • Triggers anim  │
                  └──────────────────┘
```

---

## New File Structure

### **1. core/organizer/state.lua** (EXISTING - Minor Updates)
**Lines**: ~1,200 (current)

**Changes**:
- ✅ Keep existing structure (already excellent)
- ✅ Keep event announcements (already implemented)
- ✨ **NEW**: Simplified location storage

```lua
-- NEW: Unified location storage
OrganizerState.locations = {}  -- {[playerID] = Location}

-- Location format (single consistent type):
Location = "bench" | "opt_out" | {zone="slot", group=1, slot=2}

-- Replaces:
-- • self.bench = {} (set)
-- • self.optOut = {} (set)
-- • Location checking across groups
```

**Benefits**:
- Single lookup: `local location = state.locations[playerID]`
- No scattered location tracking
- Easy same-location check: `location == newLocation` (table comparison)

---

### **2. ui/organizer/cardView.lua** (NEW - Replaces playerCard.lua)
**Lines**: ~400 (simplified from 868)

**Responsibilities**:
- Render card based on playerID only
- Display modes: compact/expanded/opt_out
- NO drag handlers (moved to DragController)
- NO business logic

```lua
local CardView = {}

-- LIGHTWEIGHT: Only stores reference
function CardView:Create(playerID, zone)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    
    card.playerID = playerID  -- ONLY ID reference
    card.zone = zone           -- "bench" / "slots" / "opt_out"
    
    -- NO playerData storage
    -- NO location storage
    -- NO displayMode storage
    -- NO drag handlers
    
    return card
end

-- Render from state
function CardView:Update(card)
    local playerData = OrganizerState:GetPlayer(card.playerID)
    local location = OrganizerState:GetLocation(card.playerID)
    
    -- Determine display mode from location
    local mode = self:GetDisplayMode(location)
    
    -- Render content
    self:RenderContent(card, playerData, mode)
end

function CardView:GetDisplayMode(location)
    if location == "bench" then return "compact" end
    if location == "opt_out" then return "opt_out" end
    if location.zone == "slot" then return "expanded" end
end
```

**Benefits**:
- Cards are pure views (no state duplication)
- Always render from current state
- Impossible to desync

---

### **3. ui/organizer/dragController.lua** (NEW - Replaces dragManager.lua + parts of cardMovement.lua)
**Lines**: ~350 (consolidated from 270 + 430)

**Responsibilities**:
- Single drag system using native WoW handlers
- Validate drops
- Update OrganizerState
- Trigger animations
- NO UI manipulation

```lua
local DragController = {}

-- Register drag handlers on card creation
function DragController:EnableDrag(card)
    card:SetMovable(true)
    card:RegisterForDrag("LeftButton")
    
    card:SetScript("OnDragStart", function(self)
        DragController:StartDrag(self)
    end)
    
    card:SetScript("OnDragStop", function(self)
        DragController:CompleteDrag(self)
    end)
end

-- Drag transaction (state-first)
function DragController:StartDrag(card)
    -- 1. Visual feedback
    card:StartMoving()
    card:SetBackdropBorderColor(1.0, 1.0, 0, 1.0)  -- Yellow border
    
    -- 2. Store transaction data
    self.activeDrag = {
        card = card,
        playerID = card.playerID,
        fromLocation = OrganizerState:GetLocation(card.playerID)
    }
end

function DragController:CompleteDrag(card)
    card:StopMovingOrSizing()
    
    local drag = self.activeDrag
    if not drag then return end
    
    -- 1. Detect drop target
    local dropTarget = self:DetectDropTarget()
    local toLocation = self:GetLocationFromTarget(dropTarget)
    
    -- 2. Validate move
    if not self:ValidateMove(drag.playerID, drag.fromLocation, toLocation) then
        -- Bounce back animation
        AnimationController:Reject(drag.card, drag.fromLocation)
        self.activeDrag = nil
        return
    end
    
    -- 3. Update state FIRST
    local success = OrganizerState:MovePlayer(drag.playerID, toLocation)
    
    if success then
        -- 4. Trigger animation (UI will rebuild from state after animation)
        AnimationController:MoveTo(drag.card, dropTarget, function()
            -- Animation complete - state already updated
            -- Event system will trigger UI rebuild
        end)
    end
    
    self.activeDrag = nil
end

-- Simple drop detection
function DragController:DetectDropTarget()
    local mouseX, mouseY = GetCursorPosition()
    
    -- Check slots first (priority)
    for groupIndex, slots in pairs(RosterBoard.groupSlots) do
        for slotIndex, slot in pairs(slots) do
            if slot.frame:IsMouseOver() then
                return {type="slot", group=groupIndex, slot=slotIndex, frame=slot.frame}
            end
        end
    end
    
    -- Check opt-out
    if RosterBoard.optOutSection:IsMouseOver() then
        return {type="opt_out", frame=RosterBoard.optOutSection}
    end
    
    -- Default: bench
    return {type="bench", frame=RosterBoard.benchContainer}
end

-- Unified validation (NO DUPLICATION)
function DragController:ValidateMove(playerID, fromLocation, toLocation)
    -- Same location = valid (just reset visual state)
    if self:IsSameLocation(fromLocation, toLocation) then
        return true
    end
    
    -- Check role compatibility for slot targets
    if toLocation.zone == "slot" then
        local playerData = OrganizerState:GetPlayer(playerID)
        local slot = RosterBoard.groupSlots[toLocation.group][toLocation.slot]
        
        return self:CanFillRole(playerData.roles, slot.role)
    end
    
    return true  -- Bench/opt-out always valid
end

-- Simple same-location check
function DragController:IsSameLocation(loc1, loc2)
    -- String comparison
    if type(loc1) == "string" and type(loc2) == "string" then
        return loc1 == loc2
    end
    
    -- Table comparison
    if type(loc1) == "table" and type(loc2) == "table" then
        return loc1.zone == loc2.zone and
               loc1.group == loc2.group and
               loc1.slot == loc2.slot
    end
    
    return false
end
```

**Benefits**:
- Single drag system (no more dual implementations)
- State-first updates (no desyncs)
- Simple validation (no duplication)
- Clear transaction boundaries
- 3-line same-location check (vs 60+ lines)

---

### **4. ui/organizer/animationController.lua** (NEW - Replaces animationQueue.lua)
**Lines**: ~400 (simplified from 560)

**Responsibilities**:
- Execute animations only
- NO state updates
- NO UI rebuilds
- Callbacks notify completion only

```lua
local AnimationController = {}

-- Simple move animation (no state updates)
function AnimationController:MoveTo(card, targetFrame, onComplete)
    local startX, startY = card:GetCenter()
    local targetX, targetY = targetFrame:GetCenter()
    
    -- Animate (unchanged from current)
    self:AnimateParabolic(card, startX, startY, targetX, targetY, function()
        -- Animation complete - just hide card
        -- State already updated by DragController
        -- Event system will rebuild UI from state
        card:Hide()
        
        if onComplete then onComplete() end
    end)
end

-- Rejection animation (bounce back)
function AnimationController:Reject(card, originalLocation, onComplete)
    -- Flash red
    card:SetBackdropBorderColor(1.0, 0, 0, 1.0)
    
    -- Wait, then reset
    C_Timer.After(0.3, function()
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        if onComplete then onComplete() end
    end)
end
```

**Benefits**:
- Animations don't update state (separation of concerns)
- Callbacks are simple (no chained state updates)
- Can be tested independently

---

### **5. ui/organizer/rosterBoard.lua** (UPDATED - Simplified)
**Lines**: ~1,500 (from 2,888 - 48% reduction)

**Changes**:
- ✅ Keep event listeners (already implemented)
- ✅ Keep section creation (bench, slots, opt-out)
- ❌ **REMOVE**: All drag/drop handling (moved to DragController)
- ❌ **REMOVE**: All card manipulation (moved to CardView)
- ❌ **REMOVE**: MoveSingleCard, SyncBenchAndOptOutOnly (event-driven rebuild only)
- ✨ **NEW**: Simple rebuild methods only

```lua
-- Event handler (simplified)
function RosterBoard:OnPlayerMoved(payload)
    -- Only update UI if visible
    if not self:IsVisible() then return end
    
    -- Skip during animations
    if self.isAnimating then return end
    
    -- Rebuild affected sections from state
    local sections = self:GetAffectedSections(payload.fromLocation, payload.toLocation)
    
    for _, section in ipairs(sections) do
        self:RebuildSection(section)
    end
end

-- Simple rebuild (no card manipulation)
function RosterBoard:RebuildSection(section)
    if section == "bench" then
        -- Clear old cards
        for _, card in ipairs(self.benchCards) do
            card:Hide()
        end
        self.benchCards = {}
        
        -- Create new cards from state
        local benchPlayers = OrganizerState:GetBenchPlayers()
        for _, playerID in ipairs(benchPlayers) do
            local card = CardView:Create(playerID, "bench")
            CardView:Update(card)
            DragController:EnableDrag(card)
            table.insert(self.benchCards, card)
        end
        
        -- Layout
        self:LayoutBench()
    end
    
    -- Similar for "slots" and "opt_out"
end
```

**Benefits**:
- No card manipulation logic
- No state synchronization logic
- Event-driven only
- Clear, simple rebuilds

---

## Migration Strategy

### Phase 1: Foundation (Week 1)
**Goal**: New core files without breaking existing system

1. Create `core/organizer/location.lua`
   - Location type definitions
   - Comparison utilities
   - Migration helpers

2. Update `core/organizer/state.lua`
   - Add `locations = {}` table
   - Add `GetLocation(playerID)`, `SetLocation(playerID, location)`
   - Maintain backward compatibility with bench/optOut/groups

3. Create test harness
   - Validate location format conversions
   - Test state.lua changes with existing code

**Deliverable**: State can store locations in new format while old code still works

### Phase 2: Views (Week 2)
**Goal**: Lightweight card views

1. Create `ui/organizer/cardView.lua`
   - Minimal card creation
   - Render from playerID only
   - No drag handlers yet

2. Update `ui/organizer/rosterBoard.lua`
   - Add `RebuildSection()` methods
   - Keep old methods for now
   - Test rebuilds with CardView

**Deliverable**: Can create and render cards from new system

### Phase 3: Drag System (Week 3)
**Goal**: Single drag controller

1. Create `ui/organizer/dragController.lua`
   - Implement StartDrag/CompleteDrag
   - Integrate with OrganizerState
   - Simple validation

2. Update CardView
   - Remove old drag handlers
   - Let DragController attach handlers

3. Test drag transactions
   - Bench → Slot
   - Slot → Bench
   - Slot → Slot
   - Same location drops

**Deliverable**: Drag system works with new architecture

### Phase 4: Animations (Week 4)
**Goal**: Simplified animations

1. Create `ui/organizer/animationController.lua`
   - MoveTo animation
   - Reject animation
   - NO state updates

2. Update DragController
   - Call AnimationController instead of AnimationQueue

3. Update event handlers
   - Remove old animation coordination
   - Simple rebuild after animation complete

**Deliverable**: Animations work without complex callbacks

### Phase 5: Cleanup (Week 5)
**Goal**: Remove old system

1. Delete old files:
   - `ui/organizer/dragManager.lua`
   - `ui/organizer/playerCard.lua` (replaced by cardView.lua)
   - `core/organizer/animationQueue.lua` (replaced by animationController.lua)
   - `ui/organizer/modules/cardMovement.lua` (logic moved to dragController.lua)

2. Simplify RosterBoard:
   - Remove MoveSingleCard
   - Remove SyncBenchAndOptOutOnly
   - Remove all card manipulation
   - Keep only rebuild methods

3. Clean up state.lua:
   - Remove backward compatibility code
   - Remove old bench/optOut sets
   - Use only locations table

**Deliverable**: Clean, simplified codebase

---

## Testing Checklist

### Unit Tests
- [ ] Location format conversion
- [ ] Same-location detection
- [ ] Role validation logic
- [ ] State location updates

### Integration Tests
- [ ] Drag bench → slot (valid role)
- [ ] Drag bench → slot (invalid role) → rejection
- [ ] Drag slot → bench
- [ ] Drag slot → different slot
- [ ] Drag within same location (no-op)
- [ ] Drag to opt-out
- [ ] Drag from opt-out to bench

### Animation Tests
- [ ] MoveTo animation completes
- [ ] Rejection animation completes
- [ ] No orphaned cards after animation
- [ ] UI rebuilds correctly after animation

### State Tests
- [ ] State updates before UI changes
- [ ] Events fire correctly
- [ ] Persistence works with new location format
- [ ] /reload preserves all locations

### Performance Tests
- [ ] 40 player drag performance
- [ ] Animation smoothness
- [ ] UI rebuild speed
- [ ] Memory usage (should decrease)

---

## Success Metrics

### Code Quality
- **Lines of Code**: 43% reduction (3,500 → 2,000)
- **File Count**: 29% reduction (7 → 5)
- **Cyclomatic Complexity**: <10 per function

### Bug Elimination
- ✅ No dual drag systems
- ✅ No state synchronization conflicts
- ✅ No card metadata duplication
- ✅ No complex same-location detection
- ✅ No orphaned cards
- ✅ No stuck yellow borders
- ✅ No circular event loops
- ✅ No animation callback chains

### Performance
- **Drag Response**: <16ms (60 FPS)
- **Animation FPS**: Consistent 60 FPS
- **Memory**: <50MB with 40 players
- **Rebuild Time**: <100ms

---

## Risk Assessment

### High Risk
- **Event loop bugs**: Careful guard placement needed
- **Animation timing**: Must not conflict with state updates
- **Backward compatibility**: SavedVariables migration

**Mitigation**:
- Extensive testing with event logging
- Phased rollout (can revert per phase)
- Migration helper for old save data

### Medium Risk
- **Performance regression**: More rebuilds vs surgical updates
- **Visual glitches**: Cards hiding/showing during transition

**Mitigation**:
- Profile rebuild performance
- Add visibility guards
- Maintain animation quality

### Low Risk
- **Code complexity**: New system is simpler
- **Testing**: Better separation of concerns makes testing easier

---

## Conclusion

This refactor eliminates architectural debt by enforcing a **Single Source of Truth** model with **clear separation of concerns**. The new system is:

- **43% less code** (easier to maintain)
- **Architecturally sound** (no hacky fixes)
- **Event-driven** (no state desyncs)
- **Testable** (isolated components)
- **Performant** (lightweight views)

The migration can be done in 5 weekly phases with rollback points at each phase. Since there are no users yet, this is the ideal time for a complete rewrite.

**Recommendation**: Proceed with phased implementation starting with Phase 1.