# NextKey Organizer: Drag & Drop Refactor - Implementation Checklist

**Date**: November 20, 2025  
**Status**: Implementation Ready  
**Parent Document**: [ORGANIZER_DRAG_DROP_REFACTOR.md](ORGANIZER_DRAG_DROP_REFACTOR.md:1)

---

## 📋 Overview

This checklist provides a step-by-step implementation guide for the complete drag-and-drop system refactor. Each phase has clear deliverables and rollback points.

**Estimated Timeline**: 5 weeks  
**Estimated Effort**: 80-100 hours

---

## Phase 1: Foundation (Week 1) ✅ COMPLETE
**Goal**: Add location storage without breaking existing system
**Rollback Point**: Can revert without affecting production code

### 1.1 Create Location Type System ✅
- [x] Create `core/organizer/location.lua`
  - [x] Define Location type
    ```lua
    -- Location = "bench" | "opt_out" | {zone="slot", group=N, slot=N}
    ```
  - [x] Add `Location.ToString(location)` for debugging
  - [x] Add `Location.IsEqual(loc1, loc2)` comparison
  - [x] Add `Location.FromLegacy(benchSet, optOutSet, groups, playerID)` converter
  - [x] Add `Location.ToLegacy(location)` converter
  - [x] Add unit tests for all conversion functions

- [x] Update `NextKey.toc` load order
  - [x] Add `core/organizer/location.lua` before `core/organizer/state.lua`

### 1.2 Update OrganizerState ✅
- [x] Open `core/organizer/state.lua`
  
- [x] Add location storage (line ~44)
  ```lua
  OrganizerState.locations = {}  -- {[playerID] = Location}
  ```

- [x] Add GetLocation method (after line 362)
  ```lua
  function OrganizerState:GetLocation(playerID)
      return NextKey222.SafeRun(function()
          if not playerID then return nil end
          
          -- NEW: Try locations table first
          if self.locations[playerID] then
              return self.locations[playerID]
          end
          
          -- LEGACY: Fall back to old system
          return Location.FromLegacy(self.bench, self.optOut, self.groups, playerID)
      end, "OrganizerState:GetLocation")
  end
  ```

- [x] Add SetLocation method (after GetLocation)
  ```lua
  function OrganizerState:SetLocation(playerID, location)
      return NextKey222.SafeRun(function()
          if not playerID then return false end
          
          -- NEW: Update locations table
          self.locations[playerID] = location
          
          -- LEGACY: Also update old system for backward compatibility
          Location.ToLegacy(location, self.bench, self.optOut, self.groups, playerID)
          
          return true
      end, "OrganizerState:SetLocation")
  end
  ```

- [x] Update Initialize (line 47)
  ```lua
  function OrganizerState:Initialize()
      return NextKey222.SafeRun(function()
          if not self._initialized then
              self.players = {}
              self.bench = {}
              self.optOut = {}
              self.groups = {}
              self.keystones = {}
              self.locations = {}  -- NEW
              self.activePoll = nil
              
              self:LoadFromPersistence()
              self._initialized = true
          end
          
          return true
      end, "OrganizerState:Initialize")
  end
  ```

- [x] Update SaveToPersistence (line 929)
  - [x] Save locations table to SavedVariables
  - [x] Keep saving old format too (backward compatibility)

- [x] Update LoadFromPersistence (line 1000)
  - [x] Load locations table if present
  - [x] Otherwise convert from old format
  - [x] Populate locations table from loaded data

### 1.3 Testing ✅
- [x] Run `/nk test` to create fake players
- [x] Verify locations stored in new format
- [x] Verify old code still works
- [x] Verify `/reload` preserves locations
- [x] Check SavedVariables has both formats

### 1.4 Phase 1 Deliverable ✅
- [x] OrganizerState can store locations in new format
- [x] Old code continues working unchanged
- [x] Migration helpers convert between formats
- [x] All tests pass

---

## Phase 2: Views (Week 2) ✅ COMPLETE
**Goal**: Create lightweight card views
**Rollback Point**: Can disable CardView and use old PlayerCard

### 2.1 Create CardView Module ✅
- [x] Create `ui/organizer/cardView.lua`

- [x] Add module definition
  ```lua
  local _, NextKey222 = ...
  local CardView = {}
  NextKey222.CardView = CardView
  NextKey222.RegisterModule("CardView", CardView)
  ```

- [x] Implement Create method
  ```lua
  function CardView:Create(playerID, parentFrame, zone)
      -- Create frame with BackdropTemplate
      -- Store ONLY playerID and zone
      -- NO playerData, NO location, NO displayMode
      -- Return frame
  end
  ```

- [x] Implement Update method
  ```lua
  function CardView:Update(card)
      -- Get playerData from OrganizerState
      -- Get location from OrganizerState
      -- Determine displayMode from location
      -- Call RenderContent
  end
  ```

