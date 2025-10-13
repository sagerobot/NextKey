# NextKey Documentation Index

## 🚨 **MANDATORY DEBUG SYSTEM - ALL DEVELOPERS**

- **[DEBUG_SYSTEM.md](DEBUG_SYSTEM.md)** - **🔥 CRITICAL - READ FIRST**
  - **MANDATORY debug system usage for ALL code**
  - **NO EXCEPTIONS - NO print() calls - NO custom debug functions**
  - Complete API reference and examples
  - Code review checklist and enforcement policies
  - Performance guidelines and best practices

- **[DEBUG_SYSTEM_USER_GUIDE.md](DEBUG_SYSTEM_USER_GUIDE.md)** - **📖 USER DOCUMENTATION**
  - Complete user interface guide
  - Features and capabilities overview
  - Performance monitoring and filtering
  - Best practices and troubleshooting

---

## 🎯 **Primary Developer Reference**

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - **⭐ MAIN REFERENCE FOR ALL DEVELOPERS**
  - Complete architectural standards and coding patterns
  - NextKey222 module registration requirements
  - Error handling and performance monitoring
  - Code templates and validation rules
  - Current project status and implementation phases

---

## 📋 **Feature & Design Documentation**

- **[DESIGN.md](DESIGN.md)** - **📋 DESIGN SPECIFICATIONS**
  - User experience design and feature intent
  - Technical specifications and data structures
  - UI/UX design principles
  - Integration points and dependencies
  - Project roadmap and success metrics

- **[FAKE_PLAYERS.md](FAKE_PLAYERS.md)** - **🧪 TESTING SYSTEM**
  - Complete fake player system documentation
  - API reference and usage examples
  - Integration with existing systems
  - Preset configurations and skill tiers
  - Testing patterns and troubleshooting

- **[PUG_MODE.md](PUG_MODE.md)** - **🚀 PUG MODE IMPLEMENTATION**
  - Complete PUG Helper system documentation
  - Automatic LFG workflow assistance
  - State machine and event handling
  - UI components and user experience
  - Configuration and troubleshooting

---

## 🔧 **Technical Documentation**

- **[API_REFERENCE.md](API_REFERENCE.md)** - **📚 API DOCUMENTATION**
  - Complete API reference for all modules
  - Function signatures and parameters
  - Return values and error handling
  - Usage examples and best practices

- **[ACE3_FRAMEWORK.md](ACE3_FRAMEWORK.md)** - **🔧 FRAMEWORK REFERENCE**
  - Ace3 library usage patterns
  - Common configurations and examples
  - Integration guidelines
  - Performance considerations

---

## 🗂️ **Project Management**

- **[../PLAN.md](../PLAN.md)** - **📋 CURRENT CLEANUP PLAN**
  - Active cleanup phases and tasks
  - Implementation status and next steps
  - Technical debt tracking
  - Quality improvement initiatives

- **[../CHANGELOG.md](../CHANGELOG.md)** - **📝 VERSION HISTORY**
  - Version history and release notes
  - Feature changes and improvements
  - Bug fixes and security updates
  - Migration guides for major versions

---

## 📖 **User Documentation**

- **[USER_GUIDE.md](USER_GUIDE.md)** - **👥 END-USER GUIDE**
  - Getting started with NextKey
  - Feature walkthroughs and tutorials
  - Configuration and customization
  - Troubleshooting common issues

---

## 🚨 **CRITICAL REQUIREMENTS - ALL DEVELOPERS**

### 🔥 **DEBUG SYSTEM IS MANDATORY**
- **ALL debugging MUST use the official debug system**
- **NO direct print() calls - EVER**
- **NO custom debug functions - EVER**
- **ALL DEV/TRACE calls MUST have categories**
- **UI controls ONLY for debug configuration**

### 📋 **CODE REVIEW REQUIREMENTS**
- Code WILL be rejected for debug system violations
- Use the checklist in `DEBUG_SYSTEM.md`
- Test with `/script NextKeyRunTests()`
- Access debug UI: `/nk config` → Debug System

### ⚡ **QUICK START**
```lua
-- ✅ CORRECT
Debug:Error("Critical error message")
Debug:User("User-facing message")
Debug:Dev("category_name", "Development message")
Debug:Trace("category_name", "Verbose trace message")

-- ❌ FORBIDDEN
print("Debug message")  -- NEVER use this
```

---

## 📚 **Documentation Structure**

