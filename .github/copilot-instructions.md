# NextKey AI Development Guide

This document provides essential context for AI agents working with the NextKey World of Warcraft addon codebase.

## Project Overview

NextKey is a Mythic+ keystone optimization addon that helps groups choose their next dungeon run by analyzing party members' keystones, scores, and loot preferences.

## Core Architecture

NextKey now follows the **Details! Damage Meter architectural patterns** for robust, scalable addon development:

### NextKey222 Namespace Organization
- **NextKey222** - Primary namespace containing all modules and utilities
- **NextKey222.Addon** - Main AceAddon-3.0 instance
- **NextKey222.RegisterModule()** - Module registration system
- **NextKey222.SafeRun()** - Error handling wrapper for all function calls
- **NextKey222.Performance** - Profiling and performance monitoring
- **NextKey222.Debug** - Centralized debug logging system

### Boot System
- **boot.lua** - Single initialization point replacing init.lua/core.lua
- **startup.lua** - Phased initialization (PreInit → Init → PostInit → Enable → Finalize)
- **Consolidated Loading** - All dependencies loaded through proper TOC order

#### Architectural Consolidation (✅ COMPLETED)
Based on analysis of major WoW addons (RaiderIO, Details, WeakAuras), NextKey's boot architecture has been consolidated:

- **✅ Industry Standard**: Now uses single entry point initialization like all major addons
- **✅ Implemented Structure**: Merged all three files into a single comprehensive boot.lua
- **✅ Benefits Realized**: Reduced complexity, better performance, clearer dependencies, easier debugging
- **✅ Implementation**: Maintained phase concept but handles all phases in one file following Details pattern
- **✅ Backward Compatibility**: Original files backed up as .bak extensions for rollback capability

### Built on **Ace3 Framework**:
  - `AceAddon-3.0` - Core addon structure
  - `AceComm-3.0` - Inter-player communication (prefix: `NKEY`)
  - `AceDB-3.0` - SavedVariables management (`NextKeyDB`)
  - `AceConfig-3.0/AceGUI-3.0` - Configuration UI
  - `AceSerializer-3.0` - Message serialization

## Code Organization

The codebase uses `-- MARK:` comments for quick navigation in VS Code. Major sections should be marked following this pattern:

```lua
-- MARK: Initialization & Setup
-- Core addon initialization code...

-- MARK: Event Handlers
-- Event registration and handlers...

-- MARK: UI Components
-- UI frame creation and updates...

-- MARK: Data Management
-- Data processing and state management...

-- MARK: Communication
-- Inter-player message handling...
```

Common MARK categories:
- Initialization & Setup
  - Module registration
  - Dependency checks
  - Environment setup
  - Initial state configuration

- Event Handlers
  - Event registration & cleanup
  - Callback processing
  - State transition logic
  - Error recovery

- UI Components
  - Frame initialization
  - Widget creation & layout
  - Event binding
  - Animation handling
  - Interactive elements
  - Tooltip management
  - State visualization

- Data Management
  - Data validation & sanitization
  - State persistence
  - Cache management
  - Data transformations
  - History tracking
  - Score calculations

- Communication
  - Protocol handling
  - Message serialization
  - Data synchronization
  - Error recovery
  - Version compatibility

- Utility Functions
  - Type conversions
  - String formatting
  - Table operations
  - Math helpers
  - Debug tools

- Frame Management
  - Layout handling
  - Visibility control
  - Scale management
  - Anchor points
  - Frame recycling

- State Updates
  - State mutation
  - Change propagation
  - View updates
  - Cache invalidation
  - State rollback

### File Organization Guidelines

1. **Core Module Files** (`core/`)
   ```lua
   -- MARK: Module Definition
   -- Core module setup and registration
   
   -- MARK: Public Interface
   -- Public API methods and properties
   
   -- MARK: Private Implementation
   -- Internal helper functions and state
   
   -- MARK: Event Handlers
   -- Event callback implementations
   
   -- MARK: State Management
   -- Data manipulation and state updates
   ```

2. **UI Component Files** (`ui/`)
   ```lua
   -- MARK: Frame Setup
   -- Frame creation and initial layout
   
   -- MARK: Widget Creation
   -- Individual UI element creation
   
   -- MARK: Event Binding
   -- User interaction handlers
   
   -- MARK: Update Functions
   -- Visual state update handlers
   
   -- MARK: Animations
   -- Animation definitions and controls
   ```

