# Custom Fake Player Creation Guide

## Overview

NextKey now supports creating fully customized fake players with precise control over all attributes. This feature is designed for testing specific scenarios, edge cases, and complex group compositions.

## Access Methods

### Method 1: GUI Builder (Recommended)

The graphical interface provides the easiest way to create custom fake players with full control.

**Access:**
```
/nk config → Debug System → Fake Player Tools → Custom Player Builder
```

**Features:**
- Player name input with validation
- Class dropdown (13 classes)
- Specialization dropdown (auto-filtered by class)
- Skill tier presets OR manual IO score
- Keystone dungeon and level selection
- Real-time preview before creation
- Auto-reset after successful creation

**Example Workflow:**
1. Open `/nk config`
2. Navigate to Debug System tab
3. Scroll to "Custom Player Builder" section
4. Fill out the form:
   - Name: "Ryuzaki"
   - Class: Evoker
   - Spec: Preservation (HEALER)
   - Tier: Expert (or Manual IO: 3200)
   - Keystone: Ara-Kara +15
5. Review the preview summary
6. Click "Create Player"
7. Form resets, player is added to your group

### Method 2: Slash Command (Quick Access)

For rapid creation when you know exactly what you want.

**Syntax:**
```
/nk test custom <name> <class> [specID] [io]
```

**Arguments:**
- `name` - Player name (required, realm auto-added)
- `class` - WoW class token (required, e.g., EVOKER, WARRIOR)
- `specID` - Optional: Specific spec ID (e.g., 1468 for Preservation)
- `io` - Optional: Total IO score (0-4000)

**Examples:**
```bash
# Basic - just name and class
/nk test custom Ryuzaki EVOKER

# With specific spec and IO
/nk test custom TankMain WARRIOR 73 3500

# Healer with specific IO
/nk test custom Heals PRIEST 256 2800
```

## Available Customization Options

### Basic Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| **Name** | String | Custom player name following **Blizzard's official naming rules** |
| **Class** | Dropdown | WARRIOR, PALADIN, HUNTER, ROGUE, PRIEST, DEATHKNIGHT, SHAMAN, MAGE, WARLOCK, MONK, DRUID, DEMONHUNTER, EVOKER |
| **Spec** | Dropdown | Spec selection (filtered by class, or "Random") |

**Blizzard's Official Character Naming Rules:**
1. ✅ **Length:** Must be 2-12 characters long
2. ✅ **Accented Characters:** Supported (é, ñ, ü, etc.)
3. ❌ **Numbers and Symbols:** Not supported
4. ❌ **Mixed Capitals and Spaces:** Not supported

**Valid Capitalization:**
- All lowercase: `tank`, `heals`, `ryuzaki`
- All uppercase: `TANK`, `HEALS`, `RYUZAKI`
- Proper case: `Tank`, `Heals`, `Ryuzaki`
- ✅ **Valid:** `tank`, `Tank`, `TANK`, `José`, `josé`, `JOSÉ`
- ❌ **Invalid:** `TaNk`, `tAnK`, `RyUzAkI` (mixed capitals)

**Invalid Examples:**
- `Player1` - Contains number
- `My Tank` - Contains space
- `Ryu-zaki` - Contains symbol
- `DPS!` - Contains symbol
- `TaNk` - Mixed capitals (not all one case)

### Scoring Options

**Tier Presets** (auto-generates realistic dungeon scores):
- Title (3600-3800 IO) - Top 0.1%, all 20s+
- Elite (3300-3600 IO) - Top 1%, 18-19s
- Expert (3100-3400 IO) - Top 5%, 15-17s
- Skilled (2900-3100 IO) - Top 10%, 13-14s (KSL)
- Competent (2500-2900 IO) - Top 25%, 11-12s (KSH)
- Average (2000-2600 IO) - Top 50%, 7-10s (KSM)
- Casual (1500-2000 IO) - Top 60%, 4-6s (KSC)
- Beginner (1000-1500 IO) - Top 70%, 2-3s

**Manual IO Score:**
- Range: 0 - 4000
- Step: 10
- Only used if no tier preset selected

### Keystone Options

| Option | Type | Description |
|--------|------|-------------|
| **Dungeon** | Dropdown | Active season dungeons, or "No Keystone" |
| **Level** | Slider | 2-30 (disabled if no dungeon selected) |

## Spec ID Reference

### Tanks
- 73 - Warrior (Protection)
- 66 - Paladin (Protection)
- 250 - Death Knight (Blood)
- 268 - Monk (Brewmaster)
- 104 - Druid (Guardian)
- 581 - Demon Hunter (Vengeance)

### Healers
- 65 - Paladin (Holy)
- 256 - Priest (Discipline)
- 257 - Priest (Holy)
- 264 - Shaman (Restoration)
- 270 - Monk (Mistweaver)
- 105 - Druid (Restoration)
- 1468 - Evoker (Preservation)

