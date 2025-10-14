# AceGUI-3.0 Widgets

## Base Widget APIs

This is a list of all commonly used and public APIs all widgets (and containers) share. There are additional APIs that are reserved for internal use by the Layout functions or the Widgets themself, and are not documented here.

### widget:SetCallback(name, func)

Set the callback function of a specific callback. Only one function can be assigned to every callback.

**Usage**

```lua
local frame = AceGUI:Create("Frame")
frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
```

Every callback is called with the widget as the first argument, and the name of the callback as the second.
Any arguments specific to the callback type follow after these two arguments.

### widget:SetWidth(width)

Sets the absolute width of the widget.
Calling this function will try to call :OnWidthSet on the widget, if defined.

### widget:SetRelativeWidth(width)

Set the width of the widget relative to its container.
Any values between 0.0 and 1.0 are accepted, in percent.

### widget:SetHeight(width)

Sets the absolute height of the widget.
Calling this function will try to call :OnHeightSet on the widget, if defined.

**Note**: Most widgets have a fixed pre-defined height, and changing their height is not recommended.

### widget:IsVisible()

Return whether or not an object is actually visible on-screen.

### widget:IsShown()

Determine if this object is shown (would be visible if its parent was visible).

### widget:Release()

Release the widget back into the widget pool.

This is the equivalent to `AceGUI:Release(widget)`

### widget:SetPoint(...)

Set an attachment point of this widget.
This function directly forwards to the base-frames :SetPoint

### widget:ClearAllPoints()

Clear all attachment points of this widget.

### widget:GetNumPoints()

Get the number of anchor points for this widget.

### widget:GetPoint(...)

Get details for an anchor point for this widget.

### widget:GetUserDataTable()

Return the internal user data table from this widget.

The User Data can be used to store information about this widget, and its functionality. Any User Data is wiped when the widget is released.

### widget:SetUserData(key, value)

Set a key in the user data table.

### widget:GetUserData(key)

Get the value of a specific user data key.

### widget:SetFullHeight(isFull)

Set if the widget should use the full available height of its container.

### widget:IsFullHeight()

Return if the widget is using the full height of its container.

### widget:SetFullWidth(isFull)

Set if the widget should use the full available width of its container.

### widget:IsFullWidth()

Return if the widget is using the full width of its container.

## Widgets

### Button

This widget is a default click-able Button.

#### APIs

- `SetText(text)` - Set the Text to be displayed on the button.
- `SetDisabled(flag)` - Disable the widget.

#### Callbacks

- `OnClick()` - Fires when the button is clicked.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### CheckBox

A checkbox, optionally tri-state.

#### APIs

- `SetValue(flag)` - Set the state of the checkbox
- `GetValue()` - Get the state of the checkbox
- `SetType(type)` - Set the type of the checkbox("radio" or "checkbox")
- `ToggleChecked()` - Toggle the value
- `SetLabel(text)` - Set the text for the label
- `SetTriState(state)` - Enable/Disable the tri-state behaviour.
- `SetDisabled(flag)` - Disable the widget.
- `SetDescription(description)` - Set the description of the widget, shown as small text below it.
- `SetImage(path, ...)` - Set the image of the checkbox. Optionally you can pass parameters to be passed to SetTexCoords (4 or 8 argument version)

#### Callbacks

- `OnValueChanged(value)` - Fires when the state of the checkbox changes.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### ColorPicker

A small color-display widget which opens the ColorPicker frame when clicked.

#### APIs

- `SetColor(r, g, b, a)` - Set the color
- `SetLabel(text)` - Set the text for the label
- `SetHasAlpha(flag)` - Set if the color picker has an alpha value
- `SetDisabled(flag)` - Disable the widget.

#### Callbacks

- `OnValueChanged(r, g, b, a)` - Fires when the color value is changed, but the color picker is still open.
- `OnValueConfirmed(r, g, b, a)` - Fires when the color picker is closed.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### Dropdown

