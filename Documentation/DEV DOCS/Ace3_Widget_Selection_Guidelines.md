# Ace3 Widget Selection Guidelines
**Version:** 1.0  
**Status:** Complete  
**Created:** 2025-10-16  
**Phase:** Phase 6 - Ace3 Best Practices Documentation

---

## Overview

This document provides comprehensive guidelines for selecting the appropriate AceGUI widgets for different UI scenarios in NextKey. Following these guidelines ensures consistency, maintainability, and optimal user experience across all UI components.

---

## 1. Widget Selection Decision Tree

### 1.1 Primary Widget Selection Flow

```
Start → Need User Interaction?
├─ Yes → Need Text Input?
│   ├─ Yes → Use EditBox
│   └─ No → Need Selection from List?
│       ├─ Yes → Use Dropdown
│       └─ No → Use Button
└─ No → Need to Display Content?
    ├─ Yes → Need Multiple Lines?
    │   ├─ Yes → Use ScrollFrame
    │   └─ No → Use Label
    └─ No → Need to Group Elements?
        ├─ Yes → Use Container (SimpleGroup/InlineGroup)
        └─ No → Use Icon
```

### 1.2 Container Selection Flow

```
Need Container? → Purpose?
├─ Main Window → Use Frame
├─ Modal Dialog → Use Frame with dialog backdrop
├─ Content Section → Use InlineGroup
├─ Simple Grouping → Use SimpleGroup
├─ Scrollable Content → Use ScrollFrame
└─ Tabbed Interface → Use TabGroup
```

---

## 2. Widget Usage Guidelines

### 2.1 Frame Containers

#### **Frame** (`AceGUI:Create("Frame")`)
**Use Cases:**
- Main application windows
- Modal dialogs
- Top-level containers that need movement/resizing

**When to Use:**
- Creating the primary window for a UI panel
- Need window controls (close, minimize)
- Require resize functionality
- Need to be draggable

**Example:**
```lua
local mainWindow = AceGUI:Create("Frame")
mainWindow:SetTitle("NextKey")
mainWindow:SetLayout("Flow")
mainWindow:EnableResize(true)
NextKey222.UIComponents:ConfigureBackdrop(mainWindow, "dialog", { colorScheme = "dark" })
```

#### **SimpleGroup** (`AceGUI:Create("SimpleGroup")`)
**Use Cases:**
- Logical grouping of related elements
- Creating custom layout sections
- Minimal visual grouping

**When to Use:**
- Need to group elements without visual border
- Creating layout containers
- Organizing related controls

**Example:**
```lua
local controlGroup = AceGUI:Create("SimpleGroup")
controlGroup:SetLayout("Flow")
controlGroup:SetFullWidth(true)
NextKey222.UIComponents:ConfigureFrame(controlGroup, "container", {
    layout = "Flow"
})
```

#### **InlineGroup** (`AceGUI:Create("InlineGroup")`)
**Use Cases:**
- Content sections with visual boundaries
- Grouped form elements
- Visual hierarchy establishment

**When to Use:**
- Need visual grouping with border and title
- Creating content sections
- Organizing related form fields

**Example:**
```lua
local contentSection = AceGUI:Create("InlineGroup")
contentSection:SetTitle("Player Information")
contentSection:SetLayout("List")
NextKey222.UIComponents:ConfigureFrame(contentSection, "panel", {
    width = 400,
    height = 200
})
```

#### **ScrollFrame** (`AceGUI:Create("ScrollFrame")`)
**Use Cases:**
- Long lists of items
- Content that exceeds available space
- Dynamic content with variable height

**When to Use:**
- Displaying variable numbers of items
- Content may exceed container height
- Need efficient scrolling for large datasets

**Example:**
```lua
local scrollFrame = AceGUI:Create("ScrollFrame")
scrollFrame:SetLayout("List")
scrollFrame:SetFullWidth(true)
scrollFrame:SetFullHeight(true)
NextKey222.UIComponents:ConfigureScrollFrame(scrollFrame, "primary", {
    fullWidth = true,
    fullHeight = true,
    layout = "List"
})
```

### 2.2 Interactive Elements

#### **Button** (`AceGUI:Create("Button")`)
**Use Cases:**
- User actions (save, cancel, confirm)
- Navigation (next, previous, back)
- Mode toggles (switch views, enable/disable)

