# Communications Module Refactor Analysis

**Date**: November 16, 2025
**Version**: 0.6.0
**Status**: Phase 4.1 - Planning
**Risk Level**: HIGH (Critical communication paths)

## Executive Summary

The Communications module (`core/comms.lua`, 1339 lines) currently serves as both a message router AND a business logic container. This violates the pure message router pattern and creates tight coupling between communication infrastructure and domain logic.

**Goal**: Extract all business logic from Communications, leaving it as a pure message router that only handles serialization, deserialization, throttling, and message dispatch via events.

**Timeline**: 2-3 weeks (Option A: Full Extraction)
**Risk**: HIGH - touches all major communication paths

---

## Current Architecture Problems

### Problem 1: IO Data Management in Communications (Lines 136-375)

**Current State**:
```lua
function Communications:SharePlayerIOData()
    -- Business logic: Create IO package
    local ioPackage = NextKey222.PlayerIODataStructure:CreatePlayerIOPackage(playerName, false)
    
    -- Business logic: Fetch scores from multiple sources
    if NextKey222.RaiderIOAdapter and NextKey222.RaiderIOAdapter.GetDungeonScore then
        score = NextKey222.RaiderIOAdapter:GetDungeonScore(dungeonID) or 0
    elseif NextKey222.UI and NextKey222.UI.GetRaiderIODungeonScore then
        score = NextKey222.UI:GetRaiderIODungeonScore(dungeonID) or 0
    -- ... more business logic
    
    -- Business logic: Store in cache
    self.playerIOCache[playerName] = ioPackage
    
    -- THEN send message (this is the only part Communications should do)
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, channel)
end
```

**Should Be**:
```lua
-- Communications just routes the event
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if payload.opcode == "PLAYER_IO_UPDATE" then
        -- Announce event - let PlayerDataService handle it
        self:AnnounceEvent("COMM_PLAYER_IO_RECEIVED", {
            sender = sender,
            ioData = payload.ioData,
            timestamp = payload.timestamp
        })
    end
end

-- PlayerDataService handles the business logic
function PlayerDataService:OnIODataReceived(payload)
    local ioPackage = payload.ioData
    if self:ValidatePackage(ioPackage) then
        self.playerIOCache[payload.sender] = ioPackage
        self:AnnounceEvent("PLAYER_IO_UPDATED", payload)
    end
end
```

**Logic to Extract**:
- `SharePlayerIOData()` → Move to new `PlayerDataService` or `IOCalculator`
- `GetDungeonRunDetails()` → Move to `IOCalculator`
- `EnsureCurrentPlayerIOData()` → Move to `PlayerDataService`
- `playerIOCache` management → Move to `PlayerDataService`
- All IO accessor methods → Move to `PlayerDataService`

---

### Problem 2: Keystone Business Logic (Lines 927-1026)

**Current State**:
```lua
function Communications:ProcessKeystoneShare(payload, sender)
    local keyData = payload.keystoneData
    
    -- Business logic: Store keystone
    if NextKey222.Keystones and NextKey222.Keystones.StoreGuildKeystone then
        NextKey222.Keystones:StoreGuildKeystone(sender, keyData.dungeonID, keyData.level, "guild-comm")
    end
end

function Communications:ShareKeystone(keystoneData)
    -- Business logic: Validation, payload construction
    if not IsInGuild() or not keystoneData then return false end
    
    local payload = { ... }
    
    -- This is the only part Communications should do
    local serialized = AceSerializer:Serialize(payload)
    NextKey:SendCommMessage(NextKey222.Constants.COMM_PREFIX, serialized, "GUILD")
end
```

**Should Be**:
```lua
-- Communications announces event
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if payload.opcode == "KEYSTONE_SHARE" then
        self:AnnounceEvent("COMM_KEYSTONE_RECEIVED", {
            sender = sender,
            keystoneData = payload.keystoneData,
            timestamp = payload.timestamp
        })
    end
end

-- Keystones module handles business logic
function Keystones:OnKeystoneReceived(payload)
    if self:ValidateKeystoneData(payload.keystoneData) then
        self:StoreGuildKeystone(payload.sender, payload.keystoneData.dungeonID, payload.keystoneData.level, "guild-comm")
        self:AnnounceEvent("KEYSTONE_ADDED", payload)
    end
end
```

