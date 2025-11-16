# Fake Player System Overhaul - Comprehensive Plan

**Status**: Design Phase
**Priority**: High
**Target Version**: 0.7.0
**Last Updated**: 2025-11-15
**Architectural Compliance**: ✅ Validated against Modularity Checklist

---

## Executive Summary

The Fake Player Service has grown organically to become a critical testing tool but suffers from UI bloat, limited granularity, and difficulty creating diverse test scenarios. This overhaul will transform it into a powerful, intuitive testing framework that enables comprehensive validation of all 7 sorting algorithms.

**Key Metrics:**
- Current: 40+ scattered buttons across flat UI
- Target: 6 logical sections with hierarchical organization
- New Capabilities: Per-dungeon score control, loot targeting integration, algorithm variance testing

---

## Problem Statement

### Current Pain Points

1. **UI Bloat** (Critical)
   - 40+ buttons in [`options/main.lua`](../../options/main.lua:1) with flat hierarchy
   - Difficult to find specific generators
   - No visual grouping by purpose
   - **Impact**: Wastes development time, makes testing frustrating

2. **Limited Granularity** (High)
   - Can't create "expert in Priory, weak in Ara-Kara" players
   - No per-dungeon score/level control
   - Skill tiers are broad (8 tiers but applied uniformly)
   - **Impact**: Can't test edge cases or specific scenarios

3. **No Loot Integration** (High)
   - Loot data exists in [`data/loot.lua`](../../data/loot.lua:1) but not connected to player generation
   - Can't test "Max Item Need" sorting algorithm effectively
   - No way to generate "loot-motivated" teams
   - **Impact**: 1 of 7 sorting algorithms is untestable

4. **Difficult IO Variance Testing** (Critical)
   - Hard to create teams where different algorithms produce different results
   - Presets too homogeneous (mixed_skill still mostly uniform)
   - No validation that test scenarios actually differentiate algorithms
   - **Impact**: Can't validate sorting system is working correctly

5. **No Per-Dungeon Control** (High)
   - [`generateDungeonScores()`](../../core/fakePlayerService.lua:373) has expert/weak arrays but limited
   - Can't manually set specific scores for testing
   - No UI for granular dungeon performance
   - **Impact**: Can't reproduce specific bug scenarios

---

## Solution Architecture

### Design Principles

1. **Progressive Disclosure**: Simple by default, powerful when needed
2. **Intent-Based Organization**: Group by "what I want to test" not "how it works"
3. **Validation-First**: Every generator should create meaningful test scenarios
4. **Data-Driven**: Leverage existing loot/portal data for realism
5. **Composability**: Combine features (loot + per-dungeon + skill tier)

### Architectural Compliance

This plan adheres to NextKey's architectural standards per [`04_Modularity_Checklist.md`](../_Architectural_Audit/04_Modularity_Checklist.md:1):

**✅ Code Isolation & Namespace**
- All code in [`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1) is properly scoped with `local _, NextKey222 = ...`
- FakePlayerService module attached to `NextKey222` namespace
- All internal functions are `local` by default
- Public API exposed through module table

**✅ Communication & Coupling**
- **Pure Service Module**: FakePlayerService has **ZERO UI dependencies**
- All communication is one-way: UI → Service (synchronous API calls)
- No direct calls from FakePlayerService to UI modules
- Event-based refresh: When player data changes, UI modules listen to `NEXTKEY_PROFILE_UPDATED` (announced by ProfilesService)
- **Separation of Concerns**: Service generates data, UI (options/main.lua) handles presentation

**✅ Separation of Concerns (UI vs. Logic)**
- **Core Logic**: [`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1) - Data generation, validation, scoring
- **UI Layer**: [`options/main.lua`](../../options/main.lua:1) - AceConfig widgets, user input handling
- **Data Flow**:
  ```
  User clicks button → options/main.lua fires FakePlayerService API
                     → FakePlayerService generates player data
                     → Returns PlayerProfile object
                     → options/main.lua adds to Profiles module
                     → ProfilesService announces NEXTKEY_PROFILE_UPDATED
                     → UI modules refresh themselves
  ```
- UI knows about service APIs, service has **zero knowledge of UI**

**✅ Code Health & Simplicity**
- Plan includes cleanup: Remove unused preset generators during reorganization
- Simplify complex generation logic by consolidating into scenario templates
- Clear naming conventions: `CreatePlayer()`, `RunScenario()`, `AnalyzeTeamVariance()`
- Comments explain *why* (edge cases, algorithm differentiation), code is self-documenting

### Module Boundaries

```
┌─────────────────────────────────────────────────────┐
│  options/main.lua (UI Layer)                        │
│  - AceConfig-3.0 widget definitions                 │
│  - Button click handlers                            │
│  - Dropdown/slider callbacks                        │
│  - NO business logic                                │
└─────────────────────┬───────────────────────────────┘
                      │ Synchronous API calls
                      ▼
┌─────────────────────────────────────────────────────┐
│  core/fakePlayerService.lua (Service Layer)         │
│  - CreatePlayer(config) → PlayerProfile             │
│  - RunScenario(name) → PlayerProfile[]              │
│  - AnalyzeTeamVariance() → variance report          │
│  - NO UI dependencies (frames, widgets, etc.)       │
└─────────────────────┬───────────────────────────────┘
                      │ Returns data objects
                      ▼
┌─────────────────────────────────────────────────────┐
│  core/profiles.lua (State Management)               │
│  - AddFakePlayer(profile)                           │
│  - GetAllFakePlayers() → PlayerProfile[]            │
│  - Announces NEXTKEY_PROFILE_UPDATED                │
└─────────────────────────────────────────────────────┘
                      │ Event announcement
                      ▼
┌─────────────────────────────────────────────────────┐
│  ui/main.lua, ui/keystoneCards.lua (Consumers)      │
│  - Listen for NEXTKEY_PROFILE_UPDATED               │
│  - Re-render UI with updated data                   │
└─────────────────────────────────────────────────────┘
```

