# Refactor Implementation Plan: 02_Group_Organizer

## 1. Core Logic (`core/organizer/state.lua`) Modifications

The `state.lua` module will be modified to become the sole announcer of the roster's state.

1.  **Identify State-Changing Functions:** A thorough review of the file will be conducted to identify all public and private functions that result in a modification of the main roster table. This includes functions that add, remove, or update players.

2.  **Create a Centralized Broadcast Function:** A new private function, `BroadcastRosterUpdate()`, will be created within the module.
    ```lua
    local function BroadcastRosterUpdate()
        -- The roster table is assumed to be a local variable 'roster'
        NextKey:SendMessage("ORGANIZER_ROSTER_UPDATED", roster)
    end
    ```

3.  **Integrate the Broadcast:** At the end of every identified state-changing function, a call to `BroadcastRosterUpdate()` will be added. This ensures that every change, no matter how small, triggers a state announcement.

4.  **Remove UI Dependencies:** Any code that suggests a dependency on the UI (e.g., checking if the UI is visible before processing data) will be removed. The core logic should be completely independent of any consumer.

## 2. UI (`ui/organizer/rosterBoard.lua`) Modifications

The `rosterBoard.lua` module will be refactored into a passive listener and renderer.

1.  **Remove Direct Calls:** All direct function calls to the `core/organizer/state.lua` module (or any of its equivalents for fetching data) will be located and removed.

2.  **Register Event Listener:** In the module's initialization function (e.g., `OnInitialize`), a listener for the new `ORGANIZER_ROSTER_UPDATED` event will be registered.
    ```lua
    function RosterBoard:OnInitialize()
        -- ... other initialization
        NextKey:RegisterMessage("ORGANIZER_ROSTER_UPDATED", self.OnRosterUpdated, self)
    end
    ```

3.  **Implement the Event Handler:** A new method, `OnRosterUpdated`, will be created. This method will accept the roster data from the event payload.
    ```lua
    function RosterBoard:OnRosterUpdated(eventName, roster)
        -- Store the new roster data locally
        self.rosterData = roster
        -- Trigger a full redraw of the UI
        self:Redraw()
    end
    ```

4.  **Adapt the Redraw Logic:** The existing `Redraw()` function (or its equivalent) will be modified to source its data exclusively from the locally stored `self.rosterData`. It will no longer fetch data on its own. It will be responsible for iterating over the data and rendering the player cards, sorting headers, and any other relevant UI elements.

## 3. Data Flow Diagram

The resulting data flow will be a simple, one-way push from the core to the UI.

```
+----------------------------+
| core/organizer/state.lua   |
+----------------------------+
|                            |
|  - Roster data is changed  |
|  - Calls BroadcastRoster() |
|                            |
+-------------+--------------+
              |
              | Fires Event: "ORGANIZER_ROSTER_UPDATED"
              | Payload: (roster_table)
              v
+-------------+--------------+
| ui/organizer/rosterBoard.lua|
+----------------------------+
|                            |
| - Listens for event        |
| - Calls OnRosterUpdated()  |
| - Stores new roster data   |
| - Calls self:Redraw()      |
|                            |
+----------------------------+
```
