# NextKey Debug System Architecture

## System Architecture Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        UI[Options Interface]
        DebugUI[Debug Control Panel]
        SlashUI[Slash Commands]
    end
    
    subgraph "Debug Service Core"
        DS[DebugService]
        LM[Level Manager]
        CM[Category Manager]
        GM[Group Manager]
        PM[Preset Manager]
        SM[Statistics Manager]
    end
    
    subgraph "Output Layer"
        CF[Chat Formatter]
        LF[Log Formatter]
        FF[File Formatter]
        WF[Window Formatter]
    end
    
    subgraph "Configuration Layer"
        DB[(Database)]
        Settings[Settings Manager]
        Migration[Migration Handler]
    end
    
    subgraph "Integration Layer"
        Events[Event System]
        Comms[Communications]
        UI_Hooks[UI Hooks]
        API[External API]
    end
    
    UI --> DS
    DebugUI --> DS
    SlashUI --> DS
    
    DS --> LM
    DS --> CM
    DS --> GM
    DS --> PM
    DS --> SM
    
    LM --> CF
    CM --> CF
    CF --> LF
    CF --> FF
    CF --> WF
    
    DS --> Settings
    Settings --> DB
    Migration --> Settings
    
    DS --> Events
    DS --> Comms
    DS --> UI_Hooks
    DS --> API
```

## Category Group Hierarchy

```mermaid
graph TD
    subgraph "Debug Categories"
        subgraph "Core Systems"
            CS[Core Systems]
            S[startup]
            E[events]
            P[performance]
            DB[database]
            C[config]
            O[options]
        end
        
        subgraph "Communications"
            COM[Communications]
            COMM[communications]
            COMMS[comms]
            LOR[libopenraid]
            RIO[raiderio]
            BLIZ[blizzard]
        end
        
        subgraph "Features & UI"
            UI_GRP[Features & UI]
            UI_CAT[ui]
            COMP[components]
            TT[tooltip]
            TP[teleport]
            LW[lootwindow]
            PRO[profiles]
        end
        
        subgraph "Data Processing"
            DP[Data Processing]
            KS[keystones]
            SN[season]
            IOC[IOCalculator]
            IOCC[ioc]
            FPS[fakeplayerservice]
        end
        
        subgraph "Testing & Development"
            TD[Testing & Development]
            TEST[test]
            DEBUG_CAT[debug]
        end
    end
    
    CS --> S
    CS --> E
    CS --> P
    CS --> DB
    CS --> C
    CS --> O
    
    COM --> COMM
    COM --> COMMS
    COM --> LOR
    COM --> RIO
    COM --> BLIZ
    
    UI_GRP --> UI_CAT
    UI_GRP --> COMP
    UI_GRP --> TT
    UI_GRP --> TP
    UI_GRP --> LW
    UI_GRP --> PRO
    
    DP --> KS
    DP --> SN
    DP --> IOC
    DP --> IOCC
    DP --> FPS
    
    TD --> TEST
    TD --> DEBUG_CAT
```

## Debug Level Flow

```mermaid
flowchart LR
    subgraph "Input"
        MESSAGE[Debug Message]
        CATEGORY[Category]
        LEVEL[Level]
    end
    
    subgraph "Filtering Logic"
        CHECK{Check Level}
        CATEGORY_CHECK{Check Category}
        DEV_MODE{DEV_MODE?}
        SHOULD_PRINT{Should Print?}
    end
    
    subgraph "Output"
        ERROR[ERROR Output]
        USER[USER Output]
        DEV[DEV Output]
        TRACE[TRACE Output]
        SUPPRESSED[Suppressed]
    end
    
    MESSAGE --> CHECK
    LEVEL --> CHECK
    
    CHECK -->|Level 1| ERROR
    CHECK -->|Level 2| USER
    CHECK -->|Level 3+| DEV_MODE
    
    DEV_MODE -->|True| CATEGORY_CHECK
    DEV_MODE -->|False| SUPPRESSED
    
    CATEGORY --> CATEGORY_CHECK
    CATEGORY_CHECK -->|Enabled| SHOULD_PRINT
    CATEGORY_CHECK -->|Disabled| SUPPRESSED
    
    SHOULD_PRINT -->|Level 3| DEV
    SHOULD_PRINT -->|Level 4| TRACE
