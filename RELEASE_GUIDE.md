# NextKey GitHub Release Guide

This guide will walk you through creating your first GitHub release for NextKey, step by step.

## 📋 Pre-Release Checklist

Before creating a release, you **MUST** complete these critical steps:

### 1. Set DEV_MODE to False ✅ **CRITICAL**
**File:** `core/debugService.lua` (Line 119)

Change:
```lua
DEV_MODE = true,
```

To:
```lua
DEV_MODE = false,
```

**Why:** This disables all development logging and removes debug overhead for production users.

### 2. Verify Version Numbers Match
Check that these files have matching version numbers:

- **`NextKey.toc`** (Line 5): `## Version: 0.6.3`
- **`boot.lua`** (Lines 55-57):
  ```lua
  NextKey.version_major = 0
  NextKey.version_minor = 6
  NextKey.version_patch = 3
  ```
- **`README.md`** (Line 166): `**Current Status** (v0.6.3):`

**Current Version:** v0.6.3

### 3. Test the Addon In-Game
1. Enable script errors: `/console scriptErrors 1`
2. Open main window: `/nk`
3. Test major features:
   - Keystone detection and ranking
   - M+ Group Organizer (`/nk organizer`)
   - Teleport system
   - Configuration panel (`/nk config`)
4. Check for Lua errors in chat

### 4. Verify No Debug Output
With `DEV_MODE = false`:
1. `/reload` in-game
2. Open NextKey: `/nk`
3. Use various features
4. **Verify:** No debug messages appear in chat (except ERROR and USER level messages)

### 5. Update CHANGELOG.md (If Needed)
Ensure the latest changes are documented in `CHANGELOG.md`.

**Current Latest Version:** v0.6.3 (2025-11-11)

---

## 📦 Files to EXCLUDE from Release

The following files/directories should **NOT** be included in the release package:

### Development & Documentation Files
- `.kilocode/` - AI assistant rules and memory bank
- `.vscode/` - VSCode workspace settings
- `.github/` - GitHub workflows and templates
- `Documentation/` - Internal development documentation
- `RELEASE_GUIDE.md` - This guide (optional - can include if helpful)
- `TOOLTIP_BUG_REPORT.md` - Internal bug tracking
- `.gitignore` - Git configuration

### Version Control
- `.git/` - Git repository data (if present)

### Test/Debug Files (Located in `debug/` directory - Keep for Alpha)
**Note:** For an Alpha release, you may want to **INCLUDE** the `debug/` folder to help testers report issues. For Beta/Production releases, these should be removed:

- `debug/card_layout_test.lua`
- `debug/check_card_state.lua`
- `debug/drag_test_simple.lua`
- `debug/init.lua`
- `debug/loot_tracking_test.lua`
- `debug/memoryProfile.lua`
- `debug/organizer_foundation_tests.lua`
- `debug/organizer_survey_tests.lua`
- `debug/organizer_ui_tests.lua`
- `debug/performanceMonitor.lua`
- `debug/performanceTest.lua`
- `debug/pollSimulator.lua`
- `debug/pugHelper_tests.lua`
- `debug/pugHelper_testUI.lua`
- `debug/pugPerformanceTest.lua`
- `debug/simple_test.lua`
- `debug/spec_change_test.lua`
- `debug/test_card_movement.lua`
- `debug/test_io_tooltips.lua`
- `debug/test_lfg_apis.lua`
- `debug/test_priority_sorting.lua`
- `debug/tools.lua`

**Recommendation for Alpha:** Keep the `debug/` folder for now to help with testing and bug reports.

---

## 📁 What TO INCLUDE in Release

Your release package should contain:

### Core Addon Files
- `NextKey.toc` - Addon manifest
- `boot.lua` - Initialization system
- `embeds.xml` - Library loader
- `LICENSE` - MIT License
- `README.md` - User documentation
- `CHANGELOG.md` - Version history

