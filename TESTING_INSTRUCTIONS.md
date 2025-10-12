# Testing Instructions - Fake Player System Fix

## What Was Fixed

### 1. **Single Fake Player Creation** - FIXED ✅
**Problem:** The "Add Fake Player" button was using old manual system and failing with "Missing name/mapID/level" error even when fields were filled.

**Solution:** Updated to use `NextKey222.FakePlayerService:CreatePlayer()` with proper validation and error messages.

### 2. **Preset Team Buttons** - ENHANCED ✅
**Problem:** Buttons didn't provide feedback when clicked.

**Solution:** Added confirmation messages showing how many players were created.

## How to Test

### In-Game Testing Steps:

1. **Reload UI**
   ```
   /reload
   ```

2. **Open Options**
   ```
   /nk opt
   ```
   Go to **Debug Tools** tab

3. **Test Global Addon Checkboxes**
   - You should see two checkboxes at the top:
     - ✅ **"Players Have NextKey"** 
     - ✅ **"Players Have RaiderIO"**
   - Below them, a green status indicator: "✓ Players will have: NextKey + RaiderIO"
   - Try toggling them on/off to see the status change
   - If both are OFF, you'll see a red warning: "⚠ Both addons disabled..."

4. **Test Preset Buttons** (should work now!)
   - Click **"Mixed Skill Team (Recommended)"**
   - You should see: `"Generated 4 Mixed Skill players"` in chat
   - Check the "Current Status" section - should show 4 active players
   
   - Try other presets:
     - **Beginner Team** → `"Generated 4 Beginner Team players"`
     - **Expert Team** → `"Generated 4 Expert Team players"`
     - **High Keys Team** → `"Generated 4 High Keys Team players"`

5. **Test Single Player Creation** (should work now!)
   - Scroll down to **"Add Specific Fake Player"**
   - Fill in:
     - **Name**: "TestPlayer"
     - **Dungeon**: Select "The Dawnbreaker" from dropdown
     - **Key Level**: Set to 10 (or any level)
     - **Class**: Pick any class
     - **IO Score**: Optional (leave blank for auto-calculation)
   
   - Click **"Add Fake Player"**
   - You should see: `"Created fake player: TestPlayer-TestRealm"` in chat
   - The player should appear in the status section

6. **Test Custom Team Builder**
   - Set **Team Size** slider (1-12)
   - Click **"Generate Custom Team"**
   - Should see: `"Generated X custom players"` in chat

7. **Test Addon Toggle Effects**
   - Turn OFF **"Players Have RaiderIO"** checkbox
   - Generate a team (any preset)
   - The players should only have NextKey addon (no RIO scores)
   
   - Turn OFF **"Players Have NextKey"** too
   - Generate another team
   - Players should have NO addon data at all

## Expected Results

### ✅ Success Indicators:
- Chat messages confirm player creation
- "Current Status" shows correct player count
- Players have appropriate addon status based on checkboxes
- No Lua errors in chat
- Single player creation works with dungeon selection

### ❌ If Still Broken:
If you still see issues:

1. **Check for Lua errors**: Enable Lua errors with `/console scriptErrors 1`
2. **Check debug output**: Look for any FakePlayerService debug messages
3. **Verify initialization**: Try `/dump NextKey222.FakePlayerService` - should show a table, not nil
4. **Check saved variables**: Make sure `db.global.debug` exists

## What Changed Technically

### Files Modified:

1. **`options/main.lua`** - 6 changes:
   - Fixed "Add Fake Player" button to use FakePlayerService:CreatePlayer()
   - Added validation with user-friendly error messages
   - Added confirmation messages to all preset buttons
   - Added confirmation message to custom team builder
   
2. **`core/fakePlayerService.lua`** - 2 changes:
   - Updated GeneratePreset() to read global addon config from `db.global.debug.presetAddonConfig`
   - Removed per-player addon settings from PRESET_CONFIGS

### Key Functions:
- `NextKey222.FakePlayerService:CreatePlayer(config)` - Creates single player
- `NextKey222.Addon:GeneratePresetTeam(presetType)` - Creates preset team
- `NextKey222.Addon:AddRandomFakePlayers(count)` - Creates random team
- `NextKey222.Addon:ClearFakePlayers()` - Removes all fake players

## Debugging Commands

If something goes wrong, try these:

```lua
-- Check if FakePlayerService is loaded
/dump NextKey222.FakePlayerService

-- Check if it's initialized
/dump NextKey222.FakePlayerService.isInitialized

-- Check addon config
/dump NextKey222.Addon.db.global.debug.presetAddonConfig

-- Check current fake players
/dump NextKey222.Addon.db.global.debug.players

-- Manual test
/run NextKey222.FakePlayerService:CreatePlayer({name="TestManual", keystoneLevel=10, keystoneDungeon=503})
```

## Next Steps

Once testing is complete:
1. If everything works → Document the new realistic IO tiers
2. If there are issues → Let me know what errors you see and I'll fix them
3. Consider adding more presets (regional variations, role-specific, etc.)
