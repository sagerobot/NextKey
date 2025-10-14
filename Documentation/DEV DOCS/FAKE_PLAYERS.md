# NextKey Fake Player System - Complete Guide

## Overview

The NextKey Fake Player System provides a comprehensive testing framework for simulating realistic Mythic+ party compositions with accurate IO scores, keystones, and addon configurations. This system is essential for testing UI behavior, IO calculations, and addon integration without requiring real players.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Quick Reference](#quick-reference)
3. [API Reference](#api-reference)
4. [Integration with Existing Systems](#integration-with-existing-systems)
5. [Preset Configurations](#preset-configurations)
6. [Skill Tiers](#skill-tiers)
7. [Debug Logging](#debug-logging)
8. [Common Patterns](#common-patterns)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)
11. [Migration from Legacy System](#migration-from-legacy-system)

---

## System Overview

### Key Features

- **Realistic IO Distribution**: Based on actual TWW Season 3 US percentile data
- **Global Addon Control**: Toggle NextKey/RaiderIO presence for all generated players
- **Preset Teams**: Quick generation of balanced party compositions
- **Standard Profile Format**: Fake players use identical data structures as real players
- **Performance Monitoring**: Track generation and integration performance

### Architecture

```
FakePlayerService → fakePlayerStorage (in-memory)
                    ↓
                    GetAllPlayers()
                    ↓
      ┌──────────────┴──────────────┐
      │                             │
Options UI                   Main UI (keystones.lua)
   - Status Display              - GetAvailableKeys()
   - Edit Controls               - GetPartyMemberNames()
   - Preset Buttons              ↓
                            IOCalculator
                               - CalculateIORange()
                               ↓
                            Tooltips with IO gain
```

---

## Quick Reference

### Generate Test Players

```lua
-- Generate 4 realistic fake players (default)
/nk test

-- Generate a preset team
/nk test preset mixed_skill    -- Mixed skill levels (default)
/nk test preset beginner       -- Low skill team
/nk test preset expert         -- High skill team
/nk test preset high_keys      -- Very high keys team

-- Clear all fake players
/nk test clear

-- Show service status
/nk test status
```

### Slash Commands

```bash
# Basic operations
/nk test                           # Generate 4 random fake players
/nk test preset [name]             # Generate specific preset
/nk test clear                     # Remove all fake players
/nk test status                    # Show current status

# Custom generation
/nk test mixed [nextkey] [raiderio] [none]  # Custom addon mix
/nk test custom [count]            # Generate specific number
```

---

## API Reference

### Creating Players

```lua
-- Create a single player with defaults
local playerName = NextKey222.FakePlayerService:CreatePlayer()

-- Create a player with specific configuration
local playerName = NextKey222.FakePlayerService:CreatePlayer({
    name = "TestTank",              -- Optional, auto-generated if not provided
    class = "PALADIN",              -- Optional, random if not provided
    tier = "expert",                -- Optional: title, elite, expert, skilled, competent, average, casual, beginner
    keystoneLevel = 20,             -- Optional, auto-generated if not provided
    keystoneDungeon = 375,          -- Optional, requires keystoneLevel
    addonStatus = {                 -- Optional
        nextkey = true,
        raiderio = true
    }
})

-- playerName will be normalized to "TestTank-RealmName" format
```

### Getting Player Data

```lua
-- Check if a player is fake
local isFake = NextKey222.FakePlayerService:IsFakePlayer("FakePlayer1-Realm")

-- Get standard PlayerProfile (same format as real players!)
local profile = NextKey222.FakePlayerService:GetProfile("FakePlayer1-Realm")
-- profile.io          -- Total IO score
-- profile.class       -- Class token
-- profile.dungeonScores[dungeonID]  -- Per-dungeon scores
-- profile.addonStatus -- Addon presence

-- Get keystone
local keystone = NextKey222.FakePlayerService:GetKeystone("FakePlayer1-Realm")
-- keystone.dungeonID
-- keystone.level

-- Get all fake player names
local names = NextKey222.FakePlayerService:GetAllPlayerNames()
for _, name in ipairs(names) do
    print(name)
end
```

### Modifying Players

```lua
local playerName = "FakePlayer1-Realm"

-- Set a dungeon best
NextKey222.FakePlayerService:SetDungeonBest(
    playerName,
    375,        -- dungeonID
    18,         -- level
    true,       -- timed
    2           -- chests (0-3)
)

-- Set keystone
NextKey222.FakePlayerService:SetKeystone(playerName, 376, 20)

-- Set addon status
NextKey222.FakePlayerService:SetAddonStatus(playerName, {
    nextkey = true,
    raiderio = true
})
```

### Management

```lua
-- Remove a specific player
NextKey222.FakePlayerService:RemovePlayer("FakePlayer1-Realm")

-- Clear all fake players
local count = NextKey222.FakePlayerService:ClearAllPlayers()
print("Removed " .. count .. " fake players")

-- Get service status
local status = NextKey222.FakePlayerService:GetStatus()
-- status.initialized    -- boolean
-- status.playerCount    -- number
-- status.defaultRealm   -- string
```

---

## Integration with Existing Systems

### ProfilesService Integration

The ProfilesService automatically handles fake players through the DebugAdapter:

```lua
-- This works for both real AND fake players!
local profile = NextKey222.ProfilesService:BuildProfileForPlayer(playerName)

-- You don't need to check if it's fake or real
-- The profile format is identical
if profile then
    print("IO:", profile.io)
    print("Class:", profile.class)
    for dungeonID, scores in pairs(profile.dungeonScores) do
        print("Dungeon", dungeonID, "score:", scores.bestScore)
    end
end
```

### DebugAdapter Integration

```lua
-- Check if player is fake (uses FakePlayerService)
local isFake = NextKey222.DebugAdapter:IsDebugPlayer(playerName)

-- Get profile (returns standard PlayerProfile)
local profile = NextKey222.DebugAdapter:GetProfile(playerName)

-- Get all debug players
local players = NextKey222.DebugAdapter:GetAllDebugPlayers()
```

### UI Integration

Fake players automatically appear in:
- Main UI keystone list
- Options panel status display
- IO gain calculations
- Tooltip information
- Edit controls

---

## Preset Configurations

### Available Presets

| Preset | Description | Players | Composition |
|--------|-------------|---------|-------------|
| `mixed_skill` | Realistic party composition | 4 | 1 expert, 1 skilled, 1 average, 1 casual |
| `beginner` | Low skill group learning keys | 4 | 1 beginner, 2 casual, 1 average |
| `expert` | High skill push group | 4 | 1 title, 1 elite, 2 expert |
| `high_keys` | Very high key team | 4 | 2 title, 1 elite, 1 expert |

### Global Addon Control

Two checkboxes in the options UI control addon usage for ALL generated players:

- **"Players Have NextKey"** - Toggle whether generated players have NextKey addon
- **"Players Have RaiderIO"** - Toggle whether generated players have RaiderIO addon

Both checkboxes apply to ALL preset buttons and custom generation.

### Custom Presets

```lua
-- Generate with custom count (cycles through preset specs)
NextKey222.FakePlayerService:GeneratePreset("mixed_skill", 8)  -- 8 players

-- Generate with custom addon mix
NextKey222.FakePlayerService:GenerateRandomPlayers(5, {
    nextkey = 3,    -- 3 players with NextKey + RaiderIO
    raiderio = 1,   -- 1 player with RaiderIO only
    none = 1        -- 1 player with no addons
})
```

---

## Skill Tiers

Based on actual TWW Season 3 US percentile data:

| Tier | Percentile | Key Levels | IO Range | Description |
|------|------------|------------|----------|-------------|
| **title** | Top 0.1% | 20-22 | 3600-3800 | Title holders, all 20s+ |
| **elite** | Top 1% | 18-20 | 3300-3600 | Elite pushers, 18-19s |
| **expert** | Top 5% | 15-18 | 3100-3400 | Expert players, 15-17s |
| **skilled** | Top 10% | 13-15 | 2900-3100 | KSL territory, 13-14s |
| **competent** | Top 25% | 11-13 | 2500-2900 | KSH territory, 11-12s |
| **average** | Top 50% | 7-11 | 2000-2600 | KSM territory, 7-10s |
| **casual** | Top 60% | 4-7 | 1500-2000 | KSC territory, 4-6s |
| **beginner** | Top 70% | 2-4 | 1000-1500 | New players, 2-3s |

### Tier Characteristics

- **Key Levels**: Typical key range for players in this tier
- **Timing %**: Approximate chance of timing keys at this level
- **IO Range**: Realistic IO scores based on raider.io data
- **Dungeon Scores**: Per-dungeon scores calculated from tier characteristics

---

## Debug Logging

### Enable Debug Output

```lua
-- Enable debug categories
NextKey222.Debug.enabled = true
NextKey222.Debug.categories.fakeplayerservice = true
NextKey222.Debug.categories.debug = true
NextKey222.Debug.categories.profiles = true

-- Now generate players to see detailed logs
/nk test preset expert
```

### View Service Stats

```lua
-- Log statistics
NextKey222.FakePlayerService:LogStats()

-- Output example:
-- "Status: Initialized | Players: 4 | Storage: in-memory | Realm: Area52"
```

### Debug Categories

- `fakeplayerservice` - Player generation and management
- `debug` - Debug system self-monitoring
- `profiles` - Profile building and caching
- `ui` - UI integration and display

---

## Common Patterns

### Pattern 1: Test UI with Fake Players

```lua
-- Generate test players
NextKey222.FakePlayerService:GeneratePreset("mixed_skill")

-- Open UI
/nk show

-- UI should display fake players identically to real players
-- Check: names, classes, IO scores, keystones all visible
```

### Pattern 2: Test Keystones Detection

```lua
-- Generate players
NextKey222.FakePlayerService:GeneratePreset("expert")

-- Get available keys (should include fake player keystones)
local keys = NextKey222.Addon:GetAvailableKeys()

-- Verify fake keystones appear
for _, key in ipairs(keys) do
    print(key.ownerName, key.dungeonID, key.level)
end
```

### Pattern 3: Test IO Calculator

```lua
-- Generate player
local playerName = NextKey222.FakePlayerService:CreatePlayer({
    tier = "expert"
})

-- Get profile
local profile = NextKey222.ProfilesService:BuildProfileForPlayer(playerName)

-- Verify IO calculation
print("Total IO:", profile.io)  -- Should be realistic for tier

-- Check per-dungeon scores
for dungeonID, scores in pairs(profile.dungeonScores) do
    print("Dungeon", dungeonID, ":", scores.bestScore, "at level", scores.bestLevel)
end
```

### Pattern 4: Test Addon Detection

```lua
-- Create player without addon
local playerName = NextKey222.FakePlayerService:CreatePlayer({
    addonStatus = { nextkey = false, raiderio = false }
})

-- Verify addon status
local profile = NextKey222.ProfilesService:BuildProfileForPlayer(playerName)
print("Has NextKey:", profile.addonStatus.nextkey)     -- false
print("Has RaiderIO:", profile.addonStatus.raiderio)   -- false
```

---

## Troubleshooting

### Players Not Appearing in UI?

```lua
-- Check service is initialized
/dump NextKey222.FakePlayerService:IsInitialized()  -- Should be true

-- Check players exist
/dump NextKey222.FakePlayerService:GetAllPlayerNames()  -- Should show player names

-- Check profiles are accessible
local names = NextKey222.FakePlayerService:GetAllPlayerNames()
for _, name in ipairs(names) do
    local profile = NextKey222.ProfilesService:BuildProfileForPlayer(name)
    /dump profile ~= nil  -- Should be true
end

-- Enable debug logging to see what's happening
NextKey222.Debug.enabled = true
NextKey222.Debug.categories.fakeplayerservice = true
NextKey222.Debug.categories.ui = true
```

### Profile Returns Nil?

```lua
-- Check player name format (must include realm)
local wrongName = "FakePlayer1"        -- ❌ Missing realm
local rightName = "FakePlayer1-Realm"  -- ✅ Correct

-- Service auto-normalizes names
local profile = NextKey222.FakePlayerService:GetProfile("FakePlayer1")
-- Automatically converted to "FakePlayer1-YourRealm"
```

### Cache Not Updating?

```lua
-- Service fires events automatically, but you can manually invalidate
NextKey222.ProfilesService:InvalidateCache("FakePlayer1-Realm")

-- Or invalidate all
NextKey222.ProfilesService:InvalidateCache()

-- Check cache stats
local stats = NextKey222.ProfilesService:GetCacheStats()
/dump stats
```

---

## Best Practices

### ✅ DO

- Use the service for all fake player operations
- Let ProfilesService handle profile building
- Use preset teams for consistent testing scenarios
- Enable debug logging when troubleshooting
- Clear fake players between test sessions

### ❌ DON'T

- Access `NextKey.db.global.debug.players` directly
- Manually cache invalidate (events handle this)
- Hardcode player names without realm suffix
- Mix fake and real player data structures
- Assume fake players persist across reloads (in-memory only)

---

## Migration from Legacy System

If you have old code accessing fake players directly:

```lua
-- OLD (deprecated)
local dbg = NextKey222.Addon:EnsureDebug()
local fakePlayer = dbg.players[1]

-- NEW (preferred)
local playerName = "FakePlayer1-Realm"
local profile = NextKey222.FakePlayerService:GetProfile(playerName)

-- OLD (deprecated)
NextKey222.Addon:AddRandomFakePlayers(4)

-- NEW (preferred)
NextKey222.FakePlayerService:GenerateRandomPlayers(4)

-- OLD (deprecated)  
if NextKey222.Addon.UI:GetFakePlayerData(playerName) then
    -- handle fake player
end

-- NEW (preferred)
if NextKey222.FakePlayerService:IsFakePlayer(playerName) then
    -- handle fake player
end
```

**Note**: Old API still works via wrapper functions, but new code should use FakePlayerService directly.

---

## Data Structures

### Player Profile Format

```lua
playerData = {
    id = 1,
    name = "FakePlayer1-Dalaran",
    class = "WARRIOR",
    tier = "skilled",
    io = 1234,
    keystone = { dungeonID = 503, level = 8 },
    dungeonScores = {
        [501] = { score = 150, level = 10, timed = true },
        [502] = { score = 145, level = 9, timed = false },
        -- ... etc
    },
    addonStatus = { nextkey = true, raiderio = true },
    dataSource = "fake_player_service"
}
```

### Standard PlayerProfile Contract

FakePlayerService implements the standard `PlayerProfile` format used throughout the addon:
- `name` - Full player name with realm
- `class` - Class token (WARRIOR, MAGE, etc.)
- `io` - Total IO score
- `dungeonScores{}` - Per-dungeon breakdown
- `addonStatus{}` - Addon presence flags
- `dataSource` - Where data came from

---

## Known Limitations

1. **Not Persisted**: Fake players clear on `/reload` (by design for testing)
2. **No Communications**: Fake players don't share data via addon comms (not needed)
3. **Party-Only**: Fake players treated as party members, not guild members

---

## Future Enhancements

### Short-Term
1. Add debug command to inspect fake player data: `/nk dump fakeplayer FakePlayer1`
2. Add validation warnings if dungeon scores are missing

### Long-Term
1. Refactor `IOCalculator:GetPlayerDungeonScore()` to use ProfilesService exclusively
2. Remove redundant fallback chains
3. Add profile schema validation system

---

## Credits

IO distribution data sourced from:
- https://raider.io/mythic-plus/cutoffs/season-tww-3/us
- TWW Season 3 US region percentile cutoffs (as of Jan 2025)

---

**Last Updated**: October 13, 2025  
**Version**: Consolidated Documentation v1.0