**When to Use:**
- Need clickable action
- Require text label
- Visual feedback on interaction

**Button Type Selection:**
- `BUTTON_PRIMARY_ACTION`: Main actions (Save, Apply)
- `BUTTON_SECONDARY_ACTION`: Secondary actions (Cancel, Reset)
- `BUTTON_COMPACT_LIST`: List items with limited space
- `BUTTON_SELECT`: Selection actions (Choose, Select)
- `BUTTON_ICON`: Icon-only buttons
- `BUTTON_TOGGLE`: State toggle buttons

**Example:**
```lua
local saveButton = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(saveButton, "primary_action", {
    text = "Save Settings",
    onClick = function()
        -- Save logic
    end
})
```

#### **Dropdown** (`AceGUI:Create("Dropdown")`)
**Use Cases:**
- Selection from predefined options
- Mode selection
- Configuration choices

**When to Use:**
- User needs to select from 3+ options
- Limited screen space
- Need clear selection indicator

**Example:**
```lua
local sortDropdown = AceGUI:Create("Dropdown")
NextKey222.UIComponents:ConfigureDropdown(sortDropdown, "primary", {
    label = "Sort Mode",
    list = {
        ["HighestKeyLevel"] = "Highest Key Level",
        ["LowestKeyLevel"] = "Lowest Key Level",
        ["IOGainPotential"] = "IO Gain Potential"
    },
    value = "HighestKeyLevel",
    onValueChanged = function(_, _, value)
        -- Handle selection change
    end
})
```

#### **CheckBox** (`AceGUI:Create("CheckBox")`)
**Use Cases:**
- Binary options (enable/disable)
- Multiple selection from list
- Feature toggles

**When to Use:**
- Simple on/off choice
- Multiple independent options
- Need immediate visual feedback

**Example:**
```lua
local enableDebug = AceGUI:Create("CheckBox")
enableDebug:SetLabel("Enable Debug Mode")
enableDebug:SetValue(false)
enableDebug:SetCallback("OnValueChanged", function(_, _, value)
    -- Handle toggle
end)
```

#### **EditBox** (`AceGUI:Create("EditBox")`)
**Use Cases:**
- Text input
- Search fields
- Numeric entry

**When to Use:**
- Need user text input
- Search functionality
- Configuration values

**Example:**
```lua
local searchBox = AceGUI:Create("EditBox")
searchBox:SetLabel("Search")
searchBox:SetButtonText("Search")
searchBox:SetCallback("OnEnterPressed", function(_, _, text)
    -- Handle search
end)
```

### 2.3 Display Elements

#### **Label** (`AceGUI:Create("Label")`)
**Use Cases:**
- Static text display
- Dynamic information
- Status indicators

**When to Use:**
- Display non-interactive text
- Show dynamic information
- Create visual hierarchy

**Text Type Selection:**
- `TEXT_HEADER`: Titles and section headers
- `TEXT_BODY`: Standard content text
- `TEXT_LABEL`: Field labels and descriptions
- `TEXT_TOOLTIP`: Tooltip text
- `TEXT_SCORE`: Numeric scores with coloring
- `TEXT_SMALL`: Supplementary information

**Example:**
```lua
local titleLabel = AceGUI:Create("Label")
NextKey222.UIComponents:ConfigureText(titleLabel, "header", {
    text = "Player Information",
    justifyH = "CENTER"
})
```

#### **Icon** (`AceGUI:Create("Icon")`)
**Use Cases:**
- Visual indicators
- Class/spec icons
- Status symbols
- Item/dungeon icons

**When to Use:**
- Need visual representation
- Convey information visually
- Enhance visual appeal

**Icon Type Selection:**
- `ICON_CLASS`: Class icons
- `ICON_ROLE`: Role icons (tank/healer/dps)
- `ICON_DUNGEON`: Dungeon icons
- `ICON_ITEM`: Item icons
- `ICON_SMALL`: Small icons (16x16)
- `ICON_LARGE`: Large icons (64x64)

**Example:**
```lua
local classIcon = AceGUI:Create("Icon")
NextKey222.UIComponents:ConfigureIcon(classIcon, "class", {
    imagePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes",
    imageWidth = 32,
    imageHeight = 32,
    onClick = function()
        -- Handle icon click
    end
})
```

