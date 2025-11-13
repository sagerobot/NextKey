# Version Management

## Single Source of Truth

The canonical version number is stored in the [`VERSION`](VERSION:1) file at the project root. This file contains only the version number in the format `major.minor.patch` (e.g., `0.6.6`).

## Files to Update

When updating the version, the following files must be updated to maintain consistency:

### 1. VERSION (Source of Truth)
- **File:** [`VERSION`](VERSION:1)
- **Format:** `0.6.6` (plain version number, no prefix)

### 2. NextKey.toc
- **File:** [`NextKey.toc`](NextKey.toc:5)
- **Line:** 5
- **Format:** `## Version: 0.6.6`

### 3. boot.lua
- **File:** [`boot.lua`](boot.lua:54)
- **Lines:** 54-57
- **Format:**
  ```lua
  NextKey.build_counter = 34  -- Increment for each release
  NextKey.version_major = 0
  NextKey.version_minor = 6
  NextKey.version_patch = 6
  ```

### 4. CHANGELOG.md
- **File:** [`CHANGELOG.md`](CHANGELOG.md:54)
- **Add new entry at line 54** (after the header, before previous entries)
- **Format:** `## [v0.6.6] - YYYY-MM-DD`

### 5. README.md
- **File:** [`README.md`](README.md:166)
- **Line:** 166 - Update "Current Status" version
- **Line:** 196 - Add new release entry with description

### 6. RELEASE_GUIDE.md
- **File:** [`RELEASE_GUIDE.md`](RELEASE_GUIDE.md:27)
- **Multiple locations** - Update all version references throughout the guide

## Version Update Checklist

When releasing a new version:

1. ✅ Determine new version number using [`CHANGELOG.md`](CHANGELOG.md:15) increment rules
2. ✅ Update [`VERSION`](VERSION:1) file with new version
3. ✅ Update [`NextKey.toc`](NextKey.toc:5) (Line 5)
4. ✅ Update [`boot.lua`](boot.lua:54) (Lines 54-57, increment build_counter)
5. ✅ Add new entry to [`CHANGELOG.md`](CHANGELOG.md:54) (Line 54)
6. ✅ Update [`README.md`](README.md:166) current status and add release entry
7. ✅ Update all version references in [`RELEASE_GUIDE.md`](RELEASE_GUIDE.md:27)
8. ✅ Commit with message: `chore: bump version to vX.Y.Z`
9. ✅ Create git tag: `git tag vX.Y.Z`

## Automation Opportunity

In the future, consider creating a script (PowerShell or Bash) that:
1. Reads the version from [`VERSION`](VERSION:1)
2. Automatically updates all files listed above
3. Validates that all files are in sync

This would eliminate manual updates and reduce the risk of version mismatches.

## Version Numbering Rules

Follow the rules defined in [`CHANGELOG.md`](CHANGELOG.md:7):

| Change Type | Symbol | Patch Increment | Minor Increment |
|-------------|--------|----------------|-----------------|
| **Features** | 🚀 | — | +1 (reset patch to 0) |
| **Enhancements** | ✨ | +3 | — |
| **Optimizations** | ⚡️ | +2 | — |
| **Bug Fixes** | 🐛 | +1 | — |
| **Documentation** | 📚 | +1 | — |
| **Maintenance** | 🔧 | +1 | — |
| **Developer Features** | 🧪 | +5 | — |

**Important:** When a release has multiple change types, use only the **highest increment value**.