A select-box style box with a dropdown pullout.

#### APIs

- `SetValue(key)` - Set the value to an item in the List.
- `SetList(table [, order])` - Set the list of values for the dropdown (key => value pairs). The order is a optional second table, that contains the order in which the entrys should be displayed (Array table with the data tables keys as values). Behaviour is undefined if you provide a order table that contains not the exact same keys as in the data table.
- `SetText(text)` - Set the text displayed in the box.
- `SetLabel(text)` - Set the text for the label.
- `AddItem(key, value)` - Add an item to the list.
- `SetMultiselect(flag)` - Toggle multi-selecting.
- `GetMultiselect()` - Query the multi-select flag.
- `SetItemValue(key, value)` - Set the value of a item in the list.
- `SetItemDisabled(key, flag)` - Disable one item in the list.
- `SetDisabled(flag)` - Disable the widget.

#### Callbacks

- `OnValueChanged(key [,checked])` - Fires when the selection changes. The second argument is send for multi-select dropdowns to indicate a change in one option.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### EditBox

A simple text input box.

#### APIs

- `SetText(text)` - Set the text in the edit box.
- `GetText()` - Get the text in the edit box.
- `SetLabel(text)` - Set the text for the label.
- `SetDisabled(flag)` - Disable the widget.
- `DisableButton(flag)` - True to disable the "Okay" button, false to enable it again.
- `SetMaxLetters(num)` - Set the maximum number of letters that can be entered (0 for unlimited).
- `SetFocus()` - Set the focus to the editbox.
- `HighlightText(start, end)` - Highlight the text in the editbox (see Blizzard EditBox Widget documentation for details)

#### Callbacks

- `OnTextChanged(text)` - Fires on every text change.
- `OnEnterPressed(text)` - Fires when the new text was confirmed and should be saved.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### Heading

A horizontal line with a short label in the middle.

#### APIs

- `SetText(text)` - Set the text to be displayed in the heading.

#### Callbacks

- none

### Icon

A click-able icon widget.

#### APIs

- `SetImage(image, ...)` - Set the image to be shown. Additionally to the path, any extra arguments will be directly forwarded to `:SetTexCoord`.
- `SetImageSize(width, height)` - Set the size of the image.
- `SetLabel(text)` - Set the text for the label.

#### Callbacks

- `OnClick(button)` - Fires when the icon is clicked.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### InteractiveLabel

A basic label which reacts to mouse interaction, optionally with an icon in front.

#### APIs

- `SetText(text)` - Set the text.
- `SetColor(r, g, b)` - Set the color of the text.
- `SetFont(font, height, flags)` - Set the font of the text.
- `SetFontObject(font)` - Set the font using a pre-defined font-object.
- `SetImage(image, ...)` - Set the image to be shown. Additionally to the path, any extra arguments will be directly forwarded to `:SetTexCoord`.
- `SetImageSize(width, height)` - Set the size of the image.
- `SetHighlight(...)` - Set the highlight texture (either path to a texture, or RGBA values for a solid color)
- `SetHighlightTexCoord(...)` - Set the tex coords for the highlight texture.

#### Callbacks

- `OnClick(button)` - Fires when the label is clicked.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### Keybinding

A widget to control binding of keys.

#### APIs

- `SetKey(key)` - Set the current key.
- `GetKey()` - Set the current key.
- `SetLabel(text)` - Set the text of the label.
- `SetDisabled(flag)` - Disable the widget.

#### Callbacks

- `OnKeyChanged(key)` - Fires when the key was changed.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### Label

A plain text, optionally with an icon in front.

#### APIs

- `SetText(text)` - Set the text.
- `SetColor(r, g, b)` - Set the color of the text.
- `SetFont(font, height, flags)` - Set the font of the text.
- `SetFontObject(font)` - Set the font using a pre-defined font-object.
- `SetImage(image, ...)` - Set the image to be shown. Additionally to the path, any extra arguments will be directly forwarded to `:SetTexCoord`.
- `SetImageSize(width, height)` - Set the size of the image.