**Logic to Extract**:
- `ProcessKeystoneRequest()` → Move to `Keystones`
- `ProcessKeystoneShare()` → Move to `Keystones`
- `ShareKeystone()` → Move to `Keystones`
- `RequestGuildKeystones()` → Move to `Keystones`

---

### Problem 3: Direct UI Calls (Multiple Locations)

**Current State** (Lines 367-369, 536-538, 572-574):
```lua
function Communications:EnsureCurrentPlayerIOData()
    -- ... business logic ...
    
    -- PROBLEM: Direct UI call
    if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
        NextKey222.UI:OnPlayerIOUpdated(playerName, self.playerIOCache[playerName])
    end
end

function Communications:ProcessPlayerIOUpdate(payload, sender)
    self.playerIOCache[sender] = ioPackage
    
    -- PROBLEM: Direct UI call
    if NextKey222.UI and NextKey222.UI.OnPlayerIOUpdated then
        NextKey222.UI:OnPlayerIOUpdated(sender, ioPackage)
    end
end
```

**Should Be**:
```lua
-- Communications announces event (after extraction to PlayerDataService)
function PlayerDataService:OnIODataReceived(payload)
    if self:ValidatePackage(payload.ioData) then
        self.playerIOCache[payload.sender] = payload.ioData
        
        -- Announce event - UI listens
        self:AnnounceEvent("PLAYER_IO_UPDATED", {
            playerName = payload.sender,
            ioData = payload.ioData,
            timestamp = GetTime()
        })
    end
end

-- UI listens for event
function UI:Initialize()
    NextKey222.Addon:RegisterMessage("PLAYER_IO_UPDATED", function(event, payload)
        self:OnPlayerIOUpdated(payload.playerName, payload.ioData)
    end)
end
```

**All Direct UI Calls to Replace**:
- Lines 367-369: `OnPlayerIOUpdated`
- Lines 536-538: `OnPlayerIOUpdated`
- Lines 572-574: `OnPartyScoresUpdated`

---

### Problem 4: Organizer Routing (Lines 1275-1337)

**Current State**:
```lua
function Communications:ProcessOrganizerPollRequest(payload, sender)
    -- Delegation to survey module
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnPollRequestReceived(payload, sender)
    end
end

function Communications:ProcessOrganizerPollResponse(payload, sender)
    -- Delegation to survey module
    if NextKey222.ParticipantSurvey then
        NextKey222.ParticipantSurvey:OnPollResponseReceived(payload, sender)
    end
    
    -- ALSO directly updates RosterBoard
    if NextKey222.RosterBoard and NextKey222.RosterBoard.activePoll then
        table.insert(NextKey222.RosterBoard.activePoll.responses, { ... })
        NextKey222.RosterBoard:UpdatePollProgress()
    end
end
```

**Should Be**:
```lua
-- Communications announces event
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if payload.opcode == "ORG_POLL_REQUEST" then
        self:AnnounceEvent("COMM_ORG_POLL_REQUEST", {
            sender = sender,
            pollData = payload.data,
            timestamp = payload.timestamp
        })
    elseif payload.opcode == "ORG_POLL_RESPONSE" then
        self:AnnounceEvent("COMM_ORG_POLL_RESPONSE", {
            sender = sender,
            responseData = payload.data,
            timestamp = payload.timestamp
        })
    end
end

-- ParticipantSurvey listens
-- RosterBoard listens
-- Both react to same event
```

**Logic to Extract**:
- Organizer poll routing should use `core/organizer/comms.lua` (already exists!)
- Communications should only announce events
- Organizer modules listen and react

---

### Problem 5: Teleport UI Knowledge (Lines 456-464)

**Current State**:
```lua
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if payload.opcode == "TELEPORT_SELECT" then
        -- Good: Uses single-source API
        if NextKey and NextKey.SetTeleportTargetKey then
            NextKey:SetTeleportTargetKey(k, {
                source = "remote_select",
                broadcast = false,
                receivedFrom = sender
            })
        end
        
        -- PROBLEM: Direct UI knowledge
        if NextKey and NextKey.ToggleTeleportWindow then
            local window = NextKey.teleportWindow and NextKey.teleportWindow.frame
            if not window or not window:IsShown() then
                NextKey:ToggleTeleportWindow()
            end
        end
    end
end
```

