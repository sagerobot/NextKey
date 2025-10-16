# NextKey Ace3 Usage Guidelines
**Version:** 1.0  
**Status:** In Review  
**Created:** 2025-10-16

---

## 1. Core Principle: Pure Ace3 with Configuration Wrappers

To maximize consistency and leverage the power of the Ace3 library, all new UI development **must** use pure AceGUI widgets. We will no longer use native `CreateFrame` calls for UI elements that have an AceGUI equivalent.

Instead of manually styling each widget, we will use the configuration wrappers provided in `ui/components.lua`. These wrappers apply a consistent set of properties to standard AceGUI widgets, ensuring a uniform look and feel across the entire addon.

---

## 2. Widget Creation and Configuration Workflow

The standard workflow for creating any UI element is as follows:

1.  **Create the AceGUI Widget:**
    ```lua
    local button = AceGUI:Create("Button")
    ```

2.  **Apply Configuration Wrapper:**
    ```lua
    -- Apply the 'select' button style from our component configurations
    NextKey222.UIComponents:ConfigureButton(button, "select", {
        text = "Click Me!",
        onClick = function() print("Button clicked!") end
    })
    ```

3.  **Add to Container:**
    ```lua
    container:AddChild(button)
    ```

This approach separates the creation of the widget (handled by AceGUI) from the configuration of its appearance and behavior (handled by our wrappers), leading to cleaner and more maintainable code.

---

## 3. Configuration Wrappers

The following configuration wrappers are available in `ui/components.lua` and **must** be used to ensure a consistent look and feel:

-   **`Components:ConfigureBackdrop(widget, type, config)`**: Applies standard backdrop styles to any AceGUI container. This is crucial for maintaining visual consistency.
-   **`Components:ConfigureButton(widget, type, config)`**: Configures `AceGUI:Create("Button")` with our standard button styles (size, text, etc.).
-   **`Components:ConfigureText(widget, type, config)`**: Configures `AceGUI:Create("Label")` with our standard text styles (font, size, color).
-   **`Components:ConfigureFrame(widget, type, config)`**: Configures AceGUI containers (`Frame`, `SimpleGroup`, etc.) with standard properties like size and layout.
-   **`Components:ConfigureIcon(widget, type, config)`**: Configures `AceGUI:Create("Icon")` with standard icon styles, including image and size.

---

## 4. When to Use Native Frames (Hybrid Approach)

While pure Ace3 is the goal, there are specific situations where a native frame may be necessary:

-   **Specialized Behavior:** If a widget requires behavior not supported by AceGUI (e.g., complex mouse interactions, non-standard animations). The **Teleport Window** is a good example of this, as it requires secure action button templates and custom layout logic.
-   **Performance-Critical Elements:** For UI elements that are created and destroyed hundreds of times per second (though this should be rare), a lightweight native frame might be more performant.
-   **No AceGUI Equivalent:** If there is no AceGUI widget that provides the needed functionality.

In these cases, the native frame should still use the `ConfigureBackdrop` wrapper to maintain a consistent appearance with the rest of the UI.

---

## 5. Migrating Existing UI Files

When migrating existing UI files from native frames to AceGUI, follow these steps:

1.  **Replace `CreateFrame` with `AceGUI:Create`.**
2.  **Replace manual styling with calls to the appropriate configuration wrapper.**
3.  **Migrate `SetScript` calls to `SetCallback` for AceGUI widgets.**
4.  **Use AceGUI's layout system (`SetLayout`) instead of manual positioning where possible.**

---

## 6. Example: Migrating a Native Button to AceGUI

**Old Code (Native):**
```lua
local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
button:SetSize(100, 25)
button:SetText("Click Me!")
button:SetScript("OnClick", function() print("Clicked!") end)
```

**New Code (AceGUI with Wrapper):**
```lua
local button = AceGUI:Create("Button")
NextKey222.UIComponents:ConfigureButton(button, "select", {
    text = "Click Me!",
    onClick = function() print("Clicked!") end
})
parent:AddChild(button)
```

By following these guidelines, we can ensure that our UI is consistent, maintainable, and fully leverages the power of the Ace3 library.