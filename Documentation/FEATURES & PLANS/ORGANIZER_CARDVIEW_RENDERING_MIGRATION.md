# NextKey Organizer: CardView Rendering Migration Plan

**Date**: November 20, 2025  
**Status**: Implementation Plan  
**Goal**: Complete CardView rendering to match PlayerCard visual fidelity  
**Estimated Effort**: 8-12 hours (2-3 sessions)

---

## Executive Summary

This document provides step-by-step instructions to complete the CardView rendering migration. The goal is to copy all rendering logic from PlayerCard to CardView so cards display rich content (role icons, keystones, IO scores) instead of just player names.

**Current State**: CardView renders ~10% of what PlayerCard renders  
**Target State**: CardView renders 100% visual parity with PlayerCard  
**Then**: Delete PlayerCard and complete the refactor

---

## Phase 1: Add Region Tracking to CardView

**Goal**: Support proper cleanup of dynamically created UI elements  
**Time**: 1-2 hours

### Step 1.1: Add Region Pool Structure

**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:1)

**Location**: After line 9 (after Debug declaration), before Helper Functions

```lua
-- MARK: Region Pool Structure
-- Each card stores references to all created regions for proper cleanup
local function InitializeRegionPool(card)
    card.regions = {
        textures = {},      -- All texture regions
        fontStrings = {},   -- All font string regions
        activeCount = 0     -- Track how many regions are in use
    }
end

-- MARK: Region Cleanup
local function ClearCardRegions(card)
    if not card.regions then return end
    
    -- Properly destroy all textures
    for _, texture in ipairs(card.regions.textures) do
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetTexture(nil)  -- Release texture memory
    end
    
    -- Properly destroy all font strings
    for _, fontString in ipairs(card.regions.fontStrings) do
        fontString:Hide()
        fontString:SetText("")
        fontString:ClearAllPoints()
    end
    
    -- Properly destroy role icon buttons (created with CreateFrame)
    if card.roleButtons then
        for _, button in ipairs(card.roleButtons) do
            if button then
                -- MEMORY LEAK FIX: Nil all script handlers
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
                button:SetScript("OnClick", nil)
                
                -- Clear all child textures
                for _, region in ipairs({button:GetRegions()}) do
                    if region:GetObjectType() == "Texture" then
                        region:SetTexture(nil)
                    end
                end
                
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
            end
        end
        card.roleButtons = {}
    end
    
    -- Reset active count
    card.regions.activeCount = 0
    
    Debug:Trace("card_view", "Cleared all regions from card:", card.playerID)
end

-- MARK: Region Helpers
-- Region creation with tracking
local function CreateTrackedTexture(card, ...)
    local texture = card:CreateTexture(...)
    table.insert(card.regions.textures, texture)
    card.regions.activeCount = card.regions.activeCount + 1
    return texture
end

local function CreateTrackedFontString(card, ...)
    local fontString = card:CreateFontString(...)
    table.insert(card.regions.fontStrings, fontString)
    card.regions.activeCount = card.regions.activeCount + 1
    return fontString
end
```

### Step 1.2: Initialize Region Pool in Create()

**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:38)

**Location**: Line 62, after SetBackdropBorderColor, before DragController

```lua
        -- Initialize region pool for tracking
        InitializeRegionPool(card)
        
        -- Initialize role buttons array for proper cleanup
        card.roleButtons = {}
```

### Step 1.3: Clear Regions in RenderContent()

**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:110)

**Location**: Replace lines 112-119 (old clearing logic) with:

```lua
        -- Clear existing regions before creating new ones
        ClearCardRegions(card)
```

**Test**: 
- Create cards via `/nk organizer`
- Drag cards around
- Use `/reload`
- Check memory usage doesn't grow (use `/nk perf metrics`)

---

## Phase 2: Copy Rendering Helper Functions

**Goal**: Migrate all 4 rendering helpers from PlayerCard to CardView  
**Time**: 2-3 hours

### Step 2.1: Add Tooltip Handler

**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:1)

**Location**: After CreateTrackedFontString(), before Card Creation mark

