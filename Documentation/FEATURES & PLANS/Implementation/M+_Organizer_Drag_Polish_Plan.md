# M+ Group Organizer - Drag-and-Drop Polish Plan

## Status: READY FOR IMPLEMENTATION
**Date**: 2025-10-26
**Priority**: HIGH (Final 10% to complete drag system)

---

## Problem Summary

The M+ Group Organizer drag-and-drop system is 90% complete with two remaining issues:

### Issue 1: Gap Appears in Bench on Rejection
**Problem**: When a card is dragged from the bench and rejected, a visible gap appears in the bench list during the rejection animation.

**Root Cause**: Card is removed from `benchCards` array immediately on drag start (line 929), creating a gap until the rejection animation completes and re-inserts the card.

**Impact**: Visual glitch - users see a blank space in the bench list during rejection animation.

### Issue 2: Rejected Slot Cards Render Behind Background
**Problem**: When cards are rejected back to their original slot, they appear behind the slot background instead of on top.

**Root Cause**: Frame level/strata not properly restored after rejection animation completes.

**Impact**: Cards become invisible/unusable after rejection from slots.

---

## Solution Design

### Part A: Two-Phase Card Removal System

**Concept**: Don't actually remove cards from their source until drop is confirmed successful.

**New Flow**:
```
1. Drag Start → Mark card as "pending removal" (store metadata, don't modify arrays)
2. Drop Attempt → Validation
   a. Success → Actually remove from source, place in destination
   b. Failure → Clear "pending removal" flag, animate back
```

**Implementation**:

1. **Rename Function**: `RemoveCardFromSource()` → `MarkCardForRemoval()`
   - Store original location data (index, parent, etc.)
   - Set `card.pendingRemoval = true`
   - DO NOT modify `benchCards` or `groupSlots` arrays

2. **Add New Function**: `CompleteCardRemoval()`
   - Called ONLY on successful drop
   - Actually removes card from source array
   - Triggers layout refresh

3. **Update Rejection Animation**: `AnimateRejection()`
   - Clear `card.pendingRemoval = false`
   - No array manipulation needed (card was never removed)
   - Layout refresh will show card in original position

**Benefits**:
- No gaps during drag or rejection
- Simpler logic (no re-insertion needed)
- Cards stay in arrays until drop confirmed

---

### Part B: Frame Level Restoration Fix

**Problem Analysis**:

Current rejection animation (lines 1089-1097) restores:
- `SetFrameStrata("MEDIUM")` ✅
- `EnableMouse(true)` ✅
- `SetMovable(true)` ✅
- `SetFrameLevel(parent + 1)` ✅

**But**: When card returns to slot, it needs slot-specific frame level, not bench frame level.

**Solution**:

Store **original frame properties** before drag starts:

```lua
-- In EnableNativeDragging (playerCard.lua)
card:SetScript("OnDragStart", function(self)
    -- Store original frame properties
    self.originalFrameStrata = self:GetFrameStrata()
    self.originalFrameLevel = self:GetFrameLevel()
    self.originalParent = self:GetParent()
    self.originalX, self.originalY = self:GetCenter()
    
    -- ... rest of drag start logic
end)
```

Then restore exact values in rejection animation:

```lua
-- In AnimateRejection (rosterBoard.lua)
card:SetFrameStrata(card.originalFrameStrata or "MEDIUM")
card:SetFrameLevel(card.originalFrameLevel or (card:GetParent():GetFrameLevel() + 1))
```

**Additional Fix**: Ensure slots have proper frame levels

```lua
-- In CreateFlatRoleSlot (rosterBoard.lua)
slot:SetFrameLevel(parentContainer:GetFrameLevel() + 50)  -- Slots WAY above background
slot:SetFrameStrata("MEDIUM")

-- When placing card in slot:
card:SetFrameLevel(slot:GetFrameLevel() + 1)  -- Card above slot
card:SetFrameStrata("MEDIUM")
```

---

## Implementation Checklist

### Phase 1: Two-Phase Removal System

**File**: [`ui/organizer/rosterBoard.lua`](ui/organizer/rosterBoard.lua)