### Why This Design Is Modular

1. **Testability**: FakePlayerService can be unit-tested without loading UI
2. **Reusability**: Same service could be used by slash commands, automation scripts, or future test frameworks
3. **Maintainability**: UI changes don't require service changes (and vice versa)
4. **Clarity**: Each module has a single, well-defined responsibility

---

## Phase 1: UI Reorganization (Quick Wins)

**Goal**: Consolidate 40+ buttons into 6 logical sections with dropdowns

### New UI Structure

```
Developer Tools
├── 📁 Quick Teams (Dropdown)
│   ├── Mixed Skill (4 players)
│   ├── Beginner Team
│   ├── Expert Team
│   ├── High Keys Team
│   └── Clear All Fake Players
│
├── 📁 Algorithm Test Scenarios (Dropdown)
│   ├── IO Gap Test (MaxGroupIO vs SmartSort)
│   ├── Loot Priority Test (ItemNeed vs others)
│   ├── Coverage Test (PlayerCoverage edge case)
│   ├── Key Level Variance (different levels)
│   ├── Comprehensive Suite (all algorithms)
│   └── 📊 Show Algorithm Comparison
│
├── 📁 Custom Player Builder (Expandable Section)
│   ├── Basic Info (Name, Class, Spec, Role)
│   ├── Overall Skill Tier (8-tier dropdown)
│   ├── 🆕 Per-Dungeon Tuning (collapsible)
│   │   ├── Ara-Kara: [Slider: -4 to +4 levels from tier]
│   │   ├── Dawnbreaker: [Slider: -4 to +4]
│   │   ├── ... (8 dungeons)
│   │   └── Reset All to Tier Default
│   ├── Keystone Assignment
│   │   ├── Dungeon (dropdown)
│   │   ├── Level (slider 2-20)
│   │   └── Random Key (checkbox)
│   ├── 🆕 Loot Targeting (collapsible)
│   │   ├── Target Dungeons: [Multi-select: Ara, Dawn, Eco, etc.]
│   │   ├── Priority Items: [Show featured items from selected dungeons]
│   │   └── Random Loot (1-3 items)
│   ├── Addon Status (NextKey: Yes/No, RaiderIO: Yes/No)
│   └── [Create Player] [Create + Add to Party]
│
├── 📁 Keystone Scenarios (Dropdown)
│   ├── Diverse Keys (all different dungeons)
│   ├── Duplicate Keys (same dungeon, different levels)
│   ├── Level Spread (wide range 2-15)
│   ├── High Keys Only (12+)
│   └── Loot-Targeted Keys (based on tracked items)
│
├── 📁 Advanced Operations (Dropdown)
│   ├── Modify Existing Players
│   │   ├── [Player List Dropdown]
│   │   ├── Change Keystone
│   │   ├── Adjust IO (+/-500)
│   │   └── Add/Remove Loot Target
│   ├── Bulk Operations
│   │   ├── Add Loot to All Players
│   │   ├── Randomize All Keys
│   │   └── Reset All IO Scores
│   ├── 🆕 Save/Load Configurations
│   │   ├── Save Current Team (name input)
│   │   ├── Load Team (dropdown)
│   │   └── Delete Saved Team
│   └── 🆕 Team Variance Analyzer
│       ├── [Analyze Current Team]
│       └── Show Algorithm Rankings
│
└── 📁 Debug & Validation (Dropdown)
    ├── Show Player Details
    ├── Validate Team Diversity
    ├── 🆕 Algorithm Differentiation Report
    └── Export Team Config (chat link)
```

### Implementation Notes

**AceConfig-3.0 Structure:**

```lua
-- Top-level organization
developertoolsgroup = {
    type = "group",
    name = "Developer Tools",
    order = 8,
    args = {
        quickteams = {
            type = "group",
            name = "Quick Teams",
            inline = true,
            order = 1,
            args = { ... }
        },
        algorithmtests = {
            type = "group", 
            name = "Algorithm Test Scenarios",
            inline = true,
            order = 2,
            args = { ... }
        },
        custombuilder = {
            type = "group",
            name = "Custom Player Builder",
            inline = false,  -- Expandable
            order = 3,
            args = {
                perdungeontuning = {
                    type = "group",
                    name = "Per-Dungeon Tuning",
                    inline = false,
                    hidden = function() return not DB.showPerDungeonControls end,
                    args = { ... }
                },
                loottargeting = {
                    type = "group",
                    name = "Loot Targeting",
                    inline = false,
                    hidden = function() return not DB.showLootControls end,
                    args = { ... }
                }
            }
        },
        -- ... other sections
    }
}
```

**Key Changes:**
1. Replace 40+ flat buttons with nested groups
2. Use `inline = true` for dropdowns, `false` for expandable sections
3. Use `hidden` functions for progressive disclosure
4. Order by usage frequency (Quick Teams first)

---

## Phase 2: Enhanced Generation (Power Features)

### 2.1 Per-Dungeon Score Control

**Goal**: Allow precise per-dungeon score/level customization

**API Design:**