```lua
-- MARK: Tooltip Handler
local function ShowRoleTooltip(roleButton, roleInfo, playerData)
    GameTooltip:SetOwner(roleButton, "ANCHOR_RIGHT")
    
    -- Normalize role display: DAMAGER → DPS for consistency
    local displayRole = roleInfo.role
    if displayRole:upper() == "DAMAGER" then
        displayRole = "DPS"
    end
    
    GameTooltip:SetText(displayRole, 1, 1, 1)
    
    -- Show current spec with preference color
    if playerData.specName then
        if roleInfo.preference == "play" then
            GameTooltip:AddLine(playerData.specName .. ": Want to Play", 0.2, 0.9, 0.2)
        elseif roleInfo.preference == "fill" then
            GameTooltip:AddLine(playerData.specName .. ": Will Fill", 0.9, 0.8, 0.2)
        else
            GameTooltip:AddLine(playerData.specName, 1, 1, 1)
        end
    else
        -- Fallback if no spec name available
        if roleInfo.preference == "play" then
            GameTooltip:AddLine("Want to Play", 0.2, 0.9, 0.2)
        elseif roleInfo.preference == "fill" then
            GameTooltip:AddLine("Will Fill", 0.9, 0.8, 0.2)
        end
    end
    
    GameTooltip:Show()
end
```

### Step 2.2: Add RenderRoleIcons()

**Source**: [`ui/organizer/playerCard.lua:126-269`](ui/organizer/playerCard.lua:126)

**Destination**: After ShowRoleTooltip()

**Action**: Copy entire RenderRoleIcons() function (146 lines)

**Critical Changes**:
- Function is already local (good)
- Uses CreateTrackedFontString/CreateTrackedTexture (already added)
- No modifications needed

### Step 2.3: Add RenderKeystoneInfo()

**Source**: [`ui/organizer/playerCard.lua:271-315`](ui/organizer/playerCard.lua:271)

**Destination**: After RenderRoleIcons()

**Action**: Copy entire RenderKeystoneInfo() function (45 lines)

**Critical Changes**:
- Uses CreateTrackedFontString (already added)
- No modifications needed

### Step 2.4: Add RenderPlayerName()

**Source**: [`ui/organizer/playerCard.lua:317-340`](ui/organizer/playerCard.lua:317)

**Destination**: After RenderKeystoneInfo()

**Action**: Copy entire RenderPlayerName() function (22 lines)

**Critical Changes**:
- Uses CreateTrackedFontString (already added)
- No modifications needed

### Step 2.5: Add RenderIOScore()

**Source**: [`ui/organizer/playerCard.lua:342-360`](ui/organizer/playerCard.lua:342)

**Destination**: After RenderPlayerName()

**Action**: Copy entire RenderIOScore() function (18 lines)

**Critical Changes**:
- Uses CreateTrackedFontString (already added)
- Uses NextKey222.Utils:GetIOScoreColor() (already exists)
- No modifications needed

**Test After Each Helper**:
- Add debug prints in each helper
- Create test card and call helper manually
- Verify no lua errors

---

## Phase 3: Update CardView Rendering Methods

**Goal**: Use helpers in RenderContent() to create rich visuals  
**Time**: 2-3 hours

### Step 3.1: Add Compact Content Rendering

**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:110)

**Location**: Replace lines 134-139 (current compact mode) with:

```lua
        if displayMode == "compact" then
            -- Use UIConfig for dynamic height
            local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
            local benchCardHeight = config.BENCH_CARD_HEIGHT or 25
            card:SetSize(200, benchCardHeight)
            
            -- Check if awaiting poll response (greyed out state)
            local isAwaitingPollResponse = false
            if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
                local addonUsers = NextKey222.RosterBoard.activePoll.addonUsers or {}
                local isAddonUser = false
                for _, playerID in ipairs(addonUsers) do
                    if playerID == playerData.id then
                        isAddonUser = true
                        break
                    end
                end
                
                if isAddonUser then
                    local hasResponded = false
                    for _, response in ipairs(NextKey222.RosterBoard.activePoll.responses) do
                        if response.sender == playerData.id then
                            hasResponded = true
                            break
                        end
                    end
                    isAwaitingPollResponse = not hasResponded
                end
            end
            
            -- Apply greyed-out visual state if awaiting response
            if isAwaitingPollResponse then
                card:SetAlpha(0.6)
                
                local pollingText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
                pollingText:SetPoint("CENTER", card, "CENTER", 0, 0)
                pollingText:SetText("Polling...")
                pollingText:SetTextColor(1, 1, 0.5)
                
                return  -- Skip normal content rendering
            else
                card:SetAlpha(1.0)
            end
            
            -- Read configurable left padding from UIConfig
            local xOffset = config.BENCH_CARD_LEFT_PADDING or 5
            
            -- Player name (truncated to 7 chars) - FIRST
            xOffset = RenderPlayerName(card, playerData, xOffset, 0, 7)
            
            -- Multi-role icons with preference colors (max 3) - SECOND
            xOffset = RenderRoleIcons(card, playerData, xOffset, 0, 3)
            
            -- Separator
            local sepText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
            sepText:SetPoint("LEFT", card, "LEFT", xOffset, 0)
            sepText:SetText("|")
            sepText:SetTextColor(0.7, 0.7, 0.7)
            xOffset = xOffset + 10
            
            -- Keystone info (use alias for compact display)
            xOffset = RenderKeystoneInfo(card, playerData, xOffset, 0, true)
            
            -- IO Score
            RenderIOScore(card, playerData, xOffset, 0, true)
```