3. **Data Files** (`data/`)
   ```lua
   -- MARK: Constants
   -- Static data definitions
   
   -- MARK: Lookup Tables
   -- Data mapping and reference tables
   
   -- MARK: Default Values
   -- Default configuration states
   ```

4. **Event Files** (`events/`)
   ```lua
   -- MARK: Event Registration
   -- Event handler setup
   
   -- MARK: Core Events
   -- Primary game event handlers
   
   -- MARK: Custom Events
   -- Addon-specific event handlers
   
   -- MARK: State Updates
   -- Event-driven state changes
   ```

## Critical Files & Components

- `Core.lua` - Main addon initialization and core logic
- `Events.lua` - WoW event handlers
- `Options.lua` - AceConfig tables for settings
- `MythicPlusOptions.lua` - M+ specific configuration
- `UI.lua` - Main interface components 
- `PortalDB.lua` - Dungeon teleport data
- `TeleportWindow.lua` - Travel assistance UI

## Key Data Structures

### Communication Payload
```lua
{
    -- Core keystone data (required)
    keystone = {
        dungeonID = number,  -- Valid dungeon ID from current season
        level = number,      -- Key level (2-30)
        ownerName = string   -- Full player name with realm
    },
    
    -- Score tracking (required)
    scores = {
        [dungeonID] = {
            bestScore = number,     -- Best score for this dungeon
            bestLevel = number,     -- Level of best run
            totalRuns = number,     -- Total runs attempted
            weeklyBest = number     -- Best run this week
        }
    },
    
    -- Live run data (optional)
    liveRun = {
        dungeonID = number,
        level = number,
        timedSuccess = boolean,
        completionTime = number,
        affixes = { number }
    },
    
    -- Loot preferences (optional)
    lootTargets = {
        [itemID] = {
            priority = number,      -- 1-3, higher is more important
            runCount = number,      -- Times attempted to get this item
            lastSeen = timestamp    -- Last time item was available
        }
    },
    
    -- Dungeon preferences (optional)
    preferences = {
        [dungeonID] = {
            liked = boolean,
            disliked = boolean,
            reason = string,
            lastUpdated = timestamp
        }
    },
    
    -- Protocol metadata (required)
    meta = {
        version = string,          -- Addon version
        timestamp = number,        -- Message timestamp
        sequenceID = number       -- For ordering/deduplication
    }
}
```

### SavedVariables (NextKeyDB)
```lua
{
    global = {
        -- Leader settings
        leaderSettings = {
            autoSuggestEnabled = boolean,
            defaultSortMode = string,     -- "smart"|"score"|"loot"|"preference"
            suggestionDelay = number      -- Seconds to wait before suggesting
        },
        
        -- UI preferences
        ui = {
            cardViewEnabled = boolean,
            showAnimations = boolean,
            colorblindMode = boolean,
            framePosition = { x = number, y = number }
        },
        
        -- Communication settings
        comms = {
            throttleInterval = number,    -- Seconds between broadcasts
            maxRetries = number,          -- Connection retry attempts
            debugLevel = number           -- 0-3, higher = more verbose
        }
    },
    
    char = {
        -- Run history
        liveRuns = {
            [timestamp] = {
                dungeonID = number,
                level = number,
                success = boolean,
                score = number
            }
        },
        
        -- Loot tracking
        targetedItems = {
            [itemID] = {
                priority = number,
                attempts = number,
                firstSeen = timestamp
            }
        },
        
        -- Dungeon stats
        dungeonRunCounts = {
            [dungeonID] = {
                total = number,
                completed = number,
                abandoned = number,
                averageTime = number
            }
        },
        
        -- Personal preferences
        preferences = {
            [dungeonID] = {
                liked = boolean,
                disliked = boolean,
                reason = string,
                lastUpdated = timestamp
            }
        }
    }
}
```

### Validation Rules
1. **Keystone Data**
   - dungeonID must be valid for current season
   - level must be between 2-30
   - ownerName must include realm

2. **Score Data**
   - All scores must be non-negative
   - Weekly best cannot exceed overall best
   - Total runs must be accurate

3. **Preferences**
   - Cannot be both liked and disliked
   - Reason required if disliked
   - lastUpdated must be valid timestamp

4. **Comms Protocol**
   - Version check before processing
   - Sequence ID must be monotonic
   - Throttle checks on send/receive
   - Max message size limits

