# NextKey Debug System Enhancement Design

## Overview

This document outlines the design for a comprehensive debug system enhancement that consolidates and professionalizes debug outputs while providing an intuitive in-game interface for granular control over all debug settings.

## Current State Analysis

### Existing Debug System
- **5-level debug system**: NONE (0), ERROR (1), USER (2), DEV (3), TRACE (4)
- **Category-based filtering**: 20+ debug categories (keystones, communications, ui, etc.)
- **Slash command interface**: `/nk debug <subcommand>` for all control
- **Chat output**: All debug messages go to chat frame
- **Settings persistence**: Saved in `db.global.debug` structure

### Pain Points
1. **Fragmented interface**: Debug settings scattered across slash commands with no visual feedback
2. **No bulk operations**: Cannot enable/disable multiple categories at once
3. **Limited output control**: No formatting options, timestamps, or filtering
4. **No presets**: No way to quickly switch between common debug configurations
5. **No monitoring**: No statistics or performance tracking for debug system itself

## Enhanced Debug System Design

### 1. Unified Debug Configuration UI

#### Integration Points
- **Primary Access**: Integrated into main options interface (`/nk config`)
- **Quick Access**: Dedicated debug window accessible via `/nk debug` (opens directly to debug tab)
- **Slash Commands**: All existing slash commands maintained for power users

#### UI Structure
```
NextKey Options
├── General Settings
├── Group Composition Preferences  
├── Teleport Window
├── Debug System (NEW)
│   ├── Debug Control Panel
│   ├── Output Formatting
│   ├── Debug Presets
│   ├── Statistics & Monitoring
│   └── Advanced Options
└── [Other existing sections]
```

### 2. Debug Control Panel

#### Visual Layout
- **Master Debug Toggle**: Large toggle to enable/disable entire debug system
- **Debug Level Selector**: Visual dropdown showing current level with color coding
- **Category Groups**: Organized by functionality with expand/collapse functionality

#### Category Grouping
```
Core Systems
├── Startup & Initialization
├── Event Handling
├── Performance Monitoring
└── Database Operations

Communications
├── Addon Communications
├── LibOpenRaid Integration
└── RaiderIO Integration

Features & UI
├── Keystone Processing
├── UI Rendering
├── Teleport System
└── Group Suggestions

Testing & Development
├── Fake Player Service
├── IO Calculator
├── Debug System (meta-debug)
└── Test Framework
```

#### Group Controls
- **Group Enable/Disable**: Toggle entire category group on/off
- **Individual Toggles**: Fine-grained control over each category
- **Visual Status**: Color-coded indicators (green=enabled, yellow=partial, gray=disabled)
- **Category Counters**: Show number of active categories per group

### 3. Debug Level Management

#### Visual Level Indicator
- **Color-coded display**: 
  - NONE: Gray
  - ERROR: Red
  - USER: Green
  - DEV: Yellow
  - TRACE: Blue
- **Level descriptions**: Clear explanations of what each level includes
- **Dynamic filtering**: Category checkboxes automatically enable/disable based on selected level