#### Callbacks

- none

### MultiLineEditBox

A multiline editbox for text input.

#### APIs

- `SetText(text)` - Set the text in the edit box.
- `GetText()` - Get the text in the edit box.
- `SetLabel(text)` - Set the text for the label.
- `SetNumLines(num)` - Set the number of lines to be displayed in the editbox.
- `SetDisabled(flag)` - Disable the widget.
- `SetMaxLetters(num)` - Set the maximum number of letters that can be entered (0 for unlimited).
- `DisableButton(flag)` - Disable the "Okay" Button
- `SetFocus()` - Set the focus to the editbox.
- `HighlightText(start, end)` - Highlight the text in the editbox (see Blizzard EditBox Widget documentation for details)

#### Callbacks

- `OnTextChanged(text)` - Fires on every text change.
- `OnEnterPressed(text)` - Fires when the new text was confirmed and should be saved.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

### Slider

A slider. Like, for ranges of values.

#### APIs

- `SetValue(value)` - Set the current value of the slider.
- `GetValue()` - Get the current value of the slider.
- `SetSliderValues(min, max, step)` - Set the parameters of the slider. Minimum, maximum and the step value.
- `SetIsPercent(flag)` - Set if the values are percentage values.
- `SetLabel(text)` - Set the text for the label.
- `SetDisabled(flag)` - Disable the widget.

#### Callbacks

- `OnValueChanged(value)` - Fires when the value changed. (Fires *alot* when moving the slider with the mouse)
- `OnMouseUp(value)` - Fires when the mouse is removed from the slider, and the movement stops at the final position.
- `OnEnter()` - Fires when the cursor enters the widget.
- `OnLeave()` - Fires when the cursor leaves the widget.

## Base Container APIs

In addition to all Base Widget APIs, all Containers share another set of common APIs to manage the Layout and their child widgets.

### container:AddChild(widget [, beforeWidget])

Add a new widget to the list of the containers children.
If `beforeWidget` is specified, the new widget will be inserted before this widget in the list, otherwise at the end.

### container:SetLayout(layout)

Set the Layout this container should use when managing its child frames.
Currently implemented Layouts in AceGUI-3.0:

- "Flow" - A row based flow layout
- "List" - A simple stacking layout
- "Fill" - Fill the whole container with the first widget (used by Groups)

### container:SetAutoAdjustHeight(flag)

Enable/Disable the automatic height adjustment of containers.
If this is on (default), the container will resize vertically to fit all widgets in it.

This setting has no effect if a container is added in a "Fill" Layout, or if its set to use all available space (SetFullHeight).

### container:ReleaseChildren()

Release all child frames of this container.

### container:DoLayout()

Cause the container to re-layout all his child frames.

### container:PauseLayout()

Suspend all layout operations until resumed.

### container:ResumeLayout()

Resume layout operations after pause.

## Containers

### DropdownGroup

A group controlled by a dropdown on top of a big container frame.

#### APIs

- `SetTitle(text)` - Set the title of the group.
- `SetGroupList(table [, order])` - Set the list of groups (key => value pairs) .The order is a optional second table, that contains the order in which the entrys should be displayed (Array table with the data tables keys as values). Behaviour is undefined if you provide a order table that contains not the exact same keys as in the data table.
- `SetGroup(key)` - Set the active group.
- `SetDropdownWidth(width)` - Set the width of the dropdown box.
- `SetStatusTable(table)` - Set an external status table.

#### Callbacks

- `OnGroupSelected(group)` - Fires when a new group selection occurs.

### Frame

A simple stand-alone container widget, usually the base of any UI.

#### APIs