```lua
-- FakePlayerService enhancement
function FakePlayerService:CreatePlayer(config)
    -- Enhanced config structure
    config = {
        name = "Testplayer",
        class = "PALADIN",
        spec = "Protection",
        tier = "expert",  -- Base tier
        
        -- 🆕 Per-dungeon overrides
        dungeonOverrides = {
            [503] = { modifier = -2 },  -- Ara-Kara: 2 levels below tier
            [499] = { modifier = +3 },  -- Priory: 3 levels above tier
            [378] = { score = 2850 },   -- Halls: explicit score
        },
        
        keystone = { ... },
        lootTargets = { ... },
        hasNextKey = true,
        hasRaiderIO = true
    }
end

-- Internal: Enhanced score generation
function FakePlayerService:generateDungeonScores(tierData, dungeonOverrides)
    local scores = {}
    
    for dungeonID in pairs(NextKey.PortalData.dungeons) do
        local baseLevel = tierData.keystoneRange.min + random(0, tierData.keystoneRange.max - tierData.keystoneRange.min)
        
        -- Apply override
        local override = dungeonOverrides and dungeonOverrides[dungeonID]
        if override then
            if override.score then
                scores[dungeonID] = override.score
            elseif override.modifier then
                local adjustedLevel = math.max(2, math.min(20, baseLevel + override.modifier))
                scores[dungeonID] = IOCalculator:EstimateRunScore(dungeonID, adjustedLevel)
            end
        else
            -- Normal generation with expert/weak arrays
            scores[dungeonID] = IOCalculator:EstimateRunScore(dungeonID, baseLevel)
        end
    end
    
    return scores
end
```

**UI Implementation:**

```lua
-- Custom Builder: Per-Dungeon Tuning section
perdungeontuning = {
    type = "group",
    name = "Per-Dungeon Tuning",
    inline = false,
    args = {
        header = {
            type = "description",
            name = "Adjust performance per dungeon relative to base skill tier",
            order = 0
        }
    }
}

-- Dynamically add sliders for each dungeon
local order = 1
for dungeonID, dungeonData in pairs(NextKey.PortalData.dungeons) do
    perdungeontuning.args["dungeon_" .. dungeonID] = {
        type = "range",
        name = dungeonData.name,
        desc = string.format("Modifier: -4 (much weaker) to +4 (much stronger)"),
        min = -4,
        max = 4,
        step = 1,
        get = function() return DB.customBuilder.dungeonOverrides[dungeonID] or 0 end,
        set = function(_, val)
            DB.customBuilder.dungeonOverrides[dungeonID] = val
        end,
        order = order
    }
    order = order + 1
end

-- Reset button
perdungeontuning.args.reset = {
    type = "execute",
    name = "Reset All to Tier Default",
    func = function() DB.customBuilder.dungeonOverrides = {} end,
    order = 99
}
```

### 2.2 Loot Targeting Integration

**Goal**: Generate players with loot targets to test "Max Item Need" algorithm

**Data Model:**

```lua
-- Player profile enhancement (core/types/player.lua)
PlayerProfile = {
    -- ... existing fields ...
    
    -- 🆕 Loot targeting
    lootTargets = {
        [503] = {  -- Ara-Kara
            itemIDs = {219314, 219316},  -- Sacbrood, Swarmgland
            priority = "high"  -- high/medium/low
        },
        [499] = {  -- Priory
            itemIDs = {219310},  -- Bursting Lightshard
            priority = "medium"
        }
    },
    hasLootTargets = true  -- Quick check
}
```

**Generation API:**

```lua
-- FakePlayerService: Loot target generation
function FakePlayerService:assignRandomLootTargets(playerProfile, config)
    config = config or {}
    local numDungeons = config.numDungeons or random(1, 3)
    local itemsPerDungeon = config.itemsPerDungeon or random(1, 2)
    
    playerProfile.lootTargets = {}
    
    -- Get all dungeon IDs
    local dungeonIDs = {}
    for id in pairs(NextKey.PortalData.dungeons) do
        table.insert(dungeonIDs, id)
    end
    
    -- Shuffle and take numDungeons
    for i = 1, numDungeons do
        local idx = random(1, #dungeonIDs)
        local dungeonID = table.remove(dungeonIDs, idx)
        
        -- Get featured items for this dungeon
        local featuredItems = NextKey:GetFeaturedItems(dungeonID)
        if #featuredItems > 0 then
            local targetItems = {}
            for j = 1, math.min(itemsPerDungeon, #featuredItems) do
                local itemIdx = random(1, #featuredItems)
                table.insert(targetItems, table.remove(featuredItems, itemIdx))
            end
            
            playerProfile.lootTargets[dungeonID] = {
                itemIDs = targetItems,
                priority = ({"high", "medium", "low"})[random(1, 3)]
            }
        end
    end
    
    playerProfile.hasLootTargets = next(playerProfile.lootTargets) ~= nil
end

-- Quick preset: Generate loot-focused team
function FakePlayerService:CreateLootFocusedTeam()
    local players = {}
    
    -- Tank wants trinkets from Floodgate
    local tank = self:CreatePlayer({
        role = "TANK",
        tier = "competent",
        lootTargets = {
            [525] = { itemIDs = {232542, 232541}, priority = "high" }  -- Medichopper, Pacemaker
        }
    })
    table.insert(players, tank)
    
    -- Healer wants Priory trinkets
    local healer = self:CreatePlayer({
        role = "HEALER",
        tier = "skilled",
        lootTargets = {
            [499] = { itemIDs = {219309}, priority = "high" }  -- Tome of Light's Devotion
        }
    })
    table.insert(players, healer)
    
    -- DPS with varied targets
    for i = 1, 3 do
        local dps = self:CreatePlayer({
            role = "DAMAGER",
            tier = ({"average", "skilled", "expert"})[i],
            lootTargets = "random"  -- Auto-assign
        })
        table.insert(players, dps)
    end
    
    return players
end
```