### Source Code Directories
- `core/` - All core functionality
- `ui/` - All UI components
- `data/` - Season data (portals, loot, hearthstones)
- `events/` - Event handlers
- `options/` - Configuration UI
- `Libs/` - Required libraries (Ace3, LibStub, LibOpenRaid)

### Debug Files (Alpha Only)
- `debug/` - Testing and debug utilities (helpful for alpha testers)

### User Documentation
- `README/` - User guides and documentation
  - `DEBUG_SYSTEM_USER_GUIDE.md`
  - `PUG_MODE.md`
  - `SLASH_COMMANDS.md`
  - `USER_GUIDE.md`

---

## 🚀 Step-by-Step GitHub Release Process

### Step 1: Prepare the Release Package

**Option A: Manual (Recommended for First Release)**

1. Create a new folder called `NextKey`
2. Copy all files/folders TO INCLUDE (listed above) into this folder
3. **DO NOT** copy any files from the EXCLUDE list
4. Verify the structure looks like this:
   ```
   NextKey/
   ├── core/
   ├── ui/
   ├── data/
   ├── events/
   ├── options/
   ├── Libs/
   ├── debug/          (Alpha only)
   ├── README/
   ├── NextKey.toc
   ├── boot.lua
   ├── embeds.xml
   ├── LICENSE
   ├── README.md
   └── CHANGELOG.md
   ```
5. Compress the `NextKey` folder into a ZIP file: `NextKey-v0.6.3-alpha.zip`

**Option B: Using Git (Advanced)**

1. Create a `.gitattributes` file with export-ignore rules (similar to .gitignore)
2. Use `git archive` to create a clean release package

### Step 2: Create GitHub Release

1. **Go to GitHub Repository**
   - Navigate to: `https://github.com/sagerobot/NextKey`

2. **Click "Releases"** (right sidebar or top navigation)

3. **Click "Draft a new release"**

4. **Fill in Release Details:**

   **Tag version:**
   ```
   v0.6.3-alpha
   ```
   
   **Release title:**
   ```
   NextKey v0.6.3 Alpha - M+ Group Organizer Enhancements
   ```
   
   **Description:** (Copy/paste this template)
   ```markdown
   # NextKey v0.6.3 Alpha Release
   
   ## ⚠️ Alpha Release Notice
   
   This is an **ALPHA** release for early testing. Expect bugs and incomplete features. Please report issues via [GitHub Issues](https://github.com/sagerobot/NextKey/issues).
   
   ## 🚀 What's New in v0.6.3
   
   ### M+ Group Organizer Enhancements
   - **Auto-save functionality** preserves player slot assignments across sessions
   - **Visual theming improvements** with class-colored survey cards and role icons
   - **Enhanced poll data usage** and state management
   - **Dynamic organizer button** only appears when in groups of 6+ players
   
   ### Bug Fixes
   - Fixed fake player detection to prevent data filtering issues
   
   ## 📦 Installation
   
   1. Download `NextKey-v0.6.3-alpha.zip`
   2. Extract the ZIP file
   3. Copy the `NextKey` folder to `World of Warcraft\_retail_\Interface\AddOns\`
   4. Restart World of Warcraft or type `/reload` in-game
   5. Type `/nk` to open NextKey
   
   ## ⚙️ Requirements
   
   - **World of Warcraft:** Retail (The War Within - 11.0.5+)
   - **RaiderIO Addon:** **REQUIRED** for player scores
   - **LibOpenRaid:** Optional (enhances keystone sharing)
   
   ## 🐛 Known Issues
   
   - Hero-track item tooltips need ilvl display tuning
   - PUG Helper architecture is functional but still undergoing validation
   
   ## 📚 Documentation
   
   - [User Guide](https://github.com/sagerobot/NextKey/blob/main/README/USER_GUIDE.md)
   - [Slash Commands](https://github.com/sagerobot/NextKey/blob/main/README/SLASH_COMMANDS.md)
   - [Debug System Guide](https://github.com/sagerobot/NextKey/blob/main/README/DEBUG_SYSTEM_USER_GUIDE.md)
   
   ## 💬 Feedback & Bug Reports
   
   Please report issues at: https://github.com/sagerobot/NextKey/issues
   
   Include:
   - WoW version and build number
   - Steps to reproduce the issue
   - Any Lua errors (enable with `/console scriptErrors 1`)
   - Debug logs if applicable (`/nk config` → Debug System)
   
   ---
   
   **Full Changelog:** See [CHANGELOG.md](https://github.com/sagerobot/NextKey/blob/main/CHANGELOG.md)
   ```

