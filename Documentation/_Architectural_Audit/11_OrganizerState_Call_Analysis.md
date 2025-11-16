# OrganizerState Direct Call Analysis

**Date**: November 16, 2025
**Purpose**: Identify and categorize all direct calls to OrganizerState for event-driven refactor
**Status**: Part 1 - Call Identification Complete

---

## Executive Summary

Found **32 direct call sites** to `NextKey222.OrganizerState` across 6 files. These calls are categorized into:

- **Query Operations** (16 calls) - Can remain as direct calls
- **Mutation Operations** (16 calls) - Must convert to events

---

## Call Categories

### Category 1: Query Operations (Read-Only) ✅ Keep Direct Calls

These operations read state without modifying it. They can remain as direct calls since they don't trigger side effects.

| File | Line | Method | Context |
|------|------|--------|---------|
| `ui/controls.lua` | 273 | `GetAllPlayers()` | Fetch players for dropdown |
| `ui/organizer/playerCard.lua` | 424 | `GetPlayer()` | Refresh card data |
| `ui/organizer/modules/benchManager.lua` | 27 | `GetBenchPlayers()` | Get bench player IDs |
| `ui/organizer/modules/benchManager.lua` | 33 | `GetPlayer()` | Fetch player data |
| `ui/organizer/modules/benchManager.lua` | 54 | `PlayerExists()` | Check if player exists |
| `ui/organizer/modules/benchManager.lua` | 58 | `GetPlayerLocation()` | Check player location |
| `ui/organizer/modules/benchManager.lua` | 86 | `PlayerExists()` | Check if player exists |
| `ui/organizer/modules/benchManager.lua` | 90 | `GetPlayerLocation()` | Check player location |
| `ui/organizer/rosterBoard.lua` | 474 | `GetSlotPlayer()` | Get player in slot |
| `ui/organizer/rosterBoard.lua` | 482 | `GetPlayer()` | Fetch player data |
| `ui/organizer/rosterBoard.lua` | 511 | `GetOptOutPlayers()` | Get opt-out player IDs |
| `ui/organizer/rosterBoard.lua` | 514 | `GetPlayer()` | Fetch player data |
| `ui/organizer/rosterBoard.lua` | 1179 | `GetGroupAssignments()` | Get group slot assignments |
| `ui/organizer/rosterBoard.lua` | 1189 | `GetDesignatedKeystone()` | Get group keystone |
| `ui/organizer/rosterBoard.lua` | 1209 | `GetPlayer()` | Fetch player data |
| `ui/organizer/rosterBoard.lua` | 2162-2163 | `GetBenchPlayers()`, `GetOptOutPlayers()` | Sync UI to state |
| `ui/organizer/rosterBoard.lua` | 2189 | `GetPlayer()` | Fetch player data |
| `ui/organizer/rosterBoard.lua` | 2205 | `GetPlayer()` | Fetch player data |

**Total Query Operations**: 16 calls across 4 files

---

### Category 2: Mutation Operations (State Changes) 🔄 Convert to Events

These operations modify state and should announce events for UI/system reactions.

#### 2A: Player Management Mutations

| File | Line | Method | Context | Event Needed |
|------|------|--------|---------|--------------|
| `ui/organizer/modules/benchManager.lua` | 65 | `SetPlayer()` | Add fake player | `ORGANIZER_PLAYER_ADDED` |
| `ui/organizer/modules/benchManager.lua` | 66 | `MoveToBench()` | Move to bench | `ORGANIZER_PLAYER_MOVED` |
| `ui/organizer/modules/benchManager.lua` | 98 | `SetPlayer()` | Add party member | `ORGANIZER_PLAYER_ADDED` |
| `ui/organizer/modules/benchManager.lua` | 99 | `MoveToBench()` | Move to bench | `ORGANIZER_PLAYER_MOVED` |
| `ui/organizer/modules/cardMovement.lua` | 238 | `MoveToBench()` | Move card to bench | `ORGANIZER_PLAYER_MOVED` |
| `ui/organizer/modules/cardMovement.lua` | 241 | `GetPlayer()` | Fetch fresh data | (query - no event) |
| `ui/organizer/modules/slotManager.lua` | 332 | `MoveToSlot()` | Place card in slot | `ORGANIZER_PLAYER_MOVED` |
| `ui/organizer/modules/slotManager.lua` | 494 | `MoveToBench()` | Return from opt-out | `ORGANIZER_PLAYER_MOVED` |
| `ui/organizer/modules/slotManager.lua` | 705 | `MoveToBench()` | Remove group - move players | `ORGANIZER_PLAYER_MOVED` |

**Subtotal**: 9 calls (7 mutations, 2 queries)

#### 2B: Poll/Survey Mutations