**Should Be**:
```lua
-- Communications announces event
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if payload.opcode == "TELEPORT_SELECT" then
        self:AnnounceEvent("COMM_TELEPORT_SELECT", {
            sender = sender,
            key = payload.key,
            timestamp = payload.timestamp
        })
    end
end

-- Keystones module handles teleport target
function Keystones:OnTeleportSelectReceived(payload)
    if self:ValidateKey(payload.key) then
        NextKey:SetTeleportTargetKey(payload.key, {
            source = "remote_select",
            broadcast = false,
            receivedFrom = payload.sender
        })
        
        -- Announce event for UI
        self:AnnounceEvent("TELEPORT_TARGET_CHANGED", {
            key = payload.key,
            source = "remote_select"
        })
    end
end

-- UI listens and shows window
function UI:Initialize()
    NextKey222.Addon:RegisterMessage("TELEPORT_TARGET_CHANGED", function(event, payload)
        if payload.source == "remote_select" then
            self:ShowTeleportWindow()
        end
    end)
end
```

---

## Extraction Plan

### Phase 1: Create New Service Modules (Week 1)

#### 1.1: Create PlayerDataService

**File**: `core/playerDataService.lua`

**Responsibilities**:
- Manage `playerIOCache`
- Create and validate IO packages
- Handle IO data sharing logic
- Announce `PLAYER_IO_UPDATED` events

**Methods**:
```lua
PlayerDataService:CreateIOPackage(playerName)
PlayerDataService:GetPlayerIOData(playerName)
PlayerDataService:GetPlayerTotalIO(playerName)
PlayerDataService:GetPlayerDungeonScore(playerName, dungeonID)
PlayerDataService:HasIODataForPlayer(playerName)
PlayerDataService:SharePlayerIOData()
PlayerDataService:OnIODataReceived(payload)
PlayerDataService:CleanupOldCacheEntries()
PlayerDataService:ValidateCachedData()
```

**Events Announced**:
- `PLAYER_IO_UPDATED` - When player IO data changes
- `PLAYER_IO_CACHE_CLEANED` - After cache cleanup

#### 1.2: Update Keystones Module

**File**: `core/keystones.lua`

**Add Methods**:
```lua
Keystones:ShareKeystone(keystoneData)
Keystones:OnKeystoneReceived(payload)
Keystones:RequestGuildKeystones()
Keystones:OnKeystoneRequestReceived(payload)
```

**Events to Add**:
- `KEYSTONE_SHARED` - When keystone shared to guild
- `KEYSTONE_RECEIVED` - When keystone received from guild
- `GUILD_KEYSTONE_SCAN_COMPLETE` - After guild scan

#### 1.3: Update Organizer Comms

**File**: `core/organizer/comms.lua`

**Add Event Listeners**:
- Listen for `COMM_ORG_POLL_REQUEST`
- Listen for `COMM_ORG_POLL_RESPONSE`
- Handle routing to ParticipantSurvey and RosterBoard

---

### Phase 2: Implement Event System in Communications (Week 1-2)

#### 2.1: Add Event Announcement Helper

```lua
function Communications:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            NextKey222.Debug:Dev("comms", "Cannot announce event - AceEvent not ready")
            return
        end
        
        NextKey222.Debug:Dev("comms", string.format("Announcing event: %s", eventName))
        NextKey222.Addon:SendMessage(eventName, payload)
    end, "Communications:AnnounceEvent")
end
```

#### 2.2: Define All Communication Events

**File**: `core/constants.lua` (add to COMM section)

```lua
COMM_EVENTS = {
    -- Player IO Events
    PLAYER_IO_RECEIVED = "COMM_PLAYER_IO_RECEIVED",
    PLAYER_IO_REQUEST = "COMM_PLAYER_IO_REQUEST",
    
    -- Keystone Events
    KEYSTONE_RECEIVED = "COMM_KEYSTONE_RECEIVED",
    KEYSTONE_REQUEST = "COMM_KEYSTONE_REQUEST",
    
    -- Teleport Events
    TELEPORT_SELECT = "COMM_TELEPORT_SELECT",
    
    -- Organizer Events
    ORG_POLL_REQUEST = "COMM_ORG_POLL_REQUEST",
    ORG_POLL_RESPONSE = "COMM_ORG_POLL_RESPONSE",
    ORG_ADDON_PING = "COMM_ORG_ADDON_PING",
    ORG_ADDON_PONG = "COMM_ORG_ADDON_PONG",
    ORG_DATA = "COMM_ORG_DATA",
    ORG_DATA_REQUEST = "COMM_ORG_DATA_REQUEST",
    
    -- Preference Events
    PREFERENCE_UPDATE = "COMM_PREFERENCE_UPDATE",
    
    -- Legacy Events
    DUNGEON_SCORES = "COMM_DUNGEON_SCORES",
    SYNC = "COMM_SYNC"
}
```

