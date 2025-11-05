# M+ Organizer Layout Fix Plan - URGENT

## Status: 🔴 CRITICAL - Production Layout Broken

**Date**: November 5, 2025  
**Priority**: BLOCKER  
**Affects**: All organizer UI functionality  
**Estimated Fix Time**: 2-3 hours

---

## Critical Issues Identified

### Issue 1: Bottom Bar Button Overlap (BLOCKER)
**Severity**: 🔴 CRITICAL  
**Location**: `ui/organizer/rosterBoard.lua:822-967` (CreateBottomBar)  
**Visual Evidence**: Screenshot shows all bottom buttons stacked on top of each other

**Problem**:
- Two separate native frames (`leftActionPanel` + `rightActionPanel`) both anchor to opt-out section
- Both panels start at same X position (TOPLEFT, TOPRIGHT of opt-out)
- Their AceGUI button rows overlap because parent panels don't respect each other's space

**Current Code**:
```lua
-- Line 831-840: Left panel
local leftActionPanel = CreateFrame(...)
leftActionPanel:SetPoint("TOPLEFT", self.optOutSection, "BOTTOMLEFT", 10, -10)
leftActionPanel:SetSize(400, 32)

-- Line 892-895: Right panel
local rightActionPanel = CreateFrame(...)
rightActionPanel:SetPoint("TOPRIGHT", self.optOutSection, "BOTTOMRIGHT", -10, -10)
rightActionPanel:SetPoint("LEFT", leftActionPanel, "RIGHT", 10, 0)  -- CONFLICT!
```

**Root Cause**: Right panel anchors to BOTH opt-out (TOPRIGHT) AND left panel (LEFT), creating geometry conflict.

---

### Issue 2: Massive Empty Space in Bench (~500px)
**Severity**: 🔴 CRITICAL  
**Location**: `ui/organizer/modules/benchManager.lua:414-416` (scroll frame positioning)  
**Visual Evidence**: Huge gap between "BENCH" title and first player card

**Problem**:
- Scroll frame positioned 40px below title bar (line 415: `-40`)
- But layout calculations suggest bench should start much higher
- Empty space indicates Y-offset calculation error or parent frame size mismatch

**Current Code**:
```lua
-- Line 414-416
local scrollFrame = CreateFrame("ScrollFrame", nil, bench, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -40)  -- Only 40px offset!
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
```

**Suspect**: Bench frame height (line 346: 540px) may be incorrect, OR parent frame positioning is off.

---

### Issue 3: Removed Header Section
**Severity**: 🟡 MAJOR  
**Location**: `ui/organizer/rosterBoard.lua:410-425` (CreateHeaderSection)  
**Design Violation**: Contradicts `M+_Organizer_Header_Architecture.md`

**Problem**:
- Header intentionally replaced with 1px spacer
- All buttons moved to "contextual" locations (bench title, bottom bar)
- Result: No global controls visible, poor UX

**Current Code**:
```lua
-- Line 416-422: Minimal spacer
local headerSpacer = CreateFrame("Frame", nil, nativeParent)
headerSpacer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
headerSpacer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
headerSpacer:SetHeight(1)  -- MINIMAL!
```

**Impact**: Users must scroll/hunt for critical controls (Poll, Organize, Announce).

---

### Issue 4: Bottom Bar Anchoring Failure
**Severity**: 🔴 CRITICAL  
**Location**: `ui/organizer/rosterBoard.lua:831-893` (zone positioning)

**Problem**:
- Bottom bar attempts to position relative to opt-out section
- But opt-out positioning is dynamic (depends on player count)
- Layout calculations don't account for bottom bar height properly

**Current Layout Calculation** (line 336-366):
```lua
local headerHeight = 10      -- Should be ~90px (full header)
local groupHeight = 550
local optOutHeight = 90
local actionBarHeight = 40   -- Zones 1+2
local statusBarHeight = 30   -- Zone 3

local totalHeight = headerHeight + groupHeight + optOutHeight + actionBarHeight + statusBarHeight
-- Result: 10 + 550 + 90 + 40 + 30 = 720px
-- WRONG: Should be ~90 + 550 + 90 + 40 + 30 = 800px
```

**Root Cause**: `headerHeight = 10` hardcoded for spacer, not real header.

---

## Architectural Fix Strategy

### Priority Order
1. **Fix Bottom Bar Overlap** (30 min) - Unblocks testing
2. **Fix Bench Empty Space** (20 min) - Restores usability
3. **Restore Proper Header** (60 min) - Implements design spec
4. **Fix Layout Calculations** (30 min) - Ensures consistency
5. **Validate Button Sizing** (20 min) - Final polish

---

## Phase 1: Fix Bottom Bar Overlap (IMMEDIATE)