## Development Patterns

### 1. Module Registration
All modules must register with the NextKey222 system:
```lua
local MyModule = {}
NextKey222.MyModule = MyModule
NextKey222.RegisterModule("MyModule", MyModule)

function MyModule:Initialize()
    -- Module setup logic
    return true
end

return MyModule
```

### 2. Error Handling
Use NextKey222.SafeRun for all function calls:
```lua
NextKey.SafeRun(MyModule.SomeFunction, "Description", arg1, arg2)
```

### 3. Performance Profiling
Profile critical code paths:
```lua
NextKey222.Performance:StartProfile("MyFunction")
-- Function logic here
NextKey222.Performance:StopProfile("MyFunction")
```

### 4. Event Handling
Register events through the Events module:
```lua
NextKey:RegisterEvent("CHALLENGE_MODE_COMPLETED", function(event, ...)
    self:OnMythicPlusCompleted(...)
end)
```

### 5. Inter-player Communication
Use Communications module for party data sync:
```lua
NextKey.Communications:SendSync()
NextKey.Communications:ProcessMessage(prefix, message, distribution, sender)
```

### 6. Debug Logging
Use centralized debug system:
```lua
NextKey222.Debug:Print("module", "Debug message", variable)
```

### 7. Settings and SavedVariables
Access through NextKey.db with proper validation:
```lua
local setting = NextKey.db.global.someSetting or defaultValue
NextKey.db.char.playerSetting = newValue
```

## Dependencies

- Hard dependency on **Raider.IO** addon for score data
- Test with both retail and PTR WoW clients (check Interface version in .toc)

## Best Practices

### 1. Coding Standards
- Use **snake_case** for function and variable names
- Use **PascalCase** for module and class names
- Prefix private functions with underscore (_function_name)
- Group related functions under MARK comments
- Use descriptive variable names that indicate purpose and type
- Document all public functions with parameter and return value descriptions

### 2. Error Handling
- **Validate all inputs** at public function boundaries
- Use Ace3's debug logging for development tracking:
  ```lua
  self:Debug('Processing keystone:', keystoneLink)
  ```
- Gracefully handle missing or invalid data:
  ```lua
  if not keystone or not keystone.dungeonID then
      self:Debug('Invalid keystone data')
      return
  end
  ```
- Provide user feedback for recoverable errors
- Maintain addon stability even if RaiderIO is missing

### 3. Performance Guidelines
- Cache frequently accessed data
- Minimize string concatenations in loops
- Use table pools for frequent create/destroy cycles
- Throttle communication messages
- Batch UI updates
- Profile critical paths with debug tools

### 4. UI/UX Standards
- Follow WoW UI style guidelines
- Support both mouse and keyboard interactions
- Provide tooltips for all interactive elements
- Ensure colorblind-friendly indicators
- Use consistent spacing and alignment
- Support UI scale changes

### 5. Communication Protocol
- Version payload data for backward compatibility
- Implement throttling for spam prevention
- Handle disconnects and reconnects gracefully
- Validate received data before processing
- Log communication errors in debug mode

## Common Workflows

1. **Adding New Features**:
   - Register event handlers in `Events.lua` (use MARK comments for organization)
   - Add configuration in `Options.lua`
   - Implement UI components in `UI.lua` (group related components under MARK sections)
   - Update communication payload if needed

2. **Testing**:
   
### Basic Testing
   - Use `/nk` or `/nextkey` commands for initial UI validation
   - Test basic functionality with different UI scales
   - Verify all tooltip information is accurate
   - Check memory usage with `/console scriptprofile 1`

### Party Testing
   - Test in 5-player party context
   - Verify cross-realm communication
   - Test with mixed addon versions in party
   - Validate leader vs member functionality
   - Check preference sync behavior
   - Test disconnection handling

### Dungeon Testing
   - Run a variety of key levels (2-30)
   - Test all seasonal dungeons
   - Verify score calculations
   - Test completion/failure scenarios
   - Validate loot tracking
   - Test travel assistance features

### UI Testing
   - Verify card layout in both views
   - Test animations and transitions
   - Validate colorblind mode
   - Check all interactive elements
   - Test keyboard navigation
   - Verify tooltip behavior

### Edge Cases
   - Test with missing RaiderIO data
   - Verify behavior with disabled features
   - Test extreme party sizes
   - Check high latency scenarios
   - Validate error handling
   - Test with invalid keystones