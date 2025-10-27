# NextKey Current Status & Requirements

## Project Status
**Date**: October 25, 2025
**Version**: 0.2.1
**Phase**: M+ Group Organizer UI Complete

## Phase 1: M+ Group Organizer UI
**State**: Implementation complete, validation in progress.

### Delivered
- `ui/organizer/rosterBoard.lua` and `ui/organizer/playerCard.lua` completely redesigned.
- Compact, single-line, draggable player cards for the bench.
- Visually distinct group slots with role-colored borders.
- Class-colored backgrounds for player cards.
- Card expansion on drop with more detailed information.
- Role validation and "bounce-back" logic for invalid placements.
- Modern WoW API compatibility using texture-based UI components instead of `SetBackdrop`.
- Drag-and-drop functionality fixed with `OnMouseDown`/`OnMouseUp` event handling.

### Outstanding Validation
1. In-game validation of the new M+ Group Organizer UI.
2. Verification of drag-and-drop functionality, role validation, and visual fidelity.

## Phase 3: Loot Targeting System (Queued)
- Validation of the loot targeting system is queued until the M+ Group Organizer UI is stable.

## Phase 4: PUG Mode (Queued)
- PUG mode repairs and feature work are queued until the loot targeting system is validated.

## Implementation Priorities
1. Finish M+ Group Organizer UI validation.
2. Resume and complete loot targeting system validation.
3. Resume PUG mode repairs.

## Technical Notes
- The new UI uses texture-based rendering for backgrounds and borders to ensure compatibility with modern WoW API versions.
- The drag-and-drop system now uses `OnMouseDown`/`OnMouseUp` events, which is a more robust solution for AceGUI `InlineGroup` widgets.
