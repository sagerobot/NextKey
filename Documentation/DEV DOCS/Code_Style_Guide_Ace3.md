# Code Style Guide for Ace3 Development
**Version:** 1.0  
**Status:** Complete  
**Created:** 2025-10-16  
**Phase:** Phase 6 - Ace3 Best Practices Documentation

---

## Overview

This guide establishes coding standards and best practices for developing UI components with Ace3 in NextKey. Following these guidelines ensures code consistency, maintainability, and collaboration efficiency across the development team.

---

## 1. General Principles

### 1.1 Code Quality Standards

1. **Readability First**: Code should be self-documenting and easy to understand
2. **Consistency**: Follow established patterns throughout the codebase
3. **Simplicity**: Prefer simple solutions over complex ones
4. **Maintainability**: Write code that's easy to modify and extend
5. **Performance**: Consider performance implications without premature optimization

### 1.2 Ace3 Integration Philosophy

1. **Pure Ace3**: Use AceGUI widgets whenever possible
2. **Configuration Wrappers**: Always use NextKey configuration wrappers for styling
3. **Component Factory**: Prefer factory functions over direct widget creation
4. **Error Handling**: Implement robust error handling for all UI operations
5. **Debug Integration**: Use NextKey debug system for all logging

---

## 2. File Organization

### 2.1 File Structure

```
ui/
├── components.lua          # Component factory system
├── main.lua               # Main UI window
├── teleport.lua           # Teleport window
├── lootWindow.lua         # Loot tracking interface
├── dungeonCards.lua       # Dungeon card display
├── pugInviteNotification.lua  # PUG invite notifications
├── pugGetawayUI.lua       # PUG getaway UI
└── pugApplicationTracker.lua  # PUG application tracker
```

### 2.2 File Naming Conventions

- **Lua files**: `snake_case.lua` (lowercase with underscores)
- **Module names**: `PascalCase` (uppercase first letter of each word)
- **Function names**: `snake_case()` (lowercase with underscores)
- **Variable names**: `snake_case` (lowercase with underscores)
- **Constants**: `UPPER_SNAKE_CASE` (all uppercase with underscores)

### 2.3 File Header Template

```lua
-- Module Name - Brief Description
-- Provides functionality for specific UI features
-- Following Ace3 best practices and NextKey architecture

local _, NextKey222 = ...
local AceGUI = LibStub("AceGUI-3.0")

-- MARK: Module Definition
local ModuleName = {}
NextKey222.ModuleName = ModuleName

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("ModuleName", ModuleName)

-- MARK: Public Interface
-- Public function definitions

-- MARK: Private Implementation
-- Private function definitions

-- MARK: Event Handlers
-- Event handling functions

-- MARK: Initialization
function ModuleName:Initialize()
    NextKey222.Debug:Dev("modulename", "Module initialized")
    return true
end

return ModuleName
```

---

## 3. Code Formatting

### 3.1 Indentation and Spacing

- **Indentation**: 4 spaces (no tabs)
- **Maximum line length**: 120 characters
- **Blank lines**: Use blank lines to separate logical sections
- **Spacing**: Use spaces around operators and after commas

### 3.2 Function Formatting

```lua
-- Good formatting
local function processPlayerData(playerName, profile, options)
    if not playerName or not profile then
        NextKey222.Debug:Error("processPlayerData", "Invalid parameters")
        return nil
    end
    
    local processedData = {
        name = playerName,
        class = profile.class,
        role = profile.role
    }
    
    if options and options.includeScore then
        processedData.score = profile.score or 0
    end
    
    return processedData
end

-- Bad formatting
local function processPlayerData(playerName,profile,options)
if not playerName or not profile then
NextKey222.Debug:Error("processPlayerData","Invalid parameters")
return nil
end
local processedData={name=playerName,class=profile.class,role=profile.role}
return processedData
end
```

### 3.3 Table Formatting

```lua
-- Good formatting
local buttonConfig = {
    type = "primary_action",
    text = "Save Settings",
    onClick = function()
        SaveSettings()
    end,
    tooltip = "Save current settings to profile",
    enabled = true
}

-- Bad formatting
local buttonConfig={type="primary_action",text="Save Settings",onClick=function()SaveSettings()end,tooltip="Save current settings to profile",enabled=true}
```