- [x] Implement GetDisplayMode method
  ```lua
  function CardView:GetDisplayMode(location)
      if location == "bench" then return "compact" end
      if location == "opt_out" then return "opt_out" end
      if location.zone == "slot" then return "expanded" end
  end
  ```

- [x] Implement RenderContent method
  ```lua
  function CardView:RenderContent(card, playerData, displayMode)
      -- Copy rendering logic from PlayerCard:UpdateCardContent
      -- Use playerData parameter instead of card.playerData
      -- Clear old content first
      -- Add name, class, spec, role icons based on displayMode
  end
  ```

- [x] Update `NextKey.toc` load order
  - [x] Add `ui/organizer/cardView.lua` after `ui/organizer/playerCard.lua`

### 2.2 Add Rebuild Methods to RosterBoard ✅
- [x] Open `ui/organizer/rosterBoard.lua`

- [x] Add RebuildBench method (after line 1806)
  ```lua
  function RosterBoard:RebuildBench()
      return NextKey222.SafeRun(function()
          -- Clear old cards
          for _, card in ipairs(self.benchCards) do
              card:Hide()
              card:SetParent(nil)
          end
          self.benchCards = {}
          
          -- Get players from state
          local benchPlayerIDs = NextKey222.OrganizerState:GetBenchPlayers()
          
          -- Create new cards with CardView
          for _, playerID in ipairs(benchPlayerIDs) do
              local card = NextKey222.CardView:Create(playerID, self.benchContainer, "bench")
              NextKey222.CardView:Update(card)
              table.insert(self.benchCards, card)
          end
          
          -- Layout
          self:LayoutBench()
      end, "RosterBoard:RebuildBench")
  end
  ```

- [x] Add RebuildSlots method
  ```lua
  function RosterBoard:RebuildSlots()
      -- Similar to RebuildBench
      -- Clear slot cards
      -- Get slot assignments from state
      -- Create cards with CardView
      -- Place in slots
  end
  ```

- [x] Add RebuildOptOut method
  ```lua
  function RosterBoard:RebuildOptOut()
      -- Similar to RebuildBench
      -- Clear opt-out cards
      -- Get opt-out players from state
      -- Create cards with CardView
      -- Layout opt-out
  end
  ```

- [x] Add GetAffectedSections helper
  ```lua
  function RosterBoard:GetAffectedSections(fromLocation, toLocation)
      local sections = {}
      
      -- Check fromLocation
      if fromLocation == "bench" then table.insert(sections, "bench") end
      if fromLocation == "opt_out" then table.insert(sections, "opt_out") end
      if type(fromLocation) == "table" and fromLocation.zone == "slot" then
          table.insert(sections, "slots")
      end
      
      -- Check toLocation (if different)
      -- ...
      
      return sections
  end
  ```

### 2.3 Testing ✅
- [x] Test RebuildBench manually
  - [x] Clear bench cards
  - [x] Call RebuildBench()
  - [x] Verify cards appear correctly
  - [x] Verify compact display mode

- [x] Test RebuildSlots
  - [x] Place players in slots via state
  - [x] Call RebuildSlots()
  - [x] Verify expanded display mode

- [x] Test RebuildOptOut
  - [x] Move players to opt-out
  - [x] Call RebuildOptOut()
  - [x] Verify opt-out display mode

- [x] Performance test
  - [x] Time rebuild with 40 players
  - [x] Should be <100ms

### 2.4 Phase 2 Deliverable ✅
- [x] CardView creates lightweight cards
- [x] Cards render correctly from playerID only
- [x] Rebuild methods work for all sections
- [x] All display modes render correctly

---

## Phase 3: CardView Rendering Migration (URGENT - Visual Bug Fix) 🔴 IN PROGRESS
**Goal**: Complete CardView rendering to fix visual bugs
**Time**: 8-12 hours (2-3 sessions)
**Rollback Point**: Revert RosterBoard to use PlayerCard
**Reference**: [ORGANIZER_CARDVIEW_RENDERING_MIGRATION.md](ORGANIZER_CARDVIEW_RENDERING_MIGRATION.md:1)

### 3.0 Background - Visual Bug Diagnosis ✅
- [x] Cards losing colors, role icons, keystone info, IO scores after drag-and-drop
- [x] Root cause: CardView only renders ~10% of needed content (just player names)
- [x] PlayerCard has full rendering (500+ lines) but RosterBoard stopped calling it
- [x] Solution: Complete CardView rendering migration

### 3.1 Add Region Tracking to CardView ✅
**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:1)
**Time**: 1-2 hours

- [x] Add InitializeRegionPool() function (after line 9)
- [x] Add ClearCardRegions() function
- [x] Add CreateTrackedTexture() helper
- [x] Add CreateTrackedFontString() helper
- [x] Initialize region pool in Create() method (line 62)
- [x] Clear regions in RenderContent() (replace lines 112-119)
- [x] Test: Memory doesn't leak after `/reload`

