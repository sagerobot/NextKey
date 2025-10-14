# Release Preparation Guide

This document outlines the steps to prepare the NextKey addon for a new release. Following these guidelines ensures a clean, user-friendly, and efficient release package.

## 1. Remove Unnecessary Files and Directories

Before creating a release candidate, the following files and directories should be removed from the codebase. These are either development-related, temporary, or not required by the end-user.

### Directories to Remove:
- **.git/**: Git version control directory.
- **.kilocode/**: Kilocode development directory.
- **.vscode/**: VSCode workspace settings.
- **Documentation/EXAMPLE ADDONS/**: Example addons for developers.
- **Documentation/LEGACY/**: Legacy documentation.
- **Logs/**: Log files, if any.

### Files to Remove:
- **.gitignore**: Specifies intentionally untracked files to ignore.
- **PLAN.md**: Development plan.
- **REFACTOR_SUGGESTIONS.md**: Suggestions for refactoring.
- **TECH_DEBT.md**: Technical debt documentation.
- **TESTING_INSTRUCTIONS.md**: Instructions for testing.
- **migrate_ui_debug.ps1**: UI migration debug script.
- **test_button_visibility_debug.lua**: Debug script for button visibility.
- **test_button_visibility_fix.lua**: Debug script for button visibility fix.
- **test_dungeon_view_debug_buttons.lua**: Debug script for dungeon view buttons.
- **All Ace3 framework markdown files in `Documentation/`**: e.g., `AceAddon-3.0.md`, `AceGUI-3.0.md`, etc.
- **Developer-facing documentation in `Documentation/`**:
    - `CONSOLIDATION_SUMMARY.md`
    - `DEBUG_IMPLEMENTATION_GUIDE.md`
    - `DEBUG_SYSTEM.md`
    - `DEBUG_SYSTEM_USER_GUIDE.md`
    - `DESIGN.md`
    - `DEVELOPMENT.md`
    - `DOCUMENTATION_MAINTENANCE.md`
    - `FAKE_PLAYERS.md`
    - `INTELLIGENT_GROUPING_SYSTEM.md`
    - `IO_GAIN_SYSTEM_ANALYSIS.md`
    - `LibStub.md`
    - `RaiderIO Dev API.md`

## 2. Review and Retain User-Facing Documentation

The following documentation files are intended for the end-user and should be included in the release.

### Documentation to Keep:
- **CHANGELOG.md**: A log of changes for the current version.
- **Getting Started.md**: A guide for new users.
- **PUG-MODE.md** or **PUG_MODE.md**: Information on PUG mode.
- **README.md**: The main README file.
- **SLASH_COMMANDS.md**: A list of available slash commands.
- **Startup Prompts.md**: Information on startup prompts.
- **USER_GUIDE.md**: The main user guide.
- **Frame.png** and **Frame2.png**: UI-related images for documentation.

Ensure that the `README.md` in the `Documentation/` directory is reviewed and either updated or removed if it is not intended for the end-user.

## 3. Versioning

Before finalizing the release, ensure that the addon version number in `NextKey.toc` is updated to reflect the new release version.

## 4. Final Check

Perform a final check of the codebase to ensure no stray debug code or temporary files have been left behind. The addon should be in a clean state, ready for packaging.
