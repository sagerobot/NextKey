# Code Cleanup - Aggressive Deletion Plan

**Goal**: Remove deprecated/redundant code now that FakePlayerService is in place

---

## Summary

**Current State**: ~2,000 lines added  
**Target After Cleanup**: ~1,400 lines net change  
**Deletions Planned**: ~600+ lines of deprecated code

---

## Phase 1: Remove Legacy Fake Player Functions from debug/init.lua

### Target: ~280 lines to delete

All the `Legacy*` functions in `debug/init.lua` can be removed:

- `LegacyAddRandomFakePlayers()` + helpers (~150 lines)
- `LegacyGeneratePresetTeam()` + helpers (~80 lines)  
- `LegacyClearFakePlayers()` (~10 lines)
- All helper functions: `GenerateRealisticFakePlayer`, `GenerateRealisticIOTier`, etc. (~40 lines)

**Reason**: FakePlayerService now handles all this. The wrappers will just fail gracefully if service isn't available.

**Risk**: ⚠️ MEDIUM - If FakePlayerService fails to load, no fallback
**Mitigation**: Add better error messages in wrappers

---

## Phase 2: Simplify Wrappers in debug/init.lua

### Target: ~20 lines to simplify

Current wrappers have legacy fallback:
```lua
function NextKey222.Addon:AddRandomFakePlayers(count, addonMix)
    if NextKey222.FakePlayerService:IsEnabled() then
        return NextKey222.FakePlayerService:GenerateRandomPlayers(count, addonMix)
    end
    return self:LegacyAddRandomFakePlayers(count, addonMix)  -- DELETE THIS
end
```

Simplified:
```lua
function NextKey222.Addon:AddRandomFakePlayers(count, addonMix)
    if not NextKey222.FakePlayerService or not NextKey222.FakePlayerService:IsEnabled() then
        print("NextKey: FakePlayerService not available")
        return 0
    end
    return NextKey222.FakePlayerService:GenerateRandomPlayers(count, addonMix)
end
```

---

## Phase 3: Remove Old Storage Functions from debug/init.lua

### Target: ~80 lines to delete

These functions work with old `dbg.players[index]` format:
- `GetFakePlayerBest()`
- `SetFakePlayerBest()`
- `RecalculateFakePlayerScore()`
- `SetFakePlayerAllBests()`
- `ClearFakePlayerBests()`

**Reason**: FakePlayerService has equivalent methods
**Keep**: Only `EnsureDebug()` for options panel compatibility (for now)

---

## Phase 4: Simplify DebugAdapter Legacy Fallback

### Target: ~40 lines to delete

Current code has legacy fallback paths. Since FakePlayerService is always initialized at boot, we can remove the fallback:

```lua
-- DELETE this entire section:
-- LEGACY FALLBACK: Check old debug storage system
if not NextKey222.Addon.UI.GetFakePlayerData then
    return nil
end
-- ... 40 lines of fallback code
```

---

## Phase 5: Remove Debug Tools

### Target: ~50 lines to delete

`debug/tools.lua` has "Add Form" functions for manually adding fake players. Not needed with presets:
- `EnsureDebugAddForm()`
- `GetAddFormBest()`
- `SetAddFormBest()`
- `SetAddFormAllBest()`
- `ClearAddFormBest()`

**Reason**: Presets are better UX than manual forms

---

## Phase 6: Remove Validation Script (After Testing)

### Target: ~230 lines to delete

`debug/validate_phase1.lua` is useful NOW but not needed long-term.

**Keep For**: 1-2 weeks of testing  
**Then**: DELETE entire file

---

## Phase 7: Simplify Documentation

### Target: 3 files to delete after publishing

These are development docs, not user docs:
- `FAKE_PLAYER_ANALYSIS.md` (use GitHub wiki instead)
- `PHASE_1_COMPLETE.md` (archive to wiki)
- Move `FAKE_PLAYER_QUICK_REFERENCE.md` content into main README

---

## Total Impact

| Category | Lines Deleted | Lines Added | Net Change |
|----------|---------------|-------------|------------|
| debug/init.lua | -380 | +15 (error messages) | -365 |
| debug/tools.lua | -50 | 0 | -50 |
| adapters/debug.lua | -40 | +5 | -35 |
| validate_phase1.lua | -230 (later) | 0 | -230 |
| Documentation | -500 (later) | 0 | -500 |
| **Total** | **-1200** | **+20** | **-1180** |

**Final Net**: ~800 lines added (down from 2000!)

---

## Execution Order

1. ✅ **Now**: Remove legacy functions (safe, immediate benefit)
2. ✅ **Now**: Simplify wrappers (safe)
3. ✅ **Now**: Remove old storage functions (safe)
4. ✅ **Now**: Simplify DebugAdapter (safe)
5. ⏳ **After 1 week**: Remove validation script
6. ⏳ **After 1 month**: Remove development docs

---

## Start Now?

Execute phases 1-4 immediately (saves ~500 lines)
