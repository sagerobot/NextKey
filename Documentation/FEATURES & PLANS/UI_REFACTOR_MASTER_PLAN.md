# NextKey UI Refactoring Master Plan
**Version:** 2.0  
**Status:** Draft - Planning Phase  
**Created:** 2025-10-16

---

## Executive Summary

This master plan addresses the **Duplicated UI Logic** refactoring identified in [`REFACTOR_SUGGESTIONS.md`](REFACTOR_SUGGESTIONS.md:6-21). The goal is to consolidate UI component creation across NextKey into a unified, maintainable system that maximizes Ace3 library usage while creating minimal custom factory code for configuration consistency.

### Current State Analysis

**UI Creation Patterns Found:**
- **117 instances** of frame/widget creation across 7 UI files
- **40+ SetBackdrop calls** with duplicated configuration
- **Mixed paradigms:** AceGUI-3.0 (30+ calls) vs native CreateFrame (80+ calls)
- **Partial component system:** [`ui/components.lua`](../../ui/components.lua) exists but creates native frames

**Key Insight:**
Ace3 already provides comprehensive widget creation. We don't need to recreate widgets - we just need to create standardized configuration wrappers that apply consistent styling and behavior to AceGUI widgets.

---

## Strategic Goals

1. **Maximize Ace3 Usage:** Leverage existing AceGUI widgets instead of recreating them
2. **Standardize Configuration:** Create lightweight configuration wrappers for consistent styling
3. **Reduce Code Duplication:** Consolidate repeated configuration patterns into reusable functions
4. **Improve Maintainability:** Make UI changes in configuration, not in widget creation
5. **Enhance Consistency:** Ensure uniform look and feel through standardized configuration

---

## Refactoring Phases

### Phase 1: Foundation & Analysis
**Goal:** Establish the groundwork for maximizing Ace3 usage

#### Objectives:
- Audit all UI creation patterns and document current Ace3 usage
- Identify all configuration patterns that need standardization
- Map which AceGUI widgets can replace native frames
- Create comprehensive test coverage for existing UI behavior
- Design minimal configuration wrapper system

#### Key Deliverables:
- UI Pattern Inventory focused on Ace3 opportunities
- Configuration Pattern Catalog (backdrops, colors, sizes, etc.)
- Test Suite for UI behavior
- Configuration Wrapper API Design

#### Success Criteria:
- Complete inventory of Ace3 migration opportunities
- All repeated configuration patterns documented
- Zero functional regressions from baseline

---

### Phase 2: Ace3 Configuration Wrapper System
**Goal:** Create minimal wrappers for Ace3 widget configuration

#### Objectives:
- Create configuration wrapper for AceGUI backdrops (using BackdropTemplate)
- Create button configuration wrapper for consistent button styling
- Create text/label configuration wrapper for consistent typography
- Create frame configuration wrapper for consistent frame properties
- Create icon configuration wrapper for consistent icon display

#### Key Deliverables:
- `Components:ConfigureBackdrop(widget, type)` - Applies standard backdrop to AceGUI widgets
- `Components:ConfigureButton(widget, type)` - Applies standard button styling
- `Components:ConfigureText(widget, type)` - Applies standard text styling
- `Components:ConfigureFrame(widget, type)` - Applies standard frame properties
- `Components:ConfigureIcon(widget, type)` - Applies standard icon styling
- Configuration documentation and examples

#### Success Criteria:
- All repeated configurations available through wrappers
- Configuration wrappers work with native AceGUI widgets
- Component API covers 90%+ of current UI configuration needs
- Documentation with code examples for each wrapper function

---

### Phase 3: Main Window Migration to Pure Ace3
**Goal:** Refactor [`ui/main.lua`](../../ui/main.lua) to use pure Ace3 with configuration wrappers

#### Objectives:
- Replace all native CreateFrame calls with appropriate AceGUI widgets
- Apply configuration wrappers to all AceGUI widgets for consistency
- Migrate complex UI patterns to AceGUI equivalents
- Maintain existing functionality and appearance
- Establish Ace3 usage patterns for remaining UI files

#### Key Deliverables:
- Refactored `ui/main.lua` using 100% AceGUI widgets
- All widgets using configuration wrappers for consistency
- Regression testing to verify no visual or functional changes
- Updated inline documentation
- Ace3 usage guidelines document

#### Success Criteria:
- No visual regressions in main window appearance
- All automated tests pass
- Code reduction of 200+ lines through Ace3 usage
- All UI elements using AceGUI widgets with configuration wrappers

---

