# Configuration Wrapper Usage Guide
**Version:** 1.0  
**Status:** Complete  
**Created:** 2025-10-16  
**Phase:** Phase 6 - Ace3 Best Practices Documentation

---

## Overview

This guide provides comprehensive documentation for using the NextKey configuration wrapper system. The configuration wrappers are the bridge between AceGUI widgets and the NextKey visual design system, ensuring consistent styling, behavior, and user experience across all UI components.

---

## 1. Configuration Wrapper Architecture

### 1.1 Core Design Principles

The configuration wrapper system follows these principles:

1. **Separation of Concerns**: Widget creation (AceGUI) is separate from styling (NextKey components)
2. **Consistency**: All widgets use the same styling system
3. **Flexibility**: Configuration overrides allow customization when needed
4. **Maintainability**: Centralized styling reduces code duplication
5. **Performance**: Optimized configuration application

### 1.2 Wrapper System Structure

```
NextKey222.UIComponents
├─ ConfigureBackdrop(widget, type, config)
├─ ConfigureButton(widget, type, config)
├─ ConfigureText(widget, type, config)
├─ ConfigureFrame(widget, type, config)
├─ ConfigureIcon(widget, type, config)
├─ ConfigureDropdown(widget, type, config)
└─ ConfigureScrollFrame(widget, type, config)
```

---

## 2. Backdrop Configuration Wrapper

### 2.1 Method Signature

```lua
Components:ConfigureBackdrop(widget, backdropType, config)
```

**Parameters:**
- `widget`: The AceGUI widget or frame to apply backdrop to
- `backdropType`: String identifier for backdrop style
- `config`: Optional configuration table for overrides

### 2.2 Available Backdrop Types

| Type | Use Case | Visual Style |
|------|----------|--------------|
| `tooltip` | General UI elements, tooltips | Light border, semi-transparent |
| `dialog` | Modal dialogs, important windows | Heavy border, dark background |
| `dark_dialog` | Settings windows, configuration | Dark background, standard border |
| `compact` | List items, small elements | Minimal border, lightweight |

### 2.3 Configuration Options

```lua
local config = {
    colorScheme = "standard",  -- "dark", "standard", "light", "transparent"
    customBgColor = {r, g, b, a},  -- Override background color
    customBorderColor = {r, g, b, a}  -- Override border color
}
```

### 2.4 Usage Examples

#### **Basic Usage**
```lua
-- Apply standard tooltip backdrop
local container = AceGUI:Create("SimpleGroup")
NextKey222.UIComponents:ConfigureBackdrop(container, "tooltip")
```

#### **With Color Scheme**
```lua
-- Apply dark dialog backdrop
local settingsWindow = AceGUI:Create("Frame")
NextKey222.UIComponents:ConfigureBackdrop(settingsWindow, "dialog", {
    colorScheme = "dark"
})
```

#### **Custom Colors**
```lua
-- Apply custom colors for special cases
local warningPanel = AceGUI:Create("SimpleGroup")
NextKey222.UIComponents:ConfigureBackdrop(warningPanel, "tooltip", {
    customBgColor = {0.2, 0, 0, 0.8},  -- Dark red background
    customBorderColor = {1, 0.2, 0.2, 1}  -- Light red border
})
```

---

## 3. Button Configuration Wrapper

### 3.1 Method Signature

```lua
Components:ConfigureButton(widget, buttonType, config)
```

**Parameters:**
- `widget`: The AceGUI button widget to configure
- `buttonType`: String identifier for button style
- `config`: Optional configuration table for overrides

### 3.2 Available Button Types

| Type | Use Case | Default Size | Style |
|------|----------|--------------|-------|
| `primary_action` | Main actions (Save, Apply) | 120x25 | Prominent styling |
| `secondary_action` | Secondary actions (Cancel, Reset) | 100x25 | Subtle styling |
| `compact_list` | List items with limited space | 80x22 | Minimal styling |
| `select` | Selection actions (Choose, Select) | 100x25 | Standard styling |
| `select_compact` | Compact selection buttons | 80x22 | Small styling |
| `icon` | Icon-only buttons | 32x32 | No text, icon only |
| `secure` | Spell/item casting actions | 100x25 | Secure styling |
| `toggle` | State toggle buttons | 100x25 | Toggle styling |
| `small` | Small utility buttons | 70x20 | Minimal styling |
| `large` | Prominent action buttons | 150x30 | Large styling |

