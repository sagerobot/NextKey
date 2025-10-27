# M+ Group Organizer - Phase 2 Testing Guide

**Version:** 1.0  
**Date:** October 27, 2025  
**Status:** Ready for Testing

---

## Overview

This guide provides step-by-step testing instructions for the Phase 2 Participant Survey System, including the debug mode poll simulator.

---

## Prerequisites

1. **Latest Code**: Ensure you have all Phase 2 files loaded:
   - `core/organizer/survey.lua`
   - `ui/organizer/surveyDialog.lua`
   - `debug/pollSimulator.lua`
   - Updated `ui/organizer/rosterBoard.lua`
   - Updated `core/comms.lua`
   - Updated `boot.lua`
   - Updated `events/handlers.lua`
   - Updated `core/fakePlayerService.lua`

2. **Reload Required**: `/reload` after updating files

3. **Debug Enabled**: Enable organizer debug category for verbose output:
   ```lua
   /nk config
   → Debug System
   → Enable "organizer" category
   ```

---

## Test Scenario 1: Poll Simulation (Solo Mode)

### Step 1: Generate Fake Players

```lua
/reload
/nk test preset raid_group
```

**Expected Output:**
- Message: "Created 20 fake players for preset: raid_group"
- Debug: "FakePlayerService: Created fake player: FakePlayer1-TestRealm..."

### Step 2: Open RosterBoard

```lua
/nk
```

