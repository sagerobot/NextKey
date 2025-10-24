# M+ Group Organizer - Phase 1: UI Framework

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0 (Foundation), Phase 0.5 (Integration)  
**Estimated Complexity:** Very High  
**Implementation Priority:** HIGH - Core feature visibility

---

## Overview

This document defines the UI architecture for the M+ Group Organizer's Roster Board - the central interactive interface for managing multiple M+ groups. This is the most complex UI component in NextKey to date, requiring:

- Multi-column drag-and-drop system
- Real-time synchronization for 20+ participants
- Dual-view architecture (Organizer vs Participant)
- Dynamic layout adaptation
- Component pooling for performance

**Key Deliverables:**
1. Roster Board layout system
2. Player Card component with drag-and-drop
3. Access control (Organizer vs Participant views)
4. Real-time state synchronization
5. Keystone designation system

---

## 1. Roster Board Architecture

### 1.1 Layout Structure

**Visual Structure:**
```
┌─────────────────────────────────────────────────────────────────────┐
│ [Poll Group] [Optimize Groups ▼] [Announce Groups]     [Close] [?] │ Header
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐ │
│  │ M+ Grp 1│  │ M+ Grp 2│  │ M+ Grp 3│  │ M+ Grp 4│  │  Bench   │ │ Group Headers
│  ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤  ├──────────┤ │
│  │ [Tank]  │  │ [Tank]  │  │ [Tank]  │  │ [Tank]  │  │ Player 1 │ │
│  │ [Healer]│  │ [Healer]│  │ [Healer]│  │ [Healer]│  │ Player 2 │ │
│  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ Player 3 │ │ Active Pool
│  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ Player 4 │ │ (Vertical)
│  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ [DPS]   │  │ Player 5 │ │
│  │         │  │         │  │         │  │         │  │ Player 6 │ │
│  │         │  │         │  │         │  │         │  │   ...    │ │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └──────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│ [OptOut Player 1] [OptOut Player 2] [OptOut Player 3] →           │ Opt-Out Row
└─────────────────────────────────────────────────────────────────────┘ (Horizontal)
```

### 1.2 AceGUI-3.0 Widget Hierarchy

**File:** `ui/organizer/rosterBoard.lua` (NEW)

```lua
-- MARK: Module Definition
local RosterBoard = {}
NextKey222.RosterBoard = RosterBoard
NextKey222.RegisterModule("RosterBoard", RosterBoard)

local AceGUI = LibStub("AceGUI-3.0")

function RosterBoard:CreateMainFrame()
    return NextKey222.SafeRun(function()
        -- Create main window container
        local frame = AceGUI:Create("Frame")
        frame:SetTitle("M+ Group Organizer")
        frame:SetWidth(1400)
        frame:SetHeight(800)
        frame:SetLayout("Fill")
        
        -- Store reference
        self.mainFrame = frame
        
        -- Build interior
        local interior = AceGUI:Create("SimpleGroup")
        interior:SetFullWidth(true)
        interior:SetFullHeight(true)
        interior:SetLayout("Flow")
        
        frame:AddChild(interior)
        
        -- Add sections
        self:CreateHeaderSection(interior)
        self:CreateActivePoolSection(interior)
        self:CreateOptOutSection(interior)
        
        Debug:Dev("organizer_ui", "Created Roster Board main frame")
        return frame
        
    end, "RosterBoard:CreateMainFrame")
end
```

### 1.3 Responsive Layout System

**Challenge:** Window width varies, need dynamic column count

**Solution:** Calculate columns based on available width
```lua
function RosterBoard:CalculateOptimalLayout()
    local totalWidth = self.mainFrame:GetWidth()
    local benchWidth = 200 -- Fixed bench width
    local columnWidth = 150 -- Each group column
    local padding = 20
    
    -- Available width for group columns
    local availableWidth = totalWidth - benchWidth - (padding * 2)
    
    -- Max groups that fit
    local maxGroups = math.floor(availableWidth / columnWidth)
    
    -- Limit to actual number of groups needed
    local playerCount = #self:GetBenchPlayers() + #self:GetGroupedPlayers()
    local neededGroups = math.ceil(playerCount / 5)
    
    local groupColumns = math.min(maxGroups, neededGroups, 8) -- Max 8 groups
    
    return {
        groupColumns = groupColumns,
        columnWidth = columnWidth,
        benchWidth = benchWidth
    }
end
```

---

## 2. Header Section

### 2.1 Organizer Controls

**File:** `ui/organizer/rosterBoard.lua`

