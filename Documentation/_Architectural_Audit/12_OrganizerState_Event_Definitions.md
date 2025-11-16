# OrganizerState Event Definitions

**Date**: November 16, 2025
**Purpose**: Define event names, payloads, and contracts for event-driven OrganizerState refactor
**Status**: Part 2 - Event Definition Complete

---

## Executive Summary

This document defines the **5 core events** that will replace direct mutation calls to OrganizerState. These events follow the AceEvent-3.0 pattern used throughout NextKey and enable a clean separation between state management and UI reactions.

**Design Principles**:
1. **Events announce WHAT happened, not HOW to react** - State owns the event, UI owns the reaction
2. **Payloads include all necessary context** - No additional queries needed in handlers
3. **Events fire AFTER successful state changes** - Never announce failed operations
4. **Single responsibility per event** - Each event represents one atomic state change
5. **Backward compatible** - Query operations remain as direct calls

---

## Event Catalog

### 1. ORGANIZER_PLAYER_ADDED

**Purpose**: Announces when a new player is added to OrganizerState

**When Fired**: After successful `SetPlayer()` for a player that didn't previously exist

**Payload Structure**:
```lua
{
    playerID = "PlayerName-Realm",           -- Player identifier
    playerData = {                           -- Complete player object
        id = "PlayerName-Realm",
        name = "PlayerName",
        class = "WARRIOR",
        roles = {"TANK", "DAMAGER"},
        overallScore = 3000,
        specPreferences = {...},
        specDetails = {...},
        -- ... all other player fields
    },
    location = "bench",                      -- Initial location: "bench", "opt_out", or {type="role_slot", groupIndex=N, slotIndex=N}
    source = "poll_response",                -- Source of addition: "poll_response", "auto_detect", "manual", "alt_selection"
    timestamp = 1234567890.123               -- GetTime() when added
}
```

**Who Listens**:
- `RosterBoard` - Creates player card in appropriate location
- `BenchManager` - Adds card to bench UI (if location = "bench")
- `SlotManager` - Places card in slot (if location = "role_slot")

**Call Sites** (3 total):
- `benchManager.lua:65` - Add fake player
- `benchManager.lua:98` - Add party member
- `survey.lua:340` - Add alt player

---

### 2. ORGANIZER_PLAYER_MOVED

**Purpose**: Announces when a player moves between bench/slot/opt-out

**When Fired**: After successful `MoveToBench()`, `MoveToSlot()`, or `MoveToOptOut()`

**Payload Structure**:
```lua
{
    playerID = "PlayerName-Realm",           -- Player identifier
    fromLocation = "bench",                  -- Previous location: "bench", "opt_out", or {type="role_slot", groupIndex=N, slotIndex=N}
    toLocation = {                           -- New location (same format as fromLocation)
        type = "role_slot",
        groupIndex = 1,
        slotIndex = 2
    },
    playerData = {                           -- Complete player object after move
        id = "PlayerName-Realm",
        name = "PlayerName",
        class = "WARRIOR",
        roles = {"TANK"},
        -- ... all player fields
    },
    reason = "drag_drop",                    -- Reason for move: "drag_drop", "sort_algorithm", "poll_response", "return_all"
    timestamp = 1234567890.123
}
```

**Who Listens**:
- `RosterBoard` - Coordinates card movement animation
- `BenchManager` - Updates bench layout
- `SlotManager` - Updates slot state, triggers role validation UI
- `CardMovement` - Handles visual card transition
- `AnimationQueue` - Queues movement animation (if reason = "sort_algorithm")

**Call Sites** (10 total):
- `benchManager.lua:66, 99` - Move to bench (2 calls)
- `cardMovement.lua:238` - Move card to bench
- `slotManager.lua:332` - Move to slot
- `slotManager.lua:494, 705` - Move to bench from opt-out/group (2 calls)
- `survey.lua:326, 329, 341, 343, 350` - Poll-driven moves (5 calls)

---

### 3. ORGANIZER_PLAYER_UPDATED

**Purpose**: Announces when player data changes (non-location updates)

