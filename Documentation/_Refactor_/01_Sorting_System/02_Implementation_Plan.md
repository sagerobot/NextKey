# Refactor Implementation Plan: 01_Sorting_System

## 1. File Structure

A new directory will be created to house the sorting service and its related algorithm files.

- **`core/sorting/`**
  - **`main.lua`**: The core of the service. It will contain the registry, the public API, and the filtering logic.
  - **`algorithms/`**: A new subdirectory to hold the individual algorithm files.
    - **`byScore.lua`**: Example algorithm file.
    - **`byKeyLevel.lua`**: Example algorithm file.

## 2. Public API

The sorting service will be attached to the main addon table at `NextKey.Sorting`. It will expose the following public methods:

---

### `NextKey.Sorting:RegisterAlgorithm(name, metadata, sortFunction)`

Registers a new sorting algorithm with the service.

-   **`name`** (string): The display name of the algorithm (e.g., "By Score").
-   **`metadata`** (table): A table containing rules for when this algorithm is applicable. See section 3 for the structure.
-   **`sortFunction`** (function): The function that performs the comparison. It should accept two arguments (`a`, `b`) and return `true` if `a` should come before `b`.

---

### `NextKey.Sorting:GetAlgorithmsForContext(context)`

Retrieves a list of algorithms that are valid for the given context.

-   **`context`** (table): A table describing the current situation (e.g., the UI view, the group size).
-   **Returns**: A new table (array) of applicable algorithms, where each element is a table containing the name and the sort function, e.g., `{ {name = "By Score", func = sortFunc1}, ... }`.

## 3. Metadata Structure

The `metadata` table passed to `RegisterAlgorithm` will use the following key/value pairs to define applicability. All keys are optional. If a key is omitted, the algorithm will match any value for that context parameter.

-   **`applicableViews`** (table, optional): An array of strings. If present, the algorithm will only be available in the specified UI views (e.g., `{"mainWindow", "organizer"}`).
-   **`minGroupSize`** (number, optional): The minimum number of players in a group for this sort to be applicable.
-   **`maxGroupSize`** (number, optional): The maximum number of players in a group for this sort to be applicable.

### Example Metadata:

```lua
-- Only for the main window, for groups of 1 to 5 players
local metadata = {
    applicableViews = {"mainWindow"},
    minGroupSize = 1,
    maxGroupSize = 5
}

-- For any view, but only for full raid groups
local metadata_raid = {
    minGroupSize = 10
}
```

## 4. Usage Example (Consumer)

A UI module, like the Organizer, would use the system as follows:

```lua
-- In the Organizer UI file

-- 1. Define the current context
local context = {
    view = "organizer",
    groupSize = #currentGroup -- Get the number of players in the group
}

-- 2. Get the valid sorting algorithms for this context
local availableSorts = NextKey.Sorting:GetAlgorithmsForContext(context)

-- 3. Populate a dropdown menu with the names
for _, sortInfo in ipairs(availableSorts) do
    MyDropdown:AddLine(sortInfo.name)
end

-- 4. When a user selects a sort, retrieve the function and use it
local selectedSortName = MyDropdown:GetSelectedValue()
local sortFunction
for _, sortInfo in ipairs(availableSorts) do
    if sortInfo.name == selectedSortName then
        sortFunction = sortInfo.func
        break
    end
end

if sortFunction then
    table.sort(currentGroup, sortFunction)
    -- Redraw the UI
end
```

## 5. Implementation Example (Algorithm)

A new sorting algorithm file (`core/sorting/algorithms/byKeyLevel.lua`) would look like this:

```lua
-- File: core/sorting/algorithms/byKeyLevel.lua
local AddonName, Addon = ...

-- The actual sorting logic
local function SortByKeyLevel(groupA, groupB)
    -- Assuming groupA and groupB are tables with a 'keyLevel' field
    return groupA.keyLevel > groupB.keyLevel
end

-- The metadata defining where this sort can be used
local metadata = {
    applicableViews = {"mainWindow", "organizer"},
    minGroupSize = 2,
    maxGroupSize = 5
}

-- Register the algorithm with the central service
Addon.Sorting:RegisterAlgorithm("By Key Level", metadata, SortByKeyLevel)
```