### Step 3.2: Add Expanded Content Rendering

**Location**: Replace lines 140-188 (current expanded mode) with:

```lua
        elseif displayMode == "expanded" then
            card:SetSize(170, 105)
            
            local yOffset = 5
            local xOffset = 5
            
            -- Line 1: Class icon + Multi-role icons (left) | IO Score (right)
            if playerData.class then
                local classIcon = CreateTrackedTexture(card, nil, "ARTWORK")
                classIcon:SetSize(20, 20)
                classIcon:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -yOffset)
                classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                
                local coords = CLASS_ICON_TCOORDS[playerData.class]
                if coords then
                    classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                end
                xOffset = xOffset + 25
            end
            
            -- CRITICAL: If in a slot, override roles to show slot role
            local displayPlayerData = playerData
            if card.zone == "slots" then
                local location = NextKey222.OrganizerState:GetLocation(card.playerID)
                if location and type(location) == "table" and location.zone == "slot" then
                    displayPlayerData = {}
                    for k, v in pairs(playerData) do
                        displayPlayerData[k] = v
                    end
                    -- Override roles to show the slot's role
                    local RosterBoard = NextKey222.RosterBoard
                    local slot = RosterBoard.groupSlots[location.group] and 
                                 RosterBoard.groupSlots[location.group][location.slot]
                    if slot then
                        displayPlayerData.roles = {slot.role}
                        Debug:Dev("card_view", "Expanded card showing slot role:", slot.role, "for", playerData.name)
                    end
                end
            end
            
            -- Multi-role icons with preference colors (up to 3)
            RenderRoleIcons(card, displayPlayerData, xOffset, yOffset, 3)
            
            -- IO Score (right-aligned on line 1)
            local ioText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
            ioText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -yOffset)
            ioText:SetText(playerData.overallScore or 0)
            
            local r, g, b = NextKey222.Utils:GetIOScoreColor(playerData.overallScore or 0)
            ioText:SetTextColor(r, g, b)
            
            yOffset = yOffset + 25
            
            -- Line 2: Player name - Current Spec (truncated if needed)
            local nameSpecText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormal")
            nameSpecText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
            
            local displayText = playerData.name or "Unknown"
            if playerData.specName then
                displayText = displayText .. " - " .. playerData.specName
            end
            
            nameSpecText:SetWidth(160)
            nameSpecText:SetWordWrap(false)
            nameSpecText:SetJustifyH("LEFT")
            nameSpecText:SetText(displayText)
            
            -- Truncate with ellipsis if too long
            local actualWidth = nameSpecText:GetStringWidth()
            if actualWidth > 160 then
                local truncated = displayText
                while nameSpecText:GetStringWidth() > 150 and #truncated > 3 do
                    truncated = truncated:sub(1, -2)
                    nameSpecText:SetText(truncated .. "...")
                end
            end
            nameSpecText:SetTextColor(1, 1, 1)
            
            yOffset = yOffset + 18
            
            -- Lines 3-4: Keystone info (full name with wrapping)
            if playerData.keystone then
                local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
                keyText:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -yOffset)
                
                local dungeonText = "Unknown"
                if NextKey222.DungeonNameService then
                    dungeonText = NextKey222.DungeonNameService:GetFullName(playerData.keystone.dungeonID)
                end
                
                keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
                keyText:SetTextColor(1, 0.82, 0)
                keyText:SetWidth(135)
                keyText:SetWordWrap(true)
                keyText:SetJustifyH("LEFT")
            end
            
            -- Keystone designation button (bottom-right corner)
            if playerData.keystone and card.zone == "slots" then
                local location = NextKey222.OrganizerState:GetLocation(card.playerID)
                if location and type(location) == "table" and location.zone == "slot" then
                    local keystoneButton = self:CreateKeystoneButton(card, playerData, location)
                    if keystoneButton then
                        card.keystoneButton = keystoneButton
                        table.insert(card.roleButtons, keystoneButton)
                    end
                end
            end
```