**UI Integration:**

```lua
-- Custom Builder: Loot Targeting section
loottargeting = {
    type = "group",
    name = "Loot Targeting",
    inline = false,
    args = {
        targetdungeons = {
            type = "multiselect",
            name = "Target Dungeons",
            desc = "Select dungeons this player needs loot from",
            values = function()
                local dungeons = {}
                for id, data in pairs(NextKey.PortalData.dungeons) do
                    dungeons[id] = data.name
                end
                return dungeons
            end,
            get = function(_, dungeonID)
                return DB.customBuilder.lootDungeons[dungeonID] == true
            end,
            set = function(_, dungeonID, value)
                DB.customBuilder.lootDungeons[dungeonID] = value
            end,
            order = 1
        },
        itempreview = {
            type = "description",
            name = function()
                local text = "Featured items from selected dungeons:\\n"
                for dungeonID in pairs(DB.customBuilder.lootDungeons) do
                    local items = NextKey:GetFeaturedItems(dungeonID)
                    if #items > 0 then
                        local dungeonName = NextKey.PortalData.dungeons[dungeonID].name
                        text = text .. string.format("\\n%s:", dungeonName)
                        for _, itemID in ipairs(items) do
                            local itemName = GetItemInfo(itemID) or "Item " .. itemID
                            text = text .. string.format("\\n  - %s", itemName)
                        end
                    end
                end
                return text
            end,
            order = 2
        },
        randomloot = {
            type = "execute",
            name = "Assign Random Loot (1-3 items)",
            desc = "Automatically assign 1-3 featured items as loot targets",
            func = function()
                DB.customBuilder.lootDungeons = {}
                local numDungeons = random(1, 3)
                local allDungeons = {}
                for id in pairs(NextKey.PortalData.dungeons) do
                    table.insert(allDungeons, id)
                end
                for i = 1, numDungeons do
                    local idx = random(1, #allDungeons)
                    DB.customBuilder.lootDungeons[table.remove(allDungeons, idx)] = true
                end
            end,
            order = 3
        }
    }
}
```

### 2.3 Algorithm Testing Scenario Templates

**Goal**: Auto-generate edge cases that differentiate sorting algorithms

**Scenario Definitions:**

```lua
FakePlayerService.AlgorithmScenarios = {
    -- Test MaxGroupIO vs SmartSort
    io_gap = {
        name = "IO Gap Test",
        description = "Creates a scenario where MaxGroupIO and SmartSort produce different rankings",
        generator = function(self)
            -- Player 1: Very high IO, but only benefits from one dungeon
            local p1 = self:CreatePlayer({
                tier = "elite",
                dungeonOverrides = {
                    [503] = { modifier = -4 },  -- Weak in Ara-Kara
                    [499] = { modifier = +4 },  -- Strong in Priory only
                }
            })
            
            -- Player 2: Medium IO, but benefits from multiple dungeons
            local p2 = self:CreatePlayer({
                tier = "skilled",
                dungeonOverrides = {
                    [503] = { modifier = -2 },
                    [524] = { modifier = -2 },
                    [525] = { modifier = -2 },
                }
            })
            
            -- Player 3-4: Fill out party
            local p3 = self:CreatePlayer({ tier = "competent" })
            local p4 = self:CreatePlayer({ tier = "average" })
            
            -- Keys that expose the difference
            p1.keystone = { dungeonID = 499, level = 15 }  -- Priory
            p2.keystone = { dungeonID = 503, level = 12 }  -- Ara-Kara
            p3.keystone = { dungeonID = 524, level = 11 }  -- Dawnbreaker
            p4.keystone = { dungeonID = 525, level = 10 }  -- Floodgate
            
            return {p1, p2, p3, p4}
        end
    },
    
    -- Test ItemNeed vs others
    loot_priority = {
        name = "Loot Priority Test",
        description = "Creates a scenario where ItemNeed sorting differs significantly",
        generator = function(self)
            -- Player 1: High IO, no loot targets
            local p1 = self:CreatePlayer({
                tier = "expert",
                keystone = { dungeonID = 499, level = 14 }
            })
            
            -- Player 2: Medium IO, CRITICAL loot target
            local p2 = self:CreatePlayer({
                tier = "skilled",
                keystone = { dungeonID = 525, level = 12 },
                lootTargets = {
                    [525] = { itemIDs = {232542, 232541, 232543}, priority = "high" }
                }
            })
            
            -- Player 3: Low IO, high priority loot
            local p3 = self:CreatePlayer({
                tier = "competent",
                keystone = { dungeonID = 503, level = 10 },
                lootTargets = {
                    [503] = { itemIDs = {219314, 219316}, priority = "high" }
                }
            })
            
            -- Player 4: No loot, medium IO
            local p4 = self:CreatePlayer({
                tier = "average",
                keystone = { dungeonID = 378, level = 9 }
            })
            
            return {p1, p2, p3, p4}
        end
    },
    
    -- Test PlayerCoverage edge case
    coverage_test = {
        name = "Coverage Test",
        description = "Tests PlayerCoverage algorithm with uneven benefit distribution",
        generator = function(self)
            -- Player 1: Benefits from keys 1, 2, 3
            local p1 = self:CreatePlayer({
                tier = "skilled",
                dungeonOverrides = {
                    [503] = { modifier = -3 },
                    [499] = { modifier = -3 },
                    [378] = { modifier = -3 },
                }
            })
            
            -- Player 2: Benefits from keys 1, 2 only
            local p2 = self:CreatePlayer({
                tier = "competent",
                dungeonOverrides = {
                    [503] = { modifier = -2 },
                    [499] = { modifier = -2 },
                }
            })
            
            -- Player 3: Benefits from key 1 only
            local p3 = self:CreatePlayer({
                tier = "average",
                dungeonOverrides = {
                    [503] = { modifier = -4 },
                }
            })
            
            -- Player 4: Benefits from key 4 only (unique)
            local p4 = self:CreatePlayer({
                tier = "beginner",
                dungeonOverrides = {
                    [524] = { modifier = -4 },
                }
            })
            
            p1.keystone = { dungeonID = 503, level = 12 }
            p2.keystone = { dungeonID = 499, level = 11 }
            p3.keystone = { dungeonID = 378, level = 10 }
            p4.keystone = { dungeonID = 524, level = 8 }
            
            return {p1, p2, p3, p4}
        end
    },
    
    -- Comprehensive test (all 7 algorithms should produce different rankings)
    comprehensive = {
        name = "Comprehensive Test",
        description = "Creates maximum variance across all 7 sorting algorithms",
        generator = function(self)
            return {
                -- High IO, high key, no loot
                self:CreatePlayer({
                    tier = "elite",
                    keystone = { dungeonID = 499, level = 16 },
                    dungeonOverrides = { [499] = { modifier = +3 } }
                }),
                
                -- Medium IO, medium key, high-priority loot
                self:CreatePlayer({
                    tier = "skilled",
                    keystone = { dungeonID = 525, level = 12 },
                    lootTargets = {
                        [525] = { itemIDs = {232542, 232541}, priority = "high" }
                    }
                }),
                
                -- Low IO, low key, benefits many players
                self:CreatePlayer({
                    tier = "competent",
                    keystone = { dungeonID = 503, level = 8 },
                    dungeonOverrides = {
                        [503] = { modifier = -4 },
                        [524] = { modifier = -4 },
                        [378] = { modifier = -4 },
                    }
                }),
                
                -- Medium IO, very high key
                self:CreatePlayer({
                    tier = "average",
                    keystone = { dungeonID = 378, level = 15 },
                    dungeonOverrides = { [378] = { modifier = +4 } }
                })
            }
        end
    }
}
```