```lua
function RosterBoard:CreateHeaderSection(parent)
    local header = AceGUI:Create("SimpleGroup")
    header:SetFullWidth(true)
    header:SetHeight(60)
    header:SetLayout("Flow")
    
    -- Poll Group Button
    local pollButton = AceGUI:Create("Button")
    pollButton:SetText("Poll Group")
    pollButton:SetWidth(120)
    pollButton:SetCallback("OnClick", function()
        self:OnPollGroupClicked()
    end)
    header:AddChild(pollButton)
    
    -- Optimizer Dropdown
    local optimizerDropdown = AceGUI:Create("Dropdown")
    optimizerDropdown:SetLabel("Optimize:")
    optimizerDropdown:SetList({
        mode1 = "Max Power",
        mode2 = "Balanced",
        mode3 = "Vault Completion"
    })
    optimizerDropdown:SetValue("mode2") -- Default
    optimizerDropdown:SetWidth(180)
    optimizerDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        self.selectedOptimizerMode = value
    end)
    header:AddChild(optimizerDropdown)
    
    -- Optimize Button
    local optimizeButton = AceGUI:Create("Button")
    optimizeButton:SetText("Run Optimizer")
    optimizeButton:SetWidth(120)
    optimizeButton:SetCallback("OnClick", function()
        self:OnOptimizeClicked()
    end)
    header:AddChild(optimizeButton)
    
    -- Announce Button
    local announceButton = AceGUI:Create("Button")
    announceButton:SetText("Announce Groups")
    announceButton:SetWidth(150)
    announceButton:SetCallback("OnClick", function()
        self:OnAnnounceClicked()
    end)
    header:AddChild(announceButton)
    
    -- Channel Checkboxes
    local raidCheckbox = AceGUI:Create("CheckBox")
    raidCheckbox:SetLabel("Raid/Instance")
    raidCheckbox:SetValue(true)
    raidCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        self.announceToRaid = value
    end)
    header:AddChild(raidCheckbox)
    
    local guildCheckbox = AceGUI:Create("CheckBox")
    guildCheckbox:SetLabel("Guild")
    guildCheckbox:SetValue(false)
    guildCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        self.announceToGuild = value
    end)
    header:AddChild(guildCheckbox)
    
    parent:AddChild(header)
    self.headerSection = header
end
```

### 2.2 Participant View Differences

**For non-leaders:**
```lua
function RosterBoard:DisableOrganizerControls()
    -- Gray out and disable all interactive buttons
    if self.pollButton then
        self.pollButton:SetDisabled(true)
    end
    if self.optimizeButton then
        self.optimizeButton:SetDisabled(true)
    end
    if self.announceButton then
        self.announceButton:SetDisabled(true)
    end
    
    -- Hide optimizer dropdown
    if self.optimizerDropdown then
        self.optimizerDropdown:SetDisabled(true)
    end
    
    Debug:Dev("organizer_ui", "Disabled organizer controls (participant view)")
end
```

---

## 3. Active Pool Section (Vertical Columns)

### 3.1 Column Container System

```lua
function RosterBoard:CreateActivePoolSection(parent)
    local poolContainer = AceGUI:Create("SimpleGroup")
    poolContainer:SetFullWidth(true)
    poolContainer:SetHeight(600) -- Adjustable
    poolContainer:SetLayout("Flow")
    
    -- Calculate layout
    local layout = self:CalculateOptimalLayout()
    
    -- Create group columns
    self.groupColumns = {}
    for i = 1, layout.groupColumns do
        local groupColumn = self:CreateGroupColumn(i, layout.columnWidth)
        poolContainer:AddChild(groupColumn)
        table.insert(self.groupColumns, groupColumn)
    end
    
    -- Create bench column
    local benchColumn = self:CreateBenchColumn(layout.benchWidth)
    poolContainer:AddChild(benchColumn)
    self.benchColumn = benchColumn
    
    parent:AddChild(poolContainer)
    self.activePoolSection = poolContainer
end
```

### 3.2 Group Column Component

