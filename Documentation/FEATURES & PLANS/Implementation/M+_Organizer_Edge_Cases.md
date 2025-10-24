# M+ Group Organizer - Edge Cases & Error Handling

**Version:** 1.0  
**Status:** Reference Document  
**Priority:** HIGH - Robustness critical

---

## Overview

This document catalogs edge cases, error scenarios, and handling strategies across all Organizer phases. Every scenario must have a defined behavior.

---

## 1. Group Size & Roster Changes

### 1.1 Mid-Session Size Changes

**Edge Case:** Group size changes while Roster Board is open

**Scenarios:**
- **5 → 6 players:** Trigger UI fork to Roster Board
- **6 → 5 players:** Save state, switch to 5-player UI, restore if returning to 6+
- **20 → 19 → 20 players:** Handle frequent fluctuations without constant rebuilds

**Implementation:**
```lua
function RosterBoard:OnRosterSizeChange(newSize)
    if newSize <= 5 and self:IsActive() then
        self:SaveTemporaryState()
        self:Hide()
        NextKeyUI:ShowKeystoneOptimizerUI()
    elseif newSize >= 6 and not self:IsActive() then
        if self:HasRecentSavedState() then
            self:RestoreTemporaryState()
        end
        self:Show()
    end
end
```

### 1.2 Player Disconnects

**Edge Case:** Player disconnects mid-organization

**Behavior:**
- Card remains on board (grayed out)
- Auto-detected players: Remove card
- Survey respondents: Keep card with "Offline" indicator
- Optimizer: Exclude from calculations

---

## 2. Survey System Edge Cases

### 2.1 Survey Timeout

**Edge Case:** Player doesn't respond within 60 seconds

**Behavior:**
- Count as non-response
- Auto-detect if addon not detected
- Allow manual re-poll for specific player

### 2.2 Alt Character Data Stale

**Edge Case:** Alt selected but data is weeks old

**Behavior:**
- Display "Data may be outdated" warning
- Use cached data anyway
- Provide manual refresh option

### 2.3 Character Not in Storage

**Edge Case:** Player selects alt not in local storage

**Behavior:**
- Accept alt data from survey response
- Store temporarily
- Add to character storage for future

### 2.4 Duplicate Survey Responses

**Edge Case:** Player submits survey twice

**Behavior:**
- Keep latest response
- Overwrite previous card
- Don't create duplicates

### 2.5 Role Configuration Missing

**Edge Case:** Player has no roles configured in Options

**Behavior:**
- Auto-derive from current spec
- Show tutorial tooltip about role configuration
- Allow survey submission with derived roles

---

## 3. Drag-and-Drop Edge Cases

### 3.1 Card Dropped on Invalid Target

**Edge Case:** Tank card dropped on Healer slot

**Behavior:**
- Card returns to source (spring-back animation)
- Show error message: "Cannot place Tank in Healer slot"
- Highlight valid drop targets

### 3.2 Rapid Drag Operations

**Edge Case:** User drags multiple cards very quickly

**Behavior:**
- Queue operations
- Process sequentially
- Prevent race conditions

### 3.3 Drag During Network Lag

**Edge Case:** Drag initiated but sync message delayed

**Behavior:**
- Complete drag locally immediately
- Queue sync message
- Handle out-of-order updates on participants

### 3.4 Card Swapping

**Edge Case:** Drag Tank to occupied Tank slot

**Behavior:**
- Swap positions
- Validate both players can fill swapped roles
- If invalid, cancel swap

---

## 4. Keystone Designation Edge Cases

### 4.1 No Keystones in Group

**Edge Case:** All 5 players have no keystones

**Behavior:**
- Allow group formation
- Show warning: "No keystone designated"
- Allow manual keystone entry (future feature)

### 4.2 Keystone Depleted Mid-Organization

**Edge Case:** Player runs their key while on Roster Board

**Behavior:**
- Mark keystone as depleted
- Update card visual
- Optimizer excludes depleted keys

### 4.3 Server Reset During Organization

**Edge Case:** Tuesday reset clears all keystones

**Behavior:**
- Detect reset event
- Clear all keystone data
- Show notification: "Server reset detected, keystones cleared"
- Allow continuation without keystones

### 4.4 Multiple Keystone Designation Clicks

