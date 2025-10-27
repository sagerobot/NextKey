# NextKey Project Brief

## Project Identity
**Name**: NextKey
**Type**: World of Warcraft Addon
**Version**: 0.2.1
**Game Version**: Retail (11.0.2+)
**Primary Language**: Lua
**Current Phase**: M+ Group Organizer Implementation

## Core Purpose
NextKey is a Mythic+ keystone optimization addon that helps groups intelligently select the best dungeon run next by analyzing party keystones, player scores, and loot preferences in under 30 seconds. It also features a robust M+ Group Organizer for forming and managing groups.

## Target Users
- Mythic+ premade groups optimizing key selection
- Party leaders making dungeon run decisions
- Raid leaders organizing M+ groups
- Score pushers improving Mythic+ ratings
- Loot-focused players farming specific items

## Operating Modes
1. **Premade Group Mode** (Default): Full functionality with automatic key sharing, score syncing, complex sorting
2. **PUG Mode**: Simplified travel assistance for group finder groups
3. **M+ Group Organizer**: Advanced UI for raid-style M+ group formation

## Key Success Metrics
- **Decision Time**: Groups select next key in <30 seconds
- **Performance**: <100ms UI response time, <10MB memory baseline
- **Reliability**: 99.9% uptime during gameplay
- **User Experience**: Intuitive for new players, powerful for experts

## Core Value Proposition
Transforms group key selection from a time-consuming decision process into an instant, data-driven recommendation that maximizes IO gain and respects player preferences.

## Development Philosophy
- **User-First**: Every feature solves a real user problem
- **Performance**: Never impact gameplay experience
- **Reliability**: Comprehensive error handling and graceful degradation
- **Maintainability**: Clean architecture following industry best practices (Details! Damage Meter patterns)
- **Professional Quality**: Enterprise-grade debugging, performance monitoring, modular design
- **Component-Driven**: Established factory pattern for consistent UI creation

## Recent Completion: M+ Group Organizer UI
The M+ Group Organizer UI has been implemented, featuring a complete visual redesign with:
- Compact, single-line, draggable player cards for the bench
- Visually distinct group slots with role-colored borders
- Class-colored backgrounds for player cards
- Card expansion on drop with more detailed information
- Role validation and "bounce-back" logic for invalid placements
- Modern WoW API compatibility (texture-based UI components)

**Current Phase**: M+ Group Organizer UI complete.

## Current Focus
- Validating the M+ Group Organizer UI in a live environment
- Verifying drag-and-drop functionality, role validation, and visual fidelity
- Queued: Loot targeting system validation and PUG mode repairs