```
Documentation/
├── README.md                 # This file - Main index and navigation
├── DEVELOPMENT.md            # Technical implementation guide
├── DESIGN.md                 # Design specifications and UX
├── DEBUG_SYSTEM.md           # Complete debug system documentation
├── DEBUG_SYSTEM_USER_GUIDE.md # End-user debug guide
├── FAKE_PLAYERS.md           # Fake player testing system
├── PUG_MODE.md               # PUG Mode implementation guide
├── API_REFERENCE.md          # Complete API documentation
├── ACE3_FRAMEWORK.md         # Ace3 library reference
├── USER_GUIDE.md             # End-user documentation
└── CHANGELOG.md              # Version history
```

---

## 🎯 **Getting Started**

### For New Developers

1. **Read DEBUG_SYSTEM.md first** - This is mandatory
2. **Review DEVELOPMENT.md** for architectural patterns
3. **Check DESIGN.md** for feature context
4. **Examine FAKE_PLAYERS.md** for testing tools
5. **Run the test suite**: `/script NextKeyRunTests()`

### For Contributors

1. **All code must follow patterns in DEVELOPMENT.md**
2. **Debug system usage is non-negotiable**
3. **Include tests for new features**
4. **Update documentation for API changes**
5. **Follow the code review checklist**

### For Users

1. **Read USER_GUIDE.md** for basic usage
2. **Check DEBUG_SYSTEM_USER_GUIDE.md** for troubleshooting
3. **Report issues with reproduction steps**
4. **Include debug output when reporting bugs**

---

## 🚨 **Critical for AI Agents & All Developers**

**ALL code must follow the standards in `DEBUG_SYSTEM.md`. Debug system usage is MANDATORY with NO EXCEPTIONS.**

### 📋 **Code Review Checklist (MANDATORY)**

#### Debug System Compliance
- [ ] **NO direct print() calls anywhere in code**
- [ ] **NO custom debug functions**
- [ ] **ALL DEV/TRACE calls have proper categories**
- [ ] **Appropriate debug levels used**
- [ ] **No manual debug state checking**
- [ ] **No hardcoded debug behavior**
- [ ] **UI controls used for all debug configuration**

#### Architecture Compliance
- [ ] Module registered with `NextKey222.RegisterModule()`
- [ ] All critical operations wrapped in `NextKey222.SafeRun()`
- [ ] Performance-critical paths use profiling
- [ ] Code exists within NextKey222 namespace
- [ ] Proper input validation for all public functions

---

## 🔗 **Quick Links**

### Essential Commands
```lua
/nk config                    -- Open options panel
/nk debug                     -- Toggle debug mode
/script NextKeyRunTests()      -- Run test suite
```

### Debug System Access
```
/nk config → Debug System tab
```

### Testing Commands
```lua
/nk test                      -- Generate fake players
/nk test preset mixed_skill    -- Generate preset team
/nk test clear                 -- Clear fake players

-- PUG Helper Testing
/nk pug test                  -- Test PUG Helper application tracking
/nk pug simulate invite       -- Simulate receiving group invite
/nk pug simulate join         -- Simulate joining group
/nk pug simulate complete     -- Simulate dungeon completion
/nk pug status                -- Show PUG Helper status
```

---

## 📞 **Getting Help**

### Debug System Issues
1. Check `DEBUG_SYSTEM.md` for standards
2. Check `DEBUG_SYSTEM_USER_GUIDE.md` for UI help
3. Run tests: `/script NextKeyRunTests()`
4. Ask in development channels

### Feature Questions
1. Check `DESIGN.md` for design intent
2. Check `DEVELOPMENT.md` for implementation details
3. Check `API_REFERENCE.md` for function documentation
4. Review code examples in relevant files

### Bug Reports
1. Enable debug: `/nk config → Debug System`
2. Reproduce the issue
3. Export debug output
4. Report with steps and debug information

---

## 📈 **Documentation Quality**

This documentation follows these principles:

- **Single Source of Truth**: Each topic has one authoritative document
- **Cross-Referenced**: Related topics linked throughout
- **Example-Driven**: Code examples for all important concepts
- **Maintained**: Updated with each feature change
- **Searchable**: Clear structure and comprehensive indexing

---

## 🔄 **Documentation Maintenance**

### Updating Documentation
1. **API Changes**: Update `API_REFERENCE.md`
2. **New Features**: Update `DESIGN.md` and `DEVELOPMENT.md`
3. **Debug Changes**: Update `DEBUG_SYSTEM.md`
4. **UI Changes**: Update `DEBUG_SYSTEM_USER_GUIDE.md` and `USER_GUIDE.md`

### Review Schedule
- **Weekly**: Check for outdated references
- **Monthly**: Comprehensive review of all documents
- **Per Release**: Update changelog and version information
- **As Needed**: Update for bug fixes and emergency changes

---

**Remember**: Good documentation is as important as good code. Keep it accurate, keep it current, and keep it useful.

---

**Last Updated**: October 13, 2025  
**Version**: Consolidated Documentation v1.0