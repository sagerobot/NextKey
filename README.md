# NextKey

**The intelligent Mythic+ companion addon that helps you choose your next key in under 30 seconds.**

NextKey analyzes your group's keystones, player scores, and loot preferences to provide instant, data-driven recommendations for which dungeon to run next. Stop wasting time debating which key to push—let NextKey optimize your IO gains and loot targeting for you.

---

## 🚀 What NextKey Does

### **Smart Key Selection** (Main Feature)
When your group has multiple keystones, which one gives the best IO gains? NextKey instantly ranks all available keys by:
- **IO Gain Potential**: Shows exactly how much rating each player will earn
- **Player Coverage**: Highlights keys that benefit the most group members
- **Loot Targeting**: Prioritizes dungeons with items you're farming
- **Smart Sort (Borda Count)**: Balances all factors for the mathematically optimal choice

**Result**: Your group agrees on the next key in under 30 seconds instead of 5-10 minutes of discussion.

### **M+ Group Organizer**
Forming multiple groups for M+ night? The Organizer helps you:
- **Drag-and-drop roster management** with role validation
- **Keystone assignment** per group for rotation planning
- **Spec preference polling** to understand player flexibility
- **Auto-detection** of party members with instant roster population

Perfect for guilds running 10-20 people through keys each week.

### **PUG Helper** (For Solo Players)
Applying to Mythic+ PUGs via Group Finder? NextKey assists with:
- **Auto-travel assistance**: Teleport window opens when you're accepted to a group
- **Dungeon detection**: Automatically identifies which dungeon from group names
- **Leave Group helper**: Quick exit after dungeon completion
- **Application tracking**: Debug UI shows all your active applications (dev mode)

### **Loot Targeting System**
Stop running dungeons you don't need. Track specific items and see:
- **Featured Season 3 loot** for each dungeon
- **Custom item tracking** by item ID
- **Run counters**: How many times you've run each dungeon (7+ only)
- **Smart sorting**: "Max Item Need" mode prioritizes dungeons with your tracked items

---

## 📦 Installation

