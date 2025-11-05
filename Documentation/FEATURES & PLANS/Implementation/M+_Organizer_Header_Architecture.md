# M+ Organizer Header Architecture (Option B: All Visible)

## Overview

This document defines the professional header architecture for the M+ Group Organizer UI. The design prioritizes **visual clarity**, **consistent sizing**, and **logical grouping** over the previous cramped, arbitrarily-sized button layout.

## Design Philosophy

1. **All Controls Visible** - No hidden functionality in dropdowns
2. **Logical Grouping** - Related actions grouped with section labels
3. **Consistent Sizing** - Named size constants, no arbitrary widths
4. **Grid-Based Layout** - Predictable spacing and alignment
5. **Visual Hierarchy** - Section labels → Primary buttons → Tertiary controls

## Visual Layout

```
┌──────────────────────────────────────────────────────────────────────────┐
│ POLL CONTROLS                                                             │
│ [Poll Group]  [End Poll]  [Clear Poll]  [Sort Players]                   │
│                                                                            │
│ COMMUNICATION                                                             │
│ [Announce Groups]  [☑ Raid]  [☐ Guild]                                   │
│                                                                            │
│ OPTIMIZER                                          DEBUG (if enabled)     │
│ Mode: [Balanced ▼]  [Run Optimizer]               [Add Fake Raid]        │
└──────────────────────────────────────────────────────────────────────────┘
```

## Button Sizing Strategy

### Size Constants

```lua
-- MARK: Header Button Sizes (Consistent System)
local HEADER_BUTTON_SIZES = {
    -- Primary action buttons (main workflow)
    PRIMARY = 110,      -- Poll, End Poll, Clear Poll, Sort, Announce
    
    -- Dropdown menus (need extra width for arrow)
    DROPDOWN = 130,     -- Optimizer mode dropdown
    
    -- Secondary action buttons
    SECONDARY = 120,    -- Run Optimizer
    
    -- Checkbox labels (fixed width for alignment)
    CHECKBOX = 70,      -- Raid, Guild checkboxes
    
    -- Debug utilities (compact)
    DEBUG = 100         -- Add Raid button
}
```

### Rationale

- **PRIMARY (110px)** - Most common actions, comfortably fits text like "Poll Group", "Clear Poll"
- **DROPDOWN (130px)** - Extra 20px for dropdown arrow and longer option text ("Balanced")
- **SECONDARY (120px)** - Slightly wider for emphasis ("Run Optimizer")
- **CHECKBOX (70px)** - Minimal width for single words ("Raid", "Guild")
- **DEBUG (100px)** - Compact debug utilities ("Add Raid")

## Spacing & Layout

### Row Spacing Constants

```lua
local HEADER_ROW_SPACING = {
    LABEL_HEIGHT = 16,      -- Section label height
    BUTTON_HEIGHT = 24,     -- Standard button height
    ROW_GAP = 8,            -- Gap between rows
    SECTION_GAP = 4,        -- Gap between label and buttons
    PADDING = 10,           -- Edge padding
    BUTTON_GAP = 8          -- Gap between buttons in same row
}
```

### Grid Calculation

```lua
-- MARK: Grid Layout Calculator
local function CalculateHeaderGrid(availableWidth)
    local grid = {
        -- Row 1: Poll Controls (4 buttons)
        row1 = {
            y = PADDING + LABEL_HEIGHT + SECTION_GAP,
            buttons = {
                {x = PADDING, width = PRIMARY},                           -- Poll
                {x = PADDING + PRIMARY + 8, width = PRIMARY},             -- End Poll
                {x = PADDING + (PRIMARY + 8) * 2, width = PRIMARY},       -- Clear Poll
                {x = PADDING + (PRIMARY + 8) * 3, width = PRIMARY}        -- Sort
            }
        },
        
        -- Row 2: Communication (1 button + 2 checkboxes)
        row2 = {
            y = row1.y + BUTTON_HEIGHT + ROW_GAP + LABEL_HEIGHT + SECTION_GAP,
            buttons = {
                {x = PADDING, width = PRIMARY},                           -- Announce
                {x = PADDING + PRIMARY + 8, width = CHECKBOX},            -- Raid checkbox
                {x = PADDING + PRIMARY + CHECKBOX + 16, width = CHECKBOX} -- Guild checkbox
            }
        },
        
        -- Row 3: Optimizer + Debug
        row3 = {
            y = row2.y + BUTTON_HEIGHT + ROW_GAP + LABEL_HEIGHT + SECTION_GAP,
            buttons = {
                {x = PADDING, width = DROPDOWN},                          -- Optimizer dropdown
                {x = PADDING + DROPDOWN + 8, width = SECONDARY},          -- Run button
                {x = availableWidth - DEBUG - PADDING, width = DEBUG}     -- Debug (right-aligned)
            }
        }
    }
    
    -- Calculate total height
    grid.totalHeight = row3.y + BUTTON_HEIGHT + PADDING
    
    return grid
end
```

