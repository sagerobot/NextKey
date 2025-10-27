# M+ Group Organizer - Progressive Poll UI Design

**Status**: Design Phase  
**Created**: 2025-10-27  
**Objective**: Redesign the poll window with a progressive, card-based UI similar to teleport and loot windows

---

## Overview

Transform the current all-at-once poll dialog into a streamlined, progressive experience using clickable cards. Each step focuses on a single decision, reducing cognitive load and improving user experience.

## Design Principles

1. **Progressive Disclosure**: Show only what's needed at each step
2. **Visual Consistency**: Match style of loot window and teleport window
3. **Clear Affordances**: Cards clearly indicate they are clickable
4. **Minimal Clicks**: 1-2 clicks for most common flows
5. **Dynamic Sizing**: Window adjusts to content (2-4 specs, variable alt count)

---

## User Flows

### Flow 1: Yes on Current Character (Most Common)
```
Poll Received → Phase 1 (Participation) → Click "Yes" → Phase 3 (Spec Selection) → Submit
```
**Total Clicks**: 1 (Yes) + 1-4 (spec clicks) + 1 (Submit) = 3-6 clicks

### Flow 2: Yes on Alt Character
```
Poll Received → Phase 1 (Participation) → Click "Yes on Alt" → 
Phase 2 (Alt Selection) → Click Alt Card → Phase 3 (Spec Selection) → Submit
```
**Total Clicks**: 1 (Yes on Alt) + 1 (Alt) + 1-4 (specs) + 1 (Submit) = 4-7 clicks

### Flow 3: Opt Out
```
Poll Received → Phase 1 (Participation) → Click "No" → Window closes, added to opt-out
```
**Total Clicks**: 1 (No)

---

## Phase 1: Participation Question

### Window Specs
- **Title**: "M+ Group Organizer - Poll"
- **Dimensions**: 380w x 280h (fits 3 cards + padding)
- **Style**: Native frame with BackdropTemplate (like loot window)

### Header Text
```
"[OrganizerName] is organizing M+ groups.
Do you want to play M+ tonight?"
```
- Font: GameFontNormalLarge
- Color: White (1, 1, 1)
- Position: Centered, 20px from top

### Card Layout
Three vertically stacked cards, each 100px tall:

#### Card 1: "Yes" (Green)
```
┌─────────────────────────────────┐
│  ✓  Yes                         │
│     Play on current character   │
└─────────────────────────────────┘
```
- Background: Dark with green border (0.2, 0.8, 0.2)
- Icon: Green checkmark texture
- Primary Text: "Yes" (GameFontNormalLarge, white)
- Secondary Text: "Play on current character" (GameFontNormalSmall, 0.8, 0.8, 0.8)

#### Card 2: "Yes on an Alt" (Green with Alt Icon)
```
┌─────────────────────────────────┐
│  ⇄  Yes on an Alt               │
│     Choose a different character│
└─────────────────────────────────┘
```
- Background: Dark with green border (0.2, 0.8, 0.2)
- Icon: Character swap/alt icon
- Primary Text: "Yes on an Alt" (GameFontNormalLarge, white)
- Secondary Text: "Choose a different character" (GameFontNormalSmall, 0.8, 0.8, 0.8)

#### Card 3: "No" (Red)
```
┌─────────────────────────────────┐
│  ✗  No                          │
│     Not playing tonight         │
└─────────────────────────────────┘
```
- Background: Dark with red border (0.8, 0.2, 0.2)
- Icon: Red X texture
- Primary Text: "No" (GameFontNormalLarge, white)
- Secondary Text: "Not playing tonight" (GameFontNormalSmall, 0.8, 0.8, 0.8)

### Card Interactions
- **OnEnter**: Brighten background, highlight border
- **OnLeave**: Restore normal appearance
- **OnClick**: Execute corresponding action

### Actions
- **"Yes" Click**: Store response, proceed to Phase 3 (Spec Selection)
- **"Yes on Alt" Click**: Proceed to Phase 2 (Alt Selection)
- **"No" Click**: Send opt-out response, close window, add to opt-out list

---

## Phase 2: Alt Character Selection (Conditional)

### Window Specs
- **Title**: "M+ Group Organizer - Choose Character"
- **Dimensions**: 420w x (dynamic based on character count)
  - Base: 180px (header + footer)
  - Per character: 95px
  - Example: 3 chars = 180 + (3 × 95) = 465px height
- **Max Height**: 700px (with scrolling if needed)

### Header Text
```
"Select which character you want to play:"
```
- Font: GameFontNormalLarge
- Color: White (1, 1, 1)
- Position: Centered, 20px from top

### Character Card Layout
Each character card displays:

```
┌──────────────────────────────────────────┐
│  [Icon]  CharacterName                   │
│          Class - Spec                    │
│          IO: 2850 | iLvl: 639           │
│          Key: ARA +15 (or "No Key")     │
└──────────────────────────────────────────┘
```

#### Card Components
1. **Class Icon** (48x48px)
   - Left aligned, 8px padding
   - Colored border matching class color

2. **Character Name** (Line 1)
   - Font: GameFontNormalLarge
   - Color: Class color
   - Position: Right of icon, +10px

3. **Class & Spec** (Line 2)
   - Font: GameFontNormal
   - Color: White (1, 1, 1)
   - Text: "{ClassName} - {SpecName}"

4. **Scores** (Line 3)
   - Font: GameFontNormalSmall
   - Color: (0.8, 0.8, 1) for IO, (1, 0.8, 0.5) for iLvl
   - Text: "IO: {score} | iLvl: {itemLevel}"

5. **Keystone** (Line 4)
   - Font: GameFontNormalSmall
   - Color: (0.7, 0.7, 0.7)
   - Text: "Key: {DungeonAlias} +{level}" or "Key: None"

### Character Ordering
1. Alt characters (sorted by IO, highest first)
2. **Current character LAST** (easy to select if changing mind)

### Card Interactions
- **OnEnter**: Highlight entire card
- **OnClick**: Select character, proceed to Phase 3 (Spec Selection)

### Back Button
- Bottom left corner
- Text: "← Back"
- Action: Return to Phase 1

---

## Phase 3: Spec Selection

### Window Specs
- **Title**: "M+ Group Organizer - Choose Specs"
- **Dimensions**: Dynamic based on spec count
  - **2 Specs** (DH): 340w x 300h
  - **3 Specs** (Most): 340w x 380h  
  - **4 Specs** (Druid): 340w x 460h
- **Style**: Native frame with BackdropTemplate

### Header Text
```
"Select specs for [CharacterName]:
Click once to play, twice to fill"
```
- Font: GameFontNormal
- Color: White (1, 1, 1)
- Position: Centered, 20px from top

### Spec Card Layout
Each spec card (80px tall):

```
┌─────────────────────────────────┐
│  [Spec Icon]  Spec Name         │
│               Role              │
│               [State Text]      │
└─────────────────────────────────┘
```

#### Card States

**State 1: Not Playing (Default)**
- Background: Dark (0.05, 0.05, 0.05, 0.85)
- Border: Grey (0.35, 0.35, 0.35)
- State Text: "Click to play" (grey, 0.6, 0.6, 0.6)
- Icon: Normal brightness

**State 2: Playing (First Click)**
- Background: Slightly brighter (0.08, 0.12, 0.08)
- Border: Green (0.2, 0.8, 0.2)
- State Text: "Will Play" (green, 0.3, 0.9, 0.3)
- Icon: Full brightness
- Checkmark overlay (top-right corner)

**State 3: Fill (Second Click)**
- Background: Slightly brighter (0.12, 0.12, 0.05)
- Border: Yellow (0.9, 0.8, 0.2)
- State Text: "Fill if Needed" (yellow, 0.9, 0.9, 0.3)
- Icon: Full brightness
- Star overlay (top-right corner)

**State Cycle**: Not Playing → Playing → Fill → Not Playing

#### Card Components
1. **Spec Icon** (48x48px)
   - Left aligned, 8px padding
   - Spec-specific icon from game assets

2. **Spec Name** (Line 1)
   - Font: GameFontNormalLarge
   - Color: White (1, 1, 1)
   - Position: Right of icon, +10px

3. **Role** (Line 2)
   - Font: GameFontNormal
   - Color: Role-specific
     - Tank: (0.8, 0.6, 0.4)
     - Healer: (0.4, 0.8, 0.4)
     - DPS: (0.8, 0.4, 0.4)

4. **State Text** (Line 3)
   - Font: GameFontNormalSmall
   - Color: State-dependent (see above)