### Step 3.3: Add Opt-Out Content Rendering

**Location**: Replace lines 189-199 (current opt-out mode) with:

```lua
        elseif displayMode == "opt_out" then
            -- Use UIConfig for opt-out card dimensions
            local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
            local width = config.OPT_OUT_CARD_WIDTH or 90
            local height = config.OPT_OUT_CARD_HEIGHT or 40
            local padding = config.OPT_OUT_PADDING or 5
            
            card:SetSize(width, height)
            
            local xOffset = padding
            
            -- Role icon (first role only) - vertically centered on left side
            if playerData.roles and playerData.roles[1] then
                local icon = CreateTrackedTexture(card, nil, "ARTWORK")
                icon:SetSize(16, 16)
                icon:SetPoint("LEFT", card, "LEFT", xOffset, 0)
                icon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                
                local normalizedRole = playerData.roles[1]:upper()
                if normalizedRole == "TANK" then
                    icon:SetTexCoord(0, 19/64, 22/64, 41/64)
                elseif normalizedRole == "HEALER" then
                    icon:SetTexCoord(20/64, 39/64, 1/64, 20/64)
                else  -- DAMAGER/DPS
                    icon:SetTexCoord(20/64, 39/64, 22/64, 41/64)
                end
                
                xOffset = xOffset + 18
            end
            
            -- Line 1: Player name (truncated to 7 chars) - top line
            local nameText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("TOPLEFT", card, "TOPLEFT", xOffset, -padding)
            
            local displayName = playerData.name or "Unknown"
            if #displayName > 7 then
                displayName = displayName:sub(1, 7)
            end
            nameText:SetText(displayName)
            nameText:SetTextColor(1, 1, 1)
            
            -- Line 2: Keystone info (short name) - bottom line
            if playerData.keystone then
                local dungeonText = "???"
                if NextKey222.DungeonNameService then
                    dungeonText = NextKey222.DungeonNameService:GetAlias(playerData.keystone.dungeonID)
                end
                
                local keyText = CreateTrackedFontString(card, nil, "OVERLAY", "GameFontNormalSmall")
                keyText:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", xOffset, padding)
                keyText:SetText(dungeonText .. " +" .. (playerData.keystone.level or 0))
                keyText:SetTextColor(1, 0.82, 0)
            end
            
            -- Gray out the card
            card:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
            card:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
        end
```

### Step 3.4: Add CreateKeystoneButton() Method

**Location**: After RenderContent(), before Cleanup mark

