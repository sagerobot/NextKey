# Nested List Architecture Design

## Overview
Extension of [`drag_test_simple.lua`](../../debug/drag_test_simple.lua) to support hierarchical list structures - specifically a Group with nested sub-lists for Tank (1), Healer (1), and DPS (3).

## Visual Layout

```
┌─────────────────────────┐  ┌─────────────────────┐
│   Group (0/5)           │  │   Bench (2)         │
├─────────────────────────┤  ├─────────────────────┤
│ ┌─────────────────────┐ │  │ [Player Card 1]    │
│ │ Tank (0/1) [TANK]   │ │  │ [Player Card 2]    │
│ └─────────────────────┘ │  │ [...]              │
│ ┌─────────────────────┐ │  └─────────────────────┘
│ │ Healer (0/1) [HEAL] │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ DPS (0/3) [DPS]     │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

## Data Structure Design

### Parent List (Group)
```lua
local listA = {
    frame = nil,
    label = nil,
    subLists = {},  -- Array of sub-list references
    totalCapacity = 5,
    
    -- Helper to get total cards across all sub-lists
    getTotalCards = function(self)
        local count = 0
        for _, subList in ipairs(self.subLists) do
            count = count + #subList.cards
        end
        return count
    end,
    
    -- Helper to check if any sub-list can accept a card
    canAcceptCard = function(self, card)
        -- Check total capacity first
        if self:getTotalCards() >= self.totalCapacity then
            return false, nil, "Group full"
        end
        
        -- Find appropriate sub-list based on role
        for _, subList in ipairs(self.subLists) do
            if subList:canAcceptCard(card) then
                return true, subList, nil
            end
        end
        
        return false, nil, "No suitable slot"
    end
}
```

### Sub-Lists (Tank, Healer, DPS)
```lua
local tankSlot = {
    frame = nil,
    label = nil,
    cards = {},
    maxCapacity = 1,
    roleFilter = "TANK",
    parentList = listA,
    slotName = "Tank",
    
    canAcceptCard = function(self, card)
        -- Check capacity
        if #self.cards >= self.maxCapacity then
            return false, "Slot full"
        end
        
        -- Check role filter
        if self.roleFilter and card.role ~= self.roleFilter then
            return false, "Wrong role"
        end
        
        return true, nil
    end
}

local healerSlot = {
    frame = nil,
    label = nil,
    cards = {},
    maxCapacity = 1,
    roleFilter = "HEALER",
    parentList = listA,
    slotName = "Healer",
    
    canAcceptCard = function(self, card)
        if #self.cards >= self.maxCapacity then
            return false, "Slot full"
        end
        if self.roleFilter and card.role ~= self.roleFilter then
            return false, "Wrong role"
        end
        return true, nil
    end
}

local dpsSlots = {
    frame = nil,
    label = nil,
    cards = {},
    maxCapacity = 3,
    roleFilter = "DAMAGER",
    parentList = listA,
    slotName = "DPS",
    
    canAcceptCard = function(self, card)
        if #self.cards >= self.maxCapacity then
            return false, "Slot full"
        end
        if self.roleFilter and card.role ~= self.roleFilter then
            return false, "Wrong role"
        end
        return true, nil
    end
}

-- Register sub-lists with parent
listA.subLists = {tankSlot, healerSlot, dpsSlots}
```

## Frame Hierarchy

```
testFrame (UIParent)
└── InsetFrame
    ├── listA.frame (Group Container)
    │   ├── listA.label ("Group (0/5)")
    │   ├── tankSlot.frame
    │   │   ├── tankSlot.label ("Tank (0/1)")
    │   │   └── [Card frames parented here]
    │   ├── healerSlot.frame
    │   │   ├── healerSlot.label ("Healer (0/1)")
    │   │   └── [Card frames parented here]
    │   └── dpsSlots.frame
    │       ├── dpsSlots.label ("DPS (0/3)")
    │       └── [Card frames parented here]
    └── listB.frame (Bench Container)
        └── listB.scrollChild
            └── [Card frames parented here]
```

## Visual Styling

### Parent Group Frame
```lua
listA.frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
```

### Sub-List Frames (Lighter, Nested Appearance)
```lua
subList.frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, edgeSize = 2,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
subList.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

-- Role-specific border colors
if subList.roleFilter == "TANK" then
    subList.frame:SetBackdropBorderColor(0.2, 0.5, 1.0, 1.0)  -- Blue
elseif subList.roleFilter == "HEALER" then
    subList.frame:SetBackdropBorderColor(0.1, 0.9, 0.1, 1.0)  -- Green
