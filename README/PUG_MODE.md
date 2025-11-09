# NextKey PUG Mode

## Overview

PUG Mode is an automated workflow assistant for World of Warcraft's Premade Group Finder (LFG) tool. It helps streamline the process of applying to groups, managing invites, traveling to dungeons, and handling post-run activities.

## Features

### Application Tracker (NEW)
- Visual window showing all active LFG applications in real-time
- Displays dungeon alias, key level, group leader, and application status
- Color-coded status indicators (pending=yellow, invited=green, declined=red)
- Time tracking showing how long ago each application was submitted
- Auto-shows when you have active applications (configurable)
- Manual control via slash commands: `/nk pug tracker show/hide/toggle`
- Configurable in Options → PUG Helper → Show Application Tracker (off by default)

### Automated Workflow Tracking
- Tracks your LFG applications with timestamps and status history
- Matches received invites to your tracked applications
- Provides contextual information about dungeon invites including key level and group details
- Automatically detects when you join a group and completes a dungeon run
- Enhanced status tracking (pending, invited, declined, cancelled, failed)

### Contextual Notifications
- **Invite Notifications**: Enhanced invite notifications that show dungeon information, key level, and group comments
- **Travel Assistance**: Automatic travel suggestions when joining a group, including hearthstone status and teleport options
- **Enhanced Detection**: Travel window automatically appears when Blizzard's invite popup shows
- **Getaway UI**: Quick exit options after dungeon completion with hearthstone, leave group, and exit dungeon options

### State Management
- Intelligent state machine with 5 states: IDLE, TRACKING, INVITE_RECEIVED, IN_GROUP, RUN_COMPLETE
- Validates all state transitions to ensure proper workflow progression
- Automatic cleanup of timers and data when transitioning between states

## Configuration

PUG Mode can be configured through the NextKey options panel (`/nk config`):

- **Enable/Disable PUG Mode**: Turn the entire feature on or off
- **Show Application Tracker**: Display the application tracker window (off by default)
- **Auto-Show Tracker**: Automatically show tracker when you have applications
- **Show Notifications**: Control whether contextual invite notifications are displayed
- **Travel Assistant**: Enable/disable travel assistance when joining groups
- **Getaway UI**: Enable/disable the post-run getaway options
- **Auto-Accept Invites**: Automatically accept invites from tracked applications (disabled by default)

## Usage

### Basic Usage

1. **Enable PUG Mode**: Make sure PUG Mode is enabled in the NextKey options
2. **(Optional) Enable Application Tracker**: Check "Show Application Tracker" in PUG Helper options
3. **Apply to Groups**: Use the LFG tool to apply to Mythic+ groups as usual
4. **Application Tracker**: Window will automatically show your active applications with status
5. **Receive Invites**: When you receive an invite that matches a tracked application, you'll see an enhanced notification with dungeon details
6. **Travel Window**: Automatically appears when Blizzard's invite popup shows
7. **Join Group**: Accept the invite to join the group - PUG Mode will detect this and offer travel assistance
8. **Complete Dungeon**: Run the Mythic+ dungeon - PUG Mode will detect completion and show getaway options

### Application Tracker Usage

- **Auto-Show**: Automatically appears when you have active applications
- **Manual Control**: Use `/nk pug tracker show/hide/toggle` for manual control
- **Status Indicators**: Color-coded status for quick visual reference
- **Time Tracking**: Shows elapsed time since application submission
- **Auto-Hide**: Automatically hides when all applications are resolved

### Testing PUG Mode

You can test PUG Mode functionality with these commands:

```
/nk pug test                    -- Test application tracking with a fake application
/nk pug simulate invite         -- Simulate receiving a group invite
/nk pug simulate join           -- Simulate joining a group
/nk pug simulate complete       -- Simulate dungeon completion
/nk pug status                  -- Show current PUG Mode status
/nk pug tracker show            -- Show the application tracker window
/nk pug tracker hide            -- Hide the application tracker window
/nk pug tracker toggle          -- Toggle the application tracker window
```

### Integration Testing

For comprehensive testing of the refactored PUG Mode:

