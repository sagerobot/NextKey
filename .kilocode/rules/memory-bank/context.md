# NextKey Current Context

## Current Work Status
**Date**: November 2, 2025
**Version**: 0.2.1
**Current Phase**: M+ Group Organizer - Tooltip Bug Investigation

## Active Work

### CRITICAL BUG: Default Spec Tooltips Not Displaying (UNRESOLVED)
**Status**: Under active investigation
**Priority**: HIGH

**Problem**: 
Player card role icon tooltips are showing fallback text ("Want to Play", "Will Fill") instead of spec-level breakdowns with spec names, even though `GenerateDefaultSpecPreferences()` is being called and should be generating `specDetails` data.

**Attempted Fixes (FAILED)**:
1. Added `GenerateDefaultSpecPreferences()` to `rosterBoard.lua` GetBenchPlayers() for both fake and real players (lines 409-420, 473-481)
2. Added case normalization in `playerCard.lua` tooltip lookups (lines 264-265, 519-520)
3. Improved debug logging to trace key lookups and data availability

**Investigation Needed**:
- Verify `specDetails` is actually being set on playerData objects in GetBenchPlayers()
- Check if data is being lost/overwritten somewhere in the data flow
- Examine if the issue is in data generation vs data persistence vs data lookup
- Enable debug logging and trace the actual data flow from generation to tooltip display

**Files Involved**:
- `ui/organizer/rosterBoard.lua` - GetBenchPlayers() generates player cards
- `core/organizer/playerDataBuilder.lua` - GenerateDefaultSpecPreferences() creates spec data
- `ui/organizer/playerCard.lua` - Tooltip rendering logic

**Next Steps**:
1. Add comprehensive debug logging to trace playerData.specDetails through entire flow
2. Verify data is present immediately after GenerateDefaultSpecPreferences() call
3. Check if data survives transfer to card.playerData
4. Confirm tooltip code is actually checking the right data structure

### Recently Completed
- M+ Group Organizer Poll System (3-phase survey with spec preferences)
- Poll UI with smart defaults and 3-state selection system
- Character data capture with full specialization metadata
- Flexible role assignment algorithm with priority system (play=10, fill=5, none=0)

## Current Blockers
**CRITICAL**: Tooltip bug preventing proper spec-level display of player preferences before poll is sent.

## Technical Notes
- Poll system uses 3-state preference system (Want to Play, Will Fill, Not Playing)
- Weighted scoring (10/5/0) for optimization algorithms
- All poll UI components use texture-based rendering for modern WoW API compatibility
- Default spec preferences should be generated using player's current spec from profile data
- Role keys in specDetails MUST be uppercase (TANK, HEALER, DAMAGER) for consistent lookups
