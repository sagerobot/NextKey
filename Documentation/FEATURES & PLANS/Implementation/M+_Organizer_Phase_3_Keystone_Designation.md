# M+ Group Organizer - Phase 3: Keystone Designation System

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0, 0.5, 1, 2  
**Estimated Complexity:** Low  
**Implementation Time:** 2-3 hours

---

## Overview

This document specifies the **Keystone Designation System** - the critical missing feature from Phase 3 (Manual Mode). This allows organizers to select which player's keystone each group will run.

**Key Insight:** The drag-and-drop manual mode is already fully functional. We only need to add keystone designation to make Phase 3 complete.

---

## User Experience Flow

### Current State (Working)
1. ✅ Organizer polls group
2. ✅ Players respond with specs and keystones
3. ✅ Organizer drags players into groups
4. ✅ Groups validate composition (1T/1H/3D)
5. ❌ **MISSING**: Organizer cannot designate which keystone the group will run

### Target State (With Keystone Designation)
1. ✅ Organizer polls group
2. ✅ Players respond with specs and keystones
3. ✅ Organizer drags players into groups
4. ✅ Groups validate composition (1T/1H/3D)
5. ✅ **NEW**: Organizer clicks keystone icon on player card to designate it
6. ✅ **NEW**: Group header updates to show designated keystone
7. ✅ **NEW**: Visual feedback shows which keystone is selected

---

## Design Specification

### Visual Design

**Keystone Button Location:**
- Appears in **expanded cards only** (when player is in a group slot)
- Positioned next to keystone text in Line 3 of card
- Size: 16x16 pixels (standard icon size)
- Texture: `Interface\\Buttons\\UI-GuildButton-PublicNote-Up` (star icon)

**Visual States:**
1. **Default (Undesignated)**
   - Gray star icon
   - Border: `(0.3, 0.3, 0.3, 1.0)`
   - Tooltip: "Click to designate as group keystone"

2. **Designated**
   - Same star icon
   - Border: `(1, 0.84, 0, 1.0)` (gold)
   - Tooltip: "Group keystone (click to undesignate)"

3. **Hover**
   - Slight brightness increase
   - Cursor changes to pointer

**Group Header Update:**
- Default: `"M+ Grp. 1"`
- With keystone: `"[DungeonAbbrev] +[Level]"` (e.g., `"AV +15"`)
- Uses [`DungeonNameService:GetAlias()`](../../../core/dungeonNameService.lua) for abbreviations

---

## Implementation Specification

### 1. Player Card Updates

**File:** [`ui/organizer/playerCard.lua`](../../../ui/organizer/playerCard.lua:483-496)

**Location:** In `CreateExpandedContent()` function, after keystone text creation

```lua
-- MARK: Keystone Designation Button (NEW)
function PlayerCard:CreateKeystoneButton(card, keyText, playerData)
    -- Only create if card is in a group slot
    if not card.location or 
       type(card.location) ~= "table" or 
       card.location.type ~= "role_slot" then
        return nil
    end
    
    -- Create button frame
    local keystoneButton = CreateFrame("Button", nil, card, "BackdropTemplate")
    keystoneButton:SetSize(16, 16)
    keystoneButton:SetPoint("LEFT", keyText, "RIGHT", 5, 0)
    keystoneButton:EnableMouse(true)
    
    -- Backdrop for visual feedback
    keystoneButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    keystoneButton:SetBackdropColor(0, 0, 0, 0.5)
    keystoneButton:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
    
    -- Star icon
    local icon = keystoneButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)  -- Crop edges
    
    -- Click handler
    keystoneButton:SetScript("OnClick", function()
        NextKey222.RosterBoard:DesignateGroupKeystone(
            card.location.groupIndex,
            playerData.keystone,
            playerData.id
        )
    end)
    
    -- Tooltip
    keystoneButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        -- Check if this keystone is designated
        local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
            card.location.groupIndex,
            playerData.id
        )
        
        if isDesignated then
            GameTooltip:SetText("Group Keystone", 1, 1, 1)
            GameTooltip:AddLine("Click to undesignate", 0.7, 0.7, 0.7)
        else
            GameTooltip:SetText("Click to Set as Group Keystone", 1, 1, 1)
        end
        
        GameTooltip:Show()
    end)
    
    keystoneButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return keystoneButton
end
```

**Integration Point:**
Modify `CreateExpandedContent()` at line ~483:

```lua
-- Line 3: Keystone info
if playerData.keystone then
    -- ... existing keystone text creation ...
    
    -- NEW: Add keystone designation button
    local keystoneButton = self:CreateKeystoneButton(card, keyText, playerData)
    if keystoneButton then
        card.keystoneButton = keystoneButton
        table.insert(card.roleButtons, keystoneButton)  -- Track for cleanup
    end
    
    yOffset = yOffset + 16
end
```

---

### 2. Roster Board Updates

**File:** [`ui/organizer/rosterBoard.lua`](../../../ui/organizer/rosterBoard.lua)

#### A. Implement `DesignateGroupKeystone()`