### Solution: Single Container with Horizontal Layout

**Replace dual-panel system with unified approach:**

```lua
-- MARK: Unified Bottom Bar (Phase 1 Fix)
function RosterBoard:CreateBottomBar(nativeParent)
    local layout = self:CalculateOptimalLayout()
    local windowFrame = self.mainFrame and self.mainFrame.frame or nativeParent
    local hasFakePlayers = NextKey222.FakePlayerService and NextKey222.FakePlayerService:IsEnabled()
    
    -- SINGLE unified container
    local bottomBarContainer = CreateFrame("Frame", nil, windowFrame, "BackdropTemplate")
    bottomBarContainer:SetPoint("TOPLEFT", self.optOutSection, "BOTTOMLEFT", 10, -10)
    bottomBarContainer:SetPoint("TOPRIGHT", self.optOutSection, "BOTTOMRIGHT", -10, -10)
    bottomBarContainer:SetHeight(32)  -- Single row
    bottomBarContainer:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bottomBarContainer:Show()
    
    -- Single AceGUI row for ALL buttons
    local buttonRow = AceGUI:Create("SimpleGroup")
    buttonRow:SetLayout("Flow")
    buttonRow.frame:SetParent(bottomBarContainer)
    buttonRow.frame:SetPoint("LEFT", bottomBarContainer, "LEFT", 8, 0)
    buttonRow.frame:SetWidth(layout.totalWidth - 40)  -- Full width minus padding
    buttonRow.frame:SetHeight(26)
    buttonRow.frame:Show()
    
    -- Left section: Organize controls
    local organizeDropdown = AceGUI:Create("Dropdown")
    organizeDropdown:SetLabel("")
    organizeDropdown:SetList({
        simple_sort = "Simple Sort",
        max_power = "Max Power",
        balanced = "Balanced",
        vault = "Vault Focused"
    })
    organizeDropdown:SetValue("simple_sort")
    organizeDropdown:SetWidth(130)  -- DROPDOWN constant
    buttonRow:AddChild(organizeDropdown)
    
    local organizeButton = AceGUI:Create("Button")
    organizeButton:SetText("Organize")
    organizeButton:SetWidth(110)  -- PRIMARY constant
    buttonRow:AddChild(organizeButton)
    
    -- Spacer (pushes announce to right)
    local spacer = AceGUI:Create("Label")
    spacer:SetWidth(20)
    buttonRow:AddChild(spacer)
    
    -- Right section: Announce controls
    local announceButton = AceGUI:Create("Button")
    announceButton:SetText("Announce")
    announceButton:SetWidth(110)  -- PRIMARY constant
    buttonRow:AddChild(announceButton)
    
    local raidCheckbox = AceGUI:Create("CheckBox")
    raidCheckbox:SetLabel("Raid")
    raidCheckbox:SetValue(true)
    raidCheckbox:SetWidth(70)  -- CHECKBOX constant
    buttonRow:AddChild(raidCheckbox)
    
    local guildCheckbox = AceGUI:Create("CheckBox")
    guildCheckbox:SetLabel("Guild")
    guildCheckbox:SetValue(false)
    guildCheckbox:SetWidth(70)  -- CHECKBOX constant
    buttonRow:AddChild(guildCheckbox)
    
    -- Debug section (if enabled)
    if hasFakePlayers then
        local debugSpacer = AceGUI:Create("Label")
        debugSpacer:SetWidth(10)
        buttonRow:AddChild(debugSpacer)
        
        local fakeRaidButton = AceGUI:Create("Button")
        fakeRaidButton:SetText("Add Raid")
        fakeRaidButton:SetWidth(100)  -- DEBUG constant
        buttonRow:AddChild(fakeRaidButton)
    end
    
    -- Store references
    self.bottomBarContainer = bottomBarContainer
    self.bottomButtonRow = buttonRow
end
```

**Key Changes**:
1. Single container spans full width
2. Single button row prevents overlap
3. Flow layout handles spacing automatically
4. No geometry conflicts

---

## Phase 2: Fix Bench Empty Space

### Investigation Required

**Diagnosis Steps**:
1. Log bench frame height at creation: `Debug:Dev("bench_height", bench:GetHeight())`
2. Log scroll frame actual position: `Debug:Dev("scroll_pos", scrollFrame:GetTop(), scrollFrame:GetBottom())`
3. Log title bar height: `Debug:Dev("title_height", titleBar:GetHeight())`

**Hypothesis**: Title bar taking more space than expected (24px declared, but AceGUI widgets may expand it).

**Potential Fix**:
```lua
-- In benchManager.lua:414
-- BEFORE: scrollFrame:SetPoint("TOPLEFT", 10, -40)
-- AFTER: Anchor to titleBar bottom
scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -8)  -- 8px gap
scrollFrame:SetPoint("BOTTOMRIGHT", bench, "BOTTOMRIGHT", -30, 10)
```

