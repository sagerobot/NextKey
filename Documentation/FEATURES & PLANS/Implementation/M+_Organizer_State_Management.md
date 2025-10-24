# M+ Group Organizer - State Management

**Version:** 1.0  
**Status:** Reference Document  
**Priority:** CRITICAL - Cross-cutting concern

---

## Overview

This document defines state management strategies for the Organizer feature, covering persistence, synchronization, error recovery, and state transitions across all phases.

---

## 1. State Types

### 1.1 Persistent State (SavedVariables)

**Location:** `NextKeyDB.profile.organizer`

```lua
NextKeyDB.profile.organizer = {
    -- Last session state
    lastSession = {
        timestamp = 1729742400,
        groups = {...}, -- Serialized group data
        bench = {...},
        optOut = {...}
    },
    
    -- User preferences
    defaultOptimizerMode = "mode2",
    partialGroupStrategy = "maximize_full",
    requireLust = false,
    requireBrez = false,
    likeBonus = 1,
    dislikePenalty = 25
}
```

### 1.2 Session State (Runtime)

```lua
RosterBoard.sessionState = {
    groups = {}, -- Current group compositions
    bench = {}, -- Players on bench
    optOut = {}, -- Opted-out players
    activePoll = nil, -- Current poll data
    organizerID = "PlayerName-Realm",
    lastModified = GetTime(),
    isDirty = false -- Unsaved changes flag
}
```

### 1.3 Synchronization State

```lua
RosterBoard.syncState = {
    lastBroadcast = GetTime(),
    pendingUpdates = {}, -- Queued delta updates
    participantStates = {}, -- Tracking participant view states
    desyncDetected = false
}
```

---

## 2. State Persistence

### 2.1 Auto-Save Strategy

```lua
function RosterBoard:EnableAutoSave()
    self.autoSaveTimer = C_Timer.NewTicker(30, function()
        if self.sessionState.isDirty then
            self:SaveState()
        end
    end)
end

function RosterBoard:SaveState()
    NextKey222.Config.db.profile.organizer.lastSession = {
        timestamp = GetTime(),
        groups = self:SerializeGroups(),
        bench = self:SerializeBench(),
        optOut = self:SerializeOptOut()
    }
    
    self.sessionState.isDirty = false
    Debug:Dev("state", "Saved organizer state")
end

function RosterBoard:MarkDirty()
    self.sessionState.isDirty = true
    self.sessionState.lastModified = GetTime()
end
```

### 2.2 State Recovery on /reload

```lua
function RosterBoard:RestoreLastSession()
    local lastSession = NextKey222.Config.db.profile.organizer.lastSession
    
    if not lastSession then return false end
    
    -- Check if session is recent (< 5 minutes old)
    local age = GetTime() - lastSession.timestamp
    if age > 300 then
        return false -- Too old
    end
    
    -- Restore groups
    self:DeserializeGroups(lastSession.groups)
    self:DeserializeBench(lastSession.bench)
    self:DeserializeOptOut(lastSession.optOut)
    
    Debug:User("Restored previous organizer session")
    return true
end
```

---

## 3. State Synchronization

### 3.1 Broadcast Strategy

**Full State Broadcast:**
- On participant first opening Roster Board
- On desync detection
- On organizer promotion (new leader)

**Delta Updates:**
- Card moved
- Keystone designated
- Player added/removed

### 3.2 Conflict Resolution

```lua
function RosterBoard:OnStateConflict(incomingState, currentState)
    -- Organizer state always wins
    if self:IsOrganizer() then
        -- Re-broadcast our state
        self:BroadcastFullState()
        return
    end
    
    -- Participant: accept organizer's state
    self:ApplyFullRosterState(incomingState)
end
```

---

## 4. State Transitions

### 4.1 Lifecycle States

```
[CLOSED] → [OPENING] → [READY] → [POLLING] → [BUILDING] → [OPTIMIZING] → [COMPLETE] → [CLOSED]
```

**State Handlers:**
```lua
RosterBoard.stateHandlers = {
    OPENING = function() self:LoadCharacterData() end,
    READY = function() self:EnablePollButton() end,
    POLLING = function() self:DisablePollButton() end,
    BUILDING = function() self:EnableDragDrop() end,
    OPTIMIZING = function() self:DisableDragDrop() end,
    COMPLETE = function() self:EnableAnnounce() end
}
```

---

## 5. Error Recovery

### 5.1 Desync Recovery

```lua
function RosterBoard:ValidateStateConsistency()
    local errors = {}
    
    -- Check for duplicate players
    local seen = {}
    for loc, players in pairs({
        groups = self:GetAllGroupedPlayers(),
        bench = self.benchColumn.playerCards,
        optOut = self.optOutSection.playerCards
    }) do
        for _, card in ipairs(players) do
            if seen[card.playerData.id] then
                table.insert(errors, "Duplicate: " .. card.playerData.id)
            end
            seen[card.playerData.id] = true
        end
    end
    
    if #errors > 0 then
        self:RequestFullResync()
    end
end
```

### 5.2 Crash Recovery

```lua
function RosterBoard:OnUnexpectedClose()
    -- Save emergency backup
    self:SaveState()
    
    -- Notify participants
    NextKey222.Communications:SendOrganizerMessage(
        "ORGANIZER_DISCONNECTED",
        {},
        "RAID"
    )
end
```

---

## 6. Implementation Checklist

- [ ] Implement SavedVariables schema
- [ ] Add auto-save timer
- [ ] Build state serialization/deserialization
- [ ] Implement session recovery
- [ ] Add full state broadcast system
- [ ] Implement delta update system
- [ ] Add conflict resolution
- [ ] Build desync detection
- [ ] Implement error recovery
- [ ] Add state transition handlers
- [ ] Write state validation tests

---

**Document Status:** Complete  
**Ready for Reference:** Yes