### 3.4 Conditional Statements

```lua
-- Good formatting
if condition then
    -- Action
elseif otherCondition then
    -- Alternative action
else
    -- Default action
end

-- Bad formatting
if condition then
-- Action
end
if otherCondition then
-- Alternative action
end
```

---

## 4. Naming Conventions

### 4.1 Variables

```lua
-- Good naming
local playerName = "PlayerName"
local playerScore = 2500
local isDebugEnabled = true
local maxKeyLevel = 20

-- Bad naming
local pn = "PlayerName"
local ps = 2500
local dbg = true
local mkl = 20
```

### 4.2 Functions

```lua
-- Good naming
local function getPlayerScore(playerName)
    return NextKey222.ProfilesService:GetPlayerScore(playerName)
end

local function updatePlayerDisplay(playerData)
    -- Update display logic
end

-- Bad naming
local function getps(pn)
    return NextKey222.ProfilesService:GetPlayerScore(pn)
end

local function upd(pd)
    -- Update display logic
end
```

### 4.3 Constants

```lua
-- Good naming
local MAX_KEY_LEVEL = 30
local DEFAULT_WINDOW_WIDTH = 600
local COMM_PREFIX = "NKEY1"
local DEBUG_CATEGORY = "ui"

-- Bad naming
local maxkl = 30
local dww = 600
local cp = "NKEY1"
local dc = "ui"
```

### 4.4 Module and Class Names

```lua
-- Good naming
local PlayerCard = {}
local DungeonDisplay = {}
local TeleportWindow = {}

-- Bad naming
local pc = {}
local dd = {}
local tw = {}
```

---

## 5. Ace3 Widget Patterns

### 5.1 Widget Creation Pattern

```lua
-- Standard widget creation pattern
local function createStyledButton(parent, buttonType, config)
    -- Create AceGUI widget
    local widget = AceGUI:Create("Button")
    
    -- Apply NextKey configuration wrapper
    NextKey222.UIComponents:ConfigureButton(widget, buttonType, config)
    
    -- Add to parent
    if parent then
        parent:AddChild(widget)
    end
    
    return widget
end

-- Usage
local saveButton = createStyledButton(container, "primary_action", {
    text = "Save",
    onClick = function()
        SaveSettings()
    end
})
```

### 5.2 Container Creation Pattern

```lua
-- Standard container creation pattern
local function createStyledContainer(parent, containerType, config)
    -- Create appropriate widget type
    local widgetType = "SimpleGroup"
    if containerType == "window" then
        widgetType = "Frame"
    elseif containerType == "scroll" then
        widgetType = "ScrollFrame"
    end
    
    -- Create AceGUI widget
    local widget = AceGUI:Create(widgetType)
    
    -- Apply NextKey configuration wrapper
    NextKey222.UIComponents:ConfigureFrame(widget, containerType, config)
    
    -- Add to parent
    if parent then
        parent:AddChild(widget)
    end
    
    return widget
end
```

### 5.3 Event Handler Pattern

```lua
-- Standard event handler pattern
local function createButtonWithTooltip(parent, text, tooltip, onClick)
    local button = createStyledButton(parent, "select", {
        text = text,
        onClick = onClick,
        onEnter = function(btn)
            GameTooltip:SetOwner(btn.frame, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip)
            GameTooltip:Show()
        end,
        onLeave = function(btn)
            GameTooltip:Hide()
        end
    })
    
    return button
end
```

---

## 6. Error Handling Patterns

### 6.1 Safe Function Execution

```lua
-- Standard safe execution pattern
local function safeExecute(func, context, ...)
    if not func or type(func) ~= "function" then
        NextKey222.Debug:Error(context, "Invalid function provided")
        return nil
    end
    
    local success, result = pcall(func, ...)
    if not success then
        NextKey222.Debug:Error(context, "Function execution failed:", result)
        return nil
    end
    
    return result
end

-- Usage
local result = safeExecute(processPlayerData, "UI:RenderPlayerCard", playerName, profile)
```

### 6.2 Input Validation