### 3.2 Copy Rendering Helper Functions ✅
**Source**: [`ui/organizer/playerCard.lua`](ui/organizer/playerCard.lua:1)
**Destination**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:1)
**Time**: 2-3 hours

- [x] Add ShowRoleTooltip() (after CreateTrackedFontString)
- [x] Add RenderRoleIcons() (146 lines from playerCard.lua:126-269)
- [x] Add RenderKeystoneInfo() (45 lines from playerCard.lua:271-315)
- [x] Add RenderPlayerName() (22 lines from playerCard.lua:317-340)
- [x] Add RenderIOScore() (18 lines from playerCard.lua:342-360)
- [x] Test: Each helper individually with debug prints

### 3.3 Update CardView Rendering Methods ✅
**File**: [`ui/organizer/cardView.lua`](ui/organizer/cardView.lua:110)
**Time**: 2-3 hours

- [x] Replace compact mode rendering (lines 134-139) with full PlayerCard logic
  - [x] Player name (truncated)
  - [x] Multi-role icons with preference colors
  - [x] Separator
  - [x] Keystone info (alias)
  - [x] IO score with color coding
  - [x] Polling state check ("Polling..." text)

- [x] Replace expanded mode rendering (lines 140-188) with full PlayerCard logic
  - [x] Class icon
  - [x] Multi-role icons with tooltips
  - [x] IO score (larger)
  - [x] Player name + spec
  - [x] Full dungeon names with word wrap
  - [x] Keystone designation button

- [x] Replace opt-out mode rendering (lines 189-199) with full PlayerCard logic
  - [x] Role icon
  - [x] Two-line layout
  - [x] Player name (truncated)
  - [x] Keystone info

- [x] Add CreateKeystoneButton() method (after RenderContent)
  - [x] Star icon with click handler
  - [x] Hover tooltips
  - [x] Integration with RosterBoard:DesignateGroupKeystone

### 3.4 Connect RosterBoard to CardView 🔴 CRITICAL - IN PROGRESS
**Goal**: Replace ALL `PlayerCard:CreateNativeCard()` calls with `CardView:Create()` + `CardView:Update()`
**Time**: 3-4 hours
**Why**: Cards created with PlayerCard have OLD drag handlers that conflict with DragController

**Problem Found**: Search revealed 16 instances of `PlayerCard:CreateNativeCard()` across 2 files:
- RosterBoard (11 instances)
- BenchManager (5 instances)

When organizer opens, `PopulateAllSections()` uses PlayerCard → creates cards with conflicting drag handlers → drag breaks all cards.

**Files to Update**:

#### 3.4.1 Update RosterBoard Methods
**File**: [`ui/organizer/rosterBoard.lua`](ui/organizer/rosterBoard.lua:1)

- [ ] `PopulateAllSections()` (line 526) - slot cards
  ```lua
  -- OLD:
  local card = NextKey222.PlayerCard:CreateNativeCard(playerData, slot, "role_slot", "compact")
  
  -- NEW:
  local card = NextKey222.CardView:Create(playerID, slot.frame, "slot")
  NextKey222.CardView:Update(card)
  ```

- [ ] `AddPlayerToOptOut()` (line 1765) - single opt-out card
- [ ] `SyncUIToState()` (lines 2533, 2549, 2569) - all three sections
- [ ] `SyncBenchAndOptOutOnly()` (lines 2665, 2681) - bench and opt-out
- [ ] `OnPlayerAdded()` (line 2727) - slot cards

#### 3.4.2 Update BenchManager Methods
**File**: [`ui/organizer/modules/benchManager.lua`](ui/organizer/modules/benchManager.lua:1)

- [ ] `add_player_to_bench()` (line 244) - single bench card
- [ ] `populate_bench()` (line 328) - batch bench cards
- [ ] `rebuild_bench_after_poll()` (line 646) - legacy method (will be deleted later)

#### 3.4.3 Remove PlayerCard.UpdateCardContent Calls
These methods call `PlayerCard:UpdateCardContent()` instead of `CardView:Update()`:

- [ ] `RosterBoard:RefreshBenchCardsFromState()` (line 2406)
  ```lua
  -- OLD:
  NextKey222.PlayerCard:UpdateCardContent(card, "compact")
  
  -- NEW:
  NextKey222.CardView:Update(card)
  ```

- [ ] `RosterBoard:RefreshSingleCardByPlayerID()` (lines 2430, 2443, 2457)
- [ ] `RosterBoard:MoveSingleCard()` (lines 2977, 2986)
- [ ] `RefreshSingleCard()` local function (line 2334) - helper used by RefreshAllCards

