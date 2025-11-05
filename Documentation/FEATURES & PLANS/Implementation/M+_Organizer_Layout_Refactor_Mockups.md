# M+ Group Organizer - Layout Refactor Mockups

**Status**: Architecture Planning
**Date**: November 5, 2025
**Context**: Fixing critical layout overlaps and utilizing wasted space

---

## Current Problems (From Screenshot Analysis)

### Critical Issues
1. **Two Overlapping Bottom Bars**: 
   - Top bar: "Organize" dropdown + button + "Announce" + Raid/Guild checkboxes + "Add R..." button
   - Bottom bar: Status text ("M+ Group Organizer - Drag players...")
   - These bars overlap, creating visual confusion

2. **Truncated Button Text**: "Add R..." (should be "Add Roster" or similar)

3. **Wasted Space**: Large empty void in bottom-left under "M+ Grp. 1" panel

4. **Poor Button Grouping**: "Simple Sort" dropdown mixed with primary actions

5. **Status Text**: Currently button-like, should be plain label

---

## Option A: Three-Zone Layout (Recommended)

```
┌────────────────────────────────────────────────────────────────────┐
│  M+ Group Organizer                                    [✕] CLOSE   │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌─────────────────────────────────────────────┐   │
│  │  BENCH   │  │  M+ Grp. 1        │  M+ Grp. 2     │ ...     │   │
│  │          │  │                   │                │         │   │
│  │  Poll    │  │  [Tank Slot]      │  [Tank Slot]   │         │   │
│  │  End     │  │  [Healer Slot]    │  [Healer Slot] │         │   │
│  │  Clear   │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │ [Cards]  │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  └─────────────────────────────────────────────┘   │
│  └──────────┘                                                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  NOT PLAYING                                                  │ │
│  │  [Opt-out cards...]                                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────────────────┬──────────────────────────────┤
│  │ ZONE 1: PRIMARY ACTIONS         │ ZONE 2: SECONDARY ACTIONS    │
│  ├─────────────────────────────────┼──────────────────────────────┤
│  │ [Simple Sort ▼] [Organize]      │ [Announce] ☑Raid  ☑Guild    │
│  │ [Add Roster] [Add Raid]*        │                              │
│  └─────────────────────────────────┴──────────────────────────────┤
│  ZONE 3: STATUS BAR (non-interactive text)                        │
│  M+ Group Organizer - Drag players between bench and groups       │
└────────────────────────────────────────────────────────────────────┘
```

### Advantages
- **Uses Empty Space**: Bottom-left void now contains primary actions
- **Clear Separation**: Primary vs secondary actions visually distinct
- **No Overlaps**: Three separate zones prevent any collision
- **Readable Status**: Status text clearly separated as informational

### Layout Details
- **Zone 1 (Bottom-Left)**: 400px wide
  - "Simple Sort" dropdown: 130px
  - "Organize" button: 100px
  - "Add Roster" button: 90px
  - "Add Raid" button: 80px (debug mode only)
  
- **Zone 2 (Bottom-Right)**: Remaining width
  - "Announce" button: 90px
  - "Raid" checkbox: 60px
  - "Guild" checkbox: 60px

- **Zone 3 (Status Bar)**: Full width, 20px height
  - Plain text label (no button styling)
  - Centered or left-aligned

---

## Option B: Single Consolidated Bottom Bar

```
┌────────────────────────────────────────────────────────────────────┐
│  M+ Group Organizer                                    [✕] CLOSE   │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌─────────────────────────────────────────────┐   │
│  │  BENCH   │  │  M+ Grp. 1        │  M+ Grp. 2     │ ...     │   │
│  │          │  │                   │                │         │   │
│  │  Poll    │  │  [Tank Slot]      │  [Tank Slot]   │         │   │
│  │  End     │  │  [Healer Slot]    │  [Healer Slot] │         │   │
│  │  Clear   │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │ [Cards]  │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  └─────────────────────────────────────────────┘   │
│  └──────────┘                                                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  NOT PLAYING                                                  │ │
│  │  [Opt-out cards...]                                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
├────────────────────────────────────────────────────────────────────┤
│  [Simple Sort ▼] [Organize] [Announce] ☑Raid ☑Guild [Add Roster] │
│                                     Drag players to organize groups │
└────────────────────────────────────────────────────────────────────┘
```

### Advantages
- **Maximum Simplicity**: One bar, everything visible
- **Space Efficient**: Uses full horizontal width
- **Modern Design**: Similar to browser toolbars
- **Status Integrated**: Instruction text inline with controls

### Layout Details
- **Single Bottom Bar**: Full width, 32px height
  - Left side: Action buttons (left-aligned)
  - Right side: Status text (right-aligned, italic, smaller font)
  
- **Button Sizes**:
  - "Simple Sort" dropdown: 130px
  - "Organize" button: 100px
  - "Announce" button: 90px
  - Checkboxes: 60px each
  - "Add Roster": 90px

---

## Option C: Contextual Placement (Fixed)

