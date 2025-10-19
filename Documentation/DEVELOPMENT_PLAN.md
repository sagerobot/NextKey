# NextKey Development Plan - Post-UI Refactor Bugfixing Phase

**Date**: October 19, 2025
**Current Version**: 0.2.0.1
**Project Status**: Post-UI Refactor Bugfixing Phase

---

## 🎯 Executive Summary

The NextKey addon has completed a major UI refactoring (Phases 1-6) and is now in the bugfixing and stabilization phase. This plan prioritizes core functionality restoration, visual consistency improvements, and major feature implementation based on user requirements documented in `CURRENT_STATUS_REQUIREMENTS.md`.

---

## 🚀 Phase 1: Critical Core Functionality (Immediate Priority)

### 1. Fix IO Tooltips - HIGHEST PRIORITY ⭐⭐⭐

**Problem**: Core decision-making functionality broken - players can't see per-player key impact
**Impact**: Most critical missing feature for key selection workflow
**Location**: `ui/main.lua` lines 1154-1297 (function exists but not triggering properly)
**Files Involved**:
- `ui/main.lua` - Main tooltip function and attachment logic
- `ui/components.lua` - Component tooltip attachment system (lines 1170-1374)
- `core/tooltip.lua` - Centralized tooltip management system

**Diagnostic Approach**:
1. Enable debug mode: `/nk config` → Debug System → Set level to DEV
2. Test hovering over IO gain areas in both regular and compact views
3. Check debug output for tooltip trigger events under "tooltip" category
4. Verify event handlers are attached in component system
5. Test with different sort modes (especially IOGainPotential)

**Expected Issues**:
- Event handlers not properly attached after UI refactor
- Component factory tooltip integration broken
- Tooltip data not passed correctly to centralized system

**Expected Time**: 1-2 hours (likely quick fix)
**Success Criteria**: Players can hover over IO calculations and see detailed per-player impact breakdowns

---

### 2. Fix Dungeon View IO Color Consistency ⭐⭐

**Problem**: Visual inconsistency between player keystone cards and dungeon view total IO display
**Impact**: Professional appearance and user experience
**Location**: `ui/main.lua` lines 2520-2563 (color function exists but uses different logic)
**Current Issue**: Dungeon view uses different color calculation than player keystone cards

**Approach**: 
- Analyze color logic in `FormatColoredTotalScore()` (lines 2614-2654)
- Compare with player keystone card color logic in `FormatPlayerNameWithScore()` (lines 1105-1154)
- Unify color gradient calculation between both views
- Ensure same color scaling and ranges are used

**Expected Time**: 30-60 minutes
**Success Criteria**: Dungeon view IO colors match player keystone card gradients exactly

---

### 3. Fix Hearthstone Selector Icon Loading ⭐⭐

**Problem**: Question marks appear instead of proper icons on first open
**Impact**: First impression quality and user confidence
**Location**: `ui/hearthstoneSelector.lua` (icon loading sequence)
**Current Workaround**: Close/reopen window or press select button in options

**Root Cause Analysis**:
- Icon textures not preloaded or cached properly
- Loading sequence race condition with UI initialization
- Missing error handling for failed icon loads

**Approach**:
1. Implement icon preloading system
2. Add proper error handling and fallback mechanisms
3. Ensure icon loading completes before window display
4. Add loading indicators if necessary

**Expected Time**: 1-2 hours
**Success Criteria**: No question marks on first open, all icons display correctly immediately

---

## 🎨 Phase 2: Quick UI Wins (After Phase 1)

### 4. Improve Card Button Layout ⭐

**Problem**: Button arrangement could be more integrated and visually appealing
**Current State**: Looking decent but could be improved
**Options Identified**:
- Center line of buttons for better visual balance
- Stack +/- on top of Teleport/Loot buttons to save space
- Improve spacing and alignment

**Files Involved**:
- `ui/main.lua` - Keystone card button layout (lines 1745-1819)
- `ui/main.lua` - Dungeon card button layout (lines 2386-2441)

**Approach**:
- Analyze current button positioning logic
- Test different layout options
- Ensure responsive behavior in different view modes
- Maintain functionality while improving aesthetics

**Expected Time**: 1-2 hours
**Success Criteria**: More integrated button appearance with better visual flow

---

### 5. Add More Fake Player Varieties ⭐

**Problem**: Limited testing variety with only high-skill fake players
**Current Tiers**: Expert/Skilled/Competent
**Missing**: Below average, novice, beginner tiers for comprehensive testing

**Location**: `core/fakePlayerService.lua`
**Current Distribution**: Only high-skill presets available

**Approach**:
1. Design lower-skill fake player profiles
2. Add new tiers to dropdown selection
3. Include new varieties in random generation
4. Ensure realistic IO score distributions for each tier

