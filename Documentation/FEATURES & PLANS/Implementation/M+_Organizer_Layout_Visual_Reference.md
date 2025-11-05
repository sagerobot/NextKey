# M+ Organizer Layout Visual Reference

## Final Layout Architecture (After Fixes)

### Full Window Structure
```
┌──────────────────────────────────────────────────────────────────┐
│ M+ Group Organizer                                    [_][□][X] │ ← Window chrome (AceGUI Frame)
├──────────────────────────────────────────────────────────────────┤
│ HEADER SECTION (90px height)                                     │
│                                                                   │
│ POLL CONTROLS                                                    │
│ [Poll Group]  [End Poll]  [Clear Poll]  [Sort Players]          │
│                                                                   │
│ COMMUNICATION                                                    │
│ [Announce Groups]  [☑ Raid]  [☐ Guild]                          │
├──────────────────────────────────────────────────────────────────┤
│ ACTIVE POOL SECTION (550px height)                               │
│ ┌──────────┬──────────┬──────────┬──────────┬──────────────────┐ │
│ │  BENCH   │ Group 1  │ Group 2  │ Group 3  │ Group 4          │ │
│ │ (260px)  │ (180px)  │ (180px)  │ (180px)  │ (180px)          │ │
│ │          │          │          │          │                  │ │
│ │ Player1  │ [Tank]   │ [Tank]   │ [Tank]   │ [Tank]           │ │
│ │ Player2  │ [Healer] │ [Healer] │ [Healer] │ [Healer]         │ │
│ │ Player3  │ [DPS]    │ [DPS]    │ [DPS]    │ [DPS]            │ │
│ │ Player4  │ [DPS]    │ [DPS]    │ [DPS]    │ [DPS]            │ │
│ │ Player5  │ [DPS]    │ [DPS]    │ [DPS]    │ [DPS]            │ │
│ │ ...      │          │          │          │                  │ │
│ └──────────┴──────────┴──────────┴──────────┴──────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│ OPT-OUT SECTION (90px height)                                     │
│ Players who opted out: [Player6] [Player7]                       │
├──────────────────────────────────────────────────────────────────┤
│ BOTTOM BAR (42px height)                                          │
│ [Simple Sort ▼] [Organize]      [Announce] [☑ Raid] [☐ Guild]   │
├──────────────────────────────────────────────────────────────────┤
│ Status: M+ Group Organizer - Drag players between bench & groups │ ← Status bar (30px)
└──────────────────────────────────────────────────────────────────┘

Total Height: 90 + 550 + 90 + 42 + 30 = 802px
```

---

## Detailed Section Breakdown

### 1. Header Section (90px)

**Purpose**: Global controls for poll, communication, and organization

**Layout**: 3 rows with section labels
- Row 1 (Poll Controls): 4 buttons × 110px = 440px + spacing
- Row 2 (Communication): 1 button (110px) + 2 checkboxes (70px each) = 250px
- Row 3 (Optimizer): Dropdown (130px) + button (120px) = 250px

**Spacing**:
- Section label height: 16px
- Button row height: 24px
- Gap between sections: 8px
- Total: (16 + 4 + 24) × 2 rows + 8px gaps = ~90px

**Code Location**: `ui/organizer/rosterBoard.lua:CreateHeaderSection()`

---

### 2. Active Pool Section (550px)

**Purpose**: Bench + group slots for drag-and-drop organization

**Layout**: Horizontal columns
- Bench column: 260px width (native frame with scroll)
- Group columns: 180px each (dynamic 1-4 groups)
- Each group: 5 vertical slots (Tank, Healer, DPS×3)

**Spacing**:
- Padding between columns: 20px
- Slot height: 100px each
- Total bench/group area: 5 slots × 100px + title bars = ~550px

**Code Location**: 
- Bench: `ui/organizer/modules/benchManager.lua:create_native_bench_column()`
- Groups: `ui/organizer/modules/slotManager.lua:create_active_pool_section()`

---

### 3. Opt-Out Section (90px)

**Purpose**: Display players who declined to participate

**Layout**: Horizontal scrollable row
- Fixed height: 90px
- Horizontal card layout (20px height × compact mode)
- Scroll left/right if many opt-outs