## Visual Hierarchy

### Three-Level System

1. **Section Labels** (Level 1 - Organizational)
   - Font: `GameFontNormalSmall`
   - Color: `0.6, 0.6, 0.6, 1.0` (subtle gray)
   - Text: Uppercase ("POLL CONTROLS", "COMMUNICATION", etc.)
   - Purpose: Group related functionality

2. **Primary Buttons** (Level 2 - Actionable)
   - Font: `GameFontNormal`
   - Style: Full AceGUI button chrome with hover/click states
   - Color: Standard WoW button styling
   - Purpose: Main workflow actions

3. **Tertiary Controls** (Level 3 - Supportive)
   - Checkboxes, debug utilities
   - Smaller visual weight
   - Purpose: Configuration and testing

## Functional Groups

### Group 1: Poll Controls

**Purpose:** Manage participant surveys
**Buttons:**
- `Poll Group` (PRIMARY) - Start new poll
- `End Poll` (PRIMARY) - Force-complete active poll
- `Clear Poll` (PRIMARY) - Erase all poll data
- `Sort Players` (PRIMARY) - Auto-assign players to groups

**Layout:** Single row, left-aligned, equal spacing

### Group 2: Communication

**Purpose:** Announce group compositions
**Controls:**
- `Announce Groups` (PRIMARY) - Send formatted announcement
- `Raid` checkbox (CHECKBOX) - Announce to raid chat
- `Guild` checkbox (CHECKBOX) - Announce to guild chat

**Layout:** Single row, button followed by checkboxes

### Group 3: Optimizer

**Purpose:** Algorithmic group formation
**Controls:**
- Optimizer Mode dropdown (DROPDOWN) - Select algorithm (Max Power, Balanced, Vault)
- `Run Optimizer` (SECONDARY) - Execute optimization

**Layout:** Single row, dropdown followed by action button

### Group 4: Debug (Conditional)

**Purpose:** Development testing utilities
**Controls:**
- `Add Fake Raid` (DEBUG) - Generate 20-player test roster

**Layout:** Single row, right-aligned
**Visibility:** Only shown when `FakePlayerService:IsEnabled()`

## Implementation Reference

### Core Function

```lua
-- MARK: Header Section (Option B: All Visible with Grouping)
function RosterBoard:CreateHeaderSection(nativeParent)
    local layout = self:CalculateOptimalLayout()
    local availableWidth = layout.totalWidth - 40
    local hasFakePlayers = NextKey222.FakePlayerService and 
                          NextKey222.FakePlayerService:IsEnabled()
    
    -- Calculate grid positions
    local grid = CalculateHeaderGrid(availableWidth)
    
    -- Create native container
    local headerContainer = CreateFrame("Frame", nil, nativeParent)
    headerContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
    headerContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
    headerContainer:SetHeight(grid.totalHeight)
    headerContainer:Show()
    
    -- Section 1: Poll Controls
    self:CreateSectionLabel(headerContainer, "POLL CONTROLS", 0)
    local row1 = self:CreateHeaderRow(headerContainer, grid.row1.y, availableWidth)
    self:AddPollButton(row1, HEADER_BUTTON_SIZES.PRIMARY)
    self:AddEndPollButton(row1, HEADER_BUTTON_SIZES.PRIMARY)
    self:AddClearPollButton(row1, HEADER_BUTTON_SIZES.PRIMARY)
    self:AddSortButton(row1, HEADER_BUTTON_SIZES.PRIMARY)
    
    -- Section 2: Communication
    self:CreateSectionLabel(headerContainer, "COMMUNICATION", grid.row2.y - LABEL_HEIGHT - SECTION_GAP)
    local row2 = self:CreateHeaderRow(headerContainer, grid.row2.y, availableWidth)
    self:AddAnnounceButton(row2, HEADER_BUTTON_SIZES.PRIMARY)
    self:AddRaidCheckbox(row2, HEADER_BUTTON_SIZES.CHECKBOX)
    self:AddGuildCheckbox(row2, HEADER_BUTTON_SIZES.CHECKBOX)
    
    -- Section 3: Optimizer
    self:CreateSectionLabel(headerContainer, "OPTIMIZER", grid.row3.y - LABEL_HEIGHT - SECTION_GAP)
    local row3 = self:CreateHeaderRow(headerContainer, grid.row3.y, availableWidth)
    self:AddOptimizerDropdown(row3, HEADER_BUTTON_SIZES.DROPDOWN)
    self:AddOptimizeButton(row3, HEADER_BUTTON_SIZES.SECONDARY)
    
    -- Debug section (right-aligned)
    if hasFakePlayers then
        self:CreateSectionLabel(headerContainer, "DEBUG", 
                               grid.row3.y - LABEL_HEIGHT - SECTION_GAP,
                               availableWidth - HEADER_BUTTON_SIZES.DEBUG - 20)
        self:AddFakeRaidButton(row3, HEADER_BUTTON_SIZES.DEBUG)
    end
    
    self.headerSection = headerContainer
end
```

