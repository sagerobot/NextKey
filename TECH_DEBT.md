# NextKey - Technical Debt Analysis & Recommendations

## Overview

This document provides an analysis of the current technical debt in the NextKey addon. The assessment is based on a review of the codebase, documentation, and overall project structure. While the addon is well-architected, several areas could be improved to enhance maintainability, reduce complexity, and ensure long-term stability.

---

## 1. Documentation Drift

### Observation
The `Documentation/` directory is comprehensive, but some documents are outdated or inconsistent with the current implementation.

- **`DESIGN.md` vs. Implementation**: The design document outlines features and data structures that are not fully implemented or have diverged. For example, the "PUG Mode" is mentioned but not fully realized in the UI.
- **Outdated Docs**: Some documents in `Documentation/LEGACY/` may contain outdated information that could confuse new developers.

### Recommendation
- **Audit and Update**: Conduct a thorough audit of all documentation. Update `DESIGN.md` to reflect the current state of the addon, or create a "v2" design document for future features.
- **Archive Legacy Docs**: Move any irrelevant legacy documents to a separate, clearly marked archive to prevent confusion.

---

## 2. Code Complexity & Hotspots

### Observation
Several files in the `core/` directory exhibit high complexity or have the potential to become maintenance burdens.

- **`core/scoring.lua`**: The scoring logic is complex and tightly coupled. This makes it difficult to modify or extend the scoring algorithms.
- **`core/utils.lua`**: This file has become a "catch-all" for miscellaneous functions, which reduces modularity and makes it harder to find specific functionality.
- **Redundant Season Logic**: The presence of `core/season.lua`, `core/seasons.lua`, and `core/seasons_utils.lua` suggests duplicated or disorganized logic for handling Mythic+ seasons.

### Recommendation
- **Refactor `core/scoring.lua`**: Break down the scoring module into smaller, more manageable functions. Consider a more modular design that allows for easier customization of scoring algorithms.
- **Organize `core/utils.lua`**: Group related functions in `core/utils.lua` into separate modules (e.g., `string_utils.lua`, `table_utils.lua`).
- **Consolidate Season Logic**: Merge the logic from the three season-related files into a single, well-structured module.

---

## 3. External Dependencies

### Observation
The addon has a hard dependency on the Raider.IO addon, which creates a potential point of failure.

- **Raider.IO Dependency**: If the Raider.IO addon is not present or changes its data structures, NextKey's functionality will be severely impacted.
- **Forks and Maintenance**: The `Libs/` directory contains forked or modified libraries, which can be difficult to maintain and update.

### Recommendation
- **Graceful Fallbacks**: Implement more robust fallback mechanisms if Raider.IO data is unavailable. The addon should still provide core functionality without it.
- **Dependency Management**: Establish a clear process for managing external libraries. Use unmodified libraries whenever possible and document any necessary changes.

---

## 4. Project Structure

### Observation
The project structure is generally clean, but a few inconsistencies could be addressed.

- **Root-level Test Files**: Test files like `test_button_visibility_debug.lua` are located in the root directory, which clutters the main project space.
- **Unclear File Naming**: Some file names are not descriptive, which can make it difficult to understand their purpose at a glance.

### Recommendation
- **Dedicated Test Directory**: Create a `tests/` directory to house all test-related files.
- **Consistent Naming Conventions**: Enforce a consistent naming convention for all files and directories.

---

## 5. Future-Proofing

### Observation
The addon's design is robust, but there are opportunities to make it more adaptable to future changes in the game.

- **Hardcoded Data**: `data/portals.lua` and other data files contain hardcoded information that will need to be manually updated with each new season or expansion.
- **Limited Extensibility**: The current architecture could be more modular to allow for easier addition of new features.

### Recommendation
- **Data-driven Design**: Move hardcoded data to configuration files or, where possible, fetch it from the game's API.
- **Modular Architecture**: Continue to refactor the codebase into smaller, more independent modules to improve extensibility.