**Edge Case:** User rapidly clicks star icons

**Behavior:**
- Debounce clicks (200ms)
- Toggle designation on/off
- Sync final state only

---

## 5. Optimizer Edge Cases

### 5.1 No Valid Groups Possible

**Edge Case:** 7 players, all DPS

**Behavior:**
- Optimizer completes with 0 groups
- All players remain on bench
- Show message: "Cannot form valid groups (no Tank/Healer)"

### 5.2 All Players Dislike All Keys

**Edge Case:** Every player has -1 for every dungeon

**Behavior:**
- Optimizer forms groups anyway (negative scores acceptable)
- Mode 3 (Vault) may fail to form groups
- Show warning about low happiness

### 5.3 Optimizer Hangs

**Edge Case:** Mode 1 with 20 players exceeds performance limits

**Behavior:**
- Wizard allows pause/cancel
- Show progress: "Evaluated X/Y combinations"
- Timeout after 2 minutes
- Partial results accepted

### 5.4 Partial Groups with No PUG Options

**Edge Case:** 7 players, "Maximize Full Groups", no PUG allowed

**Behavior:**
- Form 1 full group
- Place 2 remaining players on bench
- Show: "2 players could not be placed"

### 5.5 Optimizer Crash

**Edge Case:** Lua error during optimization

**Behavior:**
- Catch error with SafeRun()
- Log error details
- Revert to manual mode
- Preserve pre-optimization state

---

## 6. Communication Edge Cases

### 6.1 Organizer Disconnects

**Edge Case:** Leader crashes/disconnects during organization

**Behavior:**
- Participants see "Organizer disconnected" message
- Roster Board becomes read-only (already was)
- New leader promoted: Offer to take over organization

### 6.2 Participant Joins Mid-Organization

**Edge Case:** New player joins raid after poll sent

**Behavior:**
- Send individual poll to new player
- Auto-add to bench when they respond
- Or auto-detect if no addon

### 6.3 Mixed Addon Versions

**Edge Case:** Some members have v0.2.1, others v0.3.0

**Behavior:**
- v0.3.0 organizer: Auto-detect v0.2.1 users as non-addon
- v0.2.1 leader: Cannot use Organizer (no 6+ UI)
- Show version mismatch warning

### 6.4 Message Spam

**Edge Case:** Rapid state changes = excessive sync messages

**Behavior:**
- Batch updates every 500ms
- Drop duplicate updates
- Throttle per-player messages

### 6.5 Cross-Realm Communication Failure

**Edge Case:** Addon message fails to cross realm

**Behavior:**
- Retry up to 3 times
- Fallback to whisper
- Mark player as "Communication issues"

---

## 7. Data Integrity Edge Cases

### 7.1 Duplicate Players

**Edge Case:** Same player appears in 2 locations

**Behavior:**
- Desync detected
- Request full state resync
- Organizer state wins

### 7.2 Ghost Players

**Edge Case:** Player left raid but card remains

**Behavior:**
- Periodic roster validation
- Remove cards for players not in raid
- Allow undo if accidental

### 7.3 Score Data Mismatch

**Edge Case:** RaiderIO shows different score than Blizzard API

**Behavior:**
- Prefer RaiderIO (more accurate)
- Show warning if large discrepancy (>500 IO)
- Allow manual override

### 7.4 Character Storage Corruption

**Edge Case:** SavedVariables corrupted

**Behavior:**
- Detect on load (schema validation)
- Reset to defaults
- Notify user: "Character data reset"

---

## 8. UI Edge Cases

### 8.1 Tiny Window Size

**Edge Case:** User resizes window very small

**Behavior:**
- Minimum width: 800px
- Minimum height: 600px
- Enforce via Ace3 constraints

### 8.2 Ultra-Wide Monitor

**Edge Case:** 3440x1440 resolution

**Behavior:**
- Dynamically add more group columns
- Max 8 groups visible
- Responsive layout adapts

### 8.3 Component Pooling Exhaustion

**Edge Case:** 40+ players in raid

**Behavior:**
- Expand pool dynamically
- Show warning: "Large raid detected, performance may vary"
- Limit to first 40 players

### 8.4 Missing Textures/Icons

**Edge Case:** Class icon file not found