- `SetTitle(text)` - Set the title of the frame.
- `SetStatusText(text)` - Set the text in the status bar.
- `SetStatusTable(table)` - Set an external status table.
- `ApplyStatus()` - Apply the settings stored in the status table.

#### Callbacks

- `OnClose()` - Fires when the frame is closed.
- `OnEnterStatusBar()` - When the mouse enters the statusbar region of the frame.
- `OnLeaveStatusBar()` - When the mouse leaves the statusbar region of the frame.

### InlineGroup

A group designed to be used inline in other content, to group widgets.

#### APIs

- `SetTitle(text)` - Set the title of the inline group.

#### Callbacks

- none

### ScrollFrame

A scrolling group, usually used inside another group to provide scrolling capabilities.
Note that the container containing the ScrollFrame should always be set to the "Fill" layout, or the ScrollFrame will not function properly.

```lua
scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
scrollcontainer:SetFullWidth(true)
scrollcontainer:SetFullHeight(true) -- probably?
scrollcontainer:SetLayout("Fill") -- important!

topContainer:AddChild(scrollcontainer)

scroll = AceGUI:Create("ScrollFrame")
scroll:SetLayout("Flow") -- probably?
scrollcontainer:AddChild(scroll)

-- ... add your widgets to "scroll"
```

#### APIs

- `SetScroll(value)` - Set the scroll position.
- `SetStatusTable(table)` - Set an external status table.

#### Callbacks

- none

### SimpleGroup

An empty group with no title or graphics.

#### APIs

- none

#### Callbacks

- none

### TabGroup

A group controlled by tabs above it.

#### APIs

- `SetTitle(text)` - Set the title of the group.
- `SetTabs(table)` - Set the list of tabs. Tabs need to be provided as a array of {value = "key", text = "Visible Text" }. Additionally they can contain a "disabled" member.
- `SelectTab(key)` - Select an tab.
- `SetStatusTable(table)` - Set an external status table.

#### Callbacks

- `OnGroupSelected(group)` - Fires when a new group selection occurs.
- `OnTabEnter(key, tab)` - Fires when the cursor enters a tab.
- `OnTabLeave(key, tab)` - Fires when the cursor leaves a tab.

### TreeGroup

A tree-group widget.

#### The tree table

The basic tree-table is a array of sub-tables. Every entry in the array has to have a `value` and a `text` member, and an optional `icon` member.
An optional `children` member can be provided, which simply contains another complete tree.
Additionally, you can specify `visible` and `disabled` members to control the creation/behaviour of the table.

**Example**

```lua
-- Integrated example for tree table structure
--[[ 
   Alpha
   Bravo
     -Charlie
     -Delta
       -Echo
   Foxtrot
]]
```

```lua
tree = { 
  { 
    value = "A",
    text = "Alpha",
    icon = "Interface\\Icons\\INV_Drink_05",
  },
  {
    value = "B",
    text = "Bravo",
    children = {
      {
        value = "C", 
        text = "Charlie",
      },
      {
        value = "D",	
        text = "Delta",
        children = { 
          {
            value = "E",
            text = "Echo"
          }
        }
      }
    }
  },
  {
    value = "F", 
    text = "Foxtrot",
    disabled = true,
  },
}
```

#### APIs

- `SetTree(tree)` - Set the tree to be displayed. See above for the format of the tree table.
- `SelectByPath(...)` - Set the path in the tree given the raw keys.
- `SelectByValue(uniquevalue)` - Set the path in the tree by a given unique value.
- `EnableButtonTooltips(flag)` - Toggle the tooltips on the tree buttons.
- `SetStatusTable(table)` - Set an external status table.

#### Callbacks

- `OnGroupSelected(group)` - Fires when a new group selection occurs.
- `OnTreeResize(width)` - Fires when the tree was resized by the user.
- `OnButtonEnter(path, frame)` - Fires when the cursor enters a tree-button.
- `OnButtonLeave(path, frame)` - Fires when the cursor leaves a tree-button.