```lua
function RosterBoard:CreateGroupColumn(groupIndex, width)
    local column = AceGUI:Create("InlineGroup")
    column:SetTitle("M+ Grp. " .. groupIndex)
    column:SetWidth(width)
    column:SetHeight(600)
    column:SetLayout("List")
    
    -- Create role slots
    local roles = {"Tank", "Healer", "DPS", "DPS", "DPS"}
    local roleSlots = {}
    
    for slotIndex, role in ipairs(roles) do
        local slot = self:CreateRoleSlot(groupIndex, role, slotIndex)
        column:AddChild(slot)
        table.insert(roleSlots, slot)
    end
    
    -- Store references
    column.groupIndex = groupIndex
    column.roleSlots = roleSlots
    column.selectedKeystone = nil -- Will be set when designated
    
    return column
end

function RosterBoard:CreateRoleSlot(groupIndex, role, slotIndex)
    -- Create drop target frame
    local slot = AceGUI:Create("InteractiveLabel")
    slot:SetFullWidth(true)
    slot:SetHeight(80) -- Enough for player card
    slot:SetText("[Empty " .. role .. " Slot]")
    slot:SetColor(0.3, 0.3, 0.3) -- Gray for empty
    
    -- Enable as drop target
    slot.frame:EnableMouse(true)
    slot.frame:RegisterForDrag("LeftButton")
    
    -- Drop handling
    slot.frame:SetScript("OnReceiveDrag", function(frame)
        self:OnCardDroppedInSlot(groupIndex, role, slotIndex)
    end)
    
    -- Store metadata
    slot.groupIndex = groupIndex
    slot.role = role
    slot.slotIndex = slotIndex
    slot.playerCard = nil -- Will hold Player Card when filled
    
    return slot
end
```

### 3.3 Bench Column Component

```lua
function RosterBoard:CreateBenchColumn(width)
    local bench = AceGUI:Create("InlineGroup")
    bench:SetTitle("Bench (Pending Players)")
    bench:SetWidth(width)
    bench:SetHeight(600)
    bench:SetLayout("List")
    
    -- Make scrollable
    local scrollContainer = AceGUI:Create("ScrollFrame")
    scrollContainer:SetLayout("List")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    
    bench:AddChild(scrollContainer)
    bench.scrollContainer = scrollContainer
    bench.playerCards = {} -- Will hold Player Card widgets
    
    return bench
end

function RosterBoard:PopulateBench(players)
    local scrollContainer = self.benchColumn.scrollContainer
    
    -- Clear existing cards
    scrollContainer:ReleaseChildren()
    self.benchColumn.playerCards = {}
    
    -- Add player cards
    for _, playerData in ipairs(players) do
        local playerCard = self:CreatePlayerCard(playerData, "bench")
        scrollContainer:AddChild(playerCard)
        table.insert(self.benchColumn.playerCards, playerCard)
    end
    
    Debug:Dev("organizer_ui", "Populated bench with", #players, "players")
end
```

---

## 4. Player Card Component

### 4.1 Card Structure

**Visual Layout:**
```
┌────────────────────────────┐
│ PlayerName [★]             │ Name + Keystone Star
│ Warrior - Tank/DPS         │ Class + Roles
│ ARA: +10  |  IO: 2850      │ Keystone + Rating
│ [T] [H] [D] [Lust] [Brez]  │ Role icons + Utilities
└────────────────────────────┘
```

**File:** `ui/organizer/playerCard.lua` (NEW)