**UI Integration:**

```lua
-- Algorithm Test Scenarios dropdown
algorithmtests = {
    type = "group",
    name = "Algorithm Test Scenarios",
    inline = true,
    order = 2,
    args = {
        iogap = {
            type = "execute",
            name = "IO Gap Test",
            desc = "MaxGroupIO vs SmartSort differentiation",
            func = function()
                local players = FakePlayerService:RunScenario("io_gap")
                -- Add to party and show comparison
                for _, p in ipairs(players) do
                    Profiles:AddFakePlayer(p)
                end
                FakePlayerService:ShowAlgorithmComparison()
            end,
            order = 1
        },
        lootpriority = {
            type = "execute",
            name = "Loot Priority Test",
            desc = "ItemNeed vs other algorithms",
            func = function()
                local players = FakePlayerService:RunScenario("loot_priority")
                for _, p in ipairs(players) do
                    Profiles:AddFakePlayer(p)
                end
                FakePlayerService:ShowAlgorithmComparison()
            end,
            order = 2
        },
        coverage = {
            type = "execute",
            name = "Coverage Test",
            desc = "PlayerCoverage edge case",
            func = function()
                local players = FakePlayerService:RunScenario("coverage_test")
                for _, p in ipairs(players) do
                    Profiles:AddFakePlayer(p)
                end
                FakePlayerService:ShowAlgorithmComparison()
            end,
            order = 3
        },
        comprehensive = {
            type = "execute",
            name = "Comprehensive Suite",
            desc = "All 7 algorithms should produce different results",
            func = function()
                local players = FakePlayerService:RunScenario("comprehensive")
                for _, p in ipairs(players) do
                    Profiles:AddFakePlayer(p)
                end
                FakePlayerService:ShowAlgorithmComparison()
            end,
            order = 4
        },
        separator = {
            type = "header",
            name = "",
            order = 5
        },
        showcomparison = {
            type = "execute",
            name = "Show Algorithm Comparison",
            desc = "Compare how all 7 algorithms rank current keys",
            func = function()
                FakePlayerService:ShowAlgorithmComparison()
            end,
            order = 6
        }
    }
}
```

---

## Phase 3: Advanced Tools (Nice-to-Have)

### 3.1 Team Variance Analyzer

**Goal**: Visualize how different algorithms rank the same set of keys

**Implementation:**

