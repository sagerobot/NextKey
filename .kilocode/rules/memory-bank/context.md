# NextKey Current Context

## Current Work Status
**Date**: October 27, 2025
**Version**: 0.2.1
**Project Status**: Role Icon Spec Change Fix - Complete ✅

## Session Progress Summary

### Task: Fix Role Icon Not Updating on Spec Change ✅ COMPLETE

**Original Problem**:
Role icons in both Main UI and Roster Board did not update when player changed specializations. Icons stayed on previous spec's role until `/reload`.

**Root Causes Identified**:
1. **ProfilesService Not Initialized**: `Initialize()` never called during boot → event handlers never registered
2. **Missing Module Registration**: ProfilesService not registered with module system
3. **Event Handler Signature Error**: Missing `self` parameter caused event name misalignment
4. **Profile Role Assignment Bug**: Local variable set instead of profile object field
5. **Main UI Render Skipping**: Performance optimization skipped renders when keystone list unchanged
6. **Pattern Escaping Bug**: Dash in `Name-Realm` broke cache invalidation regex
7. **Cache Timing Issues**: Multiple profile builds during window creation reused stale cache

**Solutions Implemented**: Seven interconnected fixes across profiles, boot, and UI systems.

### Major Fixes Completed

#### 1. ProfilesService Initialization ✅
**Fixed**: [`boot.lua:277-284`](boot.lua:277-284)

**Changes**:
- Added ProfilesService to Init phase of boot sequence
- Now properly calls `Initialize()` which registers spec change event handlers
- Events now fire correctly when player changes specs

#### 2. Module Registration ✅
**Fixed**: [`core/profiles.lua:78-79`](core/profiles.lua:78-79)

**Changes**:
```lua
NextKey222.ProfilesService = ProfilesService
NextKey222.RegisterModule("ProfilesService", ProfilesService)
```

#### 3. Event Handler Function Signature ✅
**Fixed**: [`core/profiles.lua:141`](core/profiles.lua:141)

**Problem**: AceEvent callbacks receive `self` as first parameter, but function wasn't handling it

**Solution**:
```lua
// BEFORE (wrong):
OnProfilesInvalidation = function(event, unit, ...)

// AFTER (correct):  
OnProfilesInvalidation = function(self, event, unit, ...)
```

#### 4. Profile Role Assignment Bug ✅
**Fixed**: [`core/profiles.lua:732-734`](core/profiles.lua:732-734)

**Problem**: Code set local variables but never updated profile object:
```lua
role = specRole      // Only sets local variable
specName = name      // Only sets local variable
// profile.role was never set!
```

**Solution**:
```lua
profile.role = specRole      // Actually update profile object
profile.specName = name      // Actually update profile object
```

#### 5. Main UI Render Skipping Fix ✅
**Fixed**: [`core/profiles.lua:295-297`](core/profiles.lua:295-297)