```lua
-- MARK: Module Definition
local PlayerCard = {}
NextKey222.PlayerCard = PlayerCard
NextKey222.RegisterModule("PlayerCard", PlayerCard)

local AceGUI = LibStub("AceGUI-3.0")

function PlayerCard:Create(playerData, location)
    return NextKey222.SafeRun(function()
        -- Create card container
        local card = AceGUI:Create("InlineGroup")
        card:SetWidth(180)
        card:SetHeight(75)
        card:SetLayout("Flow")
        
        -- Apply class color to border
        local classColor = RAID_CLASS_COLORS[playerData.class]
        if classColor then
            card:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.3)
        end
        
        -- Player name line
        local nameLine = self:CreateNameLine(playerData)
        card:AddChild(nameLine)
        
        -- Class and roles line
        local classLine = self:CreateClassRoleLine(playerData)
        card:AddChild(classLine)
        
        -- Keystone and rating line
        local statsLine = self:CreateStatsLine(playerData)
        card:AddChild(statsLine)
        
        -- Icons line
        local iconsLine = self:CreateIconsLine(playerData)
        card:AddChild(iconsLine)
        
        -- Store metadata
        card.playerData = playerData
        card.location = location
        card.isDragging = false
        
        -- Enable dragging (if Organizer view)
        if self:IsOrganizerView() then
            self:EnableDragging(card)
        end
        
        return card
        
    end, "PlayerCard:Create")
end

function PlayerCard:CreateNameLine(playerData)
    local nameLine = AceGUI:Create("SimpleGroup")
    nameLine:SetFullWidth(true)
    nameLine:SetHeight(20)
    nameLine:SetLayout("Flow")
    
    -- Player name
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(playerData.name)
    nameLabel:SetFont(GameFontNormalLarge)
    nameLabel:SetColor(1, 1, 1)
    nameLine:AddChild(nameLabel)
    
    -- Keystone star (if has keystone)
    if playerData.keystone then
        local starButton = AceGUI:Create("Icon")
        starButton:SetImage("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        starButton:SetImageSize(16, 16)
        starButton:SetCallback("OnClick", function()
            self:OnKeystoneStarClicked(playerData)
        end)
        nameLine:AddChild(starButton)
        
        -- Store reference for toggling
        nameLine.starButton = starButton
    end
    
    return nameLine
end

function PlayerCard:CreateClassRoleLine(playerData)
    local classLine = AceGUI:Create("Label")
    classLine:SetFullWidth(true)
    
    local classText = playerData.class:sub(1, 1):upper() .. playerData.class:sub(2):lower()
    local rolesText = table.concat(playerData.roles, "/")
    
    classLine:SetText(classText .. " - " .. rolesText)
    classLine:SetFont(GameFontNormalSmall)
    classLine:SetColor(0.8, 0.8, 0.8)
    
    return classLine
end

function PlayerCard:CreateStatsLine(playerData)
    local statsLine = AceGUI:Create("Label")
    statsLine:SetFullWidth(true)
    
    local keystoneText = "No Key"
    if playerData.keystone then
        local dungeonAbbrev = NextKey222.Utils:GetDungeonAbbreviation(playerData.keystone.dungeonID)
        keystoneText = dungeonAbbrev .. ": +" .. playerData.keystone.level
    end
    
    local ioText = "IO: " .. (playerData.overallScore or 0)
    
    statsLine:SetText(keystoneText .. "  |  " .. ioText)
    statsLine:SetFont(GameFontNormal)
    statsLine:SetColor(1, 1, 1)
    
    return statsLine
end

function PlayerCard:CreateIconsLine(playerData)
    local iconsLine = AceGUI:Create("SimpleGroup")
    iconsLine:SetFullWidth(true)
    iconsLine:SetHeight(20)
    iconsLine:SetLayout("Flow")
    
    -- Role icons
    if playerData.roles then
        for _, role in ipairs(playerData.roles) do
            local roleIcon = AceGUI:Create("Icon")
            roleIcon:SetImageSize(16, 16)
            
            if role == "Tank" then
                roleIcon:SetImage("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                roleIcon:SetImageSize(16, 16)
                -- Crop to tank portion
            elseif role == "Healer" then
                roleIcon:SetImage("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                -- Crop to healer portion
            elseif role == "DPS" then
                roleIcon:SetImage("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                -- Crop to DPS portion
            end
            
            iconsLine:AddChild(roleIcon)
        end
    end
    
    -- Utility icons
    if playerData.utilities then
        for _, utility in ipairs(playerData.utilities) do
            local utilIcon = AceGUI:Create("Icon")
            utilIcon:SetImageSize(16, 16)
            
            if utility == "Lust" then
                utilIcon:SetImage("Interface\\Icons\\Spell_Nature_BloodLust")
            elseif utility == "Brez" then
                utilIcon:SetImage("Interface\\Icons\\Spell_Nature_Reincarnation")
            end
            
            iconsLine:AddChild(utilIcon)
        end
    end
    
    return iconsLine
end
```

### 4.2 Drag-and-Drop System

**Challenge:** WoW UI doesn't have native drag-and-drop for custom frames

**Solution:** Implement custom drag system with cursor tracking

