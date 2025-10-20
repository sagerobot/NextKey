# NextKey Changelog

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
