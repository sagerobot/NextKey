# M+ Group Organizer - Comprehensive Fix Plan

**Status**: Architecture Planning
**Date**: November 5, 2025
**Context**: Fixing all remaining layout issues after three-zone implementation

---

## Identified Issues (From Screenshot Analysis)

### Issue 1: Bench Width Insufficient ⚠️ HIGH PRIORITY
**Problem**: Player cards (200px) + inline buttons (60+45+45=150px) + borders/padding exceed 240px bench width
**Symptoms**: 
- Poll/End/Clear buttons cut off on right edge
- Player cards clipping on right edge
**Root Cause**: Bench width calculation doesn't account for:
- Button row width (150px)
- Card width (200px)
- Borders (8px left + 8px right = 16px)
- Internal padding (10px left + 10px right = 20px)
**Required Width**: 200px (cards) + 36px (borders + padding) = 236px minimum
**Better Width**: 260px (cards) or move buttons outside bench area

**Proposed Solution**: 
- Option A: Increase bench width to 260px
- Option B: Move Poll/End/Clear buttons to a separate control panel above bench
- **Recommended**: Option A (simpler, maintains contextual placement)

### Issue 2: Opt-Out Section Vertical Positioning ⚠️ CRITICAL
**Problem**: "NOT PLAYING" section overlaps with Zone 1/Zone 2 action panels
**Symptoms**: Label and action bars occupy same vertical space
**Root Cause**: Opt-out section anchored too low, doesn't account for three-zone layout height
**Current Anchoring**: Unknown (need to check CreateOptOutSection)
**Required Fix**: Anchor opt-out section ABOVE the three-zone layout

**Proposed Solution**:
```lua
-- Opt-out section should be anchored to:
-- TOP: Below active pool section
-- BOTTOM: Above Zone 1/Zone 2 action panels (not above status bar)
optOutSection:SetPoint("TOPLEFT", activePoolSection, "BOTTOMLEFT", 0, -10)
optOutSection:SetPoint("TOPRIGHT", activePoolSection, "BOTTOMRIGHT", 0, -10)
optOutSection:SetPoint("BOTTOM", leftActionPanel, "TOP", 0, 10)  -- Above Zone 1
```

### Issue 3: Action Bar Vertical Spacing 🔧 MEDIUM PRIORITY
**Problem**: Three-zone layout positioned without accounting for opt-out section height
**Symptoms**: Content sections squeezed, overlapping elements
**Root Cause**: Layout calculations don't properly allocate space for all sections
**Current Heights**:
- Header: 10px
- Groups: 550px
- Action bars: 70px
- Opt-out: 100px (allocated but not positioned correctly)

**Proposed Solution**:
Recalculate vertical layout:
```
┌────────────────────────────────────┐
│ Title Bar (AceGUI chrome)          │ 30px
├────────────────────────────────────┤
│ Header Spacer                      │ 10px
├────────────────────────────────────┤
│ Active Pool (Bench + Groups)       │ 550px
├────────────────────────────────────┤
│ Opt-Out Section ("NOT PLAYING")    │ 100px
├────────────────────────────────────┤
│ Zone 1 + Zone 2 (Action Panels)    │ 40px (32 + 8 spacing)
├────────────────────────────────────┤
│ Zone 3 (Status Bar)                │ 30px (20 + 10 spacing)
├────────────────────────────────────┤
│ Status Bar (AceGUI chrome)         │ 20px
└────────────────────────────────────┘
Total: 780px (was ~770px, needs increase)
```

### Issue 4: Bench Inline Buttons Too Wide 🎨 LOW PRIORITY
**Problem**: Button row (160px) + card width (200px) = 360px, but bench is 240px
**Symptoms**: Buttons overlap bench border
**Root Cause**: Button widths (60, 45, 45) optimized for readability but too wide for container

**Proposed Solution**:
- Option A: Reduce button widths (Poll: 50px, End: 40px, Clear: 40px = 130px total)
- Option B: Increase bench width to 260px (accommodates current button sizes)
- **Recommended**: Option B (maintains readability)

### Issue 5: Zone 1/Zone 2 Horizontal Spacing 🔧 MEDIUM PRIORITY
**Problem**: Gap between Zone 1 and Zone 2 may be too narrow or wide
**Symptoms**: Unclear from screenshot, needs verification
**Current**: Zone 2 anchored with 10px gap to Zone 1
**Proposed**: Maintain 10px gap, but ensure Zone 2 doesn't extend beyond window edge

### Issue 6: Player Card Content Overflow 🎨 LOW PRIORITY
**Problem**: Player card content (roles, name, keystone, IO) may overflow 200px width
**Symptoms**: Text truncation, icon crowding
**Root Cause**: Compact card layout with many elements
**Current Layout**: 3 role icons (54px) + name (55px) + separator (10px) + keystone (45px) + IO = ~180px
**Card Width**: 200px (should be sufficient)
**Verification Needed**: Check if content is actually overflowing or if it's just the bench container

---

## Comprehensive Fix Implementation Plan

### Phase 1: Bench Width Adjustment 🔧
**File**: `ui/organizer/rosterBoard.lua` (line 346)
**Change**: Increase `benchWidth` from 240 to 260