**When Fired**: After successful `UpdatePlayer()` or `UpdatePlayerFromPollResponse()`

**Payload Structure**:
```lua
{
    playerID = "PlayerName-Realm",           -- Player identifier
    updates = {                              -- Changed fields only
        benchedForAlt = true,
        overallScore = 3100,
        -- ... only fields that changed
    },
    playerData = {                           -- Complete player object after update
        id = "PlayerName-Realm",
        name = "PlayerName",
        benchedForAlt = true,
        overallScore = 3100,
        -- ... all player fields
    },
    updateType = "poll_response",            -- Type of update: "poll_response", "profile_refresh", "manual_edit", "spec_change"
    timestamp = 1234567890.123
}
```

**Who Listens**:
- `PlayerCard` - Refreshes card content to show new data
- `RosterBoard` - Updates any affected UI elements (e.g., benched-for-alt indicators)

**Call Sites** (3 total):
- `survey.lua:342` - Mark benched for alt
- `state.lua:119-138` - UpdatePlayer() (generic updates)
- `state.lua:146-186` - UpdatePlayerFromPollResponse() (poll data)

---

### 4. ORGANIZER_POLL_RESPONSE_RECEIVED

**Purpose**: Announces when a poll response is processed and stored in state

**When Fired**: After successful `AddPollResponse()` and `UpdatePlayerFromPollResponse()`

**Payload Structure**:
```lua
{
    playerID = "PlayerName-Realm",           -- Player who responded
    response = {                             -- Poll response data
        pollID = "1234567890-5678",
        optedIn = true,
        selectedCharacter = "PlayerName-Realm",
        specPreferences = {
            TANK = "preferred",
            HEALER = "available",
            DAMAGER = "preferred"
        },
        specDetails = {
            TANK = {...},
            HEALER = {...},
            DAMAGER = {...}
        },
        rolePreferences = {...}
    },
    playerData = {                           -- Complete player object after processing response
        id = "PlayerName-Realm",
        specPreferences = {...},             -- Updated with poll data
        specDetails = {...},
        -- ... all player fields
    },
    timestamp = 1234567890.123,
    totalResponses = 5,                      -- Count of responses received so far
    expectedResponses = 10                   -- Total expected (for progress tracking)
}
```

**Who Listens**:
- `RosterBoard` - Updates poll progress UI
- `PlayerCard` - Refreshes card to show poll data (role icon colors)
- `SurveyDialog` - Updates response count display

**Call Sites** (2 total):
- `surveyDialog.lua:1126` - Process dialog response
- `survey.lua:314` - Process received poll response

---

### 5. ORGANIZER_STATE_CLEARED

**Purpose**: Announces when organizer state is completely reset (Clear Poll)

**When Fired**: After successful `ClearPersistedData()`

**Payload Structure**:
```lua
{
    reason = "clear_poll",                   -- Reason for clear: "clear_poll", "new_poll", "logout"
    clearedData = {                          -- Summary of what was cleared
        playerCount = 15,
        benchCount = 10,
        groupedCount = 4,
        optOutCount = 1,
        keystoneCount = 2
    },
    timestamp = 1234567890.123
}
```

**Who Listens**:
- `RosterBoard` - Triggers full UI rebuild
- `BenchManager` - Clears all bench cards
- `SlotManager` - Clears all group slots
- `KeystoneManager` - Clears keystone designations

**Call Sites** (1 total):
- `rosterBoard.lua:1423` - Clear Poll button

---

## Location Data Structure

**Standard Location Format** (used in all movement events):

```lua
-- Simple locations (strings):
"bench"                                      -- Player is on bench
"opt_out"                                    -- Player opted out

-- Complex location (table):
{
    type = "role_slot",                      -- Player is in a group slot
    groupIndex = 1,                          -- Group number (1-4)
    slotIndex = 2                            -- Slot number (1-5)
}
```

**Location Utilities** (to be added to OrganizerState):