```lua
function FakePlayerService:AnalyzeTeamVariance()
    -- Get all current keys
    local keystones = Keystones:GetAllKeystones()
    if #keystones == 0 then
        NextKey222.Debug:User("No keystones available to analyze")
        return
    end
    
    -- Run all 7 sorting algorithms
    local rankings = {}
    local algorithms = Sorting:GetAlgorithmsForContext("KEYSTONES")
    
    for _, algo in ipairs(algorithms) do
        local sorted = Sorting:SortKeystones(keystones, algo.name)
        rankings[algo.displayName] = {}
        for i, key in ipairs(sorted) do
            rankings[algo.displayName][key.dungeonID] = i
        end
    end
    
    -- Calculate variance metrics
    local variance = {
        totalAlgorithms = #algorithms,
        uniqueRankings = 0,
        maxDifference = 0,
        algorithmsAgreeing = 0
    }
    
    -- Count how many algorithms produce unique rankings
    local seen = {}
    for algoName, ranking in pairs(rankings) do
        local signature = table.concat(ranking, ",")
        if not seen[signature] then
            seen[signature] = true
            variance.uniqueRankings = variance.uniqueRankings + 1
        end
    end
    
    -- Find max rank difference for any single key
    for _, keystone in ipairs(keystones) do
        local ranks = {}
        for algoName, ranking in pairs(rankings) do
            table.insert(ranks, ranking[keystone.dungeonID])
        end
        table.sort(ranks)
        local diff = ranks[#ranks] - ranks[1]
        variance.maxDifference = math.max(variance.maxDifference, diff)
    end
    
    -- Display results
    self:DisplayVarianceReport(rankings, variance)
end

function FakePlayerService:DisplayVarianceReport(rankings, variance)
    print("|cff00ff00=== Algorithm Variance Report ===|r")
    print(string.format("Total Algorithms: %d", variance.totalAlgorithms))
    print(string.format("Unique Rankings: %d", variance.uniqueRankings))
    print(string.format("Max Rank Difference: %d positions", variance.maxDifference))
    
    if variance.uniqueRankings == 1 then
        print("|cffff0000WARNING: All algorithms produce IDENTICAL rankings!|r")
        print("This team does not test algorithm differentiation.")
    elseif variance.uniqueRankings < variance.totalAlgorithms / 2 then
        print("|cffffff00CAUTION: Low algorithm variance.|r")
        print("Consider using a test scenario for better coverage.")
    else
        print("|cff00ff00GOOD: Algorithms produce diverse rankings.|r")
    end
    
    print("\\n|cff00ff00Rankings by Algorithm:|r")
    for algoName, ranking in pairs(rankings) do
        local rankStr = ""
        for dungeonID, rank in pairs(ranking) do
            local dungeonName = NextKey.PortalData.dungeons[dungeonID].alias
            rankStr = rankStr .. string.format("%s(%d) ", dungeonName, rank)
        end
        print(string.format("  %s: %s", algoName, rankStr))
    end
end
```

### 3.2 Save/Load Team Configurations

**Goal**: Persist custom team setups for regression testing

**Data Structure:**

```lua
-- SavedVariables: NextKeyDB.global.savedTeams
NextKeyDB.global.savedTeams = {
    ["High Variance Test"] = {
        created = 1700000000,
        description = "Team that maximally differentiates all algorithms",
        players = {
            {
                name = "Testplayer1",
                class = "PALADIN",
                spec = "Protection",
                tier = "elite",
                dungeonOverrides = { [499] = { modifier = +4 } },
                keystone = { dungeonID = 499, level = 16 },
                lootTargets = {}
            },
            -- ... more players
        }
    },
    -- ... more saved teams
}
```

**API:**

```lua
function FakePlayerService:SaveCurrentTeam(name, description)
    local players = Profiles:GetAllFakePlayers()
    if #players == 0 then
        NextKey222.Debug:User("No fake players to save")
        return false
    end
    
    NextKeyDB.global.savedTeams = NextKeyDB.global.savedTeams or {}
    NextKeyDB.global.savedTeams[name] = {
        created = time(),
        description = description or "",
        players = self:SerializeTeam(players)
    }
    
    NextKey222.Debug:User(string.format("Saved team '%s' with %d players", name, #players))
    return true
end

function FakePlayerService:LoadTeam(name)
    local teamData = NextKeyDB.global.savedTeams[name]
    if not teamData then
        NextKey222.Debug:Error("Team not found:", name)
        return false
    end
    
    -- Clear existing fake players
    Profiles:ClearAllFakePlayers()
    
    -- Recreate players
    for _, playerData in ipairs(teamData.players) do
        local player = self:CreatePlayer(playerData)
        Profiles:AddFakePlayer(player)
    end
    
    NextKey222.Debug:User(string.format("Loaded team '%s' with %d players", name, #teamData.players))
    return true
end

function FakePlayerService:DeleteTeam(name)
    if NextKeyDB.global.savedTeams[name] then
        NextKeyDB.global.savedTeams[name] = nil
        NextKey222.Debug:User(string.format("Deleted team '%s'", name))
        return true
    end
    return false
end
```

### 3.3 Bulk Operations

**Goal**: Modify multiple fake players at once

**API:**

```lua
function FakePlayerService:BulkAddLoot(config)
    config = config or {}
    local numDungeons = config.numDungeons or 2
    local itemsPerDungeon = config.itemsPerDungeon or 1
    
    local players = Profiles:GetAllFakePlayers()
    for _, player in ipairs(players) do
        self:assignRandomLootTargets(player, {
            numDungeons = numDungeons,
            itemsPerDungeon = itemsPerDungeon
        })
    end
    
    NextKey222.Debug:User(string.format("Added loot targets to %d players", #players))
end

function FakePlayerService:BulkRandomizeKeys()
    local players = Profiles:GetAllFakePlayers()
    local dungeonIDs = {}
    for id in pairs(NextKey.PortalData.dungeons) do
        table.insert(dungeonIDs, id)
    end
    
    for _, player in ipairs(players) do
        local dungeonID = dungeonIDs[random(1, #dungeonIDs)]
        local level = random(2, 15)
        self:SetKeystone(player.name, dungeonID, level)
    end
    
    NextKey222.Debug:User(string.format("Randomized keys for %d players", #players))
end

function FakePlayerService:BulkAdjustIO(delta)
    local players = Profiles:GetAllFakePlayers()
    
    for _, player in ipairs(players) do
        -- Adjust all dungeon scores proportionally
        for dungeonID, score in pairs(player.mythicPlus.dungeonScores) do
            local newScore = math.max(0, score + delta)
            player.mythicPlus.dungeonScores[dungeonID] = newScore
        end
        
        -- Recalculate total IO
        player.mythicPlus.score = Scoring:CalculateTotalIO(player.mythicPlus.dungeonScores)
    end
    
    NextKey222.Debug:User(string.format("Adjusted IO by %+d for %d players", delta, #players))
end
```

