# NextKey Product Description

## What NextKey Is

NextKey is a World of Warcraft addon that solves the "which key should we run next?" problem for Mythic+ groups. It automatically collects party keystones, analyzes player scores, calculates IO gain potential, and provides intelligent ranked suggestions - all in under 30 seconds.

## The Problem It Solves

**Before NextKey:**
- Groups spend 5-10 minutes discussing which keystone to run
- Manual score checking across multiple players
- Difficult to optimize for group IO gains
- No visibility into who benefits most from each key
- Loot targeting requires manual dungeon tracking
- Travel coordination adds additional delays

**After NextKey:**
- Instant ranked list of available keystones
- Automatic score syncing across party members
- Clear IO gain visualization for each option
- Intelligent sorting algorithms (Smart Sort, Max Group IO, etc.)
- One-click teleport assistance
- Loot tracking integrated into decision-making

## How It Works

### Data Collection
1. **Automatic Keystone Detection**: Scans player bags and uses Blizzard API + LibOpenRaid integration
2. **Score Aggregation**: Pulls comprehensive data from RaiderIO with multiple fallbacks
3. **Real-time Sync**: Uses AceComm-3.0 for reliable party communication
4. **Cross-realm Support**: Works seamlessly with players from different realms

### Intelligent Ranking
1. **Smart Sort (Borda Count)**: Balances IO gain, player coverage, key level, and loot preferences
2. **Max Group IO**: Maximizes total IO gain for entire party
3. **Max Player Coverage**: Ensures most players benefit
4. **Highest Key Level**: Pushes challenging content
5. **Max Item Need**: Prioritizes dungeons with targeted loot

### User Experience
1. **Main Window**: Clean card-based interface showing all available keys
2. **Dungeon View**: Personal score tracking and preference management
3. **Tooltips**: Detailed IO breakdowns and player-specific gains
4. **Travel Assistant**: Integrated teleport system with one-click travel
5. **Group Suggestions**: Intelligent multi-group formation with key rotation

## Target User Experience

### Quick Decision Flow (Most Common - <30 seconds)
1. Player opens NextKey (`/nk`)
2. System shows ranked keystones with IO gains
3. Leader reviews top 3 recommendations
4. Party agrees on selection
5. Click teleport for instant travel

### Score Pushing Flow
1. Enable "Max Group IO" sorting
2. View detailed per-player breakdowns
3. Identify keys where most players gain
4. Track improvement over time
5. Optimize for rating increases

### Loot Farming Flow
1. Set loot targets in options
2. Enable "Max Item Need" sorting
3. View drop chances and run counts
4. Get notifications on item acquisition
5. Track farming progress

## Key Differentiators

### vs Manual Coordination
- **Speed**: 30 seconds vs 5-10 minutes
- **Accuracy**: Calculated IO gains vs guesswork
- **Coverage**: Full party analysis vs individual requests

### vs Other Addons
- **Focus**: Specialized for key selection optimization
- **Integration**: Deep RaiderIO + LibOpenRaid + Blizzard API integration
- **Intelligence**: Multi-factor ranking algorithms
- **Group-Centric**: Optimizes for entire party, not individuals

## Success Indicators

### User Adoption
- Players use it for every key selection decision
- Groups prefer NextKey users for faster coordination
- Positive impact on M+ completion rates

### Performance Metrics
- Decision time consistently under 30 seconds
- Zero impact on gameplay performance
- High reliability across addon combinations

### Community Impact
- Reduces friction in M+ group formation
- Helps players improve scores efficiently
- Creates more positive group experiences