### 3.3 Configuration Options

```lua
local config = {
    text = "Button Text",           -- Override default text
    size = {width, height},         -- Override default size
    onClick = function() end,       -- Click handler
    onEnter = function(btn) end,    -- Hover enter handler
    onLeave = function(btn) end,    -- Hover leave handler
    enabled = true,                 -- Enable/disable state
    colorScheme = "standard"        -- Color scheme override
}
```

### 3.4 Usage Examples

#### **Primary Action Button**
```lua
local saveButton = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(saveButton, "primary_action", {
    text = "Save Settings",
    onClick = function()
        -- Save logic here
        NextKey222.Debug:User("Settings saved successfully")
    end,
    onEnter = function(btn)
        GameTooltip:SetOwner(btn.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText("Save current settings to profile")
        GameTooltip:Show()
    end,
    onLeave = function(btn)
        GameTooltip:Hide()
    end
})
```

#### **Compact List Button**
```lua
local deleteButton = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(deleteButton, "compact_list", {
    text = "Delete",
    onClick = function()
        -- Delete logic here
    end,
    enabled = false  -- Disabled by default
})
```

#### **Icon Button with Hover Effects**
```lua
local helpButton = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(helpButton, "icon", {
    size = {24, 24},
    onClick = function()
        -- Show help dialog
    end,
    onEnter = function(btn)
        GameTooltip:SetOwner(btn.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show help documentation")
        GameTooltip:Show()
    end,
    onLeave = function(btn)
        GameTooltip:Hide()
    end
})
```

---

## 4. Text Configuration Wrapper

### 4.1 Method Signature

```lua
Components:ConfigureText(widget, textType, config)
```

**Parameters:**
- `widget`: The AceGUI label widget to configure
- `textType`: String identifier for text style
- `config`: Optional configuration table for overrides

### 4.2 Available Text Types

| Type | Use Case | Font Object | Default Color |
|------|----------|-------------|---------------|
| `header` | Window titles, section headers | GameFontNormalLarge | White |
| `body` | Standard content text | GameFontNormal | White |
| `label` | Field labels, descriptions | GameFontNormalSmall | Light gray |
| `tooltip` | Tooltip text | GameTooltipText | White |
| `score` | Numeric scores with coloring | GameFontNormal | Green |
| `small` | Small supplementary text | GameFontNormalSmall | Gray |
| `large` | Large display text | GameFontNormalLarge | White |

### 4.3 Configuration Options

```lua
local config = {
    text = "Display text",         -- Text content
    fontObject = GameFontNormal,   -- Font object override
    color = {r, g, b},            -- Color override
    justifyH = "LEFT",             -- Horizontal justification
    width = number,                -- Fixed width
    height = number                -- Fixed height
}
```

### 4.4 Usage Examples

#### **Dynamic Score Display**
```lua
local scoreLabel = AceGUI:Create("Label")
NextKey222.UIComponents:ConfigureText(scoreLabel, "score", {
    text = "0",
    justifyH = "RIGHT",
    width = 100
})

-- Update function
function UpdateScore(newScore)
    local color = GetScoreColor(newScore)  -- Custom color function
    scoreLabel:SetColor(color[1], color[2], color[3])
    scoreLabel:SetText(string.format("%.0f", newScore))
end
```

#### **Multiline Description**
```lua
local descriptionLabel = AceGUI:Create("Label")
NextKey222.UIComponents:ConfigureText(descriptionLabel, "body", {
    text = "This is a long description that will wrap automatically when the text exceeds the specified width.",
    width = 300,
    justifyH = "LEFT"
})
```

#### **Colored Status Text**
```lua
local statusLabel = AceGUI:Create("Label")
NextKey222.UIComponents:ConfigureText(statusLabel, "label", {
    text = "Connected",
    color = {0, 1, 0},  -- Green for success
    justifyH = "CENTER"
})

function UpdateStatus(status, isError)
    local color = isError and {1, 0, 0} or {0, 1, 0}  -- Red for error, green for success
    statusLabel:SetColor(color[1], color[2], color[3])
    statusLabel:SetText(status)
end
```

---

## 5. Frame Configuration Wrapper