```lua
-- Helper to serialize location for event payloads
function OrganizerState:SerializeLocation(playerID)
    local location = self:GetPlayerLocation(playerID)
    
    if type(location) == "string" then
        return location
    elseif type(location) == "table" then
        return {
            type = "role_slot",
            groupIndex = location.groupIndex,
            slotIndex = location.slotIndex
        }
    else
        return nil
    end
end
```

---

## Event Announcement Implementation

### Generic Announcement Helper

Add to [`core/organizer/state.lua`](../../core/organizer/state.lua:1):

```lua
-- MARK: Event System
--- Announce an event via AceEvent system
-- @param eventName string - Event name (e.g., "ORGANIZER_PLAYER_ADDED")
-- @param payload table - Event payload with all necessary context
function OrganizerState:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            Debug:Error("Cannot announce event - AceEvent system not available:", eventName)
            return false
        end
        
        -- Always include timestamp
        if not payload.timestamp then
            payload.timestamp = GetTime()
        end
        
        -- Announce event
        NextKey222.Addon:SendMessage(eventName, payload)
        
        Debug:Dev("organizer_events", "Event announced:", eventName, "- playerID:", payload.playerID or "N/A")
        
        return true
    end, "OrganizerState:AnnounceEvent")
end
```

### Example: SetPlayer() with Event

```lua
function OrganizerState:SetPlayer(playerID, playerData)
    return NextKey222.SafeRun(function()
        if not playerID or not playerData then
            Debug:Error("SetPlayer called with missing arguments")
            return
        end
        
        -- Check if player is new
        local isNewPlayer = (self.players[playerID] == nil)
        
        -- Normalize and store player data
        playerData.id = playerID
        -- ... existing normalization logic ...
        self.players[playerID] = playerData
        
        -- ANNOUNCE EVENT (only for new players)
        if isNewPlayer then
            local location = self:SerializeLocation(playerID)
            
            self:AnnounceEvent("ORGANIZER_PLAYER_ADDED", {
                playerID = playerID,
                playerData = playerData,
                location = location or "bench",  -- Default to bench if no location
                source = "manual",                -- Can be parameterized
                timestamp = GetTime()
            })
        end
        
        Debug:Dev("organizer_state", "SetPlayer:", playerID, "- new:", isNewPlayer)
    end, "OrganizerState:SetPlayer")
end
```

---

## Event Listener Registration

### RosterBoard Listener Setup

Add to [`ui/organizer/rosterBoard.lua:Initialize()`](../../ui/organizer/rosterBoard.lua:47):

```lua
function RosterBoard:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Initializing Roster Board module")
        
        -- ... existing initialization ...
        
        -- REGISTER EVENT LISTENERS
        if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_ADDED", function(event, payload)
                self:OnPlayerAdded(payload)
            end)
            
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_MOVED", function(event, payload)
                self:OnPlayerMoved(payload)
            end)
            
            NextKey222.Addon:RegisterMessage("ORGANIZER_PLAYER_UPDATED", function(event, payload)
                self:OnPlayerUpdated(payload)
            end)
            
            NextKey222.Addon:RegisterMessage("ORGANIZER_POLL_RESPONSE_RECEIVED", function(event, payload)
                self:OnPollResponseReceived(payload)
            end)
            
            NextKey222.Addon:RegisterMessage("ORGANIZER_STATE_CLEARED", function(event, payload)
                self:OnStateCleared(payload)
            end)
            
            Debug:Dev("organizer_ui", "Registered 5 organizer event listeners")
        else
            Debug:Error("Cannot register event listeners - AceEvent system not available")
        end
        
        Debug:Dev("organizer_ui", "Roster Board initialized successfully")
        return true
    end, "RosterBoard:Initialize")
end
```

---

## Event Handler Patterns

### Pattern 1: Simple UI Update

```lua
function RosterBoard:OnPlayerUpdated(payload)
    return NextKey222.SafeRun(function()
        -- Find the player's card
        local card = self:FindCardByPlayerID(payload.playerID)
        
        if card then
            -- Update card content with fresh data
            NextKey222.PlayerCard:UpdateCardContent(card, card.displayMode)
            Debug:Dev("organizer_ui", "Updated card for:", payload.playerID)
        else
            Debug:Dev("organizer_ui", "Card not found for:", payload.playerID, "- may need rebuild")
        end
    end, "RosterBoard:OnPlayerUpdated")
end
```

