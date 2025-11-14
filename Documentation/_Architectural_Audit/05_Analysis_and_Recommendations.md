# Architectural Audit Analysis & Recommendations

**Date**: November 14, 2025  
**Version**: 0.6.0  
**Status**: Complete

## Executive Summary

This document provides a comprehensive analysis of the architectural audit documents, sorting system refactor plans, and current codebase structure. **The proposed refactor strategy is sound and well-designed**, with the PUG Helper already serving as a successful proof-of-concept.

---

## ✅ What's Working Well

### 1. PUG Helper as Reference Implementation

The [`core/PugHelper/main.lua`](../core/PugHelper/main.lua) demonstrates **excellent modular architecture**:

- ✅ Clear module definition with `NextKey222.RegisterModule()`
- ✅ Self-contained configuration management
- ✅ Event-based communication using `RegisterMessage()`
- ✅ Clean separation: orchestrator → state → applications → detection → UI
- ✅ Proper initialization lifecycle with phased startup
- ✅ SafeRun wrapping for critical operations

**Key Success Pattern:**
```lua
-- PUG Helper doesn't directly call other modules
-- Instead, it announces completion:
NextKey:SendMessage("PUG_RUN_COMPLETED", key_info)
-- Then OTHER modules react to this event
```

This is **exactly** the event-driven pattern the refactor strategy recommends.

### 2. Sorting System Refactor Plan is Excellent

The [`Documentation/_Refactor_/01_Sorting_System/`](_Refactor_/01_Sorting_System/) plan demonstrates **mature architectural thinking**:

- ✅ **Registry Pattern**: Pluggable algorithms via `RegisterSortingAlgorithm()`
- ✅ **Metadata-Driven Filtering**: Context-aware algorithm availability
- ✅ **Service Module Pattern**: Direct API calls (not events) for synchronous data retrieval
- ✅ **Clear Rationale**: Explains *why* events aren't appropriate here (synchronous on-demand logic)

**Critical Insight:**  
The plan correctly identifies that **not everything should use events**. Service modules that provide synchronous data (like sorting algorithms) should use **direct API calls** with **one-way dependencies** (UI → Service, not Service → UI).

### 3. Architectural Audit is Accurate

The [`Documentation/_Architectural_Audit/`](_Architectural_Audit/) documents correctly identify:

- ✅ Hotspot files ([`boot.lua`](../boot.lua), [`core/utils.lua`](../core/utils.lua), [`core/config.lua`](../core/config.lua))
- ✅ Tight coupling issues (direct function calls between modules)
- ✅ Logical feature groups (8 clear categories)
- ✅ Circular dependency risks (core ↔ ui)

---

## 🎯 Critical Observations

### 1. OrganizerSorting Already Follows Service Pattern

[`core/organizer/sorting.lua`](../core/organizer/sorting.lua) is a **well-designed service module**:

- ✅ Single public method: `CalculateSequentialAssignment()`
- ✅ No direct dependencies on UI
- ✅ Pure business logic (role-by-role assignment strategy)
- ✅ SafeRun wrapped with detailed debug logging

**This module already follows the refactor strategy!** It's a perfect example of a service that can be called directly without events.

### 2. UI/Main.lua Shows Facade Pattern Success

[`ui/main.lua`](../ui/main.lua) has been successfully refactored from ~3000 lines to ~1541 lines:

- ✅ Delegates to specialized modules (MainWindow, UIControls, ViewManager, UIRendering)
- ✅ Maintains stable public APIs for backward compatibility
- ✅ Clear separation of concerns

**However**, there's still room for further modularization (see recommendations below).

### 3. Current Sorting Logic is Scattered

The current sorting implementation in [`ui/main.lua:SortKeys()`](../ui/main.lua:870) is **hardcoded** in the UI layer:

```lua
function UI:SortKeys(keys, mode)
    if mode == "HighestKeyLevel" then
        -- hardcoded sort logic
    elseif mode == "LowestKeyLevel" then
        -- hardcoded sort logic
    elseif mode == "IOGainPotential" then
        -- hardcoded sort logic
    end
end
```

This is **exactly** the problem the sorting system refactor plan aims to solve. ✅ The plan is targeting the right issue.

---

## 📋 Refactor Strategy Assessment

### ✅ APPROVED: Core Principle - Events Over Direct Calls

**Verdict**: **Strongly Recommend** with **one critical caveat**.

**What's Right:**

1. **AceEvent-3.0 pub/sub** breaks tight coupling
2. **One-way dependencies** are healthier than circular dependencies
3. **PUG Helper proves this works** in production

**Critical Caveat (from the sorting plan):**

**NOT everything should use events.** The sorting plan correctly identifies two communication patterns:

1. **Event-Based Communication** (for state changes & announcements):
   ```lua
   -- Module A announces something happened
   NextKey:SendMessage("SCORE_UPDATED", dungeonID, newScore)
   
   -- Module B reacts to the announcement
   NextKey:RegisterMessage("SCORE_UPDATED", handlerFunction)
   ```