### 5.1 Method Signature

```lua
Components:ConfigureFrame(widget, frameType, config)
```

**Parameters:**
- `widget`: The AceGUI container widget to configure
- `frameType`: String identifier for frame style
- `config`: Optional configuration table for overrides

### 5.2 Available Frame Types

| Type | Use Case | Recommended Widget | Default Layout |
|------|----------|-------------------|----------------|
| `window` | Top-level windows | Frame | Flow |
| `panel` | Content sections | SimpleGroup/InlineGroup | List |
| `container` | Generic grouping | SimpleGroup | Flow |
| `scroll` | Scrollable content | ScrollFrame | List |
| `tooltip` | Temporary overlays | SimpleGroup | Flow |
| `dialog` | Modal dialogs | Frame | Fill |

### 5.3 Configuration Options

```lua
local config = {
    width = number,                 -- Fixed width
    height = number,                -- Fixed height
    layout = "Flow",                -- Layout type
    colorScheme = "standard",       -- Color scheme for backdrop
    fullWidth = true,               -- Use full parent width
    fullHeight = true               -- Use full parent height
}
```

### 5.4 Usage Examples

#### **Main Window Configuration**
```lua
local mainWindow = AceGUI:Create("Frame")
NextKey222.UIComponents:ConfigureFrame(mainWindow, "window", {
    width = 600,
    height = 400,
    layout = "Fill"
})

-- Window-specific configuration
mainWindow:SetTitle("NextKey Settings")
mainWindow:EnableResize(true)
mainWindow:SetCallback("OnClose", function(widget)
    widget:Hide()
end)
```

#### **Content Panel**
```lua
local contentPanel = AceGUI:Create("InlineGroup")
NextKey222.UIComponents:ConfigureFrame(contentPanel, "panel", {
    width = 500,
    height = 300,
    layout = "List"
})

contentPanel:SetTitle("Player Information")
```

#### **Scrollable List Container**
```lua
local scrollContainer = AceGUI:Create("ScrollFrame")
NextKey222.UIComponents:ConfigureFrame(scrollContainer, "scroll", {
    fullWidth = true,
    fullHeight = true,
    layout = "List",
    colorScheme = "light"
})
```

---

## 6. Icon Configuration Wrapper

### 6.1 Method Signature

```lua
Components:ConfigureIcon(widget, iconType, config)
```

**Parameters:**
- `widget`: The AceGUI icon widget to configure
- `iconType`: String identifier for icon style
- `config`: Optional configuration table for overrides

### 6.2 Available Icon Types

| Type | Use Case | Default Size | Default Texture |
|------|----------|--------------|-----------------|
| `class` | Class icons | 32x32 | Class icon texture |
| `role` | Role icons (tank/healer/dps) | 16x16 | LFG role texture |
| `dungeon` | Dungeon icons | 32x32 | Dungeon texture |
| `item` | Item icons | 32x32 | Item texture |
| `small` | Small icons | 16x16 | Question mark |
| `large` | Large icons | 64x64 | Question mark |

### 6.3 Configuration Options

```lua
local config = {
    imagePath = "texture/path",    -- Custom texture path
    size = {width, height},        -- Size override
    imageWidth = number,           -- Texture width
    imageHeight = number,          -- Texture height
    onClick = function() end,      -- Click handler
    onEnter = function(icon) end,  -- Hover enter handler
    onLeave = function(icon) end   -- Hover leave handler
}
```

### 6.4 Usage Examples

#### **Class Icon with Tooltip**
```lua
local classIcon = AceGUI:Create("Icon")
NextKey222.UIComponents:ConfigureIcon(classIcon, "class", {
    imagePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
    imageWidth = 32,
    imageHeight = 32,
    onClick = function()
        -- Show class details
    end,
    onEnter = function(icon)
        local classData = GetClassData(playerClass)
        GameTooltip:SetOwner(icon.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(classData.name)
        GameTooltip:AddLine(classData.description, 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end,
    onLeave = function(icon)
        GameTooltip:Hide()
    end
})
```

#### **Dynamic Item Icon**
```lua
local itemIcon = AceGUI:Create("Icon")
NextKey222.UIComponents:ConfigureIcon(itemIcon, "item", {
    size = {24, 24},
    onClick = function()
        -- Show item details
    end
})

-- Update item icon
function UpdateItemIcon(itemID)
    local texture = select(10, C_Item.GetItemInfo(itemID))
    if texture then
        itemIcon:SetImage(texture)
    else
        itemIcon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end
```