### Validation
- **Minimum**: No minimum - all not playing is valid (player can't fill any role)
- **Submit Button**: Always enabled

### Action Buttons
```
[← Back]               [Submit →]
```
- **Back Button**: Left aligned, returns to appropriate phase:
  - If came from alt selection → Phase 2
  - If came from "Yes" → Phase 1
- **Submit Button**: Right aligned, green, submits final response

---

## Data Structures

### Phase 1 Response
```lua
{
    phase = 1,
    participation = "yes" | "yes_alt" | "no",
    timestamp = GetTime()
}
```

### Phase 2 Response (Intermediate)
```lua
{
    phase = 2,
    selectedCharacterID = "Name-Realm",
    characterData = {
        name = "CharName",
        class = "WARRIOR",
        io = 2850,
        itemLevel = 639,
        keystone = { dungeonID, level } or nil
    }
}
```

### Final Response (Phase 3)
```lua
{
    pollID = "poll-uuid",
    optedIn = true | false,
    selectedCharacter = "Name-Realm",  -- current or alt
    characterData = { ... },           -- only if alt
    specPreferences = {
        [specID] = "none" | "play" | "fill"
    },
    timestamp = GetTime()
}
```

---

## UI Configuration Constants

Add to [`core/uiConfig.lua`](core/uiConfig.lua):

```lua
POLL_WINDOW = {
    -- Phase 1: Participation
    PHASE1_WIDTH = 380,
    PHASE1_HEIGHT = 280,
    CARD_HEIGHT = 90,
    CARD_SPACING = 8,
    
    -- Phase 2: Alt Selection  
    PHASE2_WIDTH = 420,
    PHASE2_BASE_HEIGHT = 180,
    PHASE2_CARD_HEIGHT = 95,
    PHASE2_MAX_HEIGHT = 700,
    
    -- Phase 3: Spec Selection
    PHASE3_WIDTH = 340,
    PHASE3_BASE_HEIGHT = 160,
    PHASE3_SPEC_HEIGHT = 80,
    
    -- Card styling
    ICON_SIZE = 48,
    CARD_PADDING = 8,
    
    -- Colors
    COLOR_GREEN_BORDER = {0.2, 0.8, 0.2, 1},
    COLOR_RED_BORDER = {0.8, 0.2, 0.2, 1},
    COLOR_YELLOW_BORDER = {0.9, 0.8, 0.2, 1},
    COLOR_GREY_BORDER = {0.35, 0.35, 0.35, 0.8}
}
```

---

## Implementation Plan

### Step 1: Core Module Refactor
**File**: [`ui/organizer/surveyDialog.lua`](ui/organizer/surveyDialog.lua)

- Replace single `Show()` method with phase-specific methods:
  - `ShowPhase1()` - Participation cards
  - `ShowPhase2()` - Alt selection cards
  - `ShowPhase3()` - Spec selection cards
- Add state tracking:
  - `currentPhase` (1, 2, or 3)
  - `selectedCharacter` (player ID)
  - `specStates` (table of spec preferences)
- Add navigation methods:
  - `GoToPhase2()` - Transition to alt selection
  - `GoToPhase3()` - Transition to spec selection
  - `GoBack()` - Return to previous phase

### Step 2: Card Builder Functions
Create reusable card builders following teleport/loot window patterns:

```lua
-- Build participation card (Phase 1)
function BuildParticipationCard(type, parent)
    -- type: "yes", "yes_alt", "no"
    -- Returns native frame with click handler
end

-- Build character card (Phase 2)
function BuildCharacterCard(characterData, parent)
    -- Returns card with character info
end

-- Build spec card (Phase 3)
function BuildSpecCard(specID, specInfo, parent)
    -- Returns 3-state toggle card
end
```

### Step 3: Data Retrieval
**File**: [`core/characterStorage.lua`](core/characterStorage.lua)

Add methods:
```lua
-- Get all max-level characters sorted by IO
function CharacterStorage:GetMaxLevelCharacters()
    -- Returns sorted list excluding current char
end

-- Get character item level
function CharacterStorage:GetItemLevel(characterID)
    -- Returns cached or current iLvl
end
```

**File**: [`core/profiles.lua`](core/profiles.lua)

Add methods:
```lua
-- Get spec information for character
function ProfilesService:GetCharacterSpecs(characterID)
    -- Returns array of {specID, specName, role, icon}
end
```

### Step 4: Response Building
**File**: [`core/organizer/survey.lua`](core/organizer/survey.lua)

Update methods:
```lua
-- Build final response from phases
function ParticipantSurvey:BuildFinalResponse(phase1Data, phase2Data, phase3Data)
    -- Combines all phase data into final response structure
end

-- Process final response
function ParticipantSurvey:ProcessResponse(playerID, response)
    -- Handle final submission (existing method, update to handle new format)
end
```

### Step 5: Communication Protocol
No changes needed! The final response structure matches existing `ORG_POLL_RESPONSE` format. Only the UI flow changes.

---

## Testing Plan

### Unit Tests
**File**: [`debug/organizer_survey_tests.lua`](debug/organizer_survey_tests.lua)

```lua
-- Test Phase 1 card creation
function TestPhase1Cards()
    -- Verify 3 cards render correctly
    -- Verify click handlers work
end

-- Test Phase 2 alt selection
function TestPhase2AltSelection()
    -- Verify character cards display correct data
    -- Verify sorting (IO, current last)
end

-- Test Phase 3 spec selection
function TestPhase3SpecSelection()
    -- Verify 3-state toggle works
    -- Verify all class spec counts (2-4)
end

-- Test navigation
function TestPhaseNavigation()
    -- Verify back button works
    -- Verify phase transitions
end
```

### Integration Tests
```lua
-- Test complete "Yes" flow
function TestCompleteYesFlow()
    -- Phase 1 Yes → Phase 3 → Submit
end

-- Test complete "Yes on Alt" flow
function TestCompleteAltFlow()
    -- Phase 1 Yes Alt → Phase 2 → Phase 3 → Submit
end

-- Test Opt-Out flow
function TestOptOutFlow()
    -- Phase 1 No → Immediate close
end
```

---

## Migration Strategy

### Phase A: Build New UI (Non-Breaking)
1. Create new phase-specific UI methods in surveyDialog.lua
2. Keep existing `Show()` method unchanged
3. Add feature flag: `db.global.organizer.useProgressivePoll = false`

### Phase B: Switch Implementation
1. Update `Show()` to call `ShowPhase1()` when flag enabled
2. Test with small group

### Phase C: Full Rollout
1. Set flag default to `true`
2. Remove old implementation after validation period

---

## Edge Cases

### Current Character in Alt List
**Solution**: Show current character last in Phase 2 with "(Current)" label

### No Alt Characters
**Solution**: "Yes on Alt" button disabled or hidden if no alts saved

### Character Not Max Level
**Solution**: Filter out characters < max level from Phase 2

### Spec Data Missing
**Solution**: Show "Unknown Spec" with generic icon, still allow selection

### Window Closed Mid-Flow
**Solution**: Treat as opt-out (no response sent)

---

## Visual Examples

### Phase 1 (Participation)
```
╔═══════════════════════════════════════╗
║  M+ Group Organizer - Poll           ║
╠═══════════════════════════════════════╣
║  Sager is organizing M+ groups.      ║
║  Do you want to play M+ tonight?     ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  ✓  Yes                         │ ║
║  │     Play on current character   │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  ⇄  Yes on an Alt               │ ║
║  │     Choose different character  │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  ✗  No                          │ ║
║  │     Not playing tonight         │ ║
║  └─────────────────────────────────┘ ║
╚═══════════════════════════════════════╝
```

### Phase 3 (Spec Selection - Warrior Example)
```
╔═══════════════════════════════════════╗
║  M+ Group Organizer - Choose Specs   ║
╠═══════════════════════════════════════╣
║  Select specs for Sager:             ║
║  Click once to play, twice to fill   ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  [Icon]  Arms              ✓    │ ║ (Green border)
║  │          DPS                    │ ║
║  │          Will Play              │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  [Icon]  Fury              ⭐   │ ║ (Yellow border)
║  │          DPS                    │ ║
║  │          Fill if Needed         │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │  [Icon]  Protection             │ ║ (Grey border)
║  │          Tank                   │ ║
║  │          Click to play          │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  [← Back]               [Submit →]   ║
╚═══════════════════════════════════════╝
```

---

## Success Metrics

- **Reduced Decision Time**: < 15 seconds for Phase 1 decision
- **Reduced Errors**: No accidental opt-outs (require deliberate "No" click)
- **Improved Clarity**: Users understand spec selection (3 states clear)
- **Better Alt Support**: Seamless alt selection with full data display

---

## Future Enhancements

1. **Remember Last Selection**: Pre-select previously chosen specs
2. **Tooltip Explanations**: Hover tooltips explaining "Fill" vs "Play"
3. **Quick Presets**: "All Specs" button in Phase 3
4. **Character Notes**: Allow notes on character cards (e.g., "Geared for M+")
5. **Visual Feedback**: Animation when transitioning between phases

---

## Related Files

### Core Files
- [`ui/organizer/surveyDialog.lua`](ui/organizer/surveyDialog.lua) - Main UI implementation
- [`core/organizer/survey.lua`](core/organizer/survey.lua) - Survey logic
- [`core/characterStorage.lua`](core/characterStorage.lua) - Character data
- [`core/profiles.lua`](core/profiles.lua) - Spec information
- [`core/uiConfig.lua`](core/uiConfig.lua) - UI constants

### Reference Implementations
- [`ui/lootWindow.lua`](ui/lootWindow.lua) - Card-based UI pattern
- [`ui/teleport.lua`](ui/teleport.lua) - Native frame pattern
- [`ui/hearthstoneSelector.lua`](ui/hearthstoneSelector.lua) - Multi-card selection

### Testing Files
- [`debug/organizer_survey_tests.lua`](debug/organizer_survey_tests.lua) - Unit tests
- [`debug/pollSimulator.lua`](debug/pollSimulator.lua) - Integration tests

---

**End of Design Document**