### Phase 4: Secondary UI Migration to Pure Ace3
**Goal:** Refactor remaining UI files to use pure Ace3 with configuration wrappers

#### Scope:
- [`ui/teleport.lua`](../../ui/teleport.lua) - Teleport window and buttons
- [`ui/lootWindow.lua`](../../ui/lootWindow.lua) - Loot tracking interface
- [`ui/dungeonCards.lua`](../../ui/dungeonCards.lua) - Card-based dungeon display

#### Objectives:
- Replace all native CreateFrame calls with AceGUI widgets
- Apply configuration wrappers for consistent styling
- Handle special cases that may need hybrid approach
- Ensure consistent styling across all windows

#### Key Deliverables:
- Refactored teleport.lua using AceGUI widgets
- Refactored lootWindow.lua using AceGUI widgets
- Refactored dungeonCards.lua using AceGUI widgets
- Visual regression tests for each refactored file
- Performance benchmarks (ensure no degradation)

#### Success Criteria:
- All secondary UIs use AceGUI widgets with configuration wrappers
- Visual parity with pre-refactor versions
- Code reduction of 150+ lines across three files
- Performance maintained or improved

---

### Phase 5: PUG Mode UI Migration to Pure Ace3
**Goal:** Refactor PUG Mode UI components to use pure Ace3 with configuration wrappers

#### Scope:
- [`ui/pugInviteNotification.lua`](../../ui/pugInviteNotification.lua)
- [`ui/pugGetawayUI.lua`](../../ui/pugGetawayUI.lua)
- [`ui/pugApplicationTracker.lua`](../../ui/pugApplicationTracker.lua)

#### Objectives:
- Replace all native CreateFrame calls with AceGUI widgets
- Apply configuration wrappers for consistent styling
- Remove fallback backdrop code by ensuring component availability
- Consolidate all UI patterns to Ace3

#### Key Deliverables:
- Refactored pugInviteNotification.lua with Ace3 usage
- Refactored pugGetawayUI.lua with Ace3 usage
- Refactored pugApplicationTracker.lua with Ace3 usage
- PUG Mode test suite validating all workflows
- Documentation updates for Ace3 usage patterns

#### Success Criteria:
- All PUG Mode UIs use AceGUI widgets exclusively
- Removal of fallback native frame code (100% Ace3 adoption)
- Code reduction of 100+ lines across three files
- PUG Mode workflows fully functional and tested

---

### Phase 6: Ace3 Best Practices Documentation
**Goal:** Document Ace3 usage patterns and best practices

#### Objectives:
- Document when to use which AceGUI widgets
- Create configuration wrapper usage guidelines
- Establish coding standards for Ace3 development
- Update developer documentation with best practices
- Create migration guide for future UI components

#### Key Deliverables:
- Ace3 Widget Selection Guidelines document
- Configuration Wrapper Usage Guide
- Code style guide for Ace3 development
- Migration guide for future UI components
- Updated architecture documentation
- Developer onboarding materials

#### Success Criteria:
- Clear decision tree for widget selection
- All existing code follows established patterns
- Documentation comprehensive enough for new contributors
- No ambiguity in UI development approach

---

### Phase 7: Advanced Configuration Features
**Goal:** Add advanced capabilities to configuration wrapper system with focus on static customization

#### Objectives:
- Implement dynamic configuration based on context (debug mode, view type, party size)
- Create advanced tooltip configuration system for consistency
- Implement basic theme/styling system for easy customization (dark, light, high contrast)
- Add UI scale settings for user-adjustable sizing
- Add responsive layout support through configuration

#### Key Deliverables:
- Dynamic configuration system for contextual UI (enhanced debug/keystone controls)
- Enhanced tooltip configuration system with standardized styling
- Basic theme configuration system with 3-4 color schemes
- UI scale configuration system for user-adjustable sizing
- Responsive layout configuration utilities
- Performance optimization for complex UIs

#### Success Criteria:
- Dynamic configuration reduces conditional code by 30%
- Consistent tooltip behavior across all UIs
- Theme changes propagate automatically across all elements
- UI scales properly based on user preferences (0.8x to 1.5x)
- Context-aware UI elements show/hide appropriately

---

---

## Conclusion

The UI refactoring will be completed after Phase 7, which provides all the necessary functionality for a modern, maintainable UI system. The simplified approach focuses on practical features that improve user experience without unnecessary complexity.

---

## Risk Assessment

### High Risk Areas:
1. **Ace3 Widget Limitations** - Some native frame features may not have AceGUI equivalents
2. **Visual Regression** - Changes could inadvertently alter appearance
3. **Performance Impact** - Configuration wrapper overhead could affect frame rate
4. **Breaking Changes** - Configuration changes could break dependent code