---

## 7. Dropdown Configuration Wrapper

### 7.1 Method Signature

```lua
Components:ConfigureDropdown(widget, dropdownType, config)
```

**Parameters:**
- `widget`: The AceGUI dropdown widget to configure
- `dropdownType`: String identifier for dropdown style
- `config`: Optional configuration table for overrides

### 7.2 Available Dropdown Types

| Type | Use Case | Default Size | Style |
|------|----------|--------------|-------|
| `primary` | Main selection dropdowns | 200x25 | Standard styling |
| `compact` | Space-constrained dropdowns | 150x22 | Compact styling |

### 7.3 Configuration Options

```lua
local config = {
    width = number,                -- Width override
    height = number,               -- Height override
    label = "Label Text",          -- Dropdown label
    list = {key = value},         -- Selection options
    value = "selected_key",        -- Current selection
    onValueChanged = function() end, -- Selection change handler
    colorScheme = "standard"       -- Color scheme for backdrop
}
```

### 7.4 Usage Examples

#### **Sort Mode Dropdown**
```lua
local sortDropdown = AceGUI:Create("Dropdown")
NextKey222.UIComponents:ConfigureDropdown(sortDropdown, "primary", {
    label = "Sort Mode",
    width = 200,
    list = {
        ["HighestKeyLevel"] = "Highest Key Level",
        ["LowestKeyLevel"] = "Lowest Key Level",
        ["IOGainPotential"] = "IO Gain Potential"
    },
    value = "HighestKeyLevel",
    onValueChanged = function(_, _, value)
        -- Handle sort mode change
        NextKey222.UI:SetCurrentSortMode(value)
        NextKey222.UI:RefreshResults()
    end
})
```

#### **Dynamic Options Dropdown**
```lua
local filterDropdown = AceGUI:Create("Dropdown")
NextKey222.UIComponents:ConfigureDropdown(filterDropdown, "compact", {
    label = "Filter",
    width = 150,
    list = {},  -- Will be populated dynamically
    onValueChanged = function(_, _, value)
        ApplyFilter(value)
    end
})

-- Update options dynamically
function UpdateFilterOptions(options)
    filterDropdown:SetList(options)
    filterDropdown:SetValue(options[1])  -- Select first option
end
```

---

## 8. ScrollFrame Configuration Wrapper

### 8.1 Method Signature

```lua
Components:ConfigureScrollFrame(widget, scrollFrameType, config)
```

**Parameters:**
- `widget`: The AceGUI scroll frame widget to configure
- `scrollFrameType`: String identifier for scroll frame style
- `config`: Optional configuration table for overrides

### 8.2 Available Scroll Frame Types

| Type | Use Case | Default Style |
|------|----------|---------------|
| `primary` | Main content areas | Standard styling |
| `compact` | Space-constrained lists | Compact styling |

### 8.3 Configuration Options

```lua
local config = {
    width = number,                -- Width override
    height = number,               -- Height override
    layout = "List",               -- Layout type for children
    fullWidth = true,               -- Use full parent width
    fullHeight = true,              -- Use full parent height
    colorScheme = "standard",       -- Color scheme for backdrop
    backdropType = "tooltip"        -- Backdrop type override
}
```

### 8.4 Usage Examples

#### **Main Content Scroll Frame**
```lua
local contentScroll = AceGUI:Create("ScrollFrame")
NextKey222.UIComponents:ConfigureScrollFrame(contentScroll, "primary", {
    fullWidth = true,
    fullHeight = true,
    layout = "List",
    colorScheme = "standard"
})

-- Add content items
function AddContentItem(itemText)
    local itemLabel = AceGUI:Create("Label")
    NextKey222.UIComponents:ConfigureText(itemLabel, "body", {
        text = itemText,
        fullWidth = true
    })
    contentScroll:AddChild(itemLabel)
end
```

#### **Compact List Scroll Frame**
```lua
local listScroll = AceGUI:Create("ScrollFrame")
NextKey222.UIComponents:ConfigureScrollFrame(listScroll, "compact", {
    width = 250,
    height = 200,
    layout = "List",
    colorScheme = "light"
})
```