#### 2.3: Refactor ProcessMessage to Pure Routing

**Before** (current - 90 lines of routing + business logic):
```lua
function Communications:ProcessMessage(prefix, message, distribution, sender)
    -- Parsing and validation (KEEP)
    -- Opcode routing with business logic (REFACTOR)
    -- Direct module calls (REMOVE)
end
```

**After** (pure routing - ~50 lines):
```lua
function Communications:ProcessMessage(prefix, message, distribution, sender)
    if prefix ~= NextKey222.Constants.COMM_PREFIX then return end
    if sender == NextKey.playerFullName then return end
    
    local payload = self:ParseSyncPayload(message)
    if not payload then
        NextKey222.Debug:Dev("comms", "Failed to parse message from", sender)
        return
    end
    
    -- Pure event announcement based on opcode
    local eventMap = {
        ["PLAYER_IO_UPDATE"] = "COMM_PLAYER_IO_RECEIVED",
        ["REQUEST_PLAYER_IO"] = "COMM_PLAYER_IO_REQUEST",
        ["KEYSTONE_SHARE"] = "COMM_KEYSTONE_RECEIVED",
        ["KEYSTONE_REQUEST"] = "COMM_KEYSTONE_REQUEST",
        ["TELEPORT_SELECT"] = "COMM_TELEPORT_SELECT",
        ["ORG_POLL_REQUEST"] = "COMM_ORG_POLL_REQUEST",
        ["ORG_POLL_RESPONSE"] = "COMM_ORG_POLL_RESPONSE",
        -- ... etc
    }
    
    local eventName = eventMap[payload.opcode]
    if eventName then
        self:AnnounceEvent(eventName, {
            sender = sender,
            data = payload.data or payload,
            timestamp = payload.timestamp,
            version = payload.version
        })
    else
        NextKey222.Debug:Dev("comms", "Unknown opcode:", payload.opcode, "from", sender)
    end
end
```

---

### Phase 3: Wire Event Listeners (Week 2)

#### 3.1: PlayerDataService Listeners

```lua
function PlayerDataService:Initialize()
    -- Listen for communication events
    NextKey222.Addon:RegisterMessage("COMM_PLAYER_IO_RECEIVED", function(event, payload)
        self:OnIODataReceived(payload)
    end)
    
    NextKey222.Addon:RegisterMessage("COMM_PLAYER_IO_REQUEST", function(event, payload)
        self:SharePlayerIOData()
    end)
    
    return true
end
```

#### 3.2: Keystones Listeners

```lua
function Keystones:Initialize()
    -- Listen for communication events
    NextKey222.Addon:RegisterMessage("COMM_KEYSTONE_RECEIVED", function(event, payload)
        self:OnKeystoneReceived(payload)
    end)
    
    NextKey222.Addon:RegisterMessage("COMM_KEYSTONE_REQUEST", function(event, payload)
        self:ShareKeystone()
    end)
    
    NextKey222.Addon:RegisterMessage("COMM_TELEPORT_SELECT", function(event, payload)
        self:OnTeleportSelectReceived(payload)
    end)
    
    return true
end
```

#### 3.3: UI Listeners

```lua
function UI:Initialize()
    -- Listen for data update events
    NextKey222.Addon:RegisterMessage("PLAYER_IO_UPDATED", function(event, payload)
        self:OnPlayerIOUpdated(payload.playerName, payload.ioData)
    end)
    
    NextKey222.Addon:RegisterMessage("TELEPORT_TARGET_CHANGED", function(event, payload)
        if payload.source == "remote_select" then
            self:ShowTeleportWindow()
        end
    end)
    
    return true
end
```

---

### Phase 4: Remove Business Logic from Communications (Week 2-3)

#### 4.1: Methods to Remove

**Delete Entirely** (moved to other modules):
- `SharePlayerIOData()` → PlayerDataService
- `GetDungeonRunDetails()` → IOCalculator
- `EnsureCurrentPlayerIOData()` → PlayerDataService
- `ProcessPlayerIOUpdate()` → Event announcement
- `ProcessPlayerIORequest()` → Event announcement
- `ShareKeystone()` → Keystones
- `ProcessKeystoneRequest()` → Event announcement
- `ProcessKeystoneShare()` → Event announcement
- `RequestGuildKeystones()` → Keystones
- All organizer process methods → Event announcements

