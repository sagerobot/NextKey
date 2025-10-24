# M+ Group Organizer - Phase 3: Manual Mode

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0, 0.5, 1, 2  
**Estimated Complexity:** Medium  
**Implementation Priority:** HIGH - Core organizer workflow

---

## Overview

This phase implements the manual group building workflow - the default mode where the Organizer uses drag-and-drop to arrange players into groups without algorithmic assistance. This is the foundational interaction model that must work perfectly before adding optimizer automation.

**Key Deliverables:**
1. Complete drag-and-drop workflow implementation
2. Role constraint enforcement
3. Keystone designation interaction
4. Group validation system
5. Undo/redo functionality
6. Manual fine-tuning capabilities

---

## 1. Drag-and-Drop Workflow

### 1.1 Complete Interaction Flow

**User Journey:**
1. Poll Group → Survey responses populate Bench
2. Organizer drags player card from Bench to Tank slot in Group 1
3. System validates role compatibility
4. Card snaps into slot if valid, returns to Bench if invalid
5. Organizer clicks star icon on player with keystone
6. Group header updates to show keystone
7. Repeat for all groups
8. Announce groups when ready

### 1.2 Drag State Management

**File:** `ui/organizer/dragManager.lua` (NEW)

```lua
-- MARK: Module Definition
local DragManager = {}
NextKey222.DragManager = DragManager
NextKey222.RegisterModule("DragManager", DragManager)

function DragManager:Initialize()
    return NextKey222.SafeRun(function()
        self.activeDrag = nil
        self.dragCursor = nil
        self.validDropTargets = {}
        
        return true
    end, "DragManager:Initialize")
end

function DragManager:StartDrag(playerCard)
    return NextKey222.SafeRun(function()
        self.activeDrag = {
            card = playerCard,
            playerData = playerCard.playerData,
            sourceLocation = playerCard.location,
            startTime = GetTime()
        }
        
        -- Create drag cursor (clone of card)
        self:CreateDragCursor(playerCard)
        
        -- Highlight valid drop targets
        self:HighlightValidDropTargets(playerCard.playerData)
        
        Debug:Dev("drag", "Started drag for", playerCard.playerData.name)
        
    end, "DragManager:StartDrag")
end

function DragManager:CreateDragCursor(playerCard)
    -- Create semi-transparent clone that follows cursor
    local cursor = CreateFrame("Frame", nil, UIParent)
    cursor:SetSize(180, 75)
    cursor:SetFrameStrata("TOOLTIP")
    cursor:SetAlpha(0.7)
    
    -- Copy card appearance
    -- (Simplified - actual implementation would clone textures/text)
    
    -- Position at cursor
    cursor:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end)
    
    self.dragCursor = cursor
end

function DragManager:HighlightValidDropTargets(playerData)
    self.validDropTargets = {}
    
    -- Check all group slots
    for _, groupColumn in ipairs(NextKey222.RosterBoard.groupColumns) do
        for _, slot in ipairs(groupColumn.roleSlots) do
            if self:CanPlayerFillSlot(playerData, slot) then
                self:AddHighlight(slot)
                table.insert(self.validDropTargets, slot)
            end
        end
    end
    
    -- Bench is always valid
    self:AddHighlight(NextKey222.RosterBoard.benchColumn)
    table.insert(self.validDropTargets, NextKey222.RosterBoard.benchColumn)
    
    -- Opt-out is always valid
    self:AddHighlight(NextKey222.RosterBoard.optOutSection)
    table.insert(self.validDropTargets, NextKey222.RosterBoard.optOutSection)
end

function DragManager:CanPlayerFillSlot(playerData, slot)
    -- Check role compatibility
    local slotRole = slot.role
    for _, playerRole in ipairs(playerData.roles) do
        if playerRole == slotRole then
            -- Check if slot is empty or swappable
            if not slot.playerCard then
                return true
            end
        end
    end
    
    return false
end

function DragManager:AddHighlight(target)
    if not target or not target.frame then return end
    
    -- Add green glow border
    if not target.highlightTexture then
        target.highlightTexture = target.frame:CreateTexture(nil, "OVERLAY")
        target.highlightTexture:SetAllPoints()
        target.highlightTexture:SetColorTexture(0, 1, 0, 0.3)
    end
    
    target.highlightTexture:Show()
end

function DragManager:EndDrag(dropTarget)
    return NextKey222.SafeRun(function()
        if not self.activeDrag then return end
        
        -- Remove drag cursor
        if self.dragCursor then
            self.dragCursor:Hide()
            self.dragCursor = nil
        end
        
        -- Remove highlights
        self:ClearHighlights()
        
        -- Process drop
        if dropTarget and self:IsValidDropTarget(dropTarget) then
            self:ProcessDrop(dropTarget)
        else
            self:CancelDrag()
        end
        
        self.activeDrag = nil
        
    end, "DragManager:EndDrag")
end

function DragManager:ClearHighlights()
    for _, target in ipairs(self.validDropTargets) do
        if target.highlightTexture then
            target.highlightTexture:Hide()
        end
    end
    self.validDropTargets = {}
end

function DragManager:ProcessDrop(dropTarget)
    local card = self.activeDrag.card
    local sourceLocation = self.activeDrag.sourceLocation
    
    -- Determine target location type
    if dropTarget.role then
        -- Role slot
        NextKey222.RosterBoard:MoveCardToSlot(card, dropTarget)
    elseif dropTarget == NextKey222.RosterBoard.benchColumn then
        NextKey222.RosterBoard:MoveCardToBench(card)
    elseif dropTarget == NextKey222.RosterBoard.optOutSection then
        NextKey222.RosterBoard:MoveCardToOptOut(card)
    end
    
    -- Record for undo
    self:RecordMove(sourceLocation, dropTarget)
    
    -- Sync to participants
    NextKey222.RosterBoard:BroadcastRosterUpdate({
        action = "CARD_MOVED",
        playerID = card.playerData.id,
        fromLocation = sourceLocation,
        toLocation = self:SerializeLocation(dropTarget)
    })
end

function DragManager:CancelDrag()
    local card = self.activeDrag.card
    -- Card stays in original location (no action needed)
    Debug:Dev("drag", "Drag cancelled, card returned to original location")
end
```