#### 3.4.4 Testing After Each File
- [ ] Test RosterBoard changes: `/nk organizer` → verify cards appear
- [ ] Test BenchManager changes: `/nk test` → verify bench works
- [ ] Test drag works: Try dragging a card → should NOT darken/break

### 3.4 Testing & Validation ⏳
**Time**: 2-3 hours

- [ ] Visual Parity Check
  - [ ] Create side-by-side comparison (PlayerCard vs CardView)
  - [ ] Verify role icon colors match (green/yellow/grey circles)
  - [ ] Verify keystone abbreviations match
  - [ ] Verify IO score colors match
  - [ ] Verify text positioning matches
  - [ ] Verify font sizes match

- [ ] Drag-and-Drop Flow Test
  - [ ] Open organizer: `/nk organizer`
  - [ ] Add players: `/nk test preset mixed_skill`
  - [ ] Drag bench → slot (verify full content appears)
  - [ ] Drag slot → bench (verify full content appears)
  - [ ] Drag to opt-out (verify greyed styling)

- [ ] Event-Driven Updates Test
  - [ ] Organizer sort (verify cards in slots show full content)
  - [ ] Clear and re-add players (verify rebuilds correctly)

- [ ] Memory Leak Check
  - [ ] Note baseline: `/nk perf metrics`
  - [ ] Create 40 fake players
  - [ ] Drag cards 20 times
  - [ ] `/reload`
  - [ ] Compare memory (< 5MB increase)

- [ ] Poll Response Visual State
  - [ ] Start organizer poll (requires group)
  - [ ] Verify "Polling..." text shows
  - [ ] Submit response
  - [ ] Verify card updates to full content

### 3.5 Cleanup & Documentation ⏳
**Time**: 1 hour

- [ ] Search for PlayerCard usage (should only be in tests)
- [ ] Delete `ui/organizer/playerCard.lua`
- [ ] Remove from `NextKey.toc`
- [ ] Test: `/reload` with no lua errors
- [ ] Update `ORGANIZER_DRAG_DROP_REFACTOR.md` status to COMPLETE
- [ ] Update `context.md` - CardView migration complete
- [ ] Update `architecture.md` - remove PlayerCard references

### 3.6 Phase 3 Deliverable ⏳
- [ ] CardView renders ALL content (names, roles, keystones, IO)
- [ ] Drag-and-drop updates cards without losing content
- [ ] Event-driven rebuilds work correctly
- [ ] No memory leaks (region cleanup working)
- [ ] PlayerCard.lua deleted from codebase
- [ ] Visual parity with old system confirmed
- [ ] No lua errors on `/reload`

---

## Phase 4: Original Drag System (Week 3) ⚠️ BLOCKED
**Goal**: Single unified drag controller
**Rollback Point**: Can disable DragController and use old system
**Note**: This was the original Phase 3, now moved to Phase 4 after visual bug fix

### 3.1 Create DragController Module ✅
- [x] Create `ui/organizer/dragController.lua`

- [x] Add module definition and state
  ```lua
  local DragController = {}
  NextKey222.DragController = DragController
  NextKey222.RegisterModule("DragController", DragController)
  
  DragController.activeDrag = nil  -- {card, playerID, fromLocation}
  ```

- [x] Implement EnableDrag
  ```lua
  function DragController:EnableDrag(card)
      card:SetMovable(true)
      card:RegisterForDrag("LeftButton")
      
      card:SetScript("OnDragStart", function(self)
          DragController:StartDrag(self)
      end)
      
      card:SetScript("OnDragStop", function(self)
          DragController:CompleteDrag(self)
      end)
  end
  ```

- [x] Implement StartDrag
  ```lua
  function DragController:StartDrag(card)
      -- Visual feedback
      card:StartMoving()
      card:SetBackdropBorderColor(1.0, 1.0, 0, 1.0)  -- Yellow
      
      -- Store transaction
      self.activeDrag = {
          card = card,
          playerID = card.playerID,
          fromLocation = NextKey222.OrganizerState:GetLocation(card.playerID)
      }
  end
  ```

- [x] Implement DetectDropTarget
  ```lua
  function DragController:DetectDropTarget()
      -- Check slots (priority)
      for groupIndex, slots in pairs(NextKey222.RosterBoard.groupSlots) do
          for slotIndex, slot in pairs(slots) do
              if slot.frame:IsMouseOver() then
                  return {
                      type = "slot",
                      zone = "slot",
                      group = groupIndex,
                      slot = slotIndex,
                      frame = slot.frame
                  }
              end
          end
      end
      
      -- Check opt-out
      if NextKey222.RosterBoard.optOutSection:IsMouseOver() then
          return {type = "opt_out", zone = "opt_out"}
      end
      
      -- Default: bench
      return {type = "bench", zone = "bench"}
  end
  ```