**Keep** (core communication infrastructure):
- `SerializeSyncPayload()`
- `ParseSyncPayload()`
- `ProcessMessage()` (refactored to pure routing)
- `CanSendMessage()` (throttling)
- Batching system
- Frame pacing system
- Performance optimization helpers

#### 4.2: Storage to Remove

**Delete**:
- `playerIOCache` → Move to PlayerDataService
- `partyDungeonScores` → Move to PlayerDataService
- All cache management → PlayerDataService

**Keep**:
- `throttleTimers`
- `messageQueue`
- `batchQueue`
- `workQueue`

---

## Event Definitions

### COMM_PLAYER_IO_RECEIVED
```lua
{
    sender = "PlayerName-Realm",
    data = {
        ioData = { ... },  -- IO package structure
        timestamp = 12345
    },
    timestamp = 12345,
    version = "0.6.0"
}
```

### COMM_KEYSTONE_RECEIVED
```lua
{
    sender = "PlayerName-Realm",
    data = {
        keystoneData = {
            dungeonID = 399,
            level = 15,
            source = "nextkey"
        }
    },
    timestamp = 12345,
    version = "0.6.0"
}
```

### COMM_TELEPORT_SELECT
```lua
{
    sender = "PlayerName-Realm",
    data = {
        key = {
            dungeonID = 399,
            level = 15,
            ownerName = "PlayerName-Realm",
            ownerShort = "PlayerName",
            class = "WARRIOR",
            io = 2500,
            source = "leader_select"
        }
    },
    timestamp = 12345,
    version = "0.6.0"
}
```

---

## Migration Strategy

### Step 1: Create New Modules (No Breaking Changes)
- Add `core/playerDataService.lua`
- Update `NextKey.toc` with new file
- Register new module
- Test: Addon loads, new module initializes

### Step 2: Implement Events (Parallel to Existing)
- Add event announcement to Communications
- Add event listeners to new modules
- Keep existing direct calls working
- Test: Both paths work (events + direct calls)

### Step 3: Migrate Callers Incrementally
- Update one caller at a time to use new service
- Remove corresponding code from Communications
- Test after each migration
- Document which paths use new vs old

### Step 4: Remove Old Code
- After all callers migrated
- Remove business logic from Communications
- Communications becomes pure router
- Final testing pass

---

## Testing Strategy

### Unit Tests (Per Module)
- PlayerDataService: IO package creation, caching, validation
- Keystones: Keystone sharing, storage, events
- Communications: Message routing, event announcement

### Integration Tests
- Full communication flow: send → route → announce → listen → handle
- Backward compatibility: old clients talk to new clients
- Performance: ensure no regression

### In-Game Tests
- `/nk test` - Fake player generation
- Party sync test
- Guild keystone scan
- Organizer poll flow
- Teleport sync across 5-man and raid

---

## Rollback Plan

If refactor fails:
1. Revert to backup branch
2. Document failure points
3. Analyze root cause
4. Redesign problematic areas
5. Try incremental approach instead

---

## Success Criteria

### Code Quality
- [ ] Communications module < 500 lines (from 1339)
- [ ] No business logic in Communications
- [ ] All UI calls via events
- [ ] Clean separation: routing vs. domain logic

### Functionality
- [ ] All communication paths work
- [ ] No message loss
- [ ] Performance unchanged or improved
- [ ] Memory usage unchanged

### Architecture
- [ ] Pure message router pattern achieved
- [ ] Event-driven communication established
- [ ] Module dependencies clean (one-way)
- [ ] Easy to add new message types

---

## Timeline

**Week 1**:
- Day 1-2: Create PlayerDataService
- Day 3-4: Update Keystones module
- Day 5: Create events and announcement system

**Week 2**:
- Day 1-2: Refactor ProcessMessage to pure routing
- Day 3-4: Wire event listeners in all modules
- Day 5: Begin removing business logic

**Week 3**:
- Day 1-3: Complete business logic removal
- Day 4-5: Testing and bug fixes

---

## Next Steps

1. Create `core/playerDataService.lua`
2. Add to `NextKey.toc`
3. Implement basic structure with event system
4. Test that it loads and initializes
5. Begin migration one method at a time

---

**Status**: Ready to begin implementation
**Approval**: Awaiting confirmation to proceed