---

## Implementation Roadmap

### Priority 1: Foundation (1-2 days)

**Goal**: UI reorganization + basic per-dungeon control

1. **UI Restructure** ([`options/main.lua`](../../options/main.lua:1))
   - [ ] Create new section hierarchy (6 main groups)
   - [ ] Migrate existing buttons to dropdowns
   - [ ] Add progressive disclosure (inline/expandable)
   - [ ] Test all existing generators still work

2. **Per-Dungeon API** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
   - [ ] Add `dungeonOverrides` to CreatePlayer config
   - [ ] Enhance [`generateDungeonScores()`](../../core/fakePlayerService.lua:373) to respect overrides
   - [ ] Add per-dungeon sliders to Custom Builder UI
   - [ ] Test: Create player weak in Ara, strong in Priory

3. **Validation**
   - [ ] All 40+ buttons work in new structure
   - [ ] No regressions in existing workflows
   - [ ] Per-dungeon overrides generate correct scores

### Priority 2: Loot Integration (1 day)

**Goal**: Enable loot-based testing

4. **Loot Targeting Model** ([`core/types/player.lua`](../../core/types/player.lua:1))
   - [ ] Add `lootTargets` field to PlayerProfile
   - [ ] Add `hasLootTargets` boolean flag

5. **Loot Generation** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
   - [ ] Implement `assignRandomLootTargets()`
   - [ ] Add loot controls to Custom Builder UI
   - [ ] Create "Loot Priority Test" scenario

6. **Sorting Integration** ([`core/sorting/algorithms/byItemNeed.lua`](../../core/sorting/algorithms/byItemNeed.lua:1))
   - [ ] Verify loot data is read correctly
   - [ ] Test Max Item Need with fake players

7. **Validation**
   - [ ] Create team with loot targets
   - [ ] Verify Max Item Need sorts differently than SmartSort
   - [ ] Test loot-targeted keys scenario

### Priority 3: Algorithm Testing (1-2 days)

**Goal**: Comprehensive algorithm validation

8. **Scenario Templates** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
   - [ ] Implement AlgorithmScenarios table
   - [ ] Add `RunScenario()` function
   - [ ] Create 4 core scenarios (IO Gap, Loot Priority, Coverage, Comprehensive)

9. **Variance Analyzer** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
   - [ ] Implement `AnalyzeTeamVariance()`
   - [ ] Create variance report UI
   - [ ] Add to Advanced Operations section

10. **UI Integration** ([`options/main.lua`](../../options/main.lua:1))
    - [ ] Add Algorithm Test Scenarios dropdown
    - [ ] Wire scenario buttons
    - [ ] Add "Show Algorithm Comparison" button

11. **Validation**
    - [ ] Run Comprehensive Suite
    - [ ] Verify all 7 algorithms produce different rankings
    - [ ] Document expected outcomes for each scenario

### Priority 4: Advanced Features (1 day, optional)

**Goal**: Power user tools

12. **Save/Load Teams** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
    - [ ] Implement save/load API
    - [ ] Add SavedVariables structure
    - [ ] Create UI in Advanced Operations

13. **Bulk Operations** ([`core/fakePlayerService.lua`](../../core/fakePlayerService.lua:1))
    - [ ] Implement BulkAddLoot()
    - [ ] Implement BulkRandomizeKeys()
    - [ ] Implement BulkAdjustIO()
    - [ ] Add UI controls

14. **Modify Existing Players** ([`options/main.lua`](../../options/main.lua:1))
    - [ ] Add player list dropdown
    - [ ] Add modify controls (keystone, IO, loot)
    - [ ] Wire to FakePlayerService APIs

---

## Testing Strategy

### Unit Tests

```lua
-- Test per-dungeon overrides
function TestPerDungeonOverrides()
    local player = FakePlayerService:CreatePlayer({
        tier = "skilled",
        dungeonOverrides = {
            [503] = { modifier = -4 },  -- Ara-Kara: much weaker
            [499] = { modifier = +4 },  -- Priory: much stronger
        }
    })
    
    local araScore = player.mythicPlus.dungeonScores[503]
    local prioryScore = player.mythicPlus.dungeonScores[499]
    
    assert(prioryScore > araScore, "Priory score should be higher than Ara-Kara")
    print("PASS: Per-dungeon overrides work correctly")
end

-- Test loot targeting
function TestLootTargeting()
    local player = FakePlayerService:CreatePlayer({
        tier = "competent",
        lootTargets = {
            [525] = { itemIDs = {232542}, priority = "high" }
        }
    })
    
    assert(player.hasLootTargets == true, "hasLootTargets should be true")
    assert(player.lootTargets[525] ~= nil, "Loot target should exist for Floodgate")
    print("PASS: Loot targeting works correctly")
end

-- Test algorithm variance
function TestAlgorithmVariance()
    local players = FakePlayerService:RunScenario("comprehensive")
    
    -- Add to profiles
    for _, p in ipairs(players) do
        Profiles:AddFakePlayer(p)
    end
    
    -- Analyze variance
    local rankings = {}
    local algorithms = Sorting:GetAlgorithmsForContext("KEYSTONES")
    local keystones = Keystones:GetAllKeystones()
    
    for _, algo in ipairs(algorithms) do
        local sorted = Sorting:SortKeystones(keystones, algo.name)
        rankings[algo.name] = sorted
    end
    
    -- Verify uniqueness
    local uniqueRankings = {}
    for algoName, ranking in pairs(rankings) do
        local signature = table.concat(ranking, ",")
        uniqueRankings[signature] = (uniqueRankings[signature] or 0) + 1
    end
    
    local numUnique = 0
    for _ in pairs(uniqueRankings) do numUnique = numUnique + 1 end
    
    assert(numUnique >= 5, "Comprehensive test should produce at least 5 unique rankings")
    print(string.format("PASS: Algorithm variance test (%d unique rankings)", numUnique))
end
```