```lua
-- Standard input validation pattern
local function validatePlayerData(playerData)
    if not playerData then
        return false, "Player data is nil"
    end
    
    if not playerData.name or playerData.name == "" then
        return false, "Player name is missing"
    end
    
    if not playerData.class or playerData.class == "" then
        return false, "Player class is missing"
    end
    
    return true, "Valid player data"
end

-- Usage
local isValid, message = validatePlayerData(playerData)
if not isValid then
    NextKey222.Debug:Error("UI:CreatePlayerCard", message)
    return nil
end
```

### 6.3 Graceful Degradation

```lua
-- Standard graceful degradation pattern
local function getPlayerScore(playerName)
    -- Try primary method
    if NextKey222.ProfilesService then
        local score = NextKey222.ProfilesService:GetPlayerScore(playerName)
        if score and score > 0 then
            return score
        end
    end
    
    -- Try fallback method
    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(playerName)
        if profile and profile.mythicKeystoneProfile then
            return profile.mythicKeystoneProfile.currentScore or 0
        end
    end
    
    -- Return default value
    return 0
end
```

---

## 7. Debug and Logging Patterns

### 7.1 Debug Categories

```lua
-- Define debug categories at module level
local DEBUG_CATEGORY = "playercards"

-- Use appropriate debug levels
function CreatePlayerCard(playerData)
    NextKey222.Debug:Trace(DEBUG_CATEGORY, "Creating player card for:", playerData.name)
    
    if not playerData then
        NextKey222.Debug:Error(DEBUG_CATEGORY, "Cannot create card - player data is nil")
        return nil
    end
    
    NextKey222.Debug:Dev(DEBUG_CATEGORY, "Player class:", playerData.class, "Role:", playerData.role)
    
    -- Create card logic
    
    NextKey222.Debug:User(DEBUG_CATEGORY, "Player card created for:", playerData.name)
    return card
end
```

### 7.2 Performance Logging

```lua
-- Performance monitoring pattern
local function renderPlayerList(players)
    NextKey222.Performance:StartProfile("UI:RenderPlayerList")
    
    for _, player in ipairs(players) do
        NextKey222.Performance:StartProfile("UI:RenderPlayerCard")
        CreatePlayerCard(player)
        NextKey222.Performance:StopProfile("UI:RenderPlayerCard")
    end
    
    NextKey222.Performance:StopProfile("UI:RenderPlayerList")
end
```

---

## 8. Memory Management

### 8.1 Widget Cleanup

```lua
-- Standard cleanup pattern
local function cleanupWidget(widget)
    if not widget then return end
    
    -- Remove from parent
    if widget.parent then
        widget.parent:RemoveChild(widget)
    end
    
    -- Release AceGUI widget
    AceGUI:Release(widget)
    
    -- Clear references
    widget = nil
end

-- Cleanup multiple widgets
local function cleanupWidgets(widgets)
    for _, widget in ipairs(widgets) do
        cleanupWidget(widget)
    end
    wipe(widgets)
end
```

### 8.2 Resource Pooling

```lua
-- Widget pooling pattern
local WidgetPool = {
    buttons = {},
    labels = {},
    icons = {}
}

local function getPooledButton(widgetType)
    local pool = WidgetPool.buttons[widgetType]
    if pool and #pool > 0 then
        return table.remove(pool)
    end
    
    return AceGUI:Create("Button")
end

local function releasePooledButton(widget, widgetType)
    if not widget then return end
    
    local pool = WidgetPool.buttons[widgetType]
    if not pool then
        WidgetPool.buttons[widgetType] = {}
        pool = WidgetPool.buttons[widgetType]
    end
    
    widget:Hide()
    widget:ClearAllPoints()
    table.insert(pool, widget)
end
```

---

## 9. Configuration Patterns

### 9.1 Configuration Objects

```lua
-- Configuration object pattern
local UI_CONFIG = {
    main = {
        width = 600,
        height = 400,
        layout = "Fill",
        backdrop = "dialog"
    },
    playerCard = {
        width = 300,
        height = 80,
        layout = "Flow",
        backdrop = "tooltip"
    },
    buttons = {
        primary = {
            type = "primary_action",
            width = 120,
            height = 25
        },
        secondary = {
            type = "secondary_action",
            width = 100,
            height = 25
        }
    }
}

-- Usage
local mainWindow = createStyledContainer(nil, "window", UI_CONFIG.main)
```

