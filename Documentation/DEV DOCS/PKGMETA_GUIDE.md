# .pkgmeta Guide for NextKey

## Overview

`.pkgmeta` is a YAML configuration file used by **CurseForge** and **WoWInterface** packaging tools to control what gets included in release builds of your addon. This allows you to keep development files, documentation, and debug tools in your GitHub repository while excluding them from the addon packages that users download.

## Key Concept: Two-Tier File Management

| File | Purpose | Controls |
|------|---------|----------|
| `.gitignore` | Development exclusions | What **doesn't go into GitHub** (runtime logs, temp files, personal settings) |
| `.pkgmeta` | Release exclusions | What **doesn't go into user downloads** (docs, debug tools, dev environment) |

**Best Practice for NextKey:**
- Keep `.gitignore` minimal (only runtime/temp files)
- Use `.pkgmeta` to exclude development content from releases
- Result: Full context in repo, clean addon for users

---

## .pkgmeta Format

`.pkgmeta` uses YAML syntax. Here are the key sections:

### 1. Basic Package Configuration

```yaml
package-as: NextKey

enable-nolib-creation: no
```

- `package-as`: The name of the addon package (should match your addon folder name)
- `enable-nolib-creation`: Whether to create a separate "nolib" version (typically `no` for addons that embed dependencies)

### 2. Ignore Section (What to Exclude from Releases)

```yaml
ignore:
  # Development environment
  - .kilocode
  - .vscode
  - .github
  
  # Documentation (keep in repo, exclude from downloads)
  - Documentation
  - README
  - CHANGELOG.md
  - TOOLTIP_BUG_REPORT.md
  
  # Debug and testing tools
  - debug
  - Logs
  
  # Build/temp files
  - "*.log"
  - "*.bak"
  - "*.tmp"
  - .DS_Store
  - Thumbs.db
  
  # Meta files
  - .gitignore
  - .pkgmeta
```

**Important Notes:**
- Use directory names without trailing slashes
- Use quotes around wildcard patterns (`"*.log"`)
- Paths are relative to addon root
- These files stay in GitHub but won't be in user downloads

### 3. Externals Section (Library Dependencies)

```yaml
externals:
  Libs/LibStub:
    url: https://repos.wowace.com/wow/libstub/trunk
    tag: latest
  Libs/AceAddon-3.0:
    url: https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0
    tag: latest
```

**Purpose:** Automatically fetch and include library dependencies at packaging time.

**For NextKey:** You can either:
1. **Keep `Libs/` in repo** (easier for developers, repo is larger)
2. **Use externals** (cleaner repo, CurseForge fetches libraries during packaging)

---

## Recommended .pkgmeta for NextKey

Create a file named `.pkgmeta` in your addon root:

```yaml
# NextKey Packaging Metadata
package-as: NextKey

# Exclude development files from releases
ignore:
  # Development environment
  - .kilocode
  - .vscode
  - .github
  
  # Documentation (keep in repo, exclude from user downloads)
  - Documentation
  - README
  - CHANGELOG.md
  - TOOLTIP_BUG_REPORT.md
  
  # Debug and testing tools
  - debug
  - Logs
  
  # Build/temp files
  - "*.log"
  - "*.bak"
  - "*.tmp"
  - .DS_Store
  - Thumbs.db
  
  # Meta files
  - .gitignore
  - .pkgmeta

# External library dependencies
# Option 1: Keep Libs/ in repo - comment out this section
# Option 2: Use externals - uncomment and CurseForge will fetch them

# externals:
#   Libs/LibStub:
#     url: https://repos.wowace.com/wow/libstub/trunk
#     tag: latest
#   Libs/CallbackHandler-1.0:
#     url: https://repos.wowace.com/wow/callbackhandler/trunk/CallbackHandler-1.0
#     tag: latest
#   Libs/AceAddon-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0
#     tag: latest
#   Libs/AceComm-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceComm-3.0
#     tag: latest
#   Libs/AceConfig-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceConfig-3.0
#     tag: latest
#   Libs/AceConsole-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceConsole-3.0
#     tag: latest
#   Libs/AceDB-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceDB-3.0
#     tag: latest
#   Libs/AceEvent-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceEvent-3.0
#     tag: latest
#   Libs/AceGUI-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceGUI-3.0
#     tag: latest
#   Libs/AceSerializer-3.0:
#     url: https://repos.wowace.com/wow/ace3/trunk/AceSerializer-3.0
#     tag: latest
#   Libs/LibOpenRaid:
#     url: https://github.com/Tercioo/LibOpenRaid
#     tag: latest

enable-nolib-creation: no
```

---

## Recommended .gitignore Strategy