| File | Line | Method | Context | Event Needed |
|------|------|--------|---------|--------------|
| `ui/organizer/surveyDialog.lua` | 1126 | `UpdatePlayerFromPollResponse()` | Process poll response | `ORGANIZER_POLL_RESPONSE_RECEIVED` |
| `ui/organizer/surveyDialog.lua` | 1136 | `SaveToPersistence()` | Save state | (internal - no event) |
| `core/organizer/survey.lua` | 314 | `UpdatePlayerFromPollResponse()` | Store poll response | `ORGANIZER_POLL_RESPONSE_RECEIVED` |
| `core/organizer/survey.lua` | 323 | `GetPlayerLocation()` | Check location | (query - no event) |
| `core/organizer/survey.lua` | 326 | `MoveToBench()` | Opt back in | `ORGANIZER_PLAYER_MOVED` |
| `core/organizer/survey.lua` | 329 | `MoveToBench()` | Add new player | `ORGANIZER_PLAYER_MOVED` |
| `core/organizer/survey.lua` | 340 | `SetPlayer()` | Add alt player | `ORGANIZER_PLAYER_ADDED` |
| `core/organizer/survey.lua` | 341 | `MoveToBench()` | Move alt to bench | `ORGANIZER_PLAYER_MOVED` |
| `core/organizer/survey.lua` | 342 | `UpdatePlayer()` | Mark benched for alt | `ORGANIZER_PLAYER_UPDATED` |
| `core/organizer/survey.lua` | 343 | `MoveToOptOut()` | Move to opt-out | `ORGANIZER_PLAYER_MOVED` |
| `core/organizer/survey.lua` | 350 | `MoveToOptOut()` | Player opted out | `ORGANIZER_PLAYER_MOVED` |
| `core/organizer/survey.lua` | 288 | `SaveToPersistence()` | Save state | (internal - no event) |

**Subtotal**: 12 calls (8 mutations, 2 queries, 2 internal)

#### 2C: Administrative Mutations

| File | Line | Method | Context | Event Needed |
|------|------|--------|---------|--------------|
| `ui/organizer/rosterBoard.lua` | 1423 | `ClearPersistedData()` | Clear poll data | `ORGANIZER_STATE_CLEARED` |

**Subtotal**: 1 call

**Total Mutation Operations**: 16 calls (15 mutations + 1 clear)

---

## Mutation Operations Summary by Type

### Player Movement (10 calls)
- `MoveToBench()` - 6 calls
- `MoveToSlot()` - 1 call
- `MoveToOptOut()` - 2 calls
- Location transitions that need `ORGANIZER_PLAYER_MOVED` event

### Player Data Changes (5 calls)
- `SetPlayer()` - 3 calls (new players)
- `UpdatePlayer()` - 1 call (mark benched for alt)
- `UpdatePlayerFromPollResponse()` - 2 calls (poll data)
- Need `ORGANIZER_PLAYER_ADDED` or `ORGANIZER_PLAYER_UPDATED` events

### State Operations (1 call)
- `ClearPersistedData()` - 1 call
- Needs `ORGANIZER_STATE_CLEARED` event

---

## Event Design Recommendations

### Core Events

1. **`ORGANIZER_PLAYER_ADDED`**
   - Payload: `{playerID, playerData, location}`
   - Fired when: New player added to state
   - Listeners: RosterBoard (create card), BenchManager (add to UI)

2. **`ORGANIZER_PLAYER_MOVED`**
   - Payload: `{playerID, fromLocation, toLocation, playerData}`
   - Fired when: Player moves between bench/slot/opt-out
   - Listeners: RosterBoard (update card position), SlotManager (update slot state)

3. **`ORGANIZER_PLAYER_UPDATED`**
   - Payload: `{playerID, updates, playerData}`
   - Fired when: Player data changes (not location)
   - Listeners: PlayerCard (refresh content)

4. **`ORGANIZER_POLL_RESPONSE_RECEIVED`**
   - Payload: `{playerID, response, timestamp}`
   - Fired when: Poll response processed
   - Listeners: RosterBoard (update progress), PlayerCard (refresh with poll data)

5. **`ORGANIZER_STATE_CLEARED`**
   - Payload: `{timestamp}`
   - Fired when: State cleared (Clear Poll button)
   - Listeners: RosterBoard (rebuild UI)

### Location Types

```lua
-- Location structure for events
location = {
    type = "bench" | "opt_out" | "role_slot",
    groupIndex = number,  -- only for role_slot
    slotIndex = number    -- only for role_slot
}
```

---

## Implementation Plan

### Phase 1: Add Event Announcements to OrganizerState

Modify [`core/organizer/state.lua`](../../core/organizer/state.lua:1):