```
┌────────────────────────────────────────────────────────────────────┐
│  M+ Group Organizer                    [Add Roster] [✕] CLOSE      │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌─────────────────────────────────────────────┐   │
│  │  BENCH   │  │  M+ Grp. 1        │  M+ Grp. 2     │ ...     │   │
│  │          │  │                   │                │         │   │
│  │  Poll    │  │  [Tank Slot]      │  [Tank Slot]   │         │   │
│  │  End     │  │  [Healer Slot]    │  [Healer Slot] │         │   │
│  │  Clear   │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │ [Cards]  │  │  [DPS Slot]       │  [DPS Slot]    │         │   │
│  │          │  └─────────────────────────────────────────────┘   │
│  └──────────┘                                                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  NOT PLAYING                                                  │ │
│  │  [Opt-out cards...]                                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
├────────────────────────────────────────────────────────────────────┤
│  [Simple Sort ▼] [Organize] [Announce] ☑Raid ☑Guild              │
├────────────────────────────────────────────────────────────────────┤
│  M+ Group Organizer - Drag players between bench and groups       │
└────────────────────────────────────────────────────────────────────┘
```

### Advantages
- **Minimal Changes**: Keeps current structure with fixes
- **Familiar Layout**: Users won't need to relearn
- **Clear Separation**: Actions in one bar, status in another
- **Top-Right Placement**: "Add Roster" near Close button (standard position)

### Layout Details
- **Title Bar**: Add "Add Roster" button (90px) before Close button
  
- **Action Bar**: Full width, 32px height
  - All action buttons left-aligned
  - No status text in this bar

- **Status Bar**: Full width, 20px height
  - Plain text label (no button styling)
  - Left-aligned with padding

---

## Comparison Matrix

| Feature | Option A (3-Zone) | Option B (Single Bar) | Option C (Contextual) |
|---------|-------------------|----------------------|----------------------|
| **Uses Empty Space** | ✅ Yes (bottom-left) | ❌ No | ❌ No |
| **Visual Hierarchy** | ✅ Strong (zones) | ⚠️ Moderate | ⚠️ Moderate |
| **Simplicity** | ⚠️ More complex | ✅ Very simple | ✅ Simple |
| **Space Efficiency** | ✅ Excellent | ✅ Excellent | ⚠️ Good |
| **Familiar to Users** | ❌ New layout | ⚠️ Different | ✅ Similar to current |
| **Implementation Effort** | ⚠️ Medium | ✅ Low | ✅ Low |
| **Scalability** | ✅ Easy to add buttons | ⚠️ Limited by width | ⚠️ Limited by width |
| **Status Text Clarity** | ✅ Dedicated zone | ⚠️ Inline/small | ✅ Dedicated bar |

---

## Recommendation

**Option A (Three-Zone Layout)** is recommended because:

1. **Solves Core Problem**: Utilizes the wasted bottom-left space
2. **Best Hierarchy**: Clear visual separation between primary/secondary actions
3. **Future-Proof**: Easy to add more buttons without crowding
4. **Professional**: Matches enterprise application standards
5. **No Overlaps**: Architectural solution prevents future collision issues

### Fallback Options
- **Option B**: If implementation time is critical (simplest to code)
- **Option C**: If user familiarity is highest priority (minimal changes)

---

## Implementation Plan (Option A)

### Phase 1: Remove Current Bottom Bar
- **File**: `ui/organizer/rosterBoard.lua`
- **Function**: `CreateBottomBar()` (lines 818-928)
- **Action**: Delete entire function

### Phase 2: Create Three-Zone System

#### Zone 1: Primary Actions (Bottom-Left)
```lua
-- Create left action panel
local leftActionPanel = CreateFrame("Frame", nil, windowFrame, "BackdropTemplate")
leftActionPanel:SetPoint("BOTTOMLEFT", windowFrame, "BOTTOMLEFT", 10, 40)
leftActionPanel:SetSize(400, 32)
-- Add buttons: Organize dropdown, Organize button, Add Roster, Add Raid
```

#### Zone 2: Secondary Actions (Bottom-Right)
```lua
-- Create right action panel
local rightActionPanel = CreateFrame("Frame", nil, windowFrame, "BackdropTemplate")
rightActionPanel:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -10, 40)
rightActionPanel:SetPoint("LEFT", leftActionPanel, "RIGHT", 10, 0)
rightActionPanel:SetHeight(32)
-- Add buttons: Announce, Raid checkbox, Guild checkbox
```

#### Zone 3: Status Bar (Very Bottom)
```lua
-- Create status bar (non-interactive)
local statusBar = CreateFrame("Frame", nil, windowFrame)
statusBar:SetPoint("BOTTOMLEFT", windowFrame, "BOTTOMLEFT", 10, 10)
statusBar:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -10, 10)
statusBar:SetHeight(20)

-- Status text label (NOT a button)
local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("LEFT", statusBar, "LEFT", 5, 0)
statusText:SetText("M+ Group Organizer - Drag players between bench and groups")
statusText:SetTextColor(0.7, 0.7, 0.7)  -- Grey, non-interactive appearance
```

### Phase 3: Update Layout Calculations
- Increase `totalHeight` by 20px to accommodate new status bar
- Adjust opt-out section positioning to sit above Zone 1/2

### Phase 4: Fix "Add Roster" Button Text
- Update button text from truncated "Add R..." to full "Add Roster"
- Set width to 90px (sufficient for full text)

---

## Next Steps

1. **User Approval**: Confirm Option A is acceptable
2. **Switch to Code Mode**: Implement the three-zone system
3. **Test Layout**: Verify no overlaps, all buttons readable
4. **Document**: Update architecture docs with new layout pattern