- [x] Implement ValidateMove
  ```lua
  function DragController:ValidateMove(playerID, fromLocation, toLocation)
      -- Same location check
      if NextKey222.Location.IsEqual(fromLocation, toLocation) then
          return true
      end
      
      -- Role validation for slots
      if toLocation.zone == "slot" then
          local playerData = NextKey222.OrganizerState:GetPlayer(playerID)
          local slot = NextKey222.RosterBoard.groupSlots[toLocation.group][toLocation.slot]
          
          return self:CanFillRole(playerData.roles, slot.role)
      end
      
      return true  -- Bench/opt-out always valid
  end
  ```

- [x] Implement CanFillRole (copy from cardMovement.lua)
  ```lua
  function DragController:CanFillRole(playerRoles, slotRole)
      -- Copy logic from CardMovement:can_player_fill_role
      -- Handle both array and table formats
  end
  ```

- [x] Implement CompleteDrag
  ```lua
  function DragController:CompleteDrag(card)
      card:StopMovingOrSizing()
      
      local drag = self.activeDrag
      if not drag then return end
      
      -- Detect drop target
      local dropTarget = self:DetectDropTarget()
      local toLocation = dropTarget
      
      -- Validate
      if not self:ValidateMove(drag.playerID, drag.fromLocation, toLocation) then
          -- Reject animation
          self:AnimateReject(card, drag.fromLocation)
          self.activeDrag = nil
          return
      end
      
      -- Update state FIRST
      NextKey222.OrganizerState:SetLocation(drag.playerID, toLocation)
      
      -- Trigger animation (will hide card, event will rebuild)
      self:AnimateMoveTo(card, dropTarget.frame or NextKey222.RosterBoard.benchContainer)
      
      self.activeDrag = nil
  end
  ```

- [x] Implement AnimateReject (temporary - will move to AnimationController)
  ```lua
  function DragController:AnimateReject(card, originalLocation)
      -- Red flash
      card:SetBackdropBorderColor(1.0, 0, 0, 1.0)
      
      C_Timer.After(0.3, function()
          card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
      end)
  end
  ```

- [x] Implement AnimateMoveTo (temporary)
  ```lua
  function DragController:AnimateMoveTo(card, targetFrame)
      -- Simple version - just hide card
      -- Event system will rebuild from state
      card:Hide()
  end
  ```

- [x] Update `NextKey.toc` load order
  - [x] Add `ui/organizer/dragController.lua` after `ui/organizer/cardView.lua`

### 3.2 Update CardView to Use DragController ✅
- [x] Open `ui/organizer/cardView.lua`

- [x] Update Create method
  ```lua
  function CardView:Create(playerID, parentFrame, zone)
      local card = CreateFrame(...)
      
      card.playerID = playerID
      card.zone = zone
      
      -- Enable drag via DragController
      NextKey222.DragController:EnableDrag(card)
      
      return card
  end
  ```

### 3.3 Update RosterBoard Event Handlers ✅
- [x] Open `ui/organizer/rosterBoard.lua`

- [x] Update OnPlayerMoved (line 2562)
  ```lua
  function RosterBoard:OnPlayerMoved(payload)
      return NextKey222.SafeRun(function()
          if not self:IsVisible() then return end
          if self.isAnimating then return end
          
          -- NEW: Simple rebuild of affected sections
          local sections = self:GetAffectedSections(payload.fromLocation, payload.toLocation)
          
          for _, section in ipairs(sections) do
              if section == "bench" then self:RebuildBench() end
              if section == "slots" then self:RebuildSlots() end
              if section == "opt_out" then self:RebuildOptOut() end
          end
      end, "RosterBoard:OnPlayerMoved")
  end
  ```

### 3.4 Testing ⚠️ IN PROGRESS
- [ ] Test drag bench → slot (valid role)
  - [ ] Card moves smoothly
  - [ ] State updates correctly
  - [ ] UI rebuilds from state
  - [ ] Card appears in slot expanded

- [ ] Test drag bench → slot (invalid role)
  - [ ] Red flash appears
  - [ ] Card stays on bench
  - [ ] No state change

- [ ] Test drag slot → bench
  - [ ] Card moves to bench
  - [ ] Slot becomes empty
  - [ ] Card shows compact mode

- [ ] Test drag slot → slot
  - [ ] Card changes slots
  - [ ] Both slots update correctly

- [ ] Test same-location drop
  - [ ] Card resets visually
  - [ ] No state change
  - [ ] No rebuild

- [ ] Test drag to opt-out
  - [ ] Card moves to opt-out section
  - [ ] Shows opt-out mode

### 4.5 Phase 4 Deliverable ⏳
- [ ] Single drag system works
- [ ] State-first updates prevent desyncs
- [ ] All drag scenarios tested
- [ ] No yellow border bugs
- [ ] No orphaned cards

