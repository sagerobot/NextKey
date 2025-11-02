# NextKey Changelog

## [0.2.2] - 2025-11-02
### Fixed
- **M+ Group Organizer Tooltip System** - Complete fix for post-poll tooltip issues
  - Fixed poll simulator double-appending realm names (`01FP-Dalaran-Dalaran` → `01FP-Dalaran`)
  - Fixed role icons vanishing for fake players after poll responses
  - Removed blank line between role header and spec details in tooltips
  - Normalized role naming inconsistency (DAMAGER → DPS) for all players
  - Fixed spec-level tooltip breakdowns not displaying for fake players after poll
  - Poll simulator now uses `OrganizerPlayerDataBuilder` for consistent spec preference generation

### Technical
- Enhanced `debug/pollSimulator.lua` to use correct character IDs for spec preference generation
- Updated `ui/organizer/playerCard.lua` tooltip formatting and role name normalization
- Added comprehensive debug logging to trace spec preference data flow
- Fixed `playerData.specPreferences` being empty after poll responses

## [0.2.1] - 2025-10-20
### Added
- **Loot Targeting System** - Complete implementation of item tracking functionality
  - New `data/loot.lua` with seasonal dungeon item data following portals.lua pattern
  - Enhanced `ui/lootWindow.lua` with full-featured item management interface
  - Item texture preloading system to prevent question mark icons
  - Support for default protected items and custom removable items
  - Persistent storage across sessions with database integration
  - Integration with dungeon cards via Loot button
  - Test suite for validation (`/nktestloot`)
  - Proper tooltips with item information and quality colors
  - Input system for adding custom items by ID

### Technical
- Updated `core/config.lua` with new lootTracking database structure
- Enhanced `core/dungeonCards.lua` with SaveLootTracking/LoadLootTracking methods
- Added `NextKey:HandleLootClick()` integration function
- Added comprehensive test suite in `debug/test_loot_system.lua`
- Updated NextKey.toc to include new data file and test suite

## [0.1.0] - 2024-02-04
### Added
- New DungeonCards visual interface system
  - Card-based display for available keystones
  - Visual dungeon artwork and progress indicators
  - Interactive preference controls
  - Grid layout with animations
- Preference system for dungeons
  - Like/Dislike buttons on dungeon cards
  - Per-character preference persistence
  - Real-time preference syncing with party
  - Smart sorting integration with preferences
- Enhanced loot tracking
  - Visual progress indicators on dungeon cards
  - Bad luck protection tracking
  - Drop chance display
- Updated UI/UX
  - List/Grid view toggle
  - Smooth animations and transitions
  - Responsive layout
  - Enhanced tooltips

## [0.0.2] - 2024-01-15
### Added
- Basic keystone tracking
- Simple score calculation
- Initial UI implementation

## [0.0.1] - 2024-01-01
### Added
- Initial addon structure
- Core module setup
- Basic dependency integration