```lua
function PlayerCard:EnableDragging(card)
    local frame = card.frame
    
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    
    frame:SetScript("OnDragStart", function(self)
        card.isDragging = true
        self:StartMoving()
        
        -- Visual feedback
        self:SetAlpha(0.5)
        
        -- Store original location for cancel
        card.originalLocation = card.location
        
        Debug:Dev("organizer_ui", "Started dragging player card:", card.playerData.name)
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetAlpha(1.0)
        card.isDragging = false
        
        -- Detect drop location
        local dropTarget = PlayerCard:DetectDropTarget()
        if dropTarget then
            RosterBoard:HandleCardDrop(card, dropTarget)
        else
            -- Return to original location
            RosterBoard:ReturnCardToOriginal(card)
        end
    end)
end

function PlayerCard:DetectDropTarget()
    -- Get cursor position
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorX = cursorX / scale
    cursorY = cursorY / scale
    
    -- Check all potential drop targets
    for _, groupColumn in ipairs(RosterBoard.groupColumns) do
        for _, slot in ipairs(groupColumn.roleSlots) do
            if slot.frame:IsMouseOver() then
                return {
                    type = "role_slot",
                    groupIndex = slot.groupIndex,
                    role = slot.role,
                    slotIndex = slot.slotIndex
                }
            end
        end
    end
    
    -- Check bench
    if RosterBoard.benchColumn.frame:IsMouseOver() then
        return {
            type = "bench"
        }
    end
    
    -- Check opt-out row
    if RosterBoard.optOutSection.frame:IsMouseOver() then
        return {
            type = "opt_out"
        }
    end
    
    return nil
end
```

### 4.3 Role Constraint Validation

```lua
function RosterBoard:HandleCardDrop(card, dropTarget)
    return NextKey222.SafeRun(function()
        if dropTarget.type == "role_slot" then
            -- Validate role compatibility
            local playerRoles = card.playerData.roles
            local slotRole = dropTarget.role
            
            local canFillSlot = false
            for _, role in ipairs(playerRoles) do
                if role == slotRole then
                    canFillSlot = true
                    break
                end
            end
            
            if not canFillSlot then
                Debug:User("Cannot place " .. card.playerData.name .. " in " .. slotRole .. " slot")
                self:ReturnCardToOriginal(card)
                return
            end
            
            -- Place card in slot
            self:PlaceCardInSlot(card, dropTarget)
            
        elseif dropTarget.type == "bench" then
            -- Move to bench
            self:MoveCardToBench(card)
            
        elseif dropTarget.type == "opt_out" then
            -- Move to opt-out
            self:MoveCardToOptOut(card)
        end
        
        -- Sync state to participants
        self:BroadcastRosterUpdate({
            action = "CARD_MOVED",
            playerID = card.playerData.id,
            fromLocation = card.originalLocation,
            toLocation = dropTarget
        })
        
    end, "RosterBoard:HandleCardDrop")
end
```

---

## 5. Opt-Out Row (Horizontal Section)

### 5.1 Horizontal Scroll Container

```lua
function RosterBoard:CreateOptOutSection(parent)
    local optOutContainer = AceGUI:Create("InlineGroup")
    optOutContainer:SetTitle("Opted Out / Benched")
    optOutContainer:SetFullWidth(true)
    optOutContainer:SetHeight(100)
    optOutContainer:SetLayout("Flow")
    
    -- Horizontal scroll frame
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    
    optOutContainer:AddChild(scrollFrame)
    
    optOutContainer.scrollFrame = scrollFrame
    optOutContainer.playerCards = {}
    
    parent:AddChild(optOutContainer)
    self.optOutSection = optOutContainer
end

function RosterBoard:PopulateOptOut(players)
    local scrollFrame = self.optOutSection.scrollFrame
    
    -- Clear existing
    scrollFrame:ReleaseChildren()
    self.optOutSection.playerCards = {}
    
    -- Add cards horizontally
    for _, playerData in ipairs(players) do
        local playerCard = NextKey222.PlayerCard:Create(playerData, "opt_out")
        scrollFrame:AddChild(playerCard)
        table.insert(self.optOutSection.playerCards, playerCard)
    end
    
    Debug:Dev("organizer_ui", "Populated opt-out with", #players, "players")
end
```

---

## 6. Keystone Designation System

### 6.1 Star Icon Functionality

```lua
function PlayerCard:OnKeystoneStarClicked(playerData)
    return NextKey222.SafeRun(function()
        -- Only works if card is in a group slot
        local card = self:FindCardByPlayerID(playerData.id)
        if not card or card.location.type ~= "role_slot" then
            Debug:User("Player must be in a group to designate keystone")
            return
        end
        
        local groupIndex = card.location.groupIndex
        
        -- Designate this keystone for the group
        RosterBoard:DesignateGroupKeystone(groupIndex, playerData.keystone)
        
        -- Update group header
        RosterBoard:UpdateGroupHeader(groupIndex, playerData.keystone)
        
        -- Visual feedback on star icon
        self:HighlightKeystoneStar(card)
        
        -- Sync to participants
        RosterBoard:BroadcastRosterUpdate({
            action = "KEYSTONE_DESIGNATED",
            groupIndex = groupIndex,
            keystoneOwner = playerData.id,
            keystone = playerData.keystone
        })
        
    end, "PlayerCard:OnKeystoneStarClicked")
end

function RosterBoard:UpdateGroupHeader(groupIndex, keystone)
    local groupColumn = self.groupColumns[groupIndex]
    if not groupColumn then return end
    
    local dungeonAbbrev = NextKey222.Utils:GetDungeonAbbreviation(keystone.dungeonID)
    local headerText = dungeonAbbrev .. ": +" .. keystone.level
    
    groupColumn:SetTitle(headerText)
    groupColumn.selectedKeystone = keystone
    
    Debug:Dev("organizer_ui", "Updated group", groupIndex, "header to:", headerText)
end
```