### Pattern 2: Complex State Transition

```lua
function RosterBoard:OnPlayerMoved(payload)
    return NextKey222.SafeRun(function()
        local playerID = payload.playerID
        local fromLocation = payload.fromLocation
        local toLocation = payload.toLocation
        
        Debug:Dev("organizer_ui", "Player moved:", playerID, "from", fromLocation, "to", toLocation)
        
        -- Find card in old location
        local card = self:FindCardByPlayerID(playerID)
        
        if not card then
            Debug:Error("Card not found for moving player:", playerID)
            return
        end
        
        -- Remove from old location (visual only - state already updated)
        if fromLocation == "bench" then
            NextKey222.BenchManager:remove_card_from_bench_ui(self, card)
        elseif fromLocation == "opt_out" then
            self:RemoveCardFromOptOutUI(card)
        elseif type(fromLocation) == "table" and fromLocation.type == "role_slot" then
            NextKey222.SlotManager:clear_slot_ui(self, fromLocation.groupIndex, fromLocation.slotIndex)
        end
        
        -- Add to new location (visual only)
        if toLocation == "bench" then
            NextKey222.BenchManager:add_card_to_bench_ui(self, card)
        elseif toLocation == "opt_out" then
            self:AddCardToOptOutUI(card)
        elseif type(toLocation) == "table" and toLocation.type == "role_slot" then
            local targetSlot = self.groupSlots[toLocation.groupIndex][toLocation.slotIndex]
            NextKey222.SlotManager:place_card_in_slot(card, targetSlot)
        end
        
        Debug:Dev("organizer_ui", "Player move UI updated:", playerID)
    end, "RosterBoard:OnPlayerMoved")
end
```

### Pattern 3: Broadcast Progress Update

```lua
function RosterBoard:OnPollResponseReceived(payload)
    return NextKey222.SafeRun(function()
        -- Update poll progress UI
        if self.pollLabel then
            local progress = string.format("Responses received: %d/%d",
                payload.totalResponses, payload.expectedResponses)
            self.pollLabel:SetText("POLL CONTROLS - " .. progress)
        end
        
        -- Refresh specific player's card
        self:RefreshSingleCardByPlayerID(payload.playerID)
        
        Debug:Dev("organizer_ui", "Poll response UI updated for:", payload.playerID)
    end, "RosterBoard:OnPollResponseReceived")
end
```

---

## Migration Strategy

### Phase 1: Add Event Announcements (Non-Breaking)

**Goal**: Add event announcements to all mutation methods WITHOUT removing existing direct UI calls

**Changes**:
1. Add `AnnounceEvent()` helper to OrganizerState
2. Add event announcements to each mutation method (after state change, before return)
3. Keep existing direct calls intact

**Risk**: LOW - Purely additive, no breaking changes

**Testing**: Verify events fire correctly via debug logs

---

### Phase 2: Add Event Listeners (Non-Breaking)

**Goal**: Register event listeners in UI modules WITHOUT removing direct state queries

**Changes**:
1. Add listener registration to `RosterBoard:Initialize()`
2. Implement event handler methods (can be no-ops initially)
3. Keep existing direct state queries intact

**Risk**: LOW - Listeners exist alongside direct calls

**Testing**: Verify handlers fire when events announced

---

### Phase 3: Implement Event Handlers (Breaking Changes)

**Goal**: Move UI update logic from direct calls to event handlers

**Changes**:
1. Implement full logic in event handlers
2. Remove direct UI manipulation from state mutation methods
3. UI reacts ONLY to events, never calls state methods for updates

**Risk**: MEDIUM - Changes control flow, requires careful testing

**Testing**: 
- All organizer workflows (add, move, remove players)
- Poll response processing
- Drag-and-drop operations
- Sort algorithm execution

---