---

## 2. Role Slot Management

### 2.1 Slot Occupancy System

```lua
function RosterBoard:MoveCardToSlot(playerCard, targetSlot)
    return NextKey222.SafeRun(function()
        -- Check if slot is occupied
        if targetSlot.playerCard then
            -- Swap logic
            self:SwapCards(playerCard, targetSlot.playerCard)
            return
        end
        
        -- Remove card from source
        self:RemoveCardFromSource(playerCard)
        
        -- Place card in slot
        targetSlot.playerCard = playerCard
        playerCard.location = {
            type = "role_slot",
            groupIndex = targetSlot.groupIndex,
            role = targetSlot.role,
            slotIndex = targetSlot.slotIndex
        }
        
        -- Update slot visual
        self:UpdateSlotVisual(targetSlot)
        
        -- Validate group
        self:ValidateGroup(targetSlot.groupIndex)
        
        Debug:Dev("organizer_ui", "Moved card to slot:", targetSlot.role, "in group", targetSlot.groupIndex)
        
    end, "RosterBoard:MoveCardToSlot")
end

function RosterBoard:SwapCards(card1, card2)
    -- Store locations
    local loc1 = card1.location
    local loc2 = card2.location
    
    -- Swap positions
    card1.location = loc2
    card2.location = loc1
    
    -- Update visuals
    -- (Implementation details...)
    
    Debug:Dev("organizer_ui", "Swapped cards:", card1.playerData.name, "↔", card2.playerData.name)
end

function RosterBoard:RemoveCardFromSource(playerCard)
    local loc = playerCard.location
    
    if loc.type == "bench" then
        self:RemoveCardFromBench(playerCard)
    elseif loc.type == "role_slot" then
        self:RemoveCardFromSlot(playerCard, loc.groupIndex, loc.slotIndex)
    elseif loc.type == "opt_out" then
        self:RemoveCardFromOptOut(playerCard)
    end
end

function RosterBoard:UpdateSlotVisual(slot)
    if slot.playerCard then
        -- Replace "[Empty X Slot]" label with player card
        slot:SetText("")
        slot:SetColor(0, 0, 0, 0) -- Transparent
        
        -- Position player card in slot
        slot.playerCard.frame:SetParent(slot.frame)
        slot.playerCard.frame:SetAllPoints()
    else
        -- Show empty slot label
        slot:SetText("[Empty " .. slot.role .. " Slot]")
        slot:SetColor(0.3, 0.3, 0.3)
    end
end
```