### Mitigation Strategies:
1. **Hybrid Approach** - Keep native frames where AceGUI limitations exist
2. **Comprehensive Testing** - Test suite catches regressions before release
3. **Performance Monitoring** - Benchmark each phase to track impact
4. **Incremental Migration** - Phase approach allows catching issues early

---

## Success Metrics

### Code Quality Metrics:
- **Ace3 Usage:** Target 95% of UI elements using AceGUI widgets
- **Code Duplication Reduction:** Target 60% reduction in UI configuration boilerplate
- **Lines of Code:** Expect 500-700 line reduction across UI files
- **Cyclomatic Complexity:** Reduce average complexity by 20%
- **Configuration Reusability:** 90%+ of UI styling through configuration wrappers

### Performance Metrics:
- **Memory Usage:** No more than 5% increase
- **Frame Rate:** Maintain <1ms UI overhead per frame
- **Load Time:** UI initialization under 100ms
- **Responsiveness:** All UI actions complete within 50ms

### Quality Metrics:
- **Test Coverage:** 80%+ code coverage for UI components
- **Bug Density:** <0.5 bugs per 1000 lines of code
- **Documentation Coverage:** 100% of public API documented
- **User Satisfaction:** >90% positive feedback on UI responsiveness

---

## Conclusion

The UI refactoring will be completed after Phase 7, which provides all the necessary functionality for a modern, maintainable UI system. The simplified approach focuses on practical features that improve user experience without unnecessary complexity.

---

## Dependencies

### External Dependencies:
- **Ace3 Libraries:** LibStub, AceGUI-3.0, AceConfig-3.0
- **WoW API:** BackdropTemplate for AceGUI widget backdrops
- **Testing Framework:** In-game testing infrastructure (simplified)

### Internal Dependencies:
- **Configuration Wrapper System:** Must be stable before migrations
- **Debug System:** [`core/debugService.lua`](../../core/debugService.lua) for logging during refactor
- **UIConfig:** [`core/uiConfig.lua`](../../core/uiConfig.lua) for layout constants

---

## Next Steps

### Immediate Actions (Phase 1):
1. Read all UI files and document each CreateFrame/AceGUI:Create call
2. Create UI Pattern Inventory focused on Ace3 migration opportunities
3. Catalog all repeated configuration patterns
4. Design configuration wrapper API specification document
5. Set up basic test harness for UI regression testing

### Phase Transition Criteria:
Each phase requires:
- ✅ All deliverables completed and reviewed
- ✅ Success criteria met and documented
- ✅ No critical bugs or regressions
- ✅ Code review and approval
- ✅ Documentation updated

---

## Notes for Future Breakdown

This master plan is intentionally high-level. Each phase should be broken down into:

1. **Individual Tasks:** Specific, actionable work items (2-4 hours each)
2. **Subtasks:** Granular steps within each task (30min - 1 hour each)
3. **Acceptance Criteria:** Clear definition of done for each task
4. **Test Cases:** Specific tests to verify task completion
5. **Review Checklist:** Items to verify before marking task complete

**Example Breakdown Structure:**
```
Phase 2: Configuration Wrapper System
├── Task 2.1: Create Backdrop Configuration Wrapper
│   ├── Subtask 2.1.1: Analyze all backdrop patterns
│   ├── Subtask 2.1.2: Design wrapper API
│   ├── Subtask 2.1.3: Implement wrapper function
│   └── Subtask 2.1.4: Write unit tests
├── Task 2.2: Create Button Configuration Wrapper
│   └── [Similar subtask breakdown]
└── [Additional tasks...]
```

---

## References

- **Original Suggestion:** [`REFACTOR_SUGGESTIONS.md`](REFACTOR_SUGGESTIONS.md:6-21) - Duplicated UI Logic
- **Component System:** [`ui/components.lua`](../../ui/components.lua) - Existing partial implementation
- **Main UI:** [`ui/main.lua`](../../ui/main.lua) - Primary refactor target (3341 lines)
- **Architecture:** [`.kilocode/rules/memory-bank/architecture.md`](../../.kilocode/rules/memory-bank/architecture.md) - Architectural patterns
- **Debug Standards:** [`.kilocode/rules/debug_standards.md`](../../.kilocode/rules/debug_standards.md) - Debugging requirements

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-10-16 | 1.0 | Kilo Code | Initial master plan creation |
| 2025-10-16 | 2.0 | Kilo Code | Updated to focus on maximizing Ace3 usage with minimal factory code |
