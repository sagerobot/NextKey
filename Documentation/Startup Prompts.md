I'm working on a World of Warcraft addon called NextKey located at `c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\NextKey`. This is a Mythic+ dungeon keystone management and recommendation system.

**Essential Files for Complete Project Understanding:**

**1. Project Documentation & Design:**
   - `Documentation/NextKey - Addon Design Document.md` - Complete system architecture and design patterns
   - `Documentation/NextKey - Design Intent.md` - Core goals, target users, and feature philosophy  
   - `Documentation/NextKey - Roadmap.md` - Development phases, milestones, and current status
   - `IMPLEMENTATION_SUMMARY.md` - Recent major changes and system evolution
   - PLAN.md - Current development objectives and phase breakdown
   - CHANGELOG.md - Version history and feature additions

**2. Core System Architecture:**
   - ioCalculator.lua - Central scoring engine and player data management
   - main.lua - Primary UI components, tooltips, and user interaction
   - keystones.lua - Keystone detection, validation, and management
   - comms.lua - Inter-addon communication and data sharing
   - config.lua - Configuration management and settings
   - init.lua - Debug systems and fake data generation

**3. Data & Integration Systems:**
   - raiderio.lua - RaiderIO API integration for player scoring
   - libopenraid.lua - LibOpenRaid library integration
   - scoring.lua - Scoring algorithms and calculations
   - season.lua & seasons.lua - Season management and dungeon rotation
   - portals.lua - Dungeon portal and teleportation data

**4. UI & User Experience:**
   - dungeonCards.lua - Dungeon selection and display components
   - lootWindow.lua - Loot tracking and display
   - teleport.lua - Teleportation UI and functionality
   - main.lua - Configuration interface and user settings

**5. Framework & API Documentation:**
   - AceAddon-3.0.md - Addon framework fundamentals
   - AceGUI-3.0.md - UI framework and widget system
   - AceDB-3.0.md - Database and persistent storage
   - AceConfig-3.0.md - Configuration system
   - `Documentation/RaiderIO Dev API.md` - External API integration

**6. Integration & Technical Specs:**
   - `LibOpenRaid_Integration.md` - External library integration details
   - `RAIDERIO_FALLBACK_IMPLEMENTATION.md` - API fallback strategies
   - NextKey.toc - Addon metadata and dependencies
   - embeds.xml - Library embedding configuration

**Key Technical Context:**
- **Architecture**: Modular design with Phase-based development (currently Phase 3A+)
- **Framework**: Built on Ace3 library suite for WoW addon development
- **Data Flow**: Unified IOCalculator → UI Components → User Interaction
- **Integration**: RaiderIO API, LibOpenRaid, Ace3 communications
- **Storage**: AceDB for persistent settings and fake player debug data
- **UI Pattern**: AceGUI widgets with custom tooltip and card systems

**Development Methodology:**
The project follows a structured phase approach with clear separation of concerns between scoring, UI, data management, and external integrations. Each major system has dedicated modules with well-defined interfaces.

**Common Areas of Work:**
- Scoring system enhancements and accuracy
- UI/UX improvements and tooltip functionality  
- Cross-addon communication and data sharing
- Season updates and dungeon rotation management
- Performance optimization and error handling
- Debug tools and fake data systems

Please read the documentation files first for architectural understanding, then examine the relevant core systems based on what you need to work on. The codebase is well-modularized, so you can focus on specific subsystems without needing to understand everything at once.