---

## 3. Group Validation System

### 3.1 Real-Time Validation

```lua
function RosterBoard:ValidateGroup(groupIndex)
    return NextKey222.SafeRun(function()
        local groupColumn = self.groupColumns[groupIndex]
        if not groupColumn then return end
        
        local errors = {}
        local warnings = {}
        
        -- Check role composition
        local roleCheck = self:ValidateRoleComposition(groupColumn)
        if not roleCheck.valid then
            table.insert(errors, roleCheck.error)
        end
        
        -- Check utility requirements (if toggled)
        local utilityCheck = self:ValidateUtilities(groupColumn)
        if not utilityCheck.valid then
            table.insert(warnings, utilityCheck.warning)
        end
        
        -- Check keystone designation
        if not groupColumn.selectedKeystone then
            table.insert(warnings, "No keystone designated")
        end
        
        -- Update group header visual
        self:UpdateGroupHeaderStatus(groupColumn, errors, warnings)
        
        return {
            valid = #errors == 0,
            errors = errors,
            warnings = warnings
        }
        
    end, "RosterBoard:ValidateGroup")
end

function RosterBoard:ValidateRoleComposition(groupColumn)
    local roleSlots = groupColumn.roleSlots
    local filled = {Tank = 0, Healer = 0, DPS = 0}
    
    for _, slot in ipairs(roleSlots) do
        if slot.playerCard then
            filled[slot.role] = filled[slot.role] + 1
        end
    end
    
    -- Check required composition: 1T/1H/3D
    if filled.Tank ~= 1 then
        return {valid = false, error = "Requires exactly 1 Tank"}
    end
    if filled.Healer ~= 1 then
        return {valid = false, error = "Requires exactly 1 Healer"}
    end
    if filled.DPS ~= 3 then
        return {valid = false, error = "Requires exactly 3 DPS"}
    end
    
    return {valid = true}
end

function RosterBoard:ValidateUtilities(groupColumn)
    local db = NextKey222.Config.db.global.organizer
    
    -- Get all players in group
    local players = {}
    for _, slot in ipairs(groupColumn.roleSlots) do
        if slot.playerCard then
            table.insert(players, slot.playerCard.playerData)
        end
    end
    
    -- Check Lust requirement
    if db.requireLust then
        local hasLust = false
        for _, player in ipairs(players) do
            if player.utilities and tContains(player.utilities, "Lust") then
                hasLust = true
                break
            end
        end
        if not hasLust then
            return {valid = false, warning = "No Lust/Heroism in group"}
        end
    end
    
    -- Check Brez requirement
    if db.requireBrez then
        local hasBrez = false
        for _, player in ipairs(players) do
            if player.utilities and tContains(player.utilities, "Brez") then
                hasBrez = true
                break
            end
        end
        if not hasBrez then
            return {valid = false, warning = "No Battle Rez in group"}
        end
    end
    
    return {valid = true}
end

function RosterBoard:UpdateGroupHeaderStatus(groupColumn, errors, warnings)
    local headerTitle = groupColumn:GetTitle()
    
    if #errors > 0 then
        -- Red border for errors
        groupColumn.frame:SetBackdropBorderColor(1, 0, 0, 1)
        
        -- Add error icon to header
        if not groupColumn.errorIcon then
            groupColumn.errorIcon = groupColumn.frame:CreateTexture(nil, "OVERLAY")
            groupColumn.errorIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
            groupColumn.errorIcon:SetSize(16, 16)
            groupColumn.errorIcon:SetPoint("TOPRIGHT", -5, -5)
        end
        groupColumn.errorIcon:Show()
        
    elseif #warnings > 0 then
        -- Yellow border for warnings
        groupColumn.frame:SetBackdropBorderColor(1, 1, 0, 1)
        
        if groupColumn.errorIcon then
            groupColumn.errorIcon:Hide()
        end
        
    else
        -- Green border for valid
        groupColumn.frame:SetBackdropBorderColor(0, 1, 0, 1)
        
        if groupColumn.errorIcon then
            groupColumn.errorIcon:Hide()
        end
    end
    
    -- Tooltip with details
    groupColumn.frame:SetScript("OnEnter", function(frame)
        if #errors > 0 or #warnings > 0 then
            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
            
            if #errors > 0 then
                GameTooltip:AddLine("Errors:", 1, 0, 0)
                for _, error in ipairs(errors) do
                    GameTooltip:AddLine("  • " .. error, 1, 0.5, 0.5)
                end
            end
            
            if #warnings > 0 then
                GameTooltip:AddLine("Warnings:", 1, 1, 0)
                for _, warning in ipairs(warnings) do
                    GameTooltip:AddLine("  • " .. warning, 1, 1, 0.5)
                end
            end
            
            GameTooltip:Show()
        end
    end)
    
    groupColumn.frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
```