```lua
-- MARK: Keystone Button

--- Create keystone designation button for expanded slot cards
-- @param card Frame - The card frame
-- @param playerData table - Player data
-- @param location table - Slot location {zone="slot", group=N, slot=N}
-- @return Frame - The button frame
function CardView:CreateKeystoneButton(card, playerData, location)
    return NextKey222.SafeRun(function()
        -- Create button frame in BOTTOM-RIGHT corner
        local keystoneButton = CreateFrame("Button", nil, card, "BackdropTemplate")
        keystoneButton:SetSize(20, 20)
        keystoneButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -3, 3)
        keystoneButton:EnableMouse(true)
        
        -- Backdrop for visual feedback
        keystoneButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 2,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        keystoneButton:SetBackdropColor(0, 0, 0, 0.7)
        keystoneButton:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
        
        -- Star icon
        local icon = keystoneButton:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("CENTER")
        icon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
        icon:SetTexCoord(0, 0.5625, 0, 0.5625)
        icon:SetVertexColor(0.8, 0.8, 0.8)  -- Gray by default
        
        -- Click handler
        keystoneButton:SetScript("OnClick", function()
            NextKey222.RosterBoard:DesignateGroupKeystone(
                location.group,
                playerData.keystone,
                playerData.id
            )
        end)
        
        -- Hover effect with tooltip
        keystoneButton:SetScript("OnEnter", function(self)
            local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
                location.group,
                playerData.id
            )
            
            if not isDesignated then
                icon:SetVertexColor(1.0, 1.0, 1.0)  -- Brighten
            end
            
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if isDesignated then
                GameTooltip:SetText("Group Keystone", 1, 1, 1)
                GameTooltip:AddLine("Click to undesignate", 0.7, 0.7, 0.7)
            else
                GameTooltip:SetText("Click to Set as Group Keystone", 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        
        keystoneButton:SetScript("OnLeave", function()
            local isDesignated = NextKey222.RosterBoard:IsKeystoneDesignated(
                location.group,
                playerData.id
            )
            
            if not isDesignated then
                icon:SetVertexColor(0.8, 0.8, 0.8)  -- Reset
            end
            
            GameTooltip:Hide()
        end)
        
        keystoneButton.icon = icon
        
        Debug:Dev("card_view", "Created keystone button for:", playerData.name)
        
        return keystoneButton
        
    end, "CardView:CreateKeystoneButton")
end
```

**Test After Phase 3**:
- `/nk organizer`
- Add fake players: `/nk test preset mixed_skill`
- Verify compact cards show ALL content:
  - Names
  - Role icons with colors
  - Keystones
  - IO scores
- Verify expanded cards show ALL content
- Verify opt-out cards show ALL content

---

## Phase 4: Testing & Validation

**Goal**: Ensure visual parity with old PlayerCard system  
**Time**: 2-3 hours

### Test 4.1: Visual Parity Checklist

Create side-by-side comparison:

1. Keep old PlayerCard code temporarily
2. Create test function that creates both versions:
   ```lua
   /run local pd = NextKey222.FakePlayerService:CreateFakePlayers(1)[1]
   local oldCard = NextKey222.PlayerCard:CreateNativeCard(pd, UIParent, "bench", "compact")
   oldCard:SetPoint("CENTER", -150, 0)
   local newCard = NextKey222.CardView:Create(pd.id, UIParent, "bench")
   NextKey222.CardView:Update(newCard)
   newCard:SetPoint("CENTER", 150, 0)
   ```

3. Compare visually:
   - [ ] Role icon colors match (green/yellow/grey circles)
   - [ ] Keystone abbreviations match
   - [ ] IO score colors match
   - [ ] Text positioning matches
   - [ ] Font sizes match

### Test 4.2: Drag-and-Drop Flow

1. Open organizer: `/nk organizer`
2. Add players: `/nk test preset mixed_skill`
3. Drag card from bench to slot
4. **Verify**: Card in slot shows full content (not blank)
5. Drag card from slot back to bench
6. **Verify**: Card on bench shows full content
7. Drag card to opt-out
8. **Verify**: Opt-out card shows greyed styling

### Test 4.3: Event-Driven Updates

1. With organizer open and cards on bench
2. Run organizer sort: (button in UI or `/nk organizer sort`)
3. **Verify**: After animation, cards in slots show full content
4. Clear and re-add players
5. **Verify**: Cards rebuild correctly

### Test 4.4: Memory Leak Check

1. `/nk perf metrics` - note baseline memory
2. Create 40 fake players
3. Drag cards around 20 times
4. `/reload`
5. `/nk perf metrics` - compare memory
6. **Verify**: Memory hasn't grown significantly (< 5MB increase)

### Test 4.5: Poll Response Visual State

1. Start organizer poll (requires group)
2. **Verify**: Cards awaiting response show "Polling..." text
3. Submit response
4. **Verify**: Card updates to show full content

---

## Phase 5: Cleanup & Documentation

**Goal**: Remove old PlayerCard system  
**Time**: 1 hour

### Step 5.1: Search for PlayerCard Usage

**Command**: Search entire codebase for "PlayerCard"