5. **Upload Release Asset:**
   - Click "Attach binaries by dropping them here or selecting them"
   - Upload your `NextKey-v0.6.3-alpha.zip` file

6. **Mark as Pre-release:**
   - ✅ Check the box: **"This is a pre-release"**
   - This marks it as an alpha/beta release, not production-ready

7. **Click "Publish release"**

### Step 3: Verify the Release

1. Go to your Releases page: `https://github.com/sagerobot/NextKey/releases`
2. Verify the release appears correctly
3. Download the ZIP file from GitHub
4. Test installation:
   - Extract the ZIP
   - Copy to AddOns folder
   - Test in-game
   - Verify no issues

---

## ✅ Post-Release Checklist

After publishing the release:

1. **Update README.md** (if needed)
   - Update installation link to point to latest release:
     ```markdown
     1. **Download**: Get the latest release from [GitHub Releases](https://github.com/sagerobot/NextKey/releases)
     ```

2. **Announce the Release** (optional)
   - Post in WoW addon communities
   - Share with your guild
   - Create a Discord/forum post

3. **Monitor for Issues**
   - Watch GitHub Issues for bug reports
   - Respond to user feedback
   - Track common problems for next release

4. **Revert DEV_MODE** (for continued development)
   - After the release is published, you can set `DEV_MODE = true` again in your development environment
   - **Remember:** Always set it to `false` before the next release!

---

## 🔄 For Future Releases

### Version Numbering
Follow semantic versioning: `major.minor.patch`

- **Pre-Alpha (v0.x.x):** Current stage - internal development
- **v1.0.0:** First public beta/release (feature-complete, production-ready)

### Release Types on GitHub

1. **Alpha Releases:** Check "This is a pre-release" ✅
   - Version format: `v0.6.3-alpha`
   
2. **Beta Releases:** Check "This is a pre-release" ✅
   - Version format: `v1.0.0-beta.1`
   
3. **Production Releases:** Leave unchecked
   - Version format: `v1.0.0`

### Automation (Future Enhancement)

Consider adding GitHub Actions to automate:
- Version validation
- ZIP package creation
- Release note generation from CHANGELOG.md

---

## 📞 Need Help?

If you run into issues during the release process:

1. Check GitHub's [Creating Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
2. Review this guide's troubleshooting section below
3. Ask in GitHub Discussions or relevant communities

---

## 🔧 Troubleshooting

### "Version tag already exists"
- Choose a different version number
- Or delete the existing tag (not recommended for published releases)

### "Upload failed"
- Check file size (GitHub limit: 2GB per file)
- Try re-uploading
- Verify ZIP file is not corrupted

### "Release not showing up"
- Refresh the page
- Check if it's marked as "Draft" instead of published
- Verify you're logged into the correct GitHub account

---

## 📝 Quick Reference

**Current Version:** v0.6.3  
**Release Type:** Alpha (pre-release)  
**Critical Pre-Release Step:** Set `DEV_MODE = false` in `core/debugService.lua`  
**Package Name:** `NextKey-v0.6.3-alpha.zip`  
**Tag Name:** `v0.6.3-alpha`

---

**Good luck with your first release! 🎉**