```lua
-- After SetPlayer()
function OrganizerState:SetPlayer(playerID, playerData)
    -- ... existing logic ...
    
    -- ANNOUNCE EVENT
    self:AnnounceEvent("ORGANIZER_PLAYER_ADDED", {
        playerID = playerID,
        playerData = playerData,
        location = self:GetPlayerLocation(playerID)
    })
end

-- After MoveToBench(), MoveToSlot(), MoveToOptOut()
function OrganizerState:MoveToBench(playerID)
    local fromLocation = self:GetPlayerLocation(playerID)
    
    -- ... existing logic ...
    
    -- ANNOUNCE EVENT
    self:AnnounceEvent("ORGANIZER_PLAYER_MOVED", {
        playerID = playerID,
        fromLocation = fromLocation,
        toLocation = "bench",
        playerData = self:GetPlayer(playerID)
    })
end

-- After UpdatePlayer()
function OrganizerState:UpdatePlayer(playerID, updates)
    -- ... existing logic ...
    
    -- ANNOUNCE EVENT
    self:AnnounceEvent("ORGANIZER_PLAYER_UPDATED", {
        playerID = playerID,
        updates = updates,
        playerData = self:GetPlayer(playerID)
    })
end

-- Add event announcement helper
function OrganizerState:AnnounceEvent(eventName, payload)
    if NextKey222.Addon and NextKey222.Addon.SendMessage then
        NextKey222.Addon:SendMessage(eventName, payload)
        Debug:Dev("organizer_events", "Event announced:", eventName, "playerID:", payload.playerID)
    end
end
```

### Phase 2: Update UI Modules to Listen

Modify [`ui/organizer/rosterBoard.lua`](../../ui/organizer/rosterBoard.lua:1):

```lua
function RosterBoard:Initialize()
    -- ... existing logic ...
    
    -- Register event listeners
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
    end
end

-- Event handlers
function RosterBoard:OnPlayerAdded(payload)
    -- Create card in appropriate location
end

function RosterBoard:OnPlayerMoved(payload)
    -- Move card between bench/slot/opt-out
end

function RosterBoard:OnPlayerUpdated(payload)
    -- Refresh card content
end
```

### Phase 3: Remove Direct State Mutations from UI

Replace direct calls with state-only operations (event announcement happens inside OrganizerState):

```lua
-- BEFORE (direct mutation):
NextKey222.OrganizerState:MoveToBench(playerID)
NextKey222.CardMovement:place_card_in_bench(self, card)

-- AFTER (event-driven):
NextKey222.OrganizerState:MoveToBench(playerID)  -- Announces ORGANIZER_PLAYER_MOVED
-- UI reacts via event handler automatically
```

### Phase 4: Testing Checklist

- [ ] Add player to bench (fake or real)
- [ ] Move player between bench and slot
- [ ] Move player to opt-out
- [ ] Process poll response
- [ ] Clear poll data
- [ ] Verify state persistence after each operation
- [ ] Test in real group with multiple users
- [ ] Check for race conditions

---

## Risk Analysis

### Low Risk (Query Operations)
- No changes needed to query operations
- Continue using direct calls for reads
- Zero breaking changes

### Medium Risk (Mutation Operations)
- Event announcement must happen AFTER state change (not before)
- UI listeners must handle events idempotently
- Multiple events may fire in quick succession
- Need to test event ordering in complex workflows

### High Risk Areas
- Poll response processing (multiple state changes in sequence)
- Return All / Recall All operations (batch moves)
- Group add/remove with player reassignment

---

## Success Criteria

1. ✅ All state mutations announce events
2. ✅ UI reacts to events only (no direct UI calls from state)
3. ✅ State changes persist correctly
4. ✅ No race conditions in multi-user scenarios
5. ✅ Zero breaking changes to existing workflows

---

## Next Steps

1. ✅ **Complete** - Identify and categorize all calls (this document)
2. ⏭️ **Next** - Define event payloads and contracts
3. ⏭️ **Then** - Implement event announcements in OrganizerState
4. ⏭️ **Then** - Update UI modules to listen for events
5. ⏭️ **Finally** - Test in real groups and validate persistence

---

## Appendix: Files Requiring Changes

### Core Files
- `core/organizer/state.lua` - Add event announcements to mutation methods

### UI Files
- `ui/organizer/rosterBoard.lua` - Register event listeners, add event handlers
- `ui/organizer/modules/benchManager.lua` - React to player added/moved events
- `ui/organizer/modules/slotManager.lua` - React to player moved events
- `ui/organizer/modules/cardMovement.lua` - React to player moved events
- `ui/organizer/playerCard.lua` - React to player updated events
- `ui/organizer/surveyDialog.lua` - Announce poll response event

### Service Files
- `core/organizer/survey.lua` - No changes (already calls state methods)

---

**Status**: Part 1 Complete - Ready for Part 2 (Event Definition)