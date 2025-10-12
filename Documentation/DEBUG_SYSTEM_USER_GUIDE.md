# NextKey Debug System - User Guide

## Overview

The NextKey Debug System is a comprehensive, professional debugging interface that provides granular control over debug output, performance monitoring, and advanced filtering capabilities. It replaces basic slash commands with a full-featured UI accessible through the addon options panel.

## Accessing the Debug System

1. Open the addon options: `/nk config` or Escape → Interface → Addons → NextKey
2. Navigate to the "Debug System" tab
3. All debug controls are organized into intuitive sections

## Debug Levels

The debug system uses 5 levels of verbosity:

| Level | Name | Description | When Shown |
|-------|------|-------------|------------|
| 0 | NONE | Silent mode | Never (production) |
| 1 | ERROR | Critical errors only | Always |
| 2 | USER | User-facing messages | Release & Debug |
| 3 | DEV | Development messages | Debug only |
| 4 | TRACE | Ultra-verbose tracing | Debug only |

## Category Groups

Debug categories are organized into 5 logical groups:

### Core Systems
- **Startup & Initialization**: Addon loading and startup events
- **Event Handling**: Event registration and processing
- **Performance Monitoring**: Performance tracking and metrics
- **Database Operations**: SavedVariables and data persistence
- **Configuration Management**: Settings loading and validation
- **Options Interface**: Options panel rendering

### Communications
- **Core Communications**: Main communication system
- **Communication Protocols**: Low-level message handling
- **LibOpenRaid Integration**: LibOpenRaid API interactions
- **RaiderIO Integration**: RaiderIO data fetching
- **Blizzard API Integration**: Blizzard API calls

### Features & UI
- **Main UI**: Primary user interface
- **UI Components**: Reusable UI components
- **Tooltip System**: Tooltip creation and positioning
- **Teleport System**: Teleport functionality
- **Loot Tracking**: Loot window and item tracking
- **Profile Management**: Player profile creation

### Data Processing
- **Keystone Processing**: Keystone data collection
- **Seasonal Data**: Season information and dungeons
- **IO Score Calculator**: Score calculation algorithms
- **IO Calculation Operations**: Detailed calculation steps
- **Fake Player Service**: Testing data simulation

### Testing & Development
- **Testing Utilities**: General testing tools
- **Meta-Debug**: Debug system self-monitoring

## Debug Presets

Quickly apply common debug configurations:

- **Minimal**: Errors only
- **Standard**: Errors and user messages
- **Verbose**: Errors, user, and development messages
- **Full**: All message types
- **UI Testing**: Focus on interface debugging
- **Communications Testing**: Focus on network debugging
- **Performance Testing**: Focus on performance monitoring

## Performance Monitoring

Track execution time and identify bottlenecks:

### Features
- **Real-time Performance Tracking**: Monitor operation execution times
- **Configurable Thresholds**: Set warning and critical performance levels
- **Slowest Operations List**: Identify the most time-consuming operations
- **Category Breakdown**: See performance by debug category
- **Historical Data**: Track performance over time

### Usage
1. Enable "Performance Monitoring" in the Statistics & Monitoring section
2. Configure warning and critical thresholds
3. Use the addon normally - performance data is collected automatically
4. Review "Slowest Operations" and "Performance by Category" for insights

## Advanced Filtering

Sophisticated message filtering capabilities:

### Pattern Filters
- **Text Match**: Case-insensitive text matching
- **Regular Expressions**: Powerful pattern matching
- **Wildcard**: Simple wildcard patterns with `*`

### Time Range Filtering
- Filter messages to specific time periods
- Useful for focusing on recent activity or specific events

### Level & Category Filters
- Exclude specific debug levels from output
- Filter out noisy categories while keeping others

### Usage
1. Enable "Advanced Filtering" in Output Options
2. Add pattern filters for messages you want to exclude
3. Configure time ranges if needed
4. Set level and category filters as desired