### 9.2 Dynamic Configuration

```lua
-- Dynamic configuration pattern
local function getButtonConfig(buttonType, context)
    local baseConfig = UI_CONFIG.buttons[buttonType]
    if not baseConfig then
        return nil
    end
    
    local config = CopyTable(baseConfig)
    
    -- Apply context modifications
    if context.isCompact then
        config.width = config.width * 0.8
        config.height = config.height * 0.8
    end
    
    if context.isDisabled then
        config.enabled = false
    end
    
    return config
end
```

---

## 10. Event Handling Patterns

### 10.1 AceGUI Callbacks

```lua
-- Standard callback pattern
local function createInteractiveButton(parent, text, callback)
    local button = createStyledButton(parent, "select", {
        text = text,
        onClick = function(widget, ...)
            if callback then
                local success, error = pcall(callback, widget, ...)
                if not success then
                    NextKey222.Debug:Error("UI:ButtonCallback", "Callback failed:", error)
                end
            end
        end
    })
    
    return button
end
```

### 10.2 WoW Event Handling

```lua
-- WoW event handling pattern
local function createEventFrame(events, handlers)
    local frame = CreateFrame("Frame")
    
    for event, handler in pairs(events) do
        frame:RegisterEvent(event)
    end
    
    frame:SetScript("OnEvent", function(self, event, ...)
        local handler = handlers[event]
        if handler then
            local success, error = pcall(handler, ...)
            if not success then
                NextKey222.Debug:Error("UI:EventFrame", "Event handler failed:", event, error)
            end
        end
    end)
    
    return frame
end

-- Usage
local eventFrame = createEventFrame({
    GROUP_ROSTER_UPDATE = function()
        RefreshPlayerList()
    end,
    PLAYER_SPECIALIZATION_CHANGED = function(self, unit)
        if unit == "player" then
            RefreshPlayerData()
        end
    end
})
```

---

## 11. Testing Patterns

### 11.1 Unit Testing Structure

```lua
-- Unit testing pattern
local function runWidgetTests()
    NextKey222.Debug:User("test", "Running widget tests")
    
    -- Test widget creation
    testWidgetCreation()
    
    -- Test configuration
    testWidgetConfiguration()
    
    -- Test cleanup
    testWidgetCleanup()
    
    NextKey222.Debug:User("test", "Widget tests completed")
end

local function testWidgetCreation()
    local testButton = createStyledButton(nil, "select", {
        text = "Test"
    })
    
    assert(testButton, "Button creation failed")
    assert(testButton:GetText() == "Test", "Button text incorrect")
    
    cleanupWidget(testButton)
end
```

### 11.2 Integration Testing

```lua
-- Integration testing pattern
local function testPlayerCardCreation()
    -- Create test data
    local testPlayer = {
        name = "TestPlayer",
        class = "WARRIOR",
        role = "TANK",
        score = 2500
    }
    
    -- Create card
    local card = CreatePlayerCard(testPlayer)
    assert(card, "Player card creation failed")
    
    -- Verify card structure
    assert(card.frame, "Card frame missing")
    assert(card.nameLabel, "Card name label missing")
    
    -- Cleanup
    cleanupWidget(card)
end
```

---

## 12. Documentation Patterns

### 12.1 Function Documentation

```lua
--- Creates a styled player card widget
-- @param playerData table Player information (name, class, role, score)
-- @param parent table Optional parent container
-- @return table|nil Player card widget or nil if creation failed
function CreatePlayerCard(playerData, parent)
    -- Implementation
end
```

### 12.2 Module Documentation

```lua
-- PlayerCards Module
-- Provides functionality for creating and managing player card widgets
-- Used in the main UI to display player information and scores
--
-- Key Features:
-- - Styled player cards with consistent appearance
-- - Interactive tooltips with detailed information
-- - Configurable display options
-- - Memory-efficient widget pooling
--
-- Dependencies:
-- - NextKey222.UIComponents (for styling)
-- - NextKey222.ProfilesService (for player data)
-- - AceGUI (for widget creation)
```