**Code Location**: `ui/organizer/modules/slotManager.lua:create_opt_out_section()`

---

### 4. Bottom Bar (42px)

**Purpose**: Organization and announcement controls

**Layout**: Single unified container with flow layout
- Left section: Organize dropdown (130px) + button (110px)
- Right section: Announce button (110px) + checkboxes (70px × 2)
- Debug section: Add Raid button (100px) if fake players enabled

**Spacing**: 
- Container height: 32px (internal)
- Top margin: 10px
- Total: 42px

**Code Location**: `ui/organizer/rosterBoard.lua:CreateBottomBar()`

---

### 5. Status Bar (30px)

**Purpose**: Non-interactive informational text

**Layout**: Single line at window bottom
- Plain FontString (not a button)
- Gray text (0.7, 0.7, 0.7)
- Left-aligned with 5px padding

**Code Location**: `ui/organizer/rosterBoard.lua:CreateBottomBar()` (Zone 3)

---

## Button Sizing Standards

### Named Constants (MANDATORY)

```lua
local HEADER_BUTTON_SIZES = {
    PRIMARY = 110,      -- Most action buttons
    DROPDOWN = 130,     -- Dropdowns (need arrow space)
    SECONDARY = 120,    -- Emphasized actions
    CHECKBOX = 70,      -- Checkbox labels
    DEBUG = 100         -- Debug utilities
}
```

### Usage Table

| Control | Width | Constant | Text |
|---------|-------|----------|------|
| Poll Group | 110 | PRIMARY | "Poll Group" |
| End Poll | 110 | PRIMARY | "End Poll" |
| Clear Poll | 110 | PRIMARY | "Clear Poll" |
| Sort Players | 110 | PRIMARY | "Sort Players" |
| Announce Groups | 110 | PRIMARY | "Announce Groups" |
| Organize dropdown | 130 | DROPDOWN | "Simple Sort ▼" |
| Organize button | 110 | PRIMARY | "Organize" |
| Raid checkbox | 70 | CHECKBOX | "Raid" |
| Guild checkbox | 70 | CHECKBOX | "Guild" |
| Add Raid (debug) | 100 | DEBUG | "Add Raid" |

**Search Pattern**: All `SetWidth()` calls MUST use these constants, never hardcoded numbers.

---

## Anchoring Strategy

### Parent-Child Hierarchy

```
AceGUI Frame (window chrome)
└── frame.content (native frame container)
    ├── headerSection (native Frame)
    │   ├── pollLabel (FontString)
    │   ├── row1 (AceGUI SimpleGroup)
    │   │   ├── pollButton (AceGUI Button)
    │   │   ├── endPollButton
    │   │   ├── clearPollButton
    │   │   └── sortButton
    │   ├── commLabel (FontString)
    │   └── row2 (AceGUI SimpleGroup)
    │       ├── announceButton
    │       ├── raidCheckbox
    │       └── guildCheckbox
    │
    ├── activePoolSection (native Frame)
    │   ├── benchColumn (benchManager creates)
    │   │   ├── titleBar
    │   │   │   ├── titleLabel ("BENCH")
    │   │   │   └── inlineButtonRow (NOW EMPTY - buttons moved to header)
    │   │   └── scrollFrame
    │   │       └── scrollChild (card container)
    │   └── groupColumns[] (slotManager creates)
    │       ├── groupBackground (texture)
    │       ├── groupTitle (FontString)
    │       └── slots[5] (native frames)
    │
    ├── optOutSection (slotManager creates)
    │   └── scrollFrame
    │       └── scrollChild (card container)
    │
    ├── bottomBarContainer (native Frame)
    │   └── buttonRow (AceGUI SimpleGroup)
    │       ├── organizeDropdown
    │       ├── organizeButton
    │       ├── announceButton
    │       ├── raidCheckbox
    │       ├── guildCheckbox
    │       └── fakeRaidButton (conditional)
    │
    └── statusBar (native Frame)
        └── statusText (FontString)
```

### Positioning Rules

1. **Header**: Anchors to window top
   ```lua
   headerSection:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
   headerSection:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
   headerSection:SetHeight(90)
   ```