---

## 9. Advanced Configuration Patterns

### 9.1 Configuration Composition

```lua
-- Create a styled button with custom configuration
local function CreateStyledButton(parent, text, onClick)
    local button = AceGUI:Create("Button")
    
    -- Base configuration
    NextKey222.UIComponents:ConfigureButton(button, "primary_action", {
        text = text,
        onClick = onClick
    })
    
    -- Additional customization
    NextKey222.UIComponents:ConfigureBackdrop(button, "compact", {
        colorScheme = "dark"
    })
    
    parent:AddChild(button)
    return button
end
```

### 9.2 Dynamic Configuration

```lua
-- Responsive configuration based on context
local function CreateContextualButton(parent, action, context)
    local buttonType = "secondary_action"
    local config = {text = action.text}
    
    if context.isImportant then
        buttonType = "primary_action"
    end
    
    if context.isCompact then
        buttonType = "select_compact"
    end
    
    if context.onClick then
        config.onClick = context.onClick
    end
    
    local button = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(button, buttonType, config)
    parent:AddChild(button)
    
    return button
end
```

### 9.3 Configuration Inheritance

```lua
-- Base configuration that can be inherited
local BASE_BUTTON_CONFIG = {
    onEnter = function(btn)
        GameTooltip:SetOwner(btn.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(btn.tooltipText or "Button")
        GameTooltip:Show()
    end,
    onLeave = function(btn)
        GameTooltip:Hide()
    end
}

-- Create button with inherited configuration
local function CreateButtonWithTooltip(parent, text, tooltip)
    local config = CopyTable(BASE_BUTTON_CONFIG)
    config.text = text
    config.tooltipText = tooltip
    
    local button = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(button, "select", config)
    parent:AddChild(button)
    
    return button
end
```

---

## 10. Error Handling and Validation

### 10.1 Input Validation

```lua
local function SafeConfigureWidget(widget, configureFunc, type, config)
    if not widget then
        NextKey222.Debug:Error("Widget is nil for configuration")
        return false
    end
    
    if not type or type == "" then
        NextKey222.Debug:Error("Invalid type for widget configuration")
        return false
    end
    
    local success, error = pcall(function()
        configureFunc(NextKey222.UIComponents, widget, type, config)
    end)
    
    if not success then
        NextKey222.Debug:Error("Widget configuration failed:", error)
        return false
    end
    
    return true
end
```

### 10.2 Fallback Configuration

```lua
local function ConfigureWithFallback(widget, type, config, fallbackType)
    local success = SafeConfigureWidget(widget, 
        NextKey222.UIComponents.ConfigureButton, type, config)
    
    if not success and fallbackType then
        NextKey222.Debug:Dev("Using fallback configuration:", fallbackType)
        success = SafeConfigureWidget(widget, 
            NextKey222.UIComponents.ConfigureButton, fallbackType, config)
    end
    
    return success
end
```

---

## 11. Performance Optimization

### 11.1 Configuration Caching

```lua
local configCache = {}

local function GetCachedConfig(configType, configKey)
    if not configCache[configType] then
        configCache[configType] = {}
    end
    
    if not configCache[configType][configKey] then
        configCache[configType][configKey] = BuildConfig(configType, configKey)
    end
    
    return configCache[configType][configKey]
end
```

### 11.2 Batch Configuration

```lua
local function ConfigureMultipleWidgets(widgets, configurations)
    for i, widget in ipairs(widgets) do
        local config = configurations[i]
        if config then
            local configureFunc = GetConfigureFunction(config.type)
            SafeConfigureWidget(widget, configureFunc, config.style, config.options)
        end
    end
end
```

---

## 12. Testing Configuration Wrappers

### 12.1 Unit Testing

```lua
function TestButtonConfiguration()
    local testButton = AceGUI:Create("Button")
    
    -- Test basic configuration
    NextKey222.UIComponents:ConfigureButton(testButton, "primary_action", {
        text = "Test Button"
    })
    
    assert(testButton:GetText() == "Test Button", "Button text not set correctly")
    assert(testButton:GetWidth() > 0, "Button width not set")
    assert(testButton:GetHeight() > 0, "Button height not set")
    
    print("✓ Button configuration test passed")
end
```

