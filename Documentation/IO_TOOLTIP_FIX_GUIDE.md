# IO Tooltip Fix Implementation Guide

## Overview

This document describes the implementation of the fix for IO gain tooltips that were not appearing after the UI refactor. The fix updates the tooltip system to use the centralized tooltip management system introduced in Phase 7.

## Problem Description

**Issue**: IO gain tooltips were not appearing when hovering over IO gain areas in both regular and compact keystone views.

**Root Cause**: The `ShowIOGainTooltip` function in `ui/main.lua` was using direct `GameTooltip` calls instead of the centralized tooltip system (`core/tooltip.lua`), creating a disconnect between the component factory system and tooltip display logic.

## Solution Implementation

### 1. Updated Tooltip Function Calls

**File**: `ui/main.lua`

**Changes**:
- Updated lines 1716-1718 and 2039-2041 to call `ShowIOGainTooltipCentralized` instead of `ShowIOGainTooltip`
- This ensures both regular and compact keystone views use the centralized system

### 2. New Centralized Tooltip Function

**Function**: `UI:ShowIOGainTooltipCentralized(button, keyInfo, entry, ioRange)`

**Features**:
- Uses the centralized tooltip system (`NextKey222.Tooltip`) when available
- Falls back to the original implementation if centralized system is not available
- Converts data to the format expected by the centralized system

### 3. Data Structure Conversion Functions

**Functions Added**:
- `UI:BuildIOTooltipTitle(keyInfo, ioRange)` - Builds formatted title
- `UI:BuildIOTooltipBreakdown(keyInfo, ioRange)` - Builds player breakdown data
- `UI:BuildIOTooltipTotals(keyInfo, ioRange)` - Builds totals section

### 4. Test Script

**File**: `debug/test_io_tooltips.lua`

**Features**:
- Comprehensive testing of the centralized tooltip system
- Validates all new functions
- Provides in-game testing commands
- Includes test data for validation

## Testing Instructions

### 1. Basic Functionality Test

```lua
/testiotooltips
```

This command runs the automated test suite to verify:
- Centralized tooltip system availability
- New function availability
- Data building functionality
- Tooltip creation capability

### 2. In-Game Manual Test

1. **Generate Test Data**:
   ```
   /nk test preset mixed_skill
   ```

2. **Set Sort Mode**:
   - Open NextKey: `/nk`
   - Set sort mode to "IO Gain Potential"
   - Green IO gain text should appear

3. **Test Tooltips**:
   - Hover over the green IO gain text in regular view
   - Hover over the green IO gain text in compact view
   - Detailed tooltip should appear with:
     - Dungeon name and level
     - Owner name
     - Individual player breakdown
     - Group IO gain totals (untimed/timed/+2/+3)

### 3. Debug Mode Testing

1. **Enable Debug**:
   ```
   /nk config
   → Debug System → Set level to DEV
   → Enable "tooltip" category
   ```

2. **Check Debug Output**:
   - Look for tooltip-related debug messages
   - Verify tooltip trigger events are logged

## Expected Behavior

### Before Fix
- No tooltips appear when hovering over IO gain areas
- Debug output shows tooltip events but no visual feedback

### After Fix
- Detailed tooltips appear when hovering over IO gain areas
- Tooltips show individual player breakdowns
- Tooltips show group IO gain totals at different breakpoints
- Consistent behavior in both regular and compact views
- Debug output shows successful tooltip creation

## Technical Details

### Data Flow

1. **Event Trigger**: User hovers over IO gain text
2. **Component System**: `ConfigureButton` in `ui/components.lua` triggers `onEnter` callback
3. **Centralized Function**: `ShowIOGainTooltipCentralized` is called
4. **Data Conversion**: Helper functions convert data to centralized format
5. **Tooltip Creation**: `NextKey222.Tooltip:Create` generates tooltip
6. **Display**: Tooltip appears with formatted content

### Fallback Mechanism

If the centralized tooltip system is not available, the code automatically falls back to the original `ShowIOGainTooltip` implementation, ensuring compatibility.

## Files Modified

1. `ui/main.lua` - Updated tooltip calls and added centralized functions
2. `NextKey.toc` - Added test script to load order
3. `debug/test_io_tooltips.lua` - New test script (added)

## Validation Checklist

- [ ] Tooltips appear in regular keystone view
- [ ] Tooltips appear in compact keystone view
- [ ] Tooltips show correct player breakdowns
- [ ] Tooltips show correct group totals
- [ ] Tooltips format correctly with colors
- [ ] No Lua errors in debug output
- [ ] Test script passes all checks
- [ ] Fallback works if centralized system unavailable

## Troubleshooting

### Tooltips Still Not Appearing

1. **Check Debug Output**:
   ```
   /nk config
   → Debug System → Set level to DEV
   → Enable "tooltip" category
   ```

2. **Verify Module Loading**:
   ```
   /testiotooltips
   ```
   Check if all modules are loaded correctly.

3. **Check Component System**:
   Verify buttons are created with correct callbacks in `ui/components.lua`.

### Incorrect Tooltip Content

1. **Check Data Conversion**:
   Verify helper functions are building data correctly.

2. **Check Centralized System**:
   Verify `core/tooltip.lua` content builders are working.

3. **Check Data Sources**:
   Verify IO calculation and player data are correct.

## Future Improvements

1. **Enhanced Styling**: Consider adding more visual indicators to tooltips
2. **Performance Optimization**: Cache tooltip data for better performance
3. **Accessibility**: Add keyboard navigation support for tooltips
4. **Customization**: Allow users to customize tooltip content and appearance

## Conclusion

This fix resolves the IO tooltip issue by integrating the tooltip system with the centralized tooltip management system. The solution maintains backward compatibility while providing enhanced functionality and consistency with the rest of the UI refactor.