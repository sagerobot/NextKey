# NextKey Slash Commands Reference

This document provides a complete reference for all NextKey slash commands. The command system is implemented in `core/slashCommands.lua` for easy maintenance and modification.

## Command Aliases

- `/nextkey` - Full command
- `/nk` - Short alias (recommended)

## Main Commands

### Window Management
```
/nk                    - Toggle/show the main window
/nk show               - Show the main window
/nk hide               - Hide the main window
```

### Help & Information
```
/nk help               - Show all available commands
/nk ?                  - Show all available commands (alias)
/nk version            - Show addon version and game version
/nk ver                - Show version (alias)
/nk v                  - Show version (alias)
/nk status             - Show system status (modules, services)
```

### Configuration
```
/nk config             - Open configuration panel
/nk options            - Open configuration panel (alias)
/nk opt                - Open configuration panel (alias)
```

### System
```
/nk reload             - Reload the UI
```

## Debug Commands

All debug commands start with `/nk debug`:

### Basic Controls
```
/nk debug              - Show debug command help
/nk debug help         - Show debug command help
/nk debug ?            - Show debug command help (alias)

/nk debug on           - Enable debug output
/nk debug enable       - Enable debug output (alias)

/nk debug off          - Disable debug output
/nk debug disable      - Disable debug output (alias)

/nk debug toggle       - Toggle debug on/off
```

### Debug Levels
```
/nk debug level <0-4>  - Set debug verbosity level
  0 = NONE (silent)
  1 = ERROR (critical errors only)
  2 = USER (user-facing messages)
  3 = DEV (development logs)
  4 = TRACE (ultra-verbose)

Example: /nk debug level 3
```

### Category Management
```
/nk debug category <name>  - Toggle a specific debug category
/nk debug cat <name>       - Toggle a specific debug category (alias)

/nk debug list             - List all available categories
/nk debug status           - Show current debug settings

Example: /nk debug category keystones
```

### Available Debug Categories
- **Core**: `keystones`, `communications`, `comms`, `profiles`, `season`, `startup`, `events`
- **Integrations**: `raiderio`, `libopenraid`, `blizzard`
- **System**: `performance`, `options`, `config`, `database`
- **UI**: `ui`, `teleport`, `tooltip`, `components`, `lootwindow`
- **Testing**: `fakeplayerservice`, `IOCalculator`, `ioc`, `test`, `debug`
- **PUG Helper**: `pughelper` (for PUG Mode debugging)

## Test Commands

Commands for generating fake players for testing (requires FakePlayerService enabled):

### Basic Testing
```
/nk test               - Generate 4 realistic fake players (default mix)
/nk test realistic     - Generate 4 realistic fake players (alias)
/nk test help          - Show test command help
/nk test ?             - Show test command help (alias)
```

### Advanced Testing
```
/nk test mixed X Y Z   - Generate custom mix of players
  X = Number of players with NextKey addon
  Y = Number of players with RaiderIO only
  Z = Number of players with no addons

Example: /nk test mixed 2 1 1
```

### Presets
```
/nk test preset <type> - Generate a preset team
  Types:
    - mixed_skill    : Players of varying skill levels
    - beginner       : Low IO team
    - expert         : High IO team
    - high_keys      : Very high IO team

Example: /nk test preset expert
```

### Management
```
/nk test clear         - Remove all fake players
/nk test status        - Show FakePlayerService statistics
```

## PUG Helper Commands

Commands for the PUG (Pick Up Group) Helper system that assists with LFG workflow:

### Basic PUG Commands
```
/nk pug                - Show PUG Helper help
/nk pug help           - Show PUG Helper help (alias)
/nk pug ?              - Show PUG Helper help (alias)

/nk pug status         - Show current PUG Helper state and configuration

/nk pug test           - Test PUG Helper application tracking
/nk pug enable         - Enable PUG Helper
/nk pug disable        - Disable PUG Helper
/nk pug reset          - Reset PUG Helper state
```

### Workflow Simulation
```
/nk pug simulate <action>  - Simulate PUG workflow actions
  Actions:
    invite    - Simulate receiving a group invite
    join      - Simulate joining a group
    complete  - Simulate completing a dungeon

Example: /nk pug simulate invite
```

### UI Testing
```
/nk pug testui <type>     - Test PUG UI components
  Types:
    invite    - Test invite notification UI
    travel    - Test travel assistant UI
    getaway   - Test getaway UI

Example: /nk pug testui invite
```

### Test Scenarios
```
/nk pug scenario <type> <name>  - Set test scenarios
  Types: invite, travel, getaway

Example: /nk pug scenario invite standard
```

### Application Tracker (NEW)
```
/nk pug tracker <action>  - Control application tracker window
  Actions:
    show     - Show the application tracker window
    hide     - Hide the application tracker window
    toggle   - Toggle the application tracker window

Example: /nk pug tracker show
```

## Developer Commands

### RaiderIO Debugging
```
/nk rio                - Debug RaiderIO data structure for current player
```

## Adding New Commands

To add new commands, edit `core/slashCommands.lua`:

1. **Add command definition** to the appropriate table (`Commands`, `DebugCommands`, or `TestCommands`):
   ```lua
   {
       cmd = {"mycommand", "alias"},
       desc = "Description shown in help",
       handler = "MyCommandHandler"
   }
   ```

2. **Create handler function** in the `SlashCommands` table:
   ```lua
   function SlashCommands:MyCommandHandler(arg1, args)
       -- Your command logic here
       NextKey222.Debug:User("Command executed!")
   end
   ```

3. **Test the command** with `/reload` and `/nk mycommand`

## Notes

- Commands are case-insensitive
- Multiple aliases can be defined for any command
- Help text is automatically generated from command definitions
- The system supports nested subcommands (e.g., `/nk debug category`)
- All command output uses the Debug system for consistent formatting

## File Locations

- **Command Handler**: `core/slashCommands.lua`
- **Load Order**: Defined in `NextKey.toc` (loads after `boot.lua`)
- **Documentation**: `Documentation/SLASH_COMMANDS.md` (this file)

## Migration Notes

The slash command system was refactored from `boot.lua` to `core/slashCommands.lua` for:
- **Better Organization**: Keeps boot.lua focused on initialization
- **Easier Maintenance**: All commands in one file with clear structure
- **Improved Documentation**: Command definitions include help text
- **Extensibility**: Simple pattern for adding new commands

Previous location: Lines 317-501 in `boot.lua` (removed)
Current location: `core/slashCommands.lua` (full implementation)
