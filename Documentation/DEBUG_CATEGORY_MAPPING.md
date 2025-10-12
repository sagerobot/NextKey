# Debug Category Mapping and Grouping

## Current Category Analysis

Based on the existing `core/debugService.lua`, the following debug categories are currently defined:

### Current Categories (Flat Structure)
- keystones
- communications  
- comms
- ui
- profiles
- season
- startup
- events
- raiderio
- libopenraid
- blizzard
- performance
- options
- config
- database
- teleport
- tooltip
- components
- lootwindow
- fakeplayerservice
- IOCalculator
- ioc
- test
- debug

## Proposed Category Grouping

### Group 1: Core Systems
**Purpose**: Fundamental addon functionality and initialization
- `startup` - Addon initialization and startup sequence
- `events` - Event handling and dispatching
- `performance` - Performance monitoring and optimization
- `database` - Database operations and SavedVariables management
- `config` - Configuration loading and management
- `options` - Options interface handling

### Group 2: Communications
**Purpose**: Network and addon-to-addon communication
- `communications` - Core addon communication system
- `comms` - Low-level communication protocols
- `libopenraid` - LibOpenRaid integration
- `raiderio` - RaiderIO data integration
- `blizzard` - Blizzard API integration

### Group 3: Features & UI
**Purpose**: User-facing features and interface elements
- `ui` - Main UI rendering and interaction
- `components` - UI component system
- `tooltip` - Tooltip system
- `teleport` - Teleport functionality
- `lootwindow` - Loot tracking interface
- `profiles` - Player profile management

### Group 4: Data Processing
**Purpose**: Data calculation and processing systems
- `keystones` - Keystone data processing
- `season` - Seasonal data management
- `IOCalculator` - IO score calculations
- `ioc` - IO calculation operations
- `fakeplayerservice` - Fake player data simulation

### Group 5: Testing & Development
**Purpose**: Development tools and testing utilities
- `test` - General testing utilities
- `debug` - Meta-debug (debug system self-monitoring)

## Category Group Configuration Structure

```lua
-- Proposed category groups configuration
local DEBUG_CATEGORY_GROUPS = {
    ["Core Systems"] = {
        description = "Fundamental addon functionality and initialization",
        icon = "Interface\\Icons\\INV_Gizmo_01",
        order = 1,
        categories = {
            startup = { 
                name = "Startup & Initialization",
                description = "Addon loading, initialization sequence, and startup events"
            },
            events = { 
                name = "Event Handling", 
                description = "Event registration, dispatching, and processing"
            },
            performance = { 
                name = "Performance Monitoring",
                description = "Performance tracking, optimization metrics, and timing"
            },
            database = { 
                name = "Database Operations",
                description = "SavedVariables access, data persistence, and storage"
            },
            config = { 
                name = "Configuration Management",
                description = "Settings loading, validation, and management"
            },
            options = { 
                name = "Options Interface",
                description = "Options panel rendering and user preferences"
            }
        }
    },
    
    ["Communications"] = {
        description = "Network and addon-to-addon communication systems",
        icon = "Interface\\Icons\\INV_Misc_Net_01",
        order = 2,
        categories = {
            communications = { 
                name = "Core Communications",
                description = "Main addon communication system"
            },
            comms = { 
                name = "Communication Protocols",
                description = "Low-level message handling and protocols"
            },
            libopenraid = { 
                name = "LibOpenRaid Integration",
                description = "LibOpenRaid API interactions and data exchange"
            },
            raiderio = { 
                name = "RaiderIO Integration",
                description = "RaiderIO data fetching and processing"
            },
            blizzard = { 
                name = "Blizzard API Integration",
                description = "Blizzard API calls and data retrieval"
            }
        }
    },
    
    ["Features & UI"] = {
        description = "User-facing features and interface elements",
        icon = "Interface\\Icons\\INV_Misc_Toy_07",
        order = 3,
        categories = {
            ui = { 
                name = "Main UI",
                description = "Primary user interface rendering and interaction"
            },
            components = { 
                name = "UI Components",
                description = "Reusable UI component system and widgets"
            },
            tooltip = { 
                name = "Tooltip System",
                description = "Tooltip creation, positioning, and content"
            },
            teleport = { 
                name = "Teleport System",
                description = "Teleport functionality and spell management"
            },
            lootwindow = { 
                name = "Loot Tracking",
                description = "Loot window and item tracking interface"
            },
            profiles = { 
                name = "Profile Management",
                description = "Player profile creation and management"
            }
        }
    },
    
    ["Data Processing"] = {
        description = "Data calculation and processing systems",
        icon = "Interface\\Icons\\INV_Enchant_DessertCrystals",
        order = 4,
        categories = {
            keystones = { 
                name = "Keystone Processing",
                description = "Keystone data collection and processing"
            },
            season = { 
                name = "Seasonal Data",
                description = "Season information and dungeon management"
            },
            IOCalculator = { 
                name = "IO Score Calculator",
                description = "IO score calculation algorithms and data"
            },
            ioc = { 
                name = "IO Calculation Operations",
                description = "Detailed IO calculation operations and steps"
            },
            fakeplayerservice = { 
                name = "Fake Player Service",
                description = "Testing data generation and fake player simulation"
            }
        }
    },
    
    ["Testing & Development"] = {
        description = "Development tools and testing utilities",
        icon = "Interface\\Icons\\INV_Eng_Gears",
        order = 5,
        categories = {
            test = { 
                name = "Testing Utilities",
                description = "General testing tools and utilities"
            },
            debug = { 
                name = "Meta-Debug",
                description = "Debug system self-monitoring and diagnostics"
            }
        }
    }
}
```