**New Tiers to Add**:
- Below Average (200-400 IO)
- Novice (100-200 IO)
- Beginner (50-100 IO)

**Expected Time**: 1 hour
**Success Criteria**: Full spectrum of skill levels available for testing

---

## 🏗️ Phase 3: Major Feature Implementation

### 6. Implement Proper Loot Window ⭐⭐⭐

**Problem**: Currently shows "coming soon" with a basic button
**Requirements**: Full-featured loot tracking window similar to hearthstone selector

**Detailed Requirements**:
- Hearthstone-selector-like UI using same component patterns
- Display list of available items from current dungeon
- Custom item input by item ID (users look up on Wowhead)
- Support multiple custom items per player
- Default items: unremovable (protected flag)
- Custom items: removable with red X button
- Generic data structure (no hardcoded item lists)

**Location**: `ui/lootWindow.lua`
**Reference Implementation**: `ui/hearthstoneSelector.lua` (component patterns)

**Development Approach**:
1. Analyze hearthstone selector component structure
2. Design generic item data structure
3. Implement item list with default/custom separation
4. Add custom item input dialog
5. Integrate with existing component factory system

**Expected Time**: 4-6 hours
**Success Criteria**: Fully functional loot window with custom item support

---

## 💡 Recommended Starting Point

### Start with IO Tooltips - Here's Why:

1. **System Already Implemented**: The tooltip system exists in `core/tooltip.lua` and functions work in `ui/main.lua`
2. **Critical User Impact**: This is the most important missing feature for decision-making
3. **Likely Quick Fix**: Probably just event handler attachment issues from UI refactor
4. **Immediate Value**: Success here dramatically improves core addon functionality
5. **Foundation for Other Fixes**: Understanding tooltip attachment helps with other UI issues

### Quick First Steps:

1. **Enable Debug Mode**: `/nk config` → Debug System → Enable "tooltip" category at DEV level
2. **Test Current Behavior**: Hover over IO gain areas and note what happens (or doesn't happen)
3. **Check Debug Output**: Look for tooltip-related debug messages
4. **Investigate Event Handlers**: Check if `OnEnter` events are properly attached to IO display elements

---

## 🔧 Development Environment Setup

### Debug Commands for This Phase:

```bash
# Enable comprehensive debugging
/nk config
# → Debug System → Set level to DEV
# → Enable all relevant categories (tooltip, ui, components, ioc)

# Test component system
/nk components test

# Generate test data
/nk test preset mixed_skill

# Run validation
/script NextKeyRunTests()
```

### Key Files to Monitor:

- `ui/main.lua` - Main UI logic and tooltip attachment
- `ui/components.lua` - Component factory and tooltip integration
- `core/tooltip.lua` - Centralized tooltip system
- `core/debugService.lua` - Debug output (check for tooltip category)

---

## 📊 Success Metrics for Phase 1

### Quantitative Metrics:
- **IO Tooltips**: 100% functionality restoration - tooltips appear on hover with correct data
- **Color Consistency**: 0 color mismatch between dungeon and keystone views
- **Icon Loading**: 0 question marks on first window open

### Qualitative Metrics:
- **User Decision Making**: Players can make informed key selection choices
- **Visual Professionalism**: Consistent color schemes throughout UI
- **First Impression Quality**: Polished appearance from initial interaction

### Performance Metrics:
- **Response Time**: <100ms tooltip appearance on hover
- **Memory Usage**: No increase in baseline memory usage
- **Error Rate**: Zero Lua errors in debug output

---

## 🔄 Iterative Development Process

### Phase 1 Workflow:
1. **Fix IO Tooltips** → Test → Validate
2. **Fix Dungeon Colors** → Test → Validate  
3. **Fix Icon Loading** → Test → Validate
4. **Integration Testing** → Cross-feature validation
5. **Performance Testing** → Ensure no regressions

### Testing Strategy:
- **Unit Testing**: Individual component functionality
- **Integration Testing**: Component interaction validation
- **User Testing**: Real-world usage scenarios
- **Performance Testing**: Memory and response time validation

---

## 📝 Documentation Updates

As each phase is completed:
1. Update `CURRENT_STATUS_REQUIREMENTS.md` with completed items
2. Update memory bank status files
3. Document any architectural changes
4. Update success metrics and lessons learned

---

## 🚀 Next Steps After Phase 1

Once Phase 1 is complete and validated:
1. **Begin Phase 2**: UI polish and improvements
2. **Start Phase 3 Planning**: Detailed loot window implementation
3. **Long-term Roadmap**: Complex group suggestion system design
4. **Performance Optimization**: Ensure all fixes maintain performance standards

---

**Prepared by**: NextKey Development Team
**Last Updated**: October 19, 2025
**Next Review**: After Phase 1 completion