### Integration Tests

1. **UI Navigation Test**
   - Open Developer Tools
   - Expand each section (Quick Teams, Algorithm Tests, etc.)
   - Verify no Lua errors

2. **Custom Builder Workflow**
   - Set base tier to "skilled"
   - Adjust Ara-Kara to -3
   - Adjust Priory to +2
   - Add 2 loot targets
   - Create player
   - Verify scores match expectations

3. **Algorithm Comparison Workflow**
   - Run "Comprehensive Suite"
   - Click "Show Algorithm Comparison"
   - Verify report shows variance metrics
   - Verify rankings differ across algorithms

4. **Save/Load Workflow**
   - Create custom team
   - Save as "Test Team"
   - Clear all fake players
   - Load "Test Team"
   - Verify all players restored correctly

---

## Migration Plan

### Backward Compatibility

**Preserved Behaviors:**
- All existing slash commands (`/nk test`, `/nk test preset mixed_skill`, etc.)
- All existing API calls from other modules
- SavedVariables structure (no breaking changes)

**Deprecated (but still functional):**
- Flat button layout (hidden behind "Legacy Mode" toggle)
- Old `CreatePlayer()` API (still works, new fields optional)

### Migration Steps

1. **Phase 1 Deploy** (UI reorganization)
   - New UI structure live
   - Old buttons still work via legacy mapping
   - User notification: "Developer Tools have been reorganized!"

2. **Phase 2 Deploy** (loot + per-dungeon)
   - New features available
   - Old workflows unchanged
   - Documentation updated

3. **Phase 3 Deploy** (advanced tools)
   - Optional features enabled
   - No migration required

---

## Success Metrics

### Quantitative

- [ ] UI buttons reduced from 40+ to ~15 primary controls
- [ ] 100% of sorting algorithms testable with dedicated scenarios
- [ ] Per-dungeon score control achieves ±500 IO accuracy
- [ ] Algorithm variance analyzer detects <3 unique rankings → warning

### Qualitative

- [ ] Developer can create "weak in X, strong in Y" player in <30 seconds
- [ ] Testing Max Item Need algorithm requires <5 clicks
- [ ] New contributor can understand UI organization without docs
- [ ] Comprehensive Suite produces measurably different algorithm rankings

---

## Future Enhancements

### Beyond v0.7.0

1. **Visual Keystone Builder**
   - Drag-and-drop keystone assignment
   - Visual dungeon map for click-to-assign

2. **Team Templates Library**
   - Community-shared test configurations
   - Import/export via string encoding

3. **AI-Assisted Testing**
   - "Generate team that maximizes variance"
   - Auto-detect algorithm edge cases

4. **Performance Profiling**
   - Measure sort times with different team configs
   - Identify performance bottlenecks

---

## Appendix: Current vs. Proposed UI

### Current Structure (Flat, 40+ buttons)

```
Developer Tools
├── Test: Generate 4 Mixed Skill
├── Test: Generate Beginner Team
├── Test: Generate Expert Team
├── Test: Generate High Keys Team
├── Test: Clear All Fake Players
├── Test: IO Gap Team
├── Test: Loot Focus Team
├── Test: Mixed Levels Team
├── Test: Uneven Benefit Team
├── Test: Comprehensive Test
├── Custom Player: Name [input]
├── Custom Player: Class [dropdown]
├── Custom Player: Spec [dropdown]
├── Custom Player: Tier [dropdown]
├── Custom Player: Keystone Dungeon [dropdown]
├── Custom Player: Keystone Level [slider]
├── Custom Player: Has NextKey [checkbox]
├── Custom Player: Has RaiderIO [checkbox]
├── Custom Player: Create
└── ... (20+ more buttons)
```

### Proposed Structure (Hierarchical, ~15 primary)

```
Developer Tools
├── 📁 Quick Teams (5 buttons)
├── 📁 Algorithm Test Scenarios (5 buttons + analyzer)
├── 📁 Custom Player Builder (expandable form)
│   ├── Basic Info
│   ├── 🆕 Per-Dungeon Tuning (collapsible, 8 sliders)
│   ├── Keystone
│   ├── 🆕 Loot Targeting (collapsible, multi-select)
│   └── Create
├── 📁 Keystone Scenarios (5 buttons)
├── 📁 Advanced Operations
│   ├── Modify Existing
│   ├── Bulk Operations (3 buttons)
│   └── 🆕 Save/Load (3 buttons)
└── 📁 Debug & Validation (4 buttons)
```

**Reduction**: 40+ → 15 primary + expandable sections  
**Improvement**: Logical grouping, progressive disclosure, intent-based navigation

---

**Document Status**: Draft  
**Next Steps**: Review with development team, prioritize phases, begin implementation