#### Level-Category Relationship
- **ERROR**: Always shown (cannot be disabled)
- **USER**: Shown in production (categories don't affect this level)
- **DEV**: Requires category enablement
- **TRACE**: Requires category enablement + most verbose output

### 4. Output Formatting Options

#### Message Formatting
- **Timestamps**: Toggle timestamps on debug messages
- **Source Location**: Show file/line number for debug calls
- **Category Prefixes**: Color-coded category tags in messages
- **Stack Traces**: Toggle detailed stack traces for errors

#### Chat Filtering
- **Output Destination**: Chat frame vs. dedicated debug chat frame
- **Message Types**: Filter by level, category, or text content
- **Throttling**: Rate limiting to prevent chat spam
- **History**: Optional debug log window with search/filter

### 5. Debug Presets System

#### Preset Configurations
```
Development Presets:
├── Minimal (ERROR only)
├── Standard (ERROR + USER)
├── Verbose (ERROR + USER + DEV)
└── Full (ERROR + USER + DEV + TRACE)

Testing Presets:
├── Fake Player Testing
├── Communications Testing
├── Performance Testing
└── UI Testing

Production Presets:
├── Release Mode (ERROR only)
└── Support Mode (ERROR + USER)
```

#### Preset Management
- **Quick Apply**: One-click preset application
- **Custom Presets**: Save/load user-defined configurations
- **Preset Sharing**: Export/import preset configurations
- **Reset to Default**: Return to baseline configuration

### 6. Statistics & Monitoring

#### Debug Metrics
- **Message Counters**: Track messages per level and category
- **Performance Impact**: CPU time usage by debug system
- **Memory Usage**: Track memory allocation for debug operations
- **Error Tracking**: Count and categorize error occurrences

#### Visual Feedback
- **Real-time Indicators**: Live status display in debug UI
- **Performance Graphs**: Simple charts showing debug overhead over time
- **Health Status**: Overall debug system health indicator

### 7. Advanced Options

#### Meta-Debug
- **Debug the Debugger**: Enable debug output for debug system itself
- **Startup Profiling**: Track debug system initialization performance
- **Category Performance**: Per-category performance metrics

#### Integration Options
- **External Tools**: Export debug data to external analysis tools
- **API Access**: Programmatic interface for other addons
- **Compatibility Mode**: Ensure compatibility with other debug tools

## Implementation Plan

### Phase 1: Core UI Framework
1. **Extend options/main.lua** with debug section
2. **Create debug UI module** with AceGUI widgets
3. **Integrate with existing options system**
4. **Maintain backward compatibility** with slash commands

### Phase 2: Category Management
1. **Implement grouped category controls**
2. **Add bulk enable/disable operations**
3. **Create visual status indicators**
4. **Add category search/filter functionality**

### Phase 3: Output Enhancement
1. **Implement formatting options**
2. **Add chat filtering system**
3. **Create debug log window**
4. **Add export functionality**

### Phase 4: Presets & Statistics
1. **Implement preset system**
2. **Add statistics tracking**
3. **Create performance monitoring**
4. **Add import/export features**

## Technical Considerations

### Performance
- **Lazy Loading**: Load debug UI only when accessed
- **Efficient Updates**: Minimize options refresh operations
- **Memory Management**: Proper cleanup of debug resources

### Compatibility
- **Ace3 Integration**: Full compatibility with AceConfig/AceGUI
- **Existing API**: Maintain all current debug service functions
- **Slash Commands**: Preserve existing command interface

### User Experience
- **Intuitive Layout**: Logical grouping and clear visual hierarchy
- **Immediate Feedback**: Visual confirmation of setting changes
- **Accessibility**: Clear labeling and keyboard navigation support

## Migration Strategy

### Backward Compatibility
- **Gradual Migration**: Keep existing slash commands working
- **Settings Migration**: Automatically convert old settings to new format
- **Fallback Support**: Graceful handling of missing/corrupted settings

### Rollout Plan
1. **Beta Release**: New debug system alongside existing one
2. **Testing Period**: Gather feedback from power users
3. **Transition Phase**: Migrate users to new system
4. **Full Release**: Replace old debug system completely

## Success Metrics

### Usability Goals
- **Reduced Clicks**: Enable common operations with fewer clicks
- **Faster Configuration**: Quick access to frequently used settings
- **Clearer Status**: Immediate visual feedback on debug state
- **Better Organization**: Logical grouping of related settings

### Technical Goals
- **Centralized Control**: Single interface for all debug settings
- **Enhanced Monitoring**: Better visibility into debug system performance
- **Improved Maintainability**: Cleaner, more organized code structure
- **Future-Proof Design**: Extensible architecture for new debug features

## Conclusion

This enhanced debug system will transform the current fragmented debug experience into a professional, centralized interface that provides both power users and casual users with appropriate levels of control. The design maintains backward compatibility while significantly improving the user experience through better organization, visual feedback, and advanced features like presets and monitoring.

The modular approach allows for incremental implementation and testing, ensuring a smooth transition from the current system to the enhanced one without disrupting existing functionality.