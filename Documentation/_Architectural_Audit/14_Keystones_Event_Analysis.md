# Keystones Module Event-Driven Architecture Analysis

**Date**: November 17, 2025  
**Version**: 0.6.0  
**Status**: Phase 4.2 - Analysis Complete  
**Purpose**: Define event-driven architecture for Keystones module following OrganizerState pattern

---

## Executive Summary

The Keystones module (`core/keystones.lua`, 1473 lines) is a critical component that manages keystone detection, collection, and selection. Currently it uses direct API calls and UI updates. This analysis identifies all state changes that should announce events to decouple the module from its consumers.

**Key Findings**:
- 7 major state change categories identified
- 6 events defined with complete payloads
- 4 primary consumers need event listeners
- Pattern follows successful OrganizerState implementation

---

## Current Architecture

### Module Structure

```lua
-- Location: core/keystones.lua (1473 lines)
-- Registration: NextKey222.Keystones (line 5)
-- Global methods: NextKey:ScanPlayerKeystone(), NextKey:CollectPartyKeys()
```

### Key Responsibilities

1. **Player Keystone Detection** (lines 250-390)
   - Scans player's bags via Blizzard API
   - Integrates with LibOpenRaid
   - Fallback to manual bag scanning
   
2. **Party Keystone Collection** (lines 451-789)
   - Collects from all party members
   - Integrates LibOpenRaid data
   - Manages guild keystones
   - Handles fake players (debug mode)
   
3. **Guild Keystone Management** (lines 392-446)
   - Stores guild member keystones
   - Requests keystones via communications
   - Cleans up stale data (5-minute TTL)
   
4. **Teleport Target Selection** (lines 1093-1183)
   - Manages selected keystone for teleport
   - Broadcasts selection to party (leader-only)
   - Updates UI on selection changes

5. **Keystone Filtering** (lines 791-995)
   - Applies party/guild filters
   - Deduplicates keystones
   - Adds "No Keystone" placeholders

### Current State Mutations

| Method | Lines | State Change | Current Behavior |
|--------|-------|--------------|------------------|
| `ScanPlayerKeystone()` | 250-390 | Player keystone detected/changed | Direct assignment to `self.playerKeystone` |
| `StoreGuildKeystone()` | 396-410 | Guild keystone added | Direct update to `guildKeystones` cache |
| `CollectPartyKeys()` | 451-789 | Party keystones collected | Updates `self.cachedKeys`, calls `UI:RefreshResults()` |
| `SetTeleportTargetKey()` | 1114-1159 | Teleport target selected | Updates `self.teleportTargetKey`, calls `UI:RenderResults()` |
| `StoreGuildKeystone()` | 396-410 | Guild keystone stored | Updates `guildKeystones` table, prints to chat |

### Current Consumer Integration Points

**UI Consumers** (Direct Calls):
- `NextKey222.UI:RefreshResults()` (line 651) - After fake players added
- `NextKey222.UI:RenderResults()` (line 1157) - After teleport target set
- `self:RefreshTeleportWindow()` (line 1151) - After teleport target set

**Communications Integration**:
- `NextKey222.Communications:BroadcastTeleportSelection()` (line 1143) - Leader broadcast

**Organizer Integration**:
- No direct calls (organizer queries keystones via `GetAvailableKeys()`)

---

## State Change Analysis

### 1. Player Keystone Detection

**When**: Player's owned keystone is detected or changed  
**Current Code**: `NextKey:ScanPlayerKeystone()` (lines 250-390)  
**State Mutation**: Sets `self.playerKeystone` (line 530)

**Triggers**:
- Addon initialization (boot sequence)
- `CHALLENGE_MODE_KEYSTONE_SLOTTED` event
- Manual `/reload` or bag changes
- Party joins/leaves

**Data Available**:
```lua
{
    dungeonID = number,    -- Challenge mode map ID
    level = number,        -- Keystone level
    ownerName = string,    -- Full player name with realm
    ownerShort = string,   -- Short player name
    class = string,        -- Player class token
    source = string,       -- "blizzard-api", "player", etc.
    timestamp = number     -- GetTime()
}
```