---

## Phase 5: Animations (Week 4)
**Goal**: Simplified animation system  
**Rollback Point**: Can use simple hide/show instead of animations

### 4.1 Create AnimationController Module
- [ ] Create `ui/organizer/animationController.lua`

- [ ] Add module definition
  ```lua
  local AnimationController = {}
  NextKey222.AnimationController = AnimationController
  NextKey222.RegisterModule("AnimationController", AnimationController)
  
  AnimationController.config = {
      flyDuration = 0.4,
      stepDelay = 0.02,
      arcHeight = 30
  }
  ```

- [ ] Implement MoveTo animation
  ```lua
  function AnimationController:MoveTo(card, targetFrame, onComplete)
      local startX, startY = card:GetCenter()
      local targetX, targetY = targetFrame:GetCenter()
      
      local duration = self.config.flyDuration
      local steps = math.floor(duration / self.config.stepDelay)
      local currentStep = 0
      
      -- Store original strata
      card.originalFrameStrata = card:GetFrameStrata()
      
      -- Elevate to UIParent
      card:SetParent(UIParent)
      card:SetFrameStrata("TOOLTIP")
      card:ClearAllPoints()
      card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", startX, startY)
      
      local function animateStep()
          currentStep = currentStep + 1
          local progress = currentStep / steps
          
          -- Ease-in-out
          local easedProgress = progress < 0.5
              and 2 * progress * progress
              or 1 - math.pow(-2 * progress + 2, 2) / 2
          
          -- Linear + arc
          local newX = startX + (targetX - startX) * easedProgress
          local baseY = startY + (targetY - startY) * easedProgress
          local arcOffset = self.config.arcHeight * math.sin(progress * math.pi)
          local newY = baseY + arcOffset
          
          card:ClearAllPoints()
          card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
          
          if currentStep >= steps then
              -- Animation complete - just hide
              card:Hide()
              if onComplete then onComplete() end
          else
              C_Timer.After(self.config.stepDelay, animateStep)
          end
      end
      
      animateStep()
  end
  ```

- [ ] Implement Reject animation
  ```lua
  function AnimationController:Reject(card, onComplete)
      -- Red flash
      card:SetBackdropBorderColor(1.0, 0, 0, 1.0)
      
      C_Timer.After(0.3, function()
          -- Reset
          if card.classColor then
              card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
          end
          if onComplete then onComplete() end
      end)
  end
  ```

- [ ] Update `NextKey.toc` load order
  - [ ] Add `ui/organizer/animationController.lua` after `ui/organizer/dragController.lua`

### 4.2 Update DragController to Use AnimationController
- [ ] Open `ui/organizer/dragController.lua`

- [ ] Replace AnimateMoveTo
  ```lua
  function DragController:CompleteDrag(card)
      -- ... validation code ...
      
      -- Update state FIRST
      NextKey222.OrganizerState:SetLocation(drag.playerID, toLocation)
      
      -- Use AnimationController
      NextKey222.AnimationController:MoveTo(card, dropTarget.frame, function()
          -- Animation complete - card is hidden
          -- Event system will rebuild UI from state
      end)
  end
  ```

- [ ] Replace AnimateReject
  ```lua
  if not self:ValidateMove(...) then
      NextKey222.AnimationController:Reject(card, function()
          -- Reset complete
      end)
      return
  end
  ```

### 4.3 Add Animation Flag to RosterBoard
- [ ] Open `ui/organizer/rosterBoard.lua`

- [ ] Update OnPlayerMoved
  ```lua
  function RosterBoard:OnPlayerMoved(payload)
      if not self:IsVisible() then return end
      
      -- NEW: Set animation flag before rebuild
      self.isAnimating = true
      
      local sections = self:GetAffectedSections(...)
      
      for _, section in ipairs(sections) do
          -- Rebuild sections
      end
      
      -- Clear flag after short delay (animations complete)
      C_Timer.After(0.5, function()
          self.isAnimating = false
      end)
  end
  ```

### 4.4 Testing
- [ ] Test animation smoothness
  - [ ] 60 FPS throughout animation
  - [ ] No stuttering or lag

- [ ] Test animation completion
  - [ ] Card hides after animation
  - [ ] UI rebuilds correctly
  - [ ] No orphaned cards

- [ ] Test multiple simultaneous drags
  - [ ] Animations don't conflict
  - [ ] Each completes independently

- [ ] Test rejection animation
  - [ ] Red flash appears
  - [ ] Card stays in place
  - [ ] Visual state resets

### 5.5 Phase 5 Deliverable
- [ ] Animations work smoothly
- [ ] No complex callback chains
- [ ] Cards always hide after animation
- [ ] UI rebuilds from state after animation

---

## Phase 6: Cleanup (Week 5)
**Goal**: Remove old system entirely  
**Rollback Point**: Phase 4 is stable fallback

