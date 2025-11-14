# Current Sorting Implementation Analysis

**Date**: November 14, 2025  
**Version**: 0.6.6  
**Source**: [`ui/main.lua:870-896`](ui/main.lua:870)

## Current State

### Location
All sorting logic is currently hardcoded in [`ui/main.lua:SortKeys()`](ui/main.lua:870)

### Existing Sorting Modes

#### 1. HighestKeyLevel
**Code**: Lines 876-879
```lua
if mode == "HighestKeyLevel" then
    table.sort(sorted, function(a, b)
        return (a.key.level or 0) > (b.key.level or 0)
    end)
```

**Metadata**:
- **Applicable Views**: Main window (keystones)
- **Min Group Size**: 1
- **Max Group Size**: Unlimited
- **Data Requirements**: None (only uses key.level)
- **Performance**: O(n log n) - Fast

**Business Logic**:
- Sorts keystones by level in descending order
- Higher level keys appear first
- Useful for pushing high keys or finding challenging content

---

#### 2. LowestKeyLevel
**Code**: Lines 880-883
```lua
elseif mode == "LowestKeyLevel" then
    table.sort(sorted, function(a, b)
        return (a.key.level or 0) < (b.key.level or 0)
    end)
```

**Metadata**:
- **Applicable Views**: Main window (keystones)
- **Min Group Size**: 1
- **Max Group Size**: Unlimited
- **Data Requirements**: None (only uses key.level)
- **Performance**: O(n log n) - Fast

**Business Logic**:
- Sorts keystones by level in ascending order
- Lower level keys appear first
- Useful for quick/easy runs or warming up

---

#### 3. IOGainPotential
**Code**: Lines 884-892
```lua
elseif mode == "IOGainPotential" then
    -- Calculate IO gain range for each key (includes expected value)
    for _, item in ipairs(sorted) do
        item.ioGainRange = self:CalculateIOGainRange(item.key)
        item.ioGainPotential = item.ioGainRange.expected -- For backward compatibility
    end
    table.sort(sorted, function(a, b)
        return (a.ioGainPotential or 0) > (b.ioGainPotential or 0)
    end)
```

**Metadata**:
- **Applicable Views**: Main window (keystones)
- **Min Group Size**: 1 (but more useful with 2+)
- **Max Group Size**: Unlimited
- **Data Requirements**: 
  - Requires IOCalculator module
  - Requires party profile data
  - Requires current dungeon scores
- **Performance**: O(n * m) where m = party size (expensive)

**Business Logic**:
- Calculates expected IO gain for entire party for each keystone
- Uses `UI:CalculateIOGainRange()` which delegates to IOCalculator
- Sorts by expected (timed completion) IO gain in descending order
- Most IO-efficient keys appear first
- This is the "smart" sort that optimizes group progression

---

### Additional Sorting Modes (Dungeon View)

**Code**: Lines 904-930 (in `UpdateSortDropdownOptions`)
```lua
if self.viewMode == "dungeons" then
    -- Dungeon view: Alphabetical, Highest IO, Lowest IO
    self.sortDropdown:SetList({
        Alphabetical = "Alphabetical",
        HighestIO = "Highest IO Score", 
        LowestIO = "Lowest IO Score"
    })
```

**Notes**: These are for the dungeon window (separate from keystone view), but not currently implemented in `SortKeys()`. They would need separate implementation or extension of the sorting system.

---

## Issues with Current Implementation

### 1. **Tight Coupling to UI**
- Sorting logic lives in UI layer
- Cannot be reused by other systems (e.g., Organizer, optimizer algorithms)
- Makes testing difficult

### 2. **No Extensibility**
- Adding new sort modes requires editing `ui/main.lua`
- Hardcoded if/elseif chain
- No mechanism for plugins or dynamic algorithm registration

### 3. **Mixed Concerns**
- Data enrichment (`CalculateIOGainRange`) mixed with sorting
- UI code shouldn't be responsible for business logic

### 4. **No Metadata/Filtering**
- No way to know which sorts are applicable in which contexts
- UI must manually manage dropdown options based on view mode

### 5. **Performance Concerns**
- IO gain calculation happens inline during sorting
- No caching of calculated values between re-sorts
- Expensive calculation repeated unnecessarily

---

## Proposed Refactor Architecture

### Core Sorting Service
**File**: `core/sorting/main.lua`

```lua
NextKey222.Sorting = {
    -- Registry of all available algorithms
    algorithmRegistry = {},
    
    -- Public API
    RegisterAlgorithm(name, metadata, sortFunction),
    GetAlgorithmsForContext(context),
    SortData(data, algorithmName)
}
```

### Individual Algorithm Files
**Directory**: `core/sorting/algorithms/`

Each algorithm in its own file:
- `byKeyLevel.lua` (HighestKeyLevel)
- `byKeyLevelAsc.lua` (LowestKeyLevel)
- `byIOGain.lua` (IOGainPotential)

### Algorithm Structure
```lua
-- core/sorting/algorithms/byKeyLevel.lua
local function SortByKeyLevel(a, b)
    return (a.key.level or 0) > (b.key.level or 0)
end

local metadata = {
    applicableViews = {"mainWindow"},
    minGroupSize = 1,
    maxGroupSize = nil, -- unlimited
    requiresIOCalculator = false,
}

NextKey222.Sorting:RegisterAlgorithm("Highest Key Level", metadata, SortByKeyLevel)
```

---

## Migration Path

### Phase 1: Create Sorting Service
1. Create `core/sorting/main.lua` with registry + API
2. Create algorithm files in `core/sorting/algorithms/`
3. Register existing three algorithms

### Phase 2: Update UI
1. Modify `ui/main.lua:SortKeys()` to use new service
2. Remove hardcoded if/elseif logic
3. Use `GetAlgorithmsForContext()` for dropdown population

### Phase 3: Optimization
1. Move IO calculation out of sort function
2. Pre-calculate and cache IO ranges before sorting
3. Only recalculate when party composition changes

### Phase 4: Cleanup
1. Remove old sorting code from UI
2. Document new architecture
3. Create examples for adding new algorithms

---

## Algorithm Inventory Summary

| Algorithm Name | Current Mode | Views | Data Deps | Performance | Priority |
|----------------|--------------|-------|-----------|-------------|----------|
| Highest Key Level | HighestKeyLevel | Main | None | Fast | HIGH |
| Lowest Key Level | LowestKeyLevel | Main | None | Fast | HIGH |
| IO Gain Potential | IOGainPotential | Main | IOCalc | Expensive | HIGH |
| Alphabetical | (Planned) | Dungeon | None | Fast | MEDIUM |
| Highest IO Score | (Planned) | Dungeon | Profiles | Medium | MEDIUM |
| Lowest IO Score | (Planned) | Dungeon | Profiles | Medium | MEDIUM |

---

## Next Steps

1. ✅ **Analysis Complete** - This document
2. Create `core/sorting/main.lua` with registry pattern
3. Create algorithm files for existing three sorts
4. Update `NextKey.toc` load order
5. Update `ui/main.lua` to use new service
6. Test all sorting modes
7. Document in Memory Bank
