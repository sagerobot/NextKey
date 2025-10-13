# Fake Player System Overhaul - Realistic IO Distribution

## Summary
Completely overhauled the fake player generation system to use realistic Mythic+ IO scores based on actual TWW Season 3 US distribution data from raider.io. Added global addon control checkboxes that apply to all preset buttons, making it easy to test with/without addons at any skill level.

## Key Changes

### 1. Realistic IO Tiers (Based on TWW S3 US Cutoffs)
Replaced the old 6-tier system with an 8-tier system based on actual percentile data:

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

### 2. Global Addon Control System
Added two checkboxes in the options UI that control addon usage for ALL generated players:

- **"Players Have NextKey"** - Toggle whether generated players have NextKey addon
- **"Players Have RaiderIO"** - Toggle whether generated players have RaiderIO addon
- Both checkboxes apply to ALL preset buttons (Mixed Skill, Beginner, Expert, High Keys, Custom)
- Visual status indicator shows current configuration (green = active, red = both disabled warning)

**Example Use Cases:**
- Both ON: Test full addon integration (default)
- RaiderIO only: Test NextKey with RaiderIO data sources
- NextKey only: Test exclusive NextKey broadcast scenarios
- Both OFF: Test pure fallback mode with no addon data

### 3. Updated Preset Teams

**Mixed Skill Team (Recommended)**
- Expert (3100+ IO)
- Skilled (2900+ IO)
- Competent (2500+ IO)
- Average (2000+ IO)

**Beginner Team**
- Beginner (1000-1500 IO)
- Casual (1500-2000 IO)
- Casual (1500-2000 IO)
- Average (2000+ IO)

**Expert Team**
- Title (3600+ IO)
- Elite (3300+ IO)
- Expert (3100+ IO)
- Skilled (2900+ IO)

**High Keys Team** (NEW)
- Title (3600+ IO)
- Title (3600+ IO)
- Elite (3300+ IO)
- Expert (3100+ IO)

### 4. Simplified Custom Team Builder
Removed per-player addon sliders, now just:
- **Team Size slider** (1-12 players)
- **Generate Custom Team button** - Creates random IO players using global addon settings

### 5. Technical Implementation

**Files Modified:**
- `core/fakePlayerService.lua` - Updated SKILL_TIERS with realistic data, modified GeneratePreset() and GenerateRandomPlayers() to read global addon config from `db.global.debug.presetAddonConfig`
- `options/main.lua` - Added addon control checkboxes (order 2.67-2.69), updated preset descriptions, removed old addon-specific buttons, simplified custom builder

**Addon Config Storage:**
```lua
-- Stored in AceDB global state
NextKey222.Addon.db.global.debug.presetAddonConfig = {
    nextkey = true/false,  -- NextKey enabled
    raiderio = true/false  -- RaiderIO enabled
}
```

**Default:** Both addons enabled (matches production behavior)

### 6. Benefits

✅ **Realistic Testing** - IO distributions match actual player population  
✅ **Simplified UX** - One set of addon controls affects all presets  
✅ **Flexible Testing** - Easy to test any skill level with any addon combination  
✅ **Accurate Simulation** - Key levels and timing chances match real-world data  
✅ **Better Coverage** - 8 tiers instead of 6, covers title holders to beginners  
✅ **Clear Feedback** - Visual status indicator shows current addon configuration  

### 7. Testing Workflow

1. Open `/nk opt` → Debug Tools
2. Set addon checkboxes (default: both ON)
3. Click any preset button to generate team
4. All 4 players will have the selected addon configuration
5. Change checkboxes and regenerate to test different scenarios
6. Use Custom Team Builder for larger groups (up to 12 players)

### 8. Migration Notes

**Breaking Changes:**
- Old preset configs no longer include per-player addon settings
- `GenerateRandomPlayers()` second parameter (addonMix) is now deprecated
- All fake player generation now uses global addon config

**Backwards Compatibility:**
- Defaults to both addons enabled if config not set
- Existing saved variables unaffected
- Old slash commands still work

### 9. Future Enhancements

Potential additions:
- Per-tier addon adoption rates (e.g., 95% of title holders have addons, 20% of beginners)
- Regional variations (US vs EU vs KR distributions)
- Season-specific presets (historical season data)
- Role-specific IO variations (tanks/healers typically lower IO)
- Dungeon preference patterns (some players push specific dungeons)

## Credits
IO distribution data sourced from:
- https://raider.io/mythic-plus/cutoffs/season-tww-3/us
- TWW Season 3 US region percentile cutoffs (as of Jan 2025)
