# NextKey Testing Philosophy (Simplified)

## Overview

NextKey is a simple addon focused on core functionality. Testing should be straightforward and practical, not overly complex or burdensome.

## Guiding Principles

1.  **Simplicity First**: Keep testing basic and focused on core functionality
2.  **Functionality Over Form**: Ensure features work correctly rather than perfect visual validation
3.  **Essential Debugging**: Use debug system for error reporting and basic diagnostics only
4.  **User Experience Focus**: Test from the perspective of what users actually need

## Basic Testing Approach

### Core Functionality Testing
-   Test keystone detection and display
-   Verify communication between addon users
-   Validate group suggestion logic
-   Check PUG Helper workflow (if enabled)

### Simple Validation Methods
1.  **In-Game Testing**: Use the addon as a normal user would
2.  **Basic Debug Output**: Use debug system for troubleshooting only
3.  **Error Reporting**: Focus on catching and reporting errors effectively
4.  **Manual Verification**: Check that features work as expected

## Debug System Usage

### Required Usage
-   Use `Debug:Error()` for critical errors that must be visible
-   Use `Debug:User()` for important user-facing messages
-   Use `Debug:Dev()` for development troubleshooting with categories

### Avoid
-   Complex visual testing frameworks
-   Automated test suites with pass/fail outputs
-   Overly detailed validation checklists
-   Time-consuming visual confirmation procedures

## Documentation

### Keep It Simple
-   Document core features and how they work
-   Provide basic setup instructions
-   Include troubleshooting for common issues
-   Focus on what users need to know

---

**Status**: ✅ SIMPLIFIED
**Focus**: Core functionality and basic reliability
**Testing**: Practical and user-focused