- [ ] **Rename Function** (lines 914-952):
  ```lua
  -- function RosterBoard:RemoveCardFromSource(card)
  function RosterBoard:MarkCardForRemoval(card)
      -- Store metadata only, don't modify arrays
      card.pendingRemoval = true
      card.originalLocation = card.location
      
      if location == "bench" then
          for i, benchCard in ipairs(self.benchCards) do
              if benchCard == card then
                  card.originalIndex = i
                  card.originalList = self.benchCards
                  -- DO NOT: table.remove(self.benchCards, i)
                  break
              end
          end
      elseif type(location) == "table" and location.type == "role_slot" then
          local slot = self.groupSlots[location.groupIndex][location.slotIndex]
          card.originalSlot = slot
          -- DO NOT: slot.playerCard = nil
      end
  end
  ```

- [ ] **Add New Function**:
  ```lua
  function RosterBoard:CompleteCardRemoval(card)
      -- Actually remove from arrays (called ONLY on successful drop)
      
      if card.originalList then
          for i, c in ipairs(card.originalList) do
              if c == card then
                  table.remove(card.originalList, i)
                  Debug:Dev("organizer_ui", "Completed removal from bench at index", i)
                  break
              end
          end
          self:LayoutBench()
      elseif card.originalSlot then
          card.originalSlot.playerCard = nil
          card.originalSlot.isEmpty = true
          if card.originalSlot.emptyLabel then
              card.originalSlot.emptyLabel:Show()
          end
      end
      
      -- Clear temporary data
      card.originalIndex = nil
      card.originalList = nil
      card.originalSlot = nil
      card.pendingRemoval = false
  end
  ```

- [ ] **Update HandleCardDrop** (lines 862-912):
  ```lua
  function RosterBoard:HandleCardDrop(card, dropTarget)
      -- Mark for removal (non-destructive)
      self:MarkCardForRemoval(card)
      
      if dropTarget.type == "role_slot" then
          -- Validate role
          if not canFill then
              self:AnimateRejection(card)
              return
          end
          
          if not dropTarget.slot.isEmpty then
              self:AnimateRejection(card)
              return
          end
          
          -- SUCCESS - actually remove from source
          self:CompleteCardRemoval(card)
          self:PlaceCardInSlot(card, dropTarget.slot)
          
      elseif dropTarget.type == "bench" then
          self:CompleteCardRemoval(card)
          self:PlaceCardInBench(card)
          
      elseif dropTarget.type == "opt_out" then
          self:CompleteCardRemoval(card)
          self:PlaceCardInOptOut(card)
      end
  end
  ```

- [ ] **Update AnimateRejection** (lines 1017-1106):
  ```lua
  function RosterBoard:AnimateRejection(card)
      -- Clear pending removal flag (card stays in original list)
      card.pendingRemoval = false
      
      -- ... animation logic ...
      
      -- On animation complete:
      if currentStep >= steps then
          -- Card already in correct list - just refresh layout
          if card.originalLocation == "bench" then
              self:LayoutBench()
          elseif type(card.originalLocation) == "table" and card.originalLocation.type == "role_slot" then
              -- Card already in slot - just ensure it's visible
              if card.originalSlot then
                  card:SetParent(card.originalSlot)
                  card:ClearAllPoints()
                  card:SetPoint("CENTER", card.originalSlot, "CENTER")
              end
          end
          
          -- Restore frame properties (see Part B)
          card:SetFrameStrata(card.originalFrameStrata or "MEDIUM")
          card:SetFrameLevel(card.originalFrameLevel or (card:GetParent():GetFrameLevel() + 1))
          card:EnableMouse(true)
          card:SetMovable(true)
          
          -- Reset colors
          card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
          card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
      end
  end
  ```

---

### Phase 2: Frame Level Restoration

**File**: [`ui/organizer/playerCard.lua`](ui/organizer/playerCard.lua)

- [ ] **Update OnDragStart** (lines 210-228):
  ```lua
  card:SetScript("OnDragStart", function(self)
      -- CRITICAL: Store ALL original frame properties
      self.originalParent = self:GetParent()
      self.originalX, self.originalY = self:GetCenter()
      self.originalFrameStrata = self:GetFrameStrata()
      self.originalFrameLevel = self:GetFrameLevel()
      
      -- Reparent to UIParent
      self:SetParent(UIParent)
      self:SetFrameStrata("TOOLTIP")
      
      -- Start moving
      self:StartMoving()
      self.isDragging = true
      
      -- Visual feedback
      self:SetBackdropColor(self.classColor.r, self.classColor.g, self.classColor.b, 0.5)
      self:SetBackdropBorderColor(1, 1, 0, 1)
  end)
  ```