## Group Operations

### Bulk Enable/Disable Operations
```lua
-- Enable entire group
DebugService:EnableGroup("Core Systems")
-- Equivalent to: DebugService:EnableCategory("startup", "events", "performance", "database", "config", "options")

-- Disable entire group  
DebugService:DisableGroup("Communications")
-- Equivalent to: DebugService:DisableCategory("communications", "comms", "libopenraid", "raiderio", "blizzard")

-- Toggle entire group
DebugService:ToggleGroup("Features & UI")

-- Check group status
local isEnabled, enabledCount, totalCount = DebugService:GetGroupStatus("Core Systems")
-- Returns: (true, 3, 6) if 3 of 6 categories in group are enabled
```

### Category Group Metadata
```lua
-- Get group information
local groupInfo = DebugService:GetGroupInfo("Core Systems")
-- Returns: { description, icon, order, categories }

-- Get all categories in a group
local categories = DebugService:GetGroupCategories("Data Processing")
-- Returns: { "keystones", "season", "IOCalculator", "ioc", "fakeplayerservice" }

-- Get category's parent group
local parentGroup = DebugService:GetCategoryGroup("ui")
-- Returns: "Features & UI"
```

## Preset Configurations Based on Groups

### Development Presets
```lua
local DEBUG_PRESETS = {
    ["Minimal Development"] = {
        description = "Core functionality debugging only",
        groups = {
            ["Core Systems"] = { enabled = true, categories = { "events", "config" } },
            ["Communications"] = { enabled = false },
            ["Features & UI"] = { enabled = false },
            ["Data Processing"] = { enabled = false },
            ["Testing & Development"] = { enabled = true, categories = { "debug" } }
        },
        level = 2 -- ERROR + USER
    },
    
    ["Full Development"] = {
        description = "Comprehensive debugging for development",
        groups = {
            ["Core Systems"] = { enabled = true },
            ["Communications"] = { enabled = true },
            ["Features & UI"] = { enabled = true },
            ["Data Processing"] = { enabled = true },
            ["Testing & Development"] = { enabled = true }
        },
        level = 4 -- ERROR + USER + DEV + TRACE
    },
    
    ["UI Testing"] = {
        description = "Focus on UI and user interaction debugging",
        groups = {
            ["Core Systems"] = { enabled = true, categories = { "events", "performance" } },
            ["Communications"] = { enabled = false },
            ["Features & UI"] = { enabled = true },
            ["Data Processing"] = { enabled = false },
            ["Testing & Development"] = { enabled = false }
        },
        level = 3 -- ERROR + USER + DEV
    }
}
```

## Migration Strategy

### Backward Compatibility
- Existing category names remain unchanged
- All current debug calls continue to work
- Group functionality is additive, not replacing

### Settings Migration
```lua
-- Auto-migration function for existing settings
function DebugService:MigrateSettings()
    local oldSettings = self.db.global.debug.categories or {}
    
    -- Group settings automatically apply to existing categories
    -- No data loss, just enhanced organization
    
    for categoryName, enabled in pairs(oldSettings) do
        -- Category already exists, just maintain current state
        -- Group relationships will be automatically calculated
    end
end
```

### UI Migration Path
1. **Phase 1**: Add group controls alongside existing category controls
2. **Phase 2**: Implement group-first interface with category drill-down
3. **Phase 3**: Optimize based on user feedback and usage patterns

## Benefits of Grouped Categories

1. **Improved Organization**: Logical grouping makes finding relevant settings easier
2. **Bulk Operations**: Enable/disable entire functional areas at once
3. **Better Understanding**: Group descriptions provide context for related categories
4. **Faster Configuration**: Presets can target entire functional areas
5. **Enhanced Maintainability**: Easier to add new categories to appropriate groups
6. **User-Friendly**: Reduced cognitive load when managing debug settings