### 2. Player Keystone Removed

**When**: Player no longer has a keystone  
**Current Code**: `self.playerKeystone = nil` (line 533)  
**State Mutation**: Clears player keystone reference

**Triggers**:
- Keystone used in dungeon
- Keystone deleted
- Scan returns nil

**Data Available**:
```lua
{
    previousDungeonID = number,  -- Last known dungeon
    previousLevel = number,      -- Last known level
    timestamp = number
}
```

### 3. Party Keystones Scan Complete

**When**: Full party keystone collection completes  
**Current Code**: `NextKey:CollectPartyKeys()` (lines 451-789)  
**State Mutation**: Updates `self.cachedKeys` (line 787)

**Triggers**:
- `GROUP_ROSTER_UPDATE` event
- UI refresh requests
- Manual keystone scan
- LibOpenRaid data received

**Data Available**:
```lua
{
    keystones = table,           -- Array of keystone entries
    playerCount = number,        -- Total players scanned
    keystoneCount = number,      -- Keystones with dungeonID > 0
    sources = table,             -- Count by source (blizzard, libopenraid, etc.)
    timestamp = number
}
```

### 4. Guild Keystone Received

**When**: Guild member's keystone is received via communication  
**Current Code**: `NextKey:StoreGuildKeystone()` (lines 396-410)  
**State Mutation**: Updates `guildKeystones` table (line 400)

**Triggers**:
- `KEYSTONE_SHARE` communication message
- LibOpenRaid guild data
- Manual guild scan request

**Data Available**:
```lua
{
    playerName = string,       -- Full player name
    playerShort = string,      -- Short player name
    dungeonID = number,
    level = number,
    source = string,           -- "guild-comm", "libopenraid-direct"
    timestamp = number
}
```

### 5. Teleport Target Selected

**When**: Leader selects a keystone for group teleport  
**Current Code**: `NextKey:SetTeleportTargetKey()` (lines 1114-1159)  
**State Mutation**: Updates `self.teleportTargetKey` (line 1119)

**Triggers**:
- User clicks keystone card
- Remote leader selection (TELEPORT_SELECT message)
- PUG Helper auto-selection
- Dungeon card teleport click

**Data Available**:
```lua
{
    dungeonID = number,
    level = number,
    ownerName = string,
    ownerShort = string,
    class = string,
    io = number,
    source = string,           -- "user_select", "remote_select", "pug_auto"
    receivedFrom = string,     -- Player name if remote
    broadcast = boolean,       -- Whether to broadcast to party
    timestamp = number
}
```

### 6. Teleport Target Cleared

**When**: Teleport target is deselected  
**Current Code**: `self.teleportTargetKey = nil` (line 1136)  
**State Mutation**: Clears teleport target

**Triggers**:
- User deselects keystone
- Dungeon completion
- Manual clear

**Data Available**:
```lua
{
    previousDungeonID = number,
    previousLevel = number,
    timestamp = number
}
```

---

## Event Definitions

Following the OrganizerState event pattern, we define 6 events with complete payloads:

### Event 1: KEYSTONE_PLAYER_DETECTED

**Purpose**: Announce when the current player's keystone is detected or changed  
**When Fired**: After `ScanPlayerKeystone()` successfully detects a keystone  
**Payload Structure**:

```lua
{
    playerName = string,       -- Full player name with realm
    playerShort = string,      -- Short player name
    dungeonID = number,        -- Challenge mode map ID
    level = number,            -- Keystone level
    class = string,            -- Player class token
    source = string,           -- "blizzard-api", "blizzard", "player"
    dungeonName = string,      -- Human-readable dungeon name
    previous = {               -- Previous keystone (if changed)
        dungeonID = number,
        level = number
    },
    timestamp = number         -- GetTime()
}
```