### 5.1 Delete Old Files
- [ ] **BACKUP FIRST**: Create git branch or copy files to backup folder

- [ ] Delete `ui/organizer/dragManager.lua`
  - [ ] Remove from `NextKey.toc`
  - [ ] Search codebase for references: `DragManager`
  - [ ] Replace any remaining references

- [ ] Delete `ui/organizer/playerCard.lua`
  - [ ] Remove from `NextKey.toc`
  - [ ] Search for `PlayerCard:CreateNativeCard`
  - [ ] Replace with `CardView:Create`

- [ ] Delete `core/organizer/animationQueue.lua`
  - [ ] Remove from `NextKey.toc`
  - [ ] Search for `AnimationQueue:Execute`
  - [ ] Replace with `AnimationController` methods

- [ ] Delete `ui/organizer/modules/cardMovement.lua`
  - [ ] Remove from `NextKey.toc`
  - [ ] Search for `CardMovement:handle_card_drop`
  - [ ] Logic now in DragController

### 5.2 Clean Up RosterBoard
- [ ] Open `ui/organizer/rosterBoard.lua`

- [ ] Remove old methods (search and delete):
  - [ ] `MoveSingleCard` (line 2725)
  - [ ] `SyncBenchAndOptOutOnly` (line 2419)
  - [ ] `ResetDragState` (line 2696)
  - [ ] `HandleCardDrop` (delegates to CardMovement - line 1838)
  - [ ] `DetectDropTarget` (delegates to CardMovement - line 1832)
  - [ ] `MarkCardForRemoval` (line 1844)
  - [ ] `CompleteCardRemoval` (line 1850)
  - [ ] `AnimateRejection` (line 1874)
  - [ ] `PlaceCardInBench` (line 1862)
  - [ ] `RemoveCardFromBenchArray` (line 1868)

- [ ] Remove delegation methods to old modules
  - [ ] All `return NextKey222.CardMovement:...` calls
  - [ ] Replace with direct calls or remove entirely

- [ ] Simplify SyncUIToState (line 2294)
  ```lua
  function RosterBoard:SyncUIToState()
      return NextKey222.SafeRun(function()
          -- NEW: Just rebuild all sections
          self:RebuildBench()
          self:RebuildSlots()
          self:RebuildOptOut()
      end, "RosterBoard:SyncUIToState")
  end
  ```

- [ ] Remove orphaned card cleanup (lines 2432-2455)
  - [ ] No longer needed with new system

### 5.3 Clean Up OrganizerState
- [ ] Open `core/organizer/state.lua`

- [ ] Remove backward compatibility code
  - [ ] Remove fallback in GetLocation (keep only locations table lookup)
  - [ ] Remove ToLegacy call in SetLocation
  - [ ] Remove old bench/optOut/groups management from movement methods

- [ ] Update MoveToBench (line 369)
  ```lua
  function OrganizerState:MoveToBench(playerID)
      return NextKey222.SafeRun(function()
          local fromLocation = self:GetLocation(playerID)
          
          -- NEW: Simple location update
          self:SetLocation(playerID, "bench")
          
          -- Announce event
          local playerData = self.players[playerID]
          if playerData then
              self:AnnounceEvent("ORGANIZER_PLAYER_MOVED", {
                  playerID = playerID,
                  fromLocation = fromLocation,
                  toLocation = "bench",
                  playerData = playerData,
                  reason = "manual"
              })
          end
          
          return true
      end, "OrganizerState:MoveToBench")
  end
  ```

- [ ] Update MoveToOptOut similarly
- [ ] Update MoveToSlot similarly

- [ ] Remove old GetBenchPlayers (line 536)
  ```lua
  function OrganizerState:GetBenchPlayers()
      return NextKey222.SafeRun(function()
          local players = {}
          
          -- NEW: Filter locations table
          for playerID, location in pairs(self.locations) do
              if location == "bench" then
                  table.insert(players, playerID)
              end
          end
          
          return players
      end, "OrganizerState:GetBenchPlayers")
  end
  ```

- [ ] Remove old GetOptOutPlayers similarly
- [ ] Remove old GetSlotPlayers similarly

- [ ] Update SaveToPersistence (line 929)
  - [ ] Remove old format saving
  - [ ] Save only locations table

- [ ] Update LoadFromPersistence (line 1000)
  - [ ] Load only locations table
  - [ ] Remove conversion from old format

### 5.4 Update Load Order in NextKey.toc
- [ ] Remove old files:
  ```lua
  -- REMOVED: ui/organizer/dragManager.lua
  -- REMOVED: ui/organizer/playerCard.lua
  -- REMOVED: core/organizer/animationQueue.lua
  -- REMOVED: ui/organizer/modules/cardMovement.lua
  ```