## Output Formatting Options

Customize how debug messages appear:

### Message Formatting
- **Show Timestamps**: Add timing information to messages
- **Show Source Location**: Include file and line numbers
- **Show Stack Traces**: Detailed error information
- **Enhanced Color Coding**: Better visual distinction

### Output Destination
- **Chat Frame**: Standard chat output
- **Dedicated Debug Frame**: Separate debug window
- **Both**: Show in both locations

### Message Throttling
- Limit messages per second to reduce spam
- Set 0 for no limit

## Statistics & Monitoring

### Current Statistics
- Total message counts by level
- Enabled categories count
- Memory usage
- Uptime
- Performance metrics

### Performance Metrics
- Filter efficiency (how many messages are filtered out)
- Cache efficiency (message formatting cache performance)
- Messages per minute
- Memory per message

### Optimization Tools
- **Memory Usage Breakdown**: See what's using memory
- **Perform Maintenance**: Clean up caches and optimize memory
- **Optimize for Production**: Disable all debug features for minimal impact

## Keyboard Shortcuts and Commands

### Slash Commands
- `/nk config` - Open options panel
- `/nk debug` - Toggle debug mode (legacy)
- `/nk debug level <0-4>` - Set debug level (legacy)

### Testing
- `/script NextKeyRunTests()` - Run comprehensive test suite

## Best Practices

### Development
1. Use appropriate debug levels for different types of messages
2. Organize debug output into logical categories
3. Use performance monitoring to identify bottlenecks
4. Filter out noisy messages during development

### Production
1. Use "Optimize for Production" before release
2. Keep only ERROR and USER levels enabled
3. Disable performance monitoring and advanced filtering
4. Regular maintenance to prevent memory leaks

### Troubleshooting
1. Enable relevant categories for the issue you're investigating
2. Use preset configurations for common scenarios
3. Check performance monitoring for slow operations
4. Use filtering to focus on specific messages

## Integration with Other Systems

### SavedVariables
All debug settings are automatically saved and restored between sessions.

### Performance Impact
- Zero-cost no-ops when DEV_MODE is false
- Efficient caching for message formatting
- Configurable limits for history and buffer sizes
- Automatic cleanup to prevent memory leaks

### API Integration
The debug system integrates with:
- AceConfig for UI management
- Blizzard API for performance timing
- SavedVariables for persistence
- Chat system for output

## Troubleshooting

### Common Issues

**Debug messages not appearing:**
1. Check if debug mode is enabled
2. Verify debug level is high enough
3. Ensure relevant categories are enabled
4. Check if advanced filtering is blocking messages

**Performance impact:**
1. Use "Optimize for Production" button
2. Disable performance monitoring
3. Reduce history and buffer sizes
4. Perform maintenance cleanup

**UI not refreshing:**
1. Reload UI with `/reload`
2. Check for Lua errors
3. Ensure all modules loaded correctly

### Getting Help

1. Run the test suite: `/script NextKeyRunTests()`
2. Check debug statistics for issues
3. Export statistics for analysis
4. Review filtering patterns if messages are missing

## Advanced Usage

### Custom Presets
Create your own debug configurations:
1. Set up your desired debug state
2. Use "Save Current Configuration" in presets
3. Name your preset for future use

### Exporting Data
Export debug data for analysis:
- Statistics export for performance analysis
- Performance data export for optimization
- Filtering data export for message analysis

### Automation
Use the debug API in your code:
```lua
-- Performance monitoring
local timer = Debug:StartPerformanceTimer("operation", "category")
-- ... your code ...
local result = Debug:EndPerformanceTimer(timer)

-- Advanced filtering
Debug:AddFilterPattern("noise", "spam", "text", true)

-- Custom debug output
Debug:Dev("category", "Custom message: %s", value)
```

This comprehensive debug system provides professional-grade debugging capabilities while maintaining excellent performance and ease of use.