2. **Direct API Calls** (for synchronous services):
   ```lua
   -- UI directly calls service to get data
   local algorithms = NextKey.Sorting:GetAlgorithmsForContext(context)
   ```

**Use Events For:**

- State changes that other modules may care about
- User actions that trigger multi-module workflows
- Async operations where you don't need immediate response

**Use Direct Calls For:**

- Synchronous data retrieval
- Service modules that provide on-demand logic
- Performance-critical paths (events have overhead)

---

### ✅ APPROVED: Starting with PUG Helper

**Verdict**: **Already Complete** - PUG Helper is the reference implementation.

The PUG Helper refactor has **already been implemented** successfully, as evidenced by:

- Modular architecture (state/applications/detection/UI split)
- Event-driven communication (`PUG_RUN_COMPLETED` message)
- Clean initialization lifecycle
- No circular dependencies

**Next logical candidate**: The **Organizer feature** (already partially modular with OrganizerState).

---

### ✅ APPROVED: Pluggable Sorting System

**Verdict**: **Excellent Design** - Implement as specified.

The sorting system refactor plan is **production-ready**:

1. ✅ Registry pattern enables easy extension
2. ✅ Metadata-driven filtering provides context awareness
3. ✅ Service module pattern is appropriate for synchronous logic
4. ✅ Clear migration path from current hardcoded implementation

**Implementation Priority**: **HIGH** - This should be the next major refactor after the architectural audit documents are internalized.

---

## 🚨 Areas of Concern

### 1. TOC Load Order Dependency

The sequential load order in [`NextKey.toc`](../NextKey.toc) creates **implicit dependencies** that make refactoring risky.

**Risk**: Moving files in the TOC can break the addon if modules haven't explicitly declared their dependencies.

**Mitigation Strategy:**

- Document explicit dependencies in module headers
- Use `Initialize()` methods to validate dependencies at runtime
- Consider a **dependency injection pattern** for critical services

### 2. Util Files as Dependency Hotspots

[`core/utils.lua`](../core/utils.lua) likely contains **dozens of helper functions** used across the entire codebase.

**Problem**: This creates a **massive implicit dependency** - every module depends on utils, making it impossible to isolate modules.

**Recommended Solution:**

1. **Audit utils.lua** - categorize functions by domain
2. **Split into domain-specific utils**:
   - `core/utils/string.lua` - String manipulation
   - `core/utils/table.lua` - Table operations
   - `core/utils/player.lua` - Player name normalization
   - `core/utils/dungeon.lua` - Dungeon ID conversions
3. **Move specialized functions to their owning modules**

### 3. Constants.lua as Configuration Hotspot

[`core/constants.lua`](../core/constants.lua) likely contains values used everywhere.

**Problem**: Changing a constant can have **ripple effects** across the entire addon.

**Recommended Solution:**

1. **Namespace constants by domain**:
   ```lua
   NextKey222.Constants = {
       Dungeons = { ... },
       Keystones = { ... },
       UI = { ... },
       Performance = { ... }
   }
   ```