### 6.2 Visual Indicator for Designated Keystone

```lua
function PlayerCard:HighlightKeystoneStar(card)
    local nameLine = card.children[1] -- First child is name line
    local starButton = nameLine.starButton
    
    if starButton then
        -- Change star to golden/filled version
        starButton:SetImage("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
        starButton:SetImageSize(20, 20) -- Slightly larger
        
        -- Add glow effect
        starButton.frame:SetBackdropBorderColor(1, 1, 0, 1) -- Gold border
    end
end
```

---

## 7. Real-Time Synchronization

### 7.1 State Broadcast System

```lua
function RosterBoard:BroadcastRosterUpdate(updateData)
    -- Queue update for batching (from Phase 0.5 integration)
    NextKey222.Communications:QueueOrganizerUpdate(updateData)
end

function RosterBoard:OnRosterUpdateReceived(message, sender)
    return NextKey222.SafeRun(function()
        -- Only process if we're a participant (not the organizer)
        if self:IsOrganizer() then
            return
        end
        
        local updateData = message.data
        
        if updateData.action == "CARD_MOVED" then
            self:ApplyCardMove(updateData)
        elseif updateData.action == "KEYSTONE_DESIGNATED" then
            self:ApplyKeystoneDesignation(updateData)
        elseif updateData.action == "ROSTER_STATE_FULL" then
            self:ApplyFullRosterState(updateData)
        end
        
        Debug:Dev("org_sync", "Applied roster update:", updateData.action)
        
    end, "RosterBoard:OnRosterUpdateReceived")
end

function RosterBoard:ApplyCardMove(updateData)
    -- Find card by player ID
    local card = self:FindCardByPlayerID(updateData.playerID)
    if not card then
        Debug:Error("Cannot find card for player:", updateData.playerID)
        return
    end
    
    -- Move card to new location
    local fromLoc = updateData.fromLocation
    local toLoc = updateData.toLocation
    
    self:MoveCardVisually(card, fromLoc, toLoc)
end

function RosterBoard:MoveCardVisually(card, fromLoc, toLoc)
    -- Remove from old location
    if fromLoc.type == "bench" then
        self:RemoveCardFromBench(card)
    elseif fromLoc.type == "role_slot" then
        self:RemoveCardFromSlot(card, fromLoc.groupIndex, fromLoc.slotIndex)
    elseif fromLoc.type == "opt_out" then
        self:RemoveCardFromOptOut(card)
    end
    
    -- Add to new location
    if toLoc.type == "bench" then
        self:AddCardToBench(card)
    elseif toLoc.type == "role_slot" then
        self:AddCardToSlot(card, toLoc.groupIndex, toLoc.slotIndex)
    elseif toLoc.type == "opt_out" then
        self:AddCardToOptOut(card)
    end
end
```

### 7.2 Full State Synchronization

**Sent when participant first opens Roster Board:**

```lua
function RosterBoard:SendFullRosterState(targetPlayerID)
    local fullState = {
        groups = {},
        bench = {},
        optOut = {}
    }
    
    -- Serialize all groups
    for groupIndex, groupColumn in ipairs(self.groupColumns) do
        fullState.groups[groupIndex] = {
            selectedKeystone = groupColumn.selectedKeystone,
            slots = {}
        }
        
        for slotIndex, slot in ipairs(groupColumn.roleSlots) do
            if slot.playerCard then
                fullState.groups[groupIndex].slots[slotIndex] = {
                    role = slot.role,
                    playerID = slot.playerCard.playerData.id
                }
            end
        end
    end
    
    -- Serialize bench
    for _, card in ipairs(self.benchColumn.playerCards) do
        table.insert(fullState.bench, card.playerData.id)
    end
    
    -- Serialize opt-out
    for _, card in ipairs(self.optOutSection.playerCards) do
        table.insert(fullState.optOut, card.playerData.id)
    end
    
    -- Send to target
    NextKey222.Communications:SendOrganizerMessage(
        "ROSTER_STATE_FULL",
        fullState,
        "WHISPER",
        targetPlayerID
    )
end
```