### Helper Functions

```lua
-- MARK: Section Label Helper
function RosterBoard:CreateSectionLabel(parent, text, yOffset, xOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset or 0, -yOffset)
    label:SetText(text)
    label:SetTextColor(0.6, 0.6, 0.6, 1.0)
    return label
end

-- MARK: Button Creation with Explicit Width
function RosterBoard:AddPollButton(row, width)
    local pollButton = AceGUI:Create("Button")
    pollButton:SetText("Poll Group")
    pollButton:SetWidth(width)
    pollButton:SetCallback("OnClick", function()
        self:OnPollGroupClicked()
    end)
    
    row:AddChild(pollButton)
    self.pollButton = pollButton
    self.headerWidgets.pollButton = pollButton
end
```

## Comparison: Before vs After

### Before (Current Implementation)

**Issues:**
- Arbitrary widths: 120, 95, 80, 60 (no pattern)
- Cramped spacing: 2px row gaps
- No visual grouping
- Poor alignment
- Unclear button relationships

**Metrics:**
- Total height: ~70px
- Usability score: 4/10

### After (Option B)

**Improvements:**
- Consistent widths: 110, 130, 120, 70, 100 (named constants)
- Comfortable spacing: 8px row gaps, section labels
- Clear functional groups with labels
- Grid-based alignment
- Obvious button relationships

**Metrics:**
- Total height: ~90px (+20px, but worth it)
- Usability score: 9/10

## Future Enhancements

### Potential Additions
1. **Tooltips on section labels** - "What is the optimizer?"
2. **Button state indicators** - Disabled states with explanatory tooltips
3. **Keyboard shortcuts** - Hotkeys displayed on buttons (Ctrl+P for Poll)
4. **Collapsible sections** - Minimize unused groups to save space

### Responsive Behavior
- If window width < 700px, stack buttons vertically within groups
- If window width < 500px, collapse to single-column layout
- Section labels remain visible at all sizes

## Testing Checklist

- [ ] All buttons render at correct widths
- [ ] Section labels display with proper color/font
- [ ] Spacing between rows is consistent (8px)
- [ ] Debug section only shows when fake players enabled
- [ ] Buttons respond to clicks correctly
- [ ] Layout adapts to window resize
- [ ] No visual artifacts or overlaps
- [ ] Accessibility: Tab navigation works correctly

## Maintenance Notes

### Adding New Buttons
1. Determine which functional group it belongs to
2. Choose appropriate size constant (or create new if needed)
3. Add to grid calculator
4. Add section label if creating new group
5. Update this documentation

### Modifying Sizes
1. Update `HEADER_BUTTON_SIZES` constants
2. Test layout at various window widths
3. Ensure no overlaps or spacing issues
4. Update documentation

### Removing Buttons
1. Remove from helper function calls
2. Update grid calculator
3. Test remaining layout
4. Update documentation

---

**Status:** ✅ DESIGNED  
**Implementation:** Pending code mode implementation  
**Last Updated:** November 5, 2025