**Verification**: Measure actual titleBar bottom position dynamically instead of hardcoding offset.

---

## Phase 3: Restore Proper Header

### Implementation: Header Architecture Document

**Follow `M+_Organizer_Header_Architecture.md` specification exactly:**

```lua
-- MARK: Header Section (Restored Per Architecture Doc)
function RosterBoard:CreateHeaderSection(nativeParent)
    local HEADER_BUTTON_SIZES = {
        PRIMARY = 110,
        DROPDOWN = 130,
        SECONDARY = 120,
        CHECKBOX = 70,
        DEBUG = 100
    }
    
    local layout = self:CalculateOptimalLayout()
    local availableWidth = layout.totalWidth - 40
    
    -- Create header container (NOT 1px spacer!)
    local headerContainer = CreateFrame("Frame", nil, nativeParent)
    headerContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -10)
    headerContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -10, -10)
    headerContainer:SetHeight(90)  -- Proper height for 3-row layout
    headerContainer:Show()
    
    -- Section 1: Poll Controls (Row 1)
    local pollLabel = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pollLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, 0)
    pollLabel:SetText("POLL CONTROLS")
    pollLabel:SetTextColor(0.6, 0.6, 0.6, 1.0)
    
    local row1 = AceGUI:Create("SimpleGroup")
    row1:SetLayout("Flow")
    row1.frame:SetParent(headerContainer)
    row1.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -20)
    row1.frame:SetWidth(availableWidth)
    row1.frame:SetHeight(24)
    row1.frame:Show()
    
    -- Poll button
    local pollButton = AceGUI:Create("Button")
    pollButton:SetText("Poll Group")
    pollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
    pollButton:SetCallback("OnClick", function() self:OnPollGroupClicked() end)
    row1:AddChild(pollButton)
    self.pollButton = pollButton
    
    -- End Poll button
    local endPollButton = AceGUI:Create("Button")
    endPollButton:SetText("End Poll")
    endPollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
    endPollButton:SetCallback("OnClick", function() self:OnEndPollClicked() end)
    row1:AddChild(endPollButton)
    
    -- Clear Poll button
    local clearPollButton = AceGUI:Create("Button")
    clearPollButton:SetText("Clear Poll")
    clearPollButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
    clearPollButton:SetCallback("OnClick", function() self:OnClearPollClicked() end)
    row1:AddChild(clearPollButton)
    
    -- Sort button (NOT in bottom bar anymore)
    local sortButton = AceGUI:Create("Button")
    sortButton:SetText("Sort Players")
    sortButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
    sortButton:SetCallback("OnClick", function() self:ExecuteSimpleSort() end)
    row1:AddChild(sortButton)
    
    -- Section 2: Communication (Row 2)
    local commLabel = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    commLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -52)
    commLabel:SetText("COMMUNICATION")
    commLabel:SetTextColor(0.6, 0.6, 0.6, 1.0)
    
    local row2 = AceGUI:Create("SimpleGroup")
    row2:SetLayout("Flow")
    row2.frame:SetParent(headerContainer)
    row2.frame:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 0, -72)
    row2.frame:SetWidth(availableWidth)
    row2.frame:SetHeight(24)
    row2.frame:Show()
    
    -- Announce button
    local announceButton = AceGUI:Create("Button")
    announceButton:SetText("Announce Groups")
    announceButton:SetWidth(HEADER_BUTTON_SIZES.PRIMARY)
    announceButton:SetCallback("OnClick", function() self:OnAnnounceClicked() end)
    row2:AddChild(announceButton)
    self.announceButton = announceButton
    
    -- Raid checkbox
    local raidCheckbox = AceGUI:Create("CheckBox")
    raidCheckbox:SetLabel("Raid")
    raidCheckbox:SetValue(true)
    raidCheckbox:SetWidth(HEADER_BUTTON_SIZES.CHECKBOX)
    row2:AddChild(raidCheckbox)
    
    -- Guild checkbox
    local guildCheckbox = AceGUI:Create("CheckBox")
    guildCheckbox:SetLabel("Guild")
    guildCheckbox:SetValue(false)
    guildCheckbox:SetWidth(HEADER_BUTTON_SIZES.CHECKBOX)
    row2:AddChild(guildCheckbox)
    
    self.headerSection = headerContainer
    self.headerWidgets = {pollButton, endPollButton, clearPollButton, sortButton, announceButton, raidCheckbox, guildCheckbox, row1, row2}
    
    Debug:Dev("organizer_ui", "Created full header section with 3-row layout")
end
```

**Critical Note**: This removes Poll/End/Clear buttons from bench title bar (benchManager.lua:368-411).