---

## 8. Access Control System

### 8.1 View Detection

```lua
function RosterBoard:DetermineViewMode()
    local isLeader = UnitIsGroupLeader("player")
    local isAssistant = UnitIsGroupAssistant("player")
    
    if isLeader or isAssistant then
        return "ORGANIZER"
    else
        return "PARTICIPANT"
    end
end

function RosterBoard:Initialize()
    return NextKey222.SafeRun(function()
        self.viewMode = self:DetermineViewMode()
        
        -- Build UI based on view
        if self.viewMode == "ORGANIZER" then
            self:CreateOrganizerView()
        else
            self:CreateParticipantView()
        end
        
        Debug:Dev("organizer_ui", "Initialized Roster Board in", self.viewMode, "mode")
        return true
        
    end, "RosterBoard:Initialize")
end
```

### 8.2 Participant View Restrictions

```lua
function RosterBoard:CreateParticipantView()
    -- Create same layout as organizer
    self:CreateMainFrame()
    
    -- Disable all interactive controls
    self:DisableOrganizerControls()
    self:DisableDragging()
    
    -- Request full state from organizer
    self:RequestRosterState()
    
    -- Add read-only indicator
    local readOnlyLabel = AceGUI:Create("Label")
    readOnlyLabel:SetText("|cFFFF0000[READ-ONLY VIEW]|r")
    readOnlyLabel:SetFont(GameFontNormalLarge)
    self.mainFrame:AddChild(readOnlyLabel)
end

function RosterBoard:DisableDragging()
    -- Remove drag handlers from all player cards
    for _, groupColumn in ipairs(self.groupColumns) do
        for _, slot in ipairs(groupColumn.roleSlots) do
            if slot.playerCard then
                slot.playerCard.frame:EnableMouse(false)
                slot.playerCard.frame:RegisterForDrag()
            end
        end
    end
    
    for _, card in ipairs(self.benchColumn.playerCards) do
        card.frame:EnableMouse(false)
        card.frame:RegisterForDrag()
    end
end
```

---

## 9. Performance Optimizations

### 9.1 Component Pooling

**Challenge:** Creating/destroying 20+ player cards repeatedly = garbage collection lag

**Solution:** Pool and reuse card widgets

```lua
PlayerCard.cardPool = {}

function PlayerCard:AcquireCard(playerData, location)
    -- Try to reuse from pool
    local card = table.remove(self.cardPool)
    
    if card then
        -- Recycle existing card
        self:UpdateCardData(card, playerData, location)
        Debug:Dev("organizer_perf", "Reused pooled player card")
    else
        -- Create new card
        card = self:Create(playerData, location)
        Debug:Dev("organizer_perf", "Created new player card")
    end
    
    return card
end

function PlayerCard:ReleaseCard(card)
    -- Reset card state
    card.playerData = nil
    card.location = nil
    card:Hide()
    
    -- Return to pool
    table.insert(self.cardPool, card)
    
    Debug:Dev("organizer_perf", "Released card to pool")
end

function PlayerCard:UpdateCardData(card, playerData, location)
    -- Update existing card with new data without recreating widgets
    card.playerData = playerData
    card.location = location
    
    -- Update text/icons
    -- (Implementation details...)
    
    card:Show()
end
```

### 9.2 Lazy Rendering

**Challenge:** Rendering 20+ cards on initial load = frame spike

**Solution:** Stagger rendering over multiple frames

```lua
function RosterBoard:PopulateBenchStaggered(players)
    local batchSize = 5
    local currentIndex = 1
    
    local function renderBatch()
        local endIndex = math.min(currentIndex + batchSize - 1, #players)
        
        for i = currentIndex, endIndex do
            local playerCard = NextKey222.PlayerCard:AcquireCard(players[i], "bench")
            self.benchColumn.scrollContainer:AddChild(playerCard)
            table.insert(self.benchColumn.playerCards, playerCard)
        end
        
        currentIndex = endIndex + 1
        
        if currentIndex <= #players then
            -- Schedule next batch
            C_Timer.After(0.05, renderBatch) -- 50ms between batches
        else
            Debug:Dev("organizer_perf", "Completed staggered bench population")
        end
    end
    
    renderBatch() -- Start first batch
end
```