**Current stub location:** Lines 1829-1849

**Replace with:**

```lua
-- MARK: Keystone Designation
function RosterBoard:DesignateGroupKeystone(groupIndex, keystone, playerID)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "DesignateGroupKeystone called:", groupIndex, playerID)
        
        -- Validate group exists
        if not self.groupKeystones[groupIndex] then
            Debug:Error("Invalid group index:", groupIndex)
            return
        end
        
        -- Check if clicking the same keystone (toggle off)
        if self.groupKeystones[groupIndex].playerID == playerID then
            Debug:Dev("organizer", "Undesignating keystone")
            self:ClearGroupKeystone(groupIndex)
            return
        end
        
        -- Clear previous designation if different player
        if self.groupKeystones[groupIndex].playerID then
            self:UnhighlightKeystoneButton(
                self.groupKeystones[groupIndex].playerID
            )
        end
        
        -- Set new designation
        self.groupKeystones[groupIndex] = {
            keystone = keystone,
            playerID = playerID
        }
        
        -- Update group header
        self:UpdateGroupHeader(groupIndex, keystone)
        
        -- Highlight new keystone button
        self:HighlightKeystoneButton(playerID)
        
        -- Sync to participants
        self:BroadcastRosterUpdate({
            action = "KEYSTONE_DESIGNATED",
            groupIndex = groupIndex,
            keystoneOwner = playerID,
            keystone = keystone
        })
        
        Debug:Dev("organizer", "Designated keystone for group", groupIndex)
        
    end, "RosterBoard:DesignateGroupKeystone")
end
```

#### B. Implement Helper Functions

```lua
-- MARK: Keystone Designation Helpers
function RosterBoard:ClearGroupKeystone(groupIndex)
    if not self.groupKeystones[groupIndex] then return end
    
    -- Unhighlight button
    if self.groupKeystones[groupIndex].playerID then
        self:UnhighlightKeystoneButton(
            self.groupKeystones[groupIndex].playerID
        )
    end
    
    -- Clear data
    self.groupKeystones[groupIndex] = {
        keystone = nil,
        playerID = nil
    }
    
    -- Reset group header
    if self.groupTitles[groupIndex] then
        self.groupTitles[groupIndex]:SetText("M+ Grp. " .. groupIndex)
    end
    
    -- Sync to participants
    self:BroadcastRosterUpdate({
        action = "KEYSTONE_CLEARED",
        groupIndex = groupIndex
    })
    
    Debug:Dev("organizer", "Cleared keystone for group", groupIndex)
end

function RosterBoard:HighlightKeystoneButton(playerID)
    local card = self:FindCardByPlayerID(playerID)
    if not card or not card.keystoneButton then return end
    
    card.keystoneButton:SetBackdropBorderColor(1, 0.84, 0, 1.0)  -- Gold
    Debug:Dev("organizer", "Highlighted keystone button for:", playerID)
end

function RosterBoard:UnhighlightKeystoneButton(playerID)
    local card = self:FindCardByPlayerID(playerID)
    if not card or not card.keystoneButton then return end
    
    card.keystoneButton:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)  -- Gray
    Debug:Dev("organizer", "Unhighlighted keystone button for:", playerID)
end

function RosterBoard:IsKeystoneDesignated(groupIndex, playerID)
    if not self.groupKeystones[groupIndex] then return false end
    return self.groupKeystones[groupIndex].playerID == playerID
end
```

#### C. Update `UpdateGroupHeader()` (already exists at 1861-1877)

**Replace with enhanced version:**

```lua
function RosterBoard:UpdateGroupHeader(groupIndex, keystone)
    if not self.groupTitles[groupIndex] then
        Debug:Error("Group title not found for index:", groupIndex)
        return
    end
    
    if keystone then
        -- Get dungeon abbreviation using centralized service
        local dungeonAbbrev = "???"
        if NextKey222.DungeonNameService then
            dungeonAbbrev = NextKey222.DungeonNameService:GetAlias(keystone.dungeonID)
        end
        
        local headerText = dungeonAbbrev .. " +" .. keystone.level
        self.groupTitles[groupIndex]:SetText(headerText)
        
        -- Optional: Color code by key level
        if keystone.level >= 15 then
            self.groupTitles[groupIndex]:SetTextColor(1, 0.5, 0)  -- Orange
        elseif keystone.level >= 10 then
            self.groupTitles[groupIndex]:SetTextColor(0.8, 0.8, 1)  -- Light blue
        else
            self.groupTitles[groupIndex]:SetTextColor(1, 1, 1)  -- White
        end
        
        Debug:Dev("organizer", "Updated group", groupIndex, "header:", headerText)
    else
        -- Reset to default
        self.groupTitles[groupIndex]:SetText("M+ Grp. " .. groupIndex)
        self.groupTitles[groupIndex]:SetTextColor(1, 1, 1)  -- White
    end
end
```

---

### 3. Edge Case Handling

#### A. Card Moved Between Groups

When a card with a designated keystone is moved to a different group:

**Location:** In `HandleCardDrop()` at line ~1379

