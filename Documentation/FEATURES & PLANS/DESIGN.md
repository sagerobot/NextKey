# NextKey - Design & Feature Specifications

## Overview

NextKey is a World of Warcraft addon designed to help Mythic+ groups intelligently select the best keystone to run next. It aggregates keystone, player score, and loot preference data from all party members, processes this data through various customizable ranking algorithms, and presents a clear, ranked list of suggestions to the group.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Core Features](#core-features)
3. [User Experience Design](#user-experience-design)
4. [Technical Foundation](#technical-foundation)
5. [Feature Specifications](#feature-specifications)
6. [User Interface Design](#user-interface-design)
7. [Data Structures](#data-structures)
8. [Integration Points](#integration-points)
9. [Roadmap](#roadmap)

---

## Project Overview

### Addon Name
NextKey

### Purpose
NextKey is a World of Warcraft addon designed to help Mythic+ groups intelligently select the best keystone to run next. It aggregates keystone, player score, and loot preference data from all party members, processes this data through various customizable ranking algorithms, and presents a clear, ranked list of suggestions to the group.

### Target Users
- **Mythic+ Groups**: Premade groups looking to optimize their key selection
- **Party Leaders**: Players responsible for choosing which key to run
- **Loot-focused Players**: Groups targeting specific items from dungeons
- **Score Pushers**: Players focused on improving their Mythic+ scores

### Operating Modes
1. **Premade Group Mode** (Default): Full functionality with automatic key sharing, score syncing, complex sorting
2. **PUG Mode**: Simplified travel assistance focused interface for group finder groups

---

## Core Features

### 1. Data Collection & Communication
- **Automatic Key Detection**: Scans bags and uses Blizzard API to detect keystones
- **Score Aggregation**: Pulls score data from Raider.IO with fallbacks
- **Party Communication**: Uses AceComm-3.0 for reliable data sharing
- **Cross-Realm Support**: Handles players from different realms
- **Real-time Updates**: Automatically refreshes when keys or scores change

### 2. Ranking & Sorting Algorithms
- **Smart Sort (Borda Count)**: Intelligent ranking based on multiple factors
- **Max Group IO**: Prioritizes total IO gain for the party
- **Max Player Coverage**: Maximizes number of players who can gain IO
- **Highest Key Level**: Prioritizes running the highest available key
- **Max Item Need**: Focuses on dungeons with targeted loot

### 3. User Interface
- **Main Ranking Window**: Clean, sortable list of available keys
- **Dungeon Cards**: Visual card-based interface with rich information
- **Tooltip System**: Detailed tooltips with IO gain breakdowns
- **Teleport Integration**: One-click travel assistance
- **Options Panel**: Comprehensive settings management

### 4. Loot Targeting System
- **Item Database**: Complete loot table for current Mythic+ season
- **Target Selection**: Players can mark desired items from dungeons
- **Drop Chance Calculation**: Shows probability of targeted items dropping
- **Loot Announcements**: Celebrates when targeted items are obtained

### 5. Auto-Suggest & Travel Assistant
- **Leader-Only Feature**: Automatic key suggestions for party leaders
- **Smart Suggestions**: Uses configurable algorithms to recommend best key
- **Travel Assistance**: Integrates with teleportation system
- **Announcement Tools**: Easy sharing of suggestions with party

---

## User Experience Design

### Design Philosophy
- **Speed**: Groups should spend <30 seconds deciding next key
- **Clarity**: Information must be easy to understand at a glance
- **Flexibility**: Support different playstyles and priorities
- **Reliability**: Work consistently across all group compositions
- **Integration**: Seamless integration with existing WoW UI

### Key User Flows

#### Flow 1: Quick Decision (Most Common)
1. Player opens NextKey (`/nk`)
2. System automatically detects all party keystones and scores
3. Smart Sort shows ranked list with top recommendation highlighted
4. Leader clicks "Suggest" button to announce to party
5. Party members can click "Teleport" for travel assistance

#### Flow 2: Loot-Focused Run
1. Players mark desired items in Options panel
2. System prioritizes dungeons with targeted items
3. "Max Item Need" sort shows relevant keys first
4. Drop chances and attempt counts displayed in tooltips
5. Success announcements when items are obtained

#### Flow 3: Score Pushing
1. Group focuses on maximizing IO gains
2. "Max Group IO" or "Max Player Coverage" sorting selected
3. Detailed IO gain breakdowns shown in tooltips
4. System identifies keys where most players can gain score
5. Performance tracking shows improvement over time

### Accessibility Considerations
- **Colorblind Support**: Alternative indicators beyond color coding
- **Scalable UI**: Interface scales from 0.5x to 2.0x
- **Keyboard Navigation**: Full keyboard accessibility
- **Clear Typography**: High contrast, readable fonts
- **Visual Hierarchy**: Important information prominently displayed

---

## Technical Foundation

### Architecture Overview
NextKey follows the **Details! Damage Meter architectural patterns** for enterprise-grade addon development:

- **NextKey222 Namespace**: All modules organized under hierarchical namespace
- **Module Registration**: Every component registers with central module system
- **Error Resilience**: Critical operations use SafeRun wrapper for error handling
- **Performance Monitoring**: Built-in profiling for performance-critical paths
- **Centralized Debug**: Professional debug system with UI controls

### Dependencies
- **Hard Dependency**: RaiderIO addon for score data
- **Ace3 Framework**: AceAddon, AceComm, AceDB, AceConfig, AceGUI
- **Optional**: LibOpenRaid for additional score sources

### Data Sources
1. **Primary**: Raider.IO SavedVariables (most comprehensive)
2. **Secondary**: LibOpenRaid API (fallback for missing data)
3. **Tertiary**: Blizzard API (basic score information)
4. **Testing**: Fake Player Service for development/testing

---

## Feature Specifications

### 1. Data Collection & Communication (AceComm-3.0)

The addon's communication system uses AceComm-3.0 to ensure reliable and efficient data transfer between party members.

#### Comm Protocol
- **Comm Prefix**: `NKEY`
- **Channel**: `PARTY` for automatic syncing, `WHISPER` for direct requests
- **Throttling**: Max 1 message per second per player to prevent spam
- **Compression**: Large payloads compressed automatically

#### Data Payload Structure
```lua
{
    -- Core keystone data (REQUIRED)
    keystone = {
        dungeonID = number,      -- Valid dungeon ID from current season
        level = number,          -- Key level (2-30)
        ownerName = string       -- Full player name with realm
    },
    
    -- Score tracking (REQUIRED)
    scores = {
        [dungeonID] = {
            bestScore = number,         -- Best score for this dungeon
            bestLevel = number,         -- Highest level completed
            weeklyBest = number,        -- Best run this week
            totalRuns = number          -- Total attempts
        }
    },
    
    -- Live run data (OPTIONAL)
    liveRun = {
        dungeonID = number,
        level = number,
        timedSuccess = boolean,
        completionTime = number,
        affixes = { number }            -- Current week's affixes
    },
    
    -- Loot preferences (OPTIONAL)
    lootTargets = {
        [itemID] = {
            priority = number,          -- 1-3, higher is more important  
            attempts = number,          -- Number of runs for this item
            lastSeen = timestamp        -- Last time item was available
        }
    },
    
    -- Dungeon preferences (OPTIONAL)
    preferences = {
        [dungeonID] = {
            liked = boolean,
            disliked = boolean,
            reason = string,            -- Required if disliked
            lastUpdated = timestamp
        }
    },
    
    -- Protocol metadata (REQUIRED)
    meta = {
        version = string,               -- Addon version for compatibility
        timestamp = number,             -- Message timestamp  
        sequenceID = number            -- For ordering/deduplication
    }
}
```

#### Communication Triggers
- **Proactive Broadcast**: On `CHALLENGE_MODE_COMPLETED` event
- **Sync on Roster Change**: On `GROUP_ROSTER_UPDATE` event
- **Manual Refresh**: UI button or slash command
- **Request Response**: Reply to data requests from party members

### 2. Saved Data Management (AceDB-3.0)

All persistent data is managed by AceDB-3.0 with automatic migration support.

#### Database Structure
```lua
NextKeyDB = {
    global = {
        -- Leader settings
        leaderSettings = {
            autoSuggestEnabled = false,
            defaultSortMode = "SmartSort",
            suggestionDelay = 5.0
        },
        
        -- UI preferences  
        ui = {
            cardViewEnabled = true,
            animationsEnabled = true,
            framePosition = { x = 200, y = 200 },
            frameSize = { width = 600, height = 400 }
        },
        
        -- Communication settings
        comms = {
            throttleInterval = 1.0,
            maxRetries = 3,
            timeout = 5.0
        },
        
        -- Debug settings
        debug = {
            enabled = false,
            categories = {
                keystones = false,
                comms = false,
                ui = false
            }
        }
    },
    
    char = {
        -- Character-specific run history
        liveRuns = {},
        
        -- Targeted loot items
        targetedItems = {},
        
        -- Per-dungeon run counts for loot tracking
        dungeonRunCounts = {},
        
        -- Personal dungeon preferences
        dungeonPreferences = {}
    }
}
```

### 3. Ranking & Sorting Algorithms

#### Smart Sort (Borda Count)
Assigns points based on rank in each category and sums for overall ranking:

```lua
-- Scoring algorithm
local function CalculateSmartSortScore(keyData, allKeys)
    local points = 0
    
    -- Points based on IO gain rank (higher = better)
    local ioRank = GetRankByKey(keyData.ioGain, allKeys, "ioGain")
    points = points + (maxKeys - ioRank + 1) * 3
    
    -- Points based on player coverage rank
    local coverageRank = GetRankByKey(keyData.playerCount, allKeys, "playerCount")
    points = points + (maxKeys - coverageRank + 1) * 2
    
    -- Points based on key level rank
    local levelRank = GetRankByKey(keyData.level, allKeys, "level")
    points = points + (maxKeys - levelRank + 1) * 1
    
    -- Points based on item need rank
    local itemRank = GetRankByKey(keyData.itemNeed, allKeys, "itemNeed")
    points = points + (maxKeys - itemRank + 1) * 1
    
    return points
end
```

#### Max Group IO
Ranks by total potential IO gain for the entire party:

```lua
local function CalculateGroupIO(keyData, partyMembers)
    local totalIOGain = 0
    
    for _, player in ipairs(partyMembers) do
        local currentScore = GetPlayerDungeonScore(player, keyData.dungeonID)
        local potentialScore = CalculatePotentialScore(player, keyData.level)
        totalIOGain = totalIOGain + (potentialScore - currentScore)
    end
    
    return totalIOGain
end
```

#### Max Player Coverage
Prioritizes keys where the most players can gain IO:

```lua
local function CalculatePlayerCoverage(keyData, partyMembers)
    local coveredPlayers = 0
    
    for _, player in ipairs(partyMembers) do
        local currentScore = GetPlayerDungeonScore(player, keyData.dungeonID)
        local potentialScore = CalculatePotentialScore(player, keyData.level)
        
        if potentialScore > currentScore then
            coveredPlayers = coveredPlayers + 1
        end
    end
    
    return coveredPlayers
end
```

### 4. Loot Targeting & Tracking

#### Item Database Structure
```lua
-- LootDB.lua format
local LootDB = {
    [dungeonID] = {
        [itemID] = {
            name = string,
            slot = string,           -- "head", "chest", "weapon", etc.
            ilvl = number,
            classes = {string},     -- Classes that can use this item
            specRestrictions = {string}, -- Specs that benefit most
            dropChance = number,    -- Base drop chance percentage
            sources = {             -- Which bosses can drop this item
                [bossID] = number   -- Modified drop chance
            }
        }
    }
}
```

#### Drop Chance Calculation
```lua
local function CalculateDropChance(itemID, dungeonID, runCount)
    local itemData = LootDB[dungeonID][itemID]
    if not itemData then return 0 end
    
    local baseChance = itemData.dropChance
    local pityModifier = math.min(runCount * 0.05, 0.5) -- Max 50% pity
    local totalChance = baseChance + pityModifier
    
    return math.min(totalChance, 0.95) -- Cap at 95%
end
```

### 5. Auto-Suggest & Travel Assistant

#### Suggestion Algorithm
```lua
local function GenerateSuggestion(sortMode, partyKeys)
    local rankedKeys = SortKeys(partyKeys, sortMode)
    
    -- Apply additional filters
    local filteredKeys = {}
    for _, key in ipairs(rankedKeys) do
        -- Skip keys with very low IO gain unless no other options
        if key.ioGain > 10 or #filteredKeys == 0 then
            table.insert(filteredKeys, key)
        end
    end
    
    -- Return top suggestion
    return filteredKeys[1]
end
```

#### Travel Integration
```lua
local function ProvideTravelAssistance(dungeonID)
    local portalData = PortalsDB[dungeonID]
    if not portalData then return false end
    
    -- Check for teleport spells
    if HasTeleportSpell(portalData.teleportSpell) then
        return { type = "spell", spell = portalData.teleportSpell }
    end
    
    -- Check for flight paths
    local nearestFP = GetNearestFlightPath(portalData.location)
    if nearestFP then
        return { type = "flight", location = nearestFP }
    end
    
    -- Check for hearthstone
    local hearthLocation = GetHearthstoneLocation()
    if GetDistance(hearthLocation, portalData.location) < 5000 then
        return { type = "hearthstone" }
    end
    
    return false
end
```

---

## User Interface Design

### Main Window Layout
```
┌─────────────────────────────────────────┐
│ NextKey - [Dungeon Name] [Key Level]  │
├─────────────────────────────────────────┤
│ [Sort Mode Dropdown] [Refresh] [Dice]   │
├─────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │Dungeon  │ │Dungeon  │ │Dungeon  │    │
│ │ Card 1  │ │ Card 2  │ │ Card 3  │    │
│ │         │ │         │ │         │    │
│ │ IO: +45 │ │ IO: +32 │ │ IO: +28 │    │
│ │ 3/4 P   │ │ 2/4 P   │ │ 2/4 P   │    │
│ └─────────┘ └─────────┘ └─────────┘    │
│                                         │
│ [Suggest] [Teleport] [Announce]         │
└─────────────────────────────────────────┘
```

### Dungeon Card Design
```lua
-- Card structure
local cardData = {
    dungeonID = number,
    keyLevel = number,
    owner = string,
    preferences = {
        [playerGUID] = {
            liked = boolean,
            disliked = boolean,
            reason = string
        }
    },
    scores = {
        totalGain = number,
        affectedPlayers = table,
        potentialGains = table
    },
    loot = {
        targetedItems = number,
        interestedPlayers = table,
        dropChances = table
    }
}
```

### Tooltip Information
- **Key Details**: Owner, level, dungeon name
- **IO Breakdown**: Total gain, per-player gains
- **Player Coverage**: Who can gain, by how much
- **Loot Information**: Targeted items, drop chances
- **Preferences**: Who likes/dislikes this dungeon

### Options Panel Structure
```
NextKey Options
├── General Settings
│   ├── Default Sort Mode
│   ├── Auto-Suggest (Leader Only)
│   └── UI Preferences
├── Group Composition
│   ├── Role Preferences
│   ├── Class Preferences
│   └── Score Thresholds
├── Loot Targets
│   ├── [Dungeon 1]
│   │   ├── Item 1 [Priority]
│   │   └── Item 2 [Priority]
│   └── [Dungeon 2]
├── Debug Tools
│   ├── Fake Player Generator
│   ├── Debug Categories
│   └── Performance Monitoring
└── About & Support
    ├── Version Information
    ├── Credits
    └── Report Issues
```

---

## Data Structures

### Player Profile Contract
```lua
PlayerProfile = {
    name = string,              -- Full name with realm
    class = string,             -- Class token (WARRIOR, MAGE, etc.)
    io = number,                -- Total IO score
    dungeonScores = {           -- Per-dungeon breakdown
        [dungeonID] = {
            bestScore = number,
            bestLevel = number,
            weeklyBest = number,
            totalRuns = number,
            timed = boolean
        }
    },
    addonStatus = {             -- Addon presence flags
        nextkey = boolean,
        raiderio = boolean
    },
    dataSource = string         -- Where data came from
}
```

### Keystone Data Structure
```lua
KeystoneData = {
    dungeonID = number,
    level = number,
    ownerName = string,
    class = string,
    io = number,
    dungeonScores = table,
    addonStatus = table,
    source = string             -- "player", "debug", "imported"
}
```

### IO Calculation Input
```lua
IOCalculationInput = {
    keyData = KeystoneData,
    partyMembers = {PlayerProfile},
    sortMode = string,          -- "smart", "group_io", "coverage", etc.
    userPreferences = {
        ignoreDisliked = boolean,
        weightLoot = number,
        weightScore = number
    }
}
```

---

## Integration Points

### External Addons
- **RaiderIO**: Primary source of player score data
- **LibOpenRaid**: Secondary score source with real-time data
- **Deadly Boss Mods**: Potential integration for boss-specific loot
- **Details! Damage Meter**: Performance data correlation

### Blizzard API Integration
- **MythicPlus API**: Keystone detection, run history
- **Item API**: Loot detection, item information
- **Unit API**: Player information, class/spec detection
- **Spell API**: Teleport spell detection
- **Chat System**: Announcements and communications

### WoW Events
- `CHALLENGE_MODE_COMPLETED`: Trigger data refresh
- `GROUP_ROSTER_UPDATE`: Sync party data
- `BAG_UPDATE`: Detect keystone changes
- `CHAT_MSG_LOOT`: Track loot acquisitions
- `PLAYER_ENTERING_WORLD`: Initialize data

---

## Roadmap

### Phase 0: Foundation ✅ COMPLETED
- [x] Basic addon structure with Ace3 framework
- [x] Core communication system
- [x] Basic UI framework
- [x] Debug system implementation
- [x] Fake player service for testing

### Phase 1: Core Features ✅ COMPLETED
- [x] Keystone detection and management
- [x] Score calculation and display
- [x] Basic sorting algorithms
- [x] Party communication
- [x] Main ranking window

### Phase 2: Enhanced Features ✅ COMPLETED
- [x] Advanced sorting algorithms (Smart Sort)
- [x] Dungeon cards interface
- [x] Tooltip system with detailed information
- [x] Options panel with settings
- [x] Performance monitoring

### Phase 3: Loot System ✅ COMPLETED
- [x] Item database integration
- [x] Loot targeting interface
- [x] Drop chance calculations
- [x] Loot announcement system
- [x] Run tracking

### Phase 4: Polish & Optimization ✅ COMPLETED
- [x] UI refinements and animations
- [x] Performance optimizations
- [x] Error handling improvements
- [x] Comprehensive testing
- [x] Documentation

### Phase 5: Advanced Features (FUTURE)
- [ ] Auto-suggest system for party leaders
- [ ] Travel assistance integration
- [ ] Advanced analytics and insights
- [ ] Guild integration
- [ ] Historical data tracking

### Phase 6: Community Features (FUTURE)
- [ ] Import/export configurations
- [ ] Community ratings for dungeons
- [ ] Integration with popular websites
- [ ] Mobile companion app
- [ ] API for third-party developers

---

## Success Metrics

### User Experience Goals
- **Decision Time**: <30 seconds to select next key
- **Setup Time**: <2 minutes for new users to configure
- **Error Rate**: <1% of users encounter technical issues
- **Retention**: >80% of users continue using after 1 week

### Technical Goals
- **Performance**: <100ms UI response time
- **Memory**: <10MB baseline usage
- **Compatibility**: Works with 99% of common addon combinations
- **Reliability**: 99.9% uptime during gameplay

### Feature Adoption Goals
- **Core Features**: 100% of users use ranking and sorting
- **Advanced Features**: 60% of users use loot targeting
- **Social Features**: 40% of users use sharing features
- **Customization**: 70% of users modify settings

---

## Design Principles

### User-First Design
- Every feature must solve a real user problem
- Interface should be intuitive for new WoW players
- Advanced features should not complicate basic usage
- Performance should never impact gameplay

### Technical Excellence
- Code must be maintainable and well-documented
- Architecture should support future enhancements
- Error handling must be comprehensive
- Performance optimization is continuous

### Community Integration
- Respect existing addon ecosystem
- Provide value to the broader Mythic+ community
- Enable customizations and extensions
- Listen to user feedback and iterate

---

**Last Updated**: October 13, 2025  
**Version**: Consolidated Design Documentation v1.0