Keep `.gitignore` **minimal** since `.pkgmeta` handles release exclusions:

```gitignore
# WoW Addon Development - NextKey .gitignore
# Keep this minimal - .pkgmeta handles release exclusions

# Runtime logs (generated during gameplay)
Logs/
*.log

# Personal editor settings (optional - uncomment if you don't want to share)
# .vscode/

# Operating System Files
.DS_Store
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.bak
*~

# IDE/Editor specific
.idea/
*.swp
*.swo
```

**Rationale:**
- Only exclude files that shouldn't be in version control at all (logs, OS files, personal settings)
- Keep everything else in the repo for contributors and AI context
- Use `.pkgmeta` to control what users download

---

## Workflow Summary

### What Goes Where

| File/Directory | GitHub Repo | Release Build | Reason |
|----------------|-------------|---------------|---------|
| `core/`, `ui/`, `data/` | ✅ | ✅ | Core addon code - needed by users |
| `Libs/` | ✅ | ✅ | Dependencies - needed by users |
| `options/` | ✅ | ✅ | Configuration UI - needed by users |
| `events/` | ✅ | ✅ | Event handlers - needed by users |
| `Documentation/` | ✅ | ❌ | Dev docs - not needed by users |
| `debug/` | ✅ | ❌ | Test tools - not needed by users |
| `.kilocode/` | ✅ | ❌ | AI dev environment - not needed by users |
| `.vscode/` | ✅ | ❌ | Editor settings - not needed by users |
| `.github/` | ✅ | ❌ | CI/CD workflows - not needed by users |
| `Logs/` | ❌ | ❌ | Runtime logs - shouldn't be committed |
| `*.log`, `*.bak` | ❌ | ❌ | Temp files - shouldn't be committed |

### Benefits for NextKey

1. **For AI/Contributors:**
   - Full context available in GitHub repo
   - Memory Bank (`.kilocode/`) preserved
   - Documentation and debug tools accessible
   - Architectural decisions documented

2. **For Users:**
   - Clean, minimal addon download
   - No unnecessary files bloating installation
   - Faster downloads and updates
   - Professional release quality

3. **For Maintainers:**
   - Single source of truth in GitHub
   - No manual file copying for releases
   - Automated packaging via CurseForge/WoWInterface
   - Version control for all development assets

---

## Testing Your .pkgmeta

### Local Testing
You can't fully test `.pkgmeta` locally since it's processed by CurseForge/WoWInterface servers. However, you can validate:

1. **YAML Syntax:** Use an online YAML validator
2. **Path Accuracy:** Verify paths exist in your repo
3. **External URLs:** Check library URLs are accessible

### CurseForge/WoWInterface Testing
1. Create a test release
2. Download the packaged addon
3. Verify excluded files aren't present
4. Verify included files are complete
5. Test addon functionality

---

## Common Pitfalls

### ❌ Wrong: Excluding Core Files
```yaml
ignore:
  - core  # DON'T DO THIS - users need core files!
```

### ✅ Correct: Excluding Dev Files
```yaml
ignore:
  - debug        # Test tools - not needed by users
  - Documentation # Dev docs - not needed by users
```

### ❌ Wrong: Missing Quotes on Wildcards
```yaml
ignore:
  - *.log  # This won't work!
```

### ✅ Correct: Quoted Wildcards
```yaml
ignore:
  - "*.log"  # Proper YAML syntax
```

---

## Integration with GitHub Actions

If you use GitHub Actions for automated releases, `.pkgmeta` works seamlessly:

```yaml
# .github/workflows/release.yml (example)
name: Package and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Package for CurseForge
        uses: BigWigsMods/packager@v2
        with:
          args: -p NextKey
        env:
          CF_API_KEY: ${{ secrets.CF_API_KEY }}
```

The packager will automatically read `.pkgmeta` and create the correct package.

---

## Resources

- [CurseForge Packaging Documentation](https://authors.curseforge.com/knowledge-base/projects/529-tools)
- [WoWAce Packager](https://github.com/BigWigsMods/packager)
- [WoWInterface Packaging](https://www.wowinterface.com/forums/forumdisplay.php?f=17)

---

## Quick Start Checklist

- [ ] Create `.pkgmeta` in addon root
- [ ] Add development directories to `ignore:` section
- [ ] Decide on `Libs/` strategy (keep in repo vs externals)
- [ ] Update `.gitignore` to be minimal
- [ ] Test packaging locally if possible
- [ ] Create test release on CurseForge/WoWInterface
- [ ] Verify release package contents
- [ ] Document any project-specific exclusions

---

**Last Updated:** 2025-11-09  
**NextKey Version:** 0.2.2