**Problem**: Performance optimization skipped renders when keystone list unchanged (spec changes don't affect keystones)

**Solution**:
```lua
// Clear render tracking so UI actually re-renders on spec change
NextKey222.UI.lastRenderedKeystoneHash = nil
NextKey222.UI.lastRenderedSortMode = nil
```

#### 6. Pattern Escaping Fix ✅
**Fixed**: [`core/profiles.lua:109`](core/profiles.lua:109)

**Problem**: Dash in `Name-Realm` is a Lua pattern special character, broke cache invalidation

**Solution**:
```lua
local escapedName = playerName:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
if cacheKey:match("^" .. escapedName .. ":") then
```

#### 7. Cache Invalidation on Window Open ✅
**Fixed**:
- [`ui/organizer/rosterBoard.lua:107-116`](ui/organizer/rosterBoard.lua:107-116) - Roster Board
- [`ui/main.lua:557-562`](ui/main.lua:557-562) - Main UI

**Solution**: Clear both ProfilesService cache and UI profile cache when opening windows

### Files Modified

1. **Modified**: [`core/profiles.lua`](core/profiles.lua) - Module registration, event handler signature, role assignment, debug logging
2. **Modified**: [`boot.lua:277-284`](boot.lua:277-284) - Added ProfilesService initialization
3. **Modified**: [`ui/organizer/rosterBoard.lua:107-116`](ui/organizer/rosterBoard.lua:107-116) - Cache invalidation on open
4. **Modified**: [`ui/main.lua:557-562`](ui/main.lua:557-562) - Cache invalidation on open

## Working Features ✅

### Role Icon Updates (NEW - Just Fixed!)
- ✅ **Role icons update immediately when changing specs** (both windows)
- ✅ Works while windows are open (via spec change events)
- ✅ Works when reopening windows after spec change (via cache invalidation)
- ✅ No `/reload` required
- ✅ Uses `GetSpecialization()` as source of truth for current player
- ✅ Events fire correctly: `PLAYER_SPECIALIZATION_CHANGED` → cache invalidation → UI refresh

### M+ Group Organizer - Poll System
- ✅ Poll window displays correctly with all UI elements
- ✅ Opt-in/opt-out toggle works correctly
- ✅ Character selection dropdown populates from character storage
- ✅ Role preferences display based on character's available roles
- ✅ Poll responses send successfully via AceComm
- ✅ **Accepting poll adds player to bench**
- ✅ **Declining poll removes from bench and adds to opt-out**
- ✅ Opt-out section displays horizontally with scrolling

### M+ Group Organizer - Core Features
- ✅ Dynamic window sizing (scales to player count)
- ✅ Drag-and-drop system (bench, slots, opt-out)
- ✅ Two-phase card removal (no gaps during rejection)
- ✅ Role validation logic
- ✅ Rejection animation (smooth 300ms bounce-back)
- ✅ Progressive data disclosure (3 display modes)
- ✅ Opt-out horizontal scrolling
- ✅ **Correct role icons for all specs with live updates**

## Known Issues & Needed Features ⚠️

### 1. Roster State Persistence (HIGH PRIORITY)
**Problem**: Card positions not saved when closing/reopening window
**Impact**: Organizer loses all group composition work when window is closed

**Requirements**:
- Save roster state to SavedVariables when window closes
- Restore player positions (bench/slots/opt-out) when window reopens
- Persist group assignments and keystone designations
- Handle players who log off between sessions

**Implementation needed**:
- Add SavedVariables structure for roster state
- Implement `SaveRosterState()` in OnMainFrameClosed
- Implement `LoadRosterState()` in CreateMainFrame
- Store: player IDs, locations, group/slot assignments

### 2. Roster State Broadcasting (HIGH PRIORITY)
**Problem**: Observers (non-organizers) don't see roster changes in real-time
**Impact**: Only organizer sees current group composition; participants are blind

**Requirements**:
- Broadcast roster updates to all party/raid members
- Send full state when observer opens window
- Send incremental updates when cards are moved
- Handle observer join/leave events

**Implementation needed**:
- Implement roster state serialization
- Add broadcast on card move via OrganizerComms
- Add full state sync on window open for observers
- Add handler to apply received updates in participant mode

### 3. Dungeon Name Display - Incomplete Alias Data
**Problem**: Only 2 out of 8 Season 3 dungeons show correct abbreviated names
- Working: "ARA" (Ara-Kara), "FLOOD" (Operation: Floodgate)
- Not working: Other 6 Season 3 dungeons showing "???"

## Next Session Prompt

**Task**: Implement Roster State Persistence for M+ Group Organizer

**Context**: The poll system works correctly, role icons update properly when specs change, and players can accept/decline polls. However, when the organizer closes and reopens the window, all card positions are lost. This is a critical UX issue as organizers spend significant time arranging groups.

**Requirements**:
1. Save complete roster state to SavedVariables when window closes
2. Restore player positions when window reopens
3. Handle edge cases (players offline, different raid composition, etc.)

**Implementation approach**:
1. Design SavedVariables structure for roster state (players, locations, groups)
2. Implement `SaveRosterState()` in `OnMainFrameClosed()` - serialize bench, slots, opt-out
3. Implement `LoadRosterState()` in `CreateMainFrame()` - restore from saved data
4. Add validation logic (skip players not in current raid, handle missing data)
5. Test with various scenarios (close/reopen, /reload, different raid compositions)

**Files to modify**:
- [`ui/organizer/rosterBoard.lua`](ui/organizer/rosterBoard.lua) - Add save/load methods
- [`core/config.lua`](core/config.lua) - May need to add SavedVariables schema

**Success criteria**:
- Closing and reopening window preserves all card positions
- Group compositions survive /reload
- Gracefully handles players who log off
- Works correctly when raid composition changes between sessions

**Priority**: HIGH - This is essential for organizer usability

## Queued Work (After Roster Persistence)

1. **Roster State Broadcasting** - Sync changes to all observers in real-time
2. **Dungeon Name Fix** - Fix alias display for remaining 6 Season 3 dungeons
3. **Loot Targeting** - Complete Hero-track tooltip fix
4. **PUG Mode** - Resume Phase 4 repairs