- [ ] Add new files in order:
  ```lua
  core/organizer/location.lua
  core/organizer/state.lua
  ui/organizer/cardView.lua
  ui/organizer/dragController.lua
  ui/organizer/animationController.lua
  ui/organizer/rosterBoard.lua
  ```

### 5.5 Final Testing
- [ ] Full regression test suite
  - [ ] Bench → Slot (all roles)
  - [ ] Slot → Bench
  - [ ] Slot → Slot
  - [ ] Bench → Opt-out
  - [ ] Opt-out → Bench
  - [ ] Same-location drops
  - [ ] Invalid role drops

- [ ] Performance testing
  - [ ] Load time: <2 seconds
  - [ ] Drag response: <16ms
  - [ ] Animation FPS: 60
  - [ ] Memory: <50MB with 40 players
  - [ ] Rebuild time: <100ms

- [ ] Persistence testing
  - [ ] Save state
  - [ ] `/reload`
  - [ ] Verify all locations restored
  - [ ] Verify all cards appear correctly

- [ ] Edge cases
  - [ ] Empty bench
  - [ ] Full groups
  - [ ] All players opted out
  - [ ] Rapid successive drags
  - [ ] Drag during animation

### 5.6 Code Quality Check
- [ ] Search for `print()` statements - replace with Debug
- [ ] Search for `TODO` comments - resolve or file issues
- [ ] Search for `HACK` comments - should be none
- [ ] Search for `FIXME` comments - should be none
- [ ] Run through all MARK sections - verify organization

### 5.7 Documentation Update
- [ ] Update `Documentation/FEATURES & PLANS/M+_Organizer_MASTER_IMPLEMENTATION_CHECKLIST.md`
  - [ ] Mark drag-and-drop refactor complete
  - [ ] Update architecture diagrams

- [ ] Update `Documentation/_Architectural_Audit/` if needed
  - [ ] Document new architecture
  - [ ] Remove old system references

- [ ] Update memory-bank files
  - [ ] `architecture.md` - new drag system
  - [ ] `context.md` - mark refactor complete
  - [ ] `status.md` - update completed items

### 6.8 Phase 6 Deliverable
- [ ] Old files deleted
- [ ] Old code removed
- [ ] Clean, simplified codebase
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Ready for production

---

## Success Verification

### Metrics to Verify
- [ ] **Code Reduction**: 43% less code (3,500 → 2,000 lines)
- [ ] **File Count**: 7 → 5 files
- [ ] **Bug Categories**: All 8 eliminated
- [ ] **Performance**: All targets met
- [ ] **Memory**: Reduced or stable

### Final Sign-Off
- [ ] All phases complete
- [ ] All tests pass
- [ ] No regressions found
- [ ] Performance acceptable
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Ready for merge

---

## Rollback Procedures

### Phase 1 Rollback
```lua
-- Remove location.lua from toc
-- Comment out locations table in state.lua
-- Remove GetLocation/SetLocation methods
```

### Phase 2 Rollback
```lua
-- Remove cardView.lua from toc
-- Remove RebuildBench/Slots/OptOut methods
-- Revert to old card creation
```

### Phase 3 Rollback
```lua
-- Remove dragController.lua from toc
-- Re-enable old drag handlers
-- Revert OnPlayerMoved to old logic
```

### Phase 4 Rollback
```lua
-- Remove animationController.lua from toc
-- Use simple hide/show instead of animations
-- Remove animation flags
```

### Phase 5 Rollback
```lua
-- Restore old files from backup
-- Revert toc changes
-- Revert to Phase 4 state
```

---

## Notes for Future Maintainers

### Design Principles
1. **OrganizerState owns all data** - Never store state in UI
2. **Cards are views** - Only store playerID reference
3. **State-first updates** - Always update state before UI
4. **Event-driven UI** - UI reacts to state changes only
5. **Single drag system** - No duplicate implementations

### Common Pitfalls to Avoid
- ❌ Don't store playerData on cards
- ❌ Don't update UI before state
- ❌ Don't create multiple drag systems
- ❌ Don't mix animation and state updates
- ❌ Don't add guard flags without documenting why

### Extension Points
- Add new display modes: Update `CardView:GetDisplayMode()`
- Add new drop targets: Update `DragController:DetectDropTarget()`
- Add new animations: Add methods to `AnimationController`
- Add new validation: Update `DragController:ValidateMove()`

---

## Estimated Time Breakdown

| Phase | Days | Hours |
|-------|------|-------|
| Phase 1: Foundation | 5 | 15-20 |
| Phase 2: Views | 5 | 15-20 |
| Phase 3: Drag System | 5 | 20-25 |
| Phase 4: Animations | 5 | 15-20 |
| Phase 5: Cleanup | 5 | 15-20 |
| **Total** | **25** | **80-100** |

**Working Schedule**: ~4 hours/day = 5 weeks