2. **Active Pool**: Anchors below header
   ```lua
   activePoolSection:SetPoint("TOPLEFT", headerSection, "BOTTOMLEFT", 0, -10)
   activePoolSection:SetPoint("TOPRIGHT", headerSection, "BOTTOMRIGHT", 0, -10)
   activePoolSection:SetHeight(550)
   ```

3. **Opt-Out**: Anchors below active pool
   ```lua
   optOutSection:SetPoint("TOPLEFT", activePoolSection, "BOTTOMLEFT", 0, -10)
   optOutSection:SetPoint("TOPRIGHT", activePoolSection, "BOTTOMRIGHT", 0, -10)
   optOutSection:SetHeight(90)
   ```

4. **Bottom Bar**: Anchors below opt-out
   ```lua
   bottomBarContainer:SetPoint("TOPLEFT", optOutSection, "BOTTOMLEFT", 10, -10)
   bottomBarContainer:SetPoint("TOPRIGHT", optOutSection, "BOTTOMRIGHT", -10, -10)
   bottomBarContainer:SetHeight(32)
   ```

5. **Status Bar**: Anchors to window bottom
   ```lua
   statusBar:SetPoint("BOTTOMLEFT", windowFrame, "BOTTOMLEFT", 10, 10)
   statusBar:SetPoint("BOTTOMRIGHT", windowFrame, "BOTTOMRIGHT", -10, 10)
   statusBar:SetHeight(20)
   ```

**Critical**: Each section anchors to the PREVIOUS section, creating a vertical chain.

---

## Before/After Comparison

### BEFORE (Current Broken State)

**Issues**:
- Header: 1px spacer (no controls visible)
- Bench: ~500px empty space after title
- Bottom bar: All buttons overlapping (dual-panel conflict)
- Layout calculation: `totalHeight = 720px` (missing header space)

**Visual**: 
```
[Tiny spacer]
[BENCH]
[Massive empty space]
[Player cards]
[Opt-out]
[OVERLAPPING BUTTONS CHAOS]
[Status]
```

### AFTER (Fixed State)

**Improvements**:
- Header: 90px with 3 organized rows of controls
- Bench: Title immediately above cards (8px gap)
- Bottom bar: Single container, no overlaps
- Layout calculation: `totalHeight = 802px` (correct)

**Visual**: See full diagram at top of document

---

## Implementation Checklist

### Phase 1: Bottom Bar Fix
- [ ] Remove dual-panel system (lines 831-941 in rosterBoard.lua)
- [ ] Create single `bottomBarContainer` with unified button row
- [ ] Test: All buttons visible and properly spaced

### Phase 2: Bench Empty Space Fix
- [ ] Change scroll frame anchor from hardcoded offset to titleBar-relative
- [ ] Add debug logging for titleBar height measurement
- [ ] Test: No empty space between title and first card

### Phase 3: Header Restoration
- [ ] Replace 1px spacer with full 90px header
- [ ] Create 3 rows with section labels
- [ ] Move Poll/End/Clear buttons from bench title to header
- [ ] Remove inline button row from benchManager.lua (lines 368-411)
- [ ] Test: All header buttons functional

### Phase 4: Layout Calculation Fix
- [ ] Update `headerHeight = 90` (was 10)
- [ ] Update `bottomBarHeight = 42` (was 40)
- [ ] Verify `totalHeight = 802px`
- [ ] Test: Window height matches content exactly

### Phase 5: Button Sizing Validation
- [ ] Define `HEADER_BUTTON_SIZES` constants
- [ ] Replace all hardcoded widths with constants
- [ ] Test: All buttons use correct sizes per table above

### Phase 6: Full Testing
- [ ] Visual: No overlaps, proper spacing
- [ ] Functional: All buttons work correctly
- [ ] Responsive: Layout adapts to 1-4 groups dynamically

---

## Success Criteria

✅ **Layout is correct** when:
1. Screenshot matches this document's top diagram exactly
2. All buttons visible with proper spacing (no overlaps)
3. No empty space in any section
4. Window height = 802px (for 4 groups)
5. All controls functional with correct callbacks

**Final Verification**: Close/reopen organizer 3 times - layout should be identical each time.

---

**Status**: 📐 VISUAL REFERENCE COMPLETE  
**Usage**: Reference this document during implementation in Code mode  
**Last Updated**: November 5, 2025