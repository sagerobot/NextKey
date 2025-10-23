# NextKey Project Brief

## Project Identity
**Name**: NextKey  
**Type**: World of Warcraft Addon  
**Version**: 0.2.1  
**Game Version**: Retail (11.0.2+)  
**Primary Language**: Lua  
**Current Phase**: Post-UI Refactor Bugfixing Phase - Loot System Stabilization

## Core Purpose
NextKey is a Mythic+ keystone optimization addon that helps groups intelligently select the best dungeon run next by analyzing party keystones, player scores, and loot preferences in under 30 seconds.

## Target Users
- Mythic+ premade groups optimizing key selection
- Party leaders making dungeon run decisions  
- Score pushers improving Mythic+ ratings
- Loot-focused players farming specific items

## Operating Modes
1. **Premade Group Mode** (Default): Full functionality with automatic key sharing, score syncing, complex sorting
2. **PUG Mode**: Simplified travel assistance for group finder groups

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

## Recent Completion: UI Refactor (Phases 1-6)
The UI refactor successfully transformed NextKey's UI system:
- **Phase 1**: Comprehensive analysis of UI patterns and Ace3 migration opportunities
- **Phase 2**: Created Ace3 configuration wrapper system for consistent styling
- **Phase 3**: Migrated main window to pure Ace3 with configuration wrappers
- **Phase 4**: Migrated secondary UI components to Ace3
- **Phase 5**: Migrated all PUG Mode UI components to Ace3
- **Phase 6**: Created comprehensive Ace3 best practices documentation

**Current Phase**: Bugfixing and stabilization to restore full functionality after the refactor, with emphasis on validating the loot targeting system added in 0.2.1 before resuming PUG mode work.

## Current Focus
- Exercise the Season 3 loot targeting workflow (rendering, persistence, item data audit, Hero-track tooltip fix)
- Confirm run counter logic and cross-session storage introduced with the new loot system
- Queue Phase 4 PUG mode repairs once loot targeting is stable in live play