```
/script TestPUGIntegration()          -- Run full integration test suite
/script TestPUGQuick()                 -- Run quick module validation
/script TestPUGApplicationTracker()    -- Run application tracker test suite
```

#### How to Use the Tests

1. **Quick Validation**:
   - Type `/script TestPUGQuick()` in chat
   - This will check if all PUG Mode modules are loaded correctly
   - You should see "All PUG Mode modules loaded successfully!" if everything is working

2. **Full Integration Test**:
   - Type `/script TestPUGIntegration()` in chat
   - This will run 6 comprehensive tests covering:
     - State Management
     - UI Components Integration
     - Teleport System Integration
     - Event Handlers Integration
     - Configuration Management
     - PUG Workflow Simulation
   - Each test will show ✓ PASSED or ✗ FAILED with details if something goes wrong

3. **Manual Testing Commands**:
   - `/nk pug test` - Creates a fake LFG application to test tracking
   - `/nk pug simulate invite` - Simulates receiving a group invite (should show notification)
   - `/nk pug simulate join` - Simulates joining a group (should show travel assistant)
   - `/nk pug simulate complete` - Simulates dungeon completion (should show getaway UI)
   - `/nk pug status` - Shows current PUG Mode state

4. **Debug Mode**:
   - Enable debug mode in `/nk config` → Debug System
   - Set "PUG Helper" category to DEV or TRACE level
   - This will show detailed debug messages for all PUG Mode operations

## Technical Details

### Architecture

PUG Mode has been refactored to integrate with NextKey's existing systems:

- **UI Components**: All PUG UI components now use the standardized UIComponents system for consistent styling and behavior
- **Teleport System**: The travel assistant leverages the existing teleport window instead of creating duplicate UI
- **State Management**: Unified state management system with validation and proper cleanup
- **Event Handling**: All PUG events are handled through the centralized events system

### State Machine

PUG Mode uses a 5-state machine:

1. **IDLE**: Not tracking any LFG activity
2. **TRACKING**: Applied to groups, tracking applications
3. **INVITE_RECEIVED**: Received invite, showing notification
4. **IN_GROUP**: Joined group, providing travel assistance
5. **RUN_COMPLETE**: Dungeon completed, providing getaway options

All state transitions are validated to ensure proper workflow progression.

### UI Components

PUG Mode consists of four main UI components:

1. **Application Tracker** (`ui/pugApplicationTracker.lua`): Shows active LFG applications with real-time status
2. **Invite Notification** (`ui/pugInviteNotification.lua`): Shows contextual information about received invites
3. **Travel Assistant** (`ui/pugTravelAssistant.lua`): Provides travel options when joining groups
4. **Getaway UI** (`ui/pugGetawayUI.lua`): Offers quick exit options after dungeon completion

All components use the NextKey UIComponents system for consistent styling and behavior.

## Troubleshooting

### PUG Mode Not Working

1. Check if PUG Mode is enabled in the NextKey options (`/nk config`)
2. Make sure you're not in a group when applying to LFG listings
3. Try reloading the UI (`/reload`) and testing again

### Invites Not Being Tracked

1. Make sure you've applied to groups through the LFG tool
2. Check if the group leader's name matches the invite sender
3. Use `/nk pug status` to see the current PUG Mode state

### Application Tracker Not Working

1. Check if Application Tracker is enabled in the NextKey options
2. Ensure Auto-Show is enabled if you want it to appear automatically
3. Use `/nk pug tracker show` to test manual display
4. Check your active applications in the LFG tool

### Travel Assistant Not Showing

1. Ensure Travel Assistant is enabled in the options
2. Check if you've successfully joined a group
3. Verify the PUG Mode state is IN_GROUP (`/nk pug status`)
4. Check if travel window appears when invite popup shows

### Getaway UI Not Appearing

1. Make sure Getaway UI is enabled in the options
2. Verify you've completed a Mythic+ dungeon run
3. Check if the PUG Mode state is RUN_COMPLETE (`/nk pug status`)

## Version History

See the main [CHANGELOG.md](../CHANGELOG.md) for complete version history and all PUG Mode related changes.