1. **Download**: Get the latest release from [GitHub Releases](#) *(or CurseForge/Wago when published)*
2. **Extract**: Unzip the `NextKey` folder
3. **Install**: Copy to `World of Warcraft\_retail_\Interface\AddOns\`
4. **Restart WoW**: Log in and type `/nk` to start

**Requirements**:
- **World of Warcraft**: Retail (The War Within - 11.0.2+)
- **RaiderIO Addon**: **REQUIRED** for accurate player scores and dungeon data
- **LibOpenRaid** (optional): Enhanced keystone sharing across party/guild

---

## 🎮 Quick Start Guide

### First Time Setup
1. Open the addon: `/nk`
2. The main window shows all available keystones in your party
3. Keys are automatically ranked by "Smart Sort" (best overall choice)
4. Click the **Teleport** button on any key to get portal assistance

### Common Workflows

**Premade Group (Guild/Friends)**:
1. Form your group
2. Open NextKey: `/nk`
3. Review ranked keys (top = best IO gains)
4. Leader announces choice: "Let's do [top key]"
5. Click Teleport → Use portal or hearthstone

**PUG Mode (Solo via Group Finder)**:
1. Apply to M+ groups via the default Group Finder
2. Get accepted → NextKey teleport window opens automatically
3. Use suggested portal/hearthstone to travel
4. Complete dungeon → "Leave Group" card appears

**Loot Farming**:
1. Open a dungeon card (e.g., "Priory of the Sacred Flame")
2. Click the **Loot** button
3. Track items you want (featured items or custom IDs)
4. Change main window sort to "Max Item Need"
5. Run the top-ranked dungeons to target your loot

**M+ Organizer (10+ People)**:
1. Open organizer: `/nk organizer`
2. Auto-detect detects party → click to populate roster
3. Drag players from bench into Tank/Healer/DPS slots
4. Assign a keystone to each group
5. Send poll to gather spec preferences (optional)
6. Form groups in-game and run keys

---

## ⚙️ Key Slash Commands

| Command | Description |
|---------|-------------|
| `/nk` | Open main NextKey window (keystone rankings) |
| `/nk config` | Open configuration panel |
| `/nk organizer` | Open M+ Group Organizer |
| `/nk test` | Generate 4 fake players for testing (dev mode) |
| `/nkpugtest` | Open PUG Helper Test UI (dev mode) |

**Debug Mode** (for troubleshooting):
- `/nk config` → Debug System → Enable Debugging
- Allows granular logging control and performance monitoring

---

## 🔧 Configuration Options

Access via `/nk config`:

**Teleport Settings**:
- Auto-show teleport window after M+ completion (default: ON)
- Hearthstone preferences for travel assistance

**UI Settings**:
- Window scale and positioning
- Theme customization

**Debug System** (Advanced):
- 23 debug categories across 5 logical groups
- Performance profiling tools
- Fake player simulation

---

## 🏆 What Makes NextKey Different?

### vs Manual Coordination
- **Speed**: 30 seconds vs minutes
- **Accuracy**: Calculated IO gains vs guesswork
- **Coverage**: Analyzes entire party, not just individuals

### vs Other Addons
- **Focus**: Specialized for key selection optimization (not just tracking)
- **Integration**: Deep RaiderIO + LibOpenRaid + Blizzard API integration
- **Intelligence**: Multi-factor ranking algorithms (not just key level sorting)
- **Group-Centric**: Optimizes for the entire party's benefit

---

## 📊 Sorting Algorithms Explained

NextKey offers multiple sorting strategies:

| Algorithm | Best For | How It Works |
|-----------|----------|--------------|
| **Smart Sort** | Balanced groups | Borda Count algorithm: balances IO gain, player coverage, key level, and loot |
| **Max Group IO** | Score pushing | Maximizes total IO gain for the entire party |
| **Max Player Coverage** | Fairness | Ensures the most players benefit from IO gains |
| **Highest Key Level** | Challenge seekers | Prioritizes the hardest content |
| **Max Item Need** | Loot farming | Ranks dungeons with the most tracked items |

**Recommended**: Use "Smart Sort" for most groups. Switch to "Max Group IO" when everyone needs rating.

---

## 🐛 Known Issues & Limitations

**Current Status** (v0.2.3):
- ✅ Core keystone ranking stable
- ✅ M+ Group Organizer functional (drag/drop, polls, keystone assignment)
- ⚠️ PUG Helper in validation (recent critical fixes applied)
- ⚠️ Hero-track item tooltips (ilvl display needs tuning)

**Limitations**:
- **RaiderIO Dependency**: Score data requires RaiderIO addon installed
- **Party Member Keystones**: Requires LibOpenRaid or manual communication for non-current-player keys
- **Cross-Realm**: Some features may behave differently cross-realm

**Reporting Bugs**:
1. Enable debug logging: `/nk config` → Debug System → Enable
2. Reproduce the issue
3. Type `/console scriptErrors 1` to see Lua errors
4. Report via GitHub Issues with debug logs

---

## 🛠️ For Developers

NextKey follows the **Details! Damage Meter** architectural patterns for enterprise-grade WoW addon development.

**Key Technologies**:
- Lua 5.1 (WoW embedded)
- Ace3 Framework (AceAddon, AceDB, AceComm, AceConfig, AceGUI)
- Professional debug system with compile-time stripping
- Modular architecture with centralized boot sequence

**Getting Started**:
1. Read [`Documentation/DEVELOPMENT.md`](Documentation/DEVELOPMENT.md)
2. Review [`Documentation/AI DOCS/DEBUG_SYSTEM.md`](Documentation/AI DOCS/DEBUG_SYSTEM.md)
3. Check [`.kilocode/rules/memory-bank/`](.kilocode/rules/memory-bank/) for architecture docs
4. Use `/nk test` to generate fake players for testing

**Contributing**: Pull requests welcome! Please follow the mandatory debug system rules (no `print()` statements).

---

## 📚 Documentation

- **[User Guide](README/USER_GUIDE.md)**: Comprehensive player documentation
- **[PUG Mode Guide](README/PUG_MODE.md)**: PUG Helper features and workflows
- **[Slash Commands](README/SLASH_COMMANDS.md)**: Complete command reference
- **[Debug System Guide](README/DEBUG_SYSTEM_USER_GUIDE.md)**: Troubleshooting and advanced features
- **[Developer Docs](Documentation/README.md)**: Full technical documentation

---

## 📝 Version History

**v0.2.3** (November 8, 2025) - PUG Mode Critical Fixes
- Fixed primary invite lock for first-accepted-wins guarantee
- Added Season 3 dungeon abbreviation support (Priory, Eco-Dome, Floodgate)
- Enhanced PUG Helper stability

**v0.2.2** (November 2, 2025) - M+ Group Organizer Tooltip Fixes
- Fixed role icons and spec tooltips for fake players after polls
- Normalized DAMAGER → DPS role naming

**v0.2.1** (October 20, 2025) - Loot Targeting System
- Complete loot tracking implementation with Season 3 data
- Item texture preloading and run counters

**v0.1.0** (February 4, 2024) - DungeonCards & Preferences
- Card-based visual interface for keystones
- Per-character dungeon preferences (like/dislike)

See [`CHANGELOG.md`](CHANGELOG.md) for full version history.

---

## 🙏 Credits

**Created by**: [Your Name/Guild]  
**Inspired by**: Details! Damage Meter architecture  
**Powered by**: RaiderIO data, Ace3 libraries, LibOpenRaid  

**Special Thanks**:
- RaiderIO team for comprehensive M+ data
- Details! team for architectural inspiration
- Ace3 library maintainers

---

## 📄 License

NextKey is provided as-is for World of Warcraft players. See [LICENSE](LICENSE) for details.

---

**Questions? Feedback?**  
Open an issue on [GitHub](#) or find us in the NextKey Discord community!