---

## 4. Keystone Designation Interaction

### 4.1 Star Icon Click Handler

```lua
function PlayerCard:OnKeystoneStarClicked(playerData)
    return NextKey222.SafeRun(function()
        local card = NextKey222.RosterBoard:FindCardByPlayerID(playerData.id)
        if not card then return end
        
        -- Must be in a group slot
        if card.location.type ~= "role_slot" then
            Debug:User("Player must be in a group to designate keystone")
            return
        end
        
        local groupIndex = card.location.groupIndex
        
        -- Check if player has keystone
        if not playerData.keystone then
            Debug:User(playerData.name .. " does not have a keystone")
            return
        end
        
        -- Designate keystone
        NextKey222.RosterBoard:DesignateGroupKeystone(groupIndex, playerData)
        
    end, "PlayerCard:OnKeystoneStarClicked")
end
```

### 4.2 Keystone Designation Logic

```lua
function RosterBoard:DesignateGroupKeystone(groupIndex, playerData)
    return NextKey222.SafeRun(function()
        local groupColumn = self.groupColumns[groupIndex]
        if not groupColumn then return end
        
        -- Check if another player's keystone was previously designated
        if groupColumn.designatedPlayer then
            self:ClearPreviousDesignation(groupColumn)
        end
        
        -- Set new designation
        groupColumn.selectedKeystone = playerData.keystone
        groupColumn.designatedPlayer = playerData.id
        
        -- Update group header
        local dungeonAbbrev = NextKey222.Utils:GetDungeonAbbreviation(playerData.keystone.dungeonID)
        local headerText = dungeonAbbrev .. ": +" .. playerData.keystone.level
        groupColumn:SetTitle(headerText)
        
        -- Highlight star on card
        self:HighlightKeystoneStar(playerData.id)
        
        -- Sync to participants
        self:BroadcastRosterUpdate({
            action = "KEYSTONE_DESIGNATED",
            groupIndex = groupIndex,
            keystoneOwner = playerData.id,
            keystone = playerData.keystone
        })
        
        Debug:Dev("organizer", "Designated keystone for group", groupIndex, ":", headerText)
        
    end, "RosterBoard:DesignateGroupKeystone")
end

function RosterBoard:ClearPreviousDesignation(groupColumn)
    if groupColumn.designatedPlayer then
        -- Unhighlight previous player's star
        local previousCard = self:FindCardByPlayerID(groupColumn.designatedPlayer)
        if previousCard then
            self:UnhighlightKeystoneStar(previousCard)
        end
    end
end

function RosterBoard:HighlightKeystoneStar(playerID)
    local card = self:FindCardByPlayerID(playerID)
    if not card then return end
    
    -- Find star button in card
    local nameLine = card.children[1]
    local starButton = nameLine and nameLine.starButton
    
    if starButton then
        starButton:SetImage("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
        starButton:SetImageSize(20, 20)
        starButton.frame:SetBackdropBorderColor(1, 1, 0, 1) -- Gold border
    end
end

function RosterBoard:UnhighlightKeystoneStar(card)
    local nameLine = card.children[1]
    local starButton = nameLine and nameLine.starButton
    
    if starButton then
        starButton:SetImage("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        starButton:SetImageSize(16, 16)
        starButton.frame:SetBackdropBorderColor(1, 1, 1, 1)
    end
end
```

---

## 5. Undo/Redo System

### 5.1 History Stack