**Expected locations**:
- `ui/organizer/playerCard.lua` (delete this file)
- `ui/organizer/rosterBoard.lua` (should NOT use PlayerCard anymore - already using CardView)
- `NextKey.toc` (remove playerCard.lua from load order)

**Action**: Verify no files call `NextKey222.PlayerCard:CreateNativeCard()` except test files

### Step 5.2: Delete PlayerCard File

1. Remove from TOC: [`NextKey.toc`](NextKey.toc:1)
   - Find line with `ui/organizer/playerCard.lua`
   - Delete it

2. Delete file: `ui/organizer/playerCard.lua`

3. Test: `/reload` and verify no lua errors

### Step 5.3: Update Documentation

1. Mark [`ORGANIZER_DRAG_DROP_REFACTOR.md`](Documentation/FEATURES & PLANS/ORGANIZER_DRAG_DROP_REFACTOR.md:1) as:
   ```markdown
   **Status**: ✅ COMPLETE (November 20, 2025)
   ```

2. Update [`context.md`](.kilocode/rules/memory-bank/context.md:1):
   ```markdown
   ## Recent Completions
   
   ### CardView Rendering Migration ✅ COMPLETE (November 20, 2025)
   - Migrated all rendering logic from PlayerCard to CardView
   - CardView now renders rich content (role icons, keystones, IO scores)
   - Deleted old PlayerCard system (982 lines removed)
   - Visual parity confirmed via testing
   ```

3. Update [`architecture.md`](.kilocode/rules/memory-bank/architecture.md:1):
   - Remove PlayerCard references
   - Document CardView as the canonical card rendering system

---

## Success Criteria

- [x] CardView renders compact cards with ALL content (names, roles, keystones, IO)
- [x] CardView renders expanded cards with ALL content (class icons, spec, keystone button)
- [x] CardView renders opt-out cards correctly (greyed out, two-line layout)
- [x] Drag-and-drop updates cards without losing content
- [x] Event-driven rebuilds work correctly
- [x] No memory leaks (region cleanup working)
- [x] PlayerCard.lua deleted from codebase
- [x] No lua errors on `/reload`
- [x] Visual parity with old system confirmed

---

## Rollback Plan

If issues arise during migration:

1. **Revert RosterBoard to use PlayerCard**:
   ```lua
   -- In RebuildBench()
   local card = NextKey222.PlayerCard:CreateNativeCard(
       playerData,
       self.benchContainer,
       "bench",
       "compact"
   )
   ```

2. **Keep CardView for future**:
   - Don't delete CardView.lua
   - Mark as "incomplete migration"
   - Document in context.md

3. **Re-enable PlayerCard in TOC**:
   - Uncomment `ui/organizer/playerCard.lua`

---

## Implementation Checklist

### Phase 1: Region Tracking
- [ ] Add InitializeRegionPool()
- [ ] Add ClearCardRegions()
- [ ] Add CreateTrackedTexture()
- [ ] Add CreateTrackedFontString()
- [ ] Initialize region pool in Create()
- [ ] Clear regions in RenderContent()
- [ ] Test: Memory doesn't leak

### Phase 2: Helper Functions
- [ ] Add ShowRoleTooltip()
- [ ] Add RenderRoleIcons()
- [ ] Add RenderKeystoneInfo()
- [ ] Add RenderPlayerName()
- [ ] Add RenderIOScore()
- [ ] Test: Each helper individually

### Phase 3: Rendering Methods
- [ ] Update compact mode rendering
- [ ] Update expanded mode rendering
- [ ] Update opt-out mode rendering
- [ ] Add CreateKeystoneButton()
- [ ] Test: All 3 modes render correctly

### Phase 4: Testing
- [ ] Visual parity check
- [ ] Drag-and-drop flow test
- [ ] Event-driven updates test
- [ ] Memory leak check
- [ ] Poll response visual state test

### Phase 5: Cleanup
- [ ] Search for PlayerCard usage
- [ ] Delete PlayerCard.lua
- [ ] Remove from NextKey.toc
- [ ] Update documentation
- [ ] Final `/reload` test

---

## Notes

- **Estimated Total Time**: 8-12 hours across 2-3 sessions
- **Risk Level**: Medium (copying proven code, but need to test thoroughly)
- **Rollback Available**: Yes (revert to PlayerCard if needed)
- **Long-term Benefit**: Single card system, clean architecture, maintainable