### DPS (Selected Examples)
- 71 - Warrior (Arms)
- 72 - Warrior (Fury)
- 70 - Paladin (Retribution)
- 253 - Hunter (Beast Mastery)
- 254 - Hunter (Marksmanship)
- 255 - Hunter (Survival)
- 259 - Rogue (Assassination)
- 260 - Rogue (Outlaw)
- 261 - Rogue (Subtlety)
- 258 - Priest (Shadow)
- 251 - Death Knight (Frost)
- 252 - Death Knight (Unholy)
- 262 - Shaman (Elemental)
- 263 - Shaman (Enhancement)
- 62 - Mage (Arcane)
- 63 - Mage (Fire)
- 64 - Mage (Frost)
- 265 - Warlock (Affliction)
- 266 - Warlock (Demonology)
- 267 - Warlock (Destruction)
- 269 - Monk (Windwalker)
- 102 - Druid (Balance)
- 103 - Druid (Feral)
- 577 - Demon Hunter (Havoc)
- 1467 - Evoker (Devastation)
- 1473 - Evoker (Augmentation)

## Common Use Cases

### 1. Testing Specific Group Compositions

Create a balanced M+ group:
```bash
/nk test custom MainTank WARRIOR 73 3200
/nk test custom Healer1 EVOKER 1468 3100
/nk test custom DPS1 HUNTER 253 3000
/nk test custom DPS2 MAGE 63 2900
/nk test custom DPS3 ROGUE 260 2800
```

### 2. Testing IO Range Scenarios

Create players at specific IO breakpoints:
```bash
/nk test custom Title PALADIN 70 3700    # Title cutoff
/nk test custom KSH SHAMAN 263 2900      # KSH threshold
/nk test custom KSM PRIEST 258 2400      # KSM threshold
```

### 3. Testing Specific Dungeon Scenarios

Use the GUI builder to:
1. Create 4 players each with different dungeons at +15
2. All with Expert tier IO
3. Mix of roles for composition testing

### 4. Edge Cases & Debugging

Create unusual configurations:
- Very low IO players (beginner tier)
- Very high IO players (title tier)
- Players with no keystones
- Players with specific specs for role validation

## Validation & Error Handling

### Automatic Validation

The system validates:
- ✅ **Name uniqueness** (prevents duplicates)
- ✅ **Name length** (2-12 characters)
- ✅ **Name format** (letters only, no spaces/numbers/symbols - WoW character naming rules)
- ✅ **Valid class tokens**
- ✅ **Spec matches class** (if both provided)
- ✅ **Spec ID existence** in database

### Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| "Player already exists" | Duplicate name | Use a different name or clear existing player |
| "Invalid spec ID" | Spec ID not found | Check Spec ID Reference above |
| "Spec doesn't match class" | Spec/class mismatch | Ensure spec belongs to selected class |
| "Please enter a player name" | Name field empty | Fill in the name field |
| "Player name must be 2-12 characters" | Name too short or too long | Use 2-12 characters only |
| "Name can only contain letters" | Invalid characters in name | Remove spaces, numbers, and symbols |

## Tips & Best Practices

1. **Use Tier Presets** for realistic testing - they generate proper per-dungeon scores
2. **Use Manual IO** for testing specific breakpoints or edge cases
3. **Name Uniquely** - use descriptive names for easier management
4. **Preview First** - always check the preview before creating
5. **Reset Between Tests** - use "Clear All Fake Players" between test scenarios
6. **Combine with Presets** - use custom players alongside preset teams

## Clearing Fake Players

After testing, clean up:
```
/nk config → Debug System → Fake Player Tools → Clear All Fake Players
```

Or via command:
```bash
/nk test clear
```

## Troubleshooting

**Problem:** Custom player not appearing in group
**Solution:** Refresh the UI with `/reload` or check if player was actually created (error message will show)

**Problem:** Spec dropdown shows "Random" only
**Solution:** Select a class first - the spec dropdown auto-filters based on class selection

**Problem:** IO slider is disabled
**Solution:** Clear the tier preset selection to enable manual IO input

**Problem:** Keystone level slider is disabled
**Solution:** Select a dungeon first - level slider requires dungeon selection

## Integration with Existing Tools

Custom players work seamlessly with:
- ✅ All preset generation buttons
- ✅ Role composition generators
- ✅ Keystone scenario generators
- ✅ Organizer team generation
- ✅ Main UI rendering
- ✅ Profile system
- ✅ IO calculations

## Future Enhancements

Planned features for future versions:
- Per-dungeon score customization
- Capability overrides (heroism, battle res)
- Save/load custom player templates
- Bulk import from CSV/JSON

## Support

For issues or feature requests related to custom fake players:
1. Check this documentation first
2. Use `/nk test help` for quick reference
3. Report issues with full error messages and steps to reproduce