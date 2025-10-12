# NextKey Documentation Index

## 🚨 **MANDATORY DEBUG SYSTEM - ALL DEVELOPERS**
- **[DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md](DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md)** - **🔥 CRITICAL - READ FIRST**
  - **MANDATORY debug system usage for ALL code**
  - **NO EXCEPTIONS - NO print() calls - NO custom debug functions**
  - Complete API reference and examples
  - Code review checklist and enforcement policies
  - Performance guidelines and best practices

- **[DEBUG_SYSTEM_QUICK_REFERENCE.md](DEBUG_SYSTEM_QUICK_REFERENCE.md)** - **⚡ QUICK START**
  - Essential debug calls and patterns
  - Available categories and usage
  - Common scenarios and examples
  - Troubleshooting and testing

- **[DEBUG_SYSTEM_USER_GUIDE.md](DEBUG_SYSTEM_USER_GUIDE.md)** - **📖 USER DOCUMENTATION**
  - Complete user interface guide
  - Features and capabilities overview
  - Performance monitoring and filtering
  - Best practices and troubleshooting

## 🎯 **Primary Developer Reference**
- **[AI_DEVELOPMENT_GUIDE.md](../AI_DEVELOPMENT_GUIDE.md)** - **⭐ MAIN REFERENCE FOR ALL DEVELOPERS**
  - Complete architectural standards and coding patterns
  - NextKey222 module registration requirements
  - Error handling and performance monitoring
  - Code templates and validation rules
  - Current project status and implementation phases

## 📋 **Debug System Technical Documentation**
- **[DEBUG_SYSTEM_IMPLEMENTATION_SUMMARY.md](DEBUG_SYSTEM_IMPLEMENTATION_SUMMARY.md)** - **📊 IMPLEMENTATION DETAILS**
  - Complete technical implementation summary
  - Architecture and performance characteristics
  - Quality assurance and testing results
  - Future enhancement possibilities

- **[DEBUG_SYSTEM_DESIGN.md](DEBUG_SYSTEM_DESIGN.md)** - **🏗️ DESIGN SPECIFICATIONS**
  - System architecture and design decisions
  - Technical requirements and constraints
  - Integration points and dependencies

- **[DEBUG_CATEGORY_MAPPING.md](DEBUG_CATEGORY_MAPPING.md)** - **📂 CATEGORY REFERENCE**
  - Complete category mapping and usage guidelines
  - Group organization and best practices
  - When to use each category

## 📋 **Feature & Design Documentation**
- **[NextKey - Design Intent.md](NextKey%20-%20Design%20Intent.md)** - User experience design and feature intent
- **[NextKey - Addon Design Document.md](NextKey%20-%20Addon%20Design%20Document.md)** - Detailed feature specifications
- **[NextKey - Roadmap.md](NextKey%20-%20Roadmap.md)** - Original project milestones and delivery plan

## 🔧 **Ace3 Framework Documentation**
- **[Getting Started.md](Getting%20Started.md)** - Ace3 framework primer
- **[AceAddon-3.0.md](AceAddon-3.0.md)** - Core addon structure
- **[AceComm-3.0.md](AceComm-3.0.md)** - Inter-addon communication
- **[AceDB-3.0.md](AceDB-3.0.md)** - SavedVariables management
- **[AceConfig-3.0.md](AceConfig-3.0.md)** - Configuration UI
- **[AceGUI-3.0.md](AceGUI-3.0.md)** - GUI widgets

## 🗂️ **Project Management**
- **[../PLAN.md](../PLAN.md)** - Current cleanup phases and tasks
- **[../CHANGELOG.md](../CHANGELOG.md)** - Version history

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
- Use the checklist in `DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md`
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

## 🚨 **Critical for AI Agents & All Developers**
**ALL code must follow the standards in `DEBUG_SYSTEM_DEVELOPER_GUIDELINES.md`. Debug system usage is MANDATORY with NO EXCEPTIONS.**