2. **Document which constants are user-facing** (can't change) vs internal (can refactor)

---

## 🎯 Recommended Refactor Sequence

### Phase 1: Foundation (Weeks 1-2)

1. ✅ **Already Complete**: Internalize architectural audit documents
2. **Split utils.lua** into domain-specific files
3. **Namespace constants.lua** by domain
4. **Document explicit module dependencies** in headers

### Phase 2: Service Modules (Weeks 3-4)

1. **Implement Pluggable Sorting System** (following the refactor plan)
2. **Extract IOCalculator as pure service** (if not already)
3. **Extract Scoring as pure service** (if not already)

### Phase 3: Feature Modules (Weeks 5-8)

1. **Refactor Organizer** to fully event-driven architecture
   - OrganizerState already exists ✅
   - Convert UI → State interactions to use events
2. **Refactor Teleport System** (if needed - already seems modular)
3. **Refactor Loot Tracking System** (reconfirm current state)

### Phase 4: Core Modules (Weeks 9-12)

1. **Refactor Communications** to pure message router
2. **Refactor Keystones** to announce state changes via events
3. **Refactor Profiles** to cache + event pattern

### Phase 5: UI Layer (Weeks 13-16)

1. **Extract remaining UI logic** from ui/main.lua
2. **Standardize component creation** via factories
3. **Implement render queuing** for performance

---

## 📊 Module Consolidation Opportunities

### Candidates for Merging:

1. **Dungeon Name Services** (3 files → 1 service):
   - `core/dungeonNameService.lua`
   - `core/dungeonNameMatcher.lua`
   - `core/activityToDungeonMap.lua`

2. **Adapter Layer** (4 files → unified adapter pattern):
   - `core/adapters/blizzard.lua`
   - `core/adapters/raiderio.lua`
   - `core/adapters/libopenraid.lua`
   - `core/adapters/debug.lua`

### Candidates for Splitting:

1. **ui/main.lua** (1541 lines → further split):
   - Still contains business logic (SortKeys, EnrichEntryMetadata)
   - Extract to `ui/keystoneService.lua` or `core/keystonePresenter.lua`

---

## 🎓 Key Architectural Lessons from PUG Helper

The PUG Helper implementation demonstrates **5 critical patterns**:

### 1. State Machine Pattern

```lua
-- core/pugHelper_state.lua
STATE = {
    IDLE = "IDLE",
    TRACKING = "TRACKING",
    INVITE_RECEIVED = "INVITE_RECEIVED",
    IN_GROUP = "IN_GROUP",
    RUN_COMPLETE = "RUN_COMPLETE"
}
```

**Use this for**: Any feature with complex workflows (Organizer, Teleport flows, Loot targeting)

### 2. Primary Resource Lock

```lua
-- Ensures first-accepted-wins
primaryInvite + activeInviteID enforce locking
```

**Use this for**: Any exclusive resource (raid frames, teleport targets, optimizer runs)

### 3. Orchestrator Pattern

```lua
-- core/pugHelper.lua wires everything together
-- But doesn't contain business logic itself
```

**Use this for**: Feature entry points that coordinate submodules

### 4. Message-Based Completion

```lua
-- Announces completion, doesn't call directly
NextKey:SendMessage("PUG_RUN_COMPLETED", key_info)
```

**Use this for**: All feature completion announcements

### 5. Graceful Degradation

```lua
-- Checks for API availability before using
if not NextKey or not NextKey.SetTeleportTargetKey then
    return
end
```

**Use this for**: All module interactions

---

## ⚠️ Risks & Mitigations

### Risk 1: Breaking Existing Functionality

**Likelihood**: HIGH during refactor  
**Impact**: HIGH (addon won't load/work)

**Mitigation**:

- ✅ Refactor ONE feature at a time
- ✅ Use feature flags to toggle new vs old behavior
- ✅ Comprehensive testing after each module refactor
- ✅ Keep backup of working version before major changes

### Risk 2: Performance Regression

**Likelihood**: MEDIUM (events have overhead)  
**Impact**: MEDIUM (UI lag, memory increase)

**Mitigation**:

- ✅ Profile before/after each refactor
- ✅ Use direct calls for hot paths (not events)
- ✅ Batch event announcements where appropriate
- ✅ Monitor memory usage (current: <10MB baseline)

### Risk 3: Over-Engineering

**Likelihood**: MEDIUM (tempting to over-abstract)  
**Impact**: LOW-MEDIUM (complexity without benefit)

**Mitigation**:

- ✅ Follow PUG Helper patterns (proven to work)
- ✅ Don't create abstractions until you need them
- ✅ Keep service modules simple (one responsibility)
- ✅ Remember: "Make it work, make it right, make it fast" (in that order)

---

## 🎯 Final Recommendations

### 1. Implement Sorting System Refactor NEXT

**Why**: It's well-designed, low-risk, and provides immediate extensibility benefits.

**Steps**:

1. Create `core/sorting/main.lua` (registry + filtering)
2. Create `core/sorting/algorithms/` (individual sort files)
3. Migrate existing sorts from [`ui/main.lua:SortKeys()`](../ui/main.lua:870)
4. Update UI to use registry instead of hardcoded if/else

**Estimated Effort**: 2-3 days  
**Risk**: LOW  
**Benefit**: HIGH (extensibility + proof of service pattern)

### 2. Document Module Dependencies Explicitly

**Why**: Makes refactoring safer and helps identify circular dependencies.

**Format**:

```lua
-- MARK: Module Dependencies
-- Required: NextKey222.Debug, NextKey222.SafeRun
-- Optional: NextKey222.Profiles (falls back gracefully)
-- Announces: SCORE_UPDATED, DUNGEON_COMPLETED
-- Listens: GROUP_ROSTER_UPDATE, KEYSTONE_CHANGED
```

**Estimated Effort**: 1-2 days  
**Risk**: NONE  
**Benefit**: HIGH (safety net for all future refactors)

### 3. Create Refactor Testing Checklist

**Why**: Ensures each module refactor maintains functionality.

**Checklist Items**:

- [ ] Module registers with `NextKey222.RegisterModule()`
- [ ] All critical code wrapped in `SafeRun()`
- [ ] No direct `print()` calls (use Debug system)
- [ ] Initialize() method defined and working
- [ ] Dependencies documented in header
- [ ] Events announced/listened documented
- [ ] Manual testing completed
- [ ] Memory usage checked (no leaks)

---

## Conclusion

**The architectural audit and refactor strategy are well-designed and production-ready.** The PUG Helper implementation proves the event-driven architecture works in practice.

**Key Success Factors:**

1. ✅ **Clear communication patterns** (events for announcements, direct calls for services)
2. ✅ **Proven reference implementation** (PUG Helper)
3. ✅ **Pragmatic approach** (not everything needs events)
4. ✅ **Incremental strategy** (one feature at a time)

**Next Steps:**

1. Implement sorting system refactor (high value, low risk)
2. Document all module dependencies explicitly
3. Continue with Organizer feature refactor
4. Follow the 5-phase sequence outlined above

**Confidence Level**: **HIGH** - This refactor plan will succeed if executed incrementally with proper testing at each stage.