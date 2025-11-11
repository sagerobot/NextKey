# NextKey Project Brief

## Project Identity
**Name**: NextKey
**Type**: World of Warcraft Addon
**Version**: 0.6.0
**Game Version**: Retail (11.0.2+)
**Primary Language**: Lua
**Current Phase**: Major UI Architecture Release — Independent Two-Window System, Modular UI Complete

## Core Purpose
NextKey is a Mythic+ keystone optimization addon that helps groups intelligently select the best dungeon run next by analyzing party keystones, player scores, and loot preferences in under 30 seconds. It also features:
- A robust M+ Group Organizer for forming and managing multi-group raid-style teams
- A unified teleport system with leader-synced key selection
- A hardened PUG Helper flow for LFG-based groups

## Target Users
- Mythic+ premade groups optimizing key selection
- Party leaders making dungeon run decisions
- Raid leaders organizing M+ groups
- Score pushers improving Mythic+ ratings
- Loot-focused players farming specific items
- Players using LFG/PUG flows who need clean, guided travel and decision support

## Operating Modes
1. **Premade Group Mode** (Default)
   - Full functionality with automatic key sharing, score syncing, advanced sorting
2. **PUG Mode**
   - Simplified, hardened travel and decision assistance for group finder groups
   - Uses a dedicated PUG Helper stack with stateful tracking and PUG-aware teleport UI
3. **M+ Group Organizer**
   - Raid-style multi-group organizer backed by OrganizerState as a single source of truth
   - Handshake + poll driven data collection and synchronized roster layout

## Key Success Metrics
- **Decision Time**: Groups select next key in <30 seconds
- **Performance**: <100ms UI response time, <10MB memory baseline
- **Reliability**: 99.9% uptime during gameplay
- **User Experience**: Intuitive for new players, powerful for experts

## Core Value Proposition
Transforms group key selection from a time-consuming decision process into an instant, data-driven recommendation that:
- Maximizes IO gain for the group
- Respects player preferences and loot targets
- Supports both premade and PUG/LFG environments with minimal friction

## Development Philosophy
- **User-First**: Every feature solves a real user problem
- **Performance**: Never impact gameplay experience
- **Reliability**: Comprehensive error handling and graceful degradation
- **Maintainability**: Clean architecture following Details! Damage Meter patterns
- **Professional Quality**: Enterprise-grade debugging, performance monitoring, modular design
- **Component-Driven**: Factory-based UI and centralized state (OrganizerState) for deterministic behavior

## Recent Completion: M+ Group Organizer & Sync Systems
The M+ Group Organizer and supporting systems have been implemented and hardened, including:
- OrganizerState as the single source of truth for organizer players/bench/groups/keystones/polls
- Compact, single-line, draggable player cards for the bench
- Visually distinct group slots with role-colored borders and class-colored cards
- Card expansion on drop with detailed information
- Role validation and "bounce-back" logic for invalid placements
- Modern WoW API compatibility (texture-based UI components)
- Organizer-specific handshake and poll flows built on top of Communications

## Current Phase: v0.6.0 Release
- Major UI architecture improvements complete:
  - Independent Two-Window Architecture: Keystone Selection and Dungeon Overview windows operate completely independently
  - UI Main Refactoring: Transformed monolithic 3000+ line file into 13 specialized modules (49% code reduction)
  - OrganizerState module fully wired into organizer UI
  - Unified handshake/poll system implemented
  - Teleport selection sync (TELEPORT_SELECT) hardened with single-source SetTeleportTargetKey API
  - PUG Helper architecture implemented and integrated with teleport window
- Active Focus:
  - Validate independent window behavior in production environments
  - Continue organizer flows and TELEPORT_SELECT validation in real groups
  - Validate PUG Mode behavior end-to-end using the hardened PUG Helper stack
  - Reconfirm Loot Targeting System correctness under the current architecture