### 9.3 Throttled Updates

**Challenge:** Rapid drag-and-drop = excessive sync messages

**Solution:** Debounce state updates (implemented in Phase 0.5)

```lua
-- Already handled by Communications:QueueOrganizerUpdate()
-- Uses 500ms batch interval
```

---

## 10. Error Recovery

### 10.1 Desync Detection

```lua
function RosterBoard:ValidateRosterState()
    return NextKey222.SafeRun(function()
        -- Check for duplicate players
        local seenPlayers = {}
        local duplicates = {}
        
        local function checkCard(card)
            local id = card.playerData.id
            if seenPlayers[id] then
                table.insert(duplicates, id)
            else
                seenPlayers[id] = true
            end
        end
        
        -- Check all locations
        for _, groupColumn in ipairs(self.groupColumns) do
            for _, slot in ipairs(groupColumn.roleSlots) do
                if slot.playerCard then
                    checkCard(slot.playerCard)
                end
            end
        end
        
        for _, card in ipairs(self.benchColumn.playerCards) do
            checkCard(card)
        end
        
        for _, card in ipairs(self.optOutSection.playerCards) do
            checkCard(card)
        end
        
        if #duplicates > 0 then
            Debug:Error("Roster state desync detected! Duplicate players:", table.concat(duplicates, ", "))
            self:RequestFullResync()
            return false
        end
        
        return true
        
    end, "RosterBoard:ValidateRosterState")
end

function RosterBoard:RequestFullResync()
    if self:IsParticipant() then
        -- Request fresh state from organizer
        NextKey222.Communications:SendOrganizerMessage(
            "REQUEST_FULL_STATE",
            {},
            "WHISPER",
            self:GetOrganizerName()
        )
    else
        -- Organizer rebuilds from scratch
        self:RebuildRosterFromData()
    end
end
```

---

## 11. Testing Strategy

### 11.1 UI Test Suite

**File:** `debug/organizer_ui_tests.lua` (NEW)

```lua
function TestRosterBoardCreation()
    -- Test main frame creation
    -- Verify all sections present
    -- Check layout calculations
end

function TestPlayerCardRendering()
    -- Test card creation with various data
    -- Verify class colors
    -- Check icon rendering
end

function TestDragAndDrop()
    -- Simulate drag operations
    -- Test role constraints
    -- Verify visual feedback
end

function TestKeystoneDesignation()
    -- Test star icon functionality
    -- Verify group header updates
    -- Check state synchronization
end

function TestAccessControl()
    -- Test organizer vs participant views
    -- Verify control disabling
    -- Test view switching on promotion
end

function TestStateSynchronization()
    -- Test full state broadcast
    -- Test delta updates
    -- Verify desync detection
end

function TestPerformance()
    -- Benchmark 20 card rendering
    -- Test component pooling
    -- Measure memory usage
end
```

---

## 12. Implementation Checklist

- [ ] Create `ui/organizer/rosterBoard.lua` with main frame
- [ ] Implement layout calculation system
- [ ] Create header section with organizer controls
- [ ] Build active pool section (groups + bench)
- [ ] Create opt-out row section
- [ ] Implement `ui/organizer/playerCard.lua` component
- [ ] Build drag-and-drop system with cursor tracking
- [ ] Add role constraint validation
- [ ] Implement keystone designation system
- [ ] Create state synchronization system
- [ ] Add access control (organizer vs participant)
- [ ] Implement component pooling for performance
- [ ] Add staggered rendering for large player lists
- [ ] Create desync detection and recovery
- [ ] Add error handling for all UI operations
- [ ] Write UI test suite
- [ ] Test with 5, 10, 15, 20, 25 players
- [ ] Test drag-and-drop extensively
- [ ] Verify synchronization with multiple participants
- [ ] Performance test on lower-end hardware
- [ ] Update `NextKey.toc` with new files

---

## 13. Dependencies for Next Phases

**Phase 2 (Survey) requires:**
- ✅ Player Card component (Section 4)
- ✅ Bench population system (Section 3.3)
- ✅ Opt-Out row system (Section 5)

**Phase 3 (Manual Mode) requires:**
- ✅ Complete Roster Board (Section 1)
- ✅ Drag-and-drop system (Section 4.2)
- ✅ Keystone designation (Section 6)

**Phase 4 (Algorithms) requires:**
- ✅ Group column structure (Section 3.2)
- ✅ State representation (Section 7)

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** Phase 0 and 0.5 must complete first  
**Next Document:** Phase 2 - Participant Survey