**Behavior:**
- Use fallback colored square
- Log missing texture
- Continue rendering

---

## 9. Performance Edge Cases

### 9.1 Low FPS Environment

**Edge Case:** User has 15 FPS

**Behavior:**
- Disable drag-and-drop animations
- Reduce update frequency
- Stagger rendering more aggressively

### 9.2 High Latency

**Edge Case:** 500ms+ latency

**Behavior:**
- Increase sync batch interval to 1 second
- Show "High latency detected" warning
- Disable real-time participant view

### 9.3 Memory Pressure

**Edge Case:** AddOn memory exceeds 100MB

**Behavior:**
- Trigger aggressive component pooling
- Clear unused caches
- Show memory warning

---

## 10. Announcement Edge Cases

### 10.1 Chat Throttling

**Edge Case:** WoW rate-limits chat messages

**Behavior:**
- Split long messages into chunks
- Delay between chunks (1 second)
- Show progress: "Sending 2/3..."

### 10.2 Player Not in Guild

**Edge Case:** "Announce to Guild" but player not in guild

**Behavior:**
- Gray out Guild checkbox
- Show tooltip: "You are not in a guild"

### 10.3 Empty Groups

**Edge Case:** User tries to announce with no groups formed

**Behavior:**
- Disable "Announce" button
- Show tooltip: "No groups to announce"

---

## 11. Testing Strategy for Edge Cases

### 11.1 Test Matrix

```
Dimensions to test:
- Group sizes: 5, 6, 10, 15, 20, 25, 40
- Addon coverage: 100%, 50%, 0%
- Network conditions: Good, Medium, Poor
- Player actions: Sequential, Rapid, Random
- Data states: Fresh, Stale, Missing
```

### 11.2 Stress Tests

```lua
function StressTestOrganizer()
    -- 40 fake players
    -- Rapid drag operations (10/sec)
    -- Network delays (random 0-500ms)
    -- Mixed addon versions
    -- Run for 5 minutes
end
```

### 11.3 Chaos Testing

```lua
function ChaosTestOrganizer()
    -- Random player joins/leaves
    -- Random disconnects
    -- Corrupted messages
    -- Conflicting state updates
    -- Memory pressure simulation
end
```

---

## 12. Error Message Standards

### 12.1 User-Facing Errors

**Format:** `"[Action] failed: [Reason]. [Recovery suggestion]"`

**Examples:**
- "Poll failed: No raid members detected. Please ensure you are in a group."
- "Cannot form group: Missing tank. Please add a tank to continue."
- "Optimizer timed out: Too many combinations. Try reducing player count or using Manual Mode."

### 12.2 Debug Errors

**Format:** `"[Module:Function] Error: [Technical details]"`

**Examples:**
- "RosterBoard:ApplyDrop Error: Invalid target type 'unknown'"
- "OptimizerMode1:GenerateCombinations Error: Stack overflow at depth 50"

---

## 13. Recovery Procedures

### 13.1 Full Reset

**When:** Unrecoverable state corruption

**Procedure:**
1. Save backup of current state
2. Clear all Roster Board data
3. Re-poll all members
4. Notify: "Organizer reset due to error"

### 13.2 Partial Reset

**When:** Single group corrupted

**Procedure:**
1. Clear affected group
2. Move players back to bench
3. Notify: "Group X reset, please rebuild"

### 13.3 State Resync

**When:** Desync detected

**Procedure:**
1. Organizer broadcasts full state
2. Participants clear and rebuild
3. Validate consistency
4. Notify if still desynced

---

## 14. Implementation Checklist

- [ ] Implement roster size change detection
- [ ] Add player disconnect handling
- [ ] Build survey timeout system
- [ ] Add stale data warnings
- [ ] Implement drag validation
- [ ] Add keystone depletion detection
- [ ] Build optimizer error recovery
- [ ] Add communication retry logic
- [ ] Implement desync detection
- [ ] Add data integrity checks
- [ ] Build UI constraint enforcement
- [ ] Add performance monitoring
- [ ] Implement chat throttling
- [ ] Create error message system
- [ ] Build recovery procedures
- [ ] Write edge case test suite

---

**Document Status:** Complete  
**Ready for Reference:** Yes  
**Testing Priority:** CRITICAL