```

## UI Component Architecture

```mermaid
graph TB
    subgraph "Options Window"
        MAIN[Main Options Panel]
        
        subgraph "Debug Section"
            DEBUG_TAB[Debug Tab]
            
            subgraph "Control Panel"
                MASTER_TOGGLE[Master Debug Toggle]
                LEVEL_SELECTOR[Level Selector]
                PRESET_SELECTOR[Preset Dropdown]
            end
            
            subgraph "Category Groups"
                GROUP_CONTAINER[Group Container]
                
                subgraph "Group Widget"
                    GROUP_TOGGLE[Group Toggle]
                    GROUP_STATUS[Group Status]
                    CATEGORY_LIST[Category List]
                    
                    subgraph "Category Widget"
                        CAT_TOGGLE[Category Toggle]
                        CAT_STATUS[Category Status]
                    end
                end
            end
            
            subgraph "Output Options"
                FORMAT_PANEL[Formatting Options]
                FILTER_PANEL[Filtering Options]
                DESTINATION_PANEL[Output Destination]
            end
            
            subgraph "Statistics"
                STATS_PANEL[Statistics Panel]
                METRICS_DISPLAY[Metrics Display]
                PERFORMANCE_GRAPH[Performance Graph]
            end
        end
    end
    
    MAIN --> DEBUG_TAB
    DEBUG_TAB --> CONTROL_PANEL
    DEBUG_TAB --> CATEGORY_GROUPS
    DEBUG_TAB --> OUTPUT_OPTIONS
    DEBUG_TAB --> STATISTICS
    
    CONTROL_PANEL --> MASTER_TOGGLE
    CONTROL_PANEL --> LEVEL_SELECTOR
    CONTROL_PANEL --> PRESET_SELECTOR
    
    CATEGORY_GROUPS --> GROUP_CONTAINER
    GROUP_CONTAINER --> GROUP_WIDGET
    GROUP_WIDGET --> GROUP_TOGGLE
    GROUP_WIDGET --> GROUP_STATUS
    GROUP_WIDGET --> CATEGORY_LIST
    CATEGORY_LIST --> CATEGORY_WIDGET
    CATEGORY_WIDGET --> CAT_TOGGLE
    CATEGORY_WIDGET --> CAT_STATUS
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant UI as Debug UI
    participant DS as DebugService
    participant DB as Database
    participant Output as Output System
    
    User->>UI: Change Setting
    UI->>DS: Update Configuration
    DS->>DB: Save Settings
    
    Note over DS: Debug Message Generated
    DS->>DS: Check Level & Category
    DS->>Output: Format Message
    Output->>User: Display Message
    
    User->>UI: Apply Preset
    UI->>DS: Load Preset Configuration
    DS->>DB: Update Multiple Settings
    DS->>UI: Refresh UI State
    
    User->>UI: View Statistics
    UI->>DS: Request Statistics
    DS->>DB: Query Performance Data
    DS->>UI: Return Statistics
    UI->>User: Display Metrics
```

## Integration Points

```mermaid
graph LR
    subgraph "External Systems"
        ACE[Ace3 Libraries]
        BLIZZARD[Blizzard API]
        OTHER_ADDONS[Other Addons]
    end
    
    subgraph "NextKey Systems"
        CORE[Core Systems]
        UI_SYSTEM[UI System]
        COMMS_SYSTEM[Communications]
        DATA_SYSTEM[Data Processing]
    end
    
    subgraph "Debug System"
        DEBUG_CORE[Debug Core]
        DEBUG_UI[Debug UI]
        DEBUG_OUTPUT[Debug Output]
    end
    
    ACE --> DEBUG_UI
    BLIZZARD --> DEBUG_OUTPUT
    OTHER_ADDONS --> DEBUG_CORE
    
    CORE --> DEBUG_CORE
    UI_SYSTEM --> DEBUG_CORE
    COMMS_SYSTEM --> DEBUG_CORE
    DATA_SYSTEM --> DEBUG_CORE
    
    DEBUG_CORE --> DEBUG_OUTPUT
    DEBUG_UI --> DEBUG_CORE
```

## Performance Considerations

```mermaid
graph TD
    subgraph "Performance Optimization"
        subgraph "Lazy Loading"
            UI_LAZY[UI Components]
            DATA_LAZY[Statistics Data]
            PRESET_LAZY[Preset Data]
        end
        
        subgraph "Efficient Updates"
            BATCH[Batch Updates]
            THROTTLE[Throttled Refresh]
            CACHE[Config Caching]
        end
        
        subgraph "Memory Management"
            CLEANUP[Resource Cleanup]
            POOL[Object Pooling]
            GC[Garbage Collection]
        end
    end
    
    UI_LAZY --> BATCH
    DATA_LAZY --> THROTTLE
    PRESET_LAZY --> CACHE
    
    BATCH --> CLEANUP
    THROTTLE --> POOL
    CACHE --> GC
```

## Migration Path

```mermaid
gantt
    title Debug System Implementation Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1: Foundation
    Core UI Framework     :active, phase1-1, 2024-01-01, 1w
    Basic Category Groups  :phase1-2, after phase1-1, 1w
    Integration Layer      :phase1-3, after phase1-2, 1w
    
    section Phase 2: Enhancement
    Advanced Group Controls :phase2-1, after phase1-3, 1w
    Output Formatting      :phase2-2, after phase2-1, 1w
    Statistics System      :phase2-3, after phase2-2, 1w
    
    section Phase 3: Polish
    Preset System         :phase3-1, after phase2-3, 1w
    Performance Optimization :phase3-2, after phase3-1, 1w
    Testing & Validation  :phase3-3, after phase3-2, 1w
```

## Key Design Principles

1. **Modularity**: Each component is independent and can be developed/tested separately
2. **Backward Compatibility**: All existing debug calls continue to work unchanged
3. **Performance**: Minimal overhead when debug is disabled, efficient when enabled
4. **Extensibility**: Easy to add new categories, groups, and output formats
5. **User Experience**: Intuitive interface with immediate visual feedback
6. **Maintainability**: Clean separation of concerns and well-documented code

## Technology Stack

- **UI Framework**: AceGUI-3.0 for consistent widget rendering
- **Configuration**: AceConfig-3.0 for options management
- **Data Storage**: SavedVariables with automatic migration
- **Event System**: AceEvent-3.0 for component communication
- **Formatting**: Custom formatters for different output types
- **Performance**: Built-in throttling and caching mechanisms

This architecture provides a solid foundation for the enhanced debug system while maintaining compatibility with existing code and providing a clear path for future enhancements.