**Add after successful drop:**

```lua
-- Check if card had a designated keystone in previous location
if card.location and 
   type(card.location) == "table" and 
   card.location.type == "role_slot" then
    
    local prevGroupIndex = card.location.groupIndex
    
    -- If this card's keystone was designated for previous group, clear it
    if self:IsKeystoneDesignated(prevGroupIndex, card.playerData.id) then
        self:ClearGroupKeystone(prevGroupIndex)
        Debug:Dev("organizer", "Cleared keystone - card moved to different group")
    end
end
```

#### B. Card Removed from Slot

When a card with a designated keystone is moved to bench/opt-out:

**Location:** In `PlaceCardInBench()` and `PlaceCardInOptOut()`

**Add before changing card location:**

```lua
-- Check if card's keystone was designated
if card.location and 
   type(card.location) == "table" and 
   card.location.type == "role_slot" then
    
    local groupIndex = card.location.groupIndex
    
    if self:IsKeystoneDesignated(groupIndex, card.playerData.id) then
        self:ClearGroupKeystone(groupIndex)
        Debug:Dev("organizer", "Cleared keystone - card removed from group")
    end
end
```

#### C. Card Content Updated

When card content is refreshed (mode change, spec change, etc.):

**Location:** In `UpdateCardContent()` in [`playerCard.lua`](../../../ui/organizer/playerCard.lua:138-156)

**Add preservation logic:**

```lua
function PlayerCard:UpdateCardContent(card, newDisplayMode)
    -- Store keystone button state if it exists
    local wasDesignated = false
    if card.keystoneButton and card.location and 
       type(card.location) == "table" and 
       card.location.type == "role_slot" then
        
        wasDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
            card.location.groupIndex,
            card.playerData.id
        )
    end
    
    -- ... existing content clearing ...
    
    -- ... create new content ...
    
    -- Restore keystone button highlight if needed
    if wasDesignated and card.keystoneButton then
        NextKey222.RosterBoard:HighlightKeystoneButton(card.playerData.id)
    end
end
```

---

## Testing Specification

### Manual Testing Checklist

- [ ] **Basic Designation**
  - [ ] Click keystone icon on card in group slot
  - [ ] Verify group header updates to show dungeon abbreviation + level
  - [ ] Verify star icon gets gold border
  - [ ] Verify tooltip shows "Group keystone"

- [ ] **Toggle Off**
  - [ ] Click designated keystone icon again
  - [ ] Verify group header resets to "M+ Grp. X"
  - [ ] Verify star icon returns to gray border

- [ ] **Change Designation**
  - [ ] Designate one player's keystone
  - [ ] Click different player's keystone in same group
  - [ ] Verify first star unhighlights
  - [ ] Verify second star highlights
  - [ ] Verify header updates to new keystone

- [ ] **Card Movement**
  - [ ] Designate keystone in Group 1
  - [ ] Drag that card to Group 2
  - [ ] Verify Group 1 header resets
  - [ ] Verify keystone button unhighlights

- [ ] **Card Removal**
  - [ ] Designate keystone in group
  - [ ] Drag that card to bench
  - [ ] Verify group header resets
  - [ ] Verify keystone button disappears (card becomes compact)

- [ ] **Multiple Groups**
  - [ ] Designate different keystones for Groups 1, 2, 3
  - [ ] Verify each group header shows correct keystone
  - [ ] Verify each designated star is highlighted

- [ ] **Bench Cards**
  - [ ] Verify keystone button does NOT appear on bench cards (compact mode)
  - [ ] Verify button appears when card moved to group slot

- [ ] **No Keystone**
  - [ ] Drag player without keystone into group
  - [ ] Verify no keystone button appears

---

## Implementation Checklist

### Phase 1: Core Implementation (1-2 hours)
- [ ] Add `CreateKeystoneButton()` to PlayerCard module
- [ ] Integrate button into `CreateExpandedContent()`
- [ ] Implement `DesignateGroupKeystone()` in RosterBoard
- [ ] Implement helper functions (Highlight/Unhighlight/IsDesignated/Clear)
- [ ] Update `UpdateGroupHeader()` with abbreviation lookup
- [ ] Test basic designation flow

### Phase 2: Edge Cases (30 min)
- [ ] Add card movement handling
- [ ] Add card removal handling
- [ ] Add content update preservation
- [ ] Test all edge cases

### Phase 3: Polish & Testing (30 min)
- [ ] Add color coding by key level
- [ ] Test with 4 groups, multiple designations
- [ ] Update Phase 3 documentation

---

## Files Modified

| File | Changes | Lines Added | Lines Modified |
|------|---------|-------------|----------------|
| `ui/organizer/playerCard.lua` | Add keystone button creation | ~80 | ~5 |
| `ui/organizer/rosterBoard.lua` | Implement designation system | ~120 | ~20 |
| **TOTAL** | | **~200** | **~25** |

---

**Document Status:** Implementation Ready  
**Ready for Code Mode:** Yes  
**Blockers:** None  
**Next Step:** Switch to code mode and implement