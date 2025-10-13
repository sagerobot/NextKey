# FakePlayerService Quick Reference

**Quick guide for developers working with fake/test players**

---

## Basic Usage

### Generate Test Players

```lua
-- Generate 4 realistic fake players (default)
/nk test

-- Generate a preset team
/nk test preset mixed_skill    -- Mixed skill levels (default)
/nk test preset beginner       -- Low skill team
/nk test preset expert         -- High skill team
/nk test preset high_keys      -- Very high keys team

-- Custom addon mix (2 NextKey, 1 RaiderIO, 1 None)
/nk test mixed 2 1 1

-- Clear all fake players
/nk test clear

-- Show service status
/nk test status
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
    tier = "expert",                -- Optional: elite, expert, skilled, average, casual, beginner
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

---

## Preset Configurations

### Available Presets

| Preset | Description | Players |
|--------|-------------|---------|
| `mixed_skill` | Realistic party composition | 1 expert (NK+RIO), 1 skilled (NK+RIO), 1 average (RIO), 1 casual (None) |
| `beginner` | Low skill group learning keys | 1 beginner (None), 2 casual (1 None, 1 RIO), 1 average (NK+RIO) |
| `expert` | High skill push group | 3 expert (NK+RIO), 1 skilled (NK+RIO) |
| `high_keys` | Very high key team | 2 elite (NK+RIO), 2 expert (NK+RIO) |

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

| Tier | Key Levels | Timing % | Description |
|------|-----------|----------|-------------|
| `elite` | 28-30 | 95% | Top 5% of players |
| `expert` | 22-27 | 85% | Next 10% |
| `skilled` | 16-21 | 70% | Next 20% |
| `average` | 10-15 | 50% | Middle 35% |
| `casual` | 6-9 | 30% | Next 20% |
| `beginner` | 2-5 | 15% | Bottom 10% |

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

## Related Documentation

- **Full Analysis**: `Documentation/FAKE_PLAYER_ANALYSIS.md`
- **Implementation Summary**: `Documentation/PHASE_1_COMPLETE.md`
- **AI Development Guide**: `AI_DEVELOPMENT_GUIDE.md`

---

**Last Updated**: October 11, 2025  
**Phase**: 1 Complete, 2-7 Pending
