# NextKey Current Status & Requirements Document

## Project Status: Post-UI Refactor Bugfixing Phase
**Date**: October 19, 2025
**Version**: 0.2.0.1

## 🎯 Current Implementation Status

### 1. Loot Window (`ui/lootWindow.lua`)
**Current State**: Shows "coming soon" with a button
**Requirements**:
- Create UI window similar to hearthstone selector using same component patterns
- Display list of available items from current dungeon
- Add button to input custom items by item ID (users look up on Wowhead)
- Don't hardcode item lists - pass generic data structure
- Support multiple custom items per player
- Default items: unremovable (protected flag)
- Custom items: removable with red X button

### 2. PUG Mode Components Status

#### Invite Notifications (`ui/pugInviteNotification.lua`)
- **Status**: Not working, never worked pre-UI update
- **Priority**: Fix invite detection and notifications

#### Travel Assistant (`ui/pugTravelAssistant.lua`)
- **Status**: Working great
- **Features**:
  - Window looks correct and updates when keystone selected
  - Automatic hearthstone selection based on unlocked hearthstones
  - Integration with teleport system

#### Post-Run Getaway UI (`ui/pugGetawayUI.lua`)
- **Requirements**:
  - Make it an extension of current travel assistant UI
  - Use existing card components (reuse code)
  - Layout: Hearthstone card → Leave party button (shorter card)
  - Consider adding: [Brainstorm additional elements here]

#### Application Tracker (`ui/pugApplicationTracker.lua`)
- **Status**: Doesn't work
- **Research**: Look at "Premade Group Finder" addon for insights
- **Requirements**: Implement functional application tracking

### 3. Card Button Layout

#### Dungeon Cards & Keystone Cards
- **Current State**: Looking decent
- **Requirements**:
  - Center line of buttons OR stack +/- on top of Teleport/Loot buttons
  - Improve visual appearance and spacing
  - Make buttons look more integrated

#### Keystone View Buttons
- **Current State**: Can use full "Select"/"Delete" text
- **Previous Issue**: Had to shorten to "Sel"/"Del" due to space
- **Solution**: Use full text now that there's more room

### 4. Tooltip System

#### IO Calculation & Class Icon Tooltips
- **Historical**: Used to work before UI refactor
- **Current State**: Missing/broken
- **Requirements**:
  - Restore in both regular and compact views
  - In IO sort mode: Keep "Sel"/"Del" to leave room for IO calculation
  - Show detailed per-player impact information
  - Include class/specialization information

### 5. IO Score Color Consistency

#### Current Issue
- **Player Keystone Cards**: Show correct gradient ✅
- **Dungeon View Total IO**: Uses different color ❌
- **Requirement**: Make dungeon view use same gradient as player keystone cards

### 6. Fake Player System

#### Current State
- View toggling works nicely ✅
- **Requirements**:
  - Add more lower-skill fake players to dropdown
  - Include lower-skill options in random generation
  - Current tiers: Expert/Skilled/Competent
  - Add: Below average, novice, beginner, etc.

### 7. Hearthstone Selector (`ui/hearthstoneSelector.lua`)

#### Current State
- Mostly working ✅
- **Issue**: Icon loading problems on first open
- **Symptoms**: Question marks instead of proper icons
- **Workaround**: Close/reopen window or press select button in options
- **Requirement**: Fix initial icon loading to prevent question marks

### 8. Options Panel (`options/main.lua`)

#### Current State
- Mostly functional ✅
- **Issues**:
  - Some settings are unnecessary
  - Poor category nesting structure
  - Some high-level categories have no settings (just submenus)
  - Creates confusing extra submenu layers
- **Requirements**:
  - Audit each button and setting
  - Remove unnecessary options
  - Fix category nesting
  - Condense and simplify structure

### 9. PUG System Overall
- **Status**: Pretty broken
- **Priority**: Major rework needed

## 🚨 Critical Issues (Top 3)

### 1. Missing IO Tooltips
- **Impact**: Players can't see per-player impact of keys
- **Blocker**: Core decision-making functionality broken
- **Requirement**: Essential for key selection workflow

### 2. PUG Mode Non-Functional
- **Impact**: Major feature completely broken
- **Components**: Multiple UI files not working
- **Requirement**: Complete implementation needed

### 3. Group Suggestion Functionality
- **Current State**: Needs major rework
- **Complexity**: High (drag/drop, multi-group UI)
- **Long-term**: Integrate with UI for better UX

## 🎨 Complex Feature Requirements

### Advanced Group Suggestion System

#### Current Vision
Split compact list into multiple collapsible groups with drag/drop functionality

#### UI Structure
```
Group 1: (120-588 IO) [COLLAPSED]
├── Player1 (Tank)
├── Player2 (Healer)
├── Player3 (DPS)
├── Player4 (DPS)
└── Player5 (DPS)

Group 2: (95-420 IO) [COLLAPSED]
└── [5 more players...]

[+] Add Group
```

#### Key Features

**3-Step Process for Group Leaders:**
1. **M+ Breakout Mode**: Toggle creates 2 groups (All players + "Not doing M+")
2. **Player Organization**: Drag players between groups (auto-calculate IO)
3. **Group Finalization**: Blast organized groups to chat

**Advanced Interactions:**
- **Role-based Placement**: Auto-place by current spec (Tank/Healer/DPS slots)
- **Preference Detection**: Ask players if they want to do M+ in same/different role
- **Real-time Updates**: Auto-recalculate when players move between groups
- **Fallback Handling**: Show ??? for scores when calculations lag

**Chat Output Requirements:**
- **No Emojis**: WoW can't render emojis properly
- **Clean Format**: Plain text that's easy to read
- **Group Structure**: Clear delineation of groups and roles

#### Technical Considerations
- **Performance**: Monitor calculation lag (may need to disable real-time updates)
- **Communication**: Popup system to ask players about M+ participation
- **Role Flexibility**: Account for players changing roles between raid/M+
- **Edge Cases**: Handle players with multiple characters

## 📋 Implementation Priority

### Phase 1 (Immediate - Core Functionality)
1. Fix IO tooltips (decision-making broken)
2. Fix dungeon view IO colors (visual consistency)
3. Fix hearthstone selector icon loading (UX issue)

### Phase 2 (Short-term - Major Features)
1. Implement proper loot window (placeholder currently)
2. Fix PUG invite notifications (basic PUG functionality)
3. Improve card button layouts (visual polish)

### Phase 3 (Medium-term - System Improvements)
1. Add more fake player variety (testing improvements)
2. Audit and prune options panel (UX cleanup)
3. Redesign PUG getaway UI (consistency)

### Phase 4 (Long-term - Complex Features)
1. Implement full PUG system functionality
2. Design advanced group suggestion UI with drag/drop
3. Integrate group organization workflow

## 🔧 Technical Notes

- **Component System**: All new UI must use established component factory patterns
- **Performance**: Maintain <100ms response time, <10MB memory baseline
- **Debug System**: Use `Debug:Dev/User/Error/Trace()` - never `print()`
- **Architecture**: Follow NextKey222 namespace and module registration patterns
- **Testing**: Use `/nk components test` for component validation

## 📝 Success Metrics

- **IO Tooltips**: Players can see per-player key impact
- **PUG System**: Functional invite/travel/getaway workflow
- **Visual Consistency**: Matching color gradients and layouts
- **Performance**: No lag in group calculations or UI interactions
- **User Experience**: Intuitive workflows for complex group organization