**Expected Behavior:**
- M+ Group Organizer window appears (1400x800)
- Bench shows all 20 fake players in compact mode
- Opt-out section is empty
- Poll button is enabled (you're the organizer)

### Step 3: Run Instant Poll Simulation

```lua
/nk poll test instant
```

**Expected Output:**
- Console: "Starting Instant poll simulation with 20 players"
- Console: "Scheduled 20 responses (70% opt-in, 20% opt-out, 10% timeout)"
- Debug: Multiple "Scheduled opt_in/opt_out/timeout response" messages

**Expected Behavior (0-2 seconds):**
- Poll button changes to "Polling... (0/20)" → "Polling... (14/20)" → "Polling... (18/20)"
- Players appear in bench (opt-in)
- Players appear in opt-out section (opt-out)
- ~2 players don't respond (timeout)
- After ~2 seconds: "Poll complete: 18/19 members responded"
- Poll button resets to "Poll Group"

### Step 4: Verify RosterBoard Auto-Refresh

**Check Bench:**
- Count players: Should be ~14 (70% of 20)
- Cards should be compact (180x20px)
- Scrollable if more than ~25 players

**Check Opt-Out:**
- Count players: Should be ~4 (20% of 20)
- Cards should be compact (90x40px)
- Horizontally scrollable

**Check Alt Selection:**
- Debug log: Look for "Player {name} selected alt: {name}Alt"
- ~30% of opt-in players should have selected alts
- Main should appear in opt-out, alt should appear in bench

### Step 5: Test Realistic Poll Simulation

```lua
/nk test clear
/nk test preset raid_group
/nk poll test realistic
```

**Expected Behavior (0-60 seconds):**
- Responses stagger over 60 seconds
- Watch poll progress update: "Polling... (1/19)" → "(5/19)" → "(12/19)" → etc.
- Cards appear in bench/opt-out as responses arrive
- Final completion after 60 seconds or all responses received

---

## Test Scenario 2: Manual Poll Testing (Group Mode)

### Prerequisites
- Join a real group with 2+ members (or have a friend test with you)
- All members should have NextKey installed (optional - you can test mixed scenarios)

### Step 1: Start Poll

```lua
/nk
→ Click "Poll Group" button
```

**Expected Behavior (Organizer):**
- Button changes to "Polling... (0/4)" (assuming 5-player group)
- Survey dialog appears on **other** members (not yourself)
- 60-second timeout timer starts

**Expected Behavior (Participant):**
- Survey dialog pops up with:
  - "Participation" section (Opt In / Opt Out radio buttons)
  - Character selection dropdown (current char + alts if detected)
  - Role preference checkboxes (if opt-in selected)
  - Submit/Cancel buttons

### Step 2: Participant Responds

**Opt-In Path:**
1. Select "Opt In" radio
2. Choose character (current or alt)
3. Select role preferences (Tank/Healer/DPS)
4. Click "Submit"

**Opt-Out Path:**
1. Select "Opt Out" radio
2. Click "Submit"

**Expected Behavior (Organizer):**
- Poll progress updates: "Polling... (1/4)" → "(2/4)" → etc.
- Player cards appear in bench (opt-in) or opt-out section
- If alt selected: Alt card in bench, main card in opt-out
- When all respond or 60s timeout: "Poll complete: {count}/{total} members responded"

---

## Test Scenario 3: Mixed Data Sources

### Fake Players + Auto-Detection

```lua
/nk test preset mixed_skill  -- 4 fake players
→ Join a real group with 2 friends
→ Click "Poll Group"
```

**Expected Behavior:**
- Fake players auto-respond via simulator (if enabled)
- Real players receive survey dialog
- Auto-detection scans for non-NextKey users
- All player types appear correctly in bench/opt-out

---

## Debugging Commands

### Check Poll Status

```lua
/nk poll status
```

**Output:**
- Active poll ID
- Pattern type (instant/realistic)
- Player count
- Elapsed time

### Clear Poll Simulation

```lua
/nk poll clear
```

**Output:**
- "Cleared poll simulation"
- Resets all simulation state

### Check RosterBoard State

```lua
/script print("Bench cards:", #NextKey222.RosterBoard.benchCards)
/script print("Opt-out cards:", #NextKey222.RosterBoard.optOutSection.playerCards)
/script print("Active poll:", NextKey222.RosterBoard.activePoll and NextKey222.RosterBoard.activePoll.id or "none")
```

---

## Common Issues & Solutions

### Issue: "Nothing happens when I run /nk poll test instant"

**Diagnosis:**
1. Check PollSimulator initialization:
   ```lua
   /script print(NextKey222.PollSimulator:IsInitialized())
   ```
   → Should print `true`

2. Check for fake players:
   ```lua
   /script print(#NextKey222.FakePlayerService:GetAllPlayerNames())
   ```
   → Should print `20` (if raid_group preset used)

**Solution:**
- If `false`: Run `/reload` to initialize modules
- If `0`: Run `/nk test preset raid_group` first

### Issue: "RosterBoard doesn't update when responses arrive"

**Diagnosis:**
1. Check if RosterBoard is visible:
   ```lua
   /script print(NextKey222.RosterBoard:IsVisible())
   ```

2. Check debug output for response processing:
   - Enable "organizer" category in debug system
   - Look for "OnPollResponseReceived" messages

**Solution:**
- Ensure window is open (`/nk`)
- Check for errors in chat (enable `/console scriptErrors 1`)

### Issue: "Poll button stays disabled after timeout"

**Diagnosis:**
- Check if activePoll is cleared:
  ```lua
  /script print(NextKey222.RosterBoard.activePoll)
  ```
  → Should print `nil` after completion

**Solution:**
- Manually clear poll state:
  ```lua
  /script NextKey222.RosterBoard:CompletePoll()
  ```

---

## Validation Checklist

- [ ] **Initialization**: All Phase 2 modules load without errors
- [ ] **Poll Simulation (Instant)**: 20 fake players respond within 2 seconds
- [ ] **Poll Simulation (Realistic)**: Responses stagger over 60 seconds
- [ ] **RosterBoard Auto-Refresh**: Bench/opt-out populate as responses arrive
- [ ] **Poll Progress Updates**: Button text updates correctly
- [ ] **Alt Selection**: ~30% of opt-ins select alts, main goes to opt-out
- [ ] **Response Distribution**: ~70% opt-in, ~20% opt-out, ~10% timeout
- [ ] **Timeout Handling**: Poll completes after 60s if not all respond
- [ ] **Manual Poll**: Real players can respond via survey dialog
- [ ] **Mixed Groups**: Fake + real players work together

---

## Next Steps After Validation

Once all validation checks pass, proceed to:

1. **Phase 3: Manual Mode** - Drag-and-drop workflow, group validation
2. **Update Master Checklist** - Mark Phase 2 as "✅ Complete"
3. **Memory Bank Update** - Document Phase 2 completion in context.md

---

**Testing Notes:**

_Use this space to document any issues encountered during testing:_

- 
- 
- 