**Who Listens**:
- Main UI (update keystone list)
- Teleport window (auto-select player's key)
- Communications (share with party if enabled)

### Event 2: KEYSTONE_PLAYER_REMOVED

**Purpose**: Announce when the current player no longer has a keystone  
**When Fired**: After `ScanPlayerKeystone()` returns nil  
**Payload Structure**:

```lua
{
    playerName = string,
    previous = {
        dungeonID = number,
        level = number
    },
    timestamp = number
}
```

**Who Listens**:
- Main UI (remove player keystone from list)
- Teleport window (clear auto-selection)

### Event 3: KEYSTONE_SCAN_COMPLETE

**Purpose**: Announce when party keystone collection completes  
**When Fired**: After `CollectPartyKeys()` completes  
**Payload Structure**:

```lua
{
    keystones = table,         -- Array of all collected keystones
    playerCount = number,      -- Total players scanned
    keystoneCount = number,    -- Count with valid dungeonID
    sources = {                -- Source breakdown
        blizzard = number,
        libopenraid = number,
        rio = number,
        debug = number,
        total = number
    },
    scanType = string,         -- "party", "guild", "manual"
    timestamp = number
}
```

**Who Listens**:
- Main UI (refresh keystone list)
- Organizer (update available keystones)
- PUG Helper (detect group changes)

### Event 4: KEYSTONE_GUILD_RECEIVED

**Purpose**: Announce when a guild member's keystone is received  
**When Fired**: After `StoreGuildKeystone()` stores new data  
**Payload Structure**:

```lua
{
    playerName = string,
    playerShort = string,
    dungeonID = number,
    level = number,
    source = string,           -- "guild-comm", "libopenraid-direct"
    dungeonName = string,
    timestamp = number
}
```

**Who Listens**:
- Main UI (add guild keystone if in guild mode)
- Guild keystone display

### Event 5: KEYSTONE_TELEPORT_SELECTED

**Purpose**: Announce when a keystone is selected for teleport  
**When Fired**: After `SetTeleportTargetKey()` with valid key  
**Payload Structure**:

```lua
{
    dungeonID = number,
    level = number,
    ownerName = string,
    ownerShort = string,
    class = string,
    io = number,
    source = string,           -- "user_select", "remote_select", "pug_auto"
    receivedFrom = string,     -- Player name if remote selection
    broadcast = boolean,       -- Whether to broadcast to party
    dungeonName = string,
    previous = {               -- Previous selection (if any)
        dungeonID = number,
        level = number,
        ownerName = string
    },
    timestamp = number
}
```

**Who Listens**:
- Teleport window (update target display)
- Main UI (highlight selected keystone)
- Communications (broadcast if leader and broadcast=true)
- Organizer (update group keystone tracking)

### Event 6: KEYSTONE_TELEPORT_CLEARED

**Purpose**: Announce when teleport target is deselected  
**When Fired**: After `SetTeleportTargetKey()` with nil key  
**Payload Structure**:

```lua
{
    previous = {
        dungeonID = number,
        level = number,
        ownerName = string
    },
    timestamp = number
}
```

**Who Listens**:
- Teleport window (clear selection)
- Main UI (remove highlight)

---

## Implementation Plan

### Phase 1: Add Event Infrastructure (Day 1)

**Step 1.1: Add KEYSTONE_EVENTS to constants.lua**

```lua
-- Location: core/constants.lua (after COMM_EVENTS)

KEYSTONE_EVENTS = {
    PLAYER_DETECTED = "NEXTKEY_KEYSTONE_PLAYER_DETECTED",
    PLAYER_REMOVED = "NEXTKEY_KEYSTONE_PLAYER_REMOVED",
    SCAN_COMPLETE = "NEXTKEY_KEYSTONE_SCAN_COMPLETE",
    GUILD_RECEIVED = "NEXTKEY_KEYSTONE_GUILD_RECEIVED",
    TELEPORT_SELECTED = "NEXTKEY_KEYSTONE_TELEPORT_SELECTED",
    TELEPORT_CLEARED = "NEXTKEY_KEYSTONE_TELEPORT_CLEARED"
}
```

**Step 1.2: Add AnnounceEvent() helper to Keystones module**

```lua
-- Location: core/keystones.lua (after module registration)

--- Announces keystone events via AceEvent system
--- @param eventName string The event name from KEYSTONE_EVENTS
--- @param payload table The event payload data
function Keystones:AnnounceEvent(eventName, payload)
    return NextKey222.SafeRun(function()
        if not NextKey222.Addon or not NextKey222.Addon.SendMessage then
            NextKey222.Debug:Dev("keystones", "Cannot announce event - AceEvent not ready:", eventName)
            return
        end
        
        -- Ensure timestamp
        if not payload.timestamp then
            payload.timestamp = GetTime()
        end
        
        NextKey222.Debug:Dev("keystones", "Announcing event:", eventName)
        NextKey222.Addon:SendMessage(eventName, payload)
    end, "Keystones:AnnounceEvent")
end
```

### Phase 2: Update State Mutation Methods (Days 2-3)

**Step 2.1: Update ScanPlayerKeystone()**

```lua
-- Location: core/keystones.lua:250-390
-- After line 389 (before return statement)

-- Detect if keystone changed
local previousKeystone = self.playerKeystone
local keystoneChanged = false

if previousKeystone and mapID then
    keystoneChanged = (previousKeystone.dungeonID ~= mapID) or 
                      (previousKeystone.level ~= level)
elseif not previousKeystone and mapID then
    keystoneChanged = true
end

-- Store new keystone data
local newKeystone = {
    dungeonID = mapID,
    level = level or 0,
    ownerName = owner,
    ownerShort = self.playerShortName,
    class = class ~= "" and class or "EVOKER",
    source = "player",
    timestamp = GetUtils().currentTime(),
}

-- Announce PLAYER_DETECTED event if keystone detected or changed
if keystoneChanged then
    NextKey222.Keystones:AnnounceEvent(
        NextKey222.Constants.KEYSTONE_EVENTS.PLAYER_DETECTED,
        {
            playerName = owner,
            playerShort = self.playerShortName,
            dungeonID = mapID,
            level = level or 0,
            class = class,
            source = "player",
            dungeonName = self:GetDungeonName(mapID),
            previous = previousKeystone and {
                dungeonID = previousKeystone.dungeonID,
                level = previousKeystone.level
            } or nil,
            timestamp = GetUtils().currentTime()
        }
    )
end

return newKeystone
```

**Step 2.2: Handle keystone removal**

```lua
-- Location: core/keystones.lua:533 (in CollectPartyKeys)
-- Replace: self.playerKeystone = nil

-- Announce removal event if we had a keystone before
if self.playerKeystone then
    NextKey222.Keystones:AnnounceEvent(
        NextKey222.Constants.KEYSTONE_EVENTS.PLAYER_REMOVED,
        {
            playerName = self.playerFullName,
            previous = {
                dungeonID = self.playerKeystone.dungeonID,
                level = self.playerKeystone.level
            },
            timestamp = GetTime()
        }
    )
end
self.playerKeystone = nil
```

**Step 2.3: Update CollectPartyKeys()**

```lua
-- Location: core/keystones.lua:787 (before return statement)

-- Calculate source counts
local sourceCounts = {
    blizzard = 0,
    libopenraid = 0,
    rio = 0,
    debug = 0,
    total = #keys
}

for _, key in ipairs(keys) do
    local source = key.source or "unknown"
    if source == "blizzard" or source == "blizzard-api" then
        sourceCounts.blizzard = sourceCounts.blizzard + 1
    elseif source == "libopenraid" or source == "libopenraid-direct" then
        sourceCounts.libopenraid = sourceCounts.libopenraid + 1
    elseif source == "rio" then
        sourceCounts.rio = sourceCounts.rio + 1
    elseif source == "debug" then
        sourceCounts.debug = sourceCounts.debug + 1
    end
end

-- Announce scan complete event
NextKey222.Keystones:AnnounceEvent(
    NextKey222.Constants.KEYSTONE_EVENTS.SCAN_COMPLETE,
    {
        keystones = keys,
        playerCount = #keys,
        keystoneCount = sourceCounts.total,
        sources = sourceCounts,
        scanType = IsInRaid() and "raid" or (IsInGroup() and "party" or "solo"),
        timestamp = GetTime()
    }
)

self.cachedKeys = keys
return keys
```

**Step 2.4: Update StoreGuildKeystone()**

```lua
-- Location: core/keystones.lua:396-410

function NextKey:StoreGuildKeystone(playerName, dungeonID, level, source)
    if not playerName or not dungeonID or not level then return end
    
    local shortName = playerName:match("^([^%-]+)") or playerName
    guildKeystones[shortName] = {
        dungeonID = dungeonID,
        level = level,
        ownerName = playerName,
        ownerShort = shortName,
        source = source or "guild-comm",
        timestamp = GetTime()
    }
    
    -- Announce guild keystone received event
    NextKey222.Keystones:AnnounceEvent(
        NextKey222.Constants.KEYSTONE_EVENTS.GUILD_RECEIVED,
        {
            playerName = playerName,
            playerShort = shortName,
            dungeonID = dungeonID,
            level = level,
            source = source or "guild-comm",
            dungeonName = self:GetDungeonName(dungeonID),
            timestamp = GetTime()
        }
    )
    
    NextKey222.Debug:Dev("keystones", "Stored guild keystone for", shortName, "- Level", level, "dungeon", dungeonID)
end
```

**Step 2.5: Update SetTeleportTargetKey()**

```lua
-- Location: core/keystones.lua:1114-1159

function NextKey:SetTeleportTargetKey(key, opts)
    opts = opts or {}
    local same = self:IsKeySelected(key)
    local previousKey = self.teleportTargetKey

    if key and key.dungeonID then
        self.teleportTargetKey = Keystones.copyKey({
            dungeonID = key.dungeonID,
            level = key.level,
            ownerName = key.ownerName,
            ownerShort = key.ownerShort,
            class = key.class,
            io = key.io,
            source = opts.source or key.source,
            receivedFrom = opts.receivedFrom,
            timestamp = GetUtils().currentTime(),
        })
        
        -- Announce teleport selected event
        NextKey222.Keystones:AnnounceEvent(
            NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_SELECTED,
            {
                dungeonID = key.dungeonID,
                level = key.level,
                ownerName = key.ownerName,
                ownerShort = key.ownerShort,
                class = key.class,
                io = key.io,
                source = opts.source or key.source,
                receivedFrom = opts.receivedFrom,
                broadcast = opts.broadcast or false,
                dungeonName = self:GetDungeonName(key.dungeonID),
                previous = previousKey and {
                    dungeonID = previousKey.dungeonID,
                    level = previousKey.level,
                    ownerName = previousKey.ownerName
                } or nil,
                timestamp = GetUtils().currentTime()
            }
        )
        
        NextKey222.Debug:User("SetTeleportTargetKey: " .. (key.ownerName or "Unknown") .. " - " ..
                              (self:GetDungeonName(key.dungeonID) or "Unknown") ..
                              " +" .. (key.level or 0) .. " (source: " .. (key.source or "unknown") .. ")")
    else
        -- Announce teleport cleared event
        if previousKey then
            NextKey222.Keystones:AnnounceEvent(
                NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_CLEARED,
                {
                    previous = {
                        dungeonID = previousKey.dungeonID,
                        level = previousKey.level,
                        ownerName = previousKey.ownerName
                    },
                    timestamp = GetTime()
                }
            )
        end
        
        self.teleportTargetKey = nil
        NextKey222.Debug:User("SetTeleportTargetKey: Cleared teleport target")
    end

    -- When leader (or solo) chooses a key and broadcast=true, share via comms
    if opts.broadcast and self:IsLeaderOrSolo() and key and key.dungeonID and key.level then
        if NextKey222.Communications and NextKey222.Communications.BroadcastTeleportSelection then
            NextKey222.Communications:BroadcastTeleportSelection(self.teleportTargetKey)
        else
            NextKey222.Debug:Dev("keystones", "BroadcastTeleportSelection not available")
        end
    end

    -- Update teleport window (backward compatibility - will be replaced by event listener)
    if type(self.RefreshTeleportWindow) == "function" then
        self:RefreshTeleportWindow()
    end

    -- Don't trigger UI refresh for dungeon portal fake keystones
    local isDungeonPortal = key and key.source == "dungeon_portal"
    if NextKey222.UI and NextKey222.UI.RenderResults and NextKey222.UI.mainFrame and not same and not isDungeonPortal then
        NextKey222.UI:RenderResults()
    end
end
```

### Phase 3: Update UI Consumers (Day 4)

**Step 3.1: Add event listeners to Main UI**

```lua
-- Location: ui/main.lua (in Initialize method)

-- Register keystone event listeners
if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
    NextKey222.Addon:RegisterMessage(
        NextKey222.Constants.KEYSTONE_EVENTS.PLAYER_DETECTED,
        function(event, payload) self:OnKeystonePlayerDetected(payload) end
    )
    
    NextKey222.Addon:RegisterMessage(
        NextKey222.Constants.KEYSTONE_EVENTS.SCAN_COMPLETE,
        function(event, payload) self:OnKeystoneScanComplete(payload) end
    )
    
    NextKey222.Addon:RegisterMessage(
        NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_SELECTED,
        function(event, payload) self:OnKeystoneTeleportSelected(payload) end
    )
end
```

**Step 3.2: Implement event handlers in Main UI**

```lua
-- Location: ui/main.lua (new methods)

function UI:OnKeystonePlayerDetected(payload)
    NextKey222.SafeRun(function()
        if not self:IsMainFrameVisible() then return end
        
        NextKey222.Debug:Dev("ui", "Player keystone detected:", payload.dungeonName, "+", payload.level)
        
        -- Refresh keystone list
        self:RefreshResults()
    end, "UI:OnKeystonePlayerDetected")
end

function UI:OnKeystoneScanComplete(payload)
    NextKey222.SafeRun(function()
        if not self:IsMainFrameVisible() then return end
        
        NextKey222.Debug:Dev("ui", "Keystone scan complete:", payload.keystoneCount, "keystones")
        
        -- Refresh keystone list
        self:RefreshResults()
    end, "UI:OnKeystoneScanComplete")
end

function UI:OnKeystoneTeleportSelected(payload)
    NextKey222.SafeRun(function()
        if not self:IsMainFrameVisible() then return end
        
        NextKey222.Debug:Dev("ui", "Teleport selected:", payload.dungeonName, "+", payload.level)
        
        -- Highlight selected keystone
        self:RenderResults()
    end, "UI:OnKeystoneTeleportSelected")
end
```

**Step 3.3: Add event listeners to Teleport Window**

```lua
-- Location: ui/teleport.lua (in EnsureTeleportWindow or new Initialize method)

-- Register teleport event listeners
if NextKey222.Addon and NextKey222.Addon.RegisterMessage then
    NextKey222.Addon:RegisterMessage(
        NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_SELECTED,
        function(event, payload)
            -- Refresh teleport window with new target
            if addon.RefreshTeleportWindow then
                addon:RefreshTeleportWindow()
            end
        end
    )
    
    NextKey222.Addon:RegisterMessage(
        NextKey222.Constants.KEYSTONE_EVENTS.TELEPORT_CLEARED,
        function(event, payload)
            -- Refresh teleport window (clear target)
            if addon.RefreshTeleportWindow then
                addon:RefreshTeleportWindow()
            end
        end
    )
end
```

### Phase 4: Testing & Validation (Day 5)

**Test Checklist**:

- [ ] **Player Keystone Detection**:
  - [ ] Detect keystone in bags
  - [ ] Event fires with correct payload
  - [ ] UI updates automatically
  - [ ] Teleport window shows player's key
  
- [ ] **Player Keystone Removal**:
  - [ ] Remove keystone from bags
  - [ ] Event fires with previous data
  - [ ] UI removes keystone from list
  
- [ ] **Party Scan Complete**:
  - [ ] Join party/raid
  - [ ] Event fires with all keystones
  - [ ] UI refreshes with party data
  - [ ] Source counts accurate
  
- [ ] **Guild Keystone Received**:
  - [ ] Request guild keystones
  - [ ] Event fires for each guild member
  - [ ] Guild keystones appear in UI (guild mode)
  
- [ ] **Teleport Selection**:
  - [ ] Click keystone card
  - [ ] Event fires with selection
  - [ ] Teleport window updates
  - [ ] Leader broadcasts to party
  - [ ] Non-leader doesn't broadcast
  
- [ ] **Teleport Cleared**:
  - [ ] Deselect keystone
  - [ ] Event fires with previous data
  - [ ] Teleport window clears

**Debug Commands**:

```lua
-- Enable keystone event debugging
/nk config → Debug System → keystones (enable)

-- Test player keystone detection
/script NextKey:ScanPlayerKeystone()

-- Test party scan
/script NextKey:CollectPartyKeys()

-- Test teleport selection
/script NextKey:SetTeleportTargetKey({dungeonID = 503, level = 10}, {broadcast = true})
```

---

## Migration Strategy

Following the OrganizerState non-breaking migration pattern:

### Phase 1: Additive (Week 1)
- Add event infrastructure
- Implement event announcements
- **Keep all existing direct calls**
- Both paths work simultaneously

### Phase 2: Listeners (Week 1)
- Add event listeners to UI modules
- Test event flow end-to-end
- Verify no duplicate updates

### Phase 3: Event Handlers (Week 2)
- Implement full event handler logic
- Add guards to prevent circular updates
- **Keep backward compatibility**

### Phase 4: Cleanup (Week 2-3)
- Remove direct UI calls from Keystones
- Deprecate direct refresh methods
- Update documentation

---

## Success Criteria

- [ ] All 6 keystone events defined in constants
- [ ] AnnounceEvent() helper implemented
- [ ] All state mutations fire events
- [ ] UI modules listen for events
- [ ] Teleport window listens for events
- [ ] No duplicate updates
- [ ] No infinite loops
- [ ] All workflows function correctly
- [ ] Performance unchanged
- [ ] Debug category `keystones` logs all events

---

## Files to Modify

1. **core/constants.lua** - Add KEYSTONE_EVENTS (6 events)
2. **core/keystones.lua** - Add AnnounceEvent(), update 5 mutation methods
3. **ui/main.lua** - Add 3 event listeners and handlers
4. **ui/teleport.lua** - Add 2 event listeners
5. **NextKey.toc** - Verify load order (no changes needed)

---

## Estimated Effort

- **Analysis**: ✅ Complete (1 day)
- **Implementation**: 3 days
  - Day 1: Event infrastructure
  - Days 2-3: State mutation updates
  - Day 4: UI consumer updates
- **Testing**: 1 day
- **Total**: 5 days (as estimated in checklist)

---

## Risks & Mitigations

**Risk**: Infinite event loops (state → event → UI → state)  
**Mitigation**: Add guards like OrganizerState (skipStateUpdate parameter)

**Risk**: Duplicate UI updates (both events and direct calls)  
**Mitigation**: Keep both paths during migration, remove direct calls in Phase 4

**Risk**: Performance impact from event overhead  
**Mitigation**: Event announcements are lightweight, only fire on actual state changes

**Risk**: Breaking existing integrations  
**Mitigation**: Non-breaking migration - all direct calls remain functional

---

## Next Steps

1. Update task checklist (mark Step 1 complete)
2. Add KEYSTONE_EVENTS to constants.lua
3. Implement AnnounceEvent() helper
4. Update ScanPlayerKeystone() to fire events
5. Continue through implementation plan

---

## References

- OrganizerState Event System: `Documentation/_Architectural_Audit/12_OrganizerState_Event_Definitions.md`
- Communications Refactor: `Documentation/_Architectural_Audit/13_Communications_Refactor_Analysis.md`
- Module Dependencies: `Documentation/_Architectural_Audit/07_Module_Dependencies.md`
- Implementation Checklist: `Documentation/_Architectural_Audit/06_Implementation_Checklist.md` (lines 788-822)