### 12.2 Visual Testing

```lua
function TestVisualConsistency()
    local testWindow = AceGUI:Create("Frame")
    testWindow:SetTitle("Configuration Test")
    testWindow:SetLayout("List")
    
    -- Test all button types
    for _, buttonType in ipairs({"primary_action", "secondary_action", "select"}) do
        local button = AceGUI:Create("Button")
        NextKey222.UIComponents:ConfigureButton(button, buttonType, {
            text = buttonType
        })
        testWindow:AddChild(button)
    end
    
    testWindow:Show()
    print("Visual test window opened - verify visual consistency")
end
```

---

## 13. Migration from Manual Styling

### 13.1 Before Manual Styling

```lua
-- Old approach - manual styling
local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
button:SetSize(100, 25)
button:SetText("Click Me")
button:SetScript("OnClick", function()
    print("Clicked!")
end)

-- Manual backdrop
local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
}
button:SetBackdrop(backdrop)
button:SetBackdropColor(0, 0, 0, 0.8)
button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
```

### 13.2 After Configuration Wrappers

```lua
-- New approach - configuration wrappers
local button = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(button, "select", {
    text = "Click Me",
    onClick = function()
        print("Clicked!")
    end
})
parent:AddChild(button)
```

---

## 14. Best Practices Summary

### 14.1 DO's ✅

1. **Always use configuration wrappers** for styling AceGUI widgets
2. **Select appropriate types** based on use case and context
3. **Provide meaningful tooltips** for interactive elements
4. **Use consistent color schemes** across related components
5. **Handle configuration errors gracefully** with fallbacks
6. **Test widget configurations** in isolation
7. **Cache complex configurations** for performance
8. **Document custom configurations** for maintainability

### 14.2 DON'Ts ❌

1. **Don't mix manual styling** with configuration wrappers
2. **Don't hardcode colors and sizes** - use predefined types
3. **Don't skip error handling** for widget configuration
4. **Don't create widgets without proper cleanup**
5. **Don't ignore accessibility** in widget configuration
6. **Don't use inconsistent styling** across similar elements
7. **Don't override configuration** without good reason
8. **Don't forget to test** visual appearance and functionality

---

## 15. Quick Reference

### 15.1 Configuration Method Summary

| Method | Widget Types | Key Config Options |
|--------|--------------|-------------------|
| `ConfigureBackdrop` | All containers | `colorScheme`, custom colors |
| `ConfigureButton` | Button | `text`, `onClick`, `size` |
| `ConfigureText` | Label | `text`, `color`, `fontObject` |
| `ConfigureFrame` | Containers | `layout`, `width`, `height` |
| `ConfigureIcon` | Icon | `imagePath`, `size`, `onClick` |
| `ConfigureDropdown` | Dropdown | `list`, `value`, `onValueChanged` |
| `ConfigureScrollFrame` | ScrollFrame | `layout`, `fullWidth`, `fullHeight` |

### 15.2 Common Configuration Patterns

```lua
-- Standard action button
NextKey222.UIComponents:ConfigureButton(button, "primary_action", {
    text = "Action",
    onClick = handler
})

-- List item with hover effects
NextKey222.UIComponents:ConfigureButton(button, "select_compact", {
    text = itemText,
    onClick = itemHandler,
    onEnter = hoverHandler,
    onLeave = leaveHandler
})

-- Section header
NextKey222.UIComponents:ConfigureText(label, "header", {
    text = "Section Title",
    justifyH = "CENTER"
})

-- Content panel
NextKey222.UIComponents:ConfigureFrame(container, "panel", {
    layout = "List",
    width = 400
})
```

---

## 16. Conclusion

The configuration wrapper system is the foundation of NextKey's UI consistency and maintainability. By using these wrappers correctly, developers can create UI elements that are visually consistent, functionally reliable, and easy to maintain.

Always refer to this guide when working with UI components, and don't hesitate to extend the system with new configuration types when needed for specific use cases.

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-16  
**Next Review**: 2025-11-16  
**Related Documents**: 
- [Ace3 Widget Selection Guidelines](Ace3_Widget_Selection_Guidelines.md)
- [Code Style Guide for Ace3 Development](Code_Style_Guide_Ace3.md)
- [Migration Guide for Future UI Components](Migration_Guide_UI_Components.md)