---

## 3. Layout Patterns

### 3.1 Common Layout Combinations

#### **Standard Window Layout**
```
Frame (main window)
├─ Label (title)
├─ SimpleGroup (controls)
│  ├─ Dropdown (sort mode)
│  ├─ Button (refresh)
│  └─ Button (sync)
└─ ScrollFrame (content)
   ├─ InlineGroup (item 1)
   └─ InlineGroup (item 2)
```

#### **Form Layout**
```
InlineGroup (form section)
├─ Label (field label)
├─ EditBox (input field)
├─ Label (field label)
├─ Dropdown (selection)
└─ CheckBox (option)
```

#### **List Layout**
```
ScrollFrame (list container)
├─ SimpleGroup (list item 1)
│  ├─ Icon (item icon)
│  ├─ Label (item text)
│  └─ Button (action)
├─ SimpleGroup (list item 2)
│  └─ ...
```

### 3.2 Layout Best Practices

#### **Use Appropriate Layout Types**
```lua
-- Flow layout for horizontal arrangement
container:SetLayout("Flow")

-- List layout for vertical stacking
container:SetLayout("List")

-- Fill layout for single child to fill parent
container:SetLayout("Fill")
```

#### **Set Appropriate Sizing**
```lua
-- Full width for containers
container:SetFullWidth(true)

-- Specific dimensions for precise control
widget:SetWidth(200)
widget:SetHeight(100)

-- Let content determine size
widget:SetRelativeWidth(0.5) -- 50% of parent
```

---

## 4. Performance Considerations

### 4.1 Widget Creation Patterns

#### **Reuse Widgets When Possible**
```lua
-- ✅ Good - Create once, update content
local label = AceGUI:Create("Label")
function UpdateScore(score)
    label:SetText(string.format("Score: %d", score))
end

-- ❌ Bad - Recreate for each update
function UpdateScoreBad(score)
    local label = AceGUI:Create("Label")
    label:SetText(string.format("Score: %d", score))
    container:AddChild(label)
end
```

#### **Batch Updates**
```lua
-- ✅ Good - Batch multiple updates
function UpdateMultipleItems(items)
    for _, item in ipairs(items) do
        UpdateWidgetItem(item)
    end
    container:DoLayout() -- Single layout pass
end

-- ❌ Bad - Layout after each update
function UpdateMultipleItemsBad(items)
    for _, item in ipairs(items) do
        UpdateWidgetItem(item)
        container:DoLayout() -- Multiple layout passes
    end
end
```

### 4.2 Memory Management

#### **Release Unused Widgets**
```lua
-- ✅ Good - Proper cleanup
function ClearContent()
    container:ReleaseChildren()
    -- Widgets are properly released
end

-- ✅ Good - Release individual widgets
function RemoveWidget(widget)
    container:RemoveChild(widget)
    AceGUI:Release(widget)
end
```

---

## 5. Accessibility Considerations

### 5.1 Keyboard Navigation

#### **Ensure Tab Order**
```lua
-- Set tab order for logical navigation
button1:SetFocus()
button2:SetFocus()
dropdown:SetFocus()
```

#### **Provide Keyboard Shortcuts**
```lua
-- Add keyboard support for common actions
frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide()
    elseif key == "ENTER" then
        SaveSettings()
    end
end)
```

### 5.2 Visual Clarity

#### **Use High Contrast Colors**
```lua
-- Use predefined color schemes
NextKey222.UIComponents:ConfigureBackdrop(frame, "dialog", {
    colorScheme = "dark" -- Good contrast
})
```

#### **Provide Clear Visual Feedback**
```lua
-- Show hover and active states
button:SetCallback("OnEnter", function()
    button:SetHighlight(true)
end)

button:SetCallback("OnLeave", function()
    button:SetHighlight(false)
end)
```

---

## 6. Error Handling

### 6.1 Widget Creation Safety

#### **Validate Widget Creation**
```lua
local function SafeCreateWidget(widgetType, parent)
    local widget = AceGUI:Create(widgetType)
    if not widget then
        NextKey222.Debug:Error("Failed to create widget:", widgetType)
        return nil
    end
    
    if parent then
        parent:AddChild(widget)
    end
    
    return widget
end
```