### Phase 4: Cleanup (Optional)

**Goal**: Remove any remaining redundant code

**Changes**:
1. Remove unused helper methods
2. Consolidate event handling logic
3. Optimize event payload sizes if needed

**Risk**: LOW - Cleanup only, no functional changes

---

## Success Criteria

### Functional Requirements
- ✅ All 16 mutation operations announce events
- ✅ All events include complete payload data
- ✅ UI reacts to events only (no direct state manipulation)
- ✅ State changes persist correctly
- ✅ No race conditions in multi-user scenarios

### Performance Requirements
- ✅ Event announcement overhead < 1ms per event
- ✅ No memory leaks from event listeners
- ✅ Organizer performance unchanged (baseline < 100ms UI response)

### Code Quality Requirements
- ✅ All event handlers wrapped in SafeRun
- ✅ All events logged via Debug system
- ✅ Event payloads well-documented
- ✅ Clear separation: State announces, UI listens

---

## Testing Checklist

### Event Announcement Tests
- [ ] `ORGANIZER_PLAYER_ADDED` fires when SetPlayer() adds new player
- [ ] `ORGANIZER_PLAYER_MOVED` fires for MoveToBench(), MoveToSlot(), MoveToOptOut()
- [ ] `ORGANIZER_PLAYER_UPDATED` fires for UpdatePlayer() and UpdatePlayerFromPollResponse()
- [ ] `ORGANIZER_POLL_RESPONSE_RECEIVED` fires after poll response processed
- [ ] `ORGANIZER_STATE_CLEARED` fires when ClearPersistedData() called

### Event Payload Tests
- [ ] All payloads include playerID
- [ ] All payloads include complete playerData
- [ ] Movement payloads include fromLocation and toLocation
- [ ] Poll payloads include response count
- [ ] All payloads include timestamp

### Event Handler Tests
- [ ] RosterBoard listeners registered successfully
- [ ] OnPlayerAdded() creates card in correct location
- [ ] OnPlayerMoved() updates UI correctly
- [ ] OnPlayerUpdated() refreshes card content
- [ ] OnPollResponseReceived() updates progress
- [ ] OnStateCleared() rebuilds UI from scratch

### Integration Tests
- [ ] Drag player from bench to slot (OnPlayerMoved fires)
- [ ] Poll response adds player to bench (OnPlayerAdded fires)
- [ ] Poll response moves player to opt-out (OnPlayerMoved fires)
- [ ] Sort algorithm moves 10+ players (OnPlayerMoved fires for each)
- [ ] Clear Poll button (OnStateCleared fires)

### Persistence Tests
- [ ] State persists after player added via event
- [ ] State persists after player moved via event
- [ ] State persists after poll response via event
- [ ] State reloads correctly after /reload
- [ ] UI rebuilds from state after /reload

---

## Dependencies

### Required Modules
- `core/organizer/state.lua` - Event announcement source
- `ui/organizer/rosterBoard.lua` - Primary event listener
- `ui/organizer/modules/benchManager.lua` - Bench UI reactions
- `ui/organizer/modules/slotManager.lua` - Slot UI reactions
- `ui/organizer/modules/cardMovement.lua` - Movement animations
- `ui/organizer/playerCard.lua` - Card content updates

### External Systems
- `AceEvent-3.0` - Event pub/sub system
- `NextKey222.Addon` - AceAddon instance for SendMessage/RegisterMessage
- `NextKey222.Debug` - Debug logging for event tracking

---

## Next Steps

1. ✅ **Complete** - Part 1: Identify Direct Calls
2. ✅ **Complete** - Part 2: Define Events (this document)
3. ⏭️ **Next** - Part 3: Implement Events
   - Add AnnounceEvent() helper
   - Add event announcements to mutation methods
   - Register event listeners in RosterBoard
   - Implement event handlers
   - Remove direct UI calls from state
4. ⏭️ **Then** - Part 4: Testing
   - Validate all workflows
   - Test in real groups
   - Verify persistence

---

**Status**: Part 2 Complete - Event definitions ready for implementation