**File**: [`ui/organizer/rosterBoard.lua`](ui/organizer/rosterBoard.lua)

- [ ] **Update PlaceCardInSlot** (lines 954-989):
  ```lua
  function RosterBoard:PlaceCardInSlot(card, slot)
      -- ... existing logic ...
      
      -- Set proper frame hierarchy
      card:SetParent(slot)
      card:SetFrameStrata("MEDIUM")
      card:SetFrameLevel(slot:GetFrameLevel() + 1)  -- Above slot
      
      -- ... rest of placement logic ...
  end
  ```

- [ ] **Verify Slot Frame Levels** (lines 531-580):
  ```lua
  function RosterBoard:CreateFlatRoleSlot(...)
      local slot = CreateFrame("Frame", nil, parentContainer, "BackdropTemplate")
      
      -- Ensure slots are WAY above background
      slot:SetFrameLevel(parentContainer:GetFrameLevel() + 50)
      slot:SetFrameStrata("MEDIUM")
      
      -- ... rest of slot creation ...
  end
  ```

---

## Testing Plan

### Test Case 1: Bench Gap Fix
1. Open organizer with 5+ players on bench
2. Drag card from middle of bench
3. Drop on invalid slot (wrong role)
4. **Expected**: No gap appears in bench during rejection animation
5. **Expected**: Card smoothly animates back to exact original position

### Test Case 2: Slot Frame Level Fix
1. Place card in Tank slot
2. Drag card from Tank slot
3. Drop on invalid slot (e.g., Healer)
4. **Expected**: Card animates back to Tank slot
5. **Expected**: Card is fully visible on top of slot background
6. **Expected**: Card is clickable and draggable again

### Test Case 3: Cross-Location Drag
1. Drag card from bench to Tank slot (success)
2. Drag card from Tank slot to bench (success)
3. Drag card from bench to opt-out (success)
4. Drag card from opt-out to DPS slot (success)
5. **Expected**: All transitions work smoothly, no gaps, no rendering issues

### Test Case 4: Multiple Rapid Drags
1. Quickly drag and reject multiple cards
2. **Expected**: No orphaned cards, no layout corruption
3. **Expected**: All cards return to correct positions

---

## Visual Feedback Enhancement (Optional)

If implementing visual feedback during drag:

```lua
-- In LayoutBench()
for i, card in ipairs(self.benchCards) do
    if card.pendingRemoval then
        -- Dim the card's position in the list
        card:SetAlpha(0.3)
    else
        card:SetAlpha(1.0)
    end
    -- ... positioning logic ...
end
```

This makes it visually clear that a card is "being dragged" even though it stays in the list.

---

## Performance Impact

**Memory**: Negligible (a few boolean flags per card)
**CPU**: Actually BETTER (fewer array operations during drag)
**Complexity**: LOWER (simpler flow, less re-insertion logic)

---

## Migration Notes

**Breaking Changes**: None - this is purely internal refactoring.

**Compatibility**: Works with existing card placement and layout systems.

**Rollback**: Easy - revert to immediate removal pattern if issues arise.

---

## Success Criteria

✅ No gaps appear in bench during rejection  
✅ Cards render correctly after slot rejection  
✅ All drag scenarios work smoothly  
✅ Frame levels correct for all locations  
✅ No layout corruption under rapid use  
✅ Performance remains excellent (<2ms drag operations)

---

## References

- Working implementation: [`debug/drag_test_simple.lua`](../../../debug/drag_test_simple.lua)
- Current implementation: [`ui/organizer/rosterBoard.lua`](../../../ui/organizer/rosterBoard.lua) lines 914-1106
- Card creation: [`ui/organizer/playerCard.lua`](../../../ui/organizer/playerCard.lua) lines 208-250

---

## Next Steps

**Ready for Code mode implementation**. This plan provides complete specification for:
1. Two-phase removal system (prevent gaps)
2. Frame level restoration (fix rendering)
3. Comprehensive testing approach

Estimated implementation time: 30-45 minutes
Estimated testing time: 15-20 minutes
**Total**: ~1 hour to complete final 10% of drag system.