#### **Handle Configuration Errors**
```lua
local function SafeConfigureWidget(widget, configType, config)
    if not widget or not configType then
        NextKey222.Debug:Error("Invalid parameters for widget configuration")
        return false
    end
    
    local success, error = pcall(function()
        NextKey222.UIComponents["Configure" .. configType](widget, config)
    end)
    
    if not success then
        NextKey222.Debug:Error("Widget configuration failed:", error)
        return false
    end
    
    return true
end
```

---

## 7. Testing Guidelines

### 7.1 Widget Functionality Testing

#### **Test Widget Creation**
```lua
function TestWidgetCreation()
    -- Test all widget types
    local testFrame = AceGUI:Create("Frame")
    assert(testFrame, "Frame creation failed")
    
    local testButton = AceGUI:Create("Button")
    assert(testButton, "Button creation failed")
    
    -- Test component configuration
    NextKey222.UIComponents:ConfigureButton(testButton, "select")
    assert(testButton:GetText() ~= "", "Button configuration failed")
    
    print("✓ Widget creation tests passed")
end
```

#### **Test Widget Interaction**
```lua
function TestWidgetInteraction()
    local buttonClicked = false
    
    local testButton = AceGUI:Create("Button")
    NextKey222.UIComponents:ConfigureButton(testButton, "select", {
        onClick = function()
            buttonClicked = true
        end
    })
    
    -- Simulate click
    testButton:Fire("OnClick")
    assert(buttonClicked, "Button click handler not called")
    
    print("✓ Widget interaction tests passed")
end
```

---

## 8. Migration Checklist

### 8.1 From Native Frames to AceGUI

- [ ] Identify all `CreateFrame` calls
- [ ] Map to appropriate AceGUI widgets
- [ ] Replace `SetScript` with `SetCallback`
- [ ] Apply component configuration wrappers
- [ ] Test functionality parity
- [ ] Verify visual appearance
- [ ] Performance testing

### 8.2 From Manual Styling to Components

- [ ] Remove manual `SetBackdrop` calls
- [ ] Replace with `ConfigureBackdrop`
- [ ] Remove manual font object setting
- [ ] Replace with `ConfigureText`
- [ ] Apply consistent color schemes
- [ ] Test visual consistency

---

## 9. Quick Reference

### 9.1 Widget Type Matrix

| Need | Widget | Component Method | Example Use |
|------|--------|------------------|-------------|
| Main Window | Frame | `CreateFrame("window")` | Primary UI window |
| Content Section | InlineGroup | `CreateFrame("panel")` | Settings section |
| Simple Grouping | SimpleGroup | `CreateFrame("container")` | Button container |
| Scrollable List | ScrollFrame | `CreateScrollFrame("primary")` | Item list |
| User Action | Button | `CreateButton("primary_action")` | Save button |
| Selection | Dropdown | `CreateDropdown("primary")` | Sort mode |
| Text Display | Label | `CreateText("body")` | Information text |
| Icon Display | Icon | `CreateIcon("class")` | Class icon |
| Text Input | EditBox | Create manually | Search box |
| Binary Choice | CheckBox | Create manually | Enable option |

### 9.2 Configuration Types

| Component | Types Available |
|-----------|------------------|
| Backdrop | `tooltip`, `dialog`, `dark_dialog`, `compact` |
| Button | `primary_action`, `secondary_action`, `select`, `compact_list`, `icon` |
| Frame | `window`, `panel`, `container`, `scroll`, `tooltip`, `dialog` |
| Text | `header`, `body`, `label`, `tooltip`, `score`, `small`, `large` |
| Icon | `class`, `role`, `dungeon`, `item`, `small`, `large` |

---

## 10. Conclusion

Following these guidelines ensures that NextKey's UI remains consistent, maintainable, and user-friendly. The component system provides a solid foundation for UI development while the AceGUI framework offers powerful widgets for complex interactions.

Always prefer the component system over manual styling, and choose the appropriate widget type based on the specific use case and user interaction needs.

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-16  
**Next Review**: 2025-11-16  
**Related Documents**: 
- [Configuration Wrapper Usage Guide](Configuration_Wrapper_Usage_Guide.md)
- [Code Style Guide for Ace3 Development](Code_Style_Guide_Ace3.md)
- [Migration Guide for Future UI Components](Migration_Guide_UI_Components.md)