elseif subList.roleFilter == "DAMAGER" then
    subList.frame:SetBackdropBorderColor(0.9, 0.1, 0.1, 1.0)  -- Red
end
```

## Drop Target Detection (Hierarchical)

### Priority Order
1. Check sub-list frames first (most specific)
2. Fall back to parent group frame (less specific)
3. Check bench frame (alternative target)

### Implementation
```lua
function FindDropTarget()
    -- Check sub-lists first (highest priority)
    for _, subList in ipairs(listA.subLists) do
        if subList.frame:IsMouseOver() then
            return subList, "sublist"
        end
    end
    
    -- Check parent group (medium priority)
    if listA.frame:IsMouseOver() then
        return listA, "parent"
    end
    
    -- Check bench (alternative)
    if listB.frame:IsMouseOver() then
        return listB, "bench"
    end
    
    return nil, nil
end
```

## Validation Logic

### Two-Level Capacity Check
```lua
function ValidateCardDrop(card, targetList, targetType)
    if targetType == "sublist" then
        -- Check sub-list capacity
        local canAccept, reason = targetList:canAcceptCard(card)
        if not canAccept then
            return false, reason
        end
        
        -- Check parent total capacity
        if targetList.parentList:getTotalCards() >= targetList.parentList.totalCapacity then
            return false, "Group full"
        end
        
        return true, nil
        
    elseif targetType == "parent" then
        -- Auto-assign to appropriate sub-list
        local canAccept, subList, reason = targetList:canAcceptCard(card)
        if not canAccept then
            return false, reason
        end
        
        return true, subList
        
    elseif targetType == "bench" then
        -- Bench always accepts
        return true, nil
    end
    
    return false, "Unknown target type"
end
```

### Role Filtering
```lua
function CheckRoleFilter(subList, card)
    if not subList.roleFilter then
        return true
    end
    
    if card.role ~= subList.roleFilter then
        return false, "Wrong role (need " .. subList.roleFilter .. ")"
    end
    
    return true
end
```

## Layout System

### Nested Vertical Layout
```lua
function LayoutGroupList()
    local yOffset = 30  -- Space below "Group" label
    
    for _, subList in ipairs(listA.subLists) do
        -- Position sub-list frame
        subList.frame:ClearAllPoints()
        subList.frame:SetPoint("TOP", listA.frame, "TOP", 0, -yOffset)
        
        -- Layout cards within sub-list
        local cardYOffset = 20  -- Space below sub-list label
        for i, card in ipairs(subList.cards) do
            card:ClearAllPoints()
            card:SetPoint("TOP", subList.frame, "TOP", 0, -cardYOffset)
            cardYOffset = cardYOffset + card:GetHeight() + 2
        end
        
        -- Calculate sub-list height dynamically
        local minHeight = 30  -- Minimum for label + padding
        local cardHeight = #subList.cards > 0 and (20 + (#subList.cards * 42)) or 0
        subList.frame:SetHeight(math.max(minHeight, cardHeight))
        
        -- Advance offset for next sub-list
        yOffset = yOffset + subList.frame:GetHeight() + 5
    end
    
    -- Update parent group frame height
    listA.frame:SetHeight(yOffset + 10)
end
```

## Card Drop Logic

### Modified OnDragStop
```lua
card:SetScript("OnDragStop", function(self)
    -- ... existing drag cleanup ...
    
    -- Find drop target (hierarchical)
    local targetList, targetType = FindDropTarget()
    
    if not targetList then
        -- No valid target - return to original
        ReturnToOriginalList(self)
        return
    end
    
    -- Validate drop
    local isValid, subListOrReason = ValidateCardDrop(self, targetList, targetType)
    
    if not isValid then
        -- Rejection with reason
        SimpleDragTest:AnimateRejection(self, self.listTable, subListOrReason)
        return
    end
    
    -- Handle successful drop
    if targetType == "sublist" then
        -- Direct drop into sub-list
        AcceptCardToSubList(self, targetList)
    elseif targetType == "parent" then
        -- Auto-assign to appropriate sub-list
        AcceptCardToSubList(self, subListOrReason)
    elseif targetType == "bench" then
        -- Add to bench
        AcceptCardToBench(self, targetList)
    end
    
    -- Re-layout all lists
    LayoutGroupList()
    SimpleDragTest:LayoutList(listB)
end)
```

## Label Updates

### Dynamic Status Display
```lua
function UpdateLabels()
    -- Update parent group label
    local totalCards = listA:getTotalCards()
    listA.label:SetText("Group (" .. totalCards .. "/" .. listA.totalCapacity .. ")")
    
    -- Color coding
    if totalCards >= listA.totalCapacity then
        listA.label:SetTextColor(1.0, 0.2, 0.2)  -- Red when full
    elseif totalCards >= listA.totalCapacity - 1 then
        listA.label:SetTextColor(1.0, 0.8, 0.0)  -- Yellow when almost full
    else
        listA.label:SetTextColor(1.0, 1.0, 1.0)  -- White
    end
    
    -- Update sub-list labels
    for _, subList in ipairs(listA.subLists) do
        local count = #subList.cards
        local statusText = subList.slotName .. " (" .. count .. "/" .. subList.maxCapacity .. ")"
        subList.label:SetText(statusText)
        
        -- Color code sub-list labels
        if count >= subList.maxCapacity then
            subList.label:SetTextColor(1.0, 0.2, 0.2)
        else
            subList.label:SetTextColor(0.8, 0.8, 0.8)
        end
    end
