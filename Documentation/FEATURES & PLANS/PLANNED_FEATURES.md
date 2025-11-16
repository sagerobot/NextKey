# NextKey Planned Features

This document tracks feature ideas and enhancements that are planned but not yet ready for implementation. These are notes to preserve ideas for future development.

**Status**: Ideas Only - Not Scheduled for Implementation

---

## 1. Leader-Initiated Teleport Sync

### Description
Convert the teleport button in the main `/nk` window into a "Send Teleport" button that broadcasts the teleport window to all group members who have NextKey installed.

### Requirements
- Only available to group leader
- When leader selects a dungeon and clicks the button:
  - Opens the teleport spell selection window on all addon users' screens
  - Shows the leader's selected dungeon
- Similar technology to the poll window system

### Technical Approach
- Leverage existing organizer poll/handshake communication patterns
- Use AceComm-3.0 for broadcast messaging
- New opcode: `TELEPORT_BROADCAST` or similar
- Receiver validation: only process if sender is current group leader
- UI: Convert existing teleport button into conditional "Send Teleport" (leader) vs "Teleport" (non-leader)

### Integration Points
- [`core/comms.lua`](../../core/comms.lua) - Add new message opcode
- [`core/organizer/comms.lua`](../../core/organizer/comms.lua) - Potentially reuse broadcast patterns
- [`ui/main.lua`](../../ui/main.lua) or [`ui/controls.lua`](../../ui/controls.lua) - Modify teleport button behavior
- [`ui/teleport.lua`](../../ui/teleport.lua) - Handle incoming teleport broadcast messages

### Related Systems
- Builds on existing TELEPORT_SELECT sync from 0.6.0
- Extends the leader-synced teleport pattern
- Similar to organizer poll distribution mechanism

### Considerations
- Verify group leader status before broadcast
- Handle edge cases (leader change mid-broadcast, player joins after broadcast)
- User preference: allow users to disable auto-popup from leader broadcasts
- Throttling: prevent spam if leader clicks repeatedly

---

## 2. Minimap Button

### Description
Add a minimap button for quick access to NextKey functionality.

### Requirements
- Standard WoW minimap button integration
- Click to open main window
- Right-click for quick menu (potential options: config, teleport, organizer)
- Drag to reposition around minimap

### Technical Approach
- Use LibDBIcon-1.0 (LibDataBroker display library)
  - Standard library for minimap buttons
  - Handles positioning, dragging, saved positions
  - Compatible with most minimap addons
- Alternative: Custom implementation using Blizzard minimap API
  - More control but more maintenance

### Integration Points
- Add LibDBIcon-1.0 to [`embeds.xml`](../../embeds.xml)
- New file: `core/minimapButton.lua` or `ui/minimapButton.lua`
- Register LibDataBroker data source
- Hook to existing window toggle functions
- Save position in SavedVariables

### Related Systems
- Slash commands: `/nk` - minimap button provides GUI alternative
- Main window toggle: share same show/hide logic
- Config system: option to hide minimap button

### Considerations
- Make minimap button optional (some users prefer clean minimaps)
- Coordinate with other minimap addons (SexyMap, etc.)
- Tooltip on hover showing version, quick stats, or menu options
- Icon design: create or source appropriate icon

### Resources
- LibDBIcon-1.0: https://www.curseforge.com/wow/addons/libdbicon-1-0
- LibDataBroker-1.1: https://www.curseforge.com/wow/addons/libdatabroker-1-1

---

## 3. Auto-Select Top Keystone

### Description
Add a checkbox next to the sort dropdown in the main window that automatically selects the #1 ranked keystone for the selected sort mode and sends it to the group via the teleport broadcast system.

### Requirements
- Checkbox positioned near the sort dropdown in main window header
- Label: "Auto-Select Top" or "Auto-Send #1" or similar
- When enabled:
  - Automatically selects the top-ranked keystone based on current sort mode
  - Immediately broadcasts this selection to group (same as clicking teleport button)
  - Updates automatically when sort mode changes
- Leader-only feature (checkbox disabled/hidden for non-leaders)

### Technical Approach
- UI widget: AceGUI CheckBox or custom WoW CheckButton
- Hook into sort dropdown change event
- On checkbox toggle or sort change (when checkbox is checked):
  - Get top keystone from current sorted list
  - Call teleport selection/broadcast logic
  - Update teleport button state to reflect current selection
- Save checkbox state in SavedVariables (per-character preference)

### Integration Points
- [`ui/controls.lua`](../../ui/controls.lua) or [`ui/mainWindow.lua`](../../ui/mainWindow.lua) - Add checkbox widget near sort dropdown
- [`ui/rendering.lua`](../../ui/rendering.lua) - Hook into sort update logic
- [`ui/main.lua`](../../ui/main.lua) - Access sorted keystone list
- Teleport broadcast system from Feature #1 (Leader-Initiated Teleport Sync)
- [`core/config.lua`](../../core/config.lua) - Add SavedVariable for checkbox state

### Related Systems
- Builds on Feature #1 (Leader-Initiated Teleport Sync)
- Integrates with existing sort system from 0.6.0
- Uses same broadcast mechanism as teleport button
- Leverages sorting algorithms from [`core/sorting/main.lua`](../../core/sorting/main.lua)

### Considerations
- UX: Clear visual feedback when auto-selection triggers
- Performance: Throttle updates if sort mode changes rapidly
- Edge cases:
  - What if no keystones available? (disable checkbox, show tooltip)
  - What if top keystone changes mid-session? (update automatically or require manual re-check?)
  - Group leader changes while checkbox enabled (disable for new non-leader)
- User control: Easy to toggle on/off without disrupting workflow
- Notification: Consider subtle feedback to group members when auto-selected keystone updates

### User Workflow
1. Leader opens `/nk` main window
2. Selects preferred sort mode (e.g., "Smart Sort", "Max Group IO")
3. Enables "Auto-Select Top" checkbox
4. Top keystone automatically broadcasts to group
5. If leader changes sort mode, new #1 keystone auto-broadcasts
6. Group members see teleport window update in real-time

---

## Future Ideas (Unstructured)

Add additional planned features here as they come up:

- [ ] Quick keystone swap UI (drag-and-drop keystone trading interface)
- [ ] Weekly chest reward tracking
- [ ] Dungeon route integration (MDT compatibility)
- [ ] Voice chat integration markers (which players are in voice)

---

## Notes

- Keep this document updated as ideas evolve
- Move features to proper implementation docs when ready to build
- Archive completed features to CHANGELOG.md

**Last Updated**: 2025-11-15