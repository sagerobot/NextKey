# Release Packaging Summary - NextKey

## Quick Answer

**Yes, you can have files in your GitHub repo that don't appear in release builds!**

Use two different files to control this:

| File | Controls | Use For |
|------|----------|---------|
| **`.gitignore`** | What's excluded from GitHub | Runtime logs, temp files, personal settings |
| **`.pkgmeta`** | What's excluded from releases | Documentation, debug tools, dev environment |

## Recommended Strategy for NextKey

### 1. Keep .gitignore Minimal

Your current `.gitignore` is good! Only exclude files that shouldn't be in version control:

```gitignore
# WoW Addon Development - NextKey .gitignore

# Logs directory
Logs/
*.log

# VSCode settings (uncomment if you don't want to share)
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

### 2. Create .pkgmeta for Release Control

Create a new file named `.pkgmeta` in your addon root directory with this content:

```yaml
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

# Keep Libs/ in both repo and releases (current setup)
# Users need these dependencies

enable-nolib-creation: no
```

**Note:** The `externals:` section is optional. Since you already have `Libs/` in your repo, you don't need it. If you wanted CurseForge to fetch libraries automatically, see the full guide.

## What This Achieves

| Directory/File | GitHub Repo | User Download | Why |
|----------------|-------------|---------------|-----|
| `core/`, `ui/`, `data/` | ✅ | ✅ | Core addon - users need this |
| `Libs/` | ✅ | ✅ | Dependencies - users need this |
| `Documentation/` | ✅ | ❌ | Dev docs - contributors need, users don't |
| `debug/` | ✅ | ❌ | Test tools - developers need, users don't |
| `.kilocode/` | ✅ | ❌ | AI dev environment - your workflow only |
| `.vscode/` | ✅ | ❌ | Editor settings - personal preference |
| `.github/` | ✅ | ❌ | CI/CD - automation only |
| `Logs/` | ❌ | ❌ | Runtime logs - never commit |

## Benefits

### For Your AI Development
- Full context preserved in GitHub repo
- Memory Bank (`.kilocode/`) always available
- Documentation accessible for planning
- Debug tools ready for testing

### For Users
- Clean, minimal addon download
- ~70% smaller package size
- No unnecessary files
- Professional release quality

### For Contributors
- Complete project history
- All architectural decisions documented
- Test utilities available
- Easy to understand project structure

## Implementation Steps

1. **Keep your current `.gitignore`** (it's already good)
2. **Create `.pkgmeta`** in your addon root (copy the YAML above)
3. **Test locally** - commit and push to GitHub (everything stays in repo)
4. **When you publish to CurseForge/WoWInterface:**
   - Their packaging tools will read `.pkgmeta`
   - They'll automatically exclude the specified files
   - Users download the clean version

## Verification

After creating a release on CurseForge/WoWInterface:

1. Download the packaged addon
2. Verify `Documentation/` is NOT present
3. Verify `debug/` is NOT present
4. Verify `.kilocode/` is NOT present
5. Verify `core/`, `ui/`, `Libs/` ARE present
6. Test addon functionality

## See Also

- **[PKGMETA_GUIDE.md](PKGMETA_GUIDE.md)** - Complete `.pkgmeta` documentation with examples
- **[CurseForge Documentation](https://authors.curseforge.com/knowledge-base/projects/529-tools)** - Official packaging reference

## Quick Reference: File Patterns

### .gitignore Syntax
```gitignore
Logs/              # Exclude directory
*.log              # Exclude pattern (no quotes)
.vscode/           # Exclude directory
```

### .pkgmeta Syntax
```yaml
ignore:
  - Documentation  # Exclude directory (no trailing slash)
  - "*.log"        # Exclude pattern (use quotes!)
  - .kilocode      # Exclude directory
```

---

**Last Updated:** 2025-11-09
**NextKey Version:** 0.5.32