**Impact**:
- Bench container: 260px
- Player cards: 200px (fits comfortably with 8+10px left, 8+10px right padding = 236px used)
- Button row: 160px (fits with margins)

### Phase 2: Opt-Out Section Repositioning 🔧
**File**: `ui/organizer/modules/slotManager.lua` (SlotManager:create_opt_out_section)
**Change**: Adjust vertical anchoring to sit ABOVE Zone 1/Zone 2

**New Anchoring**:
```lua
-- Anchor below active pool
optOutFrame:SetPoint("TOPLEFT", activePoolSection, "BOTTOMLEFT", 10, -10)
optOutFrame:SetPoint("TOPRIGHT", activePoolSection, "BOTTOMRIGHT", -10, -10)
-- Set fixed height
optOutFrame:SetHeight(90)
```

**Then in CreateBottomBar**:
```lua
-- Zone 1 anchored below opt-out section
leftActionPanel:SetPoint("TOPLEFT", optOutSection, "BOTTOMLEFT", 0, -10)
```

### Phase 3: Layout Height Recalculation 🔧
**File**: `ui/organizer/rosterBoard.lua` (line 336-354)
**Change**: Adjust `totalHeight` calculation

**New Calculation**:
```lua
local headerHeight = 10
local groupHeight = 550
local optOutHeight = 90
local actionBarHeight = 40  -- Zone 1 + Zone 2
local statusBarHeight = 30  -- Zone 3
local totalHeight = headerHeight + groupHeight + optOutHeight + actionBarHeight + statusBarHeight
-- Total: 720px (more compact than before)
```

### Phase 4: Button Width Verification 🎨
**File**: `ui/organizer/modules/benchManager.lua` (line 376-406)
**Change**: Verify button widths fit within 260px bench

**Current**:
- Poll: 60px
- End: 45px
- Clear: 45px
- Total: 150px
- Available: 260 - 20 (padding) - 16 (borders) = 224px ✅ FITS

### Phase 5: Zone Positioning Verification 🔧
**File**: `ui/organizer/rosterBoard.lua` (CreateBottomBar)
**Change**: Ensure zones don't overlap with content

**Zone 1 Anchoring** (verify):
```lua
leftActionPanel:SetPoint("BOTTOMLEFT", windowFrame, "BOTTOMLEFT", 10, 40)
-- Should instead be anchored to:
leftActionPanel:SetPoint("TOPLEFT", optOutSection, "BOTTOMLEFT", 10, -10)
```

**Zone 2 Anchoring** (verify):
```lua
rightActionPanel:SetPoint("LEFT", leftActionPanel, "RIGHT", 10, 0)
rightActionPanel:SetPoint("TOPRIGHT", optOutSection, "BOTTOMRIGHT", -10, -10)
```

**Zone 3 Anchoring** (keep as-is):
```lua
statusBar:SetPoint("BOTTOMLEFT", windowFrame, "BOTTOMLEFT", 10, 10)
statusBar:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -10, 10)
```

---

## Implementation Order (Critical Path)

1. **Phase 1**: Increase bench width to 260px ✅ Quick fix
2. **Phase 3**: Recalculate totalHeight ✅ Foundation fix
3. **Phase 2**: Reposition opt-out section ⚠️ Critical for layout
4. **Phase 5**: Fix zone anchoring ⚠️ Prevents overlaps
5. **Phase 4**: Verify button widths ✅ Validation only

---

## Testing Checklist

After implementation, verify:
- [ ] Bench Poll/End/Clear buttons fully visible
- [ ] Player cards not clipped on right edge
- [ ] "NOT PLAYING" section clearly separated from action zones
- [ ] Zone 1 and Zone 2 properly aligned horizontally
- [ ] Zone 3 status bar at very bottom
- [ ] No vertical overlaps between sections
- [ ] Window height appropriate (not too tall/short)
- [ ] All text readable, no truncation

---

## Expected Result

```
┌──────────────────────────────────────────────────────────────┐
│  M+ Group Organizer                              [✕] CLOSE   │
├──────────────────────────────────────────────────────────────┤
│                                                               │  10px spacer
│  ┌─────────┐  ┌────────────────────────────────────────┐    │
│  │ BENCH   │  │  M+ Grp. 1  │  M+ Grp. 2  │  M+ Grp. 3 │    │
│  │ Poll End│  │             │             │            │    │  550px
│  │ Clear   │  │  [Slots]    │  [Slots]    │  [Slots]   │    │
│  │ [Cards] │  │             │             │            │    │
│  └─────────┘  └────────────────────────────────────────┘    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  NOT PLAYING                                          │   │  90px
│  │  [Opt-out cards...]                                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌────────────────────────┬─────────────────────────────┐   │
│  │ Zone 1 (Primary)       │ Zone 2 (Secondary)           │   │  40px
│  │ [Sort▼] [Organize]     │ [Announce] ☑Raid  ☑Guild    │   │
│  └────────────────────────┴─────────────────────────────┘   │
│                                                               │  30px
│  Status: M+ Group Organizer - Drag players...                │
└──────────────────────────────────────────────────────────────┘
Total: ~720px
```

---

## Next Steps

1. Switch to Code mode
2. Apply all five phases in order
3. Test in-game with `/reload` + `/nk org`
4. Verify all checklist items pass