---

## Phase 4: Fix Layout Calculations

### Update Height Formula

**In `RosterBoard:CalculateOptimalLayout()` (line 336-366):**

```lua
function RosterBoard:CalculateOptimalLayout()
    local benchPlayers = self:GetBenchPlayers() or {}
    local groupedPlayers = self:GetGroupedPlayers() or {}
    local playerCount = #benchPlayers + #groupedPlayers
    
    local neededGroups = math.max(1, math.min(math.ceil(playerCount / 5), 4))
    
    local columnWidth = 180
    local benchWidth = 260
    local padding = 20
    
    -- FIXED HEIGHT CALCULATIONS
    local headerHeight = 90        -- CORRECTED: Full header with 3 rows
    local groupHeight = 550        -- Unchanged
    local optOutHeight = 90        -- Unchanged
    local bottomBarHeight = 42     -- Single row (32px + 10px spacing)
    local statusBarHeight = 30     -- Zone 3 (unchanged)
    
    local totalWidth = (columnWidth * neededGroups) + benchWidth + (padding * 3)
    local totalHeight = headerHeight + groupHeight + optOutHeight + bottomBarHeight + statusBarHeight
    -- Result: 90 + 550 + 90 + 42 + 30 = 802px (CORRECT)
    
    return {
        groupColumns = neededGroups,
        columnWidth = columnWidth,
        benchWidth = benchWidth,
        totalWidth = totalWidth,
        totalHeight = totalHeight,
        headerHeight = headerHeight  -- NEW: Export for positioning
    }
end
```

---

## Phase 5: Validate Button Sizing

### Size Constant Checklist

**Verify ALL button creations use named constants:**

| Button | Current Width | Should Be | Constant |
|--------|--------------|-----------|----------|
| Poll Group | ??? | 110 | PRIMARY |
| End Poll | ??? | 110 | PRIMARY |
| Clear Poll | ??? | 110 | PRIMARY |
| Sort Players | ??? | 110 | PRIMARY |
| Announce Groups | ??? | 110 | PRIMARY |
| Organize dropdown | ??? | 130 | DROPDOWN |
| Organize button | ??? | 110 | PRIMARY |
| Raid checkbox | ??? | 70 | CHECKBOX |
| Guild checkbox | ??? | 70 | CHECKBOX |
| Add Raid (debug) | ??? | 100 | DEBUG |

**Search Pattern**: `SetWidth\((\d+)\)` in `rosterBoard.lua` and `benchManager.lua`

---

## Phase 6: Testing Plan

### Visual Verification
- [ ] All buttons visible and not overlapping
- [ ] No empty space between BENCH title and cards
- [ ] Header shows 3 rows of controls
- [ ] Bottom bar positioned correctly below opt-out
- [ ] Window height matches content (no scroll bars on main frame)

### Functional Verification
- [ ] Poll button starts survey
- [ ] End/Clear buttons work correctly
- [ ] Sort button executes organization
- [ ] Announce button sends messages
- [ ] Checkboxes toggle correctly
- [ ] Add Raid button (debug) creates fake players

### Responsive Verification
- [ ] Layout adjusts for 1-4 groups dynamically
- [ ] Window resizes correctly when players added/removed
- [ ] Buttons remain visible at all window sizes

---

## Implementation Order

### Session 1: Critical Fixes (1 hour)
1. Fix bottom bar overlap (Phase 1) - 20 min
2. Fix bench empty space (Phase 2) - 20 min
3. Update layout calculations (Phase 4) - 20 min

### Session 2: Header Restoration (1 hour)
4. Implement full header (Phase 3) - 45 min
5. Remove duplicate buttons from bench title - 15 min

### Session 3: Polish & Validation (30 min)
6. Validate button sizing (Phase 5) - 15 min
7. Run full testing checklist (Phase 6) - 15 min

---

## Risk Assessment

### Low Risk
- Bottom bar fix (straightforward container change)
- Layout calculations (simple arithmetic)
- Button sizing validation (search & replace)

### Medium Risk
- Bench empty space (may require multiple iterations to diagnose)

### High Risk
- Header restoration (touches many button handlers, could break event flow)

**Mitigation**: Implement header last, after critical fixes are validated.

---

## Success Criteria

✅ **COMPLETE** when:
1. All buttons visible and properly spaced
2. No empty space in bench section
3. Header shows all controls in organized layout
4. Window height calculation correct
5. All buttons functional with correct callbacks

**Verification**: Screenshot matches M+_Organizer_Header_Architecture.md mockup.

---

**Status**: 📋 SPECIFICATION COMPLETE  
**Next Step**: Switch to Code mode for implementation  
**Estimated Total Time**: 2-3 hours  
**Priority**: BLOCKER - Must fix before any other organizer work