```lua
-- MARK: History Management
local HistoryManager = {}

function HistoryManager:Initialize()
    self.history = {}
    self.currentIndex = 0
    self.maxHistory = 50
end

function HistoryManager:RecordAction(action)
    -- Clear redo history when new action recorded
    for i = self.currentIndex + 1, #self.history do
        self.history[i] = nil
    end
    
    -- Add new action
    table.insert(self.history, {
        action = action,
        timestamp = GetTime()
    })
    
    self.currentIndex = #self.history
    
    -- Trim if exceeds max
    if #self.history > self.maxHistory then
        table.remove(self.history, 1)
        self.currentIndex = self.currentIndex - 1
    end
    
    Debug:Dev("history", "Recorded action:", action.type)
end

function HistoryManager:Undo()
    if self.currentIndex == 0 then
        Debug:User("Nothing to undo")
        return
    end
    
    local action = self.history[self.currentIndex]
    self:RevertAction(action)
    
    self.currentIndex = self.currentIndex - 1
    Debug:Dev("history", "Undo:", action.action.type)
end

function HistoryManager:Redo()
    if self.currentIndex >= #self.history then
        Debug:User("Nothing to redo")
        return
    end
    
    self.currentIndex = self.currentIndex + 1
    local action = self.history[self.currentIndex]
    
    self:ReapplyAction(action)
    Debug:Dev("history", "Redo:", action.action.type)
end

function HistoryManager:RevertAction(historyEntry)
    local action = historyEntry.action
    
    if action.type == "CARD_MOVED" then
        -- Move card back to source
        local card = NextKey222.RosterBoard:FindCardByPlayerID(action.playerID)
        if card then
            NextKey222.RosterBoard:MoveCardToLocation(card, action.fromLocation)
        end
        
    elseif action.type == "KEYSTONE_DESIGNATED" then
        -- Clear keystone designation
        local groupColumn = NextKey222.RosterBoard.groupColumns[action.groupIndex]
        if groupColumn then
            groupColumn.selectedKeystone = nil
            groupColumn.designatedPlayer = nil
            groupColumn:SetTitle("M+ Grp. " .. action.groupIndex)
        end
    end
end

function HistoryManager:ReapplyAction(historyEntry)
    local action = historyEntry.action
    
    if action.type == "CARD_MOVED" then
        local card = NextKey222.RosterBoard:FindCardByPlayerID(action.playerID)
        if card then
            NextKey222.RosterBoard:MoveCardToLocation(card, action.toLocation)
        end
        
    elseif action.type == "KEYSTONE_DESIGNATED" then
        NextKey222.RosterBoard:DesignateGroupKeystone(action.groupIndex, action.playerData)
    end
end

-- Keyboard shortcuts
function RosterBoard:RegisterUndoShortcuts()
    -- Ctrl+Z for Undo
    -- Ctrl+Y for Redo
    -- (Implementation using WoW keybinding system)
end
```

---

## 6. Manual Fine-Tuning After Optimizer

### 6.1 Optimizer Result Override

```lua
function RosterBoard:OnOptimizerComplete(optimizedGroups)
    return NextKey222.SafeRun(function()
        -- Apply optimizer results
        self:ApplyOptimizerResults(optimizedGroups)
        
        -- Enable manual adjustments
        self:EnableManualMode()
        
        -- Show message
        Debug:User("Optimizer complete. You can now manually adjust groups.")
        
    end, "RosterBoard:OnOptimizerComplete")
end

function RosterBoard:EnableManualMode()
    -- Re-enable drag-and-drop
    for _, groupColumn in ipairs(self.groupColumns) do
        for _, slot in ipairs(groupColumn.roleSlots) do
            if slot.playerCard then
                NextKey222.PlayerCard:EnableDragging(slot.playerCard)
            end
        end
    end
    
    -- Enable keystone star clicks
    -- (Already enabled by default)
end
```

---

## 7. Implementation Checklist

- [ ] Create `ui/organizer/dragManager.lua` module
- [ ] Implement complete drag-and-drop workflow
- [ ] Add drag cursor visual feedback
- [ ] Implement drop target highlighting
- [ ] Add role constraint validation
- [ ] Implement card swapping logic
- [ ] Build group validation system
- [ ] Add real-time validation feedback (colored borders)
- [ ] Implement keystone designation interaction
- [ ] Build undo/redo system with history stack
- [ ] Add keyboard shortcuts (Ctrl+Z, Ctrl+Y)
- [ ] Implement manual adjustment after optimizer
- [ ] Add confirmation dialogs for destructive actions
- [ ] Write test suite
- [ ] Test with various drag scenarios
- [ ] Test validation with invalid compositions
- [ ] Test undo/redo extensively
- [ ] Update `NextKey.toc`

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** Phases 0, 0.5, 1, 2 must complete first  
**Next Document:** Phase 4 - Optimizer Algorithms