end
```

## Animation Enhancements

### Rejection with Context
```lua
function SimpleDragTest:AnimateRejection(card, targetList, reason)
    -- Flash red to indicate rejection
    card:SetBackdropColor(1.0, 0.2, 0.2, 1.0)
    card:SetBackdropBorderColor(1.0, 1.0, 0.0, 1.0)
    
    -- Show rejection reason in chat
    if reason then
        print("[DRAG TEST] REJECTED: " .. reason)
    end
    
    -- ... existing animation logic ...
end
```

## Testing Scenarios

### Scenario 1: Valid Role Assignment
1. Drag Tank card from Bench
2. Drop on Tank sub-list
3. Verify: Card appears in Tank slot
4. Verify: Group shows (1/5), Tank shows (1/1)

### Scenario 2: Wrong Role Rejection
1. Drag DPS card from Bench
2. Drop on Tank sub-list
3. Verify: Card bounces back with "Wrong role" message
4. Verify: Card returns to Bench

### Scenario 3: Full Slot Rejection
1. Fill Tank slot (1/1)
2. Drag another Tank card
3. Drop on Tank sub-list
4. Verify: Card bounces back with "Slot full" message

### Scenario 4: Auto-Assignment
1. Drag Tank card from Bench
2. Drop on parent Group frame (not specific sub-list)
3. Verify: Card auto-assigned to Tank slot
4. Verify: Labels update correctly

### Scenario 5: Full Group Rejection
1. Fill all sub-lists (5/5 total)
2. Drag any card from Bench
3. Drop anywhere on Group
4. Verify: Card bounces back with "Group full" message

### Scenario 6: Movement Between Sub-Lists
1. Place Tank in Tank slot
2. Drag Tank out and replace with different Tank
3. Verify: First Tank returns to Bench
4. Verify: New Tank occupies slot

## Implementation Phases

### Phase 1: Data Structure Setup
- Create sub-list table structures
- Add helper functions (getTotalCards, canAcceptCard)
- Wire up parent-child relationships

### Phase 2: Frame Creation
- Create sub-list frames with nested styling
- Add role-specific border colors
- Position within parent group frame

### Phase 3: Drop Detection
- Implement hierarchical IsMouseOver checks
- Add FindDropTarget function
- Update OnDragStop to use new detection

### Phase 4: Validation Layer
- Implement two-level capacity checks
- Add role filtering logic
- Wire up ValidateCardDrop

### Phase 5: Layout System
- Implement LayoutGroupList for nested positioning
- Update card parenting logic
- Dynamic sub-list height calculation

### Phase 6: Testing & Polish
- Test all validation scenarios
- Verify rejection animations
- Ensure label updates work correctly

## Success Criteria

✅ Cards can be dragged to specific role slots
✅ Wrong roles are rejected with clear feedback
✅ Full slots reject new cards appropriately
✅ Parent group enforces total capacity (5)
✅ Sub-lists enforce individual capacity (1, 1, 3)
✅ Visual hierarchy clearly shows nesting
✅ Labels show current/max for all levels
✅ Rejection animations work with nested structure
✅ Cards return to correct parent after rejection
✅ Auto-assignment works when dropping on parent group

## Future Enhancements

- Drag reordering within sub-lists
- Swap functionality between slots
- Visual indicators during drag (highlight valid targets)
- Sound effects for successful drops vs rejections
- Tooltips showing why a drop would be rejected
- Keyboard shortcuts for quick assignment