---

## 13. Performance Guidelines

### 13.1 Widget Creation Optimization

```lua
-- Optimized widget creation pattern
local function createOptimizedPlayerList(players)
    -- Pre-allocate container
    local container = createStyledContainer(nil, "scroll", {
        layout = "List",
        fullWidth = true,
        fullHeight = true
    })
    
    -- Batch widget creation
    local widgets = {}
    for _, player in ipairs(players) do
        local card = CreatePlayerCard(player)
        if card then
            table.insert(widgets, card)
        end
    end
    
    -- Batch add to container
    for _, widget in ipairs(widgets) do
        container:AddChild(widget)
    end
    
    -- Single layout pass
    container:DoLayout()
    
    return container
end
```

### 13.2 Memory Usage Optimization

```lua
-- Memory-efficient pattern
local function updatePlayerList(players)
    -- Reuse existing container
    if not playerListContainer then
        playerListContainer = createStyledContainer(nil, "scroll", {
            layout = "List",
            fullWidth = true,
            fullHeight = true
        })
    end
    
    -- Clear existing children efficiently
    playerListContainer:ReleaseChildren()
    
    -- Add new widgets
    for _, player in ipairs(players) do
        local card = CreatePlayerCard(player)
        if card then
            playerListContainer:AddChild(card)
        end
    end
    
    -- Update layout
    playerListContainer:DoLayout()
end
```

---

## 14. Security Considerations

### 14.1 Input Sanitization

```lua
-- Input sanitization pattern
local function sanitizePlayerName(name)
    if not name or type(name) ~= "string" then
        return "Unknown"
    end
    
    -- Remove invalid characters
    local sanitized = name:gsub("[^%w%-]", "")
    
    -- Limit length
    if #sanitized > 20 then
        sanitized = sanitized:sub(1, 20)
    end
    
    return sanitized
end
```

### 14.2 Secure Widget Usage

```lua
-- Secure widget pattern for spell casting
local function createSecureSpellButton(parent, spellID)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", spellID)
    
    -- Apply NextKey styling to secure button
    NextKey222.UIComponents:ConfigureBackdrop(button, "compact", {
        colorScheme = "standard"
    })
    
    return button
end
```

---

## 15. Code Review Checklist

### 15.1 Functionality Review

- [ ] Functions have clear, single responsibilities
- [ ] Error handling is implemented for all critical operations
- [ ] Input validation is performed where necessary
- [ ] Widget cleanup is properly implemented
- [ ] Memory leaks are avoided

### 15.2 Style Review

- [ ] Naming conventions are followed consistently
- [ ] Code formatting follows established standards
- [ ] Comments are appropriate and helpful
- [ ] Magic numbers are replaced with named constants
- [ ] Complex logic is explained with comments

### 15.3 Performance Review

- [ ] Widget creation is optimized
- [ ] Memory usage is efficient
- [ ] Unnecessary widget recreation is avoided
- [ ] Performance monitoring is implemented where needed
- [ ] Resource pooling is used for frequently created widgets

### 15.4 Security Review

- [ ] User input is properly sanitized
- [ ] Secure widgets are used for sensitive operations
- [ ] Privilege checks are implemented where necessary
- [ ] Error messages don't expose sensitive information

---

## 16. Common Anti-Patterns

### 16.1 Widget Management Anti-Patterns

```lua
-- ANTI-PATTERN: Creating widgets without cleanup
function createBadWidget()
    local widget = AceGUI:Create("Button")
    widget:SetText("Bad Widget")
    return widget  -- Widget will leak memory
end

-- PATTERN: Proper widget creation with cleanup
function createGoodWidget()
    local widget = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(widget, "select", {
        text = "Good Widget"
    })
    return widget  -- Caller must clean up
end
```

### 16.2 Configuration Anti-Patterns

```lua
-- ANTI-PATTERN: Hardcoded styling
local function createBadButton()
    local button = AceGUI:Create("Button")
    button:SetWidth(100)
    button:SetHeight(25)
    button:SetText("Bad Button")
    -- Manual styling that should use configuration wrapper
    return button
end

-- PATTERN: Using configuration wrappers
local function createGoodButton()
    local button = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(button, "select", {
        text = "Good Button"
    })
    return button
end
```

### 16.3 Error Handling Anti-Patterns

```lua
-- ANTI-PATTERN: Ignoring errors
local function badFunction(data)
    local result = process(data)  -- Might fail, but we ignore it
    return result
end

-- PATTERN: Proper error handling
local function goodFunction(data)
    local success, result = pcall(process, data)
    if not success then
        NextKey222.Debug:Error("goodFunction", "Processing failed:", result)
        return nil
    end
    return result
end
```

---

## 17. Migration Guidelines

### 17.1 From Native Frames to AceGUI

```lua
-- BEFORE: Native frame creation
local function createOldButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(100, 25)
    button:SetText("Old Button")
    button:SetScript("OnClick", function()
        print("Clicked!")
    end)
    return button
end

-- AFTER: AceGUI with configuration wrapper
local function createNewButton(parent)
    local button = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(button, "select", {
        text = "New Button",
        onClick = function()
            print("Clicked!")
        end
    })
    parent:AddChild(button)
    return button
end
```

### 17.2 From Manual Styling to Components

```lua
-- BEFORE: Manual styling
local function createOldPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(200, 150)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    panel:SetBackdropColor(0, 0, 0, 0.8)
    panel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    return panel
end

-- AFTER: Component system
local function createNewPanel(parent)
    local panel = AceGUI:Create("SimpleGroup")
    NextKey222.UIComponents:ConfigureFrame(panel, "panel", {
        width = 200,
        height = 150
    })
    parent:AddChild(panel)
    return panel
end
```

---

## 18. Best Practices Summary

### 18.1 DO's ✅

1. **Always use AceGUI widgets** for UI elements
2. **Always apply configuration wrappers** for consistent styling
3. **Always implement error handling** with proper logging
4. **Always clean up widgets** when they're no longer needed
5. **Always use meaningful debug categories** for logging
6. **Always validate inputs** before processing
7. **Always follow naming conventions** consistently
8. **Always document public functions** with proper comments
9. **Always use SafeRun** for critical operations
10. **Always test widget functionality** before committing

### 18.2 DON'Ts ❌

1. **Don't mix native frames** with AceGUI without good reason
2. **Don't hardcode styling** - use configuration wrappers
3. **Don't ignore error handling** - always handle potential failures
4. **Don't create memory leaks** - clean up widgets properly
5. **Don't use print()** - use NextKey debug system
6. **Don't skip input validation** - always validate user input
7. **Don't use inconsistent naming** - follow established conventions
8. **Don't commit undocumented code** - document public interfaces
9. **Don't skip SafeRun** for critical operations
10. **Don't skip testing** - test all functionality

---

## 19. Quick Reference

### 19.1 Widget Creation Template

```lua
-- Standard widget creation template
local function createWidget(parent, widgetType, configType, config)
    local widget = AceGUI:Create(widgetType)
    NextKey222.UIComponents["Configure" .. configType](widget, configType, config)
    if parent then
        parent:AddChild(widget)
    end
    return widget
end
```

### 19.2 Error Handling Template

```lua
-- Standard error handling template
local function safeOperation(operation, context, ...)
    return NextKey222.SafeRun(function()
        return operation(...)
    end, context)
end
```

### 19.3 Debug Template

```lua
-- Standard debug template
local function debugLog(level, category, message, ...)
    NextKey222.Debug[level](category, message, ...)
end
```

---

## 20. Conclusion

Following this code style guide ensures that NextKey's UI code remains consistent, maintainable, and of high quality. The guidelines establish clear patterns for working with Ace3 while maintaining NextKey's visual identity and architectural principles.

Regular code reviews and adherence to these standards will help maintain code quality as the project evolves and new features are added.

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-16  
**Next Review**: 2025-11-16  
**Related Documents**: 
- [Ace3 Widget Selection Guidelines](Ace3_Widget_Selection_Guidelines.md)
- [Configuration Wrapper Usage Guide](Configuration_Wrapper_Usage_Guide.md)
- [Migration Guide for Future UI Components](Migration_Guide_UI_Components.md)