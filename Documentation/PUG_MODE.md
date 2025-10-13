# NextKey PUG Mode Implementation

## Overview

PUG Mode is an automatic feature in NextKey that assists with the LFG (Pick Up Group) workflow for Mythic+ dungeons. Unlike traditional "modes", PUG Mode activates automatically when using the LFG tool and provides contextual assistance throughout the entire PUG experience.

## Key Features

### 1. Application Tracking
- Automatically tracks LFG applications when you apply to groups
- Caches group information including dungeon, key level, and leader details
- Monitors application status changes (accepted, declined, cancelled)

### 2. Contextual Invite Notifications
- Enhanced invite notifications when receiving invites from tracked applications
- Shows dungeon name, key level, and group information
- Provides accept/decline buttons with timeout handling
- Optional auto-accept for trusted groups

### 3. Travel Assistant
- Automatically appears when joining a PUG group
- Provides one-click access to dungeon teleports
- Shows hearthstone status and cooldown
- Includes summon request functionality with cooldown management
- Displays relevant travel options based on current location

### 4. Post-Run Getaway UI
- Appears after completing Mythic+ dungeons with PUG groups
- Quick exit options: hearthstone, leave group, exit dungeon
- Shows completion summary with dungeon and key level
- Auto-dismisses after 2 minutes

## Architecture

### State Machine
PUG Helper operates on a 5-state machine:
- **IDLE**: Not tracking any LFG activity
- **TRACKING**: Applied to groups, monitoring applications
- **INVITE_RECEIVED**: Received invite, showing notification
- **IN_GROUP**: Joined group, providing travel assistance
- **RUN_COMPLETE**: Dungeon completed, providing getaway options

### Event Flow
```
LFG Application → Tracking → Invite Received → In Group → Run Complete → Idle
```

### Module Structure
```
core/
├── pugHelper.lua              # Core logic and state management
ui/
├── pugInviteNotification.lua  # Invite notification UI
├── pugTravelAssistant.lua    # Travel assistance UI
└── pugGetawayUI.lua          # Post-run getaway UI
```

## Configuration

PUG Helper settings are available in `/nk config` under the "PUG Helper" section:

### General Settings
- **Enable PUG Helper**: Master toggle for all PUG features
- **Show Invite Notifications**: Display enhanced invite notifications
- **Auto-Accept Invites**: Automatically accept invites from tracked applications
- **Travel Assistant**: Show travel assistance when joining groups
- **Post-Run Getaway UI**: Show quick exit options after dungeon completion

## Usage

### Automatic Operation
PUG Helper works automatically in the background:
1. Apply to LFG groups as normal
2. Receive enhanced invite notifications when invited
3. Get travel assistance when joining groups
4. Use getaway UI after completing dungeons

### Manual Control
Use slash commands for manual control:
```
/nk pug status      - Show PUG Helper status
/nk pug enable      - Enable PUG Helper
/nk pug disable     - Disable PUG Helper
/nk pug reset       - Reset PUG Helper state
/nk pug test        - Test application tracking
/nk pug simulate    - Simulate workflow steps
```

### Testing and Debugging
For development and testing:
```
/nk pug test        - Create test application
/nk pug simulate invite - Simulate receiving invite
/nk pug simulate join   - Simulate joining group
/nk pug simulate complete - Simulate dungeon completion
/nk debug category pughelper - Enable PUG debug logging
```

## Technical Implementation

### Event Integration
PUG Helper integrates with the existing event system:
- Events registered in `events/handlers.lua`
- Forwarded to PUG Helper module for processing
- Follows NextKey architecture patterns

### Data Storage
Configuration stored in `NextKeyDB.global.pugHelper`:
```lua
{
    enabled = true,
    autoAcceptInvites = false,
    showNotifications = true,
    travelAssistant = true,
    getawayUI = true
}
```

### UI Components
All UI components follow NextKey patterns:
- AceGUI-3.0 widget system
- Movable frames with backdrop styling
- Proper cleanup and memory management
- Integration with debug system

## Performance Considerations

### Memory Management
- Application cache cleared when not needed
- Timers properly cancelled on state changes
- UI components created on-demand and cleaned up

### Event Throttling
- Application list updates processed efficiently
- No blocking operations during combat
- Minimal impact on game performance

### Error Handling
- All operations wrapped in SafeRun() calls
- Graceful degradation when data unavailable
- Comprehensive debug logging

## Troubleshooting

### Common Issues

#### PUG Helper Not Working
1. Check if enabled: `/nk pug status`
2. Enable debug: `/nk debug category pughelper`
3. Test with: `/nk pug test`
4. Reload UI: `/reload`

#### Invite Notifications Not Showing
1. Check setting: `/nk config` → PUG Helper → Show Invite Notifications
2. Verify you're applying to LFG groups
3. Check debug logs for errors

#### Travel Assistant Not Appearing
1. Check setting: `/nk config` → PUG Helper → Travel Assistant
2. Verify you joined a group from a tracked application
3. Check if PUG Helper is in IN_GROUP state: `/nk pug status`

#### Getaway UI Not Showing
1. Check setting: `/nk config` → PUG Helper → Post-Run Getaway UI
2. Verify you completed a Mythic+ dungeon
3. Check if PUG Helper is in RUN_COMPLETE state: `/nk pug status`

### Debug Commands
Enable detailed debugging:
```
/nk debug level 4                    # Enable TRACE level
/nk debug category pughelper          # Enable PUG Helper category
/nk pug test                         # Test functionality
```

## Development Notes

### Adding New Features
1. Add functionality to appropriate state in `core/pugHelper.lua`
2. Update configuration in `options/main.lua`
3. Add debug capabilities in `core/slashCommands.lua`
4. Test with simulation commands

### Testing Workflow
1. Use `/nk pug test` to create test application
2. Use `/nk pug simulate` to test workflow steps
3. Check state transitions with `/nk pug status`
4. Monitor debug output with pughelper category

### Code Patterns
- Follow NextKey module registration pattern
- Use SafeRun() for all critical operations
- Use Debug:Dev() for development logging
- Implement proper cleanup in all UI components

## Future Enhancements

### Planned Features
- Guild keystone coordination
- Historical PUG performance tracking
- Advanced group composition analysis
- Integration with more external addons

### Extension Points
- Additional travel options (flight paths, portals)
- Enhanced group matching algorithms
- Performance analytics and reporting
- Mobile companion app integration

## Conclusion

PUG Mode transforms the LFG experience from manual coordination into automatic, intelligent assistance. By tracking applications, providing contextual notifications, and offering travel assistance, it streamlines the entire PUG workflow while maintaining the flexibility and control that players expect.

The implementation follows NextKey's architectural patterns, ensuring reliability, performance